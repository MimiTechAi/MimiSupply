//
//  MapView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import MapKit
import CoreLocation

/// MapKit integration for partner discovery and location visualization
struct MapView: View {
    let partners: [Partner]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to SF
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedPartner: Partner?
    @StateObject private var locationManager = MapLocationManager()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: .constant(.region(region))) {
                UserAnnotation()
                
                ForEach(partners) { partner in
                    Annotation(partner.name, coordinate: partner.location) {
                        PartnerMapAnnotation(
                            partner: partner,
                            isSelected: selectedPartner?.id == partner.id
                        ) {
                            selectedPartner = partner
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                Task {
                    await locationManager.requestLocationPermission()
                    if let userLocation = await locationManager.getCurrentLocation() {
                        updateRegion(for: userLocation)
                    }
                }
            }
            
            // Selected partner card
            if let selectedPartner = selectedPartner {
                SelectedPartnerCard(partner: selectedPartner) {
                    self.selectedPartner = nil
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: selectedPartner)
            }
        }
    }
    
    private func updateRegion(for location: CLLocation) {
        withAnimation(.easeInOut(duration: 1.0)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

/// Custom map annotation for partners
struct PartnerMapAnnotation: View {
    let partner: Partner
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isSelected ? Color.emerald : Color.white)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Category icon
                Image(systemName: partner.category.iconName)
                    .font(.system(size: isSelected ? 20 : 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .emerald)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

/// Card showing selected partner details on map
struct SelectedPartnerCard: View {
    let partner: Partner
    let onDismiss: () -> Void
    
    var body: some View {
        AppCard {
            HStack(spacing: Spacing.md) {
                // Partner image placeholder
                AsyncImage(url: partner.logoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray200)
                        .overlay(
                            Image(systemName: partner.category.iconName)
                                .foregroundColor(.gray400)
                                .font(.title2)
                        )
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(partner.name)
                        .font(.titleMedium)
                        .foregroundColor(.graphite)
                        .lineLimit(1)
                    
                    Text(partner.category.displayName)
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                    
                    HStack(spacing: Spacing.md) {
                        // Rating
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.warning)
                                .font(.caption)
                            Text(String(format: "%.1f", partner.rating))
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                        
                        // Delivery time
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "clock")
                                .foregroundColor(.gray500)
                                .font(.caption)
                            Text("\(partner.estimatedDeliveryTime) min")
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                VStack(spacing: Spacing.sm) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray500)
                            .font(.caption)
                    }
                    
                    Button(action: {
                        // Navigate to partner detail
                    }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.emerald)
                            .font(.title2)
                    }
                }
            }
        }
        .accessibilityLabel("\(partner.name), \(partner.category.displayName), \(partner.rating) stars, \(partner.estimatedDeliveryTime) minutes delivery")
        .accessibilityHint("Double tap to view partner details")
    }
}

/// Location manager for map functionality
@MainActor
class MapLocationManager: ObservableObject {
    private let locationService: LocationService
    
    init(locationService: LocationService = LocationServiceImpl()) {
        self.locationService = locationService
    }
    
    func requestLocationPermission() async {
        do {
            try await locationService.requestLocationPermission()
        } catch {
            print("Failed to request location permission: \(error)")
        }
    }
    
    func getCurrentLocation() async -> CLLocation? {
        return await locationService.currentLocation
    }
}

#Preview {
    MapView(partners: [
        Partner(
            name: "Bella Vista Restaurant",
            category: .restaurant,
            description: "Italian cuisine",
            address: Address(street: "123 Main St", city: "San Francisco", state: "CA", postalCode: "94102", country: "US"),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "info@bellavista.com",
            rating: 4.8,
            reviewCount: 120,
            estimatedDeliveryTime: 25
        ),
        Partner(
            name: "Fresh Market",
            category: .grocery,
            description: "Organic groceries",
            address: Address(street: "456 Oak St", city: "San Francisco", state: "CA", postalCode: "94102", country: "US"),
            location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            phoneNumber: "+1234567891",
            email: "info@freshmarket.com",
            rating: 4.6,
            reviewCount: 89,
            estimatedDeliveryTime: 15
        )
    ])
}