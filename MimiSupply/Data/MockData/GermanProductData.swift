//
//  GermanProductData.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation

/// Realistic German product data for MimiSupply partners
struct GermanProductData {
    
    // MARK: - McDonald's Products
    static let mcdonaldsProducts: [Product] = [
        Product(
            partnerId: "mcdonalds-berlin-alexanderplatz",
            name: "Big Mac",
            description: "Zwei Rindfleisch-Patties, Spezialsoße, Salat, Käse, Gurken, Zwiebeln im Sesam-Bun",
            priceCents: 549, // €5.49
            category: .food,
            imageURLs: [
                URL(string: "https://cdn.mcdonalds.com/content/dam/sites/de/nfl/pdf/nutrition/big-mac-menu.jpg")!
            ],
            isAvailable: true,
            preparationTime: 8,
            tags: ["Burger", "Klassiker", "Rindfleisch"],
            nutritionalInfo: NutritionalInfo(
                calories: 563,
                protein: 25.2,
                carbs: 44.3,
                fat: 33.2,
                fiber: 3.5
            )
        ),
        
        Product(
            partnerId: "mcdonalds-berlin-alexanderplatz",
            name: "McNuggets 9er",
            description: "9 knusprige Hähnchen McNuggets aus 100% Hähnchenbrust",
            priceCents: 499, // €4.99
            category: .food,
            imageURLs: [
                URL(string: "https://cdn.mcdonalds.com/content/dam/sites/de/nfl/nutrition/mcnuggets-9.jpg")!
            ],
            isAvailable: true,
            preparationTime: 5,
            tags: ["Hähnchen", "Nuggets", "Knusprig"],
            nutritionalInfo: NutritionalInfo(
                calories: 385,
                protein: 23.0,
                carbs: 24.0,
                fat: 24.0,
                fiber: 0.0
            )
        ),
        
        Product(
            partnerId: "mcdonalds-berlin-alexanderplatz",
            name: "McCafé Latte",
            description: "Cremiger Milchkaffee mit Arabica-Bohnen",
            priceCents: 289, // €2.89
            category: .beverages,
            imageURLs: [
                URL(string: "https://cdn.mcdonalds.com/content/dam/sites/de/nfl/nutrition/mccafe-latte.jpg")!
            ],
            isAvailable: true,
            preparationTime: 3,
            tags: ["Kaffee", "McCafé", "Heiß"],
            nutritionalInfo: NutritionalInfo(
                calories: 142,
                protein: 8.1,
                carbs: 11.7,
                fat: 7.2,
                fiber: 0.0
            )
        ),
        
        Product(
            partnerId: "mcdonalds-berlin-alexanderplatz",
            name: "Pommes Frites große Portion",
            description: "Goldgelbe, knusprige Pommes Frites - große Portion",
            priceCents: 279, // €2.79
            category: .food,
            imageURLs: [
                URL(string: "https://cdn.mcdonalds.com/content/dam/sites/de/nfl/nutrition/pommes-gross.jpg")!
            ],
            isAvailable: true,
            preparationTime: 4,
            tags: ["Pommes", "Beilage", "Klassiker"],
            nutritionalInfo: NutritionalInfo(
                calories: 365,
                protein: 4.9,
                carbs: 43.7,
                fat: 19.0,
                fiber: 4.6
            )
        )
    ]
    
    // MARK: - REWE Products
    static let reweProducts: [Product] = [
        Product(
            partnerId: "rewe-berlin-friedrichshain",
            name: "REWE Bio Vollmilch 3,5%",
            description: "Frische Bio-Vollmilch aus regionaler Erzeugung, 1 Liter",
            priceCents: 129, // €1.29
            category: .food,
            imageURLs: [
                URL(string: "https://img.rewe.de/products/123456/bio-vollmilch-35.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 25,
            tags: ["Bio", "Milch", "Regional"],
            nutritionalInfo: NutritionalInfo(
                calories: 64,
                protein: 3.3,
                carbs: 4.8,
                fat: 3.5,
                fiber: 0.0
            ),
            unit: "1L"
        ),
        
        Product(
            partnerId: "rewe-berlin-friedrichshain",
            name: "REWE Beste Wahl Bananen",
            description: "Süße, reife Bananen aus fairem Handel, 1kg",
            priceCents: 199, // €1.99
            category: .food,
            imageURLs: [
                URL(string: "https://img.rewe.de/products/123457/bananen-fair-trade.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 40,
            tags: ["Obst", "Fair Trade", "Frisch"],
            nutritionalInfo: NutritionalInfo(
                calories: 89,
                protein: 1.1,
                carbs: 22.8,
                fat: 0.3,
                fiber: 2.6
            ),
            unit: "1kg"
        ),
        
        Product(
            partnerId: "rewe-berlin-friedrichshain",
            name: "REWE Bio Hähnchenbrust",
            description: "Frische Bio-Hähnchenbrust aus Deutschland, 500g",
            priceCents: 699, // €6.99
            category: .food,
            imageURLs: [
                URL(string: "https://img.rewe.de/products/123458/bio-haehnchenbrust.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 15,
            tags: ["Bio", "Fleisch", "Hähnchen", "Deutschland"],
            nutritionalInfo: NutritionalInfo(
                calories: 165,
                protein: 31.0,
                carbs: 0.0,
                fat: 3.6,
                fiber: 0.0
            ),
            unit: "500g"
        ),
        
        Product(
            partnerId: "rewe-berlin-friedrichshain",
            name: "REWE Beste Wahl Vollkornbrot",
            description: "Herzhaftes Vollkornbrot aus der REWE-Bäckerei, 500g",
            priceCents: 189, // €1.89
            category: .food,
            imageURLs: [
                URL(string: "https://img.rewe.de/products/123459/vollkornbrot-baeckerei.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 30,
            tags: ["Brot", "Vollkorn", "Bäckerei"],
            nutritionalInfo: NutritionalInfo(
                calories: 247,
                protein: 8.5,
                carbs: 41.4,
                fat: 4.2,
                fiber: 7.4
            ),
            unit: "500g"
        )
    ]
    
    // MARK: - DocMorris Products
    static let docMorrisProducts: [Product] = [
        Product(
            partnerId: "docmorris-online",
            name: "Aspirin Plus C Brausetabletten",
            description: "Schnelle Hilfe bei Kopfschmerzen und Erkältung, 20 Brausetabletten",
            priceCents: 649, // €6.49
            category: .healthcare,
            imageURLs: [
                URL(string: "https://cdn.docmorris.com/products/aspirin-plus-c-brausetabletten.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 50,
            tags: ["Kopfschmerzen", "Erkältung", "Brausetabletten"],
            requiresPrescription: false,
            unit: "20 Tabletten"
        ),
        
        Product(
            partnerId: "docmorris-online",
            name: "Bepanthen Wund- und Heilsalbe",
            description: "Zur Behandlung oberflächlicher Wunden und Hautverletzungen, 30g",
            priceCents: 899, // €8.99
            category: .healthcare,
            imageURLs: [
                URL(string: "https://cdn.docmorris.com/products/bepanthen-wund-heilsalbe.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 25,
            tags: ["Wundheilung", "Salbe", "Haut"],
            requiresPrescription: false,
            unit: "30g"
        ),
        
        Product(
            partnerId: "docmorris-online",
            name: "Ibuprofen 400mg Tabletten",
            description: "Rezeptpflichtiges Schmerzmittel gegen starke Schmerzen, 20 Tabletten",
            priceCents: 1249, // €12.49
            category: .healthcare,
            imageURLs: [
                URL(string: "https://cdn.docmorris.com/products/ibuprofen-400-tabletten.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 100,
            tags: ["Schmerzmittel", "Rezeptpflichtig", "Stark"],
            requiresPrescription: true,
            unit: "20 Tabletten"
        ),
        
        Product(
            partnerId: "docmorris-online",
            name: "Eucerin Sun Face Creme LSF 50+",
            description: "Hoher Sonnenschutz für das Gesicht, wasserfest, 50ml",
            priceCents: 1599, // €15.99
            category: .healthcare,
            imageURLs: [
                URL(string: "https://cdn.docmorris.com/products/eucerin-sun-face-creme.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 30,
            tags: ["Sonnenschutz", "Gesicht", "Wasserfest"],
            requiresPrescription: false,
            unit: "50ml"
        )
    ]
    
    // MARK: - MediaMarkt Products
    static let mediaMarktProducts: [Product] = [
        Product(
            partnerId: "mediamarkt-berlin-alexanderplatz",
            name: "Apple iPhone 15 Pro 128GB",
            description: "Das neueste iPhone mit A17 Pro Chip, Titanium Design und Pro Kamera-System",
            priceCents: 119900, // €1.199,00
            category: .electronics,
            imageURLs: [
                URL(string: "https://cdn.mediamarkt.de/products/iphone-15-pro-titanium.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 5,
            tags: ["iPhone", "Apple", "Smartphone", "Premium"],
            unit: "1 Stück"
        ),
        
        Product(
            partnerId: "mediamarkt-berlin-alexanderplatz",
            name: "Samsung 65\" Neo QLED 4K TV",
            description: "65 Zoll Neo QLED 4K Smart TV mit Quantum Dot Technologie",
            priceCents: 149900, // €1.499,00
            category: .electronics,
            imageURLs: [
                URL(string: "https://cdn.mediamarkt.de/products/samsung-neo-qled-65.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 3,
            tags: ["TV", "Samsung", "4K", "65 Zoll"],
            unit: "1 Stück"
        ),
        
        Product(
            partnerId: "mediamarkt-berlin-alexanderplatz",
            name: "Sony WH-1000XM5 Kopfhörer",
            description: "Premium Noise Cancelling Over-Ear Kopfhörer mit 30h Akkulaufzeit",
            priceCents: 39900, // €399,00
            category: .electronics,
            imageURLs: [
                URL(string: "https://cdn.mediamarkt.de/products/sony-wh1000xm5.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 12,
            tags: ["Kopfhörer", "Sony", "Noise Cancelling", "Premium"],
            unit: "1 Stück"
        ),
        
        Product(
            partnerId: "mediamarkt-berlin-alexanderplatz",
            name: "Nintendo Switch OLED",
            description: "Nintendo Switch mit verbessertem OLED-Display und 64GB Speicher",
            priceCents: 34900, // €349,00
            category: .electronics,
            imageURLs: [
                URL(string: "https://cdn.mediamarkt.de/products/nintendo-switch-oled.jpg")!
            ],
            isAvailable: true,
            stockQuantity: 8,
            tags: ["Nintendo", "Gaming", "Switch", "OLED"],
            unit: "1 Stück"
        )
    ]
    
    // MARK: - All Products by Partner
    static let productsByPartner: [String: [Product]] = [
        "mcdonalds-berlin-alexanderplatz": mcdonaldsProducts,
        "mcdonalds-hamburg-hauptbahnhof": mcdonaldsProducts,
        "rewe-berlin-friedrichshain": reweProducts,
        "edeka-hamburg-eppendorf": reweProducts, // Similar products
        "docmorris-online": docMorrisProducts,
        "shop-apotheke-online": docMorrisProducts, // Similar products
        "mediamarkt-berlin-alexanderplatz": mediaMarktProducts,
        "saturn-hamburg-europa-passage": mediaMarktProducts // Similar products
    ]
    
    // MARK: - Helper Methods
    
    /// Get products for a specific partner
    static func getProducts(for partnerId: String) -> [Product] {
        return productsByPartner[partnerId] ?? []
    }
    
    /// Get all products across all partners
    static let allProducts: [Product] = Array(productsByPartner.values.flatMap { $0 })
    
    /// Search products by name or description
    static func searchProducts(_ query: String) -> [Product] {
        return allProducts.filter { product in
            product.name.localizedCaseInsensitiveContains(query) ||
            product.description.localizedCaseInsensitiveContains(query) ||
            product.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    /// Get products by category
    static func getProducts(for category: ProductCategory) -> [Product] {
        return allProducts.filter { $0.category == category }
    }
}

// MARK: - Nutritional Info Extension

extension Product {
    /// Create a product with German nutritional information
    init(
        partnerId: String,
        name: String,
        description: String,
        priceCents: Int,
        category: ProductCategory,
        imageURLs: [URL] = [],
        isAvailable: Bool = true,
        stockQuantity: Int? = nil,
        preparationTime: Int? = nil,
        tags: [String] = [],
        nutritionalInfo: NutritionalInfo? = nil,
        requiresPrescription: Bool = false,
        unit: String? = nil
    ) {
        self.init(
            partnerId: partnerId,
            name: name,
            description: description,
            priceCents: priceCents,
            category: category,
            imageURLs: imageURLs,
            isAvailable: isAvailable,
            stockQuantity: stockQuantity,
            preparationTime: preparationTime,
            tags: tags
        )
        // Note: Additional properties would be set if Product model supports them
    }
}

// MARK: - German Product Categories

extension ProductCategory {
    /// Get German products for this category
    var germanProducts: [Product] {
        return GermanProductData.getProducts(for: self)
    }
    
    /// German category display names
    var germanDisplayName: String {
        switch self {
        case .food:
            return "Lebensmittel"
        case .beverages:
            return "Getränke"
        case .healthcare:
            return "Gesundheit"
        case .electronics:
            return "Elektronik"
        case .fashion:
            return "Mode"
        case .homeAndGarden:
            return "Haus & Garten"
        case .books:
            return "Bücher"
        case .sports:
            return "Sport"
        case .beauty:
            return "Schönheit"
        case .toys:
            return "Spielzeug"
        }
    }
}