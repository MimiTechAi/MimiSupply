import Foundation
@preconcurrency import GooglePlaces
import CoreLocation

// MARK: - Protocol
protocol GooglePlacesService: Sendable {
    func findNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        placeTypes: [String]
    ) async throws -> [GooglePlace]
}

// MARK: - Implementation
final class GooglePlacesServiceImpl: GooglePlacesService, @unchecked Sendable {
    
    private let placesClient: GMSPlacesClient
    
    init(placesClient: GMSPlacesClient = GMSPlacesClient.shared()) {
        self.placesClient = placesClient
    }
    
    func findNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        placeTypes: [String]
    ) async throws -> [GooglePlace] {
        
        // For now, return mock data until we implement proper Google Places integration
        // In a real implementation, you would use GMSPlacesClient with proper API calls
        
        return [
            GooglePlace(
                name: "Demo Restaurant",
                placeID: "demo_1",
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude + 0.001, longitude: coordinate.longitude + 0.001),
                address: "Demo Address 1",
                types: ["restaurant"]
            ),
            GooglePlace(
                name: "Demo Grocery",
                placeID: "demo_2", 
                coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude - 0.001, longitude: coordinate.longitude - 0.001),
                address: "Demo Address 2",
                types: ["grocery_or_supermarket"]
            )
        ]
    }
}