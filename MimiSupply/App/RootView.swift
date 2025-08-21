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
    @StateObject private var demoAuth = DemoAuthService.shared
    
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                PremiumLoadingView()
            } else if demoAuth.isAuthenticated {
                // Authenticated user with main tab navigation
                PremiumTabView()
                    .environmentObject(container)
                    .environmentObject(router)
                    .environmentObject(demoAuth)
            } else {
                // Unauthenticated user - show premium sign-in
                PremiumSignInView()
                    .environmentObject(demoAuth)
            }
        }
        .task {
            // Simulate app initialization
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isLoading = false
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
        case .orderTracking(let orderId):
            OrderTrackingView(
                order: sampleOrderForId(orderId),
                cloudKitService: container.cloudKitService,
                onClose: {
                    router.pop()
                }
            )
        case .settings:
            PremiumSettingsView()
        case .cart:
            PremiumCartView()
        case .checkout:
            CheckoutView(
                cartItems: [],
                paymentService: container.paymentService,
                cloudKitService: container.cloudKitService,
                onOrderComplete: { _ in },
                onCancel: { }
            )
        case .authentication:
            PremiumSignInView()
        default:
            EmptyView()
        }
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

// MARK: - Premium Loading View
struct PremiumLoadingView: View {
    @State private var animationOffset: CGFloat = -50
    @State private var animationOpacity: Double = 0
    @State private var logoRotation: Double = 0
    
    var body: some View {
        ZStack {
            // Premium gradient background
            VStack(spacing: 32) {
                // Animated Logo
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(logoRotation))
                    
                    Circle()
                        .fill(.white.opacity(0.95))
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    
                    Image(systemName: "bag.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.31, green: 0.78, blue: 0.47),
                                    Color(red: 0.25, green: 0.85, blue: 0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .offset(y: animationOffset)
                .opacity(animationOpacity)
                
                VStack(spacing: 16) {
                    Text("MimiSupply")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Wird geladen...")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
                .offset(y: animationOffset * 0.5)
                .opacity(animationOpacity)
            }
        }
        .premiumBackground()
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animationOffset = 0
                animationOpacity = 1
            }
            
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                logoRotation = 360
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppContainer.shared)
        .environmentObject(AppContainer.shared.appRouter)
}