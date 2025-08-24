//
//  AccessibilityModifiers.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import UIKit

// MARK: - Basic Accessibility Modifiers

extension View {
    /// Basic accessibility setup for interactive elements
    func accessibleInteractive(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Setup for buttons with enhanced accessibility
    func accessibleButton(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true
    ) -> some View {
        self
            .accessibleInteractive(
                label: label,
                hint: hint ?? "Double tap to activate",
                traits: isEnabled ? [.isButton] : [.isButton, .notEnabled]
            )
    }
    
    /// Setup for text input fields
    func accessibleTextField(
        label: String,
        value: String,
        hint: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        self
            .accessibleInteractive(
                label: label,
                hint: hint ?? "Text field",
                value: value.isEmpty ? "Empty" : value,
                traits: isSecure ? [.isSearchField] : [.isSearchField]
            )
            .keyboardType(keyboardType)
    }
    
    /// Setup for headings
    func accessibleHeading(
        label: String? = nil,
        level: AccessibilityHeadingLevel = .h1
    ) -> some View {
        self
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(label ?? "")
            .accessibilityHeading(level)
    }
    
    /// Setup for images
    func accessibleImage(
        description: String,
        isDecorative: Bool = false
    ) -> some View {
        if isDecorative {
            return self.accessibilityHidden(true)
        } else {
            return self
                .accessibilityLabel(description)
                .accessibilityAddTraits(.isImage)
        }
    }
    
    /// Group related accessibility elements
    func accessibilityGroup(
        label: String? = nil,
        hint: String? = nil,
        combinedElements: Bool = true
    ) -> some View {
        Group {
            if combinedElements {
                self
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(label ?? "")
                    .accessibilityHint(hint ?? "")
            } else {
                self
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(label ?? "")
                    .accessibilityHint(hint ?? "")
            }
        }
    }
    
    /// High contrast aware styling
    func highContrastAware<Content: View>(
        normalBackground: Color,
        highContrastBackground: Color,
        normalForeground: Color? = nil,
        highContrastForeground: Color? = nil
    ) -> some View {
        let isDarkerColors = UIAccessibility.isDarkerSystemColorsEnabled
        
        return self
            .background(isDarkerColors ? highContrastBackground : normalBackground)
            .foregroundColor(
                isDarkerColors 
                    ? (highContrastForeground ?? .primary)
                    : (normalForeground ?? .primary)
            )
    }
    
    /// Apply transparency-aware opacity
    func transparencyAware(opacity: Double) -> some View {
        let adjustedOpacity = UIAccessibility.isReduceTransparencyEnabled ? 1.0 : opacity
        return self.opacity(adjustedOpacity)
    }
}

// MARK: - Motion-Aware Modifiers

extension View {
    /// Apply motion-aware animation
    func motionAwareAnimation(
        _ animation: Animation,
        value: some Equatable
    ) -> some View {
        let finalAnimation = UIAccessibility.isReduceMotionEnabled ? .linear(duration: 0.1) : animation
        return self.animation(finalAnimation, value: value)
    }
    
    /// Conditional animation based on motion preferences
    func conditionalAnimation(
        type: AccessibilityAnimationType,
        config: Animation,
        value: some Equatable
    ) -> some View {
        let shouldAnimate = !UIAccessibility.isReduceMotionEnabled || type.allowedWithReduceMotion
        let finalAnimation = shouldAnimate ? config : nil
        return self.animation(finalAnimation, value: value)
    }
}

// MARK: - Accessibility Animation Types (renamed to avoid conflicts)

enum AccessibilityAnimationType {
    case pageTransition
    case buttonPress
    case modalPresentation
    case listInsertion
    case shimmerEffect
    case pulseEffect
    case slideIn
    case fadeIn
    case scaleIn
    case rotation
    case parallax
    case backgroundVideo
    
    var allowedWithReduceMotion: Bool {
        switch self {
        case .pageTransition, .modalPresentation:
            return true // Essential for navigation
        case .buttonPress, .fadeIn:
            return true // Minimal motion
        case .shimmerEffect, .pulseEffect, .parallax, .backgroundVideo:
            return false // Decorative animations
        case .listInsertion, .slideIn, .scaleIn, .rotation:
            return false // Non-essential animations
        }
    }
}

// MARK: - VoiceOver Helpers

struct VoiceOverHelpers {
    /// Post an accessibility announcement
    static func announce(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Post a screen changed notification
    static func screenChanged(focusTo element: Any? = nil) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .screenChanged, argument: element)
        }
    }
    
    /// Post a layout changed notification
    static func layoutChanged(focusTo element: Any? = nil) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        }
    }
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if Switch Control is running
    static var isSwitchControlRunning: Bool {
        return UIAccessibility.isSwitchControlRunning
    }
    
    /// Check if AssistiveTouch is running
    static var isAssistiveTouchRunning: Bool {
        return UIAccessibility.isAssistiveTouchRunning
    }
}