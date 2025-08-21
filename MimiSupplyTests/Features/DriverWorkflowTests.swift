//
//  DriverWorkflowTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import CoreLocation
@testable import MimiSupply

/// Comprehensive tests for driver workflow including background location scenarios
@MainActor
final class DriverWorkflowTests: XCTestCase {
    
    var mockDriverService: MockDriverService!
    var mockLocationService: MockLocationService!
    var viewModel: DriverDashboardViewModel!
    
    override func setUp() {
        super.setUp()
        mockDriverService = MockDriverService()
        mockLocationService = MockLocationService()
        viewModel = DriverDashboardViewModel(
            driverService: mockDriverService,
            locationService: mockLocationService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockDriverService = nil
        mockLocationService = nil
        super.tearDown()
    }
    
    // MARK: - Driver Status Tests
    
    func testToggleOnlineStatus() async throws {
        // Given
        let mockDriver = Driver.mockDriver()
        mockDriverService.mockDriverProfile = mockDriver
        
        // When
        viewModel.toggleOnlineStatus()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(viewModel.isOnline)
        XCTAssertTrue(mockDriverService.updateOnlineStatusCalled)
        XCTAssertEqual(mockDriverService.lastOnlineStatus, true)
    }
    
    func testToggleOfflineStatus() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: true, isAvailable: true)
        mockDriverService.mockDriverProfile = mockDriver
        viewModel.isOnline = true
        viewModel.isAvailable = true
        
        // When
        viewModel.toggleOnlineStatus()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertFalse(viewModel.isOnline)
        XCTAssertFalse(viewModel.isAvailable)
        XCTAssertTrue(mockDriverService.updateOnlineStatusCalled)
        XCTAssertTrue(mockDriverService.updateAvailabilityStatusCalled)
        XCTAssertEqual(mockDriverService.lastOnlineStatus, false)
        XCTAssertEqual(mockDriverService.lastAvailabilityStatus, false)
    }
    
    func testToggleAvailabilityWhenOnline() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: true)
        mockDriverService.mockDriverProfile = mockDriver
        viewModel.isOnline = true
        
        // When
        viewModel.toggleAvailabilityStatus()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(viewModel.isAvailable)
        XCTAssertTrue(mockDriverService.updateAvailabilityStatusCalled)
        XCTAssertEqual(mockDriverService.lastAvailabilityStatus, true)
    }
    
    func testToggleAvailabilityWhenOffline() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: false)
        mockDriverService.mockDriverProfile = mockDriver
        viewModel.isOnline = false
        
        // When
        viewModel.toggleAvailabilityStatus()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertFalse(viewModel.isAvailable)
        XCTAssertFalse(mockDriverService.updateAvailabilityStatusCalled)
    }
    
    // MARK: - Job Management Tests
    
    func testAcceptJob() async throws {
        // Given
        let mockDriver = Driver.mockDriver()
        let mockJob = Order.mockOrder()
        mockDriverService.mockDriverProfile = mockDriver
        mockDriverService.mockAcceptedJob = mockJob
        
        // When
        viewModel.acceptJob(mockJob)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.currentJob?.id, mockJob.id)
        XCTAssertFalse(viewModel.isAvailable)
        XCTAssertTrue(mockDriverService.acceptJobCalled)
        XCTAssertTrue(mockDriverService.updateAvailabilityStatusCalled)
        XCTAssertEqual(mockDriverService.lastAcceptedOrderId, mockJob.id)
    }
    
    func testDeclineJob() async throws {
        // Given
        let mockDriver = Driver.mockDriver()
        let mockJob = Order.mockOrder()
        mockDriverService.mockDriverProfile = mockDriver
        viewModel.availableJobs = [mockJob]
        
        // When
        viewModel.declineJob(mockJob)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(viewModel.availableJobs.isEmpty)
        XCTAssertTrue(mockDriverService.declineJobCalled)
        XCTAssertEqual(mockDriverService.lastDeclinedOrderId, mockJob.id)
    }
    
    func testUpdateJobStatusToPickedUp() async throws {
        // Given
        let mockJob = Order.mockOrder(status: .driverAssigned)
        let updatedJob = Order.mockOrder(status: .pickedUp)
        mockDriverService.mockUpdatedJob = updatedJob
        viewModel.currentJob = mockJob
        
        // When
        viewModel.updateJobStatus(.pickedUp)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertEqual(viewModel.currentJob?.status, .pickedUp)
        XCTAssertTrue(mockDriverService.updateJobStatusCalled)
        XCTAssertEqual(mockDriverService.lastUpdatedStatus, .pickedUp)
    }
    
    func testCompleteDelivery() async throws {
        // Given
        let mockJob = Order.mockOrder(status: .delivering)
        let completedJob = Order.mockOrder(status: .delivered)
        let mockDriver = Driver.mockDriver()
        mockDriverService.mockDriverProfile = mockDriver
        mockDriverService.mockCompletedJob = completedJob
        viewModel.currentJob = mockJob
        
        let photoData = "mock photo data".data(using: .utf8)
        let notes = "Delivery completed successfully"
        
        // When
        viewModel.completeDelivery(photoData: photoData, notes: notes)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNil(viewModel.currentJob)
        XCTAssertTrue(viewModel.isAvailable)
        XCTAssertTrue(mockDriverService.completeDeliveryCalled)
        XCTAssertEqual(mockDriverService.lastCompletionPhotoData, photoData)
        XCTAssertEqual(mockDriverService.lastCompletionNotes, notes)
    }
    
    // MARK: - Earnings Tests
    
    func testLoadDailyEarnings() async throws {
        // Given
        let mockDriver = Driver.mockDriver()
        let mockEarnings = EarningsSummary.mockDailyEarnings()
        mockDriverService.mockDriverProfile = mockDriver
        mockDriverService.mockDailyEarnings = mockEarnings
        
        // When
        await viewModel.loadDriverProfile()
        await viewModel.loadEarnings()
        
        // Then
        XCTAssertEqual(viewModel.dailyEarnings?.totalEarnings, mockEarnings.totalEarnings)
        XCTAssertEqual(viewModel.dailyEarnings?.totalDeliveries, mockEarnings.totalDeliveries)
        XCTAssertTrue(mockDriverService.getDailyEarningsCalled)
    }
    
    func testLoadWeeklyEarnings() async throws {
        // Given
        let mockDriver = Driver.mockDriver()
        let mockEarnings = EarningsSummary.mockWeeklyEarnings()
        mockDriverService.mockDriverProfile = mockDriver
        mockDriverService.mockWeeklyEarnings = mockEarnings
        
        // When
        await viewModel.loadDriverProfile()
        await viewModel.loadEarnings()
        
        // Then
        XCTAssertEqual(viewModel.weeklyEarnings?.totalEarnings, mockEarnings.totalEarnings)
        XCTAssertEqual(viewModel.weeklyEarnings?.totalDeliveries, mockEarnings.totalDeliveries)
        XCTAssertTrue(mockDriverService.getWeeklyEarningsCalled)
    }
    
    // MARK: - Background Location Tests
    
    func testLocationUpdatesWhenOnline() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: true)
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        mockDriverService.mockDriverProfile = mockDriver
        mockLocationService.mockCurrentLocation = mockLocation
        
        // When
        viewModel.isOnline = true
        await viewModel.startLocationUpdates()
        
        // Wait for location update cycle
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        XCTAssertTrue(mockLocationService.getCurrentLocationCalled)
        XCTAssertTrue(mockDriverService.updateDriverLocationCalled)
        XCTAssertEqual(mockDriverService.lastLocationUpdate?.latitude, mockLocation.coordinate.latitude)
        XCTAssertEqual(mockDriverService.lastLocationUpdate?.longitude, mockLocation.coordinate.longitude)
    }
    
    func testLocationUpdatesStopWhenOffline() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: false)
        mockDriverService.mockDriverProfile = mockDriver
        
        // When
        viewModel.isOnline = false
        await viewModel.startLocationUpdates()
        
        // Wait briefly
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertFalse(mockDriverService.updateDriverLocationCalled)
    }
    
    func testLocationUpdateErrorHandling() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: true)
        mockDriverService.mockDriverProfile = mockDriver
        mockLocationService.shouldThrowError = true
        
        // When
        viewModel.isOnline = true
        await viewModel.startLocationUpdates()
        
        // Wait for error handling
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(mockLocationService.getCurrentLocationCalled)
        // Should continue trying despite errors
        XCTAssertFalse(mockDriverService.updateDriverLocationCalled)
    }
    
    // MARK: - Real-time Job Updates Tests
    
    func testJobStreamUpdates() async throws {
        // Given
        let mockDriver = Driver.mockDriver(isOnline: true, isAvailable: true)
        let mockJobs = [Order.mockOrder(), Order.mockOrder()]
        mockDriverService.mockDriverProfile = mockDriver
        mockDriverService.mockAvailableJobs = mockJobs
        
        // When
        await viewModel.startListeningForJobs()
        
        // Wait for job stream updates
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertTrue(mockDriverService.startListeningForJobsCalled)
        XCTAssertEqual(viewModel.availableJobs.count, mockJobs.count)
    }
    
    func testStopListeningForJobs() async throws {
        // Given
        await viewModel.startListeningForJobs()
        
        // When
        viewModel.onDisappear()
        
        // Then
        XCTAssertTrue(mockDriverService.stopListeningForJobsCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testDriverServiceError() async throws {
        // Given
        mockDriverService.shouldThrowError = true
        
        // When
        viewModel.toggleOnlineStatus()
        
        // Wait for error handling
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("Mock error") == true)
    }
    
    func testLoadingStates() async throws {
        // Given
        let mockJob = Order.mockOrder()
        mockDriverService.mockAcceptedJob = mockJob
        mockDriverService.shouldDelay = true
        
        // When
        viewModel.acceptJob(mockJob)
        
        // Check loading state immediately
        XCTAssertTrue(viewModel.isLoading)
        
        // Wait for completion
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
}

// MARK: - Mock Services

class MockDriverService: DriverService {
    var mockDriverProfile: Driver?
    var mockCurrentJob: Order?
    var mockAvailableJobs: [Order] = []
    var mockAcceptedJob: Order?
    var mockUpdatedJob: Order?
    var mockCompletedJob: Order?
    var mockDailyEarnings: EarningsSummary?
    var mockWeeklyEarnings: EarningsSummary?
    
    var shouldThrowError = false
    var shouldDelay = false
    
    // Tracking method calls
    var updateOnlineStatusCalled = false
    var updateAvailabilityStatusCalled = false
    var acceptJobCalled = false
    var declineJobCalled = false
    var updateJobStatusCalled = false
    var completeDeliveryCalled = false
    var getDailyEarningsCalled = false
    var getWeeklyEarningsCalled = false
    var updateDriverLocationCalled = false
    var startListeningForJobsCalled = false
    var stopListeningForJobsCalled = false
    
    // Tracking method parameters
    var lastOnlineStatus: Bool?
    var lastAvailabilityStatus: Bool?
    var lastAcceptedOrderId: String?
    var lastDeclinedOrderId: String?
    var lastUpdatedStatus: OrderStatus?
    var lastCompletionPhotoData: Data?
    var lastCompletionNotes: String?
    var lastLocationUpdate: CLLocationCoordinate2D?
    
    func updateOnlineStatus(_ isOnline: Bool, for driverId: String) async throws {
        updateOnlineStatusCalled = true
        lastOnlineStatus = isOnline
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    func updateAvailabilityStatus(_ isAvailable: Bool, for driverId: String) async throws {
        updateAvailabilityStatusCalled = true
        lastAvailabilityStatus = isAvailable
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
    }
    
    func getCurrentDriverProfile() async throws -> Driver? {
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        return mockDriverProfile
    }
    
    func updateDriverLocation(_ location: CLLocationCoordinate2D, for driverId: String) async throws {
        updateDriverLocationCalled = true
        lastLocationUpdate = location
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
    }
    
    func fetchAvailableJobs() async throws -> [Order] {
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        return mockAvailableJobs
    }
    
    func acceptJob(orderId: String, driverId: String) async throws -> Order {
        acceptJobCalled = true
        lastAcceptedOrderId = orderId
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        if shouldDelay {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        return mockAcceptedJob ?? Order.mockOrder()
    }
    
    func declineJob(orderId: String, driverId: String) async throws {
        declineJobCalled = true
        lastDeclinedOrderId = orderId
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
    }
    
    func getCurrentJob(for driverId: String) async throws -> Order? {
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        return mockCurrentJob
    }
    
    func updateJobStatus(orderId: String, status: OrderStatus) async throws -> Order {
        updateJobStatusCalled = true
        lastUpdatedStatus = status
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        return mockUpdatedJob ?? Order.mockOrder(status: status)
    }
    
    func completeDelivery(orderId: String, photoData: Data?, completionNotes: String?) async throws -> Order {
        completeDeliveryCalled = true
        lastCompletionPhotoData = photoData
        lastCompletionNotes = completionNotes
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        return mockCompletedJob ?? Order.mockOrder(status: .delivered)
    }
    
    func getDailyEarnings(for date: Date, driverId: String) async throws -> EarningsSummary {
        getDailyEarningsCalled = true
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        return mockDailyEarnings ?? EarningsSummary.mockDailyEarnings()
    }
    
    func getWeeklyEarnings(for weekStartDate: Date, driverId: String) async throws -> EarningsSummary {
        getWeeklyEarningsCalled = true
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        return mockWeeklyEarnings ?? EarningsSummary.mockWeeklyEarnings()
    }
    
    func getCompletedDeliveries(for driverId: String, from startDate: Date, to endDate: Date) async throws -> [Order] {
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        return []
    }
    
    func startListeningForJobs(driverId: String) async throws -> AsyncStream<Order> {
        startListeningForJobsCalled = true
        
        if shouldThrowError {
            throw AppError.unknown(NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"]))
        }
        
        return AsyncStream { continuation in
            Task {
                for job in mockAvailableJobs {
                    continuation.yield(job)
                }
                continuation.finish()
            }
        }
    }
    
    func stopListeningForJobs() {
        stopListeningForJobsCalled = true
    }
}

class MockLocationService: LocationService {
    var mockCurrentLocation: CLLocation?
    var shouldThrowError = false
    var getCurrentLocationCalled = false
    
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    
    func getCurrentLocation() async throws -> CLLocation {
        getCurrentLocationCalled = true
        
        if shouldThrowError {
            throw AppError.location(.locationUnavailable)
        }
        
        return mockCurrentLocation ?? CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
    
    func requestLocationPermission() async throws {
        if shouldThrowError {
            throw AppError.location(.permissionDenied)
        }
    }
    
    func startLocationUpdates() async throws {
        if shouldThrowError {
            throw AppError.location(.locationUnavailable)
        }
    }
    
    func stopLocationUpdates() {
        // No-op for mock
    }
    
    func startBackgroundLocationUpdates() async throws {
        if shouldThrowError {
            throw AppError.location(.locationUnavailable)
        }
    }
}

// MARK: - Mock Data Extensions

extension Driver {
    static func mockDriver(
        id: String = UUID().uuidString,
        isOnline: Bool = false,
        isAvailable: Bool = false
    ) -> Driver {
        Driver(
            id: id,
            userId: "user123",
            name: "John Driver",
            phoneNumber: "+1234567890",
            vehicleType: .car,
            licensePlate: "ABC123",
            isOnline: isOnline,
            isAvailable: isAvailable,
            rating: 4.8,
            completedDeliveries: 150
        )
    }
}

extension Order {
    static func mockOrder(
        id: String = UUID().uuidString,
        status: OrderStatus = .accepted
    ) -> Order {
        Order(
            id: id,
            customerId: "customer123",
            partnerId: "partner123",
            items: [
                OrderItem(
                    productId: "product123",
                    productName: "Test Product",
                    quantity: 1,
                    unitPriceCents: 1299
                )
            ],
            status: status,
            subtotalCents: 1299,
            deliveryFeeCents: 299,
            platformFeeCents: 150,
            taxCents: 130,
            deliveryAddress: Address(
                street: "123 Test St",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "USA"
            ),
            paymentMethod: .applePay
        )
    }
}

extension EarningsSummary {
    static func mockDailyEarnings() -> EarningsSummary {
        EarningsSummary(
            totalEarnings: 125.50,
            totalDeliveries: 8,
            workingHours: 4.0,
            earnings: [
                EarningsDetail(
                    orderId: "order1",
                    basePayment: 12.50,
                    tip: 3.00
                )
            ]
        )
    }
    
    static func mockWeeklyEarnings() -> EarningsSummary {
        EarningsSummary(
            totalEarnings: 850.75,
            totalDeliveries: 45,
            workingHours: 25.0,
            earnings: []
        )
    }
}