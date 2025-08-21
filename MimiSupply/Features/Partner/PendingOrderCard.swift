import SwiftUI

struct PendingOrderCard: View {
    let order: Order
    let onUpdateStatus: (String, OrderStatus) -> Void
    
    @State private var showingStatusOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Order Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.id.prefix(8))")
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.graphite)
                    
                    Text(formatTime(order.createdAt))
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                PartnerStatusBadge(status: order.status)
            }
            
            // Order Items Summary
            VStack(alignment: .leading, spacing: 4) {
                ForEach(order.items.prefix(3)) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .font(.bodySmall)
                            .foregroundColor(.gray600)
                            .frame(width: 30, alignment: .leading)
                        
                        Text(item.productName)
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.totalPriceCents))
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                    }
                }
                
                if order.items.count > 3 {
                    Text("+ \(order.items.count - 3) more items")
                        .font(.bodySmall)
                        .foregroundColor(.gray500)
                        .padding(.leading, 30)
                }
            }
            
            Divider()
            
            // Order Total and Actions
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                    Text(formatCurrency(order.totalCents))
                        .font(.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.graphite)
                }
                
                Spacer()
                
                // Action Buttons based on current status
                HStack(spacing: 8) {
                    if order.status == .paymentConfirmed {
                        ActionButton(
                            title: "Accept",
                            color: .success,
                            action: { onUpdateStatus(order.id, .accepted) }
                        )
                        
                        ActionButton(
                            title: "Decline",
                            color: .error,
                            action: { onUpdateStatus(order.id, .cancelled) }
                        )
                    } else if order.status == .accepted {
                        ActionButton(
                            title: "Start Preparing",
                            color: .warning,
                            action: { onUpdateStatus(order.id, .preparing) }
                        )
                    } else if order.status == .preparing {
                        ActionButton(
                            title: "Ready for Pickup",
                            color: .emerald,
                            action: { onUpdateStatus(order.id, .readyForPickup) }
                        )
                    }
                }
            }
            
            // Delivery Address
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.gray500)
                    .font(.caption)
                
                Text("\(order.deliveryAddress.street), \(order.deliveryAddress.city)")
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                    .lineLimit(1)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Status Badge (Partner)
struct PartnerStatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.labelSmall)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color)
            .cornerRadius(6)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.labelMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color)
                .cornerRadius(6)
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Recent Orders List
struct RecentOrdersList: View {
    let orders: [Order]
    let onOrderTap: (Order) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Orders")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            if orders.isEmpty {
                EmptyStateView(
                    icon: "bag",
                    title: "No Recent Orders",
                    message: "Your recent orders will appear here"
                )
                .frame(height: 120)
            } else {
                ForEach(orders) { order in
                    RecentOrderRow(
                        order: order,
                        onTap: { onOrderTap(order) }
                    )
                }
            }
        }
    }
}

// MARK: - Recent Order Row
struct RecentOrderRow: View {
    let order: Order
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order #\(order.id.prefix(8))")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.graphite)
                    
                    Text("\(order.items.count) items • \(formatTime(order.createdAt))")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(order.totalCents))
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.graphite)
                    
                    StatusBadge(status: order.status)
                }
            }
            .padding(.vertical, 8)
        }
        .accessibilityLabel("Order \(order.id.prefix(8)), \(order.items.count) items, \(formatCurrency(order.totalCents)), \(order.status.displayName)")
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - OrderStatus Extension
extension OrderStatus {
    var color: Color {
        switch self {
        case .pending: return .warning
        case .confirmed: return .info
        case .created, .paymentProcessing: return .gray500
        case .paymentConfirmed: return .info
        case .accepted: return .warning
        case .preparing: return .warning
        case .driverAssigned: return .info
        case .ready: return .emerald
        case .readyForPickup: return .emerald
        case .pickedUp, .delivering: return .info
        case .enRoute: return .info
        case .delivered: return .success
        case .cancelled, .failed: return .error
        }
    }
}

// MARK: - Mock Data
extension Order {
    static let mockPendingOrder = Order(
        id: "order123",
        customerId: "customer1",
        partnerId: "partner1",
        driverId: nil,
        items: [
            OrderItem(
                id: "item1",
                productId: "product1",
                productName: "Margherita Pizza",
                quantity: 2,
                unitPriceCents: 1299,
                specialInstructions: nil
            ),
            OrderItem(
                id: "item2",
                productId: "product2",
                productName: "Caesar Salad",
                quantity: 1,
                unitPriceCents: 899,
                specialInstructions: "Extra dressing"
            )
        ],
        status: .paymentConfirmed,
        subtotalCents: 3497,
        deliveryFeeCents: 299,
        platformFeeCents: 150,
        taxCents: 280,
        tipCents: 500,
        deliveryAddress: Address(
            street: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94102",
            country: "US"
        ),
        deliveryInstructions: "Ring doorbell",
        estimatedDeliveryTime: Date().addingTimeInterval(1800),
        actualDeliveryTime: nil,
        paymentMethod: .applePay,
        paymentStatus: .completed,
        createdAt: Date().addingTimeInterval(-600),
        updatedAt: Date().addingTimeInterval(-300)
    )
    
    static let mockDeliveredOrder = Order(
        id: "order456",
        customerId: "customer2",
        partnerId: "partner1",
        driverId: "driver1",
        items: [
            OrderItem(
                id: "item3",
                productId: "product3",
                productName: "Chicken Sandwich",
                quantity: 1,
                unitPriceCents: 1199,
                specialInstructions: nil
            )
        ],
        status: .delivered,
        subtotalCents: 1199,
        deliveryFeeCents: 299,
        platformFeeCents: 100,
        taxCents: 120,
        tipCents: 300,
        deliveryAddress: Address(
            street: "456 Oak Ave",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103",
            country: "US"
        ),
        deliveryInstructions: nil,
        estimatedDeliveryTime: Date().addingTimeInterval(-1800),
        actualDeliveryTime: Date().addingTimeInterval(-300),
        paymentMethod: .applePay,
        paymentStatus: .completed,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date().addingTimeInterval(-300)
    )
}