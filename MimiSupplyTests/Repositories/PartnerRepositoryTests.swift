//
//  PartnerRepositoryTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import MapKit
@testable import MimiSupply

/// Unit tests for PartnerRepository
final class PartnerRepositoryTests: XCTestCase {
    
    var partnerRepository: PartnerRepository!
    var mockCloudKitService: MockCloudKitService!
    var mockCoreDataStack: MockCoreDataStack!
    
    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        mockCoreDataStack = MockCoreDataStack()
        
        partnerRepository = PartnerRepositoryImpl(
            cloudKitService: mockCloudKitService,
            coreDataStack: mockCoreDataStack
        )
    }
    
    override func tearDown() {
        partnerRepository = nil
        mockCoreDataStack = nil
        mockCloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Partners Tests
    
    func testFetchPartnersInRegionSuccess() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let testPartners = [
            createTestPartner(id: "partner-1", name: "Restaurant A"),
            createTestPartner(id: "partner-2", name: "Pharmacy B")
        ]
        mockCloudKitService.mockPartners = testPartners
        
        // When
        let partners = try await partnerRepository.fetchPartners(in: region)
        
        // Then
        XCTAssertEqual(partners.count, 2)
        XCTAssertTrue(partners.contains { $0.name == "Restaurant A" })
        XCTAssertTrue(partners.contains { $0.name == "Pharmacy B" })
        XCTAssertTrue(mockCoreDataStack.cachePartnersCalled)
    }
    
    func testFetchPartnersNetworkFailureUsesCache() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let cachedPartners = [createTestPartner(id: "cached-partner", name: "Cached Restaurant")]
        mockCoreDataStack.mockCachedPartners = cachedPartners
        mockCloudKitService.shouldThrowError = true
        
        // When
        let partners = try await partnerRepository.fetchPartners(in: region)
        
        // Then
        XCTAssertEqual(partners.count, 1)
        XCTAssertEqual(partners.first?.name, "Cached Restaurant")
        XCTAssertTrue(mockCoreDataStack.loadCachedPartnersCalled)
    }
    
    // MARK: - Fetch Single Partner Tests
    
    func testFetchPartnerByIdSuccess() async throws {
        // Given
        let partnerId = "test-partner-123"
        let testPartner = createTestPartner(id: partnerId, name: "Test Restaurant")
        mockCloudKitService.mockPartners = [testPartner]
        
        // When
        let partner = try await partnerRepository.fetchPartner(by: partnerId)
        
        // Then
        XCTAssertNotNil(partner)
        XCTAssertEqual(partner?.id, partnerId)
        XCTAssertEqual(partner?.name, "Test Restaurant")
    }
    
    func testFetchPartnerByIdNotFound() async throws {
        // Given
        let partnerId = "nonexistent-partner"
        mockCloudKitService.mockPartners = []
        
        // When
        let partner = try await partnerRepository.fetchPartner(by: partnerId)
        
        // Then
        XCTAssertNil(partner)
    }
    
    // MARK: - Search Partners Tests
    
    func testSearchPartnersSuccess() async throws {
        // Given
        let query = "pizza"
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let searchResults = [
            createTestPartner(id: "pizza-1", name: "Mario's Pizza"),
            createTestPartner(id: "pizza-2", name: "Pizza Palace")
        ]
        mockCloudKitService.mockSearchResults = searchResults
        
        // When
        let results = try await partnerRepository.searchPartners(query: query, in: region)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(mockCloudKitService.lastSearchQuery, query)
        XCTAssertTrue(results.allSatisfy { $0.name.lowercased().contains("pizza") })
    }
    
    func testSearchPartnersEmptyQuery() async throws {
        // Given
        let query = ""
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let allPartners = [
            createTestPartner(id: "partner-1", name: "Restaurant A"),
            createTestPartner(id: "partner-2", name: "Pharmacy B")
        ]
        mockCloudKitService.mockPartners = allPartners
        
        // When
        let results = try await partnerRepository.searchPartners(query: query, in: region)
        
        // Then
        XCTAssertEqual(results.count, 2)
    }
    
    // MARK: - Featured Partners Tests
    
    func testFetchFeaturedPartnersSuccess() async throws {
        // Given
        let featuredPartners = [
            createTestPartner(id: "featured-1", name: "Featured Restaurant", rating: 4.8),
            createTestPartner(id: "featured-2", name: "Featured Pharmacy", rating: 4.9)
        ]
        mockCloudKitService.mockPartners = featuredPartners
        
        // When
        let partners = try await partnerRepository.fetchFeaturedPartners()
        
        // Then
        XCTAssertEqual(partners.count, 2)
        XCTAssertTrue(partners.allSatisfy { $0.rating >= 4.5 })
    }
    
    // MARK: - Category-based Fetch Tests
    
    func testFetchPartnersByCategorySuccess() async throws {
        // Given
        let category = PartnerCategory.restaurant
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let restaurants = [
            createTestPartner(id: "restaurant-1", name: "Restaurant A", category: .restaurant),
            createTestPartner(id: "restaurant-2", name: "Restaurant B", category: .restaurant)
        ]
        let pharmacies = [
            createTestPartner(id: "pharmacy-1", name: "Pharmacy A", category: .pharmacy)
        ]
        
        mockCloudKitService.mockPartners = restaurants + pharmacies
        
        // When
        let results = try await partnerRepository.fetchPartnersByCategory(category, in: region)
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.category == .restaurant })
    }
    
    // MARK: - Partner Filtering Tests
    
    func testFilterPartnersByRating() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let partners = [
            createTestPartner(id: "high-rated", name: "High Rated", rating: 4.8),
            createTestPartner(id: "medium-rated", name: "Medium Rated", rating: 3.5),
            createTestPartner(id: "low-rated", name: "Low Rated", rating: 2.1)
        ]
        mockCloudKitService.mockPartners = partners
        
        // When
        let highRatedPartners = try await partnerRepository.fetchPartners(
            in: region,
            minRating: 4.0
        )
        
        // Then
        XCTAssertEqual(highRatedPartners.count, 1)
        XCTAssertEqual(highRatedPartners.first?.name, "High Rated")
    }
    
    func testFilterPartnersByDeliveryTime() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let partners = [
            createTestPartner(id: "fast", name: "Fast Delivery", estimatedDeliveryTime: 15),
            createTestPartner(id: "medium", name: "Medium Delivery", estimatedDeliveryTime: 35),
            createTestPartner(id: "slow", name: "Slow Delivery", estimatedDeliveryTime: 60)
        ]
        mockCloudKitService.mockPartners = partners
        
        // When
        let fastPartners = try await partnerRepository.fetchPartners(
            in: region,
            maxDeliveryTime: 30
        )
        
        // Then
        XCTAssertEqual(fastPartners.count, 1)
        XCTAssertEqual(fastPartners.first?.name, "Fast Delivery")
    }
    
    // MARK: - Partner Sorting Tests
    
    func testSortPartnersByRating() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let partners = [
            createTestPartner(id: "partner-1", name: "Partner A", rating: 3.5),
            createTestPartner(id: "partner-2", name: "Partner B", rating: 4.8),
            createTestPartner(id: "partner-3", name: "Partner C", rating: 4.2)
        ]
        mockCloudKitService.mockPartners = partners
        
        // When
        let sortedPartners = try await partnerRepository.fetchPartners(
            in: region,
            sortBy: .rating
        )
        
        // Then
        XCTAssertEqual(sortedPartners.count, 3)
        XCTAssertEqual(sortedPartners[0].rating, 4.8)
        XCTAssertEqual(sortedPartners[1].rating, 4.2)
        XCTAssertEqual(sortedPartners[2].rating, 3.5)
    }
    
    func testSortPartnersByDeliveryTime() async throws {
        // Given
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        let partners = [
            createTestPartner(id: "partner-1", name: "Partner A", estimatedDeliveryTime: 45),
            createTestPartner(id: "partner-2", name: "Partner B", estimatedDeliveryTime: 20),
            createTestPartner(id: "partner-3", name: "Partner C", estimatedDeliveryTime: 35)
        ]
        mockCloudKitService.mockPartners = partners
        
        // When
        let sortedPartners = try await partnerRepository.fetchPartners(
            in: region,
            sortBy: .deliveryTime
        )
        
        // Then
        XCTAssertEqual(sortedPartners.count, 3)
        XCTAssertEqual(sortedPartners[0].estimatedDeliveryTime, 20)
        XCTAssertEqual(sortedPartners[1].estimatedDeliveryTime, 35)
        XCTAssertEqual(sortedPartners[2].estimatedDeliveryTime, 45)
    }
    
    // MARK: - Distance-based Tests
    
    func testFetchNearbyPartners() async throws {
        // Given
        let userLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let maxDistance = 5.0 // 5km
        
        let nearbyPartner = createTestPartner(
            id: "nearby",
            name: "Nearby Restaurant",
            location: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195)
        )
        let farPartner = createTestPartner(
            id: "far",
            name: "Far Restaurant",
            location: CLLocationCoordinate2D(latitude: 37.8000, longitude: -122.4500)
        )
        
        mockCloudKitService.mockPartners = [nearbyPartner, farPartner]
        
        // When
        let nearbyPartners = try await partnerRepository.fetchNearbyPartners(
            from: userLocation,
            within: maxDistance
        )
        
        // Then
        XCTAssertEqual(nearbyPartners.count, 1)
        XCTAssertEqual(nearbyPartners.first?.name, "Nearby Restaurant")
    }
    
    // MARK: - Cache Management Tests
    
    func testCachePartnerData() async throws {
        // Given
        let partners = [
            createTestPartner(id: "partner-1", name: "Restaurant A"),
            createTestPartner(id: "partner-2", name: "Pharmacy B")
        ]
        
        // When
        try await partnerRepository.cachePartners(partners)
        
        // Then
        XCTAssertTrue(mockCoreDataStack.cachePartnersCalled)
        XCTAssertEqual(mockCoreDataStack.mockCachedPartners.count, 2)
    }
    
    func testLoadCachedPartners() async throws {
        // Given
        let cachedPartners = [createTestPartner(id: "cached", name: "Cached Restaurant")]
        mockCoreDataStack.mockCachedPartners = cachedPartners
        
        // When
        let partners = try await partnerRepository.getCachedPartners()
        
        // Then
        XCTAssertEqual(partners.count, 1)
        XCTAssertEqual(partners.first?.name, "Cached Restaurant")
        XCTAssertTrue(mockCoreDataStack.loadCachedPartnersCalled)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPartner(
        id: String = "test-partner",
        name: String = "Test Partner",
        category: PartnerCategory = .restaurant,
        location: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        rating: Double = 4.5,
        estimatedDeliveryTime: Int = 30
    ) -> Partner {
        return Partner(
            id: id,
            name: name,
            category: category,
            description: "Test description",
            address: Address(
                street: "123 Test Street",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "US"
            ),
            location: location,
            phoneNumber: "+1234567890",
            email: "test@example.com",
            heroImageURL: URL(string: "https://example.com/hero.jpg"),
            logoURL: URL(string: "https://example.com/logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: rating,
            reviewCount: 100,
            openingHours: [:],
            deliveryRadius: 5.0,
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: estimatedDeliveryTime,
            createdAt: Date()
        )
    }
}

// MARK: - Partner Sort Options

enum PartnerSortOption {
    case rating
    case deliveryTime
    case distance
    case alphabetical
}

// MARK: - Extended Partner Repository Protocol

protocol PartnerRepository {
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner]
    func fetchPartner(by id: String) async throws -> Partner?
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner]
    func fetchFeaturedPartners() async throws -> [Partner]
    func fetchPartnersByCategory(_ category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner]
    
    // Extended methods for comprehensive testing
    func fetchPartners(
        in region: MKCoordinateRegion,
        minRating: Double?,
        maxDeliveryTime: Int?,
        sortBy: PartnerSortOption?
    ) async throws -> [Partner]
    
    func fetchNearbyPartners(
        from location: CLLocationCoordinate2D,
        within distance: Double
    ) async throws -> [Partner]
    
    func cachePartners(_ partners: [Partner]) async throws
    func getCachedPartners() async throws -> [Partner]
}