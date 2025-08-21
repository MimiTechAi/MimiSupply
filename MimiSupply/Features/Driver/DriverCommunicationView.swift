//
//  DriverCommunicationView.swift
//  MimiSupply
//
//  Created by Kiro on 19.08.25.
//

import SwiftUI

/// Communication view for drivers to contact customers and support
struct DriverCommunicationView: View {
    let job: Order
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Job Info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Auftrag #\(job.id.prefix(8))")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(job.deliveryAddress.singleLineAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Communication Options
                VStack(spacing: 16) {
                    // Call Customer
                    Button(action: {
                        // Call customer
                        if let url = URL(string: "tel:+4930123456789") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("Kunde anrufen")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("+49 30 123 456 789")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Message Customer
                    Button(action: {
                        // Open message app
                        if let url = URL(string: "sms:+4930123456789") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("Kunde anschreiben")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("SMS senden")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Call Restaurant
                    Button(action: {
                        // Call restaurant
                        if let url = URL(string: "tel:+493020457800") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "storefront")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("Restaurant anrufen")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("McDonald's Berlin")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                    
                    // Support Contact
                    Button(action: {
                        // Contact support
                        if let url = URL(string: "tel:+4930999999") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "headphones")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading) {
                                Text("MimiSupply Support")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("24/7 Hilfe & Support")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Kommunikation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schließen") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DriverCommunicationView(job: Order.mockOrders[0])
}