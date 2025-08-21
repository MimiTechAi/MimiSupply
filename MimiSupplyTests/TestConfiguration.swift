//
//  TestConfiguration.swift
//  MimiSupplyTests
//
//  Created by Kiro on 16.08.25.
//

import Foundation
import XCTest
@testable import MimiSupply

/// Centralized test configuration and constants
struct TestConfiguration {
    
    // MARK: - Test Environment Settings
    
    static let isRunningTests: Bool = {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               ProcessInfo.processInfo.arguments.contains("--uitesting")
    }()
    
    static let isUITesting: Bool = {
        return ProcessInfo.processInfo.arguments.contains("--uitesting")
    }()
    
    static let shouldUseMockData: Bool = {
        return ProcessInfo.processInfo.environment["UITEST_MOCK_DATA"] == "1" || isRunningTests
    }()
    
    static let shouldDisableAnimations: Bool = {
        return ProcessInfo.processInfo.environment["UITEST_DISABLE_ANIMATIONS"] == "1" || isUITesting
    }()
    
    static let shouldSimulateNetworkError: Bool = {
        return ProcessInfo.processInfo.arguments.contains("--simulate-network-error")
    }()
    
    static let shouldShowEmptyState: Bool = {
        return ProcessInfo.processInfo.arguments.contains("--empty-state")
    }()
    
    // MARK: - Performance Benchmarks
    
    struct PerformanceBenchmarks {
        static let appStartupTime: TimeInterval = 2.5 // seconds
        static let warmStartupTime: TimeInterval = 1.0 // seconds
        static let firstScreenTTI: TimeInterval = 1.0 // seconds
        static let searchResponseTime: TimeInterval = 0.3 // seconds
        static let imageLoadTime: TimeInterval = 2.0 // seconds
        static let scrollingFPS: Double = 100.0 // minimum FPS for 120Hz
        static let memoryIncreaseLimit: Double = 100.0 // MB
        static let networkRequestTimeout: TimeInterval = 10.0 // seconds
    }
    
    // MARK: - Test Data Limits
    
    struct TestDataLimits {
        static let maxPartnersForTesting = 1000
        static let maxProductsPerPartner = 100
        static let maxCartItems = 50
        static let maxOrderItems = 20
        static let maxConcurrentRequests = 10
        static let maxTestDuration: TimeInterval = 30.0 // seconds
    }
    
    // MARK: - Accessibility Requirements
    
    struct AccessibilityRequirements {
        static let minimumContrastRatio: Double = 4.5 // WCAG AA
        static let minimumTouchTargetSize: CGFloat = 44.0 // points
        static let maximumTextScaling: CGFloat = 2.0 // 200%
        static let supportedContentSizeCategories: [UIContentSizeCategory] = [
            .small, .medium, .large, .extraLarge, .extraExtraLarge, .extraExtraExtraLarge,
            .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge
        ]
    }
    
    // MARK: - Test Coverage Requirements
    
    struct CoverageRequirements {
        static let overallCoverage: Double = 0.85 // 85%
        static let businessLogicCoverage: Double = 0.90 // 90%
        static let uiCoverage: Double = 0.80 // 80%
        static let integrationCoverage: Double = 0.75 // 75%
    }
    
    // MARK: - Mock Data Configuration
    
    struct MockDataConfiguration {
        static let defaultPartnerCount = 20
        static let defaultProductsPerPartner = 15
        static let defaultOrderCount = 10
        static let defaultUserCount = 5
        
        static let mockImageURLs = [
            "https://picsum.photos/400/300?random=1",
            "https://picsum.photos/400/300?random=2",
            "https://picsum.photos/400/300?random=3",
            "https://picsum.photos/400/300?random=4",
            "https://picsum.photos/400/300?random=5"
        ]
        
        static let mockPartnerNames = [
            "Delicious Bites", "Fresh Market", "Quick Pharmacy", "Corner Store",
            "Healthy Eats", "Fast Food Plus", "Organic Garden", "City Deli",
            "Sweet Treats", "Local Grocery", "Express Mart", "Gourmet Kitchen"
        ]
        
        static let mockProductNames = [
            "Classic Burger", "Caesar Salad", "Margherita Pizza", "Chicken Sandwich",
            "Fruit Smoothie", "Pasta Primavera", "Fish Tacos", "Veggie Wrap",
            "Chocolate Cake", "Green Tea", "Iced Coffee", "Energy Drink"
        ]
    }
    
    // MARK: - Test Device Configurations
    
    struct TestDeviceConfigurations {
        static let iPhoneConfigurations: [DeviceConfiguration] = [
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "en")
            ),
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .landscape,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "en")
            ),
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .dark,
                sizeCategory: .medium,
                locale: Locale(identifier: "en")
            )
        ]
        
        static let iPadConfigurations: [DeviceConfiguration] = [
            DeviceConfiguration(
                device: .iPadPro,
                orientation: .portrait,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "en")
            ),
            DeviceConfiguration(
                device: .iPadPro,
                orientation: .landscape,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "en")
            )
        ]
        
        static let accessibilityConfigurations: [DeviceConfiguration] = [
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .light,
                sizeCategory: .accessibilityExtraExtraExtraLarge,
                locale: Locale(identifier: "en")
            ),
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .dark,
                sizeCategory: .accessibilityLarge,
                locale: Locale(identifier: "en")
            )
        ]
        
        static let localizationConfigurations: [DeviceConfiguration] = [
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "es")
            ),
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "fr")
            ),
            DeviceConfiguration(
                device: .iPhone15Pro,
                orientation: .portrait,
                colorScheme: .light,
                sizeCategory: .medium,
                locale: Locale(identifier: "ar")
            )
        ]
    }
    
    // MARK: - Test Execution Settings
    
    struct ExecutionSettings {
        static let defaultTimeout: TimeInterval = 5.0
        static let longTimeout: TimeInterval = 10.0
        static let networkTimeout: TimeInterval = 15.0
        static let animationTimeout: TimeInterval = 1.0
        
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
        
        static let parallelTestExecution = true
        static let randomizeTestOrder = true
        static let continueAfterFailure = false
    }
    
    // MARK: - Error Simulation Settings
    
    struct ErrorSimulation {
        static let networkErrorRate: Double = 0.1 // 10% of requests fail
        static let authenticationErrorRate: Double = 0.05 // 5% of auth attempts fail
        static let paymentErrorRate: Double = 0.02 // 2% of payments fail
        static let locationErrorRate: Double = 0.08 // 8% of location requests fail
        
        static let simulatedNetworkDelay: TimeInterval = 2.0 // seconds
        static let simulatedProcessingDelay: TimeInterval = 1.0 // seconds
    }
    
    // MARK: - Snapshot Testing Settings
    
    struct SnapshotSettings {
        static let tolerance: Float = 0.02 // 2% pixel difference tolerance
        static let recordMode = false // Set to true to record new snapshots
        static let compareAgainstPreviousSnapshot = true
        
        static let snapshotDirectory = "Snapshots"
        static let failedSnapshotDirectory = "FailedSnapshots"
        static let referenceSnapshotDirectory = "ReferenceSnapshots"
    }
    
    // MARK: - Helper Methods
    
    static func configureTestEnvironment() {
        // Configure global test settings
        if shouldDisableAnimations {
            UIView.setAnimationsEnabled(false)
        }
        
        // Set up mock data if needed
        if shouldUseMockData {
            configureMockData()
        }
        
        // Configure accessibility settings for testing
        configureAccessibilityTesting()
    }
    
    static func configureMockData() {
        // Set up mock data providers
        UserDefaults.standard.set(true, forKey: "UseMockData")
        UserDefaults.standard.set(MockDataConfiguration.defaultPartnerCount, forKey: "MockPartnerCount")
        UserDefaults.standard.set(MockDataConfiguration.defaultProductsPerPartner, forKey: "MockProductsPerPartner")
    }
    
    static func configureAccessibilityTesting() {
        // Enable accessibility features for testing
        UserDefaults.standard.set(true, forKey: "AccessibilityTestingEnabled")
    }
    
    static func resetTestEnvironment() {
        // Clean up test environment
        UserDefaults.standard.removeObject(forKey: "UseMockData")
        UserDefaults.standard.removeObject(forKey: "MockPartnerCount")
        UserDefaults.standard.removeObject(forKey: "MockProductsPerPartner")
        UserDefaults.standard.removeObject(forKey: "AccessibilityTestingEnabled")
        
        // Re-enable animations
        UIView.setAnimationsEnabled(true)
    }
    
    // MARK: - Test Validation Helpers
    
    static func validatePerformanceBenchmark(_ actualTime: TimeInterval, against benchmark: TimeInterval, testName: String) -> Bool {
        let passed = actualTime <= benchmark
        if !passed {
            print("⚠️ Performance benchmark failed for \(testName): \(actualTime)s > \(benchmark)s")
        }
        return passed
    }
    
    static func validateMemoryUsage(_ actualMemory: Double, against limit: Double, testName: String) -> Bool {
        let passed = actualMemory <= limit
        if !passed {
            print("⚠️ Memory usage exceeded for \(testName): \(actualMemory)MB > \(limit)MB")
        }
        return passed
    }
    
    static func validateAccessibilityCompliance(
        contrastRatio: Double,
        touchTargetSize: CGSize,
        testName: String
    ) -> Bool {
        let contrastPassed = contrastRatio >= AccessibilityRequirements.minimumContrastRatio
        let sizePassed = touchTargetSize.width >= AccessibilityRequirements.minimumTouchTargetSize &&
                        touchTargetSize.height >= AccessibilityRequirements.minimumTouchTargetSize
        
        let passed = contrastPassed && sizePassed
        
        if !passed {
            if !contrastPassed {
                print("⚠️ Contrast ratio failed for \(testName): \(contrastRatio) < \(AccessibilityRequirements.minimumContrastRatio)")
            }
            if !sizePassed {
                print("⚠️ Touch target size failed for \(testName): \(touchTargetSize) < \(AccessibilityRequirements.minimumTouchTargetSize)")
            }
        }
        
        return passed
    }
}

// MARK: - Test Environment Manager

class TestEnvironmentManager {
    static let shared = TestEnvironmentManager()
    
    private var isConfigured = false
    
    private init() {}
    
    func setUp() {
        guard !isConfigured else { return }
        
        TestConfiguration.configureTestEnvironment()
        isConfigured = true
        
        print("🔧 Test environment configured")
    }
    
    func tearDown() {
        guard isConfigured else { return }
        
        TestConfiguration.resetTestEnvironment()
        isConfigured = false
        
        print("🧹 Test environment cleaned up")
    }
}

// MARK: - Test Metrics Collector

class TestMetricsCollector {
    static let shared = TestMetricsCollector()
    
    private var metrics: [String: Any] = [:]
    private let metricsQueue = DispatchQueue(label: "test.metrics.queue", qos: .utility)
    
    private init() {}
    
    func recordMetric(_ name: String, value: Any) {
        metricsQueue.async {
            self.metrics[name] = value
        }
    }
    
    func recordPerformanceMetric(_ name: String, duration: TimeInterval) {
        recordMetric("\(name)_duration", value: duration)
        
        // Check against benchmarks
        let benchmarkKey = name.lowercased().replacingOccurrences(of: " ", with: "_")
        if let benchmark = getBenchmark(for: benchmarkKey) {
            let passed = TestConfiguration.validatePerformanceBenchmark(duration, against: benchmark, testName: name)
            recordMetric("\(name)_benchmark_passed", value: passed)
        }
    }
    
    func recordMemoryMetric(_ name: String, memoryUsage: Double) {
        recordMetric("\(name)_memory_mb", value: memoryUsage)
        
        let passed = TestConfiguration.validateMemoryUsage(
            memoryUsage,
            against: TestConfiguration.PerformanceBenchmarks.memoryIncreaseLimit,
            testName: name
        )
        recordMetric("\(name)_memory_benchmark_passed", value: passed)
    }
    
    func getMetrics() -> [String: Any] {
        return metricsQueue.sync {
            return metrics
        }
    }
    
    func exportMetrics() -> String {
        let allMetrics = getMetrics()
        
        var report = "# Test Metrics Report\n\n"
        
        for (key, value) in allMetrics.sorted(by: { $0.key < $1.key }) {
            report += "- \(key): \(value)\n"
        }
        
        return report
    }
    
    private func getBenchmark(for key: String) -> TimeInterval? {
        switch key {
        case "app_startup": return TestConfiguration.PerformanceBenchmarks.appStartupTime
        case "warm_startup": return TestConfiguration.PerformanceBenchmarks.warmStartupTime
        case "first_screen_tti": return TestConfiguration.PerformanceBenchmarks.firstScreenTTI
        case "search_response": return TestConfiguration.PerformanceBenchmarks.searchResponseTime
        case "image_load": return TestConfiguration.PerformanceBenchmarks.imageLoadTime
        default: return nil
        }
    }
}

// MARK: - Extensions

extension XCTestCase {
    func setUpTestEnvironment() {
        TestEnvironmentManager.shared.setUp()
    }
    
    func tearDownTestEnvironment() {
        TestEnvironmentManager.shared.tearDown()
    }
    
    func recordTestMetric(_ name: String, value: Any) {
        TestMetricsCollector.shared.recordMetric(name, value: value)
    }
    
    func recordPerformanceMetric(_ name: String, duration: TimeInterval) {
        TestMetricsCollector.shared.recordPerformanceMetric(name, duration: duration)
    }
    
    func recordMemoryMetric(_ name: String, memoryUsage: Double) {
        TestMetricsCollector.shared.recordMemoryMetric(name, memoryUsage: memoryUsage)
    }
}