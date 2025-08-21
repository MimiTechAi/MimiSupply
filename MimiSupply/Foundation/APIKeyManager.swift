import Foundation

enum APIKeyManager {
    static func getGooglePlacesAPIKey() -> String {
        guard let filePath = Bundle.main.path(forResource: "APIKeys", ofType: "plist") else {
            fatalError("Couldn't find file 'APIKeys.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "GooglePlacesAPIKey") as? String else {
            fatalError("Couldn't find key 'GooglePlacesAPIKey' in 'APIKeys.plist'.")
        }
        if value.starts(with: "IHREN_") {
            fatalError("Please replace 'IHREN_API_SCHLÜSSEL_HIER_EINFÜGEN' in APIKeys.plist with your actual Google Places API Key.")
        }
        return value
    }
}