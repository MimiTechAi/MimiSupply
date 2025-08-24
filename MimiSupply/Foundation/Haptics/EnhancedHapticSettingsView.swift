import SwiftUI

// MARK: - Enhanced Haptic Settings View
struct EnhancedHapticSettingsView: View {
    @StateObject private var hapticManager = HapticManager.shared
    @State private var showingTestSection = false
    
    var body: some View {
        NavigationStack {
            List {
                // Main Settings Section
                Section {
                    HStack {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .foregroundColor(.emerald)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptic Feedback")
                                .font(.bodyMedium)
                            Text("Feel physical responses to your interactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $hapticManager.isHapticsEnabled)
                            .labelsHidden()
                            .onChange(of: hapticManager.isHapticsEnabled) { _, newValue in
                                if newValue {
                                    hapticManager.trigger(.toggleOn, context: .system)
                                }
                            }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Settings")
                } footer: {
                    Text("Haptic feedback provides physical sensations that enhance your interaction with the app.")
                }
                
                // Intensity Settings
                if hapticManager.isHapticsEnabled {
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Intensity")
                                    .font(.bodyMedium)
                                Spacer()
                                Text(hapticManager.hapticIntensity.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                                    IntensityButton(
                                        intensity: intensity,
                                        isSelected: hapticManager.hapticIntensity == intensity
                                    ) {
                                        hapticManager.setIntensity(intensity)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        HStack {
                            Image(systemName: "gearshape")
                                .foregroundColor(.emerald)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contextual Haptics")
                                    .font(.bodyMedium)
                                Text("Smart haptics based on app context")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $hapticManager.contextualHapticsEnabled)
                                .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        
                    } header: {
                        Text("Customization")
                    } footer: {
                        Text("Contextual haptics provide different feedback patterns based on the type of interaction and app context.")
                    }
                    
                    // Test Section
                    Section {
                        DisclosureGroup("Test Haptic Feedback", isExpanded: $showingTestSection) {
                            VStack(spacing: 16) {
                                // Basic Haptics
                                HapticTestGroup(
                                    title: "Basic Interactions",
                                    haptics: [
                                        ("Light Tap", .lightImpact, .ui),
                                        ("Medium Tap", .mediumImpact, .ui),
                                        ("Heavy Tap", .heavyImpact, .ui),
                                        ("Selection", .selection, .ui)
                                    ]
                                )
                                
                                // Notification Haptics
                                HapticTestGroup(
                                    title: "Notifications",
                                    haptics: [
                                        ("Success", .success, .system),
                                        ("Warning", .warning, .system),
                                        ("Error", .error, .system)
                                    ]
                                )
                                
                                // App-Specific Haptics
                                HapticTestGroup(
                                    title: "App Actions",
                                    haptics: [
                                        ("Add to Cart", .addToCart, .commerce),
                                        ("Payment Success", .paymentSuccess, .commerce),
                                        ("Data Loaded", .dataLoaded, .analytics),
                                        ("Chart Tap", .chartInteraction, .analytics)
                                    ]
                                )
                                
                                // Complex Patterns
                                HapticTestGroup(
                                    title: "Complex Patterns",
                                    haptics: [
                                        ("Success Sequence", .successSequence, .system),
                                        ("Celebration", .celebrationPattern, .gaming),
                                        ("Achievement", .achievementUnlocked, .gaming)
                                    ]
                                )
                            }
                            .padding(.top)
                        }
                        .accentColor(.emerald)
                    } header: {
                        Text("Testing")
                    }
                }
                
                // Accessibility Section
                Section {
                    HStack {
                        Image(systemName: "accessibility")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Integration")
                                .font(.bodyMedium)
                            Text("Adapts to system accessibility settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                    
                    if UIAccessibility.isReduceMotionEnabled {
                        Label("Reduce Motion is enabled - haptics are automatically adjusted", 
                              systemImage: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("Haptic feedback automatically adjusts based on your accessibility preferences like Reduce Motion.")
                }
            }
            .navigationTitle("Haptic Feedback")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Intensity Button
struct IntensityButton: View {
    let intensity: HapticIntensity
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.emerald : Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: intensityIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(intensity.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .emerald : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var intensityIcon: String {
        switch intensity {
        case .subtle: return "circle"
        case .normal: return "circle.fill"
        case .strong: return "circle.fill"
        }
    }
}

// MARK: - Haptic Test Group
struct HapticTestGroup: View {
    let title: String
    let haptics: [(String, HapticFeedbackType, HapticContext)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(Array(haptics.enumerated()), id: \.offset) { _, haptic in
                    HapticTestButton(
                        title: haptic.0,
                        type: haptic.1,
                        context: haptic.2
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Haptic Test Button
struct EnhancedHapticTestButton: View {
    let hapticType: HapticFeedbackType
    let context: HapticContext
    let title: String
    
    var body: some View {
        Button {
            HapticManager.shared.trigger(hapticType, context: context)
        } label: {
            Text(title)
                .font(.caption.scaledFont())
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Haptic Settings Row
struct HapticSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodyMedium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview("Enhanced Haptic Settings") {
    EnhancedHapticSettingsView()
}

#Preview("Haptic Test Button") {
    VStack(spacing: 20) {
        HapticTestGroup(
            title: "Test Group",
            haptics: [
                ("Success", .success, .system),
                ("Error", .error, .system),
                ("Add to Cart", .addToCart, .commerce),
                ("Chart Tap", .chartInteraction, .analytics)
            ]
        )
    }
    .padding()
}