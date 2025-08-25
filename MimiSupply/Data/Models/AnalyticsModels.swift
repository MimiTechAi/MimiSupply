//
//  AnalyticsModels.swift
//  MimiSupply
//
//  Created by Kiro on 16.08.25.
//

import Foundation

// MARK: - Additional Analytics Models for Premium Dashboard

struct KeyMetrics {
    let totalRevenue: Int // in cents
    let revenueChange: Double
    let totalOrders: Int
    let ordersChange: Double
    let averageOrderValue: Int // in cents
    let aovChange: Double
    let averageRating: Double
    let ratingChange: Double
}

struct AnalyticsChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
    
    static func == (lhs: AnalyticsChartDataPoint, rhs: AnalyticsChartDataPoint) -> Bool {
        return lhs.date == rhs.date && lhs.value == rhs.value
    }
}

struct TopProduct: Identifiable {
    let id: String
    let name: String
    let revenue: Double
    let orderCount: Int
    let imageURL: URL?
}

struct PerformanceInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    
    enum InsightType {
        case positive
        case warning
        case info
    }
}

// MARK: - CloudKit Response Models

struct PartnerAnalytics {
    let totalRevenue: Double
    let totalOrders: Int
    let averageOrderValue: Double
    let customerCount: Int
    let timeRange: TimeRange
    let totalRevenueCents: Int
    let revenueChangePercent: Double
    let ordersChangePercent: Double
    let averageOrderValueCents: Int
    let aovChangePercent: Double
    let averageRating: Double
    let ratingChangePercent: Double
}

struct RevenueDataPoint {
    let date: Date
    let amount: Double
    let orderCount: Int
}

struct OrdersDataPoint {
    let date: Date
    let orderCount: Int
}

struct TopProductData {
    let productId: String
    let productName: String
    let orderCount: Int
    let revenueCents: Int
}

struct PartnerInsightData {
    let keyMetrics: [KeyMetric]
    let revenueData: [RevenueDataPoint]
    let orderAnalytics: OrderAnalytics
    let customerInsights: CustomerInsights
    let topProducts: [TopProduct]
    let generatedAt: Date
    let revenueChangePercent: Double
    let ordersChangePercent: Double
    let averageRating: Double
    let peakOrderHour: Int?
    let topProductName: String?
}

struct KeyMetric {
    let title: String
    let value: String
    let percentageChange: Double?
    let icon: String
}

struct OrderAnalytics {
    let totalOrders: Int
    let averageOrderValue: Double
    let completionRate: Double
    let peakOrderHour: Int
    
    init(totalOrders: Int = 150, averageOrderValue: Double = 83.33, completionRate: Double = 0.94, peakOrderHour: Int = 18) {
        self.totalOrders = totalOrders
        self.averageOrderValue = averageOrderValue
        self.completionRate = completionRate
        self.peakOrderHour = peakOrderHour
    }
    
    var formattedAverageOrderValue: String {
        return String(format: "€%.2f", averageOrderValue)
    }
    
    var formattedCompletionRate: String {
        return String(format: "%.1f%%", completionRate * 100)
    }
}

struct CustomerInsights {
    let totalCustomers: Int
    let newCustomers: Int
    let returningCustomers: Int
    let retentionRate: Double
    let customerSatisfactionScore: Double
    
    init(totalCustomers: Int = 89, newCustomers: Int = 23, returningCustomers: Int = 66, retentionRate: Double = 0.74, customerSatisfactionScore: Double = 4.3) {
        self.totalCustomers = totalCustomers
        self.newCustomers = newCustomers
        self.returningCustomers = returningCustomers
        self.retentionRate = retentionRate
        self.customerSatisfactionScore = customerSatisfactionScore
    }
    
    var formattedRetentionRate: String {
        return String(format: "%.1f%%", retentionRate * 100)
    }
}

// MARK: - TimeRange is defined in Data/Models/TimeRange.swift