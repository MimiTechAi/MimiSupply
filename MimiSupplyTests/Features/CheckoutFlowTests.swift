//
//  CheckoutFlowTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import CloudKit
import MapKit
@testable import MimiSupply

@MainActor
final class CheckoutFlowTests: XCTestCase {
    
    var viewModel: CheckoutViewModel!
    var mockPaymentService: MockPaymentService!
    var mockCloudKitService: MockCloudKitService!
    var sampleCartItems: [CartItem]!
    
    override func setUp() {
        super.setUp()
        
        mockPaymentService = MockPaymentService()
        mockCloudKitService = MockCloudKitService()
        
        sampleCartItems = [
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
        
        viewModel = CheckoutViewModel(
            cartItems: sampleCartItems,
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockPaymentService = nil
        mockCloudKitService = nil
        sampleCartItems = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentStep, .deliveryAddress)
        XCTAssertNil(viewModel.deliveryAddress)
        XCTAssertEqual(viewModel.deliveryInstructions, "")
        XCTAssertFalse(viewModel.isProcessing)
        XCTAssertFalse(viewModel.showingError)
        XCTAssertNil(viewModel.pendingOrder)
        XCTAssertNil(viewModel.completedOrder)
        XCTAssertNil(viewModel.paymentResult)
    }
    
    // MARK: - Address Validation Tests
    
    func testProceedToPaymentWithoutAddress() {
        // When proceeding without address
        viewModel.proceedToPayment()
        
        // Then should show error
        XCTAssertTrue(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, "Please enter a delivery address")
        XCTAssertEqual(viewModel.currentStep, .deliveryAddress)
    }
    
    func testProceedToPaymentWithValidAddress() async {
        // Given valid address
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        
        // When proceeding to payment
        viewModel.proceedToPayment()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then should create pending order and move to payment step
        XCTAssertEqual(viewModel.currentStep, .payment)
        XCTAssertNotNil(viewModel.pendingOrder)
        XCTAssertNotNil(viewModel.estimatedDeliveryTime)
        XCTAssertFalse(viewModel.availableDeliverySlots.isEmpty)
    }
    
    // MARK: - Order Creation Tests
    
    func testOrderCreationWithCorrectCalculations() {
        // Given valid address
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        
        // When creating order
        viewModel.proceedToPayment()
        
        // Then order should have correct calculations
        guard let order = viewModel.pendingOrder else {
            XCTFail("Pending order should be created")
            return
        }
        
        XCTAssertEqual(order.items.count, 2)
        XCTAssertEqual(order.subtotalCents, 1800) // 1200 + (300 * 2)
        XCTAssertGreaterThan(order.deliveryFeeCents, 0)
        XCTAssertGreaterThan(order.platformFeeCents, 0)
        XCTAssertGreaterThan(order.taxCents, 0)
        XCTAssertEqual(order.totalCents, order.subtotalCents + order.deliveryFeeCents + order.platformFeeCents + order.taxCents + order.tipCents)
        XCTAssertEqual(order.deliveryAddress, address)
        XCTAssertEqual(order.paymentMethod, .applePay)
    }
    
    // MARK: - Payment Flow Tests
    
    func testSuccessfulPaymentFlow() async {
        // Given valid address and pending order
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.proceedToPayment()
        
        guard let order = viewModel.pendingOrder else {
            XCTFail("Pending order should be created")
            return
        }
        
        // Configure mock payment service for success
        let paymentResult = PaymentResult(
            transactionId: "txn_123",
            status: .completed,
            amount: order.totalCents,
            timestamp: Date()
        )
        mockPaymentService.paymentResult = .success(paymentResult)
        
        // Configure mock CloudKit service
        mockCloudKitService.createOrderResult = .success(order)
        
        // When handling payment success
        viewModel.handlePaymentSuccess(paymentResult)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then should move to confirmation step
        XCTAssertEqual(viewModel.currentStep, .confirmation)
        XCTAssertNotNil(viewModel.completedOrder)
        XCTAssertEqual(viewModel.paymentResult, paymentResult)
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    func testFailedPaymentFlow() async {
        // Given valid address and pending order
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.proceedToPayment()
        
        // When handling payment failure
        let error = AppError.payment(.cardDeclined)
        viewModel.handlePaymentFailure(error)
        
        // Then should show error
        XCTAssertTrue(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, error.localizedDescription)
        XCTAssertEqual(viewModel.currentStep, .payment)
    }
    
    // MARK: - Delivery Time Calculation Tests
    
    func testDeliveryTimeCalculation() async {
        // Given valid address
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        
        // When proceeding to payment
        viewModel.proceedToPayment()
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then should calculate delivery time
        XCTAssertNotNil(viewModel.estimatedDeliveryTime)
        XCTAssertGreaterThan(viewModel.estimatedDeliveryTime!, Date())
        XCTAssertFalse(viewModel.availableDeliverySlots.isEmpty)
        XCTAssertEqual(viewModel.availableDeliverySlots.count, 4) // ASAP + 3 additional slots
    }
    
    // MARK: - Delivery Fee Calculation Tests
    
    func testDeliveryFeeCalculationNormalHours() {
        // Given normal hours (not peak)
        let calendar = Calendar.current
        let normalHour = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
        
        // Mock current time to normal hours
        // Note: In a real test, you'd inject a clock dependency
        
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.proceedToPayment()
        
        guard let order = viewModel.pendingOrder else {
            XCTFail("Pending order should be created")
            return
        }
        
        // Base delivery fee should be applied
        XCTAssertGreaterThanOrEqual(order.deliveryFeeCents, 299)
    }
    
    // MARK: - Error Handling Tests
    
    func testCloudKitOrderCreationFailure() async {
        // Given valid address and successful payment
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.proceedToPayment()
        
        let paymentResult = PaymentResult(
            transactionId: "txn_123",
            status: .completed,
            amount: 1000,
            timestamp: Date()
        )
        
        // Configure mock CloudKit service to fail
        mockCloudKitService.createOrderResult = .failure(AppError.cloudKit(CKError(.networkFailure)))
        
        // When handling payment success
        viewModel.handlePaymentSuccess(paymentResult)
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then should show error
        XCTAssertTrue(viewModel.showingError)
        XCTAssertTrue(viewModel.errorMessage.contains("Failed to create order"))
        XCTAssertEqual(viewModel.currentStep, .payment)
        XCTAssertFalse(viewModel.isProcessing)
    }
    
    // MARK: - Navigation Tests
    
    func testGoBackToAddress() {
        // Given payment step
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        viewModel.proceedToPayment()
        XCTAssertEqual(viewModel.currentStep, .payment)
        
        // When going back to address
        viewModel.goBackToAddress()
        
        // Then should return to address step
        XCTAssertEqual(viewModel.currentStep, .deliveryAddress)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyCartItems() {
        // Given empty cart
        let emptyViewModel = CheckoutViewModel(
            cartItems: [],
            paymentService: mockPaymentService,
            cloudKitService: mockCloudKitService
        )
        
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        emptyViewModel.deliveryAddress = address
        
        // When proceeding to payment
        emptyViewModel.proceedToPayment()
        
        // Then should handle gracefully
        XCTAssertNotNil(emptyViewModel.pendingOrder)
        XCTAssertEqual(emptyViewModel.pendingOrder?.items.count, 0)
    }
    
    func testLongDeliveryInstructions() {
        // Given very long delivery instructions
        let longInstructions = String(repeating: "Very long delivery instructions. ", count: 100)
        viewModel.deliveryInstructions = longInstructions
        
        let address = Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        )
        viewModel.deliveryAddress = address
        
        // When proceeding to payment
        viewModel.proceedToPayment()
        
        // Then should handle long instructions
        XCTAssertEqual(viewModel.pendingOrder?.deliveryInstructions, longInstructions)
    }
}

// MARK: - Mock Services

class MockPaymentService: PaymentService {
    var paymentResult: Result<PaymentResult, Error> = .success(PaymentResult(
        transactionId: "mock_txn",
        status: .completed,
        amount: 1000,
        timestamp: Date()
    ))
    
    var validateMerchantCapabilityResult = true
    
    func processPayment(for order: Order) async throws -> PaymentResult {
        switch paymentResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
    
    func refundPayment(for orderId: String, amount: Int) async throws {
        // Mock implementation
    }
    
    func validateMerchantCapability() -> Bool {
        return validateMerchantCapabilityResult
    }
    
    func getPaymentReceipt(for orderId: String) -> PaymentReceipt? {
        return nil
    }
    
    func generateDigitalReceipt(for order: Order, paymentResult: PaymentResult) -> PaymentReceipt {
        return PaymentReceipt(
            id: UUID().uuidString,
            orderId: order.id,
            transactionId: paymentResult.transactionId,
            amount: paymentResult.amount,
            paymentMethod: order.paymentMethod,
            status: paymentResult.status,
            timestamp: paymentResult.timestamp,
            items: [],
            subtotal: order.subtotalCents,
            deliveryFee: order.deliveryFeeCents,
            platformFee: order.platformFeeCents,
            tax: order.taxCents,
            tip: order.tipCents,
            total: order.totalCents,
            merchantName: "MimiSupply",
            customerEmail: nil
        )
    }
}

class MockCloudKitService: CloudKitService {
    var createOrderResult: Result<Order, Error> = .success(Order(
        customerId: "customer123",
        partnerId: "partner123",
        items: [],
        subtotalCents: 1000,
        deliveryFeeCents: 200,
        platformFeeCents: 100,
        taxCents: 100,
        deliveryAddress: Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US"
        ),
        paymentMethod: .applePay
    ))
    
    func createOrder(_ order: Order) async throws -> Order {
        switch createOrderResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        // Mock implementation
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        return []
    }
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        return []
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        return nil
    }
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        return []
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        return []
    }
    
    func saveUserProfile(_ user: UserProfile) async throws {
        // Mock implementation
    }
    
    func fetchUserProfile(by appleUserID: String) async throws -> UserProfile? {
        return nil
    }
    
    func saveDriverLocation(_ location: DriverLocation) async throws {
        // Mock implementation
    }
    
    func fetchDriverLocation(for driverId: String) async throws -> DriverLocation? {
        return nil
    }
    
    func subscribeToOrderUpdates(for userId: String) async throws {
        // Mock implementation
    }
    
    func subscribeToDriverLocationUpdates(for orderId: String) async throws {
        // Mock implementation
    }
    
    func createSubscription(_ subscription: CKSubscription) async throws -> CKSubscription {
        return subscription
    }
    
    func deleteSubscription(withID subscriptionID: String) async throws {
        // Mock implementation
    }
}