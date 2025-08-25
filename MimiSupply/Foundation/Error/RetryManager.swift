//
//  RetryManager.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI
import Network
import OSLog

/// Manages retry logic for failed operations
final class RetryManager: ObservableObject, @unchecked Sendable {
    nonisolated(unsafe) static let shared = RetryManager()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "RetryManager")
    private let networkMonitor = NetworkMonitor.shared
    
    private init() {}
    
    /// Retry an async operation with exponential backoff
    func retry<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T,
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0,
        retryableErrors: [Error.Type] = [NetworkError.self, CloudKitError.self]
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 1...maxAttempts {
            do {
                logger.debug("🔄 Attempting operation (attempt \(attempt)/\(maxAttempts))")
                return try await operation()
            } catch {
                lastError = error
                logger.warning("⚠️ Operation failed on attempt \(attempt): \(error.localizedDescription)")
                
                // Check if error is retryable
                if !isRetryable(error: error, retryableErrors: retryableErrors) {
                    logger.info("❌ Error not retryable, failing immediately")
                    throw error
                }
                
                // Don't delay on the last attempt
                if attempt < maxAttempts {
                    logger.debug("⏳ Waiting \(delay)s before retry")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    delay = min(delay * backoffMultiplier, maxDelay)
                }
            }
        }
        
        logger.error("❌ All retry attempts failed")
        throw lastError ?? AppError.unknown(NSError(domain: "RetryManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "All retry attempts failed"]))
    }
    
    /// Retry operation when network becomes available
    func retryWhenNetworkAvailable<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T,
        timeout: TimeInterval = 60.0
    ) async throws -> T {
        // If network is available, try immediately
        if await networkMonitor.isConnected {
            return try await operation()
        }
        
        logger.info("📡 Waiting for network connection...")
        
        // Wait for network to become available
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AppError.network(.timeout)
            }
            
            // Add network monitoring task
            group.addTask { [networkMonitor] in
                // Wait for network to become available
                await networkMonitor.waitForConnection()
                
                // Try the operation
                return try await operation()
            }
            
            // Return the first successful result
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Check if an error is retryable
    private func isRetryable(error: Error, retryableErrors: [Error.Type]) -> Bool {
        // Simple conversion without using ErrorHandler for concurrency safety
        if let networkError = error as? NetworkError {
            return true
        }
        if let cloudKitError = error as? CloudKitError {
            return true
        }
        if let appError = error as? AppError {
            switch appError {
            case .network(.noConnection), .network(.timeout), .network(.connectionFailed):
                return true
            case .cloudKit:
                return true
            case .authentication(.tokenExpired):
                return true
            default:
                return false
            }
        }
        return false
    }
}

/// Network connectivity monitor
final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    private static let _shared = NetworkMonitor()
    static var shared: NetworkMonitor { _shared }

    @MainActor @Published var isConnected = false
    @MainActor @Published var connectionType: NWInterface.InterfaceType?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "NetworkMonitor")
    
    private var connectionContinuation: CheckedContinuation<Void, Never>?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// Start monitoring network connectivity
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateConnectionStatus(path)
            }
        }
        monitor.start(queue: queue)
        logger.info("📡 Network monitoring started")
    }
    
    /// Stop monitoring network connectivity
    private func stopMonitoring() {
        monitor.cancel()
        logger.info("📡 Network monitoring stopped")
    }
    
    /// Update connection status based on network path
    @MainActor
    private func updateConnectionStatus(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        
        // Determine connection type
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wiredEthernet
        } else {
            connectionType = nil
        }
        
        logger.info("📡 Network status: \(self.isConnected ? "Connected" : "Disconnected") via \(self.connectionType?.description ?? "Unknown")")
        
        // Notify waiting tasks if connection was restored
        if !wasConnected && isConnected {
            connectionContinuation?.resume()
            connectionContinuation = nil
        }
    }
    
    /// Wait for network connection to become available
    func waitForConnection() async {
        if await isConnected {
            return
        }
        
        await withCheckedContinuation { continuation in
            Task { @MainActor in
                self.connectionContinuation = continuation
            }
        }
    }
}

// MARK: - NWInterface.InterfaceType Extension

extension NWInterface.InterfaceType {
    var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}