//
//  ExploreHomeViewSupport.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import SwiftUI
import MapKit

// MARK: - Filter Sheet (defined in FilterSheet.swift)

// MARK: - Cart Button
// Moved to DesignSystem/Components/Buttons/CartButton.swift

// MARK: - Optimized List View
// Moved to Foundation/Performance/LazyListRenderer.swift

// MARK: - Cached Async Image
// Moved to Foundation/Performance/ImageCache.swift

// MARK: - View Extensions for Performance and Accessibility
extension View {
    // optimizedListItem() is defined in AnimationOptimizer.swift
    
    func trackScreen(_ screenName: String, parameters: [String: Any] = [:]) -> some View {
        self.onAppear {
            // Track screen view
            print("Screen viewed: \(screenName) with parameters: \(parameters)")
        }
    }
    
    func trackPerformanceForExplore(_ eventName: String) -> some View {
        self.onAppear {
            // Track performance metric
            print("Performance event: \(eventName)")
        }
    }
    
    func memoryEfficientForExplore() -> some View {
        self
            .clipped() // Prevent overdraw
    }
    
    func optimizeStartupForExplore() -> some View {
        self
            .task(priority: .background) {
                // Perform background initialization
            }
    }
    
    func accessibleButton(label: String, hint: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
    
    // Note: Accessibility extensions are defined in DesignSystem/Accessibility/AccessibilityModifiers.swift
}

// Note: Analytics environment values and protocols are defined in AnalyticsManager.swift

// Note: Coordinate extension removed to avoid duplicate property conflict