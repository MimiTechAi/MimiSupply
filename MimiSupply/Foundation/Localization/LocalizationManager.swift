//
//  LocalizationManager.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI

/// Comprehensive localization manager for multi-language support
final class LocalizationManager: ObservableObject, @unchecked Sendable {
    
    // MARK: - Singleton
    
    static let shared = LocalizationManager()
    
    // MARK: - Published Properties
    
    @Published var currentLanguage: SupportedLanguage
    @Published var isRightToLeft: Bool = false
    @Published var currentLocale: Locale
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let languageKey = "selected_language"
    private let localeKey = "selected_locale"
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with system language or saved preference
        let savedLanguageCode = userDefaults.string(forKey: languageKey) ??
                                Locale.current.language.languageCode?.identifier ?? "en"
        
        let language = SupportedLanguage.allLanguages.first { $0.code == savedLanguageCode } ??
                       SupportedLanguage.english
        
        self.currentLanguage = language
        self.currentLocale = Locale(identifier: language.localeIdentifier)
        self.isRightToLeft = language.isRightToLeft
        
        // Set up initial localization
        setupLocalization()
    }
    
    // MARK: - Public Methods
    
    /// Change the app language
    func changeLanguage(to language: SupportedLanguage) {
        currentLanguage = language
        currentLocale = Locale(identifier: language.localeIdentifier)
        isRightToLeft = language.isRightToLeft
        
        // Save preference
        userDefaults.set(language.code, forKey: languageKey)
        userDefaults.set(language.localeIdentifier, forKey: localeKey)
        userDefaults.synchronize()
        
        // Update app localization
        setupLocalization()
        
        // Notify observers
        NotificationCenter.default.post(name: .languageDidChange, object: language)
    }
    
    /// Get localized string with optional parameters
    func localizedString(_ key: String, tableName: String? = nil, bundle: Bundle = .main, value: String = "", comment: String = "", arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, tableName: tableName, bundle: bundle, value: value, comment: comment)
        
        if arguments.isEmpty {
            return format
        } else {
            return String(format: format, arguments: arguments)
        }
    }
    
    /// Format currency for current locale
    func formatCurrency(_ amount: Int, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = currentLocale
        formatter.currencyCode = currencyCode
        
        let decimalAmount = Double(amount) / 100.0
        return formatter.string(from: NSNumber(value: decimalAmount)) ?? "$0.00"
    }
    
    /// Format date for current locale
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    /// Format time for current locale
    func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.locale = currentLocale
        formatter.timeStyle = style
        return formatter.string(from: date)
    }
    
    /// Format number for current locale
    func formatNumber(_ number: Double, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = currentLocale
        formatter.numberStyle = style
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// Get localized image name with fallback
    func localizedImageName(_ baseName: String) -> String {
        let localizedName = "\(baseName)_\(currentLanguage.code)"
        
        // Check if localized image exists
        if Bundle.main.path(forResource: localizedName, ofType: nil) != nil {
            return localizedName
        }
        
        // Fall back to base name
        return baseName
    }
    
    // MARK: - Private Methods
    
    private func setupLocalization() {
        // Set app language
        UserDefaults.standard.set([currentLanguage.code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Update bundle language
        Bundle.setLanguage(currentLanguage.code)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let languageDidChange = Notification.Name("languageDidChange")
}

// MARK: - SupportedLanguage Extension

extension SupportedLanguage {
    static let english = SupportedLanguage(code: "en", nativeName: "English", englishName: "English")
    
    static let allLanguages: [SupportedLanguage] = [
        SupportedLanguage(code: "en", nativeName: "English", englishName: "English"),
        SupportedLanguage(code: "es", nativeName: "Español", englishName: "Spanish"),
        SupportedLanguage(code: "fr", nativeName: "Français", englishName: "French"),
        SupportedLanguage(code: "de", nativeName: "Deutsch", englishName: "German"),
        SupportedLanguage(code: "it", nativeName: "Italiano", englishName: "Italian"),
        SupportedLanguage(code: "pt", nativeName: "Português", englishName: "Portuguese"),
        SupportedLanguage(code: "nl", nativeName: "Nederlands", englishName: "Dutch"),
        SupportedLanguage(code: "sv", nativeName: "Svenska", englishName: "Swedish"),
        SupportedLanguage(code: "da", nativeName: "Dansk", englishName: "Danish"),
        SupportedLanguage(code: "no", nativeName: "Norsk", englishName: "Norwegian"),
        SupportedLanguage(code: "fi", nativeName: "Suomi", englishName: "Finnish"),
        SupportedLanguage(code: "pl", nativeName: "Polski", englishName: "Polish"),
        SupportedLanguage(code: "ru", nativeName: "Русский", englishName: "Russian"),
        SupportedLanguage(code: "ja", nativeName: "日本語", englishName: "Japanese"),
        SupportedLanguage(code: "ko", nativeName: "한국어", englishName: "Korean"),
        SupportedLanguage(code: "zh-Hans", nativeName: "简体中文", englishName: "Chinese (Simplified)"),
        SupportedLanguage(code: "zh-Hant", nativeName: "繁體中文", englishName: "Chinese (Traditional)"),
        SupportedLanguage(code: "ar", nativeName: "العربية", englishName: "Arabic"),
        SupportedLanguage(code: "hi", nativeName: "हिन्दी", englishName: "Hindi"),
        SupportedLanguage(code: "th", nativeName: "ไทย", englishName: "Thai"),
        SupportedLanguage(code: "vi", nativeName: "Tiếng Việt", englishName: "Vietnamese"),
        SupportedLanguage(code: "id", nativeName: "Bahasa Indonesia", englishName: "Indonesian"),
        SupportedLanguage(code: "ms", nativeName: "Bahasa Melayu", englishName: "Malay"),
        SupportedLanguage(code: "tl", nativeName: "Filipino", englishName: "Filipino"),
        SupportedLanguage(code: "tr", nativeName: "Türkçe", englishName: "Turkish"),
        SupportedLanguage(code: "he", nativeName: "עברית", englishName: "Hebrew"),
        SupportedLanguage(code: "cs", nativeName: "Čeština", englishName: "Czech"),
        SupportedLanguage(code: "sk", nativeName: "Slovenčina", englishName: "Slovak"),
        SupportedLanguage(code: "hu", nativeName: "Magyar", englishName: "Hungarian"),
        SupportedLanguage(code: "ro", nativeName: "Română", englishName: "Romanian"),
        SupportedLanguage(code: "bg", nativeName: "Български", englishName: "Bulgarian"),
        SupportedLanguage(code: "hr", nativeName: "Hrvatski", englishName: "Croatian"),
        SupportedLanguage(code: "sr", nativeName: "Српски", englishName: "Serbian"),
        SupportedLanguage(code: "sl", nativeName: "Slovenščina", englishName: "Slovenian"),
        SupportedLanguage(code: "et", nativeName: "Eesti", englishName: "Estonian"),
        SupportedLanguage(code: "lv", nativeName: "Latviešu", englishName: "Latvian"),
        SupportedLanguage(code: "lt", nativeName: "Lietuvių", englishName: "Lithuanian"),
        SupportedLanguage(code: "uk", nativeName: "Українська", englishName: "Ukrainian"),
        SupportedLanguage(code: "el", nativeName: "Ελληνικά", englishName: "Greek"),
        SupportedLanguage(code: "ca", nativeName: "Català", englishName: "Catalan"),
        SupportedLanguage(code: "eu", nativeName: "Euskera", englishName: "Basque"),
        SupportedLanguage(code: "gl", nativeName: "Galego", englishName: "Galician")
    ]
    
    var localeIdentifier: String {
        switch code {
        case "zh-Hans": return "zh_CN"
        case "zh-Hant": return "zh_TW"
        default: return code
        }
    }
    
    var isRightToLeft: Bool {
        return ["ar", "he", "fa", "ur"].contains(code)
    }
}
