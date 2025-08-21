import SwiftUI
import PhotosUI

struct PartnerSettingsView: View {
    @StateObject private var viewModel = PartnerSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Business Profile") {
                    HStack {
                        AsyncImage(url: viewModel.logoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray200)
                                .overlay(
                                    Image(systemName: "building.2")
                                        .foregroundColor(.gray400)
                                )
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Business Logo")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                            
                            PhotosPicker(
                                selection: $viewModel.selectedLogo,
                                matching: .images
                            ) {
                                Text("Change Logo")
                                    .font(.bodySmall)
                                    .foregroundColor(.emerald)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    TextField("Business Name", text: $viewModel.businessName)
                    
                    TextField("Description", text: $viewModel.businessDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(PartnerCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Contact Information") {
                    TextField("Phone Number", text: $viewModel.phoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Website", text: $viewModel.website)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Address") {
                    TextField("Street Address", text: $viewModel.streetAddress)
                    
                    HStack {
                        TextField("City", text: $viewModel.city)
                        TextField("State", text: $viewModel.state)
                            .frame(maxWidth: 80)
                    }
                    
                    TextField("ZIP Code", text: $viewModel.zipCode)
                        .keyboardType(.numberPad)
                }
                
                Section("Verification") {
                    HStack {
                        Image(systemName: viewModel.isVerified ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundColor(viewModel.isVerified ? .success : .warning)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.isVerified ? "Verified Business" : "Verification Pending")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                            
                            Text(viewModel.isVerified ? "Your business has been verified" : "Submit documents to verify your business")
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                        
                        Spacer()
                        
                        if !viewModel.isVerified {
                            Button("Submit Documents") {
                                viewModel.showingVerification = true
                            }
                            .font(.bodySmall)
                            .foregroundColor(.emerald)
                        }
                    }
                }
                
                Section("Notifications") {
                    Toggle("New Orders", isOn: $viewModel.notifyNewOrders)
                    Toggle("Order Updates", isOn: $viewModel.notifyOrderUpdates)
                    Toggle("Marketing Updates", isOn: $viewModel.notifyMarketing)
                }
                
                Section("Account") {
                    Button("Change Password") {
                        viewModel.showingPasswordChange = true
                    }
                    
                    Button("Privacy Policy") {
                        viewModel.showingPrivacyPolicy = true
                    }
                    
                    Button("Terms of Service") {
                        viewModel.showingTermsOfService = true
                    }
                    
                    Button("Delete Account", role: .destructive) {
                        viewModel.showingDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveSettings()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .sheet(isPresented: $viewModel.showingVerification) {
                BusinessVerificationView()
            }
            .sheet(isPresented: $viewModel.showingPasswordChange) {
                PasswordChangeView()
            }
            .sheet(isPresented: $viewModel.showingPrivacyPolicy) {
                WebView(url: URL(string: "https://mimisupply.com/privacy")!)
            }
            .sheet(isPresented: $viewModel.showingTermsOfService) {
                WebView(url: URL(string: "https://mimisupply.com/terms")!)
            }
            .alert("Delete Account", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your business data.")
            }
        }
        .task {
            await viewModel.loadSettings()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Business Verification View
struct BusinessVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDocuments: [PhotosPickerItem] = []
    @State private var businessLicense = ""
    @State private var taxId = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Business Documents") {
                    TextField("Business License Number", text: $businessLicense)
                    
                    TextField("Tax ID / EIN", text: $taxId)
                    
                    PhotosPicker(
                        selection: $selectedDocuments,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("Upload Documents", systemImage: "doc.badge.plus")
                    }
                    
                    if !selectedDocuments.isEmpty {
                        Text("\(selectedDocuments.count) document(s) selected")
                            .font(.bodySmall)
                            .foregroundColor(.gray600)
                    }
                }
                
                Section {
                    Text("Please upload clear photos of your business license, tax documents, and any other relevant business registration documents.")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                } header: {
                    Text("Requirements")
                }
            }
            .navigationTitle("Business Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        isSubmitting = true
                        // Handle submission
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(businessLicense.isEmpty || taxId.isEmpty || selectedDocuments.isEmpty || isSubmitting)
                }
            }
        }
    }
}

// MARK: - Password Change View
struct PasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isChanging = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    SecureField("Current Password", text: $currentPassword)
                }
                
                Section("New Password") {
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm New Password", text: $confirmPassword)
                }
                
                Section {
                    Text("Password must be at least 8 characters long and contain a mix of letters, numbers, and symbols.")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                } header: {
                    Text("Requirements")
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Change") {
                        changePassword()
                    }
                    .disabled(currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isChanging)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else {
            errorMessage = "New passwords don't match"
            showingError = true
            return
        }
        
        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters long"
            showingError = true
            return
        }
        
        isChanging = true
        
        // Simulate password change
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isChanging = false
            dismiss()
        }
    }
}

// MARK: - Web View
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

import WebKit

// PartnerCategory displayName is already defined in Data/Models/Partner.swift

#Preview {
    PartnerSettingsView()
}