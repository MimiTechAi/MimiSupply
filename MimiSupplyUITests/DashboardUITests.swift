//
//  DashboardUITests.swift
//  MimiSupplyUITests
//
//  Created by Alex on 15.08.25.
//

import XCTest

class DashboardUITests: MimiSupplyUITestCase {
    
    var dashboardPage: DashboardPage!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Login first
        let loginPage = LoginPage(app: app)
        dashboardPage = loginPage.login(
            email: "test@example.com",
            password: "password123"
        )
        
        waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
    }
    
    // MARK: - Dashboard Display Tests
    
    func testDashboardLoadsCorrectly() {
        // Then
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should be displayed")
        XCTAssertTrue(dashboardPage.welcomeMessage.exists, "Welcome message should be visible")
        XCTAssertTrue(dashboardPage.revenueCard.exists, "Revenue card should be visible")
        XCTAssertTrue(dashboardPage.ordersCard.exists, "Orders card should be visible")
        XCTAssertTrue(dashboardPage.customersCard.exists, "Customers card should be visible")
        
        takeScreenshot(name: "dashboard_loaded")
    }
    
    func testDashboardTabNavigation() {
        // Test navigation between tabs
        
        // Navigate to Orders
        let ordersPage = dashboardPage.navigateToOrders()
        waitForElement(ordersPage.ordersList, timeout: 5.0)
        XCTAssertTrue(ordersPage.isDisplayed(), "Orders page should be displayed")
        
        // Navigate to Analytics
        let analyticsPage = dashboardPage.navigateToAnalytics()
        waitForElement(analyticsPage.revenueChart, timeout: 5.0)
        XCTAssertTrue(analyticsPage.isDisplayed(), "Analytics page should be displayed")
        
        // Navigate to Settings
        let settingsPage = dashboardPage.navigateToSettings()
        waitForElement(settingsPage.profileSection, timeout: 5.0)
        XCTAssertTrue(settingsPage.isDisplayed(), "Settings page should be displayed")
        
        // Navigate back to Dashboard
        safeTap(dashboardPage.dashboardTab)
        waitForElement(dashboardPage.welcomeMessage, timeout: 5.0)
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should be displayed again")
        
        takeScreenshot(name: "tab_navigation_complete")
    }
    
    func testDashboardCardInteractions() {
        // Test revenue card tap
        safeTap(dashboardPage.revenueCard)
        // Should navigate to detailed revenue view or show modal
        takeScreenshot(name: "revenue_card_interaction")
        
        // Navigate back if needed
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        
        // Test orders card tap
        safeTap(dashboardPage.ordersCard)
        takeScreenshot(name: "orders_card_interaction")
        
        // Test customers card tap
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        safeTap(dashboardPage.customersCard)
        takeScreenshot(name: "customers_card_interaction")
    }
    
    func testDashboardRefresh() {
        // Given
        XCTAssertTrue(dashboardPage.refreshButton.exists, "Refresh button should exist")
        
        // When
        dashboardPage.refreshDashboard()
        
        // Then - Data should refresh (might show loading indicator temporarily)
        // Wait a moment for refresh to complete
        Thread.sleep(forTimeInterval: 2.0)
        
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should still be displayed after refresh")
        takeScreenshot(name: "dashboard_after_refresh")
    }
    
    // MARK: - Profile Tests
    
    func testProfileAccess() {
        // When
        let profilePage = dashboardPage.openProfile()
        
        // Then
        waitForElement(profilePage.nameField, timeout: 5.0)
        XCTAssertTrue(profilePage.isDisplayed(), "Profile page should be displayed")
        
        takeScreenshot(name: "profile_page")
        
        // Test profile editing
        profilePage.updateName("Updated Test User")
        profilePage.save()
        
        // Should return to dashboard or show success message
        takeScreenshot(name: "profile_updated")
    }
    
    // MARK: - Accessibility Tests
    
    func testDashboardAccessibility() {
        assertAccessibilityCompliance()
        
        // Test specific accessibility elements
        XCTAssertTrue(dashboardPage.revenueCard.isAccessibilityElement)
        XCTAssertTrue(dashboardPage.ordersCard.isAccessibilityElement)
        XCTAssertTrue(dashboardPage.customersCard.isAccessibilityElement)
        
        // Check accessibility labels
        XCTAssertFalse(dashboardPage.revenueCard.label.isEmpty, "Revenue card should have accessibility label")
        XCTAssertFalse(dashboardPage.ordersCard.label.isEmpty, "Orders card should have accessibility label")
        XCTAssertFalse(dashboardPage.customersCard.label.isEmpty, "Customers card should have accessibility label")
    }
    
    // MARK: - Performance Tests
    
    func testDashboardLoadPerformance() {
        measure {
            // Navigate away and back to test load performance
            let settingsPage = dashboardPage.navigateToSettings()
            waitForElement(settingsPage.profileSection, timeout: 5.0)
            
            safeTap(dashboardPage.dashboardTab)
            waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
        }
    }
    
    func testTabSwitchingPerformance() {
        let tabs = [
            dashboardPage.ordersTab,
            dashboardPage.analyticsTab,
            dashboardPage.settingsTab,
            dashboardPage.dashboardTab
        ]
        
        measure {
            for tab in tabs {
                safeTap(tab)
                Thread.sleep(forTimeInterval: 0.5) // Allow UI to settle
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testDashboardWithNetworkError() {
        // This would require setting up network error simulation
        // in the app when launched with specific test parameters
        
        // Simulate network error by setting launch environment
        app.terminate()
        app.launchEnvironment["SIMULATE_NETWORK_ERROR"] = "1"
        app.launch()
        
        // Login again
        let loginPage = LoginPage(app: app)
        dashboardPage = loginPage.login(
            email: "test@example.com",
            password: "password123"
        )
        
        // Should show error state or fallback UI
        waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
        takeScreenshot(name: "dashboard_network_error")
    }
    
    func testDashboardWithOfflineMode() {
        // Test offline functionality
        app.terminate()
        app.launchEnvironment["SIMULATE_OFFLINE"] = "1"
        app.launch()
        
        let loginPage = LoginPage(app: app)
        dashboardPage = loginPage.login(
            email: "test@example.com",
            password: "password123"
        )
        
        // Should show cached data or offline indicator
        waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should work in offline mode")
        
        takeScreenshot(name: "dashboard_offline_mode")
    }
    
    // MARK: - Landscape Orientation Tests
    
    func testDashboardInLandscape() {
        // Rotate to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Wait for orientation change
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test that dashboard still works in landscape
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should work in landscape")
        XCTAssertTrue(dashboardPage.revenueCard.exists, "Revenue card should be visible in landscape")
        
        takeScreenshot(name: "dashboard_landscape")
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
        
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should work after rotation back")
    }
    
    // MARK: - Dark Mode Tests
    
    func testDashboardInDarkMode() {
        // This would require implementing dark mode toggle in settings
        // or using system appearance changes
        
        let settingsPage = dashboardPage.navigateToSettings()
        waitForElement(settingsPage.profileSection, timeout: 5.0)
        
        // Navigate to appearance settings if available
        // Toggle dark mode
        // Navigate back to dashboard
        
        safeTap(dashboardPage.dashboardTab)
        waitForElement(dashboardPage.welcomeMessage, timeout: 5.0)
        
        takeScreenshot(name: "dashboard_dark_mode")
    }
}