//
//  MockPartnerRepository.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import MapKit
import CoreLocation

/// Mock implementation of PartnerRepository for development and testing
final class MockPartnerRepository: PartnerRepository {
    
    private let mockPartners: [Partner] = [
        Partner(
            name: "Bella Vista Restaurant",
            category: .restaurant,
            description: "Authentic Italian cuisine with fresh ingredients and traditional recipes",
            address: Address(
                street: "123 Main Street",
                city: "San Francisco",
                state: "CA",
                postalCode: "94102",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1 (415) 555-0123",
            email: "info@bellavista.com",
            heroImageURL: URL(string: "https://example.com/bella-vista-hero.jpg"),
            logoURL: URL(string: "https://example.com/bella-vista-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.8,
            reviewCount: 127,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "22:00"),
                .tuesday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "22:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "22:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "22:00"),
                .friday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "23:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "23:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "12:00", closeTime: "21:00")
            ],
            deliveryRadius: 5.0,
            minimumOrderAmount: 1500, // $15.00
            estimatedDeliveryTime: 25
        ),
        
        Partner(
            name: "Fresh Market",
            category: .grocery,
            description: "Organic groceries, fresh produce, and everyday essentials",
            address: Address(
                street: "456 Oak Avenue",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            phoneNumber: "+1 (415) 555-0456",
            email: "hello@freshmarket.com",
            heroImageURL: URL(string: "https://example.com/fresh-market-hero.jpg"),
            logoURL: URL(string: "https://example.com/fresh-market-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.6,
            reviewCount: 89,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
                .tuesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
                .friday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "22:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "21:00")
            ],
            deliveryRadius: 7.0,
            minimumOrderAmount: 2000, // $20.00
            estimatedDeliveryTime: 15
        ),
        
        Partner(
            name: "City Pharmacy",
            category: .pharmacy,
            description: "Full-service pharmacy with prescription medications and health products",
            address: Address(
                street: "789 Pine Street",
                city: "San Francisco",
                state: "CA",
                postalCode: "94104",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7949, longitude: -122.3994),
            phoneNumber: "+1 (415) 555-0789",
            email: "contact@citypharmacy.com",
            heroImageURL: URL(string: "https://example.com/city-pharmacy-hero.jpg"),
            logoURL: URL(string: "https://example.com/city-pharmacy-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.9,
            reviewCount: 203,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .tuesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .friday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "09:00", closeTime: "18:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "17:00")
            ],
            deliveryRadius: 3.0,
            minimumOrderAmount: 1000, // $10.00
            estimatedDeliveryTime: 10
        ),
        
        Partner(
            name: "Tech Gadgets Store",
            category: .retail,
            description: "Latest electronics, gadgets, and tech accessories",
            address: Address(
                street: "321 Market Street",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4294),
            phoneNumber: "+1 (415) 555-0321",
            email: "support@techgadgets.com",
            heroImageURL: URL(string: "https://example.com/tech-gadgets-hero.jpg"),
            logoURL: URL(string: "https://example.com/tech-gadgets-logo.jpg"),
            isVerified: false,
            isActive: true,
            rating: 4.3,
            reviewCount: 67,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "19:00"),
                .tuesday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "19:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "19:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "19:00"),
                .friday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "18:00")
            ],
            deliveryRadius: 4.0,
            minimumOrderAmount: 5000, // $50.00
            estimatedDeliveryTime: 45
        ),
        
        Partner(
            name: "Corner Convenience",
            category: .convenience,
            description: "24/7 convenience store with snacks, drinks, and daily necessities",
            address: Address(
                street: "654 Mission Street",
                city: "San Francisco",
                state: "CA",
                postalCode: "94106",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7549, longitude: -122.4394),
            phoneNumber: "+1 (415) 555-0654",
            email: "info@cornerconvenience.com",
            heroImageURL: URL(string: "https://example.com/corner-convenience-hero.jpg"),
            logoURL: URL(string: "https://example.com/corner-convenience-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.1,
            reviewCount: 156,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59"),
                .tuesday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59"),
                .wednesday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59"),
                .thursday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59"),
                .friday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59"),
                .saturday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59"),
                .sunday: OpeningHours(isOpen: true, openTime: "00:00", closeTime: "23:59")
            ],
            deliveryRadius: 2.0,
            minimumOrderAmount: 500, // $5.00
            estimatedDeliveryTime: 20
        ),
        
        Partner(
            name: "Sakura Sushi",
            category: .restaurant,
            description: "Fresh sushi and Japanese cuisine made by expert chefs",
            address: Address(
                street: "987 Geary Boulevard",
                city: "San Francisco",
                state: "CA",
                postalCode: "94107",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7449, longitude: -122.4494),
            phoneNumber: "+1 (415) 555-0987",
            email: "orders@sakurasushi.com",
            heroImageURL: URL(string: "https://example.com/sakura-sushi-hero.jpg"),
            logoURL: URL(string: "https://example.com/sakura-sushi-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.7,
            reviewCount: 234,
            openingHours: [
                .monday: OpeningHours(isOpen: false),
                .tuesday: OpeningHours(isOpen: true, openTime: "17:00", closeTime: "22:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "17:00", closeTime: "22:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "17:00", closeTime: "22:00"),
                .friday: OpeningHours(isOpen: true, openTime: "17:00", closeTime: "23:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "17:00", closeTime: "23:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "17:00", closeTime: "22:00")
            ],
            deliveryRadius: 6.0,
            minimumOrderAmount: 2500, // $25.00
            estimatedDeliveryTime: 35
        ),
        
        Partner(
            name: "Green Valley Organic",
            category: .grocery,
            description: "100% organic produce, sustainable products, and eco-friendly goods",
            address: Address(
                street: "147 Valencia Street",
                city: "San Francisco",
                state: "CA",
                postalCode: "94108",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7349, longitude: -122.4594),
            phoneNumber: "+1 (415) 555-0147",
            email: "hello@greenvalleyorganic.com",
            heroImageURL: URL(string: "https://example.com/green-valley-hero.jpg"),
            logoURL: URL(string: "https://example.com/green-valley-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.5,
            reviewCount: 98,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .tuesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .friday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "09:00", closeTime: "19:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "09:00", closeTime: "18:00")
            ],
            deliveryRadius: 8.0,
            minimumOrderAmount: 3000, // $30.00
            estimatedDeliveryTime: 30
        ),
        
        Partner(
            name: "Express Pharmacy",
            category: .pharmacy,
            description: "Quick prescription fills and over-the-counter medications",
            address: Address(
                street: "258 Fillmore Street",
                city: "San Francisco",
                state: "CA",
                postalCode: "94109",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7249, longitude: -122.4694),
            phoneNumber: "+1 (415) 555-0258",
            email: "info@expresspharmacy.com",
            heroImageURL: URL(string: "https://example.com/express-pharmacy-hero.jpg"),
            logoURL: URL(string: "https://example.com/express-pharmacy-logo.jpg"),
            isVerified: true,
            isActive: true,
            rating: 4.4,
            reviewCount: 145,
            openingHours: [
                .monday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "21:00"),
                .tuesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "21:00"),
                .wednesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "21:00"),
                .thursday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "21:00"),
                .friday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "21:00"),
                .saturday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
                .sunday: OpeningHours(isOpen: true, openTime: "09:00", closeTime: "19:00")
            ],
            deliveryRadius: 4.0,
            minimumOrderAmount: 800, // $8.00
            estimatedDeliveryTime: 12
        )
    ]
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Filter partners within the region (simplified)
        let filteredPartners = mockPartners.filter { partner in
            let distance = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
                .distance(from: CLLocation(latitude: partner.location.latitude, longitude: partner.location.longitude))
            return distance <= 10000 // 10km radius
        }
        
        return filteredPartners
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        return mockPartners.first { $0.id == id }
    }
    
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        let partnersInRegion = try await fetchPartners(in: region)
        
        return partnersInRegion.filter { partner in
            partner.name.localizedCaseInsensitiveContains(query) ||
            partner.description.localizedCaseInsensitiveContains(query) ||
            partner.category.displayName.localizedCaseInsensitiveContains(query)
        }
    }
    
    func fetchFeaturedPartners() async throws -> [Partner] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000) // 400ms
        
        // Return partners with high ratings as featured
        return mockPartners.filter { $0.rating >= 4.5 }.shuffled()
    }
    
    func fetchPartnersByCategory(_ category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        let partnersInRegion = try await fetchPartners(in: region)
        return partnersInRegion.filter { $0.category == category }
    }
}