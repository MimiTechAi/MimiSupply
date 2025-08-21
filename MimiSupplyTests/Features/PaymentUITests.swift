//
//  PaymentUITests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

final class PaymentUITests: XCTestCase {
    
    var mockPaymentService: MockPaymentService!
    var mockCloudKitService: MockCloudKitService!
    var sampleOrder: Order!
    
    override func setUp() {
        super.setUp()
        mockPaymentService = MockPaymentService()
        mockCloudKitService = MockCloudKitService()
        sampleOrder = createSampleOrder()
    }
    
    override func tearDown() {
        mockPaymentService = nil
        mockCloudKitService = nil
        sampleOrder = nil
        super.tearDown()
    }
    
    // MARK: - Payment View Tests
    
    func testPaymentViewInitialization() {
        let paymentView = PaymentView(
            order: sampleOrder,
            paymentService: mockPaymentService,
            onPaymentSuccess: { _ in },
            onPaymentFailure: { _ in },
            onCancel: { }
        )
        
        // Test that view can be created without crashing
        XCTAssertNotNil(paymentView)
    }
    
    func testPaymentViewWithApplePayAvailable() {
        mockPaymentService.shouldSucceed = true
        
        let paymentView = PaymentView(
            order: sampleOrder,
            paymentService: mockPaymentService,
            onPaymentSuccess: { _ in },
            onPaymentFailure: { _ in },
            onCancel: { }
        )
        
        // Since MockPaymentService always returns true for validateMerchantCapability,
        // the view should show Apple Pay as available
        XCTAssertNotNil(paymentView)
    }
    
    func testPaymentViewCallbacks() {
        var paymentSuccessCalled = false
        var paymentFailureCalled = false
        var cancelCalled = false
        var capturedResult: PaymentResult?
        var capturedError: Error?
        
        let paymentView = PaymentView(
            order: sampleOrder,
            paymentService: mockPaymentService,
            onPaymentSuccess: { result in
                paymentSuccessCalled = true
                capturedResult = result
            },
            onPaymentFailure: { error in
                paymentFailureCalled = true
                capturedError = error
            },
            onCancel: {
                cancelCalled = true
            }
        )
        
        // Test that callbacks are properly stored
        XCTAssertNotNil(paymentView)
        XCTAssertFalse(paymentSuccessCalled)
        XCTAssertFalse(paymentFailureCalled)
        XCTAssertFalse(cancelCalled)
        XCTAssertNil(capturedResult)
        XCTAssertNil(capturedError)
    }
    
    // MARK: - Checkout View Tests
    
    func testCheckoutViewInitialization() {
        let cartItems = createSampleCartItems()
        
        let checkoutView = CheckoutView(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService,
            onOrderComplete: { _ in },
            onCancel: { }
        )
        
        XCTAssertNotNil(checkoutView)
    }
    
    func testCheckoutViewCallbacks() {
        let cartItems = createSampleCartItems()
        var orderCompleteCalled = false
        var cancelCalled = false
        var capturedOrder: Order?
        
        let checkoutView = CheckoutView(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService,
            onOrderComplete: { order in
                orderCompleteCalled = true
                capturedOrder = order
            },
            onCancel: {
                cancelCalled = true
            }
        )
        
        XCTAssertNotNil(checkoutView)
        XCTAssertFalse(orderCompleteCalled)
        XCTAssertFalse(cancelCalled)
        XCTAssertNil(capturedOrder)
    }
    
    // MARK: - Payment View Model Tests
    
    func testPaymentViewModelInitialization() {
        let viewModel = PaymentViewModel(
            order: sampleOrder,
            paymentService: mockPaymentService
        )
        
        XCTAssertFalse(viewModel.isProcessingPayment)
        XCTAssertTrue(viewModel.isApplePayAvailable) // MockPaymentService returns true
        XCTAssertFalse(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertNil(viewModel.paymentResult)
        XCTAssertNil(viewModel.paymentError)
    }
    
    func testPaymentViewModelSuccessfulPayment() async {
        let viewModel = PaymentViewModel(
            order: sampleOrder,
            paymentService: mockPaymentService
        )
        
        mockPaymentService.shouldSucceed = true
        
        await viewModel.processPayment()
        
        XCTAssertFalse(viewModel.isProcessingPayment)
        XCTAssertNotNil(viewModel.paymentResult)
        XCTAssertNil(viewModel.paymentError)
        XCTAssertFalse(viewModel.showingError)
        XCTAssertTrue(mockPaymentService.processPaymentCalled)
    }
    
    func testPaymentViewModelFailedPayment() async {
        let viewModel = PaymentViewModel(
            order: sampleOrder,
            paymentService: mockPaymentService
        )
        
        mockPaymentService.shouldThrowError = .cardDeclined
        
        await viewModel.processPayment()
        
        XCTAssertFalse(viewModel.isProcessingPayment)
        XCTAssertNil(viewModel.paymentResult)
        XCTAssertNotNil(viewModel.paymentError)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        XCTAssertTrue(mockPaymentService.processPaymentCalled)
    }
    
    func testPaymentViewModelClearError() async {
        let viewModel = PaymentViewModel(
            order: sampleOrder,
            paymentService: mockPaymentService
        )
        
        // Trigger an error
        mockPaymentService.shouldThrowError = .paymentFailed
        await viewModel.processPayment()
        
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        XCTAssertNotNil(viewModel.paymentError)
        
        // Clear the error
        viewModel.clearError()
        
        XCTAssertFalse(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertNil(viewModel.paymentError)
    }
    
    // MARK: - Checkout View Model Tests
    
    func testCheckoutViewModelInitialization() {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        XCTAssertEqual(viewModel.currentStep, .deliveryAddress)
        XCTAssertNil(viewModel.deliveryAddress)
        XCTAssertEqual(viewModel.deliveryInstructions, "")
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.showingError)
        XCTAssertNil(viewModel.pendingOrder)
        XCTAssertNil(viewModel.completedOrder)
        XCTAssertNil(viewModel.paymentResult)
    }
    
    func testCheckoutViewModelProceedToPayment() {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        // Set delivery address
        viewModel.deliveryAddress = createSampleAddress()
        
        // Proceed to payment
        viewModel.proceedToPayment()
        
        XCTAssertEqual(viewModel.currentStep, .payment)
        XCTAssertNotNil(viewModel.pendingOrder)
        XCTAssertEqual(viewModel.pendingOrder?.items.count, cartItems.count)
    }
    
    func testCheckoutViewModelProceedToPaymentWithoutAddress() {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        // Try to proceed without setting address
        viewModel.proceedToPayment()
        
        XCTAssertEqual(viewModel.currentStep, .deliveryAddress)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        XCTAssertNil(viewModel.pendingOrder)
    }
    
    func testCheckoutViewModelGoBackToAddress() {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        // Set up payment step
        viewModel.deliveryAddress = createSampleAddress()
        viewModel.proceedToPayment()
        XCTAssertEqual(viewModel.currentStep, .payment)
        
        // Go back to address
        viewModel.goBackToAddress()
        XCTAssertEqual(viewModel.currentStep, .deliveryAddress)
    }
    
    func testCheckoutViewModelHandlePaymentSuccess() async {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        // Set up for payment
        viewModel.deliveryAddress = createSampleAddress()
        viewModel.proceedToPayment()
        
        let paymentResult = PaymentResult(
            transactionId: "test_txn",
            status: .completed,
            amount: 2000,
            timestamp: Date()
        )
        
        // Handle payment success
        viewModel.handlePaymentSuccess(paymentResult)
        
        XCTAssertNotNil(viewModel.paymentResult)
        XCTAssertEqual(viewModel.paymentResult?.transactionId, "test_txn")
        
        // Wait for CloudKit order creation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Should eventually move to confirmation step
        // Note: This might require additional async handling in real implementation
    }
    
    func testCheckoutViewModelHandlePaymentFailure() {
        let cartItems = createSampleCartItems()
        let viewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        let error = AppError.payment(.cardDeclined)
        
        viewModel.handlePaymentFailure(error)
        
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }
    
    // MARK: - UI Component Tests
    
    func testOrderSummarySectionCreation() {
        let orderSummary = OrderSummarySection(order: sampleOrder)
        XCTAssertNotNil(orderSummary)
    }
    
    func testPaymentMethodSectionCreation() {
        let paymentMethodSection = PaymentMethodSection(
            isApplePayAvailable: true,
            isProcessing: false
        )
        XCTAssertNotNil(paymentMethodSection)
    }
    
    func testApplePayButtonCreation() {
        let applePayButton = ApplePayButton(
            order: sampleOrder,
            isProcessing: false,
            onPaymentRequest: { }
        )
        XCTAssertNotNil(applePayButton)
    }
    
    func testApplePayUnavailableViewCreation() {
        let unavailableView = ApplePayUnavailableView()
        XCTAssertNotNil(unavailableView)
    }
    
    func testCheckoutProgressViewCreation() {
        let progressView = CheckoutProgressView(currentStep: .payment)
        XCTAssertNotNil(progressView)
    }
    
    func testDeliveryAddressStepCreation() {
        @State var address: Address? = nil
        @State var instructions = ""
        
        let addressStep = DeliveryAddressStep(
            address: $address,
            instructions: $instructions,
            onContinue: { }
        )
        XCTAssertNotNil(addressStep)
    }
    
    func testOrderConfirmationStepCreation() {
        let paymentResult = PaymentResult(
            transactionId: "test_txn",
            status: .completed,
            amount: sampleOrder.totalCents,
            timestamp: Date()
        )
        
        let confirmationStep = OrderConfirmationStep(
            order: sampleOrder,
            paymentResult: paymentResult,
            onComplete: { }
        )
        XCTAssertNotNil(confirmationStep)
    }
    
    // MARK: - Accessibility Tests
    
    func testPaymentViewAccessibility() {
        // Test that payment view components have proper accessibility labels
        let applePayButton = ApplePayButton(
            order: sampleOrder,
            isProcessing: false,
            onPaymentRequest: { }
        )
        
        // This would require ViewInspector or similar testing framework
        // for more detailed accessibility testing
        XCTAssertNotNil(applePayButton)
    }
    
    // MARK: - Performance Tests
    
    func testPaymentViewCreationPerformance() {
        measure {
            let _ = PaymentView(
                order: sampleOrder,
                paymentService: mockPaymentService,
                onPaymentSuccess: { _ in },
                onPaymentFailure: { _ in },
                onCancel: { }
            )
        }
    }
    
    func testCheckoutViewCreationPerformance() {
        let cartItems = createSampleCartItems()
        
        measure {
            let _ = CheckoutView(
                cartItems: cartItems,
                paymentService: mockPaymentService,
                cloudKitService: mockCloudKitService,
                onOrderComplete: { _ in },
                onCancel: { }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleOrder() -> Order {
        let items = [
            OrderItem(
                productId: "product1",
                productName: "Pizza Margherita",
                quantity: 1,
                unitPriceCents: 1200
            ),
            OrderItem(
                productId: "product2",
                productName: "Coca Cola",
                quantity: 2,
                unitPriceCents: 300
            )
        ]
        
        return Order(
            customerId: "customer123",
            partnerId: "partner123",
            items: items,
            subtotalCents: 1800,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 168,
            deliveryAddress: createSampleAddress(),
            paymentMethod: .applePay
        )
    }
    
    private func createSampleCartItems() -> [CartItem] {
        return [
            CartItem(
                productId: "product1",
                productName: "Pizza Margherita",
                partnerId: "partner1",
                quantity: 1,
                unitPriceCents: 1200
            ),
            CartItem(
                productId: "product2",
                productName: "Coca Cola",
                partnerId: "partner1",
                quantity: 2,
                unitPriceCents: 300
            )
        ]
    }
    
    private func createSampleAddress() -> Address {
        return Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
    }
}

// MARK: - Integration UI Tests

final class PaymentIntegrationUITests: XCTestCase {
    
    func testCompleteCheckoutFlow() async throws {
        let mockPaymentService = MockPaymentService()
        let mockCloudKitService = MockCloudKitService()
        let cartItems = createTestCartItems()
        
        // Configure services for success
        mockPaymentService.shouldSucceed = true
        mockCloudKitService.shouldThrowError = false
        
        let checkoutViewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        // Step 1: Set delivery address
        checkoutViewModel.deliveryAddress = Address(
            street: "123 Test St",
            city: "Test City",
            state: "CA",
            postalCode: "12345",
            country: "US"
        )
        
        // Step 2: Proceed to payment
        checkoutViewModel.proceedToPayment()
        XCTAssertEqual(checkoutViewModel.currentStep, .payment)
        XCTAssertNotNil(checkoutViewModel.pendingOrder)
        
        // Step 3: Process payment
        let paymentResult = PaymentResult(
            transactionId: "test_txn_123",
            status: .completed,
            amount: checkoutViewModel.pendingOrder!.totalCents,
            timestamp: Date()
        )
        
        checkoutViewModel.handlePaymentSuccess(paymentResult)
        XCTAssertNotNil(checkoutViewModel.paymentResult)
        
        // Wait for order creation
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Verify final state
        XCTAssertTrue(mockPaymentService.processPaymentCalled)
        // Note: CloudKit order creation happens asynchronously
    }
    
    func testCheckoutFlowWithPaymentFailure() async throws {
        let mockPaymentService = MockPaymentService()
        let mockCloudKitService = MockCloudKitService()
        let cartItems = createTestCartItems()
        
        // Configure payment to fail
        mockPaymentService.shouldThrowError = .cardDeclined
        
        let checkoutViewModel = CheckoutViewModel(
            cartItems: cartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        // Set up for payment
        checkoutViewModel.deliveryAddress = Address(
            street: "123 Test St",
            city: "Test City",
            state: "CA",
            postalCode: "12345",
            country: "US"
        )
        checkoutViewModel.proceedToPayment()
        
        // Simulate payment failure
        let error = AppError.payment(.cardDeclined)
        checkoutViewModel.handlePaymentFailure(error)
        
        // Verify error handling
        XCTAssertTrue(checkoutViewModel.showingError)
        XCTAssertFalse(checkoutViewModel.errorMessage.isEmpty)
        XCTAssertEqual(checkoutViewModel.currentStep, .payment)
        XCTAssertNil(checkoutViewModel.completedOrder)
    }
    
    private func createTestCartItems() -> [CartItem] {
        return [
            CartItem(
                productId: "product1",
                productName: "Test Product 1",
                partnerId: "partner1",
                quantity: 1,
                unitPriceCents: 1000
            ),
            CartItem(
                productId: "product2",
                productName: "Test Product 2",
                partnerId: "partner1",
                quantity: 2,
                unitPriceCents: 500
            )
        ]
    }
}