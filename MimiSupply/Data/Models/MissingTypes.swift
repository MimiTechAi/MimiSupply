//
//  MissingTypes.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation

// MARK: - Authentication Types
// Authentication types are now defined in AuthenticationService.swift

// MARK: - Service Protocol Stubs
// Note: Main service protocols are defined in their respective files
// KeychainServiceImpl is defined in KeychainServiceImpl.swift

// MARK: - Extended UserProfile for Authentication
// UserProfile properties are now defined directly in the UserProfile struct

// MARK: - Product Related Types

/// Nutrition information for products
struct NutritionInfo: Codable, Sendable, Hashable, Equatable {
    let calories: Int?
    let protein: Double? // grams
    let carbohydrates: Double? // grams
    let fat: Double? // grams
    let fiber: Double? // grams
    let sugar: Double? // grams
    let sodium: Double? // milligrams
    let servingSize: String?
    
    init(
        calories: Int? = nil,
        protein: Double? = nil,
        carbohydrates: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        servingSize: String? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
    }
}

// MARK: - Analytics Types

struct PartnerAnalytics: Codable {
    let totalRevenue: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let customerCount: Int
    let timeRange: TimeRange
    
    // Additional fields for compatibility
    let totalRevenueCents: Int
    let revenueChangePercent: Double
    let ordersChangePercent: Double
    let averageOrderValueCents: Int
    let aovChangePercent: Double
    let averageRating: Double
    let ratingChangePercent: Double
    
    init(
        totalRevenue: Double,
        totalOrders: Int,
        averageOrderValue: Double,
        customerCount: Int,
        timeRange: TimeRange,
        totalRevenueCents: Int? = nil,
        revenueChangePercent: Double = 0,
        ordersChangePercent: Double = 0,
        averageOrderValueCents: Int? = nil,
        aovChangePercent: Double = 0,
        averageRating: Double = 0,
        ratingChangePercent: Double = 0
    ) {
        self.totalRevenue = totalRevenue
        self.totalOrders = totalOrders
        self.averageOrderValue = averageOrderValue
        self.customerCount = customerCount
        self.timeRange = timeRange
        self.totalRevenueCents = totalRevenueCents ?? Int(totalRevenue * 100)
        self.revenueChangePercent = revenueChangePercent
        self.ordersChangePercent = ordersChangePercent
        self.averageOrderValueCents = averageOrderValueCents ?? Int(averageOrderValue * 100)
        self.aovChangePercent = aovChangePercent
        self.averageRating = averageRating
        self.ratingChangePercent = ratingChangePercent
    }
}

struct OrdersDataPoint: Codable {
    let date: Date
    let orderCount: Int
}

struct TopProductData: Codable {
    let productId: String
    let productName: String
    let orderCount: Int
    let revenueCents: Int
}

/// Physical dimensions of products
struct ProductDimensions: Codable, Sendable, Hashable, Equatable {
    let length: Double // centimeters
    let width: Double // centimeters
    let height: Double // centimeters
    let weight: Double // grams
    
    init(length: Double, width: Double, height: Double, weight: Double) {
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
    }
    
    var volume: Double {
        return length * width * height
    }
}

// MARK: - Payment Status is now defined in Order.swift

/// Food allergen types
enum Allergen: String, Codable, Sendable, CaseIterable, Hashable {
    case milk = "milk"
    case eggs = "eggs"
    case fish = "fish"
    case shellfish = "shellfish"
    case treeNuts = "tree_nuts"
    case peanuts = "peanuts"
    case wheat = "wheat"
    case soybeans = "soybeans"
    case sesame = "sesame"
    
    var displayName: String {
        switch self {
        case .milk: return "Milk"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .treeNuts: return "Tree Nuts"
        case .peanuts: return "Peanuts"
        case .wheat: return "Wheat"
        case .soybeans: return "Soybeans"
        case .sesame: return "Sesame"
        }
    }
}

// MARK: - Removed duplicate model definitions
// DriverLocation and PartnerStats are defined canonically in:
// - Data/Models/Driver.swift (DriverLocation: Codable, Sendable)
// - Data/Models/PartnerStats.swift (PartnerStats: Codable, Sendable)
// Avoid redefining models here to prevent type conflicts.