//
//  GermanPartnerData.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import CoreLocation

/// Realistic German partner data for MimiSupply
struct GermanPartnerData {
    
    // MARK: - German Cities Coordinates
    static let germanCities: [String: CLLocationCoordinate2D] = [
        "Berlin": CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        "Hamburg": CLLocationCoordinate2D(latitude: 53.5511, longitude: 9.9937),
        "München": CLLocationCoordinate2D(latitude: 48.1351, longitude: 11.5820),
        "Köln": CLLocationCoordinate2D(latitude: 50.9375, longitude: 6.9603),
        "Frankfurt": CLLocationCoordinate2D(latitude: 50.1109, longitude: 8.6821),
        "Stuttgart": CLLocationCoordinate2D(latitude: 48.7758, longitude: 9.1829),
        "Düsseldorf": CLLocationCoordinate2D(latitude: 51.2277, longitude: 6.7735),
        "Leipzig": CLLocationCoordinate2D(latitude: 51.3397, longitude: 12.3731),
        "Dortmund": CLLocationCoordinate2D(latitude: 51.5136, longitude: 7.4653),
        "Essen": CLLocationCoordinate2D(latitude: 51.4556, longitude: 7.0116)
    ]
    
    // MARK: - Restaurant Partners
    static let restaurantPartners: [Partner] = [
        // McDonald's
        Partner(
            id: "mcdonalds-berlin-alexanderplatz",
            name: "McDonald's",
            description: "Weltberühmte Burger, Pommes und mehr. Schnell und lecker!",
            category: .restaurant,
            address: Address(
                street: "Alexanderplatz 9",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10178",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5219,
                longitude: 13.4132
            ),
            rating: 4.1,
            reviewCount: 2847,
            priceRange: 1,
            deliveryFeeCents: 199, // €1.99
            minimumOrderAmount: 1000, // €10.00
            estimatedDeliveryTime: 25,
            isOpen: true,
            imageURLs: [
                URL(string: "https://corporate.mcdonalds.com/content/dam/sites/corp/nfl/images/logos/arches-logo_108x108.jpg")!
            ],
            businessHours: createStandardBusinessHours(),
            tags: ["Burger", "Fastfood", "Amerikanisch", "Kinder-freundlich"],
            specialOffers: ["McDelivery", "Happy Meal", "McCafé"]
        ),
        
        Partner(
            id: "mcdonalds-hamburg-hauptbahnhof",
            name: "McDonald's",
            description: "Der Klassiker am Hamburger Hauptbahnhof",
            category: .restaurant,
            address: Address(
                street: "Hauptbahnhof Hamburg, Hachmannplatz 16",
                city: "Hamburg",
                state: "Hamburg",
                postalCode: "20099",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 53.5526,
                longitude: 10.0066
            ),
            rating: 3.9,
            reviewCount: 1923,
            priceRange: 1,
            deliveryFeeCents: 199,
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: 30,
            isOpen: true,
            imageURLs: [
                URL(string: "https://corporate.mcdonalds.com/content/dam/sites/corp/nfl/images/logos/arches-logo_108x108.jpg")!
            ],
            businessHours: createExtendedBusinessHours(),
            tags: ["Burger", "Fastfood", "24h", "Bahnhof"],
            specialOffers: ["McDelivery", "Breakfast", "McCafé"]
        ),
        
        // Burger King
        Partner(
            id: "burgerking-berlin-potsdamer-platz",
            name: "Burger King",
            description: "Have it your way! Flame-grilled Burger seit 1954",
            category: .restaurant,
            address: Address(
                street: "Potsdamer Platz 1",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10785",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5096,
                longitude: 13.3766
            ),
            rating: 4.0,
            reviewCount: 1654,
            priceRange: 1,
            deliveryFeeCents: 249, // €2.49
            minimumOrderAmount: 1200, // €12.00
            estimatedDeliveryTime: 35,
            isOpen: true,
            imageURLs: [
                URL(string: "https://logos-world.net/wp-content/uploads/2020/07/Burger-King-Logo.png")!
            ],
            businessHours: createStandardBusinessHours(),
            tags: ["Burger", "Fastfood", "Flame-grilled", "Whopper"],
            specialOffers: ["King Deal", "Plant-based", "Lieferando Partner"]
        ),
        
        // Subway
        Partner(
            id: "subway-muenchen-marienplatz",
            name: "Subway",
            description: "Frisch zubereitete Subs, Salate und Wraps",
            category: .restaurant,
            address: Address(
                street: "Marienplatz 8",
                city: "München",
                state: "Bayern",
                postalCode: "80331",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 48.1374,
                longitude: 11.5755
            ),
            rating: 4.3,
            reviewCount: 987,
            priceRange: 2,
            deliveryFeeCents: 199,
            minimumOrderAmount: 800, // €8.00
            estimatedDeliveryTime: 20,
            isOpen: true,
            imageURLs: [
                URL(string: "https://logos-world.net/wp-content/uploads/2020/09/Subway-Logo.png")!
            ],
            businessHours: createStandardBusinessHours(),
            tags: ["Subs", "Salate", "Gesund", "Anpassbar"],
            specialOffers: ["Sub des Tages", "Veggie Options", "Fresh Fit"]
        ),
        
        // Döner Kebab
        Partner(
            id: "berlin-doener-kreuzberg",
            name: "Mustafa's Gemüse Kebap",
            description: "Berlins berühmtester Döner mit frischem Gemüse",
            category: .restaurant,
            address: Address(
                street: "Mehringdamm 32",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10961",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.4932,
                longitude: 13.3889
            ),
            rating: 4.6,
            reviewCount: 3247,
            priceRange: 1,
            deliveryFeeCents: 150,
            minimumOrderAmount: 600, // €6.00
            estimatedDeliveryTime: 25,
            isOpen: true,
            imageURLs: [
                URL(string: "https://via.placeholder.com/300x200/34D399/FFFFFF?text=Mustafa's+Kebap")!
            ],
            businessHours: createLateNightBusinessHours(),
            tags: ["Döner", "Türkisch", "Halal", "Vegetarisch"],
            specialOffers: ["Gemüse Döner", "Falafel", "Ayran"]
        ),
        
        // Pizza
        Partner(
            id: "pizza-hut-koeln",
            name: "Pizza Hut",
            description: "Amerikas Pizza Nummer 1 - Original Pan Pizza",
            category: .restaurant,
            address: Address(
                street: "Schildergasse 65",
                city: "Köln",
                state: "Nordrhein-Westfalen",
                postalCode: "50667",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 50.9364,
                longitude: 6.9528
            ),
            rating: 4.2,
            reviewCount: 1876,
            priceRange: 2,
            deliveryFeeCents: 299,
            minimumOrderAmount: 1500, // €15.00
            estimatedDeliveryTime: 30,
            isOpen: true,
            imageURLs: [
                URL(string: "https://logos-world.net/wp-content/uploads/2020/09/Pizza-Hut-Logo.png")!
            ],
            businessHours: createStandardBusinessHours(),
            tags: ["Pizza", "Italienisch", "Pan Pizza", "Familie"],
            specialOffers: ["Stuffed Crust", "Pizza Meal Deal", "Pasta"]
        )
    ]
    
    // MARK: - Grocery Partners
    static let groceryPartners: [Partner] = [
        // REWE
        Partner(
            id: "rewe-berlin-friedrichshain",
            name: "REWE",
            description: "Dein Markt für frische Lebensmittel und alles fürs tägliche Leben",
            category: .grocery,
            address: Address(
                street: "Warschauer Str. 33",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10243",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5065,
                longitude: 13.4491
            ),
            rating: 4.4,
            reviewCount: 2341,
            priceRange: 2,
            deliveryFeeCents: 390, // €3.90
            minimumOrderAmount: 5000, // €50.00
            estimatedDeliveryTime: 60,
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/REWE_Logo_2016.svg/200px-REWE_Logo_2016.svg.png")!
            ],
            businessHours: createGroceryBusinessHours(),
            tags: ["Lebensmittel", "Frisch", "Bio", "Regional"],
            specialOffers: ["REWE Bio", "Regional", "Lieferservice"]
        ),
        
        // EDEKA
        Partner(
            id: "edeka-hamburg-eppendorf",
            name: "EDEKA",
            description: "Wir lieben Lebensmittel - Frische und Qualität aus einer Hand",
            category: .grocery,
            address: Address(
                street: "Eppendorfer Weg 171",
                city: "Hamburg",
                state: "Hamburg",
                postalCode: "20253",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 53.5958,
                longitude: 9.9731
            ),
            rating: 4.3,
            reviewCount: 1987,
            priceRange: 2,
            deliveryFeeCents: 490, // €4.90
            minimumOrderAmount: 6000, // €60.00
            estimatedDeliveryTime: 90,
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Edeka_logo.svg/200px-Edeka_logo.svg.png")!
            ],
            businessHours: createGroceryBusinessHours(),
            tags: ["Lebensmittel", "Qualität", "Frisch", "Lokal"],
            specialOffers: ["EDEKA Bio", "Gutscheine", "Wolt Partner"]
        ),
        
        // ALDI
        Partner(
            id: "aldi-sued-muenchen",
            name: "ALDI SÜD",
            description: "Einfach. Gut. Günstig. - Qualität zum kleinen Preis",
            category: .grocery,
            address: Address(
                street: "Müllerstraße 54",
                city: "München",
                state: "Bayern",
                postalCode: "80469",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 48.1299,
                longitude: 11.5643
            ),
            rating: 4.1,
            reviewCount: 1432,
            priceRange: 1,
            deliveryFeeCents: 299,
            minimumOrderAmount: 2500, // €25.00
            estimatedDeliveryTime: 120,
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/ALDI_S%C3%9CD_logo.svg/200px-ALDI_S%C3%9CD_logo.svg.png")!
            ],
            businessHours: createLimitedBusinessHours(),
            tags: ["Discount", "Günstig", "Qualität", "Non-Food"],
            specialOffers: ["Sonderangebote", "Amazon Partnership", "App Coupons"]
        ),
        
        // Lidl
        Partner(
            id: "lidl-frankfurt",
            name: "Lidl",
            description: "Lidl lohnt sich - Mehr drin für weniger Geld",
            category: .grocery,
            address: Address(
                street: "Berger Str. 177",
                city: "Frankfurt am Main",
                state: "Hessen",
                postalCode: "60385",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 50.1213,
                longitude: 8.7118
            ),
            rating: 4.0,
            reviewCount: 1876,
            priceRange: 1,
            deliveryFeeCents: 349,
            minimumOrderAmount: 3000, // €30.00
            estimatedDeliveryTime: 90,
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Lidl_Logo.svg/200px-Lidl_Logo.svg.png")!
            ],
            businessHours: createLimitedBusinessHours(),
            tags: ["Discount", "Günstig", "Bakery", "Wöchentliche Angebote"],
            specialOffers: ["Lidl Plus", "Wochenangebote", "Online Shop"]
        ),
        
        // dm-drogerie markt
        Partner(
            id: "dm-stuttgart-koenigstrasse",
            name: "dm-drogerie markt",
            description: "Hier bin ich Mensch, hier kauf ich ein - Drogerie & Gesundheit",
            category: .grocery,
            address: Address(
                street: "Königstraße 6",
                city: "Stuttgart",
                state: "Baden-Württemberg",
                postalCode: "70173",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 48.7761,
                longitude: 9.1775
            ),
            rating: 4.5,
            reviewCount: 2156,
            priceRange: 2,
            deliveryFeeCents: 495,
            minimumOrderAmount: 2000, // €20.00
            estimatedDeliveryTime: 45,
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d8/Dm-drogerie_markt_Logo.svg/200px-Dm-drogerie_markt_Logo.svg.png")!
            ],
            businessHours: createGroceryBusinessHours(),
            tags: ["Drogerie", "Gesundheit", "Bio", "Kosmetik"],
            specialOffers: ["dmBio", "Pickup Service", "Amazon Delivery"]
        )
    ]
    
    // MARK: - Pharmacy Partners
    static let pharmacyPartners: [Partner] = [
        // DocMorris
        Partner(
            id: "docmorris-online",
            name: "DocMorris Online Apotheke",
            description: "Europas größte Versandapotheke mit über 10 Millionen Kunden",
            category: .pharmacy,
            address: Address(
                street: "Online Versandapotheke",
                city: "Heerlen", // DocMorris HQ
                state: "Deutschland Service",
                postalCode: "00000",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5200, // Berlin centered for Germany service
                longitude: 13.4050
            ),
            rating: 4.4,
            reviewCount: 15678,
            priceRange: 2,
            deliveryFeeCents: 395, // €3.95
            minimumOrderAmount: 0, // No minimum for prescriptions
            estimatedDeliveryTime: 1440, // Next day (24 hours)
            isOpen: true,
            imageURLs: [
                URL(string: "https://corporate.docmorris.com/typo3conf/ext/zur_rose_template/Resources/Public/assets/images/logo-docmorris.svg")!
            ],
            businessHours: createPharmacyBusinessHours(),
            tags: ["Versandapotheke", "Rezepte", "E-Rezept", "Beratung"],
            specialOffers: ["Kostenloser Versand ab €25", "E-Rezept", "24h Service"]
        ),
        
        // Shop Apotheke
        Partner(
            id: "shop-apotheke-online",
            name: "Shop Apotheke",
            description: "7 Millionen zufriedene Kunden - Ihre Online-Apotheke",
            category: .pharmacy,
            address: Address(
                street: "Online Versandapotheke",
                city: "Venlo", // Shop Apotheke HQ
                state: "Deutschland Service",
                postalCode: "00000",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5200,
                longitude: 13.4050
            ),
            rating: 4.3,
            reviewCount: 12456,
            priceRange: 2,
            deliveryFeeCents: 0, // Free shipping over €25
            minimumOrderAmount: 2500, // €25.00 for free shipping
            estimatedDeliveryTime: 1440, // Next day
            isOpen: true,
            imageURLs: [
                URL(string: "https://www.shop-apotheke.com/images/logo-shop-apotheke.svg")!
            ],
            businessHours: createPharmacyBusinessHours(),
            tags: ["Online-Apotheke", "Kostenloser Versand", "E-Rezept", "Beauty"],
            specialOffers: ["Gratis Versand ab €25", "RedCare App", "Beauty Products"]
        ),
        
        // Local Pharmacy Berlin
        Partner(
            id: "apotheke-berlin-mitte",
            name: "Apotheke am Brandenburger Tor", 
            description: "Ihre lokale Apotheke im Herzen Berlins mit Botendienst",
            category: .pharmacy,
            address: Address(
                street: "Unter den Linden 26",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10117",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5163,
                longitude: 13.3777
            ),
            rating: 4.6,
            reviewCount: 892,
            priceRange: 2,
            deliveryFeeCents: 500, // €5.00 local delivery
            minimumOrderAmount: 1000, // €10.00
            estimatedDeliveryTime: 60, // 1 hour local delivery
            isOpen: true,
            imageURLs: [
                URL(string: "https://via.placeholder.com/300x200/059669/FFFFFF?text=Apotheke+Berlin")!
            ],
            businessHours: createPharmacyBusinessHours(),
            tags: ["Lokale Apotheke", "Botendienst", "Beratung", "Notdienst"],
            specialOffers: ["Cure Platform", "1h Lieferung", "Pharmazeutische Beratung"]
        ),
        
        // Local Pharmacy Munich
        Partner(
            id: "apotheke-muenchen-schwabing",
            name: "Schwabinger Apotheke",
            description: "Traditionelle Apotheke in Schwabing mit modernem Service",
            category: .pharmacy,
            address: Address(
                street: "Leopoldstraße 58",
                city: "München",
                state: "Bayern",
                postalCode: "80802",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 48.1549,
                longitude: 11.5808
            ),
            rating: 4.7,
            reviewCount: 1234,
            priceRange: 2,
            deliveryFeeCents: 450,
            minimumOrderAmount: 1500, // €15.00
            estimatedDeliveryTime: 45,
            isOpen: true,
            imageURLs: [
                URL(string: "https://via.placeholder.com/300x200/059669/FFFFFF?text=Schwabinger+Apotheke")!
            ],
            businessHours: createPharmacyBusinessHours(),
            tags: ["Traditionell", "Schwabing", "E-Rezept", "Homöopathie"],
            specialOffers: ["E-Rezept Service", "Homöopathie", "Kosmetikberatung"]
        )
    ]
    
    // MARK: - Retail Partners
    static let retailPartners: [Partner] = [
        // MediaMarkt
        Partner(
            id: "mediamarkt-berlin-alexanderplatz",
            name: "MediaMarkt",
            description: "Deutschlands beste Online-Shop 2024 - Ich bin doch nicht blöd!",
            category: .retail,
            address: Address(
                street: "Alexanderplatz 9",
                city: "Berlin",
                state: "Berlin", 
                postalCode: "10178",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 52.5219,
                longitude: 13.4132
            ),
            rating: 4.2,
            reviewCount: 3456,
            priceRange: 3,
            deliveryFeeCents: 599, // €5.99
            minimumOrderAmount: 0, // No minimum
            estimatedDeliveryTime: 1440, // Next day
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/MediaMarkt_logo.svg/200px-MediaMarkt_logo.svg.png")!
            ],
            businessHours: createRetailBusinessHours(),
            tags: ["Elektronik", "Technik", "Computer", "Smartphones"],
            specialOffers: ["DPD/GLS Paket-Shops", "Online Bestseller", "Technik Beratung"]
        ),
        
        // Saturn
        Partner(
            id: "saturn-hamburg-europa-passage",
            name: "Saturn",
            description: "Technik-Experte mit 400 Filialen und modernem Paket-Service",
            category: .retail,
            address: Address(
                street: "Europa Passage, Ballindamm 40",
                city: "Hamburg",
                state: "Hamburg",
                postalCode: "20095",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 53.5511,
                longitude: 9.9937
            ),
            rating: 4.1,
            reviewCount: 2876,
            priceRange: 3,
            deliveryFeeCents: 599,
            minimumOrderAmount: 0,
            estimatedDeliveryTime: 1440,
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Saturn_Logo.svg/200px-Saturn_Logo.svg.png")!
            ],
            businessHours: createRetailBusinessHours(),
            tags: ["Elektronik", "Gaming", "Computer", "Haushaltsgeräte"],
            specialOffers: ["Gaming Setup", "Smart Home", "Paket-Shop Service"]
        ),
        
        // Douglas
        Partner(
            id: "douglas-muenchen-pedestrian-zone",
            name: "Douglas",
            description: "Europas führender Beauty-Retailer mit €681M Online-Umsatz",
            category: .retail,
            address: Address(
                street: "Pedestrian Zone, Marienplatz 1",
                city: "München",
                state: "Bayern",
                postalCode: "80331",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 48.1374,
                longitude: 11.5755
            ),
            rating: 4.5,
            reviewCount: 1987,
            priceRange: 3,
            deliveryFeeCents: 395, // €3.95
            minimumOrderAmount: 2500, // €25.00
            estimatedDeliveryTime: 2880, // 2 days
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Douglas_logo.svg/200px-Douglas_logo.svg.png")!
            ],
            businessHours: createRetailBusinessHours(),
            tags: ["Beauty", "Parfüm", "Kosmetik", "Luxus"],
            specialOffers: ["Beauty Beratung", "Parfum Expertise", "200 neue Stores bis 2026"]
        ),
        
        // H&M
        Partner(
            id: "hm-koeln-schildergasse",
            name: "H&M",
            description: "Fashion and quality at the best price in a sustainable way",
            category: .retail,
            address: Address(
                street: "Schildergasse 65",
                city: "Köln",
                state: "Nordrhein-Westfalen",
                postalCode: "50667",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 50.9364,
                longitude: 6.9528
            ),
            rating: 4.0,
            reviewCount: 2341,
            priceRange: 2,
            deliveryFeeCents: 499, // €4.99
            minimumOrderAmount: 3000, // €30.00
            estimatedDeliveryTime: 4320, // 2-3 days
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/H%26M-Logo.svg/200px-H%26M-Logo.svg.png")!
            ],
            businessHours: createRetailBusinessHours(),
            tags: ["Mode", "Fashion", "Nachhaltig", "Trend"],
            specialOffers: ["Express Lieferung €14.99", "H&M Member", "Conscious Collection"]
        ),
        
        // Zara
        Partner(
            id: "zara-frankfurt-zeil",
            name: "Zara",
            description: "Fashion-Forward Designs mit flexiblen Lieferoptionen",
            category: .retail,
            address: Address(
                street: "Zeil 106",
                city: "Frankfurt am Main",
                state: "Hessen",
                postalCode: "60313",
                country: "Germany"
            ),
            coordinate: Coordinate(
                latitude: 50.1144,
                longitude: 8.6794
            ),
            rating: 4.3,
            reviewCount: 1876,
            priceRange: 3,
            deliveryFeeCents: 495, // €4.95 standard
            minimumOrderAmount: 0,
            estimatedDeliveryTime: 4320, // 2-3 days standard
            isOpen: true,
            imageURLs: [
                URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fd/Zara_Logo.svg/200px-Zara_Logo.svg.png")!
            ],
            businessHours: createRetailBusinessHours(),
            tags: ["Fashion", "Design", "Trend", "Quality"],
            specialOffers: ["Next-Day €8.95", "Neue Kollektionen", "Sales"]
        )
    ]
    
    // MARK: - All Partners Combined
    static let allPartners: [Partner] = 
        restaurantPartners + groceryPartners + pharmacyPartners + retailPartners
    
    // MARK: - Business Hours Helpers
    
    private static func createStandardBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "10:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "10:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "10:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "10:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "10:00", closeTime: "23:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "10:00", closeTime: "23:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "11:00", closeTime: "22:00", isOpen: true)
        ]
    }
    
    private static func createExtendedBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "06:00", closeTime: "01:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "06:00", closeTime: "01:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "06:00", closeTime: "01:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "06:00", closeTime: "01:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "06:00", closeTime: "02:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "06:00", closeTime: "02:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "07:00", closeTime: "01:00", isOpen: true)
        ]
    }
    
    private static func createLateNightBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "11:00", closeTime: "02:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "11:00", closeTime: "02:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "11:00", closeTime: "02:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "11:00", closeTime: "02:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "11:00", closeTime: "04:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "11:00", closeTime: "04:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "12:00", closeTime: "02:00", isOpen: true)
        ]
    }
    
    private static func createGroceryBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "07:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "07:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "07:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "07:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "07:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "07:00", closeTime: "22:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "08:00", closeTime: "20:00", isOpen: true)
        ]
    }
    
    private static func createLimitedBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "00:00", closeTime: "00:00", isOpen: false)
        ]
    }
    
    private static func createPharmacyBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "08:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "09:00", closeTime: "18:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "10:00", closeTime: "16:00", isOpen: true)
        ]
    }
    
    private static func createRetailBusinessHours() -> [BusinessHours] {
        return [
            BusinessHours(dayOfWeek: .monday, openTime: "10:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .tuesday, openTime: "10:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .wednesday, openTime: "10:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .thursday, openTime: "10:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .friday, openTime: "10:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .saturday, openTime: "10:00", closeTime: "20:00", isOpen: true),
            BusinessHours(dayOfWeek: .sunday, openTime: "12:00", closeTime: "18:00", isOpen: true)
        ]
    }
}

// MARK: - Partner Category Extension

extension PartnerCategory {
    /// Get partners for this specific category from German data
    var germanPartners: [Partner] {
        switch self {
        case .restaurant:
            return GermanPartnerData.restaurantPartners
        case .grocery:
            return GermanPartnerData.groceryPartners
        case .pharmacy:
            return GermanPartnerData.pharmacyPartners
        case .retail:
            return GermanPartnerData.retailPartners
        }
    }
}