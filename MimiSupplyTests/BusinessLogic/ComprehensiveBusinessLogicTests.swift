//
//  ComprehensiveBusinessLogicTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 16.08.25.
//

import XCTest
import CoreLocation
@testable import MimiSupply

/// Comprehensive tests for all business logic and use cases
final class ComprehensiveBusinessLogicTests: XCTestCase {
    
    var orderManager: OrderManager!
    var driverAssignmentService: DriverAssignmentService!
    var pricingCalculator: PricingCalculator!
    var deliveryEstimator: DeliveryEstimator!
    var mockServices: MockServiceContainer!
    
    override func setUp() {
        super.setUp()
        mockServices = MockServiceContainer()
        orderManager = OrderManager(
            orderRepository: mockServices.orderRepository,
            paymentService: mockServices.paymentService,
            cloudKitService: mockServices.cloudKitService
        )
        driverAssignmentService = DriverAssignmentService(
            cloudKitService: mockServices.cloudKitService,
            locationService: mockServices.locationService
        )
        pricingCalculator = PricingCalculator()
        deliveryEstimator = DeliveryEstimator(locationService: mockServices.locationService)
    }
    
    override func tearDown() {
        deliveryEstimator = nil
        pricingCalculator = nil
        driverAssignmentService = nil
        orderManager = nil
        mockServices = nil
        super.tearDown()
    }
    
    // MARK: - Order Management Business Logic Tests
    
    func testOrderCreationLogic() async throws {
        // Given
        let customer = TestDataFactory.createTestUser(role: .customer)
        let partner = TestDataFactory.createTestPartner()
        let cartItems = TestDataFactory.createTestCartItems(count: 3)
        let deliveryAddress = TestDataFactory.createTestAddress()
        
        // When
        let order = try await orderManager.createOrder(
            customerId: customer.id,
            partnerId: partner.id,
            cartItems: cartItems,
            deliveryAddress: deliveryAddress,
            paymentMethod: .applePay
        )
        
        // Then
        XCTAssertEqual(order.customerId, customer.id)
        XCTAssertEqual(order.partnerId, partner.id)
        XCTAssertEqual(order.items.count, 3)
        XCTAssertEqual(order.status, .created)
        XCTAssertEqual(order.deliveryAddress, deliveryAddress)
        XCTAssertEqual(order.paymentMethod, .applePay)
        XCTAssertEqual(order.paymentStatus, .pending)
        
        // Verify pricing calculations
        let expectedSubtotal = cartItems.reduce(0) { $0 + ($1.product.priceCents * $1.quantity) }
        XCTAssertEqual(order.subtotalCents, expectedSubtotal)
        XCTAssertGreaterThan(order.totalCents, order.subtotalCents)
    }
    
    func testOrderStatusTransitions() async throws {
        // Given
        let order = TestDataFactory.createTestOrder(status: .created)
        mockServices.orderRepository.mockOrders = [order]
        
        // Test valid transitions
        let validTransitions: [(from: OrderStatus, to: OrderStatus)] = [
            (.created, .paymentProcessing),
            (.paymentProcessing, .paymentConfirmed),
            (.paymentConfirmed, .accepted),
            (.accepted, .preparing),
            (.preparing, .readyForPickup),
            (.readyForPickup, .pickedUp),
            (.pickedUp, .delivering),
            (.delivering, .delivered)
        ]
        
        for (fromStatus, toStatus) in validTransitions {
            // When
            let canTransition = orderManager.canTransitionOrder(from: fromStatus, to: toStatus)
            
            // Then
            XCTAssertTrue(canTransition, "Should be able to transition from \(fromStatus) to \(toStatus)")
        }
        
        // Test invalid transitions
        let invalidTransitions: [(from: OrderStatus, to: OrderStatus)] = [
            (.delivered, .preparing),
            (.cancelled, .accepted),
            (.created, .delivered)
        ]
        
        for (fromStatus, toStatus) in invalidTransitions {
            // When
            let canTransition = orderManager.canTransitionOrder(from: fromStatus, to: toStatus)
            
            // Then
            XCTAssertFalse(canTransition, "Should not be able to transition from \(fromStatus) to \(toStatus)")
        }
    }
    
    func testOrderCancellationLogic() async throws {
        // Given
        let order = TestDataFactory.createTestOrder(status: .accepted)
        mockServices.orderRepository.mockOrders = [order]
        
        // When
        let result = try await orderManager.cancelOrder(order.id, reason: "Customer request")
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.refundAmount, order.totalCents)
        XCTAssertTrue(mockServices.paymentService.refundPaymentCalled)
        XCTAssertEqual(mockServices.paymentService.lastRefundAmount, order.totalCents)
    }
    
    func testOrderCancellationRestrictions() async throws {
        // Given - Order that's too far along to cancel
        let order = TestDataFactory.createTestOrder(status: .delivering)
        mockServices.orderRepository.mockOrders = [order]
        
        // When & Then
        do {
            _ = try await orderManager.cancelOrder(order.id, reason: "Customer request")
            XCTFail("Should not be able to cancel order in delivering status")
        } catch OrderError.cancellationNotAllowed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Driver Assignment Business Logic Tests
    
    func testDriverAssignmentAlgorithm() async throws {
        // Given
        let order = TestDataFactory.createTestOrder()
        let nearbyDrivers = [
            TestDataFactory.createTestDriver(id: "driver-1", isOnline: true, isAvailable: true),
            TestDataFactory.createTestDriver(id: "driver-2", isOnline: true, isAvailable: true),
            TestDataFactory.createTestDriver(id: "driver-3", isOnline: false, isAvailable: true), // Offline
            TestDataFactory.createTestDriver(id: "driver-4", isOnline: true, isAvailable: false) // Busy
        ]
        
        mockServices.cloudKitService.mockDrivers = nearbyDrivers
        
        // When
        let assignedDriver = try await driverAssignmentService.assignDriver(to: order)
        
        // Then
        XCTAssertNotNil(assignedDriver)
        XCTAssertTrue(assignedDriver!.isOnline)
        XCTAssertTrue(assignedDriver!.isAvailable)
        XCTAssertTrue(["driver-1", "driver-2"].contains(assignedDriver!.id))
    }
    
    func testDriverAssignmentByProximity() async throws {
        // Given
        let orderLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let order = TestDataFactory.createTestOrder()
        
        let closeDriver = TestDataFactory.createTestDriver(id: "close-driver")
        let farDriver = TestDataFactory.createTestDriver(id: "far-driver")
        
        // Mock location service to return distances
        mockServices.locationService.mockDistances = [
            "close-driver": 0.5, // 0.5 km away
            "far-driver": 5.0     // 5 km away
        ]
        
        mockServices.cloudKitService.mockDrivers = [farDriver, closeDriver] // Intentionally out of order
        
        // When
        let assignedDriver = try await driverAssignmentService.assignDriver(to: order)
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "close-driver")
    }
    
    func testDriverAssignmentByRating() async throws {
        // Given
        let order = TestDataFactory.createTestOrder()
        let highRatedDriver = TestDataFactory.createTestDriver(id: "high-rated", isOnline: true, isAvailable: true)
        let lowRatedDriver = TestDataFactory.createTestDriver(id: "low-rated", isOnline: true, isAvailable: true)
        
        // Set ratings
        highRatedDriver.rating = 4.9
        lowRatedDriver.rating = 3.5
        
        // Mock equal distances
        mockServices.locationService.mockDistances = [
            "high-rated": 1.0,
            "low-rated": 1.0
        ]
        
        mockServices.cloudKitService.mockDrivers = [lowRatedDriver, highRatedDriver]
        
        // When
        let assignedDriver = try await driverAssignmentService.assignDriver(to: order)
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "high-rated")
    }
    
    func testNoAvailableDrivers() async throws {
        // Given
        let order = TestDataFactory.createTestOrder()
        mockServices.cloudKitService.mockDrivers = [] // No drivers available
        
        // When & Then
        do {
            _ = try await driverAssignmentService.assignDriver(to: order)
            XCTFail("Should throw error when no drivers available")
        } catch DriverAssignmentError.noAvailableDrivers {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Pricing Calculation Business Logic Tests
    
    func testBasicPricingCalculation() throws {
        // Given
        let cartItems = TestDataFactory.createTestCartItems(count: 2)
        let deliveryAddress = TestDataFactory.createTestAddress()
        
        // When
        let pricing = pricingCalculator.calculatePricing(
            cartItems: cartItems,
            deliveryAddress: deliveryAddress,
            partnerLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        // Then
        let expectedSubtotal = cartItems.reduce(0) { $0 + ($1.product.priceCents * $1.quantity) }
        XCTAssertEqual(pricing.subtotalCents, expectedSubtotal)
        XCTAssertGreaterThan(pricing.deliveryFeeCents, 0)
        XCTAssertGreaterThan(pricing.platformFeeCents, 0)
        XCTAssertGreaterThan(pricing.taxCents, 0)
        XCTAssertEqual(pricing.totalCents, pricing.subtotalCents + pricing.deliveryFeeCents + pricing.platformFeeCents + pricing.taxCents + pricing.tipCents)
    }
    
    func testDeliveryFeeCalculation() throws {
        // Given
        let cartItems = TestDataFactory.createTestCartItems(count: 1)
        let partnerLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        // Test different distances
        let shortDistance = TestDataFactory.createTestAddress() // Assume close
        let longDistance = TestDataFactory.createTestAddress(city: "Oakland") // Assume far
        
        // When
        let shortDistancePricing = pricingCalculator.calculatePricing(
            cartItems: cartItems,
            deliveryAddress: shortDistance,
            partnerLocation: partnerLocation
        )
        
        let longDistancePricing = pricingCalculator.calculatePricing(
            cartItems: cartItems,
            deliveryAddress: longDistance,
            partnerLocation: partnerLocation
        )
        
        // Then
        XCTAssertLessThanOrEqual(shortDistancePricing.deliveryFeeCents, longDistancePricing.deliveryFeeCents)
    }
    
    func testMinimumOrderAmount() throws {
        // Given
        let partner = TestDataFactory.createTestPartner()
        partner.minimumOrderAmount = 1500 // $15.00 minimum
        
        let smallOrderItems = [TestDataFactory.createTestCartItem(
            product: TestDataFactory.createTestProduct(priceCents: 800), // $8.00
            quantity: 1
        )]
        
        // When
        let meetsMinimum = pricingCalculator.meetsMinimumOrderAmount(
            cartItems: smallOrderItems,
            partner: partner
        )
        
        // Then
        XCTAssertFalse(meetsMinimum)
        
        // When - Add more items
        let largeOrderItems = smallOrderItems + [TestDataFactory.createTestCartItem(
            product: TestDataFactory.createTestProduct(priceCents: 1000), // $10.00
            quantity: 1
        )]
        
        let meetsMinimumLarge = pricingCalculator.meetsMinimumOrderAmount(
            cartItems: largeOrderItems,
            partner: partner
        )
        
        // Then
        XCTAssertTrue(meetsMinimumLarge)
    }
    
    func testTaxCalculation() throws {
        // Given
        let cartItems = TestDataFactory.createTestCartItems(count: 2)
        let deliveryAddress = TestDataFactory.createTestAddress(state: "CA") // California has sales tax
        
        // When
        let pricing = pricingCalculator.calculatePricing(
            cartItems: cartItems,
            deliveryAddress: deliveryAddress,
            partnerLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        // Then
        XCTAssertGreaterThan(pricing.taxCents, 0)
        
        // Tax should be reasonable percentage of subtotal (5-15%)
        let taxPercentage = Double(pricing.taxCents) / Double(pricing.subtotalCents)
        XCTAssertGreaterThan(taxPercentage, 0.05)
        XCTAssertLessThan(taxPercentage, 0.15)
    }
    
    // MARK: - Delivery Estimation Business Logic Tests
    
    func testDeliveryTimeEstimation() async throws {
        // Given
        let partner = TestDataFactory.createTestPartner()
        let deliveryAddress = TestDataFactory.createTestAddress()
        let currentTime = Date()
        
        // When
        let estimatedTime = try await deliveryEstimator.estimateDeliveryTime(
            from: partner,
            to: deliveryAddress,
            orderTime: currentTime
        )
        
        // Then
        XCTAssertGreaterThan(estimatedTime, currentTime)
        
        // Should be reasonable (15-90 minutes)
        let timeDifference = estimatedTime.timeIntervalSince(currentTime)
        XCTAssertGreaterThan(timeDifference, 15 * 60) // At least 15 minutes
        XCTAssertLessThan(timeDifference, 90 * 60)    // At most 90 minutes
    }
    
    func testDeliveryTimeWithTraffic() async throws {
        // Given
        let partner = TestDataFactory.createTestPartner()
        let deliveryAddress = TestDataFactory.createTestAddress()
        
        // Rush hour time
        let rushHourTime = Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!
        
        // Off-peak time
        let offPeakTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date())!
        
        // When
        let rushHourEstimate = try await deliveryEstimator.estimateDeliveryTime(
            from: partner,
            to: deliveryAddress,
            orderTime: rushHourTime
        )
        
        let offPeakEstimate = try await deliveryEstimator.estimateDeliveryTime(
            from: partner,
            to: deliveryAddress,
            orderTime: offPeakTime
        )
        
        // Then
        let rushHourDuration = rushHourEstimate.timeIntervalSince(rushHourTime)
        let offPeakDuration = offPeakEstimate.timeIntervalSince(offPeakTime)
        
        // Rush hour should generally take longer
        XCTAssertGreaterThanOrEqual(rushHourDuration, offPeakDuration)
    }
    
    // MARK: - Inventory Management Business Logic Tests
    
    func testStockValidation() throws {
        // Given
        let product = TestDataFactory.createTestProduct(stockQuantity: 5)
        let cartItem = TestDataFactory.createTestCartItem(product: product, quantity: 3)
        
        // When
        let isValid = InventoryManager.validateStock(for: cartItem)
        
        // Then
        XCTAssertTrue(isValid)
        
        // When - Requesting more than available
        let oversizedCartItem = TestDataFactory.createTestCartItem(product: product, quantity: 10)
        let isValidOversized = InventoryManager.validateStock(for: oversizedCartItem)
        
        // Then
        XCTAssertFalse(isValidOversized)
    }
    
    func testStockReservation() async throws {
        // Given
        let product = TestDataFactory.createTestProduct(stockQuantity: 10)
        let cartItems = [
            TestDataFactory.createTestCartItem(product: product, quantity: 3),
            TestDataFactory.createTestCartItem(product: product, quantity: 2)
        ]
        
        let inventoryManager = InventoryManager(cloudKitService: mockServices.cloudKitService)
        
        // When
        let reservation = try await inventoryManager.reserveStock(for: cartItems)
        
        // Then
        XCTAssertNotNil(reservation)
        XCTAssertEqual(reservation.items.count, 2)
        XCTAssertEqual(reservation.totalQuantityReserved, 5)
        
        // Verify stock is reduced
        let updatedProduct = try await mockServices.cloudKitService.fetchProduct(by: product.id)
        XCTAssertEqual(updatedProduct?.stockQuantity, 5) // 10 - 5 = 5
    }
    
    // MARK: - Business Hours Logic Tests
    
    func testBusinessHoursValidation() throws {
        // Given
        let partner = TestDataFactory.createTestPartner()
        let businessHours = BusinessHoursManager()
        
        // Test during business hours
        let businessTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let isOpenDuringBusiness = businessHours.isPartnerOpen(partner, at: businessTime)
        XCTAssertTrue(isOpenDuringBusiness)
        
        // Test outside business hours
        let afterHoursTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        let isOpenAfterHours = businessHours.isPartnerOpen(partner, at: afterHoursTime)
        XCTAssertFalse(isOpenAfterHours)
    }
    
    // MARK: - Promotion and Discount Logic Tests
    
    func testDiscountApplication() throws {
        // Given
        let cartItems = TestDataFactory.createTestCartItems(count: 2)
        let discount = Discount(
            id: "test-discount",
            type: .percentage,
            value: 10, // 10% off
            minimumOrderAmount: 1000,
            isActive: true
        )
        
        let promotionManager = PromotionManager()
        
        // When
        let applicableDiscount = promotionManager.findApplicableDiscount(
            for: cartItems,
            availableDiscounts: [discount]
        )
        
        // Then
        XCTAssertNotNil(applicableDiscount)
        XCTAssertEqual(applicableDiscount?.id, "test-discount")
        
        // Calculate discount amount
        let subtotal = cartItems.reduce(0) { $0 + ($1.product.priceCents * $1.quantity) }
        let discountAmount = promotionManager.calculateDiscountAmount(
            discount: discount,
            subtotal: subtotal
        )
        
        XCTAssertEqual(discountAmount, subtotal / 10) // 10% of subtotal
    }
    
    // MARK: - Rating and Review Logic Tests
    
    func testRatingCalculation() throws {
        // Given
        let reviews = [
            Review(rating: 5, comment: "Excellent"),
            Review(rating: 4, comment: "Good"),
            Review(rating: 5, comment: "Great"),
            Review(rating: 3, comment: "Okay"),
            Review(rating: 4, comment: "Nice")
        ]
        
        let ratingManager = RatingManager()
        
        // When
        let averageRating = ratingManager.calculateAverageRating(from: reviews)
        
        // Then
        let expectedAverage = (5 + 4 + 5 + 3 + 4) / 5.0
        XCTAssertEqual(averageRating, expectedAverage, accuracy: 0.01)
    }
    
    // MARK: - Geolocation Business Logic Tests
    
    func testDeliveryRadiusValidation() throws {
        // Given
        let partner = TestDataFactory.createTestPartner()
        partner.deliveryRadius = 5.0 // 5 km radius
        
        let partnerLocation = partner.location
        let nearbyAddress = TestDataFactory.createTestAddress() // Assume within radius
        let farAddress = TestDataFactory.createTestAddress(city: "Oakland") // Assume outside radius
        
        let locationManager = LocationManager(locationService: mockServices.locationService)
        
        // Mock distances
        mockServices.locationService.mockDistances = [
            "nearby": 3.0, // 3 km - within radius
            "far": 8.0     // 8 km - outside radius
        ]
        
        // When
        let nearbyIsValid = locationManager.isWithinDeliveryRadius(
            partner: partner,
            deliveryAddress: nearbyAddress
        )
        
        let farIsValid = locationManager.isWithinDeliveryRadius(
            partner: partner,
            deliveryAddress: farAddress
        )
        
        // Then
        XCTAssertTrue(nearbyIsValid)
        XCTAssertFalse(farIsValid)
    }
}

// MARK: - Supporting Business Logic Classes

class OrderManager {
    private let orderRepository: OrderRepository
    private let paymentService: PaymentService
    private let cloudKitService: CloudKitService
    
    init(orderRepository: OrderRepository, paymentService: PaymentService, cloudKitService: CloudKitService) {
        self.orderRepository = orderRepository
        self.paymentService = paymentService
        self.cloudKitService = cloudKitService
    }
    
    func createOrder(
        customerId: String,
        partnerId: String,
        cartItems: [CartItem],
        deliveryAddress: Address,
        paymentMethod: PaymentMethod
    ) async throws -> Order {
        let pricingCalculator = PricingCalculator()
        let pricing = pricingCalculator.calculatePricing(
            cartItems: cartItems,
            deliveryAddress: deliveryAddress,
            partnerLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        let orderItems = cartItems.map { cartItem in
            OrderItem(
                id: UUID().uuidString,
                productId: cartItem.product.id,
                productName: cartItem.product.name,
                quantity: cartItem.quantity,
                unitPriceCents: cartItem.product.priceCents,
                totalPriceCents: cartItem.product.priceCents * cartItem.quantity,
                specialInstructions: cartItem.specialInstructions
            )
        }
        
        let order = Order(
            id: UUID().uuidString,
            customerId: customerId,
            partnerId: partnerId,
            driverId: nil,
            items: orderItems,
            status: .created,
            subtotalCents: pricing.subtotalCents,
            deliveryFeeCents: pricing.deliveryFeeCents,
            platformFeeCents: pricing.platformFeeCents,
            taxCents: pricing.taxCents,
            tipCents: pricing.tipCents,
            totalCents: pricing.totalCents,
            deliveryAddress: deliveryAddress,
            deliveryInstructions: nil,
            estimatedDeliveryTime: nil,
            actualDeliveryTime: nil,
            paymentMethod: paymentMethod,
            paymentStatus: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return try await orderRepository.createOrder(order)
    }
    
    func canTransitionOrder(from: OrderStatus, to: OrderStatus) -> Bool {
        let validTransitions: [OrderStatus: [OrderStatus]] = [
            .created: [.paymentProcessing, .cancelled],
            .paymentProcessing: [.paymentConfirmed, .cancelled],
            .paymentConfirmed: [.accepted, .cancelled],
            .accepted: [.preparing, .cancelled],
            .preparing: [.readyForPickup],
            .readyForPickup: [.pickedUp],
            .pickedUp: [.delivering],
            .delivering: [.delivered],
            .delivered: [],
            .cancelled: [],
            .failed: []
        ]
        
        return validTransitions[from]?.contains(to) ?? false
    }
    
    func cancelOrder(_ orderId: String, reason: String) async throws -> CancellationResult {
        guard let order = try await orderRepository.fetchOrder(by: orderId) else {
            throw OrderError.orderNotFound
        }
        
        // Check if cancellation is allowed
        let cancellableStatuses: [OrderStatus] = [.created, .paymentProcessing, .paymentConfirmed, .accepted, .preparing]
        guard cancellableStatuses.contains(order.status) else {
            throw OrderError.cancellationNotAllowed
        }
        
        // Process refund
        try await paymentService.refundPayment(for: orderId, amount: order.totalCents)
        
        // Update order status
        try await orderRepository.updateOrderStatus(orderId, status: .cancelled)
        
        return CancellationResult(success: true, refundAmount: order.totalCents)
    }
}

class DriverAssignmentService {
    private let cloudKitService: CloudKitService
    private let locationService: LocationService
    
    init(cloudKitService: CloudKitService, locationService: LocationService) {
        self.cloudKitService = cloudKitService
        self.locationService = locationService
    }
    
    func assignDriver(to order: Order) async throws -> Driver? {
        let availableDrivers = try await cloudKitService.fetchAvailableDrivers(near: order.deliveryAddress.coordinate)
        
        guard !availableDrivers.isEmpty else {
            throw DriverAssignmentError.noAvailableDrivers
        }
        
        // Filter online and available drivers
        let eligibleDrivers = availableDrivers.filter { $0.isOnline && $0.isAvailable }
        
        guard !eligibleDrivers.isEmpty else {
            throw DriverAssignmentError.noAvailableDrivers
        }
        
        // Sort by proximity and rating
        let sortedDrivers = eligibleDrivers.sorted { driver1, driver2 in
            let distance1 = mockServices.locationService.mockDistances[driver1.id] ?? Double.greatestFiniteMagnitude
            let distance2 = mockServices.locationService.mockDistances[driver2.id] ?? Double.greatestFiniteMagnitude
            
            if abs(distance1 - distance2) < 0.1 { // Similar distances
                return driver1.rating > driver2.rating
            }
            return distance1 < distance2
        }
        
        return sortedDrivers.first
    }
}

class PricingCalculator {
    func calculatePricing(
        cartItems: [CartItem],
        deliveryAddress: Address,
        partnerLocation: CLLocationCoordinate2D
    ) -> OrderPricing {
        let subtotal = cartItems.reduce(0) { $0 + ($1.product.priceCents * $1.quantity) }
        
        // Calculate delivery fee based on distance
        let deliveryFee = calculateDeliveryFee(
            from: partnerLocation,
            to: deliveryAddress.coordinate
        )
        
        // Platform fee (typically 10-15% of subtotal)
        let platformFee = max(199, Int(Double(subtotal) * 0.12)) // Minimum $1.99 or 12%
        
        // Tax calculation (varies by location)
        let taxRate = getTaxRate(for: deliveryAddress)
        let tax = Int(Double(subtotal) * taxRate)
        
        let total = subtotal + deliveryFee + platformFee + tax
        
        return OrderPricing(
            subtotalCents: subtotal,
            deliveryFeeCents: deliveryFee,
            platformFeeCents: platformFee,
            taxCents: tax,
            tipCents: 0, // Tip added separately
            totalCents: total
        )
    }
    
    func meetsMinimumOrderAmount(cartItems: [CartItem], partner: Partner) -> Bool {
        let subtotal = cartItems.reduce(0) { $0 + ($1.product.priceCents * $1.quantity) }
        return subtotal >= partner.minimumOrderAmount
    }
    
    private func calculateDeliveryFee(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Int {
        // Simplified distance-based delivery fee
        let baseDeliveryFee = 299 // $2.99 base fee
        let distanceMultiplier = 50 // $0.50 per km
        
        // Mock distance calculation
        let distance = 2.5 // Assume 2.5 km average
        let distanceFee = Int(distance * Double(distanceMultiplier))
        
        return baseDeliveryFee + distanceFee
    }
    
    private func getTaxRate(for address: Address) -> Double {
        // Simplified tax rate lookup
        switch address.state {
        case "CA": return 0.08 // 8% California sales tax
        case "NY": return 0.08 // 8% New York sales tax
        case "TX": return 0.06 // 6% Texas sales tax
        default: return 0.05   // 5% default
        }
    }
}

class DeliveryEstimator {
    private let locationService: LocationService
    
    init(locationService: LocationService) {
        self.locationService = locationService
    }
    
    func estimateDeliveryTime(
        from partner: Partner,
        to deliveryAddress: Address,
        orderTime: Date
    ) async throws -> Date {
        // Base preparation time
        let preparationTime = TimeInterval(partner.estimatedDeliveryTime * 60) // Convert minutes to seconds
        
        // Travel time estimation
        let travelTime = estimateTravelTime(from: partner.location, to: deliveryAddress.coordinate, at: orderTime)
        
        // Buffer time
        let bufferTime: TimeInterval = 5 * 60 // 5 minutes buffer
        
        let totalTime = preparationTime + travelTime + bufferTime
        return orderTime.addingTimeInterval(totalTime)
    }
    
    private func estimateTravelTime(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        at time: Date
    ) -> TimeInterval {
        // Simplified travel time calculation
        let baseTime: TimeInterval = 15 * 60 // 15 minutes base
        
        // Traffic multiplier based on time of day
        let hour = Calendar.current.component(.hour, from: time)
        let trafficMultiplier: Double
        
        switch hour {
        case 7...9, 17...19: // Rush hours
            trafficMultiplier = 1.5
        case 11...14: // Lunch time
            trafficMultiplier = 1.2
        default:
            trafficMultiplier = 1.0
        }
        
        return baseTime * trafficMultiplier
    }
}

// MARK: - Supporting Types and Enums

struct OrderPricing {
    let subtotalCents: Int
    let deliveryFeeCents: Int
    let platformFeeCents: Int
    let taxCents: Int
    let tipCents: Int
    let totalCents: Int
}

struct CancellationResult {
    let success: Bool
    let refundAmount: Int
}

struct Discount {
    let id: String
    let type: DiscountType
    let value: Int
    let minimumOrderAmount: Int
    let isActive: Bool
}

enum DiscountType {
    case percentage
    case fixedAmount
}

struct Review {
    let rating: Int
    let comment: String
}

enum OrderError: Error {
    case orderNotFound
    case cancellationNotAllowed
    case invalidStatus
}

enum DriverAssignmentError: Error {
    case noAvailableDrivers
    case assignmentFailed
}

// MARK: - Mock Extensions

extension MockLocationService {
    var mockDistances: [String: Double] = [:]
}

extension MockCloudKitService {
    var mockDrivers: [Driver] = []
    
    func fetchAvailableDrivers(near location: CLLocationCoordinate2D) async throws -> [Driver] {
        return mockDrivers
    }
    
    func fetchProduct(by id: String) async throws -> Product? {
        return mockProducts.first { $0.id == id }
    }
}

extension Address {
    var coordinate: CLLocationCoordinate2D {
        // Mock coordinate based on city
        switch city {
        case "San Francisco":
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        case "Oakland":
            return CLLocationCoordinate2D(latitude: 37.8044, longitude: -122.2712)
        default:
            return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
    }
}

// MARK: - Additional Business Logic Classes

class InventoryManager {
    private let cloudKitService: CloudKitService
    
    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }
    
    static func validateStock(for cartItem: CartItem) -> Bool {
        guard let stockQuantity = cartItem.product.stockQuantity else {
            return true // No stock limit
        }
        return cartItem.quantity <= stockQuantity
    }
    
    func reserveStock(for cartItems: [CartItem]) async throws -> StockReservation {
        // Implementation would reserve stock in the database
        let totalQuantity = cartItems.reduce(0) { $0 + $1.quantity }
        
        return StockReservation(
            id: UUID().uuidString,
            items: cartItems,
            totalQuantityReserved: totalQuantity,
            expiresAt: Date().addingTimeInterval(15 * 60) // 15 minutes
        )
    }
}

class BusinessHoursManager {
    func isPartnerOpen(_ partner: Partner, at time: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: time)
        let hour = calendar.component(.hour, from: time)
        
        // Simplified business hours check
        // Assume most partners are open 9 AM to 10 PM
        return hour >= 9 && hour < 22
    }
}

class PromotionManager {
    func findApplicableDiscount(
        for cartItems: [CartItem],
        availableDiscounts: [Discount]
    ) -> Discount? {
        let subtotal = cartItems.reduce(0) { $0 + ($1.product.priceCents * $1.quantity) }
        
        return availableDiscounts.first { discount in
            discount.isActive && subtotal >= discount.minimumOrderAmount
        }
    }
    
    func calculateDiscountAmount(discount: Discount, subtotal: Int) -> Int {
        switch discount.type {
        case .percentage:
            return (subtotal * discount.value) / 100
        case .fixedAmount:
            return min(discount.value, subtotal)
        }
    }
}

class RatingManager {
    func calculateAverageRating(from reviews: [Review]) -> Double {
        guard !reviews.isEmpty else { return 0.0 }
        
        let totalRating = reviews.reduce(0) { $0 + $1.rating }
        return Double(totalRating) / Double(reviews.count)
    }
}

class LocationManager {
    private let locationService: LocationService
    
    init(locationService: LocationService) {
        self.locationService = locationService
    }
    
    func isWithinDeliveryRadius(partner: Partner, deliveryAddress: Address) -> Bool {
        // Mock distance calculation
        let mockDistance = deliveryAddress.city == "San Francisco" ? 3.0 : 8.0
        return mockDistance <= partner.deliveryRadius
    }
}

struct StockReservation {
    let id: String
    let items: [CartItem]
    let totalQuantityReserved: Int
    let expiresAt: Date
}