//
//  DriverDashboardViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import CoreLocation
import Combine
import MapKit
import SwiftUI

/// Enhanced driver dashboard view model with comprehensive job management and performance tracking
@MainActor
final class DriverDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Basic Status
    @Published var driverProfile: Driver?
    @Published var isOnline = false
    @Published var isAvailable = false
    @Published var isOnBreak = false
    @Published var workingHours: Int = 0
    @Published var todayDeliveries: Int = 0
    
    // Job Management
    @Published var currentJob: Order?
    @Published var jobQueue: [Order] = []
    @Published var availableJobs: [Order] = []
    @Published var jobHistory: [Order] = []
    
    // Enhanced Features
    @Published var smartFilterEnabled = true
    @Published var estimatedTimeOfArrival: Date?
    @Published var pickupAddress: Address?
    @Published var vehicleInfo: VehicleInfo?
    @Published var vehicleAlerts: Int = 0
    
    // Earnings & Performance
    @Published var dailyEarnings: DriverEarnings?
    @Published var weeklyEarnings: DriverEarnings?
    @Published var monthlyEarnings: DriverEarnings?
    @Published var onTimeDeliveryRate: Double = 0.95
    @Published var averageCustomerRating: Double = 4.8
    @Published var deliveriesPerHour: Double = 2.1
    
    // Performance Trends
    @Published var onTimeDeliveryTrend: Double = 0.02
    @Published var ratingTrend: Double = 0.1
    @Published var efficiencyTrend: Double = -0.1
    
    // UI State
    @Published var showingJobCompletion = false
    @Published var showingBreakReminder = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let driverService: DriverService
    private let cloudKitService: CloudKitService
    private let notificationService: PushNotificationService
    private var cancellables = Set<AnyCancellable>()
    private var workStartTime: Date?
    private var breakStartTime: Date?
    private var locationUpdateTimer: Timer?
    private var performanceUpdateTimer: Timer?
    private var currentLocation: CLLocationCoordinate2D?
    
    // MARK: - Computed Properties
    
    var statusText: String {
        if isOnBreak {
            return "Pause"
        } else if isOnline && isAvailable {
            return "Verfügbar"
        } else if isOnline {
            return "Beschäftigt"
        } else {
            return "Offline"
        }
    }
    
    var statusColor: Color {
        if isOnBreak {
            return .orange
        } else if isOnline && isAvailable {
            return .green
        } else if isOnline {
            return .blue
        } else {
            return .gray
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Use AppContainer services
        self.driverService = AppContainer.shared.driverService
        self.cloudKitService = AppContainer.shared.cloudKitService
        self.notificationService = AppContainer.shared.pushNotificationService
        
        setupBindings()
        setupPerformanceTracking()
    }
    
    // MARK: - Lifecycle Methods
    
    func onAppear() {
        Task {
            await loadInitialData()
            startLocationTracking()
            startWorkTimeTracking()
            scheduleBreakReminders()
        }
    }
    
    func onDisappear() {
        stopLocationTracking()
        stopWorkTimeTracking()
        cancelScheduledReminders()
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadDriverProfile() }
            group.addTask { await self.loadCurrentJob() }
            group.addTask { await self.loadJobQueue() }
            group.addTask { await self.loadAvailableJobs() }
            group.addTask { await self.loadEarnings() }
            group.addTask { await self.loadPerformanceMetrics() }
            group.addTask { await self.loadVehicleInfo() }
        }
    }
    
    func refreshAllData() async {
        await loadInitialData()
    }
    
    func loadDriverProfile() async {
        do {
            // Mock driver profile - in real app would fetch from service
            driverProfile = Driver(
                id: "driver_1",
                userId: "user_1",
                name: "Thomas Weber",
                phoneNumber: "+49 30 55555555",
                vehicleType: .bicycle,
                licensePlate: "B-MW-1234",
                isOnline: isOnline,
                isAvailable: isAvailable,
                currentLocation: Coordinate(latitude: 52.5200, longitude: 13.4050),
                rating: 4.8,
                completedDeliveries: 247,
                verificationStatus: .verified
            )
        } catch {
            errorMessage = "Fehler beim Laden des Fahrerprofils: \(error.localizedDescription)"
        }
    }
    
    func loadCurrentJob() async {
        do {
            // Mock current job - in real app would fetch from service
            if isOnline && !isAvailable {
                currentJob = Order(
                    id: "current_job_1",
                    customerId: "customer_1",
                    partnerId: "mcdonalds_berlin_mitte",
                    items: [
                        OrderItem(
                            productId: "bigmac_1",
                            productName: "Big Mac Menü",
                            quantity: 1,
                            unitPriceCents: 899
                        )
                    ],
                    status: .delivering,
                    subtotalCents: 899,
                    deliveryFeeCents: 199,
                    platformFeeCents: 50,
                    taxCents: 115,
                    deliveryAddress: Address(
                        street: "Friedrichstraße 123",
                        city: "Berlin",
                        state: "Berlin",
                        postalCode: "10117",
                        country: "Deutschland"
                    ),
                    estimatedDeliveryTime: Date().addingTimeInterval(900), // 15 minutes
                    paymentMethod: .applePay
                )
                
                // Load pickup address for current job
                pickupAddress = Address(
                    street: "Unter den Linden 1",
                    city: "Berlin",
                    state: "Berlin",
                    postalCode: "10117",
                    country: "Deutschland"
                )
                
                // Calculate ETA
                calculateETA()
            }
        } catch {
            errorMessage = "Fehler beim Laden des aktuellen Auftrags: \(error.localizedDescription)"
        }
    }
    
    func loadJobQueue() async {
        // Mock job queue - in real app would fetch accepted but not started jobs
        if !jobQueue.isEmpty {
            return
        }
        
        jobQueue = [
            Order(
                id: "queue_job_1",
                customerId: "customer_2",
                partnerId: "rewe_alexanderplatz",
                items: [
                    OrderItem(
                        productId: "groceries_1",
                        productName: "Lebensmittel",
                        quantity: 1,
                        unitPriceCents: 2450
                    )
                ],
                status: .driverAssigned,
                subtotalCents: 2450,
                deliveryFeeCents: 299,
                platformFeeCents: 75,
                taxCents: 284,
                deliveryAddress: Address(
                    street: "Alexanderplatz 5",
                    city: "Berlin",
                    state: "Berlin",
                    postalCode: "10178",
                    country: "Deutschland"
                ),
                estimatedDeliveryTime: Date().addingTimeInterval(3600), // 1 hour
                paymentMethod: .creditCard
            )
        ]
    }
    
    func loadAvailableJobs() async {
        guard isOnline && isAvailable else {
            availableJobs = []
            return
        }
        
        do {
            // Mock available jobs - in real app would fetch from service
            let mockJobs = [
                Order(
                    id: "available_1",
                    customerId: "customer_3",
                    partnerId: "docmorris_berlin",
                    items: [
                        OrderItem(
                            productId: "medicine_1",
                            productName: "Medikamente",
                            quantity: 1,
                            unitPriceCents: 1299
                        )
                    ],
                    status: .paymentConfirmed,
                    subtotalCents: 1299,
                    deliveryFeeCents: 399,
                    platformFeeCents: 65,
                    taxCents: 212,
                    deliveryAddress: Address(
                        street: "Potsdamer Platz 1",
                        city: "Berlin",
                        state: "Berlin",
                        postalCode: "10785",
                        country: "Deutschland"
                    ),
                    estimatedDeliveryTime: Date().addingTimeInterval(1800),
                    paymentMethod: .applePay
                ),
                Order(
                    id: "available_2",
                    customerId: "customer_4",
                    partnerId: "mediamarkt_alexanderplatz",
                    items: [
                        OrderItem(
                            productId: "electronics_1",
                            productName: "Kopfhörer",
                            quantity: 1,
                            unitPriceCents: 9999
                        )
                    ],
                    status: .paymentConfirmed,
                    subtotalCents: 9999,
                    deliveryFeeCents: 499,
                    platformFeeCents: 125,
                    taxCents: 1312,
                    deliveryAddress: Address(
                        street: "Kurfürstendamm 200",
                        city: "Berlin",
                        state: "Berlin",
                        postalCode: "10719",
                        country: "Deutschland"
                    ),
                    estimatedDeliveryTime: Date().addingTimeInterval(2700),
                    paymentMethod: .creditCard
                )
            ]
            
            // Apply smart filtering if enabled
            if smartFilterEnabled {
                availableJobs = applySmartFilter(to: mockJobs)
            } else {
                availableJobs = mockJobs
            }
            
        } catch {
            errorMessage = "Fehler beim Laden verfügbarer Aufträge: \(error.localizedDescription)"
        }
    }
    
    func loadEarnings() async {
        // Mock earnings data - in real app would fetch from service
        dailyEarnings = DriverEarnings(
            date: Date(),
            basePay: 4250, // €42.50
            tips: 850, // €8.50
            bonuses: 500, // €5.00
            totalDeliveries: 8,
            workingHours: workingHours
        )
        
        weeklyEarnings = DriverEarnings(
            date: Calendar.current.startOfWeek(for: Date()) ?? Date(),
            basePay: 28750, // €287.50
            tips: 5420, // €54.20
            bonuses: 2500, // €25.00
            totalDeliveries: 52,
            workingHours: 35
        )
        
        monthlyEarnings = DriverEarnings(
            date: Calendar.current.startOfMonth(for: Date()) ?? Date(),
            basePay: 125000, // €1250.00
            tips: 23500, // €235.00
            bonuses: 12000, // €120.00
            totalDeliveries: 234,
            workingHours: 156
        )
    }
    
    func loadPerformanceMetrics() async {
        // Mock performance data - in real app would calculate from historical data
        onTimeDeliveryRate = 0.94
        averageCustomerRating = 4.7
        deliveriesPerHour = 2.3
        
        // Mock trends (positive = improvement)
        onTimeDeliveryTrend = 0.02
        ratingTrend = 0.1
        efficiencyTrend = -0.1
        
        todayDeliveries = dailyEarnings?.totalDeliveries ?? 0
    }
    
    func loadVehicleInfo() async {
        // Mock vehicle info - in real app would fetch from driver profile
        vehicleInfo = VehicleInfo(
            type: .bicycle,
            licensePlate: "B-MW-1234",
            batteryLevel: 85, // for e-bikes
            fuelLevel: nil,
            lastServiceDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date(),
            nextServiceDue: Calendar.current.date(byAdding: .month, value: 4, to: Date()) ?? Date(),
            insuranceValid: true,
            registrationValid: true
        )
        
        // Check for vehicle alerts
        checkVehicleAlerts()
    }
    
    // MARK: - Status Management
    
    func toggleOnlineStatus() {
        isOnline.toggle()
        
        if isOnline {
            startLocationTracking()
            Task {
                await loadAvailableJobs()
            }
        } else {
            isAvailable = false
            stopLocationTracking()
            availableJobs = []
        }
        
        // Update status on server
        Task {
            await updateDriverStatus()
        }
    }
    
    func toggleAvailabilityStatus() {
        guard isOnline else { return }
        
        isAvailable.toggle()
        
        Task {
            if isAvailable {
                await loadAvailableJobs()
            } else {
                availableJobs = []
            }
            await updateDriverStatus()
        }
    }
    
    func startBreak() {
        isOnBreak = true
        isAvailable = false
        breakStartTime = Date()
        
        Task {
            await updateDriverStatus()
        }
    }
    
    func endBreak() {
        isOnBreak = false
        breakStartTime = nil
        
        if isOnline {
            isAvailable = true
            Task {
                await loadAvailableJobs()
                await updateDriverStatus()
            }
        }
    }
    
    // MARK: - Job Management
    
    func acceptJob(_ job: Order) {
        // Add to job queue or set as current job
        if currentJob == nil {
            currentJob = job
            isAvailable = false
        } else {
            jobQueue.append(job)
        }
        
        // Remove from available jobs
        availableJobs.removeAll { $0.id == job.id }
        
        Task {
            await updateJobStatus(.driverAssigned, for: job.id)
            await updateDriverStatus()
        }
    }
    
    func declineJob(_ job: Order) {
        availableJobs.removeAll { $0.id == job.id }
        
        Task {
            // Inform service that job was declined
            // await driverService.declineJob(job.id)
        }
    }
    
    func updateJobStatus(_ status: OrderStatus, for jobId: String? = nil) {
        let targetJobId = jobId ?? currentJob?.id
        guard let targetJobId = targetJobId else { return }
        
        // Update current job status
        if let currentJob = currentJob, currentJob.id == targetJobId {
            self.currentJob = Order(
                id: currentJob.id,
                customerId: currentJob.customerId,
                partnerId: currentJob.partnerId,
                items: currentJob.items,
                status: status,
                subtotalCents: currentJob.subtotalCents,
                deliveryFeeCents: currentJob.deliveryFeeCents,
                platformFeeCents: currentJob.platformFeeCents,
                taxCents: currentJob.taxCents,
                deliveryAddress: currentJob.deliveryAddress,
                estimatedDeliveryTime: currentJob.estimatedDeliveryTime,
                paymentMethod: currentJob.paymentMethod
            )
            
            // Handle job completion
            if status == .delivered {
                completeCurrentJob()
            }
        }
        
        Task {
            await updateJobStatusOnServer(targetJobId, status: status)
        }
    }
    
    func completeDelivery(photoData: Data?, notes: String?, customerRating: Int?) {
        guard let currentJob = currentJob else { return }
        
        // Update job status
        updateJobStatus(.delivered, for: currentJob.id)
        
        // Move to history
        jobHistory.insert(currentJob, at: 0)
        
        // Clear current job
        self.currentJob = nil
        
        // Start next job from queue if available
        if let nextJob = jobQueue.first {
            jobQueue.removeFirst()
            self.currentJob = nextJob
        } else {
            // Make available again if no jobs in queue
            isAvailable = true
        }
        
        // Update earnings
        updateEarningsAfterDelivery(currentJob)
        
        Task {
            await updateDriverStatus()
            await loadAvailableJobs()
        }
    }
    
    // MARK: - Smart Features
    
    func toggleSmartFilter() {
        smartFilterEnabled.toggle()
        
        Task {
            await loadAvailableJobs()
        }
    }
    
    func getDistance(to job: Order) -> String? {
        // Mock distance calculation - in real app would use MapKit
        let distances = ["0.8 km", "1.2 km", "2.1 km", "3.5 km"]
        return distances.randomElement()
    }
    
    func getEstimatedEarnings(for job: Order) -> String? {
        // Calculate estimated earnings based on distance, job value, tips, etc.
        let baseEarning = Double(job.deliveryFeeCents) / 100.0
        let estimatedTip = Double(job.subtotalCents) * 0.15 / 100.0 // 15% tip estimate
        let totalEstimated = baseEarning + estimatedTip
        
        return String(format: "~€%.2f", totalEstimated)
    }
    
    // MARK: - Navigation & Location
    
    private func startLocationTracking() {
        // Mock location - in real app would use CLLocationManager
        currentLocation = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        
        // Update location every 30 seconds
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.updateLocationOnServer()
            }
        }
    }
    
    private func stopLocationTracking() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    private func calculateETA() {
        guard let currentJob = currentJob,
              let driverLocation = currentLocation else {
            return
        }
        
        // Mock ETA calculation - in real app would use MapKit directions
        let estimatedTravelTime: TimeInterval = 900 // 15 minutes
        estimatedTimeOfArrival = Date().addingTimeInterval(estimatedTravelTime)
    }
    
    // MARK: - Vehicle Management
    
    func updateVehicleInfo(_ info: VehicleInfo) {
        vehicleInfo = info
        checkVehicleAlerts()
        
        Task {
            // Save to server
            // await driverService.updateVehicleInfo(info)
        }
    }
    
    private func checkVehicleAlerts() {
        guard let vehicle = vehicleInfo else {
            vehicleAlerts = 0
            return
        }
        
        var alerts = 0
        
        // Battery/fuel alerts
        if let batteryLevel = vehicle.batteryLevel, batteryLevel < 20 {
            alerts += 1
        }
        if let fuelLevel = vehicle.fuelLevel, fuelLevel < 20 {
            alerts += 1
        }
        
        // Service alerts
        if vehicle.nextServiceDue < Date() {
            alerts += 1
        }
        
        // Insurance/registration alerts
        if !vehicle.insuranceValid || !vehicle.registrationValid {
            alerts += 1
        }
        
        vehicleAlerts = alerts
    }
    
    // MARK: - Work Time & Break Management
    
    private func startWorkTimeTracking() {
        if isOnline && workStartTime == nil {
            workStartTime = Date()
        }
        
        // Update working hours every minute
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            self.updateWorkingHours()
        }
    }
    
    private func stopWorkTimeTracking() {
        // Keep work start time for session persistence
    }
    
    private func updateWorkingHours() {
        guard let startTime = workStartTime else { return }
        
        let totalSeconds = Date().timeIntervalSince(startTime)
        workingHours = Int(totalSeconds / 3600) // Convert to hours
        
        // Check for break reminder
        if workingHours > 0 && workingHours % 4 == 0 && !isOnBreak {
            showingBreakReminder = true
        }
    }
    
    private func scheduleBreakReminders() {
        // Schedule break reminders every 4 hours
        // Implementation would use local notifications
    }
    
    private func cancelScheduledReminders() {
        // Cancel scheduled notifications
    }
    
    // MARK: - Communication & Support
    
    func contactSupport() {
        // Open support chat or call
        // Implementation would integrate with support system
    }
    
    func triggerEmergency() {
        // Trigger emergency protocol
        // Implementation would contact emergency services and notify MimiSupply
    }
    
    // MARK: - Helper Methods
    
    private func applySmartFilter(to jobs: [Order]) -> [Order] {
        // Mock smart filtering logic
        // In real app would consider:
        // - Distance from current location
        // - Traffic conditions
        // - Driver preferences
        // - Historical performance
        // - Peak hours bonuses
        
        return jobs.sorted { job1, job2 in
            // Prioritize higher value orders
            let value1 = job1.subtotalCents + job1.deliveryFeeCents
            let value2 = job2.subtotalCents + job2.deliveryFeeCents
            return value1 > value2
        }
    }
    
    private func completeCurrentJob() {
        guard let job = currentJob else { return }
        
        // Update daily stats
        todayDeliveries += 1
        
        // Update performance metrics
        // In real app would calculate based on actual delivery time vs estimated
        
        showingJobCompletion = false
    }
    
    private func updateEarningsAfterDelivery(_ job: Order) {
        guard let earnings = dailyEarnings else { return }
        
        // Mock earnings update - in real app would be calculated server-side
        let deliveryFee = Double(job.deliveryFeeCents) / 100.0
        let estimatedTip = Double(job.subtotalCents) * 0.15 / 100.0
        
        dailyEarnings = DriverEarnings(
            date: earnings.date,
            basePay: earnings.basePay + Int(deliveryFee * 100),
            tips: earnings.tips + Int(estimatedTip * 100),
            bonuses: earnings.bonuses,
            totalDeliveries: earnings.totalDeliveries + 1,
            workingHours: earnings.workingHours
        )
    }
    
    private func setupBindings() {
        // Setup reactive bindings for real-time updates
        // Implementation would bind to CloudKit subscriptions
    }
    
    private func setupPerformanceTracking() {
        // Setup performance tracking timers
        performanceUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { _ in
            Task {
                await self.loadPerformanceMetrics()
            }
        }
    }
    
    // MARK: - Server Communication
    
    private func updateDriverStatus() async {
        do {
            // Update driver status on server
            // await driverService.updateStatus(isOnline: isOnline, isAvailable: isAvailable, isOnBreak: isOnBreak)
        } catch {
            errorMessage = "Fehler beim Aktualisieren des Status: \(error.localizedDescription)"
        }
    }
    
    private func updateJobStatusOnServer(_ jobId: String, status: OrderStatus) async {
        do {
            // Update job status on server
            // await cloudKitService.updateOrderStatus(jobId, status: status)
        } catch {
            errorMessage = "Fehler beim Aktualisieren des Auftragsstatus: \(error.localizedDescription)"
        }
    }
    
    private func updateLocationOnServer() async {
        guard let location = currentLocation else { return }
        
        do {
            // Update driver location on server
            // await driverService.updateLocation(location)
        } catch {
            errorMessage = "Fehler beim Aktualisieren der Position: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Models

struct DriverEarnings {
    let date: Date
    let basePay: Int // in cents
    let tips: Int // in cents
    let bonuses: Int // in cents
    let totalDeliveries: Int
    let workingHours: Int
    
    var totalEarnings: Int {
        return basePay + tips + bonuses
    }
    
    var formattedTotalEarnings: String {
        let amount = Double(totalEarnings) / 100.0
        return String(format: "€%.2f", amount)
    }
    
    var breakdown: String {
        let baseAmount = Double(basePay) / 100.0
        let tipAmount = Double(tips) / 100.0
        let bonusAmount = Double(bonuses) / 100.0
        
        return String(format: "€%.0f + €%.0f Trinkgeld + €%.0f Bonus", baseAmount, tipAmount, bonusAmount)
    }
    
    var hourlyRate: Double {
        guard workingHours > 0 else { return 0 }
        return Double(totalEarnings) / 100.0 / Double(workingHours)
    }
}

struct VehicleInfo {
    let type: VehicleType
    let licensePlate: String?
    let batteryLevel: Int? // for e-bikes/e-scooters
    let fuelLevel: Int? // for cars/motorcycles
    let lastServiceDate: Date
    let nextServiceDue: Date
    let insuranceValid: Bool
    let registrationValid: Bool
    
    enum VehicleType {
        case bicycle
        case eBike
        case scooter
        case eScooter
        case motorcycle
        case car
        
        var displayName: String {
            switch self {
            case .bicycle: return "Fahrrad"
            case .eBike: return "E-Bike"
            case .scooter: return "Roller"
            case .eScooter: return "N-Roller"
            case .motorcycle: return "Motorrad"
            case .car: return "Auto"
            }
        }
        
        var icon: String {
            switch self {
            case .bicycle, .eBike: return "bicycle"
            case .scooter, .eScooter: return "scooter"
            case .motorcycle: return "car.rear"
            case .car: return "car"
            }
        }
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func startOfWeek(for date: Date) -> Date? {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components)
    }
    
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components)
    }
}