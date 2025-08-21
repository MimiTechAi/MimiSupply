//
//  EndToEndWorkflowTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 16.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

/// End-to-end integration tests for complete user workflows
@MainActor
final class EndToEndWorkflowTests: XCTestCase {
    
    var appContainer: AppContainer!
    var mockServices: MockServiceContainer!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockServices = MockServiceContainer()
        appContainer = AppContainer(services: mockServices)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        appContainer = nil
        mockServices = nil
        super.tearDown()
    }
    
    // MARK: - Complete Customer Journey Tests
    
    func testCompleteCustomerOrderJourney() async throws {
        // Given - Setup test data
        let testPartner = TestDataFactory.createTestPartner()
        let testProducts = TestDataFactory.createTestProducts(partnerId: testPartner.id, count: 3)
        let testUser = TestDataFactory.createTestUser(role: .customer)
        
        mockServices.cloudKitService.mockPartners = [testPartner]
        mockServices.cloudKitService.mockProducts = testProducts
        mockServices.authService.mockCurrentUser = testUser
        mockServices.authService.mockAuthState = .authenticated(testUser)
        
        // Step 1: User opens app and browses without authentication
        let exploreViewModel = ExploreHomeViewModel(
            cloudKitService: mockServices.cloudKitService,
            locationService: mockServices.locationService
        )
        
        await exploreViewModel.loadInitialData()
        
        XCTAssertEqual(exploreViewModel.partners.count, 1)
        XCTAssertEqual(exploreViewModel.partners.first?.id, testPartner.id)
        
        // Step 2: User selects a partner and views products
        let partnerDetailViewModel = PartnerDetailViewModel(
            partner: testPartner,
            productRepository: mockServices.productRepository,
            cartService: mockServices.cartService
        )
        
        await partnerDetailViewModel.loadProducts()
        
        XCTAssertEqual(partnerDetailViewModel.products.count, 3)
        
        // Step 3: User adds items to cart
        let firstProduct = testProducts[0]
        try await partnerDetailViewModel.addToCart(product: firstProduct, quantity: 2)
        
        let secondProduct = testProducts[1]
        try await partnerDetailViewModel.addToCart(product: secondProduct, quantity: 1)
        
        XCTAssertEqual(mockServices.cartService.cartItemCount, 3)
        XCTAssertEqual(mockServices.cartService.uniqueItemCount, 2)
        
        // Step 4: User proceeds to checkout (authentication gate)
        let checkoutViewModel = CheckoutViewModel(
            cartService: mockServices.cartService,
            authService: mockServices.authService,
            paymentService: mockServices.paymentService,
            orderRepository: mockServices.orderRepository
        )
        
        // Simulate authentication flow
        let authResult = AuthenticationResult(
            user: testUser,
            isNewUser: false,
            requiresRoleSelection: false
        )
        mockServices.authService.mockAuthResult = authResult
        
        try await checkoutViewModel.authenticateIfNeeded()
        
        XCTAssertTrue(checkoutViewModel.isAuthenticated)
        XCTAssertEqual(checkoutViewModel.currentUser?.id, testUser.id)
        
        // Step 5: User completes payment
        mockServices.paymentService.shouldSucceed = true
        
        let order = try await checkoutViewModel.processPayment()
        
        XCTAssertNotNil(order)
        XCTAssertEqual(order.customerId, testUser.id)
        XCTAssertEqual(order.partnerId, testPartner.id)
        XCTAssertEqual(order.items.count, 2)
        XCTAssertEqual(order.status, .paymentConfirmed)
        
        // Step 6: Order is created and driver is assigned
        XCTAssertTrue(mockServices.orderRepository.createOrderCalled)
        XCTAssertNotNil(mockServices.orderRepository.lastCreatedOrder)
        
        // Step 7: User can track the order
        let trackingViewModel = OrderTrackingViewModel(
            order: order,
            cloudKitService: mockServices.cloudKitService,
            locationService: mockServices.locationService
        )
        
        await trackingViewModel.startTracking()
        
        XCTAssertTrue(trackingViewModel.isTracking)
        XCTAssertEqual(trackingViewModel.order.id, order.id)
        
        // Step 8: Simulate order status updates
        mockServices.cloudKitService.simulateOrderUpdate(orderId: order.id, newStatus: .preparing)
        
        // Allow time for subscription to process
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify the complete workflow
        XCTAssertTrue(mockServices.cloudKitService.subscriptionCreated)
        XCTAssertEqual(mockServices.paymentService.lastProcessedOrder?.id, order.id)
        XCTAssertTrue(mockServices.cartService.getCartItems().isEmpty) // Cart should be cleared after order
    }
    
    // MARK: - Driver Workflow Tests
    
    func testCompleteDriverWorkflow() async throws {
        // Given - Setup driver and order
        let testDriver = TestDataFactory.createTestDriver()
        let testUser = TestDataFactory.createTestUser(id: testDriver.userId, role: .driver)
        let testOrder = TestDataFactory.createTestOrder(status: .accepted)
        
        mockServices.authService.mockCurrentUser = testUser
        mockServices.authService.mockAuthState = .authenticated(testUser)
        mockServices.orderRepository.mockOrders = [testOrder]
        
        // Step 1: Driver opens app and goes online
        let driverViewModel = DriverDashboardViewModel(
            authService: mockServices.authService,
            orderRepository: mockServices.orderRepository,
            locationService: mockServices.locationService,
            cloudKitService: mockServices.cloudKitService
        )
        
        await driverViewModel.initialize()
        
        XCTAssertFalse(driverViewModel.isOnline)
        
        // Step 2: Driver goes online
        try await driverViewModel.toggleOnlineStatus()
        
        XCTAssertTrue(driverViewModel.isOnline)
        XCTAssertTrue(mockServices.locationService.isBackgroundLocationEnabled)
        
        // Step 3: Driver receives and accepts an order
        await driverViewModel.loadAvailableJobs()
        
        XCTAssertEqual(driverViewModel.availableJobs.count, 1)
        
        try await driverViewModel.acceptJob(testOrder.id)
        
        XCTAssertTrue(mockServices.orderRepository.assignDriverCalled)
        XCTAssertEqual(mockServices.orderRepository.lastAssignedOrderId, testOrder.id)
        
        // Step 4: Driver navigates to pickup location
        let jobDetailViewModel = JobDetailViewModel(
            order: testOrder,
            locationService: mockServices.locationService,
            orderRepository: mockServices.orderRepository
        )
        
        await jobDetailViewModel.startNavigation()
        
        XCTAssertTrue(jobDetailViewModel.isNavigating)
        
        // Step 5: Driver picks up order
        try await jobDetailViewModel.markAsPickedUp()
        
        XCTAssertTrue(mockServices.orderRepository.updateOrderStatusCalled)
        XCTAssertEqual(mockServices.orderRepository.lastUpdatedOrderStatus, .pickedUp)
        
        // Step 6: Driver delivers order
        try await jobDetailViewModel.markAsDelivered()
        
        XCTAssertEqual(mockServices.orderRepository.lastUpdatedOrderStatus, .delivered)
        
        // Verify complete driver workflow
        XCTAssertTrue(driverViewModel.isOnline)
        XCTAssertNotNil(jobDetailViewModel.completedAt)
    }
    
    // MARK: - Partner Workflow Tests
    
    func testCompletePartnerWorkflow() async throws {
        // Given - Setup partner and orders
        let testPartner = TestDataFactory.createTestPartner()
        let testUser = TestDataFactory.createTestUser(role: .partner)
        let pendingOrder = TestDataFactory.createTestOrder(
            partnerId: testPartner.id,
            status: .paymentConfirmed
        )
        
        mockServices.authService.mockCurrentUser = testUser
        mockServices.authService.mockAuthState = .authenticated(testUser)
        mockServices.orderRepository.mockOrders = [pendingOrder]
        
        // Step 1: Partner opens dashboard
        let partnerViewModel = PartnerDashboardViewModel(
            authService: mockServices.authService,
            orderRepository: mockServices.orderRepository,
            cloudKitService: mockServices.cloudKitService
        )
        
        await partnerViewModel.loadDashboardData()
        
        XCTAssertEqual(partnerViewModel.pendingOrders.count, 1)
        XCTAssertEqual(partnerViewModel.pendingOrders.first?.id, pendingOrder.id)
        
        // Step 2: Partner accepts order
        try await partnerViewModel.updateOrderStatus(pendingOrder.id, status: .accepted)
        
        XCTAssertTrue(mockServices.orderRepository.updateOrderStatusCalled)
        XCTAssertEqual(mockServices.orderRepository.lastUpdatedOrderStatus, .accepted)
        
        // Step 3: Partner marks order as preparing
        try await partnerViewModel.updateOrderStatus(pendingOrder.id, status: .preparing)
        
        XCTAssertEqual(mockServices.orderRepository.lastUpdatedOrderStatus, .preparing)
        
        // Step 4: Partner marks order as ready for pickup
        try await partnerViewModel.updateOrderStatus(pendingOrder.id, status: .readyForPickup)
        
        XCTAssertEqual(mockServices.orderRepository.lastUpdatedOrderStatus, .readyForPickup)
        
        // Step 5: Partner manages products
        let productManagementViewModel = ProductManagementViewModel(
            partner: testPartner,
            productRepository: mockServices.productRepository,
            cloudKitService: mockServices.cloudKitService
        )
        
        await productManagementViewModel.loadProducts()
        
        // Add a new product
        let newProduct = TestDataFactory.createTestProduct(
            partnerId: testPartner.id,
            name: "New Test Product"
        )
        
        try await productManagementViewModel.addProduct(newProduct)
        
        // Verify partner workflow
        XCTAssertTrue(mockServices.cloudKitService.savedUserProfile != nil)
        XCTAssertEqual(partnerViewModel.pendingOrders.count, 1)
    }
    
    // MARK: - Multi-User Interaction Tests
    
    func testMultiUserOrderInteraction() async throws {
        // Given - Setup all user types
        let customer = TestDataFactory.createTestUser(id: "customer-1", role: .customer)
        let driver = TestDataFactory.createTestDriver(id: "driver-1")
        let partner = TestDataFactory.createTestPartner(id: "partner-1")
        
        let order = TestDataFactory.createTestOrder(
            customerId: customer.id,
            partnerId: partner.id,
            driverId: driver.id,
            status: .created
        )
        
        mockServices.orderRepository.mockOrders = [order]
        
        // Customer creates order
        mockServices.authService.mockCurrentUser = customer
        let customerOrderViewModel = OrderTrackingViewModel(
            order: order,
            cloudKitService: mockServices.cloudKitService,
            locationService: mockServices.locationService
        )
        
        await customerOrderViewModel.startTracking()
        XCTAssertTrue(customerOrderViewModel.isTracking)
        
        // Partner receives and accepts order
        mockServices.authService.mockCurrentUser = TestDataFactory.createTestUser(role: .partner)
        let partnerViewModel = PartnerDashboardViewModel(
            authService: mockServices.authService,
            orderRepository: mockServices.orderRepository,
            cloudKitService: mockServices.cloudKitService
        )
        
        try await partnerViewModel.updateOrderStatus(order.id, status: .accepted)
        
        // Driver gets assigned and picks up order
        mockServices.authService.mockCurrentUser = TestDataFactory.createTestUser(id: driver.userId, role: .driver)
        let driverViewModel = DriverDashboardViewModel(
            authService: mockServices.authService,
            orderRepository: mockServices.orderRepository,
            locationService: mockServices.locationService,
            cloudKitService: mockServices.cloudKitService
        )
        
        try await driverViewModel.acceptJob(order.id)
        
        // Verify all interactions
        XCTAssertTrue(mockServices.orderRepository.updateOrderStatusCalled)
        XCTAssertTrue(mockServices.orderRepository.assignDriverCalled)
        XCTAssertTrue(mockServices.cloudKitService.subscriptionCreated)
    }
    
    // MARK: - Error Recovery Tests
    
    func testOrderWorkflowWithNetworkErrors() async throws {
        // Given - Setup with network errors
        let testUser = TestDataFactory.createTestUser(role: .customer)
        let testOrder = TestDataFactory.createTestOrder(customerId: testUser.id)
        
        mockServices.authService.mockCurrentUser = testUser
        mockServices.orderRepository.shouldThrowError = true
        mockServices.orderRepository.errorToThrow = AppError.network(.noConnection)
        
        let checkoutViewModel = CheckoutViewModel(
            cartService: mockServices.cartService,
            authService: mockServices.authService,
            paymentService: mockServices.paymentService,
            orderRepository: mockServices.orderRepository
        )
        
        // When - Attempting to process payment with network error
        do {
            _ = try await checkoutViewModel.processPayment()
            XCTFail("Should have thrown network error")
        } catch AppError.network(.noConnection) {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Then - Verify error handling
        XCTAssertTrue(checkoutViewModel.hasError)
        XCTAssertNotNil(checkoutViewModel.errorMessage)
        
        // When - Network recovers
        mockServices.orderRepository.shouldThrowError = false
        
        // Then - Should be able to retry successfully
        let order = try await checkoutViewModel.processPayment()
        XCTAssertNotNil(order)
        XCTAssertFalse(checkoutViewModel.hasError)
    }
    
    // MARK: - Performance Tests
    
    func testLargeOrderProcessingPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Large order processing")
            
            Task {
                // Create order with many items
                let largeOrder = TestDataFactory.createTestOrder(itemCount: 50)
                mockServices.orderRepository.mockOrders = [largeOrder]
                
                let startTime = CFAbsoluteTimeGetCurrent()
                
                let trackingViewModel = OrderTrackingViewModel(
                    order: largeOrder,
                    cloudKitService: mockServices.cloudKitService,
                    locationService: mockServices.locationService
                )
                
                await trackingViewModel.startTracking()
                
                let processingTime = CFAbsoluteTimeGetCurrent() - startTime
                
                // Should process large orders quickly
                XCTAssertLessThan(processingTime, 1.0, "Large order processing should complete within 1 second")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    // MARK: - Data Consistency Tests
    
    func testDataConsistencyAcrossWorkflow() async throws {
        // Given - Initial state
        let testUser = TestDataFactory.createTestUser(role: .customer)
        let testPartner = TestDataFactory.createTestPartner()
        let testProducts = TestDataFactory.createTestProducts(partnerId: testPartner.id, count: 2)
        
        mockServices.authService.mockCurrentUser = testUser
        mockServices.cloudKitService.mockPartners = [testPartner]
        mockServices.cloudKitService.mockProducts = testProducts
        
        // Step 1: Add items to cart
        let cartService = mockServices.cartService
        try await cartService.addItem(product: testProducts[0], quantity: 2)
        try await cartService.addItem(product: testProducts[1], quantity: 1)
        
        let initialCartTotal = cartService.getSubtotal()
        let initialItemCount = cartService.cartItemCount
        
        // Step 2: Create order
        let checkoutViewModel = CheckoutViewModel(
            cartService: cartService,
            authService: mockServices.authService,
            paymentService: mockServices.paymentService,
            orderRepository: mockServices.orderRepository
        )
        
        let order = try await checkoutViewModel.processPayment()
        
        // Step 3: Verify data consistency
        XCTAssertEqual(order.items.count, 2)
        XCTAssertEqual(order.subtotalCents, initialCartTotal)
        
        // Verify cart is cleared after successful order
        XCTAssertEqual(cartService.cartItemCount, 0)
        XCTAssertTrue(cartService.isEmpty)
        
        // Verify order totals are consistent
        let calculatedTotal = order.subtotalCents + order.deliveryFeeCents + 
                             order.platformFeeCents + order.taxCents + order.tipCents
        XCTAssertEqual(order.totalCents, calculatedTotal)
        
        // Verify payment amount matches order total
        XCTAssertEqual(mockServices.paymentService.lastProcessedOrder?.totalCents, order.totalCents)
    }
}

// MARK: - Mock Service Container

class MockServiceContainer {
    let authService = MockAuthenticationService()
    let cloudKitService = MockCloudKitService()
    let locationService = MockLocationService()
    let paymentService = MockPaymentService()
    let cartService = MockCartService()
    let orderRepository = MockOrderRepository()
    let productRepository = MockProductRepository()
    
    init() {
        // Setup default successful states
        authService.shouldThrowError = false
        cloudKitService.shouldThrowError = false
        locationService.shouldThrowPermissionError = false
        paymentService.shouldSucceed = true
        orderRepository.shouldThrowError = false
        productRepository.shouldThrowError = false
    }
}

// MARK: - Mock Cart Service

class MockCartService: CartServiceProtocol {
    private var cartItems: [CartItem] = []
    private let cartItemCountSubject = CurrentValueSubject<Int, Never>(0)
    
    var cartItemCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }
    
    var uniqueItemCount: Int {
        cartItems.count
    }
    
    var isEmpty: Bool {
        cartItems.isEmpty
    }
    
    var cartItemCountPublisher: AnyPublisher<Int, Never> {
        cartItemCountSubject.eraseToAnyPublisher()
    }
    
    func getCartItems() -> [CartItem] {
        return cartItems
    }
    
    func addItem(product: Product, quantity: Int, specialInstructions: String? = nil) async throws {
        if !product.isAvailable {
            throw CartError.productUnavailable
        }
        
        if quantity <= 0 || quantity > 10 {
            throw CartError.invalidQuantity
        }
        
        if let stockQuantity = product.stockQuantity, quantity > stockQuantity {
            throw CartError.insufficientStock
        }
        
        if let existingIndex = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[existingIndex] = CartItem(
                id: cartItems[existingIndex].id,
                product: product,
                quantity: cartItems[existingIndex].quantity + quantity,
                specialInstructions: cartItems[existingIndex].specialInstructions
            )
        } else {
            let newItem = CartItem(
                id: UUID().uuidString,
                product: product,
                quantity: quantity,
                specialInstructions: specialInstructions
            )
            cartItems.append(newItem)
        }
        
        cartItemCountSubject.send(cartItemCount)
    }
    
    func removeItem(withId itemId: String) async throws {
        cartItems.removeAll { $0.id == itemId }
        cartItemCountSubject.send(cartItemCount)
    }
    
    func updateItemQuantity(itemId: String, quantity: Int) async throws {
        if quantity == 0 {
            try await removeItem(withId: itemId)
            return
        }
        
        guard let index = cartItems.firstIndex(where: { $0.id == itemId }) else {
            throw CartError.itemNotFound
        }
        
        let item = cartItems[index]
        if let stockQuantity = item.product.stockQuantity, quantity > stockQuantity {
            throw CartError.insufficientStock
        }
        
        cartItems[index] = CartItem(
            id: item.id,
            product: item.product,
            quantity: quantity,
            specialInstructions: item.specialInstructions
        )
        
        cartItemCountSubject.send(cartItemCount)
    }
    
    func clearCart() async throws {
        cartItems.removeAll()
        cartItemCountSubject.send(0)
    }
    
    func getSubtotal() -> Int {
        return cartItems.reduce(0) { total, item in
            total + (item.product.priceCents * item.quantity)
        }
    }
    
    func containsProduct(_ productId: String) -> Bool {
        return cartItems.contains { $0.product.id == productId }
    }
    
    func getProductQuantity(_ productId: String) -> Int {
        return cartItems.first { $0.product.id == productId }?.quantity ?? 0
    }
    
    func getCartItem(for productId: String) -> CartItem? {
        return cartItems.first { $0.product.id == productId }
    }
}

// MARK: - Mock Product Repository

class MockProductRepository: ProductRepository {
    var mockProducts: [Product] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.network(.noConnection)
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockProducts.filter { $0.partnerId == partnerId }
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockProducts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    func fetchProduct(by id: String) async throws -> Product? {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockProducts.first { $0.id == id }
    }
}

// MARK: - Supporting Protocols

protocol CartServiceProtocol {
    var cartItemCount: Int { get }
    var uniqueItemCount: Int { get }
    var isEmpty: Bool { get }
    var cartItemCountPublisher: AnyPublisher<Int, Never> { get }
    
    func getCartItems() -> [CartItem]
    func addItem(product: Product, quantity: Int, specialInstructions: String?) async throws
    func removeItem(withId itemId: String) async throws
    func updateItemQuantity(itemId: String, quantity: Int) async throws
    func clearCart() async throws
    func getSubtotal() -> Int
    func containsProduct(_ productId: String) -> Bool
    func getProductQuantity(_ productId: String) -> Int
    func getCartItem(for productId: String) -> CartItem?
}

protocol ProductRepository {
    func fetchProducts(for partnerId: String) async throws -> [Product]
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product]
    func fetchProduct(by id: String) async throws -> Product?
}

enum CartError: Error {
    case productUnavailable
    case invalidQuantity
    case insufficientStock
    case cartLimitExceeded
    case itemNotFound
}