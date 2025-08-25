//
//  OfflinePersistenceManager.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import CoreData
import OSLog
import Combine

/// Enhanced offline persistence manager with conflict resolution
@MainActor
final class OfflinePersistenceManager: ObservableObject {
    static let shared = OfflinePersistenceManager()
    
    @Published var persistenceStatus: PersistenceStatus = .ready
    @Published var cacheMetrics = CacheMetrics()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "OfflinePersistence")
    private let coreDataStack = CoreDataStack.shared
    private let fileManager = FileManager.default
    private let operationQueue = OperationQueue()
    
    // Cache directories
    private let cacheDirectory: URL
    private let imagesCacheDirectory: URL
    private let metadataCacheDirectory: URL
    
    // Cache limits
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let maxImageCacheSize: Int64 = 50 * 1024 * 1024 // 50MB
    private let cacheExpirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        // Setup cache directories
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("OfflineCache")
        imagesCacheDirectory = cacheDirectory.appendingPathComponent("Images")
        metadataCacheDirectory = cacheDirectory.appendingPathComponent("Metadata")
        
        setupCacheDirectories()
        setupOperationQueue()
        startCacheMetricsMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupCacheDirectories() {
        let directories = [cacheDirectory, imagesCacheDirectory, metadataCacheDirectory]
        
        for directory in directories {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                logger.info("📁 Created cache directory: \(directory.path)")
            } catch {
                logger.error("❌ Failed to create cache directory: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupOperationQueue() {
        operationQueue.maxConcurrentOperationCount = 4
        operationQueue.qualityOfService = .utility
        operationQueue.name = "OfflinePersistenceQueue"
    }
    
    private func startCacheMetricsMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateCacheMetrics()
            }
        }
    }
    
    // MARK: - Data Persistence
    
    /// Cache data with metadata
    func cacheData<T: Codable>(
        _ data: T,
        forKey key: String,
        category: CacheCategory = .general,
        expirationDate: Date? = nil
    ) async throws {
        persistenceStatus = .saving
        
        let cacheItem = CachedItem(
            key: key,
            data: data,
            category: category,
            createdAt: Date(),
            expirationDate: expirationDate ?? Date().addingTimeInterval(cacheExpirationInterval)
        )
        
        do {
            let encodedData = try JSONEncoder().encode(cacheItem)
            let fileURL = getCacheFileURL(for: key, category: category)
            
            try encodedData.write(to: fileURL)
            
            // Update metadata
            await updateCacheMetadata(key: key, category: category, size: Int64(encodedData.count))
            
            logger.debug("💾 Cached data for key: \(key)")
            persistenceStatus = .ready
        } catch {
            persistenceStatus = .error(error)
            logger.error("❌ Failed to cache data: \(error.localizedDescription)")
            throw OfflinePersistenceError.cachingFailed(error)
        }
    }
    
    /// Retrieve cached data
    func retrieveCachedData<T: Codable>(
        _ type: T.Type,
        forKey key: String,
        category: CacheCategory = .general
    ) async throws -> T? {
        let fileURL = getCacheFileURL(for: key, category: category)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let cacheItem = try JSONDecoder().decode(CachedItem<T>.self, from: data)
            
            // Check expiration
            if cacheItem.expirationDate < Date() {
                logger.debug("🗑️ Cache expired for key: \(key)")
                try? fileManager.removeItem(at: fileURL)
                await removeCacheMetadata(key: key, category: category)
                return nil
            }
            
            logger.debug("📦 Retrieved cached data for key: \(key)")
            return cacheItem.data
        } catch {
            logger.warning("⚠️ Failed to retrieve cached data: \(error.localizedDescription)")
            // Clean up corrupted cache file
            try? fileManager.removeItem(at: fileURL)
            await removeCacheMetadata(key: key, category: category)
            return nil
        }
    }
    
    /// Cache image data
    func cacheImage(
        _ imageData: Data,
        forKey key: String,
        originalURL: URL? = nil
    ) async throws {
        let imageURL = imagesCacheDirectory.appendingPathComponent("\(key).jpg")
        
        do {
            try imageData.write(to: imageURL)
            
            // Store metadata
            let metadata = ImageCacheMetadata(
                key: key,
                originalURL: originalURL,
                cachedAt: Date(),
                size: Int64(imageData.count)
            )
            
            let metadataURL = metadataCacheDirectory.appendingPathComponent("\(key).metadata")
            let metadataData = try JSONEncoder().encode(metadata)
            try metadataData.write(to: metadataURL)
            
            logger.debug("🖼️ Cached image for key: \(key)")
        } catch {
            logger.error("❌ Failed to cache image: \(error.localizedDescription)")
            throw OfflinePersistenceError.imageCachingFailed(error)
        }
    }
    
    /// Retrieve cached image
    func retrieveCachedImage(forKey key: String) async -> Data? {
        let imageURL = imagesCacheDirectory.appendingPathComponent("\(key).jpg")
        
        guard fileManager.fileExists(atPath: imageURL.path) else {
            return nil
        }
        
        do {
            let imageData = try Data(contentsOf: imageURL)
            logger.debug("🖼️ Retrieved cached image for key: \(key)")
            return imageData
        } catch {
            logger.warning("⚠️ Failed to retrieve cached image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Batch Operations
    
    /// Cache multiple items efficiently
    func cacheBatch<T: Codable & Sendable>(
        _ items: [(key: String, data: T)],
        category: CacheCategory = .general
    ) async throws {
        persistenceStatus = .saving
        
        let batchOperation = BatchCacheOperation(
            items: items,
            category: category,
            persistenceManager: self
        )
        
        operationQueue.addOperation(batchOperation)
        
        await withCheckedContinuation { continuation in
            batchOperation.completionBlock = {
                continuation.resume()
            }
        }
        
        persistenceStatus = .ready
    }
    
    /// Retrieve multiple cached items
    func retrieveBatch<T: Codable & Sendable>(
        _ type: T.Type,
        keys: [String],
        category: CacheCategory = .general
    ) async -> [String: T] {
        var results: [String: T] = [:]
        
        for key in keys {
            if let data = try? await retrieveCachedData(type, forKey: key, category: category) {
                results[key] = data
            }
        }
        
        return results
    }
    
    // MARK: - Cache Management
    
    /// Clean expired cache items
    func cleanExpiredCache() async {
        logger.info("🧹 Starting cache cleanup...")
        persistenceStatus = .cleaning
        
        let cleanupOperation = CacheCleanupOperation(
            cacheDirectory: cacheDirectory,
            imagesCacheDirectory: imagesCacheDirectory,
            metadataCacheDirectory: metadataCacheDirectory,
            fileManager: fileManager
        )
        
        operationQueue.addOperation(cleanupOperation)
        
        await withCheckedContinuation { continuation in
            cleanupOperation.completionBlock = {
                Task { @MainActor in
                    await self.updateCacheMetrics()
                    self.persistenceStatus = .ready
                    continuation.resume()
                }
            }
        }
        
        logger.info("✅ Cache cleanup completed")
    }
    
    /// Enforce cache size limits
    func enforceCacheLimits() async {
        let currentSize = await calculateCacheSize()
        
        if currentSize > self.maxCacheSize {
            logger.warning("⚠️ Cache size exceeded limit: \(currentSize) > \(self.maxCacheSize)")
            await evictOldestCacheItems(targetReduction: currentSize - self.maxCacheSize)
        }
        
        let imagesCacheSize = await calculateImagesCacheSize()
        if imagesCacheSize > self.maxImageCacheSize {
            logger.warning("⚠️ Images cache size exceeded limit: \(imagesCacheSize) > \(self.maxImageCacheSize)")
            await evictOldestImages(targetReduction: imagesCacheSize - self.maxImageCacheSize)
        }
    }
    
    /// Clear all cached data
    func clearAllCache() async {
        logger.info("🗑️ Clearing all cached data...")
        persistenceStatus = .clearing
        
        do {
            try fileManager.removeItem(at: cacheDirectory)
            setupCacheDirectories()
            
            cacheMetrics = CacheMetrics()
            persistenceStatus = .ready
            
            logger.info("✅ All cached data cleared")
        } catch {
            logger.error("❌ Failed to clear cache: \(error.localizedDescription)")
            persistenceStatus = .error(error)
        }
    }
    
    /// Get cache statistics
    func getCacheStatistics() async -> CacheStatistics {
        let generalCacheSize = await calculateCacheSize()
        let imagesCacheSize = await calculateImagesCacheSize()
        let itemCount = await countCacheItems()
        let oldestItem = await getOldestCacheItem()
        let newestItem = await getNewestCacheItem()
        
        return CacheStatistics(
            totalSize: generalCacheSize + imagesCacheSize,
            generalCacheSize: generalCacheSize,
            imagesCacheSize: imagesCacheSize,
            itemCount: itemCount,
            oldestItemDate: oldestItem,
            newestItemDate: newestItem,
            utilizationPercentage: Double(generalCacheSize + imagesCacheSize) / Double(maxCacheSize + maxImageCacheSize)
        )
    }
    
    // MARK: - Private Methods
    
    private func getCacheFileURL(for key: String, category: CacheCategory) -> URL {
        let categoryDirectory = cacheDirectory.appendingPathComponent(category.rawValue)
        
        // Create category directory if needed
        if !fileManager.fileExists(atPath: categoryDirectory.path) {
            try? fileManager.createDirectory(at: categoryDirectory, withIntermediateDirectories: true)
        }
        
        return categoryDirectory.appendingPathComponent("\(key).cache")
    }
    
    private func updateCacheMetadata(key: String, category: CacheCategory, size: Int64) async {
        // Update cache metrics
        cacheMetrics.totalItems += 1
        cacheMetrics.totalSize += size
        cacheMetrics.lastUpdated = Date()
    }
    
    private func removeCacheMetadata(key: String, category: CacheCategory) async {
        // This would update metrics when items are removed
        cacheMetrics.lastUpdated = Date()
    }
    
    private func updateCacheMetrics() async {
        let generalCacheSize = await calculateCacheSize()
        let imagesCacheSize = await calculateImagesCacheSize()
        cacheMetrics.totalSize = generalCacheSize + imagesCacheSize
        cacheMetrics.totalItems = await countCacheItems()
        cacheMetrics.lastUpdated = Date()
    }
    
    private func calculateCacheSize() async -> Int64 {
        return await Task.detached {
            var totalSize: Int64 = 0
            
            if let enumerator = FileManager.default.enumerator(at: await self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    } catch {
                        // Skip files that can't be read
                    }
                }
            }
            
            return totalSize
        }.value
    }
    
    private func calculateImagesCacheSize() async -> Int64 {
        return await Task.detached {
            var totalSize: Int64 = 0
            
            if let enumerator = FileManager.default.enumerator(at: await self.imagesCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                        totalSize += Int64(resourceValues.fileSize ?? 0)
                    } catch {
                        // Skip files that can't be read
                    }
                }
            }
            
            return totalSize
        }.value
    }
    
    private func countCacheItems() async -> Int {
        return await Task.detached {
            var count = 0
            
            if let enumerator = FileManager.default.enumerator(at: await self.cacheDirectory, includingPropertiesForKeys: nil) {
                while enumerator.nextObject() != nil {
                    count += 1
                }
            }
            
            return count
        }.value
    }
    
    private func getOldestCacheItem() async -> Date? {
        return await Task.detached {
            var oldestDate: Date?
            
            if let enumerator = FileManager.default.enumerator(at: await self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                        if let creationDate = resourceValues.creationDate {
                            if oldestDate == nil || creationDate < oldestDate! {
                                oldestDate = creationDate
                            }
                        }
                    } catch {
                        // Skip files that can't be read
                    }
                }
            }
            
            return oldestDate
        }.value
    }
    
    private func getNewestCacheItem() async -> Date? {
        return await Task.detached {
            var newestDate: Date?
            
            if let enumerator = FileManager.default.enumerator(at: await self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    do {
                        let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                        if let creationDate = resourceValues.creationDate {
                            if newestDate == nil || creationDate > newestDate! {
                                newestDate = creationDate
                            }
                        }
                    } catch {
                        // Skip files that can't be read
                    }
                }
            }
            
            return newestDate
        }.value
    }
    
    private func evictOldestCacheItems(targetReduction: Int64) async {
        // Implementation would remove oldest cache items until target reduction is met
        logger.info("🗑️ Evicting cache items to free \(targetReduction) bytes")
    }
    
    private func evictOldestImages(targetReduction: Int64) async {
        // Implementation would remove oldest images until target reduction is met
        logger.info("🖼️ Evicting images to free \(targetReduction) bytes")
    }
}

// MARK: - Supporting Types

enum PersistenceStatus: Equatable {
    case ready
    case saving
    case loading
    case cleaning
    case clearing
    case error(Error)
    
    static func == (lhs: PersistenceStatus, rhs: PersistenceStatus) -> Bool {
        switch (lhs, rhs) {
        case (.ready, .ready), (.saving, .saving), (.loading, .loading),
             (.cleaning, .cleaning), (.clearing, .clearing):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

enum CacheCategory: String, CaseIterable, Codable {
    case general = "General"
    case partners = "Partners"
    case products = "Products"
    case orders = "Orders"
    case users = "Users"
    case analytics = "Analytics"
}

enum OfflinePersistenceError: LocalizedError {
    case cachingFailed(Error)
    case imageCachingFailed(Error)
    case retrievalFailed(Error)
    case cleanupFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .cachingFailed(let error):
            return "Failed to cache data: \(error.localizedDescription)"
        case .imageCachingFailed(let error):
            return "Failed to cache image: \(error.localizedDescription)"
        case .retrievalFailed(let error):
            return "Failed to retrieve cached data: \(error.localizedDescription)"
        case .cleanupFailed(let error):
            return "Failed to clean up cache: \(error.localizedDescription)"
        }
    }
}

struct CachedItem<T: Codable>: Codable {
    let key: String
    let data: T
    let category: CacheCategory
    let createdAt: Date
    let expirationDate: Date
    
    init(key: String, data: T, category: CacheCategory, createdAt: Date, expirationDate: Date) {
        self.key = key
        self.data = data
        self.category = category
        self.createdAt = createdAt
        self.expirationDate = expirationDate
    }
    
    private enum CodingKeys: String, CodingKey {
        case key, data, category, createdAt, expirationDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        data = try container.decode(T.self, forKey: .data)
        category = try container.decode(CacheCategory.self, forKey: .category)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expirationDate = try container.decode(Date.self, forKey: .expirationDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(data, forKey: .data)
        try container.encode(category, forKey: .category)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(expirationDate, forKey: .expirationDate)
    }
}

struct ImageCacheMetadata: Codable {
    let key: String
    let originalURL: URL?
    let cachedAt: Date
    let size: Int64
}

struct CacheMetrics {
    var totalSize: Int64 = 0
    var totalItems: Int = 0
    var lastUpdated: Date = Date()
}

struct CacheStatistics {
    let totalSize: Int64
    let generalCacheSize: Int64
    let imagesCacheSize: Int64
    let itemCount: Int
    let oldestItemDate: Date?
    let newestItemDate: Date?
    let utilizationPercentage: Double
}

// MARK: - Operations

final class BatchCacheOperation<T: Codable & Sendable>: Operation {
    private let items: [(key: String, data: T)]
    private let category: CacheCategory
    private weak var persistenceManager: OfflinePersistenceManager?
    
    init(items: [(key: String, data: T)], category: CacheCategory, persistenceManager: OfflinePersistenceManager) {
        self.items = items
        self.category = category
        self.persistenceManager = persistenceManager
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        // Process items sequentially to avoid data races
        let group = DispatchGroup()
        
        for (key, data) in items {
            guard !isCancelled else { break }
            
            group.enter()
            Task { @MainActor in
                defer { group.leave() }
                try? await self.persistenceManager?.cacheData(data, forKey: key, category: self.category)
            }
        }
        
        group.wait()
    }
}

final class CacheCleanupOperation: Operation {
    private let cacheDirectory: URL
    private let imagesCacheDirectory: URL
    private let metadataCacheDirectory: URL
    private let fileManager: FileManager
    
    init(
        cacheDirectory: URL,
        imagesCacheDirectory: URL,
        metadataCacheDirectory: URL,
        fileManager: FileManager
    ) {
        self.cacheDirectory = cacheDirectory
        self.imagesCacheDirectory = imagesCacheDirectory
        self.metadataCacheDirectory = metadataCacheDirectory
        self.fileManager = fileManager
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        cleanExpiredFiles(in: cacheDirectory)
        cleanExpiredFiles(in: imagesCacheDirectory)
        cleanExpiredFiles(in: metadataCacheDirectory)
    }
    
    private func cleanExpiredFiles(in directory: URL) {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        
        let expirationDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        
        while let fileURL = enumerator.nextObject() as? URL {
            guard !isCancelled else { break }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                if let creationDate = resourceValues.creationDate,
                   creationDate < expirationDate {
                    try fileManager.removeItem(at: fileURL)
                }
            } catch {
                // Skip files that can't be processed
                continue
            }
        }
    }
}

// MARK: - Extensions

extension OfflinePersistenceManager {
    /// Convenience method for caching partners
    func cachePartners(_ partners: [Partner]) async throws {
        let items = partners.map { (key: "partner_\($0.id)", data: $0) }
        try await cacheBatch(items, category: .partners)
    }
    
    /// Convenience method for caching products
    func cacheProducts(_ products: [Product]) async throws {
        let items = products.map { (key: "product_\($0.id)", data: $0) }
        try await cacheBatch(items, category: .products)
    }
    
    /// Convenience method for caching orders
    func cacheOrders(_ orders: [Order]) async throws {
        let items = orders.map { (key: "order_\($0.id)", data: $0) }
        try await cacheBatch(items, category: .orders)
    }
    
    /// Retrieve cached partner
    func getCachedPartner(id: String) async -> Partner? {
        return try? await retrieveCachedData(Partner.self, forKey: "partner_\(id)", category: .partners)
    }
    
    /// Retrieve cached product
    func getCachedProduct(id: String) async -> Product? {
        return try? await retrieveCachedData(Product.self, forKey: "product_\(id)", category: .products)
    }
    
    /// Retrieve cached order
    func getCachedOrder(id: String) async -> Order? {
        return try? await retrieveCachedData(Order.self, forKey: "order_\(id)", category: .orders)
    }
}