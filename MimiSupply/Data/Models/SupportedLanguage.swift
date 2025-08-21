//
//  SupportedLanguage.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation

/// Represents a supported language in the app
struct SupportedLanguage: Codable, Hashable, Identifiable {
    let id = UUID()
    let code: String
    let nativeName: String
    let englishName: String
    
    init(code: String, nativeName: String, englishName: String) {
        self.code = code
        self.nativeName = nativeName
        self.englishName = englishName
    }
}

// MARK: - Comparable
extension SupportedLanguage: Comparable {
    static func < (lhs: SupportedLanguage, rhs: SupportedLanguage) -> Bool {
        return lhs.englishName < rhs.englishName
    }
}