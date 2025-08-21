//
//  OrderRepository.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// Order repository protocol for managing order data
protocol OrderRepository: Sendable {
    func createOrder(_ order: Order) async throws -> Order
    func fetchOrder(by id: String) async throws -> Order?
    func fetchOrders(for userId: String, role: UserRole) async throws -> [Order]
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws
    func assignDriver(_ driverId: String, to orderId: String) async throws
}