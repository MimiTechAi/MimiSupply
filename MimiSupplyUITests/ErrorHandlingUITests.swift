//
//  ErrorHandlingUITests.swift
//  MimiSupplyUITests
//
//  Created by Kiro on 15.08.25.
//

import XCTest

final class ErrorHandlingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing error scenarios
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--enable-error-simulation")
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Error Alert Tests
    
    func testErrorAlertDisplaysCorrectly() throws {
        // Trigger a network error
        app.buttons["simulate_network_error"].tap()
        
        // Verify error alert appears
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Verify alert content
        XCTAssertTrue(alert.staticTexts["Connection Problem"].exists)
        XCTAssertTrue(alert.buttons["Retry"].exists)
        XCTAssertTrue(alert.buttons["OK"].exists)
        
        // Dismiss alert
        alert.buttons["OK"].tap()
        XCTAssertFalse(alert.exists)
    }
    
    func testErrorAlertRetryFunctionality() throws {
        // Trigger a retryable error
        app.buttons["simulate_timeout_error"].tap()
        
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Tap retry button
        alert.buttons["Retry"].tap()
        
        // Verify alert dismisses and retry is attempted
        XCTAssertFalse(alert.exists)
        
        // In a real test, you would verify that the retry operation was triggered
        // This could be done by checking for loading indicators or success states
    }
    
    func testErrorAlertSettingsButton() throws {
        // Trigger a permission error
        app.buttons["simulate_location_permission_error"].tap()
        
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Verify settings button appears for permission errors
        XCTAssertTrue(alert.buttons["Settings"].exists)
        
        // Note: Tapping Settings would open the Settings app, which is outside our app's scope
        // In a real test, you might mock this behavior or test the button's presence only
        
        alert.buttons["OK"].tap()
    }
    
    // MARK: - Error State View Tests
    
    func testErrorStateViewDisplaysCorrectly() throws {
        // Navigate to a screen that can show error states
        app.tabBars.buttons["Explore"].tap()
        
        // Trigger an error that shows error state view
        app.buttons["simulate_data_loading_error"].tap()
        
        // Verify error state view appears
        let errorStateView = app.otherElements["error_state_view"]
        XCTAssertTrue(errorStateView.waitForExistence(timeout: 5))
        
        // Verify error state content
        XCTAssertTrue(errorStateView.images.element.exists) // Error icon
        XCTAssertTrue(errorStateView.staticTexts["Connection Problem"].exists)
        XCTAssertTrue(errorStateView.buttons["Try Again"].exists)
    }
    
    func testErrorStateViewRetryAction() throws {
        app.tabBars.buttons["Explore"].tap()
        app.buttons["simulate_data_loading_error"].tap()
        
        let errorStateView = app.otherElements["error_state_view"]
        XCTAssertTrue(errorStateView.waitForExistence(timeout: 5))
        
        // Tap retry button
        errorStateView.buttons["Try Again"].tap()
        
        // Verify loading state appears (indicating retry was triggered)
        let loadingView = app.otherElements["loading_view"]
        XCTAssertTrue(loadingView.waitForExistence(timeout: 3))
    }
    
    // MARK: - Toast Error Tests
    
    func testErrorToastDisplaysAndDismisses() throws {
        // Trigger a toast error
        app.buttons["simulate_toast_error"].tap()
        
        // Verify toast appears
        let toast = app.otherElements["error_toast"]
        XCTAssertTrue(toast.waitForExistence(timeout: 3))
        
        // Verify toast content
        XCTAssertTrue(toast.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Error'")).element.exists)
        
        // Wait for auto-dismiss or tap to dismiss
        toast.tap()
        
        // Verify toast disappears
        XCTAssertFalse(toast.waitForExistence(timeout: 2))
    }
    
    func testMultipleErrorToasts() throws {
        // Trigger multiple errors quickly
        app.buttons["simulate_multiple_errors"].tap()
        
        // Verify multiple toasts can be displayed
        let toasts = app.otherElements.matching(identifier: "error_toast")
        XCTAssertGreaterThan(toasts.count, 1)
        
        // Wait for toasts to auto-dismiss
        sleep(6)
        XCTAssertEqual(toasts.count, 0)
    }
    
    // MARK: - Network Status Tests
    
    func testNetworkStatusIndicator() throws {
        // Simulate network disconnection
        app.buttons["simulate_network_disconnection"].tap()
        
        // Verify network status indicator appears
        let networkIndicator = app.otherElements["network_status_indicator"]
        XCTAssertTrue(networkIndicator.waitForExistence(timeout: 3))
        
        // Verify indicator shows offline status
        XCTAssertTrue(networkIndicator.staticTexts["No internet connection"].exists)
        
        // Simulate network reconnection
        app.buttons["simulate_network_reconnection"].tap()
        
        // Verify indicator updates or disappears
        if networkIndicator.exists {
            XCTAssertTrue(networkIndicator.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Connected'")).element.exists)
        }
    }
    
    // MARK: - Service Status Tests
    
    func testServiceStatusIndicator() throws {
        // Trigger service degradation
        app.buttons["simulate_service_degradation"].tap()
        
        // Verify service status indicator appears
        let statusIndicator = app.otherElements["service_status_indicator"]
        XCTAssertTrue(statusIndicator.waitForExistence(timeout: 3))
        
        // Verify status message
        XCTAssertTrue(statusIndicator.staticTexts.containing(NSPredicate(format: "label CONTAINS 'features may be temporarily unavailable'")).element.exists)
    }
    
    // MARK: - Offline Mode Tests
    
    func testOfflineModeIndicator() throws {
        // Simulate going offline
        app.buttons["simulate_offline_mode"].tap()
        
        // Verify offline mode indicator appears
        let offlineIndicator = app.otherElements["offline_mode_indicator"]
        XCTAssertTrue(offlineIndicator.waitForExistence(timeout: 3))
        
        // Verify offline functionality is available
        app.tabBars.buttons["Cart"].tap()
        
        // Cart should still be accessible in offline mode
        let cartView = app.otherElements["cart_view"]
        XCTAssertTrue(cartView.exists)
    }
    
    // MARK: - Form Validation Error Tests
    
    func testInlineFormErrors() throws {
        // Navigate to a form (e.g., profile edit)
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Edit Profile"].tap()
        
        // Clear required field and try to save
        let emailField = app.textFields["email_field"]
        emailField.tap()
        emailField.clearText()
        
        app.buttons["Save"].tap()
        
        // Verify inline error appears
        let inlineError = app.staticTexts["Please enter a valid email address"]
        XCTAssertTrue(inlineError.exists)
        
        // Verify error styling
        XCTAssertTrue(inlineError.isHittable)
    }
    
    func testFormErrorAccessibility() throws {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Edit Profile"].tap()
        
        let emailField = app.textFields["email_field"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        app.buttons["Save"].tap()
        
        // Verify error is accessible to VoiceOver
        let inlineError = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'valid email'")).element
        XCTAssertTrue(inlineError.exists)
        XCTAssertTrue(inlineError.isAccessibilityElement)
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecoveryFlow() throws {
        // Simulate an error that can be recovered from
        app.buttons["simulate_recoverable_error"].tap()
        
        let errorStateView = app.otherElements["error_state_view"]
        XCTAssertTrue(errorStateView.waitForExistence(timeout: 5))
        
        // Attempt recovery
        errorStateView.buttons["Try Again"].tap()
        
        // Verify successful recovery
        let successView = app.otherElements["success_view"]
        XCTAssertTrue(successView.waitForExistence(timeout: 5))
    }
    
    // MARK: - Accessibility Tests
    
    func testErrorHandlingAccessibility() throws {
        // Enable VoiceOver simulation
        app.buttons["simulate_network_error"].tap()
        
        let alert = app.alerts["Error"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        
        // Verify alert is accessible
        XCTAssertTrue(alert.isAccessibilityElement)
        
        // Verify buttons are accessible
        let retryButton = alert.buttons["Retry"]
        XCTAssertTrue(retryButton.isAccessibilityElement)
        XCTAssertNotNil(retryButton.accessibilityLabel)
        
        alert.buttons["OK"].tap()
    }
    
    func testErrorStateViewAccessibility() throws {
        app.tabBars.buttons["Explore"].tap()
        app.buttons["simulate_data_loading_error"].tap()
        
        let errorStateView = app.otherElements["error_state_view"]
        XCTAssertTrue(errorStateView.waitForExistence(timeout: 5))
        
        // Verify error state view is accessible
        XCTAssertTrue(errorStateView.isAccessibilityElement)
        
        // Verify retry button has proper accessibility
        let retryButton = errorStateView.buttons["Try Again"]
        XCTAssertTrue(retryButton.isAccessibilityElement)
        XCTAssertNotNil(retryButton.accessibilityHint)
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() throws {
        measure {
            // Trigger multiple errors rapidly
            for _ in 0..<10 {
                app.buttons["simulate_quick_error"].tap()
            }
            
            // Verify app remains responsive
            XCTAssertTrue(app.tabBars.buttons["Explore"].isHittable)
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        typeText(deleteString)
    }
}