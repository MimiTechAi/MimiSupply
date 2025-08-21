//
//  OrderDetailView.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

/// Detailed view of an order with status, items, and tracking information
struct OrderDetailView: View {
    let order: Order
    @Environment(\.dismiss) private var dismiss
    
    private var actionButtons: some View {
        VStack(spacing: Spacing.md) {
            if order.status == .delivering || order.status == .pickedUp || order.status == .enRoute {
                PrimaryButton(
                    title: "Track Order",
                    action: {
                        showOrderTracking()
                    },
                    isLoading: false,
                    isDisabled: false
                )
            }
            
            if order.status == .delivered {
                VStack(spacing: Spacing.sm) {
                    SecondaryButton(
                        title: "Reorder",
                        action: {
                            handleReorder()
                        }
                    )
                    
                    SecondaryButton(
                        title: "Rate & Review",
                        action: {
                            handleRateAndReview()
                        }
                    )
                }
            }
            
            if canCancelOrder {
                SecondaryButton(
                    title: "Cancel Order",
                    action: {
                        handleOrderCancellation()
                    }
                )
            }
        }
    }

    // MARK: - Action Handlers
    
    @State private var showingOrderTracking = false
    @State private var showingCancellationAlert = false
    
    private func showOrderTracking() {
        showingOrderTracking = true
    }
    
    private func handleReorder() {
        // Navigate to partner detail with pre-filled cart
        // This would be implemented with navigation coordination
        print("Reorder functionality - would navigate to partner with items")
    }
    
    private func handleRateAndReview() {
        // Show rating and review interface
        print("Rate and review functionality")
    }
    
    private func handleOrderCancellation() {
        showingCancellationAlert = true
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Order Header
                orderHeader
                
                // Order Status
                orderStatus
                
                // Delivery Information
                deliveryInfo
                
                // Order Items
                orderItems
                
                // Payment Summary
                paymentSummary
                
                // Action Buttons
                actionButtons
            }
            .padding(.horizontal, Spacing.md)
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingOrderTracking) {
            OrderTrackingView(
                order: order,
                cloudKitService: CloudKitServiceImpl(),
                onClose: {
                    showingOrderTracking = false
                }
            )
        }
        .alert("Cancel Order", isPresented: $showingCancellationAlert) {
            Button("Cancel Order", role: .destructive) {
                Task {
                    await cancelOrder()
                }
            }
            Button("Keep Order", role: .cancel) { }
        } message: {
            Text("Are you sure you want to cancel this order? This action cannot be undone.")
        }
    }
    
    private func cancelOrder() async {
        // This would integrate with OrderManager
        print("Order cancellation requested for order: \(order.id)")
    }
    
    private var orderHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Order #\(order.id.prefix(8))")
                .font(.headlineSmall)
                .foregroundColor(.graphite)
            
            Text("Placed on \(order.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.bodyMedium)
                .foregroundColor(.gray600)
        }
    }
    
    private var orderStatus: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Status")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(order.status.displayName)
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                Text("ETA: \(order.estimatedDeliveryTime.formatted(date: .omitted, time: .shortened))")
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
            }
        }
        .padding(Spacing.md)
        .background(Color.gray50)
        .cornerRadius(8)
    }
    
    private var deliveryInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Delivery Address")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            Text(order.deliveryAddress.singleLineAddress)
                .font(.bodyMedium)
                .foregroundColor(.gray700)
            
            if let instructions = order.deliveryInstructions {
                Text("Instructions: \(instructions)")
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                    .padding(.top, Spacing.xs)
            }
        }
    }
    
    private var orderItems: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Items")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            ForEach(order.items) { item in
                HStack {
                    Text("\(item.quantity)x")
                        .font(.bodyMedium)
                        .foregroundColor(.gray600)
                        .frame(width: 30, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(item.productName)
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                        
                        if let instructions = item.specialInstructions {
                            Text("Note: \(instructions)")
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                    }
                    
                    Spacer()
                    
                    Text(formatCurrency(item.totalPriceCents))
                        .font(.bodyMedium)
                        .foregroundColor(.graphite)
                }
                .padding(.vertical, Spacing.xs)
                
                if item.id != order.items.last?.id {
                    Divider()
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var paymentSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Payment Summary")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            VStack(spacing: Spacing.xs) {
                summaryRow("Subtotal", formatCurrency(order.subtotalCents))
                summaryRow("Delivery Fee", formatCurrency(order.deliveryFeeCents))
                summaryRow("Platform Fee", formatCurrency(order.platformFeeCents))
                summaryRow("Tax", formatCurrency(order.taxCents))
                
                if order.tipCents > 0 {
                    summaryRow("Tip", formatCurrency(order.tipCents))
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.graphite)
                    
                    Spacer()
                    
                    Text(formatCurrency(order.totalCents))
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.graphite)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func summaryRow(_ title: String, _ amount: String) -> some View {
        HStack {
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.gray700)
            
            Spacer()
            
            Text(amount)
                .font(.bodyMedium)
                .foregroundColor(.gray700)
        }
    }
    
    private var statusColor: Color {
        switch order.status {
        case .created, .paymentProcessing, .pending:
            return .warning
        case .paymentConfirmed, .accepted, .preparing, .confirmed, .ready, .readyForPickup, .pickedUp, .enRoute, .delivering, .driverAssigned:
            return .info
        case .delivered:
            return .success
        case .cancelled, .failed:
            return .error
        }
    }
    
    private var canCancelOrder: Bool {
        switch order.status {
        case .created, .paymentProcessing, .paymentConfirmed, .accepted:
            return true
        default:
            return false
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

#Preview {
    NavigationView {
        OrderDetailView(
            order: Order(
                customerId: "customer123",
                partnerId: "partner123",
                items: [
                    OrderItem(
                        productId: "product1",
                        productName: "Pizza Margherita",
                        quantity: 2,
                        unitPriceCents: 1200
                    ),
                    OrderItem(
                        productId: "product2",
                        productName: "Caesar Salad",
                        quantity: 1,
                        unitPriceCents: 800
                    )
                ],
                status: .delivering,
                subtotalCents: 3200,
                deliveryFeeCents: 200,
                platformFeeCents: 100,
                taxCents: 320,
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
        )
    }
}