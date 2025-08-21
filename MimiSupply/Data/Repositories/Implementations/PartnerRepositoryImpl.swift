//
//  PartnerRepositoryImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import MapKit

/// Implementation of PartnerRepository using CloudKit with German partner data
final class PartnerRepositoryImpl: PartnerRepository, Sendable {
    
    private let cloudKitService: CloudKitService
    
    // MARK: - German Partner Data Cache
    private let germanPartners = GermanPartnerData.allPartners
    
    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - PartnerRepository Implementation
    
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner] {
        // For MVP, return German partners filtered by region
        return filterPartnersByRegion(germanPartners, region: region)
    }
    
    func fetchFeaturedPartners() async throws -> [Partner] {
        // Return top-rated German partners across all categories
        return germanPartners
            .sorted { $0.rating > $1.rating }
            .prefix(12) // Show 12 featured partners
            .map { $0 }
    }
    
    func fetchPartners(by category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner] {
        let categoryPartners = category.germanPartners
        return filterPartnersByRegion(categoryPartners, region: region)
    }
    
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner] {
        let searchResults = germanPartners.filter { partner in
            partner.name.localizedCaseInsensitiveContains(query) ||
            partner.description.localizedCaseInsensitiveContains(query) ||
            partner.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
            partner.category.displayName.localizedCaseInsensitiveContains(query)
        }
        
        return filterPartnersByRegion(searchResults, region: region)
    }
    
    func fetchPartner(by id: String) async throws -> Partner? {
        return germanPartners.first { $0.id == id }
    }
    
    func createPartner(_ partner: Partner) async throws -> Partner {
        // In a real implementation, this would save to CloudKit
        // For now, we'll simulate success
        return partner
    }
    
    func updatePartner(_ partner: Partner) async throws -> Partner {
        // In a real implementation, this would update in CloudKit
        return partner
    }
    
    func deletePartner(withId id: String) async throws {
        // In a real implementation, this would delete from CloudKit
    }
    
    // MARK: - Location-based Filtering
    
    private func filterPartnersByRegion(_ partners: [Partner], region: MKCoordinateRegion) -> [Partner] {
        let centerLocation = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        
        // Calculate region boundaries
        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta
        
        return partners.filter { partner in
            let partnerLocation = CLLocation(
                latitude: partner.coordinate.latitude,
                longitude: partner.coordinate.longitude
            )
            
            // Check if partner is within region bounds
            let latitudeDiff = abs(partner.coordinate.latitude - region.center.latitude)
            let longitudeDiff = abs(partner.coordinate.longitude - region.center.longitude)
            
            return latitudeDiff <= (latitudeDelta / 2) && longitudeDiff <= (longitudeDelta / 2)
        }
        .sorted { partner1, partner2 in
            // Sort by distance from region center
            let distance1 = CLLocation(
                latitude: partner1.coordinate.latitude,
                longitude: partner1.coordinate.longitude
            ).distance(from: centerLocation)
            
            let distance2 = CLLocation(
                latitude: partner2.coordinate.latitude,
                longitude: partner2.coordinate.longitude
            ).distance(from: centerLocation)
            
            return distance1 < distance2
        }
    }
}

// MARK: - Demo Data for Testing

extension PartnerRepositoryImpl {
    
    /// Get partners for a specific German city
    func getPartnersForCity(_ cityName: String) -> [Partner] {
        guard let cityCoordinate = GermanPartnerData.germanCities[cityName] else {
            return []
        }
        
        let region = MKCoordinateRegion(
            center: cityCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        return filterPartnersByRegion(germanPartners, region: region)
    }
    
    /// Get random sample of German partners for demo
    static func getDemoPartners() -> [Partner] {
        let samplePartners = [
            // Mix of categories for demo
            GermanPartnerData.restaurantPartners.first!,
            GermanPartnerData.groceryPartners.first!,
            GermanPartnerData.pharmacyPartners.first!,
            GermanPartnerData.retailPartners.first!
        ]
        
        return samplePartners
    }
}