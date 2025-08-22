//
//  DriverService.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import Foundation
import CoreLocation

protocol DriverService {
    func updateStatus(isOnline: Bool, isAvailable: Bool, isOnBreak: Bool) async throws
    func updateLocation(_ location: CLLocationCoordinate2D) async throws
    func fetchAvailableJobs() async throws -> [Order]
}