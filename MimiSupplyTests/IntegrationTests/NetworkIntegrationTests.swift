//
//  NetworkIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Alex on 15.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

class NetworkIntegrationTests: MimiSupplyTestCase {
    
    var networkService: NetworkService!
    var realNetworkService: NetworkService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use real network service for integration tests
        realNetworkService = NetworkService()
        
        // Also keep mock for comparison tests
        networkService = NetworkService()
        // Configure with test environment
        networkService.configure(baseURL: "https://api-test.mimisupply.com")
    }
    
    // MARK: - Authentication Integration Tests
    
    func testAuthenticationFlow() async throws {
        // Given
        let authService = AuthService(networkService: networkService)
        let testCredentials = TestCredentials.valid
        
        // When - Login
        let loginResponse = try await authService.login(
            email: testCredentials.email,
            password: testCredentials.password
        )
        
        // Then
        XCTAssertFalse(loginResponse.token.isEmpty, "Should receive valid token")
        XCTAssertEqual(loginResponse.user.email, testCredentials.email)
        XCTAssertNotNil(loginResponse.expiresAt)
        
        // When - Use token for authenticated request
        networkService.setAuthToken(loginResponse.token)
        let userProfile = try await networkService.request(
            APIEndpoint.getProfile,
            type: User.self
        )
        
        // Then
        XCTAssertEqual(userProfile.email, testCredentials.email)
        
        // When - Refresh token
        let refreshResponse = try await authService.refreshToken(loginResponse.refreshToken)
        
        // Then
        XCTAssertFalse(refreshResponse.token.isEmpty)
        XCTAssertNotEqual(refreshResponse.token, loginResponse.token, "Should receive new token")
        
        // When - Logout
        try await authService.logout()
        
        // Then - Subsequent authenticated requests should fail
        await assertThrowsError({
            try await networkService.request(APIEndpoint.getProfile, type: User.self)
        }, NetworkError.self)
    }
    
    func testInvalidAuthenticationHandling() async throws {
        // Given
        let authService = AuthService(networkService: networkService)
        
        // When & Then - Test invalid credentials
        await assertThrowsError({
            try await authService.login(
                email: "invalid@example.com",
                password: "wrongpassword"
            )
        }, AuthError.self)
        
        // Test expired token handling
        networkService.setAuthToken("expired.token.here")
        await assertThrowsError({
            try await networkService.request(APIEndpoint.getProfile, type: User.self)
        }, NetworkError.self)
    }
    
    // MARK: - Data Synchronization Tests
    
    func testOrderSynchronization() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        let localOrder = createTestOrder()
        
        // When - Create order locally and sync
        let createdOrder = try await orderService.createOrder(localOrder)
        
        // Then
        XCTAssertNotNil(createdOrder.id)
        XCTAssertEqual(createdOrder.total, localOrder.total)
        
        // When - Fetch order from server
        let fetchedOrder = try await orderService.getOrder(id: createdOrder.id)
        
        // Then
        XCTAssertEqual(fetchedOrder.id, createdOrder.id)
        XCTAssertEqual(fetchedOrder.status, createdOrder.status)
        
        // When - Update order status
        let updatedOrder = try await orderService.updateOrderStatus(
            id: createdOrder.id,
            status: .confirmed
        )
        
        // Then
        XCTAssertEqual(updatedOrder.status, .confirmed)
        
        // When - Delete order
        try await orderService.deleteOrder(id: createdOrder.id)
        
        // Then - Order should no longer exist
        await assertThrowsError({
            try await orderService.getOrder(id: createdOrder.id)
        }, NetworkError.self)
    }
    
    func testBatchDataSync() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        let orders = [
            createTestOrder(),
            createTestOrder(),
            createTestOrder()
        ]
        
        // When - Create multiple orders
        let createdOrders = try await orderService.batchCreateOrders(orders)
        
        // Then
        XCTAssertEqual(createdOrders.count, orders.count)
        for order in createdOrders {
            XCTAssertNotNil(order.id)
        }
        
        // When - Batch update
        let updates = createdOrders.map { order in
            OrderStatusUpdate(id: order.id, status: .confirmed)
        }
        let updatedOrders = try await orderService.batchUpdateOrderStatus(updates)
        
        // Then
        XCTAssertEqual(updatedOrders.count, createdOrders.count)
        for order in updatedOrders {
            XCTAssertEqual(order.status, .confirmed)
        }
        
        // Cleanup
        for order in createdOrders {
            try? await orderService.deleteOrder(id: order.id)
        }
    }
    
    // MARK: - Real-time Updates Tests
    
    func testWebSocketConnection() async throws {
        // Given
        let webSocketService = WebSocketService()
        let connectionExpectation = expectation(description: "WebSocket connected")
        let messageExpectation = expectation(description: "Message received")
        
        var receivedMessage: WebSocketMessage?
        
        // When
        try await webSocketService.connect(to: "wss://ws-test.mimisupply.com")
        
        webSocketService.onConnectionStatusChanged = { status in
            if status == .connected {
                connectionExpectation.fulfill()
            }
        }
        
        webSocketService.onMessageReceived = { message in
            receivedMessage = message
            messageExpectation.fulfill()
        }
        
        await fulfillment(of: [connectionExpectation], timeout: 10.0)
        
        // Send test message
        try await webSocketService.send(WebSocketMessage(
            type: .orderUpdate,
            payload: ["orderId": "test-order-123"]
        ))
        
        await fulfillment(of: [messageExpectation], timeout: 5.0)
        
        // Then
        XCTAssertNotNil(receivedMessage)
        XCTAssertEqual(receivedMessage?.type, .orderUpdate)
        
        // Cleanup
        await webSocketService.disconnect()
    }
    
    func testPushNotificationHandling() async throws {
        // Given
        let pushService = PushNotificationService()
        let notificationExpectation = expectation(description: "Notification received")
        
        var receivedNotification: PushNotification?
        
        // When
        pushService.onNotificationReceived = { notification in
            receivedNotification = notification
            notificationExpectation.fulfill()
        }
        
        // Simulate push notification
        let testNotification = PushNotification(
            id: "test-notification",
            title: "Order Update",
            body: "Your order has been shipped",
            data: ["orderId": "test-order-123"]
        )
        
        pushService.simulateNotification(testNotification)
        
        await fulfillment(of: [notificationExpectation], timeout: 5.0)
        
        // Then
        XCTAssertNotNil(receivedNotification)
        XCTAssertEqual(receivedNotification?.id, testNotification.id)
        XCTAssertEqual(receivedNotification?.title, testNotification.title)
    }
    
    // MARK: - Error Recovery Tests
    
    func testNetworkErrorRecovery() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        
        // Simulate network unavailable
        networkService.simulateNetworkUnavailable()
        
        // When - Attempt operation during network outage
        await assertThrowsError({
            try await orderService.getOrders()
        }, NetworkError.self)
        
        // When - Network recovers
        networkService.simulateNetworkRecovery()
        
        // Then - Operations should work again
        let orders = try await orderService.getOrders()
        XCTAssertNotNil(orders)
    }
    
    func testRetryMechanism() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        networkService.enableRetryTesting()
        
        var attemptCount = 0
        networkService.onRequestAttempt = { attemptCount += 1 }
        
        // Configure to fail first 2 attempts, succeed on 3rd
        networkService.configureFailurePattern([true, true, false])
        
        // When
        let orders = try await orderService.getOrders()
        
        // Then
        XCTAssertNotNil(orders)
        XCTAssertEqual(attemptCount, 3, "Should have retried 3 times")
    }
    
    // MARK: - Performance Integration Tests
    
    func testConcurrentRequestsPerformance() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        let requestCount = 10
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let orders = try await withThrowingTaskGroup(of: [Order].self) { group in
            for _ in 0..<requestCount {
                group.addTask {
                    try await orderService.getOrders()
                }
            }
            
            var allOrders: [[Order]] = []
            for try await orders in group {
                allOrders.append(orders)
            }
            return allOrders
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Then
        XCTAssertEqual(orders.count, requestCount)
        XCTAssertLessThan(totalTime, 10.0, "Concurrent requests should complete within 10 seconds")
        
        print("Completed \(requestCount) concurrent requests in \(totalTime) seconds")
    }
    
    func testLargeDataSetHandling() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        
        // When - Request large dataset
        let largeOrderSet = try await orderService.getOrdersInDateRange(
            from: Calendar.current.date(byAdding: .year, value: -1, to: Date())!,
            to: Date()
        )
        
        // Then
        XCTAssertNotNil(largeOrderSet)
        // Should handle large datasets without memory issues
        print("Retrieved \(largeOrderSet.count) orders successfully")
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossRequests() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        let testOrder = createTestOrder()
        
        // When - Create order
        let createdOrder = try await orderService.createOrder(testOrder)
        
        // Then - Verify consistency across different endpoints
        let fetchedOrderById = try await orderService.getOrder(id: createdOrder.id)
        let allOrders = try await orderService.getOrders()
        let foundInList = allOrders.first { $0.id == createdOrder.id }
        
        XCTAssertEqual(fetchedOrderById.id, createdOrder.id)
        XCTAssertNotNil(foundInList)
        XCTAssertEqual(foundInList?.total, createdOrder.total)
        
        // Cleanup
        try await orderService.deleteOrder(id: createdOrder.id)
    }
    
    // MARK: - Cache Integration Tests
    
    func testCacheConsistency() async throws {
        // Given
        let orderService = OrderService(networkService: networkService)
        let cacheService = CacheService.shared
        
        // When - First request (should hit network)
        let firstResponse = try await orderService.getOrders()
        
        // Then - Should be cached
        let cachedOrders = cacheService.getCachedOrders()
        XCTAssertNotNil(cachedOrders)
        XCTAssertEqual(cachedOrders?.count, firstResponse.count)
        
        // When - Second request (should hit cache)
        let startTime = CFAbsoluteTimeGetCurrent()
        let secondResponse = try await orderService.getOrders(forceRefresh: false)
        let cacheTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then - Should be fast (from cache) and consistent
        XCTAssertLessThan(cacheTime, 0.1, "Cache response should be very fast")
        XCTAssertEqual(secondResponse.count, firstResponse.count)
        
        // When - Force refresh
        let refreshedResponse = try await orderService.getOrders(forceRefresh: true)
        
        // Then - Should update cache
        XCTAssertNotNil(refreshedResponse)
    }
}

// MARK: - Test Data

struct TestCredentials {
    static let valid = TestCredentials(
        email: "test@mimisupply.com",
        password: "TestPassword123!"
    )
    
    let email: String
    let password: String
}

struct OrderStatusUpdate {
    let id: String
    let status: OrderStatus
}

// MARK: - Test Extensions

extension NetworkService {
    func simulateNetworkUnavailable() {
        // Implementation would set internal state to simulate network unavailable
    }
    
    func simulateNetworkRecovery() {
        // Implementation would reset network state
    }
    
    func enableRetryTesting() {
        // Implementation would enable retry mechanism testing
    }
    
    func configureFailurePattern(_ failures: [Bool]) {
        // Implementation would set up failure pattern for testing
    }
    
    var onRequestAttempt: (() -> Void)? {
        get { nil }
        set { }
    }
}

extension WebSocketService {
    enum ConnectionStatus {
        case connecting, connected, disconnected, error
    }
    
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)? {
        get { nil }
        set { }
    }
    
    var onMessageReceived: ((WebSocketMessage) -> Void)? {
        get { nil }
        set { }
    }
}

struct WebSocketMessage {
    enum MessageType {
        case orderUpdate, notification, heartbeat
    }
    
    let type: MessageType
    let payload: [String: Any]
}

struct PushNotification {
    let id: String
    let title: String
    let body: String
    let data: [String: Any]
}

extension PushNotificationService {
    var onNotificationReceived: ((PushNotification) -> Void)? {
        get { nil }
        set { }
    }
    
    func simulateNotification(_ notification: PushNotification) {
        onNotificationReceived?(notification)
    }
}