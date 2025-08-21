//
//  CloudKitError.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CloudKit

/// CloudKit-specific errors with user-friendly messages and recovery suggestions
enum CloudKitError: LocalizedError, Sendable {
    case accountNotAvailable
    case networkUnavailable
    case quotaExceeded
    case recordNotFound(String)
    case conflictResolutionFailed(String)
    case permissionFailure
    case subscriptionFailed(String)
    case syncFailed(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account not available"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .quotaExceeded:
            return "iCloud storage quota exceeded"
        case .recordNotFound(let recordType):
            return "\(recordType) not found"
        case .conflictResolutionFailed(let details):
            return "Data conflict resolution failed: \(details)"
        case .permissionFailure:
            return "Permission denied for iCloud access"
        case .subscriptionFailed(let subscriptionID):
            return "Failed to subscribe to updates: \(subscriptionID)"
        case .syncFailed(let details):
            return "Data synchronization failed: \(details)"
        case .unknown(let error):
            return "CloudKit error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .accountNotAvailable:
            return "Please sign in to iCloud in Settings and try again."
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .quotaExceeded:
            return "Please free up iCloud storage space or upgrade your plan."
        case .recordNotFound:
            return "The requested data may have been deleted or moved."
        case .conflictResolutionFailed:
            return "Your changes will be saved locally and synced when possible."
        case .permissionFailure:
            return "Please enable iCloud for this app in Settings."
        case .subscriptionFailed:
            return "Real-time updates may not work. Please restart the app."
        case .syncFailed:
            return "Your data will sync when connection is restored."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
    
    /// Convert CKError to CloudKitError
    static func from(_ ckError: CKError) -> CloudKitError {
        switch ckError.code {
        case .notAuthenticated:
            return .accountNotAvailable
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .quotaExceeded:
            return .quotaExceeded
        case .unknownItem:
            return .recordNotFound("Record")
        case .serverRecordChanged:
            return .conflictResolutionFailed("Server record changed")
        case .permissionFailure:
            return .permissionFailure
        default:
            return .unknown(ckError)
        }
    }
}

/// Conflict resolution strategy for CloudKit records
enum ConflictResolutionStrategy {
    case clientWins
    case serverWins
    case timestampBased
    case merge
}

/// CloudKit operation result with conflict resolution
struct CloudKitOperationResult<T> {
    let value: T?
    let conflicts: [CKRecord]
    let error: CloudKitError?
    
    var isSuccess: Bool {
        return error == nil && value != nil
    }
}