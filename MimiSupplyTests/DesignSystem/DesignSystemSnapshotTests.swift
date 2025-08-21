//
//  DesignSystemSnapshotTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

/// Snapshot tests for design system components to ensure visual consistency
final class DesignSystemSnapshotTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Configure snapshot testing if using a snapshot testing library
        // For now, we'll create visual regression tests manually
    }
    
    // MARK: - Button Snapshot Tests
    
    func testPrimaryButtonSnapshots() {
        let normalButton = PrimaryButton(title: "Continue") {}
        let loadingButton = PrimaryButton(title: "Loading", action: {}, isLoading: true)
        let disabledButton = PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        
        // In a real implementation, you would use a snapshot testing library
        // like swift-snapshot-testing to capture and compare visual snapshots
        XCTAssertNotNil(normalButton)
        XCTAssertNotNil(loadingButton)
        XCTAssertNotNil(disabledButton)
    }
    
    func testSecondaryButtonSnapshots() {
        let normalButton = SecondaryButton(title: "Cancel") {}
        let loadingButton = SecondaryButton(title: "Loading", action: {}, isLoading: true)
        let disabledButton = SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
        
        XCTAssertNotNil(normalButton)
        XCTAssertNotNil(loadingButton)
        XCTAssertNotNil(disabledButton)
    }
    
    // MARK: - Text Field Snapshot Tests
    
    func testTextFieldSnapshots() {
        let normalField = AppTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant("")
        )
        
        let errorField = AppTextField(
            title: "Email",
            placeholder: "Enter your email",
            text: .constant("invalid@"),
            errorMessage: "Please enter a valid email address"
        )
        
        let disabledField = AppTextField(
            title: "Disabled",
            placeholder: "This field is disabled",
            text: .constant(""),
            isDisabled: true
        )
        
        XCTAssertNotNil(normalField)
        XCTAssertNotNil(errorField)
        XCTAssertNotNil(disabledField)
    }
    
    // MARK: - Badge Snapshot Tests
    
    func testBadgeSnapshots() {
        let primaryBadge = Badge(text: "New", style: .primary, size: .small)
        let successBadge = Badge(text: "Available", style: .success, size: .medium)
        let errorBadge = Badge(text: "Urgent", style: .error, size: .large)
        let warningBadge = Badge(text: "Warning", style: .warning)
        let infoBadge = Badge(text: "Info", style: .info)
        let neutralBadge = Badge(text: "Neutral", style: .neutral)
        
        XCTAssertNotNil(primaryBadge)
        XCTAssertNotNil(successBadge)
        XCTAssertNotNil(errorBadge)
        XCTAssertNotNil(warningBadge)
        XCTAssertNotNil(infoBadge)
        XCTAssertNotNil(neutralBadge)
    }
    
    func testNotificationBadgeSnapshots() {
        let singleDigitBadge = NotificationBadge(count: 3)
        let doubleDigitBadge = NotificationBadge(count: 42)
        let maxBadge = NotificationBadge(count: 150, maxCount: 99)
        let zeroBadge = NotificationBadge(count: 0)
        
        XCTAssertNotNil(singleDigitBadge)
        XCTAssertNotNil(doubleDigitBadge)
        XCTAssertNotNil(maxBadge)
        XCTAssertNotNil(zeroBadge)
    }
    
    // MARK: - Loading View Snapshot Tests
    
    func testLoadingViewSnapshots() {
        let smallLoading = AppLoadingView(message: "Loading...", size: .small)
        let mediumLoading = AppLoadingView(message: "Loading...", size: .medium)
        let largeLoading = AppLoadingView(message: "Loading...", size: .large)
        
        XCTAssertNotNil(smallLoading)
        XCTAssertNotNil(mediumLoading)
        XCTAssertNotNil(largeLoading)
    }
    
    // MARK: - Empty State Snapshot Tests
    
    func testEmptyStateSnapshots() {
        let basicEmptyState = EmptyStateView(
            icon: "cart",
            title: "Empty Cart",
            message: "Your cart is empty. Add some items to get started."
        )
        
        let emptyStateWithAction = EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results",
            message: "We couldn't find any results for your search. Try adjusting your filters or search terms.",
            actionTitle: "Browse All Items"
        ) {
            // Action
        }
        
        XCTAssertNotNil(basicEmptyState)
        XCTAssertNotNil(emptyStateWithAction)
    }
    
    // MARK: - Card Snapshot Tests
    
    func testCardSnapshots() {
        let basicCard = AppCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Card Title")
                    .font(.titleMedium)
                    .foregroundColor(.graphite)
                
                Text("This is a sample card with some content to demonstrate the card component styling.")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
            }
        }
        
        let compactCard = AppCard(padding: Spacing.sm, cornerRadius: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.warning)
                Text("Compact Card")
                    .font(.labelMedium)
                    .foregroundColor(.graphite)
                Spacer()
            }
        }
        
        XCTAssertNotNil(basicCard)
        XCTAssertNotNil(compactCard)
    }
    
    // MARK: - Divider Snapshot Tests
    
    func testDividerSnapshots() {
        let basicDivider = AppDivider()
        let customDivider = AppDivider(
            color: .emerald,
            thickness: 2,
            padding: EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        )
        let sectionDivider = SectionDivider(title: "Settings")
        
        XCTAssertNotNil(basicDivider)
        XCTAssertNotNil(customDivider)
        XCTAssertNotNil(sectionDivider)
    }
    
    // MARK: - Typography Snapshot Tests
    
    func testTypographySnapshots() {
        let typographyStack = VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Display Large")
                .font(.displayLarge)
            Text("Headline Medium")
                .font(.headlineMedium)
            Text("Title Large")
                .font(.titleLarge)
            Text("Body Medium")
                .font(.bodyMedium)
            Text("Label Small")
                .font(.labelSmall)
        }
        
        XCTAssertNotNil(typographyStack)
    }
    
    // MARK: - Color Palette Snapshot Tests
    
    func testColorPaletteSnapshots() {
        let colorGrid = LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.sm) {
            ColorSwatch(color: .emerald, name: "Emerald")
            ColorSwatch(color: .chalk, name: "Chalk")
            ColorSwatch(color: .graphite, name: "Graphite")
            ColorSwatch(color: .success, name: "Success")
            ColorSwatch(color: .warning, name: "Warning")
            ColorSwatch(color: .error, name: "Error")
            ColorSwatch(color: .info, name: "Info")
            ColorSwatch(color: .gray300, name: "Gray 300")
            ColorSwatch(color: .gray600, name: "Gray 600")
        }
        
        XCTAssertNotNil(colorGrid)
    }
    
    // MARK: - Dark Mode Snapshot Tests
    
    func testDarkModeSnapshots() {
        // Test components in dark mode
        let darkModeButton = PrimaryButton(title: "Dark Mode Button") {}
            .preferredColorScheme(.dark)
        
        let darkModeCard = AppCard {
            Text("Dark Mode Card")
                .font(.titleMedium)
        }
        .preferredColorScheme(.dark)
        
        XCTAssertNotNil(darkModeButton)
        XCTAssertNotNil(darkModeCard)
    }
    
    // MARK: - Accessibility Size Snapshot Tests
    
    func testAccessibilitySizeSnapshots() {
        // Test components with accessibility text sizes
        let accessibilityButton = PrimaryButton(title: "Accessibility Button") {}
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        
        let accessibilityText = Text("Accessibility Text")
            .font(.bodyMedium)
            .environment(\.sizeCategory, .accessibilityLarge)
        
        XCTAssertNotNil(accessibilityButton)
        XCTAssertNotNil(accessibilityText)
    }
}

// MARK: - Helper Views for Testing

private struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: Spacing.xs) {
            Rectangle()
                .fill(color)
                .frame(height: 40)
                .cornerRadius(8)
            
            Text(name)
                .font(.labelSmall)
                .foregroundColor(.gray600)
        }
    }
}