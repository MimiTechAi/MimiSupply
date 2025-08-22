//
//  TabBarView.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

/// Custom tab bar view with role-based navigation
struct TabBarView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: AppContainer
    
    let userRole: UserRole
    let tabs: [TabRoute]
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            NavigationStack(path: $router.navigationPath) {
                mainContent
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            
            // Custom tab bar
            customTabBar
        }
        .onOpenURL { url in
            router.handleDeepLink(url)
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch router.selectedTab {
        case .explore:
            ExploreHomeView()
        case .dashboard:
            dashboardView
        case .orders:
            OrdersView()
        case .profile:
            ProfileView()
        }
    }
    
    @ViewBuilder
    private var dashboardView: some View {
        switch userRole {
        case .customer:
            CustomerHomeView()
        case .driver:
            DriverDashboardView()
        case .partner:
            PartnerDashboardView()
        case .admin:
            CustomerHomeView()
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
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: router.selectedTab == tab,
                    action: {
                        router.selectTab(tab)
                    }
                )
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
    }
    
    // Helper method - in real app this would fetch from repository
    private func sampleOrderForId(_ orderId: String) -> Order {
        return Order(
            customerId: "customer123",
            partnerId: "partner123",
            items: [
                OrderItem(
                    productId: "product1",
                    productName: "Pizza Margherita",
                    quantity: 1,
                    unitPriceCents: 1200
                )
            ],
            status: .preparing,
            subtotalCents: 1200,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 120,
            deliveryAddress: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            ),
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            paymentMethod: .applePay
        )
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let tab: TabRoute
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .emerald : .gray500)
                
                Text(tab.title)
                    .font(.labelSmall)
                    .foregroundColor(isSelected ? .emerald : .gray500)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(tab.title)
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to navigate to \(tab.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Placeholder Views
// CustomerHomeView is defined in Features/Customer/CustomerHomeView.swift
// ProfileView is defined in Features/Settings/ProfileView.swift
// OrderHistoryView is defined in Features/Shared/OrderHistoryView.swift



// ProductDetailView is now defined in Features/Customer/ProductDetailView.swift

#Preview {
    TabBarView(
        userRole: .customer,
        tabs: [.explore, .orders, .profile]
    )
    .environmentObject(AppContainer.shared.appRouter)
    .environmentObject(AppContainer.shared)
}