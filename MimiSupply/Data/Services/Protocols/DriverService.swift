//
//  DriverService.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import CoreLocation

/// Service for managing driver operations and job handling
protocol DriverService: Sendable {
    
    // MARK: - Driver Status Management
    
    /// Updates driver online/offline status
    func updateOnlineStatus(_ isOnline: Bool, for driverId: String) async throws
    
    /// Updates driver availability status
    func updateAvailabilityStatus(_ isAvailable: Bool, for driverId: String) async throws
    
    /// Gets current driver profile
    func getCurrentDriverProfile() async throws -> Driver?
    
    /// Updates driver location in background
    func updateDriverLocation(_ location: CLLocationCoordinate2D, for driverId: String) async throws
    
    // MARK: - Job Management
    
    /// Fetches available delivery jobs for the driver
    func fetchAvailableJobs() async throws -> [Order]
    
    /// Accepts a delivery job
    func acceptJob(orderId: String, driverId: String) async throws -> Order
    
    /// Declines a delivery job
    func declineJob(orderId: String, driverId: String) async throws
    
    /// Gets current active job for driver
    func getCurrentJob(for driverId: String) async throws -> Order?
    
    /// Updates job status (picked up, delivering, etc.)
    func updateJobStatus(orderId: String, status: OrderStatus) async throws -> Order
    
    /// Completes delivery with photo confirmation
    func completeDelivery(orderId: String, photoData: Data?, completionNotes: String?) async throws -> Order
    
    // MARK: - Earnings Tracking
    
    /// Gets daily earnings summary
    func getDailyEarnings(for date: Date, driverId: String) async throws -> EarningsSummary
    
    /// Gets weekly earnings summary  
    func getWeeklyEarnings(for weekStartDate: Date, driverId: String) async throws -> EarningsSummary
    
    /// Gets delivery history for earnings calculation
    func getCompletedDeliveries(for driverId: String, from startDate: Date, to endDate: Date) async throws -> [Order]
    
    // MARK: - Real-time Updates
    
    /// Starts listening for new job assignments
    func startListeningForJobs(driverId: String) async throws -> AsyncStream<Order>
    
    /// Stops listening for job assignments
    func stopListeningForJobs()
}

/// Earnings summary model for driver dashboard
struct EarningsSummary: Codable, Sendable {
    let totalEarnings: Double
    let totalDeliveries: Int
    let averageEarningsPerDelivery: Double
    let workingHours: Double
    let earnings: [EarningsDetail]
    
    init(totalEarnings: Double, totalDeliveries: Int, workingHours: Double, earnings: [EarningsDetail]) {
        self.totalEarnings = totalEarnings
        self.totalDeliveries = totalDeliveries
        self.averageEarningsPerDelivery = totalDeliveries > 0 ? totalEarnings / Double(totalDeliveries) : 0
        self.workingHours = workingHours
        self.earnings = earnings
    }
    
    var formattedTotalEarnings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalEarnings)) ?? "$0.00"
    }
}

/// Individual earnings detail for a completed delivery
struct EarningsDetail: Codable, Sendable, Identifiable {
    let id: String
    let orderId: String
    let basePayment: Double
    let tip: Double
    let bonus: Double
    let totalEarning: Double
    let completedAt: Date
    let distance: Double?
    
    init(
        id: String = UUID().uuidString,
        orderId: String,
        basePayment: Double,
        tip: Double,
        bonus: Double = 0,
        completedAt: Date = Date(),
        distance: Double? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.basePayment = basePayment
        self.tip = tip
        self.bonus = bonus
        self.totalEarning = basePayment + tip + bonus
        self.completedAt = completedAt
        self.distance = distance
    }
    
    var formattedEarning: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalEarning)) ?? "$0.00"
    }
}
