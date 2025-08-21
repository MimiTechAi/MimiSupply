//
//  SettingsUITests.swift
//  MimiSupplyUITests
//
//  Created by Kiro on 15.08.25.
//

import XCTest

/// UI tests for settings and profile management functionality
final class SettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Settings Navigation Tests
    
    func testNavigateToSettings() throws {
        // Given - App is launched and user is authenticated
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Navigate to settings
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            
            // Then - Settings view should be displayed
            let settingsTitle = app.navigationBars["Settings"]
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testSettingsViewElements() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // Then - Verify key settings elements exist
        XCTAssertTrue(app.staticTexts["Profile"].exists)
        XCTAssertTrue(app.staticTexts["Account"].exists)
        XCTAssertTrue(app.staticTexts["Preferences"].exists)
        XCTAssertTrue(app.staticTexts["Privacy & Security"].exists)
        XCTAssertTrue(app.staticTexts["Support"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)
    }
    
    // MARK: - Profile Edit Tests
    
    func testProfileEditNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap edit profile button
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // Then - Profile edit view should appear
            let profileEditTitle = app.navigationBars["Edit Profile"]
            XCTAssertTrue(profileEditTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testProfileEditForm() throws {
        // Given - Navigate to profile edit
        navigateToSettings()
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // When - Check form elements
            let firstNameField = app.textFields["first-name-field"]
            let lastNameField = app.textFields["last-name-field"]
            let emailField = app.textFields["email-field"]
            let phoneField = app.textFields["phone-field"]
            
            // Then - Form fields should exist
            XCTAssertTrue(firstNameField.waitForExistence(timeout: 3))
            XCTAssertTrue(lastNameField.exists)
            XCTAssertTrue(emailField.exists)
            XCTAssertTrue(phoneField.exists)
        }
    }
    
    func testProfileEditValidation() throws {
        // Given - Navigate to profile edit
        navigateToSettings()
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // When - Clear required fields and try to save
            let firstNameField = app.textFields["first-name-field"]
            if firstNameField.exists {
                firstNameField.tap()
                firstNameField.clearAndEnterText("")
                
                let saveButton = app.navigationBars.buttons["Save"]
                
                // Then - Save button should be disabled
                XCTAssertFalse(saveButton.isEnabled)
            }
        }
    }
    
    func testProfilePhotoSelection() throws {
        // Given - Navigate to profile edit
        navigateToSettings()
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // When - Tap change photo button
            let changePhotoButton = app.buttons["Change profile photo"]
            if changePhotoButton.exists {
                changePhotoButton.tap()
                
                // Then - Photo picker should appear (system UI)
                // Note: Testing system photo picker requires special handling
            }
        }
    }
    
    // MARK: - Language Selection Tests
    
    func testLanguageSelectionNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap language setting
        let languageRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Language'")).firstMatch
        if languageRow.exists {
            languageRow.tap()
            
            // Then - Language selection view should appear
            let languageTitle = app.navigationBars["Language"]
            XCTAssertTrue(languageTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testLanguageList() throws {
        // Given - Navigate to language selection
        navigateToSettings()
        let languageRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Language'")).firstMatch
        if languageRow.exists {
            languageRow.tap()
            
            // Then - Language options should be available
            XCTAssertTrue(app.buttons["language-en"].waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["language-es"].exists)
            XCTAssertTrue(app.buttons["language-fr"].exists)
            XCTAssertTrue(app.buttons["language-de"].exists)
        }
    }
    
    func testLanguageSelection() throws {
        // Given - Navigate to language selection
        navigateToSettings()
        let languageRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Language'")).firstMatch
        if languageRow.exists {
            languageRow.tap()
            
            // When - Select a different language
            let spanishOption = app.buttons["language-es"]
            if spanishOption.exists {
                spanishOption.tap()
                
                // Then - Selection should be indicated
                XCTAssertTrue(spanishOption.images["checkmark"].exists)
            }
        }
    }
    
    // MARK: - Account Management Tests
    
    func testSignOutConfirmation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap sign out
        let signOutButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Sign Out'")).firstMatch
        if signOutButton.exists {
            signOutButton.tap()
            
            // Then - Confirmation alert should appear
            let alert = app.alerts["Sign Out"]
            XCTAssertTrue(alert.waitForExistence(timeout: 3))
            XCTAssertTrue(alert.buttons["Cancel"].exists)
            XCTAssertTrue(alert.buttons["Sign Out"].exists)
            
            // Cancel the action
            alert.buttons["Cancel"].tap()
        }
    }
    
    func testDeleteAccountConfirmation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Scroll to and tap delete account
        let deleteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Delete Account'")).firstMatch
        if deleteButton.exists {
            // Scroll to make sure it's visible
            deleteButton.scrollToElement()
            deleteButton.tap()
            
            // Then - Confirmation alert should appear
            let alert = app.alerts["Delete Account"]
            XCTAssertTrue(alert.waitForExistence(timeout: 3))
            XCTAssertTrue(alert.buttons["Cancel"].exists)
            XCTAssertTrue(alert.buttons["Delete"].exists)
            
            // Cancel the action
            alert.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - Notification Settings Tests
    
    func testNotificationSettingsNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap notifications setting
        let notificationsRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Notifications'")).firstMatch
        if notificationsRow.exists {
            notificationsRow.tap()
            
            // Then - Should navigate to system settings
            // Note: This would open system settings, which is outside our app
        }
    }
    
    // MARK: - Privacy Settings Tests
    
    func testPrivacySettingsNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap privacy & security setting
        let privacyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Privacy & Security'")).firstMatch
        if privacyRow.exists {
            privacyRow.tap()
            
            // Then - Privacy settings should be accessible
            // Note: Implementation depends on specific privacy settings view
        }
    }
    
    // MARK: - Support Tests
    
    func testHelpAndSupportNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap help & support
        let supportRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Help & Support'")).firstMatch
        if supportRow.exists {
            supportRow.tap()
            
            // Then - Support view should be accessible
            // Note: Implementation depends on specific support view
        }
    }
    
    func testRateAppAction() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap rate app
        let rateAppRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Rate App'")).firstMatch
        if rateAppRow.exists {
            rateAppRow.tap()
            
            // Then - App Store rating should be triggered
            // Note: This would show system rating dialog
        }
    }
    
    func testSendFeedbackAction() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap send feedback
        let feedbackRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Send Feedback'")).firstMatch
        if feedbackRow.exists {
            feedbackRow.tap()
            
            // Then - Mail app should open
            // Note: This would open system mail app
        }
    }
    
    // MARK: - About Section Tests
    
    func testAboutInformation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Check about section
        let aboutRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'About MimiSupply'")).firstMatch
        
        // Then - Version information should be displayed
        XCTAssertTrue(aboutRow.exists)
        XCTAssertTrue(aboutRow.label.contains("Version"))
    }
    
    func testTermsOfServiceNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap terms of service
        let termsRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Terms of Service'")).firstMatch
        if termsRow.exists {
            termsRow.tap()
            
            // Then - Should open terms URL
            // Note: This would open Safari or in-app browser
        }
    }
    
    func testPrivacyPolicyNavigation() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // When - Tap privacy policy
        let privacyPolicyRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Privacy Policy'")).firstMatch
        if privacyPolicyRow.exists {
            privacyPolicyRow.tap()
            
            // Then - Should open privacy policy URL
            // Note: This would open Safari or in-app browser
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testSettingsAccessibilityLabels() throws {
        // Given - Navigate to settings
        navigateToSettings()
        
        // Then - All settings rows should have proper accessibility labels
        let settingsRows = app.buttons.allElementsBoundByIndex
        
        for row in settingsRows.prefix(10) { // Test first 10 rows
            if row.exists {
                XCTAssertFalse(row.label.isEmpty, "Settings row should have accessibility label")
            }
        }
    }
    
    func testProfileEditAccessibility() throws {
        // Given - Navigate to profile edit
        navigateToSettings()
        let editButton = app.buttons["Edit"]
        if editButton.exists {
            editButton.tap()
            
            // Then - Form fields should have proper accessibility
            let textFields = app.textFields.allElementsBoundByIndex
            
            for field in textFields {
                if field.exists {
                    XCTAssertFalse(field.label.isEmpty, "Text field should have accessibility label")
                }
            }
        }
    }
    
    func testLanguageSelectionAccessibility() throws {
        // Given - Navigate to language selection
        navigateToSettings()
        let languageRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Language'")).firstMatch
        if languageRow.exists {
            languageRow.tap()
            
            // Then - Language options should have proper accessibility
            let languageButtons = app.buttons.allElementsBoundByIndex
            
            for button in languageButtons.prefix(10) { // Test first 10 languages
                if button.exists && button.identifier.starts(with: "language-") {
                    XCTAssertFalse(button.label.isEmpty, "Language button should have accessibility label")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        }
    }
}
// MARK: - XCUIElement Extensions

extension XCUIElement {
    // clearAndEnterText is defined in ComprehensiveUITests.swift to avoid duplicate declarations
    
    func scrollToElement() {
        while !self.isHittable {
            XCUIApplication().swipeUp()
        }
    }
}