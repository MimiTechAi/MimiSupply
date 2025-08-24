import SwiftUI
import Foundation
import OSLog

// MARK: - Enhanced Localization Manager
@MainActor
final class EnhancedLocalizationManager: ObservableObject {
    @Published var currentLanguage: SupportedLanguage
    @Published var businessContext: BusinessLocalizationContext
    @Published var formatters: LocalizedFormatters
    @Published var isRightToLeft: Bool = false
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Localization")
    
    static let shared = EnhancedLocalizationManager()
    
    private init() {
        // Initialize with system language or saved preference
        let savedLanguageCode = UserDefaults.standard.string(forKey: "selected_language") ?? 
                               Locale.current.language.languageCode?.identifier ?? "en"
        
        let language = SupportedLanguage.allLanguages.first { $0.code == savedLanguageCode } ?? 
                      SupportedLanguage.english
        
        self.currentLanguage = language
        self.isRightToLeft = language.isRightToLeft
        
        // Initialize business context
        self.businessContext = BusinessLocalizationContext(
            userRole: UserDefaults.standard.string(forKey: "user_role") ?? "customer",
            businessType: UserDefaults.standard.string(forKey: "business_type") ?? "restaurant",
            region: UserDefaults.standard.string(forKey: "user_region") ?? "US",
            currency: UserDefaults.standard.string(forKey: "preferred_currency") ?? "USD"
        )
        
        // Initialize formatters
        self.formatters = LocalizedFormatters(language: language, context: businessContext)
        
        logger.info("🌍 Enhanced Localization Manager initialized - Language: \(language.code), RTL: \(isRightToLeft)")
    }
    
    // MARK: - Language Management
    func changeLanguage(to language: SupportedLanguage, shouldRestart: Bool = false) {
        logger.info("🌍 Changing language from \(currentLanguage.code) to \(language.code)")
        
        currentLanguage = language
        isRightToLeft = language.isRightToLeft
        formatters = LocalizedFormatters(language: language, context: businessContext)
        
        // Save preference
        UserDefaults.standard.set(language.code, forKey: "selected_language")
        UserDefaults.standard.synchronize()
        
        // Update bundle language
        Bundle.setLanguage(language.code)
        
        // Notify observers
        NotificationCenter.default.post(name: .languageDidChange, object: language)
        
        if shouldRestart {
            // In a real app, you might want to restart certain parts
            logger.info("🌍 Language change complete - restart requested")
        }
    }
    
    func updateBusinessContext(_ context: BusinessLocalizationContext) {
        businessContext = context
        formatters = LocalizedFormatters(language: currentLanguage, context: context)
        
        // Save context
        UserDefaults.standard.set(context.userRole, forKey: "user_role")
        UserDefaults.standard.set(context.businessType, forKey: "business_type")
        UserDefaults.standard.set(context.region, forKey: "user_region")
        UserDefaults.standard.set(context.currency, forKey: "preferred_currency")
        
        logger.info("🌍 Business context updated - Role: \(context.userRole), Type: \(context.businessType)")
    }
    
    // MARK: - Contextual Localization
    func localizedString(for key: LocalizationKeys.BusinessIntelligence, fallback: String? = nil) -> String {
        // Try context-specific translation first
        let contextKey = "\(key.rawValue)_\(businessContext.userRole)"
        let contextTranslation = NSLocalizedString(contextKey, value: "", comment: "")
        
        if !contextTranslation.isEmpty {
            return contextTranslation
        }
        
        // Try business-type-specific translation
        let businessKey = "\(key.rawValue)_\(businessContext.businessType)"
        let businessTranslation = NSLocalizedString(businessKey, value: "", comment: "")
        
        if !businessTranslation.isEmpty {
            return businessTranslation
        }
        
        // Fall back to default translation
        let defaultTranslation = key.localized
        return defaultTranslation.isEmpty ? (fallback ?? key.rawValue) : defaultTranslation
    }
    
    // MARK: - Pluralization with Context
    func pluralizedString(for key: LocalizationKeys.BusinessIntelligence, count: Int) -> String {
        let pluralKey = "\(key.rawValue)_plural"
        let format = NSLocalizedString(pluralKey, value: key.localized, comment: "")
        return String.localizedStringWithFormat(format, count)
    }
    
    // MARK: - Gender-Sensitive Translations
    func genderSensitiveString(for key: String, gender: GrammaticalGender) -> String {
        let languageCode = currentLanguage.code
        
        // Languages that require gender-sensitive translations
        guard ["de", "fr", "es", "it", "pt", "pl", "ru", "ar", "he"].contains(languageCode) else {
            return key.localized
        }
        
        let genderSuffix: String
        switch gender {
        case .masculine: genderSuffix = "_m"
        case .feminine: genderSuffix = "_f"
        case .neuter: genderSuffix = "_n"
        }
        
        let genderKey = "\(key)\(genderSuffix)"
        let genderTranslation = NSLocalizedString(genderKey, value: "", comment: "")
        
        return genderTranslation.isEmpty ? key.localized : genderTranslation
    }
}

// MARK: - Business Localization Context
struct BusinessLocalizationContext {
    let userRole: String
    let businessType: String
    let region: String
    let currency: String
    
    var timeZone: TimeZone {
        switch region {
        case "US": return TimeZone(identifier: "America/New_York") ?? TimeZone.current
        case "EU": return TimeZone(identifier: "Europe/Berlin") ?? TimeZone.current
        case "ASIA": return TimeZone(identifier: "Asia/Tokyo") ?? TimeZone.current
        default: return TimeZone.current
        }
    }
    
    var locale: Locale {
        let languageCode = EnhancedLocalizationManager.shared.currentLanguage.code
        let regionCode = region == "US" ? "US" : region == "EU" ? "DE" : "JP"
        return Locale(identifier: "\(languageCode)_\(regionCode)")
    }
}

// MARK: - Localized Formatters
struct LocalizedFormatters {
    let language: SupportedLanguage
    let context: BusinessLocalizationContext
    
    // MARK: - Currency Formatter
    lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = context.locale
        formatter.currencyCode = context.currency
        return formatter
    }()
    
    // MARK: - Percentage Formatter
    lazy var percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = context.locale
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    // MARK: - Number Formatter
    lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = context.locale
        return formatter
    }()
    
    // MARK: - Date Formatter
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = context.locale
        formatter.timeZone = context.timeZone
        return formatter
    }()
    
    // MARK: - Time Formatter
    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = context.locale
        formatter.timeZone = context.timeZone
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Relative Date Formatter
    lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = context.locale
        return formatter
    }()
    
    // MARK: - Format Methods
    func formatCurrency(_ amount: Double) -> String {
        return BusinessIntelligenceFormatters.formatCurrency(amount, currencyCode: context.currency, locale: context.locale)
    }
    
    func formatPercentage(_ value: Double) -> String {
        return percentageFormatter.string(from: NSNumber(value: value / 100.0)) ?? "0%"
    }
    
    func formatNumber(_ number: Double) -> String {
        return BusinessIntelligenceFormatters.formatNumber(number, locale: context.locale)
    }
    
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        dateFormatter.dateStyle = style
        return dateFormatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        return timeFormatter.string(from: date)
    }
    
    func formatRelativeDate(_ date: Date) -> String {
        return relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    func formatChange(_ value: Double, showSign: Bool = true) -> String {
        let percentage = formatPercentage(value)
        
        if showSign {
            let sign = value >= 0 ? "+" : ""
            return "\(sign)\(percentage)"
        } else {
            return percentage
        }
    }
}

// MARK: - RTL-Aware Business Intelligence Components
struct RTLAwareBusinessCard<Content: View>: View {
    let content: Content
    @StateObject private var localizationManager = EnhancedLocalizationManager.shared
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.layoutDirection, localizationManager.isRightToLeft ? .rightToLeft : .leftToRight)
            .rtlAware()
    }
}

struct LocalizedMetricCard: View {
    let title: LocalizationKeys.BusinessIntelligence
    let value: String
    let change: Double?
    let icon: String
    let color: Color
    
    @StateObject private var localizationManager = EnhancedLocalizationManager.shared
    
    var body: some View {
        RTLAwareBusinessCard {
            VStack(alignment: localizationManager.isRightToLeft ? .trailing : .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    if let change = change {
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text(localizationManager.formatters.formatChange(change))
                                .font(.caption)
                        }
                        .foregroundColor(change >= 0 ? ColorTokens.Status.success : ColorTokens.Status.error)
                    }
                }
                
                Text(value)
                    .font(.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTokens.Content.textPrimary)
                    .rtlTextAlignment()
                
                Text(localizationManager.localizedString(for: title))
                    .font(.bodySmall)
                    .foregroundColor(ColorTokens.Content.textSecondary)
                    .lineLimit(1)
                    .rtlTextAlignment()
            }
            .padding(Spacing.md)
            .background(ColorTokens.UI.surfacePrimary)
            .cornerRadius(12)
            .shadow(color: ColorTokens.UI.separator.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Language Selection Enhanced
struct EnhancedLanguageSelectionView: View {
    @StateObject private var localizationManager = EnhancedLocalizationManager.shared
    @State private var searchText = ""
    @State private var showingLanguageGroups = false
    
    private var filteredLanguages: [SupportedLanguage] {
        if searchText.isEmpty {
            return SupportedLanguage.allLanguages
        } else {
            return SupportedLanguage.allLanguages.filter { language in
                language.nativeName.localizedCaseInsensitiveContains(searchText) ||
                language.englishName.localizedCaseInsensitiveContains(searchText) ||
                language.code.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var languageGroups: [String: [SupportedLanguage]] {
        Dictionary(grouping: filteredLanguages) { language in
            String(language.nativeName.prefix(1)).uppercased()
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: LocalizationKeys.Explore.searchPlaceholder.localized)
                    .padding()
                
                // Language list
                List {
                    if showingLanguageGroups && searchText.isEmpty {
                        ForEach(languageGroups.keys.sorted(), id: \.self) { letter in
                            Section(letter) {
                                ForEach(languageGroups[letter]?.sorted(by: { $0.nativeName < $1.nativeName }) ?? [], id: \.code) { language in
                                    LanguageRow(
                                        language: language,
                                        isSelected: language.code == localizationManager.currentLanguage.code
                                    ) {
                                        localizationManager.changeLanguage(to: language)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(filteredLanguages, id: \.code) { language in
                            LanguageRow(
                                language: language,
                                isSelected: language.code == localizationManager.currentLanguage.code
                            ) {
                                localizationManager.changeLanguage(to: language)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(showingLanguageGroups ? "List" : "Groups") {
                        showingLanguageGroups.toggle()
                    }
                    .font(.caption)
                }
            }
        }
        .rtlAware()
    }
}

struct LanguageRow: View {
    let language: SupportedLanguage
    let isSelected: Bool
    let action: () -> Void
    
    @StateObject private var localizationManager = EnhancedLocalizationManager.shared
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                VStack(alignment: localizationManager.isRightToLeft ? .trailing : .leading, spacing: 4) {
                    Text(language.nativeName)
                        .font(.bodyMedium)
                        .foregroundColor(ColorTokens.Content.textPrimary)
                        .rtlTextAlignment()
                    
                    Text(language.englishName)
                        .font(.caption)
                        .foregroundColor(ColorTokens.Content.textSecondary)
                        .rtlTextAlignment()
                }
                
                Spacer()
                
                if language.isRightToLeft {
                    Image(systemName: "text.alignright")
                        .font(.caption)
                        .foregroundColor(ColorTokens.Content.iconSecondary)
                }
                
                Text(language.code.uppercased())
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTokens.Content.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ColorTokens.UI.surfaceSecondary)
                    .cornerRadius(4)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ColorTokens.Status.success)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Multi-Language Business Intelligence Dashboard
struct LocalizedBusinessIntelligenceDashboard: View {
    @StateObject private var viewModel = BusinessIntelligenceViewModel()
    @StateObject private var localizationManager = EnhancedLocalizationManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Time Range Selector (localized)
                    Picker(localizationManager.localizedString(for: .timeRange), selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(localizedTimeRangeDisplayName(for: range)).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedTimeRange) { _, newValue in
                        Task {
                            await viewModel.loadData(for: newValue)
                        }
                    }
                    
                    // Localized Key Metrics
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        LocalizedMetricCard(
                            title: .revenue,
                            value: localizationManager.formatters.formatCurrency(24680),
                            change: 15.3,
                            icon: "dollarsign.circle.fill",
                            color: ColorTokens.Special.revenue
                        )
                        
                        LocalizedMetricCard(
                            title: .orders,
                            value: localizationManager.formatters.formatNumber(1248),
                            change: 8.7,
                            icon: "bag.fill",
                            color: ColorTokens.Special.orders
                        )
                        
                        LocalizedMetricCard(
                            title: .customers,
                            value: localizationManager.formatters.formatNumber(856),
                            change: 12.1,
                            icon: "person.2.fill",
                            color: ColorTokens.Special.customers
                        )
                        
                        LocalizedMetricCard(
                            title: .performance,
                            value: localizationManager.formatters.formatPercentage(94.2),
                            change: -2.1,
                            icon: "chart.line.uptrend.xyaxis",
                            color: ColorTokens.Special.performance
                        )
                    }
                    
                    // More localized components...
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle(localizationManager.localizedString(for: .businessIntelligence))
            .rtlAware()
            .task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    private func localizedTimeRangeDisplayName(for range: TimeRange) -> String {
        switch range {
        case .day: return localizationManager.localizedString(for: .today)
        case .week: return localizationManager.localizedString(for: .thisWeek)
        case .month: return localizationManager.localizedString(for: .thisMonth)
        case .quarter: return localizationManager.localizedString(for: .thisQuarter)
        case .year: return localizationManager.localizedString(for: .thisYear)
        }
    }
}

// MARK: - Preview
#Preview("Enhanced Localization") {
    LocalizedBusinessIntelligenceDashboard()
        .environmentObject(EnhancedLocalizationManager.shared)
}

#Preview("Language Selection") {
    EnhancedLanguageSelectionView()
}