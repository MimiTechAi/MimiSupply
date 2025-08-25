//
//  SecondaryButton.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Secondary button component with outline style, accessibility support and micro-interactions
struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    let accessibilityHint: String?
    let accessibilityIdentifier: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        accessibilityHint: String? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
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
                } else if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.labelLarge)
                        .foregroundColor(textColor)
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
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(12)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowOffset
            )
        }
        .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
        .disabled(isDisabled || isLoading)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // Empty action for long press
        } onPressingChanged: { pressing in
            withAnimation {
                isPressed = pressing
            }
        }
        .onHover { hovering in
            withAnimation {
                isHovered = hovering
            }
        }
        .accessibleButton(
            label: buttonAccessibilityLabel,
            hint: buttonAccessibilityHint,
            isEnabled: !isDisabled && !isLoading
        )
        .accessibilityIdentifier(accessibilityIdentifier ?? "secondary-button-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDisabled)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
    
    private func handleAction() {
        // Lighter haptic feedback for secondary button
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
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
    
    private var backgroundColor: Color {
        let baseColor: Color
        if isDisabled {
            baseColor = .gray100
        } else if isHovered {
            baseColor = .emerald.opacity(0.05)
        } else {
            baseColor = .clear
        }
        
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
    
    private var borderWidth: CGFloat {
        isHovered ? 2 : 1
    }
    
    private var shadowColor: Color {
        if isDisabled {
            return .clear
        } else if isHovered {
            return .emerald.opacity(0.2)
        } else {
            return .clear
        }
    }
    
    private var shadowRadius: CGFloat {
        isHovered ? 4 : 0
    }
    
    private var shadowOffset: CGFloat {
        isHovered ? 2 : 0
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        SecondaryButton(title: "Cancel", systemImage: "xmark") {
            print("Secondary button tapped")
        }
        
        SecondaryButton(title: "Loading", action: {}, isLoading: true)
        
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
        
        SecondaryButton(title: "Info", systemImage: "info.circle") {
            print("Info button tapped")
        }
    }
    .padding()
}