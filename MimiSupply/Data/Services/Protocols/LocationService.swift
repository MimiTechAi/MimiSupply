//
//  LocationService.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CoreLocation

/// Location service protocol for managing location services
protocol LocationService: Sendable {
    var currentLocation: CLLocation? { get async }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission() async throws
    func startLocationUpdates() async throws
    func stopLocationUpdates()
    func startBackgroundLocationUpdates() async throws
    func stopBackgroundLocationUpdates()
}
