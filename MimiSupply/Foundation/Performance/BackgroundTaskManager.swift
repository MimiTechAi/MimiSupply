import Foundation
import BackgroundTasks
import CoreLocation
import CloudKit
import UIKit

/// Manages background tasks for location updates and data synchronization
class BackgroundTaskManager: NSObject, ObservableObject {
    static let shared = BackgroundTaskManager()
    
    // Background task identifiers
    private enum TaskIdentifier {
        static let locationUpdate = "com.mimisupply.location-update"
        static let dataSync = "com.mimisupply.data-sync"
        static let cleanup = "com.mimisupply.cleanup"
    }
    
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private let locationService: LocationService
    private let cloudKitService: CloudKitService
    
    override init() {
        self.locationService = LocationServiceImpl.shared
        self.cloudKitService = CloudKitServiceImpl.shared
        super.init()
        registerBackgroundTasks()
    }
    
    // MARK: - Background Task Registration
    
    private func registerBackgroundTasks() {
        // On iOS 17+, SwiftUI `.backgroundTask` in `MimiSupplyApp` registers handlers.
        // Keep explicit registration only for iOS < 17 to avoid duplicate registrations.
        if #available(iOS 17.0, *) {
            return
        }
        
        // Register location update task (iOS < 17)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.locationUpdate,
            using: nil
        ) { task in
            self.handleLocationUpdateTask(task as! BGAppRefreshTask)
        }
        
        // Register data sync task (iOS < 17)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.dataSync,
            using: nil
        ) { task in
            self.handleDataSyncTask(task as! BGAppRefreshTask)
        }
        
        // Register cleanup task (iOS < 17)
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskIdentifier.cleanup,
            using: nil
        ) { task in
            self.handleCleanupTask(task as! BGProcessingTask)
        }
    }
    
    // MARK: - Task Scheduling
    
    func scheduleLocationUpdate() {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.locationUpdate)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 10) // 10 seconds from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Location update task scheduled")
        } catch {
            print("❌ Failed to schedule location update task: \(error)")
        }
    }
    
    func scheduleDataSync() {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.dataSync)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60) // 1 minute from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Data sync task scheduled")
        } catch {
            print("❌ Failed to schedule data sync task: \(error)")
        }
    }
    
    func scheduleCleanup() {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.cleanup)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // 1 hour from now
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Cleanup task scheduled")
        } catch {
            print("❌ Failed to schedule cleanup task: \(error)")
        }
    }
    
    // MARK: - Task Handlers
    
    private func handleLocationUpdateTask(_ task: BGAppRefreshTask) {
        print("🔄 Handling location update background task")
        
        // Schedule next location update
        scheduleLocationUpdate()
        
        task.expirationHandler = {
            print("⏰ Location update task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Update driver location if user is a driver and online
                if await shouldUpdateDriverLocation() {
                    try await updateDriverLocation()
                }
                
                task.setTaskCompleted(success: true)
                print("✅ Location update task completed successfully")
            } catch {
                print("❌ Location update task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func handleDataSyncTask(_ task: BGAppRefreshTask) {
        print("🔄 Handling data sync background task")
        
        // Schedule next data sync
        scheduleDataSync()
        
        task.expirationHandler = {
            print("⏰ Data sync task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Sync pending data
                try await syncPendingData()
                
                task.setTaskCompleted(success: true)
                print("✅ Data sync task completed successfully")
            } catch {
                print("❌ Data sync task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func handleCleanupTask(_ task: BGProcessingTask) {
        print("🔄 Handling cleanup background task")
        
        // Schedule next cleanup
        scheduleCleanup()
        
        task.expirationHandler = {
            print("⏰ Cleanup task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Perform cleanup operations
                await performCleanup()
                
                task.setTaskCompleted(success: true)
                print("✅ Cleanup task completed successfully")
            } catch {
                print("❌ Cleanup task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // MARK: - Background Operations
    
    private func shouldUpdateDriverLocation() async -> Bool {
        // Check if user is a driver and is currently online
        guard let userProfile = await AuthenticationServiceImpl.shared.currentUser,
              userProfile.role == .driver else {
            return false
        }
        
        // Additional checks for driver status could be added here
        return true
    }
    
    func updateDriverLocation() async throws {
        // Ensure current user is a driver before updating location
        guard let userProfile = await AuthenticationServiceImpl.shared.currentUser,
              userProfile.role == .driver else {
            return
        }
        guard let location = await locationService.currentLocation else {
            throw LocationError.locationUnavailable
        }
        
        // Update driver location in CloudKit
        let driverLocation = DriverLocation(
            driverId: userProfile.id,
            location: Coordinate(location.coordinate),
            heading: location.course >= 0 ? location.course : nil,
            speed: location.speed >= 0 ? location.speed : nil,
            accuracy: location.horizontalAccuracy,
            timestamp: Date()
        )
        
        try await cloudKitService.saveDriverLocation(driverLocation)
    }
    
    func syncPendingData() async throws {
        // Sync any pending orders, status updates, etc.
        await OfflineManager.shared.forceSyncNow()
        
        // Clear old cached data
        await ImageCache.shared.clearMemoryCache()
    }
    
    func performCleanup() async {
        // Clean up old cached images
        let imageCache = await ImageCache.shared
        await imageCache.clearCache()
        
        // Clean up old log files
        cleanupLogFiles()
        
        // Clean up temporary files
        cleanupTemporaryFiles()
    }
    
    private func cleanupLogFiles() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logsDirectory = documentsDirectory.appendingPathComponent("Logs")
        
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logsDirectory, includingPropertiesForKeys: [.creationDateKey])
            let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
            
            for logFile in logFiles {
                if let creationDate = try logFile.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: logFile)
                }
            }
        } catch {
            print("Failed to cleanup log files: \(error)")
        }
    }
    
    private func cleanupTemporaryFiles() {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        
        do {
            let tempFiles = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: [.creationDateKey])
            let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
            
            for tempFile in tempFiles {
                if let creationDate = try tempFile.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < cutoffDate {
                    try fileManager.removeItem(at: tempFile)
                }
            }
        } catch {
            print("Failed to cleanup temporary files: \(error)")
        }
    }
    
    // MARK: - Foreground Background Task
    
    func beginBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}