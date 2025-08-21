//
//  SettingsView.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

/// Main settings view with account management and preferences
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                profileSection
                
                // Account Section
                accountSection
                
                // Preferences Section
                preferencesSection
                
                // Privacy & Security Section
                privacySection
                
                // Support Section
                supportSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshUserProfile()
            }
            .sheet(isPresented: $viewModel.showingProfileEdit) {
                ProfileEditView()
            }
            .sheet(isPresented: $viewModel.showingLanguageSelection) {
                LanguageSelectionView()
            }
            .alert("Sign Out", isPresented: $viewModel.showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You'll need to sign in again to access your account.")
            }
            .alert("Delete Account", isPresented: $viewModel.showingDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
        .task {
            await viewModel.loadUserProfile()
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        Section {
            HStack(spacing: Spacing.md) {
                // Profile Image
                AsyncImage(url: viewModel.userProfile?.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray400)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .accessibleImage(
                    label: "Profile picture",
                    isDecorative: false
                )
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if let profile = viewModel.userProfile {
                        Text(profile.fullName?.formatted() ?? "Unknown User")
                            .font(.titleMedium.scaledFont())
                            .foregroundColor(.graphite)
                        
                        Text(profile.email ?? "No email")
                            .font(.bodySmall.scaledFont())
                            .foregroundColor(.gray600)
                        
                        Text(profile.role.displayName)
                            .font(.bodySmall.scaledFont())
                            .foregroundColor(.emerald)
                    } else {
                        Text("Loading...")
                            .font(.titleMedium.scaledFont())
                            .foregroundColor(.gray500)
                    }
                }
                
                Spacer()
                
                Button("Edit") {
                    viewModel.showingProfileEdit = true
                }
                .font(.bodyMedium.scaledFont())
                .foregroundColor(.emerald)
                .accessibleButton(
                    label: "Edit profile",
                    hint: "Tap to edit your profile information"
                )
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            Text("Profile")
                .accessibleHeading("Profile", level: .h2)
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Section {
            SettingsRow(
                icon: "bell",
                title: "Notifications",
                subtitle: "Manage notification preferences",
                action: {
                    viewModel.navigateToNotificationSettings()
                }
            )
            
            SettingsRow(
                icon: "lock",
                title: "Privacy & Security",
                subtitle: "Data usage and security settings",
                action: {
                    viewModel.navigateToPrivacySettings()
                }
            )
            
            SettingsRow(
                icon: "arrow.down.circle",
                title: "Export Data",
                subtitle: "Download your account data",
                action: {
                    Task {
                        await viewModel.exportUserData()
                    }
                }
            )
            
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: "Sign Out",
                subtitle: nil,
                action: {
                    viewModel.showingSignOutConfirmation = true
                },
                isDestructive: false
            )
        } header: {
            Text("Account")
                .accessibleHeading("Account", level: .h2)
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section {
            SettingsRow(
                icon: "globe",
                title: "Language",
                subtitle: viewModel.currentLanguage,
                action: {
                    viewModel.showingLanguageSelection = true
                }
            )
            
            SettingsRow(
                icon: "paintbrush",
                title: "Appearance",
                subtitle: viewModel.currentAppearance,
                action: {
                    viewModel.navigateToAppearanceSettings()
                }
            )
            
            SettingsRow(
                icon: "location",
                title: "Location Services",
                subtitle: viewModel.locationPermissionStatus,
                action: {
                    viewModel.navigateToLocationSettings()
                }
            )
        } header: {
            Text("Preferences")
                .accessibleHeading("Preferences", level: .h2)
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section {
            SettingsRow(
                icon: "hand.raised",
                title: "Data & Privacy",
                subtitle: "How we use your data",
                action: {
                    viewModel.navigateToDataPrivacy()
                }
            )
            
            SettingsRow(
                icon: "checkmark.shield",
                title: "Permissions",
                subtitle: "App permissions and access",
                action: {
                    viewModel.navigateToPermissions()
                }
            )
        } header: {
            Text("Privacy & Security")
                .accessibleHeading("Privacy & Security", level: .h2)
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        Section {
            SettingsRow(
                icon: "questionmark.circle",
                title: "Help & Support",
                subtitle: "Get help and contact support",
                action: {
                    viewModel.navigateToSupport()
                }
            )
            
            SettingsRow(
                icon: "star",
                title: "Rate App",
                subtitle: "Rate MimiSupply on the App Store",
                action: {
                    viewModel.rateApp()
                }
            )
            
            SettingsRow(
                icon: "envelope",
                title: "Send Feedback",
                subtitle: "Share your thoughts with us",
                action: {
                    viewModel.sendFeedback()
                }
            )
        } header: {
            Text("Support")
                .accessibleHeading("Support", level: .h2)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Section {
            SettingsRow(
                icon: "info.circle",
                title: "About MimiSupply",
                subtitle: "Version \(viewModel.appVersion)",
                action: {
                    viewModel.navigateToAbout()
                }
            )
            
            SettingsRow(
                icon: "doc.text",
                title: "Terms of Service",
                subtitle: nil,
                action: {
                    viewModel.openTermsOfService()
                }
            )
            
            SettingsRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                subtitle: nil,
                action: {
                    viewModel.openPrivacyPolicy()
                }
            )
            
            SettingsRow(
                icon: "trash",
                title: "Delete Account",
                subtitle: "Permanently delete your account",
                action: {
                    viewModel.showingDeleteAccountConfirmation = true
                },
                isDestructive: true
            )
        } header: {
            Text("About")
                .accessibleHeading("About", level: .h2)
        }
    }
}

// MARK: - Settings Row Component

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    let isDestructive: Bool
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void,
        isDestructive: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isDestructive = isDestructive
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.bodyMedium.scaledFont())
                        .foregroundColor(titleColor)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.bodySmall.scaledFont())
                            .foregroundColor(.gray600)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray400)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibleCard(
            title: title,
            subtitle: subtitle,
            hint: "Tap to \(title.lowercased())"
        )
        .switchControlAccessible(
            identifier: "settings-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            sortPriority: 0.7
        )
    }
    
    private var iconColor: Color {
        let baseColor: Color = isDestructive ? .error : .emerald
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var titleColor: Color {
        let baseColor: Color = isDestructive ? .error : .graphite
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
}

#Preview {
    SettingsView()
}