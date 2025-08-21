//
//  AppContainer.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import SwiftUI

/// Main dependency injection container for the MimiSupply app
@MainActor
final class AppContainer: ObservableObject {
    // MARK: - Protocols
    
    let pushNotificationService: PushNotificationService
    let googlePlacesService: GooglePlacesService
    
    // MARK: - Initialization
    
    init() {
        self.appRouter = AppRouter()
        self.appState = AppState()
        self.analytics = AnalyticsServiceImpl()
        self.authenticationService = AuthenticationServiceImpl.shared
        self.featureFlagService = FeatureFlagServiceImpl.shared
        self.cloudKitService = CloudKitServiceImpl.shared
        self.pushNotificationService = PushNotificationServiceImpl.shared
        self.googlePlacesService = GooglePlacesServiceImpl() // AND ADD THIS
        
        setupCloudKitSubscriptions()
    }
    
    // MARK: - Core Services
    let cloudKitService: CloudKitService
    let authenticationService: AuthenticationService
    let locationService: LocationService
    let paymentService: PaymentService
    let pushNotificationService: PushNotificationService
    let analyticsService: AnalyticsService
    let featureFlagService: FeatureFlagService
    let keychainService: KeychainService
    let driverService: DriverService
    let cartService: CartService
    
    // MARK: - Repositories
    let orderRepository: OrderRepository
    let partnerRepository: PartnerRepository
    let productRepository: ProductRepository
    let userRepository: UserRepository
    
    // MARK: - Business Logic Managers
    let orderManager: OrderManager
    lazy var appRouter: AppRouter = AppRouter(container: self)
    
    private init() {
        // Initialize keychain service first (needed by other services)
        self.keychainService = KeychainServiceImpl()
        
        // Initialize base services
        self.cloudKitService = CloudKitServiceImpl()
        self.locationService = LocationServiceImpl()
        self.analyticsService = AnalyticsServiceImpl()
        self.paymentService = PaymentServiceImpl()
        
        // Initialize cart service
        self.cartService = CartService.shared
        
        // Initialize authentication service with dependencies
        self.authenticationService = AuthenticationServiceImpl(
            keychainService: keychainService,
            cloudKitService: cloudKitService
        )
        
        // Initialize services that need dependencies
        self.pushNotificationService = PushNotificationServiceImpl(
            cloudKitService: cloudKitService,
            authenticationService: authenticationService
        )
        
        self.featureFlagService = FeatureFlagServiceImpl(
            cloudKitService: cloudKitService,
            analyticsService: analyticsService
        )
        
        self.driverService = DriverServiceImpl(
            cloudKitService: cloudKitService,
            locationService: locationService,
            authenticationService: authenticationService
        )
        
        // Initialize repositories
        self.orderRepository = OrderRepositoryImpl(cloudKitService: cloudKitService)
        self.partnerRepository = PartnerRepositoryImpl(cloudKitService: cloudKitService)
        self.productRepository = ProductRepositoryImpl(cloudKitService: cloudKitService)
        self.userRepository = UserRepositoryImpl(
            cloudKitService: cloudKitService,
            keychainService: keychainService
        )
        
        // Initialize business logic managers
        self.orderManager = OrderManager(
            orderRepository: orderRepository,
            driverService: driverService,
            paymentService: paymentService,
            cloudKitService: cloudKitService,
            pushNotificationService: pushNotificationService,
            locationService: locationService
        )
    }
}