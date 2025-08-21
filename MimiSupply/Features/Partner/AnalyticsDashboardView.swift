import SwiftUI
import Charts

/// Premium Analytics Dashboard with stunning visuals and advanced functionality
struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetricCard: String? = nil
    @State private var showingDetailView = false
    @State private var animationProgress: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.1),
                        Color(red: 0.25, green: 0.85, blue: 0.55).opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header with welcome message
                        PremiumHeaderSection()
                            .opacity(animationProgress)
                            .offset(y: animationProgress == 0 ? -50 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animationProgress)
                        
                        // Time Range Selector
                        PremiumTimeRangeSelector(selectedRange: $selectedTimeRange)
                            .opacity(animationProgress)
                            .offset(y: animationProgress == 0 ? -30 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animationProgress)
                            .onChange(of: selectedTimeRange) { _, newValue in
                                Task {
                                    await viewModel.loadAnalytics(for: newValue)
                                }
                            }
                        
                        // Key Metrics with enhanced design
                        PremiumKeyMetricsSection(
                            metrics: viewModel.keyMetrics,
                            selectedCard: $selectedMetricCard,
                            isLoading: viewModel.isLoading
                        )
                        .opacity(animationProgress)
                        .offset(y: animationProgress == 0 ? -20 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3), value: animationProgress)
                        
                        // Interactive Charts Section
                        PremiumChartsSection(
                            revenueData: viewModel.revenueData,
                            ordersData: viewModel.ordersData,
                            timeRange: selectedTimeRange,
                            isLoading: viewModel.isLoading
                        )
                        .opacity(animationProgress)
                        .offset(y: animationProgress == 0 ? -10 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animationProgress)
                        
                        HStack(spacing: 16) {
                            // Top Products with enhanced visuals
                            PremiumTopProductsSection(
                                products: viewModel.topProducts,
                                isLoading: viewModel.isLoading
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Performance Insights with visual indicators
                            PremiumInsightsSection(
                                insights: viewModel.insights,
                                isLoading: viewModel.isLoading
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .opacity(animationProgress)
                        .offset(y: animationProgress == 0 ? 10 : 0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5), value: animationProgress)
                        
                        // Quick Actions Section
                        PremiumQuickActionsSection()
                            .opacity(animationProgress)
                            .offset(y: animationProgress == 0 ? 20 : 0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animationProgress)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Account for tab bar
                }
                .refreshable {
                    await viewModel.refresh(for: selectedTimeRange)
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Report", systemImage: "square.and.arrow.up") {
                            // Export functionality
                        }
                        Button("Settings", systemImage: "gear") {
                            // Settings
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(red: 0.31, green: 0.78, blue: 0.47))
                            .font(.title2)
                    }
                }
            }
            .task {
                await viewModel.loadAnalytics(for: selectedTimeRange)
                withAnimation {
                    animationProgress = 1.0
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("Retry") {
                    Task {
                        await viewModel.refresh(for: selectedTimeRange)
                    }
                }
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Premium Header Section
struct PremiumHeaderSection: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Track your performance and grow your business")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
                    
                    Text("Live")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }
}

// MARK: - Premium Time Range Selector
struct PremiumTimeRangeSelector: View {
    @Binding var selectedRange: TimeRange
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedRange = range
                    }
                }) {
                    Text(range.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedRange == range ? .white : .primary.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selectedRange == range {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.31, green: 0.78, blue: 0.47),
                                                Color(red: 0.25, green: 0.85, blue: 0.55)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "selectedRange", in: animation)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
    }
}

// MARK: - Premium Key Metrics Section
struct PremiumKeyMetricsSection: View {
    let metrics: KeyMetrics
    @Binding var selectedCard: String?
    let isLoading: Bool
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Key Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Last 7 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                PremiumMetricCard(
                    id: "revenue",
                    title: "Total Revenue",
                    value: metrics.formattedTotalRevenue,
                    change: metrics.revenueChange,
                    icon: "dollarsign.circle.fill",
                    gradient: [Color.green.opacity(0.8), Color.green],
                    selectedCard: $selectedCard,
                    isLoading: isLoading
                )
                
                PremiumMetricCard(
                    id: "orders",
                    title: "Total Orders",
                    value: "\(metrics.totalOrders)",
                    change: metrics.ordersChange,
                    icon: "bag.fill",
                    gradient: [Color.blue.opacity(0.8), Color.blue],
                    selectedCard: $selectedCard,
                    isLoading: isLoading
                )
                
                PremiumMetricCard(
                    id: "aov",
                    title: "Avg Order Value",
                    value: metrics.formattedAverageOrderValue,
                    change: metrics.aovChange,
                    icon: "chart.line.uptrend.xyaxis",
                    gradient: [Color.purple.opacity(0.8), Color.purple],
                    selectedCard: $selectedCard,
                    isLoading: isLoading
                )
                
                PremiumMetricCard(
                    id: "rating",
                    title: "Rating",
                    value: String(format: "%.1f", metrics.averageRating),
                    change: metrics.ratingChange,
                    icon: "star.fill",
                    gradient: [Color.orange.opacity(0.8), Color.orange],
                    selectedCard: $selectedCard,
                    isLoading: isLoading
                )
            }
        }
    }
}

// MARK: - Premium Metric Card
struct PremiumMetricCard: View {
    let id: String
    let title: String
    let value: String
    let change: Double
    let icon: String
    let gradient: [Color]
    @Binding var selectedCard: String?
    let isLoading: Bool
    
    @State private var animateValue = false
    
    var isSelected: Bool {
        selectedCard == id
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedCard = selectedCard == id ? nil : id
            }
        }) {
            VStack(spacing: 16) {
                // Header with icon and change indicator
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    // Change indicator
                    HStack(spacing: 4) {
                        Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12, weight: .bold))
                        Text("\(abs(change), specifier: "%.1f")%")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill((change >= 0 ? Color.green : Color.red).opacity(0.1))
                    )
                }
                
                // Value and title
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(value)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                                .scaleEffect(animateValue ? 1.1 : 1.0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateValue)
                        }
                        
                        Spacer()
                    }
                    
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: isSelected ? gradient : [.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 0
                            )
                    }
            }
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? gradient[0].opacity(0.3) : .black.opacity(0.1),
                radius: isSelected ? 15 : 5,
                x: 0,
                y: isSelected ? 8 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                animateValue = true
            }
        }
    }
}

// MARK: - Premium Charts Section
struct PremiumChartsSection: View {
    let revenueData: [ChartDataPoint]
    let ordersData: [ChartDataPoint]
    let timeRange: TimeRange
    let isLoading: Bool
    
    @State private var selectedChart: ChartType = .revenue
    
    enum ChartType: String, CaseIterable {
        case revenue = "Revenue"
        case orders = "Orders"
        
        var icon: String {
            switch self {
            case .revenue: return "dollarsign.circle.fill"
            case .orders: return "bag.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .revenue: return .green
            case .orders: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Chart selector
            HStack {
                Text("Performance Trends")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Chart type picker
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Label(type.rawValue, systemImage: type.icon)
                            .tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // Chart container
            VStack(spacing: 16) {
                if isLoading {
                    VStack {
                        ProgressView("Loading chart data...")
                        .frame(height: 250)
                    }
                } else {
                    PremiumChartView(
                        data: selectedChart == .revenue ? revenueData : ordersData,
                        color: selectedChart.color,
                        title: selectedChart.rawValue,
                        timeRange: timeRange
                    )
                }
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Premium Chart View
struct PremiumChartView: View {
    let data: [ChartDataPoint]
    let color: Color
    let title: String
    let timeRange: TimeRange
    
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !data.isEmpty {
                    Text("Trend: \(trendDescription)")
                        .font(.caption)
                        .foregroundColor(trendColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(trendColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if #available(iOS 16.0, *), !data.isEmpty {
                Chart(data) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.8), color],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: timeRange == .week ? .day : .weekOfYear)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: timeRange == .week ? .dateTime.weekday(.abbreviated) : .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .opacity(animateChart ? 1.0 : 0.0)
                .scaleEffect(animateChart ? 1.0 : 0.8)
                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: animateChart)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Text(data.isEmpty ? "No data available" : "Chart requires iOS 16+")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .onAppear {
            animateChart = true
        }
        .onChange(of: data) { _, _ in
            animateChart = false
            withAnimation {
                animateChart = true
            }
        }
    }
    
    private var trendDescription: String {
        guard data.count >= 2 else { return "Insufficient data" }
        let firstValue = data.first?.value ?? 0
        let lastValue = data.last?.value ?? 0
        let change = lastValue - firstValue
        return change > 0 ? "↗ Upward" : change < 0 ? "↘ Downward" : "→ Stable"
    }
    
    private var trendColor: Color {
        guard data.count >= 2 else { return .gray }
        let firstValue = data.first?.value ?? 0
        let lastValue = data.last?.value ?? 0
        let change = lastValue - firstValue
        return change > 0 ? .green : change < 0 ? .red : .gray
    }
}

// MARK: - Premium Top Products Section
struct PremiumTopProductsSection: View {
    let products: [TopProduct]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Top Products")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full products list
                }
                .font(.caption)
                .foregroundColor(Color(red: 0.31, green: 0.78, blue: 0.47))
            }
            
            if isLoading {
                VStack {
                    ForEach(0..<3, id: \.self) { _ in
                        PremiumProductRowSkeleton()
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(products.prefix(5).enumerated()), id: \.element.id) { index, product in
                        PremiumProductRow(
                            rank: index + 1,
                            product: product,
                            isTop3: index < 3
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Premium Product Row
struct PremiumProductRow: View {
    let rank: Int
    let product: TopProduct
    let isTop3: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank indicator
            ZStack {
                if isTop3 {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: rankColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 28, height: 28)
                    
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            
            // Product info
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(product.orderCount) orders")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Revenue
            Text(product.formattedRevenue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private var rankColors: [Color] {
        switch rank {
        case 1: return [.yellow.opacity(0.8), .yellow]
        case 2: return [.gray.opacity(0.8), .gray]
        case 3: return [.orange.opacity(0.8), .orange]
        default: return [.blue.opacity(0.8), .blue]
        }
    }
}

// MARK: - Premium Product Row Skeleton
struct PremiumProductRowSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: 100)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 10)
                    .frame(maxWidth: 60)
            }
            
            Spacer()
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 12)
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Premium Insights Section
struct PremiumInsightsSection: View {
    let insights: [PerformanceInsight]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            
            if isLoading {
                VStack {
                    ForEach(0..<2, id: \.self) { _ in
                        PremiumInsightSkeleton()
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.prefix(3)) { insight in
                        PremiumInsightCard(insight: insight)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Premium Insight Card
struct PremiumInsightCard: View {
    let insight: PerformanceInsight
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(insight.type.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: insight.iconName)
                    .foregroundColor(insight.type.color)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(insight.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Premium Insight Skeleton
struct PremiumInsightSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 10)
                    .frame(maxWidth: 80)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 8)
                    .frame(maxWidth: 120)
            }
            
            Spacer()
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Premium Quick Actions Section
struct PremiumQuickActionsSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    // Export action
                }
                
                QuickActionButton(
                    title: "Share Insights",
                    icon: "square.and.arrow.up.on.square",
                    color: .green
                ) {
                    // Share action
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .orange
                ) {
                    // Settings action
                }
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.8), color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions
extension PerformanceInsight.InsightType {
    var color: Color {
        switch self {
        case .positive: return .green
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

extension PerformanceInsight {
    var iconName: String {
        switch type {
        case .positive: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var iconColor: String {
        switch type {
        case .positive: return "green"
        case .warning: return "orange"  
        case .info: return "blue"
        }
    }
}

extension KeyMetrics {
    var formattedTotalRevenue: String {
        return String(format: "€%.2f", Double(totalRevenue) / 100.0)
    }
    
    var formattedAverageOrderValue: String {
        return String(format: "€%.2f", Double(averageOrderValue) / 100.0)
    }
}

extension TopProduct {
    var formattedRevenue: String {
        return String(format: "€%.2f", revenue)
    }
}

#Preview {
    AnalyticsDashboardView()
}