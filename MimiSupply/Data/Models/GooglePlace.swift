import Foundation
import CoreLocation

struct GooglePlace {
    let name: String
    let placeID: String
    let coordinate: CLLocationCoordinate2D
    let address: String?
    let types: [String]?
}