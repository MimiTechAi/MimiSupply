import SwiftUI
import PhotosUI
import Combine

@MainActor
class PartnerSettingsViewModel: ObservableObject {
    // Business Profile
    @Published var businessName: String = ""
    @Published var businessDescription: String = ""
    @Published var category: PartnerCategory = .restaurant
    @Published var logoURL: URL?
    @Published var selectedLogo: PhotosPickerItem?
    
    // Contact Information
    @Published var phoneNumber: String = ""
    @Published var email: String = ""
    @Published var website: String = ""
    
    // Address
    @Published var streetAddress: String = ""
    @Published var city: String = ""
    @Published var state: String = ""
    @Published var zipCode: String = ""
    
    // Verification
    @Published var isVerified: Bool = false
    
    // Notifications
    @Published var notifyNewOrders: Bool = true
    @Published var notifyOrderUpdates: Bool = true
    @Published var notifyMarketing: Bool = false
    
    // UI State
    @Published var isSaving: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingVerification: Bool = false
    @Published var showingPasswordChange: Bool = false
    @Published var showingPrivacyPolicy: Bool = false
    @Published var showingTermsOfService: Bool = false
    @Published var showingDeleteConfirmation: Bool = false
    
    private let cloudKitService: CloudKitService
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        authService: AuthenticationService = AuthenticationServiceImpl.shared
    ) {
        self.cloudKitService = cloudKitService
        self.authService = authService
        
        setupImageSelection()
    }
    
    func loadSettings() async {
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            let partner = try await cloudKitService.fetchPartner(by: currentUser.id)
            
            // Update UI with partner data
            guard let partner = partner else {
                throw AppError.dataNotFound("Partner profile not found")
            }
            
            businessName = partner.name
            businessDescription = partner.description
            category = partner.category
            logoURL = partner.logoURL
            phoneNumber = partner.phoneNumber ?? ""
            email = partner.email ?? ""
            isVerified = partner.isVerified
            
            // Address
            streetAddress = partner.address.street
            city = partner.address.city
            state = partner.address.state
            zipCode = partner.address.postalCode
            
            // Load notification preferences
            let preferences = try await cloudKitService.fetchNotificationPreferences(for: currentUser.id)
            notifyNewOrders = preferences.newOrders
            notifyOrderUpdates = preferences.orderUpdates
            notifyMarketing = preferences.marketing
            
        } catch {
            handleError(error)
        }
    }
    
    func saveSettings() async {
        isSaving = true
        
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            // Upload new logo if selected
            var newLogoURL = logoURL
            if let selectedLogo = selectedLogo {
                newLogoURL = try await uploadLogo(selectedLogo)
            }
            
            // Create updated partner data
            let updatedPartner = PartnerUpdateData(
                name: businessName,
                description: businessDescription,
                category: category,
                logoURL: newLogoURL,
                phoneNumber: phoneNumber,
                email: email,
                address: Address(
                    street: streetAddress,
                    city: city,
                    state: state,
                    postalCode: zipCode,
                    country: "US"
                )
            )
            
            try await cloudKitService.updatePartner(
                partnerId: currentUser.id,
                data: updatedPartner
            )
            
            // Save notification preferences
            let preferences = NotificationPreferences(
                newOrders: notifyNewOrders,
                orderUpdates: notifyOrderUpdates,
                marketing: notifyMarketing
            )
            
            try await cloudKitService.updateNotificationPreferences(
                for: currentUser.id,
                preferences: preferences
            )
            
        } catch {
            handleError(error)
        }
        
        isSaving = false
    }
    
    func deleteAccount() async {
        do {
            guard let currentUser = await authService.currentUser else {
                throw AppError.authentication(.notAuthenticated)
            }
            
            try await cloudKitService.deletePartnerAccount(partnerId: currentUser.id)
            try await authService.signOut()
            
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupImageSelection() {
        $selectedLogo
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.loadSelectedImage(item)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSelectedImage(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                throw AppError.validation(.invalidImageData)
            }
            
            // Create a temporary URL for preview
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpg")
            
            if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: tempURL)
                logoURL = tempURL
            }
            
        } catch {
            handleError(error)
        }
    }
    
    private func uploadLogo(_ item: PhotosPickerItem) async throws -> URL {
        guard let data = try await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else {
            throw AppError.validation(.invalidImageData)
        }
        
        // Resize and compress image
        let resizedImage = uiImage.resized(to: CGSize(width: 300, height: 300))
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw AppError.validation(.invalidImageData)
        }
        
        // Upload to CloudKit
        return try await cloudKitService.uploadImage(jpegData, type: .partnerLogo)
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// MARK: - CloudKit Service Extensions
extension CloudKitService {
    func fetchNotificationPreferences(for userId: String) async throws -> NotificationPreferences {
        // Mock implementation
        return NotificationPreferences(
            newOrders: true,
            orderUpdates: true,
            marketing: false
        )
    }
    
    func updatePartner(partnerId: String, data: PartnerUpdateData) async throws {
        // Implementation would update partner data in CloudKit
        print("Updating partner: \(partnerId)")
        print("Data: \(data)")
    }
    
    func updateNotificationPreferences(for userId: String, preferences: NotificationPreferences) async throws {
        // Implementation would update notification preferences in CloudKit
        print("Updating notification preferences for user: \(userId)")
        print("Preferences: \(preferences)")
    }
    
    func deletePartnerAccount(partnerId: String) async throws {
        // Implementation would delete partner account and all associated data
        print("Deleting partner account: \(partnerId)")
    }
    
    func uploadImage(_ data: Data, type: ImageType) async throws -> URL {
        // Implementation would upload image to CloudKit and return URL
        // For now, return a mock URL
        return URL(string: "https://example.com/uploaded-image.jpg")!
    }
}

// MARK: - Supporting Types
struct PartnerUpdateData {
    let name: String
    let description: String
    let category: PartnerCategory
    let logoURL: URL?
    let phoneNumber: String
    let email: String
    let address: Address
}

struct NotificationPreferences {
    let newOrders: Bool
    let orderUpdates: Bool
    let marketing: Bool
}

enum ImageType {
    case partnerLogo
    case productImage
    case heroImage
}

// ValidationError is now defined in Foundation/Error/AppError.swift
// Using specific cases: .invalidEmail, .invalidPhoneNumber, etc.

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
