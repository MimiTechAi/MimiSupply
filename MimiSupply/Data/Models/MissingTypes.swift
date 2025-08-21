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