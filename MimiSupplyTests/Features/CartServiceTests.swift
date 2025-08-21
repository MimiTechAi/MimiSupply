//
//  CartServiceTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

@MainActor
final class CartServiceTests: XCTestCase {
    
    var cartService: CartService!
    var mockCoreDataStack: MockCartCoreDataStack!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCartCoreDataStack()
        cartService = CartService(coreDataStack: mockCoreDataStack)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cartService = nil
        mockCoreDataStack = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testAddNewItem() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        
        // When
        try await cartService.addItem(product: product, quantity: 2)
        
        // Then
        let cartItems = cartService.getCartItems()
        XCTAssertEqual(cartItems.count, 1)
        XCTAssertEqual(cartItems.first?.product.name, "Test Product")
        XCTAssertEqual(cartItems.first?.quantity, 2)
        XCTAssertEqual(cartService.cartItemCount, 2)
    }
    
    func testAddExistingItem() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        try await cartService.addItem(product: product, quantity: 1)
        
        // When
        try await cartService.addItem(product: product, quantity: 2)
        
        // Then
        let cartItems = cartService.getCartItems()
        XCTAssertEqual(cartItems.count, 1)
        XCTAssertEqual(cartItems.first?.quantity, 3)
        XCTAssertEqual(cartService.cartItemCount, 3)
    }
    
    func testRemoveItem() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        try await cartService.addItem(product: product, quantity: 2)
        let cartItems = cartService.getCartItems()
        let itemId = cartItems.first!.id
        
        // When
        try await cartService.removeItem(withId: itemId)
        
        // Then
        XCTAssertEqual(cartService.getCartItems().count, 0)
        XCTAssertEqual(cartService.cartItemCount, 0)
    }
    
    func testUpdateItemQuantity() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        try await cartService.addItem(product: product, quantity: 2)
        let cartItems = cartService.getCartItems()
        let itemId = cartItems.first!.id
        
        // When
        try await cartService.updateItemQuantity(itemId: itemId, quantity: 5)
        
        // Then
        let updatedItems = cartService.getCartItems()
        XCTAssertEqual(updatedItems.first?.quantity, 5)
        XCTAssertEqual(cartService.cartItemCount, 5)
    }
    
    func testUpdateItemQuantityToZero() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        try await cartService.addItem(product: product, quantity: 2)
        let cartItems = cartService.getCartItems()
        let itemId = cartItems.first!.id
        
        // When
        try await cartService.updateItemQuantity(itemId: itemId, quantity: 0)
        
        // Then
        XCTAssertEqual(cartService.getCartItems().count, 0)
        XCTAssertEqual(cartService.cartItemCount, 0)
    }
    
    func testClearCart() async throws {
        // Given
        let product1 = createSampleProduct(name: "Product 1", priceCents: 999)
        let product2 = createSampleProduct(name: "Product 2", priceCents: 1299)
        try await cartService.addItem(product: product1, quantity: 1)
        try await cartService.addItem(product: product2, quantity: 2)
        
        // When
        try await cartService.clearCart()
        
        // Then
        XCTAssertEqual(cartService.getCartItems().count, 0)
        XCTAssertEqual(cartService.cartItemCount, 0)
    }
    
    func testGetSubtotal() async throws {
        // Given
        let product1 = createSampleProduct(name: "Product 1", priceCents: 999)  // $9.99
        let product2 = createSampleProduct(name: "Product 2", priceCents: 1299) // $12.99
        try await cartService.addItem(product: product1, quantity: 2) // $19.98
        try await cartService.addItem(product: product2, quantity: 1) // $12.99
        
        // When
        let subtotal = cartService.getSubtotal()
        
        // Then
        XCTAssertEqual(subtotal, 3297) // $32.97 in cents
    }
    
    func testCartItemCountPublisher() async throws {
        // Given
        var receivedCounts: [Int] = []
        let expectation = XCTestExpectation(description: "Cart item count updates")
        expectation.expectedFulfillmentCount = 3
        
        cartService.cartItemCountPublisher
            .sink { count in
                receivedCounts.append(count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        
        // When
        try await cartService.addItem(product: product, quantity: 2)
        try await cartService.addItem(product: product, quantity: 1)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts, [0, 2, 3])
    }
    
    // MARK: - Helper Methods
    
    func testCartPersistenceAcrossSessions() async throws {
        // Given
        let product = createSampleProduct(name: "Persistent Product", priceCents: 1299)
        try await cartService.addItem(product: product, quantity: 3)
        
        // When - simulate app restart by creating new cart service
        let newCartService = CartService(coreDataStack: mockCoreDataStack)
        
        // Then
        let persistedItems = newCartService.getCartItems()
        XCTAssertEqual(persistedItems.count, 1)
        XCTAssertEqual(persistedItems.first?.product.name, "Persistent Product")
        XCTAssertEqual(persistedItems.first?.quantity, 3)
        XCTAssertEqual(newCartService.cartItemCount, 3)
    }
    
    func testCartItemCountBadgeUpdates() async throws {
        // Given
        var receivedCounts: [Int] = []
        let expectation = XCTestExpectation(description: "Badge count updates")
        expectation.expectedFulfillmentCount = 4
        
        cartService.cartItemCountPublisher
            .sink { count in
                receivedCounts.append(count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let product1 = createSampleProduct(name: "Product 1", priceCents: 999)
        let product2 = createSampleProduct(name: "Product 2", priceCents: 1299)
        
        // When
        try await cartService.addItem(product: product1, quantity: 2)
        try await cartService.addItem(product: product2, quantity: 1)
        try await cartService.clearCart()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts, [0, 2, 3, 0])
    }
    
    func testEmptyCartState() {
        // Given & When
        let items = cartService.getCartItems()
        let count = cartService.cartItemCount
        let subtotal = cartService.getSubtotal()
        let isEmpty = cartService.isEmpty
        let uniqueCount = cartService.uniqueItemCount
        
        // Then
        XCTAssertEqual(items.count, 0)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(subtotal, 0)
        XCTAssertTrue(isEmpty)
        XCTAssertEqual(uniqueCount, 0)
    }
    
    private func createSampleProduct(name: String, priceCents: Int) -> Product {
        return Product(
            id: UUID().uuidString,
            partnerId: "test-partner",
            name: name,
            description: "Test description",
            priceCents: priceCents,
            category: .food
        )
    }
}

// Uses centralized MockCartCoreDataStack defined in `MimiSupplyTests/Mocks/MockServices.swift`