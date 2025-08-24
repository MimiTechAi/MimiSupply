//
//  RequestQueueManager.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import OSLog
import Combine

/// Intelligent request queue manager with priority, retry, and throttling
@MainActor
final class RequestQueueManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var queuedRequests: Int = 0
    @Published var processingRequests: Int = 0
    @Published var completedRequests: Int = 0
    @Published var failedRequests: Int = 0
    @Published var averageProcessingTime: TimeInterval = 0
    
    // MARK: - Configuration
    private let maxConcurrentRequests: Int
    private let maxQueueSize: Int
    private let defaultTimeout: TimeInterval
    
    // MARK: - Queue Management
    private var requestQueue: [QueuedRequest] = []
    private var processingQueue: Set<UUID> = []
    private var completedQueue: [CompletedRequest] = []
    
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "RequestQueue")
    
    init(
        maxConcurrentRequests: Int = 3,
        maxQueueSize: Int = 50,
        defaultTimeout: TimeInterval = 30.0
    ) {
        self.maxConcurrentRequests = maxConcurrentRequests
        self.maxQueueSize = maxQueueSize
        self.defaultTimeout = defaultTimeout
        
        startProcessingLoop()
        logger.info("🗃️ Request queue manager initialized: max concurrent=\(maxConcurrentRequests), max queue=\(maxQueueSize)")
    }
    
    // MARK: - Request Queuing
    
    /// Queue a request for execution
    func enqueue<T>(
        _ operation: @escaping () async throws -> T,
        priority: RequestPriority = .normal,
        timeout: TimeInterval? = nil,
        retryPolicy: RetryPolicy = .none,
        identifier: String? = nil
    ) async throws -> T {
        // Check queue capacity
        guard requestQueue.count < maxQueueSize else {
            logger.warning("⚠️ Queue full, rejecting request")
            throw ResilienceError.serviceUnavailable(service: "RequestQueue")
        }
        
        // Create queued request
        let request = QueuedRequest(
            id: UUID(),
            operation: { try await operation() },
            priority: priority,
            timeout: timeout ?? defaultTimeout,
            retryPolicy: retryPolicy,
            identifier: identifier ?? "anonymous",
            queuedAt: Date()
        )
        
        // Insert based on priority
        insertRequest(request)
        updateQueueMetrics()
        
        logger.debug("📥 Request queued: \(request.identifier) (priority: \(priority.rawValue))")
        
        // Wait for completion
        return try await withCheckedThrowingContinuation { continuation in
            request.continuation = continuation
        }
    }
    
    private func insertRequest(_ request: QueuedRequest) {
        // Insert maintaining priority order (high priority first)
        let insertIndex = requestQueue.firstIndex { $0.priority.rawValue < request.priority.rawValue } ?? requestQueue.count
        requestQueue.insert(request, at: insertIndex)
    }
    
    // MARK: - Request Processing
    
    private func startProcessingLoop() {
        Task {
            while !Task.isCancelled {
                await processNextRequests()
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
    }
    
    private func processNextRequests() async {
        // Process requests up to concurrent limit
        while processingQueue.count < maxConcurrentRequests && !requestQueue.isEmpty {
            let request = requestQueue.removeFirst()
            processingQueue.insert(request.id)
            updateQueueMetrics()
            
            // Process request concurrently
            Task {
                await processRequest(request)
            }
        }
    }
    
    private func processRequest(_ request: QueuedRequest) async {
        let startTime = Date()
        logger.debug("🏃 Processing request: \(request.identifier)")
        
        do {
            // Execute with timeout
            let result = try await withThrowingTaskGroup(of: Any.self) { group in
                // Add main operation
                group.addTask {
                    return try await request.operation()
                }
                
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(request.timeout * 1_000_000_000))
                    throw ResilienceError.requestTimeout(service: request.identifier)
                }
                
                // Return first completed result
                let result = try await group.next()!
                group.cancelAll()
                return result
            }
            
            // Success
            await completeRequest(request, result: .success(result), processingTime: Date().timeIntervalSince(startTime))
            
        } catch {
            // Handle failure with retry policy
            await handleRequestFailure(request, error: error, processingTime: Date().timeIntervalSince(startTime))
        }
    }
    
    private func handleRequestFailure(_ request: QueuedRequest, error: Error, processingTime: TimeInterval) async {
        switch request.retryPolicy {
        case .none:
            await completeRequest(request, result: .failure(error), processingTime: processingTime)
            
        case .fixed(let maxRetries, let delay):
            if request.retryCount < maxRetries {
                // Retry after delay
                let retryRequest = request.withRetry(delay: delay)
                
                Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.requestQueue.append(retryRequest)
                        self?.updateQueueMetrics()
                    }
                }
                
                logger.debug("🔄 Retrying request: \(request.identifier) (attempt \(request.retryCount + 1)/\(maxRetries))")
            } else {
                await completeRequest(request, result: .failure(error), processingTime: processingTime)
            }
            
        case .exponential(let maxRetries, let baseDelay, let maxDelay):
            if request.retryCount < maxRetries {
                let delay = min(maxDelay, baseDelay * pow(2.0, Double(request.retryCount)))
                let retryRequest = request.withRetry(delay: delay)
                
                Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    Task { @MainActor in
                        self?.requestQueue.append(retryRequest)
                        self?.updateQueueMetrics()
                    }
                }
                
                logger.debug("🔄 Exponential retry: \(request.identifier) (attempt \(request.retryCount + 1)/\(maxRetries), delay: \(delay)s)")
            } else {
                await completeRequest(request, result: .failure(error), processingTime: processingTime)
            }
        }
    }
    
    private func completeRequest(_ request: QueuedRequest, result: Result<Any, Error>, processingTime: TimeInterval) async {
        // Remove from processing queue
        processingQueue.remove(request.id)
        
        // Add to completed queue
        let completedRequest = CompletedRequest(
            id: request.id,
            identifier: request.identifier,
            result: result,
            processingTime: processingTime,
            completedAt: Date()
        )
        
        completedQueue.append(completedRequest)
        
        // Keep only recent completed requests
        if completedQueue.count > 100 {
            completedQueue.removeFirst()
        }
        
        // Update metrics
        updateQueueMetrics()
        updateProcessingTime(processingTime)
        
        // Resume continuation
        switch result {
        case .success(let value):
            request.continuation?.resume(returning: value)
            completedRequests += 1
            logger.debug("✅ Request completed: \(request.identifier) in \(processingTime, specifier: "%.2f")s")
            
        case .failure(let error):
            request.continuation?.resume(throwing: error)
            failedRequests += 1
            logger.warning("❌ Request failed: \(request.identifier) - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Metrics
    
    private func updateQueueMetrics() {
        queuedRequests = requestQueue.count
        processingRequests = processingQueue.count
    }
    
    private func updateProcessingTime(_ newTime: TimeInterval) {
        // Running average of processing times
        let alpha = 0.1 // Smoothing factor
        averageProcessingTime = averageProcessingTime * (1 - alpha) + newTime * alpha
    }
    
    func getStatistics() -> RequestQueueStatistics {
        let recentCompletedRequests = completedQueue.suffix(20)
        let recentProcessingTimes = recentCompletedRequests.map { $0.processingTime }
        
        return RequestQueueStatistics(
            queuedRequests: queuedRequests,
            processingRequests: processingRequests,
            completedRequests: completedRequests,
            failedRequests: failedRequests,
            totalRequests: completedRequests + failedRequests,
            averageProcessingTime: averageProcessingTime,
            successRate: Double(completedRequests) / Double(max(1, completedRequests + failedRequests)),
            queueUtilization: Double(queuedRequests) / Double(maxQueueSize),
            processingUtilization: Double(processingRequests) / Double(maxConcurrentRequests),
            recentProcessingTimes: recentProcessingTimes
        )
    }
    
    /// Clear completed requests and reset counters
    func reset() async {
        requestQueue.removeAll()
        completedQueue.removeAll()
        processingQueue.removeAll()
        completedRequests = 0
        failedRequests = 0
        averageProcessingTime = 0
        updateQueueMetrics()
        
        logger.info("🔄 Request queue reset")
    }
}

// MARK: - Supporting Types

struct QueuedRequest {
    let id: UUID
    let operation: () async throws -> Any
    let priority: RequestPriority
    let timeout: TimeInterval
    let retryPolicy: RetryPolicy
    let identifier: String
    let queuedAt: Date
    var retryCount: Int = 0
    var continuation: CheckedContinuation<Any, Error>?
    
    func withRetry(delay: TimeInterval) -> QueuedRequest {
        var newRequest = self
        newRequest.retryCount += 1
        return newRequest
    }
}

struct CompletedRequest {
    let id: UUID
    let identifier: String
    let result: Result<Any, Error>
    let processingTime: TimeInterval
    let completedAt: Date
}

enum RequestPriority: Int, CaseIterable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

enum RetryPolicy {
    case none
    case fixed(maxRetries: Int, delay: TimeInterval)
    case exponential(maxRetries: Int, baseDelay: TimeInterval, maxDelay: TimeInterval)
}

struct RequestQueueStatistics {
    let queuedRequests: Int
    let processingRequests: Int
    let completedRequests: Int
    let failedRequests: Int
    let totalRequests: Int
    let averageProcessingTime: TimeInterval
    let successRate: Double
    let queueUtilization: Double // 0.0 to 1.0
    let processingUtilization: Double // 0.0 to 1.0
    let recentProcessingTimes: [TimeInterval]
}