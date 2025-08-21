//
//  DriverEarningsDetailView.swift
//  MimiSupply
//
//  Created by Kiro on 19.08.25.
//

import SwiftUI

/// Detailed earnings view for drivers
struct DriverEarningsDetailView: View {
    let dailyEarnings: DriverEarnings?
    let weeklyEarnings: DriverEarnings?
    let monthlyEarnings: DriverEarnings?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Earnings Detail
                    if let daily = dailyEarnings {
                        EarningsDetailCard(
                            title: "Heute",
                            earnings: daily,
                            color: .green
                        )
                    }
                    
                    // Weekly Earnings Detail
                    if let weekly = weeklyEarnings {
                        EarningsDetailCard(
                            title: "Diese Woche",
                            earnings: weekly,
                            color: .blue
                        )
                    }
                    
                    // Monthly Earnings Detail
                    if let monthly = monthlyEarnings {
                        EarningsDetailCard(
                            title: "Dieser Monat",
                            earnings: monthly,
                            color: .purple
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Verdienste")
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

struct EarningsDetailCard: View {
    let title: String
    let earnings: DriverEarnings
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            HStack {
                Text(earnings.formattedTotalEarnings)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(color)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(earnings.totalDeliveries) Lieferungen")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(earnings.workingHours)h gearbeitet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Breakdown
            VStack(spacing: 8) {
                HStack {
                    Text("Grundvergütung")
                    Spacer()
                    Text(String(format: "€%.2f", Double(earnings.basePay) / 100.0))
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Trinkgelder")
                    Spacer()
                    Text(String(format: "€%.2f", Double(earnings.tips) / 100.0))
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                HStack {
                    Text("Boni")
                    Spacer()
                    Text(String(format: "€%.2f", Double(earnings.bonuses) / 100.0))
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Divider()
                
                HStack {
                    Text("Stundenlohn")
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "€%.2f/h", earnings.hourlyRate))
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    DriverEarningsDetailView(
        dailyEarnings: DriverEarnings(date: Date(), basePay: 4250, tips: 850, bonuses: 500, totalDeliveries: 8, workingHours: 6),
        weeklyEarnings: nil,
        monthlyEarnings: nil
    )
}