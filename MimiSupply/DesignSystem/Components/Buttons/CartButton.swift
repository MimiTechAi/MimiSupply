//
//  CartButton.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Cart button with item count badge
struct CartButton: View {
    let itemCount: Int
    let onTap: () -> Void
    
    init(itemCount: Int, onTap: @escaping () -> Void) {
        self.itemCount = itemCount
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "cart")
                    .font(.title2)
                    .foregroundColor(.graphite)
                
                if itemCount > 0 {
                    NotificationBadge(count: itemCount)
                        .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel("Shopping cart")
        .accessibilityValue(itemCount > 0 ? "\(itemCount) items" : "Empty")
    }
}

/// Floating cart button for main screens
struct FloatingCartButton: View {
    let itemCount: Int
    let action: () -> Void
    
    init(itemCount: Int, action: @escaping () -> Void) {
        self.itemCount = itemCount
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.emerald)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if itemCount > 0 {
                        NotificationBadge(count: itemCount)
                            .offset(x: 8, y: -8)
                    }
                }
            }
        }
        .accessibilityLabel("Shopping cart")
        .accessibilityValue(itemCount > 0 ? "\(itemCount) items" : "Empty")
    }
}

#Preview {
    VStack(spacing: Spacing.xl) {
        HStack(spacing: Spacing.lg) {
            CartButton(itemCount: 0, onTap: { })
            CartButton(itemCount: 3, onTap: { })
            CartButton(itemCount: 99, onTap: { })
            CartButton(itemCount: 127, onTap: { })
        }
        
        HStack(spacing: Spacing.lg) {
            FloatingCartButton(itemCount: 0) { }
            FloatingCartButton(itemCount: 5) { }
            FloatingCartButton(itemCount: 99) { }
        }
    }
    .padding()
}
