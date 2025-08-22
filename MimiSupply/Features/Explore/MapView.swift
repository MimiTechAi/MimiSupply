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