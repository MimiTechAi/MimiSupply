import SwiftUI

/// Lädt zuerst ein Asset (wenn angegeben), ansonsten eine URL, mit optionalem Placeholder.
struct HybridImageView: View {
    let assetName: String?
    let url: URL?
    let contentMode: ContentMode
    let fallbackSystemName: String
    
    init(assetName: String?, url: URL?, contentMode: ContentMode = .fill, fallbackSystemName: String = "photo") {
        self.assetName = assetName
        self.url = url
        self.contentMode = contentMode
        self.fallbackSystemName = fallbackSystemName
    }
    
    var body: some View {
        if let assetName, let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .empty:
                    ProgressView()
                case .failure(_):
                    Image(systemName: fallbackSystemName)
                        .resizable()
                        .foregroundColor(.gray)
                        .aspectRatio(contentMode: contentMode)
                @unknown default:
                    Image(systemName: fallbackSystemName)
                        .resizable()
                        .foregroundColor(.gray)
                        .aspectRatio(contentMode: contentMode)
                }
            }
        } else {
            Image(systemName: fallbackSystemName)
                .resizable()
                .foregroundColor(.gray)
                .aspectRatio(contentMode: contentMode)
        }
    }
}