//
//  ProfileEditView.swift
//  MimiSupply
//
//  Created by Kiro on 15.08.25.
//

import SwiftUI
import PhotosUI

/// Profile editing view with photo upload and validation
struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileEditViewModel()
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Profile Photo Section
                    profilePhotoSection
                    
                    // Personal Information Section
                    personalInfoSection
                    
                    // Contact Information Section
                    contactInfoSection
                    
                    // Role Information Section
                    roleInfoSection
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibleButton(
                        label: "Cancel",
                        hint: "Cancel profile editing"
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveProfile()
                            if viewModel.saveSuccessful {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                    .accessibleButton(
                        label: "Save",
                        hint: viewModel.isFormValid ? "Save profile changes" : "Complete required fields to save"
                    )
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .task {
            await viewModel.loadCurrentProfile()
        }
    }
    
    // MARK: - Profile Photo Section
    
    private var profilePhotoSection: some View {
        VStack(spacing: Spacing.md) {
            Text("Profile Photo")
                .font(.titleMedium.scaledFont())
                .foregroundColor(.graphite)
                .accessibleHeading(label: "Profile Photo", level: .h2)
            
            ZStack {
                // Current/Selected Photo
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else if let profileImageURL = viewModel.profileImageURL {
                    AsyncImage(url: profileImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray200)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray200)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray400)
                        )
                }
                
                // Upload Button Overlay
                Button(action: {
                    viewModel.showingPhotoPicker = true
                }) {
                    Circle()
                        .fill(Color.emerald)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                }
                .offset(x: 40, y: 40)
                .accessibleButton(
                    label: "Change profile photo",
                    hint: "Tap to select a new profile photo"
                )
            }
            
            if viewModel.isUploadingPhoto {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .emerald))
                        .scaleEffect(0.8)
                    
                    Text("Uploading photo...")
                        .font(.bodySmall.scaledFont())
                        .foregroundColor(.gray600)
                }
                .accessibilityLabel("Uploading photo")
            }
        }
        .photosPicker(
            isPresented: $viewModel.showingPhotoPicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.selectedPhotoItem) { _, newItem in
            Task {
                await viewModel.loadSelectedPhoto(from: newItem)
            }
        }
    }
    
    // MARK: - Personal Information Section
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Personal Information")
                .font(.titleMedium.scaledFont())
                .foregroundColor(.graphite)
                .accessibleHeading(label: "Personal Information", level: .h2)
            
            AppTextField(
                title: "First Name",
                placeholder: "Enter your first name",
                text: $viewModel.firstName,
                errorMessage: viewModel.firstNameError,
                accessibilityHint: "Enter your first name",
                accessibilityIdentifier: "first-name-field"
            )
            
            AppTextField(
                title: "Last Name",
                placeholder: "Enter your last name",
                text: $viewModel.lastName,
                errorMessage: viewModel.lastNameError,
                accessibilityHint: "Enter your last name",
                accessibilityIdentifier: "last-name-field"
            )
        }
    }
    
    // MARK: - Contact Information Section
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Contact Information")
                .font(.titleMedium.scaledFont())
                .foregroundColor(.graphite)
                .accessibleHeading(label: "Contact Information", level: .h2)
            
            AppTextField(
                title: "Email",
                placeholder: "Enter your email address",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                isDisabled: true, // Email from Apple ID cannot be changed
                errorMessage: viewModel.emailError,
                accessibilityHint: "Email address from your Apple ID",
                accessibilityIdentifier: "email-field"
            )
            
            AppTextField(
                title: "Phone Number",
                placeholder: "Enter your phone number",
                text: $viewModel.phoneNumber,
                keyboardType: .phonePad,
                errorMessage: viewModel.phoneNumberError,
                accessibilityHint: "Enter your phone number for delivery updates",
                accessibilityIdentifier: "phone-field"
            )
        }
    }
    
    // MARK: - Role Information Section
    
    private var roleInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Account Type")
                .font(.titleMedium.scaledFont())
                .foregroundColor(.graphite)
                .accessibleHeading(label: "Account Type", level: .h2)
            
            HStack(spacing: Spacing.md) {
                Image(systemName: roleIcon)
                    .font(.title2)
                    .foregroundColor(.emerald)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(viewModel.userRole?.displayName ?? "Unknown")
                        .font(.titleSmall.scaledFont())
                        .foregroundColor(.graphite)
                    
                    Text(roleDescription)
                        .font(.bodySmall.scaledFont())
                        .foregroundColor(.gray600)
                }
                
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Account type: \(viewModel.userRole?.displayName ?? "Unknown"). \(roleDescription)")
        }
    }
    
    // MARK: - Computed Properties
    
    private var roleIcon: String {
        switch viewModel.userRole {
        case .customer:
            return "person.fill"
        case .driver:
            return "car.fill"
        case .partner:
            return "storefront.fill"
        case .admin:
            return "crown.fill"
        case .none:
            return "questionmark.circle.fill"
        }
    }
    
    private var roleDescription: String {
        switch viewModel.userRole {
        case .customer:
            return "Order from local businesses"
        case .driver:
            return "Deliver orders to customers"
        case .partner:
            return "Manage your business"
        case .admin:
            return "System administrator"
        case .none:
            return "Role not set"
        }
    }
}

#Preview {
    ProfileEditView()
}