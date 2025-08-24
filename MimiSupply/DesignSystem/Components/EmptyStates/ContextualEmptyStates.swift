import SwiftUI

// MARK: - Contextual Empty State Types
enum EmptyStateType {
    case noData
    case search(query: String)
    case filter
    case offline
    case firstUse
    case maintenance
    case permission(PermissionType)
    case businessIntelligence(metric: String)
    
    var icon: String {
        switch self {
        case .noData: return "tray"
        case .search: return "magnifyingglass"
        case .filter: return "line.3.horizontal.decrease.circle"
        case .offline: return "wifi.slash"
        case .firstUse: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .permission(.location): return "location.slash"
        case .permission(.notifications): return "bell.slash"
        case .permission(.camera): return "camera.slash"
        case .businessIntelligence: return "chart.bar.xaxis"
        }
    }
    
    var title: String {
        switch self {
        case .noData: return "No Data Available"
        case .search(let query): return "No results for '\(query)'"
        case .filter: return "No matches found"
        case .offline: return "You're offline"
        case .firstUse: return "Welcome to MimiSupply!"
        case .maintenance: return "We'll be right back"
        case .permission(.location): return "Location access needed"
        case .permission(.notifications): return "Stay updated"
        case .permission(.camera): return "Camera access needed"
        case .businessIntelligence(let metric): return "No \(metric) data yet"
        }
    }
    
    var message: String {
        switch self {
        case .noData: 
            return "There's nothing to show right now. Check back later or try refreshing."
        case .search(let query): 
            return "We couldn't find anything matching '\(query)'. Try a different search term or browse our featured content."
        case .filter: 
            return "No items match your current filters. Try adjusting your criteria or clearing filters."
        case .offline: 
            return "Check your internet connection and try again. Some features may be limited while offline."
        case .firstUse: 
            return "Discover amazing local partners and get delicious food delivered right to your door."
        case .maintenance: 
            return "We're performing scheduled maintenance to make your experience even better. Please check back in a few minutes."
        case .permission(.location): 
            return "Allow location access to find nearby partners and get accurate delivery estimates."
        case .permission(.notifications): 
            return "Enable notifications to get updates about your orders and special offers from local partners."
        case .permission(.camera): 
            return "Camera access is needed to scan QR codes and take photos for your profile."
        case .businessIntelligence(let metric): 
            return "Start getting orders to see your \(metric) analytics and insights here."
        }
    }
    
    var primaryAction: (title: String, systemImage: String?)? {
        switch self {
        case .noData: 
            return ("Refresh", "arrow.clockwise")
        case .search: 
            return ("Clear Search", "xmark.circle")
        case .filter: 
            return ("Clear Filters", "xmark.circle")
        case .offline: 
            return ("Try Again", "arrow.clockwise")
        case .firstUse: 
            return ("Get Started", "arrow.right")
        case .maintenance: 
            return ("Check Status", "globe")
        case .permission: 
            return ("Open Settings", "gear")
        case .businessIntelligence: 
            return ("View Partners", "storefront")
        }
    }
    
    var secondaryAction: (title: String, systemImage: String?)? {
        switch self {
        case .search: 
            return ("Browse All", "list.bullet")
        case .filter: 
            return ("Browse All", "list.bullet")
        case .firstUse: 
            return ("Learn More", "info.circle")
        case .businessIntelligence: 
            return ("Learn Analytics", "questionmark.circle")
        default: 
            return nil
        }
    }
}

enum PermissionType {
    case location
    case notifications
    case camera
}

// MARK: - Contextual Empty State View
struct ContextualEmptyStateView: View {
    let type: EmptyStateType
    let primaryAction: (() -> Void)?
    let secondaryAction: (() -> Void)?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var hasAppeared = false
    
    init(
        type: EmptyStateType,
        primaryAction: (() -> Void)? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.type = type
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .scaleEffect(hasAppeared ? 1.0 : 0.8)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: hasAppeared)
                
                Image(systemName: type.icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(iconColor)
                    .scaleEffect(hasAppeared ? 1.0 : 0.5)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1), value: hasAppeared)
            }
            .accessibilityHidden(true)
            
            // Content
            VStack(spacing: Spacing.sm * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
                Text(type.title)
                    .font(.titleLarge.scaledFont())
                    .fontWeight(.semibold)
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: hasAppeared)
                    .accessibleHeading(type.title, level: .h2)
                
                Text(type.message)
                    .font(.bodyMedium.scaledFont())
                    .foregroundColor(messageColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: hasAppeared)
                    .accessibilityLabel(type.message)
            }
            
            // Actions
            VStack(spacing: Spacing.md) {
                if let primaryActionInfo = type.primaryAction, let primaryAction = primaryAction {
                    PrimaryButton(
                        title: primaryActionInfo.title,
                        systemImage: primaryActionInfo.systemImage,
                        action: primaryAction,
                        accessibilityHint: "Tap to \(primaryActionInfo.title.lowercased())"
                    )
                    .frame(maxWidth: 220)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: hasAppeared)
                }
                
                if let secondaryActionInfo = type.secondaryAction, let secondaryAction = secondaryAction {
                    SecondaryButton(
                        title: secondaryActionInfo.title,
                        systemImage: secondaryActionInfo.systemImage,
                        action: secondaryAction,
                        accessibilityHint: "Tap to \(secondaryActionInfo.title.lowercased())"
                    )
                    .frame(maxWidth: 220)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: hasAppeared)
                }
            }
        }
        .padding(.horizontal, Spacing.xl)
        .onAppear {
            withAnimation {
                hasAppeared = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - Computed Properties
    
    private var iconSize: CGFloat {
        let baseSize: CGFloat = 32
        return baseSize * accessibilityManager.preferredContentSizeCategory.scaleFactor
    }
    
    private var iconContainerSize: CGFloat {
        let baseSize: CGFloat = 80
        return baseSize * accessibilityManager.preferredContentSizeCategory.scaleFactor
    }
    
    private var iconBackgroundColor: Color {
        switch type {
        case .offline, .permission: return Color.warning.opacity(0.1)
        case .maintenance: return Color.error.opacity(0.1)
        case .firstUse: return Color.emerald.opacity(0.1)
        default: return Color.gray200.opacity(0.5)
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .offline, .permission: return .warning
        case .maintenance: return .error
        case .firstUse: return .emerald
        default: return .gray500
        }
    }
    
    private var titleColor: Color {
        let baseColor = Color.graphite
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var messageColor: Color {
        let baseColor = Color.gray600
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var accessibilityDescription: String {
        var description = "\(type.title). \(type.message)"
        
        if type.primaryAction != nil {
            description += ". Primary action available."
        }
        
        if type.secondaryAction != nil {
            description += ". Secondary action available."
        }
        
        return description
    }
}

// MARK: - Business Intelligence Specific Empty States
struct BusinessIntelligenceEmptyStates {
    
    static func noRevenueData(onViewPartners: @escaping () -> Void) -> ContextualEmptyStateView {
        ContextualEmptyStateView(
            type: .businessIntelligence(metric: "revenue"),
            primaryAction: onViewPartners
        )
    }
    
    static func noOrdersData(onViewPartners: @escaping () -> Void) -> ContextualEmptyStateView {
        ContextualEmptyStateView(
            type: .businessIntelligence(metric: "orders"),
            primaryAction: onViewPartners
        )
    }
    
    static func noCustomerData(onLearnAnalytics: @escaping () -> Void) -> ContextualEmptyStateView {
        ContextualEmptyStateView(
            type: .businessIntelligence(metric: "customer"),
            secondaryAction: onLearnAnalytics
        )
    }
}

// MARK: - Search Empty State Component
struct SearchEmptyStateView: View {
    let query: String
    let suggestions: [String]
    let onClearSearch: () -> Void
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ContextualEmptyStateView(
                type: .search(query: query),
                primaryAction: onClearSearch
            )
            
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("Try searching for:")
                        .font(.labelLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.graphite)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 120))
                    ], spacing: Spacing.sm) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: { onSuggestionTap(suggestion) }) {
                                Text(suggestion)
                                    .font(.bodySmall)
                                    .foregroundColor(.emerald)
                                    .padding(.horizontal, Spacing.md)
                                    .padding(.vertical, Spacing.sm)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.emerald.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.emerald.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)
            }
        }
    }
}

// MARK: - Permission Empty State Component
struct PermissionEmptyStateView: View {
    let permissionType: PermissionType
    let onOpenSettings: () -> Void
    let onSkip: (() -> Void)?
    
    var body: some View {
        ContextualEmptyStateView(
            type: .permission(permissionType),
            primaryAction: onOpenSettings,
            secondaryAction: onSkip
        )
    }
}

// MARK: - Preview
#Preview("Contextual Empty States") {
    TabView {
        ContextualEmptyStateView(
            type: .businessIntelligence(metric: "revenue"),
            primaryAction: { print("View Partners") },
            secondaryAction: { print("Learn Analytics") }
        )
        .tabItem { Text("BI Empty") }
        
        SearchEmptyStateView(
            query: "pizza margherita",
            suggestions: ["pizza", "italian food", "pasta", "margherita"],
            onClearSearch: { print("Clear search") },
            onSuggestionTap: { print("Suggestion: \($0)") }
        )
        .tabItem { Text("Search Empty") }
        
        ContextualEmptyStateView(
            type: .offline,
            primaryAction: { print("Try Again") }
        )
        .tabItem { Text("Offline") }
        
        ContextualEmptyStateView(
            type: .firstUse,
            primaryAction: { print("Get Started") },
            secondaryAction: { print("Learn More") }
        )
        .tabItem { Text("First Use") }
    }
}