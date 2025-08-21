//
//  SettingsViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI
import StoreKit

/// ViewModel for managing settings and user preferences
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Sheet presentation states
    @Published var showingProfileEdit = false
    @Published var showingLanguageSelection = false
    @Published var showingSignOutConfirmation = false
    @Published var showingDeleteAccountConfirmation = false
    
    // MARK: - Dependencies
    
    private let authService: AuthenticationService
    private let cloudKitService: CloudKitService
    private let locationService: LocationService
    
    // MARK: - Computed Properties
    
    var currentLanguage: String {
        let locale = Locale.current
        return locale.localizedString(forLanguageCode: locale.language.languageCode?.identifier ?? "en") ?? "English"
    }
    
    var currentAppearance: String {
        switch UITraitCollection.current.userInterfaceStyle {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        default:
            return "System"
        }
    }
    
    var locationPermissionStatus: String {
        switch locationService.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return "Enabled"
        case .denied, .restricted:
            return "Disabled"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }
    
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - Initialization
    
    init(
        authService: AuthenticationService? = nil,
        cloudKitService: CloudKitService? = nil,
        locationService: LocationService? = nil
    ) {
        // Access AppContainer.shared properties on MainActor
        self.authService = authService ?? AppContainer.shared.authenticationService
        self.cloudKitService = cloudKitService ?? AppContainer.shared.cloudKitService
        self.locationService = locationService ?? AppContainer.shared.locationService
    }
    
    // MARK: - Profile Management
    
    func loadUserProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            userProfile = await authService.currentUser
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshUserProfile() async {
        await loadUserProfile()
    }
    
    // MARK: - Account Actions
    
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            // Navigation will be handled by the authentication state change
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.deleteAccount()
            // Navigation will be handled by the authentication state change
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func exportUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create data export
            let exportData = try await createDataExport()
            
            // Share the data
            await shareData(exportData)
            
        } catch {
            errorMessage = "Failed to export data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Navigation Actions
    
    func navigateToNotificationSettings() {
        // Open system notification settings
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func navigateToPrivacySettings() {
        // Navigate to privacy settings view
        // This would be implemented with proper navigation
    }
    
    func navigateToAppearanceSettings() {
        // Navigate to appearance settings
        // This would be implemented with proper navigation
    }
    
    func navigateToLocationSettings() {
        // Open system location settings
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    func navigateToDataPrivacy() {
        // Navigate to data privacy view
        // This would be implemented with proper navigation
    }
    
    func navigateToPermissions() {
        // Navigate to permissions view
        // This would be implemented with proper navigation
    }
    
    func navigateToSupport() {
        // Navigate to support view
        // This would be implemented with proper navigation
    }
    
    func navigateToAbout() {
        // Navigate to about view
        // This would be implemented with proper navigation
    }
    
    // MARK: - External Actions
    
    func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    func sendFeedback() {
        // Open mail app or feedback form
        let email = "support@mimisupply.com"
        let subject = "MimiSupply Feedback"
        let body = "Hi MimiSupply team,\n\n"
        
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    func openTermsOfService() {
        if let url = URL(string: "https://mimisupply.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    func openPrivacyPolicy() {
        if let url = URL(string: "https://mimisupply.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func createDataExport() async throws -> Data {
        guard let profile = userProfile else {
            throw SettingsError.noUserProfile
        }
        
        let exportData = UserDataExport(
            profile: profile,
            exportDate: Date(),
            appVersion: appVersion
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    private func shareData(_ data: Data) async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mimisupply-data-export.json")
        
        do {
            try data.write(to: tempURL)
            
            let activityViewController = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityViewController, animated: true)
            }
        } catch {
            errorMessage = "Failed to share data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Types

struct UserDataExport: Codable {
    let profile: UserProfile
    let exportDate: Date
    let appVersion: String
}

enum SettingsError: LocalizedError {
    case noUserProfile
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noUserProfile:
            return "No user profile available"
        case .exportFailed:
            return "Failed to export user data"
        }
    }
}