//
//  CircuitBreaker.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import SwiftUI
import Combine
import OSLog

// MARK: - Circuit Breaker States
enum CircuitBreakerState: String, CaseIterable {
    case closed    // Normal operation
    case open      // Failing fast
    case halfOpen  // Testing if service recovered
}

// MARK: - Circuit Breaker Configuration
struct CircuitBreakerConfig {
    let failureThreshold: Int           // Number of failures before opening
    let recoveryTimeout: TimeInterval   // Time to wait before trying half-open
    let successThreshold: Int           // Successes needed in half-open to close
    let timeout: TimeInterval           // Request timeout
    
    static let `default` = CircuitBreakerConfig(
        failureThreshold: 5,
        recoveryTimeout: 30.0,
        successThreshold: 3,
        timeout: 10.0
    )
    
    static let network = CircuitBreakerConfig(
        failureThreshold: 3,
        recoveryTimeout: 15.0,
        successThreshold: 2,
        timeout: 5.0
    )
    
    static let payment = CircuitBreakerConfig(
        failureThreshold: 2,
        recoveryTimeout: 60.0,
        successThreshold: 5,
        timeout: 15.0
    )
}

// MARK: - Circuit Breaker Error
enum CircuitBreakerError: LocalizedError {
    case circuitOpen
    case timeout
    case tooManyRequests
    
    var errorDescription: String? {
        switch self {
        case .circuitOpen:
            return "Service temporarily unavailable - circuit breaker is open"
        case .timeout:
            return "Request timed out"
        case .tooManyRequests:
            return "Too many concurrent requests"
        }
    }
}

// NOTE: Do not access recoveryTimer in deinit—cleanup should be handled explicitly from the main actor context if needed.
// MARK: - Circuit Breaker Implementation
@MainActor
final class CircuitBreaker: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var state: CircuitBreakerState = .closed
    @Published private(set) var failureCount: Int = 0
    @Published private(set) var successCount: Int = 0
    @Published private(set) var lastFailureTime: Date?
    @Published private(set) var isHealthy: Bool = true
    
    // MARK: - Private Properties
    private let config: CircuitBreakerConfig
    let name: String  // Make this public for SwiftUI access
    private let logger: Logger
    private var recoveryTimer: Timer?
    private let maxConcurrentRequests: Int
    private var currentRequests: Int = 0
    
    // MARK: - Initialization
    init(name: String, config: CircuitBreakerConfig = .default, maxConcurrentRequests: Int = 10) {
        self.name = name
        self.config = config
        self.maxConcurrentRequests = maxConcurrentRequests
        self.logger = Logger(subsystem: "com.mimisupply.app", category: "CircuitBreaker.\(name)")
        
        logger.info("🔌 Circuit breaker initialized: \(name)")
    }
    
    // MARK: - Public Interface
    func execute<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        // Check if we can execute the request
        try await checkCanExecute()
        
        // Track concurrent requests
        currentRequests += 1
        defer { currentRequests -= 1 }
        
        do {
            // Execute with timeout
            let result = try await withTimeout(config.timeout) {
                try await operation()
            }
            
            // Record success
            await recordSuccess()
            return result
            
        } catch {
            // Record failure
            await recordFailure(error)
            throw error
        }
    }
    
    // MARK: - State Management
    private func checkCanExecute() async throws {
        switch state {
        case .closed:
            // Check concurrent request limit
            if currentRequests >= maxConcurrentRequests {
                throw CircuitBreakerError.tooManyRequests
            }
            
        case .open:
            // Check if we should transition to half-open
            if shouldAttemptRecovery() {
                await transitionToHalfOpen()
            } else {
                throw CircuitBreakerError.circuitOpen
            }
            
        case .halfOpen:
            // Allow limited requests in half-open state
            if currentRequests >= 1 {
                throw CircuitBreakerError.circuitOpen
            }
        }
    }
    
    private func recordSuccess() async {
        switch state {
        case .closed:
            // Reset failure count on success
            if failureCount > 0 {
                failureCount = 0
                logger.info("✅ Circuit breaker reset after success: \(self.name)")
            }
            
        case .halfOpen:
            successCount += 1
            logger.info("✅ Success in half-open state: \(self.name) (\(self.successCount)/\(self.config.successThreshold))")
            
            if successCount >= config.successThreshold {
                await transitionToClosed()
            }
            
        case .open:
            // Should not happen, but handle gracefully
            logger.warning("⚠️ Unexpected success in open state: \(self.name)")
        }
        
        updateHealthStatus()
    }
    
    private func recordFailure(_ error: Error) async {
        failureCount += 1
        lastFailureTime = Date()
        
        logger.error("❌ Circuit breaker failure: \(self.name) - \(error.localizedDescription) (count: \(self.failureCount))")
        
        switch state {
        case .closed:
            if failureCount >= config.failureThreshold {
                await transitionToOpen()
            }
            
        case .halfOpen:
            // Any failure in half-open immediately opens the circuit
            await transitionToOpen()
            
        case .open:
            // Already open, just log
            break
        }
        
        updateHealthStatus()
    }
    
    // MARK: - State Transitions
    private func transitionToOpen() async {
        state = .open
        successCount = 0
        isHealthy = false
        
        logger.warning("🔴 Circuit breaker opened: \(self.name) (failures: \(self.failureCount))")
        
        // Schedule recovery attempt
        scheduleRecoveryAttempt()
    }
    
    private func transitionToHalfOpen() async {
        state = .halfOpen
        successCount = 0
        
        logger.info("🟡 Circuit breaker half-open: \(self.name)")
    }
    
    private func transitionToClosed() async {
        state = .closed
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
        isHealthy = true
        
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        
        logger.info("🟢 Circuit breaker closed: \(self.name)")
    }
    
    // MARK: - Recovery Logic
    private func shouldAttemptRecovery() -> Bool {
        guard let lastFailure = lastFailureTime else { return false }
        return Date().timeIntervalSince(lastFailure) >= config.recoveryTimeout
    }
    
    private func scheduleRecoveryAttempt() {
        recoveryTimer?.invalidate()
        
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: config.recoveryTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.logger.info("⏰ Recovery timeout reached for circuit breaker: \(self?.name ?? "unknown")")
            }
        }
    }
    
    private func updateHealthStatus() {
        let previousHealth = isHealthy
        
        switch state {
        case .closed:
            isHealthy = failureCount < config.failureThreshold / 2
        case .halfOpen:
            isHealthy = successCount > 0
        case .open:
            isHealthy = false
        }
        
        if previousHealth != isHealthy {
            logger.info("🏥 Health status changed for \(self.name): \(self.isHealthy ? "healthy" : "unhealthy")")
        }
    }
    
    // MARK: - Timeout Helper
    private func withTimeout<T: Sendable>(_ timeout: TimeInterval, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw CircuitBreakerError.timeout
            }
            
            // Return the first result (either success or timeout)
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Manual Control (for testing)
    func reset() async {
        await transitionToClosed()
        logger.info("🔄 Circuit breaker manually reset: \(self.name)")
    }
    
    func forceOpen() async {
        failureCount = config.failureThreshold
        await transitionToOpen()
        logger.warning("⚠️ Circuit breaker manually opened: \(self.name)")
    }
}

// MARK: - Circuit Breaker Manager
@MainActor
final class CircuitBreakerManager: ObservableObject {
    static let shared = CircuitBreakerManager()
    
    private var circuitBreakers: [String: CircuitBreaker] = [:]
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "CircuitBreakerManager")
    
    private init() {
        setupDefaultCircuitBreakers()
    }
    
    private func setupDefaultCircuitBreakers() {
        // Network operations
        circuitBreakers["network"] = CircuitBreaker(name: "network", config: .network)
        
        // Payment operations
        circuitBreakers["payment"] = CircuitBreaker(name: "payment", config: .payment)
        
        // CloudKit operations
        circuitBreakers["cloudkit"] = CircuitBreaker(name: "cloudkit", config: .default)
        
        // Location services
        circuitBreakers["location"] = CircuitBreaker(name: "location", config: .default)
        
        logger.info("🔌 Circuit breaker manager initialized with \(self.circuitBreakers.count) breakers")
    }
    
    func getCircuitBreaker(for service: String) -> CircuitBreaker {
        if let existing = circuitBreakers[service] {
            return existing
        }
        
        // Create new circuit breaker for unknown service
        let newBreaker = CircuitBreaker(name: service, config: .default)
        circuitBreakers[service] = newBreaker
        
        logger.info("🆕 Created new circuit breaker for service: \(service)")
        return newBreaker
    }
    
    func getAllCircuitBreakers() -> [CircuitBreaker] {
        Array(circuitBreakers.values)
    }
    
    func getHealthStatus() -> [String: Bool] {
        circuitBreakers.mapValues { $0.isHealthy }
    }
    
    func resetAll() async {
        for breaker in circuitBreakers.values {
            await breaker.reset()
        }
        logger.info("🔄 All circuit breakers reset")
    }
}

// MARK: - Convenience Extensions
extension CircuitBreaker {
    func executeNetworkRequest<T: Sendable>(_ request: @escaping @Sendable () async throws -> T) async throws -> T {
        try await execute(request)
    }
    
    func executePaymentOperation<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await execute(operation)
    }
}

/// SwiftUI view for monitoring circuit breaker status
struct CircuitBreakerStatusView: View {
    @StateObject private var manager = CircuitBreakerManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Circuit Breakers")
                .font(.headline.scaledFont())
            
            ForEach(manager.getAllCircuitBreakers(), id: \.name) { breaker in
                HStack {
                    Circle()
                        .fill(colorForState(breaker.state))
                        .frame(width: 8, height: 8)
                    
                    Text(breaker.name)
                        .font(.body.scaledFont())
                    
                    Spacer()
                    
                    Text(breaker.state.rawValue)
                        .font(.caption.scaledFont())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func colorForState(_ state: CircuitBreakerState) -> Color {
        switch state {
        case .closed:
            return .success
        case .open:
            return .error
        case .halfOpen:
            return .warning
        }
    }
}
