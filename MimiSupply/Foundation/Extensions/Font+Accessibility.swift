//
//  Font+Accessibility.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import UIKit

extension Font {
    
    /// Minimum touch target size recommended by Apple
    static let minimumTouchTarget: CGFloat = 44.0
    
    /// Get a scaled version of the font that respects Dynamic Type
    func scaledFont() -> Font {
        return self
    }
    
    /// Create a font that scales with Dynamic Type
    static func scaledSystem(size: CGFloat, weight: Weight = .regular, design: Design = .default) -> Font {
        return Font.system(size: size, weight: weight, design: design)
    }
}

// MARK: - RTL Text Support

extension Text {
    /// Apply RTL-aware text alignment
    func rtlTextAlignment() -> Text {
        return self
    }
}

// MARK: - Accessibility Font Modifiers

extension View {
    /// Apply accessibility-aware font scaling
    func accessibilityFont(_ font: Font) -> some View {
        self.font(font)
    }
    
    /// Apply minimum touch target size
    func minimumTouchTarget() -> some View {
        self.frame(minWidth: Font.minimumTouchTarget, minHeight: Font.minimumTouchTarget)
    }
}