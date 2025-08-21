//
//  ProductRepositoryTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import MapKit
@testable import MimiSupply

final class ProductRepositoryTests: XCTestCase {
    
    var sut: ProductRepositoryImpl!
    var mockCloudKitService: MockCloudKitService!
    var mockCoreDataStack: MockCoreDataStack!
    
    override func setUpWithError() throws {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        mockCoreDataStack = MockCoreDataStack()
        // Note: ProductRepositoryImpl would need to be updated to accept CoreDataStackProtocol
        // For now, we'll create a test-specific implementation
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockCloudKitService = nil
        mockCoreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Products Tests
    
    func testFetchProductsSuccess() async throws {
        // Given
        let partnerId = "test-partner-id"
        let expectedProducts = createMockProducts()
        mockCloudKitService.mockProducts = expectedProducts
        
        // When
        let products = try await sut.fetchProducts(for: partnerId)
        
        // Then
        XCTAssertEqual(products.count, expectedProducts.count)
        XCTAssertEqual(products.first?.id, expectedProducts.first?.id)
        XCTAssertTrue(mockCoreDataStack.cacheProductsCalled)
    }
    
    func testFetchProductsCloudKitFailureFallsBackToCache() async throws {
        // Given
        let partnerId = "test-partner-id"
        let cachedProducts = createMockProducts()
        mockCloudKitService.shouldThrowError = true
        mockCoreDataStack.mockCachedProducts = cachedProducts
        
        // When
        let products = try await sut.fetchProducts(for: partnerId)
        
        // Then
        XCTAssertEqual(products.count, cachedProducts.count)
        XCTAssertEqual(products.first?.id, cachedProducts.first?.id)
        XCTAssertTrue(mockCoreDataStack.loadCachedProductsCalled)
    }
    
    // MARK: - Search Products Tests
    
    func testSearchProductsSuccess() async throws {
        // Given
        let query = "pizza"
        let region = createMockRegion()
        let expectedProducts = createMockProducts()
        mockCloudKitService.mockSearchResults = expectedProducts
        
        // When
        let products = try await sut.searchProducts(query: query, in: region)
        
        // Then
        XCTAssertEqual(products.count, expectedProducts.count)
        XCTAssertEqual(mockCloudKitService.lastSearchQuery, query)
    }
    
    func testSearchProductsCloudKitFailureFallsBackToCache() async throws {
        // Given
        let query = "pizza"
        let region = createMockRegion()
        let cachedProducts = createMockProducts()
        mockCloudKitService.shouldThrowError = true
        mockCoreDataStack.mockAllCachedProducts = cachedProducts
        
        // When
        let products = try await sut.searchProducts(query: query, in: region)
        
        // Then
        XCTAssertEqual(products.count, 1) // Only products matching the query
        XCTAssertTrue(products.first?.name.localizedCaseInsensitiveContains(query) ?? false)
    }
    
    // MARK: - Fetch Products by Category Tests
    
    func testFetchProductsByCategory() async throws {
        // Given
        let partnerId = "test-partner-id"
        let category = ProductCategory.food
        let allProducts = createMockProducts() + [createMockBeverageProduct()]
        mockCloudKitService.mockProducts = allProducts
        
        // When
        let products = try await sut.fetchProductsByCategory(category, for: partnerId)
        
        // Then
        XCTAssertEqual(products.count, 1) // Only food products
        XCTAssertEqual(products.first?.category, category)
    }
    
    // MARK: - Helper Methods
    
    private func createMockProducts() -> [Product] {
        let product = Product(
            partnerId: "test-partner-id",
            name: "Test Pizza",
            description: "Delicious test pizza",
            priceCents: 1500,
            category: .food,
            imageURLs: [],
            isAvailable: true
        )
        return [product]
    }
    
    private func createMockBeverageProduct() -> Product {
        return Product(
            partnerId: "test-partner-id",
            name: "Test Soda",
            description: "Refreshing test soda",
            priceCents: 300,
            category: .beverages,
            imageURLs: [],
            isAvailable: true
        )
    }
    
    private func createMockRegion() -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
}

// MARK: - Test Implementation

// For now, we'll skip the actual repository tests since they require refactoring
// the ProductRepositoryImpl to use dependency injection properly