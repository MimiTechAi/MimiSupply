//
//  MapExploreView.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import SwiftUI
import MapKit

/// Map view for exploring partners geographically
struct MapExploreView: View {
    let partners: [Partner]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedPartner: Partner?
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(coordinateRegion: $region, annotationItems: partners) { partner in
                MapAnnotation(coordinate: partner.location) {
                    PartnerMapPin(partner: partner) {
                        selectedPartner = partner
                    }
                }
            }
            .ignoresSafeArea()
            
            // Selected Partner Card
            if let selectedPartner = selectedPartner {
                PartnerMapCard(partner: selectedPartner) {
                    router.push(.partnerDetail(selectedPartner))
                } onClose: {
                    self.selectedPartner = nil
                }
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(), value: selectedPartner)
            }
        }
        .onAppear {
            updateRegionForPartners()
        }
    }
    
    private func updateRegionForPartners() {
        guard !partners.isEmpty else { return }
        
        let coordinates = partners.map { $0.location }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.2,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.2
        )
        
        region = MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - Partner Map Pin
struct PartnerMapPin: View {
    let partner: Partner
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(systemName: partner.category.iconName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(categoryColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                // Pin tail
                Triangle()
                    .fill(categoryColor)
                    .frame(width: 8, height: 8)
                    .offset(y: -2)
            }
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3), value: partner.id)
    }
    
    private var categoryColor: Color {
        switch partner.category {
        case .restaurant: return .orange
        case .grocery: return .green
        case .pharmacy: return .red
        case .coffee: return .brown
        case .retail: return .purple
        case .convenience: return .blue
        case .bakery: return .pink
        case .alcohol: return .indigo
        case .flowers: return .mint
        case .electronics: return .gray
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Partner Map Card
struct PartnerMapCard: View {
    let partner: Partner
    let onTap: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: partner.logoURL ?? partner.heroImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray200)
                    .overlay(
                        Image(systemName: partner.category.iconName)
                            .foregroundColor(.gray400)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(partner.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if partner.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text(partner.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(partner.formattedRating)
                            .font(.caption)
                    }
                    
                    Text("\(partner.estimatedDeliveryTime) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(partner.formattedMinimumOrder)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray400)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .onTapGesture {
            onTap()
        }
    }
}

// Note: MapView is defined in MapView.swift

#Preview {
    MapExploreView(partners: [])
        .environmentObject(AppContainer.shared.appRouter)
}