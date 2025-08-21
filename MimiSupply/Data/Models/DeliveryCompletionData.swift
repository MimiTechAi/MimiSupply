//
//  DeliveryCompletionData.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation

/// Data model for delivery completion information
struct DeliveryCompletionData: Codable, Sendable, Identifiable {
    let id: String
    let orderId: String
    let driverId: String
    let completedAt: Date
    let photoData: Data?
    let notes: String?
    let customerSignature: Data?
    let customerRating: Double?
    let customerFeedback: String?
    
    init(
        id: String = UUID().uuidString,
        orderId: String,
        driverId: String,
        completedAt: Date,
        photoData: Data? = nil,
        notes: String? = nil,
        customerSignature: Data? = nil,
        customerRating: Double? = nil,
        customerFeedback: String? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.driverId = driverId
        self.completedAt = completedAt
        self.photoData = photoData
        self.notes = notes
        self.customerSignature = customerSignature
        self.customerRating = customerRating
        self.customerFeedback = customerFeedback
    }
}
