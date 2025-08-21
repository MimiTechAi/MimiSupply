import SwiftUI
import Charts

// MARK: - Business Intelligence Dashboard
struct BusinessIntelligenceDashboard: View {
    @StateObject private var viewModel = BusinessIntelligenceViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: BusinessMetric = .revenue
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Time Range Selector
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                        .onChange(of: selectedTimeRange) { _, newValue in
                            Task {
                                await viewModel.loadData(for: newValue)
                            }
                        }
                    
                    // Key Metrics Cards
                    KeyMetricsGrid(metrics: viewModel.keyMetrics)
                    
                    // Revenue Chart
                    RevenueChartCard(
                        data: viewModel.revenueData,
                        timeRange: selectedTimeRange
                    )
                    
                    // Order Analytics
                    OrderAnalyticsCard(
                        data: viewModel.orderAnalytics,
                        timeRange: selectedTimeRange
                    )
                    
                    // Customer Insights
                    CustomerInsightsCard(
                        data: viewModel.customerInsights
                    )
                    
                    // Performance Metrics
                    PerformanceMetricsCard(
                        data: viewModel.performanceMetrics
                    )
                    
                    // Top Products
                    TopProductsCard(
                        products: viewModel.topProducts
                    )
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle("Business Intelligence")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Report") {
                            Task {
                                await viewModel.exportReport()
                            }
                        }
                        Button("Schedule Report") {
                            viewModel.showScheduleReport = true
                        }
                        Button("Share Dashboard") {
                            viewModel.showShareSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $viewModel.showScheduleReport) {
                ScheduleReportView()
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareDashboardView()
            }
        }
    }
}

// TimeRangeSelector is defined in Features/Partner/AnalyticsDashboardView.swift

// KeyMetricsGrid is defined in Features/Partner/AnalyticsDashboardView.swift

struct KeyMetricCard: View {
    let metric: KeyMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(.emerald)
                    .font(.title2)
                
                Spacer()
                
                if let change = metric.percentageChange {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text("\(abs(change), specifier: "%.1f")%")
                            .font(.caption)
                    }
                    .foregroundColor(change >= 0 ? .success : .error)
                }
            }
            
            Text(metric.value)
                .font(.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(.graphite)
            
            Text(metric.title)
                .font(.bodySmall)
                .foregroundColor(.gray600)
                .lineLimit(1)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.title): \(metric.value)")
        .accessibilityHint(metric.percentageChange.map { "Changed by \($0)%" } ?? "")
    }
}

// RevenueChartCard is defined in Features/Partner/AnalyticsDashboardView.swift

// MARK: - Order Analytics Card
struct OrderAnalyticsCard: View {
    let data: OrderAnalytics
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Order Analytics")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.sm) {
                AnalyticsRow(
                    title: "Total Orders",
                    value: "\(data.totalOrders)",
                    change: nil,
                    icon: "bag"
                )
                
                AnalyticsRow(
                    title: "Average Order Value",
                    value: data.formattedAverageOrderValue,
                    change: nil,
                    icon: "dollarsign.circle"
                )
                
                AnalyticsRow(
                    title: "Completion Rate",
                    value: data.formattedCompletionRate,
                    change: nil,
                    icon: "checkmark.circle"
                )
                
                AnalyticsRow(
                    title: "Peak Order Hour",
                    value: "\(data.peakOrderHour):00",
                    change: nil,
                    icon: "clock"
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Analytics Row
struct AnalyticsRow: View {
    let title: String
    let value: String
    let change: Double?
    let icon: String
    let isInverted: Bool
    
    init(title: String, value: String, change: Double?, icon: String, isInverted: Bool = false) {
        self.title = title
        self.value = value
        self.change = change
        self.icon = icon
        self.isInverted = isInverted
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.emerald)
                .frame(width: 20)
            
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.graphite)
            
            Spacer()
            
            Text(value)
                .font(.labelLarge)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
            
            if let change = change {
                let isPositive = isInverted ? change < 0 : change > 0
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text("\(abs(change), specifier: "%.1f")%")
                        .font(.caption2)
                }
                .foregroundColor(isPositive ? .success : .error)
                .frame(width: 50, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Customer Insights Card
struct CustomerInsightsCard: View {
    let data: CustomerInsights
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Customer Insights")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.sm) {
                InsightRow(
                    title: "New Customers",
                    description: "\(data.newCustomers) this period",
                    impact: "Growing",
                    priority: .low
                )
                
                InsightRow(
                    title: "Returning Customers",
                    description: "\(data.returningCustomers) customers with \(data.formattedRetentionRate) retention",
                    impact: "Stable",
                    priority: .medium
                )
                
                InsightRow(
                    title: "Total Customers",
                    description: "\(data.totalCustomers) customers all time",
                    impact: "Growing",
                    priority: .low
                )
                
                InsightRow(
                    title: "Satisfaction Score",
                    description: "\(String(format: "%.1f", data.customerSatisfactionScore)) out of 5.0",
                    impact: "Good",
                    priority: .low
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// InsightRow is defined in Features/Partner/AnalyticsDashboardView.swift

// MARK: - Performance Metrics Card
struct PerformanceMetricsCard: View {
    let data: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Performance Metrics")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.sm) {
                MetricRow(
                    title: "App Launch Time",
                    value: String(format: "%.2fs", data.appLaunchTime),
                    status: data.appLaunchTime < 2.0 ? .good : .warning
                )
                
                MetricRow(
                    title: "API Response Time",
                    value: String(format: "%.0fms", data.apiResponseTime),
                    status: data.apiResponseTime < 500 ? .good : .warning
                )
                
                MetricRow(
                    title: "Crash Rate",
                    value: String(format: "%.3f%%", data.crashRate),
                    status: data.crashRate < 0.1 ? .good : .error
                )
                
                MetricRow(
                    title: "Memory Usage",
                    value: String(format: "%.0fMB", data.memoryUsage),
                    status: data.memoryUsage < 200 ? .good : .warning
                )
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Metric Row
struct MetricRow: View {
    let title: String
    let value: String
    let status: MetricStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.graphite)
            
            Spacer()
            
            Text(value)
                .font(.labelLarge)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
        }
        .padding(.vertical, 2)
    }
}

// TopProductsCard is defined in Features/Partner/AnalyticsDashboardView.swift

// TopProductRow is defined in Features/Partner/AnalyticsDashboardView.swift

// MARK: - Supporting Types
// TimeRange is now defined in Data/Models/TimeRange.swift

enum BusinessMetric: String, CaseIterable {
    case revenue = "revenue"
    case orders = "orders"
    case customers = "customers"
    case performance = "performance"
}

enum MetricStatus {
    case good
    case warning
    case error
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - Missing UI Components
struct KeyMetricsGrid: View {
    let metrics: [KeyMetric]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(metrics, id: \.title) { metric in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: metric.icon)
                            .foregroundColor(.blue)
                        Spacer()
                        Text(metric.changeText)
                            .font(.caption)
                            .foregroundColor((metric.percentageChange ?? 0) >= 0 ? .green : .red)
                    }
                    Text(metric.value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(metric.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
        }
        .padding(.horizontal)
    }
}

struct RevenueChartCard: View {
    let data: [RevenueDataPoint]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Revenue Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart(data, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Revenue", dataPoint.amount)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Text("Chart requires iOS 16+")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct TopProductsCard: View {
    let products: [TopProduct]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Products")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(products.enumerated()), id: \.offset) { _, product in
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("\(product.orderCount) orders")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(String(format: "$%.0f", product.revenue))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InsightRow: View {
    let title: String
    let description: String
    let impact: String
    let priority: InsightPriority
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(impact)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

enum InsightPriority {
    case high, medium, low
}