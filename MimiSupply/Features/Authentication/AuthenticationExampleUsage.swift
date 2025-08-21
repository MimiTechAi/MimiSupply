//
//  AuthenticationExampleUsage.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Example usage of the authentication system in the MimiSupply app
/// This file demonstrates how to integrate authentication throughout the app

// MARK: - App Root with Authentication

/// Main app view that handles authentication state
struct MimiSupplyAppRoot: View {
    var body: some View {
        AuthenticationGate {
            MainTabView()
        }
    }
}

// MARK: - Main Tab View (Post-Authentication)

/// Main tab view shown after successful authentication
struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Customer Tab
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .customer || user.role == .admin {
                ExploreHomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Explore")
                    }
                    .tag(0)
            }
            
            // Driver Tab
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .driver || user.role == .admin {
                DriverDashboardView()
                    .tabItem {
                        Image(systemName: "car.fill")
                        Text("Drive")
                    }
                    .tag(1)
            }
            
            // Partner Tab
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .partner || user.role == .admin {
                PartnerDashboardView()
                    .tabItem {
                        Image(systemName: "storefront.fill")
                        Text("Business")
                    }
                    .tag(2)
            }
            
            // Profile Tab (Available to all)
            ExampleProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
    }
}

// MARK: - Profile View with Authentication Controls

/// Profile view with authentication management
struct ExampleProfileView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showingRoleChange = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                // User Info Section
                if case .authenticated(let user) = authManager.authenticationState {
                    Section("Account") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.emerald)
                            
                            VStack(alignment: .leading) {
                                if let fullName = user.fullName {
                                    Text(PersonNameComponentsFormatter().string(from: fullName))
                                        .font(.titleMedium)
                                }
                                
                                Text(user.role.displayName)
                                    .font(.bodyMedium)
                                    .foregroundColor(.gray600)
                                
                                if let email = user.email {
                                    Text(email)
                                        .font(.bodySmall)
                                        .foregroundColor(.gray500)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                    
                    // Role Management Section
                    Section("Role") {
                        Button("Change Role") {
                            showingRoleChange = true
                        }
                        .foregroundColor(.emerald)
                    }
                    
                    // Account Actions Section
                    Section("Account Actions") {
                        Button("Sign Out") {
                            Task {
                                await authManager.signOut()
                            }
                        }
                        .foregroundColor(.orange)
                        
                        Button("Delete Account") {
                            showingDeleteConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingRoleChange) {
                if case .authenticated(let user) = authManager.authenticationState {
                    RoleChangeView(currentUser: user) { newRole in
                        Task {
                            await authManager.selectRole(newRole)
                        }
                        showingRoleChange = false
                    }
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await authManager.deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
}

// MARK: - Role Change View

/// View for changing user role
struct RoleChangeView: View {
    let currentUser: UserProfile
    let onRoleSelected: (UserRole) -> Void
    
    @State private var selectedRole: UserRole
    @Environment(\.dismiss) private var dismiss
    
    init(currentUser: UserProfile, onRoleSelected: @escaping (UserRole) -> Void) {
        self.currentUser = currentUser
        self.onRoleSelected = onRoleSelected
        self._selectedRole = State(initialValue: currentUser.role)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Text("Change Your Role")
                    .font(.headlineMedium)
                    .padding(.top, Spacing.lg)
                
                Text("Select how you'd like to use MimiSupply")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: Spacing.md) {
                    RoleSelectionButton(
                        role: .customer,
                        title: "Customer",
                        description: "Browse and order from local businesses",
                        icon: "bag.fill",
                        isSelected: selectedRole == .customer
                    ) {
                        selectedRole = .customer
                    }
                    
                    RoleSelectionButton(
                        role: .driver,
                        title: "Driver",
                        description: "Deliver orders and earn money",
                        icon: "car.fill",
                        isSelected: selectedRole == .driver
                    ) {
                        selectedRole = .driver
                    }
                    
                    RoleSelectionButton(
                        role: .partner,
                        title: "Business Partner",
                        description: "Manage your business and products",
                        icon: "storefront.fill",
                        isSelected: selectedRole == .partner
                    ) {
                        selectedRole = .partner
                    }
                }
                
                Spacer()
                
                PrimaryButton(
                    title: "Update Role",
                    action: {
                        onRoleSelected(selectedRole)
                    },
                    isLoading: false,
                    isDisabled: selectedRole == currentUser.role
                )
                .padding(.horizontal, Spacing.md)
            }
            .padding(.horizontal, Spacing.md)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Role Selection Button Component

private struct RoleSelectionButton: View {
    let role: UserRole
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .emerald)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.titleSmall)
                        .foregroundColor(isSelected ? .white : .graphite)
                    
                    Text(description)
                        .font(.bodySmall)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .gray600)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .gray400)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.emerald : Color.white)
                    .stroke(isSelected ? Color.emerald : Color.gray200, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Protected Content Example

/// Example of how to protect content based on authentication
struct ProtectedContentExample: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Content available to all authenticated users
            Text("Welcome to MimiSupply!")
                .font(.headlineMedium)
            
            // Customer-only content
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .customer || user.role == .admin {
                
                Button("Browse Products") {
                    // Navigate to product browsing
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Driver-only content
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .driver || user.role == .admin {
                
                Button("View Available Jobs") {
                    // Navigate to driver dashboard
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Partner-only content
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .partner || user.role == .admin {
                
                Button("Manage Business") {
                    // Navigate to partner dashboard
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Permission-Based View Modifier

/// View modifier that shows content based on permissions
struct PermissionBasedModifier: ViewModifier {
    let action: AuthenticationAction
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var hasPermission = false
    
    func body(content: Content) -> some View {
        Group {
            if hasPermission {
                content
            } else {
                EmptyView()
            }
        }
        .task {
            hasPermission = await authManager.hasPermission(for: action)
        }
    }
}

extension View {
    /// Shows the view only if the user has permission for the specified action
    func requiresPermission(for action: AuthenticationAction) -> some View {
        modifier(PermissionBasedModifier(action: action))
    }
}

// MARK: - Usage Examples

/// Examples of how to use the permission-based modifier
struct PermissionExamples: View {
    var body: some View {
        VStack {
            // Only show to customers
            Text("Customer Content")
                .requiresPermission(for: .placeOrder)
            
            // Only show to drivers
            Text("Driver Content")
                .requiresPermission(for: .acceptDeliveryJobs)
            
            // Only show to partners
            Text("Partner Content")
                .requiresPermission(for: .manageBusinessProfile)
            
            // Only show to admins
            Text("Admin Content")
                .requiresPermission(for: .adminAccess)
        }
    }
}

// MARK: - Preview

#Preview("App Root") {
    MimiSupplyAppRoot()
}

#Preview("Profile View") {
    ExampleProfileView()
        .environmentObject(AuthenticationManager())
}

#Preview("Role Change") {
    RoleChangeView(
        currentUser: UserProfile(
            id: "test-user",
            email: "test@example.com",
            role: .customer
        )
    ) { role in
        print("Selected role: \(role)")
    }
}