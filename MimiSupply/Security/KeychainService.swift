//
//  KeychainService.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import Security
import CryptoKit
import os

// MARK: - Secure Keychain Service

@MainActor
final class KeychainService: ObservableObject {
    static let shared = KeychainService()
    
    private let logger = Logger(subsystem: "MimiSupply", category: "Keychain")
    private let serviceName = "com.mimisupply.app"
    private let accessGroup: String?
    
    private init() {
        // Configure access group for app extensions if needed
        self.accessGroup = nil // Set to your app group if using extensions
        logger.info("🔐 KeychainService initialized")
    }
    
    // MARK: - Generic Keychain Operations
    
    func store<T: Codable>(_ item: T, forKey key: String, accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly) throws {
        let data = try JSONEncoder().encode(item)
        try storeData(data, forKey: key, accessibility: accessibility)
    }
    
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try retrieveData(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
    
    func storeData(_ data: Data, forKey key: String, accessibility: KeychainAccessibility = .whenUnlockedThisDeviceOnly) throws {
        // Delete existing item first
        try? deleteItem(forKey: key)
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.secAccessibility
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            logger.error("❌ Failed to store keychain item: \(key), status: \(status)")
            throw KeychainError.storeFailed(status)
        }
        
        logger.debug("✅ Stored keychain item: \(key)")
    }
    
    func retrieveData(forKey key: String) throws -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidData
            }
            logger.debug("✅ Retrieved keychain item: \(key)")
            return data
            
        case errSecItemNotFound:
            logger.debug("ℹ️ Keychain item not found: \(key)")
            return nil
            
        default:
            logger.error("❌ Failed to retrieve keychain item: \(key), status: \(status)")
            throw KeychainError.retrieveFailed(status)
        }
    }
    
    func deleteItem(forKey key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("❌ Failed to delete keychain item: \(key), status: \(status)")
            throw KeychainError.deleteFailed(status)
        }
        
        logger.debug("🗑️ Deleted keychain item: \(key)")
    }
    
    func itemExists(forKey key: String) -> Bool {
        do {
            return try retrieveData(forKey: key) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Encryption Keys
    
    func storeSymmetricKey(_ key: SymmetricKey) {
        let keyData = key.withUnsafeBytes { Data($0) }
        do {
            try storeData(keyData, forKey: "symmetric_key", accessibility: .whenUnlockedThisDeviceOnly)
        } catch {
            logger.error("❌ Failed to store symmetric key: \(error)")
        }
    }
    
    func getSymmetricKey() -> SymmetricKey? {
        do {
            guard let keyData = try retrieveData(forKey: "symmetric_key"),
                  keyData.count == 32 else { return nil }
            return SymmetricKey(data: keyData)
        } catch {
            logger.error("❌ Failed to retrieve symmetric key: \(error)")
            return nil
        }
    }
    
    func storePrivateKey(_ key: P256.Signing.PrivateKey) {
        let keyData = key.rawRepresentation
        do {
            try storeData(keyData, forKey: "private_key", accessibility: .whenUnlockedThisDeviceOnly)
        } catch {
            logger.error("❌ Failed to store private key: \(error)")
        }
    }
    
    func getPrivateKey() -> P256.Signing.PrivateKey? {
        do {
            guard let keyData = try retrieveData(forKey: "private_key") else { return nil }
            return try P256.Signing.PrivateKey(rawRepresentation: keyData)
        } catch {
            logger.error("❌ Failed to retrieve private key: \(error)")
            return nil
        }
    }
    
    // MARK: - Authentication Tokens
    
    func storeAuthToken(_ token: AuthToken) throws {
        try store(token, forKey: "auth_token", accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    func getAuthToken() -> AuthToken? {
        return try? retrieve(AuthToken.self, forKey: "auth_token")
    }
    
    func deleteAuthToken() throws {
        try deleteItem(forKey: "auth_token")
    }
    
    // MARK: - Biometric Authentication Data
    
    func storeBiometricData(_ data: BiometricAuthData) throws {
        try store(data, forKey: "biometric_auth", accessibility: .biometryCurrentSet)
    }
    
    func getBiometricData() -> BiometricAuthData? {
        return try? retrieve(BiometricAuthData.self, forKey: "biometric_auth")
    }
    
    func deleteBiometricData() throws {
        try deleteItem(forKey: "biometric_auth")
    }
    
    // MARK: - User Credentials
    
    func storeUserCredentials(_ credentials: UserCredentials) throws {
        try store(credentials, forKey: "user_credentials", accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    func getUserCredentials() -> UserCredentials? {
        return try? retrieve(UserCredentials.self, forKey: "user_credentials")
    }
    
    func deleteUserCredentials() throws {
        try deleteItem(forKey: "user_credentials")
    }
    
    // MARK: - Secure Notes
    
    func storeSecureNote(_ note: String, forKey key: String) throws {
        let noteData = Data(note.utf8)
        try storeData(noteData, forKey: "note_\(key)", accessibility: .whenUnlockedThisDeviceOnly)
    }
    
    func getSecureNote(forKey key: String) -> String? {
        do {
            guard let noteData = try retrieveData(forKey: "note_\(key)") else { return nil }
            return String(data: noteData, encoding: .utf8)
        } catch {
            logger.error("❌ Failed to retrieve secure note: \(error)")
            return nil
        }
    }
    
    func deleteSecureNote(forKey key: String) throws {
        try deleteItem(forKey: "note_\(key)")
    }
    
    // MARK: - Bulk Operations
    
    func getAllKeychainItems() throws -> [KeychainItem] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let items = result as? [[String: Any]] else {
            throw KeychainError.invalidData
        }
        
        return items.compactMap { item in
            guard let account = item[kSecAttrAccount as String] as? String,
                  let data = item[kSecValueData as String] as? Data else {
                return nil
            }
            
            return KeychainItem(
                key: account,
                data: data,
                creationDate: item[kSecAttrCreationDate as String] as? Date,
                modificationDate: item[kSecAttrModificationDate as String] as? Date
            )
        }
    }
    
    func deleteAllKeychainItems() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        logger.info("🗑️ Deleted all keychain items")
    }
    
    // MARK: - Certificate Storage
    
    func storeCertificate(_ certificate: SecCertificate, forKey key: String) throws {
        let certificateData = SecCertificateCopyData(certificate)
        let data = CFDataCreateCopy(nil, certificateData)!
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
        
        logger.debug("✅ Stored certificate: \(key)")
    }
    
    func getCertificate(forKey key: String) throws -> SecCertificate? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: key,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            return result as? SecCertificate
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.retrieveFailed(status)
        }
    }
    
    // MARK: - Migration and Backup
    
    func migrateKeychainItems(from oldVersion: String, to newVersion: String) throws {
        logger.info("🔄 Starting keychain migration from \(oldVersion) to \(newVersion)")
        
        let items = try getAllKeychainItems()
        
        for item in items {
            // Apply migration logic based on version
            if oldVersion == "1.0" && newVersion == "2.0" {
                // Example migration: re-encrypt data with new key
                try migrateItemV1ToV2(item)
            }
        }
        
        logger.info("✅ Keychain migration completed")
    }
    
    private func migrateItemV1ToV2(_ item: KeychainItem) throws {
        // Example migration logic
        logger.debug("Migrating item: \(item.key)")
        // Re-store with new encryption or format
    }
    
    func exportKeychainBackup() throws -> KeychainBackup {
        let items = try getAllKeychainItems()
        return KeychainBackup(
            version: "2.0",
            timestamp: Date(),
            items: items.map { item in
                KeychainBackupItem(
                    key: item.key,
                    encryptedData: item.data.base64EncodedString(),
                    creationDate: item.creationDate,
                    modificationDate: item.modificationDate
                )
            }
        )
    }
    
    func importKeychainBackup(_ backup: KeychainBackup) throws {
        logger.info("📥 Importing keychain backup (version: \(backup.version))")
        
        for backupItem in backup.items {
            guard let data = Data(base64Encoded: backupItem.encryptedData) else {
                logger.error("❌ Invalid backup data for key: \(backupItem.key)")
                continue
            }
            
            try storeData(data, forKey: backupItem.key)
        }
        
        logger.info("✅ Keychain backup import completed")
    }
}

// MARK: - Data Models

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let tokenType: String
    let scope: [String]
}

struct BiometricAuthData: Codable {
    let userID: String
    let isEnabled: Bool
    let biometricType: BiometricType
    let createdAt: Date
    let lastUsedAt: Date?
}

struct UserCredentials: Codable {
    let username: String
    let hashedPassword: String
    let salt: Data
    let createdAt: Date
}

struct KeychainItem {
    let key: String
    let data: Data
    let creationDate: Date?
    let modificationDate: Date?
}

struct KeychainBackup: Codable {
    let version: String
    let timestamp: Date
    let items: [KeychainBackupItem]
}

struct KeychainBackupItem: Codable {
    let key: String
    let encryptedData: String
    let creationDate: Date?
    let modificationDate: Date?
}

// MARK: - Enums

enum KeychainAccessibility {
    case whenUnlockedThisDeviceOnly
    case whenUnlocked
    case afterFirstUnlockThisDeviceOnly
    case afterFirstUnlock
    case whenPasscodeSetThisDeviceOnly
    case biometryCurrentSet
    case biometryAny
    
    var secAccessibility: CFString {
        switch self {
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .biometryCurrentSet:
            return kSecAttrAccessibleBiometryCurrentSet
        case .biometryAny:
            return kSecAttrAccessibleBiometryAny
        }
    }
}

enum BiometricType: String, Codable {
    case touchID = "Touch ID"
    case faceID = "Face ID"
    case none = "None"
}

// MARK: - Errors

enum KeychainError: Error, LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidData
    case itemNotFound
    case duplicateItem
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store keychain item (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve keychain item (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete keychain item (status: \(status))"
        case .invalidData:
            return "Invalid keychain data"
        case .itemNotFound:
            return "Keychain item not found"
        case .duplicateItem:
            return "Keychain item already exists"
        case .accessDenied:
            return "Access to keychain item denied"
        }
    }
}