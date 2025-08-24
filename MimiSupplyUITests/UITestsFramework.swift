//
//  UITestsFramework.swift
//  MimiSupplyUITests
//
//  Created by Alex on 15.08.25.
//

import XCTest

// MARK: - Enhanced UI Testing Framework

class MimiSupplyUITestCase: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launchEnvironment = [
            "DISABLE_ANIMATIONS": "1",
            "MOCK_NETWORK": "1",
            "RESET_USER_DEFAULTS": "1"
        ]
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - UI Test Utilities
    
    /// Wait for element to exist with timeout
    @discardableResult
    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element \(element) did not appear within \(timeout) seconds", file: file, line: line)
        return exists
    }
    
    /// Wait for element to disappear
    @discardableResult
    func waitForElementToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval = 10.0,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element \(element) did not disappear within \(timeout) seconds", file: file, line: line)
        return result == .completed
    }
    
    /// Tap element safely
    func safeTap(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        waitForElement(element, timeout: timeout, file: file, line: line)
        XCTAssertTrue(element.isHittable, "Element \(element) is not hittable", file: file, line: line)
        element.tap()
    }
    
    /// Type text safely
    func safeTypeText(
        _ text: String,
        into element: XCUIElement,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        waitForElement(element, timeout: timeout, file: file, line: line)
        element.tap()
        element.typeText(text)
    }
    
    /// Scroll to find element
    func scrollToElement(
        _ element: XCUIElement,
        in scrollView: XCUIElement,
        direction: ScrollDirection = .down,
        maxScrolls: Int = 10
    ) -> Bool {
        var scrollCount = 0
        
        while !element.exists && scrollCount < maxScrolls {
            switch direction {
            case .up:
                scrollView.swipeUp()
            case .down:
                scrollView.swipeDown()
            case .left:
                scrollView.swipeLeft()
            case .right:
                scrollView.swipeRight()
            }
            scrollCount += 1
        }
        
        return element.exists
    }
    
    /// Take screenshot with description
    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Assert accessibility compliance
    func assertAccessibilityCompliance(
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Check for accessibility labels on interactive elements
        let buttons = app.buttons.allElementsBoundByIndex
        let textFields = app.textFields.allElementsBoundByIndex
        
        for button in buttons {
            if button.exists && button.isHittable {
                let label = button.label
                XCTAssertFalse(label.isEmpty, "Button missing accessibility label: \(button)", file: file, line: line)
            }
        }
        
        for textField in textFields {
            if textField.exists {
                let label = textField.label
                XCTAssertFalse(label.isEmpty, "Text field missing accessibility label: \(textField)", file: file, line: line)
            }
        }
    }
    
    enum ScrollDirection {
        case up, down, left, right
    }
}

// MARK: - Page Object Model

protocol PageObject {
    var app: XCUIApplication { get }
    func isDisplayed() -> Bool
}

// MARK: - Login Page

struct LoginPage: PageObject {
    let app: XCUIApplication
    
    // Elements
    var emailTextField: XCUIElement { app.textFields["login-email-field"] }
    var passwordTextField: XCUIElement { app.secureTextFields["login-password-field"] }
    var loginButton: XCUIElement { app.buttons["login-submit-button"] }
    var forgotPasswordButton: XCUIElement { app.buttons["forgot-password-button"] }
    var signUpButton: XCUIElement { app.buttons["sign-up-button"] }
    var errorMessage: XCUIElement { app.staticTexts["login-error-message"] }
    
    func isDisplayed() -> Bool {
        return emailTextField.exists && passwordTextField.exists && loginButton.exists
    }
    
    @discardableResult
    func login(email: String, password: String) -> DashboardPage {
        emailTextField.tap()
        emailTextField.typeText(email)
        
        passwordTextField.tap()
        passwordTextField.typeText(password)
        
        loginButton.tap()
        
        return DashboardPage(app: app)
    }
    
    func tapForgotPassword() {
        forgotPasswordButton.tap()
    }
    
    func tapSignUp() {
        signUpButton.tap()
    }
    
    func hasErrorMessage() -> Bool {
        return errorMessage.exists
    }
    
    func getErrorMessage() -> String {
        return errorMessage.label
    }
}

// MARK: - Dashboard Page

struct DashboardPage: PageObject {
    let app: XCUIApplication
    
    // Tab bar elements
    var dashboardTab: XCUIElement { app.tabBars.buttons["Dashboard"] }
    var ordersTab: XCUIElement { app.tabBars.buttons["Orders"] }
    var analyticsTab: XCUIElement { app.tabBars.buttons["Analytics"] }
    var settingsTab: XCUIElement { app.tabBars.buttons["Settings"] }
    
    // Dashboard elements
    var welcomeMessage: XCUIElement { app.staticTexts["welcome-message"] }
    var revenueCard: XCUIElement { app.otherElements["revenue-card"] }
    var ordersCard: XCUIElement { app.otherElements["orders-card"] }
    var customersCard: XCUIElement { app.otherElements["customers-card"] }
    var refreshButton: XCUIElement { app.buttons["refresh-dashboard"] }
    var profileButton: XCUIElement { app.buttons["profile-button"] }
    
    func isDisplayed() -> Bool {
        return welcomeMessage.exists && revenueCard.exists
    }
    
    func tapRevenueCard() {
        revenueCard.tap()
    }
    
    func tapOrdersCard() {
        ordersCard.tap()
    }
    
    func tapCustomersCard() {
        customersCard.tap()
    }
    
    func refreshDashboard() {
        refreshButton.tap()
    }
    
    func navigateToOrders() -> OrdersPage {
        ordersTab.tap()
        return OrdersPage(app: app)
    }
    
    func navigateToAnalytics() -> AnalyticsPage {
        analyticsTab.tap()
        return AnalyticsPage(app: app)
    }
    
    func navigateToSettings() -> SettingsPage {
        settingsTab.tap()
        return SettingsPage(app: app)
    }
    
    func openProfile() -> ProfilePage {
        profileButton.tap()
        return ProfilePage(app: app)
    }
}

// MARK: - Orders Page

struct OrdersPage: PageObject {
    let app: XCUIApplication
    
    // Elements
    var ordersList: XCUIElement { app.tables["orders-list"] }
    var searchField: XCUIElement { app.searchFields["orders-search"] }
    var filterButton: XCUIElement { app.buttons["orders-filter"] }
    var sortButton: XCUIElement { app.buttons["orders-sort"] }
    var addOrderButton: XCUIElement { app.buttons["add-order"] }
    var emptyStateMessage: XCUIElement { app.staticTexts["orders-empty-state"] }
    
    func isDisplayed() -> Bool {
        return ordersList.exists || emptyStateMessage.exists
    }
    
    func searchOrders(_ query: String) {
        searchField.tap()
        searchField.typeText(query)
    }
    
    func tapFilter() {
        filterButton.tap()
    }
    
    func tapSort() {
        sortButton.tap()
    }
    
    func tapAddOrder() {
        addOrderButton.tap()
    }
    
    func selectOrder(at index: Int) -> OrderDetailPage {
        let orderCell = ordersList.cells.element(boundBy: index)
        orderCell.tap()
        return OrderDetailPage(app: app)
    }
    
    func getOrderCount() -> Int {
        return ordersList.cells.count
    }
    
    func hasEmptyState() -> Bool {
        return emptyStateMessage.exists
    }
}

// MARK: - Order Detail Page

struct OrderDetailPage: PageObject {
    let app: XCUIApplication
    
    // Elements
    var orderIdLabel: XCUIElement { app.staticTexts["order-id"] }
    var statusLabel: XCUIElement { app.staticTexts["order-status"] }
    var totalLabel: XCUIElement { app.staticTexts["order-total"] }
    var itemsList: XCUIElement { app.tables["order-items"] }
    var updateStatusButton: XCUIElement { app.buttons["update-status"] }
    var cancelOrderButton: XCUIElement { app.buttons["cancel-order"] }
    var backButton: XCUIElement { app.navigationBars.buttons.element(boundBy: 0) }
    
    func isDisplayed() -> Bool {
        return orderIdLabel.exists && statusLabel.exists
    }
    
    func getOrderId() -> String {
        return orderIdLabel.label
    }
    
    func getStatus() -> String {
        return statusLabel.label
    }
    
    func getTotal() -> String {
        return totalLabel.label
    }
    
    func tapUpdateStatus() {
        updateStatusButton.tap()
    }
    
    func tapCancelOrder() {
        cancelOrderButton.tap()
    }
    
    func goBack() {
        backButton.tap()
    }
    
    func getItemCount() -> Int {
        return itemsList.cells.count
    }
}

// MARK: - Analytics Page

struct AnalyticsPage: PageObject {
    let app: XCUIApplication
    
    // Elements
    var revenueChart: XCUIElement { app.otherElements["revenue-chart"] }
    var ordersChart: XCUIElement { app.otherElements["orders-chart"] }
    var timeRangeSegmentedControl: XCUIElement { app.segmentedControls["time-range-picker"] }
    var exportButton: XCUIElement { app.buttons["export-data"] }
    var refreshButton: XCUIElement { app.buttons["refresh-analytics"] }
    
    func isDisplayed() -> Bool {
        return revenueChart.exists && ordersChart.exists
    }
    
    func selectTimeRange(_ range: String) {
        timeRangeSegmentedControl.buttons[range].tap()
    }
    
    func tapExport() {
        exportButton.tap()
    }
    
    func refresh() {
        refreshButton.tap()
    }
    
    func tapRevenueChart() {
        revenueChart.tap()
    }
    
    func tapOrdersChart() {
        ordersChart.tap()
    }
}

// MARK: - Settings Page

struct SettingsPage: PageObject {
    let app: XCUIApplication
    
    // Elements
    var profileSection: XCUIElement { app.tables.staticTexts["Profile"] }
    var notificationsSection: XCUIElement { app.tables.staticTexts["Notifications"] }
    var securitySection: XCUIElement { app.tables.staticTexts["Security"] }
    var helpSection: XCUIElement { app.tables.staticTexts["Help"] }
    var logoutButton: XCUIElement { app.buttons["logout-button"] }
    
    func isDisplayed() -> Bool {
        return profileSection.exists && logoutButton.exists
    }
    
    func tapProfile() {
        profileSection.tap()
    }
    
    func tapNotifications() {
        notificationsSection.tap()
    }
    
    func tapSecurity() {
        securitySection.tap()
    }
    
    func tapHelp() {
        helpSection.tap()
    }
    
    func logout() {
        logoutButton.tap()
    }
}

// MARK: - Profile Page

struct ProfilePage: PageObject {
    let app: XCUIApplication
    
    // Elements
    var nameField: XCUIElement { app.textFields["profile-name"] }
    var emailField: XCUIElement { app.textFields["profile-email"] }
    var phoneField: XCUIElement { app.textFields["profile-phone"] }
    var saveButton: XCUIElement { app.buttons["save-profile"] }
    var cancelButton: XCUIElement { app.buttons["cancel-profile"] }
    var changePasswordButton: XCUIElement { app.buttons["change-password"] }
    
    func isDisplayed() -> Bool {
        return nameField.exists && emailField.exists
    }
    
    func updateName(_ name: String) {
        nameField.clearAndEnterText(name)
    }
    
    func updateEmail(_ email: String) {
        emailField.clearAndEnterText(email)
    }
    
    func updatePhone(_ phone: String) {
        phoneField.clearAndEnterText(phone)
    }
    
    func save() {
        saveButton.tap()
    }
    
    func cancel() {
        cancelButton.tap()
    }
    
    func changePassword() {
        changePasswordButton.tap()
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
    
    func forceTap() {
        if self.isHittable {
            self.tap()
        } else {
            let coordinate = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coordinate.tap()
        }
    }
}