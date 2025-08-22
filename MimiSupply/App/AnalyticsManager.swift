import Foundation
import SwiftUI

// MARK: - Analytics Manager
@MainActor
final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private var analyticsService: AnalyticsService?
    private var featureFlagService: FeatureFlagService?
    
    private init() {}
    
    func configure() {
        // Initialize analytics service
        analyticsService = AnalyticsServiceImpl()
        
        // Initialize feature flag service
        if let analytics = analyticsService {
            let cloudKitService: CloudKitService = CloudKitServiceImpl.shared
            featureFlagService = FeatureFlagServiceImpl(
                cloudKitService: cloudKitService,
                analyticsService: analytics
            )
        }
        
        // Configure feature flag manager
        if let featureFlagService = featureFlagService, let analytics = analyticsService {
            FeatureFlagManager.shared.configure(
                cloudKitService: CloudKitServiceImpl.shared,
                analyticsService: analytics
            )
        }
        
        // Track app launch
        Task {
            await trackAppLaunch()
        }
    }
    
    var analytics: AnalyticsService? {
        analyticsService
    }
    
    var featureFlags: FeatureFlagService? {
        featureFlagService
    }
    
    // MARK: - Convenience Methods
    func trackScreenView(_ screenName: String, parameters: [String: Any]? = nil) {
        Task {
            await analyticsService?.trackScreenView(screenName, parameters: parameters)
        }
    }
    
    func trackEvent(_ event: AnalyticsEvent, parameters: [String: Any]? = nil) {
        Task {
            await analyticsService?.trackEvent(event, parameters: parameters)
        }
    }
    
    func trackError(_ error: Error, context: [String: Any]? = nil) {
        Task {
            await analyticsService?.trackError(error, context: context)
        }
    }
    
    func isFeatureEnabled(_ feature: FeatureFlag) async -> Bool {
        return await FeatureFlagManager.shared.isFeatureEnabled(feature)
    }
    
    func getExperimentVariant(_ experiment: String) async -> String? {
        return await FeatureFlagManager.shared.getExperimentVariant(experiment)
    }
    
    // MARK: - Private Methods
    private func trackAppLaunch() async {
        let launchMeasurement = analyticsService?.startPerformanceMeasurement("app_launch")
        
        // Simulate app launch completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Task {
                if let measurement = launchMeasurement {
                    let metric = measurement.end(metadata: [
                        "cold_start": "true",
                        "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                    ])
                    await self.analyticsService?.trackPerformanceMetric(metric)
                }
                
                await self.analyticsService?.trackEvent(.appLaunch, parameters: [
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                    "os_version": UIDevice.current.systemVersion,
                    "device_model": UIDevice.current.model
                ])
            }
        }
    }
}

// MARK: - SwiftUI Environment
struct AnalyticsEnvironmentKey: EnvironmentKey {
    static let defaultValue: AnalyticsService? = nil
}

extension EnvironmentValues {
    var analytics: AnalyticsService? {
        get { self[AnalyticsEnvironmentKey.self] }
        set { self[AnalyticsEnvironmentKey.self] = newValue }
    }
}

// MARK: - View Modifier for Screen Tracking
struct ScreenTrackingModifier: ViewModifier {
    let screenName: String
    let parameters: [String: Any]?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsManager.shared.trackScreenView(screenName, parameters: parameters)
            }
    }
}

extension View {
    func trackScreen(_ screenName: String, parameters: [String: Any]? = nil) -> some View {
        modifier(ScreenTrackingModifier(screenName: screenName, parameters: parameters))
    }
}

// MARK: - Performance Tracking View Modifier
struct PerformanceTrackingModifier: ViewModifier {
    let operationName: String
    @State private var measurement: PerformanceMeasurement?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                measurement = AnalyticsManager.shared.analytics?.startPerformanceMeasurement(operationName)
            }
            .onDisappear {
                if let measurement = measurement {
                    let metric = measurement.end()
                    Task {
                        await AnalyticsManager.shared.analytics?.trackPerformanceMetric(metric)
                    }
                }
            }
    }
}

extension View {
    func trackPerformance(_ operationName: String) -> some View {
        modifier(PerformanceTrackingModifier(operationName: operationName))
    }
}

// MARK: - Feature Flag View Modifier
struct FeatureFlagModifier: ViewModifier {
    let feature: FeatureFlag
    @State private var isEnabled = false
    
    func body(content: Content) -> some View {
        Group {
            if isEnabled {
                content
            } else {
                EmptyView()
            }
        }
        .task {
            isEnabled = await AnalyticsManager.shared.isFeatureEnabled(feature)
        }
    }
}

extension View {
    func showIf(featureEnabled feature: FeatureFlag) -> some View {
        modifier(FeatureFlagModifier(feature: feature))
    }
}

// MARK: - Experiment Variant View Modifier
struct ExperimentVariantModifier<Content: View>: ViewModifier {
    typealias Body = AnyView
    
    let experiment: String
    let variants: [String: () -> Content]
    let defaultContent: () -> Content
    
    @State private var currentVariant: String?
    
    func body(content: some View) -> AnyView {
        AnyView(
            Group {
                if let variant = currentVariant,
                   let variantContent = variants[variant] {
                    variantContent()
                } else {
                    defaultContent()
                }
            }
            .task {
                currentVariant = await AnalyticsManager.shared.getExperimentVariant(experiment)
            }
        )
    }
}

extension View {
    func experimentVariant<Content: View>(
        _ experiment: String,
        variants: [String: () -> Content],
        default defaultContent: @escaping () -> Content
    ) -> some View {
        modifier(ExperimentVariantModifier(
            experiment: experiment,
            variants: variants,
            defaultContent: defaultContent
        ))
    }
}