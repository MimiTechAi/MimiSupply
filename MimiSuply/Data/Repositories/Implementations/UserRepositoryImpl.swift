func saveUser(_ user: UserProfile) async throws {
        // Save to CloudKit
        try await cloudKitService.saveUserProfile(user)
        
        // Cache locally in Keychain
        await MainActor.run {
            Task {
                try await keychainService.store(user, forKey: currentUserKey)
            }
        }
    }
    
    func fetchUser(by appleUserID: String) async throws -> UserProfile? {
        return try await cloudKitService.fetchUserProfile(by: appleUserID)
    }
    
    func fetchCurrentUser() async throws -> UserProfile? {
        // Try to get from local cache first
        return await MainActor.run {
            Task {
                if let cachedUser: UserProfile = try await keychainService.retrieve(UserProfile.self, forKey: currentUserKey) {
                    return cachedUser
                }
                return nil
            }.value
        }
    }
    
    func updateUser(_ user: UserProfile) async throws {
        try await saveUser(user)
    }
    
    func deleteUser(_ userId: String) async throws {
        // Remove from local cache
        await MainActor.run {
            Task {
                try await keychainService.deleteItem(forKey: currentUserKey)
            }
        }
        
        // TODO: Implement CloudKit user deletion if needed
    }