//
//  OrderTrackingMapView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import MapKit

/// Map view for real-time order tracking with driver location
struct OrderTrackingMapView: View {
    let deliveryLocation: Address
    let driverLocation: DriverLocation?
    let orderStatus: OrderStatus
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
            MapPin(coordinate: annotation.coordinate, tint: annotation.type == .delivery ? .green : .blue)
        }
        .onAppear {
            setupMapRegion()
        }
        .onChange(of: driverLocation) { _ in
            updateMapRegion()
        }
    }
    
    private var mapAnnotations: [TrackingMapAnnotation] {
        var annotations: [TrackingMapAnnotation] = []
        
        // Add delivery location
        if let coordinate = geocodeAddress(deliveryLocation) {
            annotations.append(TrackingMapAnnotation(
                id: "delivery",
                coordinate: coordinate,
                type: .delivery,
                title: "Delivery Location"
            ))
        }
        
        // Add driver location if available
        if let driverLoc = driverLocation {
            annotations.append(TrackingMapAnnotation(
                id: "driver",
                coordinate: driverLoc.location.clLocationCoordinate2D,
                type: .driver,
                title: "Driver"
            ))
        }
        
        return annotations
    }
    
    private func setupMapRegion() {
        if let deliveryCoordinate = geocodeAddress(deliveryLocation) {
            region = MKCoordinateRegion(
                center: deliveryCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func updateMapRegion() {
        guard let driverLoc = driverLocation else { return }
        
        let deliveryCoordinate = geocodeAddress(deliveryLocation) ?? region.center
        
        // Calculate region that includes both driver and delivery location
        let minLat = min(driverLoc.location.latitude, deliveryCoordinate.latitude)
        let maxLat = max(driverLoc.location.latitude, deliveryCoordinate.latitude)
        let minLon = min(driverLoc.location.longitude, deliveryCoordinate.longitude)
        let maxLon = max(driverLoc.location.longitude, deliveryCoordinate.longitude)
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )
        
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
    
    private func geocodeAddress(_ address: Address) -> CLLocationCoordinate2D? {
        // In a real implementation, this would use CLGeocoder to convert address to coordinates
        // For now, return a mock coordinate
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
}


// MARK: - Supporting Types

struct TrackingMapAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let type: MapMarkerType
    let title: String
}

enum MapMarkerType {
    case delivery
    case driver
}

// MARK: - Preview

#if DEBUG
struct OrderTrackingMapView_Previews: PreviewProvider {
    static var previews: some View {
        OrderTrackingMapView(
            deliveryLocation: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            ),
            driverLocation: DriverLocation(
                driverId: "driver123",
                location: Coordinate(latitude: 37.7849, longitude: -122.4094),
                accuracy: 5.0
            ),
            orderStatus: .delivering
        )
        .frame(height: 300)
    }
}
#endif
