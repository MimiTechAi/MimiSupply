import SwiftUI
import Combine

// Temporary ChartDataPoint struct since InteractiveCharts.swift was moved aside
struct ChartDataPoint: Identifiable, Codable {
    let id = UUID()
    let x: Double
    let y: Double
    let date: Date
    let value: Double
}

@MainActor
final class AnalyticsDashboardViewModel: ObservableObject {
    @Published var keyMetrics = KeyMetrics(
        totalRevenue: 0,
        revenueChange: 0.0,
        totalOrders: 0,
        ordersChange: 0.0,
        averageOrderValue: 0,
        aovChange: 0.0,
        averageRating: 0.0,
        ratingChange: 0.0
    )
    @Published var revenueData: [ChartDataPoint] = []
    @Published var ordersData: [ChartDataPoint] = []
    @Published var topProducts: [TopProduct] = []
    @Published var insights: [PerformanceInsight] = []
    @Published var isLoading: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    
    private let cloudKitService: CloudKitService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        authService: AuthenticationService = AuthenticationServiceImpl.shared
    ) {
        self.cloudKitService = cloudKitService
        self.authService = authService
    }
    
    func loadAnalytics(for timeRange: TimeRange) async {
        isLoading = true
        
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            async let metricsTask: Void = loadKeyMetrics(for: timeRange, partnerId: currentUser.id)
            async let revenueTask: Void = loadRevenueData(for: timeRange, partnerId: currentUser.id)
            async let ordersTask: Void = loadOrdersData(for: timeRange, partnerId: currentUser.id)
            async let productsTask: Void = loadTopProducts(for: timeRange, partnerId: currentUser.id)
            async let insightsTask: Void = loadInsights(for: timeRange, partnerId: currentUser.id)
            
            try await metricsTask
            try await revenueTask
            try await ordersTask
            try await productsTask
            try await insightsTask
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refresh(for timeRange: TimeRange) async {
        await loadAnalytics(for: timeRange)
    }
    
    // MARK: - Private Methods
    
    private func loadKeyMetrics(for timeRange: TimeRange, partnerId: String) async throws {
        let analytics = try await cloudKitService.fetchPartnerAnalytics(
            partnerId: partnerId,
            timeRange: timeRange
        )
        
        keyMetrics = KeyMetrics(
            totalRevenue: analytics.totalRevenueCents,
            revenueChange: analytics.revenueChangePercent,
            totalOrders: analytics.totalOrders,
            ordersChange: analytics.ordersChangePercent,
            averageOrderValue: analytics.averageOrderValueCents,
            aovChange: analytics.aovChangePercent,
            averageRating: analytics.averageRating,
            ratingChange: analytics.ratingChangePercent
        )
    }
    
    private func loadRevenueData(for timeRange: TimeRange, partnerId: String) async throws {
        let data = try await cloudKitService.fetchRevenueChartData(
            partnerId: partnerId,
            timeRange: timeRange
        )
        
        revenueData = data.map { dataPoint in
            ChartDataPoint(
                x: dataPoint.date.timeIntervalSince1970,
                y: dataPoint.amount,
                date: dataPoint.date, 
                value: dataPoint.amount
            )
        }
    }
    
    private func loadOrdersData(for timeRange: TimeRange, partnerId: String) async throws {
        let data = try await cloudKitService.fetchOrdersChartData(
            partnerId: partnerId,
            timeRange: timeRange
        )
        
        ordersData = data.map { dataPoint in
            ChartDataPoint(
                x: dataPoint.date.timeIntervalSince1970,
                y: Double(dataPoint.orderCount),
                date: dataPoint.date, 
                value: Double(dataPoint.orderCount)
            )
        }
    }
    
    private func loadTopProducts(for timeRange: TimeRange, partnerId: String) async throws {
        let products = try await cloudKitService.fetchTopProducts(
            partnerId: partnerId,
            timeRange: timeRange,
            limit: 5
        )
        
        topProducts = products.map { product in
            TopProduct(
                id: product.productId,
                name: product.productName,
                revenue: Double(product.revenueCents) / 100.0,
                orderCount: product.orderCount,
                imageURL: nil
            )
        }
    }
    
    private func loadInsights(for timeRange: TimeRange, partnerId: String) async throws {
        let insightData = try await cloudKitService.fetchPerformanceInsights(
            partnerId: partnerId,
            timeRange: timeRange
        )
        
        insights = generateInsights(from: insightData)
    }
    
    private func generateInsights(from data: PartnerInsightData) -> [PerformanceInsight] {
        var insights: [PerformanceInsight] = []
        
        // Revenue growth insight
        if data.revenueChangePercent > 10 {
            insights.append(PerformanceInsight(
                type: .positive,
                title: "Strong Revenue Growth",
                description: "Your revenue has increased by \(String(format: "%.1f", data.revenueChangePercent))% compared to the previous period."
            ))
        } else if data.revenueChangePercent < -10 {
            insights.append(PerformanceInsight(
                type: .warning,
                title: "Revenue Decline",
                description: "Your revenue has decreased by \(String(format: "%.1f", abs(data.revenueChangePercent)))%. Consider reviewing your pricing or promotions."
            ))
        }
        
        // Order volume insight
        if data.ordersChangePercent > 15 {
            insights.append(PerformanceInsight(
                type: .positive,
                title: "Increased Order Volume",
                description: "You're receiving \(String(format: "%.1f", data.ordersChangePercent))% more orders than before."
            ))
        }
        
        // Rating insight
        if data.averageRating >= 4.5 {
            insights.append(PerformanceInsight(
                type: .positive,
                title: "Excellent Customer Satisfaction",
                description: "Your average rating of \(String(format: "%.1f", data.averageRating)) stars shows excellent customer satisfaction."
            ))
        } else if data.averageRating < 4.0 {
            insights.append(PerformanceInsight(
                type: .warning,
                title: "Rating Needs Attention",
                description: "Your average rating is \(String(format: "%.1f", data.averageRating)) stars. Focus on improving service quality."
            ))
        }
        
        // Peak hours insight
        if let peakHour = data.peakOrderHour {
            insights.append(PerformanceInsight(
                type: .info,
                title: "Peak Order Time",
                description: "Most of your orders come in around \(formatHour(peakHour)). Consider optimizing staffing for this time."
            ))
        }
        
        // Popular product insight
        if let topProduct = data.topProductName {
            insights.append(PerformanceInsight(
                type: .info,
                title: "Best Selling Product",
                description: "\(topProduct) is your most popular item. Consider creating similar offerings or promotions."
            ))
        }
        
        return insights
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - CloudKit Service Extensions
extension CloudKitService {
    func fetchPartnerAnalytics(partnerId: String, timeRange: TimeRange) async throws -> PartnerAnalytics {
        // Mock implementation - in real app, this would fetch from CloudKit
        return PartnerAnalytics(
            totalRevenue: 1250.0,
            totalOrders: 89,
            averageOrderValue: 14.04,
            customerCount: 45,
            timeRange: timeRange,
            totalRevenueCents: 125000,
            revenueChangePercent: 15.5,
            ordersChangePercent: 12.3,
            averageOrderValueCents: 1404,
            aovChangePercent: 2.8,
            averageRating: 4.6,
            ratingChangePercent: 0.2
        )
    }
    
    func fetchRevenueChartData(partnerId: String, timeRange: TimeRange) async throws -> [RevenueDataPoint] {
        // Mock implementation
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [RevenueDataPoint] = []
        
        let days = timeRange == .week ? 7 : (timeRange == .month ? 30 : 365)
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let revenue = Int.random(in: 5000...15000)
            dataPoints.append(RevenueDataPoint(date: date, amount: Double(revenue), orderCount: Int.random(in: 5...25)))
        }
        
        return dataPoints.reversed()
    }
    
    func fetchOrdersChartData(partnerId: String, timeRange: TimeRange) async throws -> [OrdersDataPoint] {
        // Mock implementation
        let calendar = Calendar.current
        let now = Date()
        var dataPoints: [OrdersDataPoint] = []
        
        let days = timeRange == .week ? 7 : (timeRange == .month ? 30 : 365)
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let orders = Int.random(in: 5...25)
            dataPoints.append(OrdersDataPoint(date: date, orderCount: orders))
        }
        
        return dataPoints.reversed()
    }
    
    func fetchTopProducts(partnerId: String, timeRange: TimeRange, limit: Int) async throws -> [TopProductData] {
        // Mock implementation
        return [
            TopProductData(
                productId: "1",
                productName: "Margherita Pizza",
                orderCount: 45,
                revenueCents: 58500
            ),
            TopProductData(
                productId: "2",
                productName: "Caesar Salad",
                orderCount: 32,
                revenueCents: 28800
            ),
            TopProductData(
                productId: "3",
                productName: "Chicken Sandwich",
                orderCount: 28,
                revenueCents: 33600
            ),
            TopProductData(
                productId: "4",
                productName: "Chocolate Cake",
                orderCount: 15,
                revenueCents: 8985
            ),
            TopProductData(
                productId: "5",
                productName: "Iced Coffee",
                orderCount: 67,
                revenueCents: 20100
            )
        ]
    }
    
    func fetchPerformanceInsights(partnerId: String, timeRange: TimeRange) async throws -> PartnerInsightData {
        // Mock implementation
        return PartnerInsightData(
            keyMetrics: [
                KeyMetric(title: "Revenue Change", value: "15.5%", percentageChange: 15.5, icon: "arrow.up"),
                KeyMetric(title: "Orders Change", value: "12.3%", percentageChange: 12.3, icon: "arrow.up"),
                KeyMetric(title: "Average Rating", value: "4.6", percentageChange: nil, icon: "star.fill")
            ],
            revenueData: [
                RevenueDataPoint(date: Date(), amount: 1250.0, orderCount: 15),
                RevenueDataPoint(date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(), amount: 1100.0, orderCount: 12)
            ],
            orderAnalytics: OrderAnalytics(),
            customerInsights: CustomerInsights(),
            topProducts: [
                TopProduct(id: "1", name: "Margherita Pizza", revenue: 225.0, orderCount: 15, imageURL: nil),
                TopProduct(id: "2", name: "Pepperoni Pizza", revenue: 192.0, orderCount: 12, imageURL: nil)
            ],
            generatedAt: Date(),
            revenueChangePercent: 15.5,
            ordersChangePercent: 12.3,
            averageRating: 4.6,
            peakOrderHour: 12,
            topProductName: "Margherita Pizza"
        )
    }
}

// MARK: - Supporting Types
// Types are now defined in Data/Models/MissingTypes.swift and Data/Models/AnalyticsModels.swift