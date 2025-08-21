//
//  ProductRepositoryImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import MapKit

/// Implementation of ProductRepository for managing product data with offline-first approach
final class ProductRepositoryImpl: ProductRepository, @unchecked Sendable {
    
    private let cloudKitService: CloudKitService
    private let coreDataStack: CoreDataStack
    
    init(cloudKitService: CloudKitService, coreDataStack: CoreDataStack = .shared) {
        self.cloudKitService = cloudKitService
        self.coreDataStack = coreDataStack
    }
    
    func fetchProducts(for partnerId: String) async throws -> [Product] {
        do {
            // Try to fetch from CloudKit first
            let products = try await cloudKitService.fetchProducts(for: partnerId)
            
            // Cache the results for offline access
            coreDataStack.cacheProducts(products, for: partnerId)
            
            return products
        } catch {
            // Fall back to cached data if CloudKit fails
            print("CloudKit fetch failed, using cached data: \(error)")
            return coreDataStack.loadCachedProducts(for: partnerId)
        }
    }
    
    func fetchProduct(by id: String) async throws -> Product? {
        // First check cached data
        let cachedProducts = coreDataStack.loadCachedProducts(for: "")
        if let cachedProduct = cachedProducts.first(where: { $0.id == id }) {
            return cachedProduct
        }
        
        // If not found in cache, this would require a CloudKit query by product ID
        // For now, return nil as individual product fetching by ID is not implemented in CloudKit service
        return nil
    }
    
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product] {
        do {
            return try await cloudKitService.searchProducts(query: query, in: region)
        } catch {
            // Fall back to searching cached data
            print("CloudKit search failed, searching cached data: \(error)")
            let allCachedProducts = coreDataStack.loadCachedProducts(for: "")
            return allCachedProducts.filter { product in
                product.name.localizedCaseInsensitiveContains(query) ||
                product.description.localizedCaseInsensitiveContains(query) ||
                product.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
    }
    
    func fetchProductsByCategory(_ category: ProductCategory, for partnerId: String) async throws -> [Product] {
        let allProducts = try await fetchProducts(for: partnerId)
        return allProducts.filter { $0.category == category }
    }
}