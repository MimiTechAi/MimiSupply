//
//  LoadingView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Reusable loading view component with different sizes and styles
struct AppLoadingView: View {
    let message: String?
    let size: LoadingSize
    let style: LoadingStyle
    
    enum LoadingSize {
        case small, medium, large
        
        var progressViewScale: CGFloat {
            switch self {
            case .small: return 0.8
            case .medium: return 1.0
            case .large: return 1.5
            }
        }
        
        var messageFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .bodyMedium
            case .large: return .titleMedium
            }
        }
    }
    
    enum LoadingStyle {
        case circular, dots
    }
    
    init(
        message: String? = nil,
        size: LoadingSize = .medium,
        style: LoadingStyle = .circular
    ) {
        self.message = message
        self.size = size
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            switch style {
            case .circular:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .emerald))
                    .scaleEffect(size.progressViewScale)
            case .dots:
                DotsLoadingView()
            }
            
            if let message = message {
                Text(message)
                    .font(size.messageFont)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Loading")
    }
}

struct DotsLoadingView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.emerald)
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = 1
        }
    }
    
    private func scale(for index: Int) -> CGFloat {
        let phase = (animationOffset + Double(index) * 0.2).truncatingRemainder(dividingBy: 1.0)
        return 1.0 + 0.5 * sin(phase * 2 * .pi)
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        AppLoadingView(message: "Loading...", size: .small)
        AppLoadingView(message: "Please wait", size: .medium)
        AppLoadingView(message: "Loading content", size: .large)
        AppLoadingView(message: "Loading with dots", style: .dots)
        AppLoadingView() // No message
    }
    .padding()
}