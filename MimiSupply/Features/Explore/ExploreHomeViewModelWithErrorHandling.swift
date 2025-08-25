//
//  ExploreHomeViewModelWithErrorHandling.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI
import MapKit
import OSLog
import Combine
import CloudKit

/// Enhanced ExploreHomeViewModel with comprehensive error handling
@MainActor
final class ExploreHomeViewModelWithErrorHandling: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var partners: [Partner] = []
    @Published var featuredPartners: [Partner] = []
    @Published var categories: [PartnerCategory] = PartnerCategory.allCases
    @Published var searchText = ""
    @Published var selectedCategory: PartnerCategory?
    @Published var isLoading = false
    @Published var currentError: AppError?
    @Published var showingErrorState = false
    
    // Location and map
    @Published var currentRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Cart
    @Published var cartItemCount = 0
    
    // MARK: - Dependencies
    
    private let cloudKitService: CloudKitService
    private let locationService: LocationService
    private let cartService: CartServiceProtocol
    private let errorHandler = ErrorHandler.shared
    private let degradationService = GracefulDegradationService.shared
    private let offlineManager = OfflineManager.shared
    private let retryManager = RetryManager.shared
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "ExploreHomeViewModel")
    
    // MARK: - Initialization
    
    init(
        cloudKitService: CloudKitService? = nil,
        locationService: LocationService? = nil,
        cartService: CartServiceProtocol? = nil
    ) {
        // Use direct service implementations instead of AppContainer
        self.cloudKitService = cloudKitService ?? CloudKitServiceImpl.shared
        self.locationService = locationService ?? LocationServiceImpl.shared
        self.cartService = cartService ?? CartService.shared
        
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe cart changes
        Task {
            for await count in cartService.cartItemCountPublisher.values {
                cartItemCount = count
            }
        }
        
        // Observe search text changes
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task {
                    await self?.performSearch(searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Load initial data with comprehensive error handling
    func loadInitialData() async {
        logger.info("🔄 Loading initial explore data")
        
        await withErrorHandling("loadInitialData") {
            isLoading = true
            showingErrorState = false
            
            // Load location first
            await loadUserLocation()
            
            // Load partners with fallback to cached data
            await loadPartners()
            
            // Load featured partners
            await loadFeaturedPartners()
            
            isLoading = false
        }
    }
    
    /// Refresh data with pull-to-refresh
    func refreshData() async {
        logger.info("🔄 Refreshing explore data")
        
        await withErrorHandling("refreshData") {
            // Clear any previous errors
            currentError = nil
            showingErrorState = false
            
            // Force refresh from network
            await loadPartners(forceRefresh: true)
            await loadFeaturedPartners(forceRefresh: true)
        }
    }
    
    /// Retry failed operations
    func retryFailedOperation() async {
        logger.info("🔄 Retrying failed operation")
        
        await withErrorHandling("retryFailedOperation") {
            currentError = nil
            showingErrorState = false
            
            await loadInitialData()
        }
    }
    
    /// Select a partner
    func selectPartner(_ partner: Partner) {
        logger.info("👆 Selected partner: \(partner.name)")
        
        // Navigate to partner detail
        // This would integrate with the navigation system
        Task { @MainActor in
            AppContainer.shared.appRouter.navigateToPartnerDetail(partner)
        }
    }
    
    /// Filter partners by category
    func filterByCategory(_ category: PartnerCategory?) {
        selectedCategory = category
        
        // Apply filter to existing partners
        if let category = category {
            partners = partners.filter { $0.category == category }
        } else {
            // Reload all partners
            Task {
                await loadPartners()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load user's current location
    private func loadUserLocation() async {
        do {
            // Check if location services are available
            guard locationService.authorizationStatus != .denied else {
                logger.info("📍 Location permission denied, using default location")
                return
            }
            
            // Request permission if needed
            if locationService.authorizationStatus == .notDetermined {
                try await locationService.requestLocationPermission()
            }
            
            // Get current location
            if let location = await locationService.currentLocation {
                currentRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                logger.info("📍 Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
            
            degradationService.reportServiceRecovery(.location)
        } catch {
            logger.warning("⚠️ Failed to load location: \(error.localizedDescription)")
            degradationService.reportServiceFailure(.location, error: error)
            
            // Don't show error to user for location - just use default
            // Location is not critical for basic functionality
        }
    }
    
    /// Load partners in current region
    private func loadPartners(forceRefresh: Bool = false) async {
        do {
            let loadedPartners = try await cloudKitService.fetchPartners(in: currentRegion)
            partners = loadedPartners
            
            logger.info("✅ Loaded \(self.partners.count) partners")
            degradationService.reportServiceRecovery(.cloudKit)
        } catch {
            logger.error("❌ Failed to load partners: \(error.localizedDescription)")
            
            await handlePartnersLoadError(error)
        }
    }
    
    /// Load featured partners
    private func loadFeaturedPartners(forceRefresh: Bool = false) async {
        do {
            // Get all partners and filter for featured ones
            let allPartners = try await cloudKitService.fetchPartners(in: currentRegion)
            featuredPartners = allPartners
                .filter { $0.isVerified && $0.rating >= 4.5 }
                .sorted { $0.rating > $1.rating }
                .prefix(5)
                .map { $0 }
            
            logger.info("✅ Loaded \(self.featuredPartners.count) featured partners")
        } catch {
            logger.warning("⚠️ Failed to load featured partners: \(error.localizedDescription)")
            
            // Featured partners failure is not critical - don't show error
            // Just use empty array
            featuredPartners = []
        }
    }
    
    /// Perform search with error handling
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            await loadPartners()
            return
        }
        
        logger.info("🔍 Searching for: \(query)")
        
        await withErrorHandling("performSearch") {
            isLoading = true
            
            let searchResults = try await cloudKitService.searchProducts(query: query, in: currentRegion)
            
            // Extract unique partners from search results
            let partnerIds = Set(searchResults.map { $0.partnerId })
            partners = partners.filter { partnerIds.contains($0.id) }
            
            isLoading = false
            logger.info("✅ Search returned \(self.partners.count) partners")
        }
    }
    
    /// Handle partners load error with appropriate fallback
    private func handlePartnersLoadError(_ error: Error) async {
        let appError = convertToAppError(error)
        
        // Try to get cached partners
        if let cachedPartners: [Partner] = degradationService.getFallbackData([Partner].self, for: "partners_cache") {
            partners = cachedPartners
            logger.info("📦 Using cached partners (\(self.partners.count) items)")
            
            // Show toast notification about using cached data
            ErrorToastManager.shared.showToast(for: appError)
        } else {
            // No cached data available - show error state
            currentError = appError
            showingErrorState = true
            partners = []
            
            logger.error("❌ No cached partners available")
        }
        
        // Report service failure
        degradationService.reportServiceFailure(.cloudKit, error: appError)
    }
    
    /// Generic error handling wrapper
    private func withErrorHandling<T: Sendable>(
        _ operation: String,
        action: @Sendable () async throws -> T
    ) async -> T? {
        do {
            return try await action()
        } catch {
            let appError = convertToAppError(error)
            
            logger.error("❌ Operation '\(operation)' failed: \(appError.localizedDescription)")
            
            // Handle error based on type
            await handleError(appError, operation: operation)
            
            return nil
        }
    }
    
    /// Handle different types of errors appropriately
    private func handleError(_ error: AppError, operation: String) async {
        switch error {
        case .network(.noConnection):
            // Network error - show toast and use cached data if available
            ErrorToastManager.shared.showToast(for: error)
            
        case .cloudKit:
            // CloudKit error - might be temporary, show retry option
            currentError = error
            showingErrorState = true
            
        case .location:
            // Location error - not critical, just log
            logger.warning("⚠️ Location error in \(operation): \(error.localizedDescription)")
            
        case .authentication:
            // Authentication error - might need to re-authenticate
            errorHandler.handle(error, showToUser: true, context: operation)
            
        default:
            // Other errors - show error state
            currentError = error
            showingErrorState = true
        }
        
        // Always report to error handler for logging and analytics
        errorHandler.handle(error, showToUser: false, context: operation)
    }
    
    /// Convert any error to AppError
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let ckError = error as? CKError {
            return .cloudKit(ckError)
        }
        
        if let urlError = error as? URLError {
            return .network(NetworkError.from(urlError))
        }
        
        return .unknown(error)
    }
}

// MARK: - Error Recovery Actions

extension ExploreHomeViewModelWithErrorHandling {
    
    /// Get appropriate recovery action for current error
    var errorRecoveryAction: (() -> Void)? {
        guard let error = currentError else { return nil }
        
        switch error {
        case .network, .cloudKit:
            return {
                Task {
                    await self.retryFailedOperation()
                }
            }
        default:
            return nil
        }
    }
    
    /// Get user-friendly error message
    var errorDisplayMessage: String {
        guard let error = currentError else { return "" }
        
        switch error {
        case .network(.noConnection):
            return "No internet connection. Please check your network and try again."
        case .cloudKit:
            return "Unable to load data. Please try again."
        default:
            return error.localizedDescription ?? "Something went wrong. Please try again."
        }
    }
    
    /// Check if retry is available for current error
    var canRetry: Bool {
        guard let error = currentError else { return false }
        
        switch error {
        case .network, .cloudKit:
            return true
        default:
            return false
        }
    }
}

// MARK: - Service Status Integration

extension ExploreHomeViewModelWithErrorHandling {
    
    /// Get current service status message
    var serviceStatusMessage: String? {
        return degradationService.getStatusMessage()
    }
    
    /// Check if app is in offline mode
    var isOfflineMode: Bool {
        return offlineManager.isOfflineMode
    }
    
    /// Get pending sync count
    var pendingSyncCount: Int {
        return offlineManager.pendingSyncCount
    }
}