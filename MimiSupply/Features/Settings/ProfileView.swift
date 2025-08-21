//
//  ProfileView.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var showingSignIn = false
    @State private var isAuthenticated = false
    @State private var currentUser: UserProfile?
    
    var body: some View {
        NavigationView {
            List {
                if isAuthenticated, let user = currentUser {
                    // Authenticated user section
                    Section {
                        HStack {
                            Circle()
                                .fill(Color.emerald)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(user.displayInitials)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.gray600)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Account") {
                        NavigationLink(destination: ProfileEditView()) {
                            Label("Edit Profile", systemImage: "person.circle")
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    
                    Section {
                        Button("Sign Out") {
                            signOut()
                        }
                        .foregroundColor(.red)
                    }
                    
                } else {
                    // Guest user section
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray400)
                            
                            Text("Sign in to access your profile")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Track orders, save favorites, and more")
                                .font(.body)
                                .foregroundColor(.gray600)
                                .multilineTextAlignment(.center)
                            
                            PrimaryButton(title: "Sign In") {
                                showingSignIn = true
                            }
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    
                    Section("General") {
                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        NavigationLink(destination: EmptyStateView(
                            icon: "bag.badge.questionmark",
                            title: "Sign In Required",
                            message: "Sign in to view your order history",
                            actionTitle: "Sign In",
                            action: { showingSignIn = true }
                        )) {
                            Label("Order History", systemImage: "bag")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                await checkAuthenticationState()
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
                    .environmentObject(AuthenticationManager())
            }
            .task {
                await checkAuthenticationState()
            }
        }
    }
    
    private func checkAuthenticationState() async {
        isAuthenticated = await container.authenticationService.isAuthenticated
        currentUser = await container.authenticationService.currentUser
    }
    
    private func signOut() {
        Task {
            try? await container.authenticationService.signOut()
            await checkAuthenticationState()
        }
    }
}

extension UserProfile {
    var displayName: String {
        if let fullName = fullName {
            if let firstName = fullName.givenName, let lastName = fullName.familyName {
                return "\(firstName) \(lastName)"
            } else if let firstName = fullName.givenName {
                return firstName
            } else if let lastName = fullName.familyName {
                return lastName
            }
        }
        return email ?? "User"
    }
    
    var displayInitials: String {
        if let fullName = fullName {
            let first = fullName.givenName?.prefix(1) ?? ""
            let last = fullName.familyName?.prefix(1) ?? ""
            return String(first + last).uppercased()
        } else if let email = email {
            return String(email.prefix(2)).uppercased()
        } else {
            return "U"
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppContainer.shared)
}