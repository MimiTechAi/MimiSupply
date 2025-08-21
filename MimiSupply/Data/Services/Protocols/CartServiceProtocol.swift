//
//  CartServiceProtocol.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import Combine

/// Protocol for cart management with local CoreData persistence
@MainActor
protocol CartServiceProtocol: Sendable {
    /// Current cart items
    var cartItems: [CartItem] { get }
    
    /// Current cart item count (total quantity)
    var cartItemCount: Int { get }
    
    /// Publisher for cart item count changes
    var cartItemCountPublisher: AnyPublisher<Int, Never> { get }
    
    /// Add a product to the cart
    /// - Parameters:
    ///   - product: The product to add
    ///   - quantity: Quantity to add (default: 1)
    ///   - specialInstructions: Optional special instructions
    func addItem(product: Product, quantity: Int, specialInstructions: String?) async throws
    
    /// Update the quantity of an existing cart item
    /// - Parameters:
    ///   - itemId: ID of the cart item to update
    ///   - quantity: New quantity (0 removes the item)
    func updateItemQuantity(itemId: String, quantity: Int) async throws
    
    /// Remove an item from the cart
    /// - Parameter itemId: ID of the cart item to remove
    func removeItem(withId itemId: String) async throws
    
    /// Clear all items from the cart
    func clearCart() async throws
    
    /// Get current cart items synchronously
    func getCartItems() -> [CartItem]
    
    /// Get subtotal in cents
    func getSubtotal() -> Int
}