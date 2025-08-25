//
//  AdvancedAnimations.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

// MARK: - Advanced Animation System

/// Enhanced animation configurations with performance optimizations
struct AdvancedAnimation {
    
    // MARK: - Predefined Animations
    static let elastic = Animation.interpolatingSpring(
        mass: 0.8,
        stiffness: 120,
        damping: 12,
        initialVelocity: 0.5
    )
    
    static let snappy = Animation.interpolatingSpring(
        mass: 0.5,
        stiffness: 200,
        damping: 15,
        initialVelocity: 0
    )
    
    static let gentle = Animation.interpolatingSpring(
        mass: 1.2,
        stiffness: 80,
        damping: 20,
        initialVelocity: 0
    )
    
    static let bouncy = Animation.interpolatingSpring(
        mass: 0.6,
        stiffness: 150,
        damping: 8,
        initialVelocity: 0.3
    )
    
    static let smooth = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.4)
    
    // MARK: - Complex Transition Types
    enum TransitionType {
        case slideAndFade(edge: Edge)
        case scaleAndRotate(angle: Angle)
        case morphing
        case particle
        case liquid
        case magnetic
        
        var transition: AnyTransition {
            switch self {
            case .slideAndFade(let edge):
                return .asymmetric(
                    insertion: .move(edge: edge).combined(with: .opacity.animation(.easeOut(duration: 0.3))),
                    removal: .move(edge: edge).combined(with: .opacity.animation(.easeIn(duration: 0.2)))
                )
            case .scaleAndRotate(let angle):
                return .asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity.animation(AdvancedAnimation.elastic)),
                    removal: .scale(scale: 1.2).combined(with: .opacity.animation(AdvancedAnimation.snappy))
                )
            case .morphing:
                return .asymmetric(
                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                    removal: .scale(scale: 2.0).combined(with: .opacity)
                )
            case .particle:
                return .asymmetric(
                    insertion: .modifier(
                        active: ParticleModifier(progress: 0),
                        identity: ParticleModifier(progress: 1)
                    ),
                    removal: .opacity.animation(.easeOut(duration: 0.2))
                )
            case .liquid:
                return .asymmetric(
                    insertion: .modifier(
                        active: LiquidModifier(progress: 0),
                        identity: LiquidModifier(progress: 1)
                    ),
                    removal: .opacity
                )
            case .magnetic:
                return .asymmetric(
                    insertion: .modifier(
                        active: MagneticModifier(progress: 0),
                        identity: MagneticModifier(progress: 1)
                    ),
                    removal: .opacity
                )
            }
        }
    }
}

// MARK: - Custom Animation Modifiers

struct ParticleModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(progress * progress) // Quadratic easing
            .opacity(progress)
            .blur(radius: (1 - progress) * 5)
            .rotation3DEffect(
                .degrees(360 * (1 - progress)),
                axis: (x: 1, y: 1, z: 0)
            )
    }
}

struct LiquidModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(x: 0.5 + progress * 0.5, y: progress)
            .opacity(progress)
            .blur(radius: (1 - progress) * 3)
    }
}

struct MagneticModifier: ViewModifier {
    let progress: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(progress)
            .opacity(progress * progress)
            .rotation3DEffect(
                .degrees(180 * (1 - progress)),
                axis: (x: 0, y: 1, z: 0)
            )
    }
}

// MARK: - Enhanced Hero Transition System

class HeroTransitionCoordinator: ObservableObject, @unchecked Sendable {
    @Published var activeTransitions: Set<String> = []
    @Published var transitionProgress: [String: Double] = [:]
    
    private var animationCompletionHandlers: [String: () -> Void] = [:]
    
    func beginTransition(id: String, completion: (() -> Void)? = nil) {
        activeTransitions.insert(id)
        transitionProgress[id] = 0.0
        
        if let completion = completion {
            animationCompletionHandlers[id] = completion
        }
        
        withAnimation(.smooth) {
            transitionProgress[id] = 1.0
        }
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task { @MainActor in
                self.completeTransition(id: id)
            }
        }
    }
    
    func completeTransition(id: String) {
        activeTransitions.remove(id)
        transitionProgress.removeValue(forKey: id)
        
        if let completion = animationCompletionHandlers.removeValue(forKey: id) {
            completion()
        }
    }
    
    func isTransitioning(id: String) -> Bool {
        return activeTransitions.contains(id)
    }
    
    func progressFor(id: String) -> Double {
        return transitionProgress[id] ?? 0.0
    }
}

// MARK: - Advanced Matched Geometry Effect

struct EnhancedMatchedGeometry: ViewModifier {
    let id: String
    let namespace: Namespace.ID
    let properties: MatchedGeometryProperties
    let anchor: UnitPoint
    let isSource: Bool
    
    @StateObject private var coordinator = HeroTransitionCoordinator()
    
    func body(content: Content) -> some View {
        content
            .matchedGeometryEffect(
                id: id,
                in: namespace,
                properties: properties,
                anchor: anchor,
                isSource: isSource
            )
            .scaleEffect(coordinator.isTransitioning(id: id) ? 1.05 : 1.0)
            .opacity(coordinator.isTransitioning(id: id) ? 0.9 : 1.0)
            .animation(AdvancedAnimation.elastic, value: coordinator.isTransitioning(id: id))
    }
}

// MARK: - View Extensions

extension View {
    /// Apply advanced transition
    func advancedTransition(_ type: AdvancedAnimation.TransitionType) -> some View {
        self.transition(type.transition)
    }
    
    /// Enhanced matched geometry effect
    func enhancedMatchedGeometry(
        id: String,
        in namespace: Namespace.ID,
        properties: MatchedGeometryProperties = .frame,
        anchor: UnitPoint = .center,
        isSource: Bool = true
    ) -> some View {
        self.modifier(EnhancedMatchedGeometry(
            id: id,
            namespace: namespace,
            properties: properties,
            anchor: anchor,
            isSource: isSource
        ))
    }
    
    /// Elastic scale animation
    func elasticScale(trigger: some Equatable) -> some View {
        self
            .scaleEffect(1.0)
            .animation(AdvancedAnimation.elastic, value: trigger)
    }
    
    /// Morphing animation
    func morphingEffect(isActive: Bool) -> some View {
        self
            .scaleEffect(isActive ? 1.2 : 1.0)
            .blur(radius: isActive ? 2 : 0)
            .animation(AdvancedAnimation.gentle, value: isActive)
    }
}

// MARK: - Angle Extension

extension Angle {
    var opposite: Angle {
        return Angle(degrees: self.degrees + 180)
    }
}

// MARK: - Preview

struct AdvancedAnimations_Previews: PreviewProvider {
    @Namespace static var previewNamespace
    
    static var previews: some View {
        VStack(spacing: 20) {
            Rectangle()
                .fill(Color.emerald)
                .frame(width: 100, height: 100)
                .enhancedMatchedGeometry(id: "demo", in: previewNamespace)
            
            Button("Animate") {
                // Demo animation
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .elasticScale(trigger: UUID())
        }
        .padding()
    }
}