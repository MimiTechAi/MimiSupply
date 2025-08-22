import Foundation
import OSLog

// MARK: - Performance Budget Configuration
struct PerformanceBudgets {
    
    // MARK: - App Launch Budgets
    struct AppLaunch {
        static let coldStartTime: TimeInterval = 2.0      // 2 seconds max
        static let warmStartTime: TimeInterval = 0.5      // 500ms max
        static let memoryUsageAtLaunch: UInt64 = 50_000_000 // 50MB max
    }
    
    // MARK: - Screen Transition Budgets
    struct Transitions {
        static let screenTransitionTime: TimeInterval = 0.3    // 300ms max
        static let modalPresentationTime: TimeInterval = 0.25  // 250ms max
        static let tabSwitchTime: TimeInterval = 0.1          // 100ms max
    }
    
    // MARK: - Network Operation Budgets
    struct Network {
        static let apiResponseTime: TimeInterval = 3.0        // 3 seconds max
        static let imageLoadTime: TimeInterval = 2.0          // 2 seconds max
        static let searchResponseTime: TimeInterval = 1.0     // 1 second max
        static let maxConcurrentRequests: Int = 6             // iOS default
    }
    
    // MARK: - Memory Budgets
    struct Memory {
        static let maxMemoryUsage: UInt64 = 200_000_000      // 200MB max
        static let memoryWarningThreshold: UInt64 = 150_000_000 // 150MB warning
        static let imageCacheSize: UInt64 = 50_000_000       // 50MB max for images
    }
    
    // MARK: - Rendering Budgets
    struct Rendering {
        static let targetFPS: Double = 60.0                   // 60 FPS target
        static let frameDropThreshold: Double = 0.95          // 95% frames on time
        static let scrollingFPS: Double = 60.0                // Smooth scrolling
        static let animationFrameTime: TimeInterval = 0.016   // 16ms per frame
    }
    
    // MARK: - Battery & Energy Budgets
    struct Energy {
        static let backgroundTaskDuration: TimeInterval = 30.0 // 30 seconds max
        static let locationUpdateInterval: TimeInterval = 60.0  // 1 minute min
        static let maxCPUUsage: Double = 0.8                   // 80% max sustained
    }
}

// MARK: - Performance Monitor
@MainActor
final class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "Performance")
    private var measurements: [String: AppPerformanceMeasurement] = [:]
    
    private init() {}
    
    // MARK: - Measurement Tracking
    func startMeasurement(_ name: String) -> AppPerformanceMeasurement {
        let measurement = AppPerformanceMeasurement(name: name)
        measurements[name] = measurement
        
        logger.info("🚀 Started performance measurement: \(name)")
        return measurement
    }
    
    func endMeasurement(_ name: String) -> TimeInterval? {
        guard let measurement = measurements[name] else {
            logger.warning("⚠️ No measurement found for: \(name)")
            return nil
        }
        
        let duration = measurement.end()
        measurements.removeValue(forKey: name)
        
        // Check against budgets
        checkPerformanceBudget(name: name, duration: duration)
        
        logger.info("✅ Completed performance measurement: \(name) - \(String(format: "%.3f", duration))s")
        return duration
    }
    
    // MARK: - Budget Validation
    private func checkPerformanceBudget(name: String, duration: TimeInterval) {
        let budget = getBudgetForMeasurement(name)
        
        if duration > budget {
            let overage = duration - budget
            let percentage = (overage / budget) * 100
            
            logger.error("❌ Performance budget exceeded for \(name): \(String(format: "%.3f", duration))s (budget: \(String(format: "%.3f", budget))s, overage: +\(String(format: "%.1f", percentage))%)")
            
            // In debug builds, assert to catch performance regressions early
            #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil {
                assertionFailure("Performance budget exceeded for \(name)")
            }
            #endif
        } else {
            let remaining = budget - duration
            let percentage = (remaining / budget) * 100
            logger.info("✅ Performance budget met for \(name): \(String(format: "%.3f", duration))s (budget: \(String(format: "%.3f", budget))s, remaining: -\(String(format: "%.1f", percentage))%)")
        }
    }
    
    private func getBudgetForMeasurement(_ name: String) -> TimeInterval {
        switch name.lowercased() {
        case let n where n.contains("launch"):
            return PerformanceBudgets.AppLaunch.coldStartTime
        case let n where n.contains("transition"):
            return PerformanceBudgets.Transitions.screenTransitionTime
        case let n where n.contains("modal"):
            return PerformanceBudgets.Transitions.modalPresentationTime
        case let n where n.contains("tab"):
            return PerformanceBudgets.Transitions.tabSwitchTime
        case let n where n.contains("api") || n.contains("network"):
            return PerformanceBudgets.Network.apiResponseTime
        case let n where n.contains("image"):
            return PerformanceBudgets.Network.imageLoadTime
        case let n where n.contains("search"):
            return PerformanceBudgets.Network.searchResponseTime
        default:
            return 1.0 // Default 1 second budget
        }
    }
    
    // MARK: - Memory Monitoring
    func checkMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        
        if memoryUsage > PerformanceBudgets.Memory.maxMemoryUsage {
            logger.error("❌ Memory budget exceeded: \(memoryUsage / 1_000_000)MB (max: \(PerformanceBudgets.Memory.maxMemoryUsage / 1_000_000)MB)")
        } else if memoryUsage > PerformanceBudgets.Memory.memoryWarningThreshold {
            logger.warning("⚠️ Memory usage high: \(memoryUsage / 1_000_000)MB (warning threshold: \(PerformanceBudgets.Memory.memoryWarningThreshold / 1_000_000)MB)")
        } else {
            logger.info("✅ Memory usage normal: \(memoryUsage / 1_000_000)MB")
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - Performance Measurement
final class AppPerformanceMeasurement {
    let name: String
    private let startTime: CFAbsoluteTime
    private var endTime: CFAbsoluteTime?
    
    init(name: String) {
        self.name = name
        self.startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func end() -> TimeInterval {
        let currentTime = CFAbsoluteTimeGetCurrent()
        endTime = currentTime
        return currentTime - startTime
    }
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime - startTime
    }
}

// MARK: - Performance Measurement Extensions
extension View {
    func measurePerformance(_ name: String) -> some View {
        self.onAppear {
            PerformanceMonitor.shared.startMeasurement(name)
        }
        .onDisappear {
            PerformanceMonitor.shared.endMeasurement(name)
        }
    }
}

// MARK: - Performance Testing Helpers
#if DEBUG
extension PerformanceMonitor {
    func simulatePerformanceIssue(_ name: String, delay: TimeInterval) {
        let measurement = startMeasurement(name)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.endMeasurement(name)
        }
    }
    
    func runPerformanceTest(_ name: String, iterations: Int = 10, operation: @escaping () async -> Void) async {
        var durations: [TimeInterval] = []
        
        for i in 0..<iterations {
            let testName = "\(name)_iteration_\(i)"
            let measurement = startMeasurement(testName)
            
            await operation()
            
            if let duration = endMeasurement(testName) {
                durations.append(duration)
            }
        }
        
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let maxDuration = durations.max() ?? 0
        let minDuration = durations.min() ?? 0
        
        logger.info("📊 Performance test results for \(name):")
        logger.info("   Average: \(String(format: "%.3f", averageDuration))s")
        logger.info("   Min: \(String(format: "%.3f", minDuration))s")
        logger.info("   Max: \(String(format: "%.3f", maxDuration))s")
        logger.info("   Iterations: \(iterations)")
    }
}
#endif
