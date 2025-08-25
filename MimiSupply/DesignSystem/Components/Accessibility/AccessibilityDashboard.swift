//
//  AccessibilityDashboard.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import SwiftUI

/// Dashboard for monitoring and testing accessibility features
struct AccessibilityDashboard: View {
    @StateObject private var auditService = AccessibilityAuditService.shared
    @StateObject private var motionManager = MotionManager.shared
    @StateObject private var dynamicTypeManager = DynamicTypeManager.shared
    @StateObject private var highContrastManager = HighContrastManager.shared
    
    @State private var isPerformingAudit = false
    @State private var showingAuditResults = false
    @State private var selectedIssue: AccessibilityAuditService.AccessibilityIssue?
    
    var body: some View {
        NavigationView {
            ScrollView {
                ResponsiveVStack(spacing: 24) {
                    // Audit Status Card
                    auditStatusCard
                    
                    // Quick Settings
                    accessibilitySettingsCard
                    
                    // Motion Settings
                    motionSettingsCard
                    
                    // Dynamic Type Settings
                    dynamicTypeCard
                    
                    // High Contrast Settings
                    highContrastCard
                    
                    // Audit Results
                    if !auditService.auditResults.isEmpty {
                        auditResultsCard
                    }
                    
                    // Testing Tools
                    testingToolsCard
                }
                .accessibilityPadding()
            }
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Audit") {
                        performAudit()
                    }
                    .accessibleButton(
                        label: "Perform accessibility audit",
                        hint: "Analyzes current app for accessibility issues"
                    )
                    .disabled(isPerformingAudit)
                }
            }
            .sheet(isPresented: $showingAuditResults) {
                AccessibilityAuditResultsView(issues: auditService.auditResults)
            }
        }
    }
    
    // MARK: - View Components
    
    private var auditStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(scoreColor)
                    .font(.title2)
                    .accessibleImage(description: "Accessibility audit status icon")
                
                ResponsiveVStack(alignment: .leading, spacing: 4) {
                    ResponsiveText("Accessibility Score", style: .headline, weight: .semibold)
                    ResponsiveText(
                        String(format: "%.1f/100", auditService.auditScore),
                        style: .title2,
                        weight: .bold
                    )
                    .foregroundColor(scoreColor)
                }
                
                Spacer()
                
                if isPerformingAudit {
                    ProgressView()
                        .accessibilityLabel("Performing audit")
                }
            }
            
            if !auditService.auditResults.isEmpty {
                Button("View Details") {
                    showingAuditResults = true
                }
                .accessibleButton(
                    label: "View audit details",
                    hint: "Shows detailed accessibility issues and suggestions"
                )
                .foregroundColor(.emerald)
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(
            label: "Accessibility audit status",
            hint: "Current accessibility score and audit information"
        )
    }
    
    private var accessibilitySettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveText("System Settings", style: .headline, weight: .semibold)
            
            VStack(spacing: 12) {
                AccessibilitySettingRow(
                    icon: "speaker.wave.3.fill",
                    title: "VoiceOver",
                    status: VoiceOverHelpers.isVoiceOverRunning ? "On" : "Off",
                    statusColor: VoiceOverHelpers.isVoiceOverRunning ? .green : .secondary
                )
                
                AccessibilitySettingRow(
                    icon: "switch.2",
                    title: "Switch Control",
                    status: VoiceOverHelpers.isSwitchControlRunning ? "On" : "Off",
                    statusColor: VoiceOverHelpers.isSwitchControlRunning ? .green : .secondary
                )
                
                AccessibilitySettingRow(
                    icon: "hand.point.up.left.fill",
                    title: "AssistiveTouch",
                    status: VoiceOverHelpers.isAssistiveTouchRunning ? "On" : "Off",
                    statusColor: VoiceOverHelpers.isAssistiveTouchRunning ? .green : .secondary
                )
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(label: "System accessibility settings")
    }
    
    private var motionSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveText("Motion Settings", style: .headline, weight: .semibold)
            
            VStack(spacing: 12) {
                AccessibilitySettingRow(
                    icon: "slowmo",
                    title: "Reduce Motion",
                    status: motionManager.reduceMotionEnabled ? "On" : "Off",
                    statusColor: motionManager.reduceMotionEnabled ? .orange : .secondary
                )
                
                AccessibilitySettingRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Cross-Fade Transitions",
                    status: motionManager.prefersCrossFadeTransitions ? "On" : "Off",
                    statusColor: motionManager.prefersCrossFadeTransitions ? .blue : .secondary
                )
                
                AccessibilitySettingRow(
                    icon: "play.rectangle.fill",
                    title: "Video Autoplay",
                    status: motionManager.isVideoAutoplayEnabled ? "On" : "Off",
                    statusColor: motionManager.isVideoAutoplayEnabled ? .green : .secondary
                )
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(label: "Motion and animation settings")
    }
    
    private var dynamicTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveText("Dynamic Type", style: .headline, weight: .semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ResponsiveText(
                    "Current Size: \(dynamicTypeSizeDescription)",
                    style: .body
                )
                
                if dynamicTypeManager.isCurrentSizeAccessibility() {
                    Label("Accessibility Size Active", systemImage: "accessibility")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(label: "Dynamic type settings")
    }
    
    private var highContrastCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveText("Display Settings", style: .headline, weight: .semibold)
            
            VStack(spacing: 12) {
                AccessibilitySettingRow(
                    icon: "circle.lefthalf.striped.horizontal",
                    title: "Increase Contrast",
                    status: highContrastManager.isDarkerSystemColorsEnabled ? "On" : "Off",
                    statusColor: highContrastManager.isDarkerSystemColorsEnabled ? .orange : .secondary
                )
                
                AccessibilitySettingRow(
                    icon: "circle.righthalf.striped.horizontal.inverse",
                    title: "Invert Colors",
                    status: highContrastManager.isInvertColorsEnabled ? "On" : "Off",
                    statusColor: highContrastManager.isInvertColorsEnabled ? .purple : .secondary
                )
                
                AccessibilitySettingRow(
                    icon: "opacity",
                    title: "Reduce Transparency",
                    status: highContrastManager.isReduceTransparencyEnabled ? "On" : "Off",
                    statusColor: highContrastManager.isReduceTransparencyEnabled ? .blue : .secondary
                )
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(label: "Display and contrast settings")
    }
    
    private var auditResultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveText("Recent Issues", style: .headline, weight: .semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(auditService.auditResults.prefix(3))) { issue in
                    AccessibilityIssueRow(issue: issue) {
                        selectedIssue = issue
                    }
                }
            }
            
            if auditService.auditResults.count > 3 {
                Button("View All (\(auditService.auditResults.count))") {
                    showingAuditResults = true
                }
                .accessibleButton(
                    label: "View all accessibility issues",
                    hint: "Shows complete list of \(auditService.auditResults.count) issues"
                )
                .foregroundColor(.emerald)
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(label: "Recent accessibility issues")
    }
    
    private var testingToolsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            ResponsiveText("Testing Tools", style: .headline, weight: .semibold)
            
            ResponsiveVStack(spacing: 12) {
                NavigationLink(destination: Text("Accessibility Testing View")) {
                    Label("Test Components", systemImage: "hammer.fill")
                        .frame(maxWidth: .infinity)
                        .accessibilityPadding()
                        .background(Color.emerald)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .accessibleButton(
                    label: "Test accessibility components",
                    hint: "Opens testing environment for accessibility features"
                )
                
                Button("Announce Test") {
                    VoiceOverHelpers.announce("This is a test announcement from the accessibility dashboard")
                }
                .accessibleButton(
                    label: "Test VoiceOver announcement",
                    hint: "Plays a sample announcement for VoiceOver users"
                )
                .frame(maxWidth: .infinity)
                .accessibilityPadding()
                .background(Color.teal)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .accessibilityPadding()
        .background(Color(.systemBackground))
        .highContrastAware(
            normalBackground: Color(.systemGray6),
            highContrastBackground: Color(.systemBackground)
        )
        .cornerRadius(12)
        .accessibilityGroup(label: "Accessibility testing tools")
    }
    
    // MARK: - Helper Views
    
    private struct AccessibilitySettingRow: View {
        let icon: String
        let title: String
        let status: String
        let statusColor: Color
        
        var body: some View {
            ResponsiveHStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.emerald)
                    .frame(width: 20)
                    .accessibleImage(description: "\(title) icon", isDecorative: true)
                
                ResponsiveText(title, style: .body)
                
                Spacer()
                
                ResponsiveText(status, style: .caption, weight: .medium)
                    .foregroundColor(statusColor)
            }
            .accessibilityGroup(
                label: "\(title): \(status)",
                hint: "System accessibility setting"
            )
        }
    }
    
    private struct AccessibilityIssueRow: View {
        let issue: AccessibilityAuditService.AccessibilityIssue
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                ResponsiveHStack(spacing: 12) {
                    Circle()
                        .fill(issue.severity.color)
                        .frame(width: 8, height: 8)
                        .accessibleImage(description: "\(issue.severity.rawValue) severity", isDecorative: true)
                    
                    ResponsiveVStack(alignment: .leading, spacing: 2) {
                        ResponsiveText(issue.description, style: .caption, weight: .medium)
                            .multilineTextAlignment(.leading)
                        
                        ResponsiveText(issue.suggestedFix, style: .caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
            }
            .accessibleButton(
                label: "\(issue.severity.rawValue) priority: \(issue.description)",
                hint: "Tap for suggested fix: \(issue.suggestedFix)"
            )
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Computed Properties
    
    private var scoreColor: Color {
        switch auditService.auditScore {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private var dynamicTypeSizeDescription: String {
        switch dynamicTypeManager.preferredContentSizeCategory {
        case .extraSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (Default)"
        case .extraLarge: return "Extra Large"
        case .extraExtraLarge: return "Extra Extra Large"
        case .extraExtraExtraLarge: return "Extra Extra Extra Large"
        case .accessibilityMedium: return "Accessibility Medium"
        case .accessibilityLarge: return "Accessibility Large"
        case .accessibilityExtraLarge: return "Accessibility Extra Large"
        case .accessibilityExtraExtraLarge: return "Accessibility Extra Extra Large"
        case .accessibilityExtraExtraExtraLarge: return "Accessibility Extra Extra Extra Large"
        default: return "Unknown"
        }
    }
    
    // MARK: - Actions
    
    private func performAudit() {
        isPerformingAudit = true
        
        Task {
            await auditService.performAudit()
            
            await MainActor.run {
                isPerformingAudit = false
                VoiceOverHelpers.announce("Accessibility audit completed with score \(String(format: "%.0f", auditService.auditScore)) out of 100")
            }
        }
    }
}

// MARK: - Audit Results View

struct AccessibilityAuditResultsView: View {
    let issues: [AccessibilityAuditService.AccessibilityIssue]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedIssues.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { severity in
                    Section(header: Text(severity.rawValue.capitalized)) {
                        ForEach(groupedIssues[severity] ?? []) { issue in
                            VStack(alignment: .leading, spacing: 8) {
                                ResponsiveText(issue.description, style: .body, weight: .medium)
                                
                                ResponsiveText("Suggested Fix:", style: .caption, weight: .semibold)
                                    .foregroundColor(.emerald)
                                
                                ResponsiveText(issue.suggestedFix, style: .caption)
                                    .foregroundColor(.secondary)
                                
                                if let viewId = issue.viewIdentifier {
                                    ResponsiveText("View: \(viewId)", style: .caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .accessibilityGroup(
                                label: "\(severity.rawValue) issue: \(issue.description)",
                                hint: "Suggested fix: \(issue.suggestedFix)"
                            )
                        }
                    }
                }
            }
            .navigationTitle("Audit Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibleButton(label: "Close audit results")
                }
            }
        }
    }
    
    private var groupedIssues: [AccessibilityAuditService.AccessibilityIssue.Severity: [AccessibilityAuditService.AccessibilityIssue]] {
        Dictionary(grouping: issues, by: { $0.severity })
    }
}

// MARK: - Preview

struct AccessibilityDashboard_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityDashboard()
            .environment(\.dynamicTypeSize, .large)
    }
}