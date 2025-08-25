// MARK: - State Container Protocol

protocol StateContainerProtocol {
    associatedtype State
    var state: State { get }
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

// MARK: - Supporting Types (simplified for compilation)

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
    let primaryButton: String
    let secondaryButton: String?
    
    init(title: String, message: String, primaryButton: String = "OK", secondaryButton: String? = nil) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}

    // ... existing code ...