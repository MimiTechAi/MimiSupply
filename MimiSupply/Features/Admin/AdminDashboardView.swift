import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @State private var showingUserManagement = false
    @State private var showingPartnerManagement = false
    @State private var showingSystemAnalytics = false
    @State private var showingOrderMonitoring = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // System Status Card
                    SystemStatusCard(
                        activeUsers: viewModel.activeUsers,
                        activePartners: viewModel.activePartners,
                        totalOrders: viewModel.totalOrders,
                        systemHealth: viewModel.systemHealth,
                        lastUpdated: viewModel.lastUpdated
                    )
                    
                    // System Statistics
                    SystemStatisticsGrid(
                        ordersToday: viewModel.ordersToday,
                        revenueToday: viewModel.revenueToday,
                        newUsers: viewModel.newUsersToday,
                        completedDeliveries: viewModel.completedDeliveriesToday
                    )
                    
                    // Quick Actions
                    AdminQuickActions(
                        onViewUsers: { showingUserManagement = true },
                        onViewPartners: { showingPartnerManagement = true },
                        onViewAnalytics: { showingSystemAnalytics = true },
                        onViewOrders: { showingOrderMonitoring = true }
                    )
                    
                    // Recent Activity
                    RecentActivitySection(
                        activities: viewModel.recentActivities
                    )
                }
                .padding(.horizontal, 16)
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refresh()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh dashboard")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingUserManagement) {
                UserManagementView()
            }
            .sheet(isPresented: $showingPartnerManagement) {
                PartnerManagementView()
            }
            .sheet(isPresented: $showingSystemAnalytics) {
                SystemAnalyticsView()
            }
            .sheet(isPresented: $showingOrderMonitoring) {
                OrderMonitoringView()
            }
        }
        .task {
            await viewModel.initialize()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - System Status Card
struct SystemStatusCard: View {
    let activeUsers: Int
    let activePartners: Int
    let totalOrders: Int
    let systemHealth: SystemHealthStatus
    let lastUpdated: Date
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("System Status")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                StatusIndicator(
                    title: systemHealth.description,
                    value: "System",
                    color: systemHealth.color
                )
            }
            
            Divider()
            
            HStack(spacing: 24) {
                StatItem(
                    title: "Active Users",
                    value: "\(activeUsers)",
                    icon: "person.2.fill"
                )
                
                StatItem(
                    title: "Active Partners",
                    value: "\(activePartners)",
                    icon: "storefront.fill"
                )
                
                StatItem(
                    title: "Total Orders",
                    value: "\(totalOrders)",
                    icon: "bag.fill"
                )
            }
            
            HStack {
                Text("Last updated:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(lastUpdated.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - System Statistics Grid
struct SystemStatisticsGrid: View {
    let ordersToday: Int
    let revenueToday: Int
    let newUsers: Int
    let completedDeliveries: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCard(
                    title: "Orders Today",
                    value: "\(ordersToday)",
                    icon: "bag.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Revenue Today",
                    value: formatCurrency(revenueToday),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "New Users",
                    value: "\(newUsers)",
                    icon: "person.fill.badge.plus",
                    color: .purple
                )
                
                StatCard(
                    title: "Completed Deliveries",
                    value: "\(completedDeliveries)",
                    icon: "checkmark.seal.fill",
                    color: .orange
                )
            }
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let euros = Double(cents) / 100.0
        return String(format: "€%.2f", euros)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Admin Quick Actions
struct AdminQuickActions: View {
    let onViewUsers: () -> Void
    let onViewPartners: () -> Void
    let onViewAnalytics: () -> Void
    let onViewOrders: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Management")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                AdminActionCard(
                    title: "User Management",
                    icon: "person.3.fill",
                    color: .blue,
                    action: onViewUsers
                )
                
                AdminActionCard(
                    title: "Partner Management",
                    icon: "storefront.fill",
                    color: .green,
                    action: onViewPartners
                )
                
                AdminActionCard(
                    title: "System Analytics",
                    icon: "chart.bar.fill",
                    color: .purple,
                    action: onViewAnalytics
                )
                
                AdminActionCard(
                    title: "Order Monitoring",
                    icon: "magnifyingglass",
                    color: .orange,
                    action: onViewOrders
                )
            }
        }
    }
}

// MARK: - Admin Action Card
struct AdminActionCard: View {
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
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let activities: [AdminActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if activities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No Recent Activity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("System activities will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                ForEach(activities) { activity in
                    ActivityItem(activity: activity)
                }
            }
        }
    }
}

// MARK: - Activity Item
struct ActivityItem: View {
    let activity: AdminActivity
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(activity.iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AdminDashboardView()
}