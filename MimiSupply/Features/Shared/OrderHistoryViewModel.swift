//
//  OrderHistoryViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation

/// View model for managing order history with filtering and sorting capabilities
@MainActor
final class OrderHistoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var orders: [Order] = []
    @Published var filteredOrders: [Order] = []
    @Published var selectedOrder: Order?
    @Published var selectedStatusFilter: OrderStatus?
    @Published var sortOption: SortOption = .date
    @Published var sortAscending: Bool = false
    @Published var isLoading: Bool = false
    @Published var showingOrderDetail: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Private Properties
    
    private let userId: String
    private let userRole: UserRole
    private let orderRepository: OrderRepository
    
    // MARK: - Initialization
    
    init(
        userId: String,
        userRole: UserRole,
        orderRepository: OrderRepository
    ) {
        self.userId = userId
        self.userRole = userRole
        self.orderRepository = orderRepository
    }
    
    // MARK: - Public Methods
    
    func loadOrderHistory() async {
        isLoading = true
        
        do {
            orders = try await orderRepository.fetchOrders(for: userId, role: userRole)
            applyFiltersAndSorting()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refreshOrderHistory() async {
        await loadOrderHistory()
    }
    
    func applyStatusFilter(_ status: OrderStatus?) {
        selectedStatusFilter = status
        applyFiltersAndSorting()
    }
    
    func sortOrders(by option: SortOption, ascending: Bool) {
        sortOption = option
        sortAscending = ascending
        applyFiltersAndSorting()
    }
    
    func selectOrder(_ order: Order) {
        selectedOrder = order
        showingOrderDetail = true
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    private func applyFiltersAndSorting() {
        var filtered = orders
        
        // Apply status filter
        if let statusFilter = selectedStatusFilter {
            filtered = filtered.filter { $0.status == statusFilter }
        }
        
        // Apply sorting
        filtered = sortOrdersArray(filtered, by: sortOption, ascending: sortAscending)
        
        filteredOrders = filtered
    }
    
    private func sortOrdersArray(_ orders: [Order], by option: SortOption, ascending: Bool) -> [Order] {
        switch option {
        case .date:
            return orders.sorted { 
                ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
            }
        case .amount:
            return orders.sorted { 
                ascending ? $0.totalCents < $1.totalCents : $0.totalCents > $1.totalCents
            }
        case .status:
            return orders.sorted { 
                let order1Priority = statusSortPriority($0.status)
                let order2Priority = statusSortPriority($1.status)
                return ascending ? order1Priority < order2Priority : order1Priority > order2Priority
            }
        }
    }
    
    private func statusSortPriority(_ status: OrderStatus) -> Int {
        switch status {
        case .created: return 0
        case .paymentProcessing: return 1
        case .paymentConfirmed: return 2
        case .accepted: return 3
        case .pending: return 4
        case .confirmed: return 5
        case .preparing: return 6
        case .driverAssigned: return 7
        case .ready: return 8
        case .readyForPickup: return 9
        case .pickedUp: return 10
        case .enRoute: return 11
        case .delivering: return 12
        case .delivered: return 13
        case .cancelled: return 14
        case .failed: return 15
        }
    }
    
    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            errorMessage = appError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred while loading your order history."
        }
        showingError = true
    }
}

// MARK: - Supporting Types

extension OrderHistoryViewModel {
    enum SortOption: String, CaseIterable {
        case date = "date"
        case amount = "amount"
        case status = "status"
        
        var displayName: String {
            switch self {
            case .date:
                return "Date"
            case .amount:
                return "Amount"
            case .status:
                return "Status"
            }
        }
    }
}
