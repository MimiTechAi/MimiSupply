//
//  PrimaryButton.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Primary button component with comprehensive accessibility support
struct PrimaryButton: View {
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
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .accessibilityHidden(true)
                }
                
                Text(title)
                    .font(.labelLarge.scaledFont())
                    .foregroundColor(.white)
                    .rtlTextAlignment()
                    .lineLimit(accessibilityManager.isAccessibilitySize ? 3 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: max(44, Font.minimumTouchTarget * accessibilityManager.preferredContentSizeCategory.scaleFactor))
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .disabled(isDisabled || isLoading)
        .accessibleButton(
            label: buttonAccessibilityLabel,
            hint: buttonAccessibilityHint,
            traits: buttonAccessibilityTraits,
            value: isLoading ? LocalizationKeys.Common.loading.localized : nil
        )
        .switchControlAccessible(
            identifier: accessibilityIdentifier ?? "primary-button-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
            sortPriority: 1.0
        )
        .voiceControlAccessible(spokenPhrase: title)
        .keyboardAccessible(
            onTab: {
                // Handle tab navigation
                AccessibilityFocusState.setFocus(to: "primary-button")
            }
        )
        .reduceMotionAdaptive(
            animation: .spring(response: 0.3, dampingFraction: 0.7),
            value: isDisabled,
            alternativeAnimation: .easeInOut(duration: 0.1)
        )
        .rtlAware()
        .observeLanguageChanges()
    }
    
    private func handleAction() {
        // Provide haptic feedback for accessibility
        if accessibilityManager.isAssistiveTechnologyEnabled {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        action()
    }
    
    private var backgroundColor: Color {
        let baseColor: Color
        if isDisabled {
            baseColor = .gray400
        } else {
            baseColor = .emerald
        }
        
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
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
            return "accessibility.button.loading_hint".localized
        } else if isDisabled {
            return "accessibility.button.disabled_hint".localized
        } else {
            return "accessibility.button.activate_hint".localized
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
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Continue") {
            print("Primary button tapped")
        }
        
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
        
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}