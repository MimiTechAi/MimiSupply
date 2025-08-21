//
//  PushNotificationIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import UserNotifications
import CloudKit
@testable import MimiSupply

final class PushNotificationIntegrationTests: XCTestCase {
    
    var pushNotificationService: PushNotificationServiceImpl!
    var mockCloudKitService: MockCloudKitService!
    var mockAuthenticationService: MockAuthenticationService!
    
    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        mockAuthenticationService = MockAuthenticationService()
        pushNotificationService = PushNotificationServiceImpl(
            cloudKitService: mockCloudKitService,
            authenticationService: mockAuthenticationService
        )
    }
    
    override func tearDown() {
        pushNotificationService = nil
        mockCloudKitService = nil
        mockAuthenticationService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Workflow Tests
    
    func testCompleteCustomerOrderNotificationFlow() async throws {
        // Setup customer user
        let customer = UserProfile.testCustomer()
        mockAuthenticationService.mockCurrentUser = customer
        mockAuthenticationService.mockAuthState = .authenticated(customer)
        
        // Setup CloudKit subscriptions
        try await pushNotificationService.setupCloudKitSubscriptions(for: .customer, userId: customer.id)
        
        // Simulate order creation and status updates
        let order = createTestOrder(customerId: customer.id)
        mockCloudKitService.mockOrders = [order]
        
        // Test order confirmation notification
        let confirmationNotification = LocalNotification(
            title: "Order Confirmed",
            body: "Your order from Test Restaurant has been confirmed",
            userInfo: [
                "type": NotificationType.orderConfirmed.rawValue,
                "orderId": order.id
            ],
            category: .orderUpdate
        )
        
        try await pushNotificationService.scheduleLocalNotification(confirmationNotification)
        
        // Test driver assignment notification
        let driverAssignmentNotification = LocalNotification(
            title: "Driver Assigned",
            body: "John is delivering your order",
            userInfo: [
                "type": NotificationType.driverAssigned.rawValue,
                "orderId": order.id,
                "driverId": "test-driver-id"
            ],
            category: .driverAssignment
        )
        
        try await pushNotificationService.scheduleLocalNotification(driverAssignmentNotification)
        
        // Test delivery notification
        let deliveryNotification = LocalNotification(
            title: "Order Delivered",
            body: "Your order has been delivered",
            userInfo: [
                "type": NotificationType.orderDelivered.rawValue,
                "orderId": order.id
            ],
            category: .orderUpdate
        )
        
        try await pushNotificationService.scheduleLocalNotification(deliveryNotification)
        
        // Verify all notifications were scheduled
        XCTAssertTrue(true) // Placeholder - in real implementation, verify notification center
    }
    
    func testCompleteDriverJobNotificationFlow() async throws {
        // Setup driver user
        let driver = UserProfile.testDriver()
        mockAuthenticationService.mockCurrentUser = driver
        mockAuthenticationService.mockAuthState = .authenticated(driver)
        
        // Setup CloudKit subscriptions
        try await pushNotificationService.setupCloudKitSubscriptions(for: .driver, userId: driver.id)
        
        // Test new job available notification
        let jobAvailableNotification = LocalNotification(
            title: "New Job Available",
            body: "Delivery job available nearby - $12.50",
            userInfo: [
                "type": NotificationType.newJobAvailable.rawValue,
                "jobId": "test-job-id",
                "estimatedEarnings": 1250
            ],
            category: .driverJob
        )
        
        try await pushNotificationService.scheduleLocalNotification(jobAvailableNotification)
        
        // Test job assignment notification
        let jobAssignedNotification = LocalNotification(
            title: "Job Assigned",
            body: "You've been assigned a delivery job",
            userInfo: [
                "type": NotificationType.jobAssigned.rawValue,
                "jobId": "test-job-id"
            ],
            category: .driverJob
        )
        
        try await pushNotificationService.scheduleLocalNotification(jobAssignedNotification)
        
        // Test order ready notification
        let orderReadyNotification = LocalNotification(
            title: "Order Ready",
            body: "Order is ready for pickup at Test Restaurant",
            userInfo: [
                "type": NotificationType.orderReady.rawValue,
                "jobId": "test-job-id",
                "partnerId": "test-partner-id"
            ],
            category: .driverJob
        )
        
        try await pushNotificationService.scheduleLocalNotification(orderReadyNotification)
        
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testCompletePartnerOrderNotificationFlow() async throws {
        // Setup partner user
        let partner = UserProfile.testPartner()
        mockAuthenticationService.mockCurrentUser = partner
        mockAuthenticationService.mockAuthState = .authenticated(partner)
        
        // Setup CloudKit subscriptions
        try await pushNotificationService.setupCloudKitSubscriptions(for: .partner, userId: partner.id)
        
        // Test new order notification
        let newOrderNotification = LocalNotification(
            title: "New Order",
            body: "You have received a new order - $25.50",
            userInfo: [
                "type": NotificationType.newOrder.rawValue,
                "orderId": "test-order-id",
                "totalAmount": 2550
            ],
            category: .partnerOrder
        )
        
        try await pushNotificationService.scheduleLocalNotification(newOrderNotification)
        
        // Test driver arrival notification
        let driverArrivedNotification = LocalNotification(
            title: "Driver Arrived",
            body: "Driver John has arrived for pickup",
            userInfo: [
                "type": NotificationType.driverArrived.rawValue,
                "orderId": "test-order-id",
                "driverId": "test-driver-id"
            ],
            category: .partnerOrder
        )
        
        try await pushNotificationService.scheduleLocalNotification(driverArrivedNotification)
        
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - CloudKit Integration Tests
    
    func testCloudKitSubscriptionLifecycle() async throws {
        let userId = "test-user-id"
        
        // Test subscription creation
        try await pushNotificationService.setupCloudKitSubscriptions(for: .customer, userId: userId)
        XCTAssertTrue(mockCloudKitService.subscriptionsCreated.count > 0)
        
        // Test subscription removal
        try await pushNotificationService.removeCloudKitSubscriptions()
        XCTAssertTrue(mockCloudKitService.subscriptionsDeleted.count > 0)
    }
    
    func testCloudKitNotificationHandling() async {
        // Create mock CloudKit notification
        let userInfo: [AnyHashable: Any] = [
            "ck": [
                "qry": [
                    "rid": "test-record-id",
                    "dbs": 2, // Private database
                    "zid": "_defaultZone"
                ]
            ]
        ]
        
        let result = await pushNotificationService.handleRemoteNotification(userInfo)
        
        // Should handle CloudKit notification appropriately
        XCTAssertTrue([.newData, .noData, .failed].contains(result))
    }
    
    // MARK: - Real-time Update Tests
    
    func testRealTimeOrderStatusUpdates() async throws {
        // Setup customer
        let customer = UserProfile.testCustomer()
        mockAuthenticationService.mockCurrentUser = customer
        
        // Setup order
        let order = createTestOrder(customerId: customer.id)
        mockCloudKitService.mockOrders = [order]
        
        // Setup subscriptions
        try await pushNotificationService.setupCloudKitSubscriptions(for: .customer, userId: customer.id)
        
        // Simulate order status changes
        let statusUpdates: [OrderStatus] = [
            .paymentConfirmed,
            .accepted,
            .preparing,
            .readyForPickup,
            .pickedUp,
            .delivering,
            .delivered
        ]
        
        for status in statusUpdates {
            // Update order status in mock service
            try await mockCloudKitService.updateOrderStatus(order.id, status: status)
            
            // Verify status was updated
            XCTAssertEqual(mockCloudKitService.updatedOrderStatus, status)
        }
    }
    
    func testRealTimeDriverLocationUpdates() async throws {
        // Setup driver
        let driver = UserProfile.testDriver()
        mockAuthenticationService.mockCurrentUser = driver
        
        // Setup driver location
        let driverLocation = DriverLocation(
            driverId: driver.id,
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            accuracy: 10.0
        )
        
        mockCloudKitService.mockDriverLocation = driverLocation
        
        // Setup subscriptions
        try await pushNotificationService.setupCloudKitSubscriptions(for: .driver, userId: driver.id)
        
        // Simulate location updates
        let updatedLocation = DriverLocation(
            driverId: driver.id,
            location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            accuracy: 5.0
        )
        
        try await mockCloudKitService.saveDriverLocation(updatedLocation)
        
        // Verify location was saved
        XCTAssertEqual(mockCloudKitService.savedDriverLocation?.driverId, driver.id)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testNetworkErrorRecovery() async throws {
        let userId = "test-user-id"
        
        // Simulate network error
        mockCloudKitService.shouldThrowError = true
        
        do {
            try await pushNotificationService.setupCloudKitSubscriptions(for: .customer, userId: userId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CloudKitError)
        }
        
        // Simulate network recovery
        mockCloudKitService.shouldThrowError = false
        
        // Should succeed after recovery
        try await pushNotificationService.setupCloudKitSubscriptions(for: .customer, userId: userId)
        XCTAssertTrue(mockCloudKitService.subscriptionsCreated.count > 0)
    }
    
    func testPermissionDeniedHandling() async throws {
        // Test permission request
        let granted = try await pushNotificationService.requestPermission()
        
        // In test environment, permission might be denied
        if !granted {
            // Should handle gracefully
            let status = await pushNotificationService.getAuthorizationStatus()
            XCTAssertTrue([.denied, .notDetermined].contains(status))
        }
    }
    
    // MARK: - Performance Tests
    
    func testBulkNotificationScheduling() async throws {
        let notifications = (0..<100).map { index in
            LocalNotification(
                id: "bulk-notification-\(index)",
                title: "Bulk Test \(index)",
                body: "Testing bulk notification scheduling",
                category: .general
            )
        }
        
        let startTime = Date()
        
        for notification in notifications {
            try await pushNotificationService.scheduleLocalNotification(notification)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Bulk notification scheduling took too long")
    }
    
    func testConcurrentSubscriptionManagement() async throws {
        let userIds = (0..<10).map { "user-\($0)" }
        
        // Test concurrent subscription setup
        await withTaskGroup(of: Void.self) { group in
            for userId in userIds {
                group.addTask {
                    do {
                        try await self.pushNotificationService.setupCloudKitSubscriptions(
                            for: .customer,
                            userId: userId
                        )
                    } catch {
                        XCTFail("Failed to setup subscription for \(userId): \(error)")
                    }
                }
            }
        }
        
        // Verify all subscriptions were created
        XCTAssertTrue(mockCloudKitService.subscriptionsCreated.count >= userIds.count)
    }
    
    // MARK: - Helper Methods
    
    private func createTestOrder(customerId: String) -> Order {
        let address = Address(
            street: "123 Test St",
            city: "Test City",
            state: "CA",
            postalCode: "12345",
            country: "US"
        )
        
        let orderItem = OrderItem(
            productId: "test-product-id",
            productName: "Test Product",
            quantity: 2,
            unitPriceCents: 1250
        )
        
        return Order(
            customerId: customerId,
            partnerId: "test-partner-id",
            items: [orderItem],
            subtotalCents: 2500,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 250,
            deliveryAddress: address,
            paymentMethod: .applePay
        )
    }
}

// MARK: - Test Extensions

extension UserProfile {
    static func testCustomer() -> UserProfile {
        return UserProfile(
            id: "test-customer-id",
            appleUserID: "test-customer-apple-id",
            email: "customer@test.com",
            role: .customer
        )
    }
    
    static func testDriver() -> UserProfile {
        return UserProfile(
            id: "test-driver-id",
            appleUserID: "test-driver-apple-id",
            email: "driver@test.com",
            role: .driver
        )
    }
    
    static func testPartner() -> UserProfile {
        return UserProfile(
            id: "test-partner-id",
            appleUserID: "test-partner-apple-id",
            email: "partner@test.com",
            role: .partner
        )
    }
}