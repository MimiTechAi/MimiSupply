//
//  EmptyStateView.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Empty state view component with customizable content and actions
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    /// Convenience initializer for simple empty states without actions
    init(
        title: String,
        message: String,
        systemImage: String
    ) {
        self.icon = systemImage
        self.title = title
        self.message = message
        self.actionTitle = nil
        self.action = nil
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(iconColor)
                .accessibilityHidden(true)
            
            VStack(spacing: Spacing.sm * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
                Text(title)
                    .font(.titleLarge.scaledFont())
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
                    .accessibleHeading(label: title, level: .h2)
                
                Text(message)
                    .font(.bodyMedium.scaledFont())
                    .foregroundColor(messageColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .accessibilityLabel(message)
                    .accessibilityAddTraits(.isStaticText)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(
                    title: actionTitle, 
                    action: action,
                    accessibilityHint: "Tap to \(actionTitle.lowercased())"
                )
                .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isStaticText)
    }
    
    private var iconSize: CGFloat {
        let baseSize: CGFloat = 48
        return baseSize * accessibilityManager.preferredContentSizeCategory.scaleFactor
    }
    
    private var iconColor: Color {
        let baseColor = Color.gray400
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var titleColor: Color {
        let baseColor = Color.graphite
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var messageColor: Color {
        let baseColor = Color.gray600
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var accessibilityDescription: String {
        if let actionTitle = actionTitle {
            return "\(title). \(message). \(actionTitle) button available."
        } else {
            return "\(title). \(message)"
        }
    }
    
    private var accessibilityHint: String {
        if actionTitle != nil {
            return "Empty state with action available"
        } else {
            return "Empty state information"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        EmptyStateView(
            icon: "cart",
            title: "Your cart is empty",
            message: "Add some delicious items from local partners to get started.",
            actionTitle: "Browse Partners"
        ) {
            print("Browse partners tapped")
        }
        
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No results found",
            message: "Try adjusting your search or browse our featured partners."
        )
    }
    .padding()
}