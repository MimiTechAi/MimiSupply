//
//  Color+Extensions.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

extension Color {
    
    // MARK: - Primary Colors (Legacy - Maintained for backwards compatibility)
    static let emerald = Color(hex: "1E9E8B")      // Primary brand
    static let chalk = Color(hex: "F9F9F5")        // Background
    static let graphite = Color(hex: "333333")     // Text primary
    
    // MARK: - Semantic Colors with Dynamic Support
    static let success = Color.dynamic(
        light: Color(hex: "10B981"),
        dark: Color(hex: "34D399")
    )
    
    static let warning = Color.dynamic(
        light: Color(hex: "F59E0B"),
        dark: Color(hex: "FBBF24")
    )
    
    static let error = Color.dynamic(
        light: Color(hex: "EF4444"),
        dark: Color(hex: "F87171")
    )
    
    static let info = Color.dynamic(
        light: Color(hex: "3B82F6"),
        dark: Color(hex: "60A5FA")
    )
    
    // MARK: - Neutral Grays with Dark Mode Support
    static let gray50 = Color.dynamic(
        light: Color(hex: "F9FAFB"),
        dark: Color(hex: "1F2937")
    )
    
    static let gray100 = Color.dynamic(
        light: Color(hex: "F3F4F6"),
        dark: Color(hex: "374151")
    )
    
    static let gray200 = Color.dynamic(
        light: Color(hex: "E5E7EB"),
        dark: Color(hex: "4B5563")
    )
    
    static let gray300 = Color.dynamic(
        light: Color(hex: "D1D5DB"),
        dark: Color(hex: "6B7280")
    )
    
    static let gray400 = Color.dynamic(
        light: Color(hex: "9CA3AF"),
        dark: Color(hex: "9CA3AF")
    )
    
    static let gray500 = Color.dynamic(
        light: Color(hex: "6B7280"),
        dark: Color(hex: "D1D5DB")
    )
    
    static let gray600 = Color.dynamic(
        light: Color(hex: "4B5563"),
        dark: Color(hex: "E5E7EB")
    )
    
    static let gray700 = Color.dynamic(
        light: Color(hex: "374151"),
        dark: Color(hex: "F3F4F6")
    )
    
    static let gray800 = Color.dynamic(
        light: Color(hex: "1F2937"),
        dark: Color(hex: "F9FAFB")
    )
    
    static let gray900 = Color.dynamic(
        light: Color(hex: "111827"),
        dark: Color(hex: "FFFFFF")
    )
    
    // MARK: - Dynamic Color Creation
    static func dynamic(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // MARK: - Enhanced Hex Initializer with Alpha Support
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Color Manipulation
    func lighter(by amount: Double = 0.2) -> Color {
        return self.opacity(1.0 - amount)
    }
    
    func darker(by amount: Double = 0.2) -> Color {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else { return self }
        
        let red = max(0, components[0] - amount)
        let green = max(0, components[1] - amount)
        let blue = max(0, components[2] - amount)
        let alpha = components.count > 3 ? components[3] : 1.0
        
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    func withSaturation(_ saturation: Double) -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var currentSaturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &currentSaturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
    
    // MARK: - High Contrast Support
    var highContrastVariant: Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return self.darker(by: 0.1)
        } else {
            return self
        }
    }
    
    // MARK: - Accessibility Helpers
    var accessibleColor: Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return self.highContrastVariant
        }
        
        if UIAccessibility.isReduceTransparencyEnabled {
            return Color(UIColor(self).withAlphaComponent(1.0))
        }
        
        return self
    }
    
    // MARK: - Business Intelligence Color Palette
    static let analyticsBlue = Color.dynamic(
        light: Color(hex: "3B82F6"),
        dark: Color(hex: "60A5FA")
    )
    
    static let analyticsPurple = Color.dynamic(
        light: Color(hex: "8B5CF6"),
        dark: Color(hex: "A78BFA")
    )
    
    static let analyticsOrange = Color.dynamic(
        light: Color(hex: "F97316"),
        dark: Color(hex: "FB923C")
    )
    
    static let analyticsPink = Color.dynamic(
        light: Color(hex: "EC4899"),
        dark: Color(hex: "F472B6")
    )
    
    static let analyticsGreen = Color.dynamic(
        light: Color(hex: "10B981"),
        dark: Color(hex: "34D399")
    )
    
    // MARK: - Chart Colors
    static let chartColors: [Color] = [
        .analyticsBlue,
        .analyticsPurple,
        .analyticsOrange,
        .analyticsPink,
        .analyticsGreen,
        .warning,
        .info
    ]
    
    // MARK: - Elevated Surface Colors
    static func elevatedSurface(level: Int = 1) -> Color {
        let baseOpacity = 0.05
        let opacity = baseOpacity * Double(level)
        
        return Color.dynamic(
            light: Color.black.opacity(opacity),
            dark: Color.white.opacity(opacity)
        )
    }
    
    // MARK: - Shadow Colors
    static var adaptiveShadow: Color {
        return Color.dynamic(
            light: Color.black.opacity(0.1),
            dark: Color.black.opacity(0.3)
        )
    }
    
    // MARK: - Gradient Helpers
    static func gradient(from startColor: Color, to endColor: Color, startPoint: UnitPoint = .topLeading, endPoint: UnitPoint = .bottomTrailing) -> LinearGradient {
        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    static var brandGradient: LinearGradient {
        return gradient(from: .emerald, to: .emerald.lighter(by: 0.2))
    }
    
    static var analyticsGradient: LinearGradient {
        return gradient(from: .analyticsBlue, to: .analyticsPurple)
    }
    
    // MARK: - Theme-Aware Colors
    static func themed(_ colorProvider: @escaping (AppTheme) -> Color) -> Color {
        let theme = ThemeManager.shared.currentTheme
        return colorProvider(theme)
    }
}

// MARK: - SwiftUI Environment Integration
struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.colorScheme, effectiveColorScheme)
    }
    
    private var effectiveColorScheme: ColorScheme {
        switch themeManager.colorSchemePreference {
        case .light: return .light
        case .dark: return .dark
        case .system: return colorScheme
        }
    }
}

extension View {
    func adaptiveColors() -> some View {
        modifier(AdaptiveColorModifier())
    }
}

// MARK: - Preview Helpers
struct ColorPreviewCard: View {
    let title: String
    let color: Color
    let description: String?
    
    init(_ title: String, color: Color, description: String? = nil) {
        self.title = title
        self.color = color
        self.description = description
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray300, lineWidth: 1)
                )
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let description = description {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

#Preview("Enhanced Colors") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ColorPreviewCard("Success", color: .success, description: "Success states and positive actions")
            ColorPreviewCard("Warning", color: .warning, description: "Caution and warning states")
            ColorPreviewCard("Error", color: .error, description: "Error states and destructive actions")
            ColorPreviewCard("Info", color: .info, description: "Informational content")
            ColorPreviewCard("Analytics Blue", color: .analyticsBlue, description: "Primary analytics color")
            ColorPreviewCard("Analytics Purple", color: .analyticsPurple, description: "Secondary analytics color")
            ColorPreviewCard("Gray 500", color: .gray500, description: "Neutral mid-tone")
            ColorPreviewCard("Emerald", color: .emerald, description: "Brand primary color")
        }
        .padding()
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode Colors") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ColorPreviewCard("Success", color: .success, description: "Success states and positive actions")
            ColorPreviewCard("Warning", color: .warning, description: "Caution and warning states")
            ColorPreviewCard("Error", color: .error, description: "Error states and destructive actions")
            ColorPreviewCard("Info", color: .info, description: "Informational content")
            ColorPreviewCard("Analytics Blue", color: .analyticsBlue, description: "Primary analytics color")
            ColorPreviewCard("Analytics Purple", color: .analyticsPurple, description: "Secondary analytics color")
            ColorPreviewCard("Gray 500", color: .gray500, description: "Neutral mid-tone")
            ColorPreviewCard("Emerald", color: .emerald, description: "Brand primary color")
        }
        .padding()
    }
    .preferredColorScheme(.dark)
    .background(Color.black)
}