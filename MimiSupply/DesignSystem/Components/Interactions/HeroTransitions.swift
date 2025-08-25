import SwiftUI
import Charts

// MARK: - Hero Transition System
struct HeroTransition {
    
    // MARK: - Matched Geometry Effects
    enum MatchedGeometryID: String, CaseIterable {
        case revenueCard = "revenue-card"
        case orderCard = "order-card"
        case customerCard = "customer-card"
        case performanceCard = "performance-card"
        case topProductsCard = "top-products-card"
        case keyMetricCard = "key-metric-card"
        
        var namespace: String {
            return "hero-\(rawValue)"
        }
    }
}

// MARK: - Hero Card Wrapper
struct HeroCard<Content: View>: View {
    let content: Content
    let heroID: HeroTransition.MatchedGeometryID
    let namespace: Namespace.ID
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    init(
        heroID: HeroTransition.MatchedGeometryID,
        namespace: Namespace.ID,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.heroID = heroID
        self.namespace = namespace
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        content
            .matchedGeometryEffect(
                id: heroID.rawValue,
                in: namespace,
                properties: .frame,
                anchor: .center,
                isSource: true
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
            .onTapGesture {
                onTap?()
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
                // Empty action
            } onPressingChanged: { pressing in
                withAnimation {
                    isPressed = pressing
                }
            }
    }
}

// MARK: - Enhanced Business Intelligence Cards with Hero Transitions
struct EnhancedBusinessIntelligenceDashboard: View {
    @StateObject private var viewModel = BusinessIntelligenceViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedCard: HeroTransition.MatchedGeometryID?
    @State private var showingDetailView = false
    @Namespace private var heroNamespace
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Time Range Selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTimeRange) { _, newValue in
                        Task {
                            await viewModel.loadData(for: newValue)
                        }
                    }
                    
                    LazyVStack(spacing: Spacing.lg) {
                        // Key Metrics Cards
                        if viewModel.loadingState.keyMetrics {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                                ForEach(0..<4, id: \.self) { _ in
                                    KeyMetricCardSkeleton()
                                }
                            }
                        } else {
                            HeroKeyMetricsGrid(metrics: viewModel.keyMetrics, namespace: heroNamespace) { cardIndex in
                                selectedCard = .keyMetricCard
                                showingDetailView = true
                            }
                        }
                        
                        // Revenue Chart
                        if viewModel.loadingState.revenueData {
                            RevenueChartCardSkeleton()
                        } else if !viewModel.revenueData.isEmpty {
                            HeroCard(
                                heroID: .revenueCard,
                                namespace: heroNamespace,
                                onTap: {
                                    selectedCard = .revenueCard
                                    showingDetailView = true
                                }
                            ) {
                                EnhancedRevenueChartCard(
                                    data: viewModel.revenueData,
                                    timeRange: selectedTimeRange
                                )
                            }
                        }
                        
                        // Order Analytics
                        if viewModel.loadingState.orderAnalytics {
                            OrderAnalyticsCardSkeleton()
                        } else if viewModel.orderAnalytics.hasData {
                            HeroCard(
                                heroID: .orderCard,
                                namespace: heroNamespace,
                                onTap: {
                                    selectedCard = .orderCard
                                    showingDetailView = true
                                }
                            ) {
                                EnhancedOrderAnalyticsCard(
                                    data: viewModel.orderAnalytics,
                                    timeRange: selectedTimeRange
                                )
                            }
                        }
                        
                        // Customer Insights
                        if viewModel.loadingState.customerInsights {
                            CustomerInsightsCardSkeleton()
                        } else if viewModel.customerInsights.hasData {
                            HeroCard(
                                heroID: .customerCard,
                                namespace: heroNamespace,
                                onTap: {
                                    selectedCard = .customerCard
                                    showingDetailView = true
                                }
                            ) {
                                EnhancedCustomerInsightsCard(
                                    data: viewModel.customerInsights
                                )
                            }
                        }
                        
                        // Performance Metrics
                        if viewModel.loadingState.performanceMetrics {
                            PerformanceMetricsCardSkeleton()
                        } else {
                            HeroCard(
                                heroID: .performanceCard,
                                namespace: heroNamespace,
                                onTap: {
                                    selectedCard = .performanceCard
                                    showingDetailView = true
                                }
                            ) {
                                EnhancedPerformanceMetricsCard(
                                    data: viewModel.performanceMetrics
                                )
                            }
                        }
                        
                        // Top Products
                        if viewModel.loadingState.topProducts {
                            TopProductsCardSkeleton()
                        } else if !viewModel.topProducts.isEmpty {
                            HeroCard(
                                heroID: .topProductsCard,
                                namespace: heroNamespace,
                                onTap: {
                                    selectedCard = .topProductsCard
                                    showingDetailView = true
                                }
                            ) {
                                EnhancedTopProductsCard(
                                    products: viewModel.topProducts
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle("Business Intelligence")
            .task {
                await viewModel.loadInitialData()
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .fullScreenCover(isPresented: $showingDetailView) {
                if let selectedCard = selectedCard {
                    CardDetailView(
                        heroID: selectedCard,
                        namespace: heroNamespace,
                        viewModel: viewModel,
                        onDismiss: {
                            showingDetailView = false
                            self.selectedCard = nil
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Cards with Animations
struct EnhancedRevenueChartCard: View {
    let data: [RevenueDataPoint]
    let timeRange: TimeRange
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Revenue Trends")
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                    
                    Text(formatTotalRevenue())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .scaleEffect(animateChart ? 1.0 : 0.8)
                        .opacity(animateChart ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateChart)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.title3)
                    .foregroundColor(.green)
                    .rotationEffect(.degrees(animateChart ? 0 : -90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: animateChart)
            }
            
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .scaleEffect(x: animateChart ? 1.0 : 0.1, y: 1.0, anchor: .leading)
                .opacity(animateChart ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.8).delay(0.2), value: animateChart)
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
        .onAppear {
            withAnimation {
                animateChart = true
            }
        }
    }
    
    private func formatTotalRevenue() -> String {
        let total = data.reduce(0) { $0 + $1.amount }
        return String(format: "$%.0f", total)
    }
}

// MARK: - Hero Key Metrics Grid
struct HeroKeyMetricsGrid: View {
    let metrics: [KeyMetric]
    let namespace: Namespace.ID
    let onCardTap: (Int) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                HeroCard(
                    heroID: .keyMetricCard,
                    namespace: namespace,
                    onTap: { onCardTap(index) }
                ) {
                    AnimatedKeyMetricCard(metric: metric, animationDelay: Double(index) * 0.1)
                }
            }
        }
    }
}

struct AnimatedKeyMetricCard: View {
    let metric: KeyMetric
    let animationDelay: Double
    @State private var hasAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(.green)
                    .font(.title2)
                    .scaleEffect(hasAnimated ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay), value: hasAnimated)
                
                Spacer()
                
                if let change = metric.percentageChange {
                    HStack(spacing: 2) {
                        Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                            .font(.caption)
                        Text("\(abs(change), specifier: "%.1f")%")
                            .font(.caption)
                    }
                    .foregroundColor(change >= 0 ? .green : .red)
                    .opacity(hasAnimated ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.3).delay(animationDelay + 0.3), value: hasAnimated)
                }
            }
            
            Text(metric.value)
                .font(.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .opacity(hasAnimated ? 1.0 : 0.0)
                .offset(y: hasAnimated ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.1), value: hasAnimated)
            
            Text(metric.title)
                .font(.bodySmall)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .opacity(hasAnimated ? 1.0 : 0.0)
                .offset(y: hasAnimated ? 0 : 20)
                .animation(.easeOut(duration: 0.4).delay(animationDelay + 0.2), value: hasAnimated)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation {
                hasAnimated = true
            }
        }
    }
}

// MARK: - Card Detail View
struct CardDetailView: View {
    let heroID: HeroTransition.MatchedGeometryID
    let namespace: Namespace.ID
    let viewModel: BusinessIntelligenceViewModel
    let onDismiss: () -> Void
    
    @State private var showingContent = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero card content
                    heroCardContent
                        .matchedGeometryEffect(
                            id: heroID.rawValue,
                            in: namespace,
                            properties: .frame,
                            anchor: .center,
                            isSource: false
                        )
                    
                    // Additional detailed content
                    if showingContent {
                        detailedContent
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                }
                .padding()
            }
            .navigationTitle(heroID.rawValue.capitalized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showingContent = true
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var heroCardContent: some View {
        switch heroID {
        case .revenueCard:
            EnhancedRevenueChartCard(
                data: viewModel.revenueData,
                timeRange: .week
            )
        case .orderCard:
            EnhancedOrderAnalyticsCard(
                data: viewModel.orderAnalytics,
                timeRange: .week
            )
        case .customerCard:
            EnhancedCustomerInsightsCard(
                data: viewModel.customerInsights
            )
        case .performanceCard:
            EnhancedPerformanceMetricsCard(
                data: viewModel.performanceMetrics
            )
        case .topProductsCard:
            EnhancedTopProductsCard(
                products: viewModel.topProducts
            )
        case .keyMetricCard:
            HeroKeyMetricsGrid(metrics: viewModel.keyMetrics, namespace: namespace) { _ in }
        }
    }
    
    @ViewBuilder
    private var detailedContent: some View {
        VStack(spacing: Spacing.lg) {
            Text("Detailed Analysis")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("This is where additional detailed information about the \(heroID.rawValue) would be displayed with charts, tables, and insights.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Placeholder for additional content
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Additional Charts & Data")
                        .foregroundColor(.secondary)
                )
        }
    }
}

// MARK: - Skeleton Components
struct KeyMetricCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                EnhancedSkeletonView(width: 24, height: 24, cornerRadius: 12)
                Spacer()
                EnhancedSkeletonView(width: 40, height: 16, cornerRadius: 8)
            }
            
            EnhancedSkeletonView(width: 80, height: 24, cornerRadius: 8)
            EnhancedSkeletonView(width: 120, height: 14, cornerRadius: 7)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct RevenueChartCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    EnhancedSkeletonView(width: 120, height: 20, cornerRadius: 8)
                    EnhancedSkeletonView(width: 80, height: 28, cornerRadius: 8)
                }
                Spacer()
                EnhancedSkeletonView(width: 24, height: 24, cornerRadius: 12)
            }
            
            EnhancedSkeletonView(width: nil, height: 200, cornerRadius: 8)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct OrderAnalyticsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EnhancedSkeletonView(width: 140, height: 20, cornerRadius: 8)
            
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        EnhancedSkeletonView(width: 20, height: 20, cornerRadius: 10)
                        EnhancedSkeletonView(width: 100, height: 16, cornerRadius: 8)
                        Spacer()
                        EnhancedSkeletonView(width: 60, height: 16, cornerRadius: 8)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct CustomerInsightsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EnhancedSkeletonView(width: 140, height: 20, cornerRadius: 8)
            
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 4) {
                        EnhancedSkeletonView(width: 120, height: 16, cornerRadius: 8)
                        EnhancedSkeletonView(width: 180, height: 14, cornerRadius: 7)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PerformanceMetricsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EnhancedSkeletonView(width: 160, height: 20, cornerRadius: 8)
            
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        EnhancedSkeletonView(width: 8, height: 8, cornerRadius: 4)
                        EnhancedSkeletonView(width: 100, height: 16, cornerRadius: 8)
                        Spacer()
                        EnhancedSkeletonView(width: 60, height: 16, cornerRadius: 8)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TopProductsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            EnhancedSkeletonView(width: 100, height: 20, cornerRadius: 8)
            
            ForEach(0..<5, id: \.self) { _ in
                HStack(spacing: Spacing.md) {
                    EnhancedSkeletonView(width: 24, height: 24, cornerRadius: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        EnhancedSkeletonView(width: 120, height: 16, cornerRadius: 8)
                        EnhancedSkeletonView(width: 80, height: 12, cornerRadius: 6)
                    }
                    
                    Spacer()
                    
                    EnhancedSkeletonView(width: 60, height: 16, cornerRadius: 8)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Enhanced Cards (using existing implementations)
struct EnhancedOrderAnalyticsCard: View {
    let data: OrderAnalytics
    let timeRange: TimeRange
    
    var body: some View {
        OrderAnalyticsCard(data: data, timeRange: timeRange)
    }
}

struct EnhancedCustomerInsightsCard: View {
    let data: CustomerInsights
    
    var body: some View {
        CustomerInsightsCard(data: data)
    }
}

struct EnhancedPerformanceMetricsCard: View {
    let data: PerformanceMetrics
    
    var body: some View {
        PerformanceMetricsCard(data: data)
    }
}

struct EnhancedTopProductsCard: View {
    let products: [TopProduct]
    
    var body: some View {
        TopProductsCard(products: products)
    }
}