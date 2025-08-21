//
//  UserRepositoryImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Implementation of UserRepository for managing user data
final class UserRepositoryImpl: UserRepository, @unchecked Sendable {
    
    private let cloudKitService: CloudKitService
    private let keychainService: KeychainService
    
    private let currentUserKey = "current_user"
    
    init(cloudKitService: CloudKitService, keychainService: KeychainService) {
        self.cloudKitService = cloudKitService
        self.keychainService = keychainService
    }
    
    func saveUser(_ user: UserProfile) async throws {
        // Save to CloudKit
        try await cloudKitService.saveUserProfile(user)
        
        // Cache locally in Keychain
        try keychainService.store(user, for: currentUserKey)
    }
    
    func fetchUser(by appleUserID: String) async throws -> UserProfile? {
        return try await cloudKitService.fetchUserProfile(by: appleUserID)
    }
    
    func fetchCurrentUser() async throws -> UserProfile? {
        // Try to get from local cache first
        if let cachedUser: UserProfile = try keychainService.retrieve(UserProfile.self, for: currentUserKey) {
            return cachedUser
        }
        
        // If not cached, return nil (user needs to authenticate)
        return nil
    }
    
    func updateUser(_ user: UserProfile) async throws {
        try await saveUser(user)
    }
    
    func deleteUser(_ userId: String) async throws {
        // Remove from local cache
        try keychainService.delete(for: currentUserKey)
        
        // TODO: Implement CloudKit user deletion if needed
    }
}