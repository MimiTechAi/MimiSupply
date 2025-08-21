//
//  ProductRepositoryImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Implementation of ProductRepository using CloudKit with German product data
final class ProductRepositoryImpl: ProductRepository, Sendable {
    
    private let cloudKitService: CloudKitService
    
    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - ProductRepository Implementation
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        // Return German products for the specific partner
        return GermanProductData.getProducts(for: partnerId)
    }
    
    func fetchProducts(by category: ProductCategory) async throws -> [Product] {
        return category.germanProducts
    }
    
    func searchProducts(query: String) async throws -> [Product] {
        return GermanProductData.searchProducts(query)
    }
    
    func fetchProduct(by id: String) async throws -> Product? {
        return GermanProductData.allProducts.first { $0.id == id }
    }
    
    func createProduct(_ product: Product) async throws -> Product {
        // In a real implementation, this would save to CloudKit
        return product
    }
    
    func updateProduct(_ product: Product) async throws -> Product {
        // In a real implementation, this would update in CloudKit
        return product
    }
    
    func deleteProduct(withId id: String) async throws {
        // In a real implementation, this would delete from CloudKit
    }
    
    func fetchFeaturedProducts() async throws -> [Product] {
        // Return a curated selection of featured German products
        let featuredProducts = [
            // Featured from each category
            GermanProductData.mcdonaldsProducts.first!, // Big Mac
            GermanProductData.reweProducts.first!, // Bio Milk
            GermanProductData.docMorrisProducts.first!, // Aspirin
            GermanProductData.mediaMarktProducts.first! // iPhone
        ]
        
        return featuredProducts
    }
    
    func fetchPopularProducts(limit: Int = 10) async throws -> [Product] {
        // Return popular products based on typical German preferences
        return Array(GermanProductData.allProducts.shuffled().prefix(limit))
    }
    
    func updateProductStock(productId: String, newStock: Int) async throws {
        // In real implementation, would update stock in CloudKit
        print("Stock updated for product \(productId): \(newStock) units")
    }
}

// MARK: - Demo Helpers

extension ProductRepositoryImpl {
    
    /// Get demo products for testing
    static func getDemoProducts() -> [Product] {
        return [
            GermanProductData.mcdonaldsProducts[0], // Big Mac
            GermanProductData.mcdonaldsProducts[1], // McNuggets
            GermanProductData.reweProducts[0], // Bio Milk
            GermanProductData.reweProducts[1], // Bananas
            GermanProductData.docMorrisProducts[0], // Aspirin
            GermanProductData.mediaMarktProducts[0] // iPhone
        ]
    }
    
    /// Get products for specific German partner
    func getGermanPartnerProducts(_ partnerId: String) -> [Product] {
        return GermanProductData.getProducts(for: partnerId)
    }
}