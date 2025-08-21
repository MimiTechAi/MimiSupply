//
//  CartViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import Combine

/// ViewModel for CartView with comprehensive cart management
@MainActor
class CartViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var cartItems: [CartItem] = []
    @Published var isLoading: Bool = false
    @Published var subtotal: Int = 0
    @Published var deliveryFee: Int = 299 // $2.99
    @Published var platformFee: Int = 99   // $0.99
    @Published var tax: Int = 0
    @Published var tip: Int = 0
    @Published var total: Int = 0
    
    // MARK: - Private Properties
    private let cartService: CartService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let taxRate: Double = 0.0875 // 8.75% tax rate
    private let defaultTipRate: Double = 0.15 // 15% default tip
    private let maxCartItems: Int = 50 // Maximum items in cart
    
    // MARK: - Initialization
    init(cartService: CartService? = nil) {
        self.cartService = cartService ?? CartService.shared
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadCartItems() async {
        isLoading = true
        defer { isLoading = false }
        
        cartItems = cartService.getCartItems()
        calculateTotals()
    }
    
    func updateItemQuantity(itemId: String, quantity: Int) async {
        do {
            try await cartService.updateItemQuantity(itemId: itemId, quantity: quantity)
            cartItems = cartService.getCartItems()
            calculateTotals()
        } catch {
            print("Failed to update item quantity: \(error)")
        }
    }
    
    func removeItem(withId itemId: String) async {
        do {
            try await cartService.removeItem(withId: itemId)
            cartItems = cartService.getCartItems()
            calculateTotals()
        } catch {
            print("Failed to remove item: \(error)")
        }
    }
    
    func clearCart() async {
        do {
            try await cartService.clearCart()
            cartItems = []
            calculateTotals()
        } catch {
            print("Failed to clear cart: \(error)")
        }
    }
    
    func updateTip(percentage: Double) {
        let tipAmount = Int(Double(subtotal) * percentage)
        tip = tipAmount
        calculateTotals()
    }
    
    func updateTip(amount: Int) {
        tip = amount
        calculateTotals()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Listen to cart service changes
        cartService.$cartItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.cartItems = items
                self?.calculateTotals()
            }
            .store(in: &cancellables)
    }
    
    private func calculateTotals() {
        subtotal = cartItems.reduce(0) { $0 + $1.totalPriceCents }
        
        // Calculate tax on subtotal
        tax = Int(Double(subtotal) * taxRate)
        
        // Calculate default tip if not manually set
        if tip == 0 && subtotal > 0 {
            tip = Int(Double(subtotal) * defaultTipRate)
        }
        
        // Adjust fees based on order size
        adjustFeesBasedOnOrderSize()
        
        // Calculate total
        total = subtotal + deliveryFee + platformFee + tax + tip
    }
    
    private func adjustFeesBasedOnOrderSize() {
        // Free delivery for orders over $25
        if subtotal >= 2500 {
            deliveryFee = 0
        }
        
        // Reduce platform fee for larger orders
        if subtotal >= 5000 { // Orders over $50
            platformFee = 49 // Reduced to $0.49
        }
    }
}
