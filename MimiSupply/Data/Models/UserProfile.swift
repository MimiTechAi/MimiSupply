//
//  UserProfile.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation

// MARK: - User Type Alias
typealias User = UserProfile

// MARK: - User Profile Model

/// User profile model representing authenticated users
struct UserProfile: Codable, Sendable, Equatable, Identifiable {
    let id: String
    let appleUserID: String?
    let email: String?
    let fullName: PersonNameComponents?
    let role: UserRole
    let phoneNumber: String?
    let profileImageURL: URL?
    let isVerified: Bool
    let createdAt: Date
    let lastActiveAt: Date
    
    // Role-specific properties
    let driverProfile: DriverProfile?
    let partnerProfile: PartnerProfile?
    
    init(
        id: String,
        appleUserID: String? = nil,
        email: String? = nil,
        fullName: PersonNameComponents? = nil,
        role: UserRole,
        phoneNumber: String? = nil,
        profileImageURL: URL? = nil,
        isVerified: Bool = false,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        driverProfile: DriverProfile? = nil,
        partnerProfile: PartnerProfile? = nil
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.email = email
        self.fullName = fullName
        self.role = role
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.driverProfile = driverProfile
        self.partnerProfile = partnerProfile
    }
}

// MARK: - User Role

/// User role enumeration
enum UserRole: String, Codable, CaseIterable, Sendable {
    case customer
    case driver
    case partner
    case admin
    
    var displayName: String {
        switch self {
        case .customer:
            return "Customer"
        case .driver:
            return "Driver"
        case .partner:
            return "Partner"
        case .admin:
            return "Administrator"
        }
    }
    
    var permissions: Set<UserPermission> {
        switch self {
        case .customer:
            return [.placeOrders, .viewOrderHistory, .editProfile]
        case .driver:
            return [.acceptJobs, .updateLocation, .completeDeliveries, .viewEarnings]
        case .partner:
            return [.manageProducts, .viewAnalytics, .manageOrders, .updateBusinessInfo]
        case .admin:
            return Set(UserPermission.allCases)
        }
    }
}

// MARK: - User Permissions

/// User permissions
enum UserPermission: String, Codable, CaseIterable, Sendable {
    case placeOrders
    case viewOrderHistory
    case editProfile
    case acceptJobs
    case updateLocation
    case completeDeliveries
    case viewEarnings
    case manageProducts
    case viewAnalytics
    case manageOrders
    case updateBusinessInfo
    case adminAccess
}

// MARK: - Driver Profile

/// Driver-specific profile information
struct DriverProfile: Codable, Sendable, Equatable {
    let vehicleType: VehicleType
    let licenseNumber: String
    let isVerified: Bool
    let rating: Double
    let totalDeliveries: Int
    let isAvailable: Bool
    let currentLocation: LocationCoordinate?
    
    enum VehicleType: String, Codable, CaseIterable {
        case bicycle
        case motorcycle
        case car
        case truck
        
        var displayName: String {
            switch self {
            case .bicycle: return "Bicycle"
            case .motorcycle: return "Motorcycle"
            case .car: return "Car"
            case .truck: return "Truck"
            }
        }
    }
}

// MARK: - Partner Profile

/// Partner-specific profile information
struct PartnerProfile: Codable, Sendable, Equatable {
    let businessName: String
    let businessType: BusinessType
    let isVerified: Bool
    let rating: Double
    let totalOrders: Int
    let isActive: Bool
    let businessAddress: Address?
    
    enum BusinessType: String, Codable, CaseIterable {
        case restaurant
        case grocery
        case pharmacy
        case retail
        case other
        
        var displayName: String {
            switch self {
            case .restaurant: return "Restaurant"
            case .grocery: return "Grocery Store"
            case .pharmacy: return "Pharmacy"
            case .retail: return "Retail Store"
            case .other: return "Other"
            }
        }
    }
}

// MARK: - Location Coordinate

/// Location coordinate
struct LocationCoordinate: Codable, Sendable, Equatable {
    let latitude: Double
    let longitude: Double
}