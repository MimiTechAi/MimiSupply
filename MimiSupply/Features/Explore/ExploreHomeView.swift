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
            .background(Color.clear)
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
        .background(Color.clear)
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
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .accessibleButton(
                label: "Filters",
                hint: "Open filtering options to refine your search results"
            )
            .accessibilityIdentifier("filters-button")
        }
        .accessibilityElement(children: .contain)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Categories")
                .font(.titleLarge)
                .foregroundColor(.graphite)
                .accessibleHeading(label: "Categories", level: .h2)
            categoriesScrollView
        }
    }

    @ViewBuilder
    private var categoriesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.md) {
                ForEach(viewModel.categories, id: \.self) { category in
                    categoryButton(for: category)
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .accessibilityLabel("Categories list")
        .accessibilityHint("Swipe horizontally to browse categories")
    }

    @ViewBuilder
    private func categoryButton(for category: PartnerCategory) -> some View {
        Button(action: {
            Task {
                await viewModel.selectCategory(category)
            }
        }) {
            VStack {
                if let premiumImageURL = category.premiumIconURL {
                    AsyncImage(url: premiumImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 38, height: 38)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } placeholder: {
                        ProgressView()
                            .frame(width: 38, height: 38)
                    }
                } else {
                    Text("🍽️").font(.largeTitle)
                }
                Text(category.displayName)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(viewModel.selectedCategory == category ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(12)
            .shadow(radius: 1)
        }
        .accessibilityLabel(category.displayName)
        .accessibilityValue(Text("\(viewModel.getPartnerCount(for: category)) partners"))
        .accessibilityHint("Tap to filter by \(category.displayName.lowercased())")
        .accessibilityAddTraits(viewModel.selectedCategory == category ? .isSelected : [])
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Featured Partners")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See All") {
                    Task {
                        await viewModel.showAllFeatured()
                    }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.31, green: 0.78, blue: 0.47))
            }
            
            // Premium Featured Partners with Horizontal Scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredPartners.prefix(5)) { partner in
                        PremiumPartnerCard(partner: partner) {
                            viewModel.selectPartner(partner)
                        }
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
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
            ZStack {
                // Background with partner-specific styling
                partnerBackgroundGradient
                
                HStack(spacing: Spacing.md) {
                    // Partner logo/image with premium styling
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.9))
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        
                        partnerIcon
                            .font(.title2)
                            .foregroundColor(partnerAccentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(partner.name)
                                .font(.titleMedium)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            if partner.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        
                        Text(partner.category.displayName)
                            .font(.bodySmall)
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack(spacing: Spacing.md) {
                            // Rating
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text(partner.formattedRating)
                                    .font(.bodySmall)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                Text("(\(partner.reviewCount))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Status & Delivery time
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(partner.isOpenNow ? .green : .red)
                                        .frame(width: 6, height: 6)
                                    
                                    Text(partner.isOpenNow ? "Geöffnet" : "Geschlossen")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                Text("\(partner.estimatedDeliveryTime) min")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
                .padding(16)
            }
        }
        .frame(height: 90)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .accessibilityLabel("\(partner.name), \(partner.category.displayName), \(partner.rating) stars, \(partner.estimatedDeliveryTime) minutes delivery")
        .accessibilityHint("Tap to view partner details and menu")
    }
    
    @ViewBuilder
    private var partnerBackgroundGradient: some View {
        switch partner.id {
        case "mcdonalds_berlin_mitte":
            LinearGradient(
                colors: [Color.red.opacity(0.8), Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "rewe_alexanderplatz":
            LinearGradient(
                colors: [Color.green.opacity(0.7), Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "docmorris_berlin":
            LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "mediamarkt_alexanderplatz":
            LinearGradient(
                colors: [Color.orange.opacity(0.7), Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "edeka_prenzlauer_berg":
            LinearGradient(
                colors: [Color.yellow.opacity(0.8), Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.8),
                    Color(red: 0.25, green: 0.85, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    @ViewBuilder
    private var partnerIcon: some View {
        if let logoURL = partner.logoURL {
            // Premium: Show partner logo from URL, cropped in a circle
            AsyncImage(url: logoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(Circle())
                    .frame(width: 48, height: 48)
            } placeholder: {
                ProgressView()
                    .frame(width: 48, height: 48)
            }
        } else {
            // Fallback: Symbolic icon
            switch partner.id {
            case "mcdonalds_berlin_mitte":
                Image(systemName: "m.circle.fill")
            case "rewe_alexanderplatz":
                Image(systemName: "cart.fill")
            case "docmorris_berlin":
                Image(systemName: "cross.case.fill")
            case "mediamarkt_alexanderplatz":
                Image(systemName: "tv.fill")
            case "edeka_prenzlauer_berg":
                Image(systemName: "leaf.fill")
            default:
                Image(systemName: partner.category.iconName)
            }
        }
    }
    
    private var partnerAccentColor: Color {
        switch partner.id {
        case "mcdonalds_berlin_mitte": return .yellow
        case "rewe_alexanderplatz": return .white
        case "docmorris_berlin": return .white
        case "mediamarkt_alexanderplatz": return .white
        case "edeka_prenzlauer_berg": return .green
        default: return .white
        }
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
        .environmentObject(AppContainer.shared.appRouter)
        .environmentObject(AppContainer.shared)
}

// Suche nach PremiumPartnerCard(partner: ...) oder erstelle Component falls sie fehlt, sonst ändere analog PartnerRowCard:

struct PremiumPartnerCard: View {
    let partner: Partner
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background: Hero image bevorzugt, sonst Farbtint
                if let heroURL = partner.heroImageURL {
                    AsyncImage(url: heroURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray200)
                            .frame(height: 160)
                            .overlay(ProgressView())
                    }
                } else {
                    partnerBackgroundGradient
                        .frame(height: 160)
                }
                // Gradient Overlay
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 160)

                // Logo links unten, Name, Kategorie
                HStack(alignment: .center, spacing: 12) {
                    if let logoURL = partner.logoURL {
                        AsyncImage(url: logoURL) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(partner.name)
                            .font(.headlineSmall)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text(partner.category.displayName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .padding(14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.black.opacity(0.13), radius: 8, x: 0, y: 3)
        }
        .frame(width: 280, height: 170)
    }

    @ViewBuilder
    private var partnerBackgroundGradient: some View {
        switch partner.id {
        case "mcdonalds_berlin_mitte":
            LinearGradient(
                colors: [Color.red.opacity(0.8), Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "rewe_alexanderplatz":
            LinearGradient(
                colors: [Color.green.opacity(0.7), Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "docmorris_berlin":
            LinearGradient(
                colors: [Color.blue.opacity(0.7), Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "mediamarkt_alexanderplatz":
            LinearGradient(
                colors: [Color.orange.opacity(0.7), Color.orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "edeka_prenzlauer_berg":
            LinearGradient(
                colors: [Color.yellow.opacity(0.8), Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.8),
                    Color(red: 0.25, green: 0.85, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
