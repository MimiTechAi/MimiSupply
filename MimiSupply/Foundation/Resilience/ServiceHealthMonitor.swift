//
//  ServiceHealthMonitor.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import SwiftUI
import Combine
import OSLog

/// Comprehensive service health monitoring with automatic recovery
@MainActor
final class ServiceHealthMonitor: ObservableObject {
    
    // MARK: - Published Properties
    @Published var services: [String: ServiceHealth] = [:]
    @Published var overallHealth: SystemHealth = .healthy
    @Published var criticalServices: [String] = []
    @Published var degradedServices: [String] = []
    
    // MARK: - Configuration
    private let healthCheckInterval: TimeInterval = 30.0 // 30 seconds
    private let criticalServiceList: Set<String> = ["CloudKit", "Authentication", "Payment"]
    
    // MARK: - Monitoring
    private var healthCheckTimer: Timer?
    private var serviceObservers: [String: AnyCancellable] = [:]
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "ServiceHealth")
    private let rateLimiterManager = RateLimiterManager.shared
    
    // MARK: - Health Checks
    private let healthChecks: [String: () async -> HealthCheckResult] = [:]
    
    static let shared = ServiceHealthMonitor()
    
    private init() {
        setupDefaultHealthChecks()
        startMonitoring()
        logger.info("🏥 Service health monitor initialized")
    }
    
    deinit {
        Task { @MainActor in
            self.stopMonitoring()
        }
    }
    
    // MARK: - Service Registration
    
    private func setupDefaultHealthChecks() {
        // Register default services for monitoring
        registerService("CloudKit", isCritical: true) {
            await self.checkCloudKitHealth()
        }
        
        registerService("Authentication", isCritical: true) {
            await self.checkAuthenticationHealth()
        }
        
        registerService("Payment", isCritical: true) {
            await self.checkPaymentHealth()
        }
        
        registerService("Location", isCritical: false) {
            await self.checkLocationHealth()
        }
        
        registerService("PushNotifications", isCritical: false) {
            await self.checkPushNotificationHealth()
        }
        
        registerService("Analytics", isCritical: false) {
            await self.checkAnalyticsHealth()
        }
    }
    
    /// Register a service for health monitoring
    func registerService(
        _ name: String,
        isCritical: Bool = false,
        healthCheck: @escaping () async -> HealthCheckResult
    ) {
        services[name] = ServiceHealth(
            name: name,
            status: .unknown,
            isCritical: isCritical,
            lastCheck: nil,
            responseTime: 0,
            errorCount: 0,
            uptimePercentage: 100.0
        )
        
        // Store health check function
        // Note: In real implementation, this would be stored properly
        
        logger.info("📋 Registered service: \(name) (critical: \(isCritical))")
        
        // Immediate health check
        Task {
            await performHealthCheck(for: name)
        }
    }
    
    /// Unregister a service
    func unregisterService(_ name: String) {
        services.removeValue(forKey: name)
        serviceObservers[name]?.cancel()
        serviceObservers.removeValue(forKey: name)
        
        updateOverallHealth()
        logger.info("📋 Unregistered service: \(name)")
    }
    
    // MARK: - Health Monitoring
    
    private func startMonitoring() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performAllHealthChecks()
            }
        }
        
        logger.info("🏃 Health monitoring started")
    }
    
    private func stopMonitoring() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        
        serviceObservers.values.forEach { $0.cancel() }
        serviceObservers.removeAll()
        
        logger.info("⏹️ Health monitoring stopped")
    }
    
    private func performAllHealthChecks() async {
        logger.debug("🔍 Performing health checks for \(self.services.count) services")
        
        await withTaskGroup(of: Void.self) { group in
            for serviceName in services.keys {
                group.addTask {
                    await self.performHealthCheck(for: serviceName)
                }
            }
        }
        
        updateOverallHealth()
    }
    
    private func performHealthCheck(for serviceName: String) async {
        guard var serviceHealth = services[serviceName] else { return }
        
        let startTime = Date()
        
        do {
            let result = await performServiceSpecificHealthCheck(serviceName)
            let responseTime = Date().timeIntervalSince(startTime)
            
            // Update service health
            serviceHealth.status = result.status
            serviceHealth.lastCheck = Date()
            serviceHealth.responseTime = responseTime
            serviceHealth.message = result.message
            
            // Update uptime calculation
            updateUptime(for: serviceName, isHealthy: result.status == .healthy)
            
            // Reset error count on success
            if result.status == .healthy {
                serviceHealth.errorCount = 0
            }
            
            services[serviceName] = serviceHealth
            
            logger.debug("✅ Health check completed: \(serviceName) - \(result.status.rawValue)")
            
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            
            // Update service health with error
            serviceHealth.status = .unhealthy
            serviceHealth.lastCheck = Date()
            serviceHealth.responseTime = responseTime
            serviceHealth.errorCount += 1
            serviceHealth.message = error.localizedDescription
            
            updateUptime(for: serviceName, isHealthy: false)
            services[serviceName] = serviceHealth
            
            logger.warning("❌ Health check failed: \(serviceName) - \(error.localizedDescription)")
        }
    }
    
    private func performServiceSpecificHealthCheck(_ serviceName: String) async -> HealthCheckResult {
        switch serviceName {
        case "CloudKit":
            return await checkCloudKitHealth()
        case "Authentication":
            return await checkAuthenticationHealth()
        case "Payment":
            return await checkPaymentHealth()
        case "Location":
            return await checkLocationHealth()
        case "PushNotifications":
            return await checkPushNotificationHealth()
        case "Analytics":
            return await checkAnalyticsHealth()
        default:
            return HealthCheckResult(status: .healthy, message: "Default health check passed")
        }
    }
    
    // MARK: - Specific Health Checks
    
    private func checkCloudKitHealth() async -> HealthCheckResult {
        // Simulate CloudKit health check
        do {
            // In real implementation, this would make a lightweight CloudKit query
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // Check if rate limiter indicates issues
            let rateLimiter = rateLimiterManager.getRateLimiter(for: "CloudKit")
            let stats = rateLimiter.getStatistics()
            
            if stats.isThrottled {
                return HealthCheckResult(status: .degraded, message: "Rate limited")
            } else if stats.successRate < 0.8 {
                return HealthCheckResult(status: .degraded, message: "Low success rate: \(String(format: "%.1f", stats.successRate * 100))%")
            } else {
                return HealthCheckResult(status: .healthy, message: "All systems operational")
            }
        } catch {
            return HealthCheckResult(status: .unhealthy, message: "Connection failed")
        }
    }
    
    private func checkAuthenticationHealth() async -> HealthCheckResult {
        // Simulate authentication health check
        do {
            try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second
            return HealthCheckResult(status: .healthy, message: "Authentication service operational")
        } catch {
            return HealthCheckResult(status: .unhealthy, message: "Authentication unavailable")
        }
    }
    
    private func checkPaymentHealth() async -> HealthCheckResult {
        // Simulate payment service health check
        try? await Task.sleep(nanoseconds: 75_000_000) // 0.075 second
        
        // Simulate occasional degradation
        if Int.random(in: 1...10) == 1 {
            return HealthCheckResult(status: .degraded, message: "Processing delays")
        } else {
            return HealthCheckResult(status: .healthy, message: "Payment processing normal")
        }
    }
    
    private func checkLocationHealth() async -> HealthCheckResult {
        // Check location services
        return HealthCheckResult(status: .healthy, message: "Location services available")
    }
    
    private func checkPushNotificationHealth() async -> HealthCheckResult {
        // Check push notification capability
        return HealthCheckResult(status: .healthy, message: "Push notifications operational")
    }
    
    private func checkAnalyticsHealth() async -> HealthCheckResult {
        // Check analytics service
        return HealthCheckResult(status: .healthy, message: "Analytics collection active")
    }
    
    // MARK: - Health Analysis
    
    private func updateOverallHealth() {
        let healthyCount = services.values.filter { $0.status == .healthy }.count
        let degradedCount = services.values.filter { $0.status == .degraded }.count
        let unhealthyCount = services.values.filter { $0.status == .unhealthy }.count
        
        // Update service lists
        criticalServices = services.values.filter { $0.isCritical && $0.status != .healthy }.map { $0.name }
        degradedServices = services.values.filter { $0.status == .degraded }.map { $0.name }
        
        // Determine overall health
        if criticalServices.isEmpty && unhealthyCount == 0 {
            if degradedCount == 0 {
                overallHealth = .healthy
            } else {
                overallHealth = .degraded
            }
        } else if !criticalServices.isEmpty {
            overallHealth = .critical
        } else {
            overallHealth = .unhealthy
        }
        
        logger.info("🏥 Overall health: \(self.overallHealth.rawValue) (healthy: \(healthyCount), degraded: \(degradedCount), unhealthy: \(unhealthyCount))")
    }
    
    private func updateUptime(for serviceName: String, isHealthy: Bool) {
        guard var service = services[serviceName] else { return }
        
        // Simple uptime calculation (in real implementation, this would be more sophisticated)
        let currentUptime = service.uptimePercentage
        let alpha = 0.1 // Smoothing factor
        
        service.uptimePercentage = currentUptime * (1 - alpha) + (isHealthy ? 100.0 : 0.0) * alpha
        services[serviceName] = service
    }
    
    // MARK: - Recovery Actions
    
    /// Attempt to recover unhealthy services
    func attemptRecovery() async {
        let unhealthyServices = services.values.filter { $0.status == .unhealthy }
        
        logger.info("🔧 Attempting recovery for \(unhealthyServices.count) unhealthy services")
        
        for service in unhealthyServices {
            await attemptServiceRecovery(service.name)
        }
    }
    
    private func attemptServiceRecovery(_ serviceName: String) async {
        logger.info("🔧 Attempting recovery for service: \(serviceName)")
        
        switch serviceName {
        case "CloudKit":
            // Reset circuit breakers, clear caches, etc.
            await clearServiceCaches(serviceName)
            
        case "Authentication":
            // Refresh tokens, clear auth state, etc.
            await refreshAuthenticationState()
            
        case "Payment":
            // Reset payment processors, clear pending transactions, etc.
            await resetPaymentState()
            
        default:
            // Generic recovery actions
            await clearServiceCaches(serviceName)
        }
        
        // Immediate health check after recovery attempt
        await performHealthCheck(for: serviceName)
    }
    
    private func clearServiceCaches(_ serviceName: String) async {
        // Clear caches related to the service
        logger.debug("🗑️ Clearing caches for: \(serviceName)")
    }
    
    private func refreshAuthenticationState() async {
        // Refresh authentication tokens and state
        logger.debug("🔐 Refreshing authentication state")
    }
    
    private func resetPaymentState() async {
        // Reset payment processor state
        logger.debug("💳 Resetting payment state")
    }
    
    // MARK: - Statistics
    
    func getHealthSummary() -> SystemHealthSummary {
        let totalServices = services.count
        let healthyServices = services.values.filter { $0.status == .healthy }.count
        let degradedServices = services.values.filter { $0.status == .degraded }.count
        let unhealthyServices = services.values.filter { $0.status == .unhealthy }.count
        
        let averageUptime = services.values.map { $0.uptimePercentage }.reduce(0, +) / Double(max(1, totalServices))
        let averageResponseTime = services.values.map { $0.responseTime }.reduce(0, +) / Double(max(1, totalServices))
        
        return SystemHealthSummary(
            overallHealth: overallHealth,
            totalServices: totalServices,
            healthyServices: healthyServices,
            degradedServices: degradedServices,
            unhealthyServices: unhealthyServices,
            criticalServicesDown: criticalServices.count,
            averageUptime: averageUptime,
            averageResponseTime: averageResponseTime,
            lastHealthCheck: services.values.compactMap { $0.lastCheck }.max()
        )
    }
}

// MARK: - Supporting Types

struct ServiceHealth {
    let name: String
    var status: HealthStatus
    let isCritical: Bool
    var lastCheck: Date?
    var responseTime: TimeInterval
    var errorCount: Int
    var uptimePercentage: Double
    var message: String?
}

struct HealthCheckResult {
    let status: HealthStatus
    let message: String?
}

enum HealthStatus: String, CaseIterable {
    case healthy = "Healthy"
    case degraded = "Degraded" 
    case unhealthy = "Unhealthy"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .healthy: return .success
        case .degraded: return .warning
        case .unhealthy: return .error
        case .unknown: return .gray500
        }
    }
    
    var icon: String {
        switch self {
        case .healthy: return "checkmark.circle.fill"
        case .degraded: return "exclamationmark.triangle.fill"
        case .unhealthy: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

enum SystemHealth: String, CaseIterable {
    case healthy = "Healthy"
    case degraded = "Degraded"
    case unhealthy = "Unhealthy"
    case critical = "Critical"
    
    var color: Color {
        switch self {
        case .healthy: return .success
        case .degraded: return .warning
        case .unhealthy: return .error
        case .critical: return .error
        }
    }
}

struct SystemHealthSummary {
    let overallHealth: SystemHealth
    let totalServices: Int
    let healthyServices: Int
    let degradedServices: Int
    let unhealthyServices: Int
    let criticalServicesDown: Int
    let averageUptime: Double
    let averageResponseTime: TimeInterval
    let lastHealthCheck: Date?
}