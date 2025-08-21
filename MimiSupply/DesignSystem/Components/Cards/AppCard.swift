//
//  AppCard.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Reusable card component with consistent styling and accessibility support
struct AppCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOffset: CGSize
    let shadowOpacity: Double
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let isInteractive: Bool
    let onTap: (() -> Void)?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        padding: CGFloat = Spacing.md,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 4,
        shadowOffset: CGSize = CGSize(width: 0, height: 2),
        shadowOpacity: Double = 0.1,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        isInteractive: Bool = false,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOffset = shadowOffset
        self.shadowOpacity = shadowOpacity
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.isInteractive = isInteractive
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if isInteractive, let onTap = onTap {
                Button(action: onTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
                .accessibleButton(
                    label: accessibilityLabel ?? "Card",
                    hint: accessibilityHint ?? "Double tap to interact"
                )
            } else {
                cardContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityLabel ?? "")
                    .accessibilityHint(accessibilityHint ?? "")
            }
        }
    }
    
    private var cardContent: some View {
        content
            .padding(padding * accessibilityManager.preferredContentSizeCategory.spacingMultiplier)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowColor,
                radius: accessibilityManager.isReduceMotionEnabled ? 0 : shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
    }
    
    private var backgroundColor: Color {
        let baseColor = Color.white
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var shadowColor: Color {
        let opacity = accessibilityManager.isHighContrastEnabled ? shadowOpacity * 1.5 : shadowOpacity
        return .black.opacity(opacity)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Card Title")
                    .font(.titleMedium)
                    .foregroundColor(.graphite)
                
                Text("This is a sample card with some content to demonstrate the card component styling.")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
            }
        }
        
        AppCard(padding: Spacing.sm, cornerRadius: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.warning)
                Text("Compact Card")
                    .font(.labelMedium)
                    .foregroundColor(.graphite)
                Spacer()
            }
        }
    }
    .padding()
    .background(Color.gray50)
}