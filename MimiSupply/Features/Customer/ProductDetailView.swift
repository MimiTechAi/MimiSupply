//
//  ProductDetailView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Detailed view for a specific product with add to cart functionality
struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Int = 1
    @State private var specialInstructions: String = ""
    
    init(product: Product) {
        self.product = product
        self._viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                heroImageSection
                
                // Product Info
                VStack(alignment: .leading, spacing: 24) {
                    productHeaderSection
                    productDescriptionSection
                    if let nutrition = product.nutritionInfo {
                        nutritionInfoSection(nutrition)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            addToCartSection
        }
        .alert("Added to Cart", isPresented: $viewModel.showingSuccessMessage) {
            Button("Continue Shopping") {
                dismiss()
            }
        } message: {
            Text("\(product.name) has been added to your cart")
        }
        .overlay(
            Group {
                if viewModel.isAddingToCart {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView("Adding to cart...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        )
    }
    
    private var heroImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Product image
            if let imageURL = product.imageURLs.first {
                CachedAsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray100)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray400)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray100)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray400)
                    )
            }
        }
        .frame(height: 300)
        .clipped()
    }
    
    private var productHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.headlineLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.graphite)
                    
                    Text(product.category.displayName)
                        .font(.bodyMedium)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.formattedPrice)
                        .font(.titleLarge)
                        .fontWeight(.bold)
                        .foregroundColor(.emerald)
                    
                    if let originalPrice = product.originalPriceCents,
                       originalPrice > product.priceCents {
                        Text(String(format: "$%.2f", Double(originalPrice) / 100))
                            .font(.bodySmall)
                            .foregroundColor(.gray500)
                            .strikethrough()
                    }
                }
            }
            
            // Availability status
            HStack(spacing: 8) {
                Circle()
                    .fill(product.isAvailable ? Color.success : Color.error)
                    .frame(width: 8, height: 8)
                
                Text(product.isAvailable ? "Available" : "Out of Stock")
                    .font(.bodyMedium)
                    .foregroundColor(product.isAvailable ? .success : .error)
                    .fontWeight(.medium)
            }
        }
    }
    
    private var productDescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
            
            Text(product.description)
                .font(.bodyMedium)
                .foregroundColor(.gray700)
                .lineSpacing(4)
            
            // Allergens
            if !product.allergens.isEmpty {
                Text("Allergens")
                    .font(.titleSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(.graphite)
                    .padding(.top, 8)
                
                HStack {
                    ForEach(product.allergens, id: \.self) { allergen in
                        Text(allergen.displayName)
                            .font(.bodySmall)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.warning.opacity(0.1))
                            .foregroundColor(.warning)
                            .cornerRadius(4)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func nutritionInfoSection(_ nutrition: NutritionInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Information")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                if let calories = nutrition.calories {
                    NutritionItem(label: "Calories", value: "\(calories)")
                }
                if let protein = nutrition.protein {
                    NutritionItem(label: "Protein", value: "\(String(format: "%.1f", protein))g")
                }
                if let carbs = nutrition.carbohydrates {
                    NutritionItem(label: "Carbs", value: "\(String(format: "%.1f", carbs))g")
                }
                if let fat = nutrition.fat {
                    NutritionItem(label: "Fat", value: "\(String(format: "%.1f", fat))g")
                }
            }
        }
    }
    
    private var addToCartSection: some View {
        VStack(spacing: 16) {
            // Quantity selector
            HStack {
                Text("Quantity")
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        if quantity > 1 {
                            quantity -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(quantity > 1 ? .emerald : .gray400)
                    }
                    .disabled(quantity <= 1)
                    
                    Text("\(quantity)")
                        .font(.titleMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.graphite)
                        .frame(width: 30)
                    
                    Button(action: {
                        quantity += 1
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.emerald)
                    }
                }
            }
            
            // Special instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Special Instructions (Optional)")
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                
                TextField("Add any special requests...", text: $specialInstructions, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(2...4)
            }
            
            // Add to cart button
            PrimaryButton(
                title: "Add to Cart • \(totalPriceFormatted)",
                action: {
                    Task {
                        await viewModel.addToCart(
                            quantity: quantity,
                            specialInstructions: specialInstructions.isEmpty ? nil : specialInstructions
                        )
                    }
                },
                isLoading: viewModel.isAddingToCart,
                isDisabled: !product.isAvailable
            )
        }
        .padding(24)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
        )
    }
    
    private var totalPriceFormatted: String {
        let totalCents = product.priceCents * quantity
        return String(format: "$%.2f", Double(totalCents) / 100.0)
    }
}

// MARK: - Supporting Views

struct NutritionItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.gray600)
            
            Text(value)
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.graphite)
        }
        .padding(12)
        .background(Color.gray50)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        ProductDetailView(product: Product.mockProducts[0])
    }
}