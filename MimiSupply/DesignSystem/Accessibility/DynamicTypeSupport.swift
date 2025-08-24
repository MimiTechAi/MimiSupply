//
//  DynamicTypeSupport.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import UIKit
import Combine

/// Service for managing Dynamic Type support throughout the app
@MainActor
final class DynamicTypeManager: ObservableObject {
    static let shared = DynamicTypeManager()
    
    @Published var currentContentSizeCategory: ContentSizeCategory = ContentSizeCategory.large
    @Published var isAccessibilitySize: Bool = false
    @Published var preferredContentSizeCategory: UIContentSizeCategory = .large
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        updateCurrentSettings()
        setupContentSizeCategoryMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Get scaled font for given text style
    func scaledFont(
        _ textStyle: Font.TextStyle,
        design: Font.Design = .default,
        weight: Font.Weight = .regular
    ) -> Font {
        return Font.system(textStyle, design: design, weight: weight)
    }
    
    /// Get scaled UIFont for UIKit components
    func scaledUIFont(
        _ textStyle: UIFont.TextStyle,
        weight: UIFont.Weight = .regular,
        maximumPointSize: CGFloat? = nil
    ) -> UIFont {
        let font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight)
        
        if let maxSize = maximumPointSize {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font, maximumPointSize: maxSize)
        } else {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
        }
    }
    
    /// Get appropriate spacing for current content size
    func scaledSpacing(_ baseSpacing: CGFloat) -> CGFloat {
        let multiplier = contentSizeMultiplier()
        return baseSpacing * multiplier
    }
    
    /// Get appropriate padding for current content size
    func scaledPadding(_ basePadding: CGFloat) -> CGFloat {
        let multiplier = contentSizeMultiplier()
        return basePadding * multiplier
    }
    
    /// Check if current size is an accessibility size
    func isCurrentSizeAccessibility() -> Bool {
        return preferredContentSizeCategory.isAccessibilityCategory
    }
    
    /// Get content size multiplier for scaling
    private func contentSizeMultiplier() -> CGFloat {
        switch preferredContentSizeCategory {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 0.95
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
    
    // MARK: - Private Methods
    
    private func setupContentSizeCategoryMonitoring() {
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateCurrentSettings()
            }
            .store(in: &cancellables)
    }
    
    private func updateCurrentSettings() {
        preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
        isAccessibilitySize = preferredContentSizeCategory.isAccessibilityCategory
        
        // Convert to SwiftUI ContentSizeCategory
        currentContentSizeCategory = ContentSizeCategory(preferredContentSizeCategory)
    }
}

// MARK: - ContentSizeCategory Extension

extension ContentSizeCategory {
    init(_ uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        default: self = .large
        }
    }
}

// MARK: - Dynamic Type View Modifiers

extension View {
    /// Apply dynamic type scaling to the view
    func dynamicTypeScaled(
        minSize: DynamicTypeSize = .xSmall,
        maxSize: DynamicTypeSize = .accessibility5
    ) -> some View {
        self.dynamicTypeSize(minSize...maxSize)
    }
    
    /// Apply accessibility-aware spacing
    func accessibilitySpacing(_ spacing: CGFloat) -> some View {
        let scaledSpacing = DynamicTypeManager.shared.scaledSpacing(spacing)
        return self.padding(scaledSpacing)
    }
    
    /// Apply accessibility-aware padding
    func accessibilityPadding(_ padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)) -> some View {
        let manager = DynamicTypeManager.shared
        let scaledPadding = EdgeInsets(
            top: manager.scaledPadding(padding.top),
            leading: manager.scaledPadding(padding.leading),
            bottom: manager.scaledPadding(padding.bottom),
            trailing: manager.scaledPadding(padding.trailing)
        )
        return self.padding(scaledPadding)
    }
    
    /// Layout adjustment for accessibility sizes
    func accessibilityLayout<AccessibilityContent: View>(
        @ViewBuilder accessibilityContent: () -> AccessibilityContent
    ) -> some View {
        Group {
            if DynamicTypeManager.shared.isCurrentSizeAccessibility() {
                accessibilityContent()
            } else {
                self
            }
        }
    }
}

// MARK: - Responsive Text Components

struct ResponsiveText: View {
    let text: String
    let textStyle: Font.TextStyle
    let design: Font.Design
    let weight: Font.Weight
    let alignment: TextAlignment
    let lineLimit: Int?
    let minimumScaleFactor: CGFloat
    
    @StateObject private var dynamicTypeManager = DynamicTypeManager.shared
    
    init(
        _ text: String,
        style: Font.TextStyle = .body,
        design: Font.Design = .default,
        weight: Font.Weight = .regular,
        alignment: TextAlignment = .leading,
        lineLimit: Int? = nil,
        minimumScaleFactor: CGFloat = 0.5
    ) {
        self.text = text
        self.textStyle = style
        self.design = design
        self.weight = weight
        self.alignment = alignment
        self.lineLimit = lineLimit
        self.minimumScaleFactor = minimumScaleFactor
    }
    
    var body: some View {
        Text(text)
            .font(dynamicTypeManager.scaledFont(textStyle, design: design, weight: weight))
            .multilineTextAlignment(alignment)
            .lineLimit(lineLimit)
            .minimumScaleFactor(minimumScaleFactor)
            .dynamicTypeScaled()
    }
}

// MARK: - Responsive Layout Containers

struct ResponsiveVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let content: Content
    
    @StateObject private var dynamicTypeManager = DynamicTypeManager.shared
    
    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: scaledSpacing) {
            content
        }
    }
    
    private var scaledSpacing: CGFloat? {
        guard let spacing = spacing else { return nil }
        return dynamicTypeManager.scaledSpacing(spacing)
    }
}

struct ResponsiveHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content
    
    @StateObject private var dynamicTypeManager = DynamicTypeManager.shared
    
    init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        Group {
            if dynamicTypeManager.isCurrentSizeAccessibility() {
                // Switch to VStack for accessibility sizes
                VStack(alignment: .leading, spacing: scaledSpacing) {
                    content
                }
            } else {
                HStack(alignment: alignment, spacing: scaledSpacing) {
                    content
                }
            }
        }
    }
    
    private var scaledSpacing: CGFloat? {
        guard let spacing = spacing else { return nil }
        return dynamicTypeManager.scaledSpacing(spacing)
    }
}

// MARK: - High Contrast Support

@MainActor
final class HighContrastManager: ObservableObject {
    static let shared = HighContrastManager()
    
    @Published var isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
    @Published var isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupHighContrastMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Get appropriate background color for high contrast
    func backgroundColor(normal: Color, highContrast: Color) -> Color {
        return isDarkerSystemColorsEnabled ? highContrast : normal
    }
    
    /// Get appropriate foreground color for high contrast
    func foregroundColor(normal: Color, highContrast: Color) -> Color {
        return isDarkerSystemColorsEnabled ? highContrast : normal
    }
    
    /// Check if high contrast is needed
    var needsHighContrast: Bool {
        return isDarkerSystemColorsEnabled || isInvertColorsEnabled
    }
    
    // MARK: - Private Methods
    
    private func setupHighContrastMonitoring() {
        NotificationCenter.default.publisher(for: UIAccessibility.darkerSystemColorsStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.invertColorsStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isInvertColorsEnabled = UIAccessibility.isInvertColorsEnabled
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.reduceTransparencyStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isReduceTransparencyEnabled = UIAccessibility.isReduceTransparencyEnabled
            }
            .store(in: &cancellables)
    }
}

// MARK: - High Contrast View Modifiers

extension View {
    /// Apply high contrast aware colors
    func highContrastAware(
        normalBackground: Color,
        highContrastBackground: Color,
        normalForeground: Color? = nil,
        highContrastForeground: Color? = nil
    ) -> some View {
        let manager = HighContrastManager.shared
        
        return self
            .background(manager.backgroundColor(normal: normalBackground, highContrast: highContrastBackground))
            .foregroundColor(
                manager.foregroundColor(
                    normal: normalForeground ?? .primary,
                    highContrast: highContrastForeground ?? .primary
                )
            )
    }
}

// MARK: - Preview

struct DynamicTypeSupport_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ResponsiveVStack(spacing: 16) {
                ResponsiveText("Dynamic Type Demo", style: .largeTitle, weight: .bold)
                
                ResponsiveText(
                    "This text will scale with the user's preferred text size settings. It demonstrates how content adapts to accessibility needs.",
                    style: .body,
                    lineLimit: nil
                )
                
                ResponsiveHStack(spacing: 12) {
                    Button("Button 1") {}
                        .foregroundColor(.white)
                        .accessibilityPadding()
                        .background(Color.emerald)
                        .cornerRadius(8)
                    
                    Button("Button 2") {}
                        .foregroundColor(.white)
                        .accessibilityPadding()
                        .background(Color.teal)
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ResponsiveText("High Contrast Demo", style: .headline, weight: .semibold)
                    
                    Text("This content adapts to high contrast settings")
                        .font(.body)
                        .highContrastAware(
                            normalBackground: Color.gray.opacity(0.1),
                            highContrastBackground: Color.black,
                            normalForeground: Color.primary,
                            highContrastForeground: Color.white
                        )
                        .padding()
                        .cornerRadius(8)
                }
            }
            .accessibilityPadding()
        }
        .environment(\.dynamicTypeSize, .accessibility1)
    }
}