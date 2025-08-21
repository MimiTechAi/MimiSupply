//
//  LocationServiceImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class LocationServiceImpl: NSObject, LocationService, CLLocationManagerDelegate {
    
    static let shared = LocationServiceImpl()
    
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
    
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
    
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?
    
    private override init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = standardAccuracy
        locationManager.distanceFilter = 10 // Only update when moved 10 meters
    }
    
    func requestLocationPermission() async throws {
        guard authorizationStatus == .notDetermined else { return }
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
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

// MARK: - CLLocationManagerDelegate

extension LocationServiceImpl: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Battery optimization: only process if enough time has passed
        if shouldUpdateLocation(location) {
            lastLocationUpdate = Date()
            currentLocationContinuation?.resume(returning: location)
            currentLocationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
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