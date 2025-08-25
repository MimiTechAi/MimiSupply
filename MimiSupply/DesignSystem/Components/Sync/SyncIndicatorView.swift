//
//  SyncIndicatorView.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Combine
import OSLog

/// Real-time sync status indicator with visual feedback
struct SyncIndicatorView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var isAnimating = false
    @State private var showDetails = false
    
    var body: some View {
        Group {
            if offlineManager.pendingSyncCount > 0 || offlineManager.isOfflineMode {
                syncStatusContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityHint("Tap for sync details")
            }
        }
    }
    
    private var syncStatusContent: some View {
        Button {
            showDetails.toggle()
            HapticManager.shared.trigger(.lightImpact)
        } label: {
            HStack(spacing: Spacing.xs) {
                statusIcon
                statusText
                
                if offlineManager.pendingSyncCount > 0 {
                    pendingCountBadge
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(statusBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDetails) {
            SyncStatusDetailsView()
                .presentationCompactAdaptation(.popover)
        }
    }
    
    private var statusIcon: some View {
        Group {
            if offlineManager.isOfflineMode {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.error)
            } else if offlineManager.pendingSyncCount > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.warning)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 2)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.success)
            }
        }
        .font(.caption)
    }
    
    private var statusText: some View {
        Text(statusMessage)
            .font(.caption2.scaledFont())
            .foregroundColor(statusColor)
            .lineLimit(1)
    }
    
    private var pendingCountBadge: some View {
        Text("\(offlineManager.pendingSyncCount)")
            .font(.caption2.scaledFont().weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.error)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(statusColor.opacity(0.1))
            .strokeBorder(statusColor.opacity(0.2), lineWidth: 1)
    }
    
    private var statusMessage: String {
        if offlineManager.isOfflineMode {
            return "Offline"
        } else if offlineManager.pendingSyncCount > 0 {
            return "Syncing..."
        } else {
            return "Synced"
        }
    }
    
    private var statusColor: Color {
        if offlineManager.isOfflineMode {
            return .error
        } else if offlineManager.pendingSyncCount > 0 {
            return .warning
        } else {
            return .success
        }
    }
    
    private var accessibilityLabel: String {
        if offlineManager.isOfflineMode {
            return "Offline mode. \(offlineManager.pendingSyncCount) items pending sync."
        } else if offlineManager.pendingSyncCount > 0 {
            return "Syncing \(offlineManager.pendingSyncCount) items"
        } else {
            return "All data synced"
        }
    }
}

/// Detailed sync status view shown in popover
struct SyncStatusDetailsView: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var degradationService = GracefulDegradationService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                // Network Status
                networkStatusSection
                
                // Sync Status
                syncStatusSection
                
                // Service Status
                serviceStatusSection
                
                Spacer()
                
                // Actions
                actionButtons
            }
            .padding(Spacing.lg)
            .navigationTitle("Sync Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(maxWidth: 320, maxHeight: 500)
    }
    
    private var networkStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Network", systemImage: "network")
                .font(.headline.scaledFont())
            
            HStack {
                Circle()
                    .fill(networkMonitor.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                    .font(.body.scaledFont())
                
                Spacer()
                
                if let connectionType = networkMonitor.connectionType {
                    Text(connectionType.description)
                        .font(.caption.scaledFont())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var syncStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline.scaledFont())
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Pending Operations:")
                        .font(.body.scaledFont())
                    
                    Spacer()
                    
                    Text("\(offlineManager.pendingSyncCount)")
                        .font(.body.scaledFont().weight(.semibold))
                        .foregroundColor(offlineManager.pendingSyncCount > 0 ? .warning : .success)
                }
                
                if let lastSync = offlineManager.lastSyncDate {
                    HStack {
                        Text("Last Sync:")
                            .font(.body.scaledFont())
                        
                        Spacer()
                        
                        Text(lastSync, style: .relative)
                            .font(.caption.scaledFont())
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var serviceStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Services", systemImage: "server.rack")
                .font(.headline.scaledFont())
            
            VStack(spacing: Spacing.xs) {
                ForEach(ServiceType.allCases, id: \.rawValue) { serviceType in
                    serviceStatusRow(for: serviceType)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func serviceStatusRow(for serviceType: ServiceType) -> some View {
        HStack {
            Circle()
                .fill(degradationService.isServiceAvailable(serviceType) ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            
            Text(serviceType.rawValue)
                .font(.caption.scaledFont())
            
            Spacer()
            
            Text(degradationService.isServiceAvailable(serviceType) ? "Healthy" : "Degraded")
                .font(.caption2.scaledFont())
                .foregroundColor(.secondary)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            if networkMonitor.isConnected && offlineManager.pendingSyncCount > 0 {
                Button {
                    Task {
                        await offlineManager.forceSyncNow()
                    }
                    HapticManager.shared.trigger(.mediumImpact)
                } label: {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
            }
            
            Button {
                offlineManager.clearPendingSync()
                HapticManager.shared.trigger(.light)
            } label: {
                Label("Clear Pending", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BorderedButtonStyle())
        }
    }
}

/// Compact sync indicator for navigation bars
struct CompactSyncIndicator: View {
    @StateObject private var offlineManager = OfflineManager.shared
    
    var body: some View {
        Group {
            if offlineManager.pendingSyncCount > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.warning)
                    .font(.caption)
                    .rotationEffect(.degrees(offlineManager.pendingSyncCount > 0 ? 360 : 0))
                    .animation(
                        .linear(duration: 2)
                        .repeatForever(autoreverses: false),
                        value: offlineManager.pendingSyncCount > 0
                    )
            } else if offlineManager.isOfflineMode {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.error)
                    .font(.caption)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: Spacing.lg) {
        SyncIndicatorView()
        CompactSyncIndicator()
    }
    .padding()
}