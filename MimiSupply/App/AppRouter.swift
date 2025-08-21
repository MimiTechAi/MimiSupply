//
//  AppRouter.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI
import Foundation

/// Main navigation router for the MimiSupply app with deep linking and state management
@MainActor
final class AppRouter: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentRoute: AppRoute = .explore
    @Published var presentedSheet: SheetRoute?
    @Published var presentedFullScreen: FullScreenRoute?
    @Published var navigationPath = NavigationPath()
    @Published var selectedTab: TabRoute = .explore
    
    // MARK: - Private Properties
    private let container: AppContainer
    private let userDefaults = UserDefaults.standard
    private let navigationStateKey = "NavigationState"
    
    // MARK: - Initialization
    
    init(container: AppContainer) {
        self.container = container
        restoreNavigationState()
    }
    
    // MARK: - Navigation Methods
    
    func navigate(to route: AppRoute) {
        currentRoute = route
        saveNavigationState()
    }
    
    func push(_ route: AppRoute) {
        navigationPath.append(route)
        saveNavigationState()
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
            saveNavigationState()
        }
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
        saveNavigationState()
    }
    
    func presentSheet(_ sheet: SheetRoute) {
        presentedSheet = sheet
    }
    
    func presentFullScreen(_ fullScreen: FullScreenRoute) {
        presentedFullScreen = fullScreen
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    func navigateToPartnerDetail(_ partner: Partner) {
        navigate(to: .partnerDetail(partner))
    }
    
    func selectTab(_ tab: TabRoute) {
        selectedTab = tab
        
        // Navigate to appropriate route based on tab
        switch tab {
        case .explore:
            navigate(to: .explore)
        case .orders:
            navigate(to: .orderHistory)
        case .profile:
            navigate(to: .profile)
        case .dashboard:
            // Navigate to role-specific dashboard
            Task {
                if let user = await container.authenticationService.currentUser {
                    switch user.role {
                    case .customer:
                        navigate(to: .customerHome)
                    case .driver:
                        navigate(to: .driverDashboard)
                    case .partner:
                        navigate(to: .partnerDashboard)
                    case .admin:
                        navigate(to: .customerHome)
                    }
                }
            }
        }
    }
    
    // MARK: - Deep Linking
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return
        }
        
        switch host {
        case "order":
            handleOrderDeepLink(components)
        case "partner":
            handlePartnerDeepLink(components)
        case "product":
            handleProductDeepLink(components)
        case "auth":
            handleAuthDeepLink(components)
        default:
            break
        }
    }
    
    private func handleOrderDeepLink(_ components: URLComponents) {
        guard let orderId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return
        }
        
        navigate(to: .orderTracking(orderId))
    }
    
    private func handlePartnerDeepLink(_ components: URLComponents) {
        guard let partnerId = components.queryItems?.first(where: { $0.name == "id" })?.value else {
            return
        }
        
        Task {
            do {
                let partners = try await container.cloudKitService.fetchPartners(in: .init())
                if let partner = partners.first(where: { $0.id == partnerId }) {
                    navigate(to: .partnerDetail(partner))
                }
            } catch {
                print("Failed to fetch partner for deep link: \(error)")
            }
        }
    }
    
    private func handleProductDeepLink(_ components: URLComponents) {
        guard let _ = components.queryItems?.first(where: { $0.name == "id" })?.value,
              let partnerId = components.queryItems?.first(where: { $0.name == "partner" })?.value else {
            return
        }
        
        Task {
            do {
                let partners = try await container.cloudKitService.fetchPartners(in: .init())
                if let partner = partners.first(where: { $0.id == partnerId }) {
                    navigate(to: .partnerDetail(partner))
                    // TODO: Navigate to specific product within partner detail
                }
            } catch {
                print("Failed to fetch partner for product deep link: \(error)")
            }
        }
    }
    
    private func handleAuthDeepLink(_ components: URLComponents) {
        guard let action = components.queryItems?.first(where: { $0.name == "action" })?.value else {
            return
        }
        
        switch action {
        case "signin":
            presentSheet(.authentication)
        case "role-selection":
            // Role selection requires a user profile, so we'll handle this differently
            // For now, redirect to authentication which will handle role selection
            presentSheet(.authentication)
        default:
            break
        }
    }
    
    // MARK: - Universal Links
    
    func generateUniversalLink(for route: AppRoute) -> URL? {
        let baseURL = "https://mimisupply.app"
        
        switch route {
        case .orderTracking(let orderId):
            return URL(string: "\(baseURL)/order?id=\(orderId)")
        case .partnerDetail(let partner):
            return URL(string: "\(baseURL)/partner?id=\(partner.id)")
        default:
            return nil
        }
    }
    
    // MARK: - Navigation State Persistence
    
    private func saveNavigationState() {
        let state = NavigationState(
            currentRoute: currentRoute,
            selectedTab: selectedTab
        )
        
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: navigationStateKey)
        }
    }
    
    private func restoreNavigationState() {
        guard let data = userDefaults.data(forKey: navigationStateKey),
              let state = try? JSONDecoder().decode(NavigationState.self, from: data) else {
            return
        }
        
        currentRoute = state.currentRoute
        selectedTab = state.selectedTab
    }
    
    // MARK: - Role-Based Navigation
    
    func navigateToRoleBasedHome(for role: UserRole) {
        switch role {
        case .customer:
            selectedTab = .explore
            navigate(to: .customerHome)
        case .driver:
            selectedTab = .dashboard
            navigate(to: .driverDashboard)
        case .partner:
            selectedTab = .dashboard
            navigate(to: .partnerDashboard)
        case .admin:
            selectedTab = .explore
            navigate(to: .customerHome)
        }
    }
    
    func getTabsForRole(_ role: UserRole) -> [TabRoute] {
        switch role {
        case .customer:
            return [.explore, .orders, .profile]
        case .driver:
            return [.dashboard, .orders, .profile]
        case .partner:
            return [.dashboard, .orders, .profile]
        case .admin:
            return [.explore, .orders, .profile]
        }
    }
}

// MARK: - Route Definitions

enum AppRoute: Hashable, Codable {
    case explore
    case customerHome
    case driverDashboard
    case partnerDashboard
    case partnerDetail(Partner)
    case productDetail(Product)
    case orderTracking(String) // orderId
    case orderHistory
    case cart
    case checkout
    case profile
    case settings
    case authentication
    case roleSelection
    case onboarding
    
    // Custom coding for Partner and Product cases
    enum CodingKeys: String, CodingKey {
        case type
        case partnerId
        case productId
        case orderId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .explore:
            try container.encode("explore", forKey: .type)
        case .customerHome:
            try container.encode("customerHome", forKey: .type)
        case .driverDashboard:
            try container.encode("driverDashboard", forKey: .type)
        case .partnerDashboard:
            try container.encode("partnerDashboard", forKey: .type)
        case .partnerDetail(let partner):
            try container.encode("partnerDetail", forKey: .type)
            try container.encode(partner.id, forKey: .partnerId)
        case .productDetail(let product):
            try container.encode("productDetail", forKey: .type)
            try container.encode(product.id, forKey: .productId)
        case .orderTracking(let orderId):
            try container.encode("orderTracking", forKey: .type)
            try container.encode(orderId, forKey: .orderId)
        case .orderHistory:
            try container.encode("orderHistory", forKey: .type)
        case .cart:
            try container.encode("cart", forKey: .type)
        case .checkout:
            try container.encode("checkout", forKey: .type)
        case .profile:
            try container.encode("profile", forKey: .type)
        case .settings:
            try container.encode("settings", forKey: .type)
        case .authentication:
            try container.encode("authentication", forKey: .type)
        case .roleSelection:
            try container.encode("roleSelection", forKey: .type)
        case .onboarding:
            try container.encode("onboarding", forKey: .type)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "explore":
            self = .explore
        case "customerHome":
            self = .customerHome
        case "driverDashboard":
            self = .driverDashboard
        case "partnerDashboard":
            self = .partnerDashboard
        case "partnerDetail":
            // For now, we'll default to explore if we can't restore the partner
            // In a real app, we'd fetch the partner by ID
            self = .explore
        case "productDetail":
            // For now, we'll default to explore if we can't restore the product
            // In a real app, we'd fetch the product by ID
            self = .explore
        case "orderTracking":
            let orderId = try container.decode(String.self, forKey: .orderId)
            self = .orderTracking(orderId)
        case "orderHistory":
            self = .orderHistory
        case "cart":
            self = .cart
        case "checkout":
            self = .checkout
        case "profile":
            self = .profile
        case "settings":
            self = .settings
        case "authentication":
            self = .authentication
        case "roleSelection":
            self = .roleSelection
        case "onboarding":
            self = .onboarding
        default:
            self = .explore
        }
    }
}

enum TabRoute: String, CaseIterable, Codable {
    case explore = "explore"
    case dashboard = "dashboard"
    case orders = "orders"
    case profile = "profile"
    
    var title: String {
        switch self {
        case .explore:
            return "Explore"
        case .dashboard:
            return "Dashboard"
        case .orders:
            return "Orders"
        case .profile:
            return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .explore:
            return "magnifyingglass"
        case .dashboard:
            return "square.grid.2x2"
        case .orders:
            return "bag"
        case .profile:
            return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .explore:
            return "magnifyingglass.circle.fill"
        case .dashboard:
            return "square.grid.2x2.fill"
        case .orders:
            return "bag.fill"
        case .profile:
            return "person.fill"
        }
    }
}

enum SheetRoute: Identifiable {
    case cart
    case checkout([CartItem])
    case authentication
    case roleSelection(UserProfile)
    case profile
    case productDetail(Product)
    case orderDetail(Order)
    case partnerSettings
    case businessHours
    case productManagement
    case analytics
    
    var id: String {
        switch self {
        case .cart: return "cart"
        case .checkout: return "checkout"
        case .authentication: return "authentication"
        case .roleSelection: return "roleSelection"
        case .profile: return "profile"
        case .productDetail: return "productDetail"
        case .orderDetail: return "orderDetail"
        case .partnerSettings: return "partnerSettings"
        case .businessHours: return "businessHours"
        case .productManagement: return "productManagement"
        case .analytics: return "analytics"
        }
    }
}

enum FullScreenRoute: Identifiable {
    case onboarding
    case orderTracking(Order)
    case jobCompletion(Order)
    
    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .orderTracking: return "orderTracking"
        case .jobCompletion: return "jobCompletion"
        }
    }
}

// MARK: - Navigation State

private struct NavigationState: Codable {
    let currentRoute: AppRoute
    let selectedTab: TabRoute
}