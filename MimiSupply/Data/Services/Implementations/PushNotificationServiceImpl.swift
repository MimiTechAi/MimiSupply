//
//  PushNotificationServiceImpl.swift
//  MimiSupply
//
//  Created by Kiro on 17.08.25.
//

import Foundation
@preconcurrency import UserNotifications
import CloudKit
import Combine
import UIKit

final class PushNotificationServiceImpl: NSObject, PushNotificationService {
    
    // MARK: - Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let cloudKitService: CloudKitService
    private let authenticationService: AuthenticationService
    private let subscriptions: [String: CKSubscription] = [:]
    
    // MARK: - Initialization
    init(
        cloudKitService: CloudKitService,
        authenticationService: AuthenticationService
    ) {
        self.cloudKitService = cloudKitService
        self.authenticationService = authenticationService
        super.init()
        setupNotificationDelegate()
    }
    
    // MARK: - PushNotificationService Implementation
    
    func requestPermission() async throws -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await setupNotificationCategories()
            }
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    func registerForRemoteNotifications() async throws {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    func unregisterFromRemoteNotifications() async {
        await UIApplication.shared.unregisterForRemoteNotifications()
    }
    
    func handleDeviceToken(_ deviceToken: Data) async {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
        
        // Store device token for the current user
        if let currentUser = await authenticationService.currentUser {
            do {
                try await cloudKitService.updateUserDeviceToken(currentUser.id, deviceToken: tokenString)
            } catch {
                print("Failed to update device token: \(error)")
            }
        }
    }
    
    func handleNotification(_ notification: UNNotification) async {
        print("Handling notification: \(notification.request.identifier)")
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("Received remote notification: \(userInfo)")
        
        // Handle CloudKit notifications
        if let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) {
            await handleCloudKitNotification(notification)
            return .newData
        }
        return .noData
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let identifier = response.actionIdentifier
        let notification = response.notification
        await handleNotificationResponse(identifier: identifier, notification: notification)
    }
    
    func scheduleLocalNotification(_ notification: LocalNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = notification.sound
        content.categoryIdentifier = notification.category.identifier
        if let badge = notification.badge { content.badge = NSNumber(value: badge) }

        // Map [String: Sendable] -> [AnyHashable: Any]
        var mappedUserInfo: [AnyHashable: Any] = [:]
        for (key, value) in notification.userInfo {
            mappedUserInfo[key] = value
        }
        content.userInfo = mappedUserInfo

        let trigger: UNNotificationTrigger
        if let date = notification.scheduledDate {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        } else {
            // Fire shortly after scheduling to present immediately
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        }

        let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
        try await notificationCenter.add(request)
    }
    
    func cancelLocalNotification(withId id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [id])
    }
    
    func cancelAllLocalNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    func setupCloudKitSubscriptions(for userRole: UserRole, userId: String) async throws {
        let database = CKContainer.default().privateCloudDatabase
        
        switch userRole {
        case .customer:
            try await setupCustomerSubscriptions(database: database, userId: userId)
        case .partner:
            try await setupPartnerSubscriptions(database: database, userId: userId)
        case .driver:
            try await setupDriverSubscriptions(database: database, userId: userId)
        case .admin:
            // Admin users currently don't require specific CK subscriptions
            break
        }
    }
    
    func removeCloudKitSubscriptions() async throws {
        let database = CKContainer.default().privateCloudDatabase
        let subscriptions = try await database.allSubscriptions()
        
        for subscription in subscriptions {
            try await database.deleteSubscription(withID: subscription.subscriptionID)
        }
    }
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) async {
        do {
            try await notificationCenter.setBadgeCount(count)
        } catch {
            print("Failed to set badge count: \(error)")
        }
    }
    
    func clearBadge() async {
        await updateBadgeCount(0)
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationDelegate() {
        notificationCenter.delegate = self
    }
    
    private func setupNotificationCategories() async {
        let categories = createNotificationCategories()
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    private func createNotificationCategories() -> [UNNotificationCategory] {
        return NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.identifier,
                actions: category.actions,
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        }
    }
    
    private func handleCloudKitNotification(_ notification: CKNotification) async {
        switch notification.notificationType {
        case .query:
            if let queryNotification = notification as? CKQueryNotification {
                await handleQueryNotification(queryNotification)
            }
        case .recordZone:
            if let recordZoneNotification = notification as? CKRecordZoneNotification {
                await handleRecordZoneNotification(recordZoneNotification)
            }
        case .database:
            if let databaseNotification = notification as? CKDatabaseNotification {
                await handleDatabaseNotification(databaseNotification)
            }
        case .readNotification:
            // Currently not used, but handled explicitly to avoid missing-case notes
            print("Received read notification")
        @unknown default:
            print("Unknown CloudKit notification type")
        }
    }
    
    private func handleQueryNotification(_ notification: CKQueryNotification) async {
        guard let recordID = notification.recordID else { return }
        
        // Handle different record types
        switch notification.recordFields?["recordType"] as? String {
        case "Order":
            await handleOrderNotification(recordID: recordID, reason: notification.queryNotificationReason)
        case "DeliveryJob":
            await handleDeliveryJobNotification(recordID: recordID, reason: notification.queryNotificationReason)
        default:
            print("Unhandled record type in query notification")
        }
    }
    
    private func handleRecordZoneNotification(_ notification: CKRecordZoneNotification) async {
        print("Received record zone notification: \(notification)")
    }
    
    private func handleDatabaseNotification(_ notification: CKDatabaseNotification) async {
        print("Received database notification: \(notification)")
    }
    
    private func handleOrderNotification(recordID: CKRecord.ID, reason: CKQueryNotification.Reason) async {
        switch reason {
        case .recordCreated:
            let notification = LocalNotification(
                id: "order_\(recordID.recordName)",
                title: "New Order",
                body: "You have received a new order",
                scheduledDate: nil,
                userInfo: ["recordId": recordID.recordName],
                category: .partnerOrder,
                sound: .default,
                badge: nil
            )
            try? await scheduleLocalNotification(notification)
        case .recordUpdated:
            let notification = LocalNotification(
                id: "order_update_\(recordID.recordName)",
                title: "Order Updated",
                body: "Your order status has been updated",
                scheduledDate: nil,
                userInfo: ["recordId": recordID.recordName],
                category: .orderUpdate,
                sound: .default,
                badge: nil
            )
            try? await scheduleLocalNotification(notification)
        case .recordDeleted:
            await cancelLocalNotification(withId: "order_\(recordID.recordName)")
        @unknown default:
            print("Unknown query notification reason")
        }
    }
    
    private func handleDeliveryJobNotification(recordID: CKRecord.ID, reason: CKQueryNotification.Reason) async {
        switch reason {
        case .recordCreated:
            let notification = LocalNotification(
                id: "job_\(recordID.recordName)",
                title: "New Delivery Job",
                body: "A new delivery job is available",
                scheduledDate: nil,
                userInfo: ["recordId": recordID.recordName],
                category: .driverJob,
                sound: .default,
                badge: nil
            )
            try? await scheduleLocalNotification(notification)
        case .recordUpdated:
            let notification = LocalNotification(
                id: "job_update_\(recordID.recordName)",
                title: "Job Updated",
                body: "Delivery job status has been updated",
                scheduledDate: nil,
                userInfo: ["recordId": recordID.recordName],
                category: .deliveryUpdate,
                sound: .default,
                badge: nil
            )
            try? await scheduleLocalNotification(notification)
        case .recordDeleted:
            await cancelLocalNotification(withId: "job_\(recordID.recordName)")
        @unknown default:
            print("Unknown query notification reason")
        }
    }
    
    private func setupCustomerSubscriptions(database: CKDatabase, userId: String) async throws {
        // Subscribe to order updates for this customer
        let predicate = NSPredicate(format: "customerId == %@", userId)
        let subscription = CKQuerySubscription(
            recordType: "Order",
            predicate: predicate,
            subscriptionID: "customer_order_updates_\(userId)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Your order has been updated"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        try await database.save(subscription)
    }
    
    private func setupPartnerSubscriptions(database: CKDatabase, userId: String) async throws {
        // Subscribe to new orders for this partner
        let predicate = NSPredicate(format: "partnerId == %@", userId)
        let subscription = CKQuerySubscription(
            recordType: "Order",
            predicate: predicate,
            subscriptionID: "partner_order_updates_\(userId)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "You have a new order"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        try await database.save(subscription)
    }
    
    private func setupDriverSubscriptions(database: CKDatabase, userId: String) async throws {
        // Subscribe to delivery jobs in driver's area
        let subscription = CKQuerySubscription(
            recordType: "DeliveryJob",
            predicate: NSPredicate(format: "status == %@", "available"),
            subscriptionID: "driver_jobs_available_\(userId)",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New delivery job available"
        notificationInfo.shouldBadge = true
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        try await database.save(subscription)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationServiceImpl: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.actionIdentifier
        let notification = response.notification
        
        Task {
            await handleNotificationResponse(identifier: identifier, notification: notification)
            completionHandler()
        }
    }
    
    private func handleNotificationResponse(identifier: String, notification: UNNotification) async {
        switch identifier {
        case "ACCEPT_ORDER":
            await handleAcceptOrder(notification)
        case "DECLINE_ORDER":
            await handleDeclineOrder(notification)
        case UNNotificationDefaultActionIdentifier:
            await handleDefaultAction(notification)
        default:
            print("Unknown notification action: \(identifier)")
        }
    }
    
    private func handleAcceptOrder(_ notification: UNNotification) async {
        // Extract order ID from notification
        if let orderId = notification.request.content.userInfo["orderId"] as? String {
            do {
                try await cloudKitService.updateOrderStatus(orderId, status: .confirmed)
            } catch {
                print("Failed to accept order: \(error)")
            }
        }
    }
    
    private func handleDeclineOrder(_ notification: UNNotification) async {
        // Extract order ID from notification
        if let orderId = notification.request.content.userInfo["orderId"] as? String {
            do {
                try await cloudKitService.updateOrderStatus(orderId, status: .cancelled)
            } catch {
                print("Failed to decline order: \(error)")
            }
        }
    }
    
    private func handleDefaultAction(_ notification: UNNotification) async {
        // Handle tapping on notification (open relevant screen)
        print("User tapped notification: \(notification.request.identifier)")
    }
}