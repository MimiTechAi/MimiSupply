//
//  ProductDetailViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation

/// ViewModel for ProductDetailView with cart management
@MainActor
class ProductDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isAddingToCart: Bool = false
    @Published var showingSuccessMessage: Bool = false
    
    // MARK: - Private Properties
    private let product: Product
    private let cartService: CartService
    
    // MARK: - Initialization
    init(
        product: Product,
        cartService: CartService? = nil
    ) {
        self.product = product
        self.cartService = cartService ?? CartService.shared
    }
    
    // MARK: - Public Methods
    func addToCart(quantity: Int, specialInstructions: String?) async {
        guard !isAddingToCart && product.isAvailable else { return }
        
        isAddingToCart = true
        defer { isAddingToCart = false }
        
        do {
            // Create cart item with special instructions
            let cartItem = CartItem(
                product: product,
                quantity: quantity,
                specialInstructions: specialInstructions
            )
            
            try await cartService.addItem(product: product, quantity: quantity, specialInstructions: specialInstructions)
            
            // Show success feedback
            showingSuccessMessage = true
            
            // Hide success message after delay
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            showingSuccessMessage = false
            
        } catch {
            print("Failed to add to cart: \(error)")
            // Handle error - could show error message
        }
    }
}
