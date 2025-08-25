//
//  EnhancedCircuitBreaker.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import SwiftUI
import Combine
import OSLog

/// Enhanced Circuit Breaker with adaptive thresholds and gradual recovery
@MainActor
final class EnhancedCircuitBreaker: ObservableObject {
    
    // MARK: - Published Properties
    @Published var state: CircuitBreakerState = .closed
    @Published var failureCount: Int = 0
    @Published var successCount: Int = 0
    @Published var lastFailureTime: Date?
    @Published var recoveryProgress: Double = 0.0
    
    // MARK: - Configuration
    private let identifier: String
    private let failureThreshold: Int
    private let recoveryTimeout: TimeInterval
    private let halfOpenMaxRequests: Int
    private let successThreshold: Int
    
    // MARK: - Adaptive Parameters
    private var adaptiveFailureThreshold: Int
    private var adaptiveTimeout: TimeInterval
    private let minTimeout: TimeInterval = 5.0
    private let maxTimeout: TimeInterval = 300.0 // 5 minutes
    
    // MARK: - State Management
    private var halfOpenRequestCount: Int = 0
    private var halfOpenSuccessCount: Int = 0
    private var recoveryTimer: Timer?
    private var stateChangeTime: Date = Date()
    
    // MARK: - Statistics
    private var totalRequests: Int = 0
    private var totalFailures: Int = 0
    private var stateHistory: [(CircuitBreakerState, Date)] = []
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "CircuitBreaker")
    
    init(
        identifier: String,
        failureThreshold: Int = 5,
        recoveryTimeout: TimeInterval = 30.0,
        halfOpenMaxRequests: Int = 3,
        successThreshold: Int = 2
    ) {
        self.identifier = identifier
        self.failureThreshold = failureThreshold
        self.recoveryTimeout = recoveryTimeout
        self.halfOpenMaxRequests = halfOpenMaxRequests
        self.successThreshold = successThreshold
        
        // Initialize adaptive parameters
        self.adaptiveFailureThreshold = failureThreshold
        self.adaptiveTimeout = recoveryTimeout
        
        logger.info("🔌 Circuit breaker initialized for \(identifier)")
    }
    
    deinit {
        recoveryTimer?.invalidate()
    }
    
    // MARK: - Request Execution
    
    /// Execute operation with circuit breaker protection
    func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        // Check if circuit breaker allows the request
        guard await canExecute() else {
            logger.debug("🚫 Request blocked by circuit breaker: \(self.identifier)")
            throw ResilienceError.circuitBreakerOpen(service: identifier)
        }
        
        totalRequests += 1
        
        do {
            let result = try await operation()
            await recordSuccess()
            return result
        } catch {
            await recordFailure(error)
            throw error
        }
    }
    
    private func canExecute() async -> Bool {
        switch state {
        case .closed:
            return true
            
        case .open:
            // Check if timeout has elapsed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= adaptiveTimeout {
                await transitionToHalfOpen()
                return true
            }
            return false
            
        case .halfOpen:
            return halfOpenRequestCount < halfOpenMaxRequests
        }
    }
    
    // MARK: - State Transitions
    
    private func recordSuccess() async {
        successCount += 1
        
        logger.debug("✅ Success recorded for \(self.identifier): \(self.successCount)")
        
        switch state {
        case .closed:
            // Reset failure count on success
            if failureCount > 0 {
                failureCount = 0
                logger.debug("🔄 Failure count reset for \(self.identifier)")
            }
            
        case .halfOpen:
            halfOpenSuccessCount += 1
            halfOpenRequestCount += 1
            
            // Check if we have enough successes to close the circuit
            if halfOpenSuccessCount >= successThreshold {
                await transitionToClosed()
            }
            
        case .open:
            // This shouldn't happen, but handle gracefully
            logger.warning("⚠️ Success recorded while circuit is open: \(self.identifier)")
        }
        
        // Adapt thresholds based on recent performance
        await adaptThresholds(success: true)
    }
    
    private func recordFailure(_ error: Error) async {
        failureCount += 1
        totalFailures += 1
        lastFailureTime = Date()
        
        logger.warning("❌ Failure recorded for \(self.identifier): \(self.failureCount)/\(self.adaptiveFailureThreshold)")
        
        switch state {
        case .closed:
            if failureCount >= adaptiveFailureThreshold {
                await transitionToOpen()
            }
            
        case .halfOpen:
            halfOpenRequestCount += 1
            // Any failure in half-open state immediately opens the circuit
            await transitionToOpen()
            
        case .open:
            // Already open, just record the failure
            break
        }
        
        // Adapt thresholds based on failure
        await adaptThresholds(success: false)
    }
    
    private func transitionToClosed() async {
        let previousState = state
        state = .closed
        stateChangeTime = Date()
        failureCount = 0
        halfOpenRequestCount = 0
        halfOpenSuccessCount = 0
        recoveryProgress = 0.0
        
        recoveryTimer?.invalidate()
        recoveryTimer = nil
        
        recordStateChange(from: previousState, to: .closed)
        logger.info("🟢 Circuit breaker CLOSED: \(self.identifier)")
    }
    
    private func transitionToOpen() async {
        let previousState = state
        state = .open
        stateChangeTime = Date()
        lastFailureTime = Date()
        recoveryProgress = 0.0
        
        // Start recovery timer
        startRecoveryTimer()
        
        recordStateChange(from: previousState, to: .open)
        logger.warning("🔴 Circuit breaker OPEN: \(self.identifier), timeout: \(self.adaptiveTimeout)s")
    }
    
    private func transitionToHalfOpen() async {
        let previousState = state
        state = .halfOpen
        stateChangeTime = Date()
        halfOpenRequestCount = 0
        halfOpenSuccessCount = 0
        recoveryProgress = 0.5
        
        recordStateChange(from: previousState, to: .halfOpen)
        logger.info("🟡 Circuit breaker HALF-OPEN: \(self.identifier)")
    }
    
    // MARK: - Adaptive Behavior
    
    private func adaptThresholds(success: Bool) async {
        let recentFailureRate = Double(totalFailures) / Double(max(1, totalRequests))
        
        if success && recentFailureRate < 0.1 { // Less than 10% failure rate
            // Gradually increase failure threshold (be more tolerant)
            adaptiveFailureThreshold = min(failureThreshold * 2, adaptiveFailureThreshold + 1)
            
            // Decrease timeout (recover faster)
            adaptiveTimeout = max(minTimeout, adaptiveTimeout * 0.9)
            
        } else if !success && recentFailureRate > 0.5 { // More than 50% failure rate
            // Decrease failure threshold (be more sensitive)
            adaptiveFailureThreshold = max(1, adaptiveFailureThreshold - 1)
            
            // Increase timeout (take longer to recover)
            adaptiveTimeout = min(maxTimeout, adaptiveTimeout * 1.5)
        }
        
        logger.debug("🎯 Adapted thresholds for \(self.identifier): threshold=\(self.adaptiveFailureThreshold), timeout=\(self.adaptiveTimeout)s")
    }
    
    // MARK: - Recovery Timer
    
    private func startRecoveryTimer() {
        recoveryTimer?.invalidate()
        
        let updateInterval = 1.0
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateRecoveryProgress()
            }
        }
    }
    
    private func updateRecoveryProgress() async {
        guard state == .open, let lastFailure = lastFailureTime else { return }
        
        let elapsed = Date().timeIntervalSince(lastFailure)
        recoveryProgress = min(1.0, elapsed / adaptiveTimeout)
        
        if elapsed >= adaptiveTimeout {
            await transitionToHalfOpen()
        }
    }
    
    // MARK: - Statistics and Monitoring
    
    private func recordStateChange(from: CircuitBreakerState, to: CircuitBreakerState) {
        stateHistory.append((to, Date()))
        
        // Keep only recent history (last 50 transitions)
        if stateHistory.count > 50 {
            stateHistory.removeFirst()
        }
    }
    
    func getStatistics() -> CircuitBreakerStatistics {
        let uptime = stateHistory.isEmpty ? 100.0 : calculateUptime()
        let currentStateDuration = Date().timeIntervalSince(stateChangeTime)
        
        return CircuitBreakerStatistics(
            identifier: identifier,
            state: state,
            failureCount: failureCount,
            successCount: successCount,
            totalRequests: totalRequests,
            totalFailures: totalFailures,
            failureRate: totalRequests > 0 ? Double(totalFailures) / Double(totalRequests) : 0.0,
            adaptiveFailureThreshold: adaptiveFailureThreshold,
            adaptiveTimeout: adaptiveTimeout,
            recoveryProgress: recoveryProgress,
            uptime: uptime,
            currentStateDuration: currentStateDuration,
            stateChanges: stateHistory.count
        )
    }
    
    private func calculateUptime() -> Double {
        guard !stateHistory.isEmpty else { return 100.0 }
        
        let totalTime = Date().timeIntervalSince(stateHistory.first!.1)
        var downTime: TimeInterval = 0
        
        for i in 0..<stateHistory.count {
            let (state, startTime) = stateHistory[i]
            let endTime = i + 1 < stateHistory.count ? stateHistory[i + 1].1 : Date()
            
            if state == .open {
                downTime += endTime.timeIntervalSince(startTime)
            }
        }
        
        return max(0.0, (totalTime - downTime) / totalTime * 100.0)
    }
    
    /// Reset circuit breaker to initial state
    func reset() async {
        await transitionToClosed()
        failureCount = 0
        successCount = 0
        totalRequests = 0
        totalFailures = 0
        stateHistory.removeAll()
        adaptiveFailureThreshold = failureThreshold
        adaptiveTimeout = recoveryTimeout
        
        logger.info("🔄 Circuit breaker reset: \(self.identifier)")
    }
    
    /// Manually trip the circuit breaker
    func trip() async {
        await transitionToOpen()
        logger.warning("⚠️ Circuit breaker manually tripped: \(self.identifier)")
    }
}

// MARK: - Statistics Model

struct CircuitBreakerStatistics {
    let identifier: String
    let state: CircuitBreakerState
    let failureCount: Int
    let successCount: Int
    let totalRequests: Int
    let totalFailures: Int
    let failureRate: Double
    let adaptiveFailureThreshold: Int
    let adaptiveTimeout: TimeInterval
    let recoveryProgress: Double
    let uptime: Double
    let currentStateDuration: TimeInterval
    let stateChanges: Int
}