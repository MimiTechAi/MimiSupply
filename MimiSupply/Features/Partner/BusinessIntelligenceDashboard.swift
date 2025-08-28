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
                    // Time Range Selector with Haptic Feedback
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTimeRange) { _, newValue in
                        HapticManager.shared.trigger(.selection, context: .analytics)
                        Task {
                            await viewModel.loadData(for: newValue)
                        }
                    }
                    
                    // Show content based on state
                    if viewModel.loadingState.isAnyLoading {
                        // Progressive Loading UI
                        loadingContentView
                    } else if viewModel.hasAnyData {
                        // Main content with data
                        mainContentView
                    } else {
                        // Empty state
                        emptyStateView
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle("Business Intelligence")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await viewModel.exportReport()
                            }
                        } label: {
                            Label("Export Report", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.loadingState.isAnyLoading || !viewModel.hasAnyData)
                        
                        Button {
                            viewModel.showScheduleReport = true
                        } label: {
                            Label("Schedule Report", systemImage: "calendar.badge.plus")
                        }
                        .disabled(viewModel.loadingState.isAnyLoading || !viewModel.hasAnyData)
                        
                        Button {
                            viewModel.showShareSheet = true
                        } label: {
                            Label("Share Dashboard", systemImage: "square.and.arrow.up.on.square")
                        }
                        .disabled(viewModel.loadingState.isAnyLoading || !viewModel.hasAnyData)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .onTapHaptic(.buttonTap, context: .analytics) {}
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .refreshable {
                HapticManager.shared.trigger(.dashboardRefresh, context: .analytics)
                await viewModel.refreshData()
            }
            .hapticFeedback(.dataLoaded, context: .analytics, trigger: viewModel.hasAnyData)
            .sheet(isPresented: $viewModel.showScheduleReport) {
                ScheduleReportView()
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareDashboardView()
            }
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var loadingContentView: some View {
        VStack(spacing: Spacing.lg) {
            // Key Metrics Cards with Progressive Loading
            if viewModel.loadingState.keyMetrics {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        KeyMetricCardSkeleton()
                    }
                }
            } else {
                HapticKeyMetricsGrid(metrics: viewModel.keyMetrics)
            }
            
            // Revenue Chart with Loading State
            if viewModel.loadingState.revenueData {
                RevenueChartCardSkeleton()
            } else if !viewModel.revenueData.isEmpty {
                HapticRevenueChartCard(
                    data: viewModel.revenueData,
                    timeRange: selectedTimeRange
                )
            }
            
            // Order Analytics with Loading State
            if viewModel.loadingState.orderAnalytics {
                OrderAnalyticsCardSkeleton()
            } else if viewModel.orderAnalytics.hasData {
                HapticOrderAnalyticsCard(
                    data: viewModel.orderAnalytics,
                    timeRange: selectedTimeRange
                )
            }
            
            // Customer Insights with Loading State
            if viewModel.loadingState.customerInsights {
                CustomerInsightsCardSkeleton()
            } else if viewModel.customerInsights.hasData {
                HapticCustomerInsightsCard(
                    data: viewModel.customerInsights
                )
            }
            
            // Performance Metrics with Loading State
            if viewModel.loadingState.performanceMetrics {
                PerformanceMetricsCardSkeleton()
            } else {
                HapticPerformanceMetricsCard(
                    data: viewModel.performanceMetrics
                )
            }
            
            // Top Products with Loading State
            if viewModel.loadingState.topProducts {
                TopProductsCardSkeleton()
            } else if !viewModel.topProducts.isEmpty {
                HapticTopProductsCard(
                    products: viewModel.topProducts
                )
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: Spacing.lg) {
            // Key Metrics Cards
            HapticKeyMetricsGrid(metrics: viewModel.keyMetrics)
            
            // Revenue Chart
            if !viewModel.revenueData.isEmpty {
                HapticRevenueChartCard(
                    data: viewModel.revenueData,
                    timeRange: selectedTimeRange
                )
            } else {
                BusinessIntelligenceEmptyStates.noRevenueData {
                    HapticManager.shared.trigger(.buttonTap, context: .analytics)
                    // Navigate to partners view
                    print("Navigate to partners")
                }
            }
            
            // Order Analytics
            if viewModel.orderAnalytics.hasData {
                HapticOrderAnalyticsCard(
                    data: viewModel.orderAnalytics,
                    timeRange: selectedTimeRange
                )
            } else {
                BusinessIntelligenceEmptyStates.noOrdersData {
                    HapticManager.shared.trigger(.buttonTap, context: .analytics)
                    // Navigate to partners view
                    print("Navigate to partners")
                }
            }
            
            // Customer Insights
            if viewModel.customerInsights.hasData {
                HapticCustomerInsightsCard(
                    data: viewModel.customerInsights
                )
            } else {
                BusinessIntelligenceEmptyStates.noCustomerData {
                    HapticManager.shared.trigger(.buttonTap, context: .analytics)
                    // Show analytics tutorial
                    print("Show analytics tutorial")
                }
            }
            
            // Performance Metrics
            HapticPerformanceMetricsCard(
                data: viewModel.performanceMetrics
            )
            
            // Top Products
            if !viewModel.topProducts.isEmpty {
                HapticTopProductsCard(
                    products: viewModel.topProducts
                )
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            ContextualEmptyStateView(
                type: .businessIntelligence(metric: "analytics"),
                primaryAction: {
                    HapticManager.shared.trigger(.buttonTap, context: .analytics)
                    // Navigate to partners or onboarding
                    print("Get started with analytics")
                },
                secondaryAction: {
                    HapticManager.shared.trigger(.buttonTap, context: .analytics)
                    // Show help or tutorial
                    print("Learn about analytics")
                }
            )
            
            Spacer()
        }
    }
}

// MARK: - KeyMetricCard
struct KeyMetricCard: View {
    let metric: KeyMetric

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(.green)
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
            Text(metric.title)
                .font(.bodySmall)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced Cards with Haptic Feedback

struct HapticKeyMetricsGrid: View {
    let metrics: [KeyMetric]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(metrics, id: \.title) { metric in
                KeyMetricCard(metric: metric)
                    .onTapHaptic(.metricTap, context: .analytics) {
                        print("Metric tapped: \(metric.title)")
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: metrics.count)
    }
}

struct HapticRevenueChartCard: View {
    let data: [RevenueDataPoint]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Revenue Trends")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart(data, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Revenue", dataPoint.amount)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Revenue", dataPoint.amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date, format: .dateTime.month(.abbreviated).day())
                            }
                        }
                    }
                }
                .onTapGesture { location in
                    HapticManager.shared.trigger(.chartInteraction, context: .analytics)
                    print("Chart tapped at: \(location)")
                }
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
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .opacity
        ))
    }
}

struct HapticOrderAnalyticsCard: View {
    let data: OrderAnalytics
    let timeRange: TimeRange
    
    var body: some View {
        OrderAnalyticsCard(data: data, timeRange: timeRange)
            .onTapHaptic(.metricTap, context: .analytics) {
                print("Order analytics tapped")
            }
    }
}

struct HapticCustomerInsightsCard: View {
    let data: CustomerInsights
    
    var body: some View {
        CustomerInsightsCard(data: data)
            .onTapHaptic(.metricTap, context: .analytics) {
                print("Customer insights tapped")
            }
    }
}

struct HapticPerformanceMetricsCard: View {
    let data: PerformanceMetrics
    
    var body: some View {
        PerformanceMetricsCard(data: data)
            .onTapHaptic(.metricTap, context: .analytics) {
                print("Performance metrics tapped")
            }
    }
}

struct HapticTopProductsCard: View {
    let products: [TopProduct]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Products")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                HapticTopProductRow(product: product, rank: index + 1)
                    .transition(.asymmetric(
                        insertion: .slide.combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.4), value: products.count)
    }
}

struct HapticTopProductRow: View {
    let product: TopProduct
    let rank: Int
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Rank indicator
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(rankColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.graphite)
                
                Text("\(product.orderCount) orders")
                    .font(.caption)
                    .foregroundColor(.gray500)
            }
            
            Spacer()
            
            Text(String(format: "$%.0f", product.revenue))
                .font(.labelLarge)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
        }
        .padding(.vertical, Spacing.xs)
        .onTapHaptic(.selection, context: .analytics) {
            print("Product tapped: \(product.name)")
        }
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray400
        case 3: return .orange
        default: return .green
        }
    }
}

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
                .foregroundColor(.green)
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
                    description: "\(String(format: "%.1f", data.retentionRate * 5.0)) out of 5.0",
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
    case high, medium, low}

extension KeyMetric {
    var changeText: String {
        guard let change = percentageChange else { return "" }
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))%"
    }
}

struct BIDashboardMetricRow: View {
    let title: String
    let value: String
    let change: String?
    let changeColor: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.caption.scaledFont())
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2.scaledFont().weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if let change = change {
                Text(change)
                    .font(.caption.scaledFont().weight(.medium))
                    .foregroundColor(changeColor)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(changeColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
}

struct BIKeyMetricsGrid: View {
    let metrics: [BusinessMetric]
    
    struct BusinessMetric: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: Color
        let change: Double?
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Image(systemName: metric.icon)
                            .foregroundColor(metric.color)
                        Text(metric.title)
                            .font(.caption.scaledFont())
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Text(metric.value)
                        .font(.title2.scaledFont().weight(.bold))
                    
                    if let change = metric.change {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                            Text("\(abs(change), specifier: "%.1f")%")
                                .font(.caption.scaledFont())
                        }
                        .foregroundColor(change > 0 ? .success : .error)
                    }
                }
                .padding(Spacing.md)
                .background(Color.surfaceSecondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

