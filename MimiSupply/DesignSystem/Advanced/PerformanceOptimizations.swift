//
//  PerformanceOptimizations.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

// MARK: - Advanced Performance Optimizations

/// Lazy loading container that only renders visible content
struct LazyContainer<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    
    @State private var isVisible = false
    
    init(threshold: CGFloat = 100, @ViewBuilder content: () -> Content) {
        self.threshold = threshold
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isVisible {
                content
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                Color.clear
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isVisible = true
                        }
                    }
            }
        }
    }
}

/// ViewThatFits wrapper for responsive design
@available(iOS 16.0, *)
struct ResponsiveViewContainer<Content: View>: View {
    let content: Content
    let fallback: Content
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder fallback: () -> Content
    ) {
        self.content = content()
        self.fallback = fallback()
    }
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            content
            fallback
        }
    }
}

/// Memory-efficient image loader
struct OptimizedAsyncImage: View {
    let url: URL?
    let placeholder: Image?
    let maxSize: CGSize
    
    @State private var imageData: Data?
    @State private var isLoading = false
    
    init(
        url: URL?,
        placeholder: Image? = nil,
        maxSize: CGSize = CGSize(width: 300, height: 300)
    ) {
        self.url = url
        self.placeholder = placeholder
        self.maxSize = maxSize
    }
    
    var body: some View {
        Group {
            if let imageData = imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
            } else {
                placeholder?
                    .frame(maxWidth: maxSize.width, maxHeight: maxSize.height)
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url else { return }
        
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Optimize image size
                let optimizedData = await optimizeImageData(data, maxSize: maxSize)
                
                await MainActor.run {
                    self.imageData = optimizedData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func optimizeImageData(_ data: Data, maxSize: CGSize) async -> Data {
        return await Task.detached {
            guard let image = UIImage(data: data) else { return data }
            
            let targetSize = calculateOptimalSize(
                original: image.size,
                maxSize: maxSize
            )
            
            UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: targetSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage?.jpegData(compressionQuality: 0.8) ?? data
        }.value
    }
    
    private func calculateOptimalSize(original: CGSize, maxSize: CGSize) -> CGSize {
        let widthRatio = maxSize.width / original.width
        let heightRatio = maxSize.height / original.height
        let ratio = min(widthRatio, heightRatio)
        
        return CGSize(
            width: original.width * ratio,
            height: original.height * ratio
        )
    }
}

/// Efficient list with cell recycling
struct HighPerformanceList<Data: RandomAccessCollection, Content: View>: View 
where Data.Element: Identifiable, Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content
    let estimatedItemHeight: CGFloat
    
    @State private var visibleRange: Range<Data.Index>?
    @State private var containerHeight: CGFloat = 0
    
    init(
        _ data: Data,
        estimatedItemHeight: CGFloat = 50,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.estimatedItemHeight = estimatedItemHeight
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(data.enumerated()), id: \.element) { index, item in
                            content(item)
                                .id(item.id)
                                .frame(minHeight: estimatedItemHeight)
                                .onAppear {
                                    updateVisibleRange(geometry: geometry)
                                }
                        }
                    }
                }
                .onAppear {
                    containerHeight = geometry.size.height
                }
            }
        }
    }
    
    private func updateVisibleRange(geometry: GeometryProxy) {
        let visibleItems = Int(geometry.size.height / estimatedItemHeight) + 2
        let startIndex = data.startIndex
        let endIndex = data.index(startIndex, offsetBy: min(visibleItems, data.count))
        visibleRange = startIndex..<endIndex
    }
}

/// Cached computed properties for expensive calculations
@propertyWrapper
struct CachedComputed<T> {
    private var cachedValue: T?
    private var lastComputationDate: Date?
    private let cacheTimeout: TimeInterval
    private let computation: () -> T
    
    init(cacheTimeout: TimeInterval = 60, _ computation: @escaping () -> T) {
        self.cacheTimeout = cacheTimeout
        self.computation = computation
    }
    
    var wrappedValue: T {
        mutating get {
            let now = Date()
            
            if let lastDate = lastComputationDate,
               let cached = cachedValue,
               now.timeIntervalSince(lastDate) < cacheTimeout {
                return cached
            }
            
            let newValue = computation()
            cachedValue = newValue
            lastComputationDate = now
            return newValue
        }
    }
    
    mutating func invalidate() {
        cachedValue = nil
        lastComputationDate = nil
    }
}

/// Debounced property wrapper for expensive operations
@propertyWrapper
struct Debounced<T: Equatable> {
    private var timer: Timer?
    private var pendingValue: T
    private let delay: TimeInterval
    private let action: (T) -> Void
    
    init(wrappedValue: T, delay: TimeInterval = 0.5, action: @escaping (T) -> Void) {
        self.pendingValue = wrappedValue
        self.delay = delay
        self.action = action
    }
    
    var wrappedValue: T {
        get { pendingValue }
        set {
            pendingValue = newValue
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                action(newValue)
            }
        }
    }
}

/// Batch update manager for reducing UI updates
@MainActor
final class BatchUpdateManager: ObservableObject {
    @Published private(set) var pendingUpdates: [String: Any] = [:]
    
    private var batchTimer: Timer?
    private let batchDelay: TimeInterval = 0.1
    
    func scheduleUpdate<T>(key: String, value: T) {
        pendingUpdates[key] = value
        
        batchTimer?.invalidate()
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchDelay, repeats: false) { _ in
            self.commitBatchUpdates()
        }
    }
    
    private func commitBatchUpdates() {
        // Commit all pending updates at once
        let updates = pendingUpdates
        pendingUpdates.removeAll()
        
        // Notify observers of batch update
        NotificationCenter.default.post(
            name: Notification.Name("BatchUpdateCommitted"),
            object: updates
        )
    }
}

/// Smart view recycling for large datasets
struct RecyclableView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    let recycleThreshold: Int
    
    @State private var visibleItems: Set<Item.ID> = []
    @State private var recycledViews: [Item.ID: AnyView] = [:]
    
    init(
        items: [Item],
        recycleThreshold: Int = 50,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.recycleThreshold = recycleThreshold
        self.content = content
    }
    
    var body: some View {
        LazyVStack {
            ForEach(items) { item in
                if visibleItems.contains(item.id) {
                    if let recycledView = recycledViews[item.id] {
                        recycledView
                    } else {
                        AnyView(content(item))
                            .onAppear {
                                cacheView(item: item)
                            }
                    }
                } else {
                    Color.clear
                        .frame(height: 50) // Placeholder height
                        .onAppear {
                            visibleItems.insert(item.id)
                        }
                        .onDisappear {
                            if visibleItems.count > recycleThreshold {
                                visibleItems.remove(item.id)
                            }
                        }
                }
            }
        }
    }
    
    private func cacheView(item: Item) {
        if recycledViews.count < recycleThreshold {
            recycledViews[item.id] = AnyView(content(item))
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add lazy loading with threshold
    func lazyLoad(threshold: CGFloat = 100) -> some View {
        LazyContainer(threshold: threshold) {
            self
        }
    }
    
    /// Optimize for large lists
    func optimizedForLargeLists() -> some View {
        self
            .drawingGroup() // Flatten into single layer
            .clipped() // Prevent overdraw
    }
    
    /// Batch updates for multiple changes
    func batchUpdates<T: Equatable>(_ value: T, key: String) -> some View {
        self.onChange(of: value) { _, newValue in
            BatchUpdateManager().scheduleUpdate(key: key, value: newValue)
        }
    }
}

// MARK: - Preview

struct PerformanceOptimizations_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<100) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.emerald.opacity(0.1))
                        .frame(height: 60)
                        .overlay(
                            Text("Item \(index)")
                        )
                        .lazyLoad()
                }
            }
            .padding()
        }
    }
}