//
//  MemoryPerformanceTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 16.08.25.
//

import XCTest
@testable import MimiSupply

/// Comprehensive memory performance and leak detection tests
final class MemoryPerformanceTests: XCTestCase {
    
    var memoryManager: MemoryManager!
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        memoryManager = MemoryManager.shared
        performanceMonitor = PerformanceMonitor()
    }
    
    override func tearDown() {
        performanceMonitor = nil
        memoryManager = nil
        super.tearDown()
    }
    
    // MARK: - Memory Usage Tests
    
    func testBaselineMemoryUsage() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Baseline memory should be reasonable for a SwiftUI app
        XCTAssertLessThan(initialMemory, 100.0, "Baseline memory usage should be under 100MB")
        XCTAssertGreaterThan(initialMemory, 10.0, "Baseline memory usage should be at least 10MB")
    }
    
    func testMemoryUsageDuringNormalOperation() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Simulate normal app operations
        let expectation = XCTestExpectation(description: "Normal operations completed")
        
        Task {
            // Load partners
            let partners = TestDataFactory.createTestPartners(count: 20)
            
            // Load products
            let products = TestDataFactory.createTestProducts(count: 100)
            
            // Create view models
            var viewModels: [Any] = []
            for partner in partners {
                let viewModel = PartnerDetailViewModel(
                    partner: partner,
                    productRepository: MockProductRepository(),
                    cartService: MockCartService()
                )
                viewModels.append(viewModel)
            }
            
            let currentMemory = self.memoryManager.getCurrentMemoryUsage()
            let memoryIncrease = currentMemory - initialMemory
            
            // Memory increase should be reasonable
            XCTAssertLessThan(memoryIncrease, 50.0, "Memory increase during normal operation should be under 50MB")
            
            // Clean up
            viewModels.removeAll()
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testMemoryUsageWithLargeDataSets() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Large dataset processing completed")
            
            Task {
                let initialMemory = self.memoryManager.getCurrentMemoryUsage()
                
                // Create large dataset
                let (partners, products) = TestDataFactory.createLargeDataSet(
                    partnerCount: 500,
                    productsPerPartner: 100
                )
                
                // Process the data
                let filteredPartners = partners.filter { $0.isActive }
                let availableProducts = products.filter { $0.isAvailable }
                
                let currentMemory = self.memoryManager.getCurrentMemoryUsage()
                let memoryIncrease = currentMemory - initialMemory
                
                // Even with large datasets, memory should be manageable
                XCTAssertLessThan(memoryIncrease, 200.0, "Memory increase with large dataset should be under 200MB")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Memory Leak Detection Tests
    
    func testViewModelMemoryLeaks() throws {
        weak var weakViewModel: ExploreHomeViewModel?
        
        autoreleasepool {
            let viewModel = ExploreHomeViewModel(
                cloudKitService: MockCloudKitService(),
                locationService: MockLocationService()
            )
            weakViewModel = viewModel
            
            // Simulate normal usage
            Task {
                await viewModel.loadInitialData()
            }
        }
        
        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool {
                // Create some temporary objects to trigger GC
                _ = Array(0..<1000).map { _ in NSObject() }
            }
        }
        
        // ViewModel should be deallocated
        XCTAssertNil(weakViewModel, "ExploreHomeViewModel should be deallocated")
    }
    
    func testServiceMemoryLeaks() throws {
        weak var weakService: MockCloudKitService?
        
        autoreleasepool {
            let service = MockCloudKitService()
            weakService = service
            
            // Simulate service usage
            Task {
                _ = try await service.fetchPartners(in: MKCoordinateRegion())
            }
        }
        
        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool {
                _ = Array(0..<1000).map { _ in NSObject() }
            }
        }
        
        // Service should be deallocated
        XCTAssertNil(weakService, "CloudKitService should be deallocated")
    }
    
    func testImageCacheMemoryManagement() throws {
        let imageCache = ImageCache.shared
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Load many images into cache
        let expectation = XCTestExpectation(description: "Images cached")
        expectation.expectedFulfillmentCount = 50
        
        for i in 0..<50 {
            Task {
                let url = URL(string: "https://picsum.photos/200/200?random=\(i)")!
                _ = await imageCache.loadImage(from: url)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
        
        let afterCachingMemory = memoryManager.getCurrentMemoryUsage()
        let memoryIncrease = afterCachingMemory - initialMemory
        
        // Memory increase should be reasonable even with many cached images
        XCTAssertLessThan(memoryIncrease, 100.0, "Image cache memory usage should be under 100MB")
        
        // Clear cache and verify memory is released
        imageCache.clearCache()
        
        // Allow time for cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let afterClearMemory = self.memoryManager.getCurrentMemoryUsage()
            let memoryReduction = afterCachingMemory - afterClearMemory
            
            // Should see significant memory reduction after clearing cache
            XCTAssertGreaterThan(memoryReduction, memoryIncrease * 0.5, "Should release at least 50% of cached memory")
        }
    }
    
    // MARK: - Memory Pressure Tests
    
    func testMemoryPressureHandling() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Simulate memory pressure
        memoryManager.simulateMemoryPressure()
        
        let expectation = XCTestExpectation(description: "Memory pressure handled")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let currentMemory = self.memoryManager.getCurrentMemoryUsage()
            
            // Memory usage should be reduced after pressure handling
            XCTAssertLessThan(currentMemory, initialMemory + 20.0, "Memory should be managed under pressure")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLowMemoryWarningResponse() throws {
        let imageCache = ImageCache.shared
        let initialCacheSize = imageCache.currentCacheSize
        
        // Fill cache with images
        let expectation = XCTestExpectation(description: "Cache filled")
        expectation.expectedFulfillmentCount = 20
        
        for i in 0..<20 {
            Task {
                let url = URL(string: "https://picsum.photos/300/300?random=\(i)")!
                _ = await imageCache.loadImage(from: url)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        let filledCacheSize = imageCache.currentCacheSize
        XCTAssertGreaterThan(filledCacheSize, initialCacheSize)
        
        // Simulate low memory warning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        // Allow time for cleanup
        let cleanupExpectation = XCTestExpectation(description: "Memory warning handled")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let afterWarningCacheSize = imageCache.currentCacheSize
            
            // Cache should be reduced after memory warning
            XCTAssertLessThan(afterWarningCacheSize, filledCacheSize, "Cache should be reduced after memory warning")
            
            cleanupExpectation.fulfill()
        }
        
        wait(for: [cleanupExpectation], timeout: 3.0)
    }
    
    // MARK: - Retain Cycle Detection Tests
    
    func testViewModelRetainCycles() throws {
        weak var weakExploreViewModel: ExploreHomeViewModel?
        weak var weakPartnerViewModel: PartnerDetailViewModel?
        weak var weakCartViewModel: CartViewModel?
        
        autoreleasepool {
            let exploreViewModel = ExploreHomeViewModel(
                cloudKitService: MockCloudKitService(),
                locationService: MockLocationService()
            )
            weakExploreViewModel = exploreViewModel
            
            let partner = TestDataFactory.createTestPartner()
            let partnerViewModel = PartnerDetailViewModel(
                partner: partner,
                productRepository: MockProductRepository(),
                cartService: MockCartService()
            )
            weakPartnerViewModel = partnerViewModel
            
            let cartViewModel = CartViewModel(cartService: MockCartService())
            weakCartViewModel = cartViewModel
            
            // Simulate interactions that might create retain cycles
            Task {
                await exploreViewModel.loadInitialData()
                await partnerViewModel.loadProducts()
            }
        }
        
        // Force multiple GC cycles
        for _ in 0..<5 {
            autoreleasepool {
                _ = Array(0..<1000).map { _ in NSObject() }
            }
        }
        
        // All view models should be deallocated
        XCTAssertNil(weakExploreViewModel, "ExploreHomeViewModel should not have retain cycles")
        XCTAssertNil(weakPartnerViewModel, "PartnerDetailViewModel should not have retain cycles")
        XCTAssertNil(weakCartViewModel, "CartViewModel should not have retain cycles")
    }
    
    func testCombinePublisherRetainCycles() throws {
        weak var weakService: MockCloudKitService?
        weak var weakSubscriber: TestSubscriber?
        
        autoreleasepool {
            let service = MockCloudKitService()
            let subscriber = TestSubscriber()
            
            weakService = service
            weakSubscriber = subscriber
            
            // Create publisher subscription that might cause retain cycle
            subscriber.subscribeToService(service)
            
            // Simulate some operations
            Task {
                _ = try await service.fetchPartners(in: MKCoordinateRegion())
            }
        }
        
        // Force garbage collection
        for _ in 0..<3 {
            autoreleasepool {
                _ = Array(0..<1000).map { _ in NSObject() }
            }
        }
        
        // Both objects should be deallocated
        XCTAssertNil(weakService, "Service should not have retain cycles with publishers")
        XCTAssertNil(weakSubscriber, "Subscriber should not have retain cycles")
    }
    
    // MARK: - Memory Allocation Pattern Tests
    
    func testMemoryAllocationPatterns() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        var memoryReadings: [Double] = []
        
        // Perform operations and track memory
        for i in 0..<10 {
            autoreleasepool {
                // Create and process data
                let partners = TestDataFactory.createTestPartners(count: 50)
                let products = TestDataFactory.createTestProducts(count: 200)
                
                // Process the data
                _ = partners.filter { $0.rating > 4.0 }
                _ = products.filter { $0.isAvailable }
                
                let currentMemory = self.memoryManager.getCurrentMemoryUsage()
                memoryReadings.append(currentMemory)
            }
        }
        
        // Analyze memory allocation patterns
        let maxMemory = memoryReadings.max() ?? 0
        let minMemory = memoryReadings.min() ?? 0
        let memoryVariation = maxMemory - minMemory
        
        // Memory variation should be reasonable (not constantly growing)
        XCTAssertLessThan(memoryVariation, 50.0, "Memory variation should be under 50MB")
        
        // Final memory should be close to initial (no major leaks)
        let finalMemory = memoryManager.getCurrentMemoryUsage()
        let totalIncrease = finalMemory - initialMemory
        XCTAssertLessThan(totalIncrease, 30.0, "Total memory increase should be under 30MB")
    }
    
    // MARK: - Background Memory Management Tests
    
    func testBackgroundMemoryManagement() throws {
        let initialMemory = memoryManager.getCurrentMemoryUsage()
        
        // Simulate app going to background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        let expectation = XCTestExpectation(description: "Background memory management completed")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let backgroundMemory = self.memoryManager.getCurrentMemoryUsage()
            
            // Memory should be optimized for background state
            XCTAssertLessThanOrEqual(backgroundMemory, initialMemory, "Memory should not increase in background")
            
            // Simulate app returning to foreground
            NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let foregroundMemory = self.memoryManager.getCurrentMemoryUsage()
                
                // Memory should be reasonable when returning to foreground
                XCTAssertLessThan(foregroundMemory, initialMemory + 20.0, "Foreground memory should be reasonable")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Memory Profiling Tests
    
    func testMemoryProfileDuringScrolling() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Scrolling simulation completed")
            
            Task {
                // Simulate scrolling through a large list
                let partners = TestDataFactory.createTestPartners(count: 1000)
                
                // Simulate lazy loading during scroll
                for i in stride(from: 0, to: partners.count, by: 20) {
                    let batch = Array(partners[i..<min(i + 20, partners.count)])
                    
                    // Process batch (simulate cell creation/destruction)
                    _ = batch.map { partner in
                        PartnerCard(partner: partner) {}
                    }
                    
                    // Small delay to simulate scroll timing
                    try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testMemoryProfileDuringImageLoading() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Image loading completed")
            expectation.expectedFulfillmentCount = 100
            
            let imageCache = ImageCache.shared
            
            // Load many images concurrently
            for i in 0..<100 {
                Task {
                    let url = URL(string: "https://picsum.photos/400/300?random=\(i)")!
                    _ = await imageCache.loadImage(from: url)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 15.0)
        }
    }
}

// MARK: - Test Helper Classes

class TestSubscriber {
    private var cancellables = Set<AnyCancellable>()
    
    func subscribeToService(_ service: MockCloudKitService) {
        // Create a subscription that might cause retain cycles
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                // Simulate periodic operations
                self?.handleTimerEvent()
            }
            .store(in: &cancellables)
    }
    
    private func handleTimerEvent() {
        // Simulate some work
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Memory Manager Extensions

extension MemoryManager {
    func getCurrentMemoryUsage() -> Double {
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
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
    
    func simulateMemoryPressure() {
        // Trigger memory management routines
        ImageCache.shared.handleMemoryPressure()
        
        // Post memory warning notification
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
}

extension ImageCache {
    var currentCacheSize: Int {
        return cache.totalCostLimit
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
    
    func handleMemoryPressure() {
        // Reduce cache size under memory pressure
        cache.totalCostLimit = cache.totalCostLimit / 2
        cache.removeAllObjects()
    }
}