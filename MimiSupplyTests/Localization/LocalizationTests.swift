//
//  LocalizationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
@testable import MimiSupply

@MainActor
final class LocalizationTests: XCTestCase {
    
    var localizationManager: LocalizationManager!
    var localeFormatter: LocaleFormatter!
    
    override func setUp() {
        super.setUp()
        localizationManager = LocalizationManager.shared
        localeFormatter = LocaleFormatter.shared
    }
    
    override func tearDown() {
        // Reset to English for other tests
        localizationManager.changeLanguage(to: SupportedLanguage.english)
        super.tearDown()
    }
    
    // MARK: - Language Management Tests
    
    func testLanguageChange() {
        // Given
        let spanish = SupportedLanguage(code: "es", nativeName: "Español", englishName: "Spanish")
        
        // When
        localizationManager.changeLanguage(to: spanish)
        
        // Then
        XCTAssertEqual(localizationManager.currentLanguage.code, "es")
        XCTAssertEqual(localizationManager.currentLocale.identifier, "es")
        XCTAssertFalse(localizationManager.isRightToLeft)
    }
    
    func testRightToLeftLanguage() {
        // Given
        let arabic = SupportedLanguage(code: "ar", nativeName: "العربية", englishName: "Arabic")
        
        // When
        localizationManager.changeLanguage(to: arabic)
        
        // Then
        XCTAssertEqual(localizationManager.currentLanguage.code, "ar")
        XCTAssertTrue(localizationManager.isRightToLeft)
    }
    
    func testHebrewRightToLeft() {
        // Given
        let hebrew = SupportedLanguage(code: "he", nativeName: "עברית", englishName: "Hebrew")
        
        // When
        localizationManager.changeLanguage(to: hebrew)
        
        // Then
        XCTAssertEqual(localizationManager.currentLanguage.code, "he")
        XCTAssertTrue(localizationManager.isRightToLeft)
    }
    
    func testChineseLocaleMapping() {
        // Given
        let simplifiedChinese = SupportedLanguage(code: "zh-Hans", nativeName: "简体中文", englishName: "Chinese (Simplified)")
        let traditionalChinese = SupportedLanguage(code: "zh-Hant", nativeName: "繁體中文", englishName: "Chinese (Traditional)")
        
        // When & Then
        localizationManager.changeLanguage(to: simplifiedChinese)
        XCTAssertEqual(localizationManager.currentLocale.identifier, "zh_CN")
        
        localizationManager.changeLanguage(to: traditionalChinese)
        XCTAssertEqual(localizationManager.currentLocale.identifier, "zh_TW")
    }
    
    // MARK: - String Localization Tests
    
    func testStringLocalization() {
        // Given
        let key = "common.ok"
        
        // When
        let localizedString = localizationManager.localizedString(key)
        
        // Then
        XCTAssertEqual(localizedString, "OK")
    }
    
    func testStringLocalizationWithArguments() {
        // Given
        let key = "cart.items_in_cart"
        let itemCount = 5
        
        // When
        let localizedString = localizationManager.localizedString(key, arguments: itemCount)
        
        // Then
        XCTAssertTrue(localizedString.contains("\(itemCount)"))
    }
    
    func testStringExtensionLocalization() {
        // Given
        let key = "common.cancel"
        
        // When
        let localizedString = key.localized
        
        // Then
        XCTAssertEqual(localizedString, "Cancel")
    }
    
    // MARK: - Currency Formatting Tests
    
    func testCurrencyFormattingUSD() {
        // Given
        let amountInCents = 1250 // $12.50
        
        // When
        let formattedCurrency = localeFormatter.formatCurrency(amountInCents, currencyCode: "USD")
        
        // Then
        XCTAssertTrue(formattedCurrency.contains("12.50") || formattedCurrency.contains("12,50"))
        XCTAssertTrue(formattedCurrency.contains("$") || formattedCurrency.contains("USD"))
    }
    
    func testCurrencyFormattingEUR() {
        // Given
        let amountInCents = 2000 // €20.00
        localizationManager.changeLanguage(to: SupportedLanguage(code: "de", nativeName: "Deutsch", englishName: "German"))
        
        // When
        let formattedCurrency = localeFormatter.formatCurrency(amountInCents, currencyCode: "EUR")
        
        // Then
        XCTAssertTrue(formattedCurrency.contains("20") || formattedCurrency.contains("20,00"))
        XCTAssertTrue(formattedCurrency.contains("€") || formattedCurrency.contains("EUR"))
    }
    
    func testCurrencyFormattingJPY() {
        // Given
        let amountInCents = 150000 // ¥1500 (JPY doesn't use cents)
        localizationManager.changeLanguage(to: SupportedLanguage(code: "ja", nativeName: "日本語", englishName: "Japanese"))
        
        // When
        let formattedCurrency = localeFormatter.formatCurrency(amountInCents, currencyCode: "JPY")
        
        // Then
        XCTAssertTrue(formattedCurrency.contains("1500") || formattedCurrency.contains("1,500"))
        XCTAssertTrue(formattedCurrency.contains("¥") || formattedCurrency.contains("JPY"))
    }
    
    // MARK: - Date Formatting Tests
    
    func testDateFormatting() {
        // Given
        let date = Date(timeIntervalSince1970: 1692115200) // August 15, 2023
        
        // When
        let formattedDate = localeFormatter.formatDate(date, style: .medium)
        
        // Then
        XCTAssertFalse(formattedDate.isEmpty)
        XCTAssertTrue(formattedDate.contains("2023") || formattedDate.contains("23"))
    }
    
    func testTimeFormatting() {
        // Given
        let date = Date(timeIntervalSince1970: 1692115200) // 12:00 PM UTC
        
        // When
        let formattedTime = localeFormatter.formatTime(date, style: .short)
        
        // Then
        XCTAssertFalse(formattedTime.isEmpty)
        XCTAssertTrue(formattedTime.contains(":"))
    }
    
    func testRelativeDateFormatting() {
        // Given
        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600)
        
        // When
        let relativeDate = localeFormatter.formatRelativeDate(twoHoursAgo)
        
        // Then
        XCTAssertFalse(relativeDate.isEmpty)
        XCTAssertTrue(relativeDate.contains("2") || relativeDate.contains("hour"))
    }
    
    // MARK: - Number Formatting Tests
    
    func testNumberFormatting() {
        // Given
        let number = 1234.56
        
        // When
        let formattedNumber = localeFormatter.formatNumber(number)
        
        // Then
        XCTAssertFalse(formattedNumber.isEmpty)
        XCTAssertTrue(formattedNumber.contains("1234") || formattedNumber.contains("1,234") || formattedNumber.contains("1.234"))
    }
    
    func testIntegerFormatting() {
        // Given
        let integer = 1000
        
        // When
        let formattedInteger = localeFormatter.formatInteger(integer)
        
        // Then
        XCTAssertFalse(formattedInteger.isEmpty)
        XCTAssertTrue(formattedInteger.contains("1000") || formattedInteger.contains("1,000") || formattedInteger.contains("1.000"))
    }
    
    func testPercentageFormatting() {
        // Given
        let percentage = 0.15 // 15%
        
        // When
        let formattedPercentage = localeFormatter.formatPercentage(percentage)
        
        // Then
        XCTAssertFalse(formattedPercentage.isEmpty)
        XCTAssertTrue(formattedPercentage.contains("15"))
        XCTAssertTrue(formattedPercentage.contains("%"))
    }
    
    // MARK: - Distance Formatting Tests
    
    func testDistanceFormattingMetric() {
        // Given
        let meters = 1500.0
        localizationManager.changeLanguage(to: SupportedLanguage(code: "de", nativeName: "Deutsch", englishName: "German"))
        
        // When
        let formattedDistance = localeFormatter.formatDistance(meters)
        
        // Then
        XCTAssertTrue(formattedDistance.contains("1.5") && formattedDistance.contains("km"))
    }
    
    func testDistanceFormattingImperial() {
        // Given
        let meters = 1609.0 // ~1 mile
        localizationManager.changeLanguage(to: SupportedLanguage(code: "en", nativeName: "English", englishName: "English"))
        
        // When
        let formattedDistance = localeFormatter.formatDistance(meters)
        
        // Then
        XCTAssertTrue(formattedDistance.contains("1.0") && formattedDistance.contains("mi"))
    }
    
    // MARK: - Duration Formatting Tests
    
    func testDurationFormattingMinutes() {
        // Given
        let minutes = 45
        
        // When
        let formattedDuration = localeFormatter.formatDuration(minutes)
        
        // Then
        XCTAssertTrue(formattedDuration.contains("45"))
        XCTAssertTrue(formattedDuration.lowercased().contains("min"))
    }
    
    func testDurationFormattingHours() {
        // Given
        let minutes = 120 // 2 hours
        
        // When
        let formattedDuration = localeFormatter.formatDuration(minutes)
        
        // Then
        XCTAssertTrue(formattedDuration.contains("2"))
        XCTAssertTrue(formattedDuration.lowercased().contains("hour"))
    }
    
    func testDurationFormattingHoursAndMinutes() {
        // Given
        let minutes = 90 // 1 hour 30 minutes
        
        // When
        let formattedDuration = localeFormatter.formatDuration(minutes)
        
        // Then
        XCTAssertTrue(formattedDuration.contains("1"))
        XCTAssertTrue(formattedDuration.contains("30"))
        XCTAssertTrue(formattedDuration.lowercased().contains("hour"))
        XCTAssertTrue(formattedDuration.lowercased().contains("min"))
    }
    
    // MARK: - RTL Support Tests
    
    func testRTLLayoutDirection() {
        // Given
        let arabic = SupportedLanguage(code: "ar", nativeName: "العربية", englishName: "Arabic")
        localizationManager.changeLanguage(to: arabic)
        
        // When
        let layoutDirection = RTLSupport.layoutDirection
        
        // Then
        XCTAssertEqual(layoutDirection, .rightToLeft)
    }
    
    func testLTRLayoutDirection() {
        // Given
        let english = SupportedLanguage.english
        localizationManager.changeLanguage(to: english)
        
        // When
        let layoutDirection = RTLSupport.layoutDirection
        
        // Then
        XCTAssertEqual(layoutDirection, .leftToRight)
    }
    
    func testRTLChevronIcons() {
        // Given
        let arabic = SupportedLanguage(code: "ar", nativeName: "العربية", englishName: "Arabic")
        localizationManager.changeLanguage(to: arabic)
        
        // When
        let forwardChevron = RTLSupport.chevronForward
        let backChevron = RTLSupport.chevronBack
        
        // Then
        XCTAssertEqual(forwardChevron, "chevron.left")
        XCTAssertEqual(backChevron, "chevron.right")
    }
    
    func testLTRChevronIcons() {
        // Given
        let english = SupportedLanguage.english
        localizationManager.changeLanguage(to: english)
        
        // When
        let forwardChevron = RTLSupport.chevronForward
        let backChevron = RTLSupport.chevronBack
        
        // Then
        XCTAssertEqual(forwardChevron, "chevron.right")
        XCTAssertEqual(backChevron, "chevron.left")
    }
    
    // MARK: - Cultural Adaptations Tests
    
    func testCulturalColorAdaptations() {
        // Given
        let chinese = SupportedLanguage(code: "zh-Hans", nativeName: "简体中文", englishName: "Chinese (Simplified)")
        localizationManager.changeLanguage(to: chinese)
        
        // When
        let successColor = CulturalAdaptations.adaptedColor(for: .success)
        
        // Then
        XCTAssertNotNil(successColor)
    }
    
    func testCulturalIconAdaptations() {
        // Given
        let japanese = SupportedLanguage(code: "ja", nativeName: "日本語", englishName: "Japanese")
        localizationManager.changeLanguage(to: japanese)
        
        // When
        let restaurantIcon = CulturalAdaptations.adaptedIcon(for: .restaurant)
        
        // Then
        XCTAssertEqual(restaurantIcon, "chopsticks")
    }
    
    func testCulturalGreetings() {
        // Given
        let japanese = SupportedLanguage(code: "ja", nativeName: "日本語", englishName: "Japanese")
        localizationManager.changeLanguage(to: japanese)
        
        // When
        let morningGreeting = CulturalAdaptations.greeting(for: .morning)
        
        // Then
        XCTAssertEqual(morningGreeting, "おはようございます")
    }
    
    // MARK: - Performance Tests
    
    func testLocalizationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = "common.ok".localized
            }
        }
    }
    
    func testCurrencyFormattingPerformance() {
        measure {
            for i in 0..<1000 {
                _ = localeFormatter.formatCurrency(i * 100)
            }
        }
    }
    
    func testDateFormattingPerformance() {
        let date = Date()
        measure {
            for _ in 0..<1000 {
                _ = localeFormatter.formatDate(date)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyStringLocalization() {
        // Given
        let emptyKey = ""
        
        // When
        let localizedString = emptyKey.localized
        
        // Then
        XCTAssertEqual(localizedString, "")
    }
    
    func testNonExistentKeyLocalization() {
        // Given
        let nonExistentKey = "non.existent.key"
        
        // When
        let localizedString = nonExistentKey.localized
        
        // Then
        XCTAssertEqual(localizedString, nonExistentKey) // Should return the key itself
    }
    
    func testZeroCurrencyFormatting() {
        // Given
        let zeroCents = 0
        
        // When
        let formattedCurrency = localeFormatter.formatCurrency(zeroCents)
        
        // Then
        XCTAssertFalse(formattedCurrency.isEmpty)
        XCTAssertTrue(formattedCurrency.contains("0"))
    }
    
    func testNegativeCurrencyFormatting() {
        // Given
        let negativeCents = -1000 // -$10.00
        
        // When
        let formattedCurrency = localeFormatter.formatCurrency(negativeCents)
        
        // Then
        XCTAssertFalse(formattedCurrency.isEmpty)
        XCTAssertTrue(formattedCurrency.contains("10"))
        XCTAssertTrue(formattedCurrency.contains("-") || formattedCurrency.contains("("))
    }
}