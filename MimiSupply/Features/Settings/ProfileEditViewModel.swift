//
//  ProfileEditViewModel.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import Foundation
import SwiftUI
import PhotosUI
import Combine

/// ViewModel for profile editing with validation and photo upload
@MainActor
final class ProfileEditViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var email = ""
    @Published var phoneNumber = ""
    @Published var userRole: UserRole?
    @Published var profileImageURL: URL?
    @Published var selectedImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    @Published var isLoading = false
    @Published var isUploadingPhoto = false
    @Published var saveSuccessful = false
    @Published var errorMessage: String?
    @Published var showingPhotoPicker = false
    
    // Validation errors
    @Published var firstNameError: String?
    @Published var lastNameError: String?
    @Published var emailError: String?
    @Published var phoneNumberError: String?
    
    // MARK: - Dependencies
    
    private let authService: AuthenticationService
    private let cloudKitService: CloudKitService
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        firstNameError == nil &&
        lastNameError == nil &&
        phoneNumberError == nil
    }
    
    // MARK: - Initialization
    
    init(
        authService: AuthenticationService? = nil,
        cloudKitService: CloudKitService? = nil
    ) {
        // Access AppContainer.shared properties on MainActor
        self.authService = authService ?? AppContainer.shared.authenticationService
        self.cloudKitService = cloudKitService ?? AppContainer.shared.cloudKitService
        
        setupValidation()
    }
    
    // MARK: - Profile Management
    
    func loadCurrentProfile() async {
        isLoading = true
        errorMessage = nil
        
        if let profile = await authService.currentUser {
            firstName = profile.fullName?.givenName ?? ""
            lastName = profile.fullName?.familyName ?? ""
            email = profile.email ?? ""
            phoneNumber = profile.phoneNumber ?? ""
            userRole = profile.role
            profileImageURL = profile.profileImageURL
        }
        
        isLoading = false
    }
    
    func saveProfile() async {
        guard isFormValid else {
            errorMessage = "Please fix validation errors before saving"
            return
        }
        
        isLoading = true
        errorMessage = nil
        saveSuccessful = false
        
        do {
            // Create updated profile
            guard let currentProfile = await authService.currentUser else {
                throw ProfileEditError.noCurrentProfile
            }
            
            var nameComponents = PersonNameComponents()
            nameComponents.givenName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            nameComponents.familyName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            let updatedProfile = UserProfile(
                id: currentProfile.id,
                appleUserID: currentProfile.appleUserID,
                email: currentProfile.email, // Email cannot be changed
                fullName: nameComponents,
                role: currentProfile.role,
                phoneNumber: trimmedPhoneNumber.isEmpty ? nil : trimmedPhoneNumber,
                profileImageURL: profileImageURL,
                isVerified: currentProfile.isVerified,
                createdAt: currentProfile.createdAt,
                lastActiveAt: Date()
            )
            
            // Upload photo if selected
            if let selectedImage = selectedImage {
                profileImageURL = try await uploadProfilePhoto(selectedImage)
            }
            
            // Save updated profile
            _ = try await authService.updateUserProfile(updatedProfile)
            
            saveSuccessful = true
            
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Photo Management
    
    func loadSelectedPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        isUploadingPhoto = true
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            errorMessage = "Failed to load selected photo: \(error.localizedDescription)"
        }
        
        isUploadingPhoto = false
    }
    
    private func uploadProfilePhoto(_ image: UIImage) async throws -> URL {
        // Resize image for optimal upload
        let resizedImage = image.resized(to: CGSize(width: 300, height: 300))
        
        guard resizedImage.jpegData(compressionQuality: 0.8) != nil else {
            throw ProfileEditError.imageProcessingFailed
        }
        
        // In a real implementation, this would upload to CloudKit or another service
        // For now, we'll simulate the upload
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Return a mock URL - in real implementation, this would be the uploaded image URL
        return URL(string: "https://example.com/profile-images/\(UUID().uuidString).jpg")!
    }
    
    // MARK: - Validation
    
    private func setupValidation() {
        // First name validation
        $firstName
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateFirstName(value)
            }
            .store(in: &cancellables)
        
        // Last name validation
        $lastName
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validateLastName(value)
            }
            .store(in: &cancellables)
        
        // Phone number validation
        $phoneNumber
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.validatePhoneNumber(value)
            }
            .store(in: &cancellables)
    }
    
    private func validateFirstName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            firstNameError = "First name is required"
        } else if trimmed.count < 2 {
            firstNameError = "First name must be at least 2 characters"
        } else if trimmed.count > 50 {
            firstNameError = "First name must be less than 50 characters"
        } else if !trimmed.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "'" }) {
            firstNameError = "First name can only contain letters, spaces, hyphens, and apostrophes"
        } else {
            firstNameError = nil
        }
    }
    
    private func validateLastName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            lastNameError = "Last name is required"
        } else if trimmed.count < 2 {
            lastNameError = "Last name must be at least 2 characters"
        } else if trimmed.count > 50 {
            lastNameError = "Last name must be less than 50 characters"
        } else if !trimmed.allSatisfy({ $0.isLetter || $0.isWhitespace || $0 == "-" || $0 == "'" }) {
            lastNameError = "Last name can only contain letters, spaces, hyphens, and apostrophes"
        } else {
            lastNameError = nil
        }
    }
    
    private func validatePhoneNumber(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            phoneNumberError = nil // Phone number is optional
            return
        }
        
        // Remove all non-digit characters for validation
        let digitsOnly = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digitsOnly.count < 10 {
            phoneNumberError = "Phone number must be at least 10 digits"
        } else if digitsOnly.count > 15 {
            phoneNumberError = "Phone number must be less than 15 digits"
        } else {
            phoneNumberError = nil
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Supporting Types

enum ProfileEditError: LocalizedError {
    case noCurrentProfile
    case imageProcessingFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .noCurrentProfile:
            return "No current profile found"
        case .imageProcessingFailed:
            return "Failed to process selected image"
        case .uploadFailed:
            return "Failed to upload profile photo"
        }
    }
}

// UIImage extension is defined in Features/Partner/PartnerSettingsViewModel.swift

