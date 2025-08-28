//
//  PaymentService.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 13.08.25.
//

import Foundation
import PassKit

/// Payment service protocol for handling Apple Pay transactions
protocol PaymentService: Sendable {
    func processPayment(for order: Order) async throws -> PaymentResult
    func refundPayment(for orderId: String, amount: Int) async throws
    func validateMerchantCapability() -> Bool
    func getPaymentReceipt(for orderId: String) -> PaymentReceipt?
    func generateDigitalReceipt(for order: Order, paymentResult: PaymentResult) -> PaymentReceipt
}

/// Result of payment operations
struct PaymentResult: Sendable, Equatable {
    let transactionId: String
    let status: PaymentStatus
    let amount: Int
    let timestamp: Date
}

/// Payment receipt for record keeping and customer reference
struct PaymentReceipt: Codable, Sendable {
    let id: String
    let orderId: String
    let transactionId: String
    let amount: Int
    let paymentMethod: PaymentMethod
    var status: PaymentStatus
    let timestamp: Date
    let items: [PaymentReceiptItem]
    let subtotal: Int
    let deliveryFee: Int
    let platformFee: Int
    let tax: Int
    let tip: Int
    let total: Int
    let merchantName: String
    let customerEmail: String?
    var refundAmount: Int?
    var refundDate: Date?
}

/// Individual item in a payment receipt
struct PaymentReceiptItem: Codable, Sendable {
    let name: String
    let quantity: Int
    let unitPrice: Int
    let totalPrice: Int
}