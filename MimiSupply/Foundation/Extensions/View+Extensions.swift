import SwiftUI

/// A view modifier that applies the premium gradient background.
struct PremiumBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Premium gradient background that covers the entire safe area
            LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.78, blue: 0.47),
                    Color(red: 0.25, green: 0.85, blue: 0.55),
                    Color(red: 0.35, green: 0.75, blue: 0.65)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            content
        }
    }
}

extension View {
    /// Applies the premium gradient background to the view.
    func premiumBackground() -> some View {
        self.modifier(PremiumBackground())
    }
}