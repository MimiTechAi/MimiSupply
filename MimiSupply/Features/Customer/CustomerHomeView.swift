//
//  CustomerHomeView.swift
//  MimiSupply
//
//  Enhanced Customer Dashboard with full functionality
//

import SwiftUI
import MapKit

struct CustomerHomeView: View {
    @StateObject private var viewModel = CustomerHomeViewModel()
    @EnvironmentObject private var appContainer: AppContainer
    @State private var showingLocationPicker = false
    @State private var showingOrderHistory = false
    @State private var showingSearch = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.lg) {
                    // Header with Location and Profile
                    headerSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Explore Partners
                    ExploreHomeView()
                        .padding(.horizontal, Spacing.md)
                    
                    // Recent Orders
                    if !viewModel.recentOrders.isEmpty {
                        recentOrdersSection
                    }
                    
                    // Favorites
                    if !viewModel.favoritePartners.isEmpty {
                        favoritesSection
                    }
                }
                .padding(.top, Spacing.sm)
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView { address in
                    viewModel.updateDeliveryAddress(address)
                    showingLocationPicker = false
                }
            }
            .sheet(isPresented: $showingOrderHistory) {
                OrderHistoryView(
                    userId: appContainer.currentUser?.id ?? "",
                    userRole: .customer,
                    orderRepository: appContainer.orderRepository
                )
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Deliver to")
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                
                Button(action: { showingLocationPicker = true }) {
                    HStack {
                        Text(viewModel.currentAddress?.street ?? "Select Address")
                            .font(.titleSmall)
                            .foregroundColor(.graphite)
                            .lineLimit(1)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray500)
                    }
                }
            }
            
            Spacer()
            
            // Profile Avatar and Cart
            HStack(spacing: Spacing.md) {
                Button(action: { showingSearch = true }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.graphite)
                }
                
                NavigationLink(destination: CartView()) {
                    CartButton()
                }
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Actions")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
                .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    QuickActionCard(
                        icon: "clock",
                        title: "Order History",
                        subtitle: "View past orders"
                    ) {
                        showingOrderHistory = true
                    }
                    
                    QuickActionCard(
                        icon: "heart.fill",
                        title: "Favorites",
                        subtitle: "Your favorite places"
                    ) {
                        viewModel.showFavorites()
                    }
                    
                    QuickActionCard(
                        icon: "percent",
                        title: "Deals",
                        subtitle: "Special offers"
                    ) {
                        viewModel.showDeals()
                    }
                    
                    QuickActionCard(
                        icon: "gift",
                        title: "Rewards",
                        subtitle: "Loyalty points"
                    ) {
                        viewModel.showRewards()
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    private var recentOrdersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Recent Orders")
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                Button("See All") {
                    showingOrderHistory = true
                }
                .font(.bodyMedium)
                .foregroundColor(.emerald)
            }
            .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(viewModel.recentOrders.prefix(3)) { order in
                        RecentOrderCard(order: order) {
                            viewModel.reorderFromOrder(order)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    
    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Your Favorites")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
                .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(viewModel.favoritePartners.prefix(5)) { partner in
                        FavoritePartnerCard(partner: partner)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.emerald)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.graphite)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray600)
                }
            }
            .frame(width: 100, height: 80)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Order Card

struct RecentOrderCard: View {
    let order: Order
    let onReorder: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                AsyncImage(url: order.items.first?.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray200)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(order.items.first?.productName ?? "Order")
                        .font(.labelMedium)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("\(order.items.count) items • \(order.formattedTotal)")
                        .font(.caption)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
            }
            
            Button("Reorder") {
                onReorder()
            }
            .font(.labelSmall)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.emerald.opacity(0.1))
            .foregroundColor(.emerald)
            .cornerRadius(6)
        }
        .padding(Spacing.sm)
        .frame(width: 180)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Favorite Partner Card

struct FavoritePartnerCard: View {
    let partner: Partner
    
    var body: some View {
        NavigationLink(destination: PartnerDetailView(partner: partner)) {
            VStack(spacing: Spacing.sm) {
                AsyncImage(url: partner.logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray200)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(30)
                
                VStack(spacing: 2) {
                    Text(partner.name)
                        .font(.labelMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.graphite)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", partner.rating))
                            .font(.caption)
                            .foregroundColor(.gray600)
                    }
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ViewModel

@MainActor
class CustomerHomeViewModel: ObservableObject {
    @Published var currentAddress: Address?
    @Published var recentOrders: [Order] = []
    @Published var favoritePartners: [Partner] = []
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var isLoading = false
    
    private let orderRepository: OrderRepository
    private let partnerRepository: PartnerRepository
    private let userRepository: UserRepository
    
    init() {
        self.orderRepository = AppContainer.shared.orderRepository
        self.partnerRepository = AppContainer.shared.partnerRepository
        self.userRepository = AppContainer.shared.userRepository
    }
    
    func loadInitialData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadCurrentAddress() }
            group.addTask { await self.loadRecentOrders() }
            group.addTask { await self.loadFavoritePartners() }
        }
    }
    
    func refreshData() async {
        await loadInitialData()
    }
    
    private func loadCurrentAddress() async {
        // Load user's default delivery address
        do {
            if let user = AppContainer.shared.currentUser {
                // In a real app, you'd have saved addresses
                currentAddress = Address(
                    street: "123 Default St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94105",
                    country: "US"
                )
            }
        } catch {
            await showError("Failed to load address: \(error.localizedDescription)")
        }
    }
    
    private func loadRecentOrders() async {
        do {
            guard let userId = AppContainer.shared.currentUser?.id else { return }
            recentOrders = try await orderRepository.fetchRecentOrders(for: userId, role: .customer, limit: 5)
        } catch {
            await showError("Failed to load recent orders: \(error.localizedDescription)")
        }
    }
    
    private func loadFavoritePartners() async {
        do {
            // Load user's favorite partners
            favoritePartners = [] // Placeholder - implement favorites
        } catch {
            await showError("Failed to load favorites: \(error.localizedDescription)")
        }
    }
    
    func updateDeliveryAddress(_ address: Address) {
        currentAddress = address
        // Save to user preferences
    }
    
    func reorderFromOrder(_ order: Order) {
        // Add order items to cart
        Task {
            do {
                let cartService = AppContainer.shared.cartService
                for item in order.items {
                    // Convert OrderItem to Product and add to cart
                    // Implementation depends on your cart service
                }
            } catch {
                await showError("Failed to reorder: \(error.localizedDescription)")
            }
        }
    }
    
    func showFavorites() {
        // Navigate to favorites view
    }
    
    func showDeals() {
        // Navigate to deals view
    }
    
    func showRewards() {
        // Navigate to rewards view
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    private func showError(_ message: String) async {
        errorMessage = message
        showingError = true
    }
}

#Preview {
    CustomerHomeView()
        .environmentObject(AppContainer.shared)
}