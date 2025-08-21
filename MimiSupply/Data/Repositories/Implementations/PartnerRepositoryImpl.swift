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
    
    func fetchPartnersByCategory(_ category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner] {
        let categoryPartners = category.germanPartners
        return filterPartnersByRegion(categoryPartners, region: region)
    }
    
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner] {
        let searchResults = germanPartners.filter { partner in
            partner.name.localizedCaseInsensitiveContains(query) ||
            partner.description.localizedCaseInsensitiveContains(query) ||
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
                latitude: partner.location.latitude,
                longitude: partner.location.longitude
            )
            
            // Check if partner is within region bounds
            let latitudeDiff = abs(partner.location.latitude - region.center.latitude)
            let longitudeDiff = abs(partner.location.longitude - region.center.longitude)
            
            return latitudeDiff <= (latitudeDelta / 2) && longitudeDiff <= (longitudeDelta / 2)
        }
        .sorted(by: { partner1, partner2 in
            // Sort by distance from region center
            let distance1 = CLLocation(
                latitude: partner1.location.latitude,
                longitude: partner1.location.longitude
            ).distance(from: centerLocation)
            
            let distance2 = CLLocation(
                latitude: partner2.location.latitude,
                longitude: partner2.location.longitude
            ).distance(from: centerLocation)
            
            return distance1 < distance2
        })
    }
}

// MARK: - Demo Data for Testing

extension PartnerRepositoryImpl {
    
    /// Get partners for a specific German city
    func getPartnersForCity(_ cityName: String) -> [Partner] {
        // For now, return all Berlin partners since we don't have the germanCities data
        let berlinCenter = CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050)
        let region = MKCoordinateRegion(
            center: berlinCenter,
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
            GermanPartnerData.electronicsPartners.first!
        ]
        
        return samplePartners
    }
}