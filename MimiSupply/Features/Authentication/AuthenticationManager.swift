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
    
    init(authenticationService: AuthenticationService = AuthenticationServiceImpl.shared) {
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
                DemoSignInView()
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
                DemoSignInView()
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