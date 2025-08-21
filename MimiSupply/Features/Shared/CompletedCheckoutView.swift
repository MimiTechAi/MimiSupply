//
//  CompletedCheckoutView.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

/// View displayed after successful order completion with tracking and shopping options
struct CompletedCheckoutView: View {
    let order: Order
    let onTrackOrder: () -> Void
    let onContinueShopping: () -> Void
    
    @State private var showConfettiAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success Animation
            VStack(spacing: Spacing.xl) {
                ZStack {
                    // Confetti Animation Background
                    if showConfettiAnimation {
                        ConfettiView()
                            .transition(.opacity)
                    }
                    
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.success.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.success)
                    }
                    .scaleEffect(showConfettiAnimation ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showConfettiAnimation)
                }
                
                // Success Message
                VStack(spacing: Spacing.md) {
                    Text("Order Confirmed!")
                        .font(.headlineLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.graphite)
                    
                    Text("Your order has been placed successfully and is being prepared with care.")
                        .font(.bodyLarge)
                        .foregroundColor(.gray600)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
            }
            
            Spacer()
            
            // Order Summary Card
            OrderSummaryCard(order: order)
                .padding(.horizontal, Spacing.md)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: Spacing.md) {
                PrimaryButton(
                    title: "Track Your Order",
                    action: onTrackOrder
                )
                
                SecondaryButton(
                    title: "Continue Shopping",
                    action: onContinueShopping
                )
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Trigger success animation
            withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                showConfettiAnimation = true
            }
            
            // Auto-hide confetti after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showConfettiAnimation = false
                }
            }
        }
    }
}

// MARK: - Order Summary Card

struct OrderSummaryCard: View {
    let order: Order
    
    var body: some View {
        AppCard {
            VStack(spacing: Spacing.lg) {
                // Order Header
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Order #\(String(order.id.prefix(8)).uppercased())")
                            .font(.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.graphite)
                        
                        Text("Placed on \(formatDate(order.createdAt))")
                            .font(.bodySmall)
                            .foregroundColor(.gray600)
                    }
                    
                    Spacer()
                    
                    Text(order.formattedTotal)
                        .font(.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.emerald)
                }
                
                AppDivider()
                
                // Delivery Info
                VStack(spacing: Spacing.md) {
                    DeliveryInfoRow(
                        icon: "clock",
                        title: "Estimated Delivery",
                        value: formatDeliveryTime(order.estimatedDeliveryTime),
                        iconColor: .info
                    )
                    
                    DeliveryInfoRow(
                        icon: "location",
                        title: "Delivery Address",
                        value: order.deliveryAddress.singleLineAddress,
                        iconColor: .emerald
                    )
                    
                    if let instructions = order.deliveryInstructions {
                        DeliveryInfoRow(
                            icon: "note.text",
                            title: "Special Instructions",
                            value: instructions,
                            iconColor: .warning
                        )
                    }
                }
                
                AppDivider()
                
                // Order Items Preview
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Items (\(order.itemCount))")
                            .font(.titleSmall)
                            .foregroundColor(.graphite)
                        Spacer()
                    }
                    
                    ForEach(order.items.prefix(3)) { item in
                        HStack {
                            Text("\(item.quantity)×")
                                .font(.bodyMedium)
                                .foregroundColor(.gray600)
                                .frame(width: 25, alignment: .leading)
                            
                            Text(item.productName)
                                .font(.bodyMedium)
                                .foregroundColor(.graphite)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(item.formattedTotalPrice)
                                .font(.bodyMedium)
                                .foregroundColor(.graphite)
                        }
                    }
                    
                    if order.items.count > 3 {
                        Text("+ \(order.items.count - 3) more items")
                            .font(.bodySmall)
                            .foregroundColor(.gray500)
                            .padding(.leading, 25)
                    }
                }
                
                // Status Badge
                HStack {
                    Spacer()
                    OrderStatusBadge(status: order.status)
                    Spacer()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDeliveryTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Delivery Info Row

struct DeliveryInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 20, alignment: .center)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundColor(.gray600)
                
                Text(value)
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
    }
}

// MARK: - Confetti Animation

struct ConfettiView: View {
    @State private var confettiParticles: [ConfettiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiParticles, id: \.id) { particle in
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.rotation))
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.emerald, .success, .info, .warning, .purple, .pink]
        
        for i in 0..<30 {
            let particle = ConfettiParticle(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: 50...300),
                    y: CGFloat.random(in: -50...50)
                ),
                color: colors.randomElement() ?? .emerald,
                rotation: Double.random(in: 0...360),
                opacity: Double.random(in: 0.6...1.0)
            )
            confettiParticles.append(particle)
            
            // Animate particle falling
            withAnimation(
                .easeIn(duration: Double.random(in: 2.0...4.0))
                .delay(Double.random(in: 0...1.0))
            ) {
                if let index = confettiParticles.firstIndex(where: { $0.id == particle.id }) {
                    confettiParticles[index].position.y += 400
                    confettiParticles[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let rotation: Double
    var opacity: Double
}

// MARK: - Preview

#Preview {
    NavigationView {
        CompletedCheckoutView(
            order: Order.mockOrders[0],
            onTrackOrder: {
                print("Track order tapped")
            },
            onContinueShopping: {
                print("Continue shopping tapped")
            }
        )
    }
}