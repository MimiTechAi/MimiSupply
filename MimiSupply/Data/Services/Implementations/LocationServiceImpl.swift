import Foundation
import CoreLocation
import Combine

@MainActor
class LocationServiceImpl: NSObject, LocationService {
    
    static let shared = LocationServiceImpl()
    
    private let locationManager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<Bool, Error>?
    
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    
    override private init() {
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() async throws -> Bool {
        guard locationManager.authorizationStatus == .notDetermined else {
            return locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.authorizationContinuation = continuation
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getPlacemark(for location: CLLocation) async throws -> CLPlacemark? {
        let geocoder = CLGeocoder()
        return try await geocoder.reverseGeocodeLocation(location).first
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationServiceImpl: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                self.currentLocation = location
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                authorizationContinuation?.resume(returning: true)
            case .denied, .restricted:
                authorizationContinuation?.resume(returning: false)
            case .notDetermined:
                break // Wait for user action
            @unknown default:
                authorizationContinuation?.resume(returning: false)
            }
            authorizationContinuation = nil
        }
    }
}