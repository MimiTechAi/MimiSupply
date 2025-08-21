import Foundation
import CoreLocation

protocol LocationService {
    var authorizationStatus: CLAuthorizationStatus { get }
    var currentLocation: CLLocation? { get }
    
    func requestLocationPermission() async throws -> Bool
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func getPlacemark(for location: CLLocation) async throws -> CLPlacemark?
}