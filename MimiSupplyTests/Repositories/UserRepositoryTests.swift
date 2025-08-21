//
//  UserRepositoryTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
@testable import MimiSupply

/// Unit tests for UserRepository
final class UserRepositoryTests: XCTestCase {
    
    var userRepository: UserRepository!
    var mockCloudKitService: MockCloudKitService!
    var mockKeychainService: MockKeychainService!
    
    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        mockKeychainService = MockKeychainService()
        
        userRepository = UserRepositoryImpl(
            cloudKitService: mockCloudKitService,
            keychainService: mockKeychainService
        )
    }
    
    override func tearDown() {
        userRepository = nil
        mockKeychainService = nil
        mockCloudKitService = nil
        super.tearDown()
    }
    
    // MARK: - User Creation Tests
    
    func testCreateUserSuccess() async throws {
        // Given
        let newUser = createTestUser()
        
        // When
        let createdUser = try await userRepository.createUser(newUser)
        
        // Then
        XCTAssertEqual(createdUser.id, newUser.id)
        XCTAssertEqual(createdUser.email, newUser.email)
        XCTAssertTrue(mockCloudKitService.savedUserProfile != nil)
        XCTAssertTrue(mockKeychainService.storedKeys.contains("user_profile_\(newUser.id)"))
    }
    
    func testCreateUserCloudKitFailure() async throws {
        // Given
        let newUser = createTestUser()
        mockCloudKitService.shouldThrowError = true
        
        // When/Then
        do {
            _ = try await userRepository.createUser(newUser)
            XCTFail("Should have thrown CloudKit error")
        } catch {
            XCTAssertTrue(error is CloudKitError)
        }
    }
    
    // MARK: - User Retrieval Tests
    
    func testGetUserByIdSuccess() async throws {
        // Given
        let testUser = createTestUser()
        mockCloudKitService.mockUserProfile = testUser
        
        // When
        let retrievedUser = try await userRepository.getUser(by: testUser.id)
        
        // Then
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.id, testUser.id)
        XCTAssertEqual(retrievedUser?.email, testUser.email)
    }
    
    func testGetUserByIdNotFound() async throws {
        // Given
        mockCloudKitService.mockUserProfile = nil
        
        // When
        let retrievedUser = try await userRepository.getUser(by: "nonexistent-id")
        
        // Then
        XCTAssertNil(retrievedUser)
    }
    
    func testGetUserByAppleIdSuccess() async throws {
        // Given
        let testUser = createTestUser()
        mockCloudKitService.mockUserProfile = testUser
        
        // When
        let retrievedUser = try await userRepository.getUserByAppleId(testUser.appleUserID)
        
        // Then
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.appleUserID, testUser.appleUserID)
    }
    
    // MARK: - User Update Tests
    
    func testUpdateUserSuccess() async throws {
        // Given
        let originalUser = createTestUser()
        let updatedUser = UserProfile(
            id: originalUser.id,
            appleUserID: originalUser.appleUserID,
            email: "updated@example.com",
            fullName: PersonNameComponents(givenName: "Updated", familyName: "User"),
            role: .driver,
            phoneNumber: "+1987654321",
            profileImageURL: URL(string: "https://example.com/updated.jpg"),
            isVerified: true,
            createdAt: originalUser.createdAt,
            lastActiveAt: Date()
        )
        
        // When
        let result = try await userRepository.updateUser(updatedUser)
        
        // Then
        XCTAssertEqual(result.email, "updated@example.com")
        XCTAssertEqual(result.role, .driver)
        XCTAssertEqual(result.phoneNumber, "+1987654321")
        XCTAssertTrue(mockCloudKitService.savedUserProfile != nil)
    }
    
    func testUpdateUserKeychainFailure() async throws {
        // Given
        let user = createTestUser()
        mockKeychainService.shouldThrowOnStore = true
        
        // When/Then
        do {
            _ = try await userRepository.updateUser(user)
            XCTFail("Should have thrown keychain error")
        } catch {
            XCTAssertTrue(error is KeychainError)
        }
    }
    
    // MARK: - User Deletion Tests
    
    func testDeleteUserSuccess() async throws {
        // Given
        let user = createTestUser()
        mockKeychainService.storedValues["user_profile_\(user.id)"] = try JSONEncoder().encode(user)
        
        // When
        try await userRepository.deleteUser(user.id)
        
        // Then
        XCTAssertTrue(mockKeychainService.deletedKeys.contains("user_profile_\(user.id)"))
    }
    
    func testDeleteUserNotFound() async throws {
        // Given
        let userId = "nonexistent-user"
        
        // When/Then
        do {
            try await userRepository.deleteUser(userId)
            XCTFail("Should have thrown user not found error")
        } catch {
            XCTAssertTrue(error is UserRepositoryError)
        }
    }
    
    // MARK: - Role Management Tests
    
    func testUpdateUserRole() async throws {
        // Given
        let user = createTestUser(role: .customer)
        mockCloudKitService.mockUserProfile = user
        
        // When
        let updatedUser = try await userRepository.updateUserRole(user.id, to: .partner)
        
        // Then
        XCTAssertEqual(updatedUser.role, .partner)
        XCTAssertTrue(mockCloudKitService.savedUserProfile?.role == .partner)
    }
    
    func testGetUsersByRole() async throws {
        // Given
        let customers = [
            createTestUser(id: "customer-1", role: .customer),
            createTestUser(id: "customer-2", role: .customer)
        ]
        let drivers = [
            createTestUser(id: "driver-1", role: .driver)
        ]
        
        mockCloudKitService.mockUserProfiles = customers + drivers
        
        // When
        let customerUsers = try await userRepository.getUsersByRole(.customer)
        let driverUsers = try await userRepository.getUsersByRole(.driver)
        
        // Then
        XCTAssertEqual(customerUsers.count, 2)
        XCTAssertEqual(driverUsers.count, 1)
        XCTAssertTrue(customerUsers.allSatisfy { $0.role == .customer })
        XCTAssertTrue(driverUsers.allSatisfy { $0.role == .driver })
    }
    
    // MARK: - User Verification Tests
    
    func testVerifyUser() async throws {
        // Given
        let user = createTestUser(isVerified: false)
        mockCloudKitService.mockUserProfile = user
        
        // When
        let verifiedUser = try await userRepository.verifyUser(user.id)
        
        // Then
        XCTAssertTrue(verifiedUser.isVerified)
        XCTAssertTrue(mockCloudKitService.savedUserProfile?.isVerified == true)
    }
    
    func testGetVerifiedUsers() async throws {
        // Given
        let users = [
            createTestUser(id: "verified-1", isVerified: true),
            createTestUser(id: "unverified-1", isVerified: false),
            createTestUser(id: "verified-2", isVerified: true)
        ]
        
        mockCloudKitService.mockUserProfiles = users
        
        // When
        let verifiedUsers = try await userRepository.getVerifiedUsers()
        
        // Then
        XCTAssertEqual(verifiedUsers.count, 2)
        XCTAssertTrue(verifiedUsers.allSatisfy { $0.isVerified })
    }
    
    // MARK: - User Activity Tests
    
    func testUpdateLastActiveTime() async throws {
        // Given
        let user = createTestUser()
        mockCloudKitService.mockUserProfile = user
        let newActiveTime = Date()
        
        // When
        let updatedUser = try await userRepository.updateLastActiveTime(user.id, to: newActiveTime)
        
        // Then
        XCTAssertEqual(updatedUser.lastActiveAt.timeIntervalSince1970, 
                      newActiveTime.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testGetActiveUsers() async throws {
        // Given
        let recentTime = Date().addingTimeInterval(-300) // 5 minutes ago
        let oldTime = Date().addingTimeInterval(-7200) // 2 hours ago
        
        let users = [
            createTestUser(id: "active-1", lastActiveAt: recentTime),
            createTestUser(id: "inactive-1", lastActiveAt: oldTime),
            createTestUser(id: "active-2", lastActiveAt: Date())
        ]
        
        mockCloudKitService.mockUserProfiles = users
        
        // When
        let activeUsers = try await userRepository.getActiveUsers(since: Date().addingTimeInterval(-3600))
        
        // Then
        XCTAssertEqual(activeUsers.count, 2)
        XCTAssertTrue(activeUsers.contains { $0.id == "active-1" })
        XCTAssertTrue(activeUsers.contains { $0.id == "active-2" })
    }
    
    // MARK: - Cache Management Tests
    
    func testCacheUserProfile() async throws {
        // Given
        let user = createTestUser()
        
        // When
        try await userRepository.cacheUserProfile(user)
        
        // Then
        XCTAssertTrue(mockKeychainService.storedKeys.contains("user_profile_\(user.id)"))
        
        let cachedUser: UserProfile? = try mockKeychainService.retrieve(UserProfile.self, for: "user_profile_\(user.id)")
        XCTAssertNotNil(cachedUser)
        XCTAssertEqual(cachedUser?.id, user.id)
    }
    
    func testGetCachedUserProfile() async throws {
        // Given
        let user = createTestUser()
        try mockKeychainService.store(user, for: "user_profile_\(user.id)")
        
        // When
        let cachedUser = try await userRepository.getCachedUserProfile(user.id)
        
        // Then
        XCTAssertNotNil(cachedUser)
        XCTAssertEqual(cachedUser?.id, user.id)
    }
    
    func testClearUserCache() async throws {
        // Given
        let user = createTestUser()
        try mockKeychainService.store(user, for: "user_profile_\(user.id)")
        
        // When
        try await userRepository.clearUserCache(user.id)
        
        // Then
        XCTAssertTrue(mockKeychainService.deletedKeys.contains("user_profile_\(user.id)"))
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(
        id: String = "test-user-123",
        role: UserRole = .customer,
        isVerified: Bool = false,
        lastActiveAt: Date = Date()
    ) -> UserProfile {
        return UserProfile(
            id: id,
            appleUserID: "apple-\(id)",
            email: "test@example.com",
            fullName: PersonNameComponents(givenName: "Test", familyName: "User"),
            role: role,
            phoneNumber: "+1234567890",
            profileImageURL: URL(string: "https://example.com/profile.jpg"),
            isVerified: isVerified,
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            lastActiveAt: lastActiveAt
        )
    }
}

// MARK: - User Repository Error Types

enum UserRepositoryError: Error, LocalizedError {
    case userNotFound
    case invalidUserData
    case updateFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidUserData:
            return "Invalid user data"
        case .updateFailed:
            return "Failed to update user"
        case .deleteFailed:
            return "Failed to delete user"
        }
    }
}

// MARK: - Mock Extensions

extension MockCloudKitService {
    var mockUserProfiles: [UserProfile] {
        get { [] }
        set { /* Mock implementation */ }
    }
}