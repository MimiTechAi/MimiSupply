import SwiftUI
import CoreLocation

/// A view that guides the user through the location permission process.
struct LocationPermissionView: View {
    @StateObject private var viewModel: LocationPermissionViewModel
    var onPermissionGranted: () -> Void
    
    init(onPermissionGranted: @escaping () -> Void) {
        self.onPermissionGranted = onPermissionGranted
        self._viewModel = StateObject(wrappedValue: LocationPermissionViewModel())
    }
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            
            // Illustration or Icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.emerald)
                .padding(.bottom, Spacing.md)
            
            // Title
            Text("Enable Location Services")
                .font(.titleLarge)
                .fontWeight(.bold)
                .foregroundColor(.graphite)
                .multilineTextAlignment(.center)
            
            // Description
            Text("To discover partners near you, please allow MimiSupply to access your location.")
                .font(.bodyMedium)
                .foregroundColor(.gray600)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: Spacing.md) {
                PrimaryButton(title: "Allow Location Access", action: viewModel.requestPermission)
                    .accessibilityIdentifier("allow-location-button")
                
                Button("Maybe Later") {
                    // Handle dismissal or alternative flow
                }
                .font(.bodyMedium)
                .foregroundColor(.gray500)
            }
        }
        .padding(Spacing.xl)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .onReceive(viewModel.$permissionGranted) { granted in
            if granted {
                onPermissionGranted()
            }
        }
        .alert("Permission Denied", isPresented: $viewModel.showingPermissionDeniedAlert) {
            Button("Open Settings") {
                viewModel.openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Location access is required to find nearby partners. Please enable it in Settings.")
        }
    }
}

// MARK: - ViewModel

@MainActor
class LocationPermissionViewModel: ObservableObject {
    private let locationService: LocationService
    
    @Published var permissionGranted = false
    @Published var showingPermissionDeniedAlert = false
    
    @MainActor
    init(locationService: LocationService = LocationServiceImpl.shared) {
        self.locationService = locationService
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationService.authorizationStatus
    }
    
    func requestPermission() {
        Task {
            let granted = try await locationService.requestLocationPermission()
            if granted {
                permissionGranted = true
            } else {
                if authorizationStatus == .denied || authorizationStatus == .restricted {
                    showingPermissionDeniedAlert = true
                }
            }
        }
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

#Preview {
    LocationPermissionView(onPermissionGranted: {})
}