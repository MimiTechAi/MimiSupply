//
//  DemoAccounts.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import Foundation

/// Demo login credentials for testing
struct DemoAccounts {
    
    // MARK: - Demo Customer Accounts
    static let demoCustomers: [DemoUser] = [
        DemoUser(
            id: "customer_1",
            email: "kunde@test.de",
            password: "kunde123",
            role: .customer,
            name: "Max Mustermann",
            phone: "+49 30 12345678",
            address: Address(
                street: "Alexanderplatz 1",
                city: "Berlin",
                state: "Berlin",
                postalCode: "10178",
                country: "Deutschland"
            )
        ),
        DemoUser(
            id: "customer_2",
            email: "anna.schmidt@test.de",
            password: "anna123",
            role: .customer,
            name: "Anna Schmidt",
            phone: "+49 89 87654321",
            address: Address(
                street: "Marienplatz 8",
                city: "München",
                state: "Bayern",
                postalCode: "80331",
                country: "Deutschland"
            )
        )
    ]
    
    // MARK: - Demo Partner Accounts
    static let demoPartners: [DemoUser] = [
        DemoUser(
            id: "partner_mcdonalds",
            email: "mcdonalds@partner.de",
            password: "partner123",
            role: .partner,
            name: "McDonald's Berlin Mitte",
            phone: "+49 30 11111111",
            partnerId: "mcdonalds_berlin_mitte",
            businessCategory: .restaurant
        ),
        DemoUser(
            id: "partner_rewe",
            email: "rewe@partner.de",
            password: "partner123",
            role: .partner,
            name: "REWE Supermarket",
            phone: "+49 30 22222222",
            partnerId: "rewe_alexanderplatz",
            businessCategory: .grocery
        ),
        DemoUser(
            id: "partner_docmorris",
            email: "docmorris@partner.de",
            password: "partner123",
            role: .partner,
            name: "DocMorris Apotheke",
            phone: "+49 30 33333333",
            partnerId: "docmorris_berlin",
            businessCategory: .pharmacy
        ),
        DemoUser(
            id: "partner_mediamarkt",
            email: "mediamarkt@partner.de",
            password: "partner123",
            role: .partner,
            name: "MediaMarkt Berlin",
            phone: "+49 30 44444444",
            partnerId: "mediamarkt_alexanderplatz",
            businessCategory: .electronics
        )
    ]
    
    // MARK: - Demo Driver Accounts
    static let demoDrivers: [DemoUser] = [
        DemoUser(
            id: "driver_1",
            email: "fahrer1@test.de",
            password: "fahrer123",
            role: .driver,
            name: "Thomas Weber",
            phone: "+49 30 55555555",
            driverInfo: DemoDriverInfo(
                licenseNumber: "B12345678",
                vehicleType: "Fahrrad",
                vehiclePlate: "B-MW-1234",
                isAvailable: true,
                rating: 4.8,
                totalDeliveries: 247
            )
        ),
        DemoUser(
            id: "driver_2",
            email: "fahrer2@test.de",
            password: "fahrer123",
            role: .driver,
            name: "Sarah Klein",
            phone: "+49 30 66666666",
            driverInfo: DemoDriverInfo(
                licenseNumber: "B87654321",
                vehicleType: "Motorroller",
                vehiclePlate: "B-SK-9876",
                isAvailable: true,
                rating: 4.9,
                totalDeliveries: 189
            )
        ),
        DemoUser(
            id: "driver_3",
            email: "fahrer3@test.de",
            password: "fahrer123",
            role: .driver,
            name: "Michael Fischer",
            phone: "+49 30 77777777",
            driverInfo: DemoDriverInfo(
                licenseNumber: "B11223344",
                vehicleType: "Auto",
                vehiclePlate: "B-MF-5678",
                isAvailable: false,
                rating: 4.7,
                totalDeliveries: 312
            )
        )
    ]
    
    // MARK: - All Demo Accounts
    static var allAccounts: [DemoUser] {
        return demoCustomers + demoPartners + demoDrivers
    }
    
    // MARK: - Helper Methods
    static func findUser(email: String, password: String) -> DemoUser? {
        return allAccounts.first { user in
            user.email.lowercased() == email.lowercased() && user.password == password
        }
    }
    
    static func getPartnerAccount(for partnerId: String) -> DemoUser? {
        return demoPartners.first { $0.partnerId == partnerId }
    }
    
    static func getAvailableDrivers() -> [DemoUser] {
        return demoDrivers.filter { $0.driverInfo?.isAvailable == true }
    }
}

// MARK: - Demo User Model
struct DemoUser: Identifiable, Codable {
    let id: String
    let email: String
    let password: String
    let role: UserRole
    let name: String
    let phone: String
    let address: Address?
    let partnerId: String?
    let businessCategory: PartnerCategory?
    let driverInfo: DemoDriverInfo?
    
    init(
        id: String,
        email: String,
        password: String,
        role: UserRole,
        name: String,
        phone: String,
        address: Address? = nil,
        partnerId: String? = nil,
        businessCategory: PartnerCategory? = nil,
        driverInfo: DemoDriverInfo? = nil
    ) {
        self.id = id
        self.email = email
        self.password = password
        self.role = role
        self.name = name
        self.phone = phone
        self.address = address
        self.partnerId = partnerId
        self.businessCategory = businessCategory
        self.driverInfo = driverInfo
    }
}

// MARK: - Demo Driver Info
struct DemoDriverInfo: Codable {
    let licenseNumber: String
    let vehicleType: String
    let vehiclePlate: String
    let isAvailable: Bool
    let rating: Double
    let totalDeliveries: Int
    
    var formattedRating: String {
        String(format: "%.1f", rating)
    }
}