import Foundation

@MainActor
final class AppContainer: ObservableObject {
    static let shared = AppContainer()
    
    // MARK: - Services
    let appRouter: AppRouter
    let appState: AppState
    let analytics: AnalyticsService
    let authenticationService: AuthenticationService
    let featureFlagService: FeatureFlagService
    let cloudKitService: CloudKitService
    let pushNotificationService: PushNotificationService
    let googlePlacesService: GooglePlacesService
    let locationService: LocationService

    private init() {
        self.appState = AppState()
        self.analytics = AnalyticsServiceImpl()
        self.authenticationService = AuthenticationServiceImpl.shared
        self.cloudKitService = CloudKitServiceImpl.shared
        self.pushNotificationService = PushNotificationServiceImpl()
        self.googlePlacesService = GooglePlacesServiceImpl()
        self.locationService = LocationServiceImpl.shared
        
        // Services that depend on other services
        self.featureFlagService = FeatureFlagServiceImpl(cloudKitService: self.cloudKitService, analyticsService: self.analytics)
        self.appRouter = AppRouter(container: self)
        
        setupCloudKitSubscriptions()
    }
    
    private func setupCloudKitSubscriptions() {
        Task {
            do {
                try await (pushNotificationService as? PushNotificationServiceImpl)?.subscribeToOrderUpdates()
                try await (pushNotificationService as? PushNotificationServiceImpl)?.subscribeToGeneralNotifications()
            } catch {
                print("Failed to setup CloudKit subscriptions: \(error.localizedDescription)")
            }
        }
    }
}