//
//  LocalizedImage.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

// MARK: - Localized Image Support

/// A view that displays localized images based on current language
struct LocalizedImage: View {
    let baseName: String
    let bundle: Bundle
    
    init(_ baseName: String, bundle: Bundle = .main) {
        self.baseName = baseName
        self.bundle = bundle
    }
    
    var body: some View {
        Image(localizedImageName, bundle: bundle)
    }
    
    private var localizedImageName: String {
        LocalizationManager.shared.localizedImageName(baseName)
    }
}

/// A view that displays localized system images with RTL support
struct LocalizedSystemImage: View {
    let systemName: String
    let rtlVariant: String?
    
    init(systemName: String, rtlVariant: String? = nil) {
        self.systemName = systemName
        self.rtlVariant = rtlVariant
    }
    
    var body: some View {
        if LocalizationManager.shared.isRightToLeft, let rtlVariant = rtlVariant {
            Image(systemName: rtlVariant)
        } else {
            Image(systemName: systemName)
        }
    }
}

// MARK: - Cultural Adaptations

/// Manages cultural adaptations for different locales
struct CulturalAdaptations {
    
    // MARK: - Color Adaptations
    
    /// Get culturally appropriate colors
    @MainActor static func adaptedColor(for context: ColorContext) -> Color {
        let languageCode = LocalizationManager.shared.currentLanguage.code
        
        switch context {
        case .success:
            return successColor(for: languageCode)
        case .warning:
            return warningColor(for: languageCode)
        case .error:
            return errorColor(for: languageCode)
        case .primary:
            return primaryColor(for: languageCode)
        case .accent:
            return accentColor(for: languageCode)
        }
    }
    
    // MARK: - Icon Adaptations
    
    /// Get culturally appropriate icons
    @MainActor static func adaptedIcon(for context: IconContext) -> String {
        let languageCode = LocalizationManager.shared.currentLanguage.code
        
        switch context {
        case .home:
            return homeIcon(for: languageCode)
        case .profile:
            return profileIcon(for: languageCode)
        case .settings:
            return settingsIcon(for: languageCode)
        case .help:
            return helpIcon(for: languageCode)
        case .payment:
            return paymentIcon(for: languageCode)
        case .delivery:
            return deliveryIcon(for: languageCode)
        case .restaurant:
            return restaurantIcon(for: languageCode)
        case .pharmacy:
            return pharmacyIcon(for: languageCode)
        case .grocery:
            return groceryIcon(for: languageCode)
        }
    }
    
    // MARK: - Text Adaptations
    
    /// Get culturally appropriate greeting
    @MainActor static func greeting(for timeOfDay: TimeOfDay) -> String {
        let languageCode = LocalizationManager.shared.currentLanguage.code
        
        switch timeOfDay {
        case .morning:
            return morningGreeting(for: languageCode)
        case .afternoon:
            return afternoonGreeting(for: languageCode)
        case .evening:
            return eveningGreeting(for: languageCode)
        case .night:
            return nightGreeting(for: languageCode)
        }
    }
    
    /// Get culturally appropriate politeness level
    @MainActor static func politenessSuffix(for context: PolitenessContext) -> String {
        let languageCode = LocalizationManager.shared.currentLanguage.code
        
        switch languageCode {
        case "ja":
            return japanesePolitenessSuffix(for: context)
        case "ko":
            return koreanPolitenessSuffix(for: context)
        case "th":
            return thaiPolitenessSuffix(for: context)
        case "vi":
            return vietnamesePolitenessSuffix(for: context)
        default:
            return ""
        }
    }
    
    // MARK: - Layout Adaptations
    
    /// Get culturally appropriate spacing
    @MainActor static func adaptedSpacing(for context: SpacingContext) -> CGFloat {
        let languageCode = LocalizationManager.shared.currentLanguage.code
        
        switch context {
        case .text:
            return textSpacing(for: languageCode)
        case .button:
            return buttonSpacing(for: languageCode)
        case .card:
            return cardSpacing(for: languageCode)
        case .list:
            return listSpacing(for: languageCode)
        }
    }
    
    // MARK: - Private Methods
    
    private static func successColor(for languageCode: String) -> Color {
        switch languageCode {
        case "zh-Hans", "zh-Hant":
            return Color(hex: "FF6B6B") // Red is lucky in Chinese culture
        case "ja":
            return Color(hex: "4CAF50") // Green is positive in Japanese culture
        default:
            return .success
        }
    }
    
    private static func warningColor(for languageCode: String) -> Color {
        switch languageCode {
        case "ar", "he":
            return Color(hex: "FF9800") // Orange for Middle Eastern cultures
        default:
            return .warning
        }
    }
    
    private static func errorColor(for languageCode: String) -> Color {
        switch languageCode {
        case "zh-Hans", "zh-Hant":
            return Color(hex: "F44336") // Bright red for Chinese
        default:
            return .error
        }
    }
    
    private static func primaryColor(for languageCode: String) -> Color {
        switch languageCode {
        case "ar":
            return Color(hex: "2E7D32") // Green for Arabic (Islamic culture)
        case "he":
            return Color(hex: "1976D2") // Blue for Hebrew
        case "hi":
            return Color(hex: "FF5722") // Saffron for Hindi (Indian culture)
        case "th":
            return Color(hex: "3F51B5") // Blue for Thai (royal color)
        default:
            return .emerald
        }
    }
    
    private static func accentColor(for languageCode: String) -> Color {
        switch languageCode {
        case "ja":
            return Color(hex: "E91E63") // Pink for Japanese aesthetics
        case "ko":
            return Color(hex: "9C27B0") // Purple for Korean aesthetics
        default:
            return .emerald
        }
    }
    
    private static func homeIcon(for languageCode: String) -> String {
        switch languageCode {
        case "ja":
            return "house.fill" // Traditional house for Japanese
        case "ar", "he":
            return "building.2.fill" // Building for Middle Eastern
        default:
            return "house.fill"
        }
    }
    
    private static func profileIcon(for languageCode: String) -> String {
        return "person.circle.fill" // Universal
    }
    
    private static func settingsIcon(for languageCode: String) -> String {
        return "gearshape.fill" // Universal
    }
    
    private static func helpIcon(for languageCode: String) -> String {
        switch languageCode {
        case "ja", "ko", "zh-Hans", "zh-Hant":
            return "questionmark.circle.fill" // Question mark for East Asian
        default:
            return "info.circle.fill"
        }
    }
    
    private static func paymentIcon(for languageCode: String) -> String {
        switch languageCode {
        case "ar", "he":
            return "banknote.fill" // Cash preferred in Middle East
        case "zh-Hans":
            return "qrcode" // QR codes popular in China
        default:
            return "creditcard.fill"
        }
    }
    
    private static func deliveryIcon(for languageCode: String) -> String {
        switch languageCode {
        case "ja":
            return "bicycle" // Bicycles common in Japan
        case "th", "vi", "id":
            return "scooter" // Scooters common in Southeast Asia
        default:
            return "car.fill"
        }
    }
    
    private static func restaurantIcon(for languageCode: String) -> String {
        switch languageCode {
        case "ja":
            return "chopsticks" // Chopsticks for Japanese
        case "zh-Hans", "zh-Hant":
            return "chopsticks" // Chopsticks for Chinese
        case "ko":
            return "chopsticks" // Chopsticks for Korean
        case "ar", "he":
            return "leaf.fill" // Halal symbol
        case "hi":
            return "leaf.fill" // Vegetarian symbol
        default:
            return "fork.knife"
        }
    }
    
    private static func pharmacyIcon(for languageCode: String) -> String {
        return "cross.fill" // Universal medical symbol
    }
    
    private static func groceryIcon(for languageCode: String) -> String {
        switch languageCode {
        case "ar", "he":
            return "basket.fill" // Basket for Middle Eastern
        default:
            return "cart.fill"
        }
    }
    
    private static func morningGreeting(for languageCode: String) -> String {
        switch languageCode {
        case "ar":
            return "صباح الخير"
        case "he":
            return "בוקר טוב"
        case "hi":
            return "सुप्रभात"
        case "th":
            return "สวัสดีตอนเช้า"
        case "ja":
            return "おはようございます"
        case "ko":
            return "좋은 아침입니다"
        case "zh-Hans":
            return "早上好"
        case "zh-Hant":
            return "早安"
        default:
            return "Good morning"
        }
    }
    
    private static func afternoonGreeting(for languageCode: String) -> String {
        switch languageCode {
        case "ar":
            return "مساء الخير"
        case "he":
            return "אחר הצהריים טובים"
        case "hi":
            return "नमस्कार"
        case "th":
            return "สวัสดีตอนบ่าย"
        case "ja":
            return "こんにちは"
        case "ko":
            return "안녕하세요"
        case "zh-Hans":
            return "下午好"
        case "zh-Hant":
            return "午安"
        default:
            return "Good afternoon"
        }
    }
    
    private static func eveningGreeting(for languageCode: String) -> String {
        switch languageCode {
        case "ar":
            return "مساء الخير"
        case "he":
            return "ערב טוב"
        case "hi":
            return "शुभ संध्या"
        case "th":
            return "สวัสดีตอนเย็น"
        case "ja":
            return "こんばんは"
        case "ko":
            return "좋은 저녁입니다"
        case "zh-Hans":
            return "晚上好"
        case "zh-Hant":
            return "晚安"
        default:
            return "Good evening"
        }
    }
    
    private static func nightGreeting(for languageCode: String) -> String {
        switch languageCode {
        case "ar":
            return "تصبح على خير"
        case "he":
            return "לילה טוב"
        case "hi":
            return "शुभ रात्रि"
        case "th":
            return "ราตรีสวัสดิ์"
        case "ja":
            return "おやすみなさい"
        case "ko":
            return "안녕히 주무세요"
        case "zh-Hans":
            return "晚安"
        case "zh-Hant":
            return "晚安"
        default:
            return "Good night"
        }
    }
    
    private static func japanesePolitenessSuffix(for context: PolitenessContext) -> String {
        switch context {
        case .formal:
            return "です"
        case .casual:
            return ""
        case .respectful:
            return "ございます"
        }
    }
    
    private static func koreanPolitenessSuffix(for context: PolitenessContext) -> String {
        switch context {
        case .formal:
            return "습니다"
        case .casual:
            return "요"
        case .respectful:
            return "습니다"
        }
    }
    
    private static func thaiPolitenessSuffix(for context: PolitenessContext) -> String {
        switch context {
        case .formal:
            return "ครับ/ค่ะ"
        case .casual:
            return ""
        case .respectful:
            return "ครับ/ค่ะ"
        }
    }
    
    private static func vietnamesePolitenessSuffix(for context: PolitenessContext) -> String {
        switch context {
        case .formal:
            return "ạ"
        case .casual:
            return ""
        case .respectful:
            return "ạ"
        }
    }
    
    private static func textSpacing(for languageCode: String) -> CGFloat {
        switch languageCode {
        case "ar", "he":
            return Spacing.md * 1.2 // More spacing for RTL languages
        case "th", "vi":
            return Spacing.md * 1.1 // Slightly more for complex scripts
        default:
            return Spacing.md
        }
    }
    
    private static func buttonSpacing(for languageCode: String) -> CGFloat {
        switch languageCode {
        case "ar", "he":
            return Spacing.lg * 1.2 // More spacing for RTL
        case "ja", "ko", "zh-Hans", "zh-Hant":
            return Spacing.lg * 0.9 // Less spacing for compact scripts
        default:
            return Spacing.lg
        }
    }
    
    private static func cardSpacing(for languageCode: String) -> CGFloat {
        switch languageCode {
        case "ar", "he":
            return Spacing.xl * 1.1 // More spacing for RTL
        default:
            return Spacing.xl
        }
    }
    
    private static func listSpacing(for languageCode: String) -> CGFloat {
        switch languageCode {
        case "th", "vi", "hi":
            return Spacing.md * 1.3 // More spacing for complex scripts
        default:
            return Spacing.md
        }
    }
}

// MARK: - Supporting Enums

enum ColorContext {
    case success
    case warning
    case error
    case primary
    case accent
}

enum IconContext {
    case home
    case profile
    case settings
    case help
    case payment
    case delivery
    case restaurant
    case pharmacy
    case grocery
}

enum TimeOfDay {
    case morning
    case afternoon
    case evening
    case night
}

enum PolitenessContext {
    case formal
    case casual
    case respectful
}

enum SpacingContext {
    case text
    case button
    case card
    case list
}