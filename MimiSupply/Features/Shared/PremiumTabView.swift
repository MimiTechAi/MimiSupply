//
//  PremiumTabView.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import SwiftUI

/// Premium tab view with stunning design and role-based navigation
struct PremiumTabView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var demoAuth: DemoAuthService
    @State private var selectedTab: PremiumTab = .explore
    @State private var animationOffset: CGFloat = 100
    @State private var animationOpacity: Double = 0
    
    // Get role-specific tabs
    private var availableTabs: [PremiumTab] {
        guard let user = demoAuth.currentUser else { return [.explore, .orders, .profile] }
        
        switch user.role {
        case .customer:
            return [.explore, .orders, .profile]
        case .driver:
            return [.dashboard, .orders, .profile]
        case .partner:
            return [.dashboard, .orders, .analytics, .profile]
        case .admin:
            return [.explore, .dashboard, .orders, .analytics, .profile]
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content with role-based tabs
            TabView(selection: $selectedTab) {
                ForEach(availableTabs, id: \.self) { tab in
                    NavigationStack(path: $router.navigationPath) {
                        contentView(for: tab)
                            .navigationDestination(for: AppRoute.self) { route in
                                destinationView(for: route)
                            }
                    }
                    .tag(tab)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom Premium Tab Bar with role-specific tabs
            PremiumTabBar(selectedTab: $selectedTab, availableTabs: availableTabs)
                .offset(y: animationOffset)
                .opacity(animationOpacity)
        }
        .premiumBackground()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                animationOffset = 0
                animationOpacity = 1
            }
            
            // Set initial tab based on user role
            if let user = demoAuth.currentUser {
                switch user.role {
                case .customer:
                    selectedTab = .explore
                case .driver, .partner:
                    selectedTab = .dashboard
                case .admin:
                    selectedTab = .dashboard
                }
            }
        }
        .onChange(of: demoAuth.currentUser) { _, newUser in
            // Update selected tab when user changes
            if let user = newUser {
                switch user.role {
                case .customer:
                    selectedTab = availableTabs.contains(.explore) ? .explore : availableTabs.first ?? .profile
                case .driver, .partner:
                    selectedTab = availableTabs.contains(.dashboard) ? .dashboard : availableTabs.first ?? .profile
                case .admin:
                    selectedTab = availableTabs.contains(.dashboard) ? .dashboard : availableTabs.first ?? .profile
                }
            }
        }
    }
    
    @ViewBuilder
    private func contentView(for tab: PremiumTab) -> some View {
        switch tab {
        case .explore:
            PremiumExploreView()
        case .dashboard:
            // Show appropriate dashboard based on user role
            if let user = demoAuth.currentUser {
                switch user.role {
                case .driver:
                    DriverDashboardView()
                case .partner:
                    PartnerDashboardView()
                case .admin:
                    PartnerDashboardView() // Admin can see partner dashboard
                default:
                    PremiumExploreView() // Fallback
                }
            } else {
                PremiumExploreView()
            }
        case .map:
            PremiumMapView()
        case .orders:
            PremiumOrdersView()
        case .analytics:
            // Only available for partners and admins
            if let user = demoAuth.currentUser, [.partner, .admin].contains(user.role) {
                AnalyticsDashboardView()
            } else {
                PremiumOrdersView() // Fallback
            }
        case .profile:
            PremiumProfileView()
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .partnerDetail(let partner):
            PremiumPartnerDetailView(partner: partner)
        case .productDetail(let product):
            PremiumProductDetailView(product: product)
        default:
            EmptyView()
        }
    }
}

// MARK: - Premium Tab Enum (Enhanced with role-specific tabs)
enum PremiumTab: String, CaseIterable {
    case explore = "explore"
    case dashboard = "dashboard"
    case map = "map"
    case orders = "orders"
    case analytics = "analytics"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .explore: return "Entdecken"
        case .dashboard: return "Dashboard"
        case .map: return "Karte"
        case .orders: return "Bestellungen"
        case .analytics: return "Analytics"
        case .profile: return "Profil"
        }
    }
    
    var icon: String {
        switch self {
        case .explore: return "magnifyingglass"
        case .dashboard: return "square.grid.2x2"
        case .map: return "map"
        case .orders: return "bag"
        case .analytics: return "chart.bar"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .explore: return "magnifyingglass.circle.fill"
        case .dashboard: return "square.grid.2x2.fill"
        case .map: return "map.fill"
        case .orders: return "bag.fill"
        case .analytics: return "chart.bar.fill"
        case .profile: return "person.fill"
        }
    }
    
    // Which roles can access this tab
    var allowedRoles: Set<UserRole> {
        switch self {
        case .explore:
            return [.customer, .admin]
        case .dashboard:
            return [.driver, .partner, .admin]
        case .map:
            return [.customer, .driver, .admin]
        case .orders:
            return [.customer, .driver, .partner, .admin]
        case .analytics:
            return [.partner, .admin]
        case .profile:
            return [.customer, .driver, .partner, .admin]
        }
    }
}

// MARK: - Premium Tab Bar (Enhanced for role-based tabs)
struct PremiumTabBar: View {
    @Binding var selectedTab: PremiumTab
    let availableTabs: [PremiumTab]
    @Namespace private var tabIndicator
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableTabs, id: \.self) { tab in
                PremiumTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: tabIndicator
                ) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            // Glassmorphism background
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 34)
    }
}

// MARK: - Premium Tab Bar Item
struct PremiumTabBarItem: View {
    let tab: PremiumTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
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
                            .frame(width: 32, height: 32)
                            .matchedGeometryEffect(id: "selectedTab", in: namespace)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .primary.opacity(0.6))
                }
                
                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .primary : .primary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Premium Views
struct PremiumExploreView: View {
    var body: some View {
        ExploreHomeView()
    }
}

struct PremiumMapView: View {
    var body: some View {
        MapExploreView(partners: GermanPartnerData.allPartners)
    }
}

struct PremiumOrdersView: View {
    var body: some View {
        OrdersView()
    }
}

struct PremiumProfileView: View {
    var body: some View {
        ProfileView()
    }
}

struct PremiumPartnerDetailView: View {
    let partner: Partner
    
    var body: some View {
        PartnerDetailView(partner: partner)
    }
}

struct PremiumProductDetailView: View {
    let product: Product
    
    var body: some View {
        ProductDetailView(product: product)
    }
}

struct PremiumSettingsView: View {
    var body: some View {
        SettingsView()
    }
}

struct PremiumCartView: View {
    var body: some View {
        CartView()
    }
}

// MARK: - Preview
#Preview {
    PremiumTabView()
        .environmentObject(AppContainer.shared.appRouter)
        .environmentObject(AppContainer.shared)
        .environmentObject(DemoAuthService.shared)
}