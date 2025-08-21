//
//  LocationPermissionView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import CoreLocation

/// Location permission request view with clear user prompts and explanations
struct LocationPermissionView: View {
    let permissionType: LocationPermissionType
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void
    
    @StateObject private var locationManager = LocationPermissionManager()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: permissionType.iconName)
                .font(.system(size: 80))
                .foregroundColor(.emerald)
            
            VStack(spacing: Spacing.md) {
                Text(permissionType.title)
                    .font(.headlineSmall)
                    .foregroundColor(.graphite)
                    .multilineTextAlignment(.center)
                
                Text(permissionType.description)
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
            }
            
            // Benefits list
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(permissionType.benefits, id: \.self) { benefit in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                            .font(.body)
                        
                        Text(benefit)
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: Spacing.md) {
                PrimaryButton(
                    title: permissionType.primaryButtonTitle,
                    action: requestPermission,
                    isLoading: locationManager.isRequestingPermission,
                    isDisabled: false
                )
                
                if locationManager.authorizationStatus == .denied {
                    SecondaryButton(
                        title: "Open Settings",
                        action: { showingSettings = true }
                    )
                }
                
                Button("Not Now") {
                    onPermissionDenied()
                }
                .font(.bodyMedium)
                .foregroundColor(.gray600)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            handleAuthorizationChange(status)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsRedirectView()
        }
    }
    
    private func requestPermission() {
        Task {
            await locationManager.requestPermission(type: permissionType)
        }
    }
    
    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            onPermissionGranted()
        case .denied, .restricted:
            // Stay on this view to show settings option
            break
        case .notDetermined:
            // Still waiting for user decision
            break
        @unknown default:
            onPermissionDenied()
        }
    }
}

/// Types of location permissions we might request
enum LocationPermissionType {
    case whenInUse
    case always
    
    var title: String {
        switch self {
        case .whenInUse:
            return "Enable Location Services"
        case .always:
            return "Enable Background Location"
        }
    }
    
    var description: String {
        switch self {
        case .whenInUse:
            return "We use your location to show nearby restaurants and stores, and to provide accurate delivery estimates."
        case .always:
            return "To provide real-time delivery tracking and ensure drivers can find you, we need location access even when the app is in the background."
        }
    }
    
    var benefits: [String] {
        switch self {
        case .whenInUse:
            return [
                "Find nearby restaurants and stores",
                "Get accurate delivery estimates",
                "Automatic address suggestions",
                "Better search results"
            ]
        case .always:
            return [
                "Real-time delivery tracking",
                "Automatic driver updates",
                "Background location sharing for drivers",
                "Seamless delivery experience"
            ]
        }
    }
    
    var iconName: String {
        switch self {
        case .whenInUse:
            return "location.circle"
        case .always:
            return "location.circle.fill"
        }
    }
    
    var primaryButtonTitle: String {
        switch self {
        case .whenInUse:
            return "Allow Location Access"
        case .always:
            return "Allow Background Location"
        }
    }
}

/// Location permission manager
@MainActor
class LocationPermissionViewModel: ObservableObject {
    private let locationService: LocationService
    
    @MainActor // Add this annotation
    init(locationService: LocationService = LocationServiceImpl.shared) {
        self.locationService = locationService
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
}

/// Location permission manager
@MainActor
class LocationPermissionManager: ObservableObject {
    @Published var isRequestingPermission = false
    
    private let locationService: LocationService
    
    init(locationService: LocationService = LocationServiceImpl()) {
        self.locationService = locationService
    }
    
    func requestPermission(type: LocationPermissionType) async {
        isRequestingPermission = true
        
        do {
            try await locationService.requestLocationPermission()
        } catch {
            print("Failed to request location permission: \(error)")
        }
        
        isRequestingPermission = false
    }
}

/// Settings redirect view
struct SettingsRedirectView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.xl) {
                Spacer()
                
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.emerald)
                
                VStack(spacing: Spacing.md) {
                    Text("Open Settings")
                        .font(.headlineSmall)
                        .foregroundColor(.graphite)
                    
                    Text("To enable location services, please go to Settings > Privacy & Security > Location Services and allow access for MimiSupply.")
                        .font(.bodyMedium)
                        .foregroundColor(.gray600)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                
                Spacer()
                
                VStack(spacing: Spacing.md) {
                    PrimaryButton(
                        title: "Open Settings",
                        action: openSettings,
                        isLoading: false,
                        isDisabled: false
                    )
                    
                    SecondaryButton(
                        title: "Cancel",
                        action: { dismiss() }
                    )
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Location Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        dismiss()
    }
}

#Preview("When In Use Permission") {
    LocationPermissionView(
        permissionType: .whenInUse,
        onPermissionGranted: { print("Permission granted") },
        onPermissionDenied: { print("Permission denied") }
    )
}

#Preview("Always Permission") {
    LocationPermissionView(
        permissionType: .always,
        onPermissionGranted: { print("Permission granted") },
        onPermissionDenied: { print("Permission denied") }
    )
}