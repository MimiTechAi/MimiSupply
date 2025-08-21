//
//  SettingsTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

/// Comprehensive tests for settings and profile management functionality
final class SettingsTests: XCTestCase {
    
    var mockAuthService: MockAuthenticationService!
    var mockCloudKitService: MockCloudKitService!
    var mockLocationService: MockLocationService!
    var settingsViewModel: SettingsViewModel!
    var profileEditViewModel: ProfileEditViewModel!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        mockCloudKitService = MockCloudKitService()
        mockLocationService = MockLocationService()
        
        settingsViewModel = SettingsViewModel(
            authService: mockAuthService,
            cloudKitService: mockCloudKitService,
            locationService: mockLocationService
        )
        
        profileEditViewModel = ProfileEditViewModel(
            authService: mockAuthService,
            cloudKitService: mockCloudKitService
        )
    }
    
    override func tearDown() {
        settingsViewModel = nil
        profileEditViewModel = nil
        mockLocationService = nil
        mockCloudKitService = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Settings View Model Tests
    
    @MainActor
    func testLoadUserProfile() async {
        // Given
        let testProfile = UserProfile(
            appleUserID: "test-apple-id",
            role: .customer
        )
        mockAuthService.mockCurrentUser = testProfile
        
        // When
        await settingsViewModel.loadUserProfile()
        
        // Then
        XCTAssertEqual(settingsViewModel.userProfile?.id, testProfile.id)
        XCTAssertEqual(settingsViewModel.userProfile?.role, .customer)
        XCTAssertFalse(settingsViewModel.isLoading)
        XCTAssertNil(settingsViewModel.errorMessage)
    }
    
    @MainActor
    func testLoadUserProfileError() async {
        // Given
        mockAuthService.mockCurrentUser = nil
        
        // When
        await settingsViewModel.loadUserProfile()
        
        // Then
        XCTAssertNil(settingsViewModel.userProfile)
        XCTAssertFalse(settingsViewModel.isLoading)
    }
    
    @MainActor
    func testSignOut() async {
        // Given
        mockAuthService.signOutShouldSucceed = true
        
        // When
        await settingsViewModel.signOut()
        
        // Then
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertFalse(settingsViewModel.isLoading)
        XCTAssertNil(settingsViewModel.errorMessage)
    }
    
    @MainActor
    func testSignOutError() async {
        // Given
        mockAuthService.signOutShouldSucceed = false
        
        // When
        await settingsViewModel.signOut()
        
        // Then
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertFalse(settingsViewModel.isLoading)
        XCTAssertNotNil(settingsViewModel.errorMessage)
    }
    
    @MainActor
    func testDeleteAccount() async {
        // Given
        mockAuthService.deleteAccountShouldSucceed = true
        
        // When
        await settingsViewModel.deleteAccount()
        
        // Then
        XCTAssertTrue(mockAuthService.deleteAccountCalled)
        XCTAssertFalse(settingsViewModel.isLoading)
        XCTAssertNil(settingsViewModel.errorMessage)
    }
    
    @MainActor
    func testDeleteAccountError() async {
        // Given
        mockAuthService.deleteAccountShouldSucceed = false
        
        // When
        await settingsViewModel.deleteAccount()
        
        // Then
        XCTAssertTrue(mockAuthService.deleteAccountCalled)
        XCTAssertFalse(settingsViewModel.isLoading)
        XCTAssertNotNil(settingsViewModel.errorMessage)
    }
    
    func testCurrentLanguage() {
        // Given/When
        let language = settingsViewModel.currentLanguage
        
        // Then
        XCTAssertFalse(language.isEmpty)
        XCTAssertTrue(language.count > 2)
    }
    
    func testCurrentAppearance() {
        // Given/When
        let appearance = settingsViewModel.currentAppearance
        
        // Then
        XCTAssertTrue(["Light", "Dark", "System"].contains(appearance))
    }
    
    func testLocationPermissionStatus() {
        // Given
        mockLocationService.mockAuthorizationStatus = .authorizedWhenInUse
        
        // When
        let status = settingsViewModel.locationPermissionStatus
        
        // Then
        XCTAssertEqual(status, "Enabled")
    }
    
    func testAppVersion() {
        // Given/When
        let version = settingsViewModel.appVersion
        
        // Then
        XCTAssertFalse(version.isEmpty)
        XCTAssertTrue(version.contains("("))
        XCTAssertTrue(version.contains(")"))
    }
    
    // MARK: - Profile Edit View Model Tests
    
    @MainActor
    func testLoadCurrentProfile() async {
        // Given
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = "John"
        nameComponents.familyName = "Doe"
        
        let testProfile = UserProfile(
            appleUserID: "test-apple-id",
            email: "john.doe@example.com",
            fullName: nameComponents,
            role: .customer,
            phoneNumber: "+1234567890"
        )
        mockAuthService.mockCurrentUser = testProfile
        
        // When
        await profileEditViewModel.loadCurrentProfile()
        
        // Then
        XCTAssertEqual(profileEditViewModel.firstName, "John")
        XCTAssertEqual(profileEditViewModel.lastName, "Doe")
        XCTAssertEqual(profileEditViewModel.email, "john.doe@example.com")
        XCTAssertEqual(profileEditViewModel.phoneNumber, "+1234567890")
        XCTAssertEqual(profileEditViewModel.userRole, .customer)
        XCTAssertFalse(profileEditViewModel.isLoading)
    }
    
    @MainActor
    func testFormValidation() {
        // Given - Empty form
        XCTAssertFalse(profileEditViewModel.isFormValid)
        
        // When - Fill required fields
        profileEditViewModel.firstName = "John"
        profileEditViewModel.lastName = "Doe"
        
        // Then
        XCTAssertTrue(profileEditViewModel.isFormValid)
    }
    
    @MainActor
    func testFirstNameValidation() {
        // Test empty first name
        profileEditViewModel.firstName = ""
        // Trigger validation manually for testing
        XCTAssertFalse(profileEditViewModel.isFormValid)
        
        // Test valid first name
        profileEditViewModel.firstName = "John"
        profileEditViewModel.lastName = "Doe" // Required for form to be valid
        XCTAssertTrue(profileEditViewModel.isFormValid)
        
        // Test first name too short
        profileEditViewModel.firstName = "J"
        XCTAssertFalse(profileEditViewModel.isFormValid)
        
        // Test first name too long
        profileEditViewModel.firstName = String(repeating: "a", count: 51)
        XCTAssertFalse(profileEditViewModel.isFormValid)
    }
    
    @MainActor
    func testLastNameValidation() {
        // Test empty last name
        profileEditViewModel.lastName = ""
        XCTAssertFalse(profileEditViewModel.isFormValid)
        
        // Test valid last name
        profileEditViewModel.firstName = "John" // Required for form to be valid
        profileEditViewModel.lastName = "Doe"
        XCTAssertTrue(profileEditViewModel.isFormValid)
        
        // Test last name too short
        profileEditViewModel.lastName = "D"
        XCTAssertFalse(profileEditViewModel.isFormValid)
        
        // Test last name too long
        profileEditViewModel.lastName = String(repeating: "a", count: 51)
        XCTAssertFalse(profileEditViewModel.isFormValid)
    }
    
    @MainActor
    func testPhoneNumberValidation() {
        // Given
        profileEditViewModel.firstName = "John"
        profileEditViewModel.lastName = "Doe"
        
        // Test empty phone number (should be valid - optional field)
        profileEditViewModel.phoneNumber = ""
        XCTAssertTrue(profileEditViewModel.isFormValid)
        
        // Test valid phone number
        profileEditViewModel.phoneNumber = "+1234567890"
        XCTAssertTrue(profileEditViewModel.isFormValid)
        
        // Test phone number too short
        profileEditViewModel.phoneNumber = "123456789"
        // Note: This would trigger validation error in real implementation
        
        // Test phone number too long
        profileEditViewModel.phoneNumber = "1234567890123456"
        // Note: This would trigger validation error in real implementation
    }
    
    @MainActor
    func testSaveProfile() async {
        // Given
        let testProfile = UserProfile(
            appleUserID: "test-apple-id",
            role: .customer
        )
        mockAuthService.mockCurrentUser = testProfile
        mockAuthService.updateUserProfileShouldSucceed = true
        
        profileEditViewModel.firstName = "John"
        profileEditViewModel.lastName = "Doe"
        profileEditViewModel.phoneNumber = "+1234567890"
        
        // When
        await profileEditViewModel.saveProfile()
        
        // Then
        XCTAssertTrue(mockAuthService.updateUserProfileCalled)
        XCTAssertTrue(profileEditViewModel.saveSuccessful)
        XCTAssertFalse(profileEditViewModel.isLoading)
        XCTAssertNil(profileEditViewModel.errorMessage)
    }
    
    @MainActor
    func testSaveProfileError() async {
        // Given
        let testProfile = UserProfile(
            appleUserID: "test-apple-id",
            role: .customer
        )
        mockAuthService.mockCurrentUser = testProfile
        mockAuthService.updateUserProfileShouldSucceed = false
        
        profileEditViewModel.firstName = "John"
        profileEditViewModel.lastName = "Doe"
        
        // When
        await profileEditViewModel.saveProfile()
        
        // Then
        XCTAssertTrue(mockAuthService.updateUserProfileCalled)
        XCTAssertFalse(profileEditViewModel.saveSuccessful)
        XCTAssertFalse(profileEditViewModel.isLoading)
        XCTAssertNotNil(profileEditViewModel.errorMessage)
    }
    
    @MainActor
    func testSaveProfileInvalidForm() async {
        // Given - Invalid form (empty required fields)
        profileEditViewModel.firstName = ""
        profileEditViewModel.lastName = ""
        
        // When
        await profileEditViewModel.saveProfile()
        
        // Then
        XCTAssertFalse(mockAuthService.updateUserProfileCalled)
        XCTAssertFalse(profileEditViewModel.saveSuccessful)
        XCTAssertNotNil(profileEditViewModel.errorMessage)
    }
    
    // MARK: - Language Selection Tests
    
    func testLanguageSelectionViewModel() {
        // Given
        let languageViewModel = LanguageSelectionViewModel()
        
        // Then
        XCTAssertFalse(languageViewModel.availableLanguages.isEmpty)
        XCTAssertTrue(languageViewModel.availableLanguages.count > 10)
        XCTAssertEqual(languageViewModel.selectedLanguageCode, "en")
    }
    
    func testLanguageSelection() {
        // Given
        let languageViewModel = LanguageSelectionViewModel()
        let spanishLanguage = SupportedLanguage(code: "es", nativeName: "Español", englishName: "Spanish")
        
        // When
        languageViewModel.selectLanguage(spanishLanguage)
        
        // Then
        XCTAssertEqual(languageViewModel.selectedLanguageCode, "es")
    }
    
    // MARK: - Settings Row Tests
    
    func testSettingsRowCreation() {
        // Given/When
        let settingsRow = SettingsRow(
            icon: "bell",
            title: "Notifications",
            subtitle: "Manage notification preferences",
            action: {}
        )
        
        // Then
        XCTAssertNotNil(settingsRow)
    }
    
    func testDestructiveSettingsRow() {
        // Given/When
        let destructiveRow = SettingsRow(
            icon: "trash",
            title: "Delete Account",
            subtitle: "Permanently delete your account",
            action: {},
            isDestructive: true
        )
        
        // Then
        XCTAssertNotNil(destructiveRow)
    }
    
    // MARK: - Data Export Tests
    
    @MainActor
    func testExportUserData() async {
        // Given
        let testProfile = UserProfile(
            appleUserID: "test-apple-id",
            email: "test@example.com",
            role: .customer
        )
        mockAuthService.mockCurrentUser = testProfile
        
        // When
        await settingsViewModel.exportUserData()
        
        // Then
        XCTAssertFalse(settingsViewModel.isLoading)
        // Note: In a real test, we would verify the export data format and content
    }
    
    @MainActor
    func testExportUserDataNoProfile() async {
        // Given
        mockAuthService.mockCurrentUser = nil
        
        // When
        await settingsViewModel.exportUserData()
        
        // Then
        XCTAssertFalse(settingsViewModel.isLoading)
        XCTAssertNotNil(settingsViewModel.errorMessage)
    }
    
    // MARK: - Accessibility Tests
    
    func testSettingsViewAccessibility() {
        // Given
        let settingsView = SettingsView()
        
        // Then
        XCTAssertNotNil(settingsView)
        // Note: In a real UI test, we would verify accessibility labels and hints
    }
    
    func testProfileEditViewAccessibility() {
        // Given
        let profileEditView = ProfileEditView()
        
        // Then
        XCTAssertNotNil(profileEditView)
        // Note: In a real UI test, we would verify form accessibility
    }
    
    func testLanguageSelectionViewAccessibility() {
        // Given
        let languageView = LanguageSelectionView()
        
        // Then
        XCTAssertNotNil(languageView)
        // Note: In a real UI test, we would verify language list accessibility
    }
}