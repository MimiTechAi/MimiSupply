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
    
    @StateObject private var dynamicTypeManager = DynamicTypeManager.shared
    @StateObject private var highContrastManager = HighContrastManager.shared
    @FocusState private var isFocused: Bool
    @State private var hasInteracted = false
    
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
        ResponsiveVStack(alignment: .leading, spacing: dynamicTypeManager.scaledSpacing(Spacing.xs)) {
            if !title.isEmpty {
                ResponsiveText(
                    title,
                    style: .subheadline,
                    weight: .medium
                )
                .foregroundColor(titleColor)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h3)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                }
            }
            .font(dynamicTypeManager.scaledFont(.body))
            .foregroundColor(textColor)
            .accessibilityPadding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(8)
            .keyboardType(keyboardType)
            .disabled(isDisabled)
            .accessibleTextField(
                label: fieldAccessibilityLabel,
                value: text,
                hint: fieldAccessibilityHint,
                isSecure: isSecure,
                keyboardType: keyboardType
            )
            .accessibilityIdentifier(accessibilityIdentifier ?? "textfield-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
            .accessibilityActions {
                if !text.isEmpty {
                    Button("Clear text") {
                        text = ""
                        if VoiceOverHelpers.isVoiceOverRunning {
                            VoiceOverHelpers.announce("Text cleared")
                        }
                    }
                }
            }
            .onChange(of: isFocused) { _, focused in
                if focused && !hasInteracted {
                    hasInteracted = true
                    if VoiceOverHelpers.isVoiceOverRunning {
                        VoiceOverHelpers.announce("Editing \(fieldAccessibilityLabel)")
                    }
                }
            }
            
            if let errorMessage = errorMessage {
                HStack(spacing: dynamicTypeManager.scaledSpacing(8)) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                        .accessibleImage(description: "Error", isDecorative: true)
                    
                    ResponsiveText(
                        errorMessage,
                        style: .caption,
                        weight: .medium
                    )
                    .foregroundColor(errorColor)
                    .multilineTextAlignment(.leading)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error: \(errorMessage)")
                .accessibilityAddTraits(.isStaticText)
                .accessibilityRemoveTraits(.isButton)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(containerAccessibilityLabel)
        .accessibilityHint(containerAccessibilityHint)
    }
    
    private var backgroundColor: Color {
        let baseColor: Color
        if isDisabled {
            baseColor = highContrastManager.backgroundColor(normal: .gray.opacity(0.1), highContrast: .gray.opacity(0.3))
        } else if isFocused {
            baseColor = highContrastManager.backgroundColor(normal: .white, highContrast: .white)
        } else {
            baseColor = highContrastManager.backgroundColor(normal: .white, highContrast: .white)
        }
        return baseColor
    }
    
    private var titleColor: Color {
        let baseColor: Color = isDisabled ? .gray : .primary
        return highContrastManager.foregroundColor(normal: baseColor, highContrast: .primary)
    }
    
    private var textColor: Color {
        let baseColor: Color = isDisabled ? .gray : .primary
        return highContrastManager.foregroundColor(normal: baseColor, highContrast: .primary)
    }
    
    private var borderColor: Color {
        let baseColor: Color
        if let _ = errorMessage {
            baseColor = .red
        } else if isFocused {
            baseColor = .emerald
        } else if isDisabled {
            baseColor = .gray.opacity(0.3)
        } else {
            baseColor = .gray.opacity(0.3)
        }
        return highContrastManager.foregroundColor(normal: baseColor, highContrast: baseColor)
    }
    
    private var borderWidth: CGFloat {
        if errorMessage != nil || isFocused {
            return highContrastManager.needsHighContrast ? 3 : 2
        } else {
            return highContrastManager.needsHighContrast ? 2 : 1
        }
    }
    
    private var errorColor: Color {
        return highContrastManager.foregroundColor(normal: .red, highContrast: .red)
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
            return "Error: \(errorMessage). \(baseAccessibilityHint)"
        } else {
            return baseAccessibilityHint
        }
    }
    
    private var baseAccessibilityHint: String {
        if let customHint = accessibilityHint {
            return customHint
        } else if isSecure {
            return "Secure text entry field"
        } else {
            return "Text input field"
        }
    }
    
    private var containerAccessibilityLabel: String {
        var label = fieldAccessibilityLabel
        if !text.isEmpty {
            label += ", current text: \(text)"
        }
        if isDisabled {
            label += ", disabled"
        }
        return label
    }
    
    private var containerAccessibilityHint: String {
        var hint = fieldAccessibilityHint
        if !text.isEmpty {
            hint += ". Double tap to edit."
        }
        return hint
    }
}

#Preview {
    ScrollView {
        ResponsiveVStack(spacing: Spacing.lg) {
            AppTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: .constant(""),
                keyboardType: .emailAddress,
                accessibilityHint: "Your email address for login"
            )
            
            AppTextField(
                title: "Password",
                placeholder: "Enter your password",
                text: .constant(""),
                isSecure: true,
                accessibilityHint: "Your account password"
            )
            
            AppTextField(
                title: "Search",
                placeholder: "Search products...",
                text: .constant("Sample text"),
                accessibilityHint: "Search for products in the catalog"
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
                errorMessage: "This field contains an invalid value. Please correct it."
            )
        }
        .accessibilityPadding()
    }
    .environment(\.dynamicTypeSize, .large)
}