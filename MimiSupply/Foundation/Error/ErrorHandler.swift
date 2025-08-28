//
//  ErrorHandler.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI
import OSLog
import CloudKit
// Assuming AnalyticsParameterValue and AnalyticsParameters are defined in a shared module or globally accessible
// import AnalyticsService

/// Global error handler for the MimiSupply app
@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "ErrorHandler")
    private let errorReporter = ErrorReporter.shared
    
    private init() {}
    
    /// Handle an error with optional user notification
    /// - Parameters:
    ///   - error: The error to handle
    ///   - showToUser: Whether to show error UI to user
    ///   - context: Optional context string describing the error environment
    func handle(_ error: Error, showToUser: Bool = true, context: String? = nil) {
        let appError = convertToAppError(error)
        
        // Log the error
        logError(appError, context: context)
        
        // Prepare typed analytics parameters, including context if present
        var analyticsParams: AnalyticsParameters = [
            "error_type": .string(String(describing: appError)),
            "error_description": .string(appError.localizedDescription),
            "recovery_suggestion": .string(appError.recoverySuggestion ?? "No suggestion"),
            "timestamp": .double(Date().timeIntervalSince1970),
            "app_version": .string(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"),
            "build_number": .string(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
        ]
        if let ctx = context {
            analyticsParams["context"] = .string(ctx)
        }
        
        // Report to analytics/crash reporting
        errorReporter.report(appError, parameters: analyticsParams)
        
        // Show to user if requested
        if showToUser {
            showError(appError)
        }
    }
    
    /// Show error to user with UI
    func showError(_ error: AppError) {
        currentError = error
        isShowingError = true
    }
    
    /// Dismiss current error
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Convert any error to AppError
    func convertToAppError(_ error: Error) -> AppError {
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
    
    /// Log error with appropriate level
    private func logError(_ error: AppError, context: String?) {
        let contextString = context.map { " [Context: \($0)]" } ?? ""
        
        switch error {
        case .network, .cloudKit:
            logger.warning("⚠️ \(error.localizedDescription)\(contextString)")
        case .authentication, .payment:
            logger.error("❌ \(error.localizedDescription)\(contextString)")
        case .validation, .location:
            logger.info("ℹ️ \(error.localizedDescription)\(contextString)")
        case .unknown:
            logger.fault("💥 \(error.localizedDescription)\(contextString)")
        case .dataNotFound:
            logger.debug("🔍 \(error.localizedDescription)\(contextString)")
        }
    }
}

/// Error reporter for analytics and crash reporting services
final class ErrorReporter: Sendable {
    static let shared = ErrorReporter()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "ErrorReporter")
    
    private init() {}
    
    /// Report error to analytics/crash reporting services with typed parameters
    /// - Parameters:
    ///   - error: The app error to report
    ///   - parameters: Typed analytics parameters with metadata and context
    func report(_ error: AppError, parameters: AnalyticsParameters = [:]) {
        // In a real app, this would integrate with services like:
        // - Firebase Crashlytics
        // - Sentry
        // - Bugsnag
        // - Apple's own crash reporting
        
        // Log the typed parameters for debugging
        logger.info("📊 Error reported with parameters: \(parameters)")
        
        // TODO: Integrate with actual error reporting service
        // Example: Crashlytics.crashlytics().record(error: error)
        // Use parameters to attach metadata/context to the error report
    }
}

// MARK: - NetworkError Extensions

extension NetworkError {
    static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cannotConnectToHost, .cannotFindHost:
            return .connectionFailed
        case .badServerResponse:
            return .invalidResponse
        default:
            return .connectionFailed
        }
    }
}
