//
//  DemoSignInView.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import SwiftUI

/// Enhanced sign-in view with both Apple Sign-In and Demo Login options
struct DemoSignInView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var isSigningIn = false
    @State private var showingDemoLogin = false
    @State private var email = ""
    @State private var password = ""
    @State private var loginError: String?
    @State private var showingLoginError = false
    
    var body: some View {
        NavigationView {
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
                    
                    Text("Dein lokaler Marktplatz")
                        .font(.titleMedium)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                // Authentication Options
                VStack(spacing: Spacing.lg) {
                    // Apple Sign-In
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
                            
                            Text(isSigningIn ? "Anmelden..." : "Mit Apple anmelden")
                                .font(.labelLarge)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.black)
                        .cornerRadius(8)
                    }
                    .disabled(isSigningIn)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray300)
                            .frame(height: 1)
                        
                        Text("oder")
                            .font(.bodyMedium)
                            .foregroundColor(.gray500)
                            .padding(.horizontal, Spacing.md)
                        
                        Rectangle()
                            .fill(Color.gray300)
                            .frame(height: 1)
                    }
                    
                    // Demo Login Button
                    Button(action: {
                        showingDemoLogin = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.title3)
                            
                            Text("Demo Login")
                                .font(.labelLarge)
                        }
                        .foregroundColor(.emerald)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.emerald.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.emerald, lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                    
                    // Quick Demo Access
                    VStack(spacing: Spacing.sm) {
                        Text("Schneller Demo-Zugang:")
                            .font(.bodySmall)
                            .foregroundColor(.gray600)
                        
                        HStack(spacing: Spacing.sm) {
                            DemoQuickLoginButton(
                                title: "Kunde",
                                email: "kunde@test.de",
                                password: "kunde123",
                                icon: "person.fill",
                                onLogin: quickLogin
                            )
                            
                            DemoQuickLoginButton(
                                title: "Partner",
                                email: "mcdonalds@partner.de",
                                password: "partner123",
                                icon: "storefront.fill",
                                onLogin: quickLogin
                            )
                            
                            DemoQuickLoginButton(
                                title: "Fahrer",
                                email: "fahrer1@test.de",
                                password: "fahrer123",
                                icon: "car.fill",
                                onLogin: quickLogin
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.md)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingDemoLogin) {
            DemoLoginSheet(
              email: $email,
              password: $password,
              onLogin: { email, password in
                  Task {
                      await attemptDemoLogin(email: email, password: password)
                  }
              },
              onDismiss: {
                  showingDemoLogin = false
              }
            )
        }
        .alert("Login Fehler", isPresented: $showingLoginError) {
            Button("OK") { }
        } message: {
            Text(loginError ?? "Unbekannter Fehler")
        }
    }
    
    private func quickLogin(email: String, password: String) {
        Task {
            await attemptDemoLogin(email: email, password: password)
        }
    }
    
    private func attemptDemoLogin(email: String, password: String) async {
        // Find matching demo account
        guard let demoUser = DemoAccounts.findUser(email: email, password: password) else {
            loginError = "Ungültige Login-Daten. Bitte überprüfe E-Mail und Passwort."
            showingLoginError = true
            return
        }
        
        // Create UserProfile from demo account
        let userProfile = UserProfile(
            id: demoUser.id,
            email: demoUser.email,
            fullName: PersonNameComponents(
                givenName: demoUser.name.components(separatedBy: " ").first,
                familyName: demoUser.name.components(separatedBy: " ").dropFirst().joined(separator: " ")
            ),
            role: demoUser.role,
            phoneNumber: demoUser.phone,
            isVerified: true
        )
        
        // Simulate successful login by setting auth state
        await MainActor.run {
            // In a real implementation, this would go through the authentication service
            // For demo purposes, we'll directly update the auth manager's state
            authManager.authenticationState = .authenticated(userProfile)
        }
        
        showingDemoLogin = false
    }
}

// MARK: - Demo Quick Login Button
struct DemoQuickLoginButton: View {
    let title: String
    let email: String
    let password: String
    let icon: String
    let onLogin: (String, String) -> Void
    
    var body: some View {
        Button(action: {
            onLogin(email, password)
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.emerald)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.emerald)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.emerald.opacity(0.1))
            .cornerRadius(6)
        }
    }
}

// MARK: - Demo Login Sheet
struct DemoLoginSheet: View {
    @Binding var email: String
    @Binding var password: String
    let onLogin: (String, String) -> Void
    let onDismiss: () -> Void
    
    @State private var isLoggingIn = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                Text("Demo Login")
                    .font(.headlineLarge)
                    .foregroundColor(.graphite)
                    .padding(.top, Spacing.lg)
                
                VStack(spacing: Spacing.md) {
                    // Email Field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("E-Mail")
                            .font(.labelMedium)
                            .foregroundColor(.graphite)
                        
                        TextField("demo@test.de", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Passwort")
                            .font(.labelMedium)
                            .foregroundColor(.graphite)
                        
                        SecureField("Passwort", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal, Spacing.md)
                
                // Demo Accounts List
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Verfügbare Demo-Konten:")
                        .font(.labelMedium)
                        .foregroundColor(.graphite)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        DemoAccountRow(name: "Max Mustermann (Kunde)", email: "kunde@test.de", password: "kunde123")
                        DemoAccountRow(name: "McDonald's (Partner)", email: "mcdonalds@partner.de", password: "partner123")
                        DemoAccountRow(name: "Thomas Weber (Fahrer)", email: "fahrer1@test.de", password: "fahrer123")
                    }
                }
                .padding(.horizontal, Spacing.md)
                
                Spacer()
                
                // Login Button
                Button(action: {
                    isLoggingIn = true
                    onLogin(email, password)
                    isLoggingIn = false
                }) {
                    HStack {
                        if isLoggingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isLoggingIn ? "Anmelden..." : "Anmelden")
                            .font(.labelLarge)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(email.isEmpty || password.isEmpty ? Color.gray400 : Color.emerald)
                    .cornerRadius(8)
                }
                .disabled(email.isEmpty || password.isEmpty || isLoggingIn)
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Demo Account Row
struct DemoAccountRow: View {
    let name: String
    let email: String
    let password: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.bodySmall)
                    .foregroundColor(.graphite)
                
                Text("\(email) • \(password)")
                    .font(.caption)
                    .foregroundColor(.gray500)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    DemoSignInView()
        .environmentObject(AuthenticationManager())
}