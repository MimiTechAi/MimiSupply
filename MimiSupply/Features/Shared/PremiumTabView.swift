//
//  PremiumTabView.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import SwiftUI

/// Premium tab view with stunning design and smooth animations
struct PremiumTabView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var demoAuth: DemoAuthService
    @State private var selectedTab: PremiumTab = .explore
    @State private var animationOffset: CGFloat = 100
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            TabView(selection: $selectedTab) {
                // Explore Tab
                NavigationStack(path: $router.navigationPath) {
                    PremiumExploreView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destinationView(for: route)
                        }
                }
                .tag(PremiumTab.explore)
                
                // Map Tab
                NavigationStack {
                    PremiumMapView()
                }
                .tag(PremiumTab.map)
                
                // Orders Tab
                NavigationStack {
                    PremiumOrdersView()
                }
                .tag(PremiumTab.orders)
                
                // Profile Tab
                NavigationStack {
                    PremiumProfileView()
                }
                .tag(PremiumTab.profile)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom Premium Tab Bar
            PremiumTabBar(selectedTab: $selectedTab)
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

// MARK: - Premium Tab Enum
enum PremiumTab: String, CaseIterable {
    case explore = "explore"
    case map = "map"
    case orders = "orders"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .explore: return "Entdecken"
        case .map: return "Karte"
        case .orders: return "Bestellungen"
        case .profile: return "Profil"
        }
    }
    
    var icon: String {
        switch self {
        case .explore: return "magnifyingglass"
        case .map: return "map"
        case .orders: return "bag"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .explore: return "magnifyingglass.circle.fill"
        case .map: return "map.fill"
        case .orders: return "bag.fill"
        case .profile: return "person.fill"
        }
    }
}

// MARK: - Premium Tab Bar
struct PremiumTabBar: View {
    @Binding var selectedTab: PremiumTab
    @Namespace private var tabIndicator
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(PremiumTab.allCases, id: \.self) { tab in
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

// MARK: - Premium Views (Placeholders for now)
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