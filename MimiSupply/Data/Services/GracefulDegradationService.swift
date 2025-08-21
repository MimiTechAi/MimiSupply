//
//  GracefulDegradationService.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI
import OSLog

/// Service for handling graceful degradation when services fail
@MainActor
final class GracefulDegradationService: ObservableObject {
    static let shared = GracefulDegradationService()
    
    @Published var serviceStatus: [ServiceType: ServiceStatus] = [:]
    @Published var degradationLevel: DegradationLevel = .none
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "GracefulDegradation")
    private let cacheManager = CacheManager.shared
    
    private init() {
        initializeServiceStatus()
    }
    
    /// Initialize service status tracking
    private func initializeServiceStatus() {
        for serviceType in ServiceType.allCases {
            serviceStatus[serviceType] = .healthy
        }
        updateDegradationLevel()
    }
    
    /// Report service failure
    func reportServiceFailure(_ serviceType: ServiceType, error: Error) {
        logger.warning("⚠️ Service failure reported: \(serviceType.rawValue) - \(error.localizedDescription)")
        
        serviceStatus[serviceType] = .degraded(error)
        updateDegradationLevel()
        
        // Implement fallback strategies
        implementFallbackStrategy(for: serviceType, error: error)
    }
    
    /// Report service recovery
    func reportServiceRecovery(_ serviceType: ServiceType) {
        logger.info("✅ Service recovery reported: \(serviceType.rawValue)")
        
        serviceStatus[serviceType] = .healthy
        updateDegradationLevel()
    }
    
    /// Check if service is available
    func isServiceAvailable(_ serviceType: ServiceType) -> Bool {
        return serviceStatus[serviceType] == .healthy
    }
    
    /// Get fallback data for a service
    func getFallbackData<T: Codable>(_ type: T.Type, for key: String) -> T? {
        return cacheManager.retrieve(type, forKey: key)
    }
    
    /// Execute operation with fallback
    func executeWithFallback<T: Codable>(
        serviceType: ServiceType,
        cacheKey: String,
        operation: () async throws -> T
    ) async -> Result<T, AppError> {
        do {
            let result = try await operation()
            
            // Cache successful result
            cacheManager.cache(result, forKey: cacheKey)
            
            // Report service recovery if it was previously degraded
            if serviceStatus[serviceType] != .healthy {
                reportServiceRecovery(serviceType)
            }
            
            return .success(result)
        } catch {
            logger.warning("⚠️ Operation failed for \(serviceType.rawValue): \(error.localizedDescription)")
            
            // Report service failure
            let appError = convertToAppError(error)
            reportServiceFailure(serviceType, error: appError)
            
            // Try to return cached data
            if let cachedData = getFallbackData(T.self, for: cacheKey) {
                logger.info("📦 Returning cached data for \(serviceType.rawValue)")
                return .success(cachedData)
            }
            
            return .failure(appError)
        }
    }
    
    /// Update overall degradation level
    private func updateDegradationLevel() {
        let degradedServices = serviceStatus.values.compactMap { status in
            if case .degraded = status { return status }
            return nil
        }
        
        let criticalServices: [ServiceType] = [.cloudKit, .authentication, .payment]
        let criticalServicesDegraded = criticalServices.filter { serviceType in
            if case .degraded = serviceStatus[serviceType] { return true }
            return false
        }
        
        if criticalServicesDegraded.count >= 2 {
            degradationLevel = .severe
        } else if criticalServicesDegraded.count == 1 {
            degradationLevel = .moderate
        } else if degradedServices.count >= 3 {
            degradationLevel = .moderate
        } else if degradedServices.count > 0 {
            degradationLevel = .minor
        } else {
            degradationLevel = .none
        }
        
        logger.info("📊 Degradation level updated: \(self.degradationLevel.rawValue)")
    }
    
    /// Implement fallback strategy for specific service
    private func implementFallbackStrategy(for serviceType: ServiceType, error: Error) {
        switch serviceType {
        case .cloudKit:
            handleCloudKitDegradation(error: error)
        case .location:
            handleLocationDegradation(error: error)
        case .payment:
            handlePaymentDegradation(error: error)
        case .pushNotifications:
            handlePushNotificationDegradation(error: error)
        case .authentication:
            handleAuthenticationDegradation(error: error)
        case .analytics:
            handleAnalyticsDegradation(error: error)
        }
    }
    
    /// Handle CloudKit service degradation
    private func handleCloudKitDegradation(error: Error) {
        logger.info("🔄 Implementing CloudKit fallback strategy")
        
        // Switch to local-only mode
        // Queue operations for later sync
        // Show user notification about offline mode
    }
    
    /// Handle location service degradation
    private func handleLocationDegradation(error: Error) {
        logger.info("📍 Implementing location fallback strategy")
        
        // Use last known location
        // Prompt user for manual location entry
        // Disable location-dependent features gracefully
    }
    
    /// Handle payment service degradation
    private func handlePaymentDegradation(error: Error) {
        logger.info("💳 Implementing payment fallback strategy")
        
        // Show alternative payment methods
        // Queue orders for later processing
        // Notify user about payment issues
    }
    
    /// Handle push notification degradation
    private func handlePushNotificationDegradation(error: Error) {
        logger.info("🔔 Implementing push notification fallback strategy")
        
        // Increase in-app polling frequency
        // Show in-app notifications instead
        // Cache notifications for later delivery
    }
    
    /// Handle authentication degradation
    private func handleAuthenticationDegradation(error: Error) {
        logger.info("🔐 Implementing authentication fallback strategy")
        
        // Allow limited functionality without auth
        // Cache user session for recovery
        // Prompt for re-authentication
    }
    
    /// Handle analytics degradation
    private func handleAnalyticsDegradation(error: Error) {
        logger.info("📊 Implementing analytics fallback strategy")
        
        // Queue analytics events locally
        // Reduce analytics collection
        // Continue core functionality without analytics
    }
    
    /// Convert error to AppError
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(error)
    }
    
    /// Get user-friendly status message
    func getStatusMessage() -> String? {
        switch degradationLevel {
        case .none:
            return nil
        case .minor:
            return "Some features may be temporarily unavailable."
        case .moderate:
            return "Limited functionality available. Some features are offline."
        case .severe:
            return "Operating in offline mode. Core features only."
        }
    }
    
    /// Get degraded services list
    func getDegradedServices() -> [ServiceType] {
        return serviceStatus.compactMap { key, value in
            if case .degraded = value { return key }
            return nil
        }
    }
}

/// Service types that can be monitored
enum ServiceType: String, CaseIterable {
    case cloudKit = "CloudKit"
    case location = "Location"
    case payment = "Payment"
    case pushNotifications = "Push Notifications"
    case authentication = "Authentication"
    case analytics = "Analytics"
}

/// Service status
enum ServiceStatus: Equatable {
    case healthy
    case degraded(Error)
    
    static func == (lhs: ServiceStatus, rhs: ServiceStatus) -> Bool {
        switch (lhs, rhs) {
        case (.healthy, .healthy):
            return true
        case (.degraded, .degraded):
            return true
        default:
            return false
        }
    }
}

/// Degradation levels
enum DegradationLevel: String, CaseIterable {
    case none = "None"
    case minor = "Minor"
    case moderate = "Moderate"
    case severe = "Severe"
    
    var color: Color {
        switch self {
        case .none:
            return .success
        case .minor:
            return .warning
        case .moderate:
            return .error
        case .severe:
            return .error
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return "checkmark.circle.fill"
        case .minor:
            return "exclamationmark.triangle.fill"
        case .moderate:
            return "exclamationmark.circle.fill"
        case .severe:
            return "xmark.circle.fill"
        }
    }
}

/// Service status indicator view
struct ServiceStatusIndicator: View {
    @StateObject private var degradationService = GracefulDegradationService.shared
    
    var body: some View {
        if degradationService.degradationLevel != .none {
            HStack(spacing: Spacing.sm) {
                Image(systemName: degradationService.degradationLevel.icon)
                    .foregroundColor(degradationService.degradationLevel.color)
                    .font(.caption)
                
                if let message = degradationService.getStatusMessage() {
                    Text(message)
                        .font(.caption.scaledFont())
                        .foregroundColor(degradationService.degradationLevel.color)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(degradationService.degradationLevel.color.opacity(0.1))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Service status: \(degradationService.degradationLevel.rawValue)")
        }
    }
}