//
//  AuthenticationServiceImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import AuthenticationServices
@preconcurrency import Combine
import CloudKit
#if canImport(UIKit)
import UIKit
#endif

// Import project-specific types
// These types are defined in their respective files within the MimiSupply target

/// Implementation of AuthenticationService using Sign in with Apple
final class AuthenticationServiceImpl: NSObject, @unchecked Sendable, AuthenticationService {
    
    // MARK: - Singleton
    static let shared = AuthenticationServiceImpl()
    
    func getCurrentUserId() async throws -> String? {
        return await currentUser?.id
    }
    
    
    private let keychainService: KeychainService
    private let cloudKitService: CloudKitService
    
    private let currentUserKey = "current_user"
    private let credentialsKey = "apple_credentials"
    private let authStateKey = "auth_state"
    
    // State management
    private let authStateSubject = CurrentValueSubject<AuthenticationState, Never>(.unauthenticated)
    private var stateManagementTask: Task<Void, Never>? = nil
    private var credentialRefreshTimer: Timer?
    private var authControllerDelegate: AuthenticationDelegate?
    private var presentationContextProvider: PresentationContextProvider?
    
    init(keychainService: KeychainService = KeychainServiceImpl(), 
         cloudKitService: CloudKitService = CloudKitServiceImpl()) {
        self.keychainService = keychainService
        self.cloudKitService = cloudKitService
        super.init()
        
        // Initialize authentication state
        Task {
            await initializeAuthenticationState()
        }
    }
    
    deinit {
        Task {
            await stopAutomaticStateManagement()
        }
    }
    
    // MARK: - Public Properties
    
    var isAuthenticated: Bool {
        get async {
            await authenticationState.isAuthenticated
        }
    }
    
    var currentUser: UserProfile? {
        get async {
            await authenticationState.user
        }
    }
    
    var authenticationState: AuthenticationState {
        get async {
            authStateSubject.value
        }
    }
    
    var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Authentication Methods
    
    func signInWithApple() async throws -> AuthenticationResult {
        await updateAuthenticationState(.authenticating)
        
        do {
            let result = try await performAppleSignIn()
            
            // Store credentials securely
            try keychainService.store(result.user, for: currentUserKey)
            try keychainService.store(Date(), for: "last_auth_time")
            
            // Check if user needs role selection
            if result.requiresRoleSelection {
                await updateAuthenticationState(.roleSelectionRequired(result.user))
            } else {
                // Sync with CloudKit
                try await syncUserProfileToCloudKit(result.user)
                await updateAuthenticationState(.authenticated(result.user))
            }
            
            return result
            
        } catch {
            let authError = mapToAuthenticationError(error)
            await updateAuthenticationState(.error(authError))
            throw authError
        }
    }
    
    func signOut() async throws {
        await updateAuthenticationState(.unauthenticated)
        
        // Clear all stored credentials
        try keychainService.delete(for: currentUserKey)
        try keychainService.delete(for: credentialsKey)
        try keychainService.delete(for: "last_auth_time")
        
        // Stop automatic state management
        await stopAutomaticStateManagement()
    }
    
    func refreshCredentials() async throws -> Bool {
        guard let currentUser = await currentUser else {
            throw AuthServiceError.invalidCredentials
        }
        
        do {
            // Check Apple ID credential state
            let provider = ASAuthorizationAppleIDProvider()
            let credentialState = try await provider.credentialState(forUserID: currentUser.id)
            
            switch credentialState {
            case .authorized:
                // Update last auth time
                try keychainService.store(Date(), for: "last_auth_time")
                return true
                
            case .revoked, .notFound:
                // Credentials are invalid, sign out
                try await signOut()
                throw AuthServiceError.invalidCredentials
                
            case .transferred:
                // Handle credential transfer (rare case)
                throw AuthServiceError.networkError
                
            @unknown default:
                throw AuthServiceError.networkError
            }
            
        } catch {
            throw AuthServiceError.networkError
        }
    }
    
    func updateUserRole(_ role: UserRole) async throws -> UserProfile {
        guard var currentUser = await currentUser else {
            throw AuthServiceError.invalidCredentials
        }
        
        // Update user role
        currentUser = UserProfile(
            id: currentUser.id,
            appleUserID: currentUser.appleUserID,
            email: currentUser.email,
            fullName: currentUser.fullName,
            role: role,
            phoneNumber: currentUser.phoneNumber,
            profileImageURL: currentUser.profileImageURL,
            isVerified: currentUser.isVerified,
            createdAt: currentUser.createdAt,
            lastActiveAt: Date(),
            driverProfile: currentUser.driverProfile,
            partnerProfile: currentUser.partnerProfile
        )
        
        // Store updated profile
        try keychainService.store(currentUser, for: currentUserKey)
        
        // Sync to CloudKit
        try await syncUserProfileToCloudKit(currentUser)
        
        // Update authentication state
        await updateAuthenticationState(.authenticated(currentUser))
        
        return currentUser
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        // Store updated profile
        try keychainService.store(profile, for: currentUserKey)
        
        // Sync to CloudKit
        try await syncUserProfileToCloudKit(profile)
        
        // Update authentication state
        await updateAuthenticationState(.authenticated(profile))
        
        return profile
    }
    
    func deleteAccount() async throws {
        guard let currentUser = await currentUser else {
            throw AuthServiceError.invalidCredentials
        }
        
        // Delete user data from CloudKit
        try await deleteUserDataFromCloudKit(currentUser.id)
        
        // Sign out and clear local data
        try await signOut()
    }
    
    // MARK: - Role-Based Access Control
    
    func hasPermission(for action: AuthenticationAction) async -> Bool {
        guard let currentUser = await currentUser else {
            return action.requiredRole == nil
        }
        
        guard let requiredRole = action.requiredRole else {
            return true // Action available to all users
        }
        
        return currentUser.role == requiredRole || currentUser.role == .admin
    }
    
    // MARK: - Automatic State Management
    
    func startAutomaticStateManagement() async {
        guard stateManagementTask == nil else { return }
        
        stateManagementTask = Task {
            // Start credential refresh timer
            await startCredentialRefreshTimer()
            
            // Monitor app lifecycle for state updates
            await monitorAppLifecycle()
        }
    }
    
    func stopAutomaticStateManagement() async {
        stateManagementTask?.cancel()
        stateManagementTask = nil
        
        credentialRefreshTimer?.invalidate()
        credentialRefreshTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func initializeAuthenticationState() async {
        do {
            if let storedUser: UserProfile = try keychainService.retrieve(UserProfile.self, for: currentUserKey) {
                // Verify credentials are still valid
                let isValid = try await refreshCredentials()
                if isValid {
                    await updateAuthenticationState(.authenticated(storedUser))
                } else {
                    await updateAuthenticationState(.unauthenticated)
                }
            } else {
                await updateAuthenticationState(.unauthenticated)
            }
        } catch {
            await updateAuthenticationState(.unauthenticated)
        }
    }
    
    private func performAppleSignIn() async throws -> AuthenticationResult {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.fullName, .email]
                
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AuthenticationDelegate { result in
                    continuation.resume(with: result)
                }
                let contextProvider = PresentationContextProvider()
                
                // Retain to ensure they live for the duration of the request
                self.authControllerDelegate = delegate
                self.presentationContextProvider = contextProvider
                
                controller.delegate = delegate
                controller.presentationContextProvider = contextProvider
                controller.performRequests()
            }
        }
    }
    
    private func syncUserProfileToCloudKit(_ profile: UserProfile) async throws {
        // Implementation would sync user profile to CloudKit private database
        // This is a placeholder for the actual CloudKit sync logic
    }
    
    private func deleteUserDataFromCloudKit(_ userId: String) async throws {
        // Implementation would delete all user data from CloudKit
        // This is a placeholder for the actual CloudKit deletion logic
    }
    
    private func updateAuthenticationState(_ newState: AuthenticationState) async {
        await MainActor.run {
            authStateSubject.send(newState)
        }
    }
    
    private func startCredentialRefreshTimer() async {
        await MainActor.run {
            credentialRefreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
                Task {
                    _ = try? await self?.refreshCredentials()
                }
            }
        }
    }
    
    private func monitorAppLifecycle() async {
        // Monitor app becoming active to refresh credentials
        #if canImport(UIKit)
        for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
            try? await refreshCredentials()
        }
        #endif
    }
    
    private func monitorAppLifecycleCompat() async {
        // Fallback for platforms without UIKit
        #if !canImport(UIKit)
        // Use a simple timer-based approach for macOS
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: 60_000_000_000) // Check every minute
                try? await refreshCredentials()
            } catch {
                break
            }
        }
        #endif
    }
    
    private func mapToAuthenticationError(_ error: Error) -> AuthServiceError {
        if let authError = error as? AuthServiceError {
            return authError
        }
        
        if let asError = error as? ASAuthorizationError {
            switch asError.code {
            case .canceled:
                return .signInCancelled
            case .failed:
                return .signInFailed("Unknown error")
            case .invalidResponse:
                return .invalidCredentials
            case .notHandled:
                return .accountDisabled
            case .unknown:
                return .signInFailed("Apple ID credential error")
            case .notInteractive:
                return .signInFailed("Identity token missing")
            case .matchedExcludedCredential:
                return .invalidCredentials
            case .credentialImport:
                return .signInFailed("Identity token data missing")
            case .credentialExport:
                return .signInFailed("Authorization code missing")
            @unknown default:
                return .signInFailed("Password credential error")
            }
        }
        
        return .signInFailed("Unexpected authorization type")
    }
}

// MARK: - Helper Classes

private class AuthenticationDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: (Result<AuthenticationResult, Error>) -> Void
    
    init(completion: @escaping (Result<AuthenticationResult, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completion(.failure(AuthServiceError.signInFailed("Authorization failed")))
            return
        }
        
        let isNewUser = appleIDCredential.email != nil
        let requiresRoleSelection = isNewUser // New users need to select role
        
        let userProfile = UserProfile(
            id: appleIDCredential.user,
            appleUserID: appleIDCredential.user,
            email: appleIDCredential.email ?? "",
            fullName: appleIDCredential.fullName ?? PersonNameComponents(),
            role: .customer, // Default role, will be updated during role selection
            phoneNumber: nil,
            profileImageURL: nil,
            isVerified: false,
            createdAt: Date(),
            lastActiveAt: Date(),
            driverProfile: nil,
            partnerProfile: nil
        )
        
        let result = AuthenticationResult(
            user: userProfile, 
            isNewUser: isNewUser,
            requiresRoleSelection: requiresRoleSelection
        )
        completion(.success(result))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
}

private class PresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Notification Extensions

extension NotificationCenter {
    func notifications(named name: Notification.Name) -> AsyncStream<Notification> {
        AsyncStream { continuation in
            let observer = addObserver(forName: name, object: nil, queue: nil) { notification in
                continuation.yield(notification)
            }
            
            continuation.onTermination = { [self] _ in
                self.removeObserver(observer)
            }
        }
    }
}
