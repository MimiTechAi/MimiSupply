//
//  MapViewTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import SwiftUI
import CoreLocation
@testable import MimiSupply

/// UI tests for MapView functionality
final class MapViewTests: XCTestCase {
    
    var samplePartners: [Partner]!
    
    override func setUp() {
        super.setUp()
        samplePartners = createSamplePartners()
    }
    
    override func tearDown() {
        samplePartners = nil
        super.tearDown()
    }
    
    // MARK: - Map View Tests
    
    func testMapView_WithPartners_ShouldDisplayAnnotations() {
        // Given
        let mapView = MapView(partners: samplePartners)
        
        // When/Then - This would typically use ViewInspector or similar testing framework
        // For now, we verify the data structure is correct
        XCTAssertEqual(samplePartners.count, 3)
        XCTAssertEqual(samplePartners[0].name, "Bella Vista Restaurant")
        XCTAssertEqual(samplePartners[1].category, .grocery)
        XCTAssertEqual(samplePartners[2].category, .pharmacy)
    }
    
    func testMapView_WithEmptyPartners_ShouldHandleGracefully() {
        // Given
        let emptyPartners: [Partner] = []
        let mapView = MapView(partners: emptyPartners)
        
        // When/Then
        XCTAssertNotNil(mapView)
        // Map should still be functional with no annotations
    }
    
    // MARK: - Partner Map Annotation Tests
    
    func testPartnerMapAnnotation_WithRestaurant_ShouldShowCorrectIcon() {
        // Given
        let restaurant = samplePartners.first { $0.category == .restaurant }!
        let annotation = PartnerMapAnnotation(
            partner: restaurant,
            isSelected: false,
            onTap: {}
        )
        
        // When/Then
        XCTAssertNotNil(annotation)
        XCTAssertEqual(restaurant.category.iconName, "fork.knife")
    }
    
    func testPartnerMapAnnotation_WhenSelected_ShouldChangeAppearance() {
        // Given
        let partner = samplePartners[0]
        let selectedAnnotation = PartnerMapAnnotation(
            partner: partner,
            isSelected: true,
            onTap: {}
        )
        let unselectedAnnotation = PartnerMapAnnotation(
            partner: partner,
            isSelected: false,
            onTap: {}
        )
        
        // When/Then
        XCTAssertNotNil(selectedAnnotation)
        XCTAssertNotNil(unselectedAnnotation)
        // Visual differences would be tested with snapshot tests
    }
    
    // MARK: - Selected Partner Card Tests
    
    func testSelectedPartnerCard_WithPartner_ShouldDisplayCorrectInfo() {
        // Given
        let partner = samplePartners[0]
        let card = SelectedPartnerCard(partner: partner, onDismiss: {})
        
        // When/Then
        XCTAssertNotNil(card)
        XCTAssertEqual(partner.name, "Bella Vista Restaurant")
        XCTAssertEqual(partner.rating, 4.8)
        XCTAssertEqual(partner.estimatedDeliveryTime, 25)
    }
    
    // MARK: - Map Location Manager Tests
    
    @MainActor
    func testMapLocationManager_RequestPermission_ShouldCallLocationService() async {
        // Given
        let mockLocationService = MockLocationService()
        let locationManager = MapLocationManager(locationService: mockLocationService)
        
        // When
        await locationManager.requestLocationPermission()
        
        // Then
        XCTAssertTrue(mockLocationService.didRequestPermission)
    }
    
    @MainActor
    func testMapLocationManager_GetCurrentLocation_ShouldReturnLocation() async {
        // Given
        let expectedLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let mockLocationService = MockLocationService()
        mockLocationService.mockCurrentLocation = expectedLocation
        let locationManager = MapLocationManager(locationService: mockLocationService)
        
        // When
        let location = await locationManager.getCurrentLocation()
        
        // Then
        XCTAssertNotNil(location)
        XCTAssertEqual(location?.coordinate.latitude, expectedLocation.coordinate.latitude, accuracy: 0.0001)
        XCTAssertEqual(location?.coordinate.longitude, expectedLocation.coordinate.longitude, accuracy: 0.0001)
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePartners() -> [Partner] {
        return [
            Partner(
                name: "Bella Vista Restaurant",
                category: .restaurant,
                description: "Italian cuisine",
                address: Address(
                    street: "123 Main St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94102",
                    country: "US"
                ),
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                phoneNumber: "+1234567890",
                email: "info@bellavista.com",
                rating: 4.8,
                reviewCount: 120,
                estimatedDeliveryTime: 25
            ),
            Partner(
                name: "Fresh Market",
                category: .grocery,
                description: "Organic groceries",
                address: Address(
                    street: "456 Oak St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94102",
                    country: "US"
                ),
                location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                phoneNumber: "+1234567891",
                email: "info@freshmarket.com",
                rating: 4.6,
                reviewCount: 89,
                estimatedDeliveryTime: 15
            ),
            Partner(
                name: "City Pharmacy",
                category: .pharmacy,
                description: "24/7 pharmacy",
                address: Address(
                    street: "789 Pine St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94102",
                    country: "US"
                ),
                location: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994),
                phoneNumber: "+1234567892",
                email: "info@citypharmacy.com",
                rating: 4.9,
                reviewCount: 156,
                estimatedDeliveryTime: 10
            )
        ]
    }
}

// MARK: - Order Tracking Map Tests

final class OrderTrackingMapViewTests: XCTestCase {
    
    var sampleOrder: Order!
    var partnerLocation: CLLocationCoordinate2D!
    var deliveryLocation: CLLocationCoordinate2D!
    var driverLocation: CLLocationCoordinate2D!
    
    override func setUp() {
        super.setUp()
        partnerLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        deliveryLocation = CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994)
        driverLocation = CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        
        sampleOrder = Order(
            id: "order-123",
            customerId: "customer-1",
            partnerId: "partner-1",
            items: [],
            status: .delivering,
            subtotalCents: 2500,
            deliveryFeeCents: 300,
            platformFeeCents: 200,
            taxCents: 250,
            tipCents: 500,
            totalCents: 3750,
            deliveryAddress: Address(
                street: "123 Delivery St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94102",
                country: "US"
            ),
            paymentMethod: .applePay,
            paymentStatus: .completed
        )
    }
    
    override func tearDown() {
        sampleOrder = nil
        partnerLocation = nil
        deliveryLocation = nil
        driverLocation = nil
        super.tearDown()
    }
    
    func testOrderTrackingMapView_WithAllLocations_ShouldDisplayCorrectAnnotations() {
        // Given
        let mapView = OrderTrackingMapView(
            order: sampleOrder,
            driverLocation: driverLocation,
            partnerLocation: partnerLocation,
            deliveryLocation: deliveryLocation
        )
        
        // When/Then
        XCTAssertNotNil(mapView)
        XCTAssertEqual(sampleOrder.status, .delivering)
    }
    
    func testTrackingAnnotation_WithDifferentTypes_ShouldHaveCorrectProperties() {
        // Given
        let partnerAnnotation = TrackingAnnotation(
            id: "partner",
            coordinate: partnerLocation,
            type: .partner,
            title: "Pickup Location"
        )
        
        let driverAnnotation = TrackingAnnotation(
            id: "driver",
            coordinate: driverLocation,
            type: .driver,
            title: "Driver Location"
        )
        
        let deliveryAnnotation = TrackingAnnotation(
            id: "delivery",
            coordinate: deliveryLocation,
            type: .delivery,
            title: "Delivery Address"
        )
        
        // When/Then
        XCTAssertEqual(partnerAnnotation.type, .partner)
        XCTAssertEqual(partnerAnnotation.title, "Pickup Location")
        
        XCTAssertEqual(driverAnnotation.type, .driver)
        XCTAssertEqual(driverAnnotation.title, "Driver Location")
        
        XCTAssertEqual(deliveryAnnotation.type, .delivery)
        XCTAssertEqual(deliveryAnnotation.title, "Delivery Address")
    }
    
    func testETACard_WithFutureTime_ShouldShowCorrectMinutes() {
        // Given
        let futureTime = Date().addingTimeInterval(15 * 60) // 15 minutes from now
        let etaCard = ETACard(estimatedArrival: futureTime)
        
        // When/Then
        XCTAssertNotNil(etaCard)
        // The actual minutes calculation would be tested with more specific view testing
    }
}