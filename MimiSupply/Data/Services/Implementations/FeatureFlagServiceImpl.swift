import Foundation
import SwiftUI
import CloudKit

// MARK: - Feature Flag Service Implementation
@MainActor
final class FeatureFlagServiceImpl: FeatureFlagService, ObservableObject {
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let cloudKitService: CloudKitService
    private let analyticsService: AnalyticsService
    
    private var flags: [String: Any] = [:]
    private var experiments: [String: ExperimentConfig] = [:]
    private var userVariants: [String: String] = [:]
    
    private let flagsKey = "feature_flags"
    private let experimentsKey = "experiments"
    private let userVariantsKey = "user_variants"
    
    private var lastRefreshDate: Date?
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    
    // MARK: - Initialization
    init(cloudKitService: CloudKitService, analyticsService: AnalyticsService) {
        self.cloudKitService = cloudKitService
        self.analyticsService = analyticsService
        
        loadLocalFlags()
        loadDefaultExperiments()
        
        // Refresh flags on init
        Task {
            try? await refreshFlags()
        }
    }
    
    // MARK: - Public Methods
    func getBoolFlag(_ key: String, defaultValue: Bool) async -> Bool {
        await refreshFlagsIfNeeded()
        
        let value = flags[key] as? Bool ?? defaultValue
        let defaultUsed = flags[key] == nil
        
        await trackFlagEvaluation(key, variant: String(value), defaultUsed: defaultUsed)
        
        return value
    }
    
    func getStringFlag(_ key: String, defaultValue: String) async -> String {
        await refreshFlagsIfNeeded()
        
        let value = flags[key] as? String ?? defaultValue
        let defaultUsed = flags[key] == nil
        
        await trackFlagEvaluation(key, variant: value, defaultUsed: defaultUsed)
        
        return value
    }
    
    func getIntFlag(_ key: String, defaultValue: Int) async -> Int {
        await refreshFlagsIfNeeded()
        
        let value = flags[key] as? Int ?? defaultValue
        let defaultUsed = flags[key] == nil
        
        await trackFlagEvaluation(key, variant: String(value), defaultUsed: defaultUsed)
        
        return value
    }
    
    func getDoubleFlag(_ key: String, defaultValue: Double) async -> Double {
        await refreshFlagsIfNeeded()
        
        let value = flags[key] as? Double ?? defaultValue
        let defaultUsed = flags[key] == nil
        
        await trackFlagEvaluation(key, variant: String(value), defaultUsed: defaultUsed)
        
        return value
    }
    
    func isFeatureEnabled(_ feature: FeatureFlag) async -> Bool {
        return await getBoolFlag(feature.rawValue, defaultValue: feature.defaultValue)
    }
    
    func getExperimentVariant(_ experiment: String) async -> String? {
        await refreshFlagsIfNeeded()
        
        // Check if user already has a variant assigned
        if let existingVariant = userVariants[experiment] {
            await trackFlagEvaluation(experiment, variant: existingVariant, defaultUsed: false)
            return existingVariant
        }
        
        // Get experiment configuration
        guard let config = experiments[experiment],
              config.isActive,
              isExperimentActive(config) else {
            return nil
        }
        
        // Assign variant based on traffic allocation
        let variant = assignVariant(for: config)
        userVariants[experiment] = variant
        saveUserVariants()
        
        await trackFlagEvaluation(experiment, variant: variant, defaultUsed: false)
        
        return variant
    }
    
    func refreshFlags() async throws {
        do {
            // In a real implementation, this would fetch from a remote service
            // For now, we'll simulate with CloudKit or local configuration
            let remoteFlags = try await fetchRemoteFlags()
            let remoteExperiments = try await fetchRemoteExperiments()
            
            flags.merge(remoteFlags) { _, new in new }
            experiments.merge(remoteExperiments) { _, new in new }
            
            saveLocalFlags()
            lastRefreshDate = Date()
            
            print("Feature flags refreshed successfully")
        } catch {
            print("Failed to refresh feature flags: \(error)")
            throw error
        }
    }
    
    func trackFlagEvaluation(_ flag: String, variant: String, defaultUsed: Bool) async {
        await analyticsService.trackFeatureFlag(flag, variant: variant)
        
        let parameters: [String: Any] = [
            "flag_name": flag,
            "variant": variant,
            "default_used": defaultUsed,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        await analyticsService.trackEvent(.featureFlagEvaluated, parameters: parameters as? AnalyticsParameters)
    }
    
    // MARK: - Private Methods
    private func loadLocalFlags() {
        if let data = userDefaults.data(forKey: flagsKey),
           let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            flags = decoded
        }
        
        if let data = userDefaults.data(forKey: userVariantsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            userVariants = decoded
        }
    }
    
    private func saveLocalFlags() {
        if let data = try? JSONSerialization.data(withJSONObject: flags) {
            userDefaults.set(data, forKey: flagsKey)
        }
    }
    
    private func saveUserVariants() {
        if let data = try? JSONEncoder().encode(userVariants) {
            userDefaults.set(data, forKey: userVariantsKey)
        }
    }
    
    private func loadDefaultExperiments() {
        experiments = [
            "checkout_flow_experiment": .checkoutFlow,
            "search_interface_experiment": .searchInterface,
            "onboarding_experience": .onboardingExperience
        ]
        
        // Load default feature flags
        for feature in FeatureFlag.allCases {
            if flags[feature.rawValue] == nil {
                flags[feature.rawValue] = feature.defaultValue
            }
        }
    }
    
    private func refreshFlagsIfNeeded() async {
        guard shouldRefreshFlags() else { return }
        
        try? await refreshFlags()
    }
    
    private func shouldRefreshFlags() -> Bool {
        guard let lastRefresh = lastRefreshDate else { return true }
        return Date().timeIntervalSince(lastRefresh) > refreshInterval
    }
    
    private func fetchRemoteFlags() async throws -> [String: Any] {
        // In a real implementation, this would fetch from your backend or CloudKit
        // For now, return some sample remote flags
        return [
            "enhanced_search": true,
            "promotional_banners": true,
            "ai_recommendations": false,
            "dark_mode_enabled": true,
            "quick_add_to_cart": true,
            "loyalty_program": false,
            "biometric_auth": true,
            "scheduled_delivery": false
        ]
    }
    
    private func fetchRemoteExperiments() async throws -> [String: ExperimentConfig] {
        // In a real implementation, this would fetch from your backend
        // For now, return the default experiments with potential updates
        var remoteExperiments: [String: ExperimentConfig] = [:]
        
        // Simulate some remote experiment updates
        let updatedCheckoutFlow = ExperimentConfig(
            name: "checkout_flow_experiment",
            variants: ["control", "single_page", "progressive", "minimal"],
            trafficAllocation: [
                "control": 0.3,
                "single_page": 0.25,
                "progressive": 0.25,
                "minimal": 0.2
            ],
            isActive: true,
            startDate: Date().addingTimeInterval(-86400), // Started yesterday
            endDate: Date().addingTimeInterval(86400 * 30), // Ends in 30 days
            targetingRules: nil
        )
        
        remoteExperiments["checkout_flow_experiment"] = updatedCheckoutFlow
        
        return remoteExperiments
    }
    
    private func isExperimentActive(_ config: ExperimentConfig) -> Bool {
        let now = Date()
        
        if let startDate = config.startDate, now < startDate {
            return false
        }
        
        if let endDate = config.endDate, now > endDate {
            return false
        }
        
        return config.isActive
    }
    
    private func assignVariant(for config: ExperimentConfig) -> String {
        // Use a deterministic hash based on user ID to ensure consistent assignment
        let userHash = getUserHash()
        let hashValue = Double(userHash % 10000) / 10000.0 // 0.0 to 1.0
        
        var cumulativeWeight = 0.0
        
        for variant in config.variants {
            let weight = config.trafficAllocation[variant] ?? 0.0
            cumulativeWeight += weight
            
            if hashValue <= cumulativeWeight {
                return variant
            }
        }
        
        // Fallback to first variant
        return config.variants.first ?? "control"
    }
    
    private func getUserHash() -> Int {
        // Create a consistent hash for the user
        // In a real app, you might use the user ID or device ID
        let userIdentifier = userDefaults.string(forKey: "user_experiment_id") ?? {
            let newID = UUID().uuidString
            userDefaults.set(newID, forKey: "user_experiment_id")
            return newID
        }()
        
        return abs(userIdentifier.hashValue)
    }
}

// MARK: - Feature Flag Manager (Singleton)
@MainActor
final class FeatureFlagManager: ObservableObject {
    static let shared = FeatureFlagManager()
    
    private var service: FeatureFlagService?
    
    private init() {}
    
    func configure(cloudKitService: CloudKitService, analyticsService: AnalyticsService) {
        self.service = FeatureFlagServiceImpl(
            cloudKitService: cloudKitService,
            analyticsService: analyticsService
        )
    }
    
    func isFeatureEnabled(_ feature: FeatureFlag) async -> Bool {
        guard let service = service else {
            return feature.defaultValue
        }
        return await service.isFeatureEnabled(feature)
    }
    
    func getExperimentVariant(_ experiment: String) async -> String? {
        return await service?.getExperimentVariant(experiment)
    }
    
    func refreshFlags() async throws {
        try await service?.refreshFlags()
    }
}

// MARK: - SwiftUI Environment
struct FeatureFlagEnvironmentKey: EnvironmentKey {
    static let defaultValue: FeatureFlagService? = nil
}

extension EnvironmentValues {
    var featureFlags: FeatureFlagService? {
        get { self[FeatureFlagEnvironmentKey.self] }
        set { self[FeatureFlagEnvironmentKey.self] = newValue }
    }
}
