//
//  PushNotificationExampleUsage.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation
import UserNotifications
import SwiftUI

/// Example usage and integration patterns for the push notification system
/// This file demonstrates how to integrate push notifications throughout the app
class PushNotificationExampleUsage {
    
    private let pushNotificationService: PushNotificationService
    private let authenticationService: AuthenticationService
    
    init(
        pushNotificationService: PushNotificationService,
        authenticationService: AuthenticationService
    ) {
        self.pushNotificationService = pushNotificationService
        self.authenticationService = authenticationService
    }
    
    // MARK: - App Lifecycle Integration
    
    /// Call this when the app launches to setup push notifications
    func setupPushNotificationsOnAppLaunch() async {
        do {
            // Request permission on first launch
            let granted = try await pushNotificationService.requestPermission()
            
            if granted {
                // Register for remote notifications
                try await pushNotificationService.registerForRemoteNotifications()
                
                // Setup CloudKit subscriptions if user is authenticated
                if let currentUser = await authenticationService.currentUser {
                    try await pushNotificationService.setupCloudKitSubscriptions(
                        for: currentUser.role,
                        userId: currentUser.id
                    )
                }
            }
        } catch {
            print("Failed to setup push notifications: \(error)")
        }
    }
    
    /// Call this when user signs in to setup role-specific subscriptions
    func setupNotificationsAfterSignIn(user: UserProfile) async {
        do {
            try await pushNotificationService.setupCloudKitSubscriptions(
                for: user.role,
                userId: user.id
            )
        } catch {
            print("Failed to setup user-specific notifications: \(error)")
        }
    }
    
    /// Call this when user signs out to clean up subscriptions
    func cleanupNotificationsAfterSignOut() async {
        do {
            try await pushNotificationService.removeCloudKitSubscriptions()
            await pushNotificationService.clearBadge()
        } catch {
            print("Failed to cleanup notifications: \(error)")
        }
    }
    
    // MARK: - Customer Notification Examples
    
    /// Schedule order confirmation notification
    func scheduleOrderConfirmationNotification(for order: Order) async {
        let notification = LocalNotification(
            title: "Order Confirmed! 🎉",
            body: "Your order from \(order.partnerId) has been confirmed and is being prepared.",
            userInfo: [
                "type": NotificationType.orderConfirmed.rawValue,
                "orderId": order.id,
                "partnerId": order.partnerId
            ],
            category: .orderUpdate,
            badge: 1
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule order confirmation notification: \(error)")
        }
    }
    
    /// Schedule delivery ETA notification
    func scheduleDeliveryETANotification(orderId: String, eta: Date, driverName: String) async {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let etaString = formatter.string(from: eta)
        
        let notification = LocalNotification(
            title: "Your order is on the way! 🚗",
            body: "\(driverName) will deliver your order by \(etaString)",
            scheduledDate: eta.addingTimeInterval(-300), // 5 minutes before ETA
            userInfo: [
                "type": NotificationType.orderPickedUp.rawValue,
                "orderId": orderId,
                "eta": eta.timeIntervalSince1970
            ],
            category: .deliveryUpdate
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule ETA notification: \(error)")
        }
    }
    
    // MARK: - Driver Notification Examples
    
    /// Schedule new job available notification
    func scheduleNewJobNotification(jobId: String, estimatedEarnings: Int, distance: Double) async {
        let earningsFormatted = String(format: "$%.2f", Double(estimatedEarnings) / 100.0)
        let distanceFormatted = String(format: "%.1f mi", distance)
        
        let notification = LocalNotification(
            title: "New Job Available! 💰",
            body: "Earn \(earningsFormatted) • \(distanceFormatted) away",
            userInfo: [
                "type": NotificationType.newJobAvailable.rawValue,
                "jobId": jobId,
                "estimatedEarnings": estimatedEarnings,
                "distance": distance
            ],
            category: .driverJob,
            sound: .defaultCriticalSound(withAudioVolume: 1.0) // Use critical sound for time-sensitive jobs
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule job notification: \(error)")
        }
    }
    
    /// Schedule order ready for pickup notification
    func scheduleOrderReadyNotification(orderId: String, partnerName: String, address: String) async {
        let notification = LocalNotification(
            title: "Order Ready for Pickup! 📦",
            body: "Pick up order at \(partnerName) - \(address)",
            userInfo: [
                "type": NotificationType.orderReady.rawValue,
                "orderId": orderId,
                "partnerName": partnerName,
                "address": address
            ],
            category: .driverJob
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule pickup notification: \(error)")
        }
    }
    
    // MARK: - Partner Notification Examples
    
    /// Schedule new order notification for partners
    func scheduleNewOrderNotificationForPartner(order: Order, customerName: String?) async {
        let customerInfo = customerName ?? "Customer"
        let totalFormatted = order.formattedTotal
        
        let notification = LocalNotification(
            title: "New Order! 🛍️",
            body: "\(customerInfo) placed an order for \(totalFormatted)",
            userInfo: [
                "type": NotificationType.newOrder.rawValue,
                "orderId": order.id,
                "customerId": order.customerId,
                "totalAmount": order.totalCents
            ],
            category: .partnerOrder,
            badge: 1
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule partner order notification: \(error)")
        }
    }
    
    /// Schedule driver arrival notification for partners
    func scheduleDriverArrivalNotification(orderId: String, driverName: String) async {
        let notification = LocalNotification(
            title: "Driver Arrived! 🚗",
            body: "\(driverName) is here to pick up order #\(orderId.prefix(8))",
            userInfo: [
                "type": NotificationType.driverArrived.rawValue,
                "orderId": orderId,
                "driverName": driverName
            ],
            category: .partnerOrder
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule driver arrival notification: \(error)")
        }
    }
    
    // MARK: - System Notification Examples
    
    /// Schedule maintenance notification
    func scheduleMaintenanceNotification(startTime: Date, duration: TimeInterval) async {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        let startString = formatter.string(from: startTime)
        let endTime = startTime.addingTimeInterval(duration)
        let endString = formatter.string(from: endTime)
        
        let notification = LocalNotification(
            title: "Scheduled Maintenance 🔧",
            body: "Service will be unavailable from \(startString) to \(endString)",
            scheduledDate: startTime.addingTimeInterval(-3600), // 1 hour before
            userInfo: [
                "type": NotificationType.systemMaintenance.rawValue,
                "startTime": startTime.timeIntervalSince1970,
                "duration": duration
            ],
            category: .general
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule maintenance notification: \(error)")
        }
    }
    
    /// Schedule promotional notification
    func schedulePromotionalNotification(title: String, message: String, promoCode: String?) async {
        var userInfo: [String: Sendable] = [
            "type": NotificationType.promotionalOffer.rawValue
        ]
        
        if let promoCode = promoCode {
            userInfo["promoCode"] = promoCode
        }
        
        let notification = LocalNotification(
            title: title,
            body: message,
            userInfo: userInfo,
            category: .general
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule promotional notification: \(error)")
        }
    }
    
    // MARK: - Badge Management Examples
    
    /// Update badge count based on user role and pending items
    func updateBadgeCount() async {
        guard let currentUser = await authenticationService.currentUser else {
            await pushNotificationService.clearBadge()
            return
        }
        
        var badgeCount = 0
        
        switch currentUser.role {
        case .customer:
            // Badge count for customers: active orders
            // This would typically fetch from your data source
            badgeCount = 0 // Placeholder
            
        case .driver:
            // Badge count for drivers: available jobs + active deliveries
            badgeCount = 0 // Placeholder
            
        case .partner:
            // Badge count for partners: pending orders
            badgeCount = 0 // Placeholder
            
        case .admin:
            // Badge count for admins: system alerts
            badgeCount = 0 // Placeholder
        }
        
        await pushNotificationService.updateBadgeCount(badgeCount)
    }
    
    // MARK: - Notification Response Handling
    
    /// Handle notification responses and navigate appropriately
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        await pushNotificationService.handleNotificationResponse(response)
        
        // Additional app-specific handling can be done here
        let userInfo = response.notification.request.content.userInfo
        
        if let typeString = userInfo["type"] as? String,
           let notificationType = NotificationType(rawValue: typeString) {
            
            switch notificationType {
            case .orderConfirmed, .orderDelivered:
                // Navigate to order tracking
                if let orderId = userInfo["orderId"] as? String {
                    await navigateToOrderTracking(orderId: orderId)
                }
                
            case .newJobAvailable:
                // Navigate to driver dashboard
                await navigateToDriverDashboard()
                
            case .newOrder:
                // Navigate to partner dashboard
                await navigateToPartnerDashboard()
                
            default:
                break
            }
        }
    }
    
    // MARK: - Navigation Helpers (would be implemented in your navigation system)
    
    private func navigateToOrderTracking(orderId: String) async {
        // Implementation would depend on your navigation system
        print("Navigate to order tracking for order: \(orderId)")
    }
    
    private func navigateToDriverDashboard() async {
        // Implementation would depend on your navigation system
        print("Navigate to driver dashboard")
    }
    
    private func navigateToPartnerDashboard() async {
        // Implementation would depend on your navigation system
        print("Navigate to partner dashboard")
    }
}

// MARK: - SwiftUI Integration Example

/// Example SwiftUI view showing how to integrate push notifications
struct PushNotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var orderUpdatesEnabled = true
    @State private var promotionalEnabled = false
    
    private let pushNotificationService: PushNotificationService
    
    init(pushNotificationService: PushNotificationService) {
        self.pushNotificationService = pushNotificationService
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notification Permissions") {
                    HStack {
                        Text("Push Notifications")
                        Spacer()
                        if notificationsEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Enable") {
                                Task {
                                    await requestNotificationPermission()
                                }
                            }
                        }
                    }
                }
                
                Section("Notification Types") {
                    Toggle("Order Updates", isOn: $orderUpdatesEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Promotional Offers", isOn: $promotionalEnabled)
                        .disabled(!notificationsEnabled)
                }
                
                Section("Actions") {
                    Button("Test Notification") {
                        Task {
                            await scheduleTestNotification()
                        }
                    }
                    .disabled(!notificationsEnabled)
                    
                    Button("Clear Badge") {
                        Task {
                            await pushNotificationService.clearBadge()
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .task {
                await checkNotificationStatus()
            }
        }
    }
    
    private func checkNotificationStatus() async {
        let status = await pushNotificationService.getAuthorizationStatus()
        notificationsEnabled = status == .authorized
    }
    
    private func requestNotificationPermission() async {
        do {
            let granted = try await pushNotificationService.requestPermission()
            notificationsEnabled = granted
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func scheduleTestNotification() async {
        let notification = LocalNotification(
            title: "Test Notification",
            body: "This is a test notification from MimiSupply",
            category: .general
        )
        
        do {
            try await pushNotificationService.scheduleLocalNotification(notification)
        } catch {
            print("Failed to schedule test notification: \(error)")
        }
    }
}