import SwiftUI
import UIKit

/// Optimizes animations for 120Hz displays and provides smooth performance
struct AnimationOptimizer {
    
    // MARK: - High Refresh Rate Animations
    
    /// Optimized spring animation for 120Hz displays
    static let smoothSpring = Animation.spring(
        response: 0.4,
        dampingFraction: 0.8,
        blendDuration: 0.1
    )
    
    /// Fast spring animation for quick interactions
    static let quickSpring = Animation.spring(
        response: 0.2,
        dampingFraction: 0.9,
        blendDuration: 0.05
    )
    
    /// Smooth easing animation
    static let smoothEase = Animation.easeInOut(duration: 0.3)
    
    /// Quick fade animation
    static let quickFade = Animation.easeInOut(duration: 0.15)
    
    /// Bouncy animation for delightful interactions
    static let bouncy = Animation.spring(
        response: 0.5,
        dampingFraction: 0.6,
        blendDuration: 0.1
    )
    
    // MARK: - Reduced Motion Support
    
    /// Returns appropriate animation based on accessibility settings
    static func adaptiveAnimation(_ defaultAnimation: Animation) -> Animation? {
        if UIAccessibility.isReduceMotionEnabled {
            return nil // No animation
        }
        return defaultAnimation
    }
    
    /// Smooth animation that respects reduce motion
    static var accessibleSmooth: Animation? {
        adaptiveAnimation(smoothSpring)
    }
    
    /// Quick animation that respects reduce motion
    static var accessibleQuick: Animation? {
        adaptiveAnimation(quickSpring)
    }
}

// MARK: - Performance-Optimized Animation Modifiers

struct OptimizedScaleEffect: ViewModifier {
    let scale: CGFloat
    let animation: Animation?
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(animation, value: scale)
            .drawingGroup() // Optimize for complex animations
    }
}

struct OptimizedOpacity: ViewModifier {
    let opacity: Double
    let animation: Animation?
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .animation(animation, value: opacity)
    }
}

struct OptimizedOffset: ViewModifier {
    let offset: CGSize
    let animation: Animation?
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .animation(animation, value: offset)
    }
}

struct OptimizedRotation: ViewModifier {
    let angle: Angle
    let animation: Animation?
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(angle)
            .animation(animation, value: angle)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies optimized scale effect with smooth animation
    func optimizedScale(_ scale: CGFloat, animation: Animation? = AnimationOptimizer.smoothSpring) -> some View {
        modifier(OptimizedScaleEffect(scale: scale, animation: AnimationOptimizer.adaptiveAnimation(animation ?? AnimationOptimizer.smoothSpring)))
    }
    
    /// Applies optimized opacity with smooth animation
    func optimizedOpacity(_ opacity: Double, animation: Animation? = AnimationOptimizer.smoothEase) -> some View {
        modifier(OptimizedOpacity(opacity: opacity, animation: AnimationOptimizer.adaptiveAnimation(animation ?? AnimationOptimizer.smoothEase)))
    }
    
    /// Applies optimized offset with smooth animation
    func optimizedOffset(_ offset: CGSize, animation: Animation? = AnimationOptimizer.smoothSpring) -> some View {
        modifier(OptimizedOffset(offset: offset, animation: AnimationOptimizer.adaptiveAnimation(animation ?? AnimationOptimizer.smoothSpring)))
    }
    
    /// Applies optimized rotation with smooth animation
    func optimizedRotation(_ angle: Angle, animation: Animation? = AnimationOptimizer.smoothSpring) -> some View {
        modifier(OptimizedRotation(angle: angle, animation: AnimationOptimizer.adaptiveAnimation(animation ?? AnimationOptimizer.smoothSpring)))
    }
    
    /// Optimizes view for smooth scrolling
    func optimizedForScrolling() -> some View {
        self
            .drawingGroup() // Rasterize complex views
            .clipped() // Prevent overdraw
    }
    
    /// Applies performance optimizations for list items
    func optimizedListItem() -> some View {
        self
            .drawingGroup(opaque: false, colorMode: .nonLinear)
            .compositingGroup()
    }
}

// MARK: - Smooth Scroll View

struct SmoothScrollView<Content: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    
    @State private var scrollOffset: CGPoint = .zero
    @State private var isDragging = false
    
    init(
        _ axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.content = content()
    }
    
    var body: some View {
        ScrollView(axes, showsIndicators: showsIndicators) {
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scrollView")).origin
                            )
                    }
                )
        }
        .coordinateSpace(name: "scrollView")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            withAnimation(AnimationOptimizer.accessibleQuick) {
                scrollOffset = value
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { _ in
                    isDragging = true
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}

// MARK: - Preference Key for Scroll Offset

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}