//
//  SkeletonView.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

/// Enhanced skeleton loading view with accessibility and animations
struct EnhancedSkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    let animationDuration: Double
    
    @State private var isAnimating = false
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(
        width: CGFloat? = nil,
        height: CGFloat = 20,
        cornerRadius: CGFloat = 4,
        animationDuration: Double = 1.5
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray200,
                        Color.gray300,
                        Color.gray200
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.6 : 1.0)
            .animation(
                accessibilityManager.isReduceMotionEnabled ? 
                    .none : 
                    .easeInOut(duration: animationDuration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                if !accessibilityManager.isReduceMotionEnabled {
                    isAnimating = true
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Loading content")
            .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Convenience Views

struct SkeletonText: View {
    let lines: Int
    let spacing: CGFloat
    
    init(lines: Int = 3, spacing: CGFloat = Spacing.xs) {
        self.lines = lines
        self.spacing = spacing
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(0..<lines, id: \.self) { index in
                EnhancedSkeletonView(
                    width: index == lines - 1 ? 120 : nil,
                    height: 16,
                    cornerRadius: 8
                )
            }
        }
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                EnhancedSkeletonView(width: 40, height: 40, cornerRadius: 20)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    EnhancedSkeletonView(width: 120, height: 16, cornerRadius: 8)
                    EnhancedSkeletonView(width: 80, height: 12, cornerRadius: 6)
                }
                
                Spacer()
            }
            
            SkeletonText(lines: 2)
            
            HStack {
                EnhancedSkeletonView(width: 60, height: 30, cornerRadius: 15)
                Spacer()
                EnhancedSkeletonView(width: 80, height: 30, cornerRadius: 8)
            }
        }
        .padding(Spacing.lg)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        EnhancedSkeletonView()
        SkeletonText()
        SkeletonCard()
    }
    .padding()
}