//
//  ImageAssets.swift
//  MimiSupply
//
//  Created by Assistant on 27.08.25.
//

import Foundation

extension Partner {
    /// Realistische Logo URLs für Demo-Partner
    var dynamicLogoURL: URL? {
        switch self.id {
        case "mcdonalds_berlin_mitte":
            return URL(string: "https://logos-world.net/wp-content/uploads/2020/04/McDonalds-Logo.png")
        case "rewe_alexanderplatz":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/REWE_Logo.svg/1200px-REWE_Logo.svg.png")
        case "docmorris_berlin":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/82/DocMorris_logo.svg/1200px-DocMorris_logo.svg.png")
        case "mediamarkt_alexanderplatz":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Media_Markt_logo.svg/1200px-Media_Markt_logo.svg.png")
        case "edeka_prenzlauer_berg":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/EDEKA_logo.svg/1200px-EDEKA_logo.svg.png")
        case "dm_hackescher_markt":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/6/65/Dm-drogerie_markt_Logo.svg/1200px-Dm-drogerie_markt_Logo.svg.png")
        case "rossmann_friedrichshain":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Rossmann_Logo.svg/1200px-Rossmann_Logo.svg.png")
        case "burger_king_potsdamer_platz":
            return URL(string: "https://logos-world.net/wp-content/uploads/2020/05/Burger-King-Logo.png")
        case "kfc_alexanderplatz":
            return URL(string: "https://logos-world.net/wp-content/uploads/2020/04/KFC-Logo.png")
        case "pizza_hut_mitte":
            return URL(string: "https://logos-world.net/wp-content/uploads/2020/05/Pizza-Hut-Logo.png")
        case "subway_friedrichstrasse":
            return URL(string: "https://logos-world.net/wp-content/uploads/2020/05/Subway-Logo.png")
        case "starbucks_unter_den_linden":
            return URL(string: "https://logos-world.net/wp-content/uploads/2020/05/Starbucks-Logo.png")
        case "lidl_kreuzberg":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Lidl-Logo.svg/1200px-Lidl-Logo.svg.png")
        case "aldi_nord_wedding":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/ALDI_Nord_Logo.svg/1200px-ALDI_Nord_Logo.svg.png")
        case "netto_tempelhof":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7e/Netto_Marken-Discount_logo.svg/1200px-Netto_Marken-Discount_logo.svg.png")
        case "penny_neukoelln":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Penny_Logo.svg/1200px-Penny_Logo.svg.png")
        case "apotheke_zur_rose_mitte":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Zur_Rose_Logo.svg/1200px-Zur_Rose_Logo.svg.png")
        case "saturn_alexanderplatz":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Saturn_logo.svg/1200px-Saturn_logo.svg.png")
        case "conrad_electronic_charlottenburg":
            return URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c8/Conrad_Electronic_logo.svg/1200px-Conrad_Electronic_logo.svg.png")
        case "cyberport_mitte":
            return URL(string: "https://www.cyberport.de/favicon-32x32.png")
        case "notebooksbilliger_online":
            return URL(string: "https://www.notebooksbilliger.de/favicon-32x32.png")
        default:
            return nil
        }
    }
    
    /// Hero/Banner Images für Featured Partners
    var dynamicHeroImageURL: URL? {
        switch self.id {
        case "mcdonalds_berlin_mitte":
            return URL(string: "https://images.unsplash.com/photo-1551782450-17144efb9c50?w=800&h=400&fit=crop&q=80")
        case "rewe_alexanderplatz":
            return URL(string: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&h=400&fit=crop&q=80")
        case "docmorris_berlin":
            return URL(string: "https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop&q=80")
        case "mediamarkt_alexanderplatz":
            return URL(string: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&h=400&fit=crop&q=80")
        case "edeka_prenzlauer_berg":
            return URL(string: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=400&fit=crop&q=80")
        case "burger_king_potsdamer_platz":
            return URL(string: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800&h=400&fit=crop&q=80")
        case "starbucks_unter_den_linden":
            return URL(string: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&h=400&fit=crop&q=80")
        case "pizza_hut_mitte":
            return URL(string: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&h=400&fit=crop&q=80")
        case "dm_hackescher_markt":
            return URL(string: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=800&h=400&fit=crop&q=80")
        case "lidl_kreuzberg":
            return URL(string: "https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=400&fit=crop&q=80")
        default:
            return nil
        }
    }
}

extension PartnerCategory {
    /// Premium Category Icons mit hochwertigen Unsplash-Bildern
    var categoryImageURL: URL? {
        switch self {
        case .restaurant:
            return URL(string: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=300&h=200&fit=crop&q=80")
        case .grocery:
            return URL(string: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=300&h=200&fit=crop&q=80")
        case .pharmacy:
            return URL(string: "https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=300&h=200&fit=crop&q=80")
        case .electronics:
            return URL(string: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=200&fit=crop&q=80")
        case .retail:
            return URL(string: "https://images.unsplash.com/photo-1441984904996-e0b6ba687e04?w=300&h=200&fit=crop&q=80")
        case .convenience:
            return URL(string: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=300&h=200&fit=crop&q=80")
        case .bakery:
            return URL(string: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300&h=200&fit=crop&q=80")
        case .coffee:
            return URL(string: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=300&h=200&fit=crop&q=80")
        case .alcohol:
            return URL(string: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=300&h=200&fit=crop&q=80")
        case .flowers:
            return URL(string: "https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=300&h=200&fit=crop&q=80")
        }
    }
}

// MARK: - Product Images

struct ProductImageAssets {
    
    /// Restaurant/Fast Food Produkte
    static let restaurantProducts: [String: URL] = [
        "big_mac": URL(string: "https://images.unsplash.com/photo-1551782450-17144efb9c50?w=400&h=300&fit=crop&q=80")!,
        "whopper": URL(string: "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&h=300&fit=crop&q=80")!,
        "pizza_margherita": URL(string: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&h=300&fit=crop&q=80")!,
        "chicken_nuggets": URL(string: "https://images.unsplash.com/photo-1562967914-608f82629710?w=400&h=300&fit=crop&q=80")!,
        "french_fries": URL(string: "https://images.unsplash.com/photo-1576107136888-069ab3d3ba2e?w=400&h=300&fit=crop&q=80")!,
        "subway_sandwich": URL(string: "https://images.unsplash.com/photo-1553909489-cd47e0ef937f?w=400&h=300&fit=crop&q=80")!,
        "starbucks_latte": URL(string: "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=300&fit=crop&q=80")!,
        "cappuccino": URL(string: "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Grocery/Lebensmittel Produkte
    static let groceryProducts: [String: URL] = [
        "bananas": URL(string: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=300&fit=crop&q=80")!,
        "apples": URL(string: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&h=300&fit=crop&q=80")!,
        "milk": URL(string: "https://images.unsplash.com/photo-1563636619-e9143da7973b?w=400&h=300&fit=crop&q=80")!,
        "bread": URL(string: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=300&fit=crop&q=80")!,
        "eggs": URL(string: "https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400&h=300&fit=crop&q=80")!,
        "cheese": URL(string: "https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&h=300&fit=crop&q=80")!,
        "yogurt": URL(string: "https://images.unsplash.com/photo-1571212515416-fdf2501b8e8c?w=400&h=300&fit=crop&q=80")!,
        "vegetables": URL(string: "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Pharmacy/Apotheke Produkte
    static let pharmacyProducts: [String: URL] = [
        "aspirin": URL(string: "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400&h=300&fit=crop&q=80")!,
        "vitamins": URL(string: "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400&h=300&fit=crop&q=80")!,
        "bandages": URL(string: "https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400&h=300&fit=crop&q=80")!,
        "thermometer": URL(string: "https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=400&h=300&fit=crop&q=80")!,
        "hand_sanitizer": URL(string: "https://images.unsplash.com/photo-1584744982491-665216d95f8b?w=400&h=300&fit=crop&q=80")!,
        "face_masks": URL(string: "https://images.unsplash.com/photo-1584744982491-665216d95f8b?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Electronics Produkte
    static let electronicsProducts: [String: URL] = [
        "iphone": URL(string: "https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400&h=300&fit=crop&q=80")!,
        "laptop": URL(string: "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400&h=300&fit=crop&q=80")!,
        "headphones": URL(string: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=300&fit=crop&q=80")!,
        "tablet": URL(string: "https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400&h=300&fit=crop&q=80")!,
        "smartwatch": URL(string: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=300&fit=crop&q=80")!,
        "camera": URL(string: "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400&h=300&fit=crop&q=80")!,
        "gaming_console": URL(string: "https://images.unsplash.com/photo-1606144042614-b2417e99c4e3?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Retail/Fashion Produkte
    static let retailProducts: [String: URL] = [
        "t_shirt": URL(string: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=300&fit=crop&q=80")!,
        "jeans": URL(string: "https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=300&fit=crop&q=80")!,
        "sneakers": URL(string: "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=300&fit=crop&q=80")!,
        "jacket": URL(string: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400&h=300&fit=crop&q=80")!,
        "dress": URL(string: "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&h=300&fit=crop&q=80")!,
        "handbag": URL(string: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Convenience Store Produkte
    static let convenienceProducts: [String: URL] = [
        "energy_drink": URL(string: "https://images.unsplash.com/photo-1624552184280-8a4db3d8cf6c?w=400&h=300&fit=crop&q=80")!,
        "chips": URL(string: "https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&h=300&fit=crop&q=80")!,
        "chocolate": URL(string: "https://images.unsplash.com/photo-1511381939415-e44015466834?w=400&h=300&fit=crop&q=80")!,
        "cigarettes": URL(string: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop&q=80")!,
        "newspaper": URL(string: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=400&h=300&fit=crop&q=80")!,
        "lottery_ticket": URL(string: "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Bakery Produkte
    static let bakeryProducts: [String: URL] = [
        "croissant": URL(string: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=300&fit=crop&q=80")!,
        "pretzel": URL(string: "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=400&h=300&fit=crop&q=80")!,
        "cake": URL(string: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&h=300&fit=crop&q=80")!,
        "donut": URL(string: "https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400&h=300&fit=crop&q=80")!,
        "muffin": URL(string: "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400&h=300&fit=crop&q=80")!,
        "bagel": URL(string: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Coffee Shop Produkte
    static let coffeeProducts: [String: URL] = [
        "espresso": URL(string: "https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400&h=300&fit=crop&q=80")!,
        "latte": URL(string: "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=300&fit=crop&q=80")!,
        "cappuccino": URL(string: "https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&h=300&fit=crop&q=80")!,
        "frappuccino": URL(string: "https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400&h=300&fit=crop&q=80")!,
        "coffee_beans": URL(string: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400&h=300&fit=crop&q=80")!,
        "tea": URL(string: "https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Alcohol Produkte
    static let alcoholProducts: [String: URL] = [
        "beer": URL(string: "https://images.unsplash.com/photo-1608270586620-248524c67de9?w=400&h=300&fit=crop&q=80")!,
        "wine": URL(string: "https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=400&h=300&fit=crop&q=80")!,
        "whiskey": URL(string: "https://images.unsplash.com/photo-1569529465841-dfecdab7503b?w=400&h=300&fit=crop&q=80")!,
        "vodka": URL(string: "https://images.unsplash.com/photo-1551538827-9c037cb4f32a?w=400&h=300&fit=crop&q=80")!,
        "champagne": URL(string: "https://images.unsplash.com/photo-1547595628-c61a29f496f0?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Flowers Produkte
    static let flowerProducts: [String: URL] = [
        "roses": URL(string: "https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400&h=300&fit=crop&q=80")!,
        "tulips": URL(string: "https://images.unsplash.com/photo-1520763185298-1b434c919102?w=400&h=300&fit=crop&q=80")!,
        "sunflowers": URL(string: "https://images.unsplash.com/photo-1470509037663-253afd7f0f51?w=400&h=300&fit=crop&q=80")!,
        "bouquet": URL(string: "https://images.unsplash.com/photo-1563241527-3004b7be0ffd?w=400&h=300&fit=crop&q=80")!,
        "orchid": URL(string: "https://images.unsplash.com/photo-1452827073306-6e6e661baf57?w=400&h=300&fit=crop&q=80")!
    ]
    
    /// Helper Funktion um Produkt-Image basierend auf Kategorie und Name zu bekommen
    static func getProductImage(for category: PartnerCategory, productName: String) -> URL? {
        let lowercaseName = productName.lowercased().replacingOccurrences(of: " ", with: "_")
        
        switch category {
        case .restaurant:
            return restaurantProducts[lowercaseName]
        case .grocery:
            return groceryProducts[lowercaseName]
        case .pharmacy:
            return pharmacyProducts[lowercaseName]
        case .electronics:
            return electronicsProducts[lowercaseName]
        case .retail:
            return retailProducts[lowercaseName]
        case .convenience:
            return convenienceProducts[lowercaseName]
        case .bakery:
            return bakeryProducts[lowercaseName]
        case .coffee:
            return coffeeProducts[lowercaseName]
        case .alcohol:
            return alcoholProducts[lowercaseName]
        case .flowers:
            return flowerProducts[lowercaseName]
        }
    }
    
    /// Fallback Image für unbekannte Produkte basierend auf Kategorie
    static func getFallbackImage(for category: PartnerCategory) -> URL? {
        return category.categoryImageURL
    }
}

// MARK: - Product Extension

extension Product {
    /// Automatische Image-URL basierend auf ProductCategory und Name
    var imageURL: URL? {
        // Mapping von ProductCategory zu PartnerCategory für Image-Lookup
        let partnerCategory: PartnerCategory
        switch self.category {
        case .food:
            partnerCategory = .restaurant
        case .beverages:
            partnerCategory = .coffee
        case .medicine, .healthcare:
            partnerCategory = .pharmacy
        case .personalCare, .beauty:
            partnerCategory = .convenience
        case .household:
            partnerCategory = .convenience
        case .electronics:
            partnerCategory = .electronics
        case .clothing, .fashion:
            partnerCategory = .retail
        case .books:
            partnerCategory = .retail
        case .homeAndGarden:
            partnerCategory = .flowers
        case .sports:
            partnerCategory = .retail
        case .toys:
            partnerCategory = .retail
        case .other:
            partnerCategory = .convenience
        }
        
        // Erst versuchen spezifisches Produkt-Image zu finden
        if let specificImage = ProductImageAssets.getProductImage(for: partnerCategory, productName: self.name) {
            return specificImage
        }
        
        // Fallback auf Kategorie-Image
        return ProductImageAssets.getFallbackImage(for: partnerCategory)
    }
}
