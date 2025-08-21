//
//  OrdersView.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import SwiftUI

/// Orders view showing user's order history and active orders
struct OrdersView: View {
    @StateObject private var viewModel = OrdersViewModel()
    @State private var selectedSegment = 0
    
    private let segments = ["Active", "History"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Orders", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Orders")
            .refreshable {
                await viewModel.refreshOrders()
            }
            .task {
                await viewModel.loadOrders()
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        let orders = selectedSegment == 0 ? viewModel.activeOrders : viewModel.orderHistory
        
        if orders.isEmpty {
            emptyStateView
        } else {
            ordersList(orders)
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<5, id: \.self) { _ in
                    OrderCardSkeleton()
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: selectedSegment == 0 ? "bag" : "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.gray400)
            
            Text(selectedSegment == 0 ? "No Active Orders" : "No Order History")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(selectedSegment == 0 ? 
                 "Your active orders will appear here" : 
                 "Your completed orders will appear here")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if selectedSegment == 0 {
                Button("Start Shopping") {
                    // Navigate to explore
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    @ViewBuilder
    private func ordersList(_ orders: [Order]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(orders) { order in
                    OrderCard(order: order) {
                        // Handle order tap
                        viewModel.selectOrder(order)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Order Card
struct OrderCard: View {
    let order: Order
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order #\(order.id.prefix(8))")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(order.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(order.formattedTotal)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        StatusBadge(status: order.status)
                    }
                }
                
                // Items Summary
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(order.items.prefix(2)) { item in
                        HStack {
                            Text("\(item.quantity)x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(item.productName)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(item.formattedTotalPrice)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if order.items.count > 2 {
                        Text("+ \(order.items.count - 2) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Action Buttons
                if order.status.isActive {
                    HStack(spacing: 12) {
                        if order.canBeTracked {
                            Button("Track Order") {
                                // Handle track order
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        if order.canBeCancelled {
                            Button("Cancel") {
                                // Handle cancel order
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundColor(.red)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(8)
    }
}

// MARK: - Order Card Skeleton
struct OrderCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 16)
                        .frame(maxWidth: 120)
                    
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 12)
                        .frame(maxWidth: 80)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 16)
                        .frame(maxWidth: 60)
                    
                    Rectangle()
                        .fill(Color.gray200)
                        .frame(height: 12)
                        .frame(maxWidth: 50)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<2, id: \.self) { _ in
                    HStack {
                        Rectangle()
                            .fill(Color.gray200)
                            .frame(height: 12)
                            .frame(maxWidth: 200)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.gray200)
                            .frame(height: 12)
                            .frame(maxWidth: 40)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Orders View Model
@MainActor
class OrdersViewModel: ObservableObject {
    @Published var activeOrders: [Order] = []
    @Published var orderHistory: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let cloudKitService: CloudKitService = AppContainer.shared.cloudKitService
    private let authService: AuthenticationService = AppContainer.shared.authenticationService
    
    func loadOrders() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let user = await authService.currentUser else { return }
            
            let orders = try await cloudKitService.fetchOrders(for: user.id, role: user.role)
            
            activeOrders = orders.filter { $0.status.isActive }
            orderHistory = orders.filter { !$0.status.isActive }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func refreshOrders() async {
        await loadOrders()
    }
    
    func selectOrder(_ order: Order) {
        // Handle order selection - navigate to order detail
        print("Selected order: \(order.id)")
    }
}

#Preview {
    OrdersView()
}