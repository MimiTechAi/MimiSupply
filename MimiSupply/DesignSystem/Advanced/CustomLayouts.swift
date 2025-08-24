//
//  CustomLayouts.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

// MARK: - Flow Layout

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return calculateSize(sizes: sizes, in: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var currentPosition = CGPoint(x: bounds.minX, y: bounds.minY)
        var rowHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            // Check if we need to wrap to the next row
            if currentRowWidth + size.width > bounds.width && currentRowWidth > 0 {
                // Move to next row
                currentPosition.x = bounds.minX
                currentPosition.y += rowHeight + spacing
                currentRowWidth = 0
                rowHeight = 0
            }
            
            // Place the subview
            let position = CGPoint(
                x: currentPosition.x + size.width / 2,
                y: currentPosition.y + size.height / 2
            )
            
            subview.place(at: position, anchor: .center, proposal: .unspecified)
            
            // Update position for next item
            currentPosition.x += size.width + spacing
            currentRowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
    
    private func calculateSize(sizes: [CGSize], in proposal: ProposedViewSize) -> CGSize {
        guard !sizes.isEmpty else { return .zero }
        
        let maxWidth = proposal.width ?? .infinity
        var totalHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var maxRowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for size in sizes {
            if currentRowWidth + size.width > maxWidth && currentRowWidth > 0 {
                // End current row
                totalHeight += rowHeight + spacing
                maxRowWidth = max(maxRowWidth, currentRowWidth - spacing)
                currentRowWidth = 0
                rowHeight = 0
            }
            
            currentRowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        // Add the last row
        totalHeight += rowHeight
        maxRowWidth = max(maxRowWidth, currentRowWidth - spacing)
        
        return CGSize(width: maxRowWidth, height: totalHeight)
    }
}

// MARK: - Masonry Layout

@available(iOS 16.0, *)
struct MasonryLayout: Layout {
    let columns: Int
    let spacing: CGFloat
    
    init(columns: Int = 2, spacing: CGFloat = 8) {
        self.columns = columns
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let columnWidth = columnWidth(for: proposal)
        let columnHeights = calculateColumnHeights(subviews: subviews, columnWidth: columnWidth)
        
        let totalWidth = proposal.width ?? columnWidth * CGFloat(columns) + spacing * CGFloat(columns - 1)
        let totalHeight = columnHeights.max() ?? 0
        
        return CGSize(width: totalWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = columnWidth(for: proposal)
        var columnHeights = Array(repeating: bounds.minY, count: columns)
        
        for subview in subviews {
            let shortestColumnIndex = columnHeights.enumerated().min { $0.element < $1.element }?.offset ?? 0
            
            let x = bounds.minX + CGFloat(shortestColumnIndex) * (columnWidth + spacing) + columnWidth / 2
            let y = columnHeights[shortestColumnIndex]
            
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            
            subview.place(
                at: CGPoint(x: x, y: y + size.height / 2),
                anchor: .center,
                proposal: ProposedViewSize(width: columnWidth, height: nil)
            )
            
            columnHeights[shortestColumnIndex] += size.height + spacing
        }
    }
    
    private func columnWidth(for proposal: ProposedViewSize) -> CGFloat {
        let totalWidth = proposal.width ?? 300
        let totalSpacing = spacing * CGFloat(columns - 1)
        return (totalWidth - totalSpacing) / CGFloat(columns)
    }
    
    private func calculateColumnHeights(subviews: Subviews, columnWidth: CGFloat) -> [CGFloat] {
        var columnHeights = Array(repeating: CGFloat.zero, count: columns)
        
        for subview in subviews {
            let shortestColumnIndex = columnHeights.enumerated().min { $0.element < $1.element }?.offset ?? 0
            let size = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            columnHeights[shortestColumnIndex] += size.height + spacing
        }
        
        return columnHeights
    }
}

// MARK: - Adaptive Layout

@available(iOS 16.0, *)
struct AdaptiveLayout: Layout {
    let minItemWidth: CGFloat
    let spacing: CGFloat
    let maxColumns: Int
    
    init(minItemWidth: CGFloat = 150, spacing: CGFloat = 16, maxColumns: Int = 4) {
        self.minItemWidth = minItemWidth
        self.spacing = spacing
        self.maxColumns = maxColumns
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout AdaptiveCache) -> CGSize {
        let cache = updateCache(proposal: proposal, subviews: subviews, cache: &cache)
        
        let totalHeight = cache.rows.reduce(0) { result, row in
            result + row.height
        } + spacing * CGFloat(max(0, cache.rows.count - 1))
        
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout AdaptiveCache) {
        let cache = updateCache(proposal: proposal, subviews: subviews, cache: &cache)
        
        var currentY = bounds.minY
        
        for row in cache.rows {
            var currentX = bounds.minX
            
            for (index, size) in row.items {
                let subview = subviews[index]
                
                subview.place(
                    at: CGPoint(x: currentX + size.width / 2, y: currentY + size.height / 2),
                    anchor: .center,
                    proposal: ProposedViewSize(size)
                )
                
                currentX += size.width + spacing
            }
            
            currentY += row.height + spacing
        }
    }
    
    func makeCache(subviews: Subviews) -> AdaptiveCache {
        return AdaptiveCache()
    }
    
    private func updateCache(proposal: ProposedViewSize, subviews: Subviews, cache: inout AdaptiveCache) -> AdaptiveCache {
        let containerWidth = proposal.width ?? 0
        let columns = min(maxColumns, max(1, Int(containerWidth / (minItemWidth + spacing))))
        let itemWidth = (containerWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        
        if cache.containerWidth == containerWidth && cache.columns == columns {
            return cache
        }
        
        var rows: [AdaptiveRow] = []
        var currentRow: [(Int, CGSize)] = []
        var currentRowHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil))
            
            currentRow.append((index, size))
            currentRowHeight = max(currentRowHeight, size.height)
            
            if currentRow.count == columns || index == subviews.count - 1 {
                rows.append(AdaptiveRow(items: currentRow, height: currentRowHeight))
                currentRow = []
                currentRowHeight = 0
            }
        }
        
        cache = AdaptiveCache(
            containerWidth: containerWidth,
            columns: columns,
            rows: rows
        )
        
        return cache
    }
}

struct AdaptiveCache {
    var containerWidth: CGFloat = 0
    var columns: Int = 0
    var rows: [AdaptiveRow] = []
}

struct AdaptiveRow {
    let items: [(Int, CGSize)]
    let height: CGFloat
}

// MARK: - Layout Extensions and Helpers

extension View {
    /// Apply flow layout (iOS 16+)
    @available(iOS 16.0, *)
    func flowLayout(spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading) -> some View {
        FlowLayout(spacing: spacing, alignment: alignment) {
            self
        }
    }
    
    /// Apply masonry layout (iOS 16+)
    @available(iOS 16.0, *)
    func masonryLayout(columns: Int = 2, spacing: CGFloat = 8) -> some View {
        MasonryLayout(columns: columns, spacing: spacing) {
            self
        }
    }
    
    /// Apply adaptive layout (iOS 16+)
    @available(iOS 16.0, *)
    func adaptiveLayout(
        minItemWidth: CGFloat = 150,
        spacing: CGFloat = 16,
        maxColumns: Int = 4
    ) -> some View {
        AdaptiveLayout(
            minItemWidth: minItemWidth,
            spacing: spacing,
            maxColumns: maxColumns
        ) {
            self
        }
    }
    
    /// Fallback for iOS 15 and below
    func responsiveGrid<Content: View>(
        columns: Int = 2,
        spacing: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing,
            content: content
        )
    }
}

// MARK: - Preview

struct CustomLayouts_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                if #available(iOS 16.0, *) {
                    FlowLayout(spacing: 8) {
                        ForEach(0..<10) { index in
                            Text("Item \(index)")
                                .padding()
                                .background(Color.emerald.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    
                    MasonryLayout(columns: 2, spacing: 16) {
                        ForEach(0..<6) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.emerald.opacity(0.6))
                                .frame(height: CGFloat.random(in: 100...200))
                                .overlay(
                                    Text("\(index)")
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding()
                }
            }
        }
    }
}