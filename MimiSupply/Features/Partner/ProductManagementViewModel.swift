import SwiftUI
import Combine

@MainActor
class ProductManagementViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var searchText: String = "" {
        didSet {
            filterProducts()
        }
    }
    @Published var isLoading: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var editingProduct: Product?
    
    private let cloudKitService: CloudKitService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        authService: AuthenticationService = AuthenticationServiceImpl.shared
    ) {
        self.cloudKitService = cloudKitService
        self.authService = authService
    }
    
    func loadProducts() async {
        isLoading = true
        
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            products = try await cloudKitService.fetchProducts(for: currentUser.id)
            filterProducts()
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadProducts()
    }
    
    func addProduct(_ product: Product) async {
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            var newProduct = product
            newProduct.partnerId = currentUser.id
            
            let savedProduct = try await cloudKitService.createProduct(newProduct)
            products.append(savedProduct)
            filterProducts()
        } catch {
            handleError(error)
        }
    }
    
    func updateProduct(_ product: Product) async {
        do {
            let updatedProduct = try await cloudKitService.updateProduct(product)
            
            if let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index] = updatedProduct
                filterProducts()
            }
        } catch {
            handleError(error)
        }
    }
    
    func deleteProduct(_ product: Product) {
        Task {
            do {
                try await cloudKitService.deleteProduct(product.id)
                products.removeAll { $0.id == product.id }
                filterProducts()
            } catch {
                handleError(error)
            }
        }
    }
    
    func toggleProductAvailability(_ product: Product) {
        Task {
            do {
                var updatedProduct = product
                updatedProduct.isAvailable.toggle()
                updatedProduct.updatedAt = Date()
                
                let savedProduct = try await cloudKitService.updateProduct(updatedProduct)
                
                if let index = products.firstIndex(where: { $0.id == product.id }) {
                    products[index] = savedProduct
                    filterProducts()
                }
            } catch {
                handleError(error)
            }
        }
    }
    
    func editProduct(_ product: Product) {
        editingProduct = product
    }
    
    // MARK: - Private Methods
    
    private func filterProducts() {
        if searchText.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText) ||
                product.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - CloudKit Service Extensions
extension CloudKitService {
    func createProduct(_ product: Product) async throws -> Product {
        // Implementation would create product in CloudKit
        // For now, return the product with updated timestamps
        var newProduct = product
        newProduct.createdAt = Date()
        newProduct.updatedAt = Date()
        return newProduct
    }
    
    func updateProduct(_ product: Product) async throws -> Product {
        // Implementation would update product in CloudKit
        var updatedProduct = product
        updatedProduct.updatedAt = Date()
        return updatedProduct
    }
    
    func deleteProduct(_ productId: String) async throws {
        // Implementation would delete product from CloudKit
        print("Deleting product: \(productId)")
    }
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        // Implementation would fetch products from CloudKit
        // For now, return mock data
        return [
            Product.mockProduct1,
            Product.mockProduct2,
            Product.mockProduct3
        ]
    }
}

// MARK: - Mock Data
extension Product {
    static let mockProduct1 = Product(
        id: "product1",
        partnerId: "partner1",
        name: "Margherita Pizza",
        description: "Classic pizza with fresh mozzarella, tomato sauce, and basil",
        priceCents: 1299,
        originalPriceCents: nil,
        category: .food,
        imageURLs: [],
        isAvailable: true,
        stockQuantity: nil,
        nutritionInfo: nil,
        allergens: [],
        tags: ["vegetarian", "popular"],
        weight: nil,
        dimensions: nil,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-3600)
    )
    
    static let mockProduct2 = Product(
        id: "product2",
        partnerId: "partner1",
        name: "Caesar Salad",
        description: "Fresh romaine lettuce with parmesan cheese and croutons",
        priceCents: 899,
        originalPriceCents: 1099,
        category: .food,
        imageURLs: [],
        isAvailable: true,
        stockQuantity: 15,
        nutritionInfo: nil,
        allergens: [],
        tags: ["healthy", "vegetarian"],
        weight: nil,
        dimensions: nil,
        createdAt: Date().addingTimeInterval(-172800),
        updatedAt: Date().addingTimeInterval(-7200)
    )
    
    static let mockProduct3 = Product(
        id: "product3",
        partnerId: "partner1",
        name: "Chocolate Cake",
        description: "Rich chocolate cake with chocolate frosting",
        priceCents: 599,
        originalPriceCents: nil,
        category: .food,
        imageURLs: [],
        isAvailable: false,
        stockQuantity: 0,
        nutritionInfo: nil,
        allergens: [],
        tags: ["dessert", "chocolate"],
        weight: nil,
        dimensions: nil,
        createdAt: Date().addingTimeInterval(-259200),
        updatedAt: Date().addingTimeInterval(-1800)
    )
}

// MARK: - Product Category
// Using existing ProductCategory from Product.swift