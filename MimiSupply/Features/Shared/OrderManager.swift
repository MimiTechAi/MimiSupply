import Foundation
import CoreLocation
import CloudKit

@MainActor
final class OrderManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentOrder: Order?
    @Published var orderHistory: [Order] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let cloudKitService: CloudKitService
    private let locationService: LocationService
    private let pushNotificationService: PushNotificationService
    
    // MARK: - Initialization
    init(
        cloudKitService: CloudKitService = CloudKitServiceImpl.shared,
        locationService: LocationService? = nil,
        pushNotificationService: PushNotificationService = PushNotificationServiceImpl()
    ) {
        self.cloudKitService = cloudKitService
        self.locationService = locationService ?? LocationServiceImpl.shared
        self.pushNotificationService = pushNotificationService
    }
    
    // MARK: - Public Methods
    
    func placeOrder(_ order: Order) async throws -> Order {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let placedOrder = try await cloudKitService.createOrder(order)
            currentOrder = placedOrder
            await sendOrderNotification(for: placedOrder)
            return placedOrder
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await cloudKitService.updateOrderStatus(orderId, status: status)
            
            if let index = orderHistory.firstIndex(where: { $0.id == orderId }) {
                var updatedOrder = orderHistory[index]
                orderHistory[index] = Order(
                    id: updatedOrder.id,
                    customerId: updatedOrder.customerId,
                    partnerId: updatedOrder.partnerId,
                    driverId: updatedOrder.driverId,
                    items: updatedOrder.items,
                    status: status,
                    subtotalCents: updatedOrder.subtotalCents,
                    deliveryFeeCents: updatedOrder.deliveryFeeCents,
                    platformFeeCents: updatedOrder.platformFeeCents,
                    taxCents: updatedOrder.taxCents,
                    tipCents: updatedOrder.tipCents,
                    deliveryAddress: updatedOrder.deliveryAddress,
                    deliveryInstructions: updatedOrder.deliveryInstructions,
                    estimatedDeliveryTime: updatedOrder.estimatedDeliveryTime,
                    actualDeliveryTime: updatedOrder.actualDeliveryTime,
                    specialInstructions: updatedOrder.specialInstructions,
                    paymentMethod: updatedOrder.paymentMethod,
                    paymentStatus: updatedOrder.paymentStatus,
                    createdAt: updatedOrder.createdAt,
                    updatedAt: updatedOrder.updatedAt
                )
            }
            
            if currentOrder?.id == orderId {
                if let current = currentOrder {
                    currentOrder = Order(
                        id: current.id,
                        customerId: current.customerId,
                        partnerId: current.partnerId,
                        driverId: current.driverId,
                        items: current.items,
                        status: status,
                        subtotalCents: current.subtotalCents,
                        deliveryFeeCents: current.deliveryFeeCents,
                        platformFeeCents: current.platformFeeCents,
                        taxCents: current.taxCents,
                        tipCents: current.tipCents,
                        deliveryAddress: current.deliveryAddress,
                        deliveryInstructions: current.deliveryInstructions,
                        estimatedDeliveryTime: current.estimatedDeliveryTime,
                        actualDeliveryTime: current.actualDeliveryTime,
                        specialInstructions: current.specialInstructions,
                        paymentMethod: current.paymentMethod,
                        paymentStatus: current.paymentStatus,
                        createdAt: current.createdAt,
                        updatedAt: current.updatedAt
                    )
                }
            }
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func cancelOrder(_ orderId: String, reason: String) async throws {
        try await updateOrderStatus(orderId, status: .cancelled)
        
        let notification = LocalNotification(
            title: "Order Cancelled",
            body: "Your order has been cancelled. \(reason)",
            timeInterval: 5,
            userInfo: ["orderId": orderId]
        )
        try? await pushNotificationService.scheduleLocalNotification(notification)
    }
    
    func trackOrder(_ orderId: String) async throws -> Order? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let order = try await cloudKitService.fetchOrder(by: orderId)
            return order
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func loadOrderHistory() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            orderHistory = try await cloudKitService.fetchOrderHistory()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func sendOrderNotification(for order: Order) async {
        let notification = LocalNotification(
            title: "Order Placed",
            body: "Your order #\(order.id.prefix(8)) has been placed successfully",
            timeInterval: 5,
            userInfo: ["orderId": order.id]
        )
        try? await pushNotificationService.scheduleLocalNotification(notification)
    }
}