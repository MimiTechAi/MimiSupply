//
//  AuthenticationServiceImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

@preconcurrency import Foundation
import AuthenticationServices
@preconcurrency import Combine
import CloudKit
import OSLog
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
    
    
    private var keychainService: SecureKeychainService!
    private let cloudKitService: CloudKitService
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Authentication")
    
    private let currentUserKey = "current_user"
    private let credentialsKey = "apple_credentials"
    private let authStateKey = "auth_state"
    
    // State management
    private let authStateSubject = CurrentValueSubject<AuthenticationState, Never>(.unauthenticated)
    private var _currentUser: UserProfile?
    private var stateManagementTask: Task<Void, Never>? = nil
    private var credentialRefreshTimer: Timer?
    private var authControllerDelegate: AuthenticationDelegate?
    private var presentationContextProvider: PresentationContextProvider?
    
    private override init() {
        self.cloudKitService = CloudKitServiceImpl.shared
        super.init()
        
        Task { @MainActor in
            self.keychainService = SecureKeychainService.shared
            await self.initializeAuthenticationState()
        }
    }
    
    convenience init(keychainService: SecureKeychainService, cloudKitService: CloudKitService) {
        self.init()
    }
    
    deinit {
        stateManagementTask?.cancel()
        stateManagementTask = nil
        credentialRefreshTimer?.invalidate()
        credentialRefreshTimer = nil
    }
    
    // MARK: - Public Properties
    
    var isAuthenticated: Bool {
        get async {
            await authenticationState.isAuthenticated
        }
    }
    
    var currentUser: UserProfile? {
        get async {
            return _currentUser
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
    
    /// Sign in with Apple
    func signInWithApple() async throws -> AuthenticationResult {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let delegate = AuthenticationDelegate(completion: { result in
                    continuation.resume(with: result)
                })
                self.authControllerDelegate = delegate
                
                let authController = ASAuthorizationController(authorizationRequests: [request])
                authController.delegate = delegate
                authController.presentationContextProvider = self.presentationContextProvider
                authController.performRequests()
            }
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        _currentUser = nil
        await updateAuthenticationState(.unauthenticated)
        
        // Clear keychain data
        await MainActor.run {
            Task {
                try await keychainService.deleteItem(forKey: currentUserKey)
                try await keychainService.deleteItem(forKey: credentialsKey)
                try await keychainService.deleteItem(forKey: "last_auth_time")
            }
        }
        
        logger.info("User signed out successfully")
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
                await MainActor.run {
                    Task {
                        try await keychainService.store(Date(), forKey: "last_auth_time")
                    }
                }
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
    
    /// Update user role
    func updateUserRole(_ role: UserRole) async throws -> UserProfile {
        guard let currentUser = await currentUser else {
            throw AuthenticationError.notAuthenticated
        }
        
        // Create updated user profile with new role
        let updatedUser = UserProfile(
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
        
        _currentUser = updatedUser
        
        // Update CloudKit
        try await cloudKitService.saveUserProfile(updatedUser)
        
        // Update local cache
        await MainActor.run {
            Task {
                try await keychainService.store(Date(), forKey: "last_auth_time")
            }
        }
        
        logger.info("User role updated to: \(role.rawValue)")
        return updatedUser
    }
    
    /// Update user profile
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        guard await currentUser != nil else {
            throw AuthenticationError.notAuthenticated
        }
        
        _currentUser = profile
        
        // Update CloudKit and local cache
        try await cloudKitService.saveUserProfile(profile)
        await MainActor.run {
            Task {
                try await keychainService.store(profile, forKey: currentUserKey)
            }
        }
        
        logger.info("User profile updated")
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
        await loadAuthenticationState()
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
            _ = try? await refreshCredentials()
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
            case ASAuthorizationError.canceled:
                return .signInFailed("User canceled")
            case ASAuthorizationError.failed:
                return .signInFailed(error.localizedDescription)
            case ASAuthorizationError.invalidResponse:
                return .signInFailed("Invalid response from Apple")
            case ASAuthorizationError.notHandled:
                return .signInFailed("Sign in not handled")
            case ASAuthorizationError.unknown:
                return .signInFailed(error.localizedDescription)
            default:
                return .signInFailed(error.localizedDescription)
            }
        }
        
        return .signInFailed("Unexpected authorization type")
    }
    
    /// Load authentication state from storage
    private func loadAuthenticationState() async {
        await MainActor.run {
            Task {
                do {
                    if let storedUser: UserProfile = try await keychainService.retrieve(UserProfile.self, forKey: currentUserKey) {
                        _currentUser = storedUser
                        await updateAuthenticationState(.authenticated(storedUser))
                        logger.info("Loaded stored user: \(storedUser.id)")
                    } else {
                        await updateAuthenticationState(.unauthenticated)
                        logger.info("No stored user found")
                    }
                } catch {
                    await updateAuthenticationState(.unauthenticated)
                    logger.warning("Failed to load stored user: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Helper Classes

private class AuthenticationDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let completion: @Sendable (Result<AuthenticationResult, Error>) -> Void
    
    init(completion: @escaping @Sendable (Result<AuthenticationResult, Error>) -> Void) {
        self.completion = completion
        super.init()
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