//
//  ExploreHomeView.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI
import CoreLocation

/// Explore home view with comprehensive partner discovery functionality
struct ExploreHomeView: View {
    @StateObject private var viewModel = ExploreHomeViewModel()
    @State private var showingMap = false
    @State private var showingFilters = false
    @Environment(\.analytics) private var analytics
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with location and search
                headerSection
                
                // Main content with loading states
                if viewModel.isLoading && viewModel.partners.isEmpty {
                    loadingStateView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarButtons
                }
            }
            .navigationDestination(item: $viewModel.selectedPartner) { partner in
                PartnerDetailView(partner: partner)
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedCategory: $viewModel.selectedCategory,
                    selectedSortOption: $viewModel.sortOption,
                    priceRange: $viewModel.priceRange,
                    deliveryTimeRange: $viewModel.deliveryTimeRange,
                    onApply: {
                        showingFilters = false
                        Task {
                            await viewModel.applyFilters()
                        }
                    }
                )
            }
            .sheet(isPresented: $viewModel.showingCart) {
                CartView()
            }
            .task {
                await viewModel.loadInitialData()
            }
            .trackScreen("ExploreHomeView", parameters: [
                "view_mode": showingMap ? "map" : "list",
                "category": viewModel.selectedCategory?.rawValue ?? "all"
            ])
            .refreshable {
                await viewModel.refreshData()
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if showingMap {
            MapView(partners: viewModel.partners)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        } else {
            listContentView
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
        }
    }
    
    @ViewBuilder
    private var listContentView: some View {
        OptimizedListView(
            data: viewModel.partners,
            onRefresh: {
                await viewModel.refreshData()
            },
            onLoadMore: {
                await viewModel.loadMoreIfNeeded()
            }
        ) { partner in
            PartnerRowCard(partner: partner) {
                viewModel.selectPartner(partner)
            }
            .optimizedListItem()
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: Spacing.lg) {
                // Search bar
                searchSection
                
                // Categories
                if !viewModel.categories.isEmpty {
                    categoriesSection
                }
                
                // Featured partners
                if !viewModel.featuredPartners.isEmpty {
                    featuredSection
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .background(Color.chalk)
        }
    }
    
    @ViewBuilder
    private var loadingStateView: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Search skeleton
                SkeletonView()
                    .frame(height: 44)
                    .cornerRadius(8)
                
                // Categories skeleton
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonView()
                                .frame(width: 80, height: 80)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                
                // Partners skeleton
                ForEach(0..<6, id: \.self) { _ in
                    PartnerCardSkeleton()
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Deliver to")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                    
                    Button(action: {
                        // Handle location selection
                    }) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.emerald)
                                .font(.caption)
                            
                            Text(viewModel.currentLocationName)
                                .font(.titleSmall)
                                .foregroundColor(.graphite)
                                .lineLimit(1)
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray500)
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("Current delivery location: \(viewModel.currentLocationName)")
                    .accessibilityHint("Tap to change delivery location")
                }
                
                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)
        }
        .background(Color.chalk)
    }
    
    private var searchSection: some View {
        HStack(spacing: Spacing.sm) {
            AppTextField(
                title: "",
                placeholder: "Search restaurants, groceries, pharmacies...",
                text: $viewModel.searchText,
                keyboardType: .default,
                accessibilityHint: "Search for restaurants, groceries, pharmacies and more",
                accessibilityIdentifier: "explore-search-field"
            )
            .onChange(of: viewModel.searchText) { _, newValue in
                Task {
                    await viewModel.performSearch(query: newValue)
                }
            }
            
            Button(action: { showingFilters = true }) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.emerald)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .accessibleButton(
                label: "Filters",
                hint: "Open filtering options to refine your search results"
            )
            .switchControlAccessible(
                identifier: "filters-button",
                sortPriority: 0.9
            )
            .voiceControlAccessible(spokenPhrase: "Filters")
        }
        .accessibilityElement(children: .contain)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Categories")
                .font(.titleLarge)
                .foregroundColor(.graphite)
                .accessibleHeading("Categories", level: .h2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        Button(action: {
                            Task {
                                await viewModel.selectCategory(category)
                            }
                        }) {
                            VStack {
                                Text("🍽️")
                                    .font(.largeTitle)
                                Text(category.displayName)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 80, height: 80)
                            .background(viewModel.selectedCategory == category ? Color.blue.opacity(0.2) : Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                        }
                        .accessibleCard(
                            title: category.displayName,
                            subtitle: "\(viewModel.getPartnerCount(for: category)) partners",
                            hint: "Tap to filter by \(category.displayName.lowercased())",
                            isSelected: viewModel.selectedCategory == category
                        )
                        .switchControlAccessible(
                            identifier: "category-\(category.rawValue)",
                            sortPriority: 0.8
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .accessibilityLabel("Categories list")
            .accessibilityHint("Swipe horizontally to browse categories")
        }
        .accessibilityElement(children: .contain)
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Featured Partners")
                    .font(.titleLarge)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                Button("See All") {
                    Task {
                        await viewModel.showAllFeatured()
                    }
                }
                .font(.bodyMedium)
                .foregroundColor(.emerald)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Spacing.md) {
                    ForEach(viewModel.featuredPartners) { partner in
                        Button(action: { viewModel.selectPartner(partner) }) {
                            VStack {
                                Text(partner.name)
                                    .font(.headline)
                                Text("⭐ \(String(format: "%.1f", partner.rating))")
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
        }
    }
    

    
    private var toolbarButtons: some View {
        HStack(spacing: Spacing.sm) {
            Button(action: { 
                withAnimation(AnimationOptimizer.accessibleSmooth) {
                    showingMap.toggle()
                }
            }) {
                Image(systemName: showingMap ? "list.bullet" : "map")
                    .foregroundColor(.emerald)
                    .font(.title2)
            }
            .accessibilityLabel(showingMap ? "Switch to list view" : "Switch to map view")
            
            CartButton(itemCount: viewModel.cartItemCount) {
                viewModel.navigateToCart()
            }
        }
    }
    

}

// MARK: - Supporting Views

// CategoryCard and FeaturedPartnerCard are defined in ExploreHomeViewWithErrorHandling.swift

struct PartnerRowCard: View {
    let partner: Partner
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AppCard {
                HStack(spacing: Spacing.md) {
                    // Partner logo/image with optimized caching
                    CachedAsyncImage(url: partner.logoURL ?? partner.heroImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray200)
                            .overlay(
                                Image(systemName: partner.category.iconName)
                                    .foregroundColor(.gray400)
                                    .font(.title2)
                            )
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(partner.name)
                                .font(.titleMedium)
                                .foregroundColor(.graphite)
                                .lineLimit(1)
                            
                            if partner.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.success)
                                    .font(.caption)
                            }
                        }
                        
                        Text(partner.category.displayName)
                            .font(.bodySmall)
                            .foregroundColor(.gray600)
                        
                        Text(partner.description)
                            .font(.caption)
                            .foregroundColor(.gray500)
                            .lineLimit(1)
                        
                        HStack(spacing: Spacing.md) {
                            // Rating
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.warning)
                                    .font(.caption)
                                Text(String(format: "%.1f", partner.rating))
                                    .font(.bodySmall)
                                    .foregroundColor(.gray600)
                                Text("(\(partner.reviewCount))")
                                    .font(.caption)
                                    .foregroundColor(.gray500)
                            }
                            
                            Spacer()
                            
                            // Delivery time
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "clock")
                                    .foregroundColor(.gray500)
                                    .font(.caption)
                                Text("\(partner.estimatedDeliveryTime) min")
                                    .font(.bodySmall)
                                    .foregroundColor(.gray600)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray400)
                        .font(.caption)
                }
            }
        }
        .accessibilityLabel("\(partner.name), \(partner.category.displayName), \(partner.rating) stars, \(partner.estimatedDeliveryTime) minutes delivery")
        .accessibilityHint("Tap to view partner details and menu")
    }
}

// MARK: - Skeleton Views

struct SkeletonView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(Color.gray200)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.6), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            )
            .clipped()
            .onAppear {
                isAnimating = true
            }
    }
}

struct PartnerCardSkeleton: View {
    var body: some View {
        AppCard {
            HStack(spacing: Spacing.md) {
                SkeletonView()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    SkeletonView()
                        .frame(height: 20)
                        .frame(maxWidth: 120)
                    
                    SkeletonView()
                        .frame(height: 16)
                        .frame(maxWidth: 80)
                    
                    SkeletonView()
                        .frame(height: 14)
                        .frame(maxWidth: 100)
                    
                    HStack {
                        SkeletonView()
                            .frame(width: 60, height: 14)
                        
                        Spacer()
                        
                        SkeletonView()
                            .frame(width: 50, height: 14)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// NotificationBadge is now imported from DesignSystem

#Preview {
    ExploreHomeView()
}