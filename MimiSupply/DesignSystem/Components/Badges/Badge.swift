//
//  Badge.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Badge component for status indicators and counts
struct Badge: View {
    let text: String
    let style: BadgeStyle
    let size: BadgeSize
    
    enum BadgeStyle {
        case primary
        case success
        case warning
        case error
        case info
        case neutral
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .emerald
            case .success: return .success
            case .warning: return .warning
            case .error: return .error
            case .info: return .info
            case .neutral: return .gray500
            }
        }
        
        var textColor: Color {
            return .white
        }
    }
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var font: Font {
            switch self {
            case .small: return .labelSmall
            case .medium: return .labelMedium
            case .large: return .labelLarge
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }
    
    init(text: String, style: BadgeStyle = .primary, size: BadgeSize = .medium) {
        self.text = text
        self.style = style
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(style.textColor)
            .padding(size.padding)
            .background(style.backgroundColor)
            .cornerRadius(size.cornerRadius)
            .accessibilityLabel("Badge: \(text)")
    }
}

/// Notification badge for showing counts
struct NotificationBadge: View {
    let count: Int
    let maxCount: Int
    
    init(count: Int, maxCount: Int = 99) {
        self.count = count
        self.maxCount = maxCount
    }
    
    var body: some View {
        if count > 0 {
            Text(displayText)
                .font(.labelSmall)
                .foregroundColor(.white)
                .padding(.horizontal, count > 9 ? 6 : 0)
                .frame(minWidth: 18, minHeight: 18)
                .background(Color.error)
                .clipShape(Circle())
                .accessibilityLabel("\(count) notifications")
        }
    }
    
    private var displayText: String {
        if count > maxCount {
            return "\(maxCount)+"
        } else {
            return "\(count)"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        HStack(spacing: Spacing.md) {
            Badge(text: "New", style: .primary, size: .small)
            Badge(text: "Available", style: .success, size: .medium)
            Badge(text: "Urgent", style: .error, size: .large)
        }
        
        HStack(spacing: Spacing.md) {
            Badge(text: "Info", style: .info)
            Badge(text: "Warning", style: .warning)
            Badge(text: "Neutral", style: .neutral)
        }
        
        HStack(spacing: Spacing.lg) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell")
                    .font(.title2)
                    .foregroundColor(.graphite)
                NotificationBadge(count: 3)
                    .offset(x: 8, y: -8)
            }
            
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                    .font(.title2)
                    .foregroundColor(.graphite)
                NotificationBadge(count: 127)
                    .offset(x: 8, y: -8)
            }
        }
    }
    .padding()
}