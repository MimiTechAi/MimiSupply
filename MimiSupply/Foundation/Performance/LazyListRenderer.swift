import SwiftUI
import Combine

/// High-performance lazy list renderer with efficient scrolling and memory management
struct LazyListRenderer<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    private let content: (Data.Element) -> Content
    private let itemHeight: CGFloat?
    private let prefetchDistance: Int
    
    @State private var visibleRange: Range<Int> = 0..<0
    @State private var scrollOffset: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    
    init(
        data: Data,
        itemHeight: CGFloat? = nil,
        prefetchDistance: Int = 5,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.itemHeight = itemHeight
        self.prefetchDistance = prefetchDistance
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                            if shouldRenderItem(at: index) {
                                content(item)
                                    .id(item.id)
                                    .onAppear {
                                        updateVisibleRange(for: index)
                                    }
                            } else {
                                // Placeholder for non-visible items
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: estimatedItemHeight)
                                    .id(item.id)
                            }
                        }
                    }
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeometry.frame(in: .named("scroll")).minY
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = -value
                    updateVisibleRange()
                }
                .onAppear {
                    containerHeight = geometry.size.height
                    updateVisibleRange()
                }
            }
        }
    }
    
    private var estimatedItemHeight: CGFloat {
        itemHeight ?? 80 // Default estimated height
    }
    
    private func shouldRenderItem(at index: Int) -> Bool {
        let extendedRange = max(0, visibleRange.lowerBound - prefetchDistance)..<min(data.count, visibleRange.upperBound + prefetchDistance)
        return extendedRange.contains(index)
    }
    
    private func updateVisibleRange(for index: Int? = nil) {
        let itemHeight = estimatedItemHeight
        let startIndex = max(0, Int(scrollOffset / itemHeight))
        let visibleCount = Int(ceil(containerHeight / itemHeight)) + 1
        let endIndex = min(data.count, startIndex + visibleCount)
        
        visibleRange = startIndex..<endIndex
    }
}

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Optimized List View
struct OptimizedListView<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    private let data: Data
    private let content: (Data.Element) -> Content
    private let onRefresh: (() async -> Void)?
    private let onLoadMore: (() async -> Void)?
    
    @State private var isRefreshing = false
    @State private var isLoadingMore = false
    
    init(
        data: Data,
        onRefresh: (() async -> Void)? = nil,
        onLoadMore: (() async -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.onRefresh = onRefresh
        self.onLoadMore = onLoadMore
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .onAppear {
                            if index == data.count - 3 && !isLoadingMore {
                                loadMore()
                            }
                        }
                }
                
                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding(.horizontal, 16)
        }
        .refreshable {
            if let onRefresh = onRefresh {
                await onRefresh()
            }
        }
    }
    
    private func loadMore() {
        guard let onLoadMore = onLoadMore, !isLoadingMore else { return }
        
        isLoadingMore = true
        Task {
            await onLoadMore()
            await MainActor.run {
                isLoadingMore = false
            }
        }
    }
}

// MARK: - Performance Monitoring
class ListPerformanceMonitor: ObservableObject {
    @Published var scrollFPS: Double = 0
    @Published var memoryUsage: Double = 0
    
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastTimestamp: CFTimeInterval = 0
    
    func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateFPS(displayLink: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
            return
        }
        
        frameCount += 1
        let elapsed = displayLink.timestamp - lastTimestamp
        
        if elapsed >= 1.0 {
            scrollFPS = Double(frameCount) / elapsed
            frameCount = 0
            lastTimestamp = displayLink.timestamp
            
            updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            memoryUsage = Double(info.resident_size) / (1024 * 1024) // MB
        }
    }
}