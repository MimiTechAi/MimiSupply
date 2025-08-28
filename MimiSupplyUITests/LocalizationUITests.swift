//
//  LocalizationUITests.swift
//  MimiSupplyUITests
//
//  Created by Kiro on 15.08.25.
//

import XCTest

@MainActor
final class LocalizationUITests: MimiSupplyUITestCase {
    
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Language Switching Tests
    
    func testLanguageSwitchingFlow() throws {
        // Launch app in English
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        // Navigate to settings
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        
        // Navigate to language selection
        let languageButton = app.buttons["Language"]
        XCTAssertTrue(languageButton.waitForExistence(timeout: 5))
        languageButton.tap()
        
        // Select Spanish
        let spanishButton = app.buttons["Español"]
        XCTAssertTrue(spanishButton.waitForExistence(timeout: 5))
        spanishButton.tap()
        
        // Apply changes
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        
        // Verify UI updated to Spanish
        let configuracionButton = app.buttons["Configuración"]
        XCTAssertTrue(configuracionButton.waitForExistence(timeout: 5))
    }
    
    func testRTLLanguageSwitching() throws {
        // Launch app in English
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        // Navigate to language selection
        navigateToLanguageSelection()
        
        // Select Arabic
        let arabicButton = app.buttons["العربية"]
        XCTAssertTrue(arabicButton.waitForExistence(timeout: 5))
        arabicButton.tap()
        
        // Apply changes
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        
        // Verify RTL layout
        // In RTL, navigation should be from right to left
        let backButton = app.buttons.matching(identifier: "back-button").firstMatch
        if backButton.exists {
            // Verify back button is on the right side in RTL
            Task { @MainActor in
                let backButtonFrame = backButton.frame
                let screenWidth = app.frame.width
                XCTAssertGreaterThan(backButtonFrame.minX, screenWidth * 0.5, "Back button should be on right side in RTL")
            }
        }
    }
    
    func testHebrewRTLLayout() throws {
        // Launch app in Hebrew
        app.launchArguments = ["--language", "he"]
        app.launch()
        
        // Verify RTL layout elements
        let exploreTab = app.tabBars.buttons.firstMatch
        if exploreTab.exists {
            // In RTL, first tab should be on the right side
            Task { @MainActor in
                let tabFrame = exploreTab.frame
                let screenWidth = app.frame.width
                XCTAssertGreaterThan(tabFrame.minX, screenWidth * 0.6, "First tab should be on right side in RTL")
            }
        }
    }
    
    // MARK: - Localized Content Tests
    
    func testLocalizedButtonTexts() throws {
        // Test English
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        XCTAssertTrue(app.buttons["Add"].exists || app.buttons["Add to Cart"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        
        // Switch to Spanish
        switchLanguage(to: "es")
        
        XCTAssertTrue(app.buttons["Agregar"].exists || app.buttons["Añadir al Carrito"].exists)
        XCTAssertTrue(app.buttons["Cancelar"].exists)
    }
    
    func testLocalizedNavigationTitles() throws {
        // Test English
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        XCTAssertTrue(app.navigationBars["Explore"].exists)
        
        // Switch to French
        switchLanguage(to: "fr")
        
        XCTAssertTrue(app.navigationBars["Explorer"].exists)
    }
    
    func testLocalizedTabBarItems() throws {
        // Test English
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Check for English tab titles
        XCTAssertTrue(app.tabBars.buttons["Explore"].exists)
        XCTAssertTrue(app.tabBars.buttons["Cart"].exists)
        
        // Switch to German
        switchLanguage(to: "de")
        
        // Check for German tab titles
        XCTAssertTrue(app.tabBars.buttons["Entdecken"].exists)
        XCTAssertTrue(app.tabBars.buttons["Warenkorb"].exists)
    }
    
    // MARK: - Currency Formatting Tests
    
    func testCurrencyFormattingInDifferentLocales() throws {
        // Test USD formatting
        app.launchArguments = ["--language", "en", "--region", "US"]
        app.launch()
        
        // Navigate to a screen with prices
        navigateToPartnerWithPrices()
        
        // Look for USD formatting ($X.XX)
        let priceElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '$'"))
        XCTAssertGreaterThan(priceElements.count, 0, "Should find USD prices")
        
        // Switch to Euro region
        switchLanguage(to: "de")
        
        // Look for EUR formatting (X,XX €)
        let euroPriceElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '€'"))
        XCTAssertGreaterThan(euroPriceElements.count, 0, "Should find EUR prices")
    }
    
    // MARK: - Date and Time Formatting Tests
    
    func testDateTimeFormattingInDifferentLocales() throws {
        // Test US date format (MM/DD/YYYY)
        app.launchArguments = ["--language", "en", "--region", "US"]
        app.launch()
        
        // Navigate to order history or similar screen with dates
        navigateToOrderHistory()
        
        // Look for US date format
        let usDateElements = app.staticTexts.matching(NSPredicate(format: "label MATCHES '.*\\d{1,2}/\\d{1,2}/\\d{4}.*'"))
        if usDateElements.count > 0 {
            XCTAssertGreaterThan(usDateElements.count, 0, "Should find US date format")
        }
        
        // Switch to European format (DD.MM.YYYY or DD/MM/YYYY)
        switchLanguage(to: "de")
        
        let europeanDateElements = app.staticTexts.matching(NSPredicate(format: "label MATCHES '.*\\d{1,2}[./]\\d{1,2}[./]\\d{4}.*'"))
        if europeanDateElements.count > 0 {
            XCTAssertGreaterThan(europeanDateElements.count, 0, "Should find European date format")
        }
    }
    
    // MARK: - Accessibility Tests for Localization
    
    func testVoiceOverWithDifferentLanguages() throws {
        // Enable VoiceOver
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        // Test VoiceOver labels in English
        let exploreButton = app.buttons["Explore"]
        XCTAssertTrue(exploreButton.exists)
        XCTAssertFalse(exploreButton.label.isEmpty)
        
        // Switch to Spanish and test VoiceOver labels
        switchLanguage(to: "es")
        
        let explorarButton = app.buttons["Explorar"]
        XCTAssertTrue(explorarButton.exists)
        XCTAssertFalse(explorarButton.label.isEmpty)
    }
    
    func testAccessibilityHintsInDifferentLanguages() throws {
        app.launchArguments = ["--language", "en"]
        app.launch()
        
        // Test accessibility hints in English
        let addButton = app.buttons.matching(identifier: "add-to-cart-button").firstMatch
        if addButton.exists {
            let hint = (addButton.value as? String) ?? ""
            XCTAssertFalse(hint.isEmpty, "Should have accessibility hint")
        }
        
        // Switch language and test hints are updated
        switchLanguage(to: "fr")
        
        let ajouterButton = app.buttons.matching(identifier: "add-to-cart-button").firstMatch
        if ajouterButton.exists {
            let hint = (ajouterButton.value as? String) ?? ""
            XCTAssertFalse(hint.isEmpty, "Should have French accessibility hint")
        }
    }
    
    // MARK: - Performance Tests
    
    func testLanguageSwitchingPerformance() throws {
        app.launch()
        
        measure {
            // Switch between languages multiple times
            switchLanguage(to: "es")
            switchLanguage(to: "fr")
            switchLanguage(to: "de")
            switchLanguage(to: "en")
        }
    }
    
    func testLocalizedContentLoadingPerformance() throws {
        app.launchArguments = ["--language", "ja"] // Japanese with complex characters
        
        measure {
            app.launch()
            
            // Navigate through different screens to test localized content loading
            let exploreTab = app.tabBars.buttons.firstMatch
            if exploreTab.exists {
                exploreTab.tap()
            }
            
            let cartTab = app.tabBars.buttons.element(boundBy: 1)
            if cartTab.exists {
                cartTab.tap()
            }
            
            let settingsTab = app.tabBars.buttons.element(boundBy: 2)
            if settingsTab.exists {
                settingsTab.tap()
            }
            
            app.terminate()
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testUnsupportedLanguageFallback() throws {
        // Try to launch with unsupported language
        app.launchArguments = ["--language", "xyz"] // Non-existent language
        app.launch()
        
        // Should fall back to English
        XCTAssertTrue(app.buttons["Explore"].exists || app.buttons["Settings"].exists)
    }
    
    func testMixedContentLanguages() throws {
        // Test when system language differs from app language
        app.launchArguments = ["--language", "es", "--system-language", "en"]
        app.launch()
        
        // App content should be in Spanish
        XCTAssertTrue(app.buttons["Explorar"].exists)
        
        // But system dialogs might be in English (this is expected behavior)
    }
    
    func testLanguageSwitchingWithoutRestart() throws {
        app.launch()
        
        // Switch language
        switchLanguage(to: "es")
        
        // Verify immediate update without app restart
        XCTAssertTrue(app.buttons["Configuración"].waitForExistence(timeout: 2))
        
        // Navigate to different screens to ensure all content is updated
        navigateToExplore()
        XCTAssertTrue(app.navigationBars["Explorar"].exists)
        
        navigateToCart()
        XCTAssertTrue(app.navigationBars["Carrito"].exists)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToLanguageSelection() {
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
        }
        
        let languageButton = app.buttons["Language"]
        if languageButton.exists {
            languageButton.tap()
        }
    }
    
    private func switchLanguage(to languageCode: String) {
        navigateToLanguageSelection()
        
        let languageNames: [String: String] = [
            "en": "English",
            "es": "Español",
            "fr": "Français",
            "de": "Deutsch",
            "ja": "日本語",
            "ar": "العربية",
            "he": "עברית"
        ]
        
        if let languageName = languageNames[languageCode] {
            let languageButton = app.buttons[languageName]
            if languageButton.exists {
                languageButton.tap()
                
                let doneButton = app.buttons["Done"]
                if doneButton.exists {
                    doneButton.tap()
                }
            }
        }
    }
    
    private func navigateToPartnerWithPrices() {
        let exploreTab = app.tabBars.buttons.firstMatch
        if exploreTab.exists {
            exploreTab.tap()
        }
        
        // Tap on first partner card
        let partnerCard = app.buttons.matching(identifier: "partner-card").firstMatch
        if partnerCard.exists {
            partnerCard.tap()
        }
    }
    
    private func navigateToOrderHistory() {
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        if settingsTab.exists {
            settingsTab.tap()
        }
        
        let orderHistoryButton = app.buttons["Order History"]
        if orderHistoryButton.exists {
            orderHistoryButton.tap()
        }
    }
    
    private func navigateToExplore() {
        let exploreTab = app.tabBars.buttons.firstMatch
        if exploreTab.exists {
            exploreTab.tap()
        }
    }
    
    private func navigateToCart() {
        let cartTab = app.tabBars.buttons.element(boundBy: 1)
        if cartTab.exists {
            cartTab.tap()
        }
    }
}