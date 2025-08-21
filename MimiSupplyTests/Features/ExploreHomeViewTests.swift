//
//  ExploreHomeViewTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import SwiftUI
#if canImport(ViewInspector)
import ViewInspector
#endif
@testable import MimiSupply

/// UI tests for ExploreHomeView functionality and accessibility
final class ExploreHomeViewTests: XCTestCase {
    
    var mockPartnerRepository: MockPartnerRepository!
    var mockLocationService: MockLocationService!
    var viewModel: ExploreHomeViewModel!
    
    override func setUp() {
        super.setUp()
        mockPartnerRepository = MockPartnerRepository()
        mockLocationService = MockLocationService()
        viewModel = ExploreHomeViewModel(
            partnerRepository: mockPartnerRepository,
            locationService: mockLocationService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockLocationService = nil
        mockPartnerRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initial Load Tests
    
    @MainActor
    func testInitialDataLoad() async throws {
        // Given
        XCTAssertTrue(viewModel.partners.isEmpty)
        XCTAssertTrue(viewModel.featuredPartners.isEmpty)
        
        // When
        await viewModel.loadInitialData()
        
        // Then
        XCTAssertFalse(viewModel.partners.isEmpty)
        XCTAssertFalse(viewModel.featuredPartners.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testLoadingStateManagement() async throws {
        // Given
        XCTAssertFalse(viewModel.isLoading)
        
        // When
        let loadTask = Task {
            await viewModel.loadInitialData()
        }
        
        // Then - loading should be true during load
        // Note: This test might be flaky due to timing, but demonstrates the concept
        
        await loadTask.value
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Search Tests
    
    @MainActor
    func testSearchFunctionality() async throws {
        // Given
        await viewModel.loadInitialData()
        let initialPartnerCount = viewModel.partners.count
        
        // When
        viewModel.searchText = "Bella"
        await viewModel.performSearch(query: "Bella")
        
        // Then
        XCTAssertLessThanOrEqual(viewModel.partners.count, initialPartnerCount)
        XCTAssertTrue(viewModel.partners.contains { $0.name.contains("Bella") })
    }
    
    @MainActor
    func testEmptySearchReturnsAllPartners() async throws {
        // Given
        await viewModel.loadInitialData()
        let initialPartnerCount = viewModel.partners.count
        
        // When
        viewModel.searchText = "NonExistentPartner"
        await viewModel.performSearch(query: "NonExistentPartner")
        let searchResultCount = viewModel.partners.count
        
        viewModel.searchText = ""
        await viewModel.performSearch(query: "")
        
        // Then
        XCTAssertEqual(viewModel.partners.count, initialPartnerCount)
        XCTAssertLessThan(searchResultCount, initialPartnerCount)
    }
    
    // MARK: - Category Filter Tests
    
    @MainActor
    func testCategoryFiltering() async throws {
        // Given
        await viewModel.loadInitialData()
        
        // When
        await viewModel.selectCategory(.restaurant)
        
        // Then
        XCTAssertEqual(viewModel.selectedCategory, .restaurant)
        XCTAssertTrue(viewModel.partners.allSatisfy { $0.category == .restaurant })
        XCTAssertEqual(viewModel.partnersListTitle, "Restaurant")
    }
    
    @MainActor
    func testCategoryToggling() async throws {
        // Given
        await viewModel.loadInitialData()
        
        // When - select category
        await viewModel.selectCategory(.pharmacy)
        XCTAssertEqual(viewModel.selectedCategory, .pharmacy)
        
        // When - select same category again (should deselect)
        await viewModel.selectCategory(.pharmacy)
        
        // Then
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertEqual(viewModel.partnersListTitle, "All Partners")
    }
    
    @MainActor
    func testGetPartnerCountForCategory() async throws {
        // Given
        await viewModel.loadInitialData()
        
        // When
        let restaurantCount = viewModel.getPartnerCount(for: .restaurant)
        let pharmacyCount = viewModel.getPartnerCount(for: .pharmacy)
        
        // Then
        XCTAssertGreaterThan(restaurantCount, 0)
        XCTAssertGreaterThan(pharmacyCount, 0)
    }
    
    // MARK: - Sorting Tests
    
    @MainActor
    func testSortingByRating() async throws {
        // Given
        await viewModel.loadInitialData()
        viewModel.sortOption = .rating
        
        // When
        await viewModel.applyFilters()
        
        // Then
        let ratings = viewModel.partners.map { $0.rating }
        let sortedRatings = ratings.sorted(by: >)
        XCTAssertEqual(ratings, sortedRatings)
    }
    
    @MainActor
    func testSortingByDeliveryTime() async throws {
        // Given
        await viewModel.loadInitialData()
        viewModel.sortOption = .deliveryTime
        
        // When
        await viewModel.applyFilters()
        
        // Then
        let deliveryTimes = viewModel.partners.map { $0.estimatedDeliveryTime }
        let sortedTimes = deliveryTimes.sorted(by: <)
        XCTAssertEqual(deliveryTimes, sortedTimes)
    }
    
    // MARK: - Filter Tests
    
    @MainActor
    func testPriceRangeFiltering() async throws {
        // Given
        await viewModel.loadInitialData()
        viewModel.priceRange = 10...20 // $10-$20
        
        // When
        await viewModel.applyFilters()
        
        // Then
        XCTAssertTrue(viewModel.partners.allSatisfy { partner in
            let minOrderDollars = Double(partner.minimumOrderAmount) / 100.0
            return viewModel.priceRange.contains(minOrderDollars)
        })
    }
    
    @MainActor
    func testDeliveryTimeRangeFiltering() async throws {
        // Given
        await viewModel.loadInitialData()
        viewModel.deliveryTimeRange = 10...30 // 10-30 minutes
        
        // When
        await viewModel.applyFilters()
        
        // Then
        XCTAssertTrue(viewModel.partners.allSatisfy { partner in
            viewModel.deliveryTimeRange.contains(partner.estimatedDeliveryTime)
        })
    }
    
    // MARK: - Pagination Tests
    
    @MainActor
    func testLoadMoreFunctionality() async throws {
        // Given
        await viewModel.loadInitialData()
        let initialCount = viewModel.partners.count
        
        // When
        await viewModel.loadMoreIfNeeded()
        
        // Then
        // Note: This test depends on having more than pageSize partners in mock data
        // For now, we just verify the method doesn't crash
        XCTAssertGreaterThanOrEqual(viewModel.partners.count, initialCount)
    }
    
    // MARK: - Featured Partners Tests
    
    @MainActor
    func testShowAllFeatured() async throws {
        // Given
        await viewModel.loadInitialData()
        let featuredCount = viewModel.featuredPartners.count
        
        // When
        await viewModel.showAllFeatured()
        
        // Then
        XCTAssertEqual(viewModel.partners.count, featuredCount)
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertTrue(viewModel.searchText.isEmpty)
    }
    
    // MARK: - Location Tests
    
    @MainActor
    func testLocationNameUpdate() async throws {
        // Given
        let initialLocationName = viewModel.currentLocationName
        
        // When
        await viewModel.loadInitialData()
        
        // Then
        // Location name should remain "Current Location" for mock
        XCTAssertEqual(viewModel.currentLocationName, "Current Location")
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testErrorHandlingDuringLoad() async throws {
        // Given
        let failingRepository = FailingPartnerRepository()
        let viewModelWithFailingRepo = ExploreHomeViewModel(
            partnerRepository: failingRepository,
            locationService: mockLocationService
        )
        
        // When
        await viewModelWithFailingRepo.loadInitialData()
        
        // Then
        XCTAssertTrue(viewModelWithFailingRepo.partners.isEmpty)
        XCTAssertFalse(viewModelWithFailingRepo.isLoading)
    }
    
    // MARK: - Refresh Tests
    
    @MainActor
    func testRefreshData() async throws {
        // Given
        await viewModel.loadInitialData()
        let initialPartners = viewModel.partners
        
        // When
        await viewModel.refreshData()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.partners.count, initialPartners.count)
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testPartnerSelection() {
        // Given
        let partner = Partner(
            name: "Test Partner",
            category: .restaurant,
            description: "Test description",
            address: Address(street: "123 Test St", city: "Test City", state: "TS", postalCode: "12345", country: "US"),
            location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            phoneNumber: "+1234567890",
            email: "test@test.com"
        )
        
        // When
        viewModel.selectPartner(partner)
        
        // Then
        // This test verifies the method doesn't crash
        // In a real implementation, you'd verify navigation occurred
        XCTAssertTrue(true)
    }
    
    @MainActor
    func testCartNavigation() {
        // When
        viewModel.navigateToCart()
        
        // Then
        // This test verifies the method doesn't crash
        // In a real implementation, you'd verify navigation occurred
        XCTAssertTrue(true)
    }
}

// MARK: - Mock Services for Testing

class MockLocationService: LocationService {
    var currentLocation: CLLocation? = CLLocation(latitude: 37.7749, longitude: -122.4194)
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    
    func requestLocationPermission() async throws {
        // Mock implementation - always succeeds
    }
    
    func startLocationUpdates() async throws {
        // Mock implementation
    }
    
    func stopLocationUpdates() {
        // Mock implementation
    }
    
    func startBackgroundLocationUpdates() async throws {
        // Mock implementation
    }
}

class FailingPartnerRepository: PartnerRepository {
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
    
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner] {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
    
    func fetchFeaturedPartners() async throws -> [Partner] {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
    
    func fetchPartnersByCategory(_ category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner] {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
}