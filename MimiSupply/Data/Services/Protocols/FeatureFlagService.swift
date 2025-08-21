import Foundation

// MARK: - Feature Flag Service Protocol
protocol FeatureFlagService: Sendable {
    /// Get boolean feature flag value
    func getBoolFlag(_ key: String, defaultValue: Bool) async -> Bool
    
    /// Get string feature flag value
    func getStringFlag(_ key: String, defaultValue: String) async -> String
    
    /// Get integer feature flag value
    func getIntFlag(_ key: String, defaultValue: Int) async -> Int
    
    /// Get double feature flag value
    func getDoubleFlag(_ key: String, defaultValue: Double) async -> Double
    
    /// Check if feature is enabled
    func isFeatureEnabled(_ feature: FeatureFlag) async -> Bool
    
    /// Get experiment variant
    func getExperimentVariant(_ experiment: String) async -> String?
    
    /// Refresh feature flags from remote
    func refreshFlags() async throws
    
    /// Track feature flag evaluation
    func trackFlagEvaluation(_ flag: String, variant: String, defaultUsed: Bool) async
}

// MARK: - Feature Flags
enum FeatureFlag: String, CaseIterable {
    // UI/UX Features
    case newOnboardingFlow = "new_onboarding_flow"
    case enhancedSearch = "enhanced_search"
    case darkModeEnabled = "dark_mode_enabled"
    case mapViewDefault = "map_view_default"
    case quickAddToCart = "quick_add_to_cart"
    
    // Performance Features
    case imageOptimization = "image_optimization"
    case backgroundSync = "background_sync"
    case cachePreloading = "cache_preloading"
    case lazyLoading = "lazy_loading"
    
    // Business Features
    case promotionalBanners = "promotional_banners"
    case loyaltyProgram = "loyalty_program"
    case subscriptionOrders = "subscription_orders"
    case groupOrders = "group_orders"
    case scheduledDelivery = "scheduled_delivery"
    
    // Analytics Features
    case enhancedAnalytics = "enhanced_analytics"
    case crashReporting = "crash_reporting"
    case performanceMonitoring = "performance_monitoring"
    case userBehaviorTracking = "user_behavior_tracking"
    
    // Experimental Features
    case aiRecommendations = "ai_recommendations"
    case voiceOrdering = "voice_ordering"
    case arProductView = "ar_product_view"
    case socialSharing = "social_sharing"
    
    // Safety and Security
    case biometricAuth = "biometric_auth"
    case fraudDetection = "fraud_detection"
    case enhancedEncryption = "enhanced_encryption"
    
    var defaultValue: Bool {
        switch self {
        case .crashReporting, .performanceMonitoring:
            return true
        case .darkModeEnabled, .imageOptimization, .backgroundSync:
            return true
        case .lazyLoading, .cachePreloading:
            return true
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .newOnboardingFlow:
            return "New user onboarding experience"
        case .enhancedSearch:
            return "Enhanced search with filters and suggestions"
        case .darkModeEnabled:
            return "Dark mode support"
        case .mapViewDefault:
            return "Show map view by default on explore screen"
        case .quickAddToCart:
            return "Quick add to cart without product detail view"
        case .imageOptimization:
            return "Advanced image compression and caching"
        case .backgroundSync:
            return "Background data synchronization"
        case .cachePreloading:
            return "Preload frequently accessed data"
        case .lazyLoading:
            return "Lazy load images and content"
        case .promotionalBanners:
            return "Show promotional banners and offers"
        case .loyaltyProgram:
            return "Customer loyalty and rewards program"
        case .subscriptionOrders:
            return "Recurring subscription orders"
        case .groupOrders:
            return "Group ordering for multiple users"
        case .scheduledDelivery:
            return "Schedule deliveries for later"
        case .enhancedAnalytics:
            return "Advanced analytics and insights"
        case .crashReporting:
            return "Automatic crash reporting"
        case .performanceMonitoring:
            return "Performance metrics collection"
        case .userBehaviorTracking:
            return "User behavior analytics"
        case .aiRecommendations:
            return "AI-powered product recommendations"
        case .voiceOrdering:
            return "Voice-activated ordering"
        case .arProductView:
            return "Augmented reality product preview"
        case .socialSharing:
            return "Social media sharing features"
        case .biometricAuth:
            return "Biometric authentication"
        case .fraudDetection:
            return "Advanced fraud detection"
        case .enhancedEncryption:
            return "Enhanced data encryption"
        }
    }
}

// MARK: - Targeting Rules
struct TargetingRules: Codable, Sendable {
    let userSegments: [String]?
    let geoTargeting: [String]?
    let deviceTypes: [String]?
    let appVersions: [String]?
    let customAttributes: [String: String]?
    
    init(
        userSegments: [String]? = nil,
        geoTargeting: [String]? = nil,
        deviceTypes: [String]? = nil,
        appVersions: [String]? = nil,
        customAttributes: [String: String]? = nil
    ) {
        self.userSegments = userSegments
        self.geoTargeting = geoTargeting
        self.deviceTypes = deviceTypes
        self.appVersions = appVersions
        self.customAttributes = customAttributes
    }
}

// MARK: - Experiment Configuration
struct ExperimentConfig: Codable, Sendable {
    let name: String
    let variants: [String]
    let trafficAllocation: [String: Double] // variant -> percentage
    let isActive: Bool
    let startDate: Date?
    let endDate: Date?
    let targetingRules: TargetingRules?
    
    enum CodingKeys: String, CodingKey {
        case name, variants, trafficAllocation, isActive, startDate, endDate, targetingRules
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(variants, forKey: .variants)
        try container.encode(trafficAllocation, forKey: .trafficAllocation)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(targetingRules, forKey: .targetingRules)
    }
    
    init(
        name: String,
        variants: [String],
        trafficAllocation: [String: Double],
        isActive: Bool,
        startDate: Date? = nil,
        endDate: Date? = nil,
        targetingRules: TargetingRules? = nil
    ) {
        self.name = name
        self.variants = variants
        self.trafficAllocation = trafficAllocation
        self.isActive = isActive
        self.startDate = startDate
        self.endDate = endDate
        self.targetingRules = targetingRules
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        variants = try container.decode([String].self, forKey: .variants)
        trafficAllocation = try container.decode([String: Double].self, forKey: .trafficAllocation)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        targetingRules = try container.decodeIfPresent(TargetingRules.self, forKey: .targetingRules)
    }
}

// MARK: - Common Experiments
extension ExperimentConfig {
    static let checkoutFlow = ExperimentConfig(
        name: "checkout_flow_experiment",
        variants: ["control", "single_page", "progressive"],
        trafficAllocation: [
            "control": 0.4,
            "single_page": 0.3,
            "progressive": 0.3
        ],
        isActive: true,
        startDate: nil,
        endDate: nil,
        targetingRules: nil
    )
    
    static let searchInterface = ExperimentConfig(
        name: "search_interface_experiment",
        variants: ["control", "enhanced_filters", "ai_suggestions"],
        trafficAllocation: [
            "control": 0.5,
            "enhanced_filters": 0.25,
            "ai_suggestions": 0.25
        ],
        isActive: true,
        startDate: nil,
        endDate: nil,
        targetingRules: nil
    )
    
    static let onboardingExperience = ExperimentConfig(
        name: "onboarding_experience",
        variants: ["control", "interactive", "video_guided"],
        trafficAllocation: [
            "control": 0.33,
            "interactive": 0.33,
            "video_guided": 0.34
        ],
        isActive: false,
        startDate: nil,
        endDate: nil,
        targetingRules: nil
    )
}