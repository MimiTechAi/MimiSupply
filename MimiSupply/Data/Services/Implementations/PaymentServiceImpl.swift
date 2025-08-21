//
//  PaymentServiceImpl.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 13.08.25.
//

import Foundation
@preconcurrency import PassKit
import OSLog

/// Implementation of PaymentService for handling Apple Pay transactions
final class PaymentServiceImpl: NSObject, PaymentService {
    
    // MARK: - Properties
    
    private let merchantIdentifier = "merchant.com.mimisupply.pay"
    private let supportedNetworks: [PKPaymentNetwork] = [.visa, .masterCard, .amex, .discover, .maestro]
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "PaymentService")
    
    // Payment processing state
    private var currentPaymentCompletion: ((Result<PaymentResult, Error>) -> Void)?
    private var currentOrder: Order?
    private var paymentReceipts: [String: PaymentReceipt] = [:]
    private var lastPaymentSummaryItems: [PKPaymentSummaryItem] = []
    
    // MARK: - PaymentService Implementation
    
    func processPayment(for order: Order) async throws -> PaymentResult {
        logger.info("Processing payment for order: \(order.id)")
        
        // Validate order
        try validateOrder(order)
        
        // Check Apple Pay availability
        guard validateMerchantCapability() else {
            logger.error("Apple Pay not available on this device")
            throw AppError.payment(.paymentFailed)
        }

        // Create payment request
        let paymentRequest = createPaymentRequest(for: order)
        
        // Process payment
        return try await withCheckedThrowingContinuation { continuation in
            currentPaymentCompletion = { result in
                continuation.resume(with: result)
            }
            currentOrder = order
            
            // Present Apple Pay sheet
            DispatchQueue.main.async {
                let controller = PKPaymentAuthorizationController(paymentRequest: paymentRequest)
                controller.delegate = self
                controller.present { presented in
                    if !presented {
                        self.logger.error("Failed to present Apple Pay controller")
                        continuation.resume(throwing: AppError.payment(.paymentFailed))
                    }
                }
            }
        }
    }
    
    func refundPayment(for orderId: String, amount: Int) async throws {
        logger.info("Processing refund for order: \(orderId), amount: \(amount)")
        
        guard let receipt = paymentReceipts[orderId] else {
            logger.error("No payment receipt found for order: \(orderId)")
            throw AppError.payment(.paymentFailed)
        }
        
        // In a real implementation, this would integrate with your payment processor
        // For now, we'll simulate the refund process
        try await simulateRefundProcessing(receipt: receipt, amount: amount)
        
        // Update receipt with refund information
        var updatedReceipt = receipt
        updatedReceipt.refundAmount = amount
        updatedReceipt.refundDate = Date()
        updatedReceipt.status = .refunded
        paymentReceipts[orderId] = updatedReceipt
        
        logger.info("Refund processed successfully for order: \(orderId)")
    }
    
    func validateMerchantCapability() -> Bool {
        let canMakePayments = PKPaymentAuthorizationController.canMakePayments()
        let canMakePaymentsWithNetworks = PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
        
        logger.debug("Apple Pay capability - canMakePayments: \(canMakePayments), canMakePaymentsWithNetworks: \(canMakePaymentsWithNetworks)")
        
        return canMakePayments && canMakePaymentsWithNetworks
    }
    
    // MARK: - Payment Receipt Management
    
    func getPaymentReceipt(for orderId: String) -> PaymentReceipt? {
        return paymentReceipts[orderId]
    }
    
    func generateDigitalReceipt(for order: Order, paymentResult: PaymentResult) -> PaymentReceipt {
        let receipt = PaymentReceipt(
            id: UUID().uuidString,
            orderId: order.id,
            transactionId: paymentResult.transactionId,
            amount: paymentResult.amount,
            paymentMethod: order.paymentMethod,
            status: paymentResult.status,
            timestamp: paymentResult.timestamp,
            items: order.items.map { item in
                PaymentReceiptItem(
                    name: item.productName,
                    quantity: item.quantity,
                    unitPrice: item.unitPriceCents,
                    totalPrice: item.totalPriceCents
                )
            },
            subtotal: order.subtotalCents,
            deliveryFee: order.deliveryFeeCents,
            platformFee: order.platformFeeCents,
            tax: order.taxCents,
            tip: order.tipCents,
            total: order.totalCents,
            merchantName: "MimiSupply",
            customerEmail: nil, // Would be populated from user profile
            refundAmount: nil,
            refundDate: nil
        )
        
        paymentReceipts[order.id] = receipt
        return receipt
    }
    
    // MARK: - Private Methods
    
    private func createPaymentRequest(for order: Order) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = [.threeDSecure, .debit, .credit]
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Set shipping requirements
        request.requiredShippingContactFields = [.postalAddress, .phoneNumber]
        request.requiredBillingContactFields = [.postalAddress]
        
        // Create payment summary items with proper formatting
        var paymentItems: [PKPaymentSummaryItem] = []
        
        // Add individual order items (for transparency)
        for item in order.items {
            let summaryItem = PKPaymentSummaryItem(
                label: "\(item.productName) × \(item.quantity)",
                amount: NSDecimalNumber(value: Double(item.totalPriceCents) / 100.0),
                type: .final
            )
            paymentItems.append(summaryItem)
        }
        
        // Add fees and charges
        if order.deliveryFeeCents > 0 {
            paymentItems.append(PKPaymentSummaryItem(
                label: "Delivery Fee",
                amount: NSDecimalNumber(value: Double(order.deliveryFeeCents) / 100.0),
                type: .final
            ))
        }
        
        if order.platformFeeCents > 0 {
            paymentItems.append(PKPaymentSummaryItem(
                label: "Service Fee",
                amount: NSDecimalNumber(value: Double(order.platformFeeCents) / 100.0),
                type: .final
            ))
        }
        
        if order.taxCents > 0 {
            paymentItems.append(PKPaymentSummaryItem(
                label: "Tax",
                amount: NSDecimalNumber(value: Double(order.taxCents) / 100.0),
                type: .final
            ))
        }
        
        if order.tipCents > 0 {
            paymentItems.append(PKPaymentSummaryItem(
                label: "Tip",
                amount: NSDecimalNumber(value: Double(order.tipCents) / 100.0),
                type: .final
            ))
        }
        
        // Add total (this is what the user will be charged)
        paymentItems.append(PKPaymentSummaryItem(
            label: "MimiSupply",
            amount: NSDecimalNumber(value: Double(order.totalCents) / 100.0),
            type: .final
        ))
        
        request.paymentSummaryItems = paymentItems
        lastPaymentSummaryItems = paymentItems
        
        // Set application data for tracking
        if let orderData = try? JSONEncoder().encode(["orderId": order.id]) {
            request.applicationData = orderData
        }
        
        logger.debug("Created payment request for order: \(order.id), total: $\(Double(order.totalCents) / 100.0)")
        
        return request
    }
    
    private func validateOrder(_ order: Order) throws {
        // Validate order has items
        guard !order.items.isEmpty else {
            logger.error("Order validation failed: No items in order")
            throw AppError.validation(.requiredFieldMissing("Order items"))
        }
        
        // Validate total amount
        guard order.totalCents > 0 else {
            logger.error("Order validation failed: Invalid total amount")
            throw AppError.payment(.invalidAmount)
        }
        
        // Validate total calculation
        let calculatedTotal = order.subtotalCents + order.deliveryFeeCents + order.platformFeeCents + order.taxCents + order.tipCents
        guard calculatedTotal == order.totalCents else {
            logger.error("Order validation failed: Total amount mismatch")
            throw AppError.payment(.invalidAmount)
        }
        
        // Validate delivery address
        guard !order.deliveryAddress.street.isEmpty else {
            logger.error("Order validation failed: Missing delivery address")
            throw AppError.validation(.requiredFieldMissing("Delivery address"))
        }
        
        logger.debug("Order validation passed for order: \(order.id)")
    }
    
    private func simulateRefundProcessing(receipt: PaymentReceipt, amount: Int) async throws {
        // Simulate network delay for refund processing
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Validate refund amount
        guard amount > 0 && amount <= receipt.amount else {
            throw AppError.payment(.invalidAmount)
        }
        
        // In a real implementation, this would call your payment processor's refund API
        logger.info("Simulated refund processing completed")
    }
    
    private func processPaymentAuthorization(_ payment: PKPayment) async throws -> PaymentResult {
        logger.info("Processing payment authorization")
        
        guard let order = currentOrder else {
            throw AppError.payment(.paymentFailed)
        }
        
        // Extract payment token
        let paymentToken = payment.token
        let paymentData = paymentToken.paymentData
        
        // In a real implementation, you would send this payment data to your payment processor
        // For now, we'll simulate successful processing
        try await simulatePaymentProcessing(paymentData: paymentData)
        
        // Create payment result
        let result = PaymentResult(
            transactionId: UUID().uuidString,
            status: .completed,
            amount: order.totalCents,
            timestamp: Date()
        )
        
        // Generate and store receipt
        _ = generateDigitalReceipt(for: order, paymentResult: result)
        logger.info("Payment processed successfully. Transaction ID: \(result.transactionId)")
        
        return result
    }
    
    private func simulatePaymentProcessing(paymentData: Data) async throws {
        // Simulate network delay for payment processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Simulate random payment failures (5% failure rate for testing)
        if Int.random(in: 1...100) <= 5 {
            throw AppError.payment(.cardDeclined)
        }
        
        logger.debug("Simulated payment processing completed successfully")
    }
}

// MARK: - Concurrency
extension PaymentServiceImpl: @unchecked Sendable {}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension PaymentServiceImpl: PKPaymentAuthorizationControllerDelegate {
    
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        logger.info("Payment authorization received")
        
        Task {
            do {
                let result = try await processPaymentAuthorization(payment)
                
                await MainActor.run {
                    completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
                    currentPaymentCompletion?(.success(result))
                }
            } catch {
                logger.error("Payment processing failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    let pkError = self.convertToPKError(error)
                    completion(PKPaymentAuthorizationResult(status: .failure, errors: [pkError]))
                    currentPaymentCompletion?(.failure(error))
                }
            }
        }
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        logger.debug("Payment authorization controller finished")
        
        controller.dismiss {
            // Clean up
            self.currentPaymentCompletion = nil
            self.currentOrder = nil
        }
    }
    
    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        // Update delivery address and recalculate fees if needed
        // For now, we'll just accept the contact
        completion(PKPaymentRequestShippingContactUpdate(errors: nil, paymentSummaryItems: self.lastPaymentSummaryItems, shippingMethods: []))
    }
    
    private func convertToPKError(_ error: Error) -> Error {
        if let appError = error as? AppError {
            switch appError {
            case .payment(.cardDeclined):
                return PKPaymentError(.unknownError)
            case .payment(.insufficientFunds):
                return PKPaymentError(.unknownError)
            case .payment(.invalidAmount):
                return PKPaymentError(.unknownError)
            default:
                return PKPaymentError(.unknownError)
            }
        }
        return PKPaymentError(.unknownError)
    }
}

