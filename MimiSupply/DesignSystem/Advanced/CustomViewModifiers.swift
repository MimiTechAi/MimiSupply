//
//  CustomViewModifiers.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

// MARK: - Advanced Custom View Modifiers

/// Shimmer effect modifier for loading states
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    let gradient = LinearGradient(
        colors: [
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.3)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    func body(content: Content) -> some View {
        content
            .mask(
                Rectangle()
                    .fill(gradient)
                    .scaleEffect(x: isAnimating ? 3 : 1, y: 1)
                    .offset(x: isAnimating ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .onAppear {
                isAnimating = true
            }
    }
}

/// Glass morphism effect modifier
struct GlassMorphismModifier: ViewModifier {
    let intensity: Double
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial.opacity(intensity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

/// Neumorphism effect modifier
struct NeumorphismModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    @Environment(\.colorScheme) var colorScheme
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    private var highlightColor: Color {
        colorScheme == .dark ? Color(red: 0.3, green: 0.3, blue: 0.3) : Color.white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black : Color(red: 0.8, green: 0.8, blue: 0.8)
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: highlightColor,
                        radius: shadowRadius,
                        x: -shadowRadius,
                        y: -shadowRadius
                    )
                    .shadow(
                        color: shadowColor,
                        radius: shadowRadius,
                        x: shadowRadius,
                        y: shadowRadius
                    )
            )
    }
}

/// Floating action button modifier
struct FloatingActionModifier: ViewModifier {
    let position: FloatingPosition
    let offset: CGSize
    let shadow: Bool
    
    enum FloatingPosition {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
        case center
        
        var alignment: Alignment {
            switch self {
            case .topLeading: return .topLeading
            case .topTrailing: return .topTrailing
            case .bottomLeading: return .bottomLeading
            case .bottomTrailing: return .bottomTrailing
            case .center: return .center
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                FloatingContent()
                    .offset(offset),
                alignment: position.alignment
            )
    }
    
    @ViewBuilder
    private func FloatingContent() -> some View {
        if shadow {
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(radius: 8)
        } else {
            Circle()
                .fill(.ultraThinMaterial)
        }
    }
}

/// Advanced card modifier with multiple effects
struct AdvancedCardModifier: ViewModifier {
    let style: CardStyle
    let cornerRadius: CGFloat
    let shadowIntensity: Double
    let isInteractive: Bool
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    enum CardStyle {
        case elevated
        case flat
        case glassmorphic
        case neumorphic
        case outlined
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
            .background(backgroundForStyle())
            .overlay(overlayForStyle())
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onTapGesture {
                if isInteractive {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            isPressed = false
                        }
                    }
                }
            }
            .onHover { hovering in
                if isInteractive {
                    isHovered = hovering
                }
            }
    }
    
    @ViewBuilder
    private func backgroundForStyle() -> some View {
        switch style {
        case .elevated:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(shadowIntensity * 0.1),
                    radius: shadowIntensity * 8,
                    x: 0,
                    y: shadowIntensity * 4
                )
        case .flat:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
        case .glassmorphic:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
        case .neumorphic:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .modifier(NeumorphismModifier(cornerRadius: cornerRadius, shadowRadius: 8))
        case .outlined:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(.separator), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private func overlayForStyle() -> some View {
        if style == .glassmorphic {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

/// Particle system modifier
struct ParticleSystemModifier: ViewModifier {
    let particleCount: Int
    let colors: [Color]
    let speed: Double
    
    @State private var particles: [Particle] = []
    @State private var timer: Timer?
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var color: Color
        var size: CGFloat
        var life: Double
        let maxLife: Double
        
        init(startPosition: CGPoint, colors: [Color]) {
            position = startPosition
            velocity = CGPoint(
                x: Double.random(in: -2...2),
                y: Double.random(in: -3...1)
            )
            color = colors.randomElement() ?? .blue
            size = CGFloat.random(in: 2...6)
            life = 1.0
            maxLife = Double.random(in: 2...4)
        }
        
        mutating func update() {
            position.x += velocity.x
            position.y += velocity.y
            velocity.y += 0.1 // gravity
            life -= 0.02
        }
        
        var opacity: Double {
            life / maxLife
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(particles) { particle in
                        Circle()
                            .fill(particle.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .opacity(particle.opacity)
                    }
                }
                .clipped()
            )
            .onAppear {
                startParticleSystem()
            }
            .onDisappear {
                stopParticleSystem()
            }
    }
    
    private func startParticleSystem() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                updateParticles()
            }
        }
    }
    
    private func stopParticleSystem() {
        timer?.invalidate()
        timer = nil
    }
    
    @MainActor
    private func updateParticles() {
        // Update existing particles
        for i in particles.indices {
            particles[i].update()
        }
        
        // Remove dead particles
        particles.removeAll { $0.life <= 0 }
        
        // Add new particles if needed
        if particles.count < particleCount {
            particles.append(Particle(
                startPosition: CGPoint(x: Double.random(in: 0...300), y: 300),
                colors: colors
            ))
        }
    }
}

/// Ripple effect modifier
struct RippleModifier: ViewModifier {
    @State private var ripples: [RippleEffect] = []
    
    struct RippleEffect: Identifiable {
        let id = UUID()
        let position: CGPoint
        let startTime: Date = Date()
        
        var progress: Double {
            Date().timeIntervalSince(startTime) / 0.6
        }
        
        var isExpired: Bool {
            progress >= 1.0
        }
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(ripples) { ripple in
                        Circle()
                            .stroke(Color.emerald.opacity(0.3), lineWidth: 2)
                            .scaleEffect(ripple.progress * 2)
                            .opacity(1 - ripple.progress)
                            .position(ripple.position)
                            .animation(.easeOut(duration: 0.6), value: ripple.progress)
                    }
                }
                .clipped()
            )
            .contentShape(Rectangle())
            .onTapGesture { location in
                addRipple(at: location)
            }
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                cleanupRipples()
            }
    }
    
    private func addRipple(at position: CGPoint) {
        ripples.append(RippleEffect(position: position))
    }
    
    private func cleanupRipples() {
        ripples.removeAll { $0.isExpired }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply shimmer loading effect
    func shimmerEffect() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    /// Apply glass morphism effect
    func glassMorphism(intensity: Double = 0.8, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(GlassMorphismModifier(intensity: intensity, cornerRadius: cornerRadius))
    }
    
    /// Apply neumorphism effect
    func neumorphism(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8) -> some View {
        self.modifier(NeumorphismModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
    
    /// Apply advanced card styling
    func advancedCard(
        style: AdvancedCardModifier.CardStyle = .elevated,
        cornerRadius: CGFloat = 12,
        shadowIntensity: Double = 1.0,
        isInteractive: Bool = true
    ) -> some View {
        self.modifier(AdvancedCardModifier(
            style: style,
            cornerRadius: cornerRadius,
            shadowIntensity: shadowIntensity,
            isInteractive: isInteractive
        ))
    }
    
    /// Add floating action button
    func floatingAction(
        position: FloatingActionModifier.FloatingPosition = .bottomTrailing,
        offset: CGSize = CGSize(width: -20, height: -20),
        shadow: Bool = true
    ) -> some View {
        self.modifier(FloatingActionModifier(position: position, offset: offset, shadow: shadow))
    }
    
    /// Add particle system effect
    func particleSystem(
        particleCount: Int = 20,
        colors: [Color] = [.emerald, .blue, .purple],
        speed: Double = 1.0
    ) -> some View {
        self.modifier(ParticleSystemModifier(
            particleCount: particleCount,
            colors: colors,
            speed: speed
        ))
    }
    
    /// Add ripple effect on tap
    func rippleEffect() -> some View {
        self.modifier(RippleModifier())
    }
    
    /// Conditional modifier application
    func conditionally<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        Group {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }
    
    /// Apply multiple modifiers based on conditions
    func styled(
        glassMorphism: Bool = false,
        neumorphism: Bool = false,
        shimmer: Bool = false,
        ripple: Bool = false,
        particles: Bool = false
    ) -> some View {
        self
            .conditionally(glassMorphism) { $0.glassMorphism() }
            .conditionally(neumorphism) { $0.neumorphism() }
            .conditionally(shimmer) { $0.shimmerEffect() }
            .conditionally(ripple) { $0.rippleEffect() }
            .conditionally(particles) { $0.particleSystem() }
    }
}