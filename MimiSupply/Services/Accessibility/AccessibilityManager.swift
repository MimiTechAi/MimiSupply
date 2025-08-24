//
//  AccessibilityManager.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import UIKit
import Combine
import os

/// Simplified accessibility manager for the app
@MainActor
final class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    // MARK: - Published Properties
    @Published var isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
    @Published var isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
    @Published var isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    @Published var preferredContentSizeCategory = UIApplication.shared.preferredContentSizeCategory
    @Published var isAccessibilitySize = false
    @Published var isHighContrastEnabled = false
    
    private let logger = Logger(subsystem: "MimiSupply", category: "AccessibilityManager")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupAccessibilityMonitoring()
        updateAccessibilityStates()
        logger.info("🎯 AccessibilityManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Announce a message for VoiceOver users
    func announce(_ message: String) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
    
    /// Get scaled font size based on current content size category
    func scaledFontSize(for baseSize: CGFloat) -> CGFloat {
        return baseSize * preferredContentSizeCategory.scaleFactor
    }
    
    /// Get scaled spacing based on current content size category
    func scaledSpacing(for baseSpacing: CGFloat) -> CGFloat {
        return baseSpacing * preferredContentSizeCategory.spacingMultiplier
    }
    
    // MARK: - Private Methods
    
    private func setupAccessibilityMonitoring() {
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                self?.logger.info("VoiceOver status changed: \(UIAccessibility.isVoiceOverRunning)")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIAccessibility.reduceMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                self?.isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
                self?.logger.info("Reduce Motion status changed: \(UIAccessibility.isReduceMotionEnabled)")
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            .sink { [weak self] _ in
                self?.updateContentSizeCategory()
            }
            .store(in: &cancellables)
    }
    
    private func updateAccessibilityStates() {
        isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isDarkerSystemColorsEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        isHighContrastEnabled = isDarkerSystemColorsEnabled
        updateContentSizeCategory()
    }
    
    private func updateContentSizeCategory() {
        let newValue = UIApplication.shared.preferredContentSizeCategory
        if newValue != preferredContentSizeCategory {
            preferredContentSizeCategory = newValue
            isAccessibilitySize = newValue.isAccessibilityCategory
            logger.info("Content Size Category changed: \(newValue.rawValue)")
        }
    }
}

// MARK: - UIContentSizeCategory Extensions

extension UIContentSizeCategory {
    var scaleFactor: CGFloat {
        switch self {
        case .extraSmall: return 0.8
        case .small: return 0.9
        case .medium: return 0.95
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.6
        case .accessibilityExtraLarge: return 1.8
        case .accessibilityExtraExtraLarge: return 2.0
        case .accessibilityExtraExtraExtraLarge: return 2.2
        default: return 1.0
        }
    }
    
    var spacingMultiplier: CGFloat {
        switch self {
        case .extraSmall: return 0.9
        case .small: return 0.95
        case .medium: return 0.98
        case .large: return 1.0
        case .extraLarge: return 1.05
        case .extraExtraLarge: return 1.1
        case .extraExtraExtraLarge: return 1.15
        case .accessibilityMedium: return 1.2
        case .accessibilityLarge: return 1.3
        case .accessibilityExtraLarge: return 1.4
        case .accessibilityExtraExtraLarge: return 1.5
        case .accessibilityExtraExtraExtraLarge: return 1.6
        default: return 1.0
        }
    }
}