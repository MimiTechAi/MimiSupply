//
//  GermanPartnerData.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation
import CoreLocation

/// German partner data for realistic demo experience
struct GermanPartnerData {
    
    // MARK: - Restaurant Partners
    static let restaurantPartners: [Partner] = [
        Partner(
            id: "mcdonalds_berlin_mitte",
            name: "McDonald's Berlin Mitte",
            category: .restaurant,
            description: "Weltbekannte Burger-Kette mit schnellem Service und klassischen Favoriten wie Big Mac und McNuggets.",
            address: Address(
                street: "Unter den Linden 1",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10117",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888),
            phoneNumber: "+49 30 20457800",
            email: "berlin.mitte@mcdonalds.de",
            heroImageURL: nil,
            logoURL: nil,
            heroAssetName: "hero_mcdonalds",
            logoAssetName: "logo_mcdonalds",
            isVerified: true,
            isActive: true,
            rating: 4.2,
            reviewCount: 1247,
            openingHours: createStandardBusinessHours(),
            deliveryRadius: 3.0,
            minimumOrderAmount: 500,
            estimatedDeliveryTime: 15
        ),
        Partner(
            id: "burgerking_alexanderplatz",
            name: "Burger King Alexanderplatz",
            category: .restaurant,
            description: "Home of the Whopper - flame-grilled Burger mit einzigartigem Geschmack.",
            address: Address(
                street: "Alexanderplatz 9",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10178",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5214, longitude: 13.4132),
            phoneNumber: "+49 30 24728450",
            email: "alexanderplatz@burgerking.de",
            isVerified: true,
            isActive: true,
            rating: 4.0,
            reviewCount: 892,
            openingHours: createExtendedBusinessHours(),
            deliveryRadius: 4.0,
            minimumOrderAmount: 600,
            estimatedDeliveryTime: 20
        ),
        Partner(
            id: "pizza_hut_friedrichshain",
            name: "Pizza Hut Friedrichshain",
            category: .restaurant,
            description: "Authentische italienische Pizza mit frischen Zutaten und knusprigem Teig.",
            address: Address(
                street: "Warschauer Straße 58",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10243",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5065, longitude: 13.4493),
            phoneNumber: "+49 30 29357920",
            email: "friedrichshain@pizzahut.de",
            isVerified: true,
            isActive: true,
            rating: 4.3,
            reviewCount: 634,
            openingHours: createLateNightBusinessHours(),
            deliveryRadius: 5.0,
            minimumOrderAmount: 800,
            estimatedDeliveryTime: 25
        )
    ]
    
    // MARK: - Grocery Partners
    static let groceryPartners: [Partner] = [
        Partner(
            id: "rewe_alexanderplatz",
            name: "REWE Supermarkt Alexanderplatz",
            category: .grocery,
            description: "Frische Lebensmittel, Bio-Produkte und alles für den täglichen Bedarf in bester Qualität.",
            address: Address(
                street: "Alexanderplatz 3-5",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10178",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5219, longitude: 13.4132),
            phoneNumber: "+49 30 24758900",
            email: "alexanderplatz@rewe.de",
            heroImageURL: nil,
            logoURL: nil,
            heroAssetName: "hero_rewe",
            logoAssetName: "logo_rewe",
            isVerified: true,
            isActive: true,
            rating: 4.4,
            reviewCount: 1523,
            openingHours: createGroceryBusinessHours(),
            deliveryRadius: 6.0,
            minimumOrderAmount: 1500,
            estimatedDeliveryTime: 45
        ),
        Partner(
            id: "edeka_prenzlauer_berg",
            name: "EDEKA Prenzlauer Berg",
            category: .grocery,
            description: "Regionaler Supermarkt mit großer Auswahl an frischen und lokalen Produkten.",
            address: Address(
                street: "Schönhauser Allee 124",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10437",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5311, longitude: 13.4104),
            phoneNumber: "+49 30 44359870",
            email: "prenzlauerberg@edeka.de",
            heroImageURL: URL(string: "https://cdn.mimisupply.ai/premium/edeka-hero.jpg"),
            logoURL: URL(string: "https://cdn.mimisupply.ai/premium/edeka-logo.png"),
            isVerified: true,
            isActive: true,
            rating: 4.6,
            reviewCount: 987,
            openingHours: createLimitedBusinessHours(),
            deliveryRadius: 4.5,
            minimumOrderAmount: 2000,
            estimatedDeliveryTime: 50
        )
    ]
    
    // MARK: - Pharmacy Partners
    static let pharmacyPartners: [Partner] = [
        Partner(
            id: "docmorris_berlin",
            name: "DocMorris Apotheke Berlin",
            category: .pharmacy,
            description: "Ihre Online-Apotheke mit schneller Lieferung von Medikamenten und Gesundheitsprodukten.",
            address: Address(
                street: "Friedrichstraße 95",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10117",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5170, longitude: 13.3888),
            phoneNumber: "+49 30 20904500",
            email: "berlin@docmorris.de",
            heroImageURL: nil,
            logoURL: nil,
            heroAssetName: "hero_docmorris",
            logoAssetName: "logo_docmorris",
            isVerified: true,
            isActive: true,
            rating: 4.8,
            reviewCount: 2341,
            openingHours: createPharmacyBusinessHours(),
            deliveryRadius: 8.0,
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: 30
        )
    ]
    
    // MARK: - Electronics Partners
    static let electronicsPartners: [Partner] = [
        Partner(
            id: "mediamarkt_alexanderplatz",
            name: "MediaMarkt Alexanderplatz",
            category: .electronics,
            description: "Ich bin doch nicht blöd! Technik-Fachmarkt mit großer Auswahl an Elektronik und Multimedia.",
            address: Address(
                street: "Alexanderplatz 5",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10178",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5214, longitude: 13.4132),
            phoneNumber: "+49 30 24758000",
            email: "alexanderplatz@mediamarkt.de",
            heroImageURL: nil,
            logoURL: nil,
            heroAssetName: "hero_mediamarkt",
            logoAssetName: "logo_mediamarkt",
            isVerified: true,
            isActive: true,
            rating: 4.1,
            reviewCount: 1876,
            openingHours: createRetailBusinessHours(),
            deliveryRadius: 10.0,
            minimumOrderAmount: 5000,
            estimatedDeliveryTime: 60
        )
    ]

    static let bakeryPartners: [Partner] = [
        Partner(
            id: "baeckerei_kamps",
            name: "Bäckerei Kamps",
            category: .bakery,
            description: "Traditionsbäckerei mit frischen Brötchen, Broten und feinem Gebäck.",
            address: Address(
                street: "Brotstraße 7",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10115",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5205, longitude: 13.4095),
            phoneNumber: "+49 30 90207500",
            email: "mitte@kamps.de",
            heroAssetName: "hero_kamps",
            logoAssetName: "logo_kamps",
            isVerified: true,
            isActive: true,
            rating: 4.6,
            reviewCount: 302,
            openingHours: createStandardBusinessHours(),
            deliveryRadius: 2.5,
            minimumOrderAmount: 300,
            estimatedDeliveryTime: 25
        )
    ]

    static let caféPartners: [Partner] = [
        Partner(
            id: "cafe_musik",
            name: "Café Musik",
            category: .coffee,
            description: "Gemütliches Café mit Spezialitätenkaffee, Kuchen und Live-Musik.",
            address: Address(
                street: "Kaffeegasse 3",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10117",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5185, longitude: 13.3911),
            phoneNumber: "+49 30 90110202",
            email: "info@cafemusik.de",
            heroAssetName: "hero_cafemusik",
            logoAssetName: "logo_cafemusik",
            isVerified: true,
            isActive: true,
            rating: 4.8,
            reviewCount: 150,
            openingHours: createStandardBusinessHours(),
            deliveryRadius: 2.0,
            minimumOrderAmount: 200,
            estimatedDeliveryTime: 20
        )
    ]

    static let flowerPartners: [Partner] = [
        Partner(
            id: "blumenfee_berlin",
            name: "Blumenfee Berlin",
            category: .flowers,
            description: "Regionale Floristik mit täglich frischen Blumensträußen und Gestecken.",
            address: Address(
                street: "Blumengasse 16",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10119",
                country: "Deutschland"
            ),
            location: CLLocationCoordinate2D(latitude: 52.5303, longitude: 13.4001),
            phoneNumber: "+49 30 90482010",
            email: "info@blumenfee.de",
            heroAssetName: "hero_blumenfee",
            logoAssetName: "logo_blumenfee",
            isVerified: true,
            isActive: true,
            rating: 4.9,
            reviewCount: 109,
            openingHours: createStandardBusinessHours(),
            deliveryRadius: 4.0,
            minimumOrderAmount: 500,
            estimatedDeliveryTime: 40
        )
    ]
    
    // MARK: - All Partners
    static var allPartners: [Partner] {
        return restaurantPartners + groceryPartners + pharmacyPartners + electronicsPartners + bakeryPartners + caféPartners + flowerPartners
    }
    
    // MARK: - Helper Methods
    static func getPartners(for category: PartnerCategory) -> [Partner] {
        return allPartners.filter { $0.category == category }
    }
    
    static func getPartner(by id: String) -> Partner? {
        return allPartners.first { $0.id == id }
    }
    
    static func getFeaturedPartners() -> [Partner] {
        return [
            restaurantPartners[0], // McDonald's
            groceryPartners[0],    // REWE
            pharmacyPartners[0],   // DocMorris
            electronicsPartners[0] // MediaMarkt
        ]
    }
    
    // MARK: - Business Hours Helpers
    private static func createStandardBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "23:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "23:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "23:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "23:00"),
            .friday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "01:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "01:00"),
            .sunday: OpeningHours(isOpen: true, openTime: "09:00", closeTime: "23:00")
        ]
    }
    
    private static func createExtendedBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "06:00", closeTime: "24:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "06:00", closeTime: "24:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "06:00", closeTime: "24:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "06:00", closeTime: "24:00"),
            .friday: OpeningHours(isOpen: true, openTime: "06:00", closeTime: "02:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "06:00", closeTime: "02:00"),
            .sunday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "24:00")
        ]
    }
    
    private static func createLateNightBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "24:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "24:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "24:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "02:00"),
            .friday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "03:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "11:00", closeTime: "03:00"),
            .sunday: OpeningHours(isOpen: true, openTime: "12:00", closeTime: "24:00")
        ]
    }
    
    private static func createGroceryBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
            .friday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "07:00", closeTime: "22:00"),
            .sunday: OpeningHours(isOpen: false)
        ]
    }
    
    private static func createLimitedBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .friday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "18:00"),
            .sunday: OpeningHours(isOpen: false)
        ]
    }
    
    private static func createPharmacyBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .friday: OpeningHours(isOpen: true, openTime: "08:00", closeTime: "20:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "09:00", closeTime: "18:00"),
            .sunday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "16:00")
        ]
    }
    
    private static func createRetailBusinessHours() -> [WeekDay: OpeningHours] {
        return [
            .monday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
            .tuesday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
            .wednesday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
            .thursday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
            .friday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
            .saturday: OpeningHours(isOpen: true, openTime: "10:00", closeTime: "20:00"),
            .sunday: OpeningHours(isOpen: false)
        ]
    }
}

// MARK: - Partner Category Extensions
extension PartnerCategory {
    var germanPartners: [Partner] {
        switch self {
        case .restaurant:
            return GermanPartnerData.restaurantPartners
        case .grocery:
            return GermanPartnerData.groceryPartners
        case .pharmacy:
            return GermanPartnerData.pharmacyPartners
        case .electronics:
            return GermanPartnerData.electronicsPartners
        case .bakery:
            return GermanPartnerData.bakeryPartners
        case .coffee:
            return GermanPartnerData.caféPartners
        case .flowers:
            return GermanPartnerData.flowerPartners
        case .retail, .convenience, .alcohol:
            return [] // No German partners defined for these categories yet
        }
    }
}