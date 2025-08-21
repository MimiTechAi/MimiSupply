//
//  CartViewTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import MimiSupply

/// UI tests for CartView functionality
final class CartViewTests: XCTestCase {
    
    var cartViewModel: CartViewModel!
    var mockCartService: MockCartService!
    
    override func setUp() {
        super.setUp()
        mockCartService = MockCartService()
        cartViewModel = CartViewModel(cartService: mockCartService)
    }
    
    override func tearDown() {
        cartViewModel = nil
        mockCartService = nil
        super.tearDown()
    }
    
    // MARK: - Cart State Tests
    
    @MainActor
    func testEmptyCartState() async throws {
        // Given
        mockCartService.mockCartItems = []
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertTrue(cartViewModel.cartItems.isEmpty)
        XCTAssertEqual(cartViewModel.subtotal, 0)
        XCTAssertEqual(cartViewModel.total, cartViewModel.deliveryFee + cartViewModel.platformFee)
    }
    
    @MainActor
    func testCartWithItems() async throws {
        // Given
        let cartItems = [
            createTestCartItem(id: "item-1", quantity: 2, unitPrice: 1200),
            createTestCartItem(id: "item-2", quantity: 1, unitPrice: 800)
        ]
        mockCartService.mockCartItems = cartItems
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertEqual(cartViewModel.cartItems.count, 2)
        XCTAssertEqual(cartViewModel.subtotal, 3200) // (2 * 1200) + (1 * 800)
        XCTAssertGreaterThan(cartViewModel.total, cartViewModel.subtotal)
    }
    
    // MARK: - Item Management Tests
    
    @MainActor
    func testAddItemToCart() async throws {
        // Given
        let newItem = createTestCartItem(id: "new-item", quantity: 1, unitPrice: 1500)
        
        // When
        await cartViewModel.addItem(newItem)
        
        // Then
        XCTAssertTrue(mockCartService.addItemCalled)
        XCTAssertEqual(mockCartService.lastAddedItem?.id, "new-item")
    }
    
    @MainActor
    func testUpdateItemQuantity() async throws {
        // Given
        let existingItem = createTestCartItem(id: "existing-item", quantity: 2, unitPrice: 1000)
        mockCartService.mockCartItems = [existingItem]
        await cartViewModel.loadCartItems()
        
        // When
        await cartViewModel.updateQuantity(for: "existing-item", to: 3)
        
        // Then
        XCTAssertTrue(mockCartService.updateQuantityCalled)
        XCTAssertEqual(mockCartService.lastUpdatedItemId, "existing-item")
        XCTAssertEqual(mockCartService.lastUpdatedQuantity, 3)
    }
    
    @MainActor
    func testRemoveItemFromCart() async throws {
        // Given
        let itemToRemove = createTestCartItem(id: "remove-item", quantity: 1, unitPrice: 1000)
        mockCartService.mockCartItems = [itemToRemove]
        await cartViewModel.loadCartItems()
        
        // When
        await cartViewModel.removeItem("remove-item")
        
        // Then
        XCTAssertTrue(mockCartService.removeItemCalled)
        XCTAssertEqual(mockCartService.lastRemovedItemId, "remove-item")
    }
    
    @MainActor
    func testClearCart() async throws {
        // Given
        let cartItems = [
            createTestCartItem(id: "item-1", quantity: 1, unitPrice: 1000),
            createTestCartItem(id: "item-2", quantity: 2, unitPrice: 500)
        ]
        mockCartService.mockCartItems = cartItems
        await cartViewModel.loadCartItems()
        
        // When
        await cartViewModel.clearCart()
        
        // Then
        XCTAssertTrue(mockCartService.clearCartCalled)
    }
    
    // MARK: - Price Calculation Tests
    
    @MainActor
    func testPriceCalculations() async throws {
        // Given
        let cartItems = [
            createTestCartItem(id: "item-1", quantity: 2, unitPrice: 1000), // $20.00
            createTestCartItem(id: "item-2", quantity: 1, unitPrice: 1500)  // $15.00
        ]
        mockCartService.mockCartItems = cartItems
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertEqual(cartViewModel.subtotal, 3500) // $35.00
        
        let expectedTax = Int(Double(cartViewModel.subtotal) * 0.08) // 8% tax
        XCTAssertEqual(cartViewModel.tax, expectedTax)
        
        let expectedTotal = cartViewModel.subtotal + cartViewModel.deliveryFee + 
                           cartViewModel.platformFee + cartViewModel.tax + cartViewModel.tip
        XCTAssertEqual(cartViewModel.total, expectedTotal)
    }
    
    @MainActor
    func testMinimumOrderAmount() async throws {
        // Given
        let smallOrder = [
            createTestCartItem(id: "small-item", quantity: 1, unitPrice: 500) // $5.00
        ]
        mockCartService.mockCartItems = smallOrder
        cartViewModel.minimumOrderAmount = 1000 // $10.00 minimum
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertFalse(cartViewModel.meetsMinimumOrder)
        XCTAssertTrue(cartViewModel.isCheckoutDisabled)
    }
    
    // MARK: - Checkout Validation Tests
    
    @MainActor
    func testCheckoutValidation() async throws {
        // Given
        let validCartItems = [
            createTestCartItem(id: "item-1", quantity: 2, unitPrice: 1500)
        ]
        mockCartService.mockCartItems = validCartItems
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertTrue(cartViewModel.canProceedToCheckout)
        XCTAssertFalse(cartViewModel.isCheckoutDisabled)
    }
    
    @MainActor
    func testCheckoutValidationEmptyCart() async throws {
        // Given
        mockCartService.mockCartItems = []
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertFalse(cartViewModel.canProceedToCheckout)
        XCTAssertTrue(cartViewModel.isCheckoutDisabled)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testErrorHandlingDuringLoad() async throws {
        // Given
        mockCartService.shouldThrowError = true
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertTrue(cartViewModel.cartItems.isEmpty)
        XCTAssertNotNil(cartViewModel.errorMessage)
    }
    
    @MainActor
    func testErrorHandlingDuringUpdate() async throws {
        // Given
        mockCartService.shouldThrowError = true
        
        // When
        await cartViewModel.updateQuantity(for: "test-item", to: 2)
        
        // Then
        XCTAssertNotNil(cartViewModel.errorMessage)
    }
    
    // MARK: - Special Instructions Tests
    
    @MainActor
    func testUpdateSpecialInstructions() async throws {
        // Given
        let item = createTestCartItem(id: "item-with-instructions")
        mockCartService.mockCartItems = [item]
        await cartViewModel.loadCartItems()
        
        // When
        await cartViewModel.updateSpecialInstructions(
            for: "item-with-instructions",
            instructions: "Extra spicy please"
        )
        
        // Then
        XCTAssertTrue(mockCartService.updateSpecialInstructionsCalled)
        XCTAssertEqual(mockCartService.lastInstructions, "Extra spicy please")
    }
    
    // MARK: - Cart Persistence Tests
    
    @MainActor
    func testCartPersistence() async throws {
        // Given
        let cartItems = [
            createTestCartItem(id: "persistent-item", quantity: 1, unitPrice: 1000)
        ]
        mockCartService.mockCartItems = cartItems
        
        // When
        await cartViewModel.loadCartItems()
        
        // Then
        XCTAssertTrue(mockCartService.loadCartItemsCalled)
        
        // When - app restarts (simulated)
        let newViewModel = CartViewModel(cartService: mockCartService)
        await newViewModel.loadCartItems()
        
        // Then
        XCTAssertEqual(newViewModel.cartItems.count, 1)
        XCTAssertEqual(newViewModel.cartItems.first?.id, "persistent-item")
    }
    
    // MARK: - Helper Methods
    
    private func createTestCartItem(
        id: String = "test-item",
        quantity: Int = 1,
        unitPrice: Int = 1000
    ) -> CartItem {
        return CartItem(
            id: id,
            productId: "product-\(id)",
            productName: "Test Product",
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: unitPrice * quantity,
            specialInstructions: nil
        )
    }
}

// MARK: - Mock Cart Service

class MockCartService: CartServiceProtocol {
    var mockCartItems: [CartItem] = []
    var shouldThrowError = false
    
    // Call tracking
    var loadCartItemsCalled = false
    var addItemCalled = false
    var updateQuantityCalled = false
    var removeItemCalled = false
    var clearCartCalled = false
    var updateSpecialInstructionsCalled = false
    
    // Last operation tracking
    var lastAddedItem: CartItem?
    var lastUpdatedItemId: String?
    var lastUpdatedQuantity: Int?
    var lastRemovedItemId: String?
    var lastInstructions: String?
    
    func getCartItems() async throws -> [CartItem] {
        loadCartItemsCalled = true
        if shouldThrowError {
            throw CartError.loadFailed
        }
        return mockCartItems
    }
    
    func addItem(_ item: CartItem) async throws {
        addItemCalled = true
        lastAddedItem = item
        if shouldThrowError {
            throw CartError.addFailed
        }
        mockCartItems.append(item)
    }
    
    func updateQuantity(for itemId: String, to quantity: Int) async throws {
        updateQuantityCalled = true
        lastUpdatedItemId = itemId
        lastUpdatedQuantity = quantity
        if shouldThrowError {
            throw CartError.updateFailed
        }
        
        if let index = mockCartItems.firstIndex(where: { $0.id == itemId }) {
            let item = mockCartItems[index]
            mockCartItems[index] = CartItem(
                id: item.id,
                productId: item.productId,
                productName: item.productName,
                quantity: quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.unitPrice * quantity,
                specialInstructions: item.specialInstructions
            )
        }
    }
    
    func removeItem(_ itemId: String) async throws {
        removeItemCalled = true
        lastRemovedItemId = itemId
        if shouldThrowError {
            throw CartError.removeFailed
        }
        mockCartItems.removeAll { $0.id == itemId }
    }
    
    func clearCart() async throws {
        clearCartCalled = true
        if shouldThrowError {
            throw CartError.clearFailed
        }
        mockCartItems.removeAll()
    }
    
    func updateSpecialInstructions(for itemId: String, instructions: String?) async throws {
        updateSpecialInstructionsCalled = true
        lastInstructions = instructions
        if shouldThrowError {
            throw CartError.updateFailed
        }
        
        if let index = mockCartItems.firstIndex(where: { $0.id == itemId }) {
            let item = mockCartItems[index]
            mockCartItems[index] = CartItem(
                id: item.id,
                productId: item.productId,
                productName: item.productName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.totalPrice,
                specialInstructions: instructions
            )
        }
    }
    
    func getCartItemCount() async throws -> Int {
        return mockCartItems.reduce(0) { $0 + $1.quantity }
    }
    
    func getCartTotal() async throws -> Int {
        return mockCartItems.reduce(0) { $0 + $1.totalPrice }
    }
}

// MARK: - Cart Error Types

enum CartError: Error, LocalizedError {
    case loadFailed
    case addFailed
    case updateFailed
    case removeFailed
    case clearFailed
    
    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "Failed to load cart items"
        case .addFailed:
            return "Failed to add item to cart"
        case .updateFailed:
            return "Failed to update cart item"
        case .removeFailed:
            return "Failed to remove item from cart"
        case .clearFailed:
            return "Failed to clear cart"
        }
    }
}