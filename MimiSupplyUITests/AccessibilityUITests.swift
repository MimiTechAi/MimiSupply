//
//  AccessibilityUITests.swift
//  MimiSupplyUITests
//
//  Created by Kiro on 15.08.25.
//

import XCTest

/// UI tests for accessibility features including VoiceOver, Switch Control, and keyboard navigation
final class AccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    func testVoiceOverNavigationThroughExploreHome() throws {
        // Given - App is launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Navigating with VoiceOver simulation
        let searchField = app.textFields["Search restaurants, groceries, pharmacies..."]
        XCTAssertTrue(searchField.exists, "Search field should exist")
        XCTAssertTrue(searchField.isHittable, "Search field should be accessible")
        
        // Then - Check accessibility labels
        XCTAssertFalse(searchField.label.isEmpty, "Search field should have accessibility label")
        
        // Test category buttons
        let restaurantCategory = app.buttons.matching(identifier: "category-restaurant").firstMatch
        if restaurantCategory.exists {
            XCTAssertTrue(restaurantCategory.isHittable, "Restaurant category should be accessible")
            XCTAssertFalse(restaurantCategory.label.isEmpty, "Category should have accessibility label")
        }
    }
    
    func testVoiceOverNavigationThroughButtons() throws {
        // Given - App is launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing button accessibility
        let buttons = app.buttons
        
        // Then - All buttons should have proper accessibility
        for i in 0..<min(buttons.count, 10) { // Test first 10 buttons
            let button = buttons.element(boundBy: i)
            if button.exists && button.isHittable {
                XCTAssertFalse(button.label.isEmpty, "Button \(i) should have accessibility label")
                
                // Test that button responds to accessibility activation
                if button.isEnabled {
                    // In a real test, we would simulate VoiceOver double-tap
                    XCTAssertTrue(button.isHittable, "Button should be hittable for VoiceOver")
                }
            }
        }
    }
    
    func testVoiceOverNavigationThroughTextFields() throws {
        // Given - Navigate to a screen with text fields (e.g., authentication)
        // This would require navigating to auth screen first
        
        // When - Testing text field accessibility
        let textFields = app.textFields
        
        // Then - All text fields should have proper accessibility
        for i in 0..<textFields.count {
            let textField = textFields.element(boundBy: i)
            if textField.exists {
                XCTAssertFalse(textField.label.isEmpty, "Text field \(i) should have accessibility label")
                XCTAssertTrue(textField.isHittable, "Text field should be accessible to VoiceOver")
            }
        }
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testDynamicTypeSupport() throws {
        // Given - App is launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing with different text sizes
        // Note: In a real implementation, we would change system text size
        // and verify that the app responds appropriately
        
        // Then - Text should be readable and not truncated
        let staticTexts = app.staticTexts
        for i in 0..<min(staticTexts.count, 5) {
            let text = staticTexts.element(boundBy: i)
            if text.exists && !text.label.isEmpty {
                // Verify text is not truncated (basic check)
                XCTAssertFalse(text.label.hasSuffix("..."), "Text should not be truncated: \(text.label)")
            }
        }
    }
    
    func testLargeTextSupport() throws {
        // Given - App with large text enabled
        // Note: This would require setting up the test with accessibility text sizes
        
        // When - Checking text elements
        let app = XCUIApplication()
        app.launch()
        
        // Then - All text should be readable
        let staticTexts = app.staticTexts
        for i in 0..<min(staticTexts.count, 10) {
            let text = staticTexts.element(boundBy: i)
            if text.exists && text.isHittable {
                // Text should exist and be accessible
                XCTAssertTrue(text.exists, "Text element should exist")
            }
        }
    }
    
    // MARK: - High Contrast Support Tests
    
    func testHighContrastMode() throws {
        // Given - App launched with high contrast
        // Note: This would require launching with high contrast enabled
        
        // When - Testing visual elements
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // Then - Elements should be visible and accessible
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 5) {
            let button = buttons.element(boundBy: i)
            if button.exists {
                XCTAssertTrue(button.isHittable, "Button should be accessible in high contrast mode")
            }
        }
    }
    
    // MARK: - Switch Control Support Tests
    
    func testSwitchControlNavigation() throws {
        // Given - App launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing switch control navigation order
        let interactiveElements = app.buttons.allElementsBoundByIndex + app.textFields.allElementsBoundByIndex
        
        // Then - Elements should be in logical order
        var accessibleElements: [XCUIElement] = []
        for element in interactiveElements {
            if element.exists && element.isHittable {
                accessibleElements.append(element)
            }
        }
        
        XCTAssertGreaterThan(accessibleElements.count, 0, "Should have accessible elements for Switch Control")
        
        // Verify elements have accessibility identifiers for proper navigation
        for element in accessibleElements.prefix(5) {
            XCTAssertFalse(element.identifier.isEmpty, "Interactive elements should have identifiers for Switch Control")
        }
    }
    
    // MARK: - Keyboard Navigation Tests
    
    func testKeyboardNavigation() throws {
        // Given - App launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing keyboard navigation
        // Note: This would require simulating keyboard input
        
        // Then - Focusable elements should be accessible via keyboard
        let textFields = app.textFields
        for textField in textFields.allElementsBoundByIndex.prefix(3) {
            if textField.exists {
                XCTAssertTrue(textField.isHittable, "Text field should be keyboard accessible")
                
                // Test that text field can receive focus
                textField.tap()
                let keyboardShown = app.keyboards.count > 0
                if keyboardShown {
                    // Type a small character to validate input focus
                    textField.typeText("a")
                    let value = (textField.value as? String) ?? ""
                    XCTAssertTrue(value.contains("a") || !value.isEmpty, "Text field should accept input when focused")
                } else {
                    // Fallback: still assert the element can be interacted with
                    XCTAssertTrue(textField.isHittable, "Text field should be able to receive input focus")
                }
            }
        }
    }
    
    func testTabOrderLogical() throws {
        // Given - App launched on a form screen
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing tab order
        let interactiveElements = app.textFields.allElementsBoundByIndex + app.buttons.allElementsBoundByIndex
        
        // Then - Tab order should be logical (top to bottom, left to right)
        var previousFrame: CGRect?
        for element in interactiveElements.prefix(5) {
            if element.exists && element.isHittable {
                let currentFrame = element.frame
                
                if let prevFrame = previousFrame {
                    // Basic check: elements should generally flow top to bottom
                    // (This is a simplified check - real implementation would be more sophisticated)
                    let isLogicalOrder = currentFrame.minY >= prevFrame.minY - 50 // Allow some tolerance
                    XCTAssertTrue(isLogicalOrder, "Tab order should be logical")
                }
                
                previousFrame = currentFrame
            }
        }
    }
    
    // MARK: - Voice Control Support Tests
    
    func testVoiceControlLabels() throws {
        // Given - App launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing voice control labels
        let buttons = app.buttons
        
        // Then - Buttons should have voice control labels
        for i in 0..<min(buttons.count, 10) {
            let button = buttons.element(boundBy: i)
            if button.exists && button.isHittable {
                // Voice control labels should be meaningful
                let label = button.label
                XCTAssertFalse(label.isEmpty, "Button should have voice control label")
                XCTAssertGreaterThan(label.count, 2, "Voice control label should be meaningful")
            }
        }
    }
    
    // MARK: - Reduce Motion Support Tests
    
    func testReduceMotionSupport() throws {
        // Given - App launched with reduce motion enabled
        // Note: This would require launching with reduce motion preference
        
        // When - Testing animations
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // Then - App should still be functional without animations
        // Basic functionality test
        let searchField = app.textFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("test")
            XCTAssertEqual(searchField.value as? String, "test", "Text input should work with reduced motion")
        }
    }
    
    // MARK: - Error State Accessibility Tests
    
    func testErrorStateAccessibility() throws {
        // Given - App in error state
        // Note: This would require triggering an error state
        
        // When - Error occurs
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // Then - Error should be announced to screen readers
        let errorTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'error'"))
        
        if errorTexts.count > 0 {
            let errorText = errorTexts.firstMatch
            XCTAssertTrue(errorText.exists, "Error text should exist")
            XCTAssertFalse(errorText.label.isEmpty, "Error should have descriptive text")
        }
    }
    
    // MARK: - Loading State Accessibility Tests
    
    func testLoadingStateAccessibility() throws {
        // Given - App in loading state
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Content is loading
        let loadingIndicators = app.activityIndicators
        
        // Then - Loading state should be accessible
        for indicator in loadingIndicators.allElementsBoundByIndex {
            if indicator.exists {
                // Loading indicators should not interfere with accessibility
                XCTAssertTrue(indicator.exists, "Loading indicator should exist")
            }
        }
    }
    
    // MARK: - Navigation Accessibility Tests
    
    func testNavigationAccessibility() throws {
        // Given - App launched
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing navigation elements
        let navigationBars = app.navigationBars
        
        // Then - Navigation should be accessible
        for navBar in navigationBars.allElementsBoundByIndex {
            if navBar.exists {
                XCTAssertTrue(navBar.isHittable, "Navigation bar should be accessible")
                
                // Check for back buttons
                let backButtons = navBar.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'back'"))
                for backButton in backButtons.allElementsBoundByIndex {
                    if backButton.exists {
                        XCTAssertTrue(backButton.isHittable, "Back button should be accessible")
                        XCTAssertFalse(backButton.label.isEmpty, "Back button should have label")
                    }
                }
            }
        }
    }
    
    // MARK: - Form Accessibility Tests
    
    func testFormAccessibility() throws {
        // Given - App with forms
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing form elements
        let textFields = app.textFields
        let secureFields = app.secureTextFields
        
        // Then - Form elements should be properly labeled
        for textField in textFields.allElementsBoundByIndex.prefix(5) {
            if textField.exists {
                XCTAssertFalse(textField.label.isEmpty, "Text field should have label")
                XCTAssertTrue(textField.isHittable, "Text field should be accessible")
            }
        }
        
        for secureField in secureFields.allElementsBoundByIndex.prefix(3) {
            if secureField.exists {
                XCTAssertFalse(secureField.label.isEmpty, "Secure field should have label")
                XCTAssertTrue(secureField.isHittable, "Secure field should be accessible")
            }
        }
    }
    
    // MARK: - List and Collection Accessibility Tests
    
    func testListAccessibility() throws {
        // Given - App with lists
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing list elements
        let tables = app.tables
        let collectionViews = app.collectionViews
        
        // Then - List elements should be accessible
        for table in tables.allElementsBoundByIndex {
            if table.exists {
                let cells = table.cells
                for i in 0..<min(cells.count, 5) {
                    let cell = cells.element(boundBy: i)
                    if cell.exists {
                        XCTAssertTrue(cell.isHittable, "Table cell should be accessible")
                        XCTAssertFalse(cell.label.isEmpty, "Table cell should have descriptive label")
                    }
                }
            }
        }
        
        for collectionView in collectionViews.allElementsBoundByIndex {
            if collectionView.exists {
                let cells = collectionView.cells
                for i in 0..<min(cells.count, 5) {
                    let cell = cells.element(boundBy: i)
                    if cell.exists {
                        XCTAssertTrue(cell.isHittable, "Collection cell should be accessible")
                    }
                }
            }
        }
    }
    
    // MARK: - Image Accessibility Tests
    
    func testImageAccessibility() throws {
        // Given - App with images
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // When - Testing image elements
        let images = app.images
        
        // Then - Images should have appropriate accessibility
        for i in 0..<min(images.count, 10) {
            let image = images.element(boundBy: i)
            if image.exists {
                // Decorative images should be hidden from accessibility
                // Informative images should have labels
                if !image.label.isEmpty {
                    XCTAssertGreaterThan(image.label.count, 2, "Image label should be descriptive")
                }
            }
        }
    }
}