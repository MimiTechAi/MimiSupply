import UIKit
import OSLog
import SwiftUI

// MARK: - Haptic Feedback Types
enum HapticFeedbackType {
    // Impact Feedback
    case lightImpact
    case mediumImpact
    case heavyImpact
    case rigidImpact
    case softImpact
    
    // Notification Feedback
    case success
    case warning
    case error
    
    // Selection Feedback
    case selection
    
    // Custom Patterns
    case buttonTap
    case cardFlip
    case swipeAction
    case pullToRefresh
    case longPress
    case dragStart
    case dragEnd
    case modalPresent
    case modalDismiss
    case tabSwitch
    case toggleOn
    case toggleOff
    case addToCart
    case removeFromCart
    case paymentSuccess
    case paymentError
    case orderPlaced
    case orderDelivered
    case navigationBack
    case searchResult
    case filterApplied
    case sortChanged
    
    // Business Intelligence Specific
    case dataLoaded
    case chartInteraction
    case metricTap
    case reportGenerated
    case exportComplete
    case dashboardRefresh
    
    // Enhanced Patterns
    case successSequence
    case errorSequence
    case celebrationPattern
    case alertPattern
    case loadingComplete
    case achievementUnlocked
    
    // iOS 17+ SensoryFeedback Mapping
    @available(iOS 17.0, *)
    var sensoryFeedback: SensoryFeedback {
        switch self {
        case .lightImpact, .buttonTap, .tabSwitch:
            return .impact(weight: .light)
        case .mediumImpact, .cardFlip, .modalPresent:
            return .impact(weight: .medium)
        case .heavyImpact, .longPress:
            return .impact(weight: .heavy)
        case .rigidImpact:
            return .impact(flexibility: .rigid)
        case .softImpact:
            return .impact(flexibility: .soft)
        case .selection, .searchResult, .filterApplied:
            return .selection
        case .success, .addToCart, .paymentSuccess, .orderPlaced, .dataLoaded:
            return .success
        case .warning:
            return .warning
        case .error, .paymentError:
            return .error
        case .successSequence, .celebrationPattern:
            return .success
        case .errorSequence, .alertPattern:
            return .error
        default:
            return .impact(weight: .light)
        }
    }
}

// MARK: - Haptic Intensity
enum HapticIntensity: CGFloat, CaseIterable {
    case subtle = 0.3
    case normal = 0.7
    case strong = 1.0
    
    var displayName: String {
        switch self {
        case .subtle: return "Subtle"
        case .normal: return "Normal"
        case .strong: return "Strong"
        }
    }
}

// MARK: - Haptic Context
enum HapticContext {
    case ui          // General UI interactions
    case navigation  // Navigation actions
    case commerce    // Shopping/payment actions
    case analytics   // Business intelligence actions
    case system      // System notifications
    case gaming      // Achievement/celebration
    
    var defaultIntensity: HapticIntensity {
        switch self {
        case .ui, .navigation: return .normal
        case .commerce, .analytics: return .strong
        case .system: return .normal
        case .gaming: return .strong
        }
    }
}

// MARK: - Enhanced Haptic Manager
@MainActor
final class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    // MARK: - Properties
    @Published var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "haptics_enabled")
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                Task { @MainActor in
                    self.logger.info("🔄 Haptics \(self.isHapticsEnabled ? "enabled" : "disabled")")
                }
            }
        }
    }
    
    @Published var hapticIntensity: HapticIntensity {
        didSet {
            UserDefaults.standard.set(hapticIntensity.rawValue, forKey: "haptic_intensity")
            
            let logger = self.logger
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                Task { @MainActor in
                    logger.info("🔄 Haptic intensity: \(self.hapticIntensity.displayName)")
                }
            }
            
            // Trigger sample haptic with new intensity
            trigger(.mediumImpact)
        }
    }
    
    @Published var contextualHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(contextualHapticsEnabled, forKey: "contextual_haptics_enabled")
        }
    }
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Haptics")
    
    // Feedback generators (lazy to avoid unnecessary initialization)
    private lazy var lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private lazy var softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private lazy var selectionGenerator = UISelectionFeedbackGenerator()
    private lazy var notificationGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    private init() {
        self.isHapticsEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
        self.hapticIntensity = HapticIntensity(rawValue: UserDefaults.standard.object(forKey: "haptic_intensity") as? CGFloat ?? HapticIntensity.normal.rawValue) ?? .normal
        self.contextualHapticsEnabled = UserDefaults.standard.object(forKey: "contextual_haptics_enabled") as? Bool ?? true
        
        // Prepare generators for better performance
        prepareGenerators()
        
        logger.info("🎯 Haptic Manager initialized - Haptics: \(self.isHapticsEnabled ? "enabled" : "disabled"), Intensity: \(self.hapticIntensity.displayName)")
    }
    
    // MARK: - Public Interface
    func trigger(_ type: HapticFeedbackType, context: HapticContext = .ui) {
        guard isHapticsEnabled else { return }
        
        // Check if device supports haptics
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            logger.debug("📱 Haptics not supported on this device")
            return
        }
        
        // Apply accessibility considerations
        let effectiveType = applyAccessibilityAdjustments(type)
        
        logger.debug("🎯 Triggering haptic: \(String(describing: effectiveType)) in context: \(String(describing: context))")
        
        // Use iOS 17+ sensoryFeedback if available
        if #available(iOS 17.0, *), contextualHapticsEnabled {
            triggerSensoryFeedback(effectiveType, context: context)
        } else {
            triggerLegacyHaptic(effectiveType, context: context)
        }
    }
    
    // MARK: - iOS 17+ SensoryFeedback
    @available(iOS 17.0, *)
    private func triggerSensoryFeedback(_ type: HapticFeedbackType, context: HapticContext) {
        let feedback = type.sensoryFeedback
        
        // Apply intensity adjustment
        let adjustedFeedback = applyIntensityAdjustment(feedback, context: context)
        
        // Note: In a real implementation, you'd apply this to a View with .sensoryFeedback()
        // For now, fall back to legacy haptics
        triggerLegacyHaptic(type, context: context)
    }
    
    @available(iOS 17.0, *)
    private func applyIntensityAdjustment(_ feedback: SensoryFeedback, context: HapticContext) -> SensoryFeedback {
        let contextIntensity = context.defaultIntensity
        let userIntensity = hapticIntensity
        
        // Combine context and user preferences
        let effectiveIntensity = min(contextIntensity.rawValue, userIntensity.rawValue)
        
        // For impact feedback, adjust based on effective intensity
        if effectiveIntensity < 0.5 {
            return .impact(weight: .light)
        } else if effectiveIntensity < 0.8 {
            return .impact(weight: .medium)
        } else {
            return feedback
        }
    }
    
    // MARK: - Legacy Haptic Implementation
    private func triggerLegacyHaptic(_ type: HapticFeedbackType, context: HapticContext) {
        switch type {
        // Basic Impact Feedback
        case .lightImpact:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .mediumImpact:
            mediumImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .heavyImpact:
            heavyImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .rigidImpact:
            rigidImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .softImpact:
            softImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        // Notification Feedback
        case .success:
            notificationGenerator.notificationOccurred(.success)
            
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            
        case .error:
            notificationGenerator.notificationOccurred(.error)
            
        // Selection Feedback
        case .selection:
            selectionGenerator.selectionChanged()
            
        // Custom Patterns
        case .buttonTap:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.8)
            
        case .cardFlip:
            mediumImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .swipeAction:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.6)
            
        case .pullToRefresh:
            mediumImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .longPress:
            heavyImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .dragStart:
            rigidImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.7)
            
        case .dragEnd:
            softImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.5)
            
        case .modalPresent:
            mediumImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .modalDismiss:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.7)
            
        case .tabSwitch:
            selectionGenerator.selectionChanged()
            
        case .toggleOn:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .toggleOff:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.6)
            
        case .addToCart:
            notificationGenerator.notificationOccurred(.success)
            
        case .removeFromCart:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.8)
            
        case .paymentSuccess:
            createCustomPattern([
                (0.0, .success),
                (0.15, .lightImpact)
            ], context: context)
            
        case .paymentError:
            notificationGenerator.notificationOccurred(.error)
            
        case .orderPlaced:
            createCustomPattern([
                (0.0, .success),
                (0.1, .mediumImpact),
                (0.2, .lightImpact)
            ], context: context)
            
        case .orderDelivered:
            createCustomPattern([
                (0.0, .success),
                (0.1, .mediumImpact),
                (0.2, .lightImpact),
                (0.3, .success)
            ], context: context)
            
        case .navigationBack:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.6)
            
        case .searchResult:
            selectionGenerator.selectionChanged()
            
        case .filterApplied:
            mediumImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        case .sortChanged:
            selectionGenerator.selectionChanged()
            
        // Business Intelligence Specific
        case .dataLoaded:
            createCustomPattern([
                (0.0, .mediumImpact),
                (0.1, .lightImpact)
            ], context: context)
            
        case .chartInteraction:
            lightImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue * 0.5)
            
        case .metricTap:
            selectionGenerator.selectionChanged()
            
        case .reportGenerated:
            createCustomPattern([
                (0.0, .success),
                (0.1, .lightImpact),
                (0.2, .lightImpact)
            ], context: context)
            
        case .exportComplete:
            notificationGenerator.notificationOccurred(.success)
            
        case .dashboardRefresh:
            mediumImpactGenerator.impactOccurred(intensity: hapticIntensity.rawValue)
            
        // Enhanced Patterns
        case .successSequence:
            createCustomPattern([
                (0.0, .lightImpact),
                (0.1, .mediumImpact),
                (0.2, .success),
                (0.4, .lightImpact)
            ], context: context)
            
        case .errorSequence:
            createCustomPattern([
                (0.0, .error),
                (0.2, .mediumImpact)
            ], context: context)
            
        case .celebrationPattern:
            createCustomPattern([
                (0.0, .success),
                (0.1, .lightImpact),
                (0.2, .mediumImpact),
                (0.3, .lightImpact),
                (0.5, .success)
            ], context: context)
            
        case .alertPattern:
            createCustomPattern([
                (0.0, .warning),
                (0.15, .mediumImpact),
                (0.3, .warning)
            ], context: context)
            
        case .loadingComplete:
            createCustomPattern([
                (0.0, .success),
                (0.1, .lightImpact)
            ], context: context)
            
        case .achievementUnlocked:
            createCustomPattern([
                (0.0, .success),
                (0.1, .mediumImpact),
                (0.2, .lightImpact),
                (0.3, .lightImpact),
                (0.5, .success)
            ], context: context)
        }
    }
    
    // MARK: - Custom Patterns
    private func createCustomPattern(_ pattern: [(TimeInterval, HapticFeedbackType)], context: HapticContext) {
        for (delay, hapticType) in pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.triggerLegacyHaptic(hapticType, context: context)
            }
        }
    }
    
    // MARK: - Accessibility Integration
    private func applyAccessibilityAdjustments(_ type: HapticFeedbackType) -> HapticFeedbackType {
        guard UIAccessibility.isReduceMotionEnabled else { return type }
        
        // Reduce haptic intensity for users with reduce motion enabled
        switch type {
        case .heavyImpact, .rigidImpact:
            return .mediumImpact
        case .mediumImpact:
            return .lightImpact
        case .successSequence, .celebrationPattern, .achievementUnlocked:
            return .success
        case .errorSequence, .alertPattern:
            return .error
        default:
            return type
        }
    }
    
    // MARK: - Generator Management
    private func prepareGenerators() {
        // Prepare all generators for better performance
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        softImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    func prepareForInteraction() {
        guard isHapticsEnabled else { return }
        prepareGenerators()
    }
    
    // MARK: - Settings
    func toggleHaptics() {
        isHapticsEnabled.toggle()
        
        // Provide feedback for the toggle action
        if isHapticsEnabled {
            trigger(.toggleOn, context: .system)
        }
    }
    
    func setIntensity(_ intensity: HapticIntensity) {
        hapticIntensity = intensity
        
        // Test the new intensity
        trigger(.mediumImpact, context: .system)
    }
    
    /// Update haptic settings
    func updateSettings(enabled: Bool) async {
        isHapticsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "haptics_enabled")
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.info("🔄 Haptics \(self.isHapticsEnabled ? "enabled" : "disabled")")
            }
        }
    }
    
    /// Update haptic intensity
    func updateIntensity(_ intensity: HapticIntensity) async {
        hapticIntensity = intensity
        UserDefaults.standard.set(intensity.rawValue, forKey: "haptic_intensity")
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.logger.info("🔄 Haptic intensity: \(self.hapticIntensity.displayName)")
            }
        }
        
        // Trigger sample haptic with new intensity
        trigger(.buttonTap)
    }
}

// MARK: - Enhanced SwiftUI Integration
extension View {
    func hapticFeedback(_ type: HapticFeedbackType, context: HapticContext = .ui, trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            HapticManager.shared.trigger(type, context: context)
        }
    }
    
    func onTapHaptic(_ type: HapticFeedbackType = .buttonTap, context: HapticContext = .ui, perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.trigger(type, context: context)
            action()
        }
    }
    
    func onLongPressHaptic(
        minimumDuration: Double = 0.5,
        maximumDistance: CGFloat = 10,
        context: HapticContext = .ui,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onLongPressGesture(
            minimumDuration: minimumDuration,
            maximumDistance: maximumDistance
        ) {
            HapticManager.shared.trigger(.longPress, context: context)
            action()
        }
    }
    
    // iOS 17+ SensoryFeedback Integration
    @available(iOS 17.0, *)
    func sensoryFeedbackOnTap(_ type: HapticFeedbackType = .buttonTap, context: HapticContext = .ui) -> some View {
        self.sensoryFeedback(type.sensoryFeedback, trigger: UUID())
    }
    
    // Business Intelligence specific haptics
    func chartInteractionHaptic() -> some View {
        self.onTapHaptic(.chartInteraction, context: .analytics) {}
    }
    
    func metricTapHaptic() -> some View {
        self.onTapHaptic(.metricTap, context: .analytics) {}
    }
}

// MARK: - Business Intelligence Haptic Extensions
extension HapticManager {
    func triggerDataLoadComplete() {
        trigger(.dataLoaded, context: .analytics)
    }
    
    func triggerChartInteraction() {
        trigger(.chartInteraction, context: .analytics)
    }
    
    func triggerMetricTap() {
        trigger(.metricTap, context: .analytics)
    }
    
    func triggerReportGenerated() {
        trigger(.reportGenerated, context: .analytics)
    }
    
    func triggerExportComplete() {
        trigger(.exportComplete, context: .analytics)
    }
    
    func triggerDashboardRefresh() {
        trigger(.dashboardRefresh, context: .analytics)
    }
}

// MARK: - Button Extensions
extension Button {
    init(
        _ title: String,
        hapticType: HapticFeedbackType = .buttonTap,
        action: @escaping () -> Void
    ) {
        self.init(title) {
            Task { @MainActor in
                HapticManager.shared.trigger(hapticType)
                action()
            }
        }
    }
}

// MARK: - Haptic Settings View
struct HapticSettingsView: View {
    @StateObject private var hapticManager = HapticManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Haptic Feedback")
                .font(.headline)
            
            Toggle("Enable Haptic Feedback", isOn: $hapticManager.isHapticsEnabled)
                .onChange(of: hapticManager.isHapticsEnabled) { _, newValue in
                    if newValue {
                        hapticManager.trigger(.toggleOn)
                    }
                }
            
            if hapticManager.isHapticsEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Test Haptic Feedback")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        HapticTestButton("Light", type: .lightImpact)
                        HapticTestButton("Medium", type: .mediumImpact)
                        HapticTestButton("Heavy", type: .heavyImpact)
                        HapticTestButton("Success", type: .success)
                        HapticTestButton("Warning", type: .warning)
                        HapticTestButton("Error", type: .error)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct HapticTestButton: View {
    let title: String
    let type: HapticFeedbackType
    
    init(_ title: String, type: HapticFeedbackType) {
        self.title = title
        self.type = type
    }
    
    var body: some View {
        Button(title) {
            HapticManager.shared.trigger(type)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

// MARK: - Accessibility Integration
extension HapticManager {
    var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    func triggerAccessible(_ type: HapticFeedbackType) {
        // Reduce haptic intensity for users with reduce motion enabled
        if isReduceMotionEnabled {
            switch type {
            case .heavyImpact, .rigidImpact:
                trigger(.mediumImpact)
            case .mediumImpact:
                trigger(.lightImpact)
            default:
                trigger(type)
            }
        } else {
            trigger(type)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HapticSettingsView()
        
        VStack(spacing: 12) {
            Text("Haptic Examples")
                .font(.headline)
            
            Button("Add to Cart") {
                // This will automatically trigger haptic feedback
            }
            .onTapHaptic(.addToCart) {
                print("Added to cart")
            }
            
            Button("Remove Item") {
                // Custom haptic for destructive action
            }
            .onTapHaptic(.removeFromCart) {
                print("Removed from cart")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}