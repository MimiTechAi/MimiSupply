import SwiftUI
import Network

// MARK: - Network-Aware Loading Component
struct NetworkAwareLoadingView<Content: View>: View {
    let isLoading: Bool
    let networkQuality: NetworkQuality
    @ViewBuilder let content: () -> Content
    @ViewBuilder let skeleton: () -> any View
    
    init(
        isLoading: Bool,
        networkQuality: NetworkQuality = .good,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder skeleton: @escaping () -> any View
    ) {
        self.isLoading = isLoading
        self.networkQuality = networkQuality
        self.content = content
        self.skeleton = skeleton
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: Spacing.md) {
                    AnyView(skeleton())
                    
                    // Show network quality indicator for slow connections
                    if networkQuality == .poor {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "wifi.slash")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Text("Slow connection detected...")
                                .font(.caption2)
                                .foregroundColor(.gray500)
                        }
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                content()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
    }
}

// MARK: - Network Quality Monitor
enum NetworkQuality {
    case excellent
    case good
    case fair
    case poor
    case offline
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .offline: return "Offline"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent, .good: return .green
        case .fair: return .yellow
        case .poor: return .orange
        case .offline: return .red
        }
    }
}

@MainActor
final class NetworkQualityMonitor: ObservableObject {
    @Published var networkQuality: NetworkQuality = .good
    @Published var isConnected = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path: path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func updateNetworkStatus(path: NWPath) {
        isConnected = path.status == .satisfied
        
        if path.status == .satisfied {
            // Estimate network quality based on interface type
            if path.usesInterfaceType(.wifi) {
                networkQuality = .excellent
            } else if path.usesInterfaceType(.cellular) {
                // Could be enhanced with actual bandwidth testing
                networkQuality = .good
            } else if path.usesInterfaceType(.wiredEthernet) {
                networkQuality = .excellent
            } else {
                networkQuality = .fair
            }
        } else {
            networkQuality = .offline
        }
    }
}

// MARK: - Enhanced Skeleton Components with Network Awareness
struct SmartSkeletonCard: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    let networkQuality: NetworkQuality
    
    init(height: CGFloat = 120, cornerRadius: CGFloat = 12, networkQuality: NetworkQuality = .good) {
        self.height = height
        self.cornerRadius = cornerRadius
        self.networkQuality = networkQuality
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(skeletonOpacity))
            .frame(height: height)
            .shimmer(intensity: shimmerIntensity)
    }
    
    private var skeletonOpacity: Double {
        switch networkQuality {
        case .excellent, .good: return 0.3
        case .fair: return 0.25
        case .poor: return 0.2
        case .offline: return 0.15
        }
    }
    
    private var shimmerIntensity: Double {
        switch networkQuality {
        case .excellent, .good: return 1.0
        case .fair: return 0.7
        case .poor: return 0.4
        case .offline: return 0.0
        }
    }
}

// MARK: - Enhanced Shimmer with Intensity Control
struct SmartShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let intensity: Double
    
    init(intensity: Double = 1.0) {
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4 * intensity),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(15))
                .offset(x: phase * 400 - 200)
                .animation(
                    intensity > 0 ? 
                    Animation.linear(duration: 1.5 / intensity)
                        .repeatForever(autoreverses: false) : 
                    .default,
                    value: phase
                )
            )
            .onAppear {
                if intensity > 0 {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer(intensity: Double = 1.0) -> some View {
        modifier(SmartShimmerEffect(intensity: intensity))
    }
}

// MARK: - Preview
#Preview("Network Aware Loading") {
    VStack(spacing: 20) {
        // Good network
        NetworkAwareLoadingView(
            isLoading: true,
            networkQuality: .good
        ) {
            Text("Content loaded")
        } skeleton: {
            SmartSkeletonCard(height: 100, networkQuality: .good)
        }
        
        // Poor network
        NetworkAwareLoadingView(
            isLoading: true,
            networkQuality: .poor
        ) {
            Text("Content loaded")
        } skeleton: {
            SmartSkeletonCard(height: 100, networkQuality: .poor)
        }
        
        // Offline
        NetworkAwareLoadingView(
            isLoading: true,
            networkQuality: .offline
        ) {
            Text("Content loaded")
        } skeleton: {
            SmartSkeletonCard(height: 100, networkQuality: .offline)
        }
    }
    .padding()
}