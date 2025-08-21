//
//  PartnerDetailViewTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

@MainActor
final class PartnerDetailViewTests: XCTestCase {
    
    var viewModel: PartnerDetailViewModel!
    var mockProductRepository: MockProductRepository!
    var mockCartService: MockCartService!
    var samplePartner: Partner!
    
    override func setUp() {
        super.setUp()
        
        samplePartner = Partner(
            name: "Test Restaurant",
            category: .restaurant,
            description: "Test description",
            address: Address(
                street: "123 Test St",
                city: "Test City",
                state: "TS",
                postalCode: "12345",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "test@example.com"
        )
        
        mockProductRepository = MockProductRepository()
        mockCartService = MockCartService()
        
        viewModel = PartnerDetailViewModel(
            partner: samplePartner,
            productRepository: mockProductRepository,
            cartService: mockCartService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockProductRepository = nil
        mockCartService = nil
        samplePartner = nil
        super.tearDown()
    }
    
    func testLoadProducts() async throws {
        // Given
        let sampleProducts = [
            Product(
                partnerId: samplePartner.id,
                name: "Test Product 1",
                description: "Description 1",
                priceCents: 999,
                category: .food
            ),
            Product(
                partnerId: samplePartner.id,
                name: "Test Product 2",
                description: "Description 2",
                priceCents: 1299,
                category: .beverages
            )
        ]
        mockProductRepository.mockProducts = sampleProducts
        
        // When
        await viewModel.loadProducts()
        
        // Then
        XCTAssertEqual(viewModel.allProducts.count, 2)
        XCTAssertEqual(viewModel.filteredProducts.count, 2)
        XCTAssertEqual(viewModel.productCategories.count, 2)
        XCTAssertTrue(viewModel.productCategories.contains(.food))
        XCTAssertTrue(viewModel.productCategories.contains(.beverages))
    }
    
    func testProductCategoryFiltering() async throws {
        // Given
        let sampleProducts = [
            Product(
                partnerId: samplePartner.id,
                name: "Pizza",
                description: "Delicious pizza",
                priceCents: 1299,
                category: .food
            ),
            Product(
                partnerId: samplePartner.id,
                name: "Soda",
                description: "Refreshing drink",
                priceCents: 299,
                category: .beverages
            )
        ]
        mockProductRepository.mockProducts = sampleProducts
        await viewModel.loadProducts()
        
        // When
        viewModel.selectProductCategory(.food)
        
        // Then
        XCTAssertEqual(viewModel.filteredProducts.count, 1)
        XCTAssertEqual(viewModel.filteredProducts.first?.name, "Pizza")
        XCTAssertEqual(viewModel.selectedProductCategory, .food)
    }
    
    func testProductSearch() async throws {
        // Given
        let sampleProducts = [
            Product(
                partnerId: samplePartner.id,
                name: "Margherita Pizza",
                description: "Classic pizza with tomato and mozzarella",
                priceCents: 1299,
                category: .food
            ),
            Product(
                partnerId: samplePartner.id,
                name: "Pepperoni Pizza",
                description: "Pizza with pepperoni",
                priceCents: 1499,
                category: .food
            ),
            Product(
                partnerId: samplePartner.id,
                name: "Caesar Salad",
                description: "Fresh salad with caesar dressing",
                priceCents: 899,
                category: .food
            )
        ]
        mockProductRepository.mockProducts = sampleProducts
        await viewModel.loadProducts()
        
        // When
        viewModel.searchText = "pizza"
        await viewModel.searchProducts(query: "pizza")
        
        // Then
        XCTAssertEqual(viewModel.filteredProducts.count, 2)
        XCTAssertTrue(viewModel.filteredProducts.allSatisfy { 
            $0.name.localizedCaseInsensitiveContains("pizza") 
        })
    }
    
    func testAddToCart() async throws {
        // Given
        let product = Product(
            partnerId: samplePartner.id,
            name: "Test Product",
            description: "Test description",
            priceCents: 999,
            category: .food
        )
        
        // When
        await viewModel.addToCart(product: product, quantity: 2)
        
        // Then
        XCTAssertEqual(mockCartService.addItemCallCount, 1)
        XCTAssertEqual(mockCartService.lastAddedProduct?.name, "Test Product")
        XCTAssertEqual(mockCartService.lastAddedQuantity, 2)
    }
    
    func testGetProductCountForCategory() async throws {
        // Given
        let sampleProducts = [
            Product(partnerId: samplePartner.id, name: "Food 1", description: "", priceCents: 999, category: .food),
            Product(partnerId: samplePartner.id, name: "Food 2", description: "", priceCents: 1299, category: .food),
            Product(partnerId: samplePartner.id, name: "Drink 1", description: "", priceCents: 299, category: .beverages)
        ]
        mockProductRepository.mockProducts = sampleProducts
        await viewModel.loadProducts()
        
        // When & Then
        XCTAssertEqual(viewModel.getProductCount(for: .food), 2)
        XCTAssertEqual(viewModel.getProductCount(for: .beverages), 1)
        XCTAssertEqual(viewModel.getProductCount(for: .medicine), 0)
    }
}

// MARK: - Mock Classes

class MockProductRepository: ProductRepository {
    var mockProducts: [Product] = []
    var shouldThrowError = false
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: nil)
        }
        return mockProducts.filter { $0.partnerId == partnerId }
    }
    
    func fetchProduct(by id: String) async throws -> Product? {
        return mockProducts.first { $0.id == id }
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        return mockProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(query) ||
            product.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    func fetchProductsByCategory(_ category: ProductCategory, for partnerId: String) async throws -> [Product] {
        return mockProducts.filter { $0.category == category && $0.partnerId == partnerId }
    }
}

class MockCartService: CartService {
    var addItemCallCount = 0
    var lastAddedProduct: Product?
    var lastAddedQuantity: Int = 0
    var mockCartItems: [CartItem] = []
    
    override func addItem(product: Product, quantity: Int) async throws {
        addItemCallCount += 1
        lastAddedProduct = product
        lastAddedQuantity = quantity
        
        let cartItem = CartItem(product: product, quantity: quantity)
        mockCartItems.append(cartItem)
    }
    
    override func getCartItems() -> [CartItem] {
        return mockCartItems
    }
}