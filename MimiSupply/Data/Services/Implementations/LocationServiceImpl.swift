//
//  LocationServiceImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
@preconcurrency import CoreLocation
import Combine

// Import project-specific types - defined in Foundation/Error/AppError.swift


/// Implementation of LocationService for managing location services with battery optimization
final class LocationServiceImpl: NSObject, LocationService {
    
    // MARK: - Singleton
    static let shared = LocationServiceImpl()
    
    private let locationManager = CLLocationManager()
    
    // Thread-safe state management using actors
    @MainActor private var currentLocationContinuation: CheckedContinuation<CLLocation?, Never>?
    @MainActor private var permissionContinuation: CheckedContinuation<Void, Error>?
    
    // Location tracking state - protected by lock for thread safety
    private let stateLock = NSLock()
    private var _isTrackingLocation = false
    private var _isBackgroundTracking = false
    private var _lastLocationUpdate = Date()
    
    private var isTrackingLocation: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _isTrackingLocation
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _isTrackingLocation = newValue
        }
    }
    
    private var isBackgroundTracking: Bool {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _isBackgroundTracking
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _isBackgroundTracking = newValue
        }
    }
    
    private var lastLocationUpdate: Date {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _lastLocationUpdate
        }
        set {
            stateLock.lock()
            defer { stateLock.unlock() }
            _lastLocationUpdate = newValue
        }
    }
    
    // Battery optimization settings
    private let standardAccuracy = kCLLocationAccuracyNearestTenMeters
    private let highAccuracy = kCLLocationAccuracyBest
    private let backgroundUpdateInterval: TimeInterval = 10.0
    private let foregroundUpdateInterval: TimeInterval = 5.0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = standardAccuracy
        locationManager.distanceFilter = 10 // Only update when moved 10 meters
    }
    
    var currentLocation: CLLocation? {
        get async {
            // Return cached location if recent (within 30 seconds)
            if let lastLocation = locationManager.location,
               lastLocation.timestamp.timeIntervalSinceNow > -30 {
                return lastLocation
            }
            
            return await withCheckedContinuation { continuation in
                Task { @MainActor in
                    currentLocationContinuation = continuation
                    locationManager.requestLocation()
                }
            }
        }
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    func requestLocationPermission() async throws {
        guard authorizationStatus == .notDetermined else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                permissionContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }
    
    func startLocationUpdates() async throws {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw AppError.location(.permissionDenied)
        }
        #else
        guard authorizationStatus == .authorized else {
            throw AppError.location(.permissionDenied)
        }
        #endif
        
        guard !isTrackingLocation else { return }
        
        isTrackingLocation = true
        isBackgroundTracking = false
        
        // Configure for foreground tracking with better accuracy
        locationManager.desiredAccuracy = standardAccuracy
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        guard isTrackingLocation else { return }
        
        isTrackingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    func startBackgroundLocationUpdates() async throws {
        guard authorizationStatus == .authorizedAlways else {
            throw AppError.location(.permissionDenied)
        }
        
        guard !isBackgroundTracking else { return }
        
        isBackgroundTracking = true
        
        // Configure for background tracking with battery optimization
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 50 // Larger distance filter for background
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
    }
    
    func stopBackgroundLocationUpdates() {
        guard isBackgroundTracking else { return }
        
        isBackgroundTracking = false
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Battery Optimization Helpers
    
    private func shouldUpdateLocation(_ location: CLLocation) -> Bool {
        let timeSinceLastUpdate = Date().timeIntervalSince(lastLocationUpdate)
        let requiredInterval = isBackgroundTracking ? backgroundUpdateInterval : foregroundUpdateInterval
        
        return timeSinceLastUpdate >= requiredInterval
    }
    
    private func optimizeAccuracyForBatteryLife() {
        if isBackgroundTracking {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = 50
        } else {
            locationManager.desiredAccuracy = standardAccuracy
            locationManager.distanceFilter = 10
        }
    }
}

// MARK: - Concurrency
extension LocationServiceImpl: @unchecked Sendable {}

// MARK: - CLLocationManagerDelegate

extension LocationServiceImpl: @preconcurrency CLLocationManagerDelegate {
    
    @MainActor func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Battery optimization: only process if enough time has passed
        if shouldUpdateLocation(location) {
            lastLocationUpdate = Date()
            currentLocationContinuation?.resume(returning: location)
            currentLocationContinuation = nil
        }
    }
    
    @MainActor func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let locationError: LocationError
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .permissionDenied
            case .locationUnknown, .network:
                locationError = .locationUnavailable
            default:
                locationError = .locationUnavailable
            }
        } else {
            locationError = .locationUnavailable
        }
        
        currentLocationContinuation?.resume(returning: nil)
        currentLocationContinuation = nil
        
        permissionContinuation?.resume(throwing: locationError)
        permissionContinuation = nil
    }
    
    @MainActor func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            permissionContinuation?.resume()
            permissionContinuation = nil
            optimizeAccuracyForBatteryLife()
            
        case .denied, .restricted:
            permissionContinuation?.resume(throwing: AppError.location(.permissionDenied))
            permissionContinuation = nil
            
        case .notDetermined:
            // Still waiting for user decision
            break
            
        @unknown default:
            permissionContinuation?.resume(throwing: AppError.location(.permissionDenied))
            permissionContinuation = nil
        }
    }
}
