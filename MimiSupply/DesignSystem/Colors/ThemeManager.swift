import SwiftUI
import OSLog

// MARK: - Theme System
@MainActor
final class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .default
    @Published var colorSchemePreference: ColorSchemeManager.ColorSchemePreference = .system
    @Published var isHighContrastEnabled: Bool = false
    @Published var customAccentColor: Color?
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Theme")
    
    static let shared = ThemeManager()
    
    private init() {
        loadUserPreferences()
        setupAccessibilityObservers()
        logger.info("🎨 Theme Manager initialized")
    }
    
    // MARK: - Theme Management
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
        logger.info("🎨 Theme changed to: \(theme.displayName)")
    }
    
    func setColorSchemePreference(_ preference: ColorSchemeManager.ColorSchemePreference) {
        colorSchemePreference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: "color_scheme_preference")
        logger.info("🎨 Color scheme preference: \(preference.displayName)")
    }
    
    func setCustomAccentColor(_ color: Color?) {
        customAccentColor = color
        if let color = color {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: "custom_accent_color")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: "custom_accent_color")
        }
    }
    
    // MARK: - Private Methods
    private func loadUserPreferences() {
        // Load theme
        if let themeRawValue = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppTheme(rawValue: themeRawValue) {
            currentTheme = theme
        }
        
        // Load color scheme preference
        if let preferenceRawValue = UserDefaults.standard.string(forKey: "color_scheme_preference"),
           let preference = ColorSchemeManager.ColorSchemePreference(rawValue: preferenceRawValue) {
            colorSchemePreference = preference
        }
        
        // Load custom accent color
        if let data = UserDefaults.standard.data(forKey: "custom_accent_color"),
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor {
            customAccentColor = Color(uiColor)
        }
        
        // Load accessibility settings
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    private func setupAccessibilityObservers() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
            }
        }
    }
    
    // MARK: - Computed Properties
    var effectiveAccentColor: Color {
        return customAccentColor ?? currentTheme.accentColor
    }
    
    var isDarkMode: Bool {
        switch colorSchemePreference {
        case .dark: return true
        case .light: return false
        case .system: return false // Would be determined by environment in real app
        }
    }
}

// MARK: - App Themes
enum AppTheme: String, CaseIterable {
    case `default` = "default"
    case vibrant = "vibrant"
    case minimal = "minimal"
    case business = "business"
    case analytics = "analytics"
    
    var displayName: String {
        switch self {
        case .default: return "Default"
        case .vibrant: return "Vibrant"
        case .minimal: return "Minimal"
        case .business: return "Business"
        case .analytics: return "Analytics"
        }
    }
    
    var description: String {
        switch self {
        case .default: return "Balanced colors for everyday use"
        case .vibrant: return "Bold and energetic colors"
        case .minimal: return "Clean and subdued palette"
        case .business: return "Professional and trustworthy"
        case .analytics: return "Data-focused with clear contrasts"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .default: return ColorTokens.Brand.primary
        case .vibrant: return .orange
        case .minimal: return .gray600
        case .business: return .blue
        case .analytics: return .purple
        }
    }
    
    var primaryGradient: LinearGradient {
        switch self {
        case .default:
            return LinearGradient(colors: [ColorTokens.Brand.primary, ColorTokens.Brand.primaryLight], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .vibrant:
            return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .minimal:
            return LinearGradient(colors: [.gray600, .gray400], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .analytics:
            return LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var surfaceColors: ThemeSurfaceColors {
        switch self {
        case .default:
            return ThemeSurfaceColors(
                primary: ColorTokens.UI.surfacePrimary,
                secondary: ColorTokens.UI.surfaceSecondary,
                elevated: ColorTokens.UI.surfaceElevated
            )
        case .vibrant:
            return ThemeSurfaceColors(
                primary: Color.colorDynamic(light: Color(red: 0.95, green: 0.95, blue: 0.95), dark: Color(red: 0.1, green: 0.1, blue: 0.1)),
                secondary: Color.colorDynamic(light: Color(red: 0.9, green: 0.9, blue: 0.9), dark: Color(red: 0.2, green: 0.2, blue: 0.2)),
                elevated: Color.colorDynamic(light: .white, dark: Color(red: 0.15, green: 0.15, blue: 0.15))
            )
        case .minimal:
            return ThemeSurfaceColors(
                primary: Color.dynamic(light: .gray50, dark: .gray900),
                secondary: Color.dynamic(light: .gray100, dark: .gray800),
                elevated: Color.dynamic(light: .white, dark: .gray700)
            )
        case .business:
            return ThemeSurfaceColors(
                primary: Color.colorDynamic(light: .white, dark: Color(red: 0.1, green: 0.1, blue: 0.1)),
                secondary: Color.colorDynamic(light: .blue.opacity(0.05), dark: .blue.opacity(0.1)),
                elevated: Color.colorDynamic(light: .white, dark: Color(red: 0.2, green: 0.2, blue: 0.2))
            )
        case .analytics:
            return ThemeSurfaceColors(
                primary: Color.colorDynamic(light: .white, dark: .black),
                secondary: Color.colorDynamic(light: .purple.opacity(0.05), dark: .purple.opacity(0.1)),
                elevated: Color.colorDynamic(light: .white, dark: Color(red: 0.1, green: 0.1, blue: 0.1))
            )
        }
    }
}

struct ThemeSurfaceColors {
    let primary: Color
    let secondary: Color
    let elevated: Color
}

// MARK: - Theme-Aware View Modifier
struct ThemeAwareModifier: ViewModifier {
    @StateObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .accentColor(themeManager.effectiveAccentColor)
            .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch themeManager.colorSchemePreference {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil // Let system decide
        }
    }
}

extension View {
    func themeAware() -> some View {
        modifier(ThemeAwareModifier())
    }
}

// MARK: - Theme Settings View
struct ThemeSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var colorSchemeManager = ColorSchemeManager.shared
    @State private var showingCustomColorPicker = false
    
    var body: some View {
        NavigationStack {
            List {
                // Color Scheme Section
                Section {
                    ForEach(ColorSchemeManager.ColorSchemePreference.allCases, id: \.self) { preference in
                        ColorSchemeRow(
                            preference: preference,
                            isSelected: themeManager.colorSchemePreference == preference
                        ) {
                            themeManager.setColorSchemePreference(preference)
                        }
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose how the app appears. System matches your device settings.")
                }
                
                // Theme Section
                Section {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeRow(
                            theme: theme,
                            isSelected: themeManager.currentTheme == theme
                        ) {
                            themeManager.setTheme(theme)
                        }
                    }
                } header: {
                    Text("Theme")
                } footer: {
                    Text("Select a visual theme that matches your style and use case.")
                }
                
                // Custom Accent Color
                Section {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(themeManager.effectiveAccentColor)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom Accent Color")
                                .font(.bodyMedium)
                            Text("Override the theme's accent color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Choose") {
                            showingCustomColorPicker = true
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.effectiveAccentColor)
                    }
                    
                    if themeManager.customAccentColor != nil {
                        Button("Reset to Default") {
                            themeManager.setCustomAccentColor(nil)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                } header: {
                    Text("Customization")
                }
                
                // Accessibility Section
                Section {
                    HStack {
                        Image(systemName: "accessibility")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("High Contrast")
                                .font(.bodyMedium)
                            Text(themeManager.isHighContrastEnabled ? "Enabled" : "Follow system setting")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if themeManager.isHighContrastEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                } header: {
                    Text("Accessibility")
                } footer: {
                    Text("High contrast colors are automatically applied when enabled in system settings.")
                }
            }
            .navigationTitle("Theme & Appearance")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCustomColorPicker) {
            CustomColorPickerView { color in
                themeManager.setCustomAccentColor(color)
            }
        }
    }
}

// MARK: - Color Scheme Row
struct ColorSchemeRow: View {
    let preference: ColorSchemeManager.ColorSchemePreference
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: preference.icon)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(preference.displayName)
                        .font(.bodyMedium)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Theme Row
struct ThemeRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Theme preview
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme.primaryGradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray300, lineWidth: isSelected ? 2 : 1)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.bodyMedium)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Color Picker
struct CustomColorPickerView: View {
    let onColorSelected: (Color) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedColor = Color.blue
    
    let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, .brown
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Color preview
                RoundedRectangle(cornerRadius: 20)
                    .fill(selectedColor)
                    .frame(height: 100)
                    .shadow(radius: 4)
                
                // Color picker
                ColorPicker("Custom Color", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                
                // Preset colors
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(Array(presetColors.enumerated()), id: \.offset) { _, color in
                        Button {
                            selectedColor = color
                        } label: {
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray300, lineWidth: 1)
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onColorSelected(selectedColor)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Theme Settings") {
    ThemeSettingsView()
}