final class EnhancedCloudKitService: CloudKitService, @unchecked Sendable {
    private let publicDatabase = CKContainer.default().publicCloudDatabase
    private let privateDatabase = CKContainer.default().privateDatabase
    private let container = CKContainer.default()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "EnhancedCloudKitService")
    private let retryManager = RetryManager.shared
    private let cacheManager = CacheManager.shared

    @MainActor
    private var degradationService: GracefulDegradationService {
        GracefulDegradationService.shared
    }

// ... existing code ...

    func save<T: Codable & Sendable>(_ object: T) async throws -> T {

// ... existing code ...

    func fetch<T: Codable & Sendable>(_ type: T.Type, predicate: NSPredicate) async throws -> [T] {

// ... existing code ...