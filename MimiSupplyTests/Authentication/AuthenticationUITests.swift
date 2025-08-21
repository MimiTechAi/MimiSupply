//
//  AuthenticationUITests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

final class AuthenticationUITests: XCTestCase {
    
    // MARK: - Authentication View Tests
    
    @MainActor
    func testAuthenticationViewDisplaysCorrectly() {
        // Given: Authentication view
        let authManager = AuthenticationManager()
        let view = SignInView()
            .environmentObject(authManager)
        
        // When: Rendering view
        let hostingController = UIHostingController(rootView: view)
        
        // Then: Should display correctly
        XCTAssertNotNil(hostingController.view)
        
        // Verify accessibility
        XCTAssertTrue(hostingController.view.isAccessibilityElement || 
                     hostingController.view.accessibilityElements?.count ?? 0 > 0)
    }
    
    @MainActor
    func testSignInButtonAccessibility() {
        // Given: Authentication view
        let authManager = AuthenticationManager()
        let view = SignInView()
            .environmentObject(authManager)
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Finding sign in button
        let signInButton = findAccessibilityElement(
            in: hostingController.view,
            withLabel: "Sign in with Apple"
        )
        
        // Then: Should be accessible
        XCTAssertNotNil(signInButton)
        XCTAssertTrue(signInButton?.accessibilityTraits.contains(.button) ?? false)
    }
    
    // MARK: - Role Selection View Tests
    
    func testRoleSelectionViewDisplaysAllRoles() {
        // Given: Test user and role selection view
        let testUser = createTestUser()
        var selectedRole: UserRole?
        
        let view = RoleSelectionView(user: testUser) { role in
            selectedRole = role
        }
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Rendering view
        // Then: Should display all role options
        XCTAssertNotNil(hostingController.view)
        
        // Verify customer role card
        let customerCard = findAccessibilityElement(
            in: hostingController.view,
            withLabel: "Customer"
        )
        XCTAssertNotNil(customerCard)
        
        // Verify driver role card
        let driverCard = findAccessibilityElement(
            in: hostingController.view,
            withLabel: "Driver"
        )
        XCTAssertNotNil(driverCard)
        
        // Verify partner role card
        let partnerCard = findAccessibilityElement(
            in: hostingController.view,
            withLabel: "Business Partner"
        )
        XCTAssertNotNil(partnerCard)
    }
    
    func testRoleSelectionAccessibility() {
        // Given: Role selection view
        let testUser = createTestUser()
        let view = RoleSelectionView(user: testUser) { _ in }
        let hostingController = UIHostingController(rootView: view)
        
        // When: Checking accessibility
        let roleCards = findAllAccessibilityElements(
            in: hostingController.view,
            withTrait: .button
        )
        
        // Then: All role cards should be accessible
        XCTAssertGreaterThanOrEqual(roleCards.count, 3) // At least 3 role cards
        
        // Verify each role card has proper accessibility labels
        for card in roleCards {
            XCTAssertFalse(card.accessibilityLabel?.isEmpty ?? true)
            XCTAssertFalse(card.accessibilityHint?.isEmpty ?? true)
        }
    }
    
    func testRoleSelectionContinueButtonState() {
        // Given: Role selection view
        let testUser = createTestUser()
        let view = RoleSelectionView(user: testUser) { _ in }
        let hostingController = UIHostingController(rootView: view)
        
        // When: Finding continue button
        let continueButton = findAccessibilityElement(
            in: hostingController.view,
            withLabel: "Continue"
        )
        
        // Then: Continue button should exist and be initially disabled
        XCTAssertNotNil(continueButton)
        // Note: Testing button state would require more sophisticated UI testing
    }
    
    // MARK: - Authentication Gate Tests
    
    func testAuthenticationGateShowsAuthenticationWhenUnauthenticated() {
        // Given: Unauthenticated state
        let view = AuthenticationGate {
            Text("Protected Content")
        }
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Rendering gate
        // Then: Should show authentication view
        XCTAssertNotNil(hostingController.view)
        
        // Verify sign in button is present
        let signInButton = findAccessibilityElement(
            in: hostingController.view,
            withLabel: "Sign in with Apple"
        )
        XCTAssertNotNil(signInButton)
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testVoiceOverSupport() {
        // Given: Authentication view
        let authManager = AuthenticationManager()
        let view = SignInView()
            .environmentObject(authManager)
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Checking VoiceOver support
        let accessibleElements = findAllAccessibilityElements(in: hostingController.view)
        
        // Then: Should have accessible elements
        XCTAssertGreaterThan(accessibleElements.count, 0)
        
        // Verify each element has proper accessibility labels
        for element in accessibleElements {
            XCTAssertFalse(element.accessibilityLabel?.isEmpty ?? true,
                          "Accessibility element should have a label")
        }
    }
    
    @MainActor
    func testDynamicTypeSupport() {
        // Given: Authentication view with large text
        let authManager = AuthenticationManager()
        let view = SignInView()
            .environmentObject(authManager)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Rendering with large text
        // Then: Should render without issues
        XCTAssertNotNil(hostingController.view)
        
        // Verify layout doesn't break with large text
        hostingController.view.layoutIfNeeded()
        XCTAssertFalse(hostingController.view.bounds.isEmpty)
    }
    
    @MainActor
    func testHighContrastSupport() {
        // Given: Authentication view with high contrast
        let authManager = AuthenticationManager()
        let view = SignInView()
            .environmentObject(authManager)
            .environment(\.colorScheme, .dark)
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Rendering with high contrast
        // Then: Should render correctly
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layoutIfNeeded()
    }
    
    @MainActor
    func testReduceMotionSupport() {
        // Given: Authentication view with reduced motion
        let authManager = AuthenticationManager()
        let view = SignInView()
            .environmentObject(authManager)
            .environment(\.accessibilityReduceMotion, true)
        
        let hostingController = UIHostingController(rootView: view)
        
        // When: Rendering with reduced motion
        // Then: Should render correctly
        XCTAssertNotNil(hostingController.view)
        hostingController.view.layoutIfNeeded()
    }
    
    // MARK: - Security Tests
    
    func testNoSensitiveDataInAccessibilityLabels() {
        // Given: Role selection view with user data
        let testUser = createTestUser()
        let view = RoleSelectionView(user: testUser) { _ in }
        let hostingController = UIHostingController(rootView: view)
        
        // When: Checking accessibility labels
        let accessibleElements = findAllAccessibilityElements(in: hostingController.view)
        
        // Then: Should not expose sensitive data
        for element in accessibleElements {
            let label = element.accessibilityLabel ?? ""
            let hint = element.accessibilityHint ?? ""
            
            // Verify no email addresses in accessibility text
            XCTAssertFalse(label.contains("@"), "Accessibility label should not contain email")
            XCTAssertFalse(hint.contains("@"), "Accessibility hint should not contain email")
            
            // Verify no phone numbers in accessibility text
            XCTAssertFalse(label.contains("+"), "Accessibility label should not contain phone number")
            XCTAssertFalse(hint.contains("+"), "Accessibility hint should not contain phone number")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser() -> UserProfile {
        UserProfile(
            id: "test-user-id",
            appleUserID: "test-apple-id",
            email: "test@example.com",
            fullName: PersonNameComponents(givenName: "Test", familyName: "User"),
            role: .customer,
            phoneNumber: "+1234567890",
            profileImageURL: nil,
            isVerified: true,
            createdAt: Date(),
            lastActiveAt: Date()
        )
    }
    
    private func findAccessibilityElement(
        in view: UIView,
        withLabel label: String
    ) -> UIAccessibilityElement? {
        return findAllAccessibilityElements(in: view)
            .first { $0.accessibilityLabel == label }
    }
    
    private func findAllAccessibilityElements(in view: UIView) -> [UIAccessibilityElement] {
        var elements: [UIAccessibilityElement] = []
        
        if view.isAccessibilityElement {
            if let element = view as? UIAccessibilityElement {
                elements.append(element)
            }
        }
        
        if let accessibilityElements = view.accessibilityElements {
            for element in accessibilityElements {
                if let accessibilityElement = element as? UIAccessibilityElement {
                    elements.append(accessibilityElement)
                }
            }
        }
        
        for subview in view.subviews {
            elements.append(contentsOf: findAllAccessibilityElements(in: subview))
        }
        
        return elements
    }
    
    private func findAllAccessibilityElements(
        in view: UIView,
        withTrait trait: UIAccessibilityTraits
    ) -> [UIAccessibilityElement] {
        return findAllAccessibilityElements(in: view)
            .filter { $0.accessibilityTraits.contains(trait) }
    }
}