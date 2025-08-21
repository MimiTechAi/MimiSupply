import SwiftUI

struct GlassyLoadingView: View {
    @State private var phase = 0.0

    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(radius: 6)
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.emerald, .blue, .orange, .emerald]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(phase))
                        .frame(width: 54, height: 54)
                        .opacity(0.85)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: phase)

                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 40, height: 40)
                }
                .onAppear { withAnimation { phase = 360 } }

                Text("Premium wird geladen ...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            }
            .padding(28)
        }
        .frame(width: 180, height: 160)
    }
}