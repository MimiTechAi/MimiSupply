//
//  FilterSheet.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Filter sheet for partner discovery with comprehensive filtering options
struct FilterSheet: View {
    @Binding var selectedCategory: PartnerCategory?
    @Binding var selectedSortOption: SortOption
    @Binding var priceRange: ClosedRange<Double>
    @Binding var deliveryTimeRange: ClosedRange<Int>
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var tempCategory: PartnerCategory?
    @State private var tempSortOption: SortOption
    @State private var tempPriceRange: ClosedRange<Double>
    @State private var tempDeliveryTimeRange: ClosedRange<Int>
    
    init(
        selectedCategory: Binding<PartnerCategory?>,
        selectedSortOption: Binding<SortOption>,
        priceRange: Binding<ClosedRange<Double>>,
        deliveryTimeRange: Binding<ClosedRange<Int>>,
        onApply: @escaping () -> Void
    ) {
        self._selectedCategory = selectedCategory
        self._selectedSortOption = selectedSortOption
        self._priceRange = priceRange
        self._deliveryTimeRange = deliveryTimeRange
        self.onApply = onApply
        
        // Initialize temp values
        self._tempCategory = State(initialValue: selectedCategory.wrappedValue)
        self._tempSortOption = State(initialValue: selectedSortOption.wrappedValue)
        self._tempPriceRange = State(initialValue: priceRange.wrappedValue)
        self._tempDeliveryTimeRange = State(initialValue: deliveryTimeRange.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Category Filter
                    categorySection
                    
                    AppDivider()
                    
                    // Sort Options
                    sortSection
                    
                    AppDivider()
                    
                    // Price Range
                    priceRangeSection
                    
                    AppDivider()
                    
                    // Delivery Time Range
                    deliveryTimeSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                    .foregroundColor(.emerald)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applyFilters()
                    }
                    .foregroundColor(.emerald)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Sections
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Category")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Spacing.md) {
                ForEach(PartnerCategory.allCases, id: \.self) { category in
                    CategoryFilterCard(
                        category: category,
                        isSelected: tempCategory == category
                    ) {
                        if tempCategory == category {
                            tempCategory = nil
                        } else {
                            tempCategory = category
                        }
                    }
                }
            }
        }
    }
    
    private var sortSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sort By")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            VStack(spacing: Spacing.xs) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    SortOptionRow(
                        option: option,
                        isSelected: tempSortOption == option
                    ) {
                        tempSortOption = option
                    }
                }
            }
        }
    }
    
    private var priceRangeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Minimum Order Amount")
                    .font(.titleMedium)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                Text("$\(Int(tempPriceRange.lowerBound)) - $\(Int(tempPriceRange.upperBound))")
                    .font(.bodyMedium)
                    .foregroundColor(.emerald)
            }
            
            RangeSlider(
                range: $tempPriceRange,
                bounds: 0...100,
                step: 5
            )
        }
    }
    
    private var deliveryTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Delivery Time")
                    .font(.titleMedium)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                Text("\(tempDeliveryTimeRange.lowerBound) - \(tempDeliveryTimeRange.upperBound) min")
                    .font(.bodyMedium)
                    .foregroundColor(.emerald)
            }
            
            RangeSlider(
                range: Binding(
                    get: { Double(tempDeliveryTimeRange.lowerBound)...Double(tempDeliveryTimeRange.upperBound) },
                    set: { tempDeliveryTimeRange = Int($0.lowerBound)...Int($0.upperBound) }
                ),
                bounds: 0...120,
                step: 5
            )
        }
    }
    
    // MARK: - Actions
    
    private func resetFilters() {
        tempCategory = nil
        tempSortOption = .relevance
        tempPriceRange = 0...100
        tempDeliveryTimeRange = 0...60
    }
    
    private func applyFilters() {
        selectedCategory = tempCategory
        selectedSortOption = tempSortOption
        priceRange = tempPriceRange
        deliveryTimeRange = tempDeliveryTimeRange
        onApply()
        dismiss()
    }
}

// MARK: - Supporting Views

struct CategoryFilterCard: View {
    let category: PartnerCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .emerald)
                
                Text(category.displayName)
                    .font(.labelSmall)
                    .foregroundColor(isSelected ? .white : .graphite)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.emerald : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.emerald : Color.gray300, lineWidth: 1)
            )
        }
        .accessibilityLabel(category.displayName)
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select this category")
    }
}

struct SortOptionRow: View {
    let option: SortOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option.displayName)
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.emerald)
                        .font(.bodyMedium)
                }
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.md)
            .background(isSelected ? Color.emerald.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .accessibilityLabel(option.displayName)
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to sort by \(option.displayName)")
    }
}

struct RangeSlider: View {
    @Binding var range: ClosedRange<Double>
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Custom range slider implementation
            GeometryReader { geometry in
                let width = geometry.size.width
                let lowerPercent = (range.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
                let upperPercent = (range.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound)
                
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(Color.gray300)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Active range
                    Rectangle()
                        .fill(Color.emerald)
                        .frame(width: width * (upperPercent - lowerPercent), height: 4)
                        .offset(x: width * lowerPercent)
                        .cornerRadius(2)
                    
                    // Lower thumb
                    Circle()
                        .fill(Color.emerald)
                        .frame(width: 20, height: 20)
                        .offset(x: width * lowerPercent - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = bounds.lowerBound + (value.location.x / width) * (bounds.upperBound - bounds.lowerBound)
                                    let clampedValue = max(bounds.lowerBound, min(range.upperBound - step, newValue))
                                    let steppedValue = round(clampedValue / step) * step
                                    range = steppedValue...range.upperBound
                                }
                        )
                    
                    // Upper thumb
                    Circle()
                        .fill(Color.emerald)
                        .frame(width: 20, height: 20)
                        .offset(x: width * upperPercent - 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = bounds.lowerBound + (value.location.x / width) * (bounds.upperBound - bounds.lowerBound)
                                    let clampedValue = max(range.lowerBound + step, min(bounds.upperBound, newValue))
                                    let steppedValue = round(clampedValue / step) * step
                                    range = range.lowerBound...steppedValue
                                }
                        )
                }
            }
            .frame(height: 20)
            
            // Range labels
            HStack {
                Text("\(Int(bounds.lowerBound))")
                    .font(.caption)
                    .foregroundColor(.gray500)
                
                Spacer()
                
                Text("\(Int(bounds.upperBound))")
                    .font(.caption)
                    .foregroundColor(.gray500)
            }
        }
    }
}

#Preview {
    FilterSheet(
        selectedCategory: .constant(.restaurant),
        selectedSortOption: .constant(.relevance),
        priceRange: .constant(0...50),
        deliveryTimeRange: .constant(0...30),
        onApply: {}
    )
}