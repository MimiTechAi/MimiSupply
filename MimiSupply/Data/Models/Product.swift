//
//  Product.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Product model representing items available for purchase from partners
struct Product: Codable, Sendable, Identifiable, Hashable, Equatable {
    let id: String
    var partnerId: String
    var name: String
    var description: String
    var priceCents: Int
    var originalPriceCents: Int?
    var category: ProductCategory
    var imageURLs: [URL]
    var imageAssetName: String?   // NEU
    
    var isAvailable: Bool
    var stockQuantity: Int?
    var nutritionInfo: NutritionInfo?
    var allergens: [Allergen]
    var tags: [String]
    var weight: Measurement<UnitMass>?
    var dimensions: ProductDimensions?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        partnerId: String,
        name: String,
        description: String,
        priceCents: Int,
        originalPriceCents: Int? = nil,
        category: ProductCategory,
        imageAssetName: String? = nil, // NEU
        imageURLs: [URL] = [],
        isAvailable: Bool = true,
        stockQuantity: Int? = nil,
        nutritionInfo: NutritionInfo? = nil,
        allergens: [Allergen] = [],
        tags: [String] = [],
        weight: Measurement<UnitMass>? = nil,
        dimensions: ProductDimensions? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.partnerId = partnerId
        self.name = name
        self.description = description
        self.priceCents = priceCents
        self.originalPriceCents = originalPriceCents
        self.category = category
        self.imageAssetName = imageAssetName      // NEU
        self.imageURLs = imageURLs
        self.isAvailable = isAvailable
        self.stockQuantity = stockQuantity
        self.nutritionInfo = nutritionInfo
        self.allergens = allergens
        self.tags = tags
        self.weight = weight
        self.dimensions = dimensions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Formatted price string
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(priceCents) / 100.0)) ?? "$0.00"
    }
    
    /// Whether the product is on sale
    var isOnSale: Bool {
        guard let originalPrice = originalPriceCents else { return false }
        return priceCents < originalPrice
    }
}

/// Product categories for organization and filtering
enum ProductCategory: String, CaseIterable, Codable, Sendable {
    case food
    case beverages
    case medicine
    case personalCare
    case household
    case electronics
    case clothing
    case books
    case healthcare
    case fashion
    case homeAndGarden
    case sports
    case beauty
    case toys
    case other
    
    var displayName: String {
        switch self {
        case .food:
            return "Food"
        case .beverages:
            return "Beverages"
        case .medicine:
            return "Medicine"
        case .personalCare:
            return "Personal Care"
        case .household:
            return "Household"
        case .electronics:
            return "Electronics"
        case .clothing:
            return "Clothing"
        case .books:
            return "Books"
        case .healthcare:
            return "Healthcare"
        case .fashion:
            return "Fashion"
        case .homeAndGarden:
            return "Home & Garden"
        case .sports:
            return "Sports"
        case .beauty:
            return "Beauty"
        case .toys:
            return "Toys"
        case .other:
            return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .food:
            return "fork.knife"
        case .beverages:
            return "cup.and.saucer"
        case .medicine:
            return "pills"
        case .personalCare:
            return "heart"
        case .household:
            return "house"
        case .electronics:
            return "iphone"
        case .clothing:
            return "tshirt"
        case .books:
            return "book"
        case .healthcare:
            return "cross.case"
        case .fashion:
            return "shirt"
        case .homeAndGarden:
            return "leaf"
        case .sports:
            return "figure.run"
        case .beauty:
            return "sparkles"
        case .toys:
            return "gamecontroller"
        case .other:
            return "tag"
        }
    }
    
    /// German products for this category
    var germanProducts: [Product] {
        switch self {
        case .food:
            return GermanProductData.mcdonaldsProducts + GermanProductData.reweProducts
        case .healthcare, .medicine:
            return GermanProductData.docMorrisProducts
        case .electronics:
            return GermanProductData.mediaMarktProducts
        default:
            return []
        }
    }
}

// NutritionInfo, Allergen, and ProductDimensions are defined in MissingTypes.swift

// MARK: - Mock Data Extensions
extension Product {
    static let mockProducts: [Product] = [
        Product(
            partnerId: "partner1",
            name: "Margherita Pizza",
            description: "Classic pizza with fresh mozzarella, tomato sauce, and basil",
            priceCents: 1299,
            category: .food,
            imageURLs: [],
            isAvailable: true,
            nutritionInfo: NutritionInfo(
                calories: 280,
                protein: 12.0,
                carbohydrates: 36.0,
                fat: 10.0,
                fiber: 2.0,
                sugar: 4.0,
                sodium: 640.0
            ),
            allergens: [.wheat, .milk],
            tags: ["vegetarian", "popular"]
        ),
        Product(
            partnerId: "partner1",
            name: "Caesar Salad",
            description: "Crisp romaine lettuce with parmesan cheese and caesar dressing",
            priceCents: 899,
            originalPriceCents: 1099,
            category: .food,
            imageURLs: [],
            isAvailable: true,
            nutritionInfo: NutritionInfo(
                calories: 180,
                protein: 8.0,
                carbohydrates: 12.0,
                fat: 12.0,
                fiber: 4.0,
                sugar: 3.0,
                sodium: 480.0
            ),
            allergens: [.milk],
            tags: ["healthy", "salad"]
        ),
        Product(
            partnerId: "partner2",
            name: "Organic Bananas",
            description: "Fresh organic bananas, perfect for snacking or smoothies",
            priceCents: 299,
            category: .food,
            imageURLs: [],
            isAvailable: true,
            stockQuantity: 50,
            nutritionInfo: NutritionInfo(
                calories: 105,
                protein: 1.3,
                carbohydrates: 27.0,
                fat: 0.3,
                fiber: 3.1,
                sugar: 14.4,
                sodium: 1.0
            ),
            allergens: [],
            tags: ["organic", "fruit", "healthy"]
        )
    ]
}