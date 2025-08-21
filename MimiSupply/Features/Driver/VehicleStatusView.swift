//
//  VehicleStatusView.swift
//  MimiSupply
//
//  Created by Kiro on 19.08.25.
//

import SwiftUI

/// Vehicle status and management view for drivers
struct VehicleStatusView: View {
    let vehicleInfo: VehicleInfo?
    let onUpdate: (VehicleInfo) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let vehicle = vehicleInfo {
                        // Vehicle Info Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: vehicle.type.icon)
                                    .font(.title)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading) {
                                    Text(vehicle.type.displayName)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    if let plate = vehicle.licensePlate {
                                        Text("Kennzeichen: \(plate)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            // Battery/Fuel Level
                            if let batteryLevel = vehicle.batteryLevel {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Akkuladung")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(batteryLevel)%")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(batteryLevel > 20 ? .green : .red)
                                    }
                                    
                                    ProgressView(value: Double(batteryLevel), total: 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: batteryLevel > 20 ? .green : .red))
                                }
                            }
                            
                            if let fuelLevel = vehicle.fuelLevel {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Kraftstoff")
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        Text("\(fuelLevel)%")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(fuelLevel > 20 ? .green : .red)
                                    }
                                    
                                    ProgressView(value: Double(fuelLevel), total: 100)
                                        .progressViewStyle(LinearProgressViewStyle(tint: fuelLevel > 20 ? .green : .red))
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        
                        // Service Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Service & Wartung")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Letzte Wartung")
                                    Spacer()
                                    Text(vehicle.lastServiceDate.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("Nächste Wartung")
                                    Spacer()
                                    Text(vehicle.nextServiceDue.formatted(date: .abbreviated, time: .omitted))
                                        .foregroundColor(vehicle.nextServiceDue < Date() ? .red : .secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Legal Status
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rechtlicher Status")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Versicherung")
                                    Spacer()
                                    Image(systemName: vehicle.insuranceValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(vehicle.insuranceValid ? .green : .red)
                                }
                                
                                HStack {
                                    Text("Zulassung")
                                    Spacer()
                                    Image(systemName: vehicle.registrationValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(vehicle.registrationValid ? .green : .red)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        Text("Keine Fahrzeuginformationen verfügbar")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Fahrzeugstatus")
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
    VehicleStatusView(
        vehicleInfo: VehicleInfo(
            type: .bicycle,
            licensePlate: "B-MW-1234",
            batteryLevel: 85,
            fuelLevel: nil,
            lastServiceDate: Date(),
            nextServiceDue: Date().addingTimeInterval(86400 * 30),
            insuranceValid: true,
            registrationValid: true
        )
    ) { _ in }
}