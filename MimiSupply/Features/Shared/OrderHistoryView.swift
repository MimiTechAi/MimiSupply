//
//  OrderHistoryView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// View for displaying user's order history with filtering and sorting
struct OrderHistoryView: View {
    @StateObject private var viewModel: OrderHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOrderForTracking: Order?
    @State private var showingOrderTracking = false
    
    init(
        userId: String,
        userRole: UserRole,
        orderRepository: OrderRepository
    ) {
        self._viewModel = StateObject(wrappedValue: OrderHistoryViewModel(
            userId: userId,
            userRole: userRole,
            orderRepository: orderRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter and Sort Controls
                FilterSortBar(
                    selectedStatus: $viewModel.selectedStatusFilter,
                    sortOption: $viewModel.sortOption,
                    sortAscending: $viewModel.sortAscending,
                    onStatusFilterChange: viewModel.applyStatusFilter,
                    onSortChange: viewModel.sortOrders
                )
                
                // Order List
                if viewModel.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredOrders.isEmpty {
                    EmptyOrderHistoryView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.md) {
                            ForEach(viewModel.filteredOrders) { order in
                                OrderHistoryCard(
                                    order: order,
                                    onTap: { 
                                        if order.status == .delivering || order.status == .pickedUp {
                                            selectedOrderForTracking = order
                                            showingOrderTracking = true
                                        } else {
                                            viewModel.selectOrder(order) 
                                        }
                                    }
                                )
                                .padding(.horizontal, Spacing.md)
                            }
                        }
                        .padding(.vertical, Spacing.lg)
                    }
                    .refreshable {
                        await viewModel.refreshOrderHistory()
                    }
                }
            }
            .navigationTitle("Order History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingOrderDetail) {
                if let selectedOrder = viewModel.selectedOrder {
                    OrderDetailView(order: selectedOrder)
                }
            }
            .sheet(isPresented: $showingOrderTracking) {
                if let order = selectedOrderForTracking {
                    OrderTrackingView(
                        order: order,
                        cloudKitService: AppContainer.shared.cloudKitService,
                        onClose: {
                            showingOrderTracking = false
                            selectedOrderForTracking = nil
                        }
                    )
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .task {
            await viewModel.loadOrderHistory()
        }
    }
}

// MARK: - Filter Sort Bar

struct FilterSortBar: View {
    @Binding var selectedStatus: OrderStatus?
    @Binding var sortOption: OrderHistoryViewModel.SortOption
    @Binding var sortAscending: Bool
    
    let onStatusFilterChange: (OrderStatus?) -> Void
    let onSortChange: (OrderHistoryViewModel.SortOption, Bool) -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Status Filter
            Menu {
                Button("All Orders") {
                    selectedStatus = nil
                    onStatusFilterChange(nil)
                }
                
                ForEach(OrderStatus.allCases, id: \.rawValue) { status in
                    Button(status.displayName) {
                        selectedStatus = status
                        onStatusFilterChange(status)
                    }
                }
            } label: {
                HStack {
                    Text(selectedStatus?.displayName ?? "All Orders")
                        .font(.bodyMedium)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.graphite)
            }
            
            Spacer()
            
            // Sort Options
            Menu {
                ForEach(OrderHistoryViewModel.SortOption.allCases, id: \.rawValue) { option in
                    Button(action: {
                        if sortOption == option {
                            sortAscending.toggle()
                        } else {
                            sortOption = option
                            sortAscending = false
                        }
                        onSortChange(option, sortAscending)
                    }) {
                        HStack {
                            Text(option.displayName)
                            if sortOption == option {
                                Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Sort")
                        .font(.bodyMedium)
                }
                .foregroundColor(.graphite)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.gray50)
    }
}

// MARK: - Order History Card

struct OrderHistoryCard: View {
    let order: Order
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Order #\(String(order.id.prefix(8)).uppercased())")
                                .font(.titleSmall)
                                .foregroundColor(.graphite)
                            
                            Text(formatDate(order.createdAt))
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: Spacing.xs) {
                            OrderStatusBadge(status: order.status)
                            
                            if order.status == .delivering || order.status == .pickedUp {
                                Text("Tap to Track")
                                    .font(.caption)
                                    .foregroundColor(.emerald)
                            }
                        }
                    }
                    
                    // Items Summary
                    Text(itemsSummary)
                        .font(.bodyMedium)
                        .foregroundColor(.graphite)
                        .lineLimit(2)
                    
                    // Footer
                    HStack {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "location")
                                .font(.caption)
                                .foregroundColor(.gray500)
                            Text(order.deliveryAddress.street)
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text(order.formattedTotal)
                            .font(.titleSmall)
                            .foregroundColor(.graphite)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var itemsSummary: String {
        let totalItems = order.items.reduce(0) { $0 + $1.quantity }
        if totalItems == 1 {
            return order.items.first?.productName ?? "1 item"
        } else {
            let firstItem = order.items.first?.productName ?? "Items"
            return "\(firstItem) + \(totalItems - 1) more"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Order Status Badge

struct OrderStatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: status.iconName)
                .font(.caption)
            Text(status.displayName)
                .font(.labelSmall)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(backgroundColor)
        .foregroundColor(textColor)
        .cornerRadius(12)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .delivered:
            return .success.opacity(0.1)
        case .cancelled, .failed:
            return .error.opacity(0.1)
        case .delivering, .pickedUp, .enRoute, .driverAssigned:
            return .info.opacity(0.1)
        default:
            return .warning.opacity(0.1)
        }
    }
    
    private var textColor: Color {
        switch status {
        case .delivered:
            return .success
        case .cancelled, .failed:
            return .error
        case .delivering, .pickedUp, .enRoute, .driverAssigned:
            return .info
        default:
            return .warning
        }
    }
}

// MARK: - Empty Order History View

struct EmptyOrderHistoryView: View {
    var body: some View {
        EmptyStateView(
            icon: "clock.badge.xmark",
            title: "No Orders Yet",
            message: "Your order history will appear here once you place your first order.",
            actionTitle: "Start Browsing",
            action: {
                // Navigate to explore view
            }
        )
    }
}



// MARK: - Preview

#if DEBUG
struct OrderHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        OrderHistoryView(
            userId: "user123",
            userRole: .customer,
            orderRepository: OrderRepositoryImpl(cloudKitService: CloudKitServiceImpl())
        )
    }
}
#endif