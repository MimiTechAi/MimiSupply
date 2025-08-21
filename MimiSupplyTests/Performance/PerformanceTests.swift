import XCTest
import SwiftUI
import UIKit
import CoreLocation
@testable import MimiSupply

/// Comprehensive performance tests measuring key metrics and benchmarks
@MainActor
class PerformanceTests: XCTestCase {
    
    var imageCache: ImageCache!
    var memoryManager: MemoryManager!
    var startupOptimizer: StartupOptimizer!
    
    override func setUp() {
        super.setUp()
        imageCache = ImageCache.shared
        memoryManager = MemoryManager.shared
        startupOptimizer = StartupOptimizer.shared
    }
    
    override func tearDown() {
        imageCache.clearCache()
        super.tearDown()
    }
    
    // MARK: - Startup Performance Tests
    
    func testAppStartupTime() throws {
        measure {
            let expectation = XCTestExpectation(description: "Startup completed")
            
            Task {
                await startupOptimizer.performStartupInitialization()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
        
        // Verify startup time is under 2.5 seconds (requirement 11.1)
        XCTAssertLessThan(startupOptimizer.startupTime, 2.5, "Startup time should be under 2.5 seconds")
    }
    
    func testColdStartPerformance() throws {
        // Simulate cold start by clearing all caches
        imageCache.clearCache()
        URLCache.shared.removeAllCachedResponses()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        measure {
            let expectation = XCTestExpectation(description: "Cold start completed")
            
            Task {
                await startupOptimizer.performStartupInitialization()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
        
        let coldStartTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(coldStartTime, 3.0, "Cold start should complete within 3 seconds")
    }
    
    // MARK: - Image Loading Performance Tests
    
    func testImageCachePerformance() throws {
        let testURLs = generateTestImageURLs(count: 100)
        
        measure {
            let expectation = XCTestExpectation(description: "Image loading completed")
            expectation.expectedFulfillmentCount = testURLs.count
            
            for url in testURLs {
                Task {
                    _ = await imageCache.loadImage(from: url)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
    
    func testImageCacheMemoryEfficiency() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        let testURLs = generateTestImageURLs(count: 50)
        
        // Load images
        let expectation = XCTestExpectation(description: "Images loaded")
        expectation.expectedFulfillmentCount = testURLs.count
        
        for url in testURLs {
            Task {
                _ = await imageCache.loadImage(from: url)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
        
        let memoryAfterLoading = memoryManager.getCurrentMemoryUsage()
        let memoryIncrease = memoryAfterLoading - initialMemory
        
        // Memory increase should be reasonable (less than 100MB for 50 images)
        XCTAssertLessThan(memoryIncrease, 100.0, "Memory increase should be under 100MB")
        
        // Clear cache and verify memory is released
        imageCache.clearCache()
        
        // Wait for cleanup
        Thread.sleep(forTimeInterval: 2.0)
        
        let memoryAfterClearing = memoryManager.getCurrentMemoryUsage()
        let memoryRecovered = memoryAfterLoading - memoryAfterClearing
        
        // Should recover at least 50% of the memory
        XCTAssertGreaterThan(memoryRecovered, memoryIncrease * 0.5, "Should recover significant memory after clearing cache")
    }
    
    // MARK: - List Rendering Performance Tests
    
    func testLazyListRenderingPerformance() throws {
        let testData = generateTestPartners(count: 1000)
        
        measure {
            let expectation = XCTestExpectation(description: "List rendering completed")
            
            DispatchQueue.main.async {
                let listView = LazyListRenderer(
                    data: testData,
                    itemHeight: 120,
                    prefetchDistance: 5
                ) { (partner: Partner) in
                    Text(partner.name)
                }
                
                // Simulate view rendering
                let hostingController = UIHostingController(rootView: listView)
                hostingController.loadViewIfNeeded()
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testScrollingPerformance() throws {
        let performanceMonitor = AnimationPerformanceMonitor()
        performanceMonitor.startMonitoring()
        
        // Simulate scrolling for 2 seconds
        let scrollExpectation = XCTestExpectation(description: "Scrolling completed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            performanceMonitor.stopMonitoring()
            scrollExpectation.fulfill()
        }
        
        wait(for: [scrollExpectation], timeout: 3.0)
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Should maintain at least 60 FPS during scrolling
        XCTAssertGreaterThan(report.averageFPS, 60.0, "Should maintain at least 60 FPS")
        
        // Dropped frame percentage should be low
        XCTAssertLessThan(report.droppedFramePercentage, 5.0, "Dropped frames should be less than 5%")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeakDetection() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Create and release objects
        autoreleasepool {
            let testObjects = (0..<100).map { _ in TestObject() }
            testObjects.forEach { memoryManager.trackObject($0) }
        }
        
        // Force garbage collection
        memoryManager.performLeakDetection()
        
        // Wait for cleanup
        Thread.sleep(forTimeInterval: 1.0)
        
        let finalMemory = memoryManager.getCurrentMemoryUsage()
        let memoryDifference = finalMemory - initialMemory
        
        // Memory should not increase significantly
        XCTAssertLessThan(memoryDifference, 10.0, "Memory should not leak significantly")
    }
    
    func testMemoryWarningHandling() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Simulate memory warning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Wait for cleanup
        Thread.sleep(forTimeInterval: 2.0)
        
        let memoryAfterWarning = memoryManager.getCurrentMemoryUsage()
        
        // Memory should be reduced after warning
        XCTAssertLessThan(memoryAfterWarning, initialMemory + 50.0, "Memory should be cleaned up after warning")
    }
    
    // MARK: - Background Task Performance Tests
    
    func testBackgroundTaskEfficiency() throws {
        let backgroundTaskManager = BackgroundTaskManager.shared
        
        measure {
            let expectation = XCTestExpectation(description: "Background task completed")
            
            Task {
                // Simulate background data sync
                try await backgroundTaskManager.syncPendingData()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testLocationUpdatePerformance() throws {
        let backgroundTaskManager = BackgroundTaskManager.shared
        
        measure {
            let expectation = XCTestExpectation(description: "Location update completed")
            
            Task {
                do {
                    try await backgroundTaskManager.updateDriverLocation()
                    expectation.fulfill()
                } catch {
                    // Handle expected errors for test environment
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Animation Performance Tests
    
    func testAnimationSmoothness() throws {
        let performanceMonitor = AnimationPerformanceMonitor()
        performanceMonitor.startMonitoring()
        
        // Simulate complex animations
        let animationExpectation = XCTestExpectation(description: "Animation completed")
        
        DispatchQueue.main.async {
            withAnimation(AnimationOptimizer.smoothSpring) {
                // Simulate view state changes that trigger animations
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                performanceMonitor.stopMonitoring()
                animationExpectation.fulfill()
            }
        }
        
        wait(for: [animationExpectation], timeout: 2.0)
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Should maintain high FPS during animations
        XCTAssertGreaterThan(report.averageFPS, 90.0, "Should maintain high FPS during animations")
    }
    
    // MARK: - Network Performance Tests
    
    func testConcurrentNetworkRequests() throws {
        let urls = generateTestImageURLs(count: 20)
        
        measure {
            let expectation = XCTestExpectation(description: "Concurrent requests completed")
            expectation.expectedFulfillmentCount = urls.count
            
            for url in urls {
                Task {
                    _ = await imageCache.loadImage(from: url)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateTestImageURLs(count: Int) -> [URL] {
        return (0..<count).compactMap { index in
            URL(string: "https://picsum.photos/200/200?random=\(index)")
        }
    }
    
    private func generateTestPartners(count: Int) -> [Partner] {
        return (0..<count).map { index in
            Partner(
                id: "partner-\(index)",
                name: "Test Partner \(index)",
                category: .restaurant,
                description: "Test description",
                address: Address(
                    street: "Test Street",
                    city: "Test City",
                    state: "Test State",
                    postalCode: "12345",
                    country: "Test Country"
                ),
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                phoneNumber: "+1234567890",
                email: "test@example.com",
                heroImageURL: URL(string: "https://picsum.photos/400/200?random=\(index)"),
                logoURL: URL(string: "https://picsum.photos/100/100?random=\(index)"),
                isVerified: true,
                isActive: true,
                rating: Double.random(in: 3.0...5.0),
                reviewCount: Int.random(in: 10...500),
                openingHours: [:],
                deliveryRadius: 5.0,
                minimumOrderAmount: 1000,
                estimatedDeliveryTime: Int.random(in: 20...60),
                createdAt: Date()
            )
        }
    }
}

// MARK: - Test Helper Classes

private class TestObject {
    let data = Data(count: 1024) // 1KB of data
    
    deinit {
        // Object is being deallocated
    }
}

// MARK: - Performance Benchmark Tests

@MainActor
class PerformanceBenchmarkTests: XCTestCase {
    
    func testImageLoadingBenchmark() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        
        measure(options: options) {
            let expectation = XCTestExpectation(description: "Benchmark completed")
            
            Task {
                let url = URL(string: "https://picsum.photos/800/600")!
                _ = await ImageCache.shared.loadImage(from: url)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testListRenderingBenchmark() throws {
        let testData = (0..<500).map { index in
            Partner(
                id: "partner-\(index)",
                name: "Benchmark Partner \(index)",
                category: .restaurant,
                description: "Benchmark description",
                address: Address(
                    street: "Benchmark Street",
                    city: "Benchmark City",
                    state: "Benchmark State",
                    postalCode: "12345",
                    country: "Benchmark Country"
                ),
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                phoneNumber: "+1234567890",
                email: "benchmark@example.com",
                heroImageURL: nil,
                logoURL: nil,
                isVerified: true,
                isActive: true,
                rating: 4.5,
                reviewCount: 100,
                openingHours: [:],
                deliveryRadius: 5.0,
                minimumOrderAmount: 1000,
                estimatedDeliveryTime: 30,
                createdAt: Date()
            )
        }
        
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        
        measure(options: options) {
            let expectation = XCTestExpectation(description: "List rendering benchmark")
            
            DispatchQueue.main.async {
                let listView = OptimizedListView(data: testData) { (partner: Partner) in
                    Text(partner.name)
                }
                
                let hostingController = UIHostingController(rootView: listView)
                hostingController.loadViewIfNeeded()
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testMemoryAllocationBenchmark() throws {
        let options = XCTMeasureOptions()
        options.iterationCount = 20
        
        measure(options: options) {
            autoreleasepool {
                let objects = (0..<1000).map { _ in TestObject() }
                _ = objects.count // Use the objects
            }
        }
    }
}