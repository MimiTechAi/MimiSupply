//
//  JobCompletionView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import PhotosUI

/// View for completing a delivery with photo confirmation and notes
struct JobCompletionView: View {
    let job: Order
    let onComplete: (Data?, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var completionNotes: String = ""
    @State private var showingCamera = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Completion Header
                    completionHeader
                    
                    // Order Summary
                    orderSummary
                    
                    // Photo Confirmation
                    photoConfirmation
                    
                    // Completion Notes
                    notesSection
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Complete Delivery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Complete") {
                        completeDelivery()
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { data in
                    photoData = data
                }
            }
            .onChange(of: selectedPhoto) { _, newPhoto in
                Task {
                    if let newPhoto = newPhoto {
                        photoData = try? await newPhoto.loadTransferable(type: Data.self)
                    }
                }
            }
        }
    }
    
    // MARK: - Completion Header
    
    private var completionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to Complete")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Confirm delivery completion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Order Summary
    
    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Order #")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(job.id.prefix(8))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Address")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(job.deliveryAddress.singleLineAddress)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Total")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(job.formattedTotal)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                if job.tipCents > 0 {
                    HStack {
                        Text("Tip")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", Double(job.tipCents) / 100.0))")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Photo Confirmation
    
    private var photoConfirmation: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo Confirmation")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Take a photo to confirm successful delivery (optional)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                // Photo Display
                if let photoData = photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                        .overlay(
                            Button(action: { self.photoData = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8),
                            alignment: .topTrailing
                        )
                } else {
                    // Photo Placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("No photo selected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                // Photo Action Buttons
                HStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Notes")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Add any additional notes about the delivery (optional)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Enter completion notes...", text: $completionNotes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Actions
    
    private func completeDelivery() {
        isLoading = true
        
        // Add a small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete(photoData, completionNotes.isEmpty ? nil : completionNotes)
            dismiss()
            isLoading = false
        }
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage,
               let imageData = image.jpegData(compressionQuality: 0.8) {
                parent.onImageCaptured(imageData)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
