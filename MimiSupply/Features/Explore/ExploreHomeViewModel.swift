import SwiftUI
import Combine
import CoreLocation

@MainActor
class ExploreHomeViewModel: ObservableObject, @unchecked Sendable {
    // MARK: - Published Properties
    @Published var partners: [Partner] = []
    @Published var featuredPartners: [Partner] = []
    @Published var categories: [PartnerCategory] = PartnerCategory.allCases
    @Published var selectedCategory: PartnerCategory?
    @Published var sortOption: SortOption = .recommended
    @Published var priceRange: ClosedRange<Double> = 0...100
    @Published var deliveryTimeRange: ClosedRange<Double> = 0...60
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var selectedPartner: Partner?
    @Published var currentLocationName = "Loading..."
    @Published var cartItemCount = 0
    @Published var showingCart = false
    @Published private(set) var error: AppError?
    
    // MARK: - Private Properties
    private let locationService: LocationService
    private let googlePlacesService: GooglePlacesService
    private var cancellables = Set<AnyCancellable>()
    private var userLocation: CLLocation?

    // MARK: - Initialization
    init(
        locationService: LocationService = LocationServiceImpl.shared,
        googlePlacesService: GooglePlacesService = GooglePlacesServiceImpl()
    ) {
        self.locationService = locationService
        self.googlePlacesService = googlePlacesService
        
        setupBindings()
    }
    
    // MARK: - Data Loading
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await locationService.requestLocationPermission()
            self.userLocation = await locationService.currentLocation
            
            if let location = userLocation {
                await updateLocationName(location: location)
                await fetchNearbyPartners(location: location)
            } else {
                // Fallback or error handling if location is not available
                currentLocationName = "Location not found"
                // Optionally, load partners from a default location
                let defaultLocation = CLLocation(latitude: 52.5200, longitude: 13.4050) // Berlin
                await updateLocationName(location: defaultLocation)
                await fetchNearbyPartners(location: defaultLocation)
            }
            
            // For now, featured partners can remain static or be derived from the fetched partners
            self.featuredPartners = GermanPartnerData.getFeaturedPartners()
            
        } catch {
            self.error = .location(.permissionDenied)
            currentLocationName = "Permission denied"
        }
    }
    
    func refreshData() async {
        await loadInitialData()
    }
    
    // MARK: - Partner Fetching
    private func fetchNearbyPartners(location: CLLocation) async {
        let placeTypes = selectedCategory?.googlePlaceTypes ?? defaultPlaceTypes
        
        do {
            let googlePlaces = try await googlePlacesService.findNearbyPlaces(
                coordinate: location.coordinate,
                radius: 5000, // 5km radius
                placeTypes: placeTypes
            )
            
            // Convert GooglePlace to our Partner model
            self.partners = googlePlaces.map { convertGooglePlaceToPartner($0) }
            
        } catch {
            self.error = .network(.connectionFailed) // CORRECTED
            print("Error fetching nearby places: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Filtering and Sorting
    func selectCategory(_ category: PartnerCategory?) async {
        if selectedCategory == category {
            selectedCategory = nil // Deselect if tapped again
        } else {
            selectedCategory = category
        }
        
        if let location = userLocation {
            isLoading = true
            await fetchNearbyPartners(location: location)
            isLoading = false
        }
    }
    
    func performSearch(query: String) async {
        // Implement search logic here if needed, or rely on category filtering
    }
    
    func applyFilters() async {
        // Implement filter logic if needed
    }
    
    func showAllFeatured() async {
        // Implement logic to show all featured partners
    }
    
    // MARK: - Navigation
    func selectPartner(_ partner: Partner) {
        self.selectedPartner = partner
    }
    
    func navigateToCart() {
        showingCart = true
    }
    
    // MARK: - Helper Methods
    private func setupBindings() {
        // Setup any necessary Combine bindings
    }
    
    private func updateLocationName(location: CLLocation) async {
        let geocoder = CLGeocoder()
        if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
            currentLocationName = placemark.locality ?? placemark.name ?? "Current Location"
        }
    }
    
    private var defaultPlaceTypes: [String] {
        return ["restaurant", "cafe", "bakery", "grocery_or_supermarket", "pharmacy", "store"]
    }
    
    func loadMoreIfNeeded() async {
        // Implementation for loading more partners (pagination)
        // For now, do nothing
        print("Load more partners requested")
    }
    
    func getPartnerCount(for category: PartnerCategory) -> Int {
        // This can be adapted if needed, for now, it's less relevant with dynamic data
        return partners.filter { $0.category == category }.count
    }
    
    // MARK: - Conversion
    private func convertGooglePlaceToPartner(_ place: GooglePlace) -> Partner {
        // This is a simplified conversion. In a real app, you might fetch more details
        // for each place to get ratings, opening hours, etc.
        return Partner(
            id: place.placeID,
            name: place.name,
            category: mapGoogleTypeToPartnerCategory(place.types),
            description: place.address ?? "No address available",
            address: Address(
                street: place.address ?? "",
                city: "", state: "", postalCode: "", country: "" // These would need more detailed fetching
            ),
            location: place.coordinate,
            phoneNumber: nil,
            email: nil,
            heroImageURL: nil,
            logoURL: nil,
            isVerified: false,
            isActive: true, // Assume active if returned by API
            rating: 0, // Placeholder
            reviewCount: 0, // Placeholder
            openingHours: [:], // Placeholder
            deliveryRadius: 5.0,
            minimumOrderAmount: 0, // Placeholder
            estimatedDeliveryTime: 25 // Placeholder
        )
    }
    
    private func mapGoogleTypeToPartnerCategory(_ types: [String]?) -> PartnerCategory {
        guard let types = types else { return .restaurant }
        
        if types.contains("restaurant") { return .restaurant }
        if types.contains("cafe") { return .coffee }
        if types.contains("bakery") { return .bakery }
        if types.contains("grocery_or_supermarket") { return .grocery }
        if types.contains("pharmacy") { return .pharmacy }
        if types.contains("electronics_store") { return .electronics }
        if types.contains("florist") { return .flowers }
        if types.contains("liquor_store") { return .alcohol }
        // Add more mappings as needed
        
        return .retail
    }
}

extension PartnerCategory {
    var googlePlaceTypes: [String] {
        switch self {
        case .restaurant: return ["restaurant"]
        case .grocery: return ["grocery_or_supermarket"]
        case .pharmacy: return ["pharmacy"]
        case .coffee: return ["cafe"]
        case .retail: return ["store"]
        case .convenience: return ["convenience_store"]
        case .bakery: return ["bakery"]
        case .alcohol: return ["liquor_store"]
        case .flowers: return ["florist"]
        case .electronics: return ["electronics_store"]
        }
    }
}