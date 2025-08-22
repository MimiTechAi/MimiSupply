import Foundation

protocol PushNotificationService {
    func requestNotificationPermission() async throws -> Bool
    func subscribeToOrderUpdates() async throws
    func subscribeToGeneralNotifications() async throws
    func registerForRemoteNotifications() async
    func scheduleLocalNotification(_ notification: LocalNotification) async throws
}