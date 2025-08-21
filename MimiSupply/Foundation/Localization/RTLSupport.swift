//
//  RTLSupport.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI

// MARK: - RTL Layout Support

/// Utilities for right-to-left language support
struct RTLSupport {
    
    // MARK: - Layout Direction
    
    /// Get the appropriate layout direction for current language
    @MainActor static var layoutDirection: LayoutDirection {
        return LocalizationManager.shared.isRightToLeft ? .rightToLeft : .leftToRight
    }
    
    /// Get the appropriate text alignment for current language
    @MainActor static var textAlignment: TextAlignment {
        return LocalizationManager.shared.isRightToLeft ? .trailing : .leading
    }
    
    /// Get the appropriate horizontal alignment for current language
    @MainActor static var horizontalAlignment: HorizontalAlignment {
        return LocalizationManager.shared.isRightToLeft ? .trailing : .leading
    }
    
    /// Get the appropriate alignment for current language
    @MainActor static var alignment: Alignment {
        return LocalizationManager.shared.isRightToLeft ? .trailing : .leading
    }
    
    // MARK: - Edge Utilities
    
    /// Get the leading edge for current language
    @MainActor static var leadingEdge: Edge {
        return LocalizationManager.shared.isRightToLeft ? .trailing : .leading
    }
    
    /// Get the trailing edge for current language
    @MainActor static var trailingEdge: Edge {
        return LocalizationManager.shared.isRightToLeft ? .leading : .trailing
    }
    
    /// Get the leading edge set for current language
    @MainActor static var leadingEdgeSet: Edge.Set {
        return LocalizationManager.shared.isRightToLeft ? .trailing : .leading
    }
    
    /// Get the trailing edge set for current language
    @MainActor static var trailingEdgeSet: Edge.Set {
        return LocalizationManager.shared.isRightToLeft ? .leading : .trailing
    }
    
    // MARK: - Animation Utilities
    
    /// Get slide-in animation from leading edge
    @MainActor static var slideInFromLeading: AnyTransition {
        return .asymmetric(
            insertion: .move(edge: leadingEdge),
            removal: .move(edge: trailingEdge)
        )
    }
    
    /// Get slide-in animation from trailing edge
    @MainActor static var slideInFromTrailing: AnyTransition {
        return .asymmetric(
            insertion: .move(edge: trailingEdge),
            removal: .move(edge: leadingEdge)
        )
    }
    
    // MARK: - Icon Utilities
    
    /// Get the appropriate chevron icon for navigation
    @MainActor static var chevronForward: String {
        return LocalizationManager.shared.isRightToLeft ? "chevron.left" : "chevron.right"
    }
    
    /// Get the appropriate chevron icon for back navigation
    @MainActor static var chevronBack: String {
        return LocalizationManager.shared.isRightToLeft ? "chevron.right" : "chevron.left"
    }
    
    /// Get the appropriate arrow icon for forward direction
    @MainActor static var arrowForward: String {
        return LocalizationManager.shared.isRightToLeft ? "arrow.left" : "arrow.right"
    }
    
    /// Get the appropriate arrow icon for back direction
    @MainActor static var arrowBack: String {
        return LocalizationManager.shared.isRightToLeft ? "arrow.right" : "arrow.left"
    }
    
    // MARK: - Rotation Utilities
    
    /// Get rotation angle for RTL adaptation
    @MainActor static func rotationAngle(for degrees: Double) -> Double {
        return LocalizationManager.shared.isRightToLeft ? -degrees : degrees
    }
    
    /// Flip horizontal offset for RTL
    @MainActor static func horizontalOffset(_ offset: CGFloat) -> CGFloat {
        return LocalizationManager.shared.isRightToLeft ? -offset : offset
    }
}

// MARK: - RTL-Aware View Modifiers

struct RTLAwareModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.layoutDirection, RTLSupport.layoutDirection)
    }
}

struct RTLAwarePaddingModifier: ViewModifier {
    let leading: CGFloat?
    let trailing: CGFloat?
    let top: CGFloat?
    let bottom: CGFloat?
    
    func body(content: Content) -> some View {
        content
            .padding(.top, top)
            .padding(.bottom, bottom)
            .padding(RTLSupport.leadingEdgeSet, leading)
            .padding(RTLSupport.trailingEdgeSet, trailing)
    }
}

struct RTLAwareAlignmentModifier: ViewModifier {
    let alignment: HorizontalAlignment
    
    func body(content: Content) -> some View {
        let rtlAlignment: HorizontalAlignment
        
        if LocalizationManager.shared.isRightToLeft {
            switch alignment {
            case .leading:
                rtlAlignment = .trailing
            case .trailing:
                rtlAlignment = .leading
            default:
                rtlAlignment = alignment
            }
        } else {
            rtlAlignment = alignment
        }
        
        return content
            .frame(maxWidth: .infinity, alignment: Alignment(horizontal: rtlAlignment, vertical: .center))
    }
}

// MARK: - View Extensions for RTL Support

extension View {
    
    /// Apply RTL-aware layout direction
    func rtlAware() -> some View {
        self.modifier(RTLAwareModifier())
    }
    
    /// Apply RTL-aware padding
    func rtlPadding(leading: CGFloat? = nil, trailing: CGFloat? = nil, top: CGFloat? = nil, bottom: CGFloat? = nil) -> some View {
        self.modifier(RTLAwarePaddingModifier(leading: leading, trailing: trailing, top: top, bottom: bottom))
    }
    
    /// Apply RTL-aware horizontal alignment
    func rtlAlignment(_ alignment: HorizontalAlignment) -> some View {
        self.modifier(RTLAwareAlignmentModifier(alignment: alignment))
    }
    
    /// Apply RTL-aware text alignment
    func rtlTextAlignment() -> some View {
        self.multilineTextAlignment(RTLSupport.textAlignment)
    }
    
    /// Apply RTL-aware horizontal flip
    func rtlFlipped() -> some View {
        self.scaleEffect(x: LocalizationManager.shared.isRightToLeft ? -1 : 1, y: 1)
    }
    
    /// Apply RTL-aware rotation
    func rtlRotation(_ degrees: Double) -> some View {
        self.rotationEffect(.degrees(RTLSupport.rotationAngle(for: degrees)))
    }
    
    /// Apply RTL-aware horizontal offset
    func rtlOffset(x: CGFloat, y: CGFloat = 0) -> some View {
        self.offset(x: RTLSupport.horizontalOffset(x), y: y)
    }
}

// MARK: - RTL-Aware Components

struct RTLAwareHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content
    
    init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if LocalizationManager.shared.isRightToLeft {
            HStack(alignment: alignment, spacing: spacing) {
                content()
            }
            .environment(\.layoutDirection, .rightToLeft)
        } else {
            HStack(alignment: alignment, spacing: spacing) {
                content()
            }
        }
    }
}

struct RTLAwareNavigationLink<Label: View, Destination: View>: View {
    let destination: Destination
    let label: () -> Label
    
    init(destination: Destination, @ViewBuilder label: @escaping () -> Label) {
        self.destination = destination
        self.label = label
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                label()
                Spacer()
                Image(systemName: RTLSupport.chevronForward)
                    .foregroundColor(.gray400)
                    .font(.caption)
            }
        }
    }
}

struct RTLAwareBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: RTLSupport.chevronBack)
                    .font(.body)
                    .foregroundColor(.emerald)
                
                Text(LocalizationKeys.Common.back.localized)
                    .font(.bodyMedium)
                    .foregroundColor(.emerald)
            }
        }
        .accessibilityLabel(LocalizationKeys.Common.back.localized)
        .accessibilityHint("Navigate back to previous screen")
    }
}