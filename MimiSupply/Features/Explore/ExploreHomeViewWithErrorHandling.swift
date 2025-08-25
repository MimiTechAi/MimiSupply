//
//  ExploreHomeViewWithErrorHandling.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI
import MapKit

/// Enhanced ExploreHomeView with comprehensive error handling
struct ExploreHomeViewWithErrorHandling: View {
    
    @StateObject private var viewModel = ExploreHomeViewModelWithErrorHandling()
    @StateObject private var degradationService = GracefulDegradationService.shared
    @StateObject private var offlineManager = OfflineManager.shared
    
    @State private var showingMap = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Service status indicator
                if let statusMessage = viewModel.serviceStatusMessage {
                    ServiceStatusBanner(message: statusMessage)
                }
                
                // Offline mode indicator
                if viewModel.isOfflineMode {
                    OfflineModeBanner(pendingSyncCount: viewModel.pendingSyncCount)
                }
                
                // Header with search and toggle
                ExploreHeader(
                    searchText: $viewModel.searchText,
                    showingMap: $showingMap,
                    cartItemCount: viewModel.cartItemCount,
                    onFilterTap: { showingFilters = true }
                )
                
                // Main content
                Group {
                    if viewModel.showingErrorState {
                        // Error state view
                        ErrorStateView(
                            error: viewModel.currentError ?? AppError.unknown(NSError()),
                            onRetry: viewModel.errorRecoveryAction,
                            onDismiss: {
                                viewModel.currentError = nil
                                viewModel.showingErrorState = false
                            }
                        )
                        .accessibilityIdentifier("error_state_view")
                    } else if showingMap {
                        // Map view
                        ExploreMapView(
                            partners: viewModel.partners,
                            region: $viewModel.currentRegion,
                            onPartnerSelect: viewModel.selectPartner
                        )
                    } else {
                        // List view
                        ExploreListView(
                            partners: viewModel.partners,
                            featuredPartners: viewModel.featuredPartners,
                            categories: viewModel.categories,
                            selectedCategory: viewModel.selectedCategory,
                            isLoading: viewModel.isLoading,
                            onPartnerSelect: viewModel.selectPartner,
                            onCategorySelect: viewModel.filterByCategory
                        )
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    CartButton(itemCount: viewModel.cartItemCount, onTap: {})
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedCategory: .constant(nil),
                    selectedSortOption: .constant(.recommended),
                    priceRange: .constant(0...100),
                    deliveryTimeRange: .constant(0...60),
                    onApply: {}
                )
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadInitialData()
            }
        }
        .accessibilityIdentifier("explore_home_view")
    }
}

// MARK: - Service Status Banner

struct ServiceStatusBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warning)
                .font(.caption)
            
            Text(message)
                .font(.caption.scaledFont())
                .foregroundColor(.warning)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.warning.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Service status: \(message)")
        .accessibilityIdentifier("service_status_indicator")
    }
}

// MARK: - Offline Mode Banner

struct OfflineModeBanner: View {
    let pendingSyncCount: Int
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "wifi.slash")
                .foregroundColor(.error)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Offline Mode")
                    .font(.caption.scaledFont())
                    .foregroundColor(.error)
                    .fontWeight(.medium)
                
                if pendingSyncCount > 0 {
                    Text("\(pendingSyncCount) items pending sync")
                        .font(.caption2.scaledFont())
                        .foregroundColor(.error.opacity(0.8))
                }
            }
            
            Spacer()
            
            if pendingSyncCount > 0 {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.error)
                    .font(.caption)
                    .rotationEffect(.degrees(pendingSyncCount > 0 ? 360 : 0))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), 
                              value: pendingSyncCount > 0)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.error.opacity(0.1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline mode. \(pendingSyncCount) items pending sync")
        .accessibilityIdentifier("offline_mode_indicator")
    }
}

// MARK: - Explore Header

struct ExploreHeader: View {
    @Binding var searchText: String
    @Binding var showingMap: Bool
    let cartItemCount: Int
    let onFilterTap: () -> Void
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            // Search bar
            HStack(spacing: Spacing.sm) {
                SearchBar(
                    text: $searchText,
                    placeholder: "Search restaurants, shops..."
                )
                
                Button(action: onFilterTap) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.emerald)
                }
                .accessibilityLabel("Filters")
                .accessibilityHint("Tap to open filter options")
            }
            
            // Map/List toggle
            HStack {
                Picker("View Mode", selection: $showingMap) {
                    Label("List", systemImage: "list.bullet").tag(false)
                    Label("Map", systemImage: "map").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.chalk)
    }
}

// MARK: - Explore List View

struct ExploreListView: View {
    let partners: [Partner]
    let featuredPartners: [Partner]
    let categories: [PartnerCategory]
    let selectedCategory: PartnerCategory?
    let isLoading: Bool
    let onPartnerSelect: (Partner) -> Void
    let onCategorySelect: (PartnerCategory?) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                if isLoading && partners.isEmpty {
                    // Loading state
                    LoadingView()
                        .accessibilityIdentifier("loading_view")
                } else if partners.isEmpty {
                    // Empty state
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No partners found",
                        message: "Try adjusting your search or location to find nearby businesses.",
                        actionTitle: "Refresh",
                        action: {
                            // Trigger refresh
                        }
                    )
                } else {
                    // Featured partners carousel
                    if !featuredPartners.isEmpty && selectedCategory == nil {
                        FeaturedPartnersCarousel(
                            partners: featuredPartners,
                            onPartnerSelect: onPartnerSelect
                        )
                    }
                    
                    // Categories
                    if selectedCategory == nil {
                        CategoryGrid(
                            categories: categories,
                            onCategorySelect: onCategorySelect
                        )
                    }
                    
                    // Partners list
                    LazyVStack(spacing: Spacing.md) {
                        ForEach(partners) { partner in
                            Button(action: { onPartnerSelect(partner) }) {
                                VStack(alignment: .leading) {
                                    Text(partner.name)
                                        .font(.headline)
                                    Text(partner.description ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .refreshable {
            // Refresh handled by parent view
        }
    }
}

// MARK: - Explore Map View

struct ExploreMapView: View {
    let partners: [Partner]
    @Binding var region: MKCoordinateRegion
    let onPartnerSelect: (Partner) -> Void
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: partners) { partner in
            MapPin(coordinate: partner.location, tint: .red)
        }
        .accessibilityIdentifier("explore_map")
    }
}

// PartnerMapAnnotation is defined in Features/Explore/MapView.swift

// MARK: - Featured Partners Carousel

struct FeaturedPartnersCarousel: View {
    let partners: [Partner]
    let onPartnerSelect: (Partner) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Featured Partners")
                .font(.titleMedium.scaledFont())
                .foregroundColor(.graphite)
                .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Spacing.md) {
                    ForEach(partners) { partner in
                        Button(action: { onPartnerSelect(partner) }) {
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
}

// FeaturedPartnerCard is defined in Features/Explore/ExploreHomeView.swift

// MARK: - Category Grid

struct CategoryGrid: View {
    let categories: [PartnerCategory]
    let onCategorySelect: (PartnerCategory?) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Categories")
                .font(.titleMedium.scaledFont())
                .foregroundColor(.graphite)
                .padding(.horizontal, Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(Array(categories.enumerated()), id: \.offset) { _, category in
                        Button(action: { onCategorySelect(category) }) {
                            VStack {
                                Text("🍽️")
                                    .font(.largeTitle)
                                Text(category.displayName)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// CategoryCard is defined in Features/Explore/ExploreHomeView.swift

#Preview {
    ExploreHomeViewWithErrorHandling()
}