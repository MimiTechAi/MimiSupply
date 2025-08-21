//
//  PremiumSignInView.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import SwiftUI

/// Premium authentication view with stunning visuals and smooth animations
struct PremiumSignInView: View {
    @StateObject private var demoAuth = DemoAuthService.shared
    @State private var isLoading = false
    @State private var showDemoOptions = false
    @State private var selectedRole: UserRole = .customer
    @State private var email = ""
    @State private var password = ""
    @State private var showEmailLogin = false
    @State private var loginError: String?
    @State private var showError = false
    @State private var animationOffset: CGFloat = -100
    @State private var animationOpacity: Double = 0
    
    private let emeraldGradient = LinearGradient(
        colors: [
            Color(red: 0.31, green: 0.78, blue: 0.47),
            Color(red: 0.25, green: 0.85, blue: 0.55)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Premium Background with Animated Gradient
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Section
                    VStack(spacing: 24) {
                        Spacer(minLength: 60)
                        
                        // Animated Logo
                        AnimatedLogoView()
                            .offset(y: animationOffset)
                            .opacity(animationOpacity)
                            .animation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0), value: animationOffset)
                        
                        // Welcome Text
                        VStack(spacing: 12) {
                            Text("Willkommen bei")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("MimiSupply")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Dein Premium Marktplatz")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .offset(y: animationOffset * 0.5)
                        .opacity(animationOpacity)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8, blendDuration: 0).delay(0.2), value: animationOffset)
                        
                        Spacer(minLength: 40)
                    }
                    
                    // Authentication Card
                    VStack(spacing: 0) {
                        // Card with glassmorphism effect
                        VStack(spacing: 28) {
                            // Demo Role Selection
                            PremiumRoleSelector(selectedRole: $selectedRole)
                                .opacity(animationOpacity)
                                .animation(.spring(response: 1.0, dampingFraction: 0.8, blendDuration: 0).delay(0.4), value: animationOpacity)
                            
                            // Quick Login Buttons
                            VStack(spacing: 16) {
                                PremiumButton(
                                    title: "Demo Login - \(selectedRole.displayName)",
                                    icon: selectedRole.iconName,
                                    style: .primary,
                                    isLoading: isLoading
                                ) {
                                    await performQuickLogin()
                                }
                                
                                PremiumButton(
                                    title: "Mit Apple anmelden",
                                    icon: "applelogo",
                                    style: .apple,
                                    isLoading: false
                                ) {
                                    // Apple Sign-In implementation
                                }
                                
                                PremiumButton(
                                    title: "Email & Passwort",
                                    icon: "envelope",
                                    style: .secondary,
                                    isLoading: false
                                ) {
                                    showEmailLogin = true
                                }
                            }
                            .opacity(animationOpacity)
                            .animation(.spring(response: 1.0, dampingFraction: 0.8, blendDuration: 0).delay(0.6), value: animationOpacity)
                            
                            // Demo Accounts Info
                            DemoAccountsInfoCard()
                                .opacity(animationOpacity)
                                .animation(.spring(response: 1.0, dampingFraction: 0.8, blendDuration: 0).delay(0.8), value: animationOpacity)
                        }
                        .padding(32)
                        .background {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(
                                            LinearGradient(
                                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .padding(.horizontal, 24)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                        
                        Spacer(minLength: 60)
                    }
                }
            }
        }
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginSheet(
                email: $email,
                password: $password,
                onLogin: performEmailLogin,
                onDismiss: { showEmailLogin = false }
            )
        }
        .alert("Login Fehler", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(loginError ?? "Unbekannter Fehler")
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0)) {
                animationOffset = 0
                animationOpacity = 1
            }
        }
        .onChange(of: demoAuth.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                // Navigate to main app - this will be handled by the root view
                print("✅ Demo login successful!")
            }
        }
    }
    
    private func performQuickLogin() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            _ = try await demoAuth.quickLogin(role: selectedRole)
        } catch {
            loginError = error.localizedDescription
            showError = true
        }
    }
    
    private func performEmailLogin(email: String, password: String) async {
        do {
            _ = try await demoAuth.login(email: email, password: password)
            showEmailLogin = false
        } catch {
            loginError = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Animated Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.31, green: 0.78, blue: 0.47),
                Color(red: 0.25, green: 0.85, blue: 0.55),
                Color(red: 0.35, green: 0.75, blue: 0.65),
                Color(red: 0.28, green: 0.82, blue: 0.52)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

// MARK: - Animated Logo
struct AnimatedLogoView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0.5 : 0.8)
            
            // Main logo background
            Circle()
                .fill(.white.opacity(0.95))
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
            
            // Logo icon
            Image(systemName: "bag.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.31, green: 0.78, blue: 0.47),
                            Color(red: 0.25, green: 0.85, blue: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Premium Role Selector
struct PremiumRoleSelector: View {
    @Binding var selectedRole: UserRole
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Rolle wählen")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach([UserRole.customer, UserRole.partner, UserRole.driver], id: \.self) { role in
                    RoleButton(
                        role: role,
                        isSelected: selectedRole == role
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedRole = role
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Role Button
struct RoleButton: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: role.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(role.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .white.opacity(0.25) : .white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? .white.opacity(0.4) : .white.opacity(0.2),
                                lineWidth: 1
                            )
                    }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Premium Button
struct PremiumButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let isLoading: Bool
    let action: () async -> Void
    
    enum ButtonStyle {
        case primary, secondary, apple
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .white.opacity(0.2)
            case .secondary: return .white.opacity(0.1)
            case .apple: return .black
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary: return .white
            case .apple: return .white
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return .white.opacity(0.3)
            case .secondary: return .white.opacity(0.2)
            case .apple: return .clear
            }
        }
    }
    
    var body: some View {
        Button {
            Task {
                await action()
            }
        } label: {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Text(isLoading ? "Wird geladen..." : title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(style.backgroundColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style.borderColor, lineWidth: 1)
                    }
            }
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
    }
}

// MARK: - Demo Accounts Info Card
struct DemoAccountsInfoCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🎯 Demo-Konten")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DemoAccountInfo(
                    role: "👤 Kunde",
                    email: "kunde@test.de",
                    features: "• Bestellen • Verfolgen • Bewerten"
                )
                
                DemoAccountInfo(
                    role: "🏪 Partner",
                    email: "mcdonalds@partner.de",
                    features: "• Menü verwalten • Bestellungen • Analytics"
                )
                
                DemoAccountInfo(
                    role: "🚗 Fahrer",
                    email: "fahrer1@test.de",
                    features: "• Jobs annehmen • Navigation • Verdienste"
                )
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

// MARK: - Demo Account Info
struct DemoAccountInfo: View {
    let role: String
    let email: String
    let features: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(role)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(email)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Text(features)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Email Login Sheet
struct EmailLoginSheet: View {
    @Binding var email: String
    @Binding var password: String
    let onLogin: (String, String) async -> Void
    let onDismiss: () -> Void
    
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    TextField("E-Mail", text: $email)
                        .textFieldStyle(PremiumTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Passwort", text: $password)
                        .textFieldStyle(PremiumTextFieldStyle())
                }
                
                PremiumButton(
                    title: "Anmelden",
                    icon: "person.crop.circle.badge.checkmark",
                    style: .primary,
                    isLoading: isLoading
                ) {
                    isLoading = true
                    await onLogin(email, password)
                    isLoading = false
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Login")
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

// MARK: - Premium Text Field Style
struct PremiumTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    }
            }
            .foregroundColor(.primary)
    }
}

// MARK: - UserRole Extension
extension UserRole {
    var iconName: String {
        switch self {
        case .customer: return "person.fill"
        case .partner: return "storefront.fill"
        case .driver: return "car.fill"
        case .admin: return "person.badge.key.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    PremiumSignInView()
}