//
//  DriverNavigationView.swift
//  MimiSupply
//
//  Created by Kiro on 19.08.25.
//

import SwiftUI
import MapKit

/// Navigation view for drivers with turn-by-turn directions
struct DriverNavigationView: View {
    let job: Order
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            VStack {
                // Map View
                Map(coordinateRegion: $region)
                    .ignoresSafeArea(edges: .top)
                
                // Navigation Info Panel
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Navigation zu:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(job.deliveryAddress.singleLineAddress)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("8 min")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Text("2.3 km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Button("Navigation beenden") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                        
                        Button("Angekommen") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DriverNavigationView(job: Order.mockOrders[0])
}