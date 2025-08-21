//
//  EnhancedJobCompletionView.swift
//  MimiSupply
//
//  Created by Kiro on 19.08.25.
//

import SwiftUI

/// Enhanced job completion view with photo proof and customer rating
struct EnhancedJobCompletionView: View {
    let job: Order
    let onComplete: (Data?, String?, Int?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var deliveryPhoto: UIImage?
    @State private var showingCamera = false
    @State private var notes = ""
    @State private var customerRating: Int?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 60))
                        
                        Text("Lieferung abgeschlossen!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Auftrag #\(job.id.prefix(8))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Photo Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Liefernachweis (optional)")
                            .font(.headline)
                        
                        if let photo = deliveryPhoto {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .cornerRadius(12)
                        } else {
                            Button(action: { showingCamera = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    
                                    Text("Foto aufnehmen")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    Text("Dokumentiere die erfolgreiche Zustellung")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notizen (optional)")
                            .font(.headline)
                        
                        TextField("Zusätzliche Informationen zur Lieferung...", text: $notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    
                    // Customer Rating Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wie war die Interaktion mit dem Kunden?")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            ForEach(1...5, id: \.self) { rating in
                                Button(action: {
                                    customerRating = rating
                                }) {
                                    Image(systemName: rating <= (customerRating ?? 0) ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(rating <= (customerRating ?? 0) ? .yellow : .gray)
                                }
                            }
                            
                            if let rating = customerRating {
                                Text("(\(rating)/5)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Earnings Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dein Verdienst")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Liefergebühr")
                                Spacer()
                                Text(String(format: "€%.2f", Double(job.deliveryFeeCents) / 100.0))
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Geschätztes Trinkgeld")
                                Spacer()
                                Text("€3.50")
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Gesamt")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(String(format: "€%.2f", Double(job.deliveryFeeCents) / 100.0 + 3.50))
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Abgeschlossen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        let photoData = deliveryPhoto?.jpegData(compressionQuality: 0.8)
                        onComplete(photoData, notes.isEmpty ? nil : notes, customerRating)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            DriverCameraView { image in
                deliveryPhoto = image
                showingCamera = false
            }
        }
    }
}

// Simple camera view wrapper
struct DriverCameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
        }
    }
}

#Preview {
    EnhancedJobCompletionView(job: Order.mockOrders[0]) { _, _, _ in }
}