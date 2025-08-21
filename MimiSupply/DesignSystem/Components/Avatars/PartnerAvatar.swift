import SwiftUI

struct PartnerAvatar: View {
    let url: URL?
    let fallbackSymbol: String

    var body: some View {
        if let url {
            AsyncImage(url: url) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 34, height: 34)
            .clipShape(Circle())
            .background(Circle().fill(Color.white.opacity(0.45)))
            .shadow(radius: 2)
        } else {
            Image(systemName: fallbackSymbol)
                .resizable()
                .foregroundColor(.gray400)
                .background(Circle().fill(Color.white.opacity(0.45)))
                .frame(width: 34, height: 34)
        }
    }
}