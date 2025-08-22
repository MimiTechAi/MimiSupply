import Foundation
import CoreLocation

@MainActor
protocol LocationService: ObservableObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var currentLocation: CLLocation? { get }
    
    func requestLocationPermission() async throws -> Bool
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func getPlacemark(for location: CLLocation) async throws -> CLPlacemark?
}