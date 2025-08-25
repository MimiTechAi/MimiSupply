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
    
    @StateObject private var motionManager = MotionManager.shared
    @StateObject private var dynamicTypeManager = DynamicTypeManager.shared
    @StateObject private var highContrastManager = HighContrastManager.shared
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
            ResponsiveHStack(spacing: dynamicTypeManager.scaledSpacing(Spacing.sm)) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                        .accessibilityHidden(true)
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(dynamicTypeManager.scaledFont(.body, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(successAnimation ? 1.2 : 1.0)
                        .conditionalAnimation(
                            type: .scaleIn,
                            config: .spring,
                            value: successAnimation
                        )
                        .accessibleImage(
                            description: "\(title) icon",
                            isDecorative: true
                        )
                }
                
                ResponsiveText(
                    title,
                    style: .headline,
                    weight: .semibold
                )
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(dynamicTypeManager.isCurrentSizeAccessibility() ? 3 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: max(44, dynamicTypeManager.scaledSpacing(44)))
            .accessibilityPadding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .background(backgroundColor)
            .cornerRadius(12)
            .transparencyAware(opacity: isDisabled ? 0.6 : 1.0)
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
        .motionAwareAnimation(.spring(), value: isPressed)
        .motionAwareAnimation(MotionManager.AnimationConfig.default.animation, value: isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // Empty action for long press
        } onPressingChanged: { pressing in
            if motionManager.shouldAnimate(type: .buttonPress) {
                motionManager.withAnimation(.spring) {
                    isPressed = pressing
                }
            }
        }
        .accessibleButton(
            label: buttonAccessibilityLabel,
            hint: buttonAccessibilityHint,
            isEnabled: !isDisabled && !isLoading
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(accessibilityIdentifier ?? "primary-button-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
        .accessibilityValue(isLoading ? "Loading" : "")
        .accessibilityActions {
            Button("Activate") {
                if !isDisabled && !isLoading {
                    handleAction()
                }
            }
        }
    }
    
    private func handleAction() {
        // Announce action for VoiceOver users
        if VoiceOverHelpers.isVoiceOverRunning {
            VoiceOverHelpers.announce("\(title) activated")
        }
        
        // Provide contextual haptic feedback
        let intensity = motionManager.hapticIntensity()
        HapticManager.shared.trigger(.mediumImpact)
        
        // Trigger success animation if there's an icon
        if systemImage != nil && motionManager.shouldAnimate(type: .scaleIn) {
            motionManager.withAnimation(.spring) {
                successAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                motionManager.withAnimation(.spring) {
                    successAnimation = false
                }
            }
        }
        
        action()
    }
    
    private var backgroundColor: Color {
        let baseColor: Color = isDisabled ? .gray : .emerald
        return highContrastManager.backgroundColor(
            normal: baseColor,
            highContrast: isDisabled ? .black : .emerald
        )
    }
    
    private var shadowColor: Color {
        if isDisabled || motionManager.reduceMotionEnabled {
            return .clear
        } else {
            return highContrastManager.backgroundColor(
                normal: .emerald.opacity(isPressed ? 0.2 : 0.3),
                highContrast: .clear
            )
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDisabled || motionManager.reduceMotionEnabled {
            return 0
        } else {
            return isPressed ? 2 : 4
        }
    }
    
    private var shadowOffset: CGFloat {
        if isDisabled || motionManager.reduceMotionEnabled {
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
            return "Please wait while the action completes"
        } else if isDisabled {
            return "This button is currently disabled"
        } else {
            return "Double tap to activate"
        }
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
            hapticContext: .commerce,
            accessibilityHint: "Adds item to your shopping cart"
        )
    }
    
    static func checkout(title: String = "Checkout", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "creditcard",
            action: action,
            hapticType: .paymentSuccess,
            hapticContext: .commerce,
            accessibilityHint: "Proceed to payment and complete your order"
        )
    }
    
    // Analytics context buttons
    static func generateReport(title: String = "Generate Report", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "doc.text",
            action: action,
            hapticType: .reportGenerated,
            hapticContext: .analytics,
            accessibilityHint: "Creates a new analytical report"
        )
    }
    
    static func exportData(title: String = "Export", action: @escaping () -> Void) -> PrimaryButton {
        PrimaryButton(
            title: title,
            systemImage: "square.and.arrow.up",
            action: action,
            hapticType: .exportComplete,
            hapticContext: .analytics,
            accessibilityHint: "Export data to external application"
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