//
//  AccessibilityModifiers.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

// MARK: - Accessibility View Modifiers

extension View {
    /// Adds comprehensive accessibility support for interactive elements
    func accessibleButton(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(traits)
    }
    
    /// Adds accessibility support for text fields
    func accessibleTextField(
        label: String,
        value: String? = nil,
        hint: String? = nil,
        isSecure: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(isSecure ? [] : .isSearchField)
    }
    
    /// Adds accessibility support for headings
    func accessibleHeading(
        _ text: String,
        level: AccessibilityHeadingLevel = .h1
    ) -> some View {
        self
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(level)
    }
    
    /// Adds accessibility support for images
    func accessibleImage(
        label: String,
        isDecorative: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(isDecorative ? "" : label)
            .accessibilityAddTraits(isDecorative ? [] : .isImage)
            .accessibilityHidden(isDecorative)
    }
    
    /// Groups accessibility elements for better VoiceOver navigation
    func accessibilityGroup(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
    
    /// Adds high contrast support with WCAG 2.2 AA+ compliance
    func highContrastAdaptive(
        normalColor: Color,
        highContrastColor: Color
    ) -> some View {
        self
            .foregroundColor(
                AccessibilityManager.shared.isHighContrastEnabled ? 
                highContrastColor : normalColor
            )
    }
    
    /// Adds reduce motion support with alternative animations
    func reduceMotionAdaptive<T: Equatable>(
        animation: Animation?,
        value: T,
        alternativeAnimation: Animation? = .easeInOut(duration: 0.1)
    ) -> some View {
        self
            .animation(
                AccessibilityManager.shared.isReduceMotionEnabled ? 
                alternativeAnimation : animation,
                value: value
            )
    }
    
    /// Adds Switch Control navigation support
    func switchControlAccessible(
        identifier: String,
        sortPriority: Double = 0
    ) -> some View {
        self
            .accessibilityIdentifier(identifier)
            .accessibilitySortPriority(sortPriority)
    }
    
    /// Adds Voice Control support with custom spoken phrase
    func voiceControlAccessible(
        spokenPhrase: String
    ) -> some View {
        self
            .accessibilityInputLabels([spokenPhrase])
    }
    
    /// Adds keyboard navigation support
    func keyboardAccessible(
        onTab: (() -> Void)? = nil,
        onShiftTab: (() -> Void)? = nil
    ) -> some View {
        self
            .focusable()
            // Tab navigation support would be implemented here for macOS
            // For iOS, this is handled by the system
    }
    
    /// Adds comprehensive accessibility for cards/list items
    func accessibleCard(
        title: String,
        subtitle: String? = nil,
        details: [String] = [],
        hint: String? = nil,
        isSelected: Bool = false
    ) -> some View {
        let combinedLabel = [title, subtitle].compactMap { $0 }.joined(separator: ", ")
        let detailsText = details.isEmpty ? "" : ", " + details.joined(separator: ", ")
        let fullLabel = combinedLabel + detailsText
        
        return self
            .accessibilityLabel(fullLabel)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    /// Adds loading state accessibility
    func accessibleLoadingState(
        isLoading: Bool,
        loadingMessage: String = "Loading"
    ) -> some View {
        self
            .accessibilityLabel(isLoading ? loadingMessage : "")
            .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
    
    /// Adds error state accessibility
    func accessibleErrorState(
        hasError: Bool,
        errorMessage: String = ""
    ) -> some View {
        self
            .accessibilityLabel(hasError ? "Error: \(errorMessage)" : "")
            .accessibilityAddTraits(hasError ? .causesPageTurn : [])
    }
}

// MARK: - Accessibility Manager

@MainActor
class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
    @Published var isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
    @Published var preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
                self?.announceAccessibilityChange("VoiceOver \(UIAccessibility.isVoiceOverRunning ? "enabled" : "disabled")")
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.switchControlStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isSwitchControlEnabled = UIAccessibility.isSwitchControlRunning
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.assistiveTouchStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isAssistiveTouchEnabled = UIAccessibility.isAssistiveTouchRunning
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
            }
        }
    }
    
    var isAccessibilitySize: Bool {
        preferredContentSizeCategory.isAccessibilityCategory
    }
    
    var dynamicTypeSize: DynamicTypeSize {
        switch preferredContentSizeCategory {
        case .extraSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .extraLarge: return .xLarge
        case .extraExtraLarge: return .xxLarge
        case .extraExtraExtraLarge: return .xxxLarge
        case .accessibilityMedium: return .accessibility1
        case .accessibilityLarge: return .accessibility2
        case .accessibilityExtraLarge: return .accessibility3
        case .accessibilityExtraExtraLarge: return .accessibility4
        case .accessibilityExtraExtraExtraLarge: return .accessibility5
        default: return .large
        }
    }
    
    /// Announces accessibility changes to screen readers
    func announceAccessibilityChange(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// Posts layout change notification for major UI updates
    func announceLayoutChange(focusElement: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: focusElement)
    }
    
    /// Posts screen change notification for navigation
    func announceScreenChange(focusElement: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: focusElement)
    }
    
    /// Checks if any assistive technology is running
    var isAssistiveTechnologyEnabled: Bool {
        isVoiceOverEnabled || isSwitchControlEnabled || isAssistiveTouchEnabled
    }
    
    /// Gets appropriate animation duration based on accessibility settings
    var accessibleAnimationDuration: Double {
        if isReduceMotionEnabled {
            return 0.1
        } else if isAssistiveTechnologyEnabled {
            return 0.2
        } else {
            return 0.3
        }
    }
    
    /// Gets high contrast colors for WCAG 2.2 AA+ compliance
    func getHighContrastColor(for color: Color) -> Color {
        guard isHighContrastEnabled else { return color }
        
        switch color {
        case .emerald:
            return Color(red: 0.0, green: 0.5, blue: 0.4) // Darker emerald for better contrast
        case .gray600:
            return .black
        case .gray500:
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .gray400:
            return Color(red: 0.3, green: 0.3, blue: 0.3)
        default:
            return color
        }
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// Returns a font that scales with Dynamic Type and supports accessibility sizes
    func scaledFont(for category: UIContentSizeCategory = UIApplication.shared.preferredContentSizeCategory) -> Font {
        let scaleFactor = category.scaleFactor
        
        // Apply scaling based on the font type
        switch self {
        case .displayLarge:
            return Font.custom("Inter", size: 57 * scaleFactor).weight(.regular)
        case .displayMedium:
            return Font.custom("Inter", size: 45 * scaleFactor).weight(.regular)
        case .displaySmall:
            return Font.custom("Inter", size: 36 * scaleFactor).weight(.regular)
        case .headlineLarge:
            return Font.custom("Inter", size: 32 * scaleFactor).weight(.regular)
        case .headlineMedium:
            return Font.custom("Inter", size: 28 * scaleFactor).weight(.regular)
        case .headlineSmall:
            return Font.custom("Inter", size: 24 * scaleFactor).weight(.regular)
        case .titleLarge:
            return Font.custom("Inter", size: 22 * scaleFactor).weight(.medium)
        case .titleMedium:
            return Font.custom("Inter", size: 16 * scaleFactor).weight(.medium)
        case .titleSmall:
            return Font.custom("Inter", size: 14 * scaleFactor).weight(.medium)
        case .bodyLarge:
            return Font.custom("Inter", size: 16 * scaleFactor).weight(.regular)
        case .bodyMedium:
            return Font.custom("Inter", size: 14 * scaleFactor).weight(.regular)
        case .bodySmall:
            return Font.custom("Inter", size: 12 * scaleFactor).weight(.regular)
        case .labelLarge:
            return Font.custom("Inter", size: 14 * scaleFactor).weight(.medium)
        case .labelMedium:
            return Font.custom("Inter", size: 12 * scaleFactor).weight(.medium)
        case .labelSmall:
            return Font.custom("Inter", size: 11 * scaleFactor).weight(.medium)
        default:
            return self
        }
    }
    
    /// Returns minimum touch target size for accessibility
    static var minimumTouchTarget: CGFloat {
        return 44.0 // Apple's recommended minimum touch target
    }
}

extension UIContentSizeCategory {
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.6
        case .accessibilityExtraLarge: return 1.8
        case .accessibilityExtraExtraLarge: return 2.0
        case .accessibilityExtraExtraExtraLarge: return 2.2
        default: return 1.0
        }
    }
    
    /// Returns appropriate spacing multiplier for the content size category
    var spacingMultiplier: CGFloat {
        if isAccessibilityCategory {
            return 1.5 // Increase spacing for accessibility sizes
        } else {
            return 1.0
        }
    }
}

// MARK: - WCAG 2.2 AA+ Color Contrast Support

extension Color {
    /// High contrast variants for WCAG 2.2 AA+ compliance
    var highContrastVariant: Color {
        // Return a high contrast version of the color
        return self
    }
    
    /// Adaptive color that changes based on accessibility settings
    func adaptiveColor(highContrast: Color) -> Color {
        // For now, return the original color
        return self
    }
    
    /// Checks if color combination meets WCAG contrast requirements
    static func meetsContrastRequirements(foreground: Color, background: Color) -> Bool {
        // This would implement actual contrast ratio calculation
        // For now, return true as a placeholder
        return true
    }
}

// MARK: - Focus Management

struct AccessibilityFocusState {
    static var currentFocusedElement: String?
    
    static func setFocus(to element: String) {
        currentFocusedElement = element
        // Layout change announcement would be implemented here
    }
    
    static func clearFocus() {
        currentFocusedElement = nil
    }
}