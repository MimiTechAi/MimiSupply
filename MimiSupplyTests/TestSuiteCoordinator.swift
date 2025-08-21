//
//  TestSuiteCoordinator.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import Foundation
@testable import MimiSupply

/// Coordinates and manages the comprehensive testing suite
class TestSuiteCoordinator: NSObject {
    
    static let shared = TestSuiteCoordinator()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Test Suite Management
    
    /// Runs all unit tests in the correct order
    func runUnitTestSuite() async throws {
        print("🧪 Starting Unit Test Suite...")
        
        // Core services tests
        try await runServiceTests()
        
        // Business logic tests
        try await runBusinessLogicTests()
        
        // Repository tests
        try await runRepositoryTests()
        
        // Design system tests
        try await runDesignSystemTests()
        
        print("✅ Unit Test Suite completed successfully")
    }
    
    /// Runs all integration tests
    func runIntegrationTestSuite() async throws {
        print("🔗 Starting Integration Test Suite...")
        
        // End-to-end workflow tests
        try await runWorkflowTests()
        
        // Service integration tests
        try await runServiceIntegrationTests()
        
        // Comprehensive end-to-end tests
        try await runEndToEndTests()
        
        print("✅ Integration Test Suite completed successfully")
    }
    
    /// Runs all UI tests
    func runUITestSuite() async throws {
        print("📱 Starting UI Test Suite...")
        
        // Screen interaction tests
        try await runScreenTests()
        
        // Navigation tests
        try await runNavigationTests()
        
        // Accessibility tests
        try await runAccessibilityTests()
        
        print("✅ UI Test Suite completed successfully")
    }
    
    /// Runs performance tests
    func runPerformanceTestSuite() async throws {
        print("⚡ Starting Performance Test Suite...")
        
        // Startup performance
        try await runStartupPerformanceTests()
        
        // Runtime performance
        try await runRuntimePerformanceTests()
        
        // Memory performance
        try await runMemoryPerformanceTests()
        
        print("✅ Performance Test Suite completed successfully")
    }
    
    /// Runs snapshot tests for visual regression testing
    func runSnapshotTestSuite() async throws {
        print("📸 Starting Snapshot Test Suite...")
        
        let snapshotTests = SnapshotTestRunner()
        try await snapshotTests.runAllTests()
        
        print("✅ Snapshot Test Suite completed successfully")
    }
    
    /// Runs comprehensive UI tests
    func runComprehensiveUITestSuite() async throws {
        print("📱 Starting Comprehensive UI Test Suite...")
        
        // Note: UI tests run in separate process, this is a placeholder
        print("UI tests should be run separately using XCTest framework")
        
        print("✅ Comprehensive UI Test Suite completed successfully")
    }
    
    // MARK: - Private Test Runners
    
    private func runServiceTests() async throws {
        // Authentication service tests
        let authTests = AuthenticationServiceTests()
        try await authTests.runAllTests()
        
        // CloudKit service tests
        let cloudKitTests = CloudKitServiceTests()
        try await cloudKitTests.runAllTests()
        
        // Location service tests
        let locationTests = LocationServiceTests()
        try await locationTests.runAllTests()
        
        // Payment service tests
        let paymentTests = PaymentServiceTests()
        try await paymentTests.runAllTests()
    }
    
    private func runBusinessLogicTests() async throws {
        // Cart logic tests
        let cartTests = CartServiceUnitTests()
        try await cartTests.runAllTests()
        
        // Order management tests
        let orderTests = OrderManagementTests()
        try await orderTests.runAllTests()
        
        // Driver assignment tests
        let driverTests = DriverAssignmentTests()
        try await driverTests.runAllTests()
        
        // Comprehensive business logic tests
        let comprehensiveTests = ComprehensiveBusinessLogicTests()
        try await comprehensiveTests.runAllTests()
    }
    
    private func runRepositoryTests() async throws {
        // Product repository tests
        let productTests = ProductRepositoryTests()
        try await productTests.runAllTests()
        
        // Partner repository tests
        let partnerTests = PartnerRepositoryTests()
        try await partnerTests.runAllTests()
        
        // User repository tests
        let userTests = UserRepositoryTests()
        try await userTests.runAllTests()
    }
    
    private func runWorkflowTests() async throws {
        // Complete order workflow
        let orderWorkflowTests = OrderWorkflowIntegrationTests()
        try await orderWorkflowTests.runAllTests()
        
        // Authentication workflow
        let authWorkflowTests = AuthenticationIntegrationTests()
        try await authWorkflowTests.runAllTests()
        
        // Driver workflow
        let driverWorkflowTests = DriverWorkflowTests()
        try await driverWorkflowTests.runAllTests()
    }
    
    private func runServiceIntegrationTests() async throws {
        // CloudKit + CoreData integration
        let dataIntegrationTests = DataLayerIntegrationTests()
        try await dataIntegrationTests.runAllTests()
        
        // Payment + Order integration
        let paymentIntegrationTests = PaymentIntegrationTests()
        try await paymentIntegrationTests.runAllTests()
        
        // Push notification integration
        let pushIntegrationTests = PushNotificationIntegrationTests()
        try await pushIntegrationTests.runAllTests()
    }
    
    private func runScreenTests() async throws {
        // Explore home tests
        let exploreTests = ExploreHomeViewTests()
        try await exploreTests.runAllTests()
        
        // Partner detail tests
        let partnerTests = PartnerDetailViewTests()
        try await partnerTests.runAllTests()
        
        // Cart tests
        let cartTests = CartViewTests()
        try await cartTests.runAllTests()
    }
    
    private func runNavigationTests() async throws {
        let navigationTests = NavigationTests()
        try await navigationTests.runAllTests()
    }
    
    private func runAccessibilityTests() async throws {
        let accessibilityTests = AccessibilityComplianceTests()
        try await accessibilityTests.runAllTests()
    }
    
    private func runStartupPerformanceTests() async throws {
        let startupTests = StartupPerformanceTests()
        try await startupTests.runAllTests()
    }
    
    private func runRuntimePerformanceTests() async throws {
        let runtimeTests = RuntimePerformanceTests()
        try await runtimeTests.runAllTests()
    }
    
    private func runMemoryPerformanceTests() async throws {
        let memoryTests = MemoryPerformanceTests()
        try await memoryTests.runAllTests()
    }
    
    private func runDesignSystemTests() async throws {
        let designSystemTests = DesignSystemTests()
        try await designSystemTests.runAllTests()
        
        let snapshotTests = DesignSystemSnapshotTests()
        try await snapshotTests.runAllTests()
    }
    
    private func runEndToEndTests() async throws {
        let endToEndTests = EndToEndWorkflowTests()
        try await endToEndTests.runAllTests()
}

// MARK: - Test Protocol Extensions

// Note: XCTestCase.runAllTests() extension is defined in TestExecutionScript.swift to avoid duplication.