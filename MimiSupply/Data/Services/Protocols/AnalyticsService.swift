import Foundation
import os.signpost

// MARK: - Sendable Analytics Parameter Type
public typealias AnalyticsParameters = [String: AnalyticsParameterValue]

public enum AnalyticsParameterValue: Sendable, Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    
    // Computed property to extract the underlying value
    public var value: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .date(let value): return value
        }
    }
}

// MARK: - Analytics Service Protocol
protocol AnalyticsService: Sendable {
    /// Track a user event with optional parameters
    func trackEvent(_ event: AnalyticsEvent, parameters: AnalyticsParameters?) async
    
    /// Track screen view
    func trackScreenView(_ screenName: String, parameters: AnalyticsParameters?) async
    
    /// Track user property (non-PII only)
    func setUserProperty(_ property: String, value: String?) async
    
    /// Track performance metric
    func trackPerformanceMetric(_ metric: PerformanceMetric) async
    
    /// Track error or crash
    func trackError(_ error: Error, context: AnalyticsParameters?) async
    
    /// Start performance measurement
    nonisolated func startPerformanceMeasurement(_ name: String) -> PerformanceMeasurement
    
    /// Track feature flag usage
    func trackFeatureFlag(_ flag: String, variant: String) async
    
    /// Track user engagement
    func trackEngagement(_ engagement: UserEngagement) async
    
    /// Flush pending events
    func flush() async
}

// MARK: - Convenience Extensions
extension AnalyticsParameters {
    // Helper initializers for common parameter types
    init(stringParams: [String: String]) {
        self = stringParams.mapValues { .string($0) }
    }
    
    init(intParams: [String: Int]) {
        self = intParams.mapValues { .int($0) }
    }
    
    init(doubleParams: [String: Double]) {
        self = doubleParams.mapValues { .double($0) }
    }
    
    init(boolParams: [String: Bool]) {
        self = boolParams.mapValues { .bool($0) }
    }
    
    // Convert to [String: Any] for legacy APIs
    var legacyFormat: [String: Any] {
        return self.mapValues { $0.value }
    }
}

// Convenience subscript for easy access
extension AnalyticsParameters {
    subscript(key: String, string value: String) -> String? {
        get {
            if case .string(let stringValue) = self[key] {
                return stringValue
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self[key] = .string(newValue)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
    
    subscript(key: String, int value: Int) -> Int? {
        get {
            if case .int(let intValue) = self[key] {
                return intValue
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self[key] = .int(newValue)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
    
    subscript(key: String, double value: Double) -> Double? {
        get {
            if case .double(let doubleValue) = self[key] {
                return doubleValue
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self[key] = .double(newValue)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
    
    subscript(key: String, bool value: Bool) -> Bool? {
        get {
            if case .bool(let boolValue) = self[key] {
                return boolValue
            }
            return nil
        }
        set {
            if let newValue = newValue {
                self[key] = .bool(newValue)
            } else {
                self.removeValue(forKey: key)
            }
        }
    }
}

// MARK: - Analytics Event
struct AnalyticsEvent: Sendable, Codable {
    let name: String
    let category: EventCategory
    let timestamp: Date
    
    init(name: String, category: EventCategory) {
        self.name = name
        self.category = category
        self.timestamp = Date()
    }
}

enum EventCategory: String, CaseIterable, Sendable, Codable {
    case user = "user"
    case navigation = "navigation"
    case commerce = "commerce"
    case performance = "performance"
    case error = "error"
    case engagement = "engagement"
    case feature = "feature"
}

// MARK: - Performance Metrics
struct PerformanceMetric: Sendable {
    let name: String
    let value: Double
    let unit: String
    let timestamp: Date
    let metadata: [String: String]?
    
    init(name: String, value: Double, unit: String, metadata: [String: String]? = nil) {
        self.name = name
        self.value = value
        self.unit = unit
        self.timestamp = Date()
        self.metadata = metadata
    }
}

struct PerformanceMeasurement: Sendable {
    let name: String
    let startTime: Date
    private let signpostID: OSSignpostID
    private let log: OSLog
    
    init(name: String) {
        self.name = name
        self.startTime = Date()
        self.log = OSLog(subsystem: "com.mimisupply.app", category: "Performance")
        self.signpostID = OSSignpostID(log: log)
        
        os_signpost(.begin, log: log, name: "Performance", signpostID: signpostID)
    }
    
    func end(metadata: [String: String]? = nil) -> PerformanceMetric {
        let duration = Date().timeIntervalSince(startTime)
        os_signpost(.end, log: log, name: "Performance", signpostID: signpostID)
        
        return PerformanceMetric(
            name: name,
            value: duration * 1000, // Convert to milliseconds
            unit: "ms",
            metadata: metadata
        )
    }
}

// MARK: - User Engagement
struct UserEngagement: Sendable {
    let type: EngagementType
    let duration: TimeInterval?
    let value: Double?
    let metadata: [String: String]?
    let timestamp: Date
    
    init(type: EngagementType, duration: TimeInterval? = nil, value: Double? = nil, metadata: [String: String]? = nil) {
        self.type = type
        self.duration = duration
        self.value = value
        self.metadata = metadata
        self.timestamp = Date()
    }
}

enum EngagementType: String, CaseIterable, Sendable {
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case screenView = "screen_view"
    case userAction = "user_action"
    case conversion = "conversion"
    case retention = "retention"
}

// MARK: - Common Analytics Events
extension AnalyticsEvent {
    // User Events
    static let userSignIn = AnalyticsEvent(name: "user_sign_in", category: .user)
    static let userSignOut = AnalyticsEvent(name: "user_sign_out", category: .user)
    static let roleSelected = AnalyticsEvent(name: "role_selected", category: .user)
    
    // Navigation Events
    static let screenView = AnalyticsEvent(name: "screen_view", category: .navigation)
    static let tabSwitch = AnalyticsEvent(name: "tab_switch", category: .navigation)
    static let deepLinkOpened = AnalyticsEvent(name: "deep_link_opened", category: .navigation)
    
    // Commerce Events
    static let productViewed = AnalyticsEvent(name: "product_viewed", category: .commerce)
    static let addToCart = AnalyticsEvent(name: "add_to_cart", category: .commerce)
    static let removeFromCart = AnalyticsEvent(name: "remove_from_cart", category: .commerce)
    static let checkoutStarted = AnalyticsEvent(name: "checkout_started", category: .commerce)
    static let paymentCompleted = AnalyticsEvent(name: "payment_completed", category: .commerce)
    static let orderPlaced = AnalyticsEvent(name: "order_placed", category: .commerce)
    
    // Performance Events
    static let appLaunch = AnalyticsEvent(name: "app_launch", category: .performance)
    static let screenLoad = AnalyticsEvent(name: "screen_load", category: .performance)
    static let apiCall = AnalyticsEvent(name: "api_call", category: .performance)
    
    // Error Events
    static let errorOccurred = AnalyticsEvent(name: "error_occurred", category: .error)
    static let crashReported = AnalyticsEvent(name: "crash_reported", category: .error)
    
    // Feature Events
    static let featureFlagEvaluated = AnalyticsEvent(name: "feature_flag_evaluated", category: .feature)
    static let experimentViewed = AnalyticsEvent(name: "experiment_viewed", category: .feature)
}