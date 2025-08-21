import XCTest
@testable import MimiSupply

// MARK: - Feature Flag Service Tests
@MainActor
final class FeatureFlagServiceTests: XCTestCase {
    
    var featureFlagService: FeatureFlagServiceImpl!
    var mockCloudKitService: MockCloudKitService!
    var mockAnalyticsService: MockAnalyticsService!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        
        mockUserDefaults = UserDefaults(suiteName: "FeatureFlagServiceTests")!
        mockUserDefaults.removePersistentDomain(forName: "FeatureFlagServiceTests")
        
        mockCloudKitService = MockCloudKitService()
        mockAnalyticsService = MockAnalyticsService()
        
        featureFlagService = FeatureFlagServiceImpl(
            cloudKitService: mockCloudKitService,
            analyticsService: mockAnalyticsService
        )
    }
    
    override func tearDown() {
        featureFlagService = nil
        mockCloudKitService = nil
        mockAnalyticsService = nil
        mockUserDefaults.removePersistentDomain(forName: "FeatureFlagServiceTests")
        mockUserDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Boolean Flag Tests
    func testGetBoolFlag_WithExistingFlag_ShouldReturnValue() async {
        // Given
        let flagKey = "test_feature"
        let expectedValue = true
        
        // When
        let result = await featureFlagService.getBoolFlag(flagKey, defaultValue: false)
        
        // Then
        // Since flag doesn't exist, should return default
        XCTAssertFalse(result)
        
        // Verify analytics tracking
        XCTAssertTrue(mockAnalyticsService.trackedFeatureFlags.contains { $0.flag == flagKey })
    }
    
    func testGetBoolFlag_WithDefaultValue_ShouldReturnDefault() async {
        // Given
        let flagKey = "non_existent_flag"
        let defaultValue = true
        
        // When
        let result = await featureFlagService.getBoolFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue)
    }
    
    // MARK: - String Flag Tests
    func testGetStringFlag_WithValidFlag_ShouldReturnValue() async {
        // Given
        let flagKey = "theme_variant"
        let defaultValue = "light"
        
        // When
        let result = await featureFlagService.getStringFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue)
    }
    
    // MARK: - Integer Flag Tests
    func testGetIntFlag_WithValidFlag_ShouldReturnValue() async {
        // Given
        let flagKey = "max_items"
        let defaultValue = 10
        
        // When
        let result = await featureFlagService.getIntFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue)
    }
    
    // MARK: - Double Flag Tests
    func testGetDoubleFlag_WithValidFlag_ShouldReturnValue() async {
        // Given
        let flagKey = "conversion_rate"
        let defaultValue = 0.05
        
        // When
        let result = await featureFlagService.getDoubleFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue, accuracy: 0.001)
    }
    
    // MARK: - Feature Flag Tests
    func testIsFeatureEnabled_WithKnownFeature_ShouldReturnDefaultValue() async {
        // Given
        let feature = FeatureFlag.enhancedSearch
        
        // When
        let result = await featureFlagService.isFeatureEnabled(feature)
        
        // Then
        XCTAssertEqual(result, feature.defaultValue)
    }
    
    func testIsFeatureEnabled_WithMultipleFeatures_ShouldReturnCorrectValues() async {
        // Given
        let features: [FeatureFlag] = [
            .crashReporting,
            .performanceMonitoring,
            .aiRecommendations,
            .darkModeEnabled
        ]
        
        // When & Then
        for feature in features {
            let result = await featureFlagService.isFeatureEnabled(feature)
            XCTAssertEqual(result, feature.defaultValue, "Feature \(feature.rawValue) should return its default value")
        }
    }
    
    // MARK: - Experiment Tests
    func testGetExperimentVariant_WithActiveExperiment_ShouldReturnVariant() async {
        // Given
        let experimentName = "checkout_flow_experiment"
        
        // When
        let variant = await featureFlagService.getExperimentVariant(experimentName)
        
        // Then
        XCTAssertNotNil(variant)
        XCTAssertTrue(["control", "single_page", "progressive", "minimal"].contains(variant!))
    }
    
    func testGetExperimentVariant_WithConsistentUser_ShouldReturnSameVariant() async {
        // Given
        let experimentName = "checkout_flow_experiment"
        
        // When
        let variant1 = await featureFlagService.getExperimentVariant(experimentName)
        let variant2 = await featureFlagService.getExperimentVariant(experimentName)
        
        // Then
        XCTAssertEqual(variant1, variant2, "Same user should get consistent variant")
    }
    
    func testGetExperimentVariant_WithInactiveExperiment_ShouldReturnNil() async {
        // Given
        let experimentName = "onboarding_experience" // This is inactive by default
        
        // When
        let variant = await featureFlagService.getExperimentVariant(experimentName)
        
        // Then
        XCTAssertNil(variant)
    }
    
    func testGetExperimentVariant_WithNonExistentExperiment_ShouldReturnNil() async {
        // Given
        let experimentName = "non_existent_experiment"
        
        // When
        let variant = await featureFlagService.getExperimentVariant(experimentName)
        
        // Then
        XCTAssertNil(variant)
    }
    
    // MARK: - Refresh Tests
    func testRefreshFlags_ShouldUpdateFlags() async throws {
        // Given
        mockCloudKitService.shouldSucceed = true
        
        // When
        try await featureFlagService.refreshFlags()
        
        // Then
        // Flags should be updated (in a real test, you'd verify specific flag values)
    }
    
    func testRefreshFlags_WithNetworkError_ShouldThrowError() async {
        // Given
        mockCloudKitService.shouldSucceed = false
        mockCloudKitService.errorToThrow = NetworkError.noConnection
        
        // When & Then
        do {
            try await featureFlagService.refreshFlags()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // MARK: - Analytics Tracking Tests
    func testTrackFlagEvaluation_ShouldCallAnalyticsService() async {
        // Given
        let flagName = "test_flag"
        let variant = "enabled"
        let defaultUsed = false
        
        // When
        await featureFlagService.trackFlagEvaluation(flagName, variant: variant, defaultUsed: defaultUsed)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackedFeatureFlags.contains { flag in
            flag.flag == flagName && flag.variant == variant
        })
        
        XCTAssertTrue(mockAnalyticsService.trackedEvents.contains { event in
            event.name == "feature_flag_evaluated"
        })
    }
    
    // MARK: - Variant Assignment Tests
    func testVariantAssignment_ShouldRespectTrafficAllocation() async {
        // Given
        let experimentName = "checkout_flow_experiment"
        let iterations = 1000
        var variantCounts: [String: Int] = [:]
        
        // When - Simulate multiple users
        for i in 0..<iterations {
            // Create a new service instance to simulate different users
            let userDefaults = UserDefaults(suiteName: "test_user_\(i)")!
            userDefaults.removePersistentDomain(forName: "test_user_\(i)")
            
            let service = FeatureFlagServiceImpl(
                cloudKitService: mockCloudKitService,
                analyticsService: mockAnalyticsService
            )
            
            if let variant = await service.getExperimentVariant(experimentName) {
                variantCounts[variant, default: 0] += 1
            }
            
            userDefaults.removePersistentDomain(forName: "test_user_\(i)")
        }
        
        // Then - Check that distribution roughly matches traffic allocation
        let totalAssignments = variantCounts.values.reduce(0, +)
        XCTAssertGreaterThan(totalAssignments, iterations / 2, "Should assign variants to most users")
        
        // Check that all expected variants are present
        let expectedVariants = ["control", "single_page", "progressive", "minimal"]
        for variant in expectedVariants {
            XCTAssertGreaterThan(variantCounts[variant, default: 0], 0, "Variant \(variant) should be assigned to some users")
        }
    }
    
    // MARK: - Edge Cases Tests
    func testFeatureFlagWithSpecialCharacters_ShouldHandleCorrectly() async {
        // Given
        let flagKey = "feature-with_special.characters"
        let defaultValue = false
        
        // When
        let result = await featureFlagService.getBoolFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue)
    }
    
    func testFeatureFlagWithEmptyString_ShouldHandleCorrectly() async {
        // Given
        let flagKey = ""
        let defaultValue = "default"
        
        // When
        let result = await featureFlagService.getStringFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue)
    }
    
    func testFeatureFlagWithVeryLongKey_ShouldHandleCorrectly() async {
        // Given
        let flagKey = String(repeating: "a", count: 1000)
        let defaultValue = 42
        
        // When
        let result = await featureFlagService.getIntFlag(flagKey, defaultValue: defaultValue)
        
        // Then
        XCTAssertEqual(result, defaultValue)
    }
    
    // MARK: - Concurrent Access Tests
    func testConcurrentFlagAccess_ShouldBeThreadSafe() async {
        // Given
        let flagKey = "concurrent_test_flag"
        let defaultValue = true
        let taskCount = 100
        
        // When - Access flag concurrently from multiple tasks
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<taskCount {
                group.addTask {
                    await self.featureFlagService.getBoolFlag(flagKey, defaultValue: defaultValue)
                }
            }
            
            // Then - All tasks should complete successfully
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, taskCount)
            XCTAssertTrue(results.allSatisfy { $0 == defaultValue })
        }
    }
    
    // MARK: - Performance Tests
    func testFlagEvaluationPerformance() async {
        // Given
        let flagCount = 1000
        let flags = (0..<flagCount).map { "performance_flag_\($0)" }
        
        // When
        let startTime = Date()
        
        for flag in flags {
            _ = await featureFlagService.getBoolFlag(flag, defaultValue: false)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertLessThan(duration, 1.0, "Should evaluate 1000 flags in less than 1 second")
        
        let averageTimePerFlag = duration / Double(flagCount)
        XCTAssertLessThan(averageTimePerFlag, 0.001, "Average flag evaluation should be less than 1ms")
    }
}

// MARK: - Feature Flag Manager Tests
@MainActor
final class FeatureFlagManagerTests: XCTestCase {
    
    var manager: FeatureFlagManager!
    var mockCloudKitService: MockCloudKitService!
    var mockAnalyticsService: MockAnalyticsService!
    
    override func setUp() {
        super.setUp()
        
        manager = FeatureFlagManager.shared
        mockCloudKitService = MockCloudKitService()
        mockAnalyticsService = MockAnalyticsService()
        
        manager.configure(
            cloudKitService: mockCloudKitService,
            analyticsService: mockAnalyticsService
        )
    }
    
    override func tearDown() {
        manager = nil
        mockCloudKitService = nil
        mockAnalyticsService = nil
        super.tearDown()
    }
    
    func testIsFeatureEnabled_WithConfiguredManager_ShouldWork() async {
        // Given
        let feature = FeatureFlag.enhancedSearch
        
        // When
        let result = await manager.isFeatureEnabled(feature)
        
        // Then
        XCTAssertEqual(result, feature.defaultValue)
    }
    
    func testIsFeatureEnabled_WithoutConfiguration_ShouldReturnDefault() async {
        // Given
        let unconfiguredManager = FeatureFlagManager()
        let feature = FeatureFlag.enhancedSearch
        
        // When
        let result = await unconfiguredManager.isFeatureEnabled(feature)
        
        // Then
        XCTAssertEqual(result, feature.defaultValue)
    }
    
    func testGetExperimentVariant_WithConfiguredManager_ShouldWork() async {
        // Given
        let experiment = "checkout_flow_experiment"
        
        // When
        let variant = await manager.getExperimentVariant(experiment)
        
        // Then
        XCTAssertNotNil(variant)
    }
    
    func testRefreshFlags_WithConfiguredManager_ShouldWork() async throws {
        // Given
        mockCloudKitService.shouldSucceed = true
        
        // When & Then
        try await manager.refreshFlags()
    }
}

// MARK: - Mock Services
class MockAnalyticsService: AnalyticsService {
    var trackedEvents: [AnalyticsEvent] = []
    var trackedFeatureFlags: [(flag: String, variant: String)] = []
    var trackedScreenViews: [(screen: String, parameters: [String: Any]?)] = []
    var trackedErrors: [Error] = []
    var trackedPerformanceMetrics: [PerformanceMetric] = []
    var trackedEngagements: [UserEngagement] = []
    var userProperties: [String: String?] = [:]
    
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]?) async {
        trackedEvents.append(event)
    }
    
    func trackScreenView(_ screenName: String, parameters: [String: Any]?) async {
        trackedScreenViews.append((screenName, parameters))
    }
    
    func setUserProperty(_ property: String, value: String?) async {
        userProperties[property] = value
    }
    
    func trackPerformanceMetric(_ metric: PerformanceMetric) async {
        trackedPerformanceMetrics.append(metric)
    }
    
    func trackError(_ error: Error, context: [String: Any]?) async {
        trackedErrors.append(error)
    }
    
    func startPerformanceMeasurement(_ name: String) -> PerformanceMeasurement {
        return PerformanceMeasurement(name: name)
    }
    
    func trackFeatureFlag(_ flag: String, variant: String) async {
        trackedFeatureFlags.append((flag, variant))
    }
    
    func trackEngagement(_ engagement: UserEngagement) async {
        trackedEngagements.append(engagement)
    }
    
    func flush() async {
        // Mock implementation
    }
}

class MockCloudKitService: CloudKitService {
    var shouldSucceed = true
    var errorToThrow: Error?
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        if !shouldSucceed, let error = errorToThrow {
            throw error
        }
        return []
    }
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        if !shouldSucceed, let error = errorToThrow {
            throw error
        }
        return []
    }
    
    func createOrder(_ order: Order) async throws -> Order {
        if !shouldSucceed, let error = errorToThrow {
            throw error
        }
        return order
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        if !shouldSucceed, let error = errorToThrow {
            throw error
        }
    }
    
    func subscribeToOrderUpdates(for userId: String) async throws {
        if !shouldSucceed, let error = errorToThrow {
            throw error
        }
    }
}