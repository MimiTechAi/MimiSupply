import Foundation
import GooglePlaces
import CoreLocation

// MARK: - Protocol
protocol GooglePlacesService {
    func findNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        placeTypes: [String]
    ) async throws -> [GooglePlace]
}

// MARK: - Implementation
class GooglePlacesServiceImpl: GooglePlacesService {
    
    private let placesClient: GMSPlacesClient
    
    init(placesClient: GMSPlacesClient = GMSPlacesClient.shared()) {
        self.placesClient = placesClient
    }
    
    func findNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        radius: Double,
        placeTypes: [String]
    ) async throws -> [GooglePlace] {
        
        let locationBias = GMSPlaceRectangularLocationOption(
            CLLocationCoordinate2D(latitude: coordinate.latitude - 0.1, longitude: coordinate.longitude - 0.1),
            CLLocationCoordinate2D(latitude: coordinate.latitude + 0.1, longitude: coordinate.longitude + 0.1)
        )
        
        let filter = GMSPlaceFilter()
        filter.types = placeTypes
        
        let placeFields: GMSPlaceField = [.name, .placeID, .coordinate, .formattedAddress, .types]
        
        return try await withCheckedThrowingContinuation { continuation in
            placesClient.findPlaceLikelihoodsFromCurrentLocation(
                withPlaceFields: placeFields,
                filter: filter
            ) { (placeLikelihoods, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placeLikelihoods = placeLikelihoods else {
                    continuation.resume(returning: [])
                    return
                }
                
                let places = placeLikelihoods.map {
                    GooglePlace(
                        name: $0.place.name ?? "N/A",
                        placeID: $0.place.placeID ?? "N/A",
                        coordinate: $0.place.coordinate,
                        address: $0.place.formattedAddress,
                        types: $0.place.types
                    )
                }
                
                continuation.resume(returning: places)
            }
        }
    }
}