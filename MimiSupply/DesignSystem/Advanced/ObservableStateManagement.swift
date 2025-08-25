//
//  ObservableStateManagement.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Observation

// MARK: - Advanced Observable State Management

/// Enhanced state management using the new @Observable macro (iOS 17+)
@available(iOS 17.0, *)
@Observable
final class AdvancedAppState {
    // MARK: - App-wide State
    var isLoading: Bool = false
    var currentUser: User?
    var networkStatus: NetworkStatus = .connected
    var appTheme: AppTheme = .system
    
    // MARK: - UI State
    var selectedTab: Int = 0
    var isShowingSidebar: Bool = false
    var searchText: String = ""
    var selectedFilters: Set<String> = []
    
    // MARK: - Navigation State
    var navigationPath: [NavigationDestination] = []
    var presentedSheets: Set<SheetType> = []
    var alerts: [AlertInfo] = []
    
    // MARK: - Performance State
    var cachedData: [String: Any] = [:]
    var backgroundTasksCount: Int = 0
    
    // MARK: - Methods
    func updateTheme(_ theme: AppTheme) {
        withAnimation(.smooth) {
            appTheme = theme
        }
    }
    
    func showAlert(_ alert: AlertInfo) {
        alerts.append(alert)
    }
    
    func dismissAlert(id: UUID) {
        alerts.removeAll { $0.id == id }
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

// MARK: - Legacy ObservableObject for iOS 16 support

final class LegacyAppState: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var currentUser: User?
    @Published var networkStatus: NetworkStatus = .connected
    @Published var appTheme: AppTheme = .system
    @Published var selectedTab: Int = 0
    @Published var isShowingSidebar: Bool = false
    @Published var searchText: String = ""
    @Published var selectedFilters: Set<String> = []
    @Published var navigationPath: [NavigationDestination] = []
    @Published var presentedSheets: Set<SheetType> = []
    @Published var alerts: [AlertInfo] = []
    @Published var cachedData: [String: Any] = [:]
    @Published var backgroundTasksCount: Int = 0
    
    func updateTheme(_ theme: AppTheme) {
        withAnimation(.smooth) {
            appTheme = theme
        }
    }
    
    func showAlert(_ alert: AlertInfo) {
        alerts.append(alert)
    }
    
    func dismissAlert(id: UUID) {
        alerts.removeAll { $0.id == id }
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

// MARK: - Supporting Types

enum NetworkStatus {
    case connected
    case disconnected
    case limited
}

enum NavigationDestination: Hashable {
    case profile
    case settings
    case orders
    case analytics
    case productDetail(String)
    case orderDetail(String)
}

enum SheetType: Hashable {
    case profile
    case settings
    case search
    case filters
    case notifications
}

struct AlertInfo: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let type: AlertType
    let actions: [AlertAction]
    
    enum AlertType {
        case info
        case warning
        case error
        case success
    }
    
    struct AlertAction: Equatable {
        let title: String
        let style: ActionStyle
        let action: () -> Void
        
        enum ActionStyle {
            case `default`
            case cancel
            case destructive
        }
        
        static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
            lhs.title == rhs.title && lhs.style == rhs.style
        }
    }
}

// MARK: - State Management Helpers

/// Factory for creating appropriate state manager based on iOS version
struct StateManagerFactory {
    static func createAppState() -> any AppStateProtocol {
        if #available(iOS 17.0, *) {
            return AdvancedAppState()
        } else {
            return LegacyAppState()
        }
    }
}

protocol AppStateProtocol {
    var isLoading: Bool { get set }
    var currentUser: User? { get set }
    var networkStatus: NetworkStatus { get set }
    var appTheme: AppTheme { get set }
    var selectedTab: Int { get set }
    var searchText: String { get set }
    var navigationPath: [NavigationDestination] { get set }
    var alerts: [AlertInfo] { get set }
    
    func updateTheme(_ theme: AppTheme)
    func showAlert(_ alert: AlertInfo)
    func dismissAlert(id: UUID)
    func navigate(to destination: NavigationDestination)
    func navigateBack()
}

// MARK: - Advanced State Modifiers

struct StateObservingModifier<State: AppStateProtocol>: ViewModifier {
    @Bindable var state: State
    
    func body(content: Content) -> some View {
        content
            .animation(.smooth, value: state.appTheme)
            .animation(.easeInOut, value: state.isLoading)
    }
}

// MARK: - View Extensions

extension View {
    func observeAppState<State: AppStateProtocol>(_ state: State) -> some View {
        self.modifier(StateObservingModifier(state: state))
    }
}

// MARK: - Advanced State Binding

@propertyWrapper
struct DynamicBinding<Value> {
    private let getValue: () -> Value
    private let setValue: (Value) -> Void
    
    init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getValue = get
        self.setValue = set
    }
    
    var wrappedValue: Value {
        get { getValue() }
        nonmutating set { setValue(newValue) }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
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
                appState.updateTheme(appState.appTheme == .light ? .dark : .light)
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