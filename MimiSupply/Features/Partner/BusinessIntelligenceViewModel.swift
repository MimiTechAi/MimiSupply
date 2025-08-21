import Foundation
import SwiftUI

// MARK: - Business Intelligence View Model
@MainActor
final class BusinessIntelligenceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var keyMetrics: [KeyMetric] = []
    @Published var revenueData: [RevenueDataPoint] = []
    @Published var orderAnalytics: OrderAnalytics = OrderAnalytics()
    @Published var customerInsights: CustomerInsights = CustomerInsights()
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var topProducts: [TopProduct] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showScheduleReport = false
    @Published var showShareSheet = false
    
    // MARK: - Private Properties
    private let analyticsService: AnalyticsService
    private let cloudKitService: CloudKitService
    private var currentTimeRange: TimeRange = .week
    
    // MARK: - Initialization
    @MainActor init(analyticsService: AnalyticsService? = nil, 
         cloudKitService: CloudKitService = CloudKitServiceImpl.shared) {
        self.analyticsService = analyticsService ?? AnalyticsManager.shared.analytics ?? AnalyticsServiceImpl()
        self.cloudKitService = cloudKitService
    }
    
    // MARK: - Public Methods
    func loadInitialData() async {
        await loadData(for: .week)
    }
    
    func loadData(for timeRange: TimeRange) async {
        isLoading = true
        errorMessage = nil
        currentTimeRange = timeRange
        
        do {
            async let keyMetricsTask = loadKeyMetrics(for: timeRange)
            async let revenueDataTask = loadRevenueData(for: timeRange)
            async let orderAnalyticsTask = loadOrderAnalytics(for: timeRange)
            async let customerInsightsTask = loadCustomerInsights(for: timeRange)
            async let performanceMetricsTask = loadPerformanceMetrics()
            async let topProductsTask = loadTopProducts(for: timeRange)
            
            keyMetrics = try await keyMetricsTask
            revenueData = try await revenueDataTask
            orderAnalytics = try await orderAnalyticsTask
            customerInsights = try await customerInsightsTask
            performanceMetrics = try await performanceMetricsTask
            topProducts = try await topProductsTask
            
            // Track analytics event
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "business_intelligence_loaded", category: .engagement),
                parameters: [
                    "time_range": timeRange.rawValue,
                    "metrics_count": keyMetrics.count
                ]
            )
            
        } catch {
            errorMessage = error.localizedDescription
            await analyticsService.trackError(error, context: [
                "action": "load_business_intelligence",
                "time_range": timeRange.rawValue
            ])
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        await loadData(for: currentTimeRange)
    }
    
    func exportReport() async {
        let measurement = analyticsService.startPerformanceMeasurement("export_report")
        
        do {
            let report = generateReport()
            try await saveReport(report)
            
            await analyticsService.trackEvent(
                AnalyticsEvent(name: "report_exported", category: .engagement),
                parameters: [
                    "time_range": currentTimeRange.rawValue,
                    "report_size": report.count
                ]
            )
            
        } catch {
            errorMessage = "Failed to export report: \(error.localizedDescription)"
            await analyticsService.trackError(error, context: ["action": "export_report"])
        }
        
        let metric = measurement.end()
        await analyticsService.trackPerformanceMetric(metric)
    }
    
    // MARK: - Private Methods
    private func loadKeyMetrics(for timeRange: TimeRange) async throws -> [KeyMetric] {
        // Simulate loading key metrics
        // In a real app, this would fetch from your analytics backend
        
        let _ = getDateRange(for: timeRange)
        
        return [
            KeyMetric(
                title: "Total Revenue",
                value: "$12,450",
                percentageChange: 15.3,
                icon: "dollarsign.circle.fill"
            ),
            KeyMetric(
                title: "Total Orders",
                value: "248",
                percentageChange: 8.7,
                icon: "bag.fill"
            ),
            KeyMetric(
                title: "Active Customers",
                value: "156",
                percentageChange: 12.1,
                icon: "person.2.fill"
            ),
            KeyMetric(
                title: "Avg Rating",
                value: "4.8",
                percentageChange: 2.1,
                icon: "star.fill"
            )
        ]
    }
    
    private func loadRevenueData(for timeRange: TimeRange) async throws -> [RevenueDataPoint] {
        // Simulate loading revenue data
        let dateRange = getDateRange(for: timeRange)
        
        var data: [RevenueDataPoint] = []
        var currentDate = dateRange.start
        
        while currentDate <= dateRange.end {
            let revenue = Double.random(in: 800...2000)
            let orderCount = Int.random(in: 5...25)
            data.append(RevenueDataPoint(date: currentDate, amount: revenue, orderCount: orderCount))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return data
    }
    
    private func loadOrderAnalytics(for timeRange: TimeRange) async throws -> OrderAnalytics {
        // Simulate loading order analytics
        return OrderAnalytics()
    }
    
    private func loadCustomerInsights(for timeRange: TimeRange) async throws -> CustomerInsights {
        // Simulate loading customer insights
        return CustomerInsights()
    }
    
    private func loadPerformanceMetrics() async throws -> PerformanceMetrics {
        // Simulate loading performance metrics
        return PerformanceMetrics(
            appLaunchTime: 1.85,
            apiResponseTime: 320,
            crashRate: 0.045,
            memoryUsage: 145
        )
    }
    
    private func loadTopProducts(for timeRange: TimeRange) async throws -> [TopProduct] {
        // Simulate loading top products
        return [
            TopProduct(
                id: "1",
                name: "Margherita Pizza",
                revenue: 675.00,
                orderCount: 45,
                imageURL: URL(string: "https://example.com/pizza.jpg")
            ),
            TopProduct(
                id: "2",
                name: "Caesar Salad",
                revenue: 456.00,
                orderCount: 38,
                imageURL: URL(string: "https://example.com/salad.jpg")
            ),
            TopProduct(
                id: "3",
                name: "Chicken Burger",
                revenue: 512.00,
                orderCount: 32,
                imageURL: URL(string: "https://example.com/burger.jpg")
            ),
            TopProduct(
                id: "4",
                name: "Pasta Carbonara",
                revenue: 420.00,
                orderCount: 28,
                imageURL: URL(string: "https://example.com/pasta.jpg")
            ),
            TopProduct(
                id: "5",
                name: "Chocolate Cake",
                revenue: 200.00,
                orderCount: 25,
                imageURL: URL(string: "https://example.com/cake.jpg")
            )
        ]
    }
    
    private func getDateRange(for timeRange: TimeRange) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .day:
            let start = calendar.startOfDay(for: now)
            return (start, now)
            
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return (start, now)
            
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return (start, now)
            
        case .quarter:
            let start = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
            return (start, now)
            
        case .year:
            let start = calendar.dateInterval(of: .year, for: now)?.start ?? now
            return (start, now)
        }
    }
    
    private func generateReport() -> String {
        var report = "# Business Intelligence Report\n\n"
        report += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))\n"
        report += "Time Range: \(currentTimeRange.displayName)\n\n"
        
        report += "## Key Metrics\n"
        for metric in keyMetrics {
            let changeText = metric.percentageChange.map { " (\($0 >= 0 ? "+" : "")\(String(format: "%.1f", $0))%)" } ?? ""
            report += "- \(metric.title): \(metric.value)\(changeText)\n"
        }
        
        report += "\n## Order Analytics\n"
        report += "- Total Orders: \(orderAnalytics.totalOrders)\n"
        report += "- Average Order Value: \(orderAnalytics.formattedAverageOrderValue)\n"
        report += "- Completion Rate: \(orderAnalytics.formattedCompletionRate)\n"
        report += "- Peak Order Hour: \(orderAnalytics.peakOrderHour):00\n"
        
        report += "\n## Customer Insights\n"
        report += "- Total Customers: \(customerInsights.totalCustomers)\n"
        report += "- New Customers: \(customerInsights.newCustomers)\n"
        report += "- Returning Customers: \(customerInsights.returningCustomers)\n"
        report += "- Retention Rate: \(customerInsights.formattedRetentionRate)\n"
        
        report += "\n## Top Products\n"
        for (index, product) in topProducts.prefix(5).enumerated() {
            report += "\(index + 1). \(product.name) - \(product.orderCount) orders, $\(String(format: "%.2f", product.revenue)) revenue\n"
        }
        
        return report
    }
    
    private func saveReport(_ report: String) async throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let reportsPath = documentsPath.appendingPathComponent("reports")
        
        try FileManager.default.createDirectory(at: reportsPath, withIntermediateDirectories: true)
        
        let timestamp = DateFormatter.fileNameFormatter.string(from: Date())
        let fileName = "business_report_\(timestamp).md"
        let filePath = reportsPath.appendingPathComponent(fileName)
        
        try report.write(to: filePath, atomically: true, encoding: .utf8)
    }
}

// MARK: - Data Models
// KeyMetric, OrderAnalytics, CustomerInsights are defined in Data/Models/AnalyticsModels.swift

struct PerformanceMetrics {
    let appLaunchTime: Double
    let apiResponseTime: Double
    let crashRate: Double
    let memoryUsage: Double
    
    init(appLaunchTime: Double = 0, apiResponseTime: Double = 0,
         crashRate: Double = 0, memoryUsage: Double = 0) {
        self.appLaunchTime = appLaunchTime
        self.apiResponseTime = apiResponseTime
        self.crashRate = crashRate
        self.memoryUsage = memoryUsage
    }
}

// MARK: - Schedule Report View
struct ScheduleReportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var frequency: ReportFrequency = .weekly
    @State private var email = ""
    @State private var includeCharts = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Report Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(ReportFrequency.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Delivery") {
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                
                Section("Options") {
                    Toggle("Include Charts", isOn: $includeCharts)
                }
            }
            .navigationTitle("Schedule Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Schedule") {
                        // Handle scheduling
                        dismiss()
                    }
                    .disabled(email.isEmpty)
                }
            }
        }
    }
}

enum ReportFrequency: String, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Share Dashboard View
struct ShareDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.emerald)
                
                Text("Share Dashboard")
                    .font(.titleLarge)
                    .fontWeight(.semibold)
                
                Text("Share your business intelligence dashboard with team members or stakeholders.")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: Spacing.md) {
                    ShareOptionButton(
                        title: "Generate Link",
                        subtitle: "Create a shareable link",
                        icon: "link",
                        action: { /* Handle link generation */ }
                    )
                    
                    ShareOptionButton(
                        title: "Export PDF",
                        subtitle: "Download as PDF report",
                        icon: "doc.fill",
                        action: { /* Handle PDF export */ }
                    )
                    
                    ShareOptionButton(
                        title: "Send Email",
                        subtitle: "Email to team members",
                        icon: "envelope.fill",
                        action: { /* Handle email sharing */ }
                    )
                }
                
                Spacer()
            }
            .padding(Spacing.lg)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.emerald)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.graphite)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray500)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray400)
            }
            .padding(Spacing.md)
            .background(Color.gray50)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date Formatter Extension
private extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}