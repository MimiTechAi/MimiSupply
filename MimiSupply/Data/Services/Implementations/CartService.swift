//
//  CartService.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import Combine

/// Cart service implementation with local CoreData persistence
@MainActor
final class CartService: CartServiceProtocol, ObservableObject {
    
    // MARK: - Singleton
    static let shared = CartService()
    
    // MARK: - Published Properties
    @Published var cartItems: [CartItem] = []
    @Published var cartItemCount: Int = 0
    
    // MARK: - Private Properties
    private let coreDataStack: CoreDataStack
    private let cartItemCountSubject = CurrentValueSubject<Int, Never>(0)
    
    // MARK: - Public Properties
    var cartItemCountPublisher: AnyPublisher<Int, Never> {
        cartItemCountSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Constants
    private let maxCartItems: Int = 50 // Maximum items in cart
    private let maxItemQuantity: Int = 99 // Maximum quantity per item
    
    // MARK: - Initialization
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
        loadCartItemsFromStorage()
    }
    
    // MARK: - CartServiceProtocol Implementation
    
    func addItem(product: Product, quantity: Int = 1, specialInstructions: String? = nil) async throws {
        // Validate inputs
        guard quantity > 0 else {
            throw CartError.invalidQuantity
        }
        
        guard quantity <= maxItemQuantity else {
            throw CartError.invalidQuantity
        }
        
        guard product.isAvailable else {
            throw CartError.productUnavailable
        }
        
        // Check cart item limit
        if !containsProduct(product.id) && cartItems.count >= maxCartItems {
            throw CartError.cartLimitExceeded
        }
        
        // Check stock if available
        if let stockQuantity = product.stockQuantity {
            let currentQuantityInCart = getProductQuantity(product.id)
            let totalQuantity = currentQuantityInCart + quantity
            guard totalQuantity <= stockQuantity else {
                throw CartError.insufficientStock
            }
        }
        
        // Check if item already exists in cart
        if let existingItemIndex = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            // Update existing item quantity
            let existingItem = cartItems[existingItemIndex]
            let newQuantity = existingItem.quantity + quantity
            cartItems[existingItemIndex] = CartItem(
                id: existingItem.id,
                product: product,
                quantity: newQuantity,
                specialInstructions: specialInstructions ?? existingItem.specialInstructions,
                addedAt: existingItem.addedAt
            )
        } else {
            // Add new item
            let newItem = CartItem(
                product: product,
                quantity: quantity,
                specialInstructions: specialInstructions
            )
            cartItems.append(newItem)
        }
        
        await saveCartItems()
        updateCartItemCount()
    }
    
    func updateItemQuantity(itemId: String, quantity: Int) async throws {
        if quantity <= 0 {
            // Remove item if quantity is 0 or negative
            try await removeItem(withId: itemId)
            return
        }
        
        guard let itemIndex = cartItems.firstIndex(where: { $0.id == itemId }) else {
            throw CartError.itemNotFound
        }
        
        guard quantity <= maxItemQuantity else {
            throw CartError.invalidQuantity
        }
        
        let existingItem = cartItems[itemIndex]
        
        // Check stock if available
        if let stockQuantity = existingItem.product.stockQuantity {
            guard quantity <= stockQuantity else {
                throw CartError.insufficientStock
            }
        }
        
        cartItems[itemIndex] = CartItem(
            id: existingItem.id,
            product: existingItem.product,
            quantity: quantity,
            specialInstructions: existingItem.specialInstructions,
            addedAt: existingItem.addedAt
        )
        
        await saveCartItems()
        updateCartItemCount()
    }
    
    func removeItem(withId itemId: String) async throws {
        guard let itemIndex = cartItems.firstIndex(where: { $0.id == itemId }) else {
            throw CartError.itemNotFound
        }
        
        cartItems.remove(at: itemIndex)
        await saveCartItems()
        updateCartItemCount()
    }
    
    func clearCart() async throws {
        cartItems.removeAll()
        await saveCartItems()
        updateCartItemCount()
    }
    
    func getCartItems() -> [CartItem] {
        return cartItems
    }
    
    func getSubtotal() -> Int {
        return cartItems.reduce(0) { $0 + $1.totalPriceCents }
    }
    
    // MARK: - Private Methods
    
    private func loadCartItemsFromStorage() {
        cartItems = coreDataStack.loadCartItems()
        updateCartItemCount()
    }
    
    func saveCartItems() async {
        coreDataStack.saveCartItems(cartItems)
    }
    
    func updateCartItemCount() {
        let newCount = cartItems.reduce(0) { $0 + $1.quantity }
        cartItemCount = newCount
        cartItemCountSubject.send(newCount)
    }
}

// MARK: - Cart Errors

enum CartError: LocalizedError, Equatable {
    case itemNotFound
    case invalidQuantity
    case saveFailed
    case productUnavailable
    case insufficientStock
    case cartLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Cart item not found"
        case .invalidQuantity:
            return "Invalid quantity specified"
        case .saveFailed:
            return "Failed to save cart changes"
        case .productUnavailable:
            return "This product is currently unavailable"
        case .insufficientStock:
            return "Not enough stock available"
        case .cartLimitExceeded:
            return "Cart limit exceeded"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .itemNotFound:
            return "Please refresh the cart and try again."
        case .invalidQuantity:
            return "Please enter a valid quantity."
        case .saveFailed:
            return "Please try again or restart the app."
        case .productUnavailable:
            return "Try selecting a different product."
        case .insufficientStock:
            return "Reduce the quantity or try again later."
        case .cartLimitExceeded:
            return "Remove some items before adding more."
        }
    }
}

// MARK: - Convenience Methods

extension CartService {
    
    /// Add item with default parameters
    func addItem(product: Product, quantity: Int = 1) async throws {
        try await addItem(product: product, quantity: quantity, specialInstructions: nil)
    }
    
    /// Check if a product is in the cart
    func containsProduct(_ productId: String) -> Bool {
        return cartItems.contains { $0.product.id == productId }
    }
    
    /// Get quantity of a specific product in cart
    func getProductQuantity(_ productId: String) -> Int {
        return cartItems.first { $0.product.id == productId }?.quantity ?? 0
    }
    
    /// Get cart item for a specific product
    func getCartItem(for productId: String) -> CartItem? {
        return cartItems.first { $0.product.id == productId }
    }
    
    /// Get total number of unique items in cart
    var uniqueItemCount: Int {
        return cartItems.count
    }
    
    /// Check if cart is empty
    var isEmpty: Bool {
        return cartItems.isEmpty
    }
}
