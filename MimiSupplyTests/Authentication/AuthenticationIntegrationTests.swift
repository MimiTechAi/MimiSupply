//
//  AuthenticationIntegrationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import Combine
@testable import MimiSupply

final class AuthenticationIntegrationTests: XCTestCase {
    
    private var authenticationManager: AuthenticationManager!
    private var mockAuthService: MockAuthenticationService!
    private var cancellables: Set<AnyCancellable>!
    
    @MainActor
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        cancellables = Set<AnyCancellable>()
        
        // Create authentication manager with mock service
        authenticationManager = AuthenticationManager(authenticationService: mockAuthService)
    }
    
    override func tearDown() {
        cancellables = nil
        authenticationManager = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Authentication Flow Tests
    
    @MainActor
    func testCompleteAuthenticationFlow() async throws {
        // Given: Unauthenticated state
        XCTAssertEqual(authenticationManager.authenticationState, .unauthenticated)
        
        // When: User signs in with Apple
        let testUser = createTestUser()
        mockAuthService.mockAuthResult = AuthenticationResult(
            user: testUser,
            isNewUser: true,
            requiresRoleSelection: true
        )
        
        await authenticationManager.signInWithApple()
        
        // Then: Should show role selection
        XCTAssertTrue(authenticationManager.isShowingRoleSelection)
        
        // When: User selects role
        await authenticationManager.selectRole(.driver)
        
        // Then: Should be authenticated with selected role
        if case .authenticated(let user) = authenticationManager.authenticationState {
            XCTAssertEqual(user.role, .driver)
        } else {
            XCTFail("Expected authenticated state")
        }
        
        XCTAssertFalse(authenticationManager.isShowingRoleSelection)
    }
    
    @MainActor
    func testAuthenticationFlowWithExistingUser() async throws {
        // Given: Existing user sign in
        let testUser = createTestUser(role: .customer)
        mockAuthService.mockAuthResult = AuthenticationResult(
            user: testUser,
            isNewUser: false,
            requiresRoleSelection: false
        )
        
        // When: User signs in
        await authenticationManager.signInWithApple()
        
        // Then: Should be directly authenticated without role selection
        if case .authenticated(let user) = authenticationManager.authenticationState {
            XCTAssertEqual(user.role, .customer)
        } else {
            XCTFail("Expected authenticated state")
        }
        
        XCTAssertFalse(authenticationManager.isShowingRoleSelection)
    }
    
    @MainActor
    func testSignOutFlow() async throws {
        // Given: Authenticated user
        let testUser = createTestUser()
        mockAuthService.mockCurrentUser = testUser
        mockAuthService.mockAuthState = .authenticated(testUser)
        
        // When: User signs out
        await authenticationManager.signOut()
        
        // Then: Should be unauthenticated
        XCTAssertEqual(authenticationManager.authenticationState, .unauthenticated)
        XCTAssertTrue(mockAuthService.signOutCalled)
    }
    
    @MainActor
    func testAuthenticationErrorHandling() async throws {
        // Given: Authentication will fail
        mockAuthService.shouldThrowError = true
        mockAuthService.errorToThrow = AuthenticationError.userCancelled
        
        // When: User attempts sign in
        await authenticationManager.signInWithApple()
        
        // Then: Should show error
        XCTAssertTrue(authenticationManager.isShowingAuthenticationError)
        XCTAssertEqual(authenticationManager.currentError, .userCancelled)
    }
    
    @MainActor
    func testRoleSelectionErrorHandling() async throws {
        // Given: Role selection will fail
        let testUser = createTestUser()
        mockAuthService.mockAuthState = .roleSelectionRequired(testUser)
        mockAuthService.shouldThrowOnRoleUpdate = true
        
        // When: User selects role
        await authenticationManager.selectRole(.driver)
        
        // Then: Should show error
        XCTAssertTrue(authenticationManager.isShowingAuthenticationError)
        XCTAssertNotNil(authenticationManager.currentError)
    }
    
    // MARK: - State Management Tests
    
    @MainActor
    func testAuthenticationStatePublisher() async throws {
        // Given: State publisher subscription
        var receivedStates: [AuthenticationState] = []
        let expectation = XCTestExpectation(description: "State changes received")
        expectation.expectedFulfillmentCount = 2
        
        authenticationManager.$authenticationState
            .sink { state in
                receivedStates.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When: Authentication state changes
        let testUser = createTestUser()
        mockAuthService.mockAuthState = .authenticated(testUser)
        mockAuthService.stateSubject.send(.authenticated(testUser))
        
        // Then: Should receive state updates
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStates.count, 2)
    }
    
    @MainActor
    func testAutomaticStateManagement() async throws {
        // Given: Authentication manager
        let testUser = createTestUser()
        
        // When: Service state changes automatically
        mockAuthService.stateSubject.send(.authenticated(testUser))
        
        // Wait for state propagation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Manager should reflect the change
        if case .authenticated(let user) = authenticationManager.authenticationState {
            XCTAssertEqual(user.id, testUser.id)
        } else {
            XCTFail("Expected authenticated state")
        }
    }
    
    // MARK: - Permission Integration Tests
    
    @MainActor
    func testPermissionCheckIntegration() async throws {
        // Given: Authenticated customer
        let customerUser = createTestUser(role: .customer)
        mockAuthService.mockCurrentUser = customerUser
        mockAuthService.mockAuthState = .authenticated(customerUser)
        
        // When: Checking permissions
        let canPlaceOrder = await authenticationManager.hasPermission(for: .placeOrder)
        let canAcceptJobs = await authenticationManager.hasPermission(for: .acceptDeliveryJobs)
        
        // Then: Should have correct permissions
        XCTAssertTrue(canPlaceOrder)
        XCTAssertFalse(canAcceptJobs)
    }
    
    // MARK: - Profile Management Integration Tests
    
    @MainActor
    func testProfileUpdateIntegration() async throws {
        // Given: Authenticated user
        var testUser = createTestUser()
        mockAuthService.mockCurrentUser = testUser
        mockAuthService.mockAuthState = .authenticated(testUser)
        
        // When: Updating profile
        testUser = UserProfile(
            id: testUser.id,
            appleUserID: testUser.appleUserID,
            email: "updated@example.com",
            fullName: testUser.fullName,
            role: testUser.role,
            phoneNumber: "+9876543210",
            profileImageURL: testUser.profileImageURL,
            isVerified: testUser.isVerified,
            createdAt: testUser.createdAt,
            lastActiveAt: Date()
        )
        
        await authenticationManager.updateUserProfile(testUser)
        
        // Then: Should update successfully
        XCTAssertTrue(mockAuthService.updateProfileCalled)
        
        if case .authenticated(let user) = authenticationManager.authenticationState {
            XCTAssertEqual(user.email, "updated@example.com")
            XCTAssertEqual(user.phoneNumber, "+9876543210")
        } else {
            XCTFail("Expected authenticated state")
        }
    }
    
    @MainActor
    func testAccountDeletionIntegration() async throws {
        // Given: Authenticated user
        let testUser = createTestUser()
        mockAuthService.mockCurrentUser = testUser
        mockAuthService.mockAuthState = .authenticated(testUser)
        
        // When: Deleting account
        await authenticationManager.deleteAccount()
        
        // Then: Should delete account and sign out
        XCTAssertTrue(mockAuthService.deleteAccountCalled)
        XCTAssertEqual(authenticationManager.authenticationState, .unauthenticated)
    }
    
    // MARK: - Error Recovery Tests
    
    @MainActor
    func testErrorRecovery() async throws {
        // Given: Error state
        mockAuthService.shouldThrowError = true
        mockAuthService.errorToThrow = AuthenticationError.networkUnavailable
        
        await authenticationManager.signInWithApple()
        
        XCTAssertTrue(authenticationManager.isShowingAuthenticationError)
        
        // When: Dismissing error and retrying
        authenticationManager.dismissError()
        
        XCTAssertFalse(authenticationManager.isShowingAuthenticationError)
        XCTAssertNil(authenticationManager.currentError)
        
        // When: Retrying with success
        mockAuthService.shouldThrowError = false
        mockAuthService.mockAuthResult = AuthenticationResult(
            user: createTestUser(),
            isNewUser: false,
            requiresRoleSelection: false
        )
        
        await authenticationManager.signInWithApple()
        
        // Then: Should succeed
        if case .authenticated = authenticationManager.authenticationState {
            // Success
        } else {
            XCTFail("Expected authenticated state after retry")
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
}

// Mock services are now in MockServices.swift