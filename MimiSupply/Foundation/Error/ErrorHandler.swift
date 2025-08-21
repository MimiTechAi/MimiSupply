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
    func handle(_ error: Error, showToUser: Bool = true, context: String? = nil) {
        let appError = convertToAppError(error)
        
        // Log the error
        logError(appError, context: context)
        
        // Report to analytics/crash reporting
        errorReporter.report(appError, context: context)
        
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

/// Error reporter for analytics and crash reporting
final class ErrorReporter {
    static let shared = ErrorReporter()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "ErrorReporter")
    
    private init() {}
    
    /// Report error to analytics/crash reporting services
    func report(_ error: AppError, context: String? = nil) {
        // In a real app, this would integrate with services like:
        // - Firebase Crashlytics
        // - Sentry
        // - Bugsnag
        // - Apple's own crash reporting
        
        let errorData: [String: Any] = [
            "error_type": String(describing: error),
            "error_description": error.localizedDescription,
            "recovery_suggestion": error.recoverySuggestion ?? "No suggestion",
            "context": context ?? "No context",
            "timestamp": Date().timeIntervalSince1970,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ]
        
        logger.info("📊 Error reported: \(errorData)")
        
        // TODO: Integrate with actual error reporting service
        // Example: Crashlytics.crashlytics().record(error: error)
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