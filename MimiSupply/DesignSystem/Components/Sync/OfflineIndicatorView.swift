//
//  OfflineIndicatorView.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Combine

/// Prominent offline mode indicator with helpful actions
struct OfflineIndicatorView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var showOfflineGuide = false
    @State private var isPulsing = false
    
    var body: some View {
        if offlineManager.isOfflineMode {
            offlineCard
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: offlineManager.isOfflineMode)
        }
    }
    
    private var offlineCard: some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack(spacing: Spacing.sm) {
                offlineIcon
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("You're Offline")
                        .font(.headline.scaledFont().weight(.semibold))
                        .foregroundColor(.error)
                    
                    Text("Changes will sync when connection is restored")
                        .font(.caption.scaledFont())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button {
                    showOfflineGuide.toggle()
                    HapticManager.shared.trigger(.light)
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Pending sync status
            if offlineManager.pendingSyncCount > 0 {
                pendingSyncStatus
            }
            
            // Connection tips
            connectionTips
        }
        .padding(Spacing.lg)
        .background(offlineCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Spacing.lg)
        .sheet(isPresented: $showOfflineGuide) {
            OfflineGuideSheet()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline mode active. \(offlineManager.pendingSyncCount) items pending sync.")
    }
    
    private var offlineIcon: some View {
        ZStack {
            Circle()
                .fill(Color.error.opacity(0.2))
                .frame(width: 48, height: 48)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear {
                    isPulsing = true
                }
            
            Image(systemName: "wifi.slash")
                .font(.title2)
                .foregroundColor(.error)
        }
    }
    
    private var pendingSyncStatus: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(.warning)
            
            Text("\(offlineManager.pendingSyncCount) items waiting to sync")
                .font(.caption.scaledFont().weight(.medium))
                .foregroundColor(.warning)
            
            Spacer()
            
            Button {
                // Show pending items details
            } label: {
                Text("View")
                    .font(.caption.scaledFont().weight(.semibold))
                    .foregroundColor(.accentColor)
            }
        }
        .padding(Spacing.sm)
        .background(Color.warning.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var connectionTips: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label("Quick Fixes:", systemImage: "lightbulb")
                .font(.caption.scaledFont().weight(.semibold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                connectionTip("Check your WiFi or cellular connection")
                connectionTip("Try moving to a different location")
                connectionTip("Restart your WiFi connection")
            }
        }
    }
    
    private func connectionTip(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.xs) {
            Circle()
                .fill(Color.secondary)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            Text(text)
                .font(.caption2.scaledFont())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var offlineCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .strokeBorder(Color.error.opacity(0.3), lineWidth: 1)
    }
}

/// Offline guide sheet with detailed instructions
struct OfflineGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Image(systemName: "wifi.slash")
                            .font(.largeTitle)
                            .foregroundColor(.error)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Working Offline")
                            .font(.title.scaledFont().weight(.bold))
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Don't worry! You can still use MimiSupply while offline. Your changes will be saved and synced when you reconnect.")
                            .font(.body.scaledFont())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // What works offline
                    offlineFeatureSection(
                        title: "What Works Offline",
                        icon: "checkmark.circle.fill",
                        color: .success,
                        features: [
                            "Browse cached products and partners",
                            "View order history",
                            "Update profile information",
                            "Mark orders as complete",
                            "View saved addresses"
                        ]
                    )
                    
                    // What needs connection
                    offlineFeatureSection(
                        title: "Needs Internet Connection",
                        icon: "wifi",
                        color: .warning,
                        features: [
                            "Placing new orders",
                            "Real-time order tracking",
                            "Payment processing",
                            "Live partner status updates",
                            "Push notifications"
                        ]
                    )
                    
                    // Troubleshooting
                    troubleshootingSection
                }
                .padding(Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func offlineFeatureSection(
        title: String,
        icon: String,
        color: Color,
        features: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline.scaledFont().weight(.semibold))
            }
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(color)
                            .padding(.top, 6)
                        
                        Text(feature)
                            .font(.body.scaledFont())
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text("Troubleshooting")
                    .font(.headline.scaledFont().weight(.semibold))
            }
            
            VStack(alignment: .leading, spacing: Spacing.md) {
                troubleshootingStep(
                    number: "1",
                    title: "Check Connection",
                    description: "Ensure WiFi or cellular data is enabled in Settings"
                )
                
                troubleshootingStep(
                    number: "2",
                    title: "Restart Connection",
                    description: "Turn WiFi off and on, or toggle Airplane mode"
                )
                
                troubleshootingStep(
                    number: "3",
                    title: "Try Different Network",
                    description: "Switch between WiFi and cellular, or try a different WiFi network"
                )
                
                troubleshootingStep(
                    number: "4",
                    title: "Force Sync",
                    description: "Once connected, use the sync button to upload pending changes"
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color.accentColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func troubleshootingStep(
        number: String,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(number)
                .font(.headline.scaledFont().weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.body.scaledFont().weight(.semibold))
                
                Text(description)
                    .font(.caption.scaledFont())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OfflineIndicatorView()
        Spacer()
    }
    .background(Color.surfaceSecondary)
}