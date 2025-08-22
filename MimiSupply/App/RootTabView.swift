//
//  RootTabView.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import SwiftUI

/// Root tab view with main navigation tabs
struct RootTabView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer
    @State private var selectedTab: TabItem = .explore
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Explore Tab
            NavigationStack(path: $router.navigationPath) {
                ExploreHomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tabItem {
                Image(systemName: selectedTab == .explore ? "magnifyingglass.circle.fill" : "magnifyingglass")
                Text("Explore")
            }
            .tag(TabItem.explore)
            
            // Map Tab
            NavigationStack {
                MapExploreView(partners: []) // Will be populated by view model
            }
            .tabItem {
                Image(systemName: selectedTab == .map ? "map.fill" : "map")
                Text("Map")
            }
            .tag(TabItem.map)
            
            // Orders Tab
            NavigationStack {
                OrdersView()
            }
            .tabItem {
                Image(systemName: selectedTab == .orders ? "bag.fill" : "bag")
                Text("Orders")
            }
            .tag(TabItem.orders)
            
            // Profile Tab
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Image(systemName: selectedTab == .profile ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(TabItem.profile)
        }
        .accentColor(.blue)
        .sheet(item: $router.presentedSheet) { sheet in
            sheetContent(for: sheet)
        }
        .fullScreenCover(item: $router.presentedFullScreen) { fullScreen in
            fullScreenContent(for: fullScreen)
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .partnerDetail(let partner):
            PartnerDetailView(partner: partner)
        case .productDetail(let product):
            ProductDetailView(product: product)
        case .orderTracking(let orderId):
            OrderTrackingView(
                order: sampleOrderForId(orderId),
                cloudKitService: container.cloudKitService,
                onClose: {
                    router.pop()
                }
            )
        case .settings:
            SettingsView()
        case .cart:
            CartView()
        case .checkout:
            CheckoutView(
                cartItems: [],
                paymentService: container.paymentService,
                cloudKitService: container.cloudKitService,
                onOrderComplete: { _ in },
                onCancel: { }
            )
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func sheetContent(for sheet: SheetRoute) -> some View {
        switch sheet {
        case .cart:
            NavigationView {
                CartView()
            }
        case .checkout(let items):
            NavigationView {
                CheckoutView(
                    cartItems: items,
                    paymentService: container.paymentService,
                    cloudKitService: container.cloudKitService,
                    onOrderComplete: { _ in
                        router.dismissSheet()
                    },
                    onCancel: {
                        router.dismissSheet()
                    }
                )
            }
        case .authentication:
            NavigationView {
                DemoSignInView()
                    .environmentObject(AuthenticationManager())
            }
        case .profile:
            NavigationView {
                ProfileEditView()
            }
        case .productDetail(let product):
            NavigationView {
                ProductDetailView(product: product)
            }
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func fullScreenContent(for fullScreen: FullScreenRoute) -> some View {
        switch fullScreen {
        case .onboarding:
            OnboardingView {
                // Handle onboarding completion
                // Set user as onboarded or navigate to main app
            }
        case .orderTracking(let order):
            OrderTrackingView(
                order: order,
                cloudKitService: container.cloudKitService,
                onClose: {
                    router.dismissFullScreen()
                }
            )
        case .jobCompletion(let order):
            JobCompletionView(job: order) { photoData, notes in
                router.dismissFullScreen()
            }
        }
    }
    
    // Helper method - in real app this would fetch from repository
    private func sampleOrderForId(_ orderId: String) -> Order {
        return Order.mockOrders.first { $0.id == orderId } ?? Order.mockOrders[0]
    }
}

// MARK: - Tab Item
enum TabItem: String, CaseIterable {
    case explore = "explore"
    case map = "map"
    case orders = "orders"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .explore: return "Explore"
        case .map: return "Map"
        case .orders: return "Orders"
        case .profile: return "Profile"
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppContainer.shared.appRouter)
        .environmentObject(AppContainer.shared)
}