//
//  AppState.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation
import SwiftUI
import Combine

/// Global app state management
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppState()
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isOnboardingCompleted = false
    @Published var networkStatus: NetworkStatus = .connected
    @Published var appVersion: String = ""
    @Published var buildNumber: String = ""
    
    // MARK: - Feature Flags
    @Published var featureFlags: [String: Bool] = [
        "useMockCloudKit": true,
        "enableAnalytics": true,
        "enablePushNotifications": true,
        "enableLocationServices": true,
        "enableOfflineMode": true
    ]
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    private enum Keys {
        static let isOnboardingCompleted = "isOnboardingCompleted"
        static let featureFlags = "featureFlags"
    }
    
    // MARK: - Initialization
    private init() {
        loadAppInfo()
        loadPersistedState()
        setupBindings()
    }
    
    // MARK: - Public Methods
    func updateAuthenticationState(isAuthenticated: Bool, user: UserProfile?) {
        self.isAuthenticated = isAuthenticated
        self.currentUser = user
    }
    
    func completeOnboarding() {
        isOnboardingCompleted = true
        userDefaults.set(true, forKey: Keys.isOnboardingCompleted)
    }
    
    func updateNetworkStatus(_ status: NetworkStatus) {
        networkStatus = status
    }
    
    func toggleFeatureFlag(_ key: String) {
        featureFlags[key]?.toggle()
        saveFeatureFlags()
    }
    
    func setFeatureFlag(_ key: String, enabled: Bool) {
        featureFlags[key] = enabled
        saveFeatureFlags()
    }
    
    func isFeatureEnabled(_ key: String) -> Bool {
        return featureFlags[key] ?? false
    }
    
    // MARK: - Private Methods
    private func loadAppInfo() {
        if let infoPlist = Bundle.main.infoDictionary {
            appVersion = infoPlist["CFBundleShortVersionString"] as? String ?? "1.0.0"
            buildNumber = infoPlist["CFBundleVersion"] as? String ?? "1"
        }
    }
    
    private func loadPersistedState() {
        isOnboardingCompleted = userDefaults.bool(forKey: Keys.isOnboardingCompleted)
        
        if let flagsData = userDefaults.data(forKey: Keys.featureFlags),
           let flags = try? JSONDecoder().decode([String: Bool].self, from: flagsData) {
            featureFlags.merge(flags) { _, new in new }
        }
    }
    
    private func setupBindings() {
        // Auto-save feature flags when they change
        $featureFlags
            .dropFirst()
            .sink { [weak self] _ in
                self?.saveFeatureFlags()
            }
            .store(in: &cancellables)
    }
    
    private func saveFeatureFlags() {
        if let data = try? JSONEncoder().encode(featureFlags) {
            userDefaults.set(data, forKey: Keys.featureFlags)
        }
    }
}

// MARK: - Supporting Types

enum NetworkStatus {
    case connected
    case disconnected
    case poor
    
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Offline"
        case .poor: return "Poor Connection"
        }
    }
}