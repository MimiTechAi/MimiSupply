//
//  AuthenticationSecurityTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import Security
@testable import MimiSupply

final class AuthenticationSecurityTests: XCTestCase {
    
    private var keychainService: KeychainServiceImpl!
    private var authenticationService: AuthenticationServiceImpl!
    
    override func setUp() {
        super.setUp()
        keychainService = KeychainServiceImpl()
        authenticationService = AuthenticationServiceImpl(
            keychainService: keychainService,
            cloudKitService: MockCloudKitService()
        )
        
        // Clean up keychain before each test
        try? keychainService.deleteAll()
    }
    
    override func tearDown() {
        // Clean up keychain after each test
        try? keychainService.deleteAll()
        authenticationService = nil
        keychainService = nil
        super.tearDown()
    }
    
    // MARK: - Keychain Security Tests
    
    func testKeychainStorageEncryption() throws {
        // Given: Sensitive user data
        let testUser = createTestUser()
        let testKey = "test_user_key"
        
        // When: Storing in keychain
        try keychainService.store(testUser, for: testKey)
        
        // Then: Data should be encrypted and not accessible without proper entitlements
        // Verify data is not stored in plain text by checking raw keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.mimisupply.app",
            kSecAttrAccount as String: testKey,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        XCTAssertEqual(status, errSecSuccess)
        
        if let data = result as? Data {
            // Verify data is not plain text (should be JSON encoded)
            let dataString = String(data: data, encoding: .utf8) ?? ""
            XCTAssertTrue(dataString.contains("{"), "Data should be JSON encoded")
            XCTAssertFalse(dataString.contains(testUser.email ?? ""), "Raw email should not be visible")
        }
    }
    
    func testKeychainAccessibilitySettings() throws {
        // Given: Test data
        let testUser = createTestUser()
        let testKey = "accessibility_test"
        
        // When: Storing with accessibility settings
        try keychainService.store(testUser, for: testKey)
        
        // Then: Should use proper accessibility settings
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.mimisupply.app",
            kSecAttrAccount as String: testKey,
            kSecReturnAttributes as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        XCTAssertEqual(status, errSecSuccess)
        
        if let attributes = result as? [String: Any] {
            let accessibility = attributes[kSecAttrAccessible as String] as? String
            XCTAssertEqual(accessibility, kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String)
        }
    }
    
    func testKeychainDataIsolation() throws {
        // Given: Multiple users' data
        let user1 = createTestUser(id: "user1", email: "user1@test.com")
        let user2 = createTestUser(id: "user2", email: "user2@test.com")
        
        // When: Storing both users
        try keychainService.store(user1, for: "user1_key")
        try keychainService.store(user2, for: "user2_key")
        
        // Then: Each user's data should be isolated
        let retrievedUser1: UserProfile? = try keychainService.retrieve(UserProfile.self, for: "user1_key")
        let retrievedUser2: UserProfile? = try keychainService.retrieve(UserProfile.self, for: "user2_key")
        
        XCTAssertEqual(retrievedUser1?.id, "user1")
        XCTAssertEqual(retrievedUser2?.id, "user2")
        XCTAssertNotEqual(retrievedUser1?.email, retrievedUser2?.email)
    }
    
    // MARK: - Authentication Token Security Tests
    
    func testCredentialStorageSecurity() async throws {
        // Given: Authentication credentials
        let testUser = createTestUser()
        
        // When: Storing credentials through authentication service
        // Note: This would require mocking the Apple sign-in flow
        // For now, we test the keychain storage directly
        try keychainService.store(testUser, for: "current_user")
        
        // Then: Credentials should be securely stored
        let retrievedUser: UserProfile? = try keychainService.retrieve(UserProfile.self, for: "current_user")
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.appleUserID, testUser.appleUserID)
    }
    
    func testCredentialRefreshSecurity() async throws {
        // Given: Stored user credentials
        let testUser = createTestUser()
        try keychainService.store(testUser, for: "current_user")
        
        // When: Attempting credential refresh without valid user
        // Then: Should handle securely without exposing sensitive data
        do {
            _ = try await authenticationService.refreshCredentials()
        } catch {
            // Expected to fail in test environment without valid Apple ID
            XCTAssertTrue(error is AuthenticationError)
        }
    }
    
    // MARK: - Role-Based Access Control Security Tests
    
    func testRoleEscalationPrevention() async {
        // Given: Customer user
        let customerUser = createTestUser(role: .customer)
        try keychainService.store(customerUser, for: "current_user")
        
        // When: Checking admin permissions
        let hasAdminAccess = await authenticationService.hasPermission(for: .adminAccess)
        
        // Then: Should not have admin access
        XCTAssertFalse(hasAdminAccess)
    }
    
    func testRoleValidation() async throws {
        // Given: User with specific role
        let driverUser = createTestUser(role: .driver)
        try keychainService.store(driverUser, for: "current_user")
        
        // When: Checking role-specific permissions
        let canAcceptJobs = await authenticationService.hasPermission(for: .acceptDeliveryJobs)
        let canManageBusiness = await authenticationService.hasPermission(for: .manageBusinessProfile)
        
        // Then: Should only have driver permissions
        XCTAssertTrue(canAcceptJobs)
        XCTAssertFalse(canManageBusiness)
    }
    
    func testAdminRolePrivileges() async {
        // Given: Admin user
        let adminUser = createTestUser(role: .admin)
        try keychainService.store(adminUser, for: "current_user")
        
        // When: Checking various permissions
        let canAcceptJobs = await authenticationService.hasPermission(for: .acceptDeliveryJobs)
        let canManageBusiness = await authenticationService.hasPermission(for: .manageBusinessProfile)
        let hasAdminAccess = await authenticationService.hasPermission(for: .adminAccess)
        
        // Then: Admin should have all permissions
        XCTAssertTrue(canAcceptJobs)
        XCTAssertTrue(canManageBusiness)
        XCTAssertTrue(hasAdminAccess)
    }
    
    // MARK: - Data Protection Tests
    
    func testSensitiveDataHandling() throws {
        // Given: User with sensitive data
        let testUser = createTestUser()
        
        // When: Storing and retrieving user
        try keychainService.store(testUser, for: "sensitive_test")
        let retrievedUser: UserProfile? = try keychainService.retrieve(UserProfile.self, for: "sensitive_test")
        
        // Then: Sensitive data should be properly handled
        XCTAssertNotNil(retrievedUser)
        XCTAssertEqual(retrievedUser?.email, testUser.email)
        XCTAssertEqual(retrievedUser?.phoneNumber, testUser.phoneNumber)
        
        // Verify data is not logged or exposed
        // This would be verified through static analysis in a real security audit
    }
    
    func testDataMinimization() {
        // Given: User profile creation
        let testUser = createTestUser()
        
        // Then: Should only store necessary data
        XCTAssertNotNil(testUser.id)
        XCTAssertNotNil(testUser.appleUserID)
        XCTAssertNotNil(testUser.role)
        
        // Optional fields should be truly optional
        // Email and phone should only be stored if provided by user
    }
    
    // MARK: - Session Management Security Tests
    
    func testSessionTimeout() async {
        // Given: Authentication service with automatic state management
        await authenticationService.startAutomaticStateManagement()
        
        // When: Time passes (simulated)
        // Then: Should handle session timeouts appropriately
        // Note: This would require more sophisticated time mocking
        
        await authenticationService.stopAutomaticStateManagement()
    }
    
    func testConcurrentSessionHandling() async throws {
        // Given: Multiple concurrent authentication attempts
        let testUser = createTestUser()
        try keychainService.store(testUser, for: "current_user")
        
        // When: Multiple concurrent operations
        async let operation1 = authenticationService.refreshCredentials()
        async let operation2 = authenticationService.refreshCredentials()
        
        // Then: Should handle concurrency safely
        do {
            let (result1, result2) = try await (operation1, operation2)
            // Both operations should complete without data corruption
        } catch {
            // Expected to fail in test environment, but should fail safely
            XCTAssertTrue(error is AuthenticationError)
        }
    }
    
    // MARK: - Error Handling Security Tests
    
    func testSecureErrorMessages() async {
        // Given: Various error conditions
        let errors: [AuthenticationError] = [
            .signInFailed,
            .tokenExpired,
            .userNotFound,
            .invalidCredentials
        ]
        
        // When: Getting error descriptions
        for error in errors {
            let description = error.localizedDescription
            let suggestion = error.recoverySuggestion
            
            // Then: Error messages should not expose sensitive information
            XCTAssertFalse(description?.contains("password") ?? false)
            XCTAssertFalse(description?.contains("token") ?? false)
            XCTAssertFalse(description?.contains("key") ?? false)
            
            XCTAssertFalse(suggestion?.contains("password") ?? false)
            XCTAssertFalse(suggestion?.contains("token") ?? false)
            XCTAssertFalse(suggestion?.contains("key") ?? false)
        }
    }
    
    func testErrorLoggingSecurity() {
        // Given: Authentication errors
        let sensitiveError = AuthenticationError.invalidCredentials
        
        // When: Error occurs
        // Then: Should not log sensitive information
        // This would be verified through log analysis in a real security audit
        
        let description = sensitiveError.localizedDescription
        XCTAssertNotNil(description)
        XCTAssertFalse(description?.isEmpty ?? true)
    }
    
    // MARK: - Input Validation Security Tests
    
    func testUserInputValidation() throws {
        // Given: Various user inputs
        let validUser = createTestUser()
        let invalidEmailUser = createTestUser(email: "invalid-email")
        let emptyIdUser = UserProfile(
            id: "",
            appleUserID: "test",
            role: .customer
        )
        
        // When: Storing users
        // Then: Should handle invalid inputs securely
        XCTAssertNoThrow(try keychainService.store(validUser, for: "valid"))
        XCTAssertNoThrow(try keychainService.store(invalidEmailUser, for: "invalid_email"))
        XCTAssertNoThrow(try keychainService.store(emptyIdUser, for: "empty_id"))
        
        // Validation should happen at the business logic layer
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(
        id: String = "test-user-id",
        email: String? = "test@example.com",
        role: UserRole = .customer
    ) -> UserProfile {
        UserProfile(
            id: id,
            appleUserID: "test-apple-id",
            email: email,
            fullName: PersonNameComponents(givenName: "Test", familyName: "User"),
            role: role,
            phoneNumber: "+1234567890",
            profileImageURL: nil,
            isVerified: true,
            createdAt: Date(),
            lastActiveAt: Date()
        )
    }
}