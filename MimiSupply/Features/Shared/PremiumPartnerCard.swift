//
//  PremiumPartnerCard.swift
//  MimiSupply
//
//  Created by MimiTech Ai on 17.08.25.
//

import SwiftUI

/// Premium partner card with stunning visuals and animations
struct PremiumPartnerCard: View {
    let partner: Partner
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var imageOffset: CGFloat = 0
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background Image with Parallax Effect
                partnerBackgroundImage
                    .offset(y: imageOffset)
                
                // Gradient Overlay
                LinearGradient(
                    colors: [
                        .clear,
                        .clear,
                        .black.opacity(0.3),
                        .black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Content
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    // Partner Info
                    VStack(alignment: .leading, spacing: 8) {
                        // Status Badge
                        HStack {
                            Spacer()
                            
                            if partner.isOpenNow {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("Geöffnet")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            } else {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.red)
                                        .frame(width: 6, height: 6)
                                    
                                    Text("Geschlossen")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.bottom, 8)
                        
                        // Partner Name
                        Text(partner.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        
                        // Partner Details
                        HStack(spacing: 16) {
                            // Rating
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                
                                Text(partner.formattedRating)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("(\(partner.reviewCount))")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Delivery Time
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("\(partner.estimatedDeliveryTime) min")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            
                            // Minimum Order
                            HStack(spacing: 4) {
                                Image(systemName: "eurosign.circle")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(partner.formattedMinimumOrder)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        
                        // Category Tag
                        Text(partner.category.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .padding(20)
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(
            color: .black.opacity(isPressed ? 0.2 : 0.15),
            radius: isPressed ? 8 : 12,
            x: 0,
            y: isPressed ? 4 : 6
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: { }
        .onTapGesture {
            onTap()
        }
    }
    
    @ViewBuilder
    private var partnerBackgroundImage: some View {
        switch partner.id {
        case "mcdonalds_berlin_mitte":
            // McDonald's mit rotem Hintergrund und Logo-Effekt
            ZStack {
                LinearGradient(
                    colors: [
                        Color.red.opacity(0.8),
                        Color.red.opacity(0.9),
                        Color.red
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // McDonald's Pattern
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "m.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow.opacity(0.3))
                            .offset(x: 30, y: 30)
                    }
                }
            }
            
        case "rewe_alexanderplatz":
            // REWE mit grünem Hintergrund
            ZStack {
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.7),
                        Color.green.opacity(0.8),
                        Color.green
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack {
                    HStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.2))
                            .offset(x: -20, y: -20)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
        case "docmorris_berlin":
            // DocMorris mit blauem Hintergrund
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.7),
                        Color.blue.opacity(0.8),
                        Color.blue
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.2))
                            .offset(x: 25, y: 25)
                    }
                }
            }
            
        case "mediamarkt_alexanderplatz":
            // MediaMarkt mit orangem Hintergrund
            ZStack {
                LinearGradient(
                    colors: [
                        Color.orange.opacity(0.7),
                        Color.orange.opacity(0.8),
                        Color.orange
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack {
                    HStack {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.white.opacity(0.3))
                            .offset(x: -15, y: -15)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
        case "edeka_prenzlauer_berg":
            // EDEKA mit gelbem Hintergrund
            ZStack {
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.8),
                        Color.yellow.opacity(0.9),
                        Color.yellow
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 45))
                            .foregroundColor(.green.opacity(0.4))
                            .offset(x: 20, y: 20)
                    }
                }
            }
            
        default:
            // Default gradient für unbekannte Partner
            LinearGradient(
                colors: [
                    Color(red: 0.31, green: 0.78, blue: 0.47).opacity(0.8),
                    Color(red: 0.25, green: 0.85, blue: 0.55)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Premium Partner Grid
struct PremiumPartnerGrid: View {
    let partners: [Partner]
    let onPartnerTap: (Partner) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(partners) { partner in
                PremiumPartnerCard(partner: partner) {
                    onPartnerTap(partner)
                }
            }
        }
    }
}

// MARK: - Premium Featured Partners Section
struct PremiumFeaturedPartnersSection: View {
    let partners: [Partner]
    let onPartnerTap: (Partner) -> Void
    let onSeeAll: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Featured Partners")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("See All") {
                    onSeeAll()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.31, green: 0.78, blue: 0.47))
            }
            
            // Horizontal Scroll of Partners
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(partners.prefix(5)) { partner in
                        PremiumPartnerCard(partner: partner) {
                            onPartnerTap(partner)
                        }
                        .frame(width: 280)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.horizontal, -20)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PremiumPartnerCard(partner: GermanPartnerData.restaurantPartners[0]) {
            print("Tapped McDonald's")
        }
        
        PremiumPartnerCard(partner: GermanPartnerData.pharmacyPartners[0]) {
            print("Tapped DocMorris")
        }
    }
    .padding()
    .background(Color.gray100)
}