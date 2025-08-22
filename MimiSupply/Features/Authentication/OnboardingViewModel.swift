import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var showingLocationPermission = false
    
    var onComplete: (() -> Void)?
    
    func handleLocationPermissionGranted() {
        showingLocationPermission = false
        onComplete?() // CALL COMPLETION
    }
    
    func requestLocationPermission() {
        showingLocationPermission = true
    }
}