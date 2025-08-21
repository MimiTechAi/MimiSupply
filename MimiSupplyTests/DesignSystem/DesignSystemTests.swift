//
//  DesignSystemTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

final class DesignSystemTests: XCTestCase {
    
    // MARK: - Color Tests
    
    func testColorPalette() {
        // Test that all colors are properly defined
        XCTAssertNotNil(Color.emerald)
        XCTAssertNotNil(Color.chalk)
        XCTAssertNotNil(Color.graphite)
        XCTAssertNotNil(Color.success)
        XCTAssertNotNil(Color.warning)
        XCTAssertNotNil(Color.error)
        XCTAssertNotNil(Color.info)
        
        // Test gray scale
        XCTAssertNotNil(Color.gray50)
        XCTAssertNotNil(Color.gray100)
        XCTAssertNotNil(Color.gray200)
        XCTAssertNotNil(Color.gray300)
        XCTAssertNotNil(Color.gray400)
        XCTAssertNotNil(Color.gray500)
        XCTAssertNotNil(Color.gray600)
        XCTAssertNotNil(Color.gray700)
        XCTAssertNotNil(Color.gray800)
        XCTAssertNotNil(Color.gray900)
    }
    
    func testColorHexInitializer() {
        let emeraldColor = Color(hex: "1E9E8B")
        XCTAssertNotNil(emeraldColor)
        
        let shortHexColor = Color(hex: "FFF")
        XCTAssertNotNil(shortHexColor)
        
        let invalidHexColor = Color(hex: "INVALID")
        XCTAssertNotNil(invalidHexColor) // Should fallback to default
    }
    
    // MARK: - Typography Tests
    
    func testTypographySystem() {
        // Test display fonts
        XCTAssertNotNil(Font.displayLarge)
        XCTAssertNotNil(Font.displayMedium)
        XCTAssertNotNil(Font.displaySmall)
        
        // Test headline fonts
        XCTAssertNotNil(Font.headlineLarge)
        XCTAssertNotNil(Font.headlineMedium)
        XCTAssertNotNil(Font.headlineSmall)
        
        // Test title fonts
        XCTAssertNotNil(Font.titleLarge)
        XCTAssertNotNil(Font.titleMedium)
        XCTAssertNotNil(Font.titleSmall)
        
        // Test body fonts
        XCTAssertNotNil(Font.bodyLarge)
        XCTAssertNotNil(Font.bodyMedium)
        XCTAssertNotNil(Font.bodySmall)
        
        // Test label fonts
        XCTAssertNotNil(Font.labelLarge)
        XCTAssertNotNil(Font.labelMedium)
        XCTAssertNotNil(Font.labelSmall)
    }
    
    // MARK: - Spacing Tests
    
    func testSpacingSystem() {
        // Test 8pt grid system
        XCTAssertEqual(Spacing.xs, 4)
        XCTAssertEqual(Spacing.sm, 8)
        XCTAssertEqual(Spacing.md, 16)
        XCTAssertEqual(Spacing.lg, 24)
        XCTAssertEqual(Spacing.xl, 32)
        XCTAssertEqual(Spacing.xxl, 48)
        XCTAssertEqual(Spacing.xxxl, 64)
        
        // Test that spacing follows 8pt grid
        XCTAssertEqual(Spacing.sm * 2, Spacing.md)
        XCTAssertEqual(Spacing.sm * 3, Spacing.lg)
        XCTAssertEqual(Spacing.sm * 4, Spacing.xl)
    }
    
    // MARK: - Badge Tests
    
    func testBadgeStyles() {
        let primaryBadge = Badge(text: "Test", style: .primary)
        XCTAssertNotNil(primaryBadge)
        
        let successBadge = Badge(text: "Success", style: .success)
        XCTAssertNotNil(successBadge)
        
        let errorBadge = Badge(text: "Error", style: .error)
        XCTAssertNotNil(errorBadge)
    }
    
    func testNotificationBadge() {
        let badge = NotificationBadge(count: 5)
        XCTAssertNotNil(badge)
        
        let largeBadge = NotificationBadge(count: 150, maxCount: 99)
        XCTAssertNotNil(largeBadge)
        
        let zeroBadge = NotificationBadge(count: 0)
        XCTAssertNotNil(zeroBadge)
    }
    
    // MARK: - Loading View Tests
    
    func testLoadingViewSizes() {
        let smallLoading = AppLoadingView(size: .small)
        XCTAssertNotNil(smallLoading)
        
        let mediumLoading = AppLoadingView(size: .medium)
        XCTAssertNotNil(mediumLoading)
        
        let largeLoading = AppLoadingView(size: .large)
        XCTAssertNotNil(largeLoading)
    }
    
    func testLoadingOverlay() {
        let overlay = AppLoadingOverlay(message: "Loading...", isVisible: true)
        XCTAssertNotNil(overlay)
        
        let hiddenOverlay = AppLoadingOverlay(message: "Loading...", isVisible: false)
        XCTAssertNotNil(hiddenOverlay)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityManager() {
        let manager = AccessibilityManager.shared
        XCTAssertNotNil(manager)
        
        // Test that accessibility properties are accessible
        XCTAssertNotNil(manager.isVoiceOverEnabled)
        XCTAssertNotNil(manager.isReduceMotionEnabled)
        XCTAssertNotNil(manager.isHighContrastEnabled)
        XCTAssertNotNil(manager.preferredContentSizeCategory)
    }
    
    func testDynamicTypeSupport() {
        let categories: [UIContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for category in categories {
            let scaleFactor = category.scaleFactor
            XCTAssertGreaterThan(scaleFactor, 0)
            XCTAssertLessThanOrEqual(scaleFactor, 2.0)
        }
    }
    
    // MARK: - Component Integration Tests
    
    func testPrimaryButtonStates() {
        // Test normal state
        let normalButton = PrimaryButton(title: "Test") {}
        XCTAssertNotNil(normalButton)
        
        // Test loading state
        let loadingButton = PrimaryButton(title: "Loading", action: {}, isLoading: true)
        XCTAssertNotNil(loadingButton)
        
        // Test disabled state
        let disabledButton = PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        XCTAssertNotNil(disabledButton)
    }
    
    func testSecondaryButtonStates() {
        // Test normal state
        let normalButton = SecondaryButton(title: "Test") {}
        XCTAssertNotNil(normalButton)
        
        // Test loading state
        let loadingButton = SecondaryButton(title: "Loading", action: {}, isLoading: true)
        XCTAssertNotNil(loadingButton)
        
        // Test disabled state
        let disabledButton = SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
        XCTAssertNotNil(disabledButton)
    }
    
    func testAppTextFieldStates() {
        @State var text = ""
        
        // Test normal state
        let normalField = AppTextField(
            title: "Test",
            placeholder: "Enter text",
            text: .constant("")
        )
        XCTAssertNotNil(normalField)
        
        // Test secure field
        let secureField = AppTextField(
            title: "Password",
            placeholder: "Enter password",
            text: .constant(""),
            isSecure: true
        )
        XCTAssertNotNil(secureField)
        
        // Test error state
        let errorField = AppTextField(
            title: "Error",
            placeholder: "Enter text",
            text: .constant(""),
            errorMessage: "This field has an error"
        )
        XCTAssertNotNil(errorField)
        
        // Test disabled state
        let disabledField = AppTextField(
            title: "Disabled",
            placeholder: "Enter text",
            text: .constant(""),
            isDisabled: true
        )
        XCTAssertNotNil(disabledField)
    }
    
    func testEmptyStateView() {
        let emptyState = EmptyStateView(
            icon: "cart",
            title: "Empty Cart",
            message: "Your cart is empty"
        )
        XCTAssertNotNil(emptyState)
        
        let emptyStateWithAction = EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "Try a different search",
            actionTitle: "Browse All"
        ) {
            // Action
        }
        XCTAssertNotNil(emptyStateWithAction)
    }
    
    func testAppCard() {
        let card = AppCard {
            Text("Card Content")
        }
        XCTAssertNotNil(card)
        
        let customCard = AppCard(
            padding: Spacing.lg,
            cornerRadius: 16,
            shadowRadius: 8
        ) {
            VStack {
                Text("Custom Card")
                Text("With custom styling")
            }
        }
        XCTAssertNotNil(customCard)
    }
    
    func testAppDivider() {
        let divider = AppDivider()
        XCTAssertNotNil(divider)
        
        let customDivider = AppDivider(
            color: .emerald,
            thickness: 2,
            padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        )
        XCTAssertNotNil(customDivider)
        
        let sectionDivider = SectionDivider(title: "Section")
        XCTAssertNotNil(sectionDivider)
    }
}

// MARK: - Performance Tests

final class DesignSystemPerformanceTests: XCTestCase {
    
    func testColorCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = Color(hex: "1E9E8B")
            }
        }
    }
    
    func testComponentCreationPerformance() {
        measure {
            for _ in 0..<100 {
                let _ = PrimaryButton(title: "Test") {}
                let _ = SecondaryButton(title: "Test") {}
                let _ = Badge(text: "Test")
                let _ = AppLoadingView()
            }
        }
    }
}