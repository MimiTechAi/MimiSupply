//
//  SecondaryButton.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Secondary button component with outline style and accessibility support
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    let accessibilityHint: String?
    let accessibilityIdentifier: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        title: String,
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        accessibilityHint: String? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.accessibilityHint = accessibilityHint
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    var body: some View {
        Button(action: handleAction) {
            HStack(spacing: Spacing.sm * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                        .accessibilityHidden(true)
                }
                
                Text(title)
                    .font(.labelLarge.scaledFont())
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(accessibilityManager.isAccessibilitySize ? 3 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: max(44, Font.minimumTouchTarget * accessibilityManager.preferredContentSizeCategory.scaleFactor))
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .disabled(isDisabled || isLoading)
        .accessibleButton(
            label: buttonAccessibilityLabel,
            hint: buttonAccessibilityHint,
            traits: buttonAccessibilityTraits,
            value: isLoading ? "Loading" : nil
        )
        .switchControlAccessible(
            identifier: accessibilityIdentifier ?? "secondary-button-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            sortPriority: 0.8
        )
        .voiceControlAccessible(spokenPhrase: title)
        .keyboardAccessible(
            onTab: {
                AccessibilityFocusState.setFocus(to: "secondary-button")
            }
        )
        .reduceMotionAdaptive(
            animation: .spring(response: 0.3, dampingFraction: 0.7),
            value: isDisabled,
            alternativeAnimation: .easeInOut(duration: 0.1)
        )
    }
    
    private func handleAction() {
        if accessibilityManager.isAssistiveTechnologyEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        action()
    }
    
    private var buttonAccessibilityLabel: String {
        if isLoading {
            return "\(title), Loading"
        } else if isDisabled {
            return "\(title), Disabled"
        } else {
            return title
        }
    }
    
    private var buttonAccessibilityHint: String {
        if let customHint = accessibilityHint {
            return customHint
        } else if isLoading {
            return "Please wait while the action completes"
        } else if isDisabled {
            return "Button is currently disabled"
        } else {
            return "Double tap to activate"
        }
    }
    
    private var buttonAccessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = []
        
        if isLoading {
            _ = traits.insert(.updatesFrequently)
        }
        
        if isDisabled {
            _ = traits.insert(.isButton)
        }
        
        return traits
    }
    
    private var backgroundColor: Color {
        let baseColor: Color = isDisabled ? .gray100 : .clear
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var textColor: Color {
        let baseColor: Color = isDisabled ? .gray400 : .emerald
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var borderColor: Color {
        let baseColor: Color = isDisabled ? .gray300 : .emerald
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SecondaryButton(title: "Cancel") {
            print("Secondary button tapped")
        }
        
        SecondaryButton(title: "Loading", action: {}, isLoading: true)
        
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}