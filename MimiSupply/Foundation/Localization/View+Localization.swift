//
//  View+Localization.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

// MARK: - View Localization Extensions

extension View {
    
    /// Apply right-to-left layout direction based on current language
    func localizedLayoutDirection() -> some View {
        self.environment(\.layoutDirection, 
                        LocalizationManager.shared.isRightToLeft ? .rightToLeft : .leftToRight)
    }
    
    /// Apply localized text alignment
    func localizedTextAlignment(_ alignment: TextAlignment = .leading) -> some View {
        let localizedAlignment: TextAlignment
        
        if LocalizationManager.shared.isRightToLeft {
            switch alignment {
            case .leading:
                localizedAlignment = .trailing
            case .trailing:
                localizedAlignment = .leading
            default:
                localizedAlignment = alignment
            }
        } else {
            localizedAlignment = alignment
        }
        
        return self.multilineTextAlignment(localizedAlignment)
    }
    
    /// Apply localized horizontal alignment
    func localizedHorizontalAlignment(_ alignment: HorizontalAlignment = .leading) -> some View {
        let localizedAlignment: HorizontalAlignment
        
        if LocalizationManager.shared.isRightToLeft {
            switch alignment {
            case .leading:
                localizedAlignment = .trailing
            case .trailing:
                localizedAlignment = .leading
            default:
                localizedAlignment = alignment
            }
        } else {
            localizedAlignment = alignment
        }
        
        return self.frame(maxWidth: .infinity, alignment: Alignment(horizontal: localizedAlignment, vertical: .center))
    }
    
    /// Apply localized edge insets
    func localizedPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        if LocalizationManager.shared.isRightToLeft {
            let flippedEdges = edges.flippedForRTL()
            return self.padding(flippedEdges, length)
        } else {
            return self.padding(edges, length)
        }
    }
    
    /// Apply localized leading padding
    func localizedLeadingPadding(_ length: CGFloat) -> some View {
        if LocalizationManager.shared.isRightToLeft {
            return self.padding(.trailing, length)
        } else {
            return self.padding(.leading, length)
        }
    }
    
    /// Apply localized trailing padding
    func localizedTrailingPadding(_ length: CGFloat) -> some View {
        if LocalizationManager.shared.isRightToLeft {
            return self.padding(.leading, length)
        } else {
            return self.padding(.trailing, length)
        }
    }
    
    /// Observe language changes and update view
    func observeLanguageChanges() -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
            // Force view update when language changes
        }
    }
}

// MARK: - Text Localization Extensions

extension Text {
    
    /// Create localized text
    init(localized key: String, tableName: String? = nil, bundle: Bundle = .main, comment: String = "") {
        self.init(LocalizedStringKey(key), tableName: tableName, bundle: bundle)
    }
    
    /// Create localized text with arguments
    init(localized key: String, arguments: CVarArg..., tableName: String? = nil, bundle: Bundle = .main, comment: String = "") {
        let format = NSLocalizedString(key, tableName: tableName, bundle: bundle, value: key, comment: comment)
        let localizedString = String(format: format, arguments: arguments)
        self.init(localizedString)
    }
    
    /// Apply localized text alignment
    @MainActor
    func localizedAlignment() -> some View {
        self.multilineTextAlignment(LocalizationManager.shared.isRightToLeft ? .trailing : .leading)
    }
}

// MARK: - Edge.Set Extensions

extension Edge.Set {
    
    /// Flip edge set for right-to-left layout
    func flippedForRTL() -> Edge.Set {
        var flipped: Edge.Set = []
        
        if self.contains(.leading) {
            flipped.insert(.trailing)
        }
        if self.contains(.trailing) {
            flipped.insert(.leading)
        }
        if self.contains(.top) {
            flipped.insert(.top)
        }
        if self.contains(.bottom) {
            flipped.insert(.bottom)
        }
        if self.contains(.all) {
            flipped = .all
        }
        if self.contains(.horizontal) {
            flipped.insert(.horizontal)
        }
        if self.contains(.vertical) {
            flipped.insert(.vertical)
        }
        
        return flipped
    }
}