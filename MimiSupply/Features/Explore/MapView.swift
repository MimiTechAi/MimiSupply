import SwiftUI
import MapKit
import CoreLocation
import Combine

struct MapView: View {
    let partners: [Partner]
    @State private var region: MKCoordinateRegion
    @State private var selectedPartner: Partner?
    @StateObject private var locationManager: MapLocationManager
    @EnvironmentObject private var router: AppRouter
    
    init(partners: [Partner]) {
        self.partners = partners
        self._locationManager = StateObject(wrappedValue: MapLocationManager())
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050), // Default Berlin
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: $region, annotationItems: partners) { partner in
                MapAnnotation(coordinate: partner.location) {
                    PartnerMapAnnotation(
                        partner: partner,
                        isSelected: selectedPartner?.id == partner.id
                    ) {
                        withAnimation {
                            selectedPartner = partner
                        }
                    }
                }
            }
            .mapControls {
                 MapUserLocationButton()
                 MapCompass()
                 MapScaleView()
             }
            .ignoresSafeArea()
            .onAppear {
                Task {
                    await locationManager.requestLocationPermission()
                    if let userLocation = locationManager.currentLocation {
                        updateRegion(for: userLocation)
                    }
                }
            }
            
            if let selectedPartner = selectedPartner {
                SelectedPartnerCard(
                    partner: selectedPartner,
                    onDismiss: {
                        withAnimation {
                            self.selectedPartner = nil
                        }
                    },
                    onNavigate: {
                        router.push(.partnerDetail(selectedPartner))
                    }
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
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

// MARK: - Supporting Views for MapView
struct PartnerMapAnnotation: View {
    let partner: Partner
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.emerald : Color.white)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: partner.category.iconName)
                    .font(.system(size: isSelected ? 20 : 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .emerald)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct SelectedPartnerCard: View {
    let partner: Partner
    let onDismiss: () -> Void
    let onNavigate: () -> Void
    
    var body: some View {
        AppCard {
            HStack(spacing: Spacing.md) {
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
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.warning)
                                .font(.caption)
                            Text(String(format: "%.1f", partner.rating))
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                        
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
                    
                    Button(action: onNavigate) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.emerald)
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// Subviews bleiben gleich

@MainActor
class MapLocationManager: ObservableObject {
    private let locationService: LocationService
    @Published var currentLocation: CLLocation?
    private var cancellable: AnyCancellable?

    init(locationService: LocationService = LocationServiceImpl.shared) {
        self.locationService = locationService
        cancellable = (locationService as? LocationServiceImpl)?.$currentLocation.sink { [weak self] location in
            self?.currentLocation = location
        }
    }
    
    func requestLocationPermission() async {
        do {
            try await locationService.requestLocationPermission()
        } catch {
            print("Failed to request location permission: \(error)")
        }
    }
}

#Preview {
    // Re-add your preview content here if needed, with environment objects
    Text("MapView Preview")
}