//
//  RootView.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Root view that handles main app navigation and authentication state
struct RootView: View {
    
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var router: AppRouter
    
    @State private var isAuthenticated = false
    @State private var currentUser: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if isAuthenticated, currentUser != nil {
                // Authenticated user with main tab navigation
                RootTabView()
                    .environmentObject(container)
                    .environmentObject(router)
            } else {
                // Unauthenticated user - explore-first experience
                RootTabView()
                    .environmentObject(container)
                    .environmentObject(router)
            }
        }
        .task {
            await checkAuthenticationState()
        }
        .onChange(of: isAuthenticated) { _, newValue in
            if newValue, let user = currentUser {
                router.navigateToRoleBasedHome(for: user.role)
            } else {
                router.navigate(to: .explore)
            }
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
        case .authentication:
            SignInView()
                .environmentObject(AuthenticationManager())
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
                SignInView()
                    .environmentObject(AuthenticationManager())
            }
        case .roleSelection(let user):
            NavigationView {
                RoleSelectionView(user: user) { role in
                    Task {
                        // Update user role and navigate to appropriate home
                        router.dismissSheet()
                        router.navigateToRoleBasedHome(for: role)
                    }
                }
            }
        case .profile:
            NavigationView {
                ProfileView()
            }
        case .productDetail(let product):
            NavigationView {
                ProductDetailView(product: product)
            }
        case .orderDetail(let order):
            NavigationView {
                OrderDetailView(order: order)
            }
        case .partnerSettings:
            NavigationView {
                PartnerSettingsView()
            }
        case .businessHours:
            NavigationView {
                BusinessHoursManagementView()
            }
        case .productManagement:
            NavigationView {
                ProductManagementView()
            }
        case .analytics:
            NavigationView {
                AnalyticsDashboardView()
            }
        }
    }
    
    @ViewBuilder
    private func fullScreenContent(for fullScreen: FullScreenRoute) -> some View {
        switch fullScreen {
        case .onboarding:
            OnboardingView()
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
                // Handle job completion
                router.dismissFullScreen()
            }
        }
    }
    
    private func checkAuthenticationState() async {
        isAuthenticated = await container.authenticationService.isAuthenticated
        currentUser = await container.authenticationService.currentUser
        
        // Navigate to appropriate home screen based on user role
        if let user = currentUser {
            switch user.role {
            case .customer:
                router.navigate(to: .customerHome)
            case .driver:
                router.navigate(to: .driverDashboard)
            case .partner:
                router.navigate(to: .partnerDashboard)
            case .admin:
                router.navigate(to: .customerHome) // Default to customer view for admin
            }
        } else {
            router.navigate(to: .explore)
        }
        
        isLoading = false
    }
    
    private func sampleOrderForId(_ orderId: String) -> Order {
        // In a real app, this would fetch the order from a repository
        // For now, return a sample order
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

// MARK: - Placeholder Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading MimiSupply...")
                .font(.titleMedium)
                .foregroundColor(.gray600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.chalk)
    }
}

// All views are now implemented in their respective feature folders:
// - ExploreHomeView: Features/Explore/ExploreHomeView.swift
// - CustomerHomeView: Features/Customer/CustomerHomeView.swift (to be created)
// - PartnerDashboardView: Features/Partner/PartnerDashboardView.swift
// - SettingsView: Features/Settings/SettingsView.swift
// - CheckoutView: Features/Shared/CheckoutView.swift
// - AuthenticationView: Features/Authentication/AuthenticationManager.swift
// - RoleSelectionView: Features/Authentication/RoleSelectionView.swift
// - ProfileView: Features/Settings/ProfileView.swift (to be created)
// - OnboardingView: Features/Onboarding/OnboardingView.swift (to be created)

#Preview {
    RootView()
        .environmentObject(AppContainer.shared)
        .environmentObject(AppContainer.shared.appRouter)
}
