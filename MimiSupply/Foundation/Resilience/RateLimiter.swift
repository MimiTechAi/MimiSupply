//
//  RateLimiter.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import OSLog
import Combine

/// Adaptive rate limiter with token bucket algorithm and dynamic adjustment
@MainActor
final class RateLimiter: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTokens: Int = 0
    @Published var isThrottled: Bool = false
    @Published var throttleEndTime: Date?
    @Published var requestsInWindow: Int = 0
    
    // MARK: - Configuration
    private let maxTokens: Int
    private let refillRate: TimeInterval // seconds per token
    private let windowSize: TimeInterval // sliding window size
    private let burstAllowance: Int
    
    // MARK: - State
    private var lastRefill: Date
    private var requestTimestamps: [Date] = []
    private var adaptiveThreshold: Int
    private var throttleTimer: Timer?
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "RateLimiter")
    private let identifier: String
    
    // MARK: - Adaptive Parameters
    private var successRate: Double = 1.0
    private var lastSuccessRates: [Double] = []
    private let adaptationWindow = 10 // Last 10 requests for success rate calculation
    
    init(
        identifier: String,
        maxTokens: Int = 10,
        refillRate: TimeInterval = 1.0, // 1 token per second
        windowSize: TimeInterval = 60.0, // 1 minute window
        burstAllowance: Int = 5
    ) {
        self.identifier = identifier
        self.maxTokens = maxTokens
        self.refillRate = refillRate
        self.windowSize = windowSize
        self.burstAllowance = burstAllowance
        self.adaptiveThreshold = maxTokens
        self.currentTokens = maxTokens
        self.lastRefill = Date()
        
        startRefillTimer()
        logger.info("🚦 Rate limiter initialized for \(identifier): \(maxTokens) tokens, \(refillRate)s refill")
    }
    
    deinit {
        throttleTimer?.invalidate()
    }
    
    // MARK: - Token Management
    
    /// Attempt to acquire a token for making a request
    func acquireToken() async -> Bool {
        await refillTokens()
        await cleanOldRequests()
        
        // Check if we're currently throttled
        if isThrottled, let endTime = throttleEndTime, endTime > Date() {
            logger.debug("🚫 Request blocked: still throttled until \(endTime)")
            return false
        } else if isThrottled {
            // Throttle period has ended
            await endThrottle()
        }
        
        // Check sliding window limit
        if requestsInWindow >= adaptiveThreshold {
            logger.warning("⚠️ Rate limit exceeded: \(requestsInWindow)/\(adaptiveThreshold) in window")
            await startThrottle(duration: calculateThrottleDuration())
            return false
        }
        
        // Check token bucket
        if currentTokens > 0 {
            currentTokens -= 1
            requestTimestamps.append(Date())
            requestsInWindow = requestTimestamps.count
            
            logger.debug("✅ Token acquired: \(currentTokens) remaining")
            return true
        } else {
            logger.debug("🪣 No tokens available")
            return false
        }
    }
    
    /// Record the success or failure of a request for adaptive adjustment
    func recordResult(success: Bool) async {
        lastSuccessRates.append(success ? 1.0 : 0.0)
        
        // Keep only recent results for calculation
        if lastSuccessRates.count > adaptationWindow {
            lastSuccessRates.removeFirst()
        }
        
        // Calculate current success rate
        successRate = lastSuccessRates.reduce(0, +) / Double(lastSuccessRates.count)
        
        // Adapt rate limit based on success rate
        await adaptRateLimit()
        
        logger.debug("📊 Success rate: \(successRate * 100, specifier: "%.1f")%, threshold: \(adaptiveThreshold)")
    }
    
    // MARK: - Adaptive Rate Limiting
    
    private func adaptRateLimit() async {
        let oldThreshold = adaptiveThreshold
        
        if successRate < 0.5 { // Less than 50% success rate
            // Decrease rate limit aggressively
            adaptiveThreshold = max(1, Int(Double(adaptiveThreshold) * 0.5))
            logger.info("📉 Aggressive rate limit reduction: \(oldThreshold) → \(adaptiveThreshold)")
        } else if successRate < 0.8 { // Less than 80% success rate
            // Decrease rate limit moderately
            adaptiveThreshold = max(1, Int(Double(adaptiveThreshold) * 0.8))
            logger.info("📉 Moderate rate limit reduction: \(oldThreshold) → \(adaptiveThreshold)")
        } else if successRate > 0.95 && adaptiveThreshold < maxTokens {
            // Increase rate limit gradually when doing well
            adaptiveThreshold = min(maxTokens, adaptiveThreshold + 1)
            logger.info("📈 Rate limit increase: \(oldThreshold) → \(adaptiveThreshold)")
        }
    }
    
    // MARK: - Throttling Management
    
    private func startThrottle(duration: TimeInterval) async {
        isThrottled = true
        throttleEndTime = Date().addingTimeInterval(duration)
        
        logger.warning("🚫 Throttling activated for \(duration, specifier: "%.1f")s")
        
        // Start timer to end throttle
        throttleTimer?.invalidate()
        throttleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.endThrottle()
            }
        }
    }
    
    private func endThrottle() async {
        isThrottled = false
        throttleEndTime = nil
        throttleTimer?.invalidate()
        throttleTimer = nil
        
        logger.info("✅ Throttling ended")
    }
    
    private func calculateThrottleDuration() -> TimeInterval {
        // Exponential backoff based on how badly we're exceeding the limit
        let excessRatio = Double(requestsInWindow) / Double(adaptiveThreshold)
        let baseDuration = 5.0 // 5 seconds base
        let maxDuration = 60.0 // 1 minute max
        
        let duration = min(maxDuration, baseDuration * pow(2.0, excessRatio - 1.0))
        return duration
    }
    
    // MARK: - Token Refill
    
    private func refillTokens() async {
        let now = Date()
        let timeSinceLastRefill = now.timeIntervalSince(lastRefill)
        let tokensToAdd = Int(timeSinceLastRefill / refillRate)
        
        if tokensToAdd > 0 {
            currentTokens = min(maxTokens, currentTokens + tokensToAdd)
            lastRefill = now
            
            logger.debug("🔋 Refilled \(tokensToAdd) tokens: \(currentTokens)/\(maxTokens)")
        }
    }
    
    private func cleanOldRequests() async {
        let cutoff = Date().addingTimeInterval(-windowSize)
        requestTimestamps = requestTimestamps.filter { $0 > cutoff }
        requestsInWindow = requestTimestamps.count
    }
    
    private func startRefillTimer() {
        Timer.scheduledTimer(withTimeInterval: refillRate, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refillTokens()
            }
        }
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> RateLimiterStatistics {
        return RateLimiterStatistics(
            identifier: identifier,
            currentTokens: currentTokens,
            maxTokens: maxTokens,
            requestsInWindow: requestsInWindow,
            adaptiveThreshold: adaptiveThreshold,
            successRate: successRate,
            isThrottled: isThrottled,
            throttleEndTime: throttleEndTime
        )
    }
    
    /// Reset rate limiter to initial state
    func reset() async {
        currentTokens = maxTokens
        adaptiveThreshold = maxTokens
        requestTimestamps.removeAll()
        requestsInWindow = 0
        lastSuccessRates.removeAll()
        successRate = 1.0
        await endThrottle()
        
        logger.info("🔄 Rate limiter reset")
    }
}

// MARK: - Statistics Model

struct RateLimiterStatistics {
    let identifier: String
    let currentTokens: Int
    let maxTokens: Int
    let requestsInWindow: Int
    let adaptiveThreshold: Int
    let successRate: Double
    let isThrottled: Bool
    let throttleEndTime: Date?
    
    var utilizationPercentage: Double {
        return Double(maxTokens - currentTokens) / Double(maxTokens) * 100
    }
    
    var throttleTimeRemaining: TimeInterval? {
        guard let endTime = throttleEndTime else { return nil }
        return max(0, endTime.timeIntervalSinceNow)
    }
}

// MARK: - Rate Limiter Manager

@MainActor
final class RateLimiterManager: ObservableObject {
    static let shared = RateLimiterManager()
    
    @Published var rateLimiters: [String: RateLimiter] = [:]
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "RateLimiterManager")
    
    private init() {}
    
    /// Get or create a rate limiter for a service
    func getRateLimiter(
        for service: String,
        maxTokens: Int = 10,
        refillRate: TimeInterval = 1.0,
        windowSize: TimeInterval = 60.0,
        burstAllowance: Int = 5
    ) -> RateLimiter {
        if let existingLimiter = rateLimiters[service] {
            return existingLimiter
        }
        
        let newLimiter = RateLimiter(
            identifier: service,
            maxTokens: maxTokens,
            refillRate: refillRate,
            windowSize: windowSize,
            burstAllowance: burstAllowance
        )
        
        rateLimiters[service] = newLimiter
        logger.info("🆕 Created rate limiter for service: \(service)")
        
        return newLimiter
    }
    
    /// Execute a request with rate limiting
    func executeWithRateLimit<T>(
        service: String,
        operation: () async throws -> T
    ) async throws -> T {
        let rateLimiter = getRateLimiter(for: service)
        
        // Try to acquire token
        guard await rateLimiter.acquireToken() else {
            throw ResilienceError.rateLimitExceeded(service: service)
        }
        
        // Execute operation
        do {
            let result = try await operation()
            await rateLimiter.recordResult(success: true)
            return result
        } catch {
            await rateLimiter.recordResult(success: false)
            throw error
        }
    }
    
    /// Get statistics for all rate limiters
    func getAllStatistics() -> [RateLimiterStatistics] {
        return rateLimiters.values.map { $0.getStatistics() }
    }
    
    /// Reset all rate limiters
    func resetAll() async {
        for limiter in rateLimiters.values {
            await limiter.reset()
        }
        logger.info("🔄 All rate limiters reset")
    }
}

// MARK: - Resilience Errors

enum ResilienceError: LocalizedError {
    case rateLimitExceeded(service: String)
    case circuitBreakerOpen(service: String)
    case serviceUnavailable(service: String)
    case requestTimeout(service: String)
    
    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded(let service):
            return "Rate limit exceeded for \(service). Please wait and try again."
        case .circuitBreakerOpen(let service):
            return "\(service) is temporarily unavailable. Please try again later."
        case .serviceUnavailable(let service):
            return "\(service) is currently unavailable."
        case .requestTimeout(let service):
            return "Request to \(service) timed out."
        }
    }
}