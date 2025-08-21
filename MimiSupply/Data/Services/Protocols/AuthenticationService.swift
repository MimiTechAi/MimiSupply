//
//  AuthenticationService.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import Combine
import AuthenticationServices

// Types like `UserProfile`, `UserRole`, `DriverProfile`, and `PartnerProfile` are defined in
// `MimiSupply/Data/Models/UserProfile.swift`. This file should not redeclare them.

/// Authentication state
enum AuthenticationState: Sendable, Equatable {
    case unauthenticated
    case authenticating
    case authenticated(UserProfile)
    case roleSelectionRequired(UserProfile)
    case error(Error)
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var user: UserProfile? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
    
    // Implement Equatable
    static func == (lhs: AuthenticationState, rhs: AuthenticationState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser == rhsUser
        case (.roleSelectionRequired(let lhsUser), .roleSelectionRequired(let rhsUser)):
            return lhsUser == rhsUser
        case (.error, .error):
            return true // Can't easily compare errors
        default:
            return false
        }
    }
}

/// Authentication result
struct AuthenticationResult: Sendable {
    let user: UserProfile
    let isNewUser: Bool
    let requiresRoleSelection: Bool
}

/// Authentication action
enum AuthenticationAction: Sendable {
    case viewCustomerContent
    case placeOrder
    case acceptDeliveryJobs
    case manageDriverProfile
    case manageBusinessProfile
    case viewBusinessAnalytics
    case adminAccess
    
    var requiredRole: UserRole? {
        switch self {
        case .viewCustomerContent:
            return nil
        case .placeOrder:
            return .customer
        case .acceptDeliveryJobs, .manageDriverProfile:
            return .driver
        case .manageBusinessProfile, .viewBusinessAnalytics:
            return .partner
        case .adminAccess:
            return .admin
        }
    }
}

/// Authentication service error
enum AuthServiceError: LocalizedError, Sendable, Equatable {
    case signInCancelled
    case signInFailed(String)
    case invalidCredentials
    case accountDisabled
    case networkError
    case keychainError(String)
    case roleSelectionRequired
    case permissionDenied
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .signInCancelled:
            return "Sign in was cancelled"
        case .signInFailed(let reason):
            return "Sign in failed: \(reason)"
        case .invalidCredentials:
            return "Invalid credentials"
        case .accountDisabled:
            return "Account has been disabled"
        case .networkError:
            return "Network connection required"
        case .keychainError(let details):
            return "Keychain error: \(details)"
        case .roleSelectionRequired:
            return "Role selection required"
        case .permissionDenied:
            return "Permission denied"
        case .unknown(let error):
            return "Authentication error: \(error.localizedDescription)"
        }
    }
    
    // Implement Equatable
    static func == (lhs: AuthServiceError, rhs: AuthServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.signInCancelled, .signInCancelled):
            return true
        case (.signInFailed(let lhsMessage), .signInFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.invalidCredentials, .invalidCredentials):
            return true
        case (.accountDisabled, .accountDisabled):
            return true
        case (.networkError, .networkError):
            return true
        case (.keychainError(let lhsMessage), .keychainError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.roleSelectionRequired, .roleSelectionRequired):
            return true
        case (.permissionDenied, .permissionDenied):
            return true
        case (.unknown, .unknown):
            return true // Can't easily compare errors
        default:
            return false
        }
    }
}

/// Authentication service protocol for managing user authentication
protocol AuthenticationService: Sendable {
    var isAuthenticated: Bool { get async }
    var currentUser: UserProfile? { get async }
    var authenticationState: AuthenticationState { get async }
    
    /// Publisher for authentication state changes
    var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> { get }
    
    func signInWithApple() async throws -> AuthenticationResult
    func signOut() async throws
    func refreshCredentials() async throws -> Bool
    func updateUserRole(_ role: UserRole) async throws -> UserProfile
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile
    func deleteAccount() async throws
    func getCurrentUserId() async throws -> String?
    
    /// Check if user has permission for specific role-based actions
    func hasPermission(for action: AuthenticationAction) async -> Bool
    
    /// Automatic authentication state management
    func startAutomaticStateManagement() async
    func stopAutomaticStateManagement() async
}

// Import required types
// AuthenticationState is defined in MissingTypes.swift

// AuthenticationResult is defined in MissingTypes.swift

// AuthenticationAction is defined in MissingTypes.swift

// AuthServiceError is defined in AppError.swift
