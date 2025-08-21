import SwiftUI

struct ExclusivePartnerCard: View {
    let partner: Partner

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.75), .emerald.opacity(0.28), .blue.opacity(0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(radius: 7)
                .overlay(
                    partner.heroImageURL.map { url in
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(0.19)
                        } placeholder: { Color.clear }
                    }
                )
            VStack(alignment: .leading, spacing: 8) {
                if let logoURL = partner.logoURL {
                    AsyncImage(url: logoURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 2)
                    } placeholder: { ProgressView() }
                }

                Text(partner.name)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(partner.category.displayName)
                    .font(.caption)
                    .foregroundColor(.emerald)

                PremiumBadge(text: "Premium Partner")

                Spacer()
            }
            .padding(18)

            // Badge oben rechts
            if partner.isVerified {
                PremiumBadge(text: "Geprüft")
                    .padding()
            }
        }
        .frame(height: 168)
    }
}