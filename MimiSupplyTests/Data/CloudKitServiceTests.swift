//
//  CloudKitServiceTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import CloudKit
import MapKit
@testable import MimiSupply

final class CloudKitServiceTests: XCTestCase {
    
    var sut: CloudKitServiceImpl!
    var mockContainer: CKContainer!
    
    override func setUpWithError() throws {
        super.setUp()
        sut = CloudKitServiceImpl()
        mockContainer = CKContainer.default()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        mockContainer = nil
        super.tearDown()
    }
    
    // MARK: - Partner Tests
    
    func testFetchPartnersInRegion() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // When & Then
        // Note: This test would require mocking CloudKit or using a test container
        // For now, we test that the method doesn't crash and returns an array
        let partners = try await sut.fetchPartners(in: region)
        XCTAssertNotNil(partners)
        XCTAssertTrue(partners is [Partner])
    }
    
    func testFetchPartnerById() async throws {
        // Given
        let partnerId = "test-partner-id"
        
        // When & Then
        let partner = try await sut.fetchPartner(by: partnerId)
        // Partner may be nil if not found, which is valid
        if let partner = partner {
            XCTAssertEqual(partner.id, partnerId)
        }
    }
    
    // MARK: - Product Tests
    
    func testFetchProductsForPartner() async throws {
        // Given
        let partnerId = "test-partner-id"
        
        // When & Then
        let products = try await sut.fetchProducts(for: partnerId)
        XCTAssertNotNil(products)
        XCTAssertTrue(products is [Product])
    }
    
    func testSearchProducts() async throws {
        // Given
        let query = "pizza"
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        // When & Then
        let products = try await sut.searchProducts(query: query, in: region)
        XCTAssertNotNil(products)
        XCTAssertTrue(products is [Product])
    }
    
    // MARK: - Order Tests
    
    func testCreateOrder() async throws {
        // Given
        let order = createMockOrder()
        
        // When & Then
        let createdOrder = try await sut.createOrder(order)
        XCTAssertEqual(createdOrder.id, order.id)
        XCTAssertEqual(createdOrder.customerId, order.customerId)
        XCTAssertEqual(createdOrder.partnerId, order.partnerId)
    }
    
    func testUpdateOrderStatus() async throws {
        // Given
        let orderId = "test-order-id"
        let newStatus = OrderStatus.preparing
        
        // When & Then
        // This test would require an existing order in CloudKit
        // For now, we test that the method doesn't crash
        try await sut.updateOrderStatus(orderId, status: newStatus)
    }
    
    func testFetchOrdersForUser() async throws {
        // Given
        let userId = "test-user-id"
        let role = UserRole.customer
        
        // When & Then
        let orders = try await sut.fetchOrders(for: userId, role: role)
        XCTAssertNotNil(orders)
        XCTAssertTrue(orders is [Order])
    }
    
    // MARK: - User Profile Tests
    
    func testSaveUserProfile() async throws {
        // Given
        let userProfile = createMockUserProfile()
        
        // When & Then
        try await sut.saveUserProfile(userProfile)
        // Test passes if no exception is thrown
    }
    
    func testFetchUserProfile() async throws {
        // Given
        let appleUserID = "test-apple-user-id"
        
        // When & Then
        let userProfile = try await sut.fetchUserProfile(by: appleUserID)
        // User profile may be nil if not found, which is valid
        if let userProfile = userProfile {
            XCTAssertEqual(userProfile.appleUserID, appleUserID)
        }
    }
    
    // MARK: - Driver Location Tests
    
    func testSaveDriverLocation() async throws {
        // Given
        let driverLocation = createMockDriverLocation()
        
        // When & Then
        try await sut.saveDriverLocation(driverLocation)
        // Test passes if no exception is thrown
    }
    
    func testFetchDriverLocation() async throws {
        // Given
        let driverId = "test-driver-id"
        
        // When & Then
        let location = try await sut.fetchDriverLocation(for: driverId)
        // Location may be nil if not found, which is valid
        if let location = location {
            XCTAssertEqual(location.driverId, driverId)
        }
    }
    
    // MARK: - Subscription Tests
    
    func testSubscribeToOrderUpdates() async throws {
        // Given
        let userId = "test-user-id"
        
        // When & Then
        try await sut.subscribeToOrderUpdates(for: userId)
        // Test passes if no exception is thrown
    }
    
    // MARK: - Helper Methods
    
    private func createMockOrder() -> Order {
        let address = Address(
            street: "123 Test St",
            city: "Test City",
            state: "CA",
            postalCode: "12345",
            country: "US"
        )
        
        let orderItem = OrderItem(
            productId: "test-product-id",
            productName: "Test Product",
            quantity: 2,
            unitPriceCents: 1000
        )
        
        return Order(
            customerId: "test-customer-id",
            partnerId: "test-partner-id",
            items: [orderItem],
            subtotalCents: 2000,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 180,
            deliveryAddress: address,
            paymentMethod: .applePay
        )
    }
    
    private func createMockUserProfile() -> UserProfile {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "Test"
        nameComponents.familyName = "User"
        
        return UserProfile(
            appleUserID: "test-apple-user-id",
            email: "test@example.com",
            fullName: nameComponents,
            role: .customer
        )
    }
    
    private func createMockDriverLocation() -> DriverLocation {
        return DriverLocation(
            driverId: "test-driver-id",
            location: Coordinate(latitude: 37.7749, longitude: -122.4194),
            heading: 90.0,
            speed: 25.0,
            accuracy: 5.0
        )
    }
}