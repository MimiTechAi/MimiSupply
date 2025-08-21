import SwiftUI
import CloudKit
import Combine

@MainActor
class PartnerDashboardViewModel: ObservableObject {
    @Published var todayOrders: Int = 0
    @Published var todayRevenue: Int = 0
    @Published var averageRating: Double = 0.0
    @Published var isOnline: Bool = false
    @Published var pendingOrders: [Order] = []
    @Published var recentOrders: [Order] = []
    @Published var isLoading: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    
    private let cloudKitService: CloudKitService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        authService: AuthenticationService = AuthenticationServiceImpl.shared
    ) {
        self.cloudKitService = cloudKitService
        self.authService = authService
        
        setupSubscriptions()
    }
    
    func initialize() async {
        isLoading = true
        
        do {
            async let ordersTask: Void = loadOrders()
            async let statsTask: Void = loadBusinessStats()
            async let statusTask: Void = loadBusinessStatus()
            
            try await ordersTask
            try await statsTask
            try await statusTask
            
            await subscribeToOrderUpdates()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await initialize()
    }
    
    func toggleOnlineStatus() {
        Task {
            do {
                isOnline.toggle()
                try await updateBusinessStatus(isOnline: isOnline)
            } catch {
                isOnline.toggle() // Revert on error
                handleError(error)
            }
        }
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) {
        Task {
            do {
                try await cloudKitService.updateOrderStatus(orderId, status: status)
                try await loadOrders() // Refresh orders
            } catch {
                handleError(error)
            }
        }
    }
    
    func selectOrder(_ order: Order) {
        // Handle order selection - could navigate to order detail
        print("Selected order: \(order.id)")
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to real-time order updates
        NotificationCenter.default
            .publisher(for: .orderStatusUpdated)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleOrderUpdate(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadOrders() async throws {
        guard let currentUser = await authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        // Load pending orders (orders that need partner action)
        let pendingStatuses: [OrderStatus] = [.paymentConfirmed, .accepted, .preparing]
        pendingOrders = try await cloudKitService.fetchOrders(
            for: currentUser.id,
            role: .partner,
            statuses: pendingStatuses
        )
        
        // Load recent orders for history
        recentOrders = try await cloudKitService.fetchRecentOrders(
            for: currentUser.id,
            role: .partner,
            limit: 10
        )
    }
    
    private func loadBusinessStats() async throws {
        guard let currentUser = await authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        let stats = try await cloudKitService.fetchPartnerStats(for: currentUser.id)
        
        todayOrders = stats.todayOrderCount
        todayRevenue = stats.todayRevenueCents
        averageRating = stats.averageRating
    }
    
    private func loadBusinessStatus() async throws {
        guard let currentUser = await authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        let partner = try await cloudKitService.fetchPartner(by: currentUser.id)
        isOnline = partner?.isActive ?? false
    }
    
    private func updateBusinessStatus(isOnline: Bool) async throws {
        guard let currentUser = await authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        
        try await cloudKitService.updatePartnerStatus(
            partnerId: currentUser.id,
            isActive: isOnline
        )
    }
    
    private func subscribeToOrderUpdates() async {
        guard let currentUser = await authService.currentUser else { return }
        
        do {
            try await cloudKitService.subscribeToOrderUpdates(for: currentUser.id)
        } catch {
            print("Failed to subscribe to order updates: \(error)")
        }
    }
    
    private func handleOrderUpdate(_ notification: Notification) async {
        // Refresh orders when updates are received
        do {
            try await loadOrders()
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let orderStatusUpdated = Notification.Name("orderStatusUpdated")
}