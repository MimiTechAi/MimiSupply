//
//  PartnerRepository.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import MapKit

/// Partner repository protocol for managing business partner data
protocol PartnerRepository: Sendable {
    func fetchPartners(in region: MKCoordinateRegion) async throws -> [Partner]
    func fetchPartner(by id: String) async throws -> Partner?
    func searchPartners(query: String, in region: MKCoordinateRegion) async throws -> [Partner]
    func fetchFeaturedPartners() async throws -> [Partner]
    func fetchPartnersByCategory(_ category: PartnerCategory, in region: MKCoordinateRegion) async throws -> [Partner]
}