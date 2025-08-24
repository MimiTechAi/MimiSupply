import Foundation
import SwiftUI

// MARK: - Business Intelligence Localization Keys
extension LocalizationKeys {
    
    enum BusinessIntelligence: String, CaseIterable {
        // MARK: - Dashboard
        case dashboard = "bi.dashboard"
        case businessIntelligence = "bi.business_intelligence"
        case analytics = "bi.analytics"
        case overview = "bi.overview"
        case insights = "bi.insights"
        case reports = "bi.reports"
        case metrics = "bi.metrics"
        case performance = "bi.performance"
        case trends = "bi.trends"
        case forecast = "bi.forecast"
        case comparison = "bi.comparison"
        case benchmark = "bi.benchmark"
        case goalTracking = "bi.goal_tracking"
        case alerts = "bi.alerts"
        case notifications = "bi.notifications"
        
        // MARK: - Time Ranges
        case timeRange = "bi.time_range"
        case today = "bi.today"
        case yesterday = "bi.yesterday"
        case thisWeek = "bi.this_week"
        case lastWeek = "bi.last_week"
        case thisMonth = "bi.this_month"
        case lastMonth = "bi.last_month"
        case thisQuarter = "bi.this_quarter"
        case lastQuarter = "bi.last_quarter"
        case thisYear = "bi.this_year"
        case lastYear = "bi.last_year"
        case last7Days = "bi.last_7_days"
        case last30Days = "bi.last_30_days"
        case last90Days = "bi.last_90_days"
        case custom = "bi.custom"
        case dateRange = "bi.date_range"
        case startDate = "bi.start_date"
        case endDate = "bi.end_date"
        
        // MARK: - Revenue Metrics
        case revenue = "bi.revenue"
        case totalRevenue = "bi.total_revenue"
        case netRevenue = "bi.net_revenue"
        case grossRevenue = "bi.gross_revenue"
        case revenueGrowth = "bi.revenue_growth"
        case revenueTarget = "bi.revenue_target"
        case revenueVariance = "bi.revenue_variance"
        case averageOrderValue = "bi.average_order_value"
        case revenuePerCustomer = "bi.revenue_per_customer"
        case revenuePerOrder = "bi.revenue_per_order"
        case monthlyRecurringRevenue = "bi.monthly_recurring_revenue"
        case yearlyRecurringRevenue = "bi.yearly_recurring_revenue"
        case revenueByCategory = "bi.revenue_by_category"
        case revenueByPartner = "bi.revenue_by_partner"
        case revenueByRegion = "bi.revenue_by_region"
        case revenueByHour = "bi.revenue_by_hour"
        case revenueByDay = "bi.revenue_by_day"
        case revenueTrends = "bi.revenue_trends"
        case revenueProjection = "bi.revenue_projection"
        case revenueForecast = "bi.revenue_forecast"
        
        // MARK: - Order Metrics
        case orders = "bi.orders"
        case totalOrders = "bi.total_orders"
        case newOrders = "bi.new_orders"
        case completedOrders = "bi.completed_orders"
        case cancelledOrders = "bi.cancelled_orders"
        case pendingOrders = "bi.pending_orders"
        case orderGrowth = "bi.order_growth"
        case orderValue = "bi.order_value"
        case orderFrequency = "bi.order_frequency"
        case orderSize = "bi.order_size"
        case orderVolume = "bi.order_volume"
        case orderConversion = "bi.order_conversion"
        case orderFulfillment = "bi.order_fulfillment"
        case orderAccuracy = "bi.order_accuracy"
        case orderDeliveryTime = "bi.order_delivery_time"
        case orderSatisfaction = "bi.order_satisfaction"
        case repeatOrders = "bi.repeat_orders"
        case firstTimeOrders = "bi.first_time_orders"
        case ordersByHour = "bi.orders_by_hour"
        case ordersByDay = "bi.orders_by_day"
        case ordersByWeekday = "bi.orders_by_weekday"
        case peakOrderHours = "bi.peak_order_hours"
        case orderTrends = "bi.order_trends"
        case orderAnalytics = "bi.order_analytics"
        
        // MARK: - Customer Metrics
        case customers = "bi.customers"
        case totalCustomers = "bi.total_customers"
        case newCustomers = "bi.new_customers"
        case returningCustomers = "bi.returning_customers"
        case activeCustomers = "bi.active_customers"
        case customerGrowth = "bi.customer_growth"
        case customerRetention = "bi.customer_retention"
        case customerChurn = "bi.customer_churn"
        case customerLifetimeValue = "bi.customer_lifetime_value"
        case customerAcquisitionCost = "bi.customer_acquisition_cost"
        case customerSatisfaction = "bi.customer_satisfaction"
        case customerLoyalty = "bi.customer_loyalty"
        case customerSegmentation = "bi.customer_segmentation"
        case customerDemographics = "bi.customer_demographics"
        case customerBehavior = "bi.customer_behavior"
        case customerInsights = "bi.customer_insights"
        case customerFeedback = "bi.customer_feedback"
        case customerSupport = "bi.customer_support"
        case customerEngagement = "bi.customer_engagement"
        case customerJourney = "bi.customer_journey"
        case customerPreferences = "bi.customer_preferences"
        
        // MARK: - Partner Metrics
        case partners = "bi.partners"
        case totalPartners = "bi.total_partners"
        case activePartners = "bi.active_partners"
        case newPartners = "bi.new_partners"
        case partnerGrowth = "bi.partner_growth"
        case partnerPerformance = "bi.partner_performance"
        case partnerRevenue = "bi.partner_revenue"
        case partnerOrders = "bi.partner_orders"
        case partnerRating = "bi.partner_rating"
        case partnerReviews = "bi.partner_reviews"
        case partnerSatisfaction = "bi.partner_satisfaction"
        case partnerRetention = "bi.partner_retention"
        case partnerChurn = "bi.partner_churn"
        case partnerOnboarding = "bi.partner_onboarding"
        case partnerTraining = "bi.partner_training"
        case partnerSupport = "bi.partner_support"
        case partnerCommission = "bi.partner_commission"
        case partnerPayouts = "bi.partner_payouts"
        case topPartners = "bi.top_partners"
        case partnerRanking = "bi.partner_ranking"
        
        // MARK: - Product Metrics
        case products = "bi.products"
        case totalProducts = "bi.total_products"
        case activeProducts = "bi.active_products"
        case topProducts = "bi.top_products"
        case productSales = "bi.product_sales"
        case productRevenue = "bi.product_revenue"
        case productViews = "bi.product_views"
        case productConversion = "bi.product_conversion"
        case productInventory = "bi.product_inventory"
        case productAvailability = "bi.product_availability"
        case productRating = "bi.product_rating"
        case productReviews = "bi.product_reviews"
        case productCategories = "bi.product_categories"
        case productTrends = "bi.product_trends"
        case productRecommendations = "bi.product_recommendations"
        case productBundle = "bi.product_bundle"
        case productPricing = "bi.product_pricing"
        case productMargins = "bi.product_margins"
        case productProfitability = "bi.product_profitability"
        case productPopularity = "bi.product_popularity"
        
        // MARK: - Performance Metrics
        case appPerformance = "bi.app_performance"
        case systemHealth = "bi.system_health"
        case uptime = "bi.uptime"
        case downtime = "bi.downtime"
        case responseTime = "bi.response_time"
        case loadTime = "bi.load_time"
        case errorRate = "bi.error_rate"
        case crashRate = "bi.crash_rate"
        case memoryUsage = "bi.memory_usage"
        case cpuUsage = "bi.cpu_usage"
        case networkUsage = "bi.network_usage"
        case storageUsage = "bi.storage_usage"
        case apiCalls = "bi.api_calls"
        case apiLatency = "bi.api_latency"
        case apiErrors = "bi.api_errors"
        case userSessions = "bi.user_sessions"
        case sessionDuration = "bi.session_duration"
        case pageViews = "bi.page_views"
        case screenViews = "bi.screen_views"
        case userInteractions = "bi.user_interactions"
        case featureUsage = "bi.feature_usage"
        
        // MARK: - Financial Metrics
        case financials = "bi.financials"
        case profit = "bi.profit"
        case loss = "bi.loss"
        case profitMargin = "bi.profit_margin"
        case grossMargin = "bi.gross_margin"
        case netMargin = "bi.net_margin"
        case operatingMargin = "bi.operating_margin"
        case costs = "bi.costs"
        case expenses = "bi.expenses"
        case operatingCosts = "bi.operating_costs"
        case marketingCosts = "bi.marketing_costs"
        case acquisitionCosts = "bi.acquisition_costs"
        case retentionCosts = "bi.retention_costs"
        case roi = "bi.roi"
        case roas = "bi.roas"
        case cac = "bi.cac"
        case ltv = "bi.ltv"
        case cashFlow = "bi.cash_flow"
        case burnRate = "bi.burn_rate"
        case runway = "bi.runway"
        case funding = "bi.funding"
        case valuation = "bi.valuation"
        
        // MARK: - Actions & Reports
        case generateReport = "bi.generate_report"
        case exportReport = "bi.export_report"
        case scheduleReport = "bi.schedule_report"
        case shareReport = "bi.share_report"
        case printReport = "bi.print_report"
        case emailReport = "bi.email_report"
        case downloadReport = "bi.download_report"
        case saveDashboard = "bi.save_dashboard"
        case customizeDashboard = "bi.customize_dashboard"
        case resetDashboard = "bi.reset_dashboard"
        case duplicateDashboard = "bi.duplicate_dashboard"
        case createWidget = "bi.create_widget"
        case editWidget = "bi.edit_widget"
        case deleteWidget = "bi.delete_widget"
        case configureAlerts = "bi.configure_alerts"
        case setGoals = "bi.set_goals"
        case trackProgress = "bi.track_progress"
        case viewDetails = "bi.view_details"
        case drillDown = "bi.drill_down"
        case filterData = "bi.filter_data"
        case sortData = "bi.sort_data"
        case searchData = "bi.search_data"
        case refreshData = "bi.refresh_data"
        case syncData = "bi.sync_data"
        case importData = "bi.import_data"
        case exportData = "bi.export_data"
        case backupData = "bi.backup_data"
        
        // MARK: - Chart Types
        case lineChart = "bi.line_chart"
        case barChart = "bi.bar_chart"
        case pieChart = "bi.pie_chart"
        case donutChart = "bi.donut_chart"
        case areaChart = "bi.area_chart"
        case scatterChart = "bi.scatter_chart"
        case histogramChart = "bi.histogram_chart"
        case heatmapChart = "bi.heatmap_chart"
        case trendChart = "bi.trend_chart"
        case comparisonChart = "bi.comparison_chart"
        case gaugeChart = "bi.gauge_chart"
        case funnelChart = "bi.funnel_chart"
        case waterfallChart = "bi.waterfall_chart"
        case bulletChart = "bi.bullet_chart"
        case sparklineChart = "bi.sparkline_chart"
        
        // MARK: - Units & Formatting
        case currency = "bi.currency"
        case percentage = "bi.percentage"
        case count = "bi.count"
        case rate = "bi.rate"
        case ratio = "bi.ratio"
        case score = "bi.score"
        case index = "bi.index"
        case change = "bi.change"
        case growth = "bi.growth"
        case increase = "bi.increase"
        case decrease = "bi.decrease"
        case positive = "bi.positive"
        case negative = "bi.negative"
        case neutral = "bi.neutral"
        case high = "bi.high"
        case medium = "bi.medium"
        case low = "bi.low"
        case excellent = "bi.excellent"
        case good = "bi.good"
        case fair = "bi.fair"
        case poor = "bi.poor"
        case target = "bi.target"
        case actual = "bi.actual"
        case variance = "bi.variance"
        case deviation = "bi.deviation"
        case average = "bi.average"
        case median = "bi.median"
        case minimum = "bi.minimum"
        case maximum = "bi.maximum"
        case total = "bi.total"
        case sum = "bi.sum"
        
        // MARK: - Status Messages
        case loading = "bi.loading"
        case loadingData = "bi.loading_data"
        case processingData = "bi.processing_data"
        case generatingReport = "bi.generating_report"
        case calculatingMetrics = "bi.calculating_metrics"
        case updatingDashboard = "bi.updating_dashboard"
        case syncingData = "bi.syncing_data"
        case dataUpdated = "bi.data_updated"
        case reportGenerated = "bi.report_generated"
        case reportSent = "bi.report_sent"
        case reportSaved = "bi.report_saved"
        case dashboardUpdated = "bi.dashboard_updated"
        case alertConfigured = "bi.alert_configured"
        case goalSet = "bi.goal_set"
        case noData = "bi.no_data"
        case noDataAvailable = "bi.no_data_available"
        case dataNotFound = "bi.data_not_found"
        case insufficientData = "bi.insufficient_data"
        case dataError = "bi.data_error"
        case connectionError = "bi.connection_error"
        case processingError = "bi.processing_error"
        case reportError = "bi.report_error"
        case tryAgain = "bi.try_again"
        case refreshData = "bi.refresh_data"
        case contactSupport = "bi.contact_support"
        
        var localized: String {
            return self.rawValue.localized
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