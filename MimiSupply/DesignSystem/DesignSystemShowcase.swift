//
//  DesignSystemShowcase.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Comprehensive showcase of all design system components for testing and documentation
struct DesignSystemShowcase: View {
    @State private var textFieldText = ""
    @State private var isLoading = false
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Spacing.xl) {
                    // Colors Section
                    colorSection
                    
                    // Typography Section
                    typographySection
                    
                    // Buttons Section
                    buttonsSection
                    
                    // Text Fields Section
                    textFieldsSection
                    
                    // Cards Section
                    cardsSection
                    
                    // Loading States Section
                    loadingSection
                    
                    // Empty States Section
                    emptyStatesSection
                    
                    // Badges Section
                    badgesSection
                    
                    // Dividers Section
                    dividersSection
                    
                    // Accessibility Info Section
                    accessibilitySection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }
            .navigationTitle("Design System")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Color Section
    
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Colors")
                .font(.headlineSmall)
                .accessibleHeading(label: "Colors", level: .h2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.sm) {
                ColorSwatch(color: .emerald, name: "Emerald")
                ColorSwatch(color: .chalk, name: "Chalk")
                ColorSwatch(color: .graphite, name: "Graphite")
                ColorSwatch(color: .success, name: "Success")
                ColorSwatch(color: .warning, name: "Warning")
                ColorSwatch(color: .error, name: "Error")
                ColorSwatch(color: .info, name: "Info")
                ColorSwatch(color: .gray300, name: "Gray 300")
                ColorSwatch(color: .gray600, name: "Gray 600")
            }
        }
    }
    
    // MARK: - Typography Section
    
    private var typographySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Typography")
                .font(.headlineSmall)
                .accessibleHeading(label: "Typography", level: .h2)
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Display Large")
                    .font(.displayLarge)
                Text("Headline Medium")
                    .font(.headlineMedium)
                Text("Title Large")
                    .font(.titleLarge)
                Text("Body Medium - This is regular body text that scales with Dynamic Type.")
                    .font(.bodyMedium)
                Text("Label Small")
                    .font(.labelSmall)
            }
        }
    }
    
    // MARK: - Buttons Section
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Buttons")
                .font(.headlineSmall)
                .accessibleHeading(label: "Buttons", level: .h2)
            
            VStack(spacing: Spacing.sm) {
                PrimaryButton(title: "Primary Button") {
                    print("Primary button tapped")
                }
                
                PrimaryButton(title: "Loading Button", action: {}, isLoading: isLoading)
                
                PrimaryButton(title: "Disabled Button", action: {}, isDisabled: true)
                
                SecondaryButton(title: "Secondary Button") {
                    print("Secondary button tapped")
                }
                
                Button("Toggle Loading") {
                    isLoading.toggle()
                }
                .font(.bodyMedium)
                .foregroundColor(.emerald)
            }
        }
    }
    
    // MARK: - Text Fields Section
    
    private var textFieldsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Text Fields")
                .font(.headlineSmall)
                .accessibleHeading(label: "Text Fields", level: .h2)
            
            VStack(spacing: Spacing.md) {
                AppTextField(
                    title: "Email",
                    placeholder: "Enter your email",
                    text: $textFieldText,
                    keyboardType: .emailAddress
                )
                
                AppTextField(
                    title: "Password",
                    placeholder: "Enter your password",
                    text: .constant(""),
                    isSecure: true
                )
                
                AppTextField(
                    title: "Error State",
                    placeholder: "This field has an error",
                    text: .constant("invalid@"),
                    errorMessage: "Please enter a valid email address"
                )
                
                AppTextField(
                    title: "Disabled Field",
                    placeholder: "This field is disabled",
                    text: .constant(""),
                    isDisabled: true
                )
            }
        }
    }
    
    // MARK: - Cards Section
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Cards")
                .font(.headlineSmall)
                .accessibleHeading(label: "Cards", level: .h2)
            
            AppCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sample Card")
                        .font(.titleMedium)
                        .foregroundColor(.graphite)
                    
                    Text("This is a sample card demonstrating the card component with consistent styling and shadows.")
                        .font(.bodyMedium)
                        .foregroundColor(.gray600)
                }
            }
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Loading States")
                .font(.headlineSmall)
                .accessibleHeading(label: "Loading States", level: .h2)
            
            HStack(spacing: Spacing.lg) {
                AppLoadingView(message: "Small", size: .small)
                AppLoadingView(message: "Medium", size: .medium)
                AppLoadingView(message: "Large", size: .large)
            }
        }
    }
    
    // MARK: - Empty States Section
    
    private var emptyStatesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Empty States")
                .font(.headlineSmall)
                .accessibleHeading(label: "Empty States", level: .h2)
            
            AppCard {
                EmptyStateView(
                    icon: "cart",
                    title: "Empty Cart",
                    message: "Your cart is empty. Add some items to get started.",
                    actionTitle: "Browse Items"
                ) {
                    print("Browse items tapped")
                }
            }
        }
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Badges")
                .font(.headlineSmall)
                .accessibleHeading(label: "Badges", level: .h2)
            
            VStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.sm) {
                    Badge(text: "New", style: .primary, size: .small)
                    Badge(text: "Available", style: .success, size: .medium)
                    Badge(text: "Urgent", style: .error, size: .large)
                }
                
                HStack(spacing: Spacing.lg) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.title2)
                            .foregroundColor(.graphite)
                        NotificationBadge(count: 3)
                            .offset(x: 8, y: -8)
                    }
                    
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart")
                            .font(.title2)
                            .foregroundColor(.graphite)
                        NotificationBadge(count: 127)
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
    }
    
    // MARK: - Dividers Section
    
    private var dividersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Dividers")
                .font(.headlineSmall)
                .accessibleHeading(label: "Dividers", level: .h2)
            
            VStack(spacing: Spacing.md) {
                Text("Content above divider")
                    .font(.bodyMedium)
                
                AppDivider()
                
                Text("Content below divider")
                    .font(.bodyMedium)
                
                AppDivider()
                
                Text("Section content")
                    .font(.bodyMedium)
            }
        }
    }
    
    // MARK: - Accessibility Section
    
    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Accessibility Info")
                .font(.headlineSmall)
                .accessibleHeading(label: "Accessibility Info", level: .h2)
            
            AppCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    AccessibilityInfoRow(
                        title: "VoiceOver",
                        value: VoiceOverHelpers.isVoiceOverRunning ? "Enabled" : "Disabled"
                    )
                    
                    AccessibilityInfoRow(
                        title: "Reduce Motion",
                        value: accessibilityManager.isReduceMotionEnabled ? "Enabled" : "Disabled"
                    )
                    
                    AccessibilityInfoRow(
                        title: "High Contrast",
                        value: accessibilityManager.isHighContrastEnabled ? "Enabled" : "Disabled"
                    )
                    
                    AccessibilityInfoRow(
                        title: "Text Size",
                        value: accessibilityManager.preferredContentSizeCategory.rawValue
                    )
                }
            }
        }
    }
}

// MARK: - Helper Views

private struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Rectangle()
                .fill(color)
                .frame(height: 40)
                .cornerRadius(8)
                .accessibleImage(description: "\(name) color swatch")
            
            Text(name)
                .font(.labelSmall)
                .foregroundColor(.gray600)
        }
    }
}

private struct AccessibilityInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.bodyMedium)
                .foregroundColor(.graphite)
            
            Spacer()
            
            Text(value)
                .font(.bodyMedium)
                .foregroundColor(.gray600)
        }
        .accessibilityGroup(label: "\(title): \(value)")
    }
}

#Preview {
    DesignSystemShowcase()
}