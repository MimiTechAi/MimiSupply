//
//  MissingTypes.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation
import SwiftUI

// MARK: - Authentication Types
// Authentication types are now defined in AuthenticationService.swift

// MARK: - Service Protocol Stubs
// Note: Main service protocols are defined in their respective files
// KeychainServiceImpl is defined in KeychainServiceImpl.swift

// MARK: - Extended UserProfile for Authentication
// UserProfile properties are now defined directly in the UserProfile struct

// MARK: - State Management Types

/// Network connectivity status
enum NetworkStatus: Equatable, Hashable {
    case connected
    case disconnected
    case limited
    case connecting
    
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .limited: return "Limited"
        case .connecting: return "Connecting"
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected: return true
        case .disconnected, .limited, .connecting: return false
        }
    }
}

/// Sheet presentation types
enum SheetType: String, Hashable, CaseIterable {
    case profile = "profile"
    case settings = "settings"
    case search = "search"
    case filters = "filters"
    case notifications = "notifications"
    case cart = "cart"
    case orderHistory = "orderHistory"
    case productDetail = "productDetail"
    case partnerDetail = "partnerDetail"
    case checkout = "checkout"
    
    var displayName: String {
        switch self {
        case .profile: return "Profile"
        case .settings: return "Settings"
        case .search: return "Search"
        case .filters: return "Filters"
        case .notifications: return "Notifications"
        case .cart: return "Cart"
        case .orderHistory: return "Order History"
        case .productDetail: return "Product Detail"
        case .partnerDetail: return "Partner Detail"
        case .checkout: return "Checkout"
        }
    }
}

/// Navigation destinations for programmatic navigation
enum NavigationDestination: Hashable {
    case profile
    case settings
    case orders
    case analytics
    case productDetail(String)
    case orderDetail(String)
    case partnerDetail(String)
    case userProfile(String)
    case cartView
    case checkout
    case orderHistory
    case searchResults(String)
    
    var identifier: String {
        switch self {
        case .profile: return "profile"
        case .settings: return "settings"
        case .orders: return "orders"
        case .analytics: return "analytics"
        case .productDetail(let id): return "product-\(id)"
        case .orderDetail(let id): return "order-\(id)"
        case .partnerDetail(let id): return "partner-\(id)"
        case .userProfile(let id): return "user-\(id)"
        case .cartView: return "cart"
        case .checkout: return "checkout"
        case .orderHistory: return "orderHistory"
        case .searchResults(let query): return "search-\(query)"
        }
    }
}

/// Alert information with type and actions
struct AlertInfo: Identifiable, Equatable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let type: AlertType
    let actions: [AlertAction]
    
    init(
        title: String,
        message: String,
        type: AlertType = .info,
        actions: [AlertAction] = []
    ) {
        self.title = title
        self.message = message
        self.type = type
        self.actions = actions.isEmpty ? [.ok] : actions
    }
    
    // Equatable conformance
    static func == (lhs: AlertInfo, rhs: AlertInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Alert types for styling and behavior
enum AlertType: String, CaseIterable, Hashable {
    case info = "info"
    case success = "success"
    case warning = "warning"
    case error = "error"
    case confirmation = "confirmation"
    
    var systemImage: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .confirmation: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .confirmation: return .purple
        }
    }
}

/// Alert action buttons
enum AlertAction: String, CaseIterable, Hashable {
    case ok = "OK"
    case cancel = "Cancel"
    case yes = "Yes"
    case no = "No"
    case retry = "Retry"
    case dismiss = "Dismiss"
    case delete = "Delete"
    case save = "Save"
    case continueAction = "Continue"
    
    var isDestructive: Bool {
        return self == .delete
    }
    
    var isPrimary: Bool {
        switch self {
        case .ok, .yes, .save, .continueAction, .retry: return true
        case .cancel, .no, .dismiss, .delete: return false
        }
    }
}

/// Protocol for app state objects
@MainActor
protocol AppStateProtocol: AnyObject, ObservableObject {
    var isLoading: Bool { get set }
    var networkStatus: NetworkStatus { get set }
    var currentAlert: AlertInfo? { get set }
    var appTheme: AppTheme { get set }
    
    func showAlert(_ alert: AlertInfo)
    func dismissAlert()
}

// MARK: - Gesture Recognition Types

/// Recognized shape types for drawing gestures
enum RecognizedShape: String, CaseIterable, Hashable {
    case circle = "circle"
    case rectangle = "rectangle"
    case triangle = "triangle"
    case line = "line"
    case star = "star"
    case heart = "heart"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .rectangle: return "Rectangle"
        case .triangle: return "Triangle"
        case .line: return "Line"
        case .star: return "Star"
        case .heart: return "Heart"
        case .unknown: return "Unknown Shape"
        }
    }
    
    var systemImage: String {
        switch self {
        case .circle: return "circle"
        case .rectangle: return "rectangle"
        case .triangle: return "triangle"
        case .line: return "line.diagonal"
        case .star: return "star"
        case .heart: return "heart"
        case .unknown: return "questionmark"
        }
    }
}

// MARK: - Product Related Types

/// Nutrition information for products
struct NutritionInfo: Codable, Sendable, Hashable, Equatable {
    let calories: Int?
    let protein: Double? // grams
    let carbohydrates: Double? // grams
    let fat: Double? // grams
    let fiber: Double? // grams
    let sugar: Double? // grams
    let sodium: Double? // milligrams
    let servingSize: String?
    
    init(
        calories: Int? = nil,
        protein: Double? = nil,
        carbohydrates: Double? = nil,
        fat: Double? = nil,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        servingSize: String? = nil
    ) {
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
    }
}

// MARK: - Analytics Types

/// Physical dimensions of products
struct ProductDimensions: Codable, Sendable, Hashable, Equatable {
    let length: Double // centimeters
    let width: Double // centimeters
    let height: Double // centimeters
    let weight: Double // grams
    
    init(length: Double, width: Double, height: Double, weight: Double) {
        self.length = length
        self.width = width
        self.height = height
        self.weight = weight
    }
    
    var volume: Double {
        return length * width * height
    }
}

// MARK: - Payment Status is now defined in Order.swift

/// Food allergen types
enum Allergen: String, Codable, Sendable, CaseIterable, Hashable {
    case milk = "milk"
    case eggs = "eggs"
    case fish = "fish"
    case shellfish = "shellfish"
    case treeNuts = "tree_nuts"
    case peanuts = "peanuts"
    case wheat = "wheat"
    case soybeans = "soybeans"
    case sesame = "sesame"
    
    var displayName: String {
        switch self {
        case .milk: return "Milk"
        case .eggs: return "Eggs"
        case .fish: return "Fish"
        case .shellfish: return "Shellfish"
        case .treeNuts: return "Tree Nuts"
        case .peanuts: return "Peanuts"
        case .wheat: return "Wheat"
        case .soybeans: return "Soybeans"
        case .sesame: return "Sesame"
        }
    }
}

// MARK: - Removed duplicate model definitions
// DriverLocation and PartnerStats are defined canonically in:
// - Data/Models/Driver.swift (DriverLocation: Codable, Sendable)
// - Data/Models/PartnerStats.swift (PartnerStats: Codable, Sendable)
// Avoid redefining models here to prevent type conflicts.