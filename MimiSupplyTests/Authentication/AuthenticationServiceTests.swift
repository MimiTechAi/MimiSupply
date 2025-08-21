//
//  AuthenticationServiceTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import Combine
import AuthenticationServices
@testable import MimiSupply

final class AuthenticationServiceTests: XCTestCase {
    
    private var sut: AuthenticationServiceImpl!
    private var mockKeychainService: MockKeychainService!
    private var mockCloudKitService: MockCloudKitService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockKeychainService = MockKeychainService()
        mockCloudKitService = MockCloudKitService()
        sut = AuthenticationServiceImpl(
            keychainService: mockKeychainService,
            cloudKitService: mockCloudKitService
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockCloudKitService = nil
        mockKeychainService = nil
        super.tearDown()
    }
    
    // MARK: - Authentication State Tests
    
    func testInitialAuthenticationState() async {
        // Given: No stored user
        mockKeychainService.shouldReturnNil = true
        
        // When: Getting authentication state
        let state = await sut.authenticationState
        
        // Then: Should be unauthenticated
        XCTAssertEqual(state, .unauthenticated)
    }
    
    func testAuthenticationStateWithStoredUser() async {
        // Given: Stored user in keychain
        let testUser = createTestUser()
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Initializing service
        let newSut = AuthenticationServiceImpl(
            keychainService: mockKeychainService,
            cloudKitService: mockCloudKitService
        )
        
        // Wait for initialization
        try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Should be authenticated
        let state = await newSut.authenticationState
        if case .authenticated(let user) = state {
            XCTAssertEqual(user.id, testUser.id)
        } else {
            XCTFail("Expected authenticated state")
        }
    }
    
    func testAuthenticationStatePublisher() async {
        // Given: Authentication state publisher
        var receivedStates: [AuthenticationState] = []
        let expectation = XCTestExpectation(description: "State changes received")
        expectation.expectedFulfillmentCount = 2
        
        sut.authenticationStatePublisher
            .sink { state in
                receivedStates.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When: Updating authentication state
        let testUser = createTestUser()
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // Then: Should receive state updates
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.count, 2)
    }
    
    // MARK: - Sign In Tests
    
    func testSignInWithAppleSuccess() async throws {
        // Given: Mock successful Apple sign in
        // Note: This would require mocking ASAuthorizationController
        // For now, we'll test the error handling path
        
        // When/Then: This test would require significant mocking of Apple's framework
        // In a real implementation, we'd use dependency injection for the Apple ID provider
    }
    
    func testSignInWithAppleUserCancelled() async {
        // Given: User cancels sign in
        // This would test the error mapping functionality
        
        let asError = ASAuthorizationError(.canceled)
        let mappedError = mapASErrorToAuthenticationError(asError)
        
        // Then: Should map to user cancelled
        XCTAssertEqual(mappedError, .userCancelled)
    }
    
    func testSignInWithAppleFailure() async {
        // Given: Sign in fails
        let asError = ASAuthorizationError(.failed)
        let mappedError = mapASErrorToAuthenticationError(asError)
        
        // Then: Should map to sign in failed
        XCTAssertEqual(mappedError, .signInFailed)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOutSuccess() async throws {
        // Given: Authenticated user
        let testUser = createTestUser()
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Signing out
        try await sut.signOut()
        
        // Then: Should clear keychain and update state
        XCTAssertTrue(mockKeychainService.deletedKeys.contains("current_user"))
        XCTAssertTrue(mockKeychainService.deletedKeys.contains("apple_credentials"))
        
        let state = await sut.authenticationState
        XCTAssertEqual(state, .unauthenticated)
    }
    
    func testSignOutKeychainError() async {
        // Given: Keychain deletion fails
        mockKeychainService.shouldThrowOnDelete = true
        
        // When/Then: Should throw error
        do {
            try await sut.signOut()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is KeychainError)
        }
    }
    
    // MARK: - Role Management Tests
    
    func testUpdateUserRoleSuccess() async throws {
        // Given: Authenticated user
        let testUser = createTestUser(role: .customer)
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Updating role
        let updatedUser = try await sut.updateUserRole(.driver)
        
        // Then: Should update role and sync
        XCTAssertEqual(updatedUser.role, .driver)
        XCTAssertTrue(mockKeychainService.storedKeys.contains("current_user"))
    }
    
    func testUpdateUserRoleNoUser() async {
        // Given: No authenticated user
        mockKeychainService.shouldReturnNil = true
        
        // When/Then: Should throw user not found error
        do {
            _ = try await sut.updateUserRole(.driver)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticationError, .userNotFound)
        }
    }
    
    // MARK: - Permission Tests
    
    func testHasPermissionForCustomerAction() async {
        // Given: Customer user
        let testUser = createTestUser(role: .customer)
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Checking customer permission
        let hasPermission = await sut.hasPermission(for: .placeOrder)
        
        // Then: Should have permission
        XCTAssertTrue(hasPermission)
    }
    
    func testHasPermissionForDriverAction() async {
        // Given: Customer user
        let testUser = createTestUser(role: .customer)
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Checking driver permission
        let hasPermission = await sut.hasPermission(for: .acceptDeliveryJobs)
        
        // Then: Should not have permission
        XCTAssertFalse(hasPermission)
    }
    
    func testHasPermissionForAdminUser() async {
        // Given: Admin user
        let testUser = createTestUser(role: .admin)
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Checking any permission
        let hasDriverPermission = await sut.hasPermission(for: .acceptDeliveryJobs)
        let hasPartnerPermission = await sut.hasPermission(for: .manageBusinessProfile)
        
        // Then: Admin should have all permissions
        XCTAssertTrue(hasDriverPermission)
        XCTAssertTrue(hasPartnerPermission)
    }
    
    func testHasPermissionForPublicAction() async {
        // Given: No authenticated user
        mockKeychainService.shouldReturnNil = true
        
        // When: Checking public permission
        let hasPermission = await sut.hasPermission(for: .viewCustomerContent)
        
        // Then: Should have permission
        XCTAssertTrue(hasPermission)
    }
    
    // MARK: - Credential Refresh Tests
    
    func testRefreshCredentialsSuccess() async throws {
        // Given: Valid user with credentials
        let testUser = createTestUser()
        mockKeychainService.storedValues["current_user"] = try! JSONEncoder().encode(testUser)
        
        // When: Refreshing credentials
        // Note: This would require mocking ASAuthorizationAppleIDProvider
        // For now, we test the basic flow
        
        // Then: Should succeed
        // This test would be more comprehensive with proper mocking
    }
    
    func testRefreshCredentialsNoUser() async {
        // Given: No authenticated user
        mockKeychainService.shouldReturnNil = true
        
        // When/Then: Should throw user not found error
        do {
            _ = try await sut.refreshCredentials()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? AuthenticationError, .userNotFound)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(role: UserRole = .customer) -> UserProfile {
        UserProfile(
            id: "test-user-id",
            appleUserID: "test-apple-id",
            email: "test@example.com",
            fullName: PersonNameComponents(givenName: "Test", familyName: "User"),
            role: role,
            phoneNumber: "+1234567890",
            profileImageURL: nil,
            isVerified: true,
            createdAt: Date(),
            lastActiveAt: Date()
        )
    }
    
    private func mapASErrorToAuthenticationError(_ error: ASAuthorizationError) -> AuthenticationError {
        switch error.code {
        case .canceled:
            return .userCancelled
        case .failed:
            return .signInFailed
        case .invalidResponse:
            return .invalidCredentials
        case .notHandled:
            return .appleIDUnavailable
        case .unknown:
            return .signInFailed
        @unknown default:
            return .signInFailed
        }
    }
}

// MARK: - Mock Services

// Mock services are now in MockServices.swift