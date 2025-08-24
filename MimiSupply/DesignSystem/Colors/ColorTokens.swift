import SwiftUI

// MARK: - Color Token System
struct ColorTokens {
    
    // MARK: - Brand Colors
    struct Brand {
        static let primary = Color("Brand/Primary")
        static let primaryLight = Color("Brand/PrimaryLight")
        static let primaryDark = Color("Brand/PrimaryDark")
        static let secondary = Color("Brand/Secondary")
        static let tertiary = Color("Brand/Tertiary")
        static let accent = Color("Brand/Accent")
        
        // Brand gradient
        static let gradient = LinearGradient(
            colors: [primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - UI Colors
    struct UI {
        // Backgrounds
        static let backgroundPrimary = Color("UI/BackgroundPrimary")
        static let backgroundSecondary = Color("UI/BackgroundSecondary")
        static let backgroundTertiary = Color("UI/BackgroundTertiary")
        static let backgroundElevated = Color("UI/BackgroundElevated")
        static let backgroundOverlay = Color("UI/BackgroundOverlay")
        
        // Surfaces
        static let surfacePrimary = Color("UI/SurfacePrimary")
        static let surfaceSecondary = Color("UI/SurfaceSecondary")
        static let surfaceElevated = Color("UI/SurfaceElevated")
        static let surfaceInverse = Color("UI/SurfaceInverse")
        
        // Borders
        static let borderPrimary = Color("UI/BorderPrimary")
        static let borderSecondary = Color("UI/BorderSecondary")
        static let borderFocus = Color("UI/BorderFocus")
        static let borderError = Color("UI/BorderError")
        
        // Separators
        static let separator = Color("UI/Separator")
        static let separatorOpaque = Color("UI/SeparatorOpaque")
    }
    
    // MARK: - Content Colors
    struct Content {
        // Text
        static let textPrimary = Color("Content/TextPrimary")
        static let textSecondary = Color("Content/TextSecondary")
        static let textTertiary = Color("Content/TextTertiary")
        static let textDisabled = Color("Content/TextDisabled")
        static let textInverse = Color("Content/TextInverse")
        static let textPlaceholder = Color("Content/TextPlaceholder")
        
        // Icons
        static let iconPrimary = Color("Content/IconPrimary")
        static let iconSecondary = Color("Content/IconSecondary")
        static let iconTertiary = Color("Content/IconTertiary")
        static let iconDisabled = Color("Content/IconDisabled")
        static let iconInverse = Color("Content/IconInverse")
    }
    
    // MARK: - Status Colors
    struct Status {
        static let success = Color("Status/Success")
        static let successBackground = Color("Status/SuccessBackground")
        static let warning = Color("Status/Warning")
        static let warningBackground = Color("Status/WarningBackground")
        static let error = Color("Status/Error")
        static let errorBackground = Color("Status/ErrorBackground")
        static let info = Color("Status/Info")
        static let infoBackground = Color("Status/InfoBackground")
    }
    
    // MARK: - Interactive Colors
    struct Interactive {
        static let primary = Color("Interactive/Primary")
        static let primaryHover = Color("Interactive/PrimaryHover")
        static let primaryPressed = Color("Interactive/PrimaryPressed")
        static let primaryDisabled = Color("Interactive/PrimaryDisabled")
        
        static let secondary = Color("Interactive/Secondary")
        static let secondaryHover = Color("Interactive/SecondaryHover")
        static let secondaryPressed = Color("Interactive/SecondaryPressed")
        static let secondaryDisabled = Color("Interactive/SecondaryDisabled")
        
        static let tertiary = Color("Interactive/Tertiary")
        static let tertiaryHover = Color("Interactive/TertiaryHover")
        static let tertiaryPressed = Color("Interactive/TertiaryPressed")
        
        static let destructive = Color("Interactive/Destructive")
        static let destructiveHover = Color("Interactive/DestructiveHover")
        static let destructivePressed = Color("Interactive/DestructivePressed")
    }
    
    // MARK: - Special Colors
    struct Special {
        static let highlight = Color("Special/Highlight")
        static let selection = Color("Special/Selection")
        static let shadow = Color("Special/Shadow")
        static let overlay = Color("Special/Overlay")
        static let shimmer = Color("Special/Shimmer")
        
        // Business Intelligence specific
        static let analytics = Color("Special/Analytics")
        static let revenue = Color("Special/Revenue")
        static let orders = Color("Special/Orders")
        static let customers = Color("Special/Customers")
        static let performance = Color("Special/Performance")
    }
}

// MARK: - Backwards Compatibility & Migration
extension Color {
    
    // MARK: - Migration from old color system
    static let emerald = ColorTokens.Brand.primary
    static let chalk = ColorTokens.UI.backgroundPrimary
    static let graphite = ColorTokens.Content.textPrimary
    
    // MARK: - Semantic colors with dark mode support
    static let success = ColorTokens.Status.success
    static let warning = ColorTokens.Status.warning
    static let error = ColorTokens.Status.error
    static let info = ColorTokens.Status.info
    
    // MARK: - Neutral grays with dark mode variants
    static let gray50 = Color("Neutrals/Gray50")
    static let gray100 = Color("Neutrals/Gray100")
    static let gray200 = Color("Neutrals/Gray200")
    static let gray300 = Color("Neutrals/Gray300")
    static let gray400 = Color("Neutrals/Gray400")
    static let gray500 = Color("Neutrals/Gray500")
    static let gray600 = Color("Neutrals/Gray600")
    static let gray700 = Color("Neutrals/Gray700")
    static let gray800 = Color("Neutrals/Gray800")
    static let gray900 = Color("Neutrals/Gray900")
    
    // MARK: - High Contrast Support
    var highContrastVariant: Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return self.opacity(0.9)
        } else {
            return self
        }
    }
    
    // MARK: - Dynamic Color Creation
    static func dynamic(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // MARK: - Elevated Surface Colors
    static func elevatedSurface(level: Int = 1) -> Color {
        switch level {
        case 1: return ColorTokens.UI.surfaceSecondary
        case 2: return ColorTokens.UI.surfaceElevated
        default: return ColorTokens.UI.surfacePrimary
        }
    }
}

// MARK: - Color Scheme Detection
@MainActor
final class ColorSchemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme = .light
    @Published var userPreference: ColorSchemePreference = .system
    @Published var isHighContrast: Bool = false
    
    enum ColorSchemePreference: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
        
        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "gear"
            }
        }
    }
    
    static let shared = ColorSchemeManager()
    
    private init() {
        self.userPreference = ColorSchemePreference(
            rawValue: UserDefaults.standard.string(forKey: "color_scheme_preference") ?? "system"
        ) ?? .system
        
        self.isHighContrast = UIAccessibility.isDarkerSystemColorsEnabled
        
        updateColorScheme()
        
        // Listen for accessibility changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isHighContrast = UIAccessibility.isDarkerSystemColorsEnabled
        }
    }
    
    func setPreference(_ preference: ColorSchemePreference) {
        userPreference = preference
        UserDefaults.standard.set(preference.rawValue, forKey: "color_scheme_preference")
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        switch userPreference {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            // In a real app, you'd get this from the environment
            colorScheme = .light // Default fallback
        }
    }
    
    var effectiveColorScheme: ColorScheme {
        return colorScheme
    }
    
    var isDarkMode: Bool {
        return effectiveColorScheme == .dark
    }
}

// MARK: - SwiftUI Environment Integration
struct ColorSchemePreferenceKey: EnvironmentKey {
    static let defaultValue: ColorSchemeManager.ColorSchemePreference = .system
}

extension EnvironmentValues {
    var colorSchemePreference: ColorSchemeManager.ColorSchemePreference {
        get { self[ColorSchemePreferenceKey.self] }
        set { self[ColorSchemePreferenceKey.self] = newValue }
    }
}

// MARK: - View Modifiers
struct DynamicColorModifier: ViewModifier {
    let lightColor: Color
    let darkColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(colorScheme == .dark ? darkColor : lightColor)
    }
}

struct ElevatedSurfaceModifier: ViewModifier {
    let level: Int
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Color.elevatedSurface(level: level))
    }
}

extension View {
    func dynamicColor(light: Color, dark: Color) -> some View {
        modifier(DynamicColorModifier(lightColor: light, darkColor: dark))
    }
    
    func elevatedSurface(level: Int = 1) -> some View {
        modifier(ElevatedSurfaceModifier(level: level))
    }
}

// MARK: - Color Preview Helper
struct ColorTokenPreview: View {
    let title: String
    let colors: [(String, Color)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(Array(colors.enumerated()), id: \.offset) { _, colorPair in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorPair.1)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ColorTokens.UI.borderPrimary, lineWidth: 1)
                            )
                        
                        Text(colorPair.0)
                            .font(.caption2)
                            .foregroundColor(ColorTokens.Content.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Color Tokens") {
    ScrollView {
        VStack(spacing: 24) {
            ColorTokenPreview(
                title: "Brand Colors",
                colors: [
                    ("Primary", ColorTokens.Brand.primary),
                    ("Primary Light", ColorTokens.Brand.primaryLight),
                    ("Primary Dark", ColorTokens.Brand.primaryDark),
                    ("Secondary", ColorTokens.Brand.secondary),
                    ("Tertiary", ColorTokens.Brand.tertiary),
                    ("Accent", ColorTokens.Brand.accent)
                ]
            )
            
            ColorTokenPreview(
                title: "UI Colors",
                colors: [
                    ("Background Primary", ColorTokens.UI.backgroundPrimary),
                    ("Background Secondary", ColorTokens.UI.backgroundSecondary),
                    ("Surface Primary", ColorTokens.UI.surfacePrimary),
                    ("Surface Elevated", ColorTokens.UI.surfaceElevated),
                    ("Border Primary", ColorTokens.UI.borderPrimary),
                    ("Separator", ColorTokens.UI.separator)
                ]
            )
            
            ColorTokenPreview(
                title: "Status Colors",
                colors: [
                    ("Success", ColorTokens.Status.success),
                    ("Warning", ColorTokens.Status.warning),
                    ("Error", ColorTokens.Status.error),
                    ("Info", ColorTokens.Status.info),
                    ("Success BG", ColorTokens.Status.successBackground),
                    ("Error BG", ColorTokens.Status.errorBackground)
                ]
            )
            
            ColorTokenPreview(
                title: "Interactive Colors",
                colors: [
                    ("Primary", ColorTokens.Interactive.primary),
                    ("Primary Hover", ColorTokens.Interactive.primaryHover),
                    ("Primary Pressed", ColorTokens.Interactive.primaryPressed),
                    ("Secondary", ColorTokens.Interactive.secondary),
                    ("Destructive", ColorTokens.Interactive.destructive),
                    ("Tertiary", ColorTokens.Interactive.tertiary)
                ]
            )
        }
        .padding()
    }
    .background(ColorTokens.UI.backgroundPrimary)
}