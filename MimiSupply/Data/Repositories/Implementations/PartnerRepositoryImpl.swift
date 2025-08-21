//
//  PartnerRepositoryImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import MapKit

/// Implementation of PartnerRepository for managing business partner data with offline-first approach
final class PartnerRepositoryImpl: PartnerRepository, @unchecked Sendable {
    
    private let cloudKitService: CloudKitService
    private let coreDataStack: CoreDataStack
    
    init(cloudKitService: CloudKitService, coreDataStack: CoreDataStack = .shared) {
        self.cloudKitService = cloudKitService
        self.coreDataStack = coreDataStack
    }
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        do {
            // Try to fetch from CloudKit first
            let partners = try await cloudKitService.fetchPartners(in: region)
            
            // Cache the results for offline access
            coreDataStack.cachePartners(partners)
            
            return partners
        } catch {
            // Fall back to cached data if CloudKit fails
            print("CloudKit fetch failed, using cached data: \(error)")
            return coreDataStack.loadCachedPartners()
        }
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        do {
            // Try CloudKit first
            let partner = try await cloudKitService.fetchPartner(by: id)
            
            // Cache the result if found
            if let partner = partner {
                coreDataStack.cachePartners([partner])
            }
            
            return partner
        } catch {
            // Fall back to cached data
            print("CloudKit fetch failed, checking cached data: \(error)")
            let cachedPartners = coreDataStack.loadCachedPartners()
            return cachedPartners.first { $0.id == id }
        }
    }
    
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner] {
        let partners = try await fetchPartners(in: region)
        return partners.filter { partner in
            partner.name.localizedCaseInsensitiveContains(query) ||
            partner.description.localizedCaseInsensitiveContains(query) ||
            partner.category.displayName.localizedCaseInsensitiveContains(query)
        }
    }
    
    func fetchFeaturedPartners() async throws -> [Partner] {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        let allPartners = try await fetchPartners(in: region)
        return Array(allPartners.filter { $0.rating >= 4.5 }.prefix(10))
    }
    
    func fetchPartnersByCategory(_ category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner] {
        let allPartners = try await fetchPartners(in: region)
        return allPartners.filter { $0.category == category }
    }
}