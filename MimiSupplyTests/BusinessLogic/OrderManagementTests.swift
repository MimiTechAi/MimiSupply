//
//  OrderManagementTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import MapKit
@testable import MimiSupply

/// Unit tests for order management business logic
final class OrderManagementTests: XCTestCase {
    
    var orderManager: OrderManager!
    var mockOrderRepository: MockOrderRepository!
    var mockDriverService: MockDriverService!
    var mockPaymentService: MockPaymentService!
    var mockNotificationService: MockPushNotificationService!
    
    override func setUp() {
        super.setUp()
        mockOrderRepository = MockOrderRepository()
        mockDriverService = MockDriverService()
        mockPaymentService = MockPaymentService()
        mockNotificationService = MockPushNotificationService()
        
        orderManager = OrderManager(
            orderRepository: mockOrderRepository,
            driverService: mockDriverService,
            paymentService: mockPaymentService,
            notificationService: mockNotificationService
        )
    }
    
    override func tearDown() {
        orderManager = nil
        mockNotificationService = nil
        mockPaymentService = nil
        mockDriverService = nil
        mockOrderRepository = nil
        super.tearDown()
    }
    
    // MARK: - Order Creation Tests
    
    func testCreateOrderSuccess() async throws {
        // Given
        let order = createTestOrder()
        mockPaymentService.shouldSucceed = true
        mockDriverService.mockAvailableDrivers = [createTestDriver()]
        
        // When
        let createdOrder = try await orderManager.createOrder(order)
        
        // Then
        XCTAssertEqual(createdOrder.status, .paymentProcessing)
        XCTAssertTrue(mockOrderRepository.createOrderCalled)
        XCTAssertTrue(mockPaymentService.processPaymentCalled)
    }    

    func testCreateOrderPaymentFailure() async throws {
        // Given
        let order = createTestOrder()
        mockPaymentService.shouldSucceed = false
        mockPaymentService.shouldThrowError = .paymentFailed
        
        // When/Then
        do {
            _ = try await orderManager.createOrder(order)
            XCTFail("Should have thrown payment error")
        } catch {
            XCTAssertTrue(error is AppError)
            if case .payment(let paymentError) = error as? AppError {
                XCTAssertEqual(paymentError, .paymentFailed)
            }
        }
    }
    
    func testCreateOrderNoAvailableDrivers() async throws {
        // Given
        let order = createTestOrder()
        mockPaymentService.shouldSucceed = true
        mockDriverService.mockAvailableDrivers = []
        
        // When
        let createdOrder = try await orderManager.createOrder(order)
        
        // Then
        XCTAssertEqual(createdOrder.status, .paymentConfirmed)
        XCTAssertNil(createdOrder.driverId)
    }
    
    // MARK: - Order Status Update Tests
    
    func testUpdateOrderStatusSuccess() async throws {
        // Given
        let orderId = "test-order-123"
        let newStatus = OrderStatus.preparing
        
        // When
        try await orderManager.updateOrderStatus(orderId, to: newStatus)
        
        // Then
        XCTAssertTrue(mockOrderRepository.updateOrderStatusCalled)
        XCTAssertEqual(mockOrderRepository.lastUpdatedOrderId, orderId)
        XCTAssertEqual(mockOrderRepository.lastUpdatedOrderStatus, newStatus)
    }
    
    func testUpdateOrderStatusWithNotification() async throws {
        // Given
        let orderId = "test-order-123"
        let order = createTestOrder(id: orderId)
        mockOrderRepository.mockOrders = [order]
        
        // When
        try await orderManager.updateOrderStatus(orderId, to: .preparing)
        
        // Then
        XCTAssertTrue(mockNotificationService.sendNotificationCalled)
    }
    
    // MARK: - Driver Assignment Tests
    
    func testAssignDriverToOrder() async throws {
        // Given
        let orderId = "test-order-123"
        let driverId = "test-driver-456"
        let driver = createTestDriver(id: driverId)
        mockDriverService.mockAvailableDrivers = [driver]
        
        // When
        try await orderManager.assignDriver(driverId, to: orderId)
        
        // Then
        XCTAssertTrue(mockOrderRepository.assignDriverCalled)
        XCTAssertEqual(mockOrderRepository.lastAssignedDriverId, driverId)
        XCTAssertEqual(mockOrderRepository.lastAssignedOrderId, orderId)
    }
    
    func testAutoAssignNearestDriver() async throws {
        // Given
        let order = createTestOrder()
        let nearDriver = createTestDriver(
            id: "near-driver",
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        let farDriver = createTestDriver(
            id: "far-driver", 
            location: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )
        mockDriverService.mockAvailableDrivers = [farDriver, nearDriver]
        
        // When
        let assignedDriver = try await orderManager.findNearestAvailableDriver(for: order)
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "near-driver")
    }
    
    // MARK: - Order Cancellation Tests
    
    func testCancelOrderSuccess() async throws {
        // Given
        let orderId = "test-order-123"
        let order = createTestOrder(id: orderId, status: .created)
        mockOrderRepository.mockOrders = [order]
        
        // When
        try await orderManager.cancelOrder(orderId)
        
        // Then
        XCTAssertTrue(mockOrderRepository.updateOrderStatusCalled)
        XCTAssertEqual(mockOrderRepository.lastUpdatedOrderStatus, .cancelled)
        XCTAssertTrue(mockPaymentService.refundPaymentCalled)
    }
    
    func testCancelOrderAlreadyInProgress() async throws {
        // Given
        let orderId = "test-order-123"
        let order = createTestOrder(id: orderId, status: .delivering)
        mockOrderRepository.mockOrders = [order]
        
        // When/Then
        do {
            try await orderManager.cancelOrder(orderId)
            XCTFail("Should not allow cancellation of order in progress")
        } catch {
            XCTAssertTrue(error is OrderError)
        }
    }
    
    // MARK: - Order Tracking Tests
    
    func testGetOrderTrackingInfo() async throws {
        // Given
        let orderId = "test-order-123"
        let order = createTestOrder(id: orderId, status: .delivering)
        mockOrderRepository.mockOrders = [order]
        
        // When
        let trackingInfo = try await orderManager.getOrderTrackingInfo(orderId)
        
        // Then
        XCTAssertEqual(trackingInfo.orderId, orderId)
        XCTAssertEqual(trackingInfo.status, .delivering)
        XCTAssertNotNil(trackingInfo.estimatedDeliveryTime)
    }
    
    // MARK: - Helper Methods
    
    private func createTestOrder(
        id: String = "test-order-123",
        status: OrderStatus = .created
    ) -> Order {
        return Order(
            id: id,
            customerId: "customer-123",
            partnerId: "partner-456",
            driverId: nil,
            items: [createTestOrderItem()],
            status: status,
            subtotalCents: 1500,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 150,
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
    
    private func createTestOrderItem() -> OrderItem {
        return OrderItem(
            id: "item-123",
            productId: "product-456",
            productName: "Test Product",
            quantity: 2,
            unitPriceCents: 750,
            totalPriceCents: 1500,
            specialInstructions: nil
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
    
    private func createTestDriver(
        id: String = "driver-123",
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    ) -> Driver {
        return Driver(
            id: id,
            userId: "user-\(id)",
            vehicleType: .car,
            licensePlate: "ABC123",
            isOnline: true,
            isAvailable: true,
            currentLocation: location,
            rating: 4.8,
            completedDeliveries: 150,
            verificationStatus: .verified,
            createdAt: Date()
        )
    }
}

// MARK: - Mock Driver Service

class MockDriverService: DriverService {
    var mockAvailableDrivers: [Driver] = []
    var mockDriverLocation: DriverLocation?
    var shouldThrowError = false
    
    var findAvailableDriversCalled = false
    var updateDriverLocationCalled = false
    var updateDriverStatusCalled = false
    
    func findAvailableDrivers(near location: CLLocationCoordinate2D, radius: Double) async throws -> [Driver] {
        findAvailableDriversCalled = true
        if shouldThrowError {
            throw AppError.network(.noConnection)
        }
        return mockAvailableDrivers
    }
    
    func updateDriverLocation(_ location: DriverLocation) async throws {
        updateDriverLocationCalled = true
        if shouldThrowError {
            throw AppError.network(.noConnection)
        }
        mockDriverLocation = location
    }
    
    func updateDriverStatus(_ driverId: String, isOnline: Bool, isAvailable: Bool) async throws {
        updateDriverStatusCalled = true
        if shouldThrowError {
            throw AppError.network(.noConnection)
        }
    }
    
    func getDriverLocation(_ driverId: String) async throws -> DriverLocation? {
        if shouldThrowError {
            throw AppError.network(.noConnection)
        }
        return mockDriverLocation
    }
}

// MARK: - Mock Push Notification Service

class MockPushNotificationService: PushNotificationService {
    var sendNotificationCalled = false
    var lastNotificationUserId: String?
    var lastNotificationMessage: String?
    var shouldThrowError = false
    
    func requestPermission() async throws -> Bool {
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "Test", code: 1))
        }
        return true
    }
    
    func registerForRemoteNotifications() async throws {
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "Test", code: 1))
        }
    }
    
    func sendNotification(to userId: String, title: String, body: String, data: [String: Any]?) async throws {
        sendNotificationCalled = true
        lastNotificationUserId = userId
        lastNotificationMessage = body
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "Test", code: 1))
        }
    }
    
    func handleNotification(_ notification: UNNotification) async {
        // Mock implementation
    }
}

// MARK: - Order Error Types

enum OrderError: Error, LocalizedError {
    case cannotCancelOrderInProgress
    case orderNotFound
    case invalidOrderStatus
    case driverNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .cannotCancelOrderInProgress:
            return "Cannot cancel order that is already in progress"
        case .orderNotFound:
            return "Order not found"
        case .invalidOrderStatus:
            return "Invalid order status"
        case .driverNotAvailable:
            return "Driver is not available"
        }
    }
}

// MARK: - Order Tracking Info

struct OrderTrackingInfo {
    let orderId: String
    let status: OrderStatus
    let estimatedDeliveryTime: Date?
    let driverLocation: CLLocationCoordinate2D?
    let driverName: String?
    let driverPhone: String?
}