//
//  MockCloudKitService.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation
import MapKit
import CloudKit
import Combine

/// Mock CloudKit service for development and testing
final class MockCloudKitService: CloudKitService {
    
    // MARK: - Properties
    private let mockDelay: TimeInterval = 0.5
    
    // MARK: - Partner Operations
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        // Use the existing MockPartnerRepository
        let mockRepo = MockPartnerRepository()
        return try await mockRepo.fetchPartners(in: region)
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        let mockRepo = MockPartnerRepository()
        return try await mockRepo.fetchPartner(by: id)
    }
    
    func fetchFeaturedPartners() async throws -> [Partner] {
        let mockRepo = MockPartnerRepository()
        return try await mockRepo.fetchFeaturedPartners()
    }
    
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner] {
        let mockRepo = MockPartnerRepository()
        return try await mockRepo.searchPartners(query: query, in: region)
    }
    
    func updatePartnerStatus(partnerId: String, isActive: Bool) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Mock implementation - in real app would update CloudKit record
    }
    
    func fetchPartnerStats(for partnerId: String) async throws -> PartnerStats {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return PartnerStats(
            todayOrderCount: 12,
            todayRevenueCents: 45000,
            averageRating: 4.6,
            totalOrders: 320,
            totalRevenueCents: 1_250_000,
            activeOrders: 3
        )
    }
    
    // MARK: - Product Operations
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Return empty array for now - products would be implemented separately
        return []
    }
    
    func fetchProduct(by id: String) async throws -> Product? {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return nil
    }
    
    func searchProducts(query: String, partnerId: String?) async throws -> [Product] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    // CloudKitService requirement
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    // MARK: - Order Operations
    func createOrder(_ order: Order) async throws -> Order {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return order
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Return empty array for now - would be implemented with mock data
        return []
    }
    
    func fetchOrders(for userId: String, role: UserRole, statuses: [OrderStatus]) async throws -> [Order] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    func fetchRecentOrders(for userId: String, role: UserRole, limit: Int) async throws -> [Order] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    func fetchOrder(by id: String) async throws -> Order? {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return nil
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Mock implementation
    }
    
    // MARK: - User Operations
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return profile
    }
    
    // CloudKitService requirements
    func saveUserProfile(_ user: UserProfile) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
    }
    
    func fetchUserProfile(by appleUserID: String) async throws -> UserProfile? {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return nil
    }
    
    // MARK: - Driver Operations
    func fetchAvailableDrivers(near location: CLLocation, radius: Double) async throws -> [Driver] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return [] // Mock implementation
    }
    
    func updateDriverLocation(_ driverId: String, location: CLLocation) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Mock implementation
    }
    
    func assignOrderToDriver(_ orderId: String, driverId: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Mock implementation
    }
    
    // CloudKitService driver ops
    func saveDriver(_ driver: Driver) async throws -> Driver {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return driver
    }
    
    func fetchDriver(by id: String) async throws -> Driver? {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return nil
    }
    
    func fetchDriverByUserId(_ userId: String) async throws -> Driver? {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return nil
    }
    
    func saveDriverLocation(_ location: DriverLocation) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
    }
    
    func fetchDriverLocation(for driverId: String) async throws -> DriverLocation? {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return nil
    }
    
    func fetchAvailableOrders() async throws -> [Order] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    func updateOrder(_ order: Order) async throws -> Order {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return order
    }
    
    func saveDeliveryCompletion(_ completion: DeliveryCompletionData) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
    }
    
    // MARK: - Subscription Operations
    func subscribeToOrderUpdates(for userId: String) async throws {
        // Mock implementation - do nothing
        print("Mock: Subscribed to order updates for user: \(userId)")
    }
    
    func subscribeToGeneralNotifications() async throws {
        // Mock implementation - do nothing
        print("Mock: Subscribed to general notifications")
    }
    
    func subscribeToDriverLocationUpdates(for orderId: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
    }
    
    func createSubscription(_ subscription: CKSubscription) async throws -> CKSubscription {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return subscription
    }
    
    func deleteSubscription(withID subscriptionID: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
    }
    
    func subscribeToPartnerUpdates(for partnerId: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        // Mock implementation
    }
    
    // MARK: - Analytics Operations
    func fetchPartnerAnalytics(partnerId: String, timeRange: TimeRange) async throws -> PartnerAnalytics {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        return PartnerAnalytics(
            totalRevenue: 12500.0,
            totalOrders: 150,
            averageOrderValue: 83.33,
            customerCount: 89,
            timeRange: timeRange,
            totalRevenueCents: 1250000,
            revenueChangePercent: 15.2,
            ordersChangePercent: 8.7,
            averageOrderValueCents: 8333,
            aovChangePercent: 6.1,
            averageRating: 4.5,
            ratingChangePercent: 2.3
        )
    }
    
    func fetchOrdersData(partnerId: String, timeRange: TimeRange) async throws -> [OrdersDataPoint] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        // Generate mock data points
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        var dataPoints: [OrdersDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let orderCount = Int.random(in: 5...25)
            dataPoints.append(OrdersDataPoint(date: currentDate, orderCount: orderCount))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    func fetchTopProducts(partnerId: String, timeRange: TimeRange) async throws -> [TopProductData] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        return [
            TopProductData(productId: "1", productName: "Pizza Margherita", orderCount: 45, revenueCents: 540000),
            TopProductData(productId: "2", productName: "Caesar Salad", orderCount: 32, revenueCents: 256000),
            TopProductData(productId: "3", productName: "Garlic Bread", orderCount: 28, revenueCents: 168000),
            TopProductData(productId: "4", productName: "Tiramisu", orderCount: 15, revenueCents: 120000),
            TopProductData(productId: "5", productName: "Soda", orderCount: 67, revenueCents: 134000)
        ]
    }
    
    // CloudKitService analytics requirements
    func fetchRevenueChartData(partnerId: String, timeRange: TimeRange) async throws -> [RevenueDataPoint] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    func fetchOrdersChartData(partnerId: String, timeRange: TimeRange) async throws -> [OrdersDataPoint] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    func fetchTopProducts(partnerId: String, timeRange: TimeRange, limit: Int) async throws -> [TopProductData] {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
    
    func fetchPerformanceInsights(partnerId: String, timeRange: TimeRange) async throws -> PartnerInsightData {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return PartnerInsightData(
            keyMetrics: [],
            revenueData: [],
            orderAnalytics: OrderAnalytics(),
            customerInsights: CustomerInsights(),
            topProducts: [],
            generatedAt: Date(),
            revenueChangePercent: 15.2,
            ordersChangePercent: 8.7,
            averageRating: 4.5,
            peakOrderHour: 18,
            topProductName: "Pizza Margherita"
        )
    }
    
    // Push Notification Support
    func updateUserDeviceToken(_ userId: String, deviceToken: String) async throws {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
    }
    
    // MARK: - Generic Operations
    func save<T: Codable>(_ object: T) async throws -> T {
        // Simulate network delay and echo back the object
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return object
    }
    
    func fetch<T: Codable>(_ type: T.Type, predicate: NSPredicate) async throws -> [T] {
        // Simulate network delay and return empty results for mocks
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        return []
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable, Sendable {
    let language: String
    let currency: String
    let notificationsEnabled: Bool
    let locationSharingEnabled: Bool
    let marketingEmailsEnabled: Bool
    
    init(
        language: String = "en",
        currency: String = "USD",
        notificationsEnabled: Bool = true,
        locationSharingEnabled: Bool = true,
        marketingEmailsEnabled: Bool = false
    ) {
        self.language = language
        self.currency = currency
        self.notificationsEnabled = notificationsEnabled
        self.locationSharingEnabled = locationSharingEnabled
        self.marketingEmailsEnabled = marketingEmailsEnabled
    }
}