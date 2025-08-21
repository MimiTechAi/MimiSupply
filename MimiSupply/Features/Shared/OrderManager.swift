//
//  OrderManager.swift
//  MimiSupply
//
//  Created by Alex on 15.08.25.
//

import Foundation
import Combine
import CloudKit

/// Central business logic manager for order lifecycle management
@MainActor
final class OrderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeOrders: [Order] = []
    @Published var isProcessingOrder: Bool = false
    @Published var lastOrderError: Error?
    
    // MARK: - Dependencies
    private let orderRepository: OrderRepository
    private let driverService: DriverService
    private let paymentService: PaymentService
    private let notificationService: PushNotificationService
    private let locationService: LocationService
    private let cloudKitService: CloudKitService
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let orderStatusTransitions: [OrderStatus: Set<OrderStatus>] = [
        .created: [.paymentProcessing, .cancelled],
        .paymentProcessing: [.paymentConfirmed, .failed, .cancelled],
        .paymentConfirmed: [.accepted, .cancelled],
        .accepted: [.preparing, .cancelled],
        .preparing: [.ready, .cancelled],
        .ready: [.readyForPickup, .cancelled],
        .readyForPickup: [.driverAssigned, .cancelled],
        .driverAssigned: [.pickedUp, .cancelled],
        .pickedUp: [.enRoute, .cancelled],
        .enRoute: [.delivering, .cancelled],
        .delivering: [.delivered, .cancelled],
        .delivered: [],
        .cancelled: [],
        .failed: []
    ]
    
    // MARK: - Initialization
    init(
        orderRepository: OrderRepository,
        driverService: DriverService,
        paymentService: PaymentService,
        notificationService: PushNotificationService,
        locationService: LocationService? = nil,
        cloudKitService: CloudKitService
    ) {
        self.orderRepository = orderRepository
        self.driverService = driverService
        self.paymentService = paymentService
        self.notificationService = notificationService
        self.locationService = locationService ?? LocationServiceImpl()
        self.cloudKitService = cloudKitService
        
        setupRealTimeSubscriptions()
    }
    
    // MARK: - Order Creation
    
    /// Creates a new order and processes payment
    func createOrder(_ order: Order) async throws -> Order {
        isProcessingOrder = true
        lastOrderError = nil
        
        defer { isProcessingOrder = false }
        
        do {
            // 1. Validate order
            try validateOrder(order)
            
            // 2. Process payment
            let paymentResult = try await paymentService.processPayment(for: order)
            
            // 3. Update order with payment confirmation
            var confirmedOrder = order
            confirmedOrder = Order(
                id: order.id,
                customerId: order.customerId,
                partnerId: order.partnerId,
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
                paymentMethod: order.paymentMethod,
                paymentStatus: .completed,
                createdAt: order.createdAt,
                updatedAt: Date()
            )
            
            // 4. Save order to CloudKit
            let savedOrder = try await orderRepository.createOrder(confirmedOrder)
            
            // 5. Notify partner of new order
            await notifyPartnerOfNewOrder(savedOrder)
            
            // 6. Start driver assignment process
            Task {
                await assignDriverToOrder(savedOrder)
            }
            
            // 7. Add to active orders
            activeOrders.append(savedOrder)
            
            return savedOrder
            
        } catch {
            lastOrderError = error
            throw error
        }
    }
    
    // MARK: - Order Status Management
    
    /// Updates order status with validation
    func updateOrderStatus(_ orderId: String, to newStatus: OrderStatus) async throws {
        guard let orderIndex = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw AppError.orderNotFound(orderId)
        }
        
        let currentOrder = activeOrders[orderIndex]
        
        // Validate status transition
        guard canTransitionOrder(from: currentOrder.status, to: newStatus) else {
            throw AppError.invalidOrderStatusTransition(from: currentOrder.status, to: newStatus)
        }
        
        // Update order
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
        
        // Save to repository
        let savedOrder = try await orderRepository.updateOrder(updatedOrder)
        
        // Update local state
        activeOrders[orderIndex] = savedOrder
        
        // Send notifications
        await sendOrderStatusUpdateNotification(savedOrder)
        
        // Handle special status changes
        await handleSpecialStatusChange(savedOrder, from: currentOrder.status, to: newStatus)
    }
    
    /// Validates if an order status transition is allowed
    func canTransitionOrder(from currentStatus: OrderStatus, to newStatus: OrderStatus) -> Bool {
        guard let allowedTransitions = orderStatusTransitions[currentStatus] else {
            return false
        }
        return allowedTransitions.contains(newStatus)
    }
    
    // MARK: - Driver Assignment
    
    /// Assigns a driver to an order
    func assignDriver(_ driverId: String, to orderId: String) async throws {
        guard let orderIndex = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw AppError.orderNotFound(orderId)
        }
        
        let currentOrder = activeOrders[orderIndex]
        
        // Verify driver is available
        guard try await driverService.isDriverAvailable(driverId) else {
            throw AppError.driverNotAvailable(driverId)
        }
        
        // Update order with driver assignment
        var updatedOrder = currentOrder
        updatedOrder = Order(
            id: currentOrder.id,
            customerId: currentOrder.customerId,
            partnerId: currentOrder.partnerId,
            driverId: driverId,
            items: currentOrder.items,
            status: .driverAssigned,
            subtotalCents: currentOrder.subtotalCents,
            deliveryFeeCents: currentOrder.deliveryFeeCents,
            platformFeeCents: currentOrder.platformFeeCents,
            taxCents: currentOrder.taxCents,
            tipCents: currentOrder.tipCents,
            deliveryAddress: currentOrder.deliveryAddress,
            deliveryInstructions: currentOrder.deliveryInstructions,
            estimatedDeliveryTime: currentOrder.estimatedDeliveryTime,
            actualDeliveryTime: currentOrder.actualDeliveryTime,
            paymentMethod: currentOrder.paymentMethod,
            paymentStatus: currentOrder.paymentStatus,
            createdAt: currentOrder.createdAt,
            updatedAt: Date()
        )
        
        // Save changes
        let savedOrder = try await orderRepository.updateOrder(updatedOrder)
        activeOrders[orderIndex] = savedOrder
        
        // Notify driver and customer
        await notifyDriverOfAssignment(driverId, order: savedOrder)
        await notifyCustomerOfDriverAssignment(savedOrder)
        
        // Mark driver as unavailable
        try await driverService.updateDriverAvailability(driverId, isAvailable: false)
    }
    
    /// Finds and assigns the nearest available driver
    func findNearestAvailableDriver(for order: Order) async throws -> Driver? {
        // Get customer location from delivery address
        guard let customerLocation = await geocodeAddress(order.deliveryAddress) else {
            throw AppError.locationNotFound("Unable to geocode delivery address")
        }
        
        // Find available drivers near the customer
        let nearbyDrivers = try await driverService.findDriversNearLocation(
            coordinate: customerLocation,
            radiusInMeters: 10000 // 10km radius
        )
        
        // Filter for available drivers
        let availableDrivers = nearbyDrivers.filter { $0.isAvailable }
        
        // Return the nearest available driver
        return availableDrivers.first
    }
    
    // MARK: - Order Cancellation
    
    /// Cancels an order with reason
    func cancelOrder(_ orderId: String, reason: String) async throws -> Order {
        guard let orderIndex = activeOrders.firstIndex(where: { $0.id == orderId }) else {
            throw AppError.orderNotFound(orderId)
        }
        
        let currentOrder = activeOrders[orderIndex]
        
        // Check if order can be cancelled
        guard canTransitionOrder(from: currentOrder.status, to: .cancelled) else {
            throw AppError.orderCannotBeCancelled(orderId)
        }
        
        // Process refund if payment was completed
        if currentOrder.paymentStatus == .completed {
            try await processRefund(for: currentOrder)
        }
        
        // Update order status
        try await updateOrderStatus(orderId, to: .cancelled)
        
        // Release driver if assigned
        if let driverId = currentOrder.driverId {
            try await driverService.updateDriverAvailability(driverId, isAvailable: true)
        }
        
        // Send cancellation notifications
        await sendOrderCancellationNotifications(currentOrder, reason: reason)
        
        return activeOrders[orderIndex]
    }
    
    // MARK: - Order Tracking
    
    /// Gets real-time order updates
    func subscribeToOrderUpdates(_ orderId: String) -> AnyPublisher<Order, Never> {
        return orderRepository.subscribeToOrderUpdates(orderId)
            .replaceError(with: Order.emptyOrder) // Provide fallback
            .eraseToAnyPublisher()
    }
    
    /// Gets driver location updates for an order
    func subscribeToDriverLocationUpdates(_ orderId: String) -> AnyPublisher<DriverLocation?, Never> {
        guard let order = activeOrders.first(where: { $0.id == orderId }),
              let driverId = order.driverId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return driverService.subscribeToDriverLocation(driverId)
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    
    private func validateOrder(_ order: Order) throws {
        // Validate items
        guard !order.items.isEmpty else {
            throw AppError.validation(.emptyCart)
        }
        
        // Validate delivery address
        guard !order.deliveryAddress.street.isEmpty,
              !order.deliveryAddress.city.isEmpty,
              !order.deliveryAddress.postalCode.isEmpty else {
            throw AppError.validation(.invalidDeliveryAddress)
        }
        
        // Validate order totals
        let calculatedSubtotal = order.items.reduce(0) { $0 + $1.totalPriceCents }
        guard order.subtotalCents == calculatedSubtotal else {
            throw AppError.validation(.invalidOrderTotal)
        }
    }
    
    private func setupRealTimeSubscriptions() {
        // Subscribe to CloudKit order changes
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshActiveOrders()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshActiveOrders() async {
        // Refresh active orders from repository
        // This would typically fetch orders with active statuses
    }
    
    private func notifyPartnerOfNewOrder(_ order: Order) async {
        do {
            try await notificationService.sendPushNotification(
                to: order.partnerId,
                title: "New Order",
                body: "Order #\(order.id.prefix(8)) - \(order.formattedTotal)",
                data: ["orderId": order.id, "type": "new_order"]
            )
        } catch {
            print("Failed to notify partner of new order: \(error)")
        }
    }
    
    private func assignDriverToOrder(_ order: Order) async {
        do {
            // Find nearest available driver
            if let driver = try await findNearestAvailableDriver(for: order) {
                try await assignDriver(driver.id, to: order.id)
            } else {
                // No drivers available - notify support
                print("No drivers available for order \(order.id)")
            }
        } catch {
            print("Failed to assign driver to order \(order.id): \(error)")
        }
    }
    
    private func sendOrderStatusUpdateNotification(_ order: Order) async {
        do {
            let message = getStatusUpdateMessage(for: order.status)
            try await notificationService.sendPushNotification(
                to: order.customerId,
                title: "Order Update",
                body: message,
                data: ["orderId": order.id, "status": order.status.rawValue]
            )
        } catch {
            print("Failed to send status update notification: \(error)")
        }
    }
    
    private func handleSpecialStatusChange(_ order: Order, from oldStatus: OrderStatus, to newStatus: OrderStatus) async {
        switch newStatus {
        case .delivered:
            await handleOrderDelivered(order)
        case .cancelled:
            await handleOrderCancelled(order)
        default:
            break
        }
    }
    
    private func handleOrderDelivered(_ order: Order) async {
        // Mark driver as available again
        if let driverId = order.driverId {
            try? await driverService.updateDriverAvailability(driverId, isAvailable: true)
        }
        
        // Remove from active orders
        activeOrders.removeAll { $0.id == order.id }
        
        // Send delivery confirmation
        await sendDeliveryConfirmation(order)
    }
    
    private func handleOrderCancelled(_ order: Order) async {
        // Remove from active orders
        activeOrders.removeAll { $0.id == order.id }
        
        // Release driver if assigned
        if let driverId = order.driverId {
            try? await driverService.updateDriverAvailability(driverId, isAvailable: true)
        }
    }
    
    private func notifyDriverOfAssignment(_ driverId: String, order: Order) async {
        do {
            try await notificationService.sendPushNotification(
                to: driverId,
                title: "New Delivery Job",
                body: "Pickup from \(order.partnerId) → \(order.deliveryAddress.street)",
                data: ["orderId": order.id, "type": "driver_assignment"]
            )
        } catch {
            print("Failed to notify driver of assignment: \(error)")
        }
    }
    
    private func notifyCustomerOfDriverAssignment(_ order: Order) async {
        do {
            try await notificationService.sendPushNotification(
                to: order.customerId,
                title: "Driver Assigned",
                body: "Your order is being prepared and a driver has been assigned",
                data: ["orderId": order.id, "type": "driver_assigned"]
            )
        } catch {
            print("Failed to notify customer of driver assignment: \(error)")
        }
    }
    
    private func processRefund(for order: Order) async throws {
        try await paymentService.processRefund(
            paymentId: order.id,
            amount: order.totalCents,
            reason: "Order cancelled"
        )
    }
    
    private func sendOrderCancellationNotifications(_ order: Order, reason: String) async {
        // Notify customer
        do {
            try await notificationService.sendPushNotification(
                to: order.customerId,
                title: "Order Cancelled",
                body: "Your order has been cancelled. Refund will be processed within 3-5 business days.",
                data: ["orderId": order.id, "type": "order_cancelled"]
            )
        } catch {
            print("Failed to send cancellation notification to customer: \(error)")
        }
        
        // Notify partner
        do {
            try await notificationService.sendPushNotification(
                to: order.partnerId,
                title: "Order Cancelled",
                body: "Order #\(order.id.prefix(8)) has been cancelled",
                data: ["orderId": order.id, "type": "order_cancelled"]
            )
        } catch {
            print("Failed to send cancellation notification to partner: \(error)")
        }
    }
    
    private func sendDeliveryConfirmation(_ order: Order) async {
        do {
            try await notificationService.sendPushNotification(
                to: order.customerId,
                title: "Order Delivered",
                body: "Your order has been delivered! Please rate your experience.",
                data: ["orderId": order.id, "type": "order_delivered"]
            )
        } catch {
            print("Failed to send delivery confirmation: \(error)")
        }
    }
    
    private func getStatusUpdateMessage(for status: OrderStatus) -> String {
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
    
    private func geocodeAddress(_ address: Address) async -> Coordinate? {
        do {
            return try await locationService.geocodeAddress(address)
        } catch {
            print("Failed to geocode address: \(error)")
            return nil
        }
    }
}

// MARK: - AppError Extensions

extension AppError {
    static func orderNotFound(_ orderId: String) -> AppError {
        return .businessLogic("Order with ID \(orderId) not found")
    }
    
    static func invalidOrderStatusTransition(from: OrderStatus, to: OrderStatus) -> AppError {
        return .businessLogic("Cannot transition order from \(from.displayName) to \(to.displayName)")
    }
    
    static func driverNotAvailable(_ driverId: String) -> AppError {
        return .businessLogic("Driver \(driverId) is not available")
    }
    
    static func orderCannotBeCancelled(_ orderId: String) -> AppError {
        return .businessLogic("Order \(orderId) cannot be cancelled at this stage")
    }
    
    static func locationNotFound(_ message: String) -> AppError {
        return .businessLogic("Location error: \(message)")
    }
}

// MARK: - Order Extensions

extension Order {
    static var emptyOrder: Order {
        return Order(
            customerId: "",
            partnerId: "",
            items: [],
            subtotalCents: 0,
            deliveryFeeCents: 0,
            platformFeeCents: 0,
            taxCents: 0,
            deliveryAddress: Address(
                street: "",
                city: "",
                state: "",
                postalCode: "",
                country: ""
            ),
            estimatedDeliveryTime: Date(),
            paymentMethod: .applePay
        )
    }
}