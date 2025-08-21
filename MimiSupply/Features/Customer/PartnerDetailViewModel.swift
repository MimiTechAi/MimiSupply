//
//  PartnerDetailViewModel.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 14.08.25.
//

import Foundation
import Combine

/// ViewModel for PartnerDetailView with product browsing and cart management
@MainActor
class PartnerDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allProducts: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var productCategories: [ProductCategory] = []
    @Published var selectedProductCategory: ProductCategory?
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var cartItemCount: Int = 0
    @Published var showingProductDetail: Product?
    
    // MARK: - Private Properties
    private let partner: Partner
    private let productRepository: ProductRepository
    private let cartService: CartService
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        partner: Partner,
        productRepository: ProductRepository = ProductRepositoryImpl(
            cloudKitService: CloudKitServiceImpl(),
            coreDataStack: CoreDataStack.shared
        ),
        cartService: CartService? = nil
    ) {
        self.partner = partner
        self.productRepository = productRepository
        self.cartService = cartService ?? CartService.shared
        
        setupBindings()
    }
    
    // MARK: - Public Methods
    func loadProducts() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let products = try await productRepository.fetchProducts(for: partner.id)
            
            allProducts = products.filter { $0.isAvailable || $0.stockQuantity ?? 0 > 0 }
            filteredProducts = allProducts
            
            // Extract unique categories from products
            let categories = Set(allProducts.map { $0.category })
            productCategories = Array(categories).sorted { $0.displayName < $1.displayName }
            
        } catch {
            print("Failed to load products: \(error)")
            // Handle error - could show error state
        }
    }
    
    func refreshData() async {
        await loadProducts()
    }
    
    func searchProducts(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        // Debounce search
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            
            guard !Task.isCancelled else { return }
            
            await applyFilters()
        }
    }
    
    func selectProductCategory(_ category: ProductCategory?) {
        selectedProductCategory = category
        Task {
            await applyFilters()
        }
    }
    
    func addToCart(product: Product, quantity: Int = 1) async {
        guard product.isAvailable else { return }
        
        do {
            try await cartService.addItem(product: product, quantity: quantity)
            
            // Show success feedback
            await showAddToCartSuccess(for: product)
            
        } catch {
            print("Failed to add to cart: \(error)")
            // Handle error - could show error message
        }
    }
    
    func selectProduct(_ product: Product) {
        showingProductDetail = product
    }
    
    func getProductCount(for category: ProductCategory) -> Int {
        return allProducts.filter { $0.category == category }.count
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // Update cart item count
        cartService.cartItemCountPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.cartItemCount, on: self)
            .store(in: &cancellables)
    }
    
    private func applyFilters() async {
        var filtered = allProducts
        
        // Apply category filter
        if let selectedCategory = selectedProductCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText) ||
                product.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort by availability first, then by name
        filtered = filtered.sorted { lhs, rhs in
            if lhs.isAvailable != rhs.isAvailable {
                return lhs.isAvailable && !rhs.isAvailable
            }
            return lhs.name < rhs.name
        }
        
        filteredProducts = filtered
    }
    
    private func showAddToCartSuccess(for product: Product) async {
        // Could implement haptic feedback or toast message
        print("Added \(product.name) to cart")
    }
}
