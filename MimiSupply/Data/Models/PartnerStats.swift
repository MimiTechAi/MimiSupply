//
//  PartnerStats.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation

/// Canonical partner statistics model used across the app
struct PartnerStats: Codable, Sendable {
    // Daily metrics
    let todayOrderCount: Int
    let todayRevenueCents: Int
    
    // Aggregate metrics
    let averageRating: Double
    let totalOrders: Int
    let totalRevenueCents: Int
    let activeOrders: Int
}
