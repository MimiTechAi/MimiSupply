//
//  Coordinate.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 15.08.25.
//

import Foundation
import CoreLocation

/// A Codable and Sendable wrapper for geographic coordinates.
public struct Coordinate: Codable, Sendable, Equatable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(_ clCoordinate: CLLocationCoordinate2D) {
        self.init(latitude: clCoordinate.latitude, longitude: clCoordinate.longitude)
    }

    /// Bridge to CoreLocation for MapKit interop
    public var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
