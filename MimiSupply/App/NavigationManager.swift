//
//  NavigationManager.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI
import Foundation

/// Manages navigation state persistence and restoration
@MainActor
final class NavigationManager: ObservableObject {
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let navigationStateKey = "MimiSupply_NavigationState"
    private let tabStateKey = "MimiSupply_TabState"
    
    // MARK: - Navigation State Persistence
    
    func saveNavigationState(_ router: AppRouter) {
        let state = NavigationState(
            currentRoute: router.currentRoute,
            selectedTab: router.selectedTab,
            navigationPathCount: router.navigationPath.count
        )
        
        if let data = try? JSONEncoder().encode(state) {
            userDefaults.set(data, forKey: navigationStateKey)
        }
    }
    
    func restoreNavigationState(to router: AppRouter) {
        guard let data = userDefaults.data(forKey: navigationStateKey),
              let state = try? JSONDecoder().decode(NavigationState.self, from: data) else {
            return
        }
        
        router.currentRoute = state.currentRoute
        router.selectedTab = state.selectedTab
        
        // Note: NavigationPath restoration is complex and may require
        // storing the actual route data. For now, we'll just restore
        // the basic state and let the user navigate naturally.
    }
    
    func clearNavigationState() {
        userDefaults.removeObject(forKey: navigationStateKey)
        userDefaults.removeObject(forKey: tabStateKey)
    }
    
    // MARK: - Deep Link Handling
    
    func handleUniversalLink(_ url: URL, router: AppRouter) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        // Handle mimisupply.app universal links
        if components.host == "mimisupply.app" || components.host == "www.mimisupply.app" {
            return handleWebLink(components, router: router)
        }
        
        // Handle custom URL scheme
        if components.scheme == "mimisupply" {
            return handleCustomScheme(components, router: router)
        }
        
        return false
    }
    
    private func handleWebLink(_ components: URLComponents, router: AppRouter) -> Bool {
        guard let path = components.path.split(separator: "/").first else {
            return false
        }
        
        switch String(path) {
        case "order":
            if let orderId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                router.navigate(to: .orderTracking(orderId))
                return true
            }
        case "partner":
            if let _ = components.queryItems?.first(where: { $0.name == "id" })?.value {
                // In a real app, we'd fetch the partner by ID
                // For now, navigate to explore and let user search
                router.navigate(to: .explore)
                return true
            }
        case "product":
            if let _ = components.queryItems?.first(where: { $0.name == "id" })?.value {
                // In a real app, we'd fetch the product by ID
                // For now, navigate to explore
                router.navigate(to: .explore)
                return true
            }
        default:
            break
        }
        
        return false
    }
    
    private func handleCustomScheme(_ components: URLComponents, router: AppRouter) -> Bool {
        guard let host = components.host else { return false }
        
        switch host {
        case "order":
            if let orderId = components.queryItems?.first(where: { $0.name == "id" })?.value {
                router.navigate(to: .orderTracking(orderId))
                return true
            }
        case "auth":
            if let action = components.queryItems?.first(where: { $0.name == "action" })?.value {
                switch action {
                case "signin":
                    router.presentSheet(.authentication)
                    return true
                case "role-selection":
                    // This would need user context in a real app
                    return true
                default:
                    break
                }
            }
        case "explore":
            router.navigate(to: .explore)
            return true
        default:
            break
        }
        
        return false
    }
    
    // MARK: - Universal Link Generation
    
    func generateUniversalLink(for route: AppRoute) -> URL? {
        let baseURL = "https://mimisupply.app"
        
        switch route {
        case .orderTracking(let orderId):
            return URL(string: "\(baseURL)/order?id=\(orderId)")
        case .partnerDetail(let partner):
            return URL(string: "\(baseURL)/partner?id=\(partner.id)")
        case .productDetail(let product):
            return URL(string: "\(baseURL)/product?id=\(product.id)")
        default:
            return URL(string: baseURL)
        }
    }
    
    func generateCustomSchemeLink(for route: AppRoute) -> URL? {
        switch route {
        case .orderTracking(let orderId):
            return URL(string: "mimisupply://order?id=\(orderId)")
        case .partnerDetail(let partner):
            return URL(string: "mimisupply://partner?id=\(partner.id)")
        case .productDetail(let product):
            return URL(string: "mimisupply://product?id=\(product.id)")
        case .explore:
            return URL(string: "mimisupply://explore")
        case .authentication:
            return URL(string: "mimisupply://auth?action=signin")
        default:
            return nil
        }
    }
    
    // MARK: - Navigation Analytics
    
    func trackNavigation(from: AppRoute, to: AppRoute) {
        // In a real app, this would send analytics events
        print("Navigation: \(from) -> \(to)")
    }
    
    func trackDeepLink(_ url: URL, success: Bool) {
        // In a real app, this would send analytics events
        print("Deep link: \(url.absoluteString), success: \(success)")
    }
}

// MARK: - Navigation State Model

private struct NavigationState: Codable {
    let currentRoute: AppRoute
    let selectedTab: TabRoute
    let navigationPathCount: Int
    let timestamp: Date
    
    init(currentRoute: AppRoute, selectedTab: TabRoute, navigationPathCount: Int) {
        self.currentRoute = currentRoute
        self.selectedTab = selectedTab
        self.navigationPathCount = navigationPathCount
        self.timestamp = Date()
    }
}

// MARK: - Navigation Extensions

extension AppRouter {
    
    func handleUniversalLink(_ url: URL) {
        let navigationManager = NavigationManager()
        let success = navigationManager.handleUniversalLink(url, router: self)
        navigationManager.trackDeepLink(url, success: success)
    }
    
    func generateShareableLink(for route: AppRoute) -> URL? {
        let navigationManager = NavigationManager()
        return navigationManager.generateUniversalLink(for: route)
    }
}

// MARK: - View Extensions

extension View {
    func handleUniversalLinks(router: AppRouter) -> some View {
        self.onOpenURL { url in
            router.handleUniversalLink(url)
        }
    }
    
    func persistNavigationState(router: AppRouter) -> some View {
        self.onChange(of: router.currentRoute) { _, _ in
            let navigationManager = NavigationManager()
            navigationManager.saveNavigationState(router)
        }
        .onChange(of: router.selectedTab) { _, _ in
            let navigationManager = NavigationManager()
            navigationManager.saveNavigationState(router)
        }
    }
}