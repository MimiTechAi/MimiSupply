import SwiftUI

struct FilterSheet: View {
    @Binding var selectedCategory: PartnerCategory?
    @Binding var selectedSortOption: SortOption
    @Binding var priceRange: ClosedRange<Double>
    @Binding var deliveryTimeRange: ClosedRange<Double>
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempCategory: PartnerCategory?
    @State private var tempSortOption: SortOption
    @State private var tempPriceRange: ClosedRange<Double>
    @State private var tempDeliveryTimeRange: ClosedRange<Double>
    
    init(
        selectedCategory: Binding<PartnerCategory?>,
        selectedSortOption: Binding<SortOption>,
        priceRange: Binding<ClosedRange<Double>>,
        deliveryTimeRange: Binding<ClosedRange<Double>>,
        onApply: @escaping () -> Void
    ) {
        self._selectedCategory = selectedCategory
        self._selectedSortOption = selectedSortOption
        self._priceRange = priceRange
        self._deliveryTimeRange = deliveryTimeRange
        self.onApply = onApply
        
        _tempCategory = State(initialValue: selectedCategory.wrappedValue)
        _tempSortOption = State(initialValue: selectedSortOption.wrappedValue)
        _tempPriceRange = State(initialValue: priceRange.wrappedValue)
        _tempDeliveryTimeRange = State(initialValue: deliveryTimeRange.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Category Section
                Section(header: Text("Category")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PartnerCategory.allCases) { category in
                                CategoryFilterButton(
                                    category: category,
                                    isSelected: tempCategory == category,
                                    action: {
                                        tempCategory = (tempCategory == category) ? nil : category
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                
                // Sort Section
                Section(header: Text("Sort By")) {
                    Picker("Sort by", selection: $tempSortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Price Range Section
                Section(header: Text("Price Range")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("$\(Int(tempPriceRange.lowerBound)) - $\(Int(tempPriceRange.upperBound))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Simple implementation - can be enhanced later
                        HStack {
                            Text("$0")
                            Spacer()
                            Text("$100")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                // Delivery Time Section
                Section(header: Text("Max. Delivery Time")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(Int(tempDeliveryTimeRange.upperBound)) minutes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Simple implementation - can be enhanced later
                        HStack {
                            Text("0 min")
                            Spacer()
                            Text("60 min")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        resetFilters()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                    }
                    .bold()
                }
            }
        }
    }
    
    private func applyFilters() {
        selectedCategory = tempCategory
        selectedSortOption = tempSortOption
        priceRange = tempPriceRange
        deliveryTimeRange = tempDeliveryTimeRange
        onApply()
        dismiss()
    }
    
    private func resetFilters() {
        tempCategory = nil
        tempSortOption = .recommended
        tempPriceRange = 0...100
        tempDeliveryTimeRange = 0...60
    }
}

struct CategoryFilterButton: View {
    let category: PartnerCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(category.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(minWidth: 80, minHeight: 60)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FilterSheet(
        selectedCategory: .constant(nil),
        selectedSortOption: .constant(.recommended),
        priceRange: .constant(0...100),
        deliveryTimeRange: .constant(0...60),
        onApply: {}
    )
}