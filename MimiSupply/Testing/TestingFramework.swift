//
//  TestingFramework.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import XCTest
import SwiftUI
import Combine
@testable import MimiSupply

// MARK: - Enhanced Testing Framework

/// Base test case with common utilities and setup
class MimiSupplyTestCase: XCTestCase {
    
    // MARK: - Properties
    var cancellables: Set<AnyCancellable>!
    var mockNetworkService: MockNetworkService!
    var mockAuthService: MockAuthService!
    var mockAnalyticsService: MockAnalyticsService!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        cancellables = Set<AnyCancellable>()
        mockNetworkService = MockNetworkService()
        mockAuthService = MockAuthService()
        mockAnalyticsService = MockAnalyticsService()
        
        // Configure test environment
        configureTestEnvironment()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        mockNetworkService = nil
        mockAuthService = nil
        mockAnalyticsService = nil
        
        // Clean up test environment
        cleanupTestEnvironment()
        
        try super.tearDownWithError()
    }
    
    // MARK: - Test Environment Configuration
    
    private func configureTestEnvironment() {
        // Set test user defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        // Configure mock services
        ServiceContainer.shared.register(mockNetworkService, for: NetworkServiceProtocol.self)
        ServiceContainer.shared.register(mockAuthService, for: AuthServiceProtocol.self)
        ServiceContainer.shared.register(mockAnalyticsService, for: AnalyticsServiceProtocol.self)
    }
    
    private func cleanupTestEnvironment() {
        // Reset singletons
        ServiceContainer.shared.reset()
        
        // Clear test data
        try? FileManager.default.removeItem(at: testDataDirectory)
    }
    
    // MARK: - Test Utilities
    
    /// Create test data directory
    var testDataDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("TestData")
    }
    
    /// Wait for async operation with timeout
    func waitForAsyncOperation<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withTimeout(timeout) {
            try await operation()
        }
    }
    
    /// Assert publisher emits expected values
    func assertPublisher<P: Publisher>(
        _ publisher: P,
        emits expectedValues: [P.Output],
        timeout: TimeInterval = 2.0,
        file: StaticString = #file,
        line: UInt = #line
    ) where P.Output: Equatable {
        let expectation = expectation(description: "Publisher values")
        var receivedValues: [P.Output] = []
        
        publisher
            .sink(
                receiveCompletion: { _ in
                    expectation.fulfill()
                },
                receiveValue: { value in
                    receivedValues.append(value)
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: timeout)
        
        XCTAssertEqual(receivedValues, expectedValues, file: file, line: line)
    }
    
    /// Create test user
    func createTestUser() -> User {
        return User(
            id: "test-user-id",
            email: "test@example.com",
            name: "Test User",
            role: .partner,
            isActive: true,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
    
    /// Create test product
    func createTestProduct() -> Product {
        return Product(
            id: "test-product-id",
            name: "Test Product",
            description: "A test product",
            price: 99.99,
            currency: "USD",
            category: "Test Category",
            isActive: true,
            createdAt: Date()
        )
    }
    
    /// Create test order
    func createTestOrder() -> Order {
        return Order(
            id: "test-order-id",
            userId: "test-user-id",
            items: [createTestOrderItem()],
            total: 99.99,
            currency: "USD",
            status: .pending,
            createdAt: Date()
        )
    }
    
    /// Create test order item
    func createTestOrderItem() -> OrderItem {
        return OrderItem(
            id: "test-item-id",
            productId: "test-product-id",
            quantity: 1,
            price: 99.99,
            currency: "USD"
        )
    }
}

// MARK: - Mock Services

class MockNetworkService: NetworkServiceProtocol {
    var shouldSucceed = true
    var mockData: Data?
    var mockError: Error?
    var requestDelay: TimeInterval = 0.1
    
    func request<T: Codable>(_ endpoint: APIEndpoint, type: T.Type) async throws -> T {
        try await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        
        if let error = mockError {
            throw error
        }
        
        if !shouldSucceed {
            throw NetworkError.serverError(500)
        }
        
        guard let data = mockData else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func upload<T: Codable>(_ endpoint: APIEndpoint, data: Data, type: T.Type) async throws -> T {
        return try await request(endpoint, type: type)
    }
}

class MockAuthService: AuthServiceProtocol {
    var isAuthenticated = false
    var currentUser: User?
    var shouldFailLogin = false
    
    func login(email: String, password: String) async throws -> AuthResponse {
        if shouldFailLogin {
            throw AuthError.invalidCredentials
        }
        
        isAuthenticated = true
        currentUser = User(
            id: "mock-user-id",
            email: email,
            name: "Mock User",
            role: .partner,
            isActive: true,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        return AuthResponse(
            user: currentUser!,
            token: "mock-token",
            refreshToken: "mock-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
    }
    
    func logout() async {
        isAuthenticated = false
        currentUser = nil
    }
    
    func refreshToken() async throws -> AuthResponse {
        guard isAuthenticated else {
            throw AuthError.notAuthenticated
        }
        
        return AuthResponse(
            user: currentUser!,
            token: "new-mock-token",
            refreshToken: "new-mock-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
    }
}

class MockAnalyticsService: AnalyticsServiceProtocol {
    var trackedEvents: [(String, [String: Any])] = []
    var trackedScreens: [String] = []
    var userProperties: [String: Any] = [:]
    
    func track(event: String, parameters: [String: Any]) {
        trackedEvents.append((event, parameters))
    }
    
    func trackScreen(_ screenName: String) {
        trackedScreens.append(screenName)
    }
    
    func setUserProperty(_ key: String, value: Any) {
        userProperties[key] = value
    }
    
    func identify(userId: String) {
        userProperties["user_id"] = userId
    }
    
    // Helper methods for testing
    func hasTrackedEvent(_ eventName: String) -> Bool {
        return trackedEvents.contains { $0.0 == eventName }
    }
    
    func getEventParameters(for eventName: String) -> [String: Any]? {
        return trackedEvents.first { $0.0 == eventName }?.1
    }
}

// MARK: - Test Helpers

extension XCTestCase {
    /// Helper to wait for async operation with timeout
    func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Assert that an async operation throws a specific error
    func assertThrowsError<T>(
        _ operation: @escaping () async throws -> T,
        _ errorType: Error.Type,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected operation to throw \(errorType), but it succeeded", file: file, line: line)
        } catch {
            XCTAssertTrue(type(of: error) == errorType, "Expected \(errorType), got \(type(of: error))", file: file, line: line)
        }
    }
}

// MARK: - Test Errors

enum TestError: Error {
    case timeout
    case mockDataNotSet
    case unexpectedResult
}

// MARK: - Service Container for Testing

class ServiceContainer {
    static let shared = ServiceContainer()
    
    private var services: [String: Any] = [:]
    
    func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }
    
    func reset() {
        services.removeAll()
    }
}

// MARK: - Performance Testing Utilities

class PerformanceTestCase: XCTestCase {
    
    /// Measure time for async operation
    func measureAsync(
        _ operation: @escaping () async throws -> Void,
        iterations: Int = 10
    ) async throws {
        var times: [TimeInterval] = []
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            try await operation()
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            times.append(timeElapsed)
        }
        
        let averageTime = times.reduce(0, +) / Double(times.count)
        let minTime = times.min() ?? 0
        let maxTime = times.max() ?? 0
        
        print("Performance Results:")
        print("Average: \(averageTime * 1000)ms")
        print("Min: \(minTime * 1000)ms")
        print("Max: \(maxTime * 1000)ms")
        
        // Assert performance is within acceptable bounds
        XCTAssertLessThan(averageTime, 1.0, "Operation took too long on average")
        XCTAssertLessThan(maxTime, 2.0, "Operation took too long in worst case")
    }
    
    /// Measure memory usage during operation
    func measureMemory(_ operation: () throws -> Void) rethrows {
        let startMemory = getCurrentMemoryUsage()
        try operation()
        let endMemory = getCurrentMemoryUsage()
        
        let memoryIncrease = endMemory - startMemory
        print("Memory increase: \(memoryIncrease) MB")
        
        // Assert memory usage is reasonable
        XCTAssertLessThan(memoryIncrease, 50.0, "Operation used too much memory")
    }
    
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0
    }
}

// MARK: - Accessibility Testing Utilities

class AccessibilityTestCase: XCTestCase {
    
    /// Test view for accessibility compliance
    func assertAccessibilityCompliance<V: View>(
        _ view: V,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let hostingController = UIHostingController(rootView: view)
        let rootView = hostingController.view!
        
        // Check for accessibility labels
        checkAccessibilityLabels(in: rootView, file: file, line: line)
        
        // Check for minimum touch targets
        checkMinimumTouchTargets(in: rootView, file: file, line: line)
        
        // Check for color contrast (simplified)
        checkColorContrast(in: rootView, file: file, line: line)
    }
    
    private func checkAccessibilityLabels(in view: UIView, file: StaticString, line: UInt) {
        if view.isAccessibilityElement {
            XCTAssertFalse(
                view.accessibilityLabel?.isEmpty ?? true,
                "Accessibility element missing label",
                file: file,
                line: line
            )
        }
        
        for subview in view.subviews {
            checkAccessibilityLabels(in: subview, file: file, line: line)
        }
    }
    
    private func checkMinimumTouchTargets(in view: UIView, file: StaticString, line: UInt) {
        if view.isUserInteractionEnabled && !view.subviews.contains(where: { $0.isUserInteractionEnabled }) {
            let size = view.frame.size
            XCTAssertGreaterThanOrEqual(
                size.width,
                44,
                "Touch target too small: \(size)",
                file: file,
                line: line
            )
            XCTAssertGreaterThanOrEqual(
                size.height,
                44,
                "Touch target too small: \(size)",
                file: file,
                line: line
            )
        }
        
        for subview in view.subviews {
            checkMinimumTouchTargets(in: subview, file: file, line: line)
        }
    }
    
    private func checkColorContrast(in view: UIView, file: StaticString, line: UInt) {
        // Simplified contrast check
        if let label = view as? UILabel {
            let backgroundColor = label.backgroundColor ?? UIColor.clear
            let textColor = label.textColor ?? UIColor.black
            
            // This is a simplified check - a real implementation would calculate actual contrast ratios
            XCTAssertNotEqual(backgroundColor, textColor, "Text and background colors are too similar", file: file, line: line)
        }
        
        for subview in view.subviews {
            checkColorContrast(in: subview, file: file, line: line)
        }
    }
}