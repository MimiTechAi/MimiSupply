//
//  DriverServiceImpl.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import CoreLocation

/// Implementation of DriverService for managing driver operations
final class DriverServiceImpl: DriverService, Sendable {
    
    private let cloudKitService: CloudKitService
    private let locationService: LocationService
    private let authenticationService: AuthenticationService
    private let jobListenerLock = NSLock()
    private nonisolated(unsafe) var _jobListener: Task<Void, Never>?
    
    private var jobListener: Task<Void, Never>? {
        get {
            jobListenerLock.lock()
            defer { jobListenerLock.unlock() }
            return _jobListener
        }
        set {
            jobListenerLock.lock()
            defer { jobListenerLock.unlock() }
            _jobListener = newValue
        }
    }
    
    init(
        cloudKitService: CloudKitService,
        locationService: LocationService,
        authenticationService: AuthenticationService
    ) {
        self.cloudKitService = cloudKitService
        self.locationService = locationService
        self.authenticationService = authenticationService
    }
    
    // MARK: - Driver Status Management
    
    func updateOnlineStatus(_ isOnline: Bool, for driverId: String) async throws {
        let driver = try await getDriverProfile(driverId: driverId)
        let updatedDriver = Driver(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            phoneNumber: driver.phoneNumber,
            profileImageURL: driver.profileImageURL,
            vehicleType: driver.vehicleType,
            licensePlate: driver.licensePlate,
            isOnline: isOnline,
            isAvailable: isOnline ? driver.isAvailable : false,
            currentLocation: driver.currentLocation,
            rating: driver.rating,
            completedDeliveries: driver.completedDeliveries,
            verificationStatus: driver.verificationStatus,
            createdAt: driver.createdAt
        )
        try await cloudKitService.save(updatedDriver)
    }
    
    func updateAvailabilityStatus(_ isAvailable: Bool, for driverId: String) async throws {
        let driver = try await getDriverProfile(driverId: driverId)
        let updatedDriver = Driver(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            phoneNumber: driver.phoneNumber,
            profileImageURL: driver.profileImageURL,
            vehicleType: driver.vehicleType,
            licensePlate: driver.licensePlate,
            isOnline: driver.isOnline,
            isAvailable: isAvailable,
            currentLocation: driver.currentLocation,
            rating: driver.rating,
            completedDeliveries: driver.completedDeliveries,
            verificationStatus: driver.verificationStatus,
            createdAt: driver.createdAt
        )
        try await cloudKitService.save(updatedDriver)
    }
    
    func getCurrentDriverProfile() async throws -> Driver? {
        guard let userId = try await authenticationService.getCurrentUserId() else {
            return nil
        }
        return try await cloudKitService.fetch(Driver.self, predicate: NSPredicate(format: "userId == %@", userId)).first
    }
    
    func updateDriverLocation(_ location: CLLocationCoordinate2D, for driverId: String) async throws {
        let driver = try await getDriverProfile(driverId: driverId)
        let updatedDriver = Driver(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            phoneNumber: driver.phoneNumber,
            profileImageURL: driver.profileImageURL,
            vehicleType: driver.vehicleType,
            licensePlate: driver.licensePlate,
            isOnline: driver.isOnline,
            isAvailable: driver.isAvailable,
            currentLocation: Coordinate(location),
            rating: driver.rating,
            completedDeliveries: driver.completedDeliveries,
            verificationStatus: driver.verificationStatus,
            createdAt: driver.createdAt
        )
        try await cloudKitService.save(updatedDriver)
        
        // Also save location tracking entry
        let locationEntry = DriverLocation(
            driverId: driverId,
            location: Coordinate(location),
            accuracy: 5.0
        )
        try await cloudKitService.save(locationEntry)
    }
    
    // MARK: - Job Management
    
    func fetchAvailableJobs() async throws -> [Order] {
        let predicate = NSPredicate(format: "status == %@ AND driverId == nil", OrderStatus.accepted.rawValue)
        return try await cloudKitService.fetch(Order.self, predicate: predicate)
    }
    
    func acceptJob(orderId: String, driverId: String) async throws -> Order {
        guard let order = try await cloudKitService.fetch(Order.self, predicate: NSPredicate(format: "id == %@", orderId)).first else {
            throw AppError.dataNotFound("Order not found")
        }
        
        let updatedOrder = Order(
            id: order.id,
            customerId: order.customerId,
            partnerId: order.partnerId,
            driverId: driverId,
            items: order.items,
            status: .driverAssigned,
            subtotalCents: order.subtotalCents,
            deliveryFeeCents: order.deliveryFeeCents,
            platformFeeCents: order.platformFeeCents,
            taxCents: order.taxCents,
            tipCents: order.tipCents,
            deliveryAddress: order.deliveryAddress,
            deliveryInstructions: order.deliveryInstructions,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            actualDeliveryTime: order.actualDeliveryTime,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            createdAt: order.createdAt,
            updatedAt: Date()
        )
        return try await cloudKitService.save(updatedOrder)
    }
    
    func declineJob(orderId: String, driverId: String) async throws {
        // For now, just log the decline - in a real app this would be tracked for analytics
        print("Driver \(driverId) declined order \(orderId)")
    }
    
    func getCurrentJob(for driverId: String) async throws -> Order? {
        let predicate = NSPredicate(format: "driverId == %@ AND (status == %@ OR status == %@ OR status == %@ OR status == %@)", 
                                  driverId, 
                                  OrderStatus.driverAssigned.rawValue,
                                  OrderStatus.readyForPickup.rawValue,
                                  OrderStatus.pickedUp.rawValue,
                                  OrderStatus.delivering.rawValue)
        return try await cloudKitService.fetch(Order.self, predicate: predicate).first
    }
    
    func updateJobStatus(orderId: String, status: OrderStatus) async throws -> Order {
        guard let order = try await cloudKitService.fetch(Order.self, predicate: NSPredicate(format: "id == %@", orderId)).first else {
            throw AppError.dataNotFound("Order not found")
        }
        
        let updatedOrder = Order(
            id: order.id,
            customerId: order.customerId,
            partnerId: order.partnerId,
            driverId: order.driverId,
            items: order.items,
            status: status,
            subtotalCents: order.subtotalCents,
            deliveryFeeCents: order.deliveryFeeCents,
            platformFeeCents: order.platformFeeCents,
            taxCents: order.taxCents,
            tipCents: order.tipCents,
            deliveryAddress: order.deliveryAddress,
            deliveryInstructions: order.deliveryInstructions,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            actualDeliveryTime: status == .delivered ? Date() : order.actualDeliveryTime,
            paymentMethod: order.paymentMethod,
            paymentStatus: order.paymentStatus,
            createdAt: order.createdAt,
            updatedAt: Date()
        )
        return try await cloudKitService.save(updatedOrder)
    }
    
    func completeDelivery(orderId: String, photoData: Data?, completionNotes: String?) async throws -> Order {
        let order = try await updateJobStatus(orderId: orderId, status: .delivered)
        
        // Save delivery completion data
        let completionData = DeliveryCompletionData(
            orderId: orderId,
            driverId: order.driverId ?? "",
            completedAt: Date(),
            photoData: photoData,
            notes: completionNotes,
            customerSignature: nil
        )
        try await cloudKitService.save(completionData)
        
        return order
    }
    
    // MARK: - Earnings Tracking
    
    func getDailyEarnings(for date: Date, driverId: String) async throws -> EarningsSummary {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await getEarningsForPeriod(
            driverId: driverId,
            startDate: startOfDay,
            endDate: endOfDay
        )
    }
    
    func getWeeklyEarnings(for weekStartDate: Date, driverId: String) async throws -> EarningsSummary {
        let calendar = Calendar.current
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStartDate)!
        
        return try await getEarningsForPeriod(
            driverId: driverId,
            startDate: weekStartDate,
            endDate: endOfWeek
        )
    }
    
    func getCompletedDeliveries(for driverId: String, from startDate: Date, to endDate: Date) async throws -> [Order] {
        let predicate = NSPredicate(format: "driverId == %@ AND status == %@ AND actualDeliveryTime >= %@ AND actualDeliveryTime < %@",
                                  driverId,
                                  OrderStatus.delivered.rawValue,
                                  startDate as NSDate,
                                  endDate as NSDate)
        return try await cloudKitService.fetch(Order.self, predicate: predicate)
    }
    
    // MARK: - Real-time Updates
    
    func startListeningForJobs(driverId: String) async throws -> AsyncStream<Order> {
        return AsyncStream { continuation in
            jobListener = Task {
                // Simulate real-time job updates
                while !Task.isCancelled {
                    do {
                        let availableJobs = try await fetchAvailableJobs()
                        for job in availableJobs {
                            continuation.yield(job)
                        }
                        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    } catch {
                        continuation.finish()
                        break
                    }
                }
            }
        }
    }
    
    func stopListeningForJobs() {
        jobListener?.cancel()
        jobListener = nil
    }
    
    // MARK: - Private Methods
    
    private func getDriverProfile(driverId: String) async throws -> Driver {
        guard let driver = try await cloudKitService.fetch(Driver.self, predicate: NSPredicate(format: "id == %@", driverId)).first else {
            throw AppError.dataNotFound("Driver not found")
        }
        return driver
    }
    
    private func getEarningsForPeriod(driverId: String, startDate: Date, endDate: Date) async throws -> EarningsSummary {
        let completedOrders = try await getCompletedDeliveries(for: driverId, from: startDate, to: endDate)
        
        let earnings = completedOrders.map { order in
            let basePayment = Double(order.deliveryFeeCents) / 100.0
            let tip = Double(order.tipCents) / 100.0
            
            return EarningsDetail(
                orderId: order.id,
                basePayment: basePayment,
                tip: tip,
                completedAt: order.actualDeliveryTime ?? Date()
            )
        }
        
        let totalEarnings = earnings.reduce(0) { $0 + $1.totalEarning }
        let workingHours = calculateWorkingHours(from: completedOrders)
        
        return EarningsSummary(
            totalEarnings: totalEarnings,
            totalDeliveries: completedOrders.count,
            workingHours: workingHours,
            earnings: earnings
        )
    }
    
    private func calculateWorkingHours(from orders: [Order]) -> Double {
        // Simplified calculation - in reality this would track actual working time
        return Double(orders.count) * 0.5 // Assume 30 minutes per delivery
    }
}
