import Foundation
import SwiftUI

// MARK: - Business Intelligence Localization Keys
extension LocalizationKeys {
    
    enum BusinessIntelligence: String, CaseIterable {
        // Dashboard
        case dashboard = "bi.dashboard"
        case overview = "bi.overview"
        case keyMetrics = "bi.key_metrics"
        case todayEarnings = "bi.today_earnings"
        case totalOrders = "bi.total_orders"
        case averageOrderValue = "bi.average_order_value"
        case customerSatisfaction = "bi.customer_satisfaction"
        
        // Time Periods
        case today = "bi.today"
        case yesterday = "bi.yesterday"
        case thisWeek = "bi.this_week"
        case lastWeek = "bi.last_week"
        case thisMonth = "bi.this_month"
        case lastMonth = "bi.last_month"
        
        // Revenue
        case revenue = "bi.revenue"
        case revenueGrowth = "bi.revenue_growth"
        case revenueChart = "bi.revenue_chart"
        case revenueByHour = "bi.revenue_by_hour"
        case revenueByDay = "bi.revenue_by_day"
        case revenueByWeek = "bi.revenue_by_week"
        case revenueByMonth = "bi.revenue_by_month"
        
        // Orders
        case orders = "bi.orders"
        case ordersGrowth = "bi.orders_growth"
        case ordersChart = "bi.orders_chart"
        case ordersByStatus = "bi.orders_by_status"
        case ordersByHour = "bi.orders_by_hour"
        case ordersByDay = "bi.orders_by_day"
        case ordersByWeek = "bi.orders_by_week"
        case ordersByMonth = "bi.orders_by_month"
        
        // Products
        case products = "bi.products"
        case topProducts = "bi.top_products"
        case productPerformance = "bi.product_performance"
        case productsSold = "bi.products_sold"
        case productRevenue = "bi.product_revenue"
        
        // Customers
        case customers = "bi.customers"
        case newCustomers = "bi.new_customers"
        case returningCustomers = "bi.returning_customers"
        case customerGrowth = "bi.customer_growth"
        case customerRetention = "bi.customer_retention"
        
        // Performance
        case performance = "bi.performance"
        case averageDeliveryTime = "bi.average_delivery_time"
        case onTimeDelivery = "bi.on_time_delivery"
        case deliveryPerformance = "bi.delivery_performance"
        case peakHours = "bi.peak_hours"
        case busyDays = "bi.busy_days"
        
        // Analytics
        case analytics = "bi.analytics"
        case insights = "bi.insights"
        case trends = "bi.trends"
        case predictions = "bi.predictions"
        case recommendations = "bi.recommendations"
        
        // Export & Reports
        case export = "bi.export"
        case exportPDF = "bi.export_pdf"
        case exportCSV = "bi.export_csv"
        case reports = "bi.reports"
        case generateReport = "bi.generate_report"
        case reportGenerated = "bi.report_generated"
        
        // Actions
        case viewDetails = "bi.view_details"
        case viewAll = "bi.view_all"
        case showMore = "bi.show_more"
        case showLess = "bi.show_less"
        case filter = "bi.filter"
        case sort = "bi.sort"
        case search = "bi.search"
        case refresh = "bi.refresh"
        case reload = "bi.reload"
        
        // Status
        case loading = "bi.loading"
        case noData = "bi.no_data"
        case error = "bi.error"
        case success = "bi.success"
        case failed = "bi.failed"
        case retry = "bi.retry"
        
        // Comparison
        case compared = "bi.compared"
        case comparedTo = "bi.compared_to"
        case change = "bi.change"
        case growth = "bi.growth"
        case decline = "bi.decline"
        case increase = "bi.increase"
        case decrease = "bi.decrease"
        case stable = "bi.stable"
        
        // Time
        case lastUpdated = "bi.last_updated"
        case refreshedAt = "bi.refreshed_at"
        case dataFrom = "bi.data_from"
        case asOf = "bi.as_of"
        
        // Formatting
        case currency = "bi.currency"
        case percentage = "bi.percentage"
        case count = "bi.count"
        case average = "bi.average"
        case total = "bi.total"
        case minimum = "bi.minimum"
        case maximum = "bi.maximum"
        
        // Settings
        case settings = "bi.settings"
        case preferences = "bi.preferences"
        case notifications = "bi.notifications"
        case alerts = "bi.alerts"
        case thresholds = "bi.thresholds"
        
        // Navigation
        case back = "bi.back"
        case next = "bi.next"
        case previous = "bi.previous"
        case close = "bi.close"
        case done = "bi.done"
        case save = "bi.save"
        case cancel = "bi.cancel"
        
        var localized: String {
            // Use a simple NSLocalizedString fallback to avoid actor isolation issues
            return NSLocalizedString(self.rawValue, value: self.rawValue, comment: "Business Intelligence localization key")
        }
    }
}

// MARK: - Context-Aware Formatting
struct BusinessIntelligenceFormatters {
    
    // MARK: - Currency Formatting
    static func formatCurrency(_ amount: Double, currencyCode: String = "USD", locale: Locale = Locale.current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode
        
        // Handle large numbers with abbreviations
        let absAmount = abs(amount)
        let sign = amount < 0 ? "-" : ""
        
        if absAmount >= 1_000_000_000 {
            formatter.maximumFractionDigits = 1
            let billions = amount / 1_000_000_000
            return "\(sign)\(formatter.string(from: NSNumber(value: billions)) ?? "0")B"
        } else if absAmount >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            let millions = amount / 1_000_000
            return "\(sign)\(formatter.string(from: NSNumber(value: millions)) ?? "0")M"
        } else if absAmount >= 1_000 {
            formatter.maximumFractionDigits = 0
            let thousands = amount / 1_000
            return "\(sign)\(formatter.string(from: NSNumber(value: thousands)) ?? "0")K"
        } else {
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: amount)) ?? "0"
        }
    }
    
    // MARK: - Percentage Formatting
    static func formatPercentage(_ value: Double, locale: Locale = Locale.current, decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = decimalPlaces
        
        return formatter.string(from: NSNumber(value: value / 100.0)) ?? "0%"
    }
    
    // MARK: - Number Formatting
    static func formatNumber(_ number: Double, locale: Locale = Locale.current, style: NumberFormatter.Style = .decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = style
        formatter.locale = locale
        
        // Handle large numbers with abbreviations
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""
        
        if absNumber >= 1_000_000_000 {
            formatter.maximumFractionDigits = 1
            let billions = number / 1_000_000_000
            return "\(sign)\(formatter.string(from: NSNumber(value: billions)) ?? "0")B"
        } else if absNumber >= 1_000_000 {
            formatter.maximumFractionDigits = 1
            let millions = number / 1_000_000
            return "\(sign)\(formatter.string(from: NSNumber(value: millions)) ?? "0")M"
        } else if absNumber >= 1_000 {
            formatter.maximumFractionDigits = 0
            let thousands = number / 1_000
            return "\(sign)\(formatter.string(from: NSNumber(value: thousands)) ?? "0")K"
        } else {
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: number)) ?? "0"
        }
    }
    
    // MARK: - Change Formatting
    static func formatChange(_ value: Double, locale: Locale = Locale.current, showSign: Bool = true) -> String {
        let percentage = formatPercentage(value, locale: locale)
        
        if showSign {
            let sign = value >= 0 ? "+" : ""
            return "\(sign)\(percentage)"
        } else {
            return percentage
        }
    }
    
    // MARK: - Duration Formatting
    static func formatDuration(_ seconds: TimeInterval, locale: Locale = Locale.current) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.maximumUnitCount = 2
        
        return formatter.string(from: seconds) ?? "0s"
    }
    
    // MARK: - Metric Formatting with Units
    static func formatMetric(_ value: Double, unit: String, locale: Locale = Locale.current) -> String {
        let formattedValue = formatNumber(value, locale: locale)
        return "\(formattedValue) \(unit)"
    }
}

// MARK: - Pluralization Support
extension LocalizationKeys.BusinessIntelligence {
    
    func pluralized(count: Int) -> String {
        let key = "\(self.rawValue)_plural"
        
        // Use iOS built-in pluralization rules
        let format = NSLocalizedString(key, value: self.localized, comment: "")
        return String.localizedStringWithFormat(format, count)
    }
    
    func localizedWithCount(_ count: Int) -> String {
        if count == 1 {
            return self.localized
        } else {
            return pluralized(count: count)
        }
    }
}

// MARK: - Gender-Sensitive Translations
enum GrammaticalGender {
    case masculine
    case feminine
    case neuter
}

extension String {
    
    func genderSensitive(gender: GrammaticalGender, locale: Locale = Locale.current) -> String {
        let languageCode = locale.language.languageCode?.identifier ?? "en"
        
        // Languages that require gender-sensitive translations
        guard ["de", "fr", "es", "it", "pt", "pl", "ru"].contains(languageCode) else {
            return self
        }
        
        let genderSuffix: String
        switch gender {
        case .masculine: genderSuffix = "_m"
        case .feminine: genderSuffix = "_f"
        case .neuter: genderSuffix = "_n"
        }
        
        let genderKey = "\(self)\(genderSuffix)"
        let genderTranslation = NSLocalizedString(genderKey, value: "", comment: "")
        
        // Fall back to original if gender-specific translation doesn't exist
        return genderTranslation.isEmpty ? self.localized : genderTranslation
    }
}

// MARK: - Context-Aware Translations
struct BusinessIntelligenceContext {
    let userRole: String
    let businessType: String
    let region: String
    let timeZone: TimeZone
    let currency: String
    
    func localizedString(for key: LocalizationKeys.BusinessIntelligence) -> String {
        // Try role-specific translation first
        let roleKey = "\(key.rawValue)_\(userRole)"
        let roleTranslation = NSLocalizedString(roleKey, value: "", comment: "")
        
        if !roleTranslation.isEmpty {
            return roleTranslation
        }
        
        // Try business-type-specific translation
        let businessKey = "\(key.rawValue)_\(businessType)"
        let businessTranslation = NSLocalizedString(businessKey, value: "", comment: "")
        
        if !businessTranslation.isEmpty {
            return businessTranslation
        }
        
        // Fall back to default translation
        return key.localized
    }
}

// MARK: - Business Intelligence Localized Strings Helper
@MainActor
final class BILocalizationHelper: ObservableObject {
    @Published var context: BusinessIntelligenceContext
    
    init(context: BusinessIntelligenceContext) {
        self.context = context
    }
    
    func localizedString(for key: LocalizationKeys.BusinessIntelligence) -> String {
        return context.localizedString(for: key)
    }
    
    func formatCurrency(_ amount: Double) -> String {
        return BusinessIntelligenceFormatters.formatCurrency(
            amount,
            currencyCode: context.currency,
            locale: Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        )
    }
    
    func formatPercentage(_ value: Double) -> String {
        return BusinessIntelligenceFormatters.formatPercentage(
            value,
            locale: Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        )
    }
    
    func formatNumber(_ number: Double) -> String {
        return BusinessIntelligenceFormatters.formatNumber(
            number,
            locale: Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        )
    }
    
    func formatChange(_ value: Double) -> String {
        return BusinessIntelligenceFormatters.formatChange(
            value,
            locale: Locale(identifier: LocalizationManager.shared.currentLanguage.localeIdentifier)
        )
    }
}