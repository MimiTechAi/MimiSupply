//
//  DriverAssignmentTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import MapKit
@testable import MimiSupply

/// Unit tests for driver assignment logic
final class DriverAssignmentTests: XCTestCase {
    
    var driverAssignmentService: DriverAssignmentService!
    var mockDriverService: MockDriverService!
    var mockLocationService: MockLocationService!
    
    override func setUp() {
        super.setUp()
        mockDriverService = MockDriverService()
        mockLocationService = MockLocationService()
        
        driverAssignmentService = MockDriverAssignmentService(
            driverService: mockDriverService,
            locationService: mockLocationService
        )
    }
    
    override func tearDown() {
        driverAssignmentService = nil
        mockLocationService = nil
        mockDriverService = nil
        super.tearDown()
    }
    
    // MARK: - Driver Assignment Algorithm Tests
    
    func testAssignNearestAvailableDriver() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let nearDriver = createTestDriver(
            id: "near-driver",
            location: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            rating: 4.5
        )
        let farDriver = createTestDriver(
            id: "far-driver",
            location: CLLocationCoordinate2D(latitude: 37.8000, longitude: -122.4500),
            rating: 4.8
        )
        
        mockDriverService.mockAvailableDrivers = [farDriver, nearDriver]
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        )
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "near-driver")
    }
    
    func testAssignDriverWithBestRatingWhenDistanceSimilar() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let driver1 = createTestDriver(
            id: "driver-1",
            location: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            rating: 4.5
        )
        let driver2 = createTestDriver(
            id: "driver-2", 
            location: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196),
            rating: 4.9
        )
        
        mockDriverService.mockAvailableDrivers = [driver1, driver2]
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        )
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "driver-2")
    }    
 
   func testNoAvailableDrivers() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        mockDriverService.mockAvailableDrivers = []
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        )
        
        // Then
        XCTAssertNil(assignedDriver)
    }
    
    func testDriverTooFarAway() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let farDriver = createTestDriver(
            id: "far-driver",
            location: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060) // NYC
        )
        
        mockDriverService.mockAvailableDrivers = [farDriver]
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            maxDistance: 10.0 // 10km max
        )
        
        // Then
        XCTAssertNil(assignedDriver)
    }
    
    // MARK: - Driver Availability Tests
    
    func testFilterOnlineDriversOnly() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let onlineDriver = createTestDriver(id: "online", isOnline: true, isAvailable: true)
        let offlineDriver = createTestDriver(id: "offline", isOnline: false, isAvailable: true)
        
        mockDriverService.mockAvailableDrivers = [offlineDriver, onlineDriver]
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        )
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "online")
    }
    
    func testFilterAvailableDriversOnly() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let availableDriver = createTestDriver(id: "available", isOnline: true, isAvailable: true)
        let busyDriver = createTestDriver(id: "busy", isOnline: true, isAvailable: false)
        
        mockDriverService.mockAvailableDrivers = [busyDriver, availableDriver]
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        )
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "available")
    }
    
    // MARK: - Vehicle Type Preference Tests
    
    func testPreferAppropriateVehicleType() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let bicycleDriver = createTestDriver(id: "bicycle", vehicleType: .bicycle)
        let carDriver = createTestDriver(id: "car", vehicleType: .car)
        
        mockDriverService.mockAvailableDrivers = [bicycleDriver, carDriver]
        
        // When - requesting for large order that needs car
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            preferredVehicleType: VehicleType.car
        )
        
        // Then
        XCTAssertEqual(assignedDriver?.id, "car")
    }
    
    // MARK: - Load Balancing Tests
    
    func testLoadBalancingAmongSimilarDrivers() async throws {
        // Given
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let driver1 = createTestDriver(
            id: "driver-1",
            location: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195),
            completedDeliveries: 50
        )
        let driver2 = createTestDriver(
            id: "driver-2",
            location: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4196),
            completedDeliveries: 10
        )
        
        mockDriverService.mockAvailableDrivers = [driver1, driver2]
        
        // When
        let assignedDriver = try await driverAssignmentService.findBestDriver(
            for: pickupLocation,
            deliveryLocation: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            useLoadBalancing: true
        )
        
        // Then - Should prefer driver with fewer completed deliveries
        XCTAssertEqual(assignedDriver?.id, "driver-2")
    }
    
    // MARK: - ETA Calculation Tests
    
    func testCalculateEstimatedPickupTime() async throws {
        // Given
        let driver = createTestDriver(
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        
        // When
        let eta = try await driverAssignmentService.calculateEstimatedPickupTime(
            driver: driver,
            pickupLocation: pickupLocation
        )
        
        // Then
        XCTAssertGreaterThan(eta, 0)
        XCTAssertLessThan(eta, 3600) // Should be less than 1 hour
    }
    
    func testCalculateEstimatedDeliveryTime() async throws {
        // Given
        let driver = createTestDriver(
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        let pickupLocation = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        let deliveryLocation = CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994)
        
        // When
        let eta = try await driverAssignmentService.calculateEstimatedDeliveryTime(
            driver: driver,
            pickupLocation: pickupLocation,
            deliveryLocation: deliveryLocation
        )
        
        // Then
        XCTAssertGreaterThan(eta, 0)
        XCTAssertLessThan(eta, 7200) // Should be less than 2 hours
    }
    
    // MARK: - Assignment Optimization Tests
    
    func testOptimizeMultipleOrderAssignments() async throws {
        // Given
        let orders = [
            createTestOrderLocation(id: "order-1", pickup: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
            createTestOrderLocation(id: "order-2", pickup: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)),
            createTestOrderLocation(id: "order-3", pickup: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994))
        ]
        
        let drivers = [
            createTestDriver(id: "driver-1", location: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195)),
            createTestDriver(id: "driver-2", location: CLLocationCoordinate2D(latitude: 37.7850, longitude: -122.4095))
        ]
        
        mockDriverService.mockAvailableDrivers = drivers
        
        // When
        let assignments = try await driverAssignmentService.optimizeAssignments(
            orders: orders,
            availableDrivers: drivers
        )
        
        // Then
        XCTAssertEqual(assignments.count, 2) // 2 drivers available
        XCTAssertTrue(assignments.allSatisfy { $0.orders.count > 0 })
    }
    
    // MARK: - Helper Methods
    
    private func createTestDriver(
        id: String = "test-driver",
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        isOnline: Bool = true,
        isAvailable: Bool = true,
        rating: Double = 4.5,
        completedDeliveries: Int = 100,
        vehicleType: VehicleType = .car
    ) -> Driver {
        return Driver(
            id: id,
            userId: "user-\(id)",
            name: "Driver \(id)",
            phoneNumber: "+1234567890",
            vehicleType: vehicleType,
            licensePlate: "ABC-\(id)",
            isOnline: isOnline,
            isAvailable: isAvailable,
            currentLocation: Coordinate(location),
            rating: rating,
            completedDeliveries: completedDeliveries,
            verificationStatus: .verified,
            createdAt: Date()
        )
    }
    
    private func createTestOrderLocation(
        id: String,
        pickup: CLLocationCoordinate2D,
        delivery: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
    ) -> OrderLocation {
        return OrderLocation(
            orderId: id,
            pickupLocation: pickup,
            deliveryLocation: delivery,
            priority: .normal
        )
    }
}

// MARK: - Supporting Types

struct OrderLocation {
    let orderId: String
    let pickupLocation: CLLocationCoordinate2D
    let deliveryLocation: CLLocationCoordinate2D
    let priority: OrderPriority
}

enum OrderPriority {
    case low
    case normal
    case high
    case urgent
}

struct DriverAssignment {
    let driver: Driver
    let orders: [OrderLocation]
    let estimatedCompletionTime: TimeInterval
}

// MARK: - Driver Assignment Service Protocol

protocol DriverAssignmentService {
    func findBestDriver(
        for pickupLocation: CLLocationCoordinate2D,
        deliveryLocation: CLLocationCoordinate2D,
        maxDistance: Double,
        preferredVehicleType: VehicleType?,
        useLoadBalancing: Bool
    ) async throws -> Driver?
    
    func calculateEstimatedPickupTime(
        driver: Driver,
        pickupLocation: CLLocationCoordinate2D
    ) async throws -> TimeInterval
    
    func calculateEstimatedDeliveryTime(
        driver: Driver,
        pickupLocation: CLLocationCoordinate2D,
        deliveryLocation: CLLocationCoordinate2D
    ) async throws -> TimeInterval
    
    func optimizeAssignments(
        orders: [OrderLocation],
        availableDrivers: [Driver]
    ) async throws -> [DriverAssignment]
}

// MARK: - Mock Driver Assignment Service

class MockDriverAssignmentService: DriverAssignmentService {
    private let driverService: MockDriverService
    private let locationService: MockLocationService
    
    var mockBestDriver: Driver?
    var mockPickupTime: TimeInterval = 600 // 10 minutes
    var mockDeliveryTime: TimeInterval = 1800 // 30 minutes
    var mockAssignments: [DriverAssignment] = []
    
    init(driverService: MockDriverService, locationService: MockLocationService) {
        self.driverService = driverService
        self.locationService = locationService
    }
    
    func findBestDriver(
        for pickupLocation: CLLocationCoordinate2D,
        deliveryLocation: CLLocationCoordinate2D,
        maxDistance: Double = 50.0,
        preferredVehicleType: VehicleType? = nil,
        useLoadBalancing: Bool = false
    ) async throws -> Driver? {
        // Use the actual driver service to find available drivers if mockBestDriver is not set
        if let mockDriver = mockBestDriver {
            return mockDriver
        }
        
        // Return first available driver from the mock service
        return driverService.mockAvailableDrivers.first
    }
    
    func calculateEstimatedPickupTime(
        driver: Driver,
        pickupLocation: CLLocationCoordinate2D
    ) async throws -> TimeInterval {
        return mockPickupTime
    }
    
    func calculateEstimatedDeliveryTime(
        driver: Driver,
        pickupLocation: CLLocationCoordinate2D,
        deliveryLocation: CLLocationCoordinate2D
    ) async throws -> TimeInterval {
        return mockDeliveryTime
    }
    
    func optimizeAssignments(
        orders: [OrderLocation],
        availableDrivers: [Driver]
    ) async throws -> [DriverAssignment] {
        return mockAssignments
    }
}