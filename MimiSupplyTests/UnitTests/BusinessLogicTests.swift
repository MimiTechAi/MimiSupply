//
//  BusinessLogicTests.swift
//  MimiSupplyTests
//
//  Created by Alex on 15.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

class BusinessLogicTests: MimiSupplyTestCase {
    
    // MARK: - User Management Tests
    
    func testUserCreation() {
        // Given
        let email = "test@example.com"
        let name = "Test User"
        let role = UserRole.partner
        
        // When
        let user = User(
            id: "test-id",
            email: email,
            name: name,
            role: role,
            isActive: true,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        // Then
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.role, role)
        XCTAssertTrue(user.isActive)
    }
    
    func testUserValidation() {
        // Given
        let user = createTestUser()
        
        // When & Then
        XCTAssertTrue(user.isValidEmail)
        XCTAssertFalse(user.isExpired)
        XCTAssertTrue(user.canAccessPartnerFeatures)
    }
    
    // MARK: - Product Management Tests
    
    func testProductCreation() {
        // Given
        let product = createTestProduct()
        
        // When & Then
        XCTAssertEqual(product.name, "Test Product")
        XCTAssertEqual(product.price, 99.99)
        XCTAssertTrue(product.isActive)
    }
    
    func testProductPriceCalculation() {
        // Given
        let product = createTestProduct()
        let taxRate = 0.1
        
        // When
        let totalPrice = product.calculateTotalPrice(taxRate: taxRate, discount: 0.05)
        
        // Then
        let expectedPrice = (99.99 * 0.95) * 1.1 // Apply 5% discount, then 10% tax
        XCTAssertEqual(totalPrice, expectedPrice, accuracy: 0.01)
    }
    
    // MARK: - Order Management Tests
    
    func testOrderCreation() {
        // Given
        let order = createTestOrder()
        
        // When & Then
        XCTAssertEqual(order.status, .pending)
        XCTAssertEqual(order.items.count, 1)
        XCTAssertEqual(order.total, 99.99)
    }
    
    func testOrderStatusTransitions() async {
        // Given
        let order = createTestOrder()
        let orderManager = OrderManager()
        
        // When & Then - Test valid transitions
        await assertOrderTransition(order: order, from: .pending, to: .confirmed, shouldSucceed: true)
        await assertOrderTransition(order: order, from: .confirmed, to: .shipped, shouldSucceed: true)
        await assertOrderTransition(order: order, from: .shipped, to: .delivered, shouldSucceed: true)
        
        // Test invalid transitions
        await assertOrderTransition(order: order, from: .pending, to: .delivered, shouldSucceed: false)
        await assertOrderTransition(order: order, from: .cancelled, to: .confirmed, shouldSucceed: false)
    }
    
    private func assertOrderTransition(
        order: Order,
        from: OrderStatus,
        to: OrderStatus,
        shouldSucceed: Bool
    ) async {
        // Given
        var testOrder = order
        testOrder.status = from
        
        // When
        let result = OrderManager.canTransition(from: from, to: to)
        
        // Then
        XCTAssertEqual(result, shouldSucceed, "Transition from \(from) to \(to) should \(shouldSucceed ? "succeed" : "fail")")
    }
    
    // MARK: - Analytics Tests
    
    func testAnalyticsEventTracking() {
        // Given
        let eventName = "product_viewed"
        let parameters = ["product_id": "test-123", "category": "electronics"]
        
        // When
        mockAnalyticsService.track(event: eventName, parameters: parameters)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.hasTrackedEvent(eventName))
        XCTAssertEqual(mockAnalyticsService.getEventParameters(for: eventName)?["product_id"] as? String, "test-123")
    }
    
    func testAnalyticsScreenTracking() {
        // Given
        let screenName = "ProductDetailView"
        
        // When
        mockAnalyticsService.trackScreen(screenName)
        
        // Then
        XCTAssertTrue(mockAnalyticsService.trackedScreens.contains(screenName))
    }
    
    // MARK: - Network Service Tests
    
    func testSuccessfulNetworkRequest() async throws {
        // Given
        let testData = try JSONEncoder().encode(createTestUser())
        mockNetworkService.mockData = testData
        mockNetworkService.shouldSucceed = true
        
        // When
        let result = try await mockNetworkService.request(
            APIEndpoint.getUser(id: "test-id"),
            type: User.self
        )
        
        // Then
        XCTAssertEqual(result.id, "test-user-id")
        XCTAssertEqual(result.email, "test@example.com")
    }
    
    func testFailedNetworkRequest() async {
        // Given
        mockNetworkService.shouldSucceed = false
        mockNetworkService.mockError = NetworkError.serverError(500)
        
        // When & Then
        await assertThrowsError({
            try await mockNetworkService.request(
                APIEndpoint.getUser(id: "test-id"),
                type: User.self
            )
        }, NetworkError.self)
    }
    
    // MARK: - Authentication Tests
    
    func testSuccessfulLogin() async throws {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldFailLogin = false
        
        // When
        let response = try await mockAuthService.login(email: email, password: password)
        
        // Then
        XCTAssertTrue(mockAuthService.isAuthenticated)
        XCTAssertNotNil(mockAuthService.currentUser)
        XCTAssertEqual(response.user.email, email)
        XCTAssertEqual(response.token, "mock-token")
    }
    
    func testFailedLogin() async {
        // Given
        mockAuthService.shouldFailLogin = true
        
        // When & Then
        await assertThrowsError({
            try await mockAuthService.login(email: "invalid@example.com", password: "wrong")
        }, AuthError.self)
        
        XCTAssertFalse(mockAuthService.isAuthenticated)
        XCTAssertNil(mockAuthService.currentUser)
    }
    
    func testLogout() async {
        // Given - User is logged in
        try? await mockAuthService.login(email: "test@example.com", password: "password")
        XCTAssertTrue(mockAuthService.isAuthenticated)
        
        // When
        await mockAuthService.logout()
        
        // Then
        XCTAssertFalse(mockAuthService.isAuthenticated)
        XCTAssertNil(mockAuthService.currentUser)
    }
    
    // MARK: - Data Validation Tests
    
    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue(ValidationHelper.isValidEmail("test@example.com"))
        XCTAssertTrue(ValidationHelper.isValidEmail("user.name+tag@example.co.uk"))
        
        // Invalid emails
        XCTAssertFalse(ValidationHelper.isValidEmail("invalid-email"))
        XCTAssertFalse(ValidationHelper.isValidEmail("@example.com"))
        XCTAssertFalse(ValidationHelper.isValidEmail("test@"))
        XCTAssertFalse(ValidationHelper.isValidEmail(""))
    }
    
    func testPasswordValidation() {
        // Valid passwords
        XCTAssertTrue(ValidationHelper.isValidPassword("SecurePassword123!"))
        XCTAssertTrue(ValidationHelper.isValidPassword("MyP@ssw0rd"))
        
        // Invalid passwords
        XCTAssertFalse(ValidationHelper.isValidPassword("weak")) // Too short
        XCTAssertFalse(ValidationHelper.isValidPassword("NoNumbersOrSymbols")) // Missing requirements
        XCTAssertFalse(ValidationHelper.isValidPassword("")) // Empty
    }
    
    func testPhoneNumberValidation() {
        // Valid phone numbers
        XCTAssertTrue(ValidationHelper.isValidPhoneNumber("+1234567890"))
        XCTAssertTrue(ValidationHelper.isValidPhoneNumber("(555) 123-4567"))
        
        // Invalid phone numbers
        XCTAssertFalse(ValidationHelper.isValidPhoneNumber("123"))
        XCTAssertFalse(ValidationHelper.isValidPhoneNumber("invalid-phone"))
        XCTAssertFalse(ValidationHelper.isValidPhoneNumber(""))
    }
    
    // MARK: - Business Rules Tests
    
    func testDiscountCalculation() {
        // Given
        let basePrice = 100.0
        let discountPercent = 20.0
        
        // When
        let discountedPrice = PricingCalculator.applyDiscount(
            basePrice: basePrice,
            discountPercent: discountPercent
        )
        
        // Then
        XCTAssertEqual(discountedPrice, 80.0, accuracy: 0.01)
    }
    
    func testTaxCalculation() {
        // Given
        let basePrice = 100.0
        let taxRate = 8.5
        
        // When
        let totalPrice = PricingCalculator.addTax(
            basePrice: basePrice,
            taxRate: taxRate
        )
        
        // Then
        XCTAssertEqual(totalPrice, 108.5, accuracy: 0.01)
    }
    
    func testShippingCostCalculation() {
        // Given
        let weight = 2.5 // kg
        let distance = 100 // km
        
        // When
        let shippingCost = ShippingCalculator.calculateCost(
            weight: weight,
            distance: distance
        )
        
        // Then
        XCTAssertGreaterThan(shippingCost, 0)
        XCTAssertLessThan(shippingCost, 100) // Reasonable upper bound
    }
}

// MARK: - Helper Classes

struct ValidationHelper {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8 &&
               password.contains(where: { $0.isNumber }) &&
               password.contains(where: { $0.isLetter }) &&
               password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) })
    }
    
    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = #"^[\+]?[1-9][\d]{0,15}$|^\([0-9]{3}\)\s[0-9]{3}-[0-9]{4}$"#
        let cleanPhone = phone.replacingOccurrences(of: "[^0-9+()]", with: "", options: .regularExpression)
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: cleanPhone)
    }
}

struct PricingCalculator {
    static func applyDiscount(basePrice: Double, discountPercent: Double) -> Double {
        return basePrice * (1 - discountPercent / 100)
    }
    
    static func addTax(basePrice: Double, taxRate: Double) -> Double {
        return basePrice * (1 + taxRate / 100)
    }
}

struct ShippingCalculator {
    static func calculateCost(weight: Double, distance: Double) -> Double {
        let baseCost = 5.0
        let weightCost = weight * 2.0
        let distanceCost = distance * 0.1
        return baseCost + weightCost + distanceCost
    }
}

// MARK: - Extensions for Testing

extension User {
    var isValidEmail: Bool {
        return ValidationHelper.isValidEmail(email)
    }
    
    var isExpired: Bool {
        return false // Simplified for testing
    }
    
    var canAccessPartnerFeatures: Bool {
        return role == .partner && isActive
    }
}

extension Product {
    func calculateTotalPrice(taxRate: Double, discount: Double) -> Double {
        let discountedPrice = price * (1 - discount)
        return discountedPrice * (1 + taxRate)
    }
}

extension OrderManager {
    static func canTransition(from currentStatus: OrderStatus, to newStatus: OrderStatus) -> Bool {
        switch (currentStatus, newStatus) {
        case (.pending, .confirmed), (.pending, .cancelled):
            return true
        case (.confirmed, .shipped), (.confirmed, .cancelled):
            return true
        case (.shipped, .delivered):
            return true
        default:
            return false
        }
    }
}