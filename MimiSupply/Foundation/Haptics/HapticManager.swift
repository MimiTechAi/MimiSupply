import UIKit
import OSLog

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
}

// MARK: - Haptic Manager
@MainActor
final class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    // MARK: - Properties
    @Published var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "haptics_enabled")
            logger.info("🔄 Haptics \(isHapticsEnabled ? "enabled" : "disabled")")
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
        
        // Prepare generators for better performance
        prepareGenerators()
        
        logger.info("🎯 Haptic Manager initialized - Haptics: \(isHapticsEnabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Public Interface
    func trigger(_ type: HapticFeedbackType) {
        guard isHapticsEnabled else { return }
        
        // Check if device supports haptics
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            logger.debug("📱 Haptics not supported on this device")
            return
        }
        
        logger.debug("🎯 Triggering haptic: \(type)")
        
        switch type {
        // Basic Impact Feedback
        case .lightImpact:
            lightImpactGenerator.impactOccurred()
            
        case .mediumImpact:
            mediumImpactGenerator.impactOccurred()
            
        case .heavyImpact:
            heavyImpactGenerator.impactOccurred()
            
        case .rigidImpact:
            rigidImpactGenerator.impactOccurred()
            
        case .softImpact:
            softImpactGenerator.impactOccurred()
            
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
            lightImpactGenerator.impactOccurred()
            
        case .cardFlip:
            mediumImpactGenerator.impactOccurred()
            
        case .swipeAction:
            lightImpactGenerator.impactOccurred()
            
        case .pullToRefresh:
            mediumImpactGenerator.impactOccurred()
            
        case .longPress:
            heavyImpactGenerator.impactOccurred()
            
        case .dragStart:
            rigidImpactGenerator.impactOccurred()
            
        case .dragEnd:
            softImpactGenerator.impactOccurred()
            
        case .modalPresent:
            mediumImpactGenerator.impactOccurred()
            
        case .modalDismiss:
            lightImpactGenerator.impactOccurred()
            
        case .tabSwitch:
            selectionGenerator.selectionChanged()
            
        case .toggleOn:
            lightImpactGenerator.impactOccurred()
            
        case .toggleOff:
            lightImpactGenerator.impactOccurred()
            
        case .addToCart:
            notificationGenerator.notificationOccurred(.success)
            
        case .removeFromCart:
            lightImpactGenerator.impactOccurred()
            
        case .paymentSuccess:
            notificationGenerator.notificationOccurred(.success)
            
        case .paymentError:
            notificationGenerator.notificationOccurred(.error)
            
        case .orderPlaced:
            createCustomPattern([
                (0.0, .success),
                (0.1, .lightImpact)
            ])
            
        case .orderDelivered:
            createCustomPattern([
                (0.0, .success),
                (0.1, .mediumImpact),
                (0.2, .lightImpact)
            ])
            
        case .navigationBack:
            lightImpactGenerator.impactOccurred()
            
        case .searchResult:
            selectionGenerator.selectionChanged()
            
        case .filterApplied:
            mediumImpactGenerator.impactOccurred()
            
        case .sortChanged:
            selectionGenerator.selectionChanged()
        }
    }
    
    // MARK: - Custom Patterns
    private func createCustomPattern(_ pattern: [(TimeInterval, HapticFeedbackType)]) {
        for (delay, hapticType) in pattern {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.trigger(hapticType)
            }
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
            trigger(.toggleOn)
        }
    }
}

// MARK: - SwiftUI Integration
extension View {
    func hapticFeedback(_ type: HapticFeedbackType, trigger: some Equatable) -> some View {
        self.onChange(of: trigger) { _, _ in
            HapticManager.shared.trigger(type)
        }
    }
    
    func onTapHaptic(_ type: HapticFeedbackType = .buttonTap, perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.shared.trigger(type)
            action()
        }
    }
    
    func onLongPressHaptic(
        minimumDuration: Double = 0.5,
        maximumDistance: CGFloat = 10,
        perform action: @escaping () -> Void
    ) -> some View {
        self.onLongPressGesture(
            minimumDuration: minimumDuration,
            maximumDistance: maximumDistance
        ) {
            HapticManager.shared.trigger(.longPress)
            action()
        }
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
            HapticManager.shared.trigger(hapticType)
            action()
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