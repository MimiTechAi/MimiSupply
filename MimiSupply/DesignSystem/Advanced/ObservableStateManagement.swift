//
//  ObservableStateManagement.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Observation

// MARK: - Modern Observable State (iOS 17+)

@available(iOS 17.0, *)
@Observable
@MainActor
final class AdvancedAppState: AppStateProtocol {
    
    // MARK: - App-Level State
    var isLoading: Bool = false
    var networkStatus: NetworkStatus = .connected
    var appTheme: AppTheme = .default
    var presentedSheets: Set<SheetType> = []
    var navigationPath: [NavigationDestination] = []
    var currentAlert: AlertInfo?
    
    // MARK: - User State
    var currentUser: UserProfile?
    var isAuthenticated: Bool { currentUser != nil }
    
    // MARK: - Cart State
    var cartItems: [CartItem] = []
    var cartTotal: Double { 
        let total = cartItems.reduce(0.0, { currentTotal, item in 
            let itemPrice = Double(item.product.priceCents) / 100.0
            let itemQuantity = Double(item.quantity)
            return currentTotal + (itemPrice * itemQuantity)
        })
        return total
    }
    var cartItemCount: Int { cartItems.reduce(0, { $0 + $1.quantity }) }
    
    // MARK: - Methods
    func updateTheme(_ theme: AppTheme) {
        withAnimation(.smooth) {
            appTheme = theme
        }
    }
    
    func showAlert(_ alert: AlertInfo) {
        currentAlert = alert
    }
    
    func dismissAlert() {
        currentAlert = nil
    }
    
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func presentSheet(_ sheet: SheetType) {
        presentedSheets.insert(sheet)
    }
    
    func dismissSheet(_ sheet: SheetType) {
        presentedSheets.remove(sheet)
    }
}

// MARK: - Legacy Support (iOS 16 and earlier)

@MainActor
final class LegacyAppState: ObservableObject, AppStateProtocol {
    
    // MARK: - App-Level State
    @Published var isLoading: Bool = false
    @Published var networkStatus: NetworkStatus = .connected
    @Published var appTheme: AppTheme = .default
    @Published var presentedSheets: Set<SheetType> = []
    @Published var navigationPath: [NavigationDestination] = []
    @Published var currentAlert: AlertInfo?
    
    // MARK: - User State
    @Published var currentUser: UserProfile?
    var isAuthenticated: Bool { currentUser != nil }
    
    // MARK: - Cart State
    @Published var cartItems: [CartItem] = []
    var cartTotal: Double { 
        let total = cartItems.reduce(0.0, { currentTotal, item in 
            let itemPrice = Double(item.product.priceCents) / 100.0
            let itemQuantity = Double(item.quantity)
            return currentTotal + (itemPrice * itemQuantity)
        })
        return total
    }
    var cartItemCount: Int { cartItems.reduce(0, { $0 + $1.quantity }) }
    
    // MARK: - Initialization
    init() {
        // Initialize with defaults
    }
    
    // MARK: - Methods
    func updateTheme(_ theme: AppTheme) {
        withAnimation(.smooth) {
            appTheme = theme
        }
    }
    
    func showAlert(_ alert: AlertInfo) {
        currentAlert = alert
    }
    
    func dismissAlert() {
        currentAlert = nil
    }
    
    func navigate(to destination: NavigationDestination) {
        navigationPath.append(destination)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func presentSheet(_ sheet: SheetType) {
        presentedSheets.insert(sheet)
    }
    
    func dismissSheet(_ sheet: SheetType) {
        presentedSheets.remove(sheet)
    }
}

// MARK: - State Views for Legacy Support

@available(iOS 16.0, *)
struct AppStateView<Content: View>: View {
    typealias State = LegacyAppState
    
    @StateObject private var state = State()
    let content: (State) -> Content
    
    var body: some View {
        content(state)
            .environmentObject(state)
    }
}

// MARK: - Modern State Provider

@available(iOS 17.0, *)
struct ModernAppStateView<Content: View>: View {
    let state = AdvancedAppState()
    let content: (AdvancedAppState) -> Content
    
    var body: some View {
        content(state)
            .environment(state)
    }
}

// MARK: - State Management Utilities

@MainActor
struct StateManager {
    static func createLegacyState() -> LegacyAppState {
        return LegacyAppState()
    }
    
    @available(iOS 17.0, *)
    static func createModernState() -> AdvancedAppState {
        return AdvancedAppState()
    }
}

// MARK: - Advanced State Modifiers

@available(iOS 17.0, *)
struct StateObservingModifier<State: AppStateProtocol>: ViewModifier {
    let state: State
    
    func body(content: Content) -> some View {
        content
            .animation(.smooth, value: state.appTheme)
            .animation(.easeInOut, value: state.isLoading)
    }
}

// MARK: - View Extensions

extension View {
    @available(iOS 17.0, *)
    func observeAppState<State: AppStateProtocol>(_ state: State) -> some View {
        self.modifier(StateObservingModifier(state: state))
    }
}

// MARK: - Performance Optimized State

@available(iOS 17.0, *)
@Observable
final class PerformanceOptimizedState {
    private var _computedValues: [String: Any] = [:]
    private var _lastComputationTimes: [String: Date] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    func computedValue<T>(
        key: String,
        computation: () -> T
    ) -> T {
        let now = Date()
        
        // Check if we have a cached value that's still valid
        if let lastTime = _lastComputationTimes[key],
           now.timeIntervalSince(lastTime) < cacheTimeout,
           let cachedValue = _computedValues[key] as? T {
            return cachedValue
        }
        
        // Compute new value
        let newValue = computation()
        _computedValues[key] = newValue
        _lastComputationTimes[key] = now
        
        return newValue
    }
    
    func invalidateCache(key: String) {
        _computedValues.removeValue(forKey: key)
        _lastComputationTimes.removeValue(forKey: key)
    }
    
    func clearCache() {
        _computedValues.removeAll()
        _lastComputationTimes.removeAll()
    }
}

// MARK: - Preview

@available(iOS 17.0, *)
struct ObservableStateManagement_Previews: PreviewProvider {
    static var previews: some View {
        @State var appState = AdvancedAppState()
        
        VStack {
            Text("App Theme: \(appState.appTheme.displayName)")
            
            Button("Toggle Theme") {
                let newTheme: AppTheme = (appState.appTheme == .default) ? .vibrant : .default
                appState.updateTheme(newTheme)
            }
            
            if appState.isLoading {
                ProgressView("Loading...")
            }
            
            Button("Show Alert") {
                appState.showAlert(AlertInfo(
                    title: "Test Alert",
                    message: "This is a test alert",
                    type: .info,
                    actions: []
                ))
            }
        }
        .observeAppState(appState)
    }
}