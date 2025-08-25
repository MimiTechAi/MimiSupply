//
//  CloudKitErrorHandler.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import CloudKit
import OSLog

/// Enhanced CloudKit error handling with specific recovery strategies
@MainActor
final class CloudKitErrorHandler: @unchecked Sendable {
    static let shared = CloudKitErrorHandler()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "CloudKitErrorHandler")
    private let retryBannerManager = RetryBannerManager.shared
    private let degradationService = GracefulDegradationService.shared
    
    private init() {}
    
    /// Handle CloudKit error with appropriate recovery strategy
    func handleCloudKitError(
        _ error: Error,
        operation: String,
        retryOperation: (() async throws -> Void)? = nil
    ) async {
        let ckError = extractCloudKitError(from: error)
        
        logger.error("🚨 CloudKit error in \(operation): \(ckError.localizedDescription)")
        
        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            await handleNetworkError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .quotaExceeded:
            await handleQuotaError(ckError, operation: operation)
            
        case .limitExceeded:
            await handleRateLimitError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .notAuthenticated:
            await handleAuthenticationError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .permissionFailure:
            await handlePermissionError(ckError, operation: operation)
            
        case .zoneNotFound, .unknownItem:
            await handleNotFoundError(ckError, operation: operation)
            
        case .serverRecordChanged:
            await handleConflictError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .zoneBusy, .serviceUnavailable:
            await handleServiceBusyError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .badContainer, .badDatabase:
            await handleConfigurationError(ckError, operation: operation)
            
        case .incompatibleVersion:
            await handleVersionError(ckError, operation: operation)
            
        case .constraintViolation:
            await handleConstraintError(ckError, operation: operation)
            
        case .serverResponseLost:
            await handleResponseLostError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .assetFileNotFound:
            await handleAssetError(ckError, operation: operation, retryOperation: retryOperation)
            
        case .partialFailure:
            await handlePartialFailureError(ckError, operation: operation, retryOperation: retryOperation)
            
        default:
            await handleGenericError(ckError, operation: operation, retryOperation: retryOperation)
        }
        
        // Report service degradation
        degradationService.reportServiceFailure(.cloudKit, error: ckError)
    }
    
    // MARK: - Specific Error Handlers
    
    private func handleNetworkError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.info("🌐 Network error - enabling offline mode")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "Connection Lost",
                message: "Your changes will be saved and synced when connection is restored.",
                severity: .warning,
                operation: retryOp,
                autoRetryDelay: 30.0
            )
        } else {
            retryBannerManager.showInfoBanner(
                title: "Working Offline",
                message: "Some features may be limited until connection is restored.",
                severity: .warning,
                autoDismissDelay: 8.0
            )
        }
    }
    
    private func handleQuotaError(
        _ error: CKError,
        operation: String
    ) async {
        logger.warning("💾 iCloud storage quota exceeded")
        
        retryBannerManager.showInfoBanner(
            title: "Storage Full",
            message: "Your iCloud storage is full. Please free up space in Settings.",
            severity: .error,
            autoDismissDelay: 15.0
        )
    }
    
    private func handleRateLimitError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        let retryAfter = error.retryAfterSeconds ?? 60.0
        logger.info("⏱️ Rate limited - retry after \(retryAfter)s")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "Service Busy",
                message: "Too many requests. Will retry in \(Int(retryAfter)) seconds.",
                severity: .warning,
                operation: retryOp,
                autoRetryDelay: retryAfter
            )
        }
    }
    
    private func handleAuthenticationError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.warning("🔐 Authentication required")
        
        retryBannerManager.showInfoBanner(
            title: "Sign In Required",
            message: "Please sign in to iCloud in Settings to sync your data.",
            severity: .warning,
            autoDismissDelay: 10.0
        )
    }
    
    private func handlePermissionError(
        _ error: CKError,
        operation: String
    ) async {
        logger.warning("🚫 Permission denied")
        
        retryBannerManager.showInfoBanner(
            title: "Permission Denied",
            message: "You don't have permission to perform this action.",
            severity: .error,
            autoDismissDelay: 8.0
        )
    }
    
    private func handleNotFoundError(
        _ error: CKError,
        operation: String
    ) async {
        logger.info("🔍 Record not found - this may be expected")
        
        // Don't show user-facing error for not found - usually expected
    }
    
    private func handleConflictError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.warning("⚡ Record conflict detected")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "Data Conflict",
                message: "This record was modified elsewhere. Attempting to merge changes.",
                severity: .warning,
                operation: retryOp
            )
        }
    }
    
    private func handleServiceBusyError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        let retryAfter = error.retryAfterSeconds ?? 30.0
        logger.info("🏃 Service busy - retry after \(retryAfter)s")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "Service Busy",
                message: "iCloud is temporarily busy. Will retry shortly.",
                severity: .warning,
                operation: retryOp,
                autoRetryDelay: retryAfter
            )
        }
    }
    
    private func handleConfigurationError(
        _ error: CKError,
        operation: String
    ) async {
        logger.error("⚙️ CloudKit configuration error")
        
        retryBannerManager.showInfoBanner(
            title: "Configuration Error",
            message: "There's an issue with the app configuration. Please try again later.",
            severity: .error,
            autoDismissDelay: 10.0
        )
    }
    
    private func handleVersionError(
        _ error: CKError,
        operation: String
    ) async {
        logger.error("📱 App version incompatible")
        
        retryBannerManager.showInfoBanner(
            title: "Update Required",
            message: "Please update the app to continue syncing data.",
            severity: .error,
            autoDismissDelay: 15.0
        )
    }
    
    private func handleConstraintError(
        _ error: CKError,
        operation: String
    ) async {
        logger.warning("🔒 Data constraint violation")
        
        retryBannerManager.showInfoBanner(
            title: "Invalid Data",
            message: "The data couldn't be saved due to validation rules.",
            severity: .error,
            autoDismissDelay: 8.0
        )
    }
    
    private func handleResponseLostError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.warning("📡 Server response lost")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "Connection Interrupted",
                message: "The operation may have completed. Checking status...",
                severity: .warning,
                operation: retryOp
            )
        }
    }
    
    private func handleAssetError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.warning("📎 Asset file not found")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "File Missing",
                message: "A required file is missing. Attempting to recover...",
                severity: .warning,
                operation: retryOp
            )
        }
    }
    
    private func handlePartialFailureError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.warning("⚠️ Partial failure in batch operation")
        
        // Analyze partial failures
        if let partialErrors = error.partialErrorsByItemID {
            let failureCount = partialErrors.count
            
            retryBannerManager.showInfoBanner(
                title: "Partial Sync",
                message: "\(failureCount) items couldn't be synced. They'll be retried later.",
                severity: .warning,
                autoDismissDelay: 8.0
            )
            
            // Handle individual failures
            for (_, itemError) in partialErrors {
                await handleCloudKitError(itemError, operation: "batch-item")
            }
        }
    }
    
    private func handleGenericError(
        _ error: CKError,
        operation: String,
        retryOperation: (() async throws -> Void)?
    ) async {
        logger.error("❓ Unhandled CloudKit error: \(error.code.rawValue)")
        
        if let retryOp = retryOperation {
            retryBannerManager.showRetryBanner(
                title: "Sync Error",
                message: "Something went wrong with syncing. Tap to retry.",
                severity: .error,
                operation: retryOp
            )
        } else {
            retryBannerManager.showInfoBanner(
                title: "Sync Error",
                message: "There was an issue syncing your data. Please try again later.",
                severity: .error,
                autoDismissDelay: 8.0
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractCloudKitError(from error: Error) -> CKError {
        if let ckError = error as? CKError {
            return ckError
        }
        
        // Check if it's wrapped in an AppError
        if case let AppError.cloudKit(ckError) = error {
            return ckError
        }
        
        // Create a generic CloudKit error
        return CKError(.internalError, userInfo: [
            NSLocalizedDescriptionKey: error.localizedDescription,
            NSUnderlyingErrorKey: error
        ])
    }
    
    /// Get user-friendly error message
    func getUserFriendlyMessage(for error: CKError) -> String {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return "No internet connection. Your changes will be saved and synced when connection is restored."
            
        case .quotaExceeded:
            return "Your iCloud storage is full. Please free up space in Settings to continue syncing."
            
        case .limitExceeded:
            return "Too many requests. Please wait a moment and try again."
            
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings to sync your data."
            
        case .permissionFailure:
            return "You don't have permission to access this data."
            
        case .serverRecordChanged:
            return "This record was modified elsewhere. Your changes will be merged."
            
        case .zoneBusy, .serviceUnavailable:
            return "iCloud is temporarily busy. Please try again in a moment."
            
        case .badContainer, .badDatabase:
            return "There's a configuration issue. Please contact support if this persists."
            
        case .incompatibleVersion:
            return "Please update the app to continue syncing data."
            
        case .constraintViolation:
            return "The data couldn't be saved due to validation rules."
            
        default:
            return "Something went wrong with syncing. Please try again."
        }
    }
    
    /// Check if error is retryable
    func isRetryable(_ error: CKError) -> Bool {
        switch error.code {
        case .networkUnavailable, .networkFailure,
             .limitExceeded, .zoneBusy, .serviceUnavailable,
             .serverRecordChanged, .serverResponseLost,
             .assetFileNotFound, .partialFailure:
            return true
            
        case .quotaExceeded, .notAuthenticated, .permissionFailure,
             .badContainer, .badDatabase, .incompatibleVersion,
             .constraintViolation, .zoneNotFound, .unknownItem:
            return false
            
        default:
            return true // Default to retryable for unknown errors
        }
    }
    
    /// Get recommended retry delay
    func getRetryDelay(for error: CKError) -> TimeInterval {
        // Use the retry-after value if provided
        if let retryAfter = error.retryAfterSeconds {
            return retryAfter
        }
        
        // Default delays based on error type
        switch error.code {
        case .limitExceeded:
            return 60.0 // 1 minute
            
        case .zoneBusy, .serviceUnavailable:
            return 30.0 // 30 seconds
            
        case .networkUnavailable, .networkFailure:
            return 15.0 // 15 seconds
            
        default:
            return 5.0 // 5 seconds
        }
    }
}

// MARK: - CKError Extensions

extension CKError {
    /// Get retry after seconds from error
    var retryAfterSeconds: TimeInterval? {
        return userInfo[CKErrorRetryAfterKey] as? TimeInterval
    }
    
    /// Get partial errors by item ID
    var partialErrorsByItemID: [CKRecord.ID: Error]? {
        return userInfo[CKPartialErrorsByItemIDKey] as? [CKRecord.ID: Error]
    }
    
    /// Get ancestor record for reference errors
    var ancestorRecord: CKRecord? {
        // Use string literal as fallback for missing constant
        let key = "CKErrorAncestorRecord"
        return userInfo[key] as? CKRecord
    }
    
    /// Get server record for conflict errors
    var serverRecord: CKRecord? {
        // Use string literal as fallback for missing constant
        let key = "CKErrorServerRecord"
        return userInfo[key] as? CKRecord
    }
    
    /// Get client record for conflict errors
    var clientRecord: CKRecord? {
        // Use string literal as fallback for missing constant
        let key = "CKErrorClientRecord"
        return userInfo[key] as? CKRecord
    }
}