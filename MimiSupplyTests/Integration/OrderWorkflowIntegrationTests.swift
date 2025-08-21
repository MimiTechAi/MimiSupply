//
//  OrderWorkflowIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import MapKit
@testable import MimiSupply

/// Integration tests for complete order workflows
final class OrderWorkflowIntegrationTests: XCTestCase {
    
    var orderManager: OrderManager!
    var cartService: CartService!
    var paymentService: PaymentService!
    var driverService: DriverService!
    var notificationService: PushNotificationService!
    var cloudKitService: CloudKitService!
    
    override func setUp() {
        super.setUp()
        
        // Use mock services for integration testing
        cloudKitService = MockCloudKitService()
        paymentService = MockPaymentService()
        driverService = MockDriverService()
        notificationService = MockPushNotificationService()
        
        cartService = CartService(
            coreDataStack: MockCartCoreDataStack(),
            cloudKitService: cloudKitService
        )
        
        orderManager = OrderManager(
            orderRepository: MockOrderRepository(),
            driverService: driverService,
            paymentService: paymentService,
            notificationService: notificationService
        )
    }
    
    override func tearDown() {
        orderManager = nil
        cartService = nil
        paymentService = nil
        driverService = nil
        notificationService = nil
        cloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - Complete Order Flow Tests
    
    func testCompleteCustomerOrderFlow() async throws {
        // Given - Customer has items in cart
        let cartItems = [
            createTestCartItem(productId: "product-1", quantity: 2, price: 1200),
            createTestCartItem(productId: "product-2", quantity: 1, price: 800)
        ]
        
        for item in cartItems {
            try await cartService.addItem(item)
        }
        
        // Setup mock services
        let mockPayment = paymentService as! MockPaymentService
        mockPayment.shouldSucceed = true
        
        let mockDriver = driverService as! MockDriverService
        mockDriver.mockAvailableDrivers = [createTestDriver()]
        
        // When - Customer proceeds through checkout
        let order = try await createOrderFromCart()
        let createdOrder = try await orderManager.createOrder(order)
        
        // Then - Order should be created and payment processed
        XCTAssertEqual(createdOrder.status, .paymentProcessing)
        XCTAssertTrue(mockPayment.processPaymentCalled)
        
        // And driver should be assigned
        XCTAssertNotNil(createdOrder.driverId)
        
        // And notifications should be sent
        let mockNotification = notificationService as! MockPushNotificationService
        XCTAssertTrue(mockNotification.sendNotificationCalled)
    }   
 
    func testDriverWorkflowIntegration() async throws {
        // Given - Order is created and assigned to driver
        let order = createTestOrder(status: .paymentConfirmed)
        let driver = createTestDriver()
        
        let mockOrderRepo = MockOrderRepository()
        mockOrderRepo.mockOrders = [order]
        
        // When - Driver accepts order
        try await orderManager.assignDriver(driver.id, to: order.id)
        
        // Then - Order status should be updated
        XCTAssertTrue(mockOrderRepo.assignDriverCalled)
        
        // When - Driver picks up order
        try await orderManager.updateOrderStatus(order.id, to: .pickedUp)
        
        // Then - Customer should be notified
        let mockNotification = notificationService as! MockPushNotificationService
        XCTAssertTrue(mockNotification.sendNotificationCalled)
        
        // When - Driver delivers order
        try await orderManager.updateOrderStatus(order.id, to: .delivered)
        
        // Then - Order should be completed
        XCTAssertEqual(mockOrderRepo.lastUpdatedOrderStatus, .delivered)
    }
    
    func testPartnerWorkflowIntegration() async throws {
        // Given - Order is placed at partner
        let order = createTestOrder(status: .paymentConfirmed)
        
        let mockOrderRepo = MockOrderRepository()
        mockOrderRepo.mockOrders = [order]
        
        // When - Partner accepts order
        try await orderManager.updateOrderStatus(order.id, to: .accepted)
        
        // Then - Order status should be updated
        XCTAssertEqual(mockOrderRepo.lastUpdatedOrderStatus, .accepted)
        
        // When - Partner starts preparing
        try await orderManager.updateOrderStatus(order.id, to: .preparing)
        
        // Then - Driver should be notified
        let mockNotification = notificationService as! MockPushNotificationService
        XCTAssertTrue(mockNotification.sendNotificationCalled)
        
        // When - Order is ready for pickup
        try await orderManager.updateOrderStatus(order.id, to: .readyForPickup)
        
        // Then - Driver should be notified again
        XCTAssertTrue(mockNotification.sendNotificationCalled)
    }
    
    // MARK: - Error Recovery Tests
    
    func testPaymentFailureRecovery() async throws {
        // Given - Payment service will fail
        let mockPayment = paymentService as! MockPaymentService
        mockPayment.shouldSucceed = false
        mockPayment.shouldThrowError = .paymentFailed
        
        let order = createTestOrder()
        
        // When - Attempting to create order
        do {
            _ = try await orderManager.createOrder(order)
            XCTFail("Should have thrown payment error")
        } catch {
            // Then - Error should be handled gracefully
            XCTAssertTrue(error is AppError)
        }
        
        // When - Payment is retried successfully
        mockPayment.shouldSucceed = true
        mockPayment.shouldThrowError = nil
        
        let retryOrder = try await orderManager.createOrder(order)
        
        // Then - Order should be created successfully
        XCTAssertEqual(retryOrder.status, .paymentProcessing)
    }
    
    func testDriverUnavailableRecovery() async throws {
        // Given - No drivers available initially
        let mockDriver = driverService as! MockDriverService
        mockDriver.mockAvailableDrivers = []
        
        let order = createTestOrder()
        
        // When - Order is created without driver
        let createdOrder = try await orderManager.createOrder(order)
        
        // Then - Order should be created but without driver
        XCTAssertNil(createdOrder.driverId)
        XCTAssertEqual(createdOrder.status, .paymentConfirmed)
        
        // When - Driver becomes available
        mockDriver.mockAvailableDrivers = [createTestDriver()]
        
        // Simulate driver assignment retry
        let availableDriver = try await driverService.findAvailableDrivers(
            near: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 10.0
        ).first
        
        if let driver = availableDriver {
            try await orderManager.assignDriver(driver.id, to: createdOrder.id)
        }
        
        // Then - Driver should be assigned
        XCTAssertNotNil(availableDriver)
    }
    
    // MARK: - Real-time Updates Tests
    
    func testRealTimeOrderStatusUpdates() async throws {
        // Given - Order tracking is active
        let order = createTestOrder(status: .delivering)
        let mockCloudKit = cloudKitService as! MockCloudKitService
        mockCloudKit.mockOrders = [order]
        
        // When - Order status changes
        try await orderManager.updateOrderStatus(order.id, to: .delivered)
        
        // Then - CloudKit should be updated
        XCTAssertEqual(mockCloudKit.updatedOrderStatus, .delivered)
        
        // And subscription should trigger notifications
        XCTAssertTrue(mockCloudKit.subscriptionCreated)
    }
    
    func testDriverLocationUpdates() async throws {
        // Given - Driver is delivering order
        let driver = createTestDriver()
        let driverLocation = DriverLocation(
            driverId: driver.id,
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            heading: 45.0,
            speed: 25.0,
            accuracy: 5.0,
            timestamp: Date()
        )
        
        // When - Driver location is updated
        try await driverService.updateDriverLocation(driverLocation)
        
        // Then - Location should be saved to CloudKit
        let mockCloudKit = cloudKitService as! MockCloudKitService
        XCTAssertEqual(mockCloudKit.savedDriverLocation?.driverId, driver.id)
    }
    
    // MARK: - Multi-Order Scenarios
    
    func testConcurrentOrderProcessing() async throws {
        // Given - Multiple orders being processed simultaneously
        let orders = [
            createTestOrder(id: "order-1"),
            createTestOrder(id: "order-2"),
            createTestOrder(id: "order-3")
        ]
        
        let mockPayment = paymentService as! MockPaymentService
        mockPayment.shouldSucceed = true
        
        let mockDriver = driverService as! MockDriverService
        mockDriver.mockAvailableDrivers = [
            createTestDriver(id: "driver-1"),
            createTestDriver(id: "driver-2"),
            createTestDriver(id: "driver-3")
        ]
        
        // When - Processing orders concurrently
        let results = try await withThrowingTaskGroup(of: Order.self) { group in
            for order in orders {
                group.addTask {
                    return try await self.orderManager.createOrder(order)
                }
            }
            
            var processedOrders: [Order] = []
            for try await result in group {
                processedOrders.append(result)
            }
            return processedOrders
        }
        
        // Then - All orders should be processed successfully
        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.status == .paymentProcessing })
    }
    
    // MARK: - Data Consistency Tests
    
    func testOrderDataConsistency() async throws {
        // Given - Order with specific data
        let originalOrder = createTestOrder()
        
        // When - Order is created and updated multiple times
        let createdOrder = try await orderManager.createOrder(originalOrder)
        try await orderManager.updateOrderStatus(createdOrder.id, to: .accepted)
        try await orderManager.updateOrderStatus(createdOrder.id, to: .preparing)
        
        // Then - Order data should remain consistent
        let mockCloudKit = cloudKitService as! MockCloudKitService
        XCTAssertEqual(mockCloudKit.updatedOrderId, createdOrder.id)
        XCTAssertEqual(mockCloudKit.updatedOrderStatus, .preparing)
        
        // And original order data should be preserved
        XCTAssertEqual(createdOrder.customerId, originalOrder.customerId)
        XCTAssertEqual(createdOrder.partnerId, originalOrder.partnerId)
        XCTAssertEqual(createdOrder.items.count, originalOrder.items.count)
    }
    
    // MARK: - Helper Methods
    
    private func createOrderFromCart() async throws -> Order {
        let cartItems = try await cartService.getCartItems()
        let subtotal = cartItems.reduce(0) { $0 + $1.totalPrice }
        
        return Order(
            id: UUID().uuidString,
            customerId: "customer-123",
            partnerId: "partner-456",
            driverId: nil,
            items: cartItems.map { cartItem in
                OrderItem(
                    id: UUID().uuidString,
                    productId: cartItem.productId,
                    productName: cartItem.productName,
                    quantity: cartItem.quantity,
                    unitPriceCents: cartItem.unitPrice,
                    totalPriceCents: cartItem.totalPrice,
                    specialInstructions: cartItem.specialInstructions
                )
            },
            status: .created,
            subtotalCents: subtotal,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: Int(Double(subtotal) * 0.08),
            tipCents: 300,
            deliveryAddress: createTestAddress(),
            deliveryInstructions: "Leave at door",
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            actualDeliveryTime: nil,
            paymentMethod: .applePay,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestCartItem(
        productId: String,
        quantity: Int,
        price: Int
    ) -> CartItem {
        return CartItem(
            id: UUID().uuidString,
            productId: productId,
            productName: "Test Product",
            quantity: quantity,
            unitPrice: price,
            totalPrice: price * quantity,
            specialInstructions: nil
        )
    }
    
    private func createTestOrder(
        id: String = UUID().uuidString,
        status: OrderStatus = .created
    ) -> Order {
        return Order(
            id: id,
            customerId: "customer-123",
            partnerId: "partner-456",
            driverId: nil,
            items: [
                OrderItem(
                    id: "item-1",
                    productId: "product-1",
                    productName: "Test Product",
                    quantity: 2,
                    unitPriceCents: 1200,
                    totalPriceCents: 2400,
                    specialInstructions: nil
                )
            ],
            status: status,
            subtotalCents: 2400,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 192,
            tipCents: 300,
            deliveryAddress: createTestAddress(),
            deliveryInstructions: "Leave at door",
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            actualDeliveryTime: nil,
            paymentMethod: .applePay,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestDriver(id: String = "driver-123") -> Driver {
        return Driver(
            id: id,
            userId: "user-\(id)",
            vehicleType: .car,
            licensePlate: "ABC123",
            isOnline: true,
            isAvailable: true,
            currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            rating: 4.8,
            completedDeliveries: 150,
            verificationStatus: .verified,
            createdAt: Date()
        )
    }
    
    private func createTestAddress() -> Address {
        return Address(
            street: "123 Test Street",
            city: "Test City",
            state: "CA",
            postalCode: "12345",
            country: "US"
        )
    }
}