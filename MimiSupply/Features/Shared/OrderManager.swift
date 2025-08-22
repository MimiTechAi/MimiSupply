//
//  OrderManager.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import Combine
import CloudKit

/// Centralized business logic manager for order lifecycle and operations
@MainActor
final class OrderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeOrders: [Order] = []
    @Published var isProcessing: Bool = false
    
    // MARK: - Services
    private let orderRepository: OrderRepository
    private let driverService: DriverService
    private let paymentService: PaymentService
    private let cloudKitService: CloudKitService
    private let pushNotificationService: PushNotificationService
    private let locationService: LocationService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let orderStatusTransitions: [OrderStatus: [OrderStatus]]
    
    // MARK: - Initialization
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        locationService: LocationService? = nil
    ) {
        self.cloudKitService = cloudKitService
        self.locationService = locationService ?? LocationServiceImpl.shared
    }
    
    // MARK: - Public Methods
    
    // MARK: - Order Creation & Management
    
    /// Creates a new order and processes payment
    func createOrder(_ order: Order) async throws -> Order {
        guard !isProcessing else {
            throw AppError.validation(.requiredFieldMissing("Order processing in progress"))
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Validate order
            try validateOrder(order)
            
            // Process payment
            let _ = try await paymentService.processPayment(for: order)
            
            // Create order with payment confirmation
            var confirmedOrder = order
            confirmedOrder = Order(
                id: order.id,
                customerId: order.customerId,
                partnerId: order.partnerId,
                driverId: nil,
                items: order.items,
                status: .paymentConfirmed,
                subtotalCents: order.subtotalCents,
                deliveryFeeCents: order.deliveryFeeCents,
                platformFeeCents: order.platformFeeCents,
                taxCents: order.taxCents,
                tipCents: order.tipCents,
                deliveryAddress: order.deliveryAddress,
                deliveryInstructions: order.deliveryInstructions,
                estimatedDeliveryTime: order.estimatedDeliveryTime,
                actualDeliveryTime: nil,
                paymentMethod: order.paymentMethod,
                paymentStatus: .completed,
                createdAt: order.createdAt,
                updatedAt: Date()
            )
            
            // Save to repository
            let savedOrder = try await orderRepository.createOrder(confirmedOrder)
            
            // Add to active orders
            activeOrders.append(savedOrder)
            
            // Start driver assignment process
            Task {
                await attemptDriverAssignment(for: savedOrder)
            }
            
            // Send confirmation notification
            await sendOrderConfirmation(savedOrder)
            
            return savedOrder
            
        } catch {
            throw handleOrderError(error)
        }
    }
    
    /// Updates order status with business logic validation
    func updateOrderStatus(_ orderId: String, to newStatus: OrderStatus) async throws {
        guard let orderIndex = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw AppError.validation(.orderNotFound)
        }
        
        let currentOrder = activeOrders[orderIndex]
        
        // Validate status transition
        guard canTransitionOrder(from: currentOrder.status, to: newStatus) else {
            throw AppError.validation(.invalidFormat("Cannot transition from \(currentOrder.status.displayName) to \(newStatus.displayName)"))
        }
        
        // Update order status in repository
        try await orderRepository.updateOrderStatus(orderId, status: newStatus)
        
        // Update local state
        var updatedOrder = currentOrder
        updatedOrder = Order(
            id: currentOrder.id,
            customerId: currentOrder.customerId,
            partnerId: currentOrder.partnerId,
            driverId: currentOrder.driverId,
            items: currentOrder.items,
            status: newStatus,
            subtotalCents: currentOrder.subtotalCents,
            deliveryFeeCents: currentOrder.deliveryFeeCents,
            platformFeeCents: currentOrder.platformFeeCents,
            taxCents: currentOrder.taxCents,
            tipCents: currentOrder.tipCents,
            deliveryAddress: currentOrder.deliveryAddress,
            deliveryInstructions: currentOrder.deliveryInstructions,
            estimatedDeliveryTime: currentOrder.estimatedDeliveryTime,
            actualDeliveryTime: newStatus == .delivered ? Date() : currentOrder.actualDeliveryTime,
            paymentMethod: currentOrder.paymentMethod,
            paymentStatus: currentOrder.paymentStatus,
            createdAt: currentOrder.createdAt,
            updatedAt: Date()
        )
        
        activeOrders[orderIndex] = updatedOrder
        
        // Send notifications
        await sendOrderStatusNotification(updatedOrder, newStatus: newStatus)
        
        // Handle status-specific logic
        await handleStatusTransition(updatedOrder, from: currentOrder.status, to: newStatus)
        
        // Move to history if completed
        if newStatus == .delivered || newStatus == .cancelled {
            activeOrders.removeAll { $0.id == orderId }
        }
    }
    
    /// Assigns a driver to an order
    func assignDriver(_ driverId: String, to orderId: String) async throws {
        guard let orderIndex = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw AppError.validation(.orderNotFound)
        }
        
        // Use repository to assign driver
        try await orderRepository.assignDriver(driverId, to: orderId)
        
        // Update local state
        var updatedOrder = activeOrders[orderIndex]
        updatedOrder = Order(
            id: updatedOrder.id,
            customerId: updatedOrder.customerId,
            partnerId: updatedOrder.partnerId,
            driverId: driverId,
            items: updatedOrder.items,
            status: .driverAssigned,
            subtotalCents: updatedOrder.subtotalCents,
            deliveryFeeCents: updatedOrder.deliveryFeeCents,
            platformFeeCents: updatedOrder.platformFeeCents,
            taxCents: updatedOrder.taxCents,
            tipCents: updatedOrder.tipCents,
            deliveryAddress: updatedOrder.deliveryAddress,
            deliveryInstructions: updatedOrder.deliveryInstructions,
            estimatedDeliveryTime: updatedOrder.estimatedDeliveryTime,
            actualDeliveryTime: updatedOrder.actualDeliveryTime,
            paymentMethod: updatedOrder.paymentMethod,
            paymentStatus: updatedOrder.paymentStatus,
            createdAt: updatedOrder.createdAt,
            updatedAt: Date()
        )
        
        activeOrders[orderIndex] = updatedOrder
        
        // Send notifications
        await sendDriverAssignmentNotifications(updatedOrder)
    }
    
    /// Attempts to find and assign nearest available driver
    func findNearestAvailableDriver(for order: Order) async throws -> Driver? {
        // Get available drivers (simplified implementation)
        let availableJobs = try await driverService.fetchAvailableJobs()
        
        // For now, return nil - in production this would implement proper driver matching
        return nil
    }
    
    /// Cancels an order with proper validation
    func cancelOrder(_ orderId: String, reason: String) async throws -> Order {
        guard let orderIndex = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw AppError.validation(.orderNotFound)
        }
        
        let currentOrder = activeOrders[orderIndex]
        
        // Check if order can be cancelled
        guard canTransitionOrder(from: currentOrder.status, to: .cancelled) else {
            throw AppError.validation(.invalidFormat("Order cannot be cancelled at this stage"))
        }
        
        // Update order status
        try await updateOrderStatus(orderId, to: .cancelled)
        
        // Send cancellation notifications
        await sendCancellationNotifications(currentOrder, reason: reason)
        
        return activeOrders.first { $0.id == orderId } ?? currentOrder
    }
    
    // MARK: - Order Validation
    
    func canTransitionOrder(from currentStatus: OrderStatus, to newStatus: OrderStatus) -> Bool {
        return orderStatusTransitions[currentStatus]?.contains(newStatus) ?? false
    }
    
    private func validateOrder(_ order: Order) throws {
        // Validate items
        guard !order.items.isEmpty else {
            throw AppError.validation(.requiredFieldMissing("Order items"))
        }
        
        // Validate delivery address
        guard !order.deliveryAddress.street.isEmpty else {
            throw AppError.validation(.requiredFieldMissing("Delivery address"))
        }
        
        // Validate order totals
        guard order.subtotalCents > 0 else {
            throw AppError.validation(.invalidFormat("Order total"))
        }
    }
    
    // MARK: - Driver Assignment Logic
    
    private func attemptDriverAssignment(for order: Order) async {
        do {
            if let driver = try await findNearestAvailableDriver(for: order) {
                try await assignDriver(driver.id, to: order.id)
            } else {
                // No drivers available - could implement retry logic here
                print("No drivers available for order \(order.id)")
            }
        } catch {
            print("Failed to assign driver to order \(order.id): \(error)")
        }
    }
    
    // MARK: - Real-time Tracking Setup
    
    private func setupOrderTracking() {
        // Setup real-time order updates (simplified)
        // In production, this would subscribe to CloudKit changes
    }
    
    // MARK: - Status Transition Handlers
    
    private func handleStatusTransition(_ order: Order, from oldStatus: OrderStatus, to newStatus: OrderStatus) async {
        switch newStatus {
        case .accepted:
            let notification = LocalNotification(
                title: "Order Confirmed",
                body: "Your order #\(order.id.prefix(8)) has been confirmed",
                timeInterval: 5,
                userInfo: ["orderId": order.id]
            )
            try? await pushNotificationService.scheduleLocalNotification(notification)
            
        case .driverAssigned:
            guard let driverId = order.driverId else { break }
            let message = "Driver \(driverId) is on the way"
            let notification = LocalNotification(
                title: "Driver Assigned",
                body: message,
                timeInterval: 5,
                userInfo: ["orderId": order.id]
            )
            try? await pushNotificationService.scheduleLocalNotification(notification)
            
            let customerNotification = LocalNotification(
                title: "Driver Assigned",
                body: "A driver has been assigned to your order",
                timeInterval: 5,
                userInfo: ["orderId": order.id]
            )
            try? await pushNotificationService.scheduleLocalNotification(customerNotification)
            
        case .cancelled(let reason):
            let notification = LocalNotification(
                title: "Order Cancelled",
                body: "Your order has been cancelled. \(reason)",
                timeInterval: 5,
                userInfo: ["orderId": order.id]
            )
            try? await pushNotificationService.scheduleLocalNotification(notification)
            
        case .delivered:
            let notification = LocalNotification(
                title: "Order Delivered",
                body: "Your order has been delivered! Please rate your experience.",
                timeInterval: 5,
                userInfo: ["orderId": order.id]
            )
            try? await pushNotificationService.scheduleLocalNotification(notification)
            
        default:
            break
        }
    }
    
    private func handleOrderDelivered(_ order: Order) async {
        // Remove from active orders
        activeOrders.removeAll { $0.id == order.id }
        
        // Send delivery confirmation
        await sendDeliveryConfirmation(order)
    }
    
    private func handleOrderCancelled(_ order: Order) async {
        // Remove from active orders
        activeOrders.removeAll { $0.id == order.id }
    }
    
    // MARK: - Notification Sending
    
    private func sendOrderConfirmation(_ order: Order) async {
        // Send order confirmation notification using local notification
        let notification = LocalNotification(
            title: "Order Confirmed!",
            body: "Your order #\(order.id.prefix(8)) has been confirmed",
            userInfo: ["orderId": order.id, "action": "view_order"],
            category: .orderUpdate
        )
        try? await pushNotificationService.scheduleLocalNotification(notification)
    }
    
    private func sendOrderStatusNotification(_ order: Order, newStatus: OrderStatus) async {
        let message = generateStatusMessage(for: newStatus)
        
        let notification = LocalNotification(
            title: "Order Update",
            body: message,
            userInfo: ["orderId": order.id, "status": newStatus.rawValue, "action": "track_order"],
            category: .orderUpdate
        )
        try? await pushNotificationService.scheduleLocalNotification(notification)
    }
    
    private func sendDriverAssignmentNotifications(_ order: Order) async {
        // Notify customer about driver assignment
        let customerNotification = LocalNotification(
            title: "Driver Assigned",
            body: "A driver has been assigned to your order",
            userInfo: ["orderId": order.id, "action": "track_order"],
            category: .driverAssignment
        )
        try? await pushNotificationService.scheduleLocalNotification(customerNotification)
        
        // For driver notification, we would typically use a different mechanism
        // For now, we'll just log it
        if let driverId = order.driverId {
            print("Driver \(driverId) assigned to order \(order.id)")
        }
    }
    
    private func sendCancellationNotifications(_ order: Order, reason: String) async {
        let notification = LocalNotification(
            title: "Order Cancelled",
            body: "Your order has been cancelled. \(reason)",
            userInfo: ["orderId": order.id, "action": "view_refund"],
            category: .orderUpdate
        )
        try? await pushNotificationService.scheduleLocalNotification(notification)
    }
    
    private func sendDeliveryConfirmation(_ order: Order) async {
        let notification = LocalNotification(
            title: "Order Delivered",
            body: "Your order has been delivered! Enjoy!",
            userInfo: ["orderId": order.id, "action": "rate_order"],
            category: .orderUpdate
        )
        try? await pushNotificationService.scheduleLocalNotification(notification)
    }
    
    // MARK: - Helper Methods
    
    private func generateStatusMessage(for status: OrderStatus) -> String {
        switch status {
        case .paymentConfirmed:
            return "Payment confirmed! Your order is being processed."
        case .accepted:
            return "Your order has been accepted and is being prepared."
        case .preparing:
            return "Your order is being prepared with care."
        case .ready:
            return "Your order is ready for pickup!"
        case .driverAssigned:
            return "A driver has been assigned to your order."
        case .pickedUp:
            return "Your order has been picked up and is on the way!"
        case .enRoute:
            return "Your order is out for delivery."
        case .delivering:
            return "Your order is out for delivery."
        case .delivered:
            return "Your order has been delivered! Enjoy!"
        case .cancelled:
            return "Your order has been cancelled."
        default:
            return "Order status updated."
        }
    }
    
    private func handleOrderError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        return AppError.unknown(error)
    }
}