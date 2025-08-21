//
//  Partner.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation
import CoreLocation

// MARK: - Partner Model
struct Partner: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let category: PartnerCategory
    let description: String
    let address: Address
    let location: CLLocationCoordinate2D
    let phoneNumber: String?
    let email: String?
    let heroImageURL: URL?
    let logoURL: URL?
    let isVerified: Bool
    let isActive: Bool
    let rating: Double
    let reviewCount: Int
    let openingHours: [WeekDay: OpeningHours]
    let deliveryRadius: Double
    let minimumOrderAmount: Int // in cents
    let estimatedDeliveryTime: Int // in minutes
    let createdAt: Date
    let updatedAt: Date
    
    // MARK: - Computed Properties
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
    
    var formattedMinimumOrder: String {
        String(format: "$%.2f", Double(minimumOrderAmount) / 100.0)
    }
    
    var isOpenNow: Bool {
        let now = Date()
        let calendar = Calendar.current
        let weekday = WeekDay.from(calendar.component(.weekday, from: now))
        
        guard let hours = openingHours[weekday] else { return false }
        return hours.isOpenAt(now)
    }
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        name: String,
        category: PartnerCategory,
        description: String,
        address: Address,
        location: CLLocationCoordinate2D,
        phoneNumber: String? = nil,
        email: String? = nil,
        heroImageURL: URL? = nil,
        logoURL: URL? = nil,
        isVerified: Bool = false,
        isActive: Bool = true,
        rating: Double = 0.0,
        reviewCount: Int = 0,
        openingHours: [WeekDay: OpeningHours] = [:],
        deliveryRadius: Double = 5.0,
        minimumOrderAmount: Int = 0,
        estimatedDeliveryTime: Int = 30,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.address = address
        self.location = location
        self.phoneNumber = phoneNumber
        self.email = email
        self.heroImageURL = heroImageURL
        self.logoURL = logoURL
        self.isVerified = isVerified
        self.isActive = isActive
        self.rating = rating
        self.reviewCount = reviewCount
        self.openingHours = openingHours
        self.deliveryRadius = deliveryRadius
        self.minimumOrderAmount = minimumOrderAmount
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Partner Category
enum PartnerCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case restaurant = "restaurant"
    case grocery = "grocery"
    case pharmacy = "pharmacy"
    case retail = "retail"
    case convenience = "convenience"
    case bakery = "bakery"
    case coffee = "coffee"
    case alcohol = "alcohol"
    case flowers = "flowers"
    case electronics = "electronics"
    
    var displayName: String {
        switch self {
        case .restaurant: return "Restaurant"
        case .grocery: return "Grocery"
        case .pharmacy: return "Pharmacy"
        case .retail: return "Retail"
        case .convenience: return "Convenience"
        case .bakery: return "Bakery"
        case .coffee: return "Coffee"
        case .alcohol: return "Alcohol"
        case .flowers: return "Flowers"
        case .electronics: return "Electronics"
        }
    }
    
    var iconName: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .grocery: return "cart"
        case .pharmacy: return "cross.case"
        case .retail: return "bag"
        case .convenience: return "building.2"
        case .bakery: return "birthday.cake"
        case .coffee: return "cup.and.saucer"
        case .alcohol: return "wineglass"
        case .flowers: return "leaf"
        case .electronics: return "tv"
        }
    }
}

// MARK: - Weekday
enum WeekDay: String, CaseIterable, Codable, Hashable, Sendable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"
    
    static func from(_ calendarWeekday: Int) -> WeekDay {
        // Calendar.component(.weekday) returns 1 for Sunday, 2 for Monday, etc.
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

extension WeekDay {
    var displayName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

// MARK: - Opening Hours
struct OpeningHours: Codable, Hashable, Sendable {
    let isOpen: Bool
    let openTime: String? // "09:00"
    let closeTime: String? // "22:00"
    
    init(isOpen: Bool, openTime: String? = nil, closeTime: String? = nil) {
        self.isOpen = isOpen
        self.openTime = openTime
        self.closeTime = closeTime
    }
    
    var displayText: String {
        if isOpen, let openTime = openTime, let closeTime = closeTime {
            return "\(openTime) - \(closeTime)"
        } else {
            return "Closed"
        }
    }
    
    func isOpenAt(_ date: Date) -> Bool {
        guard isOpen,
              let openTime = openTime,
              let closeTime = closeTime else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let currentTime = formatter.string(from: date)
        return currentTime >= openTime && currentTime <= closeTime
    }
}

// MARK: - Mock Data Extensions
extension Partner {
    static let mockPartners: [Partner] = [
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
            minimumOrderAmount: 1500,
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
            minimumOrderAmount: 2000,
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
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: 10
        )
    ]
}

// Note: CLLocationCoordinate2D extensions for Codable and Hashable 
// should be defined in a separate file to avoid conflicts

extension PartnerCategory {
    /// Premium/AI-generiertes Icon oder Symbolbild für jede Kategorie
    var premiumIconURL: URL? {
        switch self {
        case .restaurant:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-restaurant.png")
        case .grocery:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-grocery.png")
        case .pharmacy:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-pharmacy.png")
        case .retail:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-retail.png")
        case .convenience:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-convenience.png")
        case .bakery:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-bakery.png")
        case .coffee:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-coffee.png")
        case .alcohol:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-alcohol.png")
        case .flowers:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-flowers.png")
        case .electronics:
            return URL(string: "https://cdn.mimisupply.ai/premium/category-electronics.png")
        }
    }
}