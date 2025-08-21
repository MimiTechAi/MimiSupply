//
//  OfflineManager.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import CoreData
import OSLog

/// Manages offline functionality and data synchronization
@MainActor
final class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOfflineMode = false
    @Published var pendingSyncCount = 0
    @Published var lastSyncDate: Date?
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "OfflineManager")
    private let networkMonitor = NetworkMonitor.shared
    private let coreDataStack = CoreDataStack.shared
    private let syncQueue = SyncQueue()
    
    private var syncTask: Task<Void, Never>?
    
    private init() {
        setupNetworkMonitoring()
        loadPendingSyncCount()
    }
    
    deinit {
        syncTask?.cancel()
    }
    
    /// Setup network monitoring to handle online/offline transitions
    private func setupNetworkMonitoring() {
        Task {
            for await isConnected in networkMonitor.$isConnected.values {
                await handleNetworkStatusChange(isConnected: isConnected)
            }
        }
    }
    
    /// Handle network status changes
    private func handleNetworkStatusChange(isConnected: Bool) async {
        let wasOffline = isOfflineMode
        isOfflineMode = !isConnected
        
        logger.info("📱 Offline mode: \(self.isOfflineMode ? "ON" : "OFF")")
        
        // If we just came back online, start syncing
        if wasOffline && !isOfflineMode {
            await startSync()
        }
        
        // If we went offline, cancel any ongoing sync
        if !wasOffline && isOfflineMode {
            syncTask?.cancel()
        }
    }
    
    /// Queue an operation for offline sync
    func queueForSync<T: Codable>(_ operation: SyncOperation<T>) {
        syncQueue.enqueue(operation)
        updatePendingSyncCount()
        
        logger.info("📝 Queued operation for sync: \(operation.type.rawValue)")
        
        // Try to sync immediately if online
        if !isOfflineMode {
            Task {
                await startSync()
            }
        }
    }
    
    /// Start syncing queued operations
    private func startSync() async {
        guard !isOfflineMode && syncTask == nil else { return }
        
        logger.info("🔄 Starting sync process...")
        
        syncTask = Task {
            await performSync()
        }
        
        await syncTask?.value
        syncTask = nil
    }
    
    /// Perform the actual sync process
    private func performSync() async {
        let operations = syncQueue.dequeueAll()
        guard !operations.isEmpty else { return }
        
        logger.info("🔄 Syncing \(operations.count) operations...")
        
        var successCount = 0
        var failureCount = 0
        
        for operation in operations {
            do {
                try await processSyncOperation(operation)
                successCount += 1
                logger.debug("✅ Synced operation: \(operation.type.rawValue)")
            } catch {
                failureCount += 1
                logger.warning("❌ Failed to sync operation: \(operation.type.rawValue) - \(error.localizedDescription)")
                
                // Re-queue failed operations for retry
                syncQueue.enqueue(operation)
            }
        }
        
        updatePendingSyncCount()
        lastSyncDate = Date()
        
        logger.info("🔄 Sync completed: \(successCount) success, \(failureCount) failures")
    }
    
    /// Process a single sync operation
    private func processSyncOperation(_ operation: AnySyncOperation) async throws {
        switch operation.type {
        case .createOrder:
            if let orderOp = operation as? SyncOperation<Order> {
                _ = try await CloudKitServiceImpl().createOrder(orderOp.data)
            }
        case .updateOrderStatus:
            if let statusOp = operation as? SyncOperation<OfflineOrderStatusUpdate> {
                try await CloudKitServiceImpl().updateOrderStatus(statusOp.data.orderId, status: statusOp.data.status)
            }
        case .saveUserProfile:
            if let userOp = operation as? SyncOperation<UserProfile> {
                try await CloudKitServiceImpl().saveUserProfile(userOp.data)
            }
        case .saveDriverLocation:
            if let locationOp = operation as? SyncOperation<DriverLocation> {
                try await CloudKitServiceImpl().saveDriverLocation(locationOp.data)
            }
        case .saveDeliveryCompletion:
            if let completionOp = operation as? SyncOperation<DeliveryCompletionData> {
                try await CloudKitServiceImpl().saveDeliveryCompletion(completionOp.data)
            }
        }
    }
    
    /// Update pending sync count
    private func updatePendingSyncCount() {
        pendingSyncCount = syncQueue.count
    }
    
    /// Load pending sync count from storage
    private func loadPendingSyncCount() {
        pendingSyncCount = syncQueue.count
    }
    
    /// Clear all pending sync operations
    func clearPendingSync() {
        syncQueue.clear()
        updatePendingSyncCount()
        logger.info("🗑️ Cleared all pending sync operations")
    }
    
    /// Force sync now (if online)
    func forceSyncNow() async {
        guard !isOfflineMode else {
            logger.warning("⚠️ Cannot force sync while offline")
            return
        }
        
        await startSync()
    }
}

/// Sync operation types
enum SyncOperationType: String, CaseIterable {
    case createOrder
    case updateOrderStatus
    case saveUserProfile
    case saveDriverLocation
    case saveDeliveryCompletion
}

/// Base protocol for sync operations
protocol AnySyncOperation {
    var id: UUID { get }
    var type: SyncOperationType { get }
    var timestamp: Date { get }
    var retryCount: Int { get set }
    var maxRetries: Int { get }
}

/// Generic sync operation
struct SyncOperation<T: Codable>: AnySyncOperation {
    let id = UUID()
    let type: SyncOperationType
    let data: T
    let timestamp = Date()
    var retryCount = 0
    let maxRetries = 3
    
    init(type: SyncOperationType, data: T) {
        self.type = type
        self.data = data
    }
}

/// Order status update data for offline sync
struct OfflineOrderStatusUpdate: Codable {
    let orderId: String
    let status: OrderStatus
}

/// Thread-safe sync queue
final class SyncQueue {
    private var operations: [AnySyncOperation] = []
    private let queue = DispatchQueue(label: "SyncQueue", attributes: .concurrent)
    
    var count: Int {
        queue.sync {
            operations.count
        }
    }
    
    func enqueue(_ operation: AnySyncOperation) {
        queue.async(flags: .barrier) {
            self.operations.append(operation)
        }
    }
    
    func dequeueAll() -> [AnySyncOperation] {
        queue.sync(flags: .barrier) {
            let result = operations
            operations.removeAll()
            return result
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.operations.removeAll()
        }
    }
}

/// Cached data manager for offline access
final class CacheManager: @unchecked Sendable {
    static let shared = CacheManager()
    
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Setup cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("OfflineCache")
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    /// Cache data for offline access
    func cache<T: Codable>(_ data: T, forKey key: String) {
        do {
            let encoded = try JSONEncoder().encode(data)
            
            // Memory cache
            cache.setObject(encoded as NSData, forKey: key as NSString)
            
            // Disk cache
            let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
            try encoded.write(to: fileURL)
        } catch {
            Logger(subsystem: "com.mimisupply.app", category: "CacheManager")
                .error("Failed to cache data for key \(key): \(error.localizedDescription)")
        }
    }
    
    /// Retrieve cached data
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        // Try memory cache first
        if let cachedData = cache.object(forKey: key as NSString) {
            do {
                return try JSONDecoder().decode(type, from: cachedData as Data)
            } catch {
                // Remove corrupted data from memory cache
                cache.removeObject(forKey: key as NSString)
            }
        }
        
        // Try disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        do {
            let decoded = try JSONDecoder().decode(type, from: data)
            // Update memory cache
            cache.setObject(data as NSData, forKey: key as NSString)
            return decoded
        } catch {
            // Remove corrupted file
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
    
    /// Clear all cached data
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}