import Foundation
import UIKit
import SwiftUI

/// High-performance image cache with memory and disk storage
@MainActor
class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let downloadQueue = DispatchQueue(label: "com.mimisupply.image-download", qos: .utility)
    
    init() {
        self.diskCache = DiskCache()
        configureMemoryCache()
    }
    
    private func configureMemoryCache() {
        memoryCache.countLimit = 100 // Maximum 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
    }
    
    func loadImage(from url: URL) async -> UIImage? {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await diskCache.image(for: url) {
            memoryCache.setObject(diskImage, forKey: key)
            return diskImage
        }
        
        // Download from network
        return await downloadImage(from: url)
    }
    
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }
            
            // Optimize image for display (move to background queue)
            let optimizedImage = await Task.detached {
                return self.optimizeImageOffMainActor(image)
            }.value
            
            // Cache in memory and disk on main actor
            let key = url.absoluteString as NSString
            memoryCache.setObject(optimizedImage, forKey: key)
            
            // Store in disk cache
            await diskCache.store(optimizedImage, for: url)
            
            return optimizedImage
        } catch {
            return nil
        }
    }
    
    private nonisolated func optimizeImageOffMainActor(_ image: UIImage) -> UIImage {
        // Decompress image to avoid main thread decompression
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func clearCache() async {
        memoryCache.removeAllObjects()
        await diskCache.clearAll()
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
}

// MARK: - Disk Cache
private actor DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var isDirectoryCreated = false
    
    init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
    }
    
    private func createCacheDirectoryIfNeeded() async {
        guard !isDirectoryCreated else { return }
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        isDirectoryCreated = true
    }
    
    func image(for url: URL) async -> UIImage? {
        await createCacheDirectoryIfNeeded()
        
        let filename = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    func store(_ image: UIImage, for url: URL) async {
        await createCacheDirectoryIfNeeded()
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let filename = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
    }
    
    func clearAll() async {
        try? fileManager.removeItem(at: cacheDirectory)
        isDirectoryCreated = false
        await createCacheDirectoryIfNeeded()
    }
}

// MARK: - Cached AsyncImage
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @StateObject private var imageCache = ImageCache.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        image = await imageCache.loadImage(from: url)
        isLoading = false
    }
}