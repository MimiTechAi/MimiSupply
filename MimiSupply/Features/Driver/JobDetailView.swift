//
//  JobDetailView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import MapKit

struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

/// Detailed view of a delivery job with full information and map
struct JobDetailView: View {
    let job: Order
    let onAction: (JobAction) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Order Summary
                    orderSummary
                    
                    // Delivery Address
                    deliveryAddress
                    
                    // Map View
                    mapView
                    
                    // Order Items
                    orderItems
                    
                    // Payment Summary
                    paymentSummary
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Job Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionButtons
                    .padding()
                    .background(.regularMaterial)
            }
        }
    }
    
    // MARK: - Order Summary
    
    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Order ID")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("#\(job.id.prefix(8))")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(job.status.displayName)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(for: job.status))
                }
                
                HStack {
                    Text("Total")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(job.formattedTotal)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Estimated Delivery")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(job.estimatedDeliveryTime, style: .time)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Delivery Address
    
    private var deliveryAddress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Delivery Address")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(job.deliveryAddress.formattedAddress)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if let instructions = job.deliveryInstructions {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Special Instructions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                        
                        Text(instructions)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemYellow).opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        Map {
            Marker("Delivery Location", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194))
                .tint(.red)
        }
        .mapStyle(.standard)
        .frame(height: 200)
        .cornerRadius(12)
    }
    
    // MARK: - Order Items
    
    private var orderItems: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order Items")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(job.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.productName)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            if let instructions = item.specialInstructions {
                                Text(instructions)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("×\(item.quantity)")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text("$\(String(format: "%.2f", Double(item.totalPriceCents) / 100.0))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if item.id != job.items.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Payment Summary
    
    private var paymentSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Summary")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", Double(job.subtotalCents) / 100.0))")
                }
                
                HStack {
                    Text("Delivery Fee")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", Double(job.deliveryFeeCents) / 100.0))")
                }
                
                HStack {
                    Text("Platform Fee")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", Double(job.platformFeeCents) / 100.0))")
                }
                
                HStack {
                    Text("Tax")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", Double(job.taxCents) / 100.0))")
                }
                
                if job.tipCents > 0 {
                    HStack {
                        Text("Tip")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(String(format: "%.2f", Double(job.tipCents) / 100.0))")
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(job.formattedTotal)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Decline") {
                onAction(.decline)
                dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Accept Job") {
                onAction(.accept)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .accepted, .preparing:
            return .blue
        case .driverAssigned, .readyForPickup:
            return .orange
        case .pickedUp, .delivering:
            return .purple
        case .delivered:
            return .green
        case .cancelled:
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Preview

struct JobDetailView_Previews: PreviewProvider {
    static var previews: some View {
        JobDetailView(job: Order.mock) { _ in }
    }
}

// MARK: - Mock Data Extension

extension Order {
    static var mock: Order {
        Order(
            customerId: "customer1",
            partnerId: "partner1",
            items: [
                OrderItem(
                    productId: "prod1",
                    productName: "Classic Burger",
                    quantity: 2,
                    unitPriceCents: 1299
                ),
                OrderItem(
                    productId: "prod2",
                    productName: "French Fries",
                    quantity: 1,
                    unitPriceCents: 599
                )
            ],
            status: .accepted,
            subtotalCents: 3197,
            deliveryFeeCents: 299,
            platformFeeCents: 150,
            taxCents: 320,
            tipCents: 500,
            deliveryAddress: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "USA",
                apartment: "Apt 2B"
            ),
            deliveryInstructions: "Ring doorbell twice. Leave at door if no answer.",
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            paymentMethod: .applePay
        )
    }
}
