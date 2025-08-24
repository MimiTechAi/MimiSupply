//
//  Color+Extensions.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

@preconcurrency import SwiftUI
@preconcurrency import UIKit

extension Color {
    
    // MARK: - Primary Semantic Colors
    static let success = Color.colorDynamic(
        light: Color(red: 0.2, green: 0.8, blue: 0.2),
        dark: Color(red: 0.3, green: 0.9, blue: 0.3)
    )
    
    static let warning = Color.colorDynamic(
        light: Color(red: 1.0, green: 0.6, blue: 0.0),
        dark: Color(red: 1.0, green: 0.7, blue: 0.2)
    )
    
    static let error = Color.colorDynamic(
        light: Color(red: 0.9, green: 0.2, blue: 0.2),
        dark: Color(red: 1.0, green: 0.3, blue: 0.3)
    )
    
    static let info = Color.colorDynamic(
        light: Color(red: 0.0, green: 0.5, blue: 1.0),
        dark: Color(red: 0.2, green: 0.6, blue: 1.0)
    )
    
    // MARK: - Gray Scale
    static let gray50 = Color.colorDynamic(
        light: Color(red: 0.98, green: 0.98, blue: 0.98),
        dark: Color(red: 0.05, green: 0.05, blue: 0.05)
    )
    
    static let gray100 = Color.colorDynamic(
        light: Color(red: 0.96, green: 0.96, blue: 0.96),
        dark: Color(red: 0.1, green: 0.1, blue: 0.1)
    )
    
    static let gray200 = Color.colorDynamic(
        light: Color(red: 0.93, green: 0.93, blue: 0.93),
        dark: Color(red: 0.15, green: 0.15, blue: 0.15)
    )
    
    static let gray300 = Color.colorDynamic(
        light: Color(red: 0.87, green: 0.87, blue: 0.87),
        dark: Color(red: 0.2, green: 0.2, blue: 0.2)
    )
    
    static let gray400 = Color.colorDynamic(
        light: Color(red: 0.74, green: 0.74, blue: 0.74),
        dark: Color(red: 0.3, green: 0.3, blue: 0.3)
    )
    
    static let gray500 = Color.colorDynamic(
        light: Color(red: 0.62, green: 0.62, blue: 0.62),
        dark: Color(red: 0.4, green: 0.4, blue: 0.4)
    )
    
    static let gray600 = Color.colorDynamic(
        light: Color(red: 0.45, green: 0.45, blue: 0.45),
        dark: Color(red: 0.55, green: 0.55, blue: 0.55)
    )
    
    static let gray700 = Color.colorDynamic(
        light: Color(red: 0.37, green: 0.37, blue: 0.37),
        dark: Color(red: 0.65, green: 0.65, blue: 0.65)
    )
    
    static let gray800 = Color.colorDynamic(
        light: Color(red: 0.25, green: 0.25, blue: 0.25),
        dark: Color(red: 0.75, green: 0.75, blue: 0.75)
    )
    
    static let gray900 = Color.colorDynamic(
        light: Color(red: 0.11, green: 0.11, blue: 0.11),
        dark: Color(red: 0.9, green: 0.9, blue: 0.9)
    )
    
    // MARK: - Surface Colors
    static let surfacePrimary = Color.colorDynamic(
        light: .white,
        dark: Color(red: 0.05, green: 0.05, blue: 0.05)
    )
    
    static let surfaceSecondary = Color.colorDynamic(
        light: Color(red: 0.98, green: 0.98, blue: 0.98),
        dark: Color(red: 0.1, green: 0.1, blue: 0.1)
    )
    
    static let surfaceTertiary = Color.colorDynamic(
        light: Color(red: 0.95, green: 0.95, blue: 0.95),
        dark: Color(red: 0.15, green: 0.15, blue: 0.15)
    )
    
    // MARK: - Brand Colors
    static let emerald = Color.colorDynamic(
        light: Color(red: 0.0, green: 0.7, blue: 0.4),
        dark: Color(red: 0.2, green: 0.8, blue: 0.5)
    )
    
    static let chalk = Color.colorDynamic(
        light: Color(red: 0.98, green: 0.98, blue: 0.98),
        dark: Color(red: 0.05, green: 0.05, blue: 0.05)
    )
    
    static let graphite = Color.colorDynamic(
        light: Color(red: 0.15, green: 0.15, blue: 0.15),
        dark: Color(red: 0.9, green: 0.9, blue: 0.9)
    )
    
    // MARK: - Accessibility Support
    var accessibilityHighContrastColor: Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return self.opacity(0.9)
        } else {
            return self
        }
    }
    
    // MARK: - Business Intelligence Colors
    static let analyticsBlue = Color.colorDynamic(
        light: Color(red: 0.0, green: 0.47, blue: 0.95),
        dark: Color(red: 0.2, green: 0.6, blue: 1.0)
    )
    
    static let revenueGreen = Color.colorDynamic(
        light: Color(red: 0.0, green: 0.7, blue: 0.3),
        dark: Color(red: 0.2, green: 0.8, blue: 0.4)
    )
    
    static let ordersOrange = Color.colorDynamic(
        light: Color(red: 1.0, green: 0.6, blue: 0.0),
        dark: Color(red: 1.0, green: 0.7, blue: 0.2)
    )
    
    static let customersIndigo = Color.colorDynamic(
        light: Color(red: 0.3, green: 0.2, blue: 0.8),
        dark: Color(red: 0.5, green: 0.4, blue: 0.9)
    )
    
    static let performancePurple = Color.colorDynamic(
        light: Color(red: 0.6, green: 0.2, blue: 0.8),
        dark: Color(red: 0.7, green: 0.4, blue: 0.9)
    )
    
    // MARK: - Hex Color Initializer
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
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Random Color
    static var random: Color {
        return Color(
            red: .random(in: