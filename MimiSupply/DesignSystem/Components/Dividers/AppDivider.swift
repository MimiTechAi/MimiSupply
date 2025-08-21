//
//  AppDivider.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Reusable divider component with consistent styling
struct AppDivider: View {
    let color: Color
    let thickness: CGFloat
    
    init(
        color: Color = .gray200,
        thickness: CGFloat = 1
    ) {
        self.color = color
        self.thickness = thickness
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: thickness)
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        Text("Content above")
        AppDivider()
        Text("Content below")
        AppDivider(color: .emerald, thickness: 2)
        Text("Content with colored divider")
    }
    .padding()
}