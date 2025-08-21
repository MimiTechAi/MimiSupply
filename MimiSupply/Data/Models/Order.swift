//
//  Order.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation
import SwiftUI

// MARK: - Order Status
enum OrderStatus: String, CaseIterable, Codable, Hashable, Sendable {
    case pending = "pending"
    case confirmed = "confirmed"
    case preparing = "preparing"
    case ready = "ready"
    case readyForPickup = "ready_for_pickup"
    case pickedUp = "picked_up"
    case enRoute = "en_route"
    case delivered = "delivered"
    case cancelled = "cancelled"
    case failed = "failed"
    case driverAssigned = "driver_assigned"
    case paymentConfirmed = "payment_confirmed"
    case delivering = "delivering"
    case accepted = "accepted"
    case created = "created"
    case paymentProcessing = "payment_processing"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .ready: return "Ready"
        case .readyForPickup: return "Ready for Pickup"
        case .pickedUp: return "Picked Up"
        case .enRoute: return "En Route"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        case .driverAssigned: return "Driver Assigned"
        case .paymentConfirmed: return "Payment Confirmed"
        case .delivering: return "Delivering"
        case .accepted: return "Accepted"
        case .created: return "Created"
        case .paymentProcessing: return "Payment Processing"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .confirmed: return "checkmark.circle"
        case .preparing: return "chef.hat"
        case .ready, .readyForPickup: return "bag.badge.checkmark"
        case .pickedUp: return "figure.walk"
        case .enRoute: return "car"
        case .delivered: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle"
        case .failed: return "xmark.octagon"
        case .driverAssigned: return "person.fill"
        case .paymentConfirmed: return "creditcard.fill"
        case .delivering: return "car.fill"
        case .accepted: return "checkmark.circle"
        case .created: return "plus.circle"
        case .paymentProcessing: return "creditcard"
        }
    }
    
    var isActive: Bool {
        switch self {
        case .pending, .confirmed, .preparing, .ready, .readyForPickup, .pickedUp, .enRoute, .driverAssigned, .paymentConfirmed, .delivering, .accepted, .created, .paymentProcessing:
            return true
        case .delivered, .cancelled, .failed:
            return false
        }
    }
}

// MARK: - Payment Method
enum PaymentMethod: String, CaseIterable, Codable, Sendable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case paypal = "paypal"
    case cash = "cash"
    case giftCard = "gift_card"
    
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .applePay: return "Apple Pay"
        case .googlePay: return "Google Pay"
        case .paypal: return "PayPal"
        case .cash: return "Cash"
        case .giftCard: return "Gift Card"
        }
    }
    
    var iconName: String {
        switch self {
        case .creditCard, .debitCard: return "creditcard"
        case .applePay: return "applelogo"
        case .googlePay: return "g.circle"
        case .paypal: return "p.circle"
        case .cash: return "banknote"
        case .giftCard: return "giftcard"
        }
    }
}

// MARK: - Payment Status
enum PaymentStatus: String, CaseIterable, Codable, Sendable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .refunded: return "Refunded"
        case .cancelled: return "Cancelled"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .processing: return .blue
        case .completed: return .green
        case .failed: return .red
        case .refunded: return .purple
        case .cancelled: return .gray
        }
    }
}

// MARK: - Product Customization
struct ProductCustomization: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let value: String
    let priceCents: Int
    
    init(
        id: String = UUID().uuidString,
        name: String,
        value: String,
        priceCents: Int = 0
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.priceCents = priceCents
    }
}

// MARK: - Order Item
struct OrderItem: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let productId: String
    let productName: String
    let productDescription: String?
    let quantity: Int
    let unitPriceCents: Int
    let totalPriceCents: Int
    let specialInstructions: String?
    let imageURL: URL?
    let customizations: [ProductCustomization]
    
    // MARK: - Computed Properties
    var formattedUnitPrice: String {
        String(format: "$%.2f", Double(unitPriceCents) / 100.0)
    }
    
    var formattedTotalPrice: String {
        String(format: "$%.2f", Double(totalPriceCents) / 100.0)
    }
    
    var totalPriceWithCustomizations: Int {
        let basePrice = unitPriceCents * quantity
        let customizationPrice = customizations.reduce(0) { $0 + $1.priceCents }
        return basePrice + (customizationPrice * quantity)
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        productId: String,
        productName: String,
        productDescription: String? = nil,
        quantity: Int,
        unitPriceCents: Int,
        specialInstructions: String? = nil,
        imageURL: URL? = nil,
        customizations: [ProductCustomization] = []
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.productDescription = productDescription
        self.quantity = quantity
        self.unitPriceCents = unitPriceCents
        self.totalPriceCents = unitPriceCents * quantity
        self.specialInstructions = specialInstructions
        self.imageURL = imageURL
        self.customizations = customizations
    }
}

// MARK: - Order Model
struct Order: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let customerId: String
    let partnerId: String
    let driverId: String?
    let items: [OrderItem]
    let status: OrderStatus
    let subtotalCents: Int
    let deliveryFeeCents: Int
    let platformFeeCents: Int
    let taxCents: Int
    let tipCents: Int
    let totalCents: Int
    let deliveryAddress: Address
    let deliveryInstructions: String?
    let estimatedDeliveryTime: Date
    let actualDeliveryTime: Date?
    let specialInstructions: String?
    let paymentMethod: PaymentMethod
    let paymentStatus: PaymentStatus
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    var formattedTotal: String {
        String(format: "$%.2f", Double(totalCents) / 100.0)
    }
    
    var formattedSubtotal: String {
        String(format: "$%.2f", Double(subtotalCents) / 100.0)
    }
    
    var formattedDeliveryFee: String {
        if deliveryFeeCents == 0 {
            return "Free"
        } else {
            return String(format: "$%.2f", Double(deliveryFeeCents) / 100.0)
        }
    }
    
    var formattedTax: String {
        String(format: "$%.2f", Double(taxCents) / 100.0)
    }
    
    var formattedTip: String {
        String(format: "$%.2f", Double(tipCents) / 100.0)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
    
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var canBeCancelled: Bool {
        switch status {
        case .pending, .confirmed:
            return true
        default:
            return false
        }
    }
    
    var canBeTracked: Bool {
        switch status {
        case .preparing, .ready, .pickedUp, .enRoute:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        customerId: String,
        partnerId: String,
        driverId: String? = nil,
        items: [OrderItem],
        status: OrderStatus = .pending,
        subtotalCents: Int,
        deliveryFeeCents: Int,
        platformFeeCents: Int,
        taxCents: Int,
        tipCents: Int = 0,
        deliveryAddress: Address,
        deliveryInstructions: String? = nil,
        estimatedDeliveryTime: Date,
        actualDeliveryTime: Date? = nil,
        specialInstructions: String? = nil,
        paymentMethod: PaymentMethod,
        paymentStatus: PaymentStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.customerId = customerId
        self.partnerId = partnerId
        self.driverId = driverId
        self.items = items
        self.status = status
        self.subtotalCents = subtotalCents
        self.deliveryFeeCents = deliveryFeeCents
        self.platformFeeCents = platformFeeCents
        self.taxCents = taxCents
        self.tipCents = tipCents
        self.totalCents = subtotalCents + deliveryFeeCents + platformFeeCents + taxCents + tipCents
        self.deliveryAddress = deliveryAddress
        self.deliveryInstructions = deliveryInstructions
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.actualDeliveryTime = actualDeliveryTime
        self.specialInstructions = specialInstructions
        self.paymentMethod = paymentMethod
        self.paymentStatus = paymentStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mock Data
extension Order {
    static let mockOrders: [Order] = [
        Order(
            customerId: "customer123",
            partnerId: "partner123",
            items: [
                OrderItem(
                    productId: "product1",
                    productName: "Pizza Margherita",
                    quantity: 1,
                    unitPriceCents: 1200
                ),
                OrderItem(
                    productId: "product2",
                    productName: "Caesar Salad",
                    quantity: 1,
                    unitPriceCents: 800
                )
            ],
            status: .preparing,
            subtotalCents: 2000,
            deliveryFeeCents: 299,
            platformFeeCents: 100,
            taxCents: 180,
            deliveryAddress: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            ),
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            paymentMethod: .applePay
        )
    ]
}