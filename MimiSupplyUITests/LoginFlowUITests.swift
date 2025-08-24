//
//  LoginFlowUITests.swift
//  MimiSupplyUITests
//
//  Created by Alex on 15.08.25.
//

import XCTest

class LoginFlowUITests: MimiSupplyUITestCase {
    
    // MARK: - Login Flow Tests
    
    func testSuccessfulLogin() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When
        XCTAssertTrue(loginPage.isDisplayed(), "Login page should be displayed")
        
        let dashboardPage = loginPage.login(
            email: "test@example.com",
            password: "password123"
        )
        
        // Then
        waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
        XCTAssertTrue(dashboardPage.isDisplayed(), "Dashboard should be displayed after successful login")
        
        takeScreenshot(name: "successful_login_dashboard")
    }
    
    func testFailedLoginWithInvalidCredentials() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When
        loginPage.login(
            email: "invalid@example.com",
            password: "wrongpassword"
        )
        
        // Then
        waitForElement(loginPage.errorMessage, timeout: 5.0)
        XCTAssertTrue(loginPage.hasErrorMessage(), "Error message should be displayed")
        XCTAssertTrue(loginPage.isDisplayed(), "Should remain on login page")
        
        takeScreenshot(name: "failed_login_error")
    }
    
    func testLoginWithEmptyFields() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When
        safeTap(loginPage.loginButton)
        
        // Then
        XCTAssertTrue(loginPage.isDisplayed(), "Should remain on login page")
        // Additional validation could check for field-specific error messages
        
        takeScreenshot(name: "login_empty_fields")
    }
    
    func testForgotPasswordFlow() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When
        loginPage.tapForgotPassword()
        
        // Then - This would navigate to forgot password screen
        // Implementation depends on your forgot password flow
        takeScreenshot(name: "forgot_password_flow")
    }
    
    func testSignUpFlow() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When
        loginPage.tapSignUp()
        
        // Then - This would navigate to sign up screen
        // Implementation depends on your sign up flow
        takeScreenshot(name: "sign_up_flow")
    }
    
    // MARK: - Accessibility Tests
    
    func testLoginPageAccessibility() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When & Then
        XCTAssertTrue(loginPage.isDisplayed())
        assertAccessibilityCompliance()
        
        // Test VoiceOver navigation order
        XCTAssertTrue(loginPage.emailTextField.isAccessibilityElement)
        XCTAssertTrue(loginPage.passwordTextField.isAccessibilityElement)
        XCTAssertTrue(loginPage.loginButton.isAccessibilityElement)
        
        // Test accessibility labels
        XCTAssertFalse(loginPage.emailTextField.label.isEmpty)
        XCTAssertFalse(loginPage.passwordTextField.label.isEmpty)
        XCTAssertFalse(loginPage.loginButton.label.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testLoginPerformance() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When & Then
        measure {
            loginPage.login(
                email: "test@example.com",
                password: "password123"
            )
            
            // Wait for dashboard to load
            let dashboardPage = DashboardPage(app: app)
            waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
            
            // Navigate back to login for next iteration
            dashboardPage.navigateToSettings().logout()
            waitForElement(loginPage.emailTextField, timeout: 5.0)
        }
    }
    
    // MARK: - Edge Cases
    
    func testLoginWithSpecialCharacters() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // When
        loginPage.login(
            email: "test+special@example.com",
            password: "P@ssw0rd!#$"
        )
        
        // Then - Should handle special characters correctly
        let dashboardPage = DashboardPage(app: app)
        waitForElement(dashboardPage.welcomeMessage, timeout: 10.0)
        XCTAssertTrue(dashboardPage.isDisplayed())
    }
    
    func testLoginWithLongInput() {
        // Given
        let loginPage = LoginPage(app: app)
        let longEmail = String(repeating: "a", count: 100) + "@example.com"
        let longPassword = String(repeating: "P@ssw0rd!", count: 10)
        
        // When
        safeTypeText(longEmail, into: loginPage.emailTextField)
        safeTypeText(longPassword, into: loginPage.passwordTextField)
        safeTap(loginPage.loginButton)
        
        // Then - Should handle long input gracefully
        XCTAssertTrue(loginPage.isDisplayed())
    }
    
    func testLoginFormValidation() {
        // Given
        let loginPage = LoginPage(app: app)
        
        // Test invalid email format
        safeTypeText("invalid-email", into: loginPage.emailTextField)
        safeTypeText("password123", into: loginPage.passwordTextField)
        safeTap(loginPage.loginButton)
        
        // Should show validation error or stay on page
        XCTAssertTrue(loginPage.isDisplayed())
        
        takeScreenshot(name: "login_validation_error")
    }
}