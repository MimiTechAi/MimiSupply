//
//  OrderRepositoryImpl.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Implementation of OrderRepository for managing order data
final class OrderRepositoryImpl: OrderRepository, @unchecked Sendable {
    
    private let cloudKitService: CloudKitService
    
    init(cloudKitService: CloudKitService) {
        self.cloudKitService = cloudKitService
    }
    
    func createOrder(_ order: Order) async throws -> Order {
        return try await cloudKitService.createOrder(order)
    }
    
    func fetchOrder(by id: String) async throws -> Order? {
        let orders = try await cloudKitService.fetchOrders(for: "", role: .customer)
        return orders.first { $0.id == id }
    }
    
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order] {
        return try await cloudKitService.fetchOrders(for: userId, role: role)
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        try await cloudKitService.updateOrderStatus(orderId, status: status)
    }
    
    func assignDriver(_ driverId: String, to orderId: String) async throws {
        // Fetch the order to update
        guard let existingOrder = try await fetchOrder(by: orderId) else {
            throw AppError.validation(.orderNotFound)
        }
        
        // Create updated order with driver assigned
        let updatedOrder = Order(
            id: existingOrder.id,
            customerId: existingOrder.customerId,
            partnerId: existingOrder.partnerId,
            driverId: driverId,
            items: existingOrder.items,
            status: .driverAssigned,
            subtotalCents: existingOrder.subtotalCents,
            deliveryFeeCents: existingOrder.deliveryFeeCents,
            platformFeeCents: existingOrder.platformFeeCents,
            taxCents: existingOrder.taxCents,
            tipCents: existingOrder.tipCents,
            deliveryAddress: existingOrder.deliveryAddress,
            deliveryInstructions: existingOrder.deliveryInstructions,
            estimatedDeliveryTime: existingOrder.estimatedDeliveryTime,
            actualDeliveryTime: existingOrder.actualDeliveryTime,
            paymentMethod: existingOrder.paymentMethod,
            paymentStatus: existingOrder.paymentStatus,
            createdAt: existingOrder.createdAt,
            updatedAt: Date()
        )
        
        // Update the order with driver assignment
        _ = try await cloudKitService.createOrder(updatedOrder)
        
        // Update order status
        try await updateOrderStatus(orderId, status: OrderStatus.driverAssigned)
    }
}
