import Foundation
import UIKit
import SwiftUI
import os.log

/// Memory management and leak detection system
@MainActor
class MemoryManager: ObservableObject {
    @MainActor
    static let shared = MemoryManager()
    
    @Published var currentMemoryUsage: Double = 0
    @Published var memoryWarningLevel: MemoryWarningLevel = .normal
    
    private let logger = Logger(subsystem: "com.mimisupply.app", category: "MemoryManager")
    private var memoryTimer: Timer?
    private var weakReferences: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    
    enum MemoryWarningLevel {
        case normal
        case warning
        case critical
        
        var threshold: Double {
            switch self {
            case .normal: return 100 // 100MB
            case .warning: return 200 // 200MB
            case .critical: return 300 // 300MB
            }
        }
    }
    
    private init() {
        startMemoryMonitoring()
        setupMemoryWarningNotifications()
    }
    
    deinit {
        stopMemoryMonitoring()
    }
    
    // MARK: - Memory Monitoring
    
    private func startMemoryMonitoring() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
    }
    
    private func stopMemoryMonitoring() {
        memoryTimer?.invalidate()
        memoryTimer = nil
    }
    
    private func updateMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        
        DispatchQueue.main.async {
            self.currentMemoryUsage = usage
            self.updateMemoryWarningLevel(usage)
        }
        
        if usage > MemoryWarningLevel.warning.threshold {
            logger.warning("High memory usage detected: \(usage, privacy: .public)MB")
            
            if usage > MemoryWarningLevel.critical.threshold {
                performEmergencyCleanup()
            }
        }
    }
    
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        
        return 0
    }
    
    private func updateMemoryWarningLevel(_ usage: Double) {
        let newLevel: MemoryWarningLevel
        
        if usage > MemoryWarningLevel.critical.threshold {
            newLevel = .critical
        } else if usage > MemoryWarningLevel.warning.threshold {
            newLevel = .warning
        } else {
            newLevel = .normal
        }
        
        if newLevel != memoryWarningLevel {
            memoryWarningLevel = newLevel
            handleMemoryWarningLevelChange(newLevel)
        }
    }
    
    private func handleMemoryWarningLevelChange(_ level: MemoryWarningLevel) {
        switch level {
        case .normal:
            logger.info("Memory usage returned to normal")
        case .warning:
            logger.warning("Memory usage warning - performing cleanup")
            performMemoryCleanup()
        case .critical:
            logger.error("Critical memory usage - performing emergency cleanup")
            performEmergencyCleanup()
        }
    }
    
    // MARK: - Memory Warning Notifications
    
    private func setupMemoryWarningNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        logger.warning("System memory warning received")
        performEmergencyCleanup()
    }
    
    // MARK: - Memory Cleanup
    
    private func performMemoryCleanup() {
        Task {
            // Clear image cache
            await ImageCache.shared.clearMemoryCache()
            
            // Force garbage collection
            autoreleasepool {
                // Trigger autorelease pool drain
            }
            
            logger.info("Memory cleanup completed")
        }
    }
    
    private func performEmergencyCleanup() {
        Task {
            // Clear all caches
            await ImageCache.shared.clearCache()
            
            // Clear URL cache
            URLCache.shared.removeAllCachedResponses()
            
            // Clear any other caches
            clearApplicationCaches()
            
            // Force garbage collection
            autoreleasepool {
                // Trigger autorelease pool drain
            }
            
            logger.info("Emergency memory cleanup completed")
        }
    }
    
    private func clearApplicationCaches() {
        // Clear NSCache instances
        NotificationCenter.default.post(name: .clearCaches, object: nil)
    }
    
    // MARK: - Leak Detection
    
    func trackObject<T: AnyObject>(_ object: T) {
        weakReferences.add(object)
    }
    
    func checkForLeaks() {
        let aliveObjects = weakReferences.allObjects
        logger.info("Tracked objects still alive: \(aliveObjects.count)")
        
        // Log details about alive objects for debugging
        for object in aliveObjects {
            logger.debug("Alive object: \(String(describing: type(of: object)))")
        }
    }
    
    func performLeakDetection() {
        // Force garbage collection
        autoreleasepool {
            // Trigger autorelease pool drain
        }
        
        // Check after a delay to allow cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.checkForLeaks()
        }
    }
    
    // MARK: - Memory Profiling
    
    func getDetailedMemoryInfo() -> MemoryInfo {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return MemoryInfo(
                residentSize: Double(info.resident_size) / (1024 * 1024),
                virtualSize: Double(info.virtual_size) / (1024 * 1024),
                maxResidentSize: Double(info.resident_size_max) / (1024 * 1024)
            )
        }
        
        return MemoryInfo(residentSize: 0, virtualSize: 0, maxResidentSize: 0)
    }
}

// MARK: - Memory Info
struct MemoryInfo {
    let residentSize: Double // MB
    let virtualSize: Double // MB
    let maxResidentSize: Double // MB
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let clearCaches = Notification.Name("clearCaches")
    static let memoryWarning = Notification.Name("memoryWarning")
}

// MARK: - Memory Efficient View Modifier
struct MemoryEfficientModifier: ViewModifier {
    @StateObject private var memoryManager = MemoryManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Memory tracking not needed for struct-based view modifiers
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearCaches)) { _ in
                // Handle cache clearing if needed
            }
    }
}

extension View {
    func memoryEfficient() -> some View {
        modifier(MemoryEfficientModifier())
    }
}