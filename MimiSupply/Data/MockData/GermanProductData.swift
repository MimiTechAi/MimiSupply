//
//  GermanProductData.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation

/// German product data for realistic demo experience
struct GermanProductData {
    
    // MARK: - McDonald's Products
    static let mcdonaldsProducts: [Product] = [
        createProduct(
            partnerId: "mcdonalds_berlin_mitte",
            name: "Big Mac",
            description: "Zwei Rindfleisch-Patties, Spezialsoße, Salat, Käse, Gurken, Zwiebeln auf einem Sesam-Brötchen",
            priceCents: 549,
            category: .food,
            nutritionalInfo: NutritionInfo(
                calories: 563,
                protein: 25.0,
                carbohydrates: 45.0,
                fat: 33.0,
                fiber: 3.0,
                sugar: 5.0,
                sodium: 1040.0
            ),
            allergens: [.wheat, .milk],
            tags: ["burger", "bestseller"]
        ),
        createProduct(
            partnerId: "mcdonalds_berlin_mitte",
            name: "McNuggets 6 Stück",
            description: "Zarte Hähnchen-Nuggets mit knuspriger Panade, serviert mit Ihrer Wahl der Soße",
            priceCents: 399,
            category: .food,
            nutritionalInfo: NutritionInfo(
                calories: 259,
                protein: 13.0,
                carbohydrates: 16.0,
                fat: 16.0,
                fiber: 1.0,
                sugar: 0.0,
                sodium: 540.0
            ),
            allergens: [.wheat],
            tags: ["chicken", "popular"]
        ),
        createProduct(
            partnerId: "mcdonalds_berlin_mitte",
            name: "McFlurry Oreo",
            description: "Cremiges Softeis mit knusprigen Oreo-Keksstückchen",
            priceCents: 279,
            category: .food,
            nutritionalInfo: NutritionInfo(
                calories: 327,
                protein: 8.0,
                carbohydrates: 51.0,
                fat: 11.0,
                fiber: 1.0,
                sugar: 45.0,
                sodium: 180.0
            ),
            allergens: [.milk, .wheat],
            tags: ["dessert", "ice cream"]
        ),
        createProduct(
            partnerId: "mcdonalds_berlin_mitte",
            name: "Pommes Frites groß",
            description: "Goldgelbe, knusprige Pommes frites mit Meersalz",
            priceCents: 249,
            category: .food,
            nutritionalInfo: NutritionInfo(
                calories: 365,
                protein: 4.0,
                carbohydrates: 43.0,
                fat: 19.0,
                fiber: 4.0,
                sugar: 0.0,
                sodium: 246.0
            ),
            allergens: [],
            tags: ["side", "popular"]
        )
    ]
    
    // MARK: - REWE Products
    static let reweProducts: [Product] = [
        Product(
            partnerId: "rewe_alexanderplatz",
            name: "REWE Bio Vollmilch 3,8%",
            description: "Frische Bio-Vollmilch aus kontrolliert biologischer Erzeugung, 1 Liter",
            priceCents: 129,
            category: .food,
            nutritionInfo: NutritionInfo(
                calories: 64,
                protein: 3.4,
                carbohydrates: 4.8,
                fat: 3.8,
                fiber: 0.0,
                sugar: 4.8,
                sodium: 50.0
            ),
            allergens: [.milk],
            tags: ["bio", "dairy", "fresh"]
        ),
        Product(
            partnerId: "rewe_alexanderplatz",
            name: "Bananen",
            description: "Frische Bananen aus fairem Handel, perfekt für Smoothies oder als Snack",
            priceCents: 189,
            category: .food,
            nutritionInfo: NutritionInfo(
                calories: 89,
                protein: 1.1,
                carbohydrates: 23.0,
                fat: 0.3,
                fiber: 2.6,
                sugar: 12.0,
                sodium: 1.0
            ),
            allergens: [],
            tags: ["fruit", "healthy", "fairtrade"]
        ),
        Product(
            partnerId: "rewe_alexanderplatz",
            name: "REWE Bio Haferflocken",
            description: "Kernige Bio-Haferflocken aus deutschem Anbau, ideal für Müsli und Porridge",
            priceCents: 199,
            category: .food,
            nutritionInfo: NutritionInfo(
                calories: 379,
                protein: 11.7,
                carbohydrates: 60.0,
                fat: 7.7,
                fiber: 10.0,
                sugar: 1.3,
                sodium: 6.0
            ),
            allergens: [],
            tags: ["bio", "breakfast", "healthy"]
        ),
        Product(
            partnerId: "rewe_alexanderplatz",
            name: "REWE Beste Wahl Joghurt Natur",
            description: "Cremiger Naturjoghurt 1,5% Fett, ohne Zusätze, 500g Becher",
            priceCents: 79,
            category: .food,
            nutritionInfo: NutritionInfo(
                calories: 62,
                protein: 4.3,
                carbohydrates: 4.7,
                fat: 1.5,
                fiber: 0.0,
                sugar: 4.7,
                sodium: 60.0
            ),
            allergens: [.milk],
            tags: ["dairy", "healthy", "natural"]
        )
    ]
    
    // MARK: - DocMorris Products
    static let docMorrisProducts: [Product] = [
        Product(
            id: "docmorris_aspirin_001",
            partnerId: "docmorris_berlin",
            name: "Aspirin 500mg",
            description: "Bewährtes Schmerzmittel gegen Kopfschmerzen und Fieber, 20 Tabletten",
            priceCents: 459,
            category: .healthcare,
            isAvailable: true,
            stockQuantity: 25,
            tags: ["pain relief", "otc", "headache"]
        ),
        Product(
            id: "docmorris_ibuprofen_001",
            partnerId: "docmorris_berlin",
            name: "Ibuprofen 400mg",
            description: "Entzündungshemmendes Schmerzmittel, 20 Filmtabletten",
            priceCents: 389,
            category: .healthcare,
            isAvailable: true,
            stockQuantity: 30,
            tags: ["pain relief", "anti-inflammatory", "otc"]
        ),
        Product(
            id: "docmorris_vitamind_001",
            partnerId: "docmorris_berlin",
            name: "Vitamin D3 1000 I.E.",
            description: "Nahrungsergänzungsmittel zur Unterstützung des Immunsystems, 60 Kapseln",
            priceCents: 899,
            category: .healthcare,
            isAvailable: true,
            stockQuantity: 15,
            tags: ["vitamins", "immune support", "supplement"]
        ),
        Product(
            id: "docmorris_cough_001",
            partnerId: "docmorris_berlin",
            name: "Hustensaft Efeu",
            description: "Pflanzlicher Hustensaft mit Efeu-Extrakt, 100ml Flasche",
            priceCents: 679,
            category: .healthcare,
            isAvailable: true,
            stockQuantity: 12,
            tags: ["cough", "herbal", "natural"]
        )
    ]
    
    // MARK: - MediaMarkt Products
    static let mediaMarktProducts: [Product] = [
        Product(
            partnerId: "mediamarkt_alexanderplatz",
            name: "iPhone 15 128GB",
            description: "Das neueste iPhone mit A17 Pro Chip, fortschrittlicher Kamera und USB-C",
            priceCents: 94900,
            category: .electronics,
            isAvailable: true,
            stockQuantity: 5,
            tags: ["smartphone", "apple", "premium"]
        ),
        Product(
            partnerId: "mediamarkt_alexanderplatz",
            name: "Samsung Galaxy Buds Pro",
            description: "Kabellose In-Ear-Kopfhörer mit aktiver Geräuschunterdrückung",
            priceCents: 19900,
            category: .electronics,
            isAvailable: true,
            stockQuantity: 12,
            tags: ["headphones", "wireless", "samsung"]
        ),
        Product(
            partnerId: "mediamarkt_alexanderplatz",
            name: "Nintendo Switch OLED",
            description: "Gaming-Konsole mit 7-Zoll OLED-Display für Zuhause und unterwegs",
            priceCents: 34900,
            category: .electronics,
            isAvailable: true,
            stockQuantity: 8,
            tags: ["gaming", "nintendo", "portable"]
        ),
        Product(
            partnerId: "mediamarkt_alexanderplatz",
            name: "Sony WH-1000XM5",
            description: "Premium Over-Ear-Kopfhörer mit branchenführender Geräuschunterdrückung",
            priceCents: 39900,
            category: .electronics,
            isAvailable: true,
            stockQuantity: 6,
            tags: ["headphones", "sony", "premium", "noise-cancelling"]
        )
    ]
    
    // MARK: - All Products
    static var allProducts: [Product] {
        return mcdonaldsProducts + reweProducts + docMorrisProducts + mediaMarktProducts
    }
    
    // MARK: - Helper Methods
    static func getProducts(for partnerId: String) -> [Product] {
        return allProducts.filter { $0.partnerId == partnerId }
    }
    
    static func searchProducts(_ query: String) -> [Product] {
        let lowercaseQuery = query.lowercased()
        return allProducts.filter { product in
            product.name.lowercased().contains(lowercaseQuery) ||
            product.description.lowercased().contains(lowercaseQuery) ||
            product.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    // MARK: - Private Helper
    private static func createProduct(
        id: String = UUID().uuidString,
        partnerId: String,
        name: String,
        description: String,
        priceCents: Int,
        category: ProductCategory,
        nutritionalInfo: NutritionInfo? = nil,
        allergens: [Allergen] = [],
        tags: [String] = []
    ) -> Product {
        return Product(
            id: id,
            partnerId: partnerId,
            name: name,
            description: description,
            priceCents: priceCents,
            category: category,
            nutritionInfo: nutritionalInfo,
            allergens: allergens,
            tags: tags
        )
    }
}