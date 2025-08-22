//
//  ConflictResolutionService.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import CloudKit

/// Service for handling CloudKit record conflicts with intelligent resolution strategies
final class ConflictResolutionService: Sendable {
    
    nonisolated(unsafe) static let shared = ConflictResolutionService()
    
    private init() {}
    
    // MARK: - Conflict Resolution
    
    /// Resolve conflicts between local and server records
    func resolveConflict(
        localRecord: CKRecord,
        serverRecord: CKRecord,
        strategy: ConflictResolutionStrategy = .timestampBased
    ) throws -> CKRecord {
        
        switch strategy {
        case .clientWins:
            return resolveClientWins(localRecord: localRecord, serverRecord: serverRecord)
            
        case .serverWins:
            return serverRecord
            
        case .timestampBased:
            return resolveTimestampBased(localRecord: localRecord, serverRecord: serverRecord)
            
        case .merge:
            return try resolveMerge(localRecord: localRecord, serverRecord: serverRecord)
        }
    }
    
    // MARK: - Resolution Strategies
    
    private func resolveClientWins(localRecord: CKRecord, serverRecord: CKRecord) -> CKRecord {
        // Keep local changes, but we can't modify recordChangeTag as it's read-only
        // Return the local record - CloudKit will handle the change tag
        return localRecord
    }
    
    private func resolveTimestampBased(localRecord: CKRecord, serverRecord: CKRecord) -> CKRecord {
        // Compare modification dates and choose the most recent
        let localModificationDate = localRecord.modificationDate ?? Date.distantPast
        let serverModificationDate = serverRecord.modificationDate ?? Date.distantPast
        
        if localModificationDate > serverModificationDate {
            return localRecord
        } else {
            return serverRecord
        }
    }
    
    private func resolveMerge(localRecord: CKRecord, serverRecord: CKRecord) throws -> CKRecord {
        // Intelligent merge based on record type
        let resolvedRecord = serverRecord.copy() as! CKRecord
        
        switch localRecord.recordType {
        case CloudKitSchema.Order.recordType:
            return try mergeOrderRecords(local: localRecord, server: serverRecord, resolved: resolvedRecord)
            
        case CloudKitSchema.UserProfile.recordType:
            return try mergeUserProfileRecords(local: localRecord, server: serverRecord, resolved: resolvedRecord)
            
        case CloudKitSchema.DriverLocation.recordType:
            return try mergeDriverLocationRecords(local: localRecord, server: serverRecord, resolved: resolvedRecord)
            
        default:
            // Default to timestamp-based resolution for unknown types
            return resolveTimestampBased(localRecord: localRecord, serverRecord: serverRecord)
        }
    }
    
    // MARK: - Record-Specific Merge Logic
    
    private func mergeOrderRecords(local: CKRecord, server: CKRecord, resolved: CKRecord) throws -> CKRecord {
        // For orders, prefer server status but keep local delivery instructions
        if let localInstructions = local[CloudKitSchema.Order.deliveryInstructions] as? String,
           !localInstructions.isEmpty {
            resolved[CloudKitSchema.Order.deliveryInstructions] = localInstructions
        }
        
        // Keep local tip amount if it's higher (customer might have increased tip)
        if let localTip = local[CloudKitSchema.Order.tipCents] as? Int,
           let serverTip = server[CloudKitSchema.Order.tipCents] as? Int,
           localTip > serverTip {
            resolved[CloudKitSchema.Order.tipCents] = localTip
            
            // Recalculate total
            if let subtotal = resolved[CloudKitSchema.Order.subtotalCents] as? Int,
               let deliveryFee = resolved[CloudKitSchema.Order.deliveryFeeCents] as? Int,
               let platformFee = resolved[CloudKitSchema.Order.platformFeeCents] as? Int,
               let tax = resolved[CloudKitSchema.Order.taxCents] as? Int {
                resolved[CloudKitSchema.Order.totalCents] = subtotal + deliveryFee + platformFee + tax + localTip
            }
        }
        
        return resolved
    }
    
    private func mergeUserProfileRecords(local: CKRecord, server: CKRecord, resolved: CKRecord) throws -> CKRecord {
        // For user profiles, prefer local changes for personal information
        if let localPhone = local[CloudKitSchema.UserProfile.phoneNumber] as? String,
           !localPhone.isEmpty {
            resolved[CloudKitSchema.UserProfile.phoneNumber] = localPhone
        }
        
        if let localEmail = local[CloudKitSchema.UserProfile.email] as? String,
           !localEmail.isEmpty {
            resolved[CloudKitSchema.UserProfile.email] = localEmail
        }
        
        // Always use the most recent lastActiveAt
        if let localLastActive = local[CloudKitSchema.UserProfile.lastActiveAt] as? Date,
           let serverLastActive = server[CloudKitSchema.UserProfile.lastActiveAt] as? Date {
            resolved[CloudKitSchema.UserProfile.lastActiveAt] = max(localLastActive, serverLastActive)
        }
        
        return resolved
    }
    
    private func mergeDriverLocationRecords(local: CKRecord, server: CKRecord, resolved: CKRecord) throws -> CKRecord {
        // For driver locations, always prefer the most recent timestamp
        if let localTimestamp = local[CloudKitSchema.DriverLocation.timestamp] as? Date,
           let serverTimestamp = server[CloudKitSchema.DriverLocation.timestamp] as? Date {
            
            if localTimestamp > serverTimestamp {
                // Use local record data but with server's change tag
                resolved[CloudKitSchema.DriverLocation.latitude] = local[CloudKitSchema.DriverLocation.latitude]
                resolved[CloudKitSchema.DriverLocation.longitude] = local[CloudKitSchema.DriverLocation.longitude]
                resolved[CloudKitSchema.DriverLocation.heading] = local[CloudKitSchema.DriverLocation.heading]
                resolved[CloudKitSchema.DriverLocation.speed] = local[CloudKitSchema.DriverLocation.speed]
                resolved[CloudKitSchema.DriverLocation.accuracy] = local[CloudKitSchema.DriverLocation.accuracy]
                resolved[CloudKitSchema.DriverLocation.timestamp] = localTimestamp
            }
        }
        
        return resolved
    }
    
    // MARK: - Batch Conflict Resolution
    
    /// Resolve multiple conflicts in a batch operation
    func resolveBatchConflicts(
        conflicts: [(local: CKRecord, server: CKRecord)],
        strategy: ConflictResolutionStrategy = .timestampBased
    ) throws -> [CKRecord] {
        
        return try conflicts.map { conflict in
            try resolveConflict(
                localRecord: conflict.local,
                serverRecord: conflict.server,
                strategy: strategy
            )
        }
    }
    
    // MARK: - Conflict Detection
    
    /// Check if two records have conflicts
    func hasConflict(local: CKRecord, server: CKRecord) -> Bool {
        // Records conflict if they have different change tags and modification dates
        guard local.recordChangeTag != server.recordChangeTag else {
            return false
        }
        
        let localModDate = local.modificationDate ?? Date.distantPast
        let serverModDate = server.modificationDate ?? Date.distantPast
        
        // Consider it a conflict if modification dates are different
        return abs(localModDate.timeIntervalSince(serverModDate)) > 1.0 // 1 second tolerance
    }
    
    // MARK: - Conflict Logging
    
    /// Log conflict resolution for debugging and analytics
    private func logConflictResolution(
        recordType: String,
        recordID: String,
        strategy: ConflictResolutionStrategy,
        resolution: String
    ) {
        print("🔄 Conflict resolved for \(recordType) (\(recordID)): \(strategy) -> \(resolution)")
        
        // In production, send this to analytics service
        // AnalyticsService.shared.trackConflictResolution(...)
    }
}