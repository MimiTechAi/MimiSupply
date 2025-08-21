//
//  DataLayerIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import CoreData
import CloudKit
@testable import MimiSupply

/// Integration tests for data layer components (CloudKit + CoreData)
final class DataLayerIntegrationTests: XCTestCase {
    
    var coreDataStack: CoreDataStack!
    var cloudKitService: CloudKitService!
    var conflictResolutionService: ConflictResolutionService!
    var offlineManager: OfflineManager!
    
    override func setUp() {
        super.setUp()
        
        // Use in-memory store for testing
        coreDataStack = CoreDataStack(inMemory: true)
        cloudKitService = MockCloudKitService()
        conflictResolutionService = ConflictResolutionService()
        offlineManager = OfflineManager(
            coreDataStack: coreDataStack,
            cloudKitService: cloudKitService
        )
    }
    
    override func tearDown() {
        offlineManager = nil
        conflictResolutionService = nil
        cloudKitService = nil
        coreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Data Synchronization Tests
    
    func testCloudKitToCoreDataSync() async throws {
        // Given - Data exists in CloudKit
        let mockCloudKit = cloudKitService as! MockCloudKitService
        let testPartners = [
            createTestPartner(id: "partner-1", name: "Test Restaurant 1"),
            createTestPartner(id: "partner-2", name: "Test Restaurant 2")
        ]
        mockCloudKit.mockPartners = testPartners
        
        // When - Syncing from CloudKit to CoreData
        try await offlineManager.syncFromCloudKit()
        
        // Then - Data should be saved to CoreData
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
        let savedPartners = try context.fetch(request)
        
        XCTAssertEqual(savedPartners.count, 2)
        XCTAssertTrue(savedPartners.contains { $0.name == "Test Restaurant 1" })
        XCTAssertTrue(savedPartners.contains { $0.name == "Test Restaurant 2" })
    }
    
    func testCoreDataToCloudKitSync() async throws {
        // Given - Data exists in CoreData
        let context = coreDataStack.viewContext
        let partnerEntity = PartnerEntity(context: context)
        partnerEntity.id = "local-partner-1"
        partnerEntity.name = "Local Restaurant"
        partnerEntity.category = "restaurant"
        partnerEntity.isActive = true
        partnerEntity.createdAt = Date()
        
        try context.save()
        
        // When - Syncing from CoreData to CloudKit
        try await offlineManager.syncToCloudKit()
        
        // Then - Data should be uploaded to CloudKit
        let mockCloudKit = cloudKitService as! MockCloudKitService
        XCTAssertTrue(mockCloudKit.mockPartners.contains { $0.name == "Local Restaurant" })
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testConflictResolutionLastWriterWins() async throws {
        // Given - Same record exists in both CloudKit and CoreData with different timestamps
        let cloudKitRecord = createTestPartner(
            id: "conflict-partner",
            name: "CloudKit Version",
            updatedAt: Date().addingTimeInterval(100) // Newer
        )
        
        let context = coreDataStack.viewContext
        let coreDataEntity = PartnerEntity(context: context)
        coreDataEntity.id = "conflict-partner"
        coreDataEntity.name = "CoreData Version"
        coreDataEntity.updatedAt = Date() // Older
        try context.save()
        
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.mockPartners = [cloudKitRecord]
        
        // When - Resolving conflict
        try await conflictResolutionService.resolveConflicts()
        
        // Then - CloudKit version should win (newer timestamp)
        let request: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", "conflict-partner")
        let results = try context.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "CloudKit Version")
    }
    
    func testConflictResolutionCustomLogic() async throws {
        // Given - Order with different statuses in CloudKit and CoreData
        let cloudKitOrder = createTestOrder(
            id: "conflict-order",
            status: .delivered,
            updatedAt: Date().addingTimeInterval(-100) // Older timestamp
        )
        
        let context = coreDataStack.viewContext
        let coreDataOrder = OrderEntity(context: context)
        coreDataOrder.id = "conflict-order"
        coreDataOrder.status = OrderStatus.cancelled.rawValue
        coreDataOrder.updatedAt = Date() // Newer timestamp
        try context.save()
        
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.mockOrders = [cloudKitOrder]
        
        // When - Resolving conflict with custom logic
        try await conflictResolutionService.resolveOrderConflicts()
        
        // Then - Delivered status should win over cancelled (business rule)
        let request: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", "conflict-order")
        let results = try context.fetch(request)
        
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.status, OrderStatus.delivered.rawValue)
    }
    
    // MARK: - Offline Mode Tests
    
    func testOfflineDataAccess() async throws {
        // Given - Data is cached locally
        let context = coreDataStack.viewContext
        let partnerEntity = PartnerEntity(context: context)
        partnerEntity.id = "offline-partner"
        partnerEntity.name = "Offline Restaurant"
        partnerEntity.category = "restaurant"
        partnerEntity.isActive = true
        try context.save()
        
        // When - Accessing data while offline
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.shouldThrowError = true // Simulate network error
        
        let cachedPartners = try await offlineManager.getCachedPartners()
        
        // Then - Should return cached data
        XCTAssertEqual(cachedPartners.count, 1)
        XCTAssertEqual(cachedPartners.first?.name, "Offline Restaurant")
    }
    
    func testOfflineDataModification() async throws {
        // Given - App is offline
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.shouldThrowError = true
        
        // When - Modifying data offline
        let newOrder = createTestOrder(id: "offline-order")
        try await offlineManager.saveOrderOffline(newOrder)
        
        // Then - Data should be queued for sync
        let pendingSync = try await offlineManager.getPendingSyncItems()
        XCTAssertEqual(pendingSync.count, 1)
        XCTAssertEqual(pendingSync.first?.itemId, "offline-order")
    }
    
    func testOfflineSyncWhenOnline() async throws {
        // Given - Offline changes are queued
        let offlineOrder = createTestOrder(id: "offline-order")
        try await offlineManager.saveOrderOffline(offlineOrder)
        
        // When - Coming back online
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.shouldThrowError = false
        
        try await offlineManager.syncPendingChanges()
        
        // Then - Changes should be synced to CloudKit
        XCTAssertTrue(mockCloudKit.mockOrders.contains { $0.id == "offline-order" })
        
        // And sync queue should be empty
        let pendingSync = try await offlineManager.getPendingSyncItems()
        XCTAssertEqual(pendingSync.count, 0)
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityAfterSync() async throws {
        // Given - Complex data relationships
        let partner = createTestPartner(id: "integrity-partner")
        let product = createTestProduct(id: "integrity-product", partnerId: "integrity-partner")
        let order = createTestOrder(id: "integrity-order", partnerId: "integrity-partner")
        
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.mockPartners = [partner]
        mockCloudKit.mockProducts = [product]
        mockCloudKit.mockOrders = [order]
        
        // When - Syncing all data
        try await offlineManager.syncFromCloudKit()
        
        // Then - Relationships should be maintained
        let context = coreDataStack.viewContext
        
        let partnerRequest: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
        let partners = try context.fetch(partnerRequest)
        XCTAssertEqual(partners.count, 1)
        
        let productRequest: NSFetchRequest<ProductEntity> = ProductEntity.fetchRequest()
        let products = try context.fetch(productRequest)
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.partnerId, "integrity-partner")
        
        let orderRequest: NSFetchRequest<OrderEntity> = OrderEntity.fetchRequest()
        let orders = try context.fetch(orderRequest)
        XCTAssertEqual(orders.count, 1)
        XCTAssertEqual(orders.first?.partnerId, "integrity-partner")
    }
    
    // MARK: - Performance Tests
    
    func testBatchSyncPerformance() async throws {
        // Given - Large dataset
        let partners = (0..<1000).map { index in
            createTestPartner(id: "partner-\(index)", name: "Partner \(index)")
        }
        
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.mockPartners = partners
        
        // When - Syncing large dataset
        let startTime = Date()
        try await offlineManager.syncFromCloudKit()
        let syncTime = Date().timeIntervalSince(startTime)
        
        // Then - Sync should complete in reasonable time
        XCTAssertLessThan(syncTime, 10.0, "Batch sync should complete within 10 seconds")
        
        // And all data should be synced
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
        let savedPartners = try context.fetch(request)
        XCTAssertEqual(savedPartners.count, 1000)
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncErrorRecovery() async throws {
        // Given - CloudKit service fails intermittently
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.shouldThrowError = true
        
        // When - Attempting sync
        do {
            try await offlineManager.syncFromCloudKit()
            XCTFail("Should have thrown error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(error is CloudKitError)
        }
        
        // When - Service recovers
        mockCloudKit.shouldThrowError = false
        mockCloudKit.mockPartners = [createTestPartner()]
        
        // Then - Sync should succeed
        try await offlineManager.syncFromCloudKit()
        
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<PartnerEntity> = PartnerEntity.fetchRequest()
        let partners = try context.fetch(request)
        XCTAssertEqual(partners.count, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPartner(
        id: String = "test-partner",
        name: String = "Test Partner",
        updatedAt: Date = Date()
    ) -> Partner {
        return Partner(
            id: id,
            name: name,
            category: .restaurant,
            description: "Test description",
            address: Address(
                street: "123 Test St",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "test@example.com",
            heroImageURL: nil,
            logoURL: nil,
            isVerified: true,
            isActive: true,
            rating: 4.5,
            reviewCount: 100,
            openingHours: [:],
            deliveryRadius: 5.0,
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: 30,
            createdAt: Date(),
            updatedAt: updatedAt
        )
    }
    
    private func createTestProduct(
        id: String = "test-product",
        partnerId: String = "test-partner"
    ) -> Product {
        return Product(
            id: id,
            partnerId: partnerId,
            name: "Test Product",
            description: "Test description",
            priceCents: 1200,
            originalPriceCents: nil,
            category: .food,
            imageURLs: [],
            isAvailable: true,
            stockQuantity: 10,
            nutritionInfo: nil,
            allergens: [],
            tags: [],
            weight: nil,
            dimensions: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestOrder(
        id: String = "test-order",
        partnerId: String = "test-partner",
        status: OrderStatus = .created,
        updatedAt: Date = Date()
    ) -> Order {
        return Order(
            id: id,
            customerId: "customer-123",
            partnerId: partnerId,
            driverId: nil,
            items: [],
            status: status,
            subtotalCents: 1200,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 96,
            tipCents: 200,
            deliveryAddress: Address(
                street: "123 Test St",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "US"
            ),
            deliveryInstructions: nil,
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            actualDeliveryTime: nil,
            paymentMethod: .applePay,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: updatedAt
        )
    }
}

// MARK: - Supporting Types

struct PendingSyncItem {
    let itemId: String
    let itemType: String
    let operation: SyncOperation
    let timestamp: Date
}

enum SyncOperation {
    case create
    case update
    case delete
}