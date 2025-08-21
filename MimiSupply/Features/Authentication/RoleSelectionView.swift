//
//  RoleSelectionView.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// View for new users to select their role in the marketplace
struct RoleSelectionView: View {
    let user: UserProfile
    let onRoleSelected: (UserRole) -> Void
    
    @State private var selectedRole: UserRole?
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.xl) {
                // Header
                VStack(spacing: Spacing.md) {
                    Text("Welcome to MimiSupply!")
                        .font(.headlineLarge)
                        .foregroundColor(.graphite)
                        .multilineTextAlignment(.center)
                    
                    if let fullName = user.fullName {
                        Text("Hi \(PersonNameComponentsFormatter().string(from: fullName))!")
                            .font(.titleMedium)
                            .foregroundColor(.gray600)
                    }
                    
                    Text("How would you like to use MimiSupply?")
                        .font(.bodyLarge)
                        .foregroundColor(.gray600)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xxl)
                
                // Role Selection Cards
                VStack(spacing: Spacing.lg) {
                    RoleCard(
                        role: .customer,
                        title: "Customer",
                        description: "Browse local businesses, order products, and get them delivered",
                        icon: "bag.fill",
                        isSelected: selectedRole == .customer
                    ) {
                        selectedRole = .customer
                    }
                    
                    RoleCard(
                        role: .driver,
                        title: "Driver",
                        description: "Earn money by delivering orders to customers in your area",
                        icon: "car.fill",
                        isSelected: selectedRole == .driver
                    ) {
                        selectedRole = .driver
                    }
                    
                    RoleCard(
                        role: .partner,
                        title: "Business Partner",
                        description: "List your business and products to reach more customers",
                        icon: "storefront.fill",
                        isSelected: selectedRole == .partner
                    ) {
                        selectedRole = .partner
                    }
                }
                
                Spacer()
                
                // Continue Button
                PrimaryButton(
                    title: "Continue",
                    action: {
                        guard let role = selectedRole else { return }
                        isLoading = true
                        onRoleSelected(role)
                    },
                    isLoading: isLoading,
                    isDisabled: selectedRole == nil
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.xl)
            }
            .padding(.horizontal, Spacing.md)
            .navigationBarHidden(true)
        }
        .accessibilityLabel("Role selection screen")
    }
}

// MARK: - Role Card Component

private struct RoleCard: View {
    let role: UserRole
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Icon
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .emerald)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.emerald : Color.emerald.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.titleMedium)
                        .foregroundColor(isSelected ? .white : .graphite)
                    
                    Text(description)
                        .font(.bodyMedium)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .gray600)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .gray400)
            }
            .padding(Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.emerald : Color.white)
                    .shadow(
                        color: isSelected ? .emerald.opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.emerald : Color.gray200, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title): \(description)")
        .accessibilityHint(isSelected ? "Selected" : "Tap to select this role")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    RoleSelectionView(
        user: UserProfile(
            id: "test-user",
            email: "john.doe@example.com",
            role: .customer
        )
    ) { role in
        print("Selected role: \(role)")
    }
}