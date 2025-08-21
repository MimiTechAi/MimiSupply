//
//  Driver.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 14.08.25.
//

import Foundation

/// Driver model representing delivery drivers in the system
struct Driver: Codable, Sendable, Identifiable {
    let id: String
    let userId: String
    let name: String
    let phoneNumber: String
    let profileImageURL: URL?
    let vehicleType: VehicleType
    let licensePlate: String
    let isOnline: Bool
    let isAvailable: Bool
    let currentLocation: Coordinate?
    let rating: Double
    let completedDeliveries: Int
    let verificationStatus: VerificationStatus
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        name: String,
        phoneNumber: String,
        profileImageURL: URL? = nil,
        vehicleType: VehicleType,
        licensePlate: String,
        isOnline: Bool = false,
        isAvailable: Bool = false,
        currentLocation: Coordinate? = nil,
        rating: Double = 0.0,
        completedDeliveries: Int = 0,
        verificationStatus: VerificationStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.vehicleType = vehicleType
        self.licensePlate = licensePlate
        self.isOnline = isOnline
        self.isAvailable = isAvailable
        self.currentLocation = currentLocation
        self.rating = rating
        self.completedDeliveries = completedDeliveries
        self.verificationStatus = verificationStatus
        self.createdAt = createdAt
    }
}

/// Vehicle types for drivers
enum VehicleType: String, CaseIterable, Codable, Sendable {
    case bicycle
    case scooter
    case motorcycle
    case car
    case van
    
    var displayName: String {
        switch self {
        case .bicycle:
            return "Bicycle"
        case .scooter:
            return "Scooter"
        case .motorcycle:
            return "Motorcycle"
        case .car:
            return "Car"
        case .van:
            return "Van"
        }
    }
    
    var iconName: String {
        switch self {
        case .bicycle:
            return "bicycle"
        case .scooter:
            return "scooter"
        case .motorcycle:
            return "motorcycle"
        case .car:
            return "car"
        case .van:
            return "truck.box"
        }
    }
}

/// Driver location tracking model
struct DriverLocation: Codable, Sendable, Equatable {
    let driverId: String
    let location: Coordinate
    let heading: Double?
    let speed: Double?
    let accuracy: Double
    let timestamp: Date
    
    init(
        driverId: String,
        location: Coordinate,
        heading: Double? = nil,
        speed: Double? = nil,
        accuracy: Double,
        timestamp: Date = Date()
    ) {
        self.driverId = driverId
        self.location = location
        self.heading = heading
        self.speed = speed
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
}

/// Verification status for drivers
enum VerificationStatus: String, CaseIterable, Codable, Sendable {
    case pending
    case verified
    case rejected
    case suspended
    
    var displayName: String {
        switch self {
        case .pending:
            return "Pending Verification"
        case .verified:
            return "Verified"
        case .rejected:
            return "Verification Rejected"
        case .suspended:
            return "Suspended"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending:
            return "clock"
        case .verified:
            return "checkmark.shield"
        case .rejected:
            return "xmark.shield"
        case .suspended:
            return "pause.circle"
        }
    }
}