//
//  PaymentIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
@testable import MimiSupply

final class PaymentIntegrationTests: XCTestCase {
    
    var paymentService: MockPaymentService!
    var cloudKitService: MockCloudKitService!
    
    override func setUp() {
        super.setUp()
        paymentService = MockPaymentService()
        cloudKitService = MockCloudKitService()
    }
    
    override func tearDown() {
        paymentService = nil
        cloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Payment Flow Tests
    
    func testCompletePaymentFlow() async throws {
        // Create a test order
        let order = createTestOrder()
        
        // Process payment
        let paymentResult = try await paymentService.processPayment(for: order)
        
        // Verify payment was processed
        XCTAssertTrue(paymentService.processPaymentCalled)
        XCTAssertEqual(paymentService.lastProcessedOrder?.id, order.id)
        XCTAssertEqual(paymentResult.amount, order.totalCents)
        XCTAssertEqual(paymentResult.status, .completed)
        
        // Verify receipt was generated
        let receipt = paymentService.getPaymentReceipt(for: order.id)
        XCTAssertNotNil(receipt)
        XCTAssertEqual(receipt?.orderId, order.id)
        XCTAssertEqual(receipt?.transactionId, paymentResult.transactionId)
        XCTAssertEqual(receipt?.total, order.totalCents)
    }
    
    func testPaymentFailureHandling() async {
        let order = createTestOrder()
        
        // Configure payment service to fail
        paymentService.shouldThrowError = .cardDeclined
        
        do {
            _ = try await paymentService.processPayment(for: order)
            XCTFail("Payment should have failed")
        } catch {
            if case AppError.payment(.cardDeclined) = error {
                // Expected error
                XCTAssertTrue(paymentService.processPaymentCalled)
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    func testOrderCreationAfterPayment() async throws {
        let order = createTestOrder()
        
        // Process payment
        let paymentResult = try await paymentService.processPayment(for: order)
        
        // Update order status to payment confirmed
        var updatedOrder = order
        updatedOrder = Order(
            id: order.id,
            customerId: order.customerId,
            partnerId: order.partnerId,
            items: order.items,
            status: .paymentConfirmed,
            subtotalCents: order.subtotalCents,
            deliveryFeeCents: order.deliveryFeeCents,
            platformFeeCents: order.platformFeeCents,
            taxCents: order.taxCents,
            deliveryAddress: order.deliveryAddress,
            paymentMethod: order.paymentMethod,
            paymentStatus: .completed
        )
        
        // Create order in CloudKit
        let createdOrder = try await cloudKitService.createOrder(updatedOrder)
        
        XCTAssertEqual(createdOrder.id, order.id)
        XCTAssertEqual(createdOrder.status, .paymentConfirmed)
        XCTAssertEqual(createdOrder.paymentStatus, .completed)
        XCTAssertEqual(cloudKitService.createdOrder?.id, order.id)
    }
    
    // MARK: - Refund Flow Tests
    
    func testCompleteRefundFlow() async throws {
        let order = createTestOrder()
        
        // First process payment
        let paymentResult = try await paymentService.processPayment(for: order)
        
        // Then process refund
        try await paymentService.refundPayment(for: order.id, amount: order.totalCents)
        
        // Verify refund was processed
        XCTAssertTrue(paymentService.refundPaymentCalled)
        XCTAssertEqual(paymentService.lastRefundOrderId, order.id)
        XCTAssertEqual(paymentService.lastRefundAmount, order.totalCents)
        
        // Verify receipt was updated
        let receipt = paymentService.getPaymentReceipt(for: order.id)
        XCTAssertNotNil(receipt)
        XCTAssertEqual(receipt?.refundAmount, order.totalCents)
        XCTAssertNotNil(receipt?.refundDate)
        XCTAssertEqual(receipt?.status, .refunded)
    }
    
    func testPartialRefundFlow() async throws {
        let order = createTestOrder()
        
        // Process payment
        _ = try await paymentService.processPayment(for: order)
        
        // Process partial refund (50%)
        let refundAmount = order.totalCents / 2
        try await paymentService.refundPayment(for: order.id, amount: refundAmount)
        
        // Verify partial refund
        let receipt = paymentService.getPaymentReceipt(for: order.id)
        XCTAssertEqual(receipt?.refundAmount, refundAmount)
        XCTAssertEqual(receipt?.status, .refunded)
    }
    
    func testRefundWithoutPayment() async {
        let order = createTestOrder()
        
        // Try to refund without processing payment first
        do {
            try await paymentService.refundPayment(for: order.id, amount: order.totalCents)
            XCTFail("Refund should have failed without payment")
        } catch {
            if case AppError.payment(.receiptNotFound) = error {
                // Expected error
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Error Recovery Tests
    
    func testPaymentRetryAfterFailure() async throws {
        let order = createTestOrder()
        
        // First attempt fails
        paymentService.shouldThrowError = .networkError
        
        do {
            _ = try await paymentService.processPayment(for: order)
            XCTFail("First payment attempt should have failed")
        } catch {
            // Expected failure
        }
        
        // Reset error condition and retry
        paymentService.shouldThrowError = nil
        paymentService.shouldSucceed = true
        
        // Second attempt succeeds
        let paymentResult = try await paymentService.processPayment(for: order)
        XCTAssertEqual(paymentResult.status, .completed)
    }
    
    func testMultiplePaymentAttempts() async throws {
        let order = createTestOrder()
        
        // Configure service to fail first two attempts
        var attemptCount = 0
        
        for attempt in 1...3 {
            if attempt <= 2 {
                paymentService.shouldThrowError = .networkError
            } else {
                paymentService.shouldThrowError = nil
                paymentService.shouldSucceed = true
            }
            
            do {
                let result = try await paymentService.processPayment(for: order)
                XCTAssertEqual(attempt, 3, "Payment should only succeed on third attempt")
                XCTAssertEqual(result.status, .completed)
                break
            } catch {
                XCTAssertLessThan(attempt, 3, "Payment should succeed on third attempt")
                attemptCount += 1
            }
        }
        
        XCTAssertEqual(attemptCount, 2, "Should have failed twice before succeeding")
    }
    
    // MARK: - Concurrent Payment Tests
    
    func testConcurrentPaymentProcessing() async throws {
        let orders = (1...5).map { _ in createTestOrder() }
        
        // Process multiple payments concurrently
        let results = try await withThrowingTaskGroup(of: PaymentResult.self) { group in
            for order in orders {
                group.addTask {
                    return try await self.paymentService.processPayment(for: order)
                }
            }
            
            var results: [PaymentResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        
        // Verify all payments succeeded
        XCTAssertEqual(results.count, orders.count)
        for result in results {
            XCTAssertEqual(result.status, .completed)
        }
        
        // Verify all receipts were generated
        for order in orders {
            let receipt = paymentService.getPaymentReceipt(for: order.id)
            XCTAssertNotNil(receipt)
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testPaymentDataConsistency() async throws {
        let order = createTestOrder()
        
        // Process payment
        let paymentResult = try await paymentService.processPayment(for: order)
        
        // Verify data consistency between order, payment result, and receipt
        let receipt = paymentService.getPaymentReceipt(for: order.id)!
        
        XCTAssertEqual(receipt.orderId, order.id)
        XCTAssertEqual(receipt.transactionId, paymentResult.transactionId)
        XCTAssertEqual(receipt.amount, paymentResult.amount)
        XCTAssertEqual(receipt.amount, order.totalCents)
        XCTAssertEqual(receipt.status, paymentResult.status)
        XCTAssertEqual(receipt.items.count, order.items.count)
        
        // Verify receipt item details match order items
        for (receiptItem, orderItem) in zip(receipt.items, order.items) {
            XCTAssertEqual(receiptItem.name, orderItem.productName)
            XCTAssertEqual(receiptItem.quantity, orderItem.quantity)
            XCTAssertEqual(receiptItem.unitPrice, orderItem.unitPriceCents)
            XCTAssertEqual(receiptItem.totalPrice, orderItem.totalPriceCents)
        }
        
        // Verify receipt totals match order totals
        XCTAssertEqual(receipt.subtotal, order.subtotalCents)
        XCTAssertEqual(receipt.deliveryFee, order.deliveryFeeCents)
        XCTAssertEqual(receipt.platformFee, order.platformFeeCents)
        XCTAssertEqual(receipt.tax, order.taxCents)
        XCTAssertEqual(receipt.tip, order.tipCents)
        XCTAssertEqual(receipt.total, order.totalCents)
    }
    
    // MARK: - Performance Tests
    
    func testPaymentProcessingPerformance() async throws {
        let orders = (1...10).map { _ in createTestOrder() }
        
        measure {
            let expectation = XCTestExpectation(description: "Payment processing")
            
            Task {
                for order in orders {
                    _ = try await paymentService.processPayment(for: order)
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testReceiptGenerationPerformance() async throws {
        let order = createTestOrder()
        let paymentResult = PaymentResult(
            transactionId: "test_txn",
            status: .completed,
            amount: order.totalCents,
            timestamp: Date()
        )
        
        measure {
            _ = paymentService.generateDigitalReceipt(for: order, paymentResult: paymentResult)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestOrder() -> Order {
        let items = [
            OrderItem(
                productId: "product1",
                productName: "Test Product 1",
                quantity: 2,
                unitPriceCents: 1000
            ),
            OrderItem(
                productId: "product2",
                productName: "Test Product 2",
                quantity: 1,
                unitPriceCents: 1500
            )
        ]
        
        return Order(
            customerId: "customer_\(UUID().uuidString)",
            partnerId: "partner_\(UUID().uuidString)",
            items: items,
            subtotalCents: 3500,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 320,
            deliveryAddress: Address(
                street: "123 Test St",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "US"
            ),
            paymentMethod: .applePay
        )
    }
}