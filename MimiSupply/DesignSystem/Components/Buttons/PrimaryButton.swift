//
//  PrimaryButton.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Primary button component with comprehensive accessibility support and micro-interactions
struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    let hapticType: HapticFeedbackType
    let hapticContext: HapticContext
    let accessibilityHint: String?
    let accessibilityIdentifier: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var isPressed = false
    @State private var successAnimation = false
    
    init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        hapticType: HapticFeedbackType = .buttonTap,
        hapticContext: HapticContext = .ui,
        accessibilityHint: String? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.hapticType = hapticType
        self.hapticContext = hapticContext
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
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.labelLarge)
                        .foregroundColor(.white)
                        .scaleEffect(successAnimation ? 1.2 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: successAnimation)
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
            .cornerRadius(12)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .brightness(isPressed ? -0.1 : 0.0)
        .disabled(isDisabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // Empty action for long press
        } onPressingChanged: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }
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
        // Provide contextual haptic feedback
        HapticManager.shared.trigger(hapticType, context: hapticContext)
        
        // Trigger success animation if there's an icon
        if systemImage != nil {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                successAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    successAnimation = false
                }
            }
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
    
    private var shadowColor: Color {
        if isDisabled {
            return .clear
        } else {
            return .emerald.opacity(isPressed ? 0.2 : 0.3)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDisabled {
            return 0
        } else {
            return isPressed ? 2 : 4
        }
    }
    
    private var shadowOffset: CGFloat {
        if isDisabled {
            return 0
        } else {
            return isPressed ? 1 : 2
        }
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

// MARK: - Convenience Initializers
extension PrimaryButton {
    // Commerce context buttons
    static func addToCart(title: String = "Add to Cart", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "cart.badge.plus",
            action: action,
            hapticType: .addToCart,
            hapticContext: .commerce
        )
    }
    
    static func checkout(title: String = "Checkout", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "creditcard",
            action: action,
            hapticType: .paymentSuccess,
            hapticContext: .commerce
        )
    }
    
    // Analytics context buttons
    static func generateReport(title: String = "Generate Report", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "doc.text",
            action: action,
            hapticType: .reportGenerated,
            hapticContext: .analytics
        )
    }
    
    static func exportData(title: String = "Export", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "square.and.arrow.up",
            action: action,
            hapticType: .exportComplete,
            hapticContext: .analytics
        )
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        PrimaryButton(title: "Continue", systemImage: "arrow.right") {
            print("Primary button tapped")
        }
        
        PrimaryButton.addToCart {
            print("Added to cart")
        }
        
        PrimaryButton.generateReport {
            print("Report generated")
        }
        
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
        
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}