//
//  ProductRepository.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import MapKit

/// Product repository protocol for managing product data
protocol ProductRepository: Sendable {
    func fetchProducts(for partnerId: String) async throws -> [Product]
    func fetchProduct(by id: String) async throws -> Product?
    func searchProducts(query: String, in region: MKCoordinateRegion) async throws -> [Product]
    func fetchProductsByCategory(_ category: ProductCategory, for partnerId: String) async throws -> [Product]
}