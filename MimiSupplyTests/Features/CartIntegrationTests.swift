//
//  CartIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

@MainActor
final class CartIntegrationTests: XCTestCase {
    
    var cartService: CartService!
    var cartViewModel: CartViewModel!
    var mockCoreDataStack: MockCartCoreDataStack!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCartCoreDataStack()
        cartService = CartService(coreDataStack: mockCoreDataStack)
        cartViewModel = CartViewModel(cartService: cartService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cartService = nil
        cartViewModel = nil
        mockCoreDataStack = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testCompleteCartWorkflow() async throws {
        // Given
        let product1 = createSampleProduct(name: "Pizza", priceCents: 1299) // $12.99
        let product2 = createSampleProduct(name: "Soda", priceCents: 299)   // $2.99
        
        // When - Add items to cart
        try await cartService.addItem(product: product1, quantity: 2) // $25.98
        try await cartService.addItem(product: product2, quantity: 1) // $2.99
        
        await cartViewModel.loadCartItems()
        
        // Then - Verify cart state
        XCTAssertEqual(cartViewModel.cartItems.count, 2)
        XCTAssertEqual(cartViewModel.subtotal, 2897) // $28.97
        
        // Verify free delivery for orders over $25
        XCTAssertEqual(cartViewModel.deliveryFee, 0)
        
        // Verify tax calculation (8.75%)
        let expectedTax = Int(Double(2897) * 0.0875) // ~$2.53
        XCTAssertEqual(cartViewModel.tax, expectedTax)
        
        // Verify tip calculation (15% default)
        let expectedTip = Int(Double(2897) * 0.15) // ~$4.35
        XCTAssertEqual(cartViewModel.tip, expectedTip)
        
        // Verify total calculation
        let expectedTotal = 2897 + 0 + 99 + expectedTax + expectedTip
        XCTAssertEqual(cartViewModel.total, expectedTotal)
    }
    
    func testTipFunctionality() async throws {
        // Given
        let product = createSampleProduct(name: "Test Product", priceCents: 2000) // $20.00
        try await cartService.addItem(product: product, quantity: 1)
        await cartViewModel.loadCartItems()
        
        // When - Update tip to 20%
        cartViewModel.updateTip(percentage: 0.20)
        
        // Then
        XCTAssertEqual(cartViewModel.tip, 400) // $4.00 (20% of $20.00)
        
        // When - Update tip to custom amount
        cartViewModel.updateTip(amount: 500) // $5.00
        
        // Then
        XCTAssertEqual(cartViewModel.tip, 500)
    }
    
    func testCartPersistenceAndRecovery() async throws {
        // Given
        let product1 = createSampleProduct(name: "Persistent Item 1", priceCents: 999)
        let product2 = createSampleProduct(name: "Persistent Item 2", priceCents: 1299)
        
        // When - Add items and simulate app restart
        try await cartService.addItem(product: product1, quantity: 2)
        try await cartService.addItem(product: product2, quantity: 1, specialInstructions: "Extra sauce")
        
        // Simulate app restart
        let newCartService = CartService(coreDataStack: mockCoreDataStack)
        let newCartViewModel = CartViewModel(cartService: newCartService)
        await newCartViewModel.loadCartItems()
        
        // Then - Verify persistence
        XCTAssertEqual(newCartViewModel.cartItems.count, 2)
        XCTAssertEqual(newCartViewModel.cartItems.first?.quantity, 2)
        XCTAssertEqual(newCartViewModel.cartItems.last?.specialInstructions, "Extra sauce")
        XCTAssertEqual(newCartService.cartItemCount, 3)
    }
    
    func testCartLimitsAndValidation() async throws {
        // Test maximum quantity per item
        let product = createSampleProduct(name: "Test Product", priceCents: 999)
        
        do {
            try await cartService.addItem(product: product, quantity: 100)
            XCTFail("Should have thrown invalidQuantity error")
        } catch CartError.invalidQuantity {
            // Expected
        }
        
        // Test stock validation
        let limitedProduct = createSampleProductWithStock(name: "Limited Product", priceCents: 999, stock: 3)
        
        do {
            try await cartService.addItem(product: limitedProduct, quantity: 5)
            XCTFail("Should have thrown insufficientStock error")
        } catch CartError.insufficientStock {
            // Expected
        }
    }
    
    func testCartItemManipulation() async throws {
        // Given
        let product = createSampleProduct(name: "Manipulated Product", priceCents: 1500)
        try await cartService.addItem(product: product, quantity: 3)
        await cartViewModel.loadCartItems()
        
        let itemId = cartViewModel.cartItems.first!.id
        
        // When - Update quantity
        await cartViewModel.updateItemQuantity(itemId: itemId, quantity: 5)
        
        // Then
        XCTAssertEqual(cartViewModel.cartItems.first?.quantity, 5)
        XCTAssertEqual(cartService.cartItemCount, 5)
        
        // When - Remove item
        await cartViewModel.removeItem(withId: itemId)
        
        // Then
        XCTAssertEqual(cartViewModel.cartItems.count, 0)
        XCTAssertEqual(cartService.cartItemCount, 0)
    }
    
    func testPriceCalculationEdgeCases() async throws {
        // Test with zero-price item
        let freeProduct = createSampleProduct(name: "Free Sample", priceCents: 0)
        try await cartService.addItem(product: freeProduct, quantity: 1)
        await cartViewModel.loadCartItems()
        
        XCTAssertEqual(cartViewModel.subtotal, 0)
        XCTAssertEqual(cartViewModel.tax, 0)
        XCTAssertEqual(cartViewModel.tip, 0)
        
        // Test with high-value item
        let expensiveProduct = createSampleProduct(name: "Expensive Item", priceCents: 10000) // $100.00
        try await cartService.addItem(product: expensiveProduct, quantity: 1)
        await cartViewModel.loadCartItems()
        
        // Should get reduced platform fee for orders over $50
        XCTAssertEqual(cartViewModel.platformFee, 49) // $0.49
    }
    
    func testCartStateConsistency() async throws {
        // Given
        let product1 = createSampleProduct(name: "Product 1", priceCents: 1000)
        let product2 = createSampleProduct(name: "Product 2", priceCents: 2000)
        
        // When - Add items through service
        try await cartService.addItem(product: product1, quantity: 2)
        try await cartService.addItem(product: product2, quantity: 1)
        
        // Then - ViewModel should reflect changes
        await cartViewModel.loadCartItems()
        XCTAssertEqual(cartViewModel.cartItems.count, 2)
        XCTAssertEqual(cartService.cartItemCount, 3)
        
        // When - Clear through ViewModel
        await cartViewModel.clearCart()
        
        // Then - Service should be updated
        XCTAssertEqual(cartService.getCartItems().count, 0)
        XCTAssertEqual(cartService.cartItemCount, 0)
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