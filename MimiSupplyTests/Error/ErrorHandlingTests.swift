//
//  ErrorHandlingTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import CloudKit
@testable import MimiSupply

@MainActor
final class ErrorHandlingTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    var retryManager: RetryManager!
    var offlineManager: OfflineManager!
    var degradationService: GracefulDegradationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        errorHandler = ErrorHandler.shared
        retryManager = RetryManager.shared
        offlineManager = OfflineManager.shared
        degradationService = GracefulDegradationService.shared
        
        // Reset state
        errorHandler.dismissError()
        degradationService.serviceStatus.removeAll()
    }
    
    override func tearDown() async throws {
        errorHandler = nil
        retryManager = nil
        offlineManager = nil
        degradationService = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Error Handler Tests
    
    func testErrorHandlerConvertsErrorsCorrectly() {
        // Test CKError conversion
        let ckError = CKError(.networkUnavailable)
        errorHandler.handle(ckError, showToUser: false)
        
        XCTAssertTrue(errorHandler.currentError is AppError)
        if case .cloudKit = errorHandler.currentError {
            // Success
        } else {
            XCTFail("CKError should be converted to AppError.cloudKit")
        }
        
        // Test URLError conversion
        let urlError = URLError(.notConnectedToInternet)
        errorHandler.handle(urlError, showToUser: false)
        
        if case .network = errorHandler.currentError {
            // Success
        } else {
            XCTFail("URLError should be converted to AppError.network")
        }
    }
    
    func testErrorHandlerShowsAndDismissesErrors() {
        let error = AppError.validation(.invalidEmail)
        
        // Test showing error
        errorHandler.showError(error)
        XCTAssertTrue(errorHandler.isShowingError)
        XCTAssertEqual(errorHandler.currentError?.localizedDescription, error.localizedDescription)
        
        // Test dismissing error
        errorHandler.dismissError()
        XCTAssertFalse(errorHandler.isShowingError)
        XCTAssertNil(errorHandler.currentError)
    }
    
    // MARK: - Retry Manager Tests
    
    func testRetryManagerSucceedsOnFirstAttempt() async throws {
        var callCount = 0
        
        let result = try await retryManager.retry {
            callCount += 1
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 1)
    }
    
    func testRetryManagerRetriesOnFailure() async throws {
        var callCount = 0
        
        let result = try await retryManager.retry(maxAttempts: 3) {
            callCount += 1
            if callCount < 3 {
                throw AppError.network(.timeout)
            }
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(callCount, 3)
    }
    
    func testRetryManagerFailsAfterMaxAttempts() async {
        var callCount = 0
        
        do {
            _ = try await retryManager.retry(maxAttempts: 2) {
                callCount += 1
                throw AppError.network(.timeout)
            }
            XCTFail("Should have thrown error after max attempts")
        } catch {
            XCTAssertEqual(callCount, 2)
            XCTAssertTrue(error is AppError)
        }
    }
    
    func testRetryManagerDoesNotRetryNonRetryableErrors() async {
        var callCount = 0
        
        do {
            _ = try await retryManager.retry {
                callCount += 1
                throw AppError.validation(.invalidEmail)
            }
            XCTFail("Should have thrown error immediately")
        } catch {
            XCTAssertEqual(callCount, 1)
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Offline Manager Tests
    
    func testOfflineManagerQueuesOperations() {
        let order = createMockOrder()
        let operation = SyncOperation(type: .createOrder, data: order)
        
        offlineManager.queueForSync(operation)
        
        XCTAssertEqual(offlineManager.pendingSyncCount, 1)
    }
    
    func testOfflineManagerClearsQueue() {
        let order = createMockOrder()
        let operation = SyncOperation(type: .createOrder, data: order)
        
        offlineManager.queueForSync(operation)
        XCTAssertEqual(offlineManager.pendingSyncCount, 1)
        
        offlineManager.clearPendingSync()
        XCTAssertEqual(offlineManager.pendingSyncCount, 0)
    }
    
    // MARK: - Graceful Degradation Tests
    
    func testGracefulDegradationReportsServiceFailure() {
        let error = AppError.cloudKit(CKError(.networkUnavailable))
        
        degradationService.reportServiceFailure(.cloudKit, error: error)
        
        XCTAssertFalse(degradationService.isServiceAvailable(.cloudKit))
        XCTAssertNotEqual(degradationService.degradationLevel, .none)
    }
    
    func testGracefulDegradationReportsServiceRecovery() {
        let error = AppError.cloudKit(CKError(.networkUnavailable))
        
        // First report failure
        degradationService.reportServiceFailure(.cloudKit, error: error)
        XCTAssertFalse(degradationService.isServiceAvailable(.cloudKit))
        
        // Then report recovery
        degradationService.reportServiceRecovery(.cloudKit)
        XCTAssertTrue(degradationService.isServiceAvailable(.cloudKit))
    }
    
    func testGracefulDegradationCalculatesDegradationLevel() {
        // Test minor degradation
        degradationService.reportServiceFailure(.analytics, error: AppError.network(.timeout))
        XCTAssertEqual(degradationService.degradationLevel, .minor)
        
        // Test moderate degradation
        degradationService.reportServiceFailure(.location, error: AppError.location(.permissionDenied))
        degradationService.reportServiceFailure(.pushNotifications, error: AppError.network(.noConnection))
        XCTAssertEqual(degradationService.degradationLevel, .moderate)
        
        // Test severe degradation
        degradationService.reportServiceFailure(.cloudKit, error: AppError.cloudKit(CKError(.networkUnavailable)))
        degradationService.reportServiceFailure(.authentication, error: AppError.authentication(.tokenExpired))
        XCTAssertEqual(degradationService.degradationLevel, .severe)
    }
    
    func testGracefulDegradationExecutesWithFallback() async {
        let cacheManager = CacheManager.shared
        let testData = "cached_data"
        let cacheKey = "test_key"
        
        // Cache some data
        cacheManager.cache(testData, forKey: cacheKey)
        
        // Execute operation that fails
        let result = await degradationService.executeWithFallback(
            serviceType: .cloudKit,
            cacheKey: cacheKey
        ) {
            throw AppError.cloudKit(CKError(.networkUnavailable))
        }
        
        // Should return cached data
        switch result {
        case .success(let data):
            XCTAssertEqual(data, testData)
        case .failure:
            XCTFail("Should have returned cached data")
        }
    }
    
    // MARK: - Cache Manager Tests
    
    func testCacheManagerStoresAndRetrievesData() {
        let cacheManager = CacheManager.shared
        let testData = "test_data"
        let key = "test_key"
        
        // Store data
        cacheManager.cache(testData, forKey: key)
        
        // Retrieve data
        let retrievedData: String? = cacheManager.retrieve(String.self, forKey: key)
        XCTAssertEqual(retrievedData, testData)
    }
    
    func testCacheManagerHandlesInvalidData() {
        let cacheManager = CacheManager.shared
        let key = "invalid_key"
        
        // Try to retrieve non-existent data
        let retrievedData: String? = cacheManager.retrieve(String.self, forKey: key)
        XCTAssertNil(retrievedData)
    }
    
    func testCacheManagerClearsCache() {
        let cacheManager = CacheManager.shared
        let testData = "test_data"
        let key = "test_key"
        
        // Store data
        cacheManager.cache(testData, forKey: key)
        XCTAssertNotNil(cacheManager.retrieve(String.self, forKey: key))
        
        // Clear cache
        cacheManager.clearCache()
        XCTAssertNil(cacheManager.retrieve(String.self, forKey: key))
    }
    
    // MARK: - Network Error Recovery Tests
    
    func testNetworkErrorRecoveryWithRetry() async throws {
        var attemptCount = 0
        let maxAttempts = 3
        
        let result = try await retryManager.retry(maxAttempts: maxAttempts) {
            attemptCount += 1
            if attemptCount < maxAttempts {
                throw URLError(.notConnectedToInternet)
            }
            return "success"
        }
        
        XCTAssertEqual(result, "success")
        XCTAssertEqual(attemptCount, maxAttempts)
    }
    
    // MARK: - Error Logging Tests
    
    func testErrorReporterReportsErrors() {
        let errorReporter = ErrorReporter.shared
        let error = AppError.payment(.paymentFailed)
        
        // This test verifies that error reporting doesn't crash
        // In a real implementation, you would mock the reporting service
        XCTAssertNoThrow(errorReporter.report(error, context: "test_context"))
    }
    
    // MARK: - Helper Methods
    
    private func createMockOrder() -> Order {
        return Order(
            id: UUID().uuidString,
            customerId: "customer_123",
            partnerId: "partner_123",
            driverId: nil,
            items: [],
            status: .created,
            subtotalCents: 1000,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 130,
            tipCents: 200,
            totalCents: 1630,
            deliveryAddress: Address(
                street: "123 Test St",
                city: "Test City",
                state: "TS",
                zipCode: "12345",
                country: "US",
                latitude: 0.0,
                longitude: 0.0
            ),
            deliveryInstructions: nil,
            estimatedDeliveryTime: nil,
            actualDeliveryTime: nil,
            paymentMethod: .applePay,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Network Monitor for Testing

final class MockNetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType? = .wifi
    
    func simulateDisconnection() {
        isConnected = false
        connectionType = nil
    }
    
    func simulateConnection(_ type: NWInterface.InterfaceType = .wifi) {
        isConnected = true
        connectionType = type
    }
}

// MARK: - Integration Tests

final class ErrorHandlingIntegrationTests: XCTestCase {
    
    func testEndToEndErrorHandlingFlow() async throws {
        let errorHandler = ErrorHandler.shared
        let degradationService = GracefulDegradationService.shared
        
        // Simulate a CloudKit error
        let ckError = CKError(.networkUnavailable)
        
        // Handle the error
        errorHandler.handle(ckError, showToUser: false)
        
        // Verify error was converted and handled
        XCTAssertNotNil(errorHandler.currentError)
        
        // Verify degradation service was notified
        XCTAssertFalse(degradationService.isServiceAvailable(.cloudKit))
        
        // Simulate recovery
        degradationService.reportServiceRecovery(.cloudKit)
        XCTAssertTrue(degradationService.isServiceAvailable(.cloudKit))
    }
    
    func testOfflineToOnlineTransition() async throws {
        let offlineManager = OfflineManager.shared
        let mockOrder = createMockOrder()
        
        // Queue operation while offline
        let operation = SyncOperation(type: .createOrder, data: mockOrder)
        offlineManager.queueForSync(operation)
        
        XCTAssertEqual(offlineManager.pendingSyncCount, 1)
        
        // Simulate coming back online would trigger sync
        // In a real test, you would mock the network monitor
        // and verify that sync is triggered
    }
    
    private func createMockOrder() -> Order {
        return Order(
            id: UUID().uuidString,
            customerId: "customer_123",
            partnerId: "partner_123",
            driverId: nil,
            items: [],
            status: .created,
            subtotalCents: 1000,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 130,
            tipCents: 200,
            totalCents: 1630,
            deliveryAddress: Address(
                street: "123 Test St",
                city: "Test City",
                state: "TS",
                zipCode: "12345",
                country: "US",
                latitude: 0.0,
                longitude: 0.0
            ),
            deliveryInstructions: nil,
            estimatedDeliveryTime: nil,
            actualDeliveryTime: nil,
            paymentMethod: .applePay,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}