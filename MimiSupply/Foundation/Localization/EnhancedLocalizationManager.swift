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
        let initialContext = BusinessLocalizationContext(
            userRole: UserDefaults.standard.string(forKey: "user_role") ?? "customer",
            businessType: UserDefaults.standard.string(forKey: "business_type") ?? "restaurant",
            region: UserDefaults.standard.string(forKey: "user_region") ?? "US",
            currency: UserDefaults.standard.string(forKey: "preferred_currency") ?? "USD"
        )
        self.businessContext = initialContext
        
        // Initialize formatters
        self.formatters = LocalizedFormatters(language: language, context: initialContext)
        
        logger.info("🌍 Enhanced Localization Manager initialized - Language: \(language.code), RTL: \(self.isRightToLeft)")
    }
    
    // MARK: - Language Management
    func changeLanguage(to language: SupportedLanguage, shouldRestart: Bool = false) {
        logger.info("🌍 Changing language from \(self.currentLanguage.code) to \(language.code)")
        
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
        Task { @MainActor in
            let languageCode = EnhancedLocalizationManager.shared.currentLanguage.code
            let regionCode = region == "US" ? "US" : region == "EU" ? "DE" : "JP"
            return Locale(identifier: "\(languageCode)_\(regionCode)")
        }
        // Fallback synchronous implementation
        let regionCode = region == "US" ? "US" : region == "EU" ? "DE" : "JP"
        return Locale(identifier: "en_\(regionCode)")
    }
}

// MARK: - Localized Formatters
struct LocalizedFormatters {
    let language: SupportedLanguage
    let context: BusinessLocalizationContext
    
    // MARK: - Currency Formatter Method
    func formatCurrency(_ amount: Double) -> String {
        return BusinessIntelligenceFormatters.formatCurrency(amount, currencyCode: context.currency, locale: context.locale)
    }
    
    // MARK: - Percentage Formatter Method
    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = context.locale
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value / 100.0)) ?? "0%"
    }
    
    // MARK: - Number Formatter Method
    func formatNumber(_ number: Double) -> String {
        return BusinessIntelligenceFormatters.formatNumber(number, locale: context.locale)
    }
    
    // MARK: - Date Formatter Method
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.locale = context.locale
        formatter.timeZone = context.timeZone
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    // MARK: - Time Formatter Method
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = context.locale
        formatter.timeZone = context.timeZone
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Relative Date Formatter Method
    func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = context.locale
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Format Change Method
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
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.layoutDirection, LocalizationManager.shared.isRightToLeft ? .rightToLeft : .leftToRight)
            .rtlAware()
    }
}

struct LocalizedMetricCard: View {
    let title: LocalizationKeys.BusinessIntelligence
    let value: String
    let change: Double?
    let icon: String
    let color: Color
    
    var body: some View {
        RTLAwareBusinessCard {
            VStack(alignment: LocalizationManager.shared.isRightToLeft ? .trailing : .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Spacer()
                    
                    if let change = change {
                        HStack(spacing: 2) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.caption)
                            Text(EnhancedLocalizationManager.shared.formatters.formatChange(change))
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
                
                Text(EnhancedLocalizationManager.shared.localizedString(for: title))
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
                                        isSelected: language.code == LocalizationManager.shared.currentLanguage.code
                                    ) {
                                        LocalizationManager.shared.changeLanguage(to: language)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(filteredLanguages, id: \.code) { language in
                            LanguageRow(
                                language: language,
                                isSelected: language.code == LocalizationManager.shared.currentLanguage.code
                            ) {
                                LocalizationManager.shared.changeLanguage(to: language)
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

struct LocalizationLanguageRow: View {
    let language: SupportedLanguage
    @Binding var selectedLanguage: SupportedLanguage
    let onSelect: (SupportedLanguage) -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Flag
            Text(language.flag)
                .font(.title2)
            
            // Language info
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(language.nativeName)
                    .font(.body.scaledFont())
                    .foregroundColor(.primary)
                
                Text(language.code)
                    .font(.caption.scaledFont())
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Selection indicator
            if selectedLanguage == language {
                Image(systemName: "checkmark")
                    .foregroundColor(.emerald)
                    .font(.headline)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect(language)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selectedLanguage == language ? .isSelected : [])
        .accessibilityAction {
            onSelect(language)
        }
    }
}

// MARK: - Gender enum defined in BusinessIntelligenceLocalizations.swift
// Note: GrammaticalGender enum is defined in BusinessIntelligenceLocalizations.swift

/*
// MARK: - Multi-Language Business Intelligence Dashboard
// Note: This view is temporarily commented out due to missing dependencies
// TODO: Implement missing types: TimeRange, BusinessIntelligenceViewModel, LocalizedMetricCard, ColorTokens
struct LocalizedBusinessIntelligenceDashboard: View {
    @StateObject private var viewModel = BusinessIntelligenceViewModel()
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Time Range Selector (localized)
                    Picker(EnhancedLocalizationManager.shared.localizedString(for: .filter), selection: $selectedTimeRange) {
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
                            value: EnhancedLocalizationManager.shared.formatters.formatCurrency(24680),
                            change: 15.3,
                            icon: "dollarsign.circle.fill",
                            color: ColorTokens.Special.revenue
                        )
                        
                        LocalizedMetricCard(
                            title: .orders,
                            value: EnhancedLocalizationManager.shared.formatters.formatNumber(1248),
                            change: 8.7,
                            icon: "bag.fill",
                            color: ColorTokens.Special.orders
                        )
                        
                        LocalizedMetricCard(
                            title: .customers,
                            value: EnhancedLocalizationManager.shared.formatters.formatNumber(856),
                            change: 12.1,
                            icon: "person.2.fill",
                            color: ColorTokens.Special.customers
                        )
                        
                        LocalizedMetricCard(
                            title: .performance,
                            value: EnhancedLocalizationManager.shared.formatters.formatPercentage(94.2),
                            change: -2.1,
                            icon: "chart.line.uptrend.xyaxis",
                            color: ColorTokens.Special.performance
                        )
                    }
                    
                    // More localized components...
                }
                .padding(.horizontal, Spacing.md)
            }
            .navigationTitle(EnhancedLocalizationManager.shared.localizedString(for: .analytics))
            .rtlAware()
            .task {
                await viewModel.loadInitialData()
            }
        }
    }
    
    private func localizedTimeRangeDisplayName(for range: TimeRange) -> String {
        switch range {
        case .day: return EnhancedLocalizationManager.shared.localizedString(for: .today)
        case .week: return EnhancedLocalizationManager.shared.localizedString(for: .thisWeek)
        case .month: return EnhancedLocalizationManager.shared.localizedString(for: .thisMonth)
        case .quarter: return EnhancedLocalizationManager.shared.localizedString(for: .lastMonth) // Using lastMonth as fallback
        case .year: return EnhancedLocalizationManager.shared.localizedString(for: .lastMonth) // Using lastMonth as fallback
        }
    }
}
*/

// MARK: - SupportedLanguage Flag Extension
extension SupportedLanguage {
    var flag: String {
        // Construct Unicode flag from ISO 3166-1 alpha-2 country code, fallback to empty string
        // Use first two letters of language code uppercased if possible
        let countryCode = code.count >= 2 ? String(code.prefix(2)).uppercased() : "US"
        let base: UInt32 = 127397
        var flagString = ""
        for scalar in countryCode.unicodeScalars {
            guard let scalarValue = UnicodeScalar(base + scalar.value) else {
                continue
            }
            flagString.unicodeScalars.append(scalarValue)
        }
        return flagString
    }
}

// MARK: - BusinessIntelligence enum extensions
// Note: The main BusinessIntelligence enum is defined in BusinessIntelligenceLocalizations.swift
// This file uses that enum rather than defining a duplicate
