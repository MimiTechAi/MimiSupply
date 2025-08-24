//
//  EncryptionService.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import CryptoKit
import Security
import CommonCrypto
import os

// MARK: - Advanced Encryption Service

@MainActor
final class EncryptionService: ObservableObject {
    static let shared = EncryptionService()
    
    private let logger = Logger(subsystem: "MimiSupply", category: "Encryption")
    private let keychainService: KeychainService
    
    // Encryption keys
    private var symmetricKey: SymmetricKey?
    private var privateKey: P256.Signing.PrivateKey?
    private var publicKey: P256.Signing.PublicKey?
    
    private init() {
        self.keychainService = KeychainService.shared
        setupEncryptionKeys()
    }
    
    // MARK: - Key Management
    
    private func setupEncryptionKeys() {
        // Load or generate symmetric key for data encryption
        if let existingKey = keychainService.getSymmetricKey() {
            symmetricKey = existingKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            keychainService.storeSymmetricKey(newKey)
            symmetricKey = newKey
        }
        
        // Load or generate asymmetric keys for signing
        if let existingPrivateKey = keychainService.getPrivateKey() {
            privateKey = existingPrivateKey
            publicKey = existingPrivateKey.publicKey
        } else {
            let newPrivateKey = P256.Signing.PrivateKey()
            keychainService.storePrivateKey(newPrivateKey)
            privateKey = newPrivateKey
            publicKey = newPrivateKey.publicKey
        }
        
        logger.info("🔐 Encryption keys initialized successfully")
    }
    
    // MARK: - Data Encryption
    
    /// Encrypt sensitive data using AES-GCM
    func encryptData<T: Codable>(_ data: T) throws -> EncryptedData {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        // Serialize to JSON
        let jsonData = try JSONEncoder().encode(data)
        
        // Encrypt using AES-GCM
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        let result = EncryptedData(
            data: encryptedData,
            algorithm: .aesGCM,
            keyId: getKeyIdentifier(),
            timestamp: Date()
        )
        
        logger.debug("🔒 Data encrypted successfully (size: \(encryptedData.count) bytes)")
        return result
    }
    
    /// Decrypt data
    func decryptData<T: Codable>(_ encryptedData: EncryptedData, type: T.Type) throws -> T {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        // Verify key ID matches
        guard encryptedData.keyId == getKeyIdentifier() else {
            throw EncryptionError.invalidKeyId
        }
        
        // Decrypt using AES-GCM
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData.data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        // Deserialize from JSON
        let result = try JSONDecoder().decode(T.self, from: decryptedData)
        
        logger.debug("🔓 Data decrypted successfully")
        return result
    }
    
    // MARK: - String Encryption (for simple values)
    
    func encryptString(_ string: String) throws -> String {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let data = Data(string.utf8)
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        return encryptedData.base64EncodedString()
    }
    
    func decryptString(_ encryptedString: String) throws -> String {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        guard let encryptedData = Data(base64Encoded: encryptedString) else {
            throw EncryptionError.invalidData
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let result = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidData
        }
        
        return result
    }
    
    // MARK: - Digital Signatures
    
    func signData<T: Codable>(_ data: T) throws -> DigitalSignature {
        guard let privateKey = privateKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let jsonData = try JSONEncoder().encode(data)
        let hash = SHA256.hash(data: jsonData)
        let signature = try privateKey.signature(for: Data(hash))
        
        return DigitalSignature(
            signature: signature.rawRepresentation,
            algorithm: .p256ECDSA,
            timestamp: Date(),
            dataHash: Data(hash)
        )
    }
    
    func verifySignature<T: Codable>(_ signature: DigitalSignature, for data: T) throws -> Bool {
        guard let publicKey = publicKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let jsonData = try JSONEncoder().encode(data)
        let hash = SHA256.hash(data: jsonData)
        
        // Verify hash matches
        guard Data(hash) == signature.dataHash else {
            throw EncryptionError.signatureVerificationFailed
        }
        
        let signatureObject = try P256.Signing.ECDSASignature(rawRepresentation: signature.signature)
        return publicKey.isValidSignature(signatureObject, for: Data(hash))
    }
    
    // MARK: - Password Hashing
    
    func hashPassword(_ password: String, salt: Data? = nil) throws -> PasswordHash {
        let saltData = salt ?? generateSalt()
        
        // Use PBKDF2 with SHA-256
        let passwordData = password.data(using: .utf8)!
        var derivedKey = Data(count: 32) // 256 bits
        
        let status = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            saltData.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordData.withUnsafeBytes { $0.bindMemory(to: Int8.self).baseAddress },
                    passwordData.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    saltData.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    100_000, // iterations
                    derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress,
                    32
                )
            }
        }
        
        guard status == kCCSuccess else {
            throw EncryptionError.hashingFailed
        }
        
        return PasswordHash(
            hash: derivedKey,
            salt: saltData,
            algorithm: .pbkdf2SHA256,
            iterations: 100_000
        )
    }
    
    func verifyPassword(_ password: String, against hash: PasswordHash) throws -> Bool {
        let candidateHash = try hashPassword(password, salt: hash.salt)
        return candidateHash.hash == hash.hash
    }
    
    // MARK: - File Encryption
    
    func encryptFile(at url: URL) throws -> URL {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let fileData = try Data(contentsOf: url)
        let sealedBox = try AES.GCM.seal(fileData, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }
        
        let encryptedURL = url.appendingPathExtension("encrypted")
        try encryptedData.write(to: encryptedURL)
        
        logger.info("📁 File encrypted: \(url.lastPathComponent)")
        return encryptedURL
    }
    
    func decryptFile(at url: URL, to destinationURL: URL) throws {
        guard let key = symmetricKey else {
            throw EncryptionError.keyNotAvailable
        }
        
        let encryptedData = try Data(contentsOf: url)
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        try decryptedData.write(to: destinationURL)
        
        logger.info("📁 File decrypted: \(url.lastPathComponent)")
    }
    
    // MARK: - Key Rotation
    
    func rotateKeys() throws {
        logger.info("🔄 Starting key rotation")
        
        // Generate new keys
        let newSymmetricKey = SymmetricKey(size: .bits256)
        let newPrivateKey = P256.Signing.PrivateKey()
        
        // Store old keys for data migration
        let oldSymmetricKey = symmetricKey
        let oldPrivateKey = privateKey
        
        // Update current keys
        symmetricKey = newSymmetricKey
        privateKey = newPrivateKey
        publicKey = newPrivateKey.publicKey
        
        // Store new keys
        keychainService.storeSymmetricKey(newSymmetricKey)
        keychainService.storePrivateKey(newPrivateKey)
        
        // Notify about key rotation
        NotificationCenter.default.post(
            name: .encryptionKeysRotated,
            object: self,
            userInfo: [
                "oldSymmetricKey": oldSymmetricKey as Any,
                "oldPrivateKey": oldPrivateKey as Any
            ]
        )
        
        logger.info("✅ Key rotation completed successfully")
    }
    
    // MARK: - Utilities
    
    private func generateSalt() -> Data {
        var salt = Data(count: 32)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!) }
        return salt
    }
    
    private func getKeyIdentifier() -> String {
        // Generate a stable identifier for the current key
        guard let key = symmetricKey else { return "unknown" }
        let keyData = key.withUnsafeBytes { Data($0) }
        let hash = SHA256.hash(data: keyData)
        return Data(hash).prefix(8).base64EncodedString()
    }
    
    // MARK: - Memory Security
    
    func securelyWipeMemory(_ data: inout Data) {
        data.withUnsafeMutableBytes { bytes in
            memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
        }
    }
    
    func securelyWipeString(_ string: inout String) {
        string.withUTF8 { buffer in
            memset_s(UnsafeMutableRawPointer(mutating: buffer.baseAddress), buffer.count, 0, buffer.count)
        }
        string = ""
    }
}

// MARK: - Data Models

struct EncryptedData: Codable {
    let data: Data
    let algorithm: EncryptionAlgorithm
    let keyId: String
    let timestamp: Date
}

struct DigitalSignature: Codable {
    let signature: Data
    let algorithm: SignatureAlgorithm
    let timestamp: Date
    let dataHash: Data
}

struct PasswordHash: Codable {
    let hash: Data
    let salt: Data
    let algorithm: HashAlgorithm
    let iterations: Int
}

enum EncryptionAlgorithm: String, Codable {
    case aesGCM = "AES-GCM"
    case chaChaPoly = "ChaCha20-Poly1305"
}

enum SignatureAlgorithm: String, Codable {
    case p256ECDSA = "P256-ECDSA"
    case ed25519 = "Ed25519"
}

enum HashAlgorithm: String, Codable {
    case pbkdf2SHA256 = "PBKDF2-SHA256"
    case argon2id = "Argon2id"
}

// MARK: - Errors

enum EncryptionError: Error, LocalizedError {
    case keyNotAvailable
    case encryptionFailed
    case decryptionFailed
    case invalidKeyId
    case invalidData
    case signatureVerificationFailed
    case hashingFailed
    
    var errorDescription: String? {
        switch self {
        case .keyNotAvailable:
            return "Encryption key not available"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidKeyId:
            return "Invalid encryption key identifier"
        case .invalidData:
            return "Invalid data format"
        case .signatureVerificationFailed:
            return "Digital signature verification failed"
        case .hashingFailed:
            return "Password hashing failed"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let encryptionKeysRotated = Notification.Name("encryptionKeysRotated")
}

// MARK: - Preview

#if DEBUG
struct EncryptionService_Preview: View {
    @StateObject private var encryptionService = EncryptionService.shared
    @State private var plainText = "Hello, World!"
    @State private var encryptedText = ""
    @State private var decryptedText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Encryption Service Demo")
                .font(.title)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Plain Text:")
                    .font(.headline)
                TextField("Enter text to encrypt", text: $plainText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button("Encrypt") {
                do {
                    encryptedText = try encryptionService.encryptString(plainText)
                } catch {
                    print("Encryption failed: \(error)")
                }
            }
            .padding()
            .background(Color.emerald)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            if !encryptedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Encrypted Text:")
                        .font(.headline)
                    Text(encryptedText)
                        .font(.caption.monospaced())
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Button("Decrypt") {
                do {
                    decryptedText = try encryptionService.decryptString(encryptedText)
                } catch {
                    print("Decryption failed: \(error)")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(encryptedText.isEmpty)
            
            if !decryptedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Decrypted Text:")
                        .font(.headline)
                    Text(decryptedText)
                        .font(.body)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}
#endif