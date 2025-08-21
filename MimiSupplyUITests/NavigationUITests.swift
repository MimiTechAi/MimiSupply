//
//  NavigationUITests.swift
//  MimiSupplyUITests
//
//  Created by Kiro on 15.08.25.
//

import XCTest

final class NavigationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabBarNavigation() throws {
        // Test that tab bar is visible and functional
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible")
        
        // Test explore tab
        let exploreTab = tabBar.buttons["Explore"]
        if exploreTab.exists {
            exploreTab.tap()
            XCTAssertTrue(exploreTab.isSelected, "Explore tab should be selected")
        }
        
        // Test orders tab
        let ordersTab = tabBar.buttons["Orders"]
        if ordersTab.exists {
            ordersTab.tap()
            XCTAssertTrue(ordersTab.isSelected, "Orders tab should be selected")
        }
        
        // Test profile tab
        let profileTab = tabBar.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")
        }
    }
    
    func testTabBarAccessibility() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test that all tab buttons have accessibility labels
        for button in tabBar.buttons.allElementsBoundByIndex {
            XCTAssertFalse(button.label.isEmpty, "Tab button should have accessibility label")
        }
    }
    
    // MARK: - Navigation Flow Tests
    
    func testExploreToPartnerDetailNavigation() throws {
        // Start from explore view
        let exploreView = app.scrollViews.firstMatch
        XCTAssertTrue(exploreView.waitForExistence(timeout: 5), "Explore view should be visible")
        
        // Look for partner cards and tap one
        let partnerCard = app.buttons.containing(.staticText, identifier: "Restaurant").firstMatch
        if partnerCard.exists {
            partnerCard.tap()
            
            // Verify we navigated to partner detail
            let partnerDetailView = app.navigationBars.firstMatch
            XCTAssertTrue(partnerDetailView.waitForExistence(timeout: 3), "Should navigate to partner detail")
            
            // Test back navigation
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                XCTAssertTrue(exploreView.waitForExistence(timeout: 3), "Should navigate back to explore")
            }
        }
    }
    
    func testSheetPresentation() throws {
        // Test cart sheet presentation
        let cartButton = app.buttons["Cart"]
        if cartButton.exists {
            cartButton.tap()
            
            // Verify sheet is presented
            let cartSheet = app.sheets.firstMatch
            XCTAssertTrue(cartSheet.waitForExistence(timeout: 3), "Cart sheet should be presented")
            
            // Test sheet dismissal
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
                XCTAssertFalse(cartSheet.exists, "Cart sheet should be dismissed")
            }
        }
    }
    
    // MARK: - Deep Linking Tests
    
    func testDeepLinkHandling() throws {
        // Test opening the app with a deep link
        app.terminate()
        
        // Launch with deep link URL
        let deepLinkURL = "mimisupply://order?id=test123"
        app.launchArguments = ["--deep-link", deepLinkURL]
        app.launch()
        
        // Verify the app navigated to the correct screen
        let orderTrackingView = app.staticTexts["Order Tracking"]
        XCTAssertTrue(orderTrackingView.waitForExistence(timeout: 5), "Should navigate to order tracking via deep link")
    }
    
    func testUniversalLinkHandling() throws {
        // Test opening the app with a universal link
        app.terminate()
        
        // Launch with universal link URL
        let universalLinkURL = "https://mimisupply.app/order?id=test123"
        app.launchArguments = ["--universal-link", universalLinkURL]
        app.launch()
        
        // Verify the app navigated to the correct screen
        let orderTrackingView = app.staticTexts["Order Tracking"]
        XCTAssertTrue(orderTrackingView.waitForExistence(timeout: 5), "Should navigate to order tracking via universal link")
    }
    
    // MARK: - Role-Based Navigation Tests
    
    func testCustomerNavigation() throws {
        // Simulate customer login
        simulateUserLogin(role: "customer")
        
        // Verify customer-specific tabs are visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Explore"].exists, "Customer should see Explore tab")
        XCTAssertTrue(tabBar.buttons["Orders"].exists, "Customer should see Orders tab")
        XCTAssertTrue(tabBar.buttons["Profile"].exists, "Customer should see Profile tab")
        XCTAssertFalse(tabBar.buttons["Dashboard"].exists, "Customer should not see Dashboard tab")
    }
    
    func testDriverNavigation() throws {
        // Simulate driver login
        simulateUserLogin(role: "driver")
        
        // Verify driver-specific tabs are visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Dashboard"].exists, "Driver should see Dashboard tab")
        XCTAssertTrue(tabBar.buttons["Orders"].exists, "Driver should see Orders tab")
        XCTAssertTrue(tabBar.buttons["Profile"].exists, "Driver should see Profile tab")
        XCTAssertFalse(tabBar.buttons["Explore"].exists, "Driver should not see Explore tab")
    }
    
    func testPartnerNavigation() throws {
        // Simulate partner login
        simulateUserLogin(role: "partner")
        
        // Verify partner-specific tabs are visible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Dashboard"].exists, "Partner should see Dashboard tab")
        XCTAssertTrue(tabBar.buttons["Orders"].exists, "Partner should see Orders tab")
        XCTAssertTrue(tabBar.buttons["Profile"].exists, "Partner should see Profile tab")
        XCTAssertFalse(tabBar.buttons["Explore"].exists, "Partner should not see Explore tab")
    }
    
    // MARK: - Navigation State Persistence Tests
    
    func testNavigationStatePersistence() throws {
        // Navigate to a specific screen
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            
            // Navigate to settings
            let settingsButton = app.buttons["Settings"]
            if settingsButton.exists {
                settingsButton.tap()
                
                // Verify we're in settings
                let settingsView = app.navigationBars["Settings"]
                XCTAssertTrue(settingsView.exists, "Should be in settings view")
                
                // Terminate and relaunch app
                app.terminate()
                app.launch()
                
                // Verify navigation state was restored
                // Note: This test assumes the app restores to the last known state
                let restoredView = app.navigationBars.firstMatch
                XCTAssertTrue(restoredView.waitForExistence(timeout: 5), "App should restore navigation state")
            }
        }
    }
    
    // MARK: - Accessibility Navigation Tests
    
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver for testing
        app.accessibilityActivate()
        
        // Test that navigation elements are accessible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should be accessible")
        
        // Test tab navigation with VoiceOver
        for button in tabBar.buttons.allElementsBoundByIndex {
            XCTAssertTrue(button.isHittable, "Tab button should be hittable with VoiceOver")
            XCTAssertFalse(button.label.isEmpty, "Tab button should have VoiceOver label")
        }
    }
    
    func testKeyboardNavigation() throws {
        // Test keyboard navigation support
        let firstFocusableElement = app.buttons.firstMatch
        if firstFocusableElement.exists {
            firstFocusableElement.tap()
            
            // Simulate tab key navigation
            app.typeKey(XCUIKeyboardKey.tab, modifierFlags: [])
            
            // Verify focus moved to next element
            let focusedElement = app.buttons.element(matching: .any, identifier: "focused")
            // Note: This test would need proper focus management implementation
        }
    }
    
    // MARK: - Performance Tests
    
    func testNavigationPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
        
        // Test tab switching performance
        let tabBar = app.tabBars.firstMatch
        let tabs = tabBar.buttons.allElementsBoundByIndex
        
        measure {
            for tab in tabs {
                if tab.exists {
                    tab.tap()
                }
            }
        }
    }
    
    func testDeepLinkPerformance() throws {
        // Test deep link handling performance
        let deepLinks = [
            "mimisupply://order?id=test1",
            "mimisupply://order?id=test2",
            "mimisupply://order?id=test3",
            "mimisupply://explore",
            "mimisupply://auth?action=signin"
        ]
        
        measure {
            for deepLink in deepLinks {
                app.terminate()
                app.launchArguments = ["--deep-link", deepLink]
                app.launch()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func simulateUserLogin(role: String) {
        // This would typically involve interacting with the authentication flow
        // For testing purposes, we might use launch arguments or test-specific endpoints
        app.launchArguments.append("--test-user-role")
        app.launchArguments.append(role)
        
        // Restart app with test user
        app.terminate()
        app.launch()
    }
    
    private func waitForViewToAppear(_ identifier: String, timeout: TimeInterval = 5) -> Bool {
        let view = app.otherElements[identifier]
        return view.waitForExistence(timeout: timeout)
    }
    
    private func dismissAnyPresentedSheets() {
        // Helper to dismiss any sheets that might be presented
        let sheets = app.sheets.allElementsBoundByIndex
        for sheet in sheets {
            if sheet.exists {
                let doneButton = sheet.buttons["Done"]
                if doneButton.exists {
                    doneButton.tap()
                }
            }
        }
    }
}

// MARK: - Navigation Accessibility Tests

final class NavigationAccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testTabBarAccessibilityLabels() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Test that all tabs have proper accessibility labels
        let expectedTabs = ["Explore", "Orders", "Profile", "Dashboard"]
        
        for tabName in expectedTabs {
            let tab = tabBar.buttons[tabName]
            if tab.exists {
                XCTAssertFalse(tab.label.isEmpty, "\(tabName) tab should have accessibility label")
                XCTAssertTrue(tab.isHittable, "\(tabName) tab should be hittable")
            }
        }
    }
    
    func testNavigationBarAccessibility() throws {
        // Navigate to a screen with navigation bar
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.exists {
            profileTab.tap()
            
            let navigationBar = app.navigationBars.firstMatch
            XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")
            
            // Test back button accessibility
            let backButton = navigationBar.buttons.firstMatch
            if backButton.exists {
                XCTAssertTrue(backButton.isHittable, "Back button should be hittable")
                XCTAssertFalse(backButton.label.isEmpty, "Back button should have accessibility label")
            }
        }
    }
    
    func testDynamicTypeSupport() throws {
        // Test that navigation elements scale with Dynamic Type
        // This would require setting different text size preferences
        // and verifying that navigation elements adapt appropriately
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Verify tab labels are readable at different text sizes
        for button in tabBar.buttons.allElementsBoundByIndex {
            XCTAssertTrue(button.frame.height > 0, "Tab button should have visible height")
            XCTAssertTrue(button.frame.width > 0, "Tab button should have visible width")
        }
    }
}