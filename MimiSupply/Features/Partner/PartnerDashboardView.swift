import SwiftUI
import CloudKit

struct PartnerDashboardView: View {
    @StateObject private var viewModel = PartnerDashboardViewModel()
    @State private var showingProductManagement = false
    @State private var showingAnalytics = false
    @State private var showingBusinessHours = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Business Stats Card
                    BusinessStatsCard(
                        todayOrders: viewModel.todayOrders,
                        todayRevenue: viewModel.todayRevenue,
                        averageRating: viewModel.averageRating,
                        isOnline: viewModel.isOnline,
                        onToggleOnline: viewModel.toggleOnlineStatus
                    )
                    
                    // Pending Orders Section
                    if !viewModel.pendingOrders.isEmpty {
                        PendingOrdersSection(
                            orders: viewModel.pendingOrders,
                            onUpdateStatus: viewModel.updateOrderStatus
                        )
                    }
                    
                    // Quick Actions Grid
                    QuickActionsGrid(
                        onManageProducts: { showingProductManagement = true },
                        onViewAnalytics: { showingAnalytics = true },
                        onUpdateHours: { showingBusinessHours = true }
                    )
                    
                    // Recent Orders List
                    RecentOrdersList(
                        orders: viewModel.recentOrders,
                        onOrderTap: viewModel.selectOrder
                    )
                    
                    // Bottom padding to avoid tab bar overlap
                    Color.clear
                        .frame(height: 100)
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Partner Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingProductManagement) {
                ProductManagementView()
            }
            .sheet(isPresented: $showingAnalytics) {
                AnalyticsDashboardView()
            }
            .sheet(isPresented: $showingBusinessHours) {
                BusinessHoursManagementView()
            }
            .sheet(isPresented: $showingSettings) {
                PartnerSettingsView()
            }
        }
        .task {
            await viewModel.initialize()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Business Stats Card
struct BusinessStatsCard: View {
    let todayOrders: Int
    let todayRevenue: Int
    let averageRating: Double
    let isOnline: Bool
    let onToggleOnline: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Online Status Toggle
            HStack {
                VStack(alignment: .leading) {
                    Text("Business Status")
                        .font(.titleMedium)
                        .foregroundColor(.graphite)
                    Text(isOnline ? "Online" : "Offline")
                        .font(.bodyMedium)
                        .foregroundColor(isOnline ? .success : .gray500)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isOnline },
                    set: { _ in onToggleOnline() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .emerald))
                .accessibilityLabel("Toggle business online status")
            }
            
            Divider()
            
            // Stats Grid
            HStack(spacing: 24) {
                StatItem(
                    title: "Today's Orders",
                    value: "\(todayOrders)",
                    icon: "bag.fill"
                )
                
                StatItem(
                    title: "Today's Revenue",
                    value: formatCurrency(todayRevenue),
                    icon: "dollarsign.circle.fill"
                )
                
                StatItem(
                    title: "Rating",
                    value: String(format: "%.1f", averageRating),
                    icon: "star.fill"
                )
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.emerald)
            
            Text(value)
                .font(.titleLarge)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
            
            Text(title)
                .font(.bodySmall)
                .foregroundColor(.gray600)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pending Orders Section
struct PendingOrdersSection: View {
    let orders: [Order]
    let onUpdateStatus: (String, OrderStatus) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Orders")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            ForEach(orders) { order in
                PendingOrderCard(
                    order: order,
                    onUpdateStatus: onUpdateStatus
                )
            }
        }
    }
}

// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    let onManageProducts: () -> Void
    let onViewAnalytics: () -> Void
    let onUpdateHours: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Manage Products",
                    icon: "square.grid.2x2",
                    color: .emerald,
                    action: onManageProducts
                )
                
                QuickActionCard(
                    title: "View Analytics",
                    icon: "chart.bar.fill",
                    color: .info,
                    action: onViewAnalytics
                )
                
                QuickActionCard(
                    title: "Business Hours",
                    icon: "clock.fill",
                    color: .warning,
                    action: onUpdateHours
                )
                
                QuickActionCard(
                    title: "Profile Settings",
                    icon: "person.crop.circle",
                    color: .gray600,
                    action: { /* Handle in parent */ }
                )
            }
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .accessibilityLabel(title)
    }
}

#Preview {
    PartnerDashboardView()
}
