//
//  AuthenticationManager.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import Combine
import SwiftUI

/// Manages authentication flow and state for the entire app
@MainActor
final class AuthenticationManager: ObservableObject {
    
    @Published var authenticationState: AuthenticationState = .unauthenticated
    @Published var isShowingRoleSelection = false
    @Published var isShowingAuthenticationError = false
    @Published var currentError: AuthenticationError?
    
    private let authenticationService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(authenticationService: AuthenticationService = AuthenticationServiceImpl()) {
        self.authenticationService = authenticationService
        setupStateObservation()
        
        Task {
            await authenticationService.startAutomaticStateManagement()
            authenticationState = await authenticationService.authenticationState
        }
    }
    
    deinit {
        Task {
            await authenticationService.stopAutomaticStateManagement()
        }
    }
    
    // MARK: - Public Methods
    
    func signInWithApple() async {
        do {
            let result = try await authenticationService.signInWithApple()
            
            if result.requiresRoleSelection {
                isShowingRoleSelection = true
            }
            
        } catch {
            handleAuthenticationError(error)
        }
    }
    
    func signOut() async {
        do {
            try await authenticationService.signOut()
        } catch {
            handleAuthenticationError(error)
        }
    }
    
    func selectRole(_ role: UserRole) async {
        do {
            _ = try await authenticationService.updateUserRole(role)
            isShowingRoleSelection = false
        } catch {
            handleAuthenticationError(error)
        }
    }
    
    func updateUserProfile(_ profile: UserProfile) async {
        do {
            _ = try await authenticationService.updateUserProfile(profile)
        } catch {
            handleAuthenticationError(error)
        }
    }
    
    func deleteAccount() async {
        do {
            try await authenticationService.deleteAccount()
        } catch {
            handleAuthenticationError(error)
        }
    }
    
    func hasPermission(for action: AuthenticationAction) async -> Bool {
        await authenticationService.hasPermission(for: action)
    }
    
    func dismissError() {
        isShowingAuthenticationError = false
        currentError = nil
    }
    
    // MARK: - Private Methods
    
    private func setupStateObservation() {
        authenticationService.authenticationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authenticationState = state
                
                // Handle role selection requirement
                if case .roleSelectionRequired = state {
                    self?.isShowingRoleSelection = true
                }
                
                // Handle errors
                if case .error(let error) = state {
                    self?.handleAuthenticationError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthenticationError(_ error: Error) {
        if let authError = error as? AuthenticationError {
            currentError = authError
        } else {
            currentError = .signInFailed(error.localizedDescription)
        }
        isShowingAuthenticationError = true
    }
}

// MARK: - Authentication Gate View

/// A view that presents authentication when required
struct AuthenticationGate<Content: View>: View {
    @StateObject private var authManager = AuthenticationManager()
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Group {
            switch authManager.authenticationState {
            case .unauthenticated, .authenticating:
                SignInView()
                    .environmentObject(authManager)
                
            case .authenticated:
                content()
                    .environmentObject(authManager)
                
            case .roleSelectionRequired(let user):
                RoleSelectionView(user: user) { role in
                    Task {
                        await authManager.selectRole(role)
                    }
                }
                
            case .error:
                SignInView()
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $authManager.isShowingRoleSelection) {
            if case .roleSelectionRequired(let user) = authManager.authenticationState {
                RoleSelectionView(user: user) { role in
                    Task {
                        await authManager.selectRole(role)
                    }
                }
            }
        }
        .alert("Authentication Error", isPresented: $authManager.isShowingAuthenticationError) {
            Button("OK") {
                authManager.dismissError()
            }
            
            if let error = authManager.currentError,
               let recoverySuggestion = error.recoverySuggestion {
                Button("Retry") {
                    authManager.dismissError()
                    Task {
                        await authManager.signInWithApple()
                    }
                }
            }
        } message: {
            if let error = authManager.currentError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error.localizedDescription)
                    
                    if let recoverySuggestion = error.recoverySuggestion {
                        Text(recoverySuggestion)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Authentication View

/// Main authentication view with Sign in with Apple
struct SignInView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var isSigningIn = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // App Logo and Title
            VStack(spacing: Spacing.lg) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.emerald)
                
                Text("MimiSupply")
                    .font(.displayMedium)
                    .foregroundColor(.graphite)
                
                Text("Your local marketplace")
                    .font(.titleMedium)
                    .foregroundColor(.gray600)
            }
            
            Spacer()
            
            // Sign in Button
            VStack(spacing: Spacing.md) {
                Button(action: {
                    isSigningIn = true
                    Task {
                        await authManager.signInWithApple()
                        isSigningIn = false
                    }
                }) {
                    HStack {
                        if isSigningIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "applelogo")
                                .font(.title3)
                        }
                        
                        Text(isSigningIn ? "Signing In..." : "Sign in with Apple")
                            .font(.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(8)
                }
                .disabled(isSigningIn)
                .accessibilityLabel("Sign in with Apple")
                .accessibilityHint("Authenticate using your Apple ID")
                
                Text("Secure authentication with your Apple ID")
                    .font(.bodySmall)
                    .foregroundColor(.gray500)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.md)
    }
}

// MARK: - Preview

#Preview("Authentication View") {
    SignInView()
        .environmentObject(AuthenticationManager())
}

#Preview("Authentication Gate") {
    AuthenticationGate {
        Text("Protected Content")
            .font(.title)
    }
}
