import SwiftUI

struct PremiumBadge: View {
    let text: String
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "crown.fill")
                .foregroundColor(.yellow)
            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.emerald)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(BlurView(style: .systemUltraThinMaterialLight))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(Color.emerald, lineWidth: 1)
        )
        .shadow(radius: 2)
    }
}