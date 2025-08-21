//
//  PartnerDetailView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import MapKit

/// Partner detail view with hero images, business information, and product browsing
struct PartnerDetailView: View {
    let partner: Partner
    @StateObject private var viewModel: PartnerDetailViewModel
    @State private var showingCart = false
    
    init(partner: Partner) {
        self.partner = partner
        self._viewModel = StateObject(wrappedValue: PartnerDetailViewModel(partner: partner))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero section with partner info
                heroSection
                
                // Partner info and ratings
                partnerInfoSection
                
                // Product categories and search
                productCategoriesSection
                
                // Products list
                productsSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CartButton(itemCount: viewModel.cartItemCount) {
                    showingCart = true
                }
            }
        }
        .sheet(isPresented: $showingCart) {
            CartView()
        }
        .sheet(item: $viewModel.showingProductDetail) { product in
            ProductDetailView(product: product)
        }
        .task {
            await viewModel.loadProducts()
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let imgURL = partner.heroImageURL {
                AsyncImage(url: imgURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray200)
                }
            } else {
                Rectangle()
                    .fill(LinearGradient(colors: [Color.gray300, partner.category == .restaurant ? Color.red.opacity(0.6) : Color.green.opacity(0.5)], startPoint: .top, endPoint: .bottom))
            }
            // Glassmorphism/Blurred card bottom
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    if let logoURL = partner.logoURL {
                        HybridImageView(
                            assetName: partner.logoAssetName,
                            url: partner.logoURL,
                            contentMode: .fit
                        )
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                    }
                    Text(partner.name)
                        .font(.headlineSmall)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    if partner.isVerified {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(.success).font(.title3)
                    }
                }
                Text(partner.category.displayName)
                    .font(.bodyMedium)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(Spacing.md)
            .background(
                BlurView(style: .systemUltraThinMaterialDark)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .opacity(0.76)
            )
            .padding(.bottom, 12)
            .padding(.horizontal, 12)
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
    }
    
    private var partnerInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Rating and delivery info
            HStack(spacing: Spacing.lg) {
                // Rating
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.warning)
                        .font(.caption)
                    Text(String(format: "%.1f", partner.rating))
                        .font(.titleSmall)
                        .foregroundColor(.graphite)
                    Text("(\(partner.reviewCount) reviews)")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                // Delivery time
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "clock")
                        .foregroundColor(.gray500)
                        .font(.caption)
                    Text("\(partner.estimatedDeliveryTime) min")
                        .font(.bodyMedium)
                        .foregroundColor(.graphite)
                }
            }
            
            // Description
            if !partner.description.isEmpty {
                Text(partner.description)
                    .font(.bodyMedium)
                    .foregroundColor(.gray700)
                    .lineLimit(3)
            }
            
            // Delivery info
            HStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Minimum Order")
                        .font(.labelSmall)
                        .foregroundColor(.gray600)
                    Text(formatPrice(partner.minimumOrderAmount))
                        .font(.bodyMedium)
                        .foregroundColor(.graphite)
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Delivery Radius")
                        .font(.labelSmall)
                        .foregroundColor(.gray600)
                    Text(String(format: "%.1f km", partner.deliveryRadius))
                        .font(.bodyMedium)
                        .foregroundColor(.graphite)
                }
                
                Spacer()
            }
            
            AppDivider()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.lg)
    }
    
    private var productCategoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Search bar
            HStack(spacing: Spacing.sm) {
                AppTextField(
                    title: "",
                    placeholder: "Search products...",
                    text: $viewModel.searchText,
                    keyboardType: .default
                )
                .onChange(of: viewModel.searchText) { _, newValue in
                    Task {
                        await viewModel.searchProducts(query: newValue)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
            
            // Category tabs
            if !viewModel.productCategories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        CategoryTab(
                            title: "All",
                            isSelected: viewModel.selectedProductCategory == nil,
                            productCount: viewModel.allProducts.count
                        ) {
                            viewModel.selectProductCategory(nil)
                        }
                        
                        ForEach(viewModel.productCategories, id: \.self) { category in
                            CategoryTab(
                                title: category.displayName,
                                isSelected: viewModel.selectedProductCategory == category,
                                productCount: viewModel.getProductCount(for: category)
                            ) {
                                viewModel.selectProductCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
        }
    }
    
    private var productsSection: some View {
        LazyVStack(spacing: 0) {
            if viewModel.isLoading && viewModel.filteredProducts.isEmpty {
                // Loading skeleton
                ForEach(0..<6, id: \.self) { _ in
                    ProductRowSkeleton()
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                }
            } else if viewModel.filteredProducts.isEmpty {
                // Empty state
                EmptyStateView(
                    title: "No products found",
                    message: viewModel.searchText.isEmpty ? 
                        "This partner hasn't added any products yet" : 
                        "Try adjusting your search terms",
                    systemImage: "magnifyingglass"
                )
                .padding(.vertical, Spacing.xl)
            } else {
                // Products list
                ForEach(viewModel.filteredProducts) { product in
                    ProductRow(
                        product: product,
                        onAddToCart: {
                            Task {
                                await viewModel.addToCart(product: product)
                            }
                        },
                        onTap: {
                            viewModel.selectProduct(product)
                        }
                    )
                    .padding(.horizontal, Spacing.md)
                    
                    if product.id != viewModel.filteredProducts.last?.id {
                        AppDivider()
                            .padding(.horizontal, Spacing.md)
                    }
                }
            }
        }
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Supporting Views

struct CategoryTab: View {
    let title: String
    let isSelected: Bool
    let productCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(.labelMedium)
                    .foregroundColor(isSelected ? .emerald : .gray600)
                
                if productCount > 0 {
                    Text("\(productCount)")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .emerald : .gray500)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.emerald.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.emerald : Color.gray300, lineWidth: 1)
                    )
            )
        }
        .accessibilityLabel("\(title), \(productCount) products")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to filter by this category")
    }
}

struct ProductRow: View {
    let product: Product
    let onAddToCart: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Produktbild (Premium)
                if let url = product.imageURLs.first {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray200)
                            .frame(width: 80, height: 80)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: product.category.iconName)
                                    .foregroundColor(.gray400)
                                    .font(.title2)
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray100)
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                        .overlay(
                            Image(systemName: product.category.iconName)
                                .font(.title2)
                                .foregroundColor(.gray400)
                        )
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Product name
                    Text(product.name)
                        .font(.titleSmall)
                        .foregroundColor(.graphite)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Description
                    Text(product.description)
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Price and add to cart
                    HStack {
                        PriceTag(
                            priceCents: product.priceCents,
                            originalPriceCents: product.originalPriceCents
                        )
                        
                        Spacer()
                        
                        // Availability indicator
                        if !product.isAvailable {
                            Text("Out of Stock")
                                .font(.caption)
                                .foregroundColor(.error)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(Color.error.opacity(0.1))
                                .cornerRadius(4)
                        } else {
                            Button(action: onAddToCart) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.emerald)
                                    .font(.title2)
                            }
                            .accessibilityLabel("Add \(product.name) to cart")
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, Spacing.md)
        }
        .disabled(!product.isAvailable)
        .accessibilityLabel("\(product.name), \(product.formattedPrice)")
        .accessibilityHint(product.isAvailable ? "Tap to view details or add to cart" : "Out of stock")
    }
}

struct PriceTag: View {
    let priceCents: Int
    let originalPriceCents: Int?
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(formatPrice(priceCents))
                .font(.titleSmall)
                .foregroundColor(.graphite)
            
            if let originalPrice = originalPriceCents, originalPrice > priceCents {
                Text(formatPrice(originalPrice))
                    .font(.bodySmall)
                    .foregroundColor(.gray500)
                    .strikethrough()
            }
        }
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

struct ProductRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            SkeletonView()
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                SkeletonView()
                    .frame(height: 20)
                    .frame(maxWidth: 150)
                
                SkeletonView()
                    .frame(height: 16)
                    .frame(maxWidth: 200)
                
                SkeletonView()
                    .frame(height: 16)
                    .frame(maxWidth: 120)
                
                HStack {
                    SkeletonView()
                        .frame(width: 60, height: 18)
                    
                    Spacer()
                    
                    SkeletonView()
                        .frame(width: 30, height: 30)
                        .cornerRadius(15)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Spacing.md)
    }
}

#Preview {
    NavigationStack {
        PartnerDetailView(
            partner: Partner(
                name: "Sample Restaurant",
                category: .restaurant,
                description: "Delicious food and great service",
                address: Address(
                    street: "123 Main St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94102",
                    country: "US"
                ),
                location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                phoneNumber: "+1234567890",
                email: "info@sample.com",
                heroImageURL: nil,
                isVerified: true,
                rating: 4.5,
                reviewCount: 123,
                estimatedDeliveryTime: 25
            )
        )
    }
}