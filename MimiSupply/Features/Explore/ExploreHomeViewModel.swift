//
//  ExploreHomeViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import MapKit
import Combine

/// ViewModel for ExploreHomeView with comprehensive partner discovery functionality
@MainActor
class ExploreHomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var partners: [Partner] = []
    @Published var featuredPartners: [Partner] = []
    @Published var categories: [PartnerCategory] = PartnerCategory.allCases
    @Published var searchText: String = ""
    @Published var selectedCategory: PartnerCategory?
    @Published var sortOption: SortOption = .relevance
    @Published var priceRange: ClosedRange<Double> = 0...100
    @Published var deliveryTimeRange: ClosedRange<Int> = 0...60
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var currentLocationName: String = "Current Location"
    @Published var cartItemCount: Int = 0
    @Published var selectedPartner: Partner?
    
    // MARK: - Private Properties
    private let partnerRepository: PartnerRepository
    private let locationService: LocationService
    private let cartService: CartService
    private var cancellables = Set<AnyCancellable>()
    private var currentRegion: MKCoordinateRegion
    private var allPartners: [Partner] = []
    private var searchTask: Task<Void, Never>?
    private let pageSize = 20
    private var currentPage = 0
    private var hasMorePages = true
    @Published var showingCart = false
    
    // MARK: - Computed Properties
    var partnersListTitle: String {
        if let selectedCategory = selectedCategory {
            return selectedCategory.displayName
        } else if !searchText.isEmpty {
            return "Search Results"
        } else {
            return "All Partners"
        }
    }
    
    // MARK: - Initialization
    init(
        partnerRepository: PartnerRepository? = nil,
        locationService: LocationService? = nil,
        cartService: CartService? = nil
    ) {
        self.partnerRepository = partnerRepository ?? AppContainer.shared.partnerRepository
        self.locationService = locationService ?? AppContainer.shared.locationService
        self.cartService = cartService ?? AppContainer.shared.cartService
        self.currentRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current location
            await updateCurrentLocation()
            
            // Load partners and featured partners concurrently
            async let partnersTask = partnerRepository.fetchPartners(in: currentRegion)
            async let featuredTask = partnerRepository.fetchFeaturedPartners()
            
            let (loadedPartners, loadedFeatured) = try await (partnersTask, featuredTask)
            
            allPartners = loadedPartners
            featuredPartners = Array(loadedFeatured.prefix(10)) // Limit featured partners
            partners = Array(allPartners.prefix(pageSize))
            currentPage = 1
            hasMorePages = allPartners.count > pageSize
            
        } catch {
            print("Failed to load initial data: \(error)")
            // Handle error - could show error state
        }
    }
    
    func refreshData() async {
        currentPage = 0
        hasMorePages = true
        await loadInitialData()
    }
    
    func performSearch(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            guard !Task.isCancelled else { return }
            
            if query.isEmpty {
                await applyFilters()
            } else {
                await searchPartners(query: query)
            }
        }
    }
    
    func selectCategory(_ category: PartnerCategory) async {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        await applyFilters()
    }
    
    func applyFilters() async {
        var filteredPartners = allPartners
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filteredPartners = filteredPartners.filter { $0.category == selectedCategory }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filteredPartners = filteredPartners.filter { partner in
                partner.name.localizedCaseInsensitiveContains(searchText) ||
                partner.description.localizedCaseInsensitiveContains(searchText) ||
                partner.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply price range filter (based on minimum order amount)
        filteredPartners = filteredPartners.filter { partner in
            let minOrderDollars = Double(partner.minimumOrderAmount) / 100.0
            return priceRange.contains(minOrderDollars)
        }
        
        // Apply delivery time filter
        filteredPartners = filteredPartners.filter { partner in
            deliveryTimeRange.contains(partner.estimatedDeliveryTime)
        }
        
        // Apply sorting
        filteredPartners = sortPartners(filteredPartners)
        
        partners = Array(filteredPartners.prefix(pageSize))
        currentPage = 1
        hasMorePages = filteredPartners.count > pageSize
    }
    
    func loadMoreIfNeeded() async {
        guard !isLoadingMore && hasMorePages else { return }
        
        isLoadingMore = true
        defer { isLoadingMore = false }
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, allPartners.count)
        
        if startIndex < allPartners.count {
            let morePartners = Array(allPartners[startIndex..<endIndex])
            partners.append(contentsOf: morePartners)
            currentPage += 1
            hasMorePages = endIndex < allPartners.count
        }
    }
    
    func selectPartner(_ partner: Partner) {
        // Navigate to partner detail
        selectedPartner = partner
    }
    
    func navigateToCart() {
        showingCart = true
    }
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        
        if query.isEmpty {
            partners = Array(allPartners.prefix(pageSize))
            return
        }
        
        searchTask = Task {
            await searchPartners(query: query)
        }
    }
    
    func showAllFeatured() async {
        selectedCategory = nil
        searchText = ""
        partners = featuredPartners
        currentPage = 1
        hasMorePages = false
    }
    
    func getPartnerCount(for category: PartnerCategory) -> Int {
        return allPartners.filter { $0.category == category }.count
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Listen to cart item count changes
        cartService.cartItemCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.cartItemCount = count
            }
            .store(in: &cancellables)
        
        // Search text debouncing
        $searchText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(query: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentLocation() async {
        do {
            try await locationService.requestLocationPermission()
            
            if let location = await locationService.currentLocation {
                currentRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                
                // Update location name (mock implementation)
                currentLocationName = "Current Location" // TODO: Reverse geocode
            }
        } catch {
            print("Failed to get location: \(error)")
        }
    }
    
    private func searchPartners(query: String) async {
        do {
            let searchResults = try await partnerRepository.searchPartners(
                query: query,
                in: currentRegion
            )
            partners = Array(searchResults.prefix(pageSize))
            currentPage = 1
            hasMorePages = searchResults.count > pageSize
        } catch {
            print("Search failed: \(error)")
        }
    }
    
    private func sortPartners(_ partners: [Partner]) -> [Partner] {
        switch sortOption {
        case .relevance:
            return partners.sorted { $0.rating > $1.rating }
        case .rating:
            return partners.sorted { $0.rating > $1.rating }
        case .deliveryTime:
            return partners.sorted { $0.estimatedDeliveryTime < $1.estimatedDeliveryTime }
        case .distance:
            // TODO: Implement distance sorting based on current location
            return partners
        case .alphabetical:
            return partners.sorted { $0.name < $1.name }
        }
    }
}

// MARK: - Supporting Types

enum SortOption: String, CaseIterable {
    case relevance = "Relevance"
    case rating = "Rating"
    case deliveryTime = "Delivery Time"
    case distance = "Distance"
    case alphabetical = "A-Z"
    
    var displayName: String {
        return rawValue
    }
}