//
//  SyncStatusDashboard.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI
import Combine
import OSLog

/// Comprehensive sync status dashboard for admin/debugging
struct SyncStatusDashboard: View {
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var degradationService = GracefulDegradationService.shared
    
    @State private var showingClearConfirmation = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Overview Tab
                overviewTab
                    .tabItem {
                        Label("Overview", systemImage: "gauge")
                    }
                    .tag(0)
                
                // Services Tab
                servicesTab
                    .tabItem {
                        Label("Services", systemImage: "server.rack")
                    }
                    .tag(1)
                
                // Network Tab
                networkTab
                    .tabItem {
                        Label("Network", systemImage: "network")
                    }
                    .tag(2)
                
                // Logs Tab
                logsTab
                    .tabItem {
                        Label("Logs", systemImage: "doc.text")
                    }
                    .tag(3)
            }
            .navigationTitle("Sync Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await offlineManager.forceSyncNow()
                            }
                        } label: {
                            Label("Force Sync", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(offlineManager.isOfflineMode)
                        
                        Button {
                            showingClearConfirmation = true
                        } label: {
                            Label("Clear Pending", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        Button {
                            // Export logs
                        } label: {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog(
                "Clear Pending Sync",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    offlineManager.clearPendingSync()
                }
                
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will clear all pending sync operations. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Status Cards
                statusCards
                
                // Sync Metrics
                syncMetrics
                
                // Quick Actions
                quickActions
            }
            .padding(Spacing.lg)
        }
    }
    
    private var statusCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Spacing.md) {
            StatusCard(
                title: "Connection",
                value: networkMonitor.isConnected ? "Online" : "Offline",
                icon: networkMonitor.isConnected ? "wifi" : "wifi.slash",
                color: networkMonitor.isConnected ? .success : .error
            )
            
            StatusCard(
                title: "Sync Status",
                value: offlineManager.pendingSyncCount > 0 ? "Pending" : "Complete",
                icon: offlineManager.pendingSyncCount > 0 ? "clock" : "checkmark.circle.fill",
                color: offlineManager.pendingSyncCount > 0 ? .warning : .success
            )
            
            StatusCard(
                title: "Services",
                value: healthyServicesCount,
                icon: "server.rack",
                color: servicesColor
            )
            
            StatusCard(
                title: "Last Sync",
                value: lastSyncText,
                icon: "arrow.triangle.2.circlepath",
                color: .accentColor
            )
        }
    }
    
    private var syncMetrics: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Sync Metrics")
                .font(.headline.scaledFont().weight(.semibold))
            
            VStack(spacing: Spacing.sm) {
                MetricRow(
                    title: "Pending Operations",
                    value: "\(offlineManager.pendingSyncCount)",
                    trend: nil
                )
                
                MetricRow(
                    title: "Cache Size",
                    value: "12.3 MB", // Mock data
                    trend: nil
                )
                
                MetricRow(
                    title: "Success Rate",
                    value: "98.5%", // Mock data
                    trend: .positive
                )
                
                MetricRow(
                    title: "Avg Sync Time",
                    value: "1.2s", // Mock data
                    trend: .negative
                )
            }
            .padding(Spacing.md)
            .background(Color.surfaceSecondary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quick Actions")
                .font(.headline.scaledFont().weight(.semibold))
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.sm) {
                ActionButton(
                    title: "Force Sync",
                    icon: "arrow.triangle.2.circlepath",
                    color: .accentColor,
                    isDisabled: offlineManager.isOfflineMode
                ) {
                    Task {
                        await offlineManager.forceSyncNow()
                    }
                }
                
                ActionButton(
                    title: "Clear Cache",
                    icon: "trash",
                    color: .warning
                ) {
                    CacheManager.shared.clearCache()
                }
                
                ActionButton(
                    title: "Reset Services",
                    icon: "arrow.clockwise",
                    color: .error
                ) {
                    // Reset services
                }
                
                ActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    // Export data
                }
            }
        }
    }
    
    // MARK: - Services Tab
    
    private var servicesTab: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Service Status Overview
                serviceStatusOverview
                
                // Degradation Level
                degradationLevelCard
                
                // Individual Services
                individualServicesStatus
            }
            .padding(Spacing.lg)
        }
    }
    
    private var serviceStatusOverview: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Service Health")
                .font(.headline.scaledFont().weight(.semibold))
            
            HStack(spacing: Spacing.lg) {
                serviceHealthMetric(
                    title: "Healthy",
                    count: ServiceType.allCases.count - degradationService.getDegradedServices().count,
                    color: .success
                )
                
                serviceHealthMetric(
                    title: "Degraded",
                    count: degradationService.getDegradedServices().count,
                    color: .error
                )
                
                Spacer()
            }
        }
        .padding(Spacing.lg)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func serviceHealthMetric(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text("\(count)")
                .font(.title.scaledFont().weight(.bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption.scaledFont())
                .foregroundColor(.secondary)
        }
    }
    
    private var degradationLevelCard: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: degradationService.degradationLevel.icon)
                .font(.title2)
                .foregroundColor(degradationService.degradationLevel.color)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("System Status: \(degradationService.degradationLevel.rawValue)")
                    .font(.headline.scaledFont().weight(.semibold))
                    .foregroundColor(degradationService.degradationLevel.color)
                
                if let message = degradationService.getStatusMessage() {
                    Text(message)
                        .font(.caption.scaledFont())
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(degradationService.degradationLevel.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var individualServicesStatus: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Service Details")
                .font(.headline.scaledFont().weight(.semibold))
            
            VStack(spacing: Spacing.sm) {
                ForEach(ServiceType.allCases, id: \.rawValue) { serviceType in
                    ServiceStatusRow(serviceType: serviceType)
                }
            }
        }
    }
    
    // MARK: - Network Tab
    
    private var networkTab: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                // Network Status
                networkStatusCard
                
                // Connection History
                connectionHistoryCard
                
                // Network Diagnostics
                networkDiagnosticsCard
            }
            .padding(Spacing.lg)
        }
    }
    
    private var networkStatusCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Network Status")
                .font(.headline.scaledFont().weight(.semibold))
            
            VStack(spacing: Spacing.sm) {
                NetworkMetricRow(
                    title: "Status",
                    value: networkMonitor.isConnected ? "Connected" : "Disconnected"
                )
                
                if let connectionType = networkMonitor.connectionType {
                    NetworkMetricRow(
                        title: "Type",
                        value: connectionType.description
                    )
                }
                
                NetworkMetricRow(
                    title: "Quality",
                    value: "Good" // Mock data
                )
                
                NetworkMetricRow(
                    title: "Latency",
                    value: "45ms" // Mock data
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var connectionHistoryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Connection History")
                .font(.headline.scaledFont().weight(.semibold))
            
            // Mock connection events
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ConnectionEvent(
                    timestamp: Date(),
                    event: "Connected via WiFi",
                    type: .connection
                )
                
                ConnectionEvent(
                    timestamp: Date().addingTimeInterval(-300),
                    event: "Connection lost",
                    type: .disconnection
                )
                
                ConnectionEvent(
                    timestamp: Date().addingTimeInterval(-600),
                    event: "Connected via Cellular",
                    type: .connection
                )
            }
        }
        .padding(Spacing.lg)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var networkDiagnosticsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Network Diagnostics")
                .font(.headline.scaledFont().weight(.semibold))
            
            VStack(spacing: Spacing.sm) {
                Button {
                    // Run speed test
                } label: {
                    Label("Run Speed Test", systemImage: "speedometer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                
                Button {
                    // Test CloudKit connectivity
                } label: {
                    Label("Test CloudKit", systemImage: "icloud")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
                
                Button {
                    // Ping external services
                } label: {
                    Label("Ping Services", systemImage: "network")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondary)
            }
        }
        .padding(Spacing.lg)
        .background(Color.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Logs Tab
    
    private var logsTab: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.lg) {
                Text("System Logs")
                    .font(.headline.scaledFont().weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Mock log entries
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    LogEntry(
                        timestamp: Date(),
                        level: .info,
                        category: "Sync",
                        message: "Sync completed successfully"
                    )
                    
                    LogEntry(
                        timestamp: Date().addingTimeInterval(-60),
                        level: .warning,
                        category: "Network",
                        message: "Connection unstable, retrying operations"
                    )
                    
                    LogEntry(
                        timestamp: Date().addingTimeInterval(-120),
                        level: .error,
                        category: "CloudKit",
                        message: "Failed to save record: Network unavailable"
                    )
                    
                    LogEntry(
                        timestamp: Date().addingTimeInterval(-180),
                        level: .info,
                        category: "Cache",
                        message: "Cache cleared successfully"
                    )
                }
            }
            .padding(Spacing.lg)
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthyServicesCount: String {
        let total = ServiceType.allCases.count
        let degraded = degradationService.getDegradedServices().count
        return "\(total - degraded)/\(total)"
    }
    
    private var servicesColor: Color {
        let degradedCount = degradationService.getDegradedServices().count
        if degradedCount == 0 {
            return .success
        } else if degradedCount <= 2 {
            return .warning
        } else {
            return .error
        }
    }
    
    private var lastSyncText: String {
        if let lastSync = offlineManager.lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: lastSync, relativeTo: Date())
        } else {
            return "Never"
        }
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.scaledFont().weight(.semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption.scaledFont())
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let trend: TrendDirection?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body.scaledFont())
            
            Spacer()
            
            HStack(spacing: Spacing.xs) {
                if let trend = trend {
                    Image(systemName: trend.iconName)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
                
                Text(value)
                    .font(.body.scaledFont().weight(.semibold))
            }
        }
    }
}

enum TrendDirection {
    case positive, negative, neutral
    
    var iconName: String {
        switch self {
        case .positive:
            return "arrow.up"
        case .negative:
            return "arrow.down"
        case .neutral:
            return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .positive:
            return .success
        case .negative:
            return .error
        case .neutral:
            return .secondary
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isDisabled: Bool
    let action: () -> Void
    
    init(
        title: String,
        icon: String,
        color: Color,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .font(.caption.scaledFont().weight(.medium))
            }
            .foregroundColor(isDisabled ? .secondary : color)
            .frame(maxWidth: .infinity)
            .padding(Spacing.md)
            .background(isDisabled ? Color.secondary.opacity(0.1) : color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isDisabled)
    }
}

struct ServiceStatusRow: View {
    let serviceType: ServiceType
    @StateObject private var degradationService = GracefulDegradationService.shared
    
    var body: some View {
        HStack {
            Circle()
                .fill(isHealthy ? .success : .error)
                .frame(width: 8, height: 8)
            
            Text(serviceType.rawValue)
                .font(.body.scaledFont())
            
            Spacer()
            
            Text(isHealthy ? "Healthy" : "Degraded")
                .font(.caption.scaledFont())
                .foregroundColor(isHealthy ? .success : .error)
        }
        .padding(Spacing.sm)
        .background(Color.surfaceSecondary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var isHealthy: Bool {
        degradationService.isServiceAvailable(serviceType)
    }
}

struct NetworkMetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body.scaledFont())
            
            Spacer()
            
            Text(value)
                .font(.body.scaledFont().weight(.semibold))
        }
    }
}

struct ConnectionEvent: View {
    let timestamp: Date
    let event: String
    let type: ConnectionEventType
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(type.color)
                .frame(width: 6, height: 6)
            
            Text(event)
                .font(.caption.scaledFont())
            
            Spacer()
            
            Text(timestamp, style: .time)
                .font(.caption2.scaledFont().monospacedDigit())
                .foregroundColor(.secondary)
        }
    }
}

enum ConnectionEventType {
    case connection, disconnection
    
    var color: Color {
        switch self {
        case .connection:
            return .success
        case .disconnection:
            return .error
        }
    }
}

struct LogEntry: View {
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text(timestamp, style: .time)
                .font(.caption2.scaledFont().monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(level.rawValue.uppercased())
                .font(.caption2.scaledFont().weight(.semibold))
                .foregroundColor(level.color)
                .frame(width: 50, alignment: .leading)
            
            Text(category)
                .font(.caption2.scaledFont())
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(message)
                .font(.caption2.scaledFont())
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 2)
    }
}

enum LogLevel: String {
    case info, warning, error
    
    var color: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }
}

// MARK: - Preview

#Preview {
    SyncStatusDashboard()
}