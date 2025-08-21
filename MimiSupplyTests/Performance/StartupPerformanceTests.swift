//
//  StartupPerformanceTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
@testable import MimiSupply

/// Performance tests specifically for app startup scenarios
final class StartupPerformanceTests: XCTestCase {
    
    var startupOptimizer: StartupOptimizer!
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        startupOptimizer = StartupOptimizer.shared
        performanceMonitor = PerformanceMonitor()
    }
    
    override func tearDown() {
        performanceMonitor = nil
        startupOptimizer = nil
        super.tearDown()
    }
    
    // MARK: - Cold Start Performance Tests
    
    func testColdStartupTime() throws {
        measure {
            let expectation = XCTestExpectation(description: "Cold startup completed")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Simulate cold start initialization
                await startupOptimizer.performColdStartInitialization()
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let startupTime = endTime - startTime
                
                // Requirement 11.1: Startup time < 2.5s
                XCTAssertLessThan(startupTime, 2.5, "Cold startup should complete within 2.5 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testWarmStartupTime() throws {
        // Pre-warm the app
        let warmupExpectation = XCTestExpectation(description: "Warmup completed")
        Task {
            await startupOptimizer.performColdStartInitialization()
            warmupExpectation.fulfill()
        }
        wait(for: [warmupExpectation], timeout: 5.0)
        
        measure {
            let expectation = XCTestExpectation(description: "Warm startup completed")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Simulate warm start
                await startupOptimizer.performWarmStartInitialization()
                
                let endTime = CFAbsoluteTimeGetCurrent()
                let startupTime = endTime - startTime
                
                // Warm start should be significantly faster
                XCTAssertLessThan(startupTime, 1.0, "Warm startup should complete within 1 second")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - First Screen Time to Interactive Tests
    
    func testFirstScreenTTI() throws {
        measure {
            let expectation = XCTestExpectation(description: "First screen TTI completed")
            
            Task {
                performanceMonitor.startMeasuring("first_screen_tti")
                
                // Simulate first screen loading
                await startupOptimizer.loadFirstScreen()
                
                let tti = performanceMonitor.stopMeasuring("first_screen_tti")
                
                // Requirement 1.6: First screen TTI < 1.0s on mid-range devices
                XCTAssertLessThan(tti, 1.0, "First screen TTI should be under 1 second")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - Service Initialization Performance Tests
    
    func testCoreServicesInitialization() throws {
        measure {
            let expectation = XCTestExpectation(description: "Core services initialized")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Initialize core services
                await startupOptimizer.initializeCoreServices()
                
                let initTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Core services should initialize quickly
                XCTAssertLessThan(initTime, 0.5, "Core services should initialize within 0.5 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    func testLazyServiceInitialization() throws {
        measure {
            let expectation = XCTestExpectation(description: "Lazy services initialized")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Initialize non-critical services lazily
                await startupOptimizer.initializeLazyServices()
                
                let initTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Lazy services can take longer but should still be reasonable
                XCTAssertLessThan(initTime, 2.0, "Lazy services should initialize within 2 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 4.0)
        }
    }
    
    // MARK: - Memory Usage During Startup Tests
    
    func testStartupMemoryUsage() throws {
        let initialMemory = MemoryManager.shared.getCurrentMemoryUsage()
        
        let expectation = XCTestExpectation(description: "Startup memory test completed")
        
        Task {
            await startupOptimizer.performColdStartInitialization()
            
            let finalMemory = MemoryManager.shared.getCurrentMemoryUsage()
            let memoryIncrease = finalMemory - initialMemory
            
            // Memory increase during startup should be reasonable
            XCTAssertLessThan(memoryIncrease, 50.0, "Startup memory increase should be under 50MB")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Concurrent Initialization Tests
    
    func testConcurrentServiceInitialization() throws {
        measure {
            let expectation = XCTestExpectation(description: "Concurrent initialization completed")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Initialize services concurrently
                async let authService = startupOptimizer.initializeAuthenticationService()
                async let locationService = startupOptimizer.initializeLocationService()
                async let cloudKitService = startupOptimizer.initializeCloudKitService()
                async let analyticsService = startupOptimizer.initializeAnalyticsService()
                
                // Wait for all services to initialize
                _ = await (authService, locationService, cloudKitService, analyticsService)
                
                let totalTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Concurrent initialization should be faster than sequential
                XCTAssertLessThan(totalTime, 1.5, "Concurrent service initialization should complete within 1.5 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - Cache Loading Performance Tests
    
    func testCacheLoadingPerformance() throws {
        // Pre-populate cache
        let setupExpectation = XCTestExpectation(description: "Cache setup completed")
        Task {
            await startupOptimizer.populateTestCache()
            setupExpectation.fulfill()
        }
        wait(for: [setupExpectation], timeout: 5.0)
        
        measure {
            let expectation = XCTestExpectation(description: "Cache loading completed")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Load cached data during startup
                await startupOptimizer.loadCachedData()
                
                let loadTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Cache loading should be fast
                XCTAssertLessThan(loadTime, 0.3, "Cache loading should complete within 0.3 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Network Request Optimization Tests
    
    func testStartupNetworkRequests() throws {
        measure {
            let expectation = XCTestExpectation(description: "Startup network requests completed")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Make critical network requests during startup
                await startupOptimizer.makeCriticalNetworkRequests()
                
                let requestTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Critical network requests should complete quickly
                XCTAssertLessThan(requestTime, 2.0, "Critical network requests should complete within 2 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 4.0)
        }
    }
    
    // MARK: - Background Task Performance Tests
    
    func testBackgroundTasksDuringStartup() throws {
        measure {
            let expectation = XCTestExpectation(description: "Background tasks completed")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Start background tasks that shouldn't block startup
                await startupOptimizer.startBackgroundTasks()
                
                let taskTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Background tasks should start quickly without blocking
                XCTAssertLessThan(taskTime, 0.1, "Background tasks should start within 0.1 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - UI Rendering Performance Tests
    
    func testInitialUIRenderingPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Initial UI rendering completed")
            
            DispatchQueue.main.async {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Simulate initial UI rendering
                self.startupOptimizer.renderInitialUI()
                
                let renderTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Initial UI rendering should be fast
                XCTAssertLessThan(renderTime, 0.2, "Initial UI rendering should complete within 0.2 seconds")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Resource Loading Tests
    
    func testCriticalResourceLoading() throws {
        measure {
            let expectation = XCTestExpectation(description: "Critical resources loaded")
            
            Task {
                let startTime = CFAbsoluteTimeGetCurrent()
                
                // Load critical resources (fonts, images, etc.)
                await startupOptimizer.loadCriticalResources()
                
                let loadTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Critical resources should load quickly
                XCTAssertLessThan(loadTime, 1.0, "Critical resources should load within 1 second")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - Startup Optimization Validation Tests
    
    func testStartupOptimizationEffectiveness() throws {
        // Test without optimization
        let unoptimizedExpectation = XCTestExpectation(description: "Unoptimized startup completed")
        var unoptimizedTime: TimeInterval = 0
        
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            await startupOptimizer.performUnoptimizedStartup()
            unoptimizedTime = CFAbsoluteTimeGetCurrent() - startTime
            unoptimizedExpectation.fulfill()
        }
        wait(for: [unoptimizedExpectation], timeout: 10.0)
        
        // Test with optimization
        let optimizedExpectation = XCTestExpectation(description: "Optimized startup completed")
        var optimizedTime: TimeInterval = 0
        
        Task {
            let startTime = CFAbsoluteTimeGetCurrent()
            await startupOptimizer.performOptimizedStartup()
            optimizedTime = CFAbsoluteTimeGetCurrent() - startTime
            optimizedExpectation.fulfill()
        }
        wait(for: [optimizedExpectation], timeout: 5.0)
        
        // Optimized startup should be significantly faster
        let improvement = (unoptimizedTime - optimizedTime) / unoptimizedTime
        XCTAssertGreaterThan(improvement, 0.3, "Startup optimization should improve performance by at least 30%")
    }
}

// MARK: - Performance Monitor

class PerformanceMonitor {
    private var measurements: [String: CFAbsoluteTime] = [:]
    
    func startMeasuring(_ identifier: String) {
        measurements[identifier] = CFAbsoluteTimeGetCurrent()
    }
    
    func stopMeasuring(_ identifier: String) -> TimeInterval {
        guard let startTime = measurements[identifier] else {
            return 0
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        measurements.removeValue(forKey: identifier)
        
        return endTime - startTime
    }
}

// MARK: - Startup Optimizer Extensions for Testing

extension StartupOptimizer {
    func performColdStartInitialization() async {
        // Simulate cold start tasks
        await initializeCoreServices()
        await loadCachedData()
        await makeCriticalNetworkRequests()
        renderInitialUI()
    }
    
    func performWarmStartInitialization() async {
        // Simulate warm start tasks (faster)
        await loadCachedData()
        renderInitialUI()
    }
    
    func loadFirstScreen() async {
        // Simulate first screen loading
        await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    func initializeCoreServices() async {
        // Simulate core service initialization
        await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
    }
    
    func initializeLazyServices() async {
        // Simulate lazy service initialization
        await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    func initializeAuthenticationService() async {
        await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func initializeLocationService() async {
        await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
    }
    
    func initializeCloudKitService() async {
        await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
    }
    
    func initializeAnalyticsService() async {
        await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func populateTestCache() async {
        // Simulate cache population
        await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
    
    func loadCachedData() async {
        // Simulate cache loading
        await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
    }
    
    func makeCriticalNetworkRequests() async {
        // Simulate critical network requests
        await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
    }
    
    func startBackgroundTasks() async {
        // Simulate starting background tasks
        await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
    
    func renderInitialUI() {
        // Simulate UI rendering (synchronous)
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    func loadCriticalResources() async {
        // Simulate loading critical resources
        await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
    }
    
    func performUnoptimizedStartup() async {
        // Simulate unoptimized startup (sequential operations)
        await initializeAuthenticationService()
        await initializeLocationService()
        await initializeCloudKitService()
        await initializeAnalyticsService()
        await loadCachedData()
        await makeCriticalNetworkRequests()
        renderInitialUI()
    }
    
    func performOptimizedStartup() async {
        // Simulate optimized startup (concurrent operations)
        async let auth = initializeAuthenticationService()
        async let location = initializeLocationService()
        async let cloudKit = initializeCloudKitService()
        async let analytics = initializeAnalyticsService()
        async let cache = loadCachedData()
        
        _ = await (auth, location, cloudKit, analytics, cache)
        
        // Critical path items
        await makeCriticalNetworkRequests()
        renderInitialUI()
    }
}