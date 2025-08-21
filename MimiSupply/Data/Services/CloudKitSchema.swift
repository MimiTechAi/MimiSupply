//
//  CloudKitSchema.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// CloudKit record types and field names for consistent schema management
enum CloudKitSchema {
    
    // MARK: - Public Database Records
    
    enum Partner {
        static let recordType = "Partner"
        static let name = "name"
        static let category = "category"
        static let description = "description"
        static let street = "street"
        static let city = "city"
        static let state = "state"
        static let postalCode = "postalCode"
        static let country = "country"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let phoneNumber = "phoneNumber"
        static let email = "email"
        static let heroImage = "heroImage"
        static let logo = "logo"
        static let isVerified = "isVerified"
        static let isActive = "isActive"
        static let rating = "rating"
        static let reviewCount = "reviewCount"
        static let deliveryRadius = "deliveryRadius"
        static let minimumOrderAmount = "minimumOrderAmount"
        static let estimatedDeliveryTime = "estimatedDeliveryTime"
        static let openingHours = "openingHours"
        static let createdAt = "createdAt"
    }
    
    enum Product {
        static let recordType = "Product"
        static let partnerId = "partnerId"
        static let name = "name"
        static let description = "description"
        static let priceCents = "priceCents"
        static let originalPriceCents = "originalPriceCents"
        static let category = "category"
        static let images = "images"
        static let isAvailable = "isAvailable"
        static let stockQuantity = "stockQuantity"
        static let nutritionInfo = "nutritionInfo"
        static let allergens = "allergens"
        static let tags = "tags"
        static let weight = "weight"
        static let dimensions = "dimensions"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }
    
    // MARK: - Private Database Records
    
    enum UserProfile {
        static let recordType = "UserProfile"
        static let appleUserID = "appleUserID"
        static let email = "email"
        static let fullName = "fullName"
        static let role = "role"
        static let phoneNumber = "phoneNumber"
        static let profileImage = "profileImage"
        static let isVerified = "isVerified"
        static let createdAt = "createdAt"
        static let lastActiveAt = "lastActiveAt"
        static let deviceToken = "deviceToken"
    }
    
    enum Order {
        static let recordType = "Order"
        static let customerId = "customerId"
        static let partnerId = "partnerId"
        static let driverId = "driverId"
        static let items = "items"
        static let status = "status"
        static let subtotalCents = "subtotalCents"
        static let deliveryFeeCents = "deliveryFeeCents"
        static let platformFeeCents = "platformFeeCents"
        static let taxCents = "taxCents"
        static let tipCents = "tipCents"
        static let totalCents = "totalCents"
        static let deliveryAddress = "deliveryAddress"
        static let deliveryInstructions = "deliveryInstructions"
        static let estimatedDeliveryTime = "estimatedDeliveryTime"
        static let actualDeliveryTime = "actualDeliveryTime"
        static let paymentMethod = "paymentMethod"
        static let paymentStatus = "paymentStatus"
        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
    }
    
    enum Driver {
        static let recordType = "Driver"
        static let userId = "userId"
        static let name = "name"
        static let phoneNumber = "phoneNumber"
        static let profileImage = "profileImage"
        static let vehicleType = "vehicleType"
        static let licensePlate = "licensePlate"
        static let isOnline = "isOnline"
        static let isAvailable = "isAvailable"
        static let currentLatitude = "currentLatitude"
        static let currentLongitude = "currentLongitude"
        static let rating = "rating"
        static let completedDeliveries = "completedDeliveries"
        static let verificationStatus = "verificationStatus"
        static let createdAt = "createdAt"
    }
    
    enum DriverLocation {
        static let recordType = "DriverLocation"
        static let driverId = "driverId"
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let heading = "heading"
        static let speed = "speed"
        static let accuracy = "accuracy"
        static let timestamp = "timestamp"
    }
    
    enum DeliveryCompletion {
        static let recordType = "DeliveryCompletion"
        static let orderId = "orderId"
        static let driverId = "driverId"
        static let completedAt = "completedAt"
        static let photoAsset = "photoAsset"
        static let notes = "notes"
        static let customerRating = "customerRating"
        static let customerFeedback = "customerFeedback"
    }
    
    // MARK: - Subscription IDs
    
    enum Subscriptions {
        static let orderUpdates = "order-updates"
        static let driverLocationUpdates = "driver-location-updates"
        static let partnerOrderUpdates = "partner-order-updates"
    }
}