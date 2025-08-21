//
//  EnhancedJobDetailView.swift
//  MimiSupply
//
//  Created by Kiro on 19.08.25.
//

import SwiftUI
import MapKit

/// Enhanced job detail view with navigation, communication, and detailed information
struct EnhancedJobDetailView: View {
    let job: Order
    let onAction: (JobAction) -> Void
    
    @State private var showingMap = false
    @State private var showingDirections = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Job Header
                    jobHeaderCard
                    
                    // Customer & Restaurant Info
                    locationInfoSection
                    
                    // Order Items
                    orderItemsSection
                    
                    // Delivery Instructions
                    if let instructions = job.deliveryInstructions {
                        instructionsSection(instructions)
                    }
                    
                    // Payment & Earnings Info
                    paymentSection
                    
                    // Map Preview
                    mapPreviewSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Auftrag Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingDirections = true }) {
                            Label("Navigation starten", systemImage: "location")
                        }
                        
                        Button(action: { /* Call customer */ }) {
                            Label("Kunde anrufen", systemImage: "phone")
                        }
                        
                        Button(action: { /* Call restaurant */ }) {
                            Label("Restaurant anrufen", systemImage: "phone.badge.plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionButtonsSection
            }
        }
        .sheet(isPresented: $showingDirections) {
            DriverNavigationView(job: job)
        }
    }
    
    // MARK: - Job Header Card
    
    private var jobHeaderCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auftrag #\(job.id.prefix(8))")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(job.status.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(statusColor(for: job.status))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(job.formattedTotal)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("ETA: \(job.estimatedDeliveryTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Estimated Earnings
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                
                Text("Geschätzter Verdienst: €8.50 - €12.00")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Location Info Section
    
    private var locationInfoSection: some View {
        VStack(spacing: 16) {
            // Pickup Location (if applicable)
            if job.status == .driverAssigned || job.status == .readyForPickup {
                LocationCard(
                    title: "Abholung bei",
                    name: "McDonald's Berlin Mitte",
                    address: "Unter den Linden 1, 10117 Berlin",
                    phone: "+49 30 20457800",
                    icon: "bag",
                    color: .blue
                )
            }
            
            // Delivery Location
            LocationCard(
                title: "Lieferung an",
                name: "Max Mustermann",
                address: job.deliveryAddress.singleLineAddress,
                phone: "+49 30 12345678", // Would come from order
                icon: "house",
                color: .green
            )
        }
    }
    
    // MARK: - Order Items Section
    
    private var orderItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bestellte Artikel")
                .font(.headline)
            
            ForEach(job.items, id: \.productId) { item in
                HStack {
                    Text("\(item.quantity)x")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 30, alignment: .leading)
                    
                    Text(item.productName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(String(format: "€%.2f", Double(item.unitPriceCents * item.quantity) / 100.0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Instructions Section
    
    private func instructionsSection(_ instructions: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Lieferhinweise", systemImage: "note.text")
                .font(.headline)
            
            Text(instructions)
                .font(.body)
                .padding()
                .background(Color(.systemYellow).opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemYellow), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Payment Section
    
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zahlungsdetails")
                .font(.headline)
            
            VStack(spacing: 8) {
                paymentRow("Zwischensumme", amount: job.subtotalCents)
                paymentRow("Liefergebühr", amount: job.deliveryFeeCents)
                paymentRow("Service-Gebühr", amount: job.platformFeeCents)
                paymentRow("Steuern", amount: job.taxCents)
                
                Divider()
                
                HStack {
                    Text("Gesamt")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(job.formattedTotal)
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Map Preview Section
    
    private var mapPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Route")
                    .font(.headline)
                
                Spacer()
                
                Button("Vollbild") {
                    showingMap = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Mock map preview
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: "map")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("Kartenvorschau")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("~2.3 km • 8 min")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                )
                .onTapGesture {
                    showingMap = true
                }
        }
        .sheet(isPresented: $showingMap) {
            // Full screen map view
            Text("Vollbild-Karte würde hier angezeigt")
                .navigationTitle("Route")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Accept/Decline buttons for available jobs
                if job.status == .paymentConfirmed {
                    Button("Annehmen") {
                        onAction(.accept)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    
                    Button("Ablehnen") {
                        onAction(.decline)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                
                // Status update buttons for current jobs
                if job.status == .driverAssigned || job.status == .readyForPickup {
                    Button("Abgeholt") {
                        // Handle pickup
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                
                if job.status == .pickedUp {
                    Button("Unterwegs") {
                        // Handle start delivery
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                
                if job.status == .delivering {
                    Button("Zugestellt") {
                        // Handle delivery completion
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            
            // Secondary action button
            Button("Navigation starten") {
                showingDirections = true
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Views
    
    private func paymentRow(_ title: String, amount: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(String(format: "€%.2f", Double(amount) / 100.0))
                .font(.subheadline)
        }
    }
    
    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .paymentConfirmed: return .blue
        case .driverAssigned, .readyForPickup: return .orange
        case .pickedUp, .delivering: return .purple
        case .delivered: return .green
        case .cancelled: return .red
        default: return .gray
        }
    }
}

// MARK: - Location Card

struct LocationCard: View {
    let title: String
    let name: String
    let address: String
    let phone: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(address)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Call phone number
                    if let url = URL(string: "tel:\(phone)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "phone")
                        Text(phone)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

#Preview {
    EnhancedJobDetailView(
        job: Order.mockOrders[0]
    ) { action in
        print("Action: \(action)")
    }
}