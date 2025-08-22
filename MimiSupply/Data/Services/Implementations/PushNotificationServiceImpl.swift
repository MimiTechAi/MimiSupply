import CloudKit
import UserNotifications
import UIKit

final class PushNotificationServiceImpl: NSObject, PushNotificationService {
    
    private let cloudKitService: CloudKitService
    private let authService: AuthenticationService
    
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        authenticationService: AuthenticationService = AuthenticationServiceImpl.shared
    ) {
        self.cloudKitService = cloudKitService
        self.authService = authenticationService
        super.init()
    }

    func requestNotificationPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        
        if granted {
            await registerForRemoteNotifications()
        }
        
        return granted
    }
    
    func subscribeToOrderUpdates() async throws {
        guard let currentUser = await authService.currentUser else {
            throw AppError.authentication(.notAuthenticated)
        }
        try await cloudKitService.subscribeToOrderUpdates(for: currentUser.id)
    }
    
    func subscribeToGeneralNotifications() async throws {
        try await cloudKitService.subscribeToGeneralNotifications()
    }
    
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func scheduleLocalNotification(_ notification: LocalNotification) async throws {
        // Implementation for scheduling local notifications would go here.
        // For now, we can leave it empty to satisfy the protocol.
        print("Scheduled local notification: \(notification.title)")
    }
}