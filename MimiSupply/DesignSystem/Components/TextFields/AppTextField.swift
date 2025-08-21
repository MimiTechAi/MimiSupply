//
//  AppTextField.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Reusable text field component with consistent styling and accessibility support
struct AppTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let isDisabled: Bool
    let errorMessage: String?
    let accessibilityHint: String?
    let accessibilityIdentifier: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        title: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        isDisabled: Bool = false,
        errorMessage: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.isDisabled = isDisabled
        self.errorMessage = errorMessage
        self.accessibilityHint = accessibilityHint
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs * accessibilityManager.preferredContentSizeCategory.spacingMultiplier) {
            if !title.isEmpty {
                Text(title)
                    .font(.labelMedium.scaledFont())
                    .foregroundColor(textColor)
                    .accessibleHeading(title, level: .h3)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.bodyMedium.scaledFont())
            .foregroundColor(textColor)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm * accessibilityManager.preferredContentSizeCategory.spacingMultiplier)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: accessibilityManager.isHighContrastEnabled ? 2 : 1)
                    )
            )
            .keyboardType(keyboardType)
            .disabled(isDisabled)
            .accessibleTextField(
                label: fieldAccessibilityLabel,
                value: text.isEmpty ? nil : text,
                hint: fieldAccessibilityHint,
                isSecure: isSecure
            )
            .switchControlAccessible(
                identifier: accessibilityIdentifier ?? "textfield-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))",
                sortPriority: 0.9
            )
            .keyboardAccessible()
            .accessibleErrorState(
                hasError: errorMessage != nil,
                errorMessage: errorMessage ?? ""
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption.scaledFont())
                    .foregroundColor(.error.highContrastVariant)
                    .accessibilityLabel("Error: \(errorMessage)")
                    .accessibilityAddTraits(.isStaticText)
            }
        }
    }
    
    private var backgroundColor: Color {
        let baseColor: Color = isDisabled ? .gray100 : .white
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var textColor: Color {
        let baseColor: Color = isDisabled ? .gray500 : .graphite
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var borderColor: Color {
        let baseColor: Color
        if let _ = errorMessage {
            baseColor = .error
        } else if isDisabled {
            baseColor = .gray300
        } else {
            baseColor = .gray300
        }
        return accessibilityManager.isHighContrastEnabled ? 
            baseColor.highContrastVariant : baseColor
    }
    
    private var fieldAccessibilityLabel: String {
        if !title.isEmpty {
            return title
        } else {
            return placeholder
        }
    }
    
    private var fieldAccessibilityHint: String {
        if let errorMessage = errorMessage {
            return "Error: \(errorMessage)"
        } else if let customHint = accessibilityHint {
            return customHint
        } else if isSecure {
            return "Secure text entry"
        } else {
            return "Text input field"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        AppTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant(""),
            keyboardType: .emailAddress
        )
        
        AppTextField(
            title: "Password",
            placeholder: "Enter your password",
            text: .constant(""),
            isSecure: true
        )
        
        AppTextField(
            title: "Search",
            placeholder: "Search products...",
            text: .constant("Sample text")
        )
        
        AppTextField(
            title: "Disabled Field",
            placeholder: "Cannot edit",
            text: .constant("Disabled"),
            isDisabled: true
        )
        
        AppTextField(
            title: "Error Field",
            placeholder: "Enter value",
            text: .constant("Invalid"),
            errorMessage: "This field has an error"
        )
    }
    .padding()
}