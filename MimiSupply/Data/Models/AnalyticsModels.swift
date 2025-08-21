//
//  AnalyticsModels.swift
//  MimiSupply
//
//  Created by Kiro on 16.08.25.
//

import Foundation

// MARK: - Revenue Analytics

struct RevenueDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let amount: Double
    let orderCount: Int
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

// MARK: - Product Analytics

struct TopProduct: Identifiable, Codable {
    let id: String
    let name: String
    let revenue: Double
    let orderCount: Int
    let imageURL: URL?
    
    // Computed property for cents-based revenue
    var revenueCents: Int {
        return Int(revenue * 100)
    }
    
    var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: revenue)) ?? "$0.00"
    }
}

// MARK: - Key Metrics

struct KeyMetric: Identifiable, Codable {
    let id = UUID()
    let title: String
    let value: String
    let percentageChange: Double?
    let icon: String
    
    var changeText: String {
        guard let change = percentageChange else { return "" }
        let prefix = change >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", change))%"
    }
}

// MARK: - Order Analytics

struct OrderAnalytics: Codable {
    let totalOrders: Int
    let completedOrders: Int
    let cancelledOrders: Int
    let averageOrderValue: Double
    let completionRate: Double
    let peakOrderHour: Int
    
    init() {
        self.totalOrders = 0
        self.completedOrders = 0
        self.cancelledOrders = 0
        self.averageOrderValue = 0.0
        self.completionRate = 0.0
        self.peakOrderHour = 12
    }
    
    var formattedAverageOrderValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: averageOrderValue)) ?? "$0.00"
    }
    
    var formattedCompletionRate: String {
        return String(format: "%.1f%%", completionRate * 100)
    }
}

// MARK: - Customer Analytics

struct CustomerInsights: Codable {
    let totalCustomers: Int
    let newCustomers: Int
    let returningCustomers: Int
    let averageOrdersPerCustomer: Double
    let customerRetentionRate: Double
    let customerSatisfactionScore: Double
    
    init() {
        self.totalCustomers = 0
        self.newCustomers = 0
        self.returningCustomers = 0
        self.averageOrdersPerCustomer = 0.0
        self.customerRetentionRate = 0.0
        self.customerSatisfactionScore = 0.0
    }
    
    var formattedRetentionRate: String {
        return String(format: "%.1f%%", customerRetentionRate * 100)
    }
}

// MARK: - Performance Insights

struct PartnerInsightData: Codable {
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
    
    init(
        keyMetrics: [KeyMetric], 
        revenueData: [RevenueDataPoint], 
        orderAnalytics: OrderAnalytics, 
        customerInsights: CustomerInsights, 
        topProducts: [TopProduct], 
        generatedAt: Date,
        revenueChangePercent: Double = 15.5,
        ordersChangePercent: Double = 12.3,
        averageRating: Double = 4.6,
        peakOrderHour: Int? = 12,
        topProductName: String? = nil
    ) {
        self.keyMetrics = keyMetrics
        self.revenueData = revenueData
        self.orderAnalytics = orderAnalytics
        self.customerInsights = customerInsights
        self.topProducts = topProducts
        self.generatedAt = generatedAt
        self.revenueChangePercent = revenueChangePercent
        self.ordersChangePercent = ordersChangePercent
        self.averageRating = averageRating
        self.peakOrderHour = peakOrderHour
        self.topProductName = topProductName ?? topProducts.first?.name
    }
}

// MARK: - Chart Data

struct ChartDataPoint: Identifiable, Codable {
    let id = UUID()
    let date: Date
    let value: Double
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
    
    init(date: Date, value: Int) {
        self.date = date
        self.value = Double(value)
    }
}

// MARK: - Key Metrics Dashboard

struct KeyMetrics: Codable {
    let totalRevenue: Int
    let revenueChange: Double
    let totalOrders: Int
    let ordersChange: Double
    let averageOrderValue: Int
    let aovChange: Double
    let averageRating: Double
    let ratingChange: Double
    
    var formattedTotalRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(totalRevenue) / 100.0)) ?? "$0.00"
    }
    
    var formattedAverageOrderValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(averageOrderValue) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Performance Insights

enum InsightType: String, Codable {
    case positive = "positive"
    case warning = "warning"
    case info = "info"
}

struct PerformanceInsight: Identifiable, Codable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    
    var iconName: String {
        switch type {
        case .positive:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var iconColor: String {
        switch type {
        case .positive:
            return "green"
        case .warning:
            return "orange"
        case .info:
            return "blue"
        }
    }
}

// TimeRange is defined in Data/Models/TimeRange.swift