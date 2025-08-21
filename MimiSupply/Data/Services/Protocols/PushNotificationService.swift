//
//  PushNotificationService.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

@preconcurrency import Foundation
@preconcurrency import UserNotifications
import CloudKit
import UIKit

/// Push notification service protocol for managing notifications
protocol PushNotificationService: Sendable {
    // MARK: - Permission Management
    func requestPermission() async throws -> Bool
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    
    // MARK: - Registration
    func registerForRemoteNotifications() async throws
    func unregisterFromRemoteNotifications() async
    
    // MARK: - Notification Handling
    func handleNotification(_ notification: UNNotification) async
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult
    func handleNotificationResponse(_ response: UNNotificationResponse) async
    
    // MARK: - Local Notifications
    func scheduleLocalNotification(_ notification: LocalNotification) async throws
    func cancelLocalNotification(withId id: String) async
    func cancelAllLocalNotifications() async
    
    // MARK: - CloudKit Subscriptions
    func setupCloudKitSubscriptions(for userRole: UserRole, userId: String) async throws
    func removeCloudKitSubscriptions() async throws
    
    // MARK: - Badge Management
    func updateBadgeCount(_ count: Int) async
    func clearBadge() async
}

// Note: LocalNotification unified model defined below

/// Notification categories for different user roles and actions
enum NotificationCategory: String, CaseIterable {
    case orderUpdate = "ORDER_UPDATE"
    case driverAssignment = "DRIVER_ASSIGNMENT"
    case deliveryUpdate = "DELIVERY_UPDATE"
    case partnerOrder = "PARTNER_ORDER"
    case driverJob = "DRIVER_JOB"
    case general = "GENERAL"
    
    var identifier: String { rawValue }
    
    var actions: [UNNotificationAction] {
        switch self {
        case .orderUpdate:
            return [
                UNNotificationAction(
                    identifier: "VIEW_ORDER",
                    title: "View Order",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "TRACK_ORDER",
                    title: "Track",
                    options: [.foreground]
                )
            ]
        case .driverAssignment:
            return [
                UNNotificationAction(
                    identifier: "VIEW_DRIVER",
                    title: "View Driver",
                    options: [.foreground]
                )
            ]
        case .deliveryUpdate:
            return [
                UNNotificationAction(
                    identifier: "TRACK_DELIVERY",
                    title: "Track",
                    options: [.foreground]
                )
            ]
        case .partnerOrder:
            return [
                UNNotificationAction(
                    identifier: "ACCEPT_ORDER",
                    title: "Accept",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "VIEW_ORDER_DETAILS",
                    title: "View Details",
                    options: [.foreground]
                )
            ]
        case .driverJob:
            return [
                UNNotificationAction(
                    identifier: "ACCEPT_JOB",
                    title: "Accept",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "VIEW_JOB_DETAILS",
                    title: "View Details",
                    options: [.foreground]
                )
            ]
        case .general:
            return []
        }
    }
}

/// Notification types for different events
enum NotificationType: String, Sendable {
    // Customer notifications
    case orderConfirmed = "order_confirmed"
    case driverAssigned = "driver_assigned"
    case orderPickedUp = "order_picked_up"
    case orderDelivered = "order_delivered"
    case orderCancelled = "order_cancelled"
    
    // Driver notifications
    case newJobAvailable = "new_job_available"
    case jobAssigned = "job_assigned"
    case orderReady = "order_ready"
    
    // Partner notifications
    case newOrder = "new_order"
    case orderCancellation = "order_cancellation"
    case driverArrived = "driver_arrived"
    
    // General notifications
    case systemMaintenance = "system_maintenance"
    case promotionalOffer = "promotional_offer"
    
    var category: NotificationCategory {
        switch self {
        case .orderConfirmed, .orderDelivered, .orderCancelled:
            return .orderUpdate
        case .driverAssigned:
            return .driverAssignment
        case .orderPickedUp:
            return .deliveryUpdate
        case .newJobAvailable, .jobAssigned, .orderReady:
            return .driverJob
        case .newOrder, .orderCancellation, .driverArrived:
            return .partnerOrder
        case .systemMaintenance, .promotionalOffer:
            return .general
        }
    }
}

/// Local notification model
struct LocalNotification: Sendable {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date?
    let userInfo: [String: Sendable]
    let category: NotificationCategory
    let sound: UNNotificationSound
    let badge: Int?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        body: String,
        scheduledDate: Date? = nil,
        userInfo: [String: Sendable] = [:],
        category: NotificationCategory = .general,
        sound: UNNotificationSound = .default,
        badge: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.userInfo = userInfo
        self.category = category
        self.sound = sound
        self.badge = badge
    }
}

/// CloudKit subscription configuration
struct CloudKitSubscriptionConfig {
    let subscriptionId: String
    let recordType: String
    let predicate: NSPredicate
    let notificationInfo: CKSubscription.NotificationInfo
    
    init(
        subscriptionId: String,
        recordType: String,
        predicate: NSPredicate,
        title: String? = nil,
        body: String? = nil,
        category: String? = nil
    ) {
        self.subscriptionId = subscriptionId
        self.recordType = recordType
        self.predicate = predicate
        
        let info = CKSubscription.NotificationInfo()
        info.titleLocalizationKey = title
        info.subtitleLocalizationKey = body
        info.category = category
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        self.notificationInfo = info
    }
}