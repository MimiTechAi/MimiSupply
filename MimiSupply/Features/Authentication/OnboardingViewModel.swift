import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var showingLocationPermission = false
    
    func handleLocationPermissionGranted() {
        // Handle what happens after permission is granted
        showingLocationPermission = false
    }
    
    func requestLocationPermission() {
        showingLocationPermission = true
    }
}