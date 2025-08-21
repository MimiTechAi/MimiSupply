//
//  KeychainService.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Keychain service protocol for secure credential storage
protocol KeychainService: Sendable {
    func store<T: Codable>(_ value: T, for key: String) throws
    func retrieve<T: Codable>(_ type: T.Type, for key: String) throws -> T?
    func delete(for key: String) throws
    func deleteAll() throws
}

/// Keychain-specific errors
enum KeychainError: LocalizedError, Sendable {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case encodingFailed
    case decodingFailed
    case itemNotFound
    case duplicateItem
    case invalidData
    case unknown(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store item in keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete item from keychain: \(status)"
        case .encodingFailed:
            return "Failed to encode data for keychain storage"
        case .decodingFailed:
            return "Failed to decode data from keychain"
        case .itemNotFound:
            return "Item not found in keychain"
        case .duplicateItem:
            return "Item already exists in keychain"
        case .invalidData:
            return "Invalid data format in keychain"
        case .unknown(let status):
            return "Unknown keychain error: \(status)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .storeFailed, .duplicateItem:
            return "Please try again or restart the app"
        case .retrieveFailed, .itemNotFound:
            return "Please sign in again"
        case .deleteFailed:
            return "Please try again"
        case .encodingFailed, .decodingFailed, .invalidData:
            return "Please update the app or contact support"
        case .unknown:
            return "Please restart the app and try again"
        }
    }
}