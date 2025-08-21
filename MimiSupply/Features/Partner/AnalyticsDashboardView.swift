import SwiftUI
import Charts

/// Analytics dashboard view for partners to track business metrics
struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Time Range Selector
                    TimeRangeSelector(selectedRange: $selectedTimeRange)
                        .onChange(of: selectedTimeRange) { _, newValue in
                            Task {
                                await viewModel.loadAnalytics(for: newValue)
                            }
                        }
                    
                    // Key Metrics
                    KeyMetricsSection(metrics: viewModel.keyMetrics)
                    
                    // Charts Section
                    ChartsSection(
                        revenueData: viewModel.revenueData,
                        ordersData: viewModel.ordersData,
                        timeRange: selectedTimeRange
                    )
                    
                    // Top Products
                    TopProductsSection(products: viewModel.topProducts)
                    
                    // Insights
                    InsightsSection(insights: viewModel.insights)
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refresh(for: selectedTimeRange)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadAnalytics(for: selectedTimeRange)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    selectedRange = range
                }) {
                    Text(range.displayName)
                        .font(.labelMedium)
                        .foregroundColor(selectedRange == range ? .white : .emerald)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedRange == range ? Color.emerald : Color.clear)
                                .stroke(Color.emerald, lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Key Metrics Section
struct KeyMetricsSection: View {
    let metrics: KeyMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Key Metrics")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.md) {
                MetricCard(
                    title: "Total Revenue",
                    value: metrics.formattedTotalRevenue,
                    change: metrics.revenueChange,
                    icon: "dollarsign.circle.fill"
                )
                
                MetricCard(
                    title: "Total Orders",
                    value: "\(metrics.totalOrders)",
                    change: metrics.ordersChange,
                    icon: "bag.fill"
                )
                
                MetricCard(
                    title: "Avg Order Value",
                    value: metrics.formattedAverageOrderValue,
                    change: metrics.aovChange,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                MetricCard(
                    title: "Rating",
                    value: String(format: "%.1f", metrics.averageRating),
                    change: metrics.ratingChange,
                    icon: "star.fill"
                )
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.emerald)
                    .font(.title2)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text("\(abs(change), specifier: "%.1f")%")
                        .font(.caption)
                }
                .foregroundColor(change >= 0 ? .success : .error)
            }
            
            Text(value)
                .font(.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(.graphite)
            
            Text(title)
                .font(.bodySmall)
                .foregroundColor(.gray600)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Charts Section
struct ChartsSection: View {
    let revenueData: [ChartDataPoint]
    let ordersData: [ChartDataPoint]
    let timeRange: TimeRange
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Revenue Chart
            ChartCard(
                title: "Revenue Trend",
                data: revenueData,
                color: .emerald,
                timeRange: timeRange
            )
            
            // Orders Chart
            ChartCard(
                title: "Orders Trend",
                data: ordersData,
                color: .info,
                timeRange: timeRange
            )
        }
    }
}

// MARK: - Chart Card
struct ChartCard: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart(data) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                }
                .frame(height: 200)
            } else {
                Text("Chart requires iOS 16+")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray100)
                    .cornerRadius(8)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Top Products Section
struct TopProductsSection: View {
    let products: [TopProduct]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Top Products")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.sm) {
                ForEach(Array(products.prefix(5).enumerated()), id: \.element.id) { index, product in
                    TopProductRow(rank: index + 1, product: product)
                    
                    if index < min(4, products.count - 1) {
                        Divider()
                    }
                }
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Top Product Row
struct TopProductRow: View {
    let rank: Int
    let product: TopProduct
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("\(rank)")
                .font(.labelLarge)
                .fontWeight(.bold)
                .foregroundColor(.emerald)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.graphite)
                
                Text("\(product.orderCount) orders")
                    .font(.caption)
                    .foregroundColor(.gray500)
            }
            
            Spacer()
            
            Text(product.formattedRevenue)
                .font(.labelMedium)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
        }
    }
}

// MARK: - Insights Section
struct InsightsSection: View {
    let insights: [PerformanceInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Insights")
                .font(.titleMedium)
                .fontWeight(.semibold)
            
            VStack(spacing: Spacing.sm) {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let insight: PerformanceInsight
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: insight.iconName)
                .foregroundColor(Color(insight.iconColor))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.graphite)
                
                Text(insight.description)
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
            }
            
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AnalyticsDashboardView()
}