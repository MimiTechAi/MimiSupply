//
//  Font+Extensions.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

extension Font {
    
    // MARK: - Display
    static let displayLarge = Font.custom("Inter", size: 57).weight(.regular)
    static let displayMedium = Font.custom("Inter", size: 45).weight(.regular)
    static let displaySmall = Font.custom("Inter", size: 36).weight(.regular)
    
    // MARK: - Headline
    static let headlineLarge = Font.custom("Inter", size: 32).weight(.regular)
    static let headlineMedium = Font.custom("Inter", size: 28).weight(.regular)
    static let headlineSmall = Font.custom("Inter", size: 24).weight(.regular)
    
    // MARK: - Title
    static let titleLarge = Font.custom("Inter", size: 22).weight(.medium)
    static let titleMedium = Font.custom("Inter", size: 16).weight(.medium)
    static let titleSmall = Font.custom("Inter", size: 14).weight(.medium)
    
    // MARK: - Body
    static let bodyLarge = Font.custom("Inter", size: 16).weight(.regular)
    static let bodyMedium = Font.custom("Inter", size: 14).weight(.regular)
    static let bodySmall = Font.custom("Inter", size: 12).weight(.regular)
    
    // MARK: - Label
    static let labelLarge = Font.custom("Inter", size: 14).weight(.medium)
    static let labelMedium = Font.custom("Inter", size: 12).weight(.medium)
    static let labelSmall = Font.custom("Inter", size: 11).weight(.medium)
}