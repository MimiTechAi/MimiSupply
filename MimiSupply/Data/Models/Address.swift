//
//  Address.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Address model for delivery locations and business addresses
struct Address: Codable, Sendable, Equatable, Hashable {
    let street: String
    let city: String
    let state: String
    let postalCode: String
    
    // Convenience property for backward compatibility
    var zipCode: String { postalCode }
    let country: String
    let apartment: String?
    let deliveryInstructions: String?
    
    init(
        street: String,
        city: String,
        state: String,
        postalCode: String,
        country: String,
        apartment: String? = nil,
        deliveryInstructions: String? = nil
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.apartment = apartment
        self.deliveryInstructions = deliveryInstructions
    }
    
    /// Formatted address string for display
    var formattedAddress: String {
        var components = [street]
        
        if let apartment = apartment, !apartment.isEmpty {
            components[0] += ", \(apartment)"
        }
        
        components.append("\(city), \(state) \(postalCode)")
        components.append(country)
        
        return components.joined(separator: "\n")
    }
    
    /// Single line formatted address
    var singleLineAddress: String {
        var components = [street]
        
        if let apartment = apartment, !apartment.isEmpty {
            components[0] += ", \(apartment)"
        }
        
        components.append("\(city), \(state) \(postalCode)")
        
        return components.joined(separator: ", ")
    }
}