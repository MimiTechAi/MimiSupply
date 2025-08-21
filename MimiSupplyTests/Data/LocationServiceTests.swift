//
//  LocationServiceTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import CoreLocation
@testable import MimiSupply

/// Unit tests for LocationService implementation
final class LocationServiceTests: XCTestCase {
    
    var mockLocationService: MockLocationService!
    
    override func setUp() {
        super.setUp()
        mockLocationService = MockLocationService()
    }
    
    override func tearDown() {
        mockLocationService = nil
        super.tearDown()
    }
    
    // MARK: - Permission Tests
    
    func testRequestLocationPermission_WhenNotDetermined_ShouldRequestPermission() async throws {
        // Given
        mockLocationService.authorizationStatus = .notDetermined
        
        // When
        try await mockLocationService.requestLocationPermission()
        
        // Then
        XCTAssertTrue(mockLocationService.didRequestPermission)
    }
    
    func testRequestLocationPermission_WhenAlreadyAuthorized_ShouldNotRequestAgain() async throws {
        // Given
        mockLocationService.authorizationStatus = .authorizedWhenInUse
        
        // When
        try await mockLocationService.requestLocationPermission()
        
        // Then
        XCTAssertFalse(mockLocationService.didRequestPermission)
    }
    
    func testRequestLocationPermission_WhenDenied_ShouldThrowError() async {
        // Given
        mockLocationService.authorizationStatus = .denied
        mockLocationService.shouldThrowPermissionError = true
        
        // When/Then
        do {
            try await mockLocationService.requestLocationPermission()
            XCTFail("Should have thrown permission denied error")
        } catch let error as LocationError {
            XCTAssertEqual(error, .permissionDenied)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Location Updates Tests
    
    func testStartLocationUpdates_WithPermission_ShouldStartUpdating() async throws {
        // Given
        mockLocationService.authorizationStatus = .authorizedWhenInUse
        
        // When
        try await mockLocationService.startLocationUpdates()
        
        // Then
        XCTAssertTrue(mockLocationService.isUpdatingLocation)
    }
    
    func testStartLocationUpdates_WithoutPermission_ShouldThrowError() async {
        // Given
        mockLocationService.authorizationStatus = .denied
        
        // When/Then
        do {
            try await mockLocationService.startLocationUpdates()
            XCTFail("Should have thrown permission denied error")
        } catch let error as LocationError {
            XCTAssertEqual(error, .permissionDenied)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testStopLocationUpdates_ShouldStopUpdating() {
        // Given
        mockLocationService.isUpdatingLocation = true
        
        // When
        mockLocationService.stopLocationUpdates()
        
        // Then
        XCTAssertFalse(mockLocationService.isUpdatingLocation)
    }
    
    // MARK: - Background Location Tests
    
    func testStartBackgroundLocationUpdates_WithAlwaysPermission_ShouldStartBackgroundUpdates() async throws {
        // Given
        mockLocationService.authorizationStatus = .authorizedAlways
        
        // When
        try await mockLocationService.startBackgroundLocationUpdates()
        
        // Then
        XCTAssertTrue(mockLocationService.isBackgroundLocationEnabled)
    }
    
    func testStartBackgroundLocationUpdates_WithoutAlwaysPermission_ShouldThrowError() async {
        // Given
        mockLocationService.authorizationStatus = .authorizedWhenInUse
        
        // When/Then
        do {
            try await mockLocationService.startBackgroundLocationUpdates()
            XCTFail("Should have thrown permission denied error")
        } catch let error as LocationError {
            XCTAssertEqual(error, .permissionDenied)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testStopBackgroundLocationUpdates_ShouldDisableBackgroundLocation() {
        // Given
        mockLocationService.isBackgroundLocationEnabled = true
        
        // When
        mockLocationService.stopBackgroundLocationUpdates()
        
        // Then
        XCTAssertFalse(mockLocationService.isBackgroundLocationEnabled)
    }
    
    // MARK: - Current Location Tests
    
    func testCurrentLocation_WithValidLocation_ShouldReturnLocation() async {
        // Given
        let expectedLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        mockLocationService.mockCurrentLocation = expectedLocation
        
        // When
        let location = await mockLocationService.currentLocation
        
        // Then
        XCTAssertEqual(location?.coordinate.latitude ?? 0, expectedLocation.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(location?.coordinate.longitude ?? 0, expectedLocation.coordinate.longitude, accuracy: 0.0001)
    }
    
    func testCurrentLocation_WithLocationError_ShouldReturnNil() async {
        // Given
        mockLocationService.shouldThrowLocationError = true
        
        // When
        let location = await mockLocationService.currentLocation
        
        // Then
        XCTAssertNil(location)
    }
    
    // MARK: - Battery Optimization Tests
    
    func testLocationAccuracy_InForeground_ShouldUseStandardAccuracy() async throws {
        // Given
        mockLocationService.authorizationStatus = .authorizedWhenInUse
        
        // When
        try await mockLocationService.startLocationUpdates()
        
        // Then
        XCTAssertEqual(mockLocationService.desiredAccuracy, kCLLocationAccuracyNearestTenMeters)
    }
    
    func testLocationAccuracy_InBackground_ShouldUseLowerAccuracy() async throws {
        // Given
        mockLocationService.authorizationStatus = .authorizedAlways
        
        // When
        try await mockLocationService.startBackgroundLocationUpdates()
        
        // Then
        XCTAssertEqual(mockLocationService.desiredAccuracy, kCLLocationAccuracyHundredMeters)
    }
}

