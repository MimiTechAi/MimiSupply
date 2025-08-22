//
//  CloudKitService.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CloudKit
import MapKit

/// CloudKit service protocol for data synchronization
protocol CloudKitService: Sendable {
    // MARK: - Partner Operations
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner]
    func fetchPartner(by id: String) async throws -> Partner?
    func fetchPartnerStats(for partnerId: String) async throws -> PartnerStats
    func updatePartnerStatus(partnerId: String, isActive: Bool) async throws
    
    // MARK: - Product Operations
    func fetchProducts(for partnerId: String) async throws -> [Product]
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product]
    
    // MARK: - Order Operations
    func createOrder(_ order: Order) async throws -> Order
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order]
    func fetchOrders(for userId: String, role: UserRole, statuses: [OrderStatus]) async throws -> [Order]
    func fetchRecentOrders(for userId: String, role: UserRole, limit: Int) async throws -> [Order]
    
    // MARK: - User Operations
    func saveUserProfile(_ user: UserProfile) async throws
    func fetchUserProfile(by appleUserID: String) async throws -> UserProfile?
    
    // MARK: - Driver Operations
    func saveDriver(_ driver: Driver) async throws -> Driver
    func fetchDriver(by id: String) async throws -> Driver?
    func fetchDriverByUserId(_ userId: String) async throws -> Driver?
    func saveDriverLocation(_ location: DriverLocation) async throws
    func fetchDriverLocation(for driverId: String) async throws -> DriverLocation?
    func fetchAvailableOrders() async throws -> [Order]
    func updateOrder(_ order: Order) async throws -> Order
    func saveDeliveryCompletion(_ completion: DeliveryCompletionData) async throws
    
    // MARK: - Generic Operations
    func save<T: Codable & Sendable>(_ object: T) async throws -> T
    func fetch<T: Codable & Sendable>(_ type: T.Type, predicate: NSPredicate) async throws -> [T]
    
    // MARK: - Analytics Operations
    func fetchPartnerAnalytics(partnerId: String, timeRange: TimeRange) async throws -> PartnerAnalytics
    
    // MARK: - Push Notification Support
    func updateUserDeviceToken(_ userId: String, deviceToken: String) async throws
    func fetchRevenueChartData(partnerId: String, timeRange: TimeRange) async throws -> [RevenueDataPoint]
    func fetchOrdersChartData(partnerId: String, timeRange: TimeRange) async throws -> [OrdersDataPoint]
    func fetchTopProducts(partnerId: String, timeRange: TimeRange, limit: Int) async throws -> [TopProductData]
    func fetchPerformanceInsights(partnerId: String, timeRange: TimeRange) async throws -> PartnerInsightData
    
    // MARK: - Subscriptions
    func subscribeToOrderUpdates(for userId: String) async throws
    func subscribeToGeneralNotifications() async throws
    func fetchOrder(by orderId: String) async throws -> Order?
    func fetchOrderHistory() async throws -> [Order]
}