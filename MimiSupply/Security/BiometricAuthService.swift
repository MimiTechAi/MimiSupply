//
//  BiometricAuthService.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import LocalAuthentication
import SwiftUI
import Combine
import os

// MARK: - Biometric Authentication Service

@MainActor
final class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    // MARK: - Published Properties
    @Published var isAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var isEnabled = false
    @Published var lastAuthenticationDate: Date?
    @Published var authenticationStatus: AuthenticationStatus = .notAuthenticated
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "MimiSupply", category: "BiometricAuth")
    private let keychain = KeychainService.shared
    private let context = LAContext()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupBiometricAuth()
        loadBiometricSettings()
    }
    
    // MARK: - Setup
    
    private func setupBiometricAuth() {
        evaluateBiometricAvailability()
        
        // Monitor biometric changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.evaluateBiometricAvailability()
            }
            .store(in: &cancellables)
    }
    
    private func evaluateBiometricAvailability() {
        var error: NSError?
        let isAvailable = context.canEvaluatePolicy(.biometryOwner, error: &error)
        
        self.isAvailable = isAvailable
        
        if isAvailable {
            switch context.biometryType {
            case .touchID:
                biometricType = .touchID
            case .faceID:
                biometricType = .faceID
            case .opticID:
                biometricType = .faceID // Treat Optic ID as Face ID variant
            case .none:
                biometricType = .none
            @unknown default:
                biometricType = .none
            }
        } else {
            biometricType = .none
            if let error = error {
                logger.error("❌ Biometric authentication not available: \(error.localizedDescription)")
            }
        }
        
        logger.info("🔐 Biometric availability: \(isAvailable), type: \(biometricType.rawValue)")
    }
    
    private func loadBiometricSettings() {
        if let biometricData = keychain.getBiometricData() {
            isEnabled = biometricData.isEnabled
            lastAuthenticationDate = biometricData.lastUsedAt
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Authenticate user with biometrics
    func authenticate(reason: String = "Authenticate to access your account") async -> BiometricAuthResult {
        guard isAvailable else {
            logger.warning("⚠️ Biometric authentication attempted but not available")
            return .failure(.biometricNotAvailable)
        }
        
        guard isEnabled else {
            logger.warning("⚠️ Biometric authentication attempted but not enabled")
            return .failure(.biometricNotEnabled)
        }
        
        authenticationStatus = .authenticating
        
        do {
            let success = try await context.evaluatePolicy(.biometryOwner, localizedReason: reason)
            
            if success {
                await handleSuccessfulAuthentication()
                return .success
            } else {
                authenticationStatus = .failed
                return .failure(.authenticationFailed)
            }
        } catch let error as LAError {
            authenticationStatus = .failed
            return .failure(mapLAError(error))
        } catch {
            authenticationStatus = .failed
            logger.error("❌ Unexpected biometric authentication error: \(error)")
            return .failure(.unknown(error))
        }
    }
    
    /// Authenticate for specific sensitive operation
    func authenticateForOperation(_ operation: SensitiveOperation) async -> BiometricAuthResult {
        let reason = operation.authenticationReason
        let result = await authenticate(reason: reason)
        
        if case .success = result {
            logger.info("✅ Biometric authentication successful for operation: \(operation.rawValue)")
            
            // Track usage for security monitoring
            await trackAuthenticationUsage(operation: operation)
        }
        
        return result
    }
    
    /// Enable biometric authentication
    func enableBiometricAuth(userID: String) async -> BiometricAuthResult {
        guard isAvailable else {
            return .failure(.biometricNotAvailable)
        }
        
        // First authenticate to enable
        let authResult = await authenticate(reason: "Enable biometric authentication for secure access")
        
        if case .success = authResult {
            let biometricData = BiometricAuthData(
                userID: userID,
                isEnabled: true,
                biometricType: biometricType,
                createdAt: Date(),
                lastUsedAt: Date()
            )
            
            do {
                try keychain.storeBiometricData(biometricData)
                isEnabled = true
                logger.info("✅ Biometric authentication enabled for user: \(userID)")
                
                // Store secure authentication token
                try await storeSecureAuthToken(userID: userID)
                
                return .success
            } catch {
                logger.error("❌ Failed to enable biometric authentication: \(error)")
                return .failure(.keychainError(error))
            }
        }
        
        return authResult
    }
    
    /// Disable biometric authentication
    func disableBiometricAuth() async -> Bool {
        do {
            try keychain.deleteBiometricData()
            try keychain.deleteItem(forKey: "biometric_auth_token")
            
            isEnabled = false
            lastAuthenticationDate = nil
            authenticationStatus = .notAuthenticated
            
            logger.info("✅ Biometric authentication disabled")
            return true
        } catch {
            logger.error("❌ Failed to disable biometric authentication: \(error)")
            return false
        }
    }
    
    // MARK: - Security Features
    
    /// Check if biometric enrollment has changed
    func checkBiometricIntegrity() async -> BiometricIntegrityResult {
        guard isAvailable else {
            return .notAvailable
        }
        
        // Check if biometry has changed since last use
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.biometryOwner, error: &error) else {
            if let laError = error as? LAError {
                switch laError.code {
                case .biometryNotEnrolled:
                    return .enrollmentRemoved
                case .biometryLockout:
                    return .lockedOut
                default:
                    return .unavailable
                }
            }
            return .unavailable
        }
        
        // Compare domain state to detect enrollment changes
        if let previousDomainState = getPreviousDomainState(),
           let currentDomainState = context.evaluatedPolicyDomainState {
            
            if previousDomainState != currentDomainState {
                logger.warning("⚠️ Biometric enrollment changed detected")
                
                // Disable biometric auth for security
                await disableForSecurityReason(.enrollmentChanged)
                return .enrollmentChanged
            }
        }
        
        // Store current domain state
        storeDomainState(context.evaluatedPolicyDomainState)
        
        return .valid
    }
    
    /// Force biometric re-authentication after security event
    func requireReauthentication(reason: SecurityReason) async {
        logger.warning("🔒 Biometric re-authentication required: \(reason.rawValue)")
        
        authenticationStatus = .reauthenticationRequired
        
        // Clear sensitive cached data
        await clearSensitiveCachedData()
        
        // Notify UI to show re-authentication prompt
        NotificationCenter.default.post(
            name: .biometricReauthenticationRequired,
            object: self,
            userInfo: ["reason": reason]
        )
    }
    
    /// Validate authentication freshness
    func isAuthenticationFresh(maxAge: TimeInterval = 300) -> Bool { // 5 minutes default
        guard let lastAuth = lastAuthenticationDate else { return false }
        return Date().timeIntervalSince(lastAuth) <= maxAge
    }
    
    // MARK: - Multi-Factor Authentication
    
    /// Combine biometric with PIN/Password for high-security operations
    func authenticateWithMultipleFactor(
        primaryReason: String,
        requireSecondaryAuth: Bool = true
    ) async -> BiometricAuthResult {
        
        // First factor: Biometric
        let biometricResult = await authenticate(reason: primaryReason)
        
        guard case .success = biometricResult else {
            return biometricResult
        }
        
        // Second factor: Device passcode (if required)
        if requireSecondaryAuth {
            let passcodeResult = await authenticateWithPasscode(
                reason: "Enter device passcode for additional security"
            )
            
            guard case .success = passcodeResult else {
                return passcodeResult
            }
        }
        
        logger.info("✅ Multi-factor authentication successful")
        return .success
    }
    
    private func authenticateWithPasscode(reason: String) async -> BiometricAuthResult {
        do {
            let context = LAContext()
            let success = try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
            
            return success ? .success : .failure(.authenticationFailed)
        } catch let error as LAError {
            return .failure(mapLAError(error))
        } catch {
            return .failure(.unknown(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func handleSuccessfulAuthentication() async {
        authenticationStatus = .authenticated
        lastAuthenticationDate = Date()
        
        // Update last used date in keychain
        if var biometricData = keychain.getBiometricData() {
            biometricData = BiometricAuthData(
                userID: biometricData.userID,
                isEnabled: biometricData.isEnabled,
                biometricType: biometricData.biometricType,
                createdAt: biometricData.createdAt,
                lastUsedAt: Date()
            )
            
            try? keychain.storeBiometricData(biometricData)
        }
        
        logger.info("✅ Biometric authentication successful")
    }
    
    private func storeSecureAuthToken(userID: String) async throws {
        // Generate secure token for biometric sessions
        let token = UUID().uuidString
        let tokenData = BiometricAuthToken(
            token: token,
            userID: userID,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400) // 24 hours
        )
        
        try keychain.store(tokenData, forKey: "biometric_auth_token", accessibility: .biometryCurrentSet)
    }
    
    private func trackAuthenticationUsage(operation: SensitiveOperation) async {
        let usage = BiometricUsageEvent(
            operation: operation,
            timestamp: Date(),
            biometricType: biometricType,
            success: true
        )
        
        // Store usage for security monitoring
        var usageHistory = getBiometricUsageHistory()
        usageHistory.append(usage)
        
        // Keep only last 100 events
        if usageHistory.count > 100 {
            usageHistory = Array(usageHistory.suffix(100))
        }
        
        try? keychain.store(usageHistory, forKey: "biometric_usage_history")
    }
    
    private func getBiometricUsageHistory() -> [BiometricUsageEvent] {
        return (try? keychain.retrieve([BiometricUsageEvent].self, forKey: "biometric_usage_history")) ?? []
    }
    
    private func disableForSecurityReason(_ reason: SecurityReason) async {
        logger.warning("🚨 Disabling biometric auth for security reason: \(reason.rawValue)")
        
        await disableBiometricAuth()
        
        // Notify about security event
        NotificationCenter.default.post(
            name: .biometricSecurityEvent,
            object: self,
            userInfo: ["reason": reason]
        )
    }
    
    private func clearSensitiveCachedData() async {
        // Clear any sensitive data that might be cached
        try? keychain.deleteItem(forKey: "cached_sensitive_data")
        
        // Notify other services to clear their caches
        NotificationCenter.default.post(name: .clearSensitiveCaches, object: self)
    }
    
    private func getPreviousDomainState() -> Data? {
        return try? keychain.retrieveData(forKey: "biometric_domain_state")
    }
    
    private func storeDomainState(_ domainState: Data?) {
        guard let domainState = domainState else { return }
        try? keychain.storeData(domainState, forKey: "biometric_domain_state")
    }
    
    private func mapLAError(_ error: LAError) -> BiometricAuthError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancelled
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancelled
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .biometricNotAvailable
        case .biometryNotEnrolled:
            return .biometricNotEnrolled
        case .biometryLockout:
            return .biometricLockout
        case .appCancel:
            return .appCancelled
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Data Models

struct BiometricAuthToken: Codable {
    let token: String
    let userID: String
    let createdAt: Date
    let expiresAt: Date
}

struct BiometricUsageEvent: Codable {
    let operation: SensitiveOperation
    let timestamp: Date
    let biometricType: BiometricType
    let success: Bool
}

// MARK: - Enums

enum AuthenticationStatus {
    case notAuthenticated
    case authenticating
    case authenticated
    case failed
    case reauthenticationRequired
}

enum BiometricAuthResult {
    case success
    case failure(BiometricAuthError)
}

enum BiometricAuthError: Error, LocalizedError {
    case biometricNotAvailable
    case biometricNotEnabled
    case biometricNotEnrolled
    case biometricLockout
    case authenticationFailed
    case userCancelled
    case userFallback
    case systemCancelled
    case passcodeNotSet
    case appCancelled
    case invalidContext
    case notInteractive
    case keychainError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled"
        case .biometricNotEnrolled:
            return "No biometric data is enrolled on this device"
        case .biometricLockout:
            return "Biometric authentication is locked out"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .userCancelled:
            return "Authentication was cancelled by user"
        case .userFallback:
            return "User chose to use fallback authentication"
        case .systemCancelled:
            return "Authentication was cancelled by system"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .appCancelled:
            return "Authentication was cancelled by app"
        case .invalidContext:
            return "Invalid authentication context"
        case .notInteractive:
            return "Authentication requires user interaction"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown authentication error: \(error.localizedDescription)"
        }
    }
}

enum BiometricIntegrityResult {
    case valid
    case notAvailable
    case unavailable
    case enrollmentChanged
    case enrollmentRemoved
    case lockedOut
}

enum SensitiveOperation: String, Codable {
    case login = "login"
    case payment = "payment"
    case dataExport = "data_export"
    case passwordChange = "password_change"
    case accountDeletion = "account_deletion"
    case sensitiveDataAccess = "sensitive_data_access"
    case adminAction = "admin_action"
    
    var authenticationReason: String {
        switch self {
        case .login:
            return "Authenticate to sign in to your account"
        case .payment:
            return "Authenticate to complete payment"
        case .dataExport:
            return "Authenticate to export your data"
        case .passwordChange:
            return "Authenticate to change your password"
        case .accountDeletion:
            return "Authenticate to delete your account"
        case .sensitiveDataAccess:
            return "Authenticate to access sensitive information"
        case .adminAction:
            return "Authenticate to perform administrative action"
        }
    }
}

enum SecurityReason: String {
    case enrollmentChanged = "enrollment_changed"
    case deviceCompromised = "device_compromised"
    case suspiciousActivity = "suspicious_activity"
    case multipleFailedAttempts = "multiple_failed_attempts"
    case timeBasedExpiry = "time_based_expiry"
}

// MARK: - Notifications

extension Notification.Name {
    static let biometricReauthenticationRequired = Notification.Name("biometricReauthenticationRequired")
    static let biometricSecurityEvent = Notification.Name("biometricSecurityEvent")
    static let clearSensitiveCaches = Notification.Name("clearSensitiveCaches")
}

// MARK: - SwiftUI Integration

struct BiometricAuthView: View {
    @StateObject private var biometricAuth = BiometricAuthService.shared
    @State private var isAuthenticating = false
    @State private var authResult: BiometricAuthResult?
    
    let operation: SensitiveOperation
    let onSuccess: () -> Void
    let onFailure: (BiometricAuthError) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: biometricIconName)
                .font(.system(size: 60))
                .foregroundColor(.emerald)
            
            Text("Biometric Authentication")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(operation.authenticationReason)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if isAuthenticating {
                ProgressView()
                    .scaleEffect(1.2)
            } else {
                Button("Authenticate") {
                    authenticate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .onAppear {
            if biometricAuth.isAvailable && biometricAuth.isEnabled {
                authenticate()
            }
        }
    }
    
    private var biometricIconName: String {
        switch biometricAuth.biometricType {
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .none:
            return "lock.shield"
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        
        Task {
            let result = await biometricAuth.authenticateForOperation(operation)
            
            await MainActor.run {
                isAuthenticating = false
                authResult = result
                
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    onFailure(error)
                }
            }
        }
    }
}

// MARK: - Preview

struct BiometricAuthService_Previews: PreviewProvider {
    static var previews: some View {
        BiometricAuthView(
            operation: .login,
            onSuccess: {
                print("Authentication successful")
            },
            onFailure: { error in
                print("Authentication failed: \(error)")
            }
        )
    }
}