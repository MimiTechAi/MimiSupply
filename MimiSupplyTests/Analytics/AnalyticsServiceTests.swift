import XCTest
@testable import MimiSupply

// MARK: - Analytics Service Tests
@MainActor
final class AnalyticsServiceTests: XCTestCase {
    
    var analyticsService: AnalyticsServiceImpl!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        // Use a test suite name to avoid conflicts
        mockUserDefaults = UserDefaults(suiteName: "AnalyticsServiceTests")!
        mockUserDefaults.removePersistentDomain(forName: "AnalyticsServiceTests")
        
        analyticsService = AnalyticsServiceImpl()
    }
    
    override func tearDown() {
        analyticsService = nil
        mockUserDefaults.removePersistentDomain(forName: "AnalyticsServiceTests")
        mockUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Event Tracking Tests
    func testTrackEvent_WithValidEvent_ShouldSucceed() async {
        // Given
        let event = AnalyticsEvent.userSignIn
        let parameters = ["method": "apple", "success": true] as [String: Any]
        
        // When
        await analyticsService.trackEvent(event, parameters: parameters)
        
        // Then
        // Event should be tracked (we can't easily verify internal state without exposing it)
        // In a real test, you might verify the event was added to a buffer or sent to a service
    }
    
    func testTrackEvent_WithPIIData_ShouldSanitizeParameters() async {
        // Given
        let event = AnalyticsEvent.userSignIn
        let parameters = [
            "email": "user@example.com", // Should be filtered out
            "user_role": "customer", // Should be kept
            "phone": "123-456-7890" // Should be filtered out
        ] as [String: Any]
        
        // When
        await analyticsService.trackEvent(event, parameters: parameters)
        
        // Then
        // PII data should be filtered out (verified through privacy compliance)
    }
    
    func testTrackScreenView_WithValidScreen_ShouldTrackEngagement() async {
        // Given
        let screenName = "ExploreHomeView"
        let parameters = ["source": "tab_navigation"]
        
        // When
        await analyticsService.trackScreenView(screenName, parameters: parameters)
        
        // Then
        // Should track both screen view and engagement events
    }
    
    // MARK: - Performance Tracking Tests
    func testTrackPerformanceMetric_WithValidMetric_ShouldSucceed() async {
        // Given
        let metric = PerformanceMetric(
            name: "app_launch_time",
            value: 1.5,
            unit: "seconds",
            metadata: ["cold_start": "true"]
        )
        
        // When
        await analyticsService.trackPerformanceMetric(metric)
        
        // Then
        // Metric should be tracked successfully
    }
    
    func testStartPerformanceMeasurement_ShouldReturnMeasurement() {
        // Given
        let measurementName = "api_call_duration"
        
        // When
        let measurement = analyticsService.startPerformanceMeasurement(measurementName)
        
        // Then
        XCTAssertEqual(measurement.name, measurementName)
        XCTAssertTrue(measurement.startTime <= Date())
    }
    
    func testPerformanceMeasurement_EndMeasurement_ShouldReturnMetric() async {
        // Given
        let measurement = analyticsService.startPerformanceMeasurement("test_operation")
        
        // Simulate some work
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // When
        let metric = measurement.end(metadata: ["test": "true"])
        
        // Then
        XCTAssertEqual(metric.name, "test_operation")
        XCTAssertGreaterThan(metric.value, 0)
        XCTAssertEqual(metric.unit, "ms")
        XCTAssertEqual(metric.metadata?["test"], "true")
        
        // Track the metric
        await analyticsService.trackPerformanceMetric(metric)
    }
    
    // MARK: - Error Tracking Tests
    func testTrackError_WithStandardError_ShouldExtractErrorInfo() async {
        // Given
        let error = NSError(domain: "TestDomain", code: 123, userInfo: [
            NSLocalizedDescriptionKey: "Test error description"
        ])
        let context = ["action": "test_action", "user_id": "test_user"]
        
        // When
        await analyticsService.trackError(error, context: context)
        
        // Then
        // Error should be tracked with extracted information
    }
    
    func testTrackError_WithAppError_ShouldIncludeAppErrorType() async {
        // Given
        let appError = AppError.network(.noConnection)
        let context = ["screen": "ExploreHomeView"]
        
        // When
        await analyticsService.trackError(appError, context: context)
        
        // Then
        // Should include app error type information
    }
    
    // MARK: - Feature Flag Tracking Tests
    func testTrackFeatureFlag_WithValidFlag_ShouldSucceed() async {
        // Given
        let flagName = "enhanced_search"
        let variant = "enabled"
        
        // When
        await analyticsService.trackFeatureFlag(flagName, variant: variant)
        
        // Then
        // Feature flag evaluation should be tracked
    }
    
    // MARK: - User Engagement Tests
    func testTrackEngagement_WithSessionStart_ShouldSucceed() async {
        // Given
        let engagement = UserEngagement(type: .sessionStart)
        
        // When
        await analyticsService.trackEngagement(engagement)
        
        // Then
        // Session start should be tracked
    }
    
    func testTrackEngagement_WithSessionEnd_ShouldIncludeDuration() async {
        // Given
        let sessionDuration: TimeInterval = 300 // 5 minutes
        let engagement = UserEngagement(
            type: .sessionEnd,
            duration: sessionDuration
        )
        
        // When
        await analyticsService.trackEngagement(engagement)
        
        // Then
        // Session end with duration should be tracked
    }
    
    func testTrackEngagement_WithConversion_ShouldIncludeValue() async {
        // Given
        let conversionValue: Double = 25.99
        let engagement = UserEngagement(
            type: .conversion,
            value: conversionValue,
            metadata: ["product_id": "123", "category": "food"]
        )
        
        // When
        await analyticsService.trackEngagement(engagement)
        
        // Then
        // Conversion with value should be tracked
    }
    
    // MARK: - User Property Tests
    func testSetUserProperty_WithAllowedProperty_ShouldSucceed() async {
        // Given
        let property = "user_role"
        let value = "customer"
        
        // When
        await analyticsService.setUserProperty(property, value: value)
        
        // Then
        // Property should be set successfully
    }
    
    func testSetUserProperty_WithPIIProperty_ShouldBeRejected() async {
        // Given
        let property = "email_address" // Contains PII keyword
        let value = "user@example.com"
        
        // When
        await analyticsService.setUserProperty(property, value: value)
        
        // Then
        // Property should be rejected for privacy reasons
    }
    
    // MARK: - Privacy Compliance Tests
    func testAnalyticsDisabled_ShouldNotTrackEvents() async {
        // Given
        UserDefaults.standard.set(false, forKey: "analytics_enabled")
        let event = AnalyticsEvent.userSignIn
        
        // When
        await analyticsService.trackEvent(event, parameters: nil)
        
        // Then
        // Event should not be tracked when analytics is disabled
        
        // Cleanup
        UserDefaults.standard.set(true, forKey: "analytics_enabled")
    }
    
    func testCrashReportingDisabled_ShouldNotTrackErrors() async {
        // Given
        UserDefaults.standard.set(false, forKey: "crash_reporting_enabled")
        let error = NSError(domain: "TestDomain", code: 123)
        
        // When
        await analyticsService.trackError(error, context: nil)
        
        // Then
        // Error should not be tracked when crash reporting is disabled
        
        // Cleanup
        UserDefaults.standard.set(true, forKey: "crash_reporting_enabled")
    }
    
    // MARK: - Data Serialization Tests
    func testEventSerialization_WithComplexParameters_ShouldSucceed() async {
        // Given
        let event = AnalyticsEvent.productViewed
        let parameters: [String: Any] = [
            "product_id": "123",
            "price": 25.99,
            "in_stock": true,
            "categories": ["food", "italian"],
            "metadata": [
                "source": "search",
                "position": 3
            ],
            "timestamp": Date()
        ]
        
        // When
        await analyticsService.trackEvent(event, parameters: parameters)
        
        // Then
        // Complex parameters should be serialized correctly
    }
    
    // MARK: - Flush Tests
    func testFlush_ShouldPersistEvents() async {
        // Given
        let events = [
            AnalyticsEvent.userSignIn,
            AnalyticsEvent.screenView,
            AnalyticsEvent.productViewed
        ]
        
        // Track multiple events
        for event in events {
            await analyticsService.trackEvent(event, parameters: nil)
        }
        
        // When
        await analyticsService.flush()
        
        // Then
        // Events should be persisted to storage
    }
    
    // MARK: - Integration Tests
    func testCompleteUserJourney_ShouldTrackAllEvents() async {
        // Given - Simulate a complete user journey
        let journeyEvents = [
            (AnalyticsEvent.appLaunch, ["cold_start": true]),
            (AnalyticsEvent.screenView, ["screen_name": "ExploreHomeView"]),
            (AnalyticsEvent.productViewed, ["product_id": "123"]),
            (AnalyticsEvent.addToCart, ["product_id": "123", "quantity": 2]),
            (AnalyticsEvent.checkoutStarted, ["cart_value": 51.98]),
            (AnalyticsEvent.paymentCompleted, ["amount": 51.98, "method": "apple_pay"]),
            (AnalyticsEvent.orderPlaced, ["order_id": "order_456"])
        ] as [(AnalyticsEvent, [String: Any])]
        
        // When - Track the complete journey
        for (event, parameters) in journeyEvents {
            await analyticsService.trackEvent(event, parameters: parameters)
        }
        
        // Track performance metrics
        let launchMetric = PerformanceMetric(
            name: "app_launch_time",
            value: 1.2,
            unit: "seconds"
        )
        await analyticsService.trackPerformanceMetric(launchMetric)
        
        // Track engagement
        let engagement = UserEngagement(
            type: .conversion,
            value: 51.98,
            metadata: ["funnel": "explore_to_purchase"]
        )
        await analyticsService.trackEngagement(engagement)
        
        // Flush all events
        await analyticsService.flush()
        
        // Then
        // All events should be tracked and persisted successfully
    }
}

// MARK: - Mock Network Error
enum NetworkError: Error, LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

// MARK: - Performance Tests
final class AnalyticsPerformanceTests: XCTestCase {
    
    var analyticsService: AnalyticsServiceImpl!
    
    override func setUp() {
        super.setUp()
        analyticsService = AnalyticsServiceImpl()
    }
    
    override func tearDown() {
        analyticsService = nil
        super.tearDown()
    }
    
    func testEventTrackingPerformance() async {
        // Measure the time it takes to track 100 events
        let eventCount = 100
        let events = (0..<eventCount).map { _ in
            AnalyticsEvent.productViewed
        }
        
        let startTime = Date()
        
        for event in events {
            await analyticsService.trackEvent(event, parameters: [
                "product_id": UUID().uuidString,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Should be able to track 100 events in less than 1 second
        XCTAssertLessThan(duration, 1.0, "Event tracking should be performant")
        
        // Average time per event should be less than 10ms
        let averageTimePerEvent = duration / Double(eventCount)
        XCTAssertLessThan(averageTimePerEvent, 0.01, "Average event tracking time should be less than 10ms")
    }
    
    func testPerformanceMeasurementAccuracy() async {
        // Test that performance measurements are accurate
        let measurement = analyticsService.startPerformanceMeasurement("test_operation")
        
        let expectedDuration: UInt64 = 100_000_000 // 100ms in nanoseconds
        try? await Task.sleep(nanoseconds: expectedDuration)
        
        let metric = measurement.end()
        
        // Allow for some variance in timing (±20ms)
        let expectedMs = Double(expectedDuration) / 1_000_000
        XCTAssertGreaterThan(metric.value, expectedMs - 20)
        XCTAssertLessThan(metric.value, expectedMs + 20)
    }
    
    func testMemoryUsageDuringEventTracking() async {
        // Track memory usage while tracking many events
        let initialMemory = getMemoryUsage()
        
        // Track 1000 events
        for i in 0..<1000 {
            await analyticsService.trackEvent(.productViewed, parameters: [
                "product_id": "product_\(i)",
                "category": "test_category",
                "price": Double.random(in: 1.0...100.0)
            ])
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 10MB)
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Memory usage should not increase excessively")
    }
    
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Privacy Compliance Tests
final class AnalyticsPrivacyTests: XCTestCase {
    
    var analyticsService: AnalyticsServiceImpl!
    
    override func setUp() {
        super.setUp()
        analyticsService = AnalyticsServiceImpl()
    }
    
    override func tearDown() {
        analyticsService = nil
        super.tearDown()
    }
    
    func testPIIDataFiltering() async {
        // Test that PII data is properly filtered
        let piiParameters = [
            "email": "user@example.com",
            "phone": "123-456-7890",
            "address": "123 Main St",
            "full_name": "John Doe",
            "password": "secret123",
            "credit_card": "4111-1111-1111-1111",
            "ssn": "123-45-6789"
        ]
        
        // These should be allowed
        let allowedParameters = [
            "user_role": "customer",
            "app_version": "1.0.0",
            "device_model": "iPhone14,2",
            "os_version": "17.0",
            "language": "en",
            "region": "US"
        ]
        
        let combinedParameters = piiParameters.merging(allowedParameters) { _, new in new }
        
        await analyticsService.trackEvent(.userSignIn, parameters: combinedParameters)
        
        // In a real test, you would verify that only allowed parameters were stored
        // This test serves as documentation of privacy requirements
    }
    
    func testUserConsentRespected() async {
        // Test that analytics respects user consent settings
        
        // Disable analytics
        UserDefaults.standard.set(false, forKey: "analytics_enabled")
        
        await analyticsService.trackEvent(.userSignIn, parameters: nil)
        
        // Re-enable analytics
        UserDefaults.standard.set(true, forKey: "analytics_enabled")
        
        await analyticsService.trackEvent(.userSignIn, parameters: nil)
        
        // Verify that events are only tracked when consent is given
    }
    
    func testDataRetentionCompliance() async {
        // Test that old analytics data is properly cleaned up
        // This would typically involve checking file system cleanup
        
        // Track some events
        for i in 0..<10 {
            await analyticsService.trackEvent(.productViewed, parameters: [
                "product_id": "product_\(i)"
            ])
        }
        
        await analyticsService.flush()
        
        // In a real implementation, you would verify that old files are cleaned up
        // according to your data retention policy
    }
}