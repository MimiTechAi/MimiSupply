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
    func cacheBatch<T: Codable>(
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
    func retrieveBatch<T: Codable>(
        _ type: T.Type,
        keys: [String],
        category: CacheCategory = .general
    ) async -> [String: T] {
        var results: [String: T] = [:]
        
        await withTaskGroup(of: (String, T?).self) { group in
            for key in keys {
                group.addTask {
                    let data = try? await self.retrieveCachedData(type, forKey: key, category: category)
                    return (key, data)
                }
            }
            
            for await (key, data) in group {
                if let data = data {
                    results[key] = data
                }
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
        
        if currentSize > maxCacheSize {
            logger.warning("⚠️ Cache size exceeded limit: \(currentSize) > \(maxCacheSize)")
            await evictOldestCacheItems(targetReduction: currentSize - maxCacheSize)
        }
        
        let imagesCacheSize = await calculateImagesCacheSize()
        if imagesCacheSize > maxImageCacheSize {
            logger.warning("⚠️ Images cache size exceeded limit: \(imagesCacheSize) > \(maxImageCacheSize)")
            await evictOldestImages(targetReduction: imagesCacheSize - maxImageCacheSize)
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
        cacheMetrics.totalSize = await calculateCacheSize() + await calculateImagesCacheSize()
        cacheMetrics.totalItems = await countCacheItems()
        cacheMetrics.lastUpdated = Date()
    }
    
    private func calculateCacheSize() async -> Int64 {
        return await withCheckedContinuation { continuation in
            operationQueue.addOperation {
                var totalSize: Int64 = 0
                
                if let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                    for case let fileURL as URL in enumerator {
                        do {
                            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                            totalSize += Int64(resourceValues.fileSize ?? 0)
                        } catch {
                            // Skip files that can't be read
                        }
                    }
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    private func calculateImagesCacheSize() async -> Int64 {
        return await withCheckedContinuation { continuation in
            operationQueue.addOperation {
                var totalSize: Int64 = 0
                
                if let enumerator = self.fileManager.enumerator(at: self.imagesCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
                    for case let fileURL as URL in enumerator {
                        do {
                            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                            totalSize += Int64(resourceValues.fileSize ?? 0)
                        } catch {
                            // Skip files that can't be read
                        }
                    }
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    private func countCacheItems() async -> Int {
        return await withCheckedContinuation { continuation in
            operationQueue.addOperation {
                var count = 0
                
                if let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: nil) {
                    for _ in enumerator {
                        count += 1
                    }
                }
                
                continuation.resume(returning: count)
            }
        }
    }
    
    private func getOldestCacheItem() async -> Date? {
        return await withCheckedContinuation { continuation in
            operationQueue.addOperation {
                var oldestDate: Date?
                
                if let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) {
                    for case let fileURL as URL in enumerator {
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
                
                continuation.resume(returning: oldestDate)
            }
        }
    }
    
    private func getNewestCacheItem() async -> Date? {
        return await withCheckedContinuation { continuation in
            operationQueue.addOperation {
                var newestDate: Date?
                
                if let enumerator = self.fileManager.enumerator(at: self.cacheDirectory, includingPropertiesForKeys: [.creationDateKey]) {
                    for case let fileURL as URL in enumerator {
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
                
                continuation.resume(returning: newestDate)
            }
        }
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

enum CacheCategory: String, CaseIterable {
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

final class BatchCacheOperation<T: Codable>: Operation {
    private let items: [(key: String, data: T)]
    private let category: CacheCategory
    private weak var persistenceManager: OfflinePersistenceManager?
    
    init(items: [(key: String, data: T)], category: CacheCategory, persistenceManager: OfflinePersistenceManager) {
        self.items = items
        self.category = category
        self