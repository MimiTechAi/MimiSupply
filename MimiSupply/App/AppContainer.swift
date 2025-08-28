import Foundation

@MainActor
final class AppContainer: ObservableObject {
    static let shared = AppContainer()
    
    // MARK: - Services
    let appState: AppState
    let analytics: AnalyticsService
    let authenticationService: AuthenticationService
    let featureFlagService: FeatureFlagService
    let cloudKitService: CloudKitService
    let pushNotificationService: PushNotificationService
    let googlePlacesService: GooglePlacesService
    let locationService: any LocationService
    let paymentService: PaymentService
    let driverService: DriverService
    
    // Services that depend on other services (lazy)
    lazy var appRouter: AppRouter = AppRouter(container: self)

    private init() {
        // Initialize all basic services first
        self.appState = AppState()
        self.analytics = AnalyticsServiceImpl()
        self.authenticationService = AuthenticationServiceImpl.shared
        self.cloudKitService = CloudKitServiceImpl.shared
        self.pushNotificationService = PushNotificationServiceImpl(
            cloudKitService: CloudKitServiceImpl.shared,
            authenticationService: AuthenticationServiceImpl.shared
        )
        self.googlePlacesService = GooglePlacesServiceImpl()
        self.locationService = LocationServiceImpl.shared
        self.paymentService = PaymentServiceImpl()
        self.driverService = DriverServiceImpl()
        
        // Services that depend on other services
        self.featureFlagService = FeatureFlagServiceImpl(
            cloudKitService: self.cloudKitService,
            analyticsService: self.analytics
        )
        
        setupCloudKitSubscriptions()
    }
    
    private func setupCloudKitSubscriptions() {
        Task {
            do {
                try await pushNotificationService.subscribeToOrderUpdates()
                try await pushNotificationService.subscribeToGeneralNotifications()
            } catch {
                print("Failed to setup CloudKit subscriptions: \(error.localizedDescription)")
            }
        }
    }
}