//
//  CartItem.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation

// MARK: - Cart Item
struct CartItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let product: Product
    let quantity: Int
    let specialInstructions: String?
    let addedAt: Date
    
    // MARK: - Computed Properties
    var totalPriceCents: Int {
        product.priceCents * quantity
    }
    
    var formattedTotalPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(totalPriceCents) / 100.0)) ?? "$0.00"
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        product: Product,
        quantity: Int,
        specialInstructions: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.product = product
        self.quantity = quantity
        self.specialInstructions = specialInstructions
        self.addedAt = addedAt
    }
}