//
//  MimiSupplyApp.swift
//  MimiSupply
//
//  Created by Michael Bemler on 13.08.25.
//

import SwiftUI
import CloudKit
import GooglePlaces

@main
struct MimiSupplyApp: App {
    
    @StateObject private var container = AppContainer.shared
    @StateObject private var appState = AppState()
    @StateObject private var router = AppContainer.shared.appRouter
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var analyticsManager = AnalyticsManager.shared
    
    // Error handling and offline support
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var degradationService = GracefulDegradationService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // Performance optimization services
    @StateObject private var startupOptimizer = StartupOptimizer.shared
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var backgroundTaskManager = BackgroundTaskManager.shared
    
    init() {
        // Configure Google Places API Key
        GMSPlacesClient.provideAPIKey(APIKeyManager.getGooglePlacesAPIKey())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environmentObject(appState)
                .environmentObject(router)
                .environmentObject(navigationManager)
                .environmentObject(analyticsManager)
                .environmentObject(errorHandler)
                .environmentObject(offlineManager)
                .environmentObject(degradationService)
                .environmentObject(networkMonitor)
                .environmentObject(startupOptimizer)
                .environmentObject(memoryManager)
                .environmentObject(backgroundTaskManager)
                .environment(\.analytics, analyticsManager.analytics)
                .environment(\.featureFlags, analyticsManager.featureFlags)
                .onOpenURL { url in
                    router.handleUniversalLink(url)
                }
                .persistNavigationState(router: router)
                .handleErrors() // Global error handling
                .errorToasts() // Toast-style error notifications
                .optimizeStartup() // Performance optimization
                .memoryEfficient() // Memory management
                .task {
                    await setupApp()
                }
                .onAppear {
                    navigationManager.restoreNavigationState(to: router)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    handleAppDidEnterBackground()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    handleAppWillEnterForeground()
                }
        }
        .backgroundTask(.appRefresh("com.mimisupply.location-update")) {
            await handleBackgroundLocationUpdate()
        }
        .backgroundTask(.appRefresh("com.mimisupply.data-sync")) {
            await handleBackgroundDataSync()
        }
        .backgroundTask(.appRefresh("com.mimisupply.cleanup")) {
            await handleBackgroundCleanup()
        }
    }
    
    private func handleBackgroundLocationUpdate() async {
        do {
            try await backgroundTaskManager.updateDriverLocation()
        } catch {
            errorHandler.handle(error, showToUser: false, context: "background_location_update")
        }
    }
    
    private func handleBackgroundDataSync() async {
        do {
            try await backgroundTaskManager.syncPendingData()
        } catch {
            errorHandler.handle(error, showToUser: false, context: "background_data_sync")
        }
    }
    
    private func handleBackgroundCleanup() async {
        await backgroundTaskManager.performCleanup()
    }
    
    private func setupApp() async {
        // Initialize performance optimization first
        await startupOptimizer.performStartupInitialization()
        
        // Initialize analytics and monitoring
        analyticsManager.configure()
        
        // Initialize error handling system
        await initializeErrorHandling()
        
        // Request notification permissions with error handling
        await setupNotifications()
        
        // Setup CloudKit subscriptions if user is authenticated
        await setupCloudKitSubscriptions()
        
        // Initialize offline sync if needed
        await initializeOfflineSync()
        
        // Schedule background tasks
        setupBackgroundTasks()
    }
    
    private func initializeErrorHandling() async {
        // Initialize service status monitoring
        degradationService.serviceStatus = [
            .cloudKit: .healthy,
            .location: .healthy,
            .payment: .healthy,
            .pushNotifications: .healthy,
            .authentication: .healthy,
            .analytics: .healthy
        ]
        
        // Start monitoring network connectivity
        // NetworkMonitor is automatically initialized and starts monitoring
    }
    
    private func setupNotifications() async {
        do {
            let granted = try await container.pushNotificationService.requestNotificationPermission()
            if granted {
                try await container.pushNotificationService.registerForRemoteNotifications()
                degradationService.reportServiceRecovery(.pushNotifications)
            } else {
                degradationService.reportServiceFailure(.pushNotifications, 
                                                       error: AppError.validation(.requiredFieldMissing("Notification permission")))
            }
        } catch {
            errorHandler.handle(error, showToUser: false, context: "setup_notifications")
            degradationService.reportServiceFailure(.pushNotifications, error: error)
            analyticsManager.trackError(error, context: ["action": .string("setup_notifications")])
        }
    }
    
    private func setupCloudKitSubscriptions() async {
        guard await container.authenticationService.isAuthenticated,
              let user = await container.authenticationService.currentUser else {
            return
        }
        
        do {
            try await container.cloudKitService.subscribeToOrderUpdates(for: user.id)
            degradationService.reportServiceRecovery(.cloudKit)
        } catch {
            errorHandler.handle(error, showToUser: false, context: "setup_cloudkit_subscriptions")
            degradationService.reportServiceFailure(.cloudKit, error: error)
            analyticsManager.trackError(error, context: ["action": .string("setup_cloudkit_subscriptions")])
        }
    }
    
    private func initializeOfflineSync() async {
        // Check if there are pending sync operations from previous sessions
        if offlineManager.pendingSyncCount > 0 {
            // Attempt to sync if online
            if networkMonitor.isConnected {
                await offlineManager.forceSyncNow()
            }
        }
    }
    
    private func setupBackgroundTasks() {
        backgroundTaskManager.scheduleDataSync()
        backgroundTaskManager.scheduleCleanup()
    }
    
    private func handleAppDidEnterBackground() {
        // Schedule background tasks
        backgroundTaskManager.scheduleLocationUpdate()
        backgroundTaskManager.scheduleDataSync()
        backgroundTaskManager.scheduleCleanup()
        
        // Begin background task for immediate operations
        backgroundTaskManager.beginBackgroundTask()
        
        // Log startup metrics
        startupOptimizer.logStartupMetrics()
    }
    
    private func handleAppWillEnterForeground() {
        // End background task
        backgroundTaskManager.endBackgroundTask()
        
        // Refresh data if needed
        Task {
            if !startupOptimizer.isInitialized {
                await startupOptimizer.performStartupInitialization()
            }
        }
    }
}