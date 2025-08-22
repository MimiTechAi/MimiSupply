import SwiftUI

// MARK: - Skeleton Loading System
struct SkeletonView: View {
    let content: () -> any View
    let isLoading: Bool
    
    init(isLoading: Bool, @ViewBuilder content: @escaping () -> any View) {
        self.isLoading = isLoading
        self.content = content
    }
    
    var body: some View {
        if isLoading {
            AnyView(content())
                .redacted(reason: .placeholder)
                .shimmer()
        } else {
            AnyView(content())
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                // Shimmer gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(15))
                .offset(x: phase * 400 - 200)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 1
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Predefined Skeleton Components
struct SkeletonCard: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 120, cornerRadius: CGFloat = 12) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(height: height)
            .shimmer()
    }
}

struct SkeletonText: View {
    let width: CGFloat?
    let height: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 16) {
        self.width = width
        self.height = height
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: height / 2)
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    let size: CGFloat
    
    init(size: CGFloat = 40) {
        self.size = size
    }
    
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Business Intelligence Skeleton Components
struct KeyMetricCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                SkeletonCircle(size: 24)
                
                Spacer()
                
                SkeletonText(width: 40, height: 12)
            }
            
            SkeletonText(width: 80, height: 24)
            SkeletonText(width: 120, height: 14)
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
            SkeletonText(width: 150, height: 20)
            
            SkeletonCard(height: 200, cornerRadius: 8)
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
            SkeletonText(width: 140, height: 20)
            
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        SkeletonCircle(size: 20)
                        SkeletonText(width: 100, height: 16)
                        Spacer()
                        SkeletonText(width: 60, height: 16)
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

struct CustomerInsightsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SkeletonText(width: 130, height: 20)
            
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        SkeletonCircle(size: 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonText(width: 120, height: 16)
                            SkeletonText(width: 180, height: 12)
                        }
                        
                        Spacer()
                        
                        SkeletonText(width: 50, height: 12)
                    }
                    .padding(.vertical, 8)
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
            SkeletonText(width: 160, height: 20)
            
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        SkeletonCircle(size: 8)
                        SkeletonText(width: 110, height: 16)
                        Spacer()
                        SkeletonText(width: 50, height: 16)
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
            SkeletonText(width: 100, height: 20)
            
            ForEach(0..<5, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonText(width: 140, height: 16)
                        SkeletonText(width: 80, height: 12)
                    }
                    Spacer()
                    SkeletonText(width: 60, height: 16)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview("Skeleton Components") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Skeleton Loading States")
                .font(.title)
                .padding()
            
            VStack(spacing: 16) {
                KeyMetricCardSkeleton()
                RevenueChartCardSkeleton()
                OrderAnalyticsCardSkeleton()
                CustomerInsightsCardSkeleton()
                PerformanceMetricsCardSkeleton()
                TopProductsCardSkeleton()
            }
            .padding(.horizontal)
        }
    }
    .background(Color(.systemGroupedBackground))
}