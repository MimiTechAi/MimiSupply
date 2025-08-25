//
//  MotionManager.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import UIKit
import Combine
import os

/// Manages motion preferences and animations throughout the app
@MainActor
final class MotionManager: ObservableObject {
    static let shared = MotionManager()
    
    @Published var reduceMotionEnabled: Bool = UIAccessibility.isReduceMotionEnabled
    @Published var prefersCrossFadeTransitions: Bool = UIAccessibility.prefersCrossFadeTransitions
    @Published var isVideoAutoplayEnabled: Bool = UIAccessibility.isVideoAutoplayEnabled
    
    private let logger = Logger(subsystem: "MimiSupply", category: "MotionManager")
    private var cancellables = Set<AnyCancellable>()
    
    // Animation configurations
    struct AnimationConfig {
        let duration: Double
        let reducedDuration: Double
        let animation: Animation
        let reducedAnimation: Animation
        
        static let `default` = AnimationConfig(
            duration: 0.3,
            reducedDuration: 0.1,
            animation: .easeInOut(duration: 0.3),
            reducedAnimation: .linear(duration: 0.1)
        )
        
        static let spring = AnimationConfig(
            duration: 0.6,
            reducedDuration: 0.2,
            animation: .spring(response: 0.6, dampingFraction: 0.8),
            reducedAnimation: .linear(duration: 0.2)
        )
        
        static let bouncy = AnimationConfig(
            duration: 0.8,
            reducedDuration: 0.15,
            animation: .spring(response: 0.5, dampingFraction: 0.6),
            reducedAnimation: .linear(duration: 0.15)
        )
    }
    
    var respectsReduceMotion: Bool {
        return reduceMotionEnabled
    }
    
    private init() {
        setupMotionMonitoring()
        logger.info("MotionManager initialized with reduceMotion: \(self.reduceMotionEnabled)")
    }
    
    // MARK: - Public Methods
    
    /// Get appropriate animation based on motion preferences
    func animation(for config: AnimationConfig = .default) -> Animation {
        return reduceMotionEnabled ? config.reducedAnimation : config.animation
    }
    
    /// Get appropriate duration based on motion preferences
    func duration(for config: AnimationConfig = .default) -> Double {
        return reduceMotionEnabled ? config.reducedDuration : config.duration
    }
    
    /// Perform animation with motion respect
    func withAnimation<Result>(
        _ config: AnimationConfig = .default,
        _ body: () throws -> Result
    ) rethrows -> Result {
        return try SwiftUI.withAnimation(animation(for: config), body)
    }
    
    /// Create a conditional transition based on motion preferences
    func transition(
        normal: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> AnyTransition {
        return reduceMotionEnabled ? reduced : normal
    }
    
    /// Check if a specific animation should be performed
    func shouldAnimate(type: MotionAnimationType) -> Bool {
        if reduceMotionEnabled {
            return type.allowedWithReduceMotion
        }
        return true
    }
    
    /// Get haptic feedback intensity based on motion preferences
    func hapticIntensity() -> CGFloat {
        return reduceMotionEnabled ? 0.3 : 1.0
    }
    
    // MARK: - Private Methods
    
    private func setupMotionMonitoring() {
        // Monitor reduce motion changes
        NotificationCenter.default.publisher(for: UIAccessibility.reducedMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateMotionSettings()
                }
            }
            .store(in: &cancellables)
        
        // Monitor cross fade preference changes - using existing notification name
        NotificationCenter.default.publisher(for: UIAccessibility.reducedMotionStatusDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateCrossFadeSettings()
                }
            }
            .store(in: &cancellables)
        
        // Monitor video autoplay changes
        NotificationCenter.default.publisher(for: UIAccessibility.videoAutoplayStatusDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateVideoAutoplaySettings()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateMotionSettings() {
        let newValue = UIAccessibility.isReduceMotionEnabled
        if newValue != reduceMotionEnabled {
            reduceMotionEnabled = newValue
            logger.info("Reduce motion setting changed to: \(newValue)")
        }
    }
    
    private func updateCrossFadeSettings() {
        let newValue = UIAccessibility.prefersCrossFadeTransitions
        if newValue != prefersCrossFadeTransitions {
            prefersCrossFadeTransitions = newValue
            logger.info("Cross fade preference changed to: \(newValue)")
        }
    }
    
    private func updateVideoAutoplaySettings() {
        let newValue = UIAccessibility.isVideoAutoplayEnabled
        if newValue != isVideoAutoplayEnabled {
            isVideoAutoplayEnabled = newValue
            logger.info("Video autoplay setting changed to: \(newValue)")
        }
    }
}

// MARK: - Motion Animation Types (renamed to avoid conflicts)

enum MotionAnimationType {
    case pageTransition
    case buttonPress
    case modalPresentation
    case listInsertion
    case shimmerEffect
    case pulseEffect
    case slideIn
    case fadeIn
    case scaleIn
    case rotation
    case parallax
    case backgroundVideo
    
    var allowedWithReduceMotion: Bool {
        switch self {
        case .pageTransition, .modalPresentation:
            return true // Essential for navigation
        case .buttonPress, .fadeIn:
            return true // Minimal motion
        case .shimmerEffect, .pulseEffect, .parallax, .backgroundVideo:
            return false // Decorative animations
        case .listInsertion, .slideIn, .scaleIn, .rotation:
            return false // Non-essential animations
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply motion-aware animation
    func motionAwareAnimation(
        _ config: MotionManager.AnimationConfig = .default,
        value: some Equatable
    ) -> some View {
        self.animation(MotionManager.shared.animation(for: config), value: value)
    }
    
    /// Apply motion-aware transition
    func motionAwareTransition(
        normal: AnyTransition,
        reduced: AnyTransition = .opacity
    ) -> some View {
        self.transition(MotionManager.shared.transition(normal: normal, reduced: reduced))
    }
    
    /// Conditional animation based on motion preferences
    func conditionalAnimation(
        type: MotionAnimationType,
        config: Animation = .default,
        value: some Equatable
    ) -> some View {
        self.animation(
            MotionManager.shared.shouldAnimate(type: type) 
                ? config
                : nil, 
            value: value
        )
    }
}

// MARK: - Motion-Aware Components

struct MotionAwareButton<Content: View>: View {
    let action: () -> Void
    let content: Content
    
    @State private var isPressed = false
    @StateObject private var motionManager = MotionManager.shared
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            if motionManager.shouldAnimate(type: .buttonPress) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            }
        })
    }
}

struct MotionAwareProgress: View {
    let progress: Double
    
    @StateObject private var motionManager = MotionManager.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                
                Rectangle()
                    .fill(Color.emerald)
                    .frame(width: geometry.size.width * progress)
                    .conditionalAnimation(
                        type: .slideIn,
                        config: .default,
                        value: progress
                    )
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

struct MotionManager_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Motion-Aware Components")
                .font(.title)
            
            MotionAwareButton(action: {}) {
                Text("Tap Me")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.emerald)
                    .cornerRadius(12)
            }
            
            MotionAwareProgress(progress: 0.7)
                .padding()
            
            Text("Reduce Motion: \(MotionManager.shared.reduceMotionEnabled ? "ON" : "OFF")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}