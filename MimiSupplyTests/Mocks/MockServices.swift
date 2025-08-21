//
//  MockServices.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import Combine
import CoreLocation
import CloudKit
import MapKit
@testable import MimiSupply

// MARK: - Mock CloudKit Service

class MockCloudKitService: CloudKitService {
    var mockProducts: [Product] = []
    var mockPartners: [Partner] = []
    var mockSearchResults: [Product] = []
    var mockOrders: [Order] = []
    var mockUserProfile: UserProfile?
    var mockDriverLocation: DriverLocation?
    var mockOrderStatus: OrderStatus?
    
    var shouldThrowError = false
    var lastSearchQuery: String?
    var savedUserProfile: UserProfile?
    var savedDriverLocation: DriverLocation?
    var createdOrder: Order?
    var updatedOrderId: String?
    var updatedOrderStatus: OrderStatus?
    
    // Order tracking specific properties
    var subscriptionCreated = false
    var lastSubscriptionID: String?
    
    // Simulation methods for testing
    func simulateOrderUpdate(orderId: String, newStatus: OrderStatus) {
        mockOrderStatus = newStatus
        lastSubscriptionID = "order-updates-customer123"
        subscriptionCreated = true
    }
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return mockPartners
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return mockPartners.first { $0.id == id }
    }
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return mockProducts.filter { $0.partnerId == partnerId }
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        lastSearchQuery = query
        return mockSearchResults
    }
    
    func createOrder(_ order: Order) async throws -> Order {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        createdOrder = order
        return order
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        updatedOrderId = orderId
        updatedOrderStatus = status
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return mockOrders.filter { order in
            switch role {
            case .customer:
                return order.customerId == userId
            case .driver:
                return order.driverId == userId
            case .partner:
                return order.partnerId == userId
            case .admin:
                return true
            }
        }
    }
    
    func saveUserProfile(_ user: UserProfile) async throws {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        savedUserProfile = user
    }
    
    func fetchUserProfile(by appleUserID: String) async throws -> UserProfile? {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return mockUserProfile
    }
    
    func saveDriverLocation(_ location: DriverLocation) async throws {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        savedDriverLocation = location
    }
    
    func fetchDriverLocation(for driverId: String) async throws -> DriverLocation? {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return mockDriverLocation
    }
    
    func subscribeToOrderUpdates(for userId: String) async throws {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        subscriptionCreated = true
        lastSubscriptionID = "order-updates-\(userId)"
    }
    
    func subscribeToDriverLocationUpdates(for orderId: String) async throws {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        subscriptionCreated = true
        lastSubscriptionID = "driver-location-updates-\(orderId)"
    }
    
    func createSubscription(_ subscription: CKSubscription) async throws -> CKSubscription {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
        return subscription
    }
    
    func deleteSubscription(withID subscriptionID: String) async throws {
        if shouldThrowError { throw CloudKitError.networkUnavailable }
    }
}

// MARK: - Mock Keychain Service

class MockKeychainService: KeychainService {
    var storedValues: [String: Data] = [:]
    var storedKeys: Set<String> = []
    var deletedKeys: Set<String> = []
    var shouldReturnNil = false
    var shouldThrowOnStore = false
    var shouldThrowOnDelete = false
    
    func store<T: Codable>(_ value: T, for key: String) throws {
        if shouldThrowOnStore {
            throw KeychainError.storeFailed(errSecDuplicateItem)
        }
        
        let data = try JSONEncoder().encode(value)
        storedValues[key] = data
        storedKeys.insert(key)
    }
    
    func retrieve<T: Codable>(_ type: T.Type, for key: String) throws -> T? {
        if shouldReturnNil {
            return nil
        }
        
        guard let data = storedValues[key] else {
            return nil
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
    
    func delete(for key: String) throws {
        if shouldThrowOnDelete {
            throw KeychainError.deleteFailed(errSecItemNotFound)
        }
        
        storedValues.removeValue(forKey: key)
        deletedKeys.insert(key)
    }
    
    func deleteAll() throws {
        if shouldThrowOnDelete {
            throw KeychainError.deleteFailed(errSecItemNotFound)
        }
        
        storedValues.removeAll()
        deletedKeys.formUnion(Set(storedValues.keys))
    }
}

// MARK: - Mock Authentication Service

class MockAuthenticationService: AuthenticationService {
    
    // Mock state
    var mockAuthState: AuthenticationState = .unauthenticated
    var mockCurrentUser: UserProfile?
    var mockAuthResult: AuthenticationResult?
    
    // Error simulation
    var shouldThrowError = false
    var shouldThrowOnRoleUpdate = false
    var errorToThrow: AuthenticationError = .signInFailed("Mock error")
    
    // Call tracking
    var signOutCalled = false
    var updateProfileCalled = false
    var deleteAccountCalled = false
    
    // State publisher
    let stateSubject = CurrentValueSubject<AuthenticationState, Never>(.unauthenticated)
    
    var isAuthenticated: Bool {
        get async {
            mockAuthState.isAuthenticated
        }
    }
    
    var currentUser: UserProfile? {
        get async {
            mockCurrentUser
        }
    }
    
    var authenticationState: AuthenticationState {
        get async {
            mockAuthState
        }
    }
    
    var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    func signInWithApple() async throws -> AuthenticationResult {
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let result = mockAuthResult else {
            throw AuthenticationError.signInFailed("No mock result configured")
        }
        
        mockCurrentUser = result.user
        
        if result.requiresRoleSelection {
            mockAuthState = .roleSelectionRequired(result.user)
        } else {
            mockAuthState = .authenticated(result.user)
        }
        
        stateSubject.send(mockAuthState)
        return result
    }
    
    func signOut() async throws {
        signOutCalled = true
        mockCurrentUser = nil
        mockAuthState = .unauthenticated
        stateSubject.send(mockAuthState)
    }
    
    func refreshCredentials() async throws -> Bool {
        return true
    }
    
    func updateUserRole(_ role: UserRole) async throws -> UserProfile {
        if shouldThrowOnRoleUpdate {
            throw AuthenticationError.roleSelectionRequired
        }
        
        guard var user = mockCurrentUser else {
            throw AuthenticationError.invalidCredentials
        }
        
        user = UserProfile(
            id: user.id,
            appleUserID: user.appleUserID,
            email: user.email,
            fullName: user.fullName,
            role: role,
            phoneNumber: user.phoneNumber,
            profileImageURL: user.profileImageURL,
            isVerified: user.isVerified,
            createdAt: user.createdAt,
            lastActiveAt: Date()
        )
        
        mockCurrentUser = user
        mockAuthState = .authenticated(user)
        stateSubject.send(mockAuthState)
        
        return user
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        updateProfileCalled = true
        mockCurrentUser = profile
        mockAuthState = .authenticated(profile)
        stateSubject.send(mockAuthState)
        return profile
    }
    
    func deleteAccount() async throws {
        deleteAccountCalled = true
        mockCurrentUser = nil
        mockAuthState = .unauthenticated
        stateSubject.send(mockAuthState)
    }
    
    func hasPermission(for action: AuthenticationAction) async -> Bool {
        guard let user = mockCurrentUser else {
            return action.requiredRole == nil
        }
        
        guard let requiredRole = action.requiredRole else {
            return true
        }
        
        return user.role == requiredRole || user.role == .admin
    }
    
    func startAutomaticStateManagement() async {
        // Mock implementation
    }
    
    func stopAutomaticStateManagement() async {
        // Mock implementation
    }
}

// MARK: - Mock Core Data Stack Protocol

protocol CoreDataStackProtocol {
    func cacheProducts(_ products: [Product], for partnerId: String)
    func loadCachedProducts(for partnerId: String) -> [Product]
    func cachePartners(_ partners: [Partner])
    func loadCachedPartners() -> [Partner]
}

class MockCoreDataStack: CoreDataStackProtocol {
    var mockCachedProducts: [Product] = []
    var mockAllCachedProducts: [Product] = []
    var mockCachedPartners: [Partner] = []
    var cacheProductsCalled = false
    var loadCachedProductsCalled = false
    var cachePartnersCalled = false
    var loadCachedPartnersCalled = false
    
    func cacheProducts(_ products: [Product], for partnerId: String) {
        cacheProductsCalled = true
        mockCachedProducts = products
    }
    
    func loadCachedProducts(for partnerId: String) -> [Product] {
        loadCachedProductsCalled = true
        return partnerId.isEmpty ? mockAllCachedProducts : mockCachedProducts
    }
    
    func cachePartners(_ partners: [Partner]) {
        cachePartnersCalled = true
        mockCachedPartners = partners
    }
    
    func loadCachedPartners() -> [Partner] {
        loadCachedPartnersCalled = true
        return mockCachedPartners
    }
}

// MARK: - Mock CoreDataStack for Cart

/// Centralized cart-specific CoreDataStack mock used by cart-related tests
class MockCartCoreDataStack: CoreDataStack {
    var savedCartItems: [CartItem] = []

    override func loadCartItems() -> [CartItem] {
        return savedCartItems
    }

    override func saveCartItems(_ items: [CartItem]) {
        savedCartItems = items
    }
}

// MARK: - Mock Payment Service

class MockPaymentService: PaymentService {
    
    var shouldSucceed = true
    var shouldThrowError: PaymentError?
    var mockReceipts: [String: PaymentReceipt] = [:]
    var processPaymentCalled = false
    var refundPaymentCalled = false
    var lastProcessedOrder: Order?
    var lastRefundOrderId: String?
    var lastRefundAmount: Int?
    
    func processPayment(for order: Order) async throws -> PaymentResult {
        processPaymentCalled = true
        lastProcessedOrder = order
        
        if let error = shouldThrowError {
            throw AppError.payment(error)
        }
        
        if !shouldSucceed {
            throw AppError.payment(.paymentFailed)
        }
        
        let result = PaymentResult(
            transactionId: "mock_txn_\(UUID().uuidString)",
            status: .completed,
            amount: order.totalCents,
            timestamp: Date()
        )
        
        // Generate receipt
        let receipt = generateDigitalReceipt(for: order, paymentResult: result)
        
        return result
    }
    
    func refundPayment(for orderId: String, amount: Int) async throws {
        refundPaymentCalled = true
        lastRefundOrderId = orderId
        lastRefundAmount = amount
        
        if let error = shouldThrowError {
            throw AppError.payment(error)
        }
        
        guard var receipt = mockReceipts[orderId] else {
            throw AppError.payment(.receiptNotFound)
        }
        
        receipt.refundAmount = amount
        receipt.refundDate = Date()
        receipt.status = .refunded
        mockReceipts[orderId] = receipt
    }
    
    func validateMerchantCapability() -> Bool {
        return true // Always return true for testing
    }
    
    func getPaymentReceipt(for orderId: String) -> PaymentReceipt? {
        return mockReceipts[orderId]
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
            customerEmail: nil,
            refundAmount: nil,
            refundDate: nil
        )
        
        mockReceipts[order.id] = receipt
        return receipt
    }
}

// MARK: - Mock Location Service

class MockLocationService: LocationService {
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var mockCurrentLocation: CLLocation?
    var isUpdatingLocation = false
    var isBackgroundLocationEnabled = false
    var didRequestPermission = false
    var shouldThrowPermissionError = false
    var shouldThrowLocationError = false
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    
    var currentLocation: CLLocation? {
        get async {
            if shouldThrowLocationError {
                return nil
            }
            return mockCurrentLocation
        }
    }
    
    func requestLocationPermission() async throws {
        didRequestPermission = true
        
        if shouldThrowPermissionError {
            throw LocationError.permissionDenied
        }
    }
    
    func startLocationUpdates() async throws {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        isUpdatingLocation = true
        desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func stopLocationUpdates() {
        isUpdatingLocation = false
    }
    
    func startBackgroundLocationUpdates() async throws {
        guard authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        isBackgroundLocationEnabled = true
        desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func stopBackgroundLocationUpdates() {
        isBackgroundLocationEnabled = false
    }
}

// MARK: - Mock Order Repository

class MockOrderRepository: OrderRepository {
    var mockOrders: [Order] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.network(.noConnection)
    
    var createOrderCalled = false
    var fetchOrderCalled = false
    var fetchOrdersCalled = false
    var updateOrderStatusCalled = false
    var assignDriverCalled = false
    
    var lastCreatedOrder: Order?
    var lastFetchedOrderId: String?
    var lastFetchedUserId: String?
    var lastFetchedUserRole: UserRole?
    var lastUpdatedOrderId: String?
    var lastUpdatedOrderStatus: OrderStatus?
    var lastAssignedDriverId: String?
    var lastAssignedOrderId: String?
    
    func createOrder(_ order: Order) async throws -> Order {
        createOrderCalled = true
        lastCreatedOrder = order
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        mockOrders.append(order)
        return order
    }
    
    func fetchOrder(by id: String) async throws -> Order? {
        fetchOrderCalled = true
        lastFetchedOrderId = id
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockOrders.first { $0.id == id }
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        fetchOrdersCalled = true
        lastFetchedUserId = userId
        lastFetchedUserRole = role
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockOrders.filter { order in
            switch role {
            case .customer:
                return order.customerId == userId
            case .driver:
                return order.driverId == userId
            case .partner:
                return order.partnerId == userId
            case .admin:
                return true
            }
        }
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        updateOrderStatusCalled = true
        lastUpdatedOrderId = orderId
        lastUpdatedOrderStatus = status
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Update the mock order
        if let index = mockOrders.firstIndex(where: { $0.id == orderId }) {
            let updatedOrder = Order(
                id: mockOrders[index].id,
                customerId: mockOrders[index].customerId,
                partnerId: mockOrders[index].partnerId,
                driverId: mockOrders[index].driverId,
                items: mockOrders[index].items,
                status: status,
                subtotalCents: mockOrders[index].subtotalCents,
                deliveryFeeCents: mockOrders[index].deliveryFeeCents,
                platformFeeCents: mockOrders[index].platformFeeCents,
                taxCents: mockOrders[index].taxCents,
                tipCents: mockOrders[index].tipCents,
                deliveryAddress: mockOrders[index].deliveryAddress,
                deliveryInstructions: mockOrders[index].deliveryInstructions,
                estimatedDeliveryTime: mockOrders[index].estimatedDeliveryTime,
                actualDeliveryTime: status == .delivered ? Date() : mockOrders[index].actualDeliveryTime,
                paymentMethod: mockOrders[index].paymentMethod,
                paymentStatus: mockOrders[index].paymentStatus,
                createdAt: mockOrders[index].createdAt,
                updatedAt: Date()
            )
            mockOrders[index] = updatedOrder
        }
    }
    
    func assignDriver(_ driverId: String, to orderId: String) async throws {
        assignDriverCalled = true
        lastAssignedDriverId = driverId
        lastAssignedOrderId = orderId
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Update the mock order
        if let index = mockOrders.firstIndex(where: { $0.id == orderId }) {
            let updatedOrder = Order(
                id: mockOrders[index].id,
                customerId: mockOrders[index].customerId,
                partnerId: mockOrders[index].partnerId,
                driverId: driverId,
                items: mockOrders[index].items,
                status: .driverAssigned,
                subtotalCents: mockOrders[index].subtotalCents,
                deliveryFeeCents: mockOrders[index].deliveryFeeCents,
                platformFeeCents: mockOrders[index].platformFeeCents,
                taxCents: mockOrders[index].taxCents,
                tipCents: mockOrders[index].tipCents,
                deliveryAddress: mockOrders[index].deliveryAddress,
                deliveryInstructions: mockOrders[index].deliveryInstructions,
                estimatedDeliveryTime: mockOrders[index].estimatedDeliveryTime,
                actualDeliveryTime: mockOrders[index].actualDeliveryTime,
                paymentMethod: mockOrders[index].paymentMethod,
                paymentStatus: mockOrders[index].paymentStatus,
                createdAt: mockOrders[index].createdAt,
                updatedAt: Date()
            )
            mockOrders[index] = updatedOrder
        }
    }
}
