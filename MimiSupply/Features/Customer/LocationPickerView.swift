//
//  LocationPickerView.swift
//  MimiSupply
//
//  Location picker for delivery address selection
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
    let onAddressSelected: (Address) -> Void
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var selectedAddress: Address?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray500)
                    
                    TextField("Search address...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            searchLocation()
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .font(.caption)
                        .foregroundColor(.emerald)
                    }
                }
                .padding(Spacing.md)
                .background(Color.gray100)
                
                // Map View
                Map(coordinateRegion: $region, annotationItems: selectedAddress != nil ? [selectedAddress!] : []) { address in
                    MapPin(coordinate: CLLocationCoordinate2D(
                        latitude: address.latitude ?? region.center.latitude,
                        longitude: address.longitude ?? region.center.longitude
                    ))
                }
                .frame(height: 300)
                
                // Selected Address Info
                if let address = selectedAddress {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Selected Address")
                            .font(.labelMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.graphite)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(address.street)
                                .font(.bodyMedium)
                                .foregroundColor(.graphite)
                            
                            Text("\(address.city), \(address.state) \(address.postalCode)")
                                .font(.bodySmall)
                                .foregroundColor(.gray600)
                        }
                        
                        Button("Confirm Address") {
                            onAddressSelected(address)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, Spacing.sm)
                    }
                    .padding(Spacing.md)
                    .background(Color.white)
                } else {
                    VStack(spacing: Spacing.md) {
                        Text("Tap on the map or search to select an address")
                            .font(.bodyMedium)
                            .foregroundColor(.gray600)
                            .multilineTextAlignment(.center)
                        
                        Button("Use Current Location") {
                            useCurrentLocation()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(Spacing.md)
                }
                
                Spacer()
            }
            .navigationTitle("Select Address")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func searchLocation() {
        // Implement location search using MKLocalSearch
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response,
                  let mapItem = response.mapItems.first else {
                return
            }
            
            let coordinate = mapItem.placemark.coordinate
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            selectedAddress = Address(
                street: mapItem.placemark.thoroughfare ?? "",
                city: mapItem.placemark.locality ?? "",
                state: mapItem.placemark.administrativeArea ?? "",
                postalCode: mapItem.placemark.postalCode ?? "",
                country: mapItem.placemark.country ?? "",
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        }
    }
    
    private func useCurrentLocation() {
        // Request current location and set as selected address
        // This would typically use CLLocationManager
        let sanFranciscoAddress = Address(
            street: "Current Location",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105",
            country: "US",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        selectedAddress = sanFranciscoAddress
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: sanFranciscoAddress.latitude!,
                longitude: sanFranciscoAddress.longitude!
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

// Make Address identifiable for MapKit
extension Address: Identifiable {
    var id: String {
        return "\(street), \(city), \(state)"
    }
}

#Preview {
    LocationPickerView { address in
        print("Selected address: \(address)")
    }
}