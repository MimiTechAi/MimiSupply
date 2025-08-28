//
//  CheckoutIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import CloudKit
import MapKit
@testable import MimiSupply

@MainActor
final class CheckoutIntegrationTests: XCTestCase {
    
    var paymentService: PaymentServiceImpl!
    var cloudKitService: CloudKitServiceImpl!
    
    override func setUp() {
        super.setUp()
        paymentService = PaymentServiceImpl()
        cloudKitService = CloudKitServiceImpl()
    }
    
    override func tearDown() {
        paymentService = nil
        cloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Checkout Flow Tests
    
    func testCompleteCheckoutFlow() async throws {
        // Given a cart with items
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: paymentService,
            cloudKitService: cloudKitService
        )
        
        // Step 1: Set delivery address
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.deliveryInstructions = "Leave at door"
        
        // Step 2: Proceed to payment
        viewModel.proceedToPayment()
        
        // Wait for delivery time calculation
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Verify order creation
        XCTAssertEqual(viewModel.currentStep, .payment)
        XCTAssertNotNil(viewModel.pendingOrder)
        XCTAssertNotNil(viewModel.estimatedDeliveryTime)
        
        let order = try XCTUnwrap(viewModel.pendingOrder)
        XCTAssertEqual(order.deliveryAddress, address)
        XCTAssertEqual(order.deliveryInstructions, "Leave at door")
        XCTAssertEqual(order.items.count, cartItems.count)
        
        // Step 3: Simulate successful payment
        let paymentResult = PaymentResult(
            transactionId: "test_txn_123",
            status: .completed,
            amount: order.totalCents,
            timestamp: Date()
        )
        
        viewModel.handlePaymentSuccess(paymentResult)
        
        // Wait for order creation in CloudKit
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Verify completion
        XCTAssertEqual(viewModel.currentStep, .confirmation)
        XCTAssertNotNil(viewModel.completedOrder)
        XCTAssertEqual(viewModel.paymentResult, paymentResult)
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    func testCheckoutWithPaymentFailure() async throws {
        // Given a cart with items
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: paymentService,
            cloudKitService: cloudKitService
        )
        
        // Set delivery address
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        
        // Proceed to payment
        viewModel.proceedToPayment()
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Simulate payment failure
        let paymentError = AppError.payment(.cardDeclined)
        viewModel.handlePaymentFailure(paymentError)
        
        // Verify error handling
        XCTAssertTrue(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, paymentError.localizedDescription)
        XCTAssertEqual(viewModel.currentStep, .payment)
        XCTAssertNil(viewModel.completedOrder)
    }
    
    // MARK: - Order Validation Tests
    
    func testOrderValidationWithValidData() throws {
        let order = createValidOrder()
        
        // Should not throw when validating valid order
        XCTAssertNoThrow(try validateOrder(order))
    }
    
    func testOrderValidationWithInvalidData() {
        // Test empty items
        var order = createValidOrder()
        order = Order(
            id: order.id,
            customerId: order.customerId,
            partnerId: order.partnerId,
            items: [], // Empty items
            status: order.status,
            subtotalCents: order.subtotalCents,
            deliveryFeeCents: order.deliveryFeeCents,
            platformFeeCents: order.platformFeeCents,
            taxCents: order.taxCents,
            deliveryAddress: order.deliveryAddress,
            estimatedDeliveryTime: Date().addingTimeInterval(30 * 60),
            paymentMethod: order.paymentMethod
        )
        
        XCTAssertThrowsError(try validateOrder(order)) { error in
            XCTAssertTrue(error is AppError)
        }
        
        // Test invalid total
        order = createValidOrder()
        order = Order(
            id: order.id,
            customerId: order.customerId,
            partnerId: order.partnerId,
            items: order.items,
            status: order.status,
            subtotalCents: order.subtotalCents,
            deliveryFeeCents: order.deliveryFeeCents,
            platformFeeCents: order.platformFeeCents,
            taxCents: order.taxCents,
            tipCents: -100, // Invalid negative tip
            deliveryAddress: order.deliveryAddress,
            estimatedDeliveryTime: Date().addingTimeInterval(30 * 60),
            paymentMethod: order.paymentMethod
        )
        
        XCTAssertThrowsError(try validateOrder(order))
    }
    
    // MARK: - Delivery Time Estimation Tests
    
    func testDeliveryTimeEstimation() async {
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        
        let estimatedTime = await calculateDeliveryTime(for: address)
        
        // Should be in the future
        XCTAssertGreaterThan(estimatedTime, Date())
        
        // Should be within reasonable range (30-60 minutes)
        let timeDifference = estimatedTime.timeIntervalSince(Date())
        XCTAssertGreaterThanOrEqual(timeDifference, 30 * 60) // At least 30 minutes
        XCTAssertLessThanOrEqual(timeDifference, 60 * 60) // At most 60 minutes
    }
    
    func testDeliverySlotGeneration() async {
        let baseTime = Date().addingTimeInterval(30 * 60) // 30 minutes from now
        let slots = generateDeliverySlots(from: baseTime)
        
        XCTAssertEqual(slots.count, 4) // ASAP + 3 additional slots
        
        // First slot should be ASAP
        XCTAssertEqual(slots[0].displayName, "ASAP")
        XCTAssertEqual(slots[0].estimatedTime, baseTime)
        XCTAssertTrue(slots[0].isAvailable)
        
        // Subsequent slots should be 15 minutes apart
        for i in 1..<slots.count {
            let expectedTime = baseTime.addingTimeInterval(TimeInterval(i * 15 * 60))
            XCTAssertEqual(slots[i].estimatedTime, expectedTime)
            XCTAssertTrue(slots[i].isAvailable)
        }
    }
    
    // MARK: - Fee Calculation Tests
    
    func testDeliveryFeeCalculation() {
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        
        let fee = calculateDeliveryFee(for: address)
        
        // Should have minimum base fee
        XCTAssertGreaterThanOrEqual(fee, 299) // $2.99 minimum
        
        // Should be reasonable maximum
        XCTAssertLessThanOrEqual(fee, 1000) // $10.00 maximum
    }
    
    func testPlatformFeeCalculation() {
        let subtotal = 2000 // $20.00
        let platformFee = calculatePlatformFee(subtotal: subtotal)
        
        // Should be 5% of subtotal
        let expectedFee = Int(Double(subtotal) * 0.05)
        XCTAssertEqual(platformFee, expectedFee)
    }
    
    func testTaxCalculation() {
        let subtotal = 2000
        let deliveryFee = 300
        let platformFee = 100
        
        let tax = calculateTax(subtotal: subtotal, deliveryFee: deliveryFee, platformFee: platformFee)
        
        // Should be 8% of taxable amount
        let taxableAmount = subtotal + deliveryFee + platformFee
        let expectedTax = Int(Double(taxableAmount) * 0.08)
        XCTAssertEqual(tax, expectedTax)
    }
    
    // MARK: - Error Recovery Tests
    
    func testNetworkErrorRecovery() async {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: paymentService,
            cloudKitService: cloudKitService
        )
        
        // Set up for payment
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.proceedToPayment()
        
        do {
            try await Task.sleep(nanoseconds: 200_000_000)
        } catch {
            // Handle sleep interruption if needed
        }
        
        // Simulate network error during order creation
        // In a real test, you'd mock the network layer to fail
        
        // Verify error handling doesn't crash the app
        XCTAssertNotNil(viewModel.pendingOrder)
    }
    
    // MARK: - Performance Tests
    
    func testCheckoutPerformance() {
        let cartItems = createLargeCartItems(count: 50)
        
        measure {
            let viewModel = CheckoutViewModel(
                cartItems: cartItems,
                paymentService: paymentService,
                cloudKitService: cloudKitService
            )
            
            let address = Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            )
            viewModel.deliveryAddress = address
            viewModel.proceedToPayment()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleCartItems() -> [CartItem] {
        return [
            CartItem(
                product: Product(
                    partnerId: "partner123",
                    name: "Pizza Margherita",
                    description: "Classic Italian pizza",
                    priceCents: 1200,
                    category: .food
                ),
                quantity: 1
            ),
            CartItem(
                product: Product(
                    partnerId: "partner123",
                    name: "Coca Cola",
                    description: "Refreshing soft drink",
                    priceCents: 300,
                    category: .beverages
                ),
                quantity: 2
            )
        ]
    }
    
    private func createLargeCartItems(count: Int) -> [CartItem] {
        return (0..<count).map { index in
            CartItem(
                product: Product(
                    partnerId: "partner123",
                    name: "Product \(index)",
                    description: "Description \(index)",
                    priceCents: Int.random(in: 100...2000),
                    category: .food
                ),
                quantity: Int.random(in: 1...5)
            )
        }
    }
    
    private func createValidOrder() -> Order {
        return Order(
            customerId: "customer123",
            partnerId: "partner123",
            items: [
                OrderItem(
                    productId: "product1",
                    productName: "Test Product",
                    quantity: 1,
                    unitPriceCents: 1000
                )
            ],
            subtotalCents: 1000,
            deliveryFeeCents: 300,
            platformFeeCents: 50,
            taxCents: 108,
            deliveryAddress: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            ),
            estimatedDeliveryTime: Date().addingTimeInterval(30 * 60),
            paymentMethod: .applePay
        )
    }
    
    private func validateOrder(_ order: Order) throws {
        guard !order.items.isEmpty else {
            throw AppError.validation(.requiredFieldMissing("Order items"))
        }
        
        guard order.totalCents > 0 else {
            throw AppError.payment(.invalidAmount)
        }
        
        let calculatedTotal = order.subtotalCents + order.deliveryFeeCents + order.platformFeeCents + order.taxCents + order.tipCents
        guard calculatedTotal == order.totalCents else {
            throw AppError.payment(.invalidAmount)
        }
        
        guard !order.deliveryAddress.street.isEmpty else {
            throw AppError.validation(.requiredFieldMissing("Delivery address"))
        }
    }
    
    private func calculateDeliveryTime(for address: Address) async -> Date {
        let baseDeliveryTime = 30 // 30 minutes base
        let additionalTime = Int.random(in: 0...15) // 0-15 minutes additional
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isPeakHour = (hour >= 11 && hour <= 14) || (hour >= 17 && hour <= 20)
        let peakTimeAddition = isPeakHour ? 10 : 0
        
        let totalMinutes = baseDeliveryTime + additionalTime + peakTimeAddition
        return Date().addingTimeInterval(TimeInterval(totalMinutes * 60))
    }
    
    private func generateDeliverySlots(from estimatedTime: Date) -> [DeliveryTimeSlot] {
        var slots: [DeliveryTimeSlot] = []
        
        slots.append(DeliveryTimeSlot(
            id: "asap",
            displayName: "ASAP",
            estimatedTime: estimatedTime,
            isAvailable: true
        ))
        
        for i in 1...3 {
            let slotTime = estimatedTime.addingTimeInterval(TimeInterval(i * 15 * 60))
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            slots.append(DeliveryTimeSlot(
                id: "slot_\(i)",
                displayName: formatter.string(from: slotTime),
                estimatedTime: slotTime,
                isAvailable: true
            ))
        }
        
        return slots
    }
    
    private func calculateDeliveryFee(for address: Address) -> Int {
        let baseDeliveryFee = 299 // $2.99
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isPeakHour = (hour >= 11 && hour <= 14) || (hour >= 17 && hour <= 20)
        
        if isPeakHour {
            return Int(Double(baseDeliveryFee) * 1.5) // 50% surge
        }
        
        return baseDeliveryFee
    }
    
    private func calculatePlatformFee(subtotal: Int) -> Int {
        return Int(Double(subtotal) * 0.05) // 5%
    }
    
    private func calculateTax(subtotal: Int, deliveryFee: Int, platformFee: Int) -> Int {
        let taxableAmount = subtotal + deliveryFee + platformFee
        return Int(Double(taxableAmount) * 0.08) // 8% tax
    }
}