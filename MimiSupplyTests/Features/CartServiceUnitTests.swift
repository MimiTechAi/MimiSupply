//
//  CartServiceUnitTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

@MainActor
final class CartServiceUnitTests: XCTestCase {
    
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
    
    func testInitialState() {
        // Given & When
        let items = cartService.getCartItems()
        let count = cartService.cartItemCount
        let subtotal = cartService.getSubtotal()
        
        // Then
        XCTAssertEqual(items.count, 0)
        XCTAssertEqual(count, 0)
        XCTAssertEqual(subtotal, 0)
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
    
    func testConvenienceMethods() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        
        // When
        try await cartService.addItem(product: product, quantity: 2)
        
        // Then
        XCTAssertTrue(cartService.containsProduct(product.id))
        XCTAssertEqual(cartService.getProductQuantity(product.id), 2)
        XCTAssertNotNil(cartService.getCartItem(for: product.id))
        XCTAssertEqual(cartService.uniqueItemCount, 1)
        XCTAssertFalse(cartService.isEmpty)
    }
    
    func testAddUnavailableProduct() async {
        // Given
        let product = createUnavailableProduct()
        
        // When & Then
        do {
            try await cartService.addItem(product: product, quantity: 1)
            XCTFail("Should have thrown productUnavailable error")
        } catch CartError.productUnavailable {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAddInvalidQuantity() async {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        
        // When & Then
        do {
            try await cartService.addItem(product: product, quantity: 0)
            XCTFail("Should have thrown invalidQuantity error")
        } catch CartError.invalidQuantity {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAddExcessiveQuantity() async {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        
        // When & Then
        do {
            try await cartService.addItem(product: product, quantity: 100)
            XCTFail("Should have thrown invalidQuantity error")
        } catch CartError.invalidQuantity {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInsufficientStock() async {
        // Given
        let product = createSampleProductWithStock(name: "Limited Product", priceCents: 999, stock: 5)
        
        // When & Then
        do {
            try await cartService.addItem(product: product, quantity: 10)
            XCTFail("Should have thrown insufficientStock error")
        } catch CartError.insufficientStock {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testCartLimitExceeded() async {
        // Given - Fill cart to limit
        for i in 1...50 {
            let product = createSampleProduct(name: "Product \(i)", priceCents: 999)
            try? await cartService.addItem(product: product, quantity: 1)
        }
        
        let extraProduct = createSampleProduct(name: "Extra Product", priceCents: 999)
        
        // When & Then
        do {
            try await cartService.addItem(product: extraProduct, quantity: 1)
            XCTFail("Should have thrown cartLimitExceeded error")
        } catch CartError.cartLimitExceeded {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateQuantityWithStockValidation() async throws {
        // Given
        let product = createSampleProductWithStock(name: "Limited Product", priceCents: 999, stock: 5)
        try await cartService.addItem(product: product, quantity: 2)
        let cartItems = cartService.getCartItems()
        let itemId = cartItems.first!.id
        
        // When & Then
        do {
            try await cartService.updateItemQuantity(itemId: itemId, quantity: 10)
            XCTFail("Should have thrown insufficientStock error")
        } catch CartError.insufficientStock {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSpecialInstructionsHandling() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        let instructions = "Extra spicy please"
        
        // When
        try await cartService.addItem(product: product, quantity: 1, specialInstructions: instructions)
        
        // Then
        let cartItems = cartService.getCartItems()
        XCTAssertEqual(cartItems.first?.specialInstructions, instructions)
        
        // When adding same product with different instructions
        let newInstructions = "No onions"
        try await cartService.addItem(product: product, quantity: 1, specialInstructions: newInstructions)
        
        // Then - should keep original instructions
        let updatedItems = cartService.getCartItems()
        XCTAssertEqual(updatedItems.first?.specialInstructions, instructions)
        XCTAssertEqual(updatedItems.first?.quantity, 2)
    }
    
    // MARK: - Helper Methods
    
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
    
    private func createUnavailableProduct() -> Product {
        return Product(
            id: UUID().uuidString,
            partnerId: "test-partner",
            name: "Unavailable Product",
            description: "Test description",
            priceCents: 999,
            category: .food,
            isAvailable: false
        )
    }
    
    private func createSampleProductWithStock(name: String, priceCents: Int, stock: Int) -> Product {
        return Product(
            id: UUID().uuidString,
            partnerId: "test-partner",
            name: name,
            description: "Test description",
            priceCents: priceCents,
            category: .food,
            stockQuantity: stock
        )
    }
}

// Uses centralized MockCartCoreDataStack defined in `MimiSupplyTests/Mocks/MockServices.swift`