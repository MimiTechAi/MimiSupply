//
//  SearchView.swift
//  MimiSupply
//
//  Global search for partners and products
//

import SwiftUI
import MapKit

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedCategory: SearchCategory = .all
    @Environment(\.presentationMode) var presentationMode
    
    enum SearchCategory: String, CaseIterable {
        case all = "All"
        case restaurants = "Restaurants"
        case grocery = "Grocery"
        case pharmacy = "Pharmacy"
        case retail = "Retail"
        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .restaurants: return "fork.knife"
            case .grocery: return "cart"
            case .pharmacy: return "cross.case"
            case .retail: return "bag"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeader
                
                // Category Filter
                categoryFilter
                
                // Search Results
                if isSearching {
                    searchLoadingView
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptySearchView
                } else if searchResults.isEmpty {
                    recentSearchesView
                } else {
                    searchResultsList
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .onAppear {
                loadRecentSearches()
            }
        }
    }
    
    private var searchHeader: some View {
        HStack {
            Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(.emerald)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray500)
                
                TextField("Search restaurants, stores, items...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { _ in
                        if searchText.isEmpty {
                            searchResults = []
                        } else {
                            performSearch()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray400)
                    }
                }
            }
            .padding(Spacing.sm)
            .background(Color.gray100)
            .cornerRadius(10)
        }
        .padding(Spacing.md)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(SearchCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        if !searchText.isEmpty {
                            performSearch()
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .padding(.bottom, Spacing.sm)
    }
    
    private var searchLoadingView: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.bodyMedium)
                .foregroundColor(.gray600)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray400)
            
            VStack(spacing: Spacing.sm) {
                Text("No results found")
                    .font(.titleMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.graphite)
                
                Text("Try searching with different keywords")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Recent Searches")
                .font(.titleMedium)
                .fontWeight(.semibold)
                .foregroundColor(.graphite)
                .padding(.horizontal, Spacing.md)
            
            VStack(spacing: 0) {
                ForEach(recentSearchTerms, id: \.self) { term in
                    RecentSearchRow(term: term) {
                        searchText = term
                        performSearch()
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchResults) { result in
                    SearchResultRow(result: result)
                        .onTapGesture {
                            handleResultTap(result)
                        }
                }
            }
        }
    }
    
    private var recentSearchTerms: [String] {
        // In a real app, load from UserDefaults or Core Data
        return ["Pizza", "Sushi", "Coffee", "Pharmacy", "Grocery"]
    }
    
    private func loadRecentSearches() {
        // Load recent searches from storage
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            await searchPartners()
        }
    }
    
    @MainActor
    private func searchPartners() async {
        do {
            // Simulate API call delay
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Mock search results
            let mockResults: [SearchResult] = [
                SearchResult(
                    id: "1",
                    type: .partner,
                    title: "Pizza Palace",
                    subtitle: "Italian • 4.5★ • 25-35 min",
                    imageURL: nil
                ),
                SearchResult(
                    id: "2",
                    type: .partner,
                    title: "Fresh Market",
                    subtitle: "Grocery • 4.2★ • 20-30 min",
                    imageURL: nil
                ),
                SearchResult(
                    id: "3",
                    type: .product,
                    title: "Margherita Pizza",
                    subtitle: "From Pizza Palace • $12.99",
                    imageURL: nil
                )
            ]
            
            // Filter by category if needed
            if selectedCategory != .all {
                searchResults = mockResults.filter { result in
                    // Filter logic based on selected category
                    return true
                }
            } else {
                searchResults = mockResults
            }
            
            isSearching = false
        } catch {
            isSearching = false
        }
    }
    
    private func handleResultTap(_ result: SearchResult) {
        // Save to recent searches
        saveRecentSearch(searchText)
        
        // Navigate based on result type
        switch result.type {
        case .partner:
            // Navigate to partner detail
            break
        case .product:
            // Navigate to product detail
            break
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func saveRecentSearch(_ term: String) {
        // Save to UserDefaults or Core Data
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let category: SearchView.SearchCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.labelMedium)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(isSelected ? Color.emerald : Color.white)
            .foregroundColor(isSelected ? .white : .graphite)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray300, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

struct RecentSearchRow: View {
    let term: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "clock")
                    .font(.body)
                    .foregroundColor(.gray500)
                
                Text(term)
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.caption)
                    .foregroundColor(.gray400)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SearchResultRow: View {
    let result: SearchResult
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Result Image
            AsyncImage(url: result.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray200)
                    .overlay(
                        Image(systemName: result.type == .partner ? "storefront" : "cube.box")
                            .font(.title2)
                            .foregroundColor(.gray400)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            // Result Info
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.graphite)
                    .lineLimit(1)
                
                Text(result.subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray400)
        }
        .padding(Spacing.md)
    }
}

// MARK: - Search Result Model

struct SearchResult: Identifiable {
    let id: String
    let type: ResultType
    let title: String
    let subtitle: String
    let imageURL: URL?
    
    enum ResultType {
        case partner
        case product
    }
}

#Preview {
    SearchView()
}