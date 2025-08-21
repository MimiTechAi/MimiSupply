//
//  OrderHistoryViewModelTests.swift
//  MimiSupplyTests
//
//  Created by Cascade on 20.08.2025.
//

import XCTest
@testable import MimiSupply

@MainActor
final class OrderHistoryViewModelTests: XCTestCase {
    var mockRepo: MockOrderRepository!
    var viewModel: OrderHistoryViewModel!

    override func setUp() {
        super.setUp()
        mockRepo = MockOrderRepository()
    }

    override func tearDown() {
        viewModel = nil
        mockRepo = nil
        super.tearDown()
    }

    // MARK: - Helpers
    private func makeOrder(
        id: String,
        customerId: String,
        status: OrderStatus,
        subtotal: Int,
        deliveryFee: Int = 100,
        platformFee: Int = 50,
        tax: Int = 0,
        tip: Int = 0,
        createdAt: Date
    ) -> Order {
        let address = TestDataFactory.createTestAddress()
        let item = OrderItem(
            id: "item-\(id)",
            productId: "product-\(id)",
            productName: "Item \(id)",
            quantity: 1,
            unitPriceCents: subtotal
        )
        return Order(
            id: id,
            customerId: customerId,
            partnerId: "partner-\(id)",
            driverId: nil,
            items: [item],
            status: status,
            subtotalCents: subtotal,
            deliveryFeeCents: deliveryFee,
            platformFeeCents: platformFee,
            taxCents: tax,
            tipCents: tip,
            deliveryAddress: address,
            deliveryInstructions: nil,
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            actualDeliveryTime: nil,
            specialInstructions: nil,
            paymentMethod: .applePay,
            paymentStatus: .completed,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    // MARK: - Tests
    func testLoadOrderHistorySuccess_DefaultSortByDateDescending() async {
        // Given
        let userId = "user-123"
        let now = Date()
        let older = now.addingTimeInterval(-3600)
        let oldest = now.addingTimeInterval(-7200)

        // Orders for current user and one for another user (should be filtered by repo)
        let o1 = makeOrder(id: "o1", customerId: userId, status: .preparing, subtotal: 1000, createdAt: now)
        let o2 = makeOrder(id: "o2", customerId: userId, status: .delivered, subtotal: 1500, createdAt: older)
        let o3 = makeOrder(id: "o3", customerId: userId, status: .pending, subtotal: 500, createdAt: oldest)
        let oOther = makeOrder(id: "oX", customerId: "someone-else", status: .pending, subtotal: 999, createdAt: now)
        mockRepo.mockOrders = [o2, oOther, o3, o1]

        viewModel = OrderHistoryViewModel(userId: userId, userRole: .customer, orderRepository: mockRepo)

        // When
        await viewModel.loadOrderHistory()

        // Then
        XCTAssertEqual(viewModel.orders.count, 3)
        XCTAssertEqual(viewModel.filteredOrders.map { $0.id }, ["o1", "o2", "o3"]) // date desc by default
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showingError)
    }

    func testApplyStatusFilter() async {
        // Given
        let userId = "user-123"
        let now = Date()
        let orders = [
            makeOrder(id: "o1", customerId: userId, status: .delivered, subtotal: 1000, createdAt: now),
            makeOrder(id: "o2", customerId: userId, status: .pending, subtotal: 1200, createdAt: now.addingTimeInterval(-10)),
            makeOrder(id: "o3", customerId: userId, status: .delivered, subtotal: 900, createdAt: now.addingTimeInterval(-20))
        ]
        mockRepo.mockOrders = orders
        viewModel = OrderHistoryViewModel(userId: userId, userRole: .customer, orderRepository: mockRepo)
        await viewModel.loadOrderHistory()

        // When
        viewModel.applyStatusFilter(.delivered)

        // Then
        XCTAssertTrue(viewModel.filteredOrders.allSatisfy { $0.status == .delivered })
        XCTAssertEqual(Set(viewModel.filteredOrders.map { $0.id }), Set(["o1", "o3"]))
    }

    func testSortByAmountAscendingAndDescending() async {
        // Given
        let userId = "user-123"
        let now = Date()
        let orders = [
            makeOrder(id: "o1", customerId: userId, status: .pending, subtotal: 500, createdAt: now), // total = 500 + 150 = 650
            makeOrder(id: "o2", customerId: userId, status: .pending, subtotal: 1500, createdAt: now), // total = 1650
            makeOrder(id: "o3", customerId: userId, status: .pending, subtotal: 1000, createdAt: now)  // total = 1150
        ]
        mockRepo.mockOrders = orders
        viewModel = OrderHistoryViewModel(userId: userId, userRole: .customer, orderRepository: mockRepo)
        await viewModel.loadOrderHistory()

        // When - ascending
        viewModel.sortOrders(by: .amount, ascending: true)
        XCTAssertEqual(viewModel.filteredOrders.map { $0.id }, ["o1", "o3", "o2"]) // 650, 1150, 1650

        // When - descending
        viewModel.sortOrders(by: .amount, ascending: false)
        XCTAssertEqual(viewModel.filteredOrders.map { $0.id }, ["o2", "o3", "o1"]) // 1650, 1150, 650
    }

    func testSortByStatusPriority() async {
        // Given
        let userId = "user-123"
        let now = Date()
        let orders = [
            makeOrder(id: "o1", customerId: userId, status: .delivered, subtotal: 1000, createdAt: now),
            makeOrder(id: "o2", customerId: userId, status: .pending, subtotal: 1000, createdAt: now),
            makeOrder(id: "o3", customerId: userId, status: .driverAssigned, subtotal: 1000, createdAt: now)
        ]
        mockRepo.mockOrders = orders
        viewModel = OrderHistoryViewModel(userId: userId, userRole: .customer, orderRepository: mockRepo)
        await viewModel.loadOrderHistory()

        // When - ascending status priority
        viewModel.sortOrders(by: .status, ascending: true)

        // Then - expected priority order: created(0) ... delivered(13) ... failed(15)
        // For our subset: pending(4) < driverAssigned(7) < delivered(13)
        XCTAssertEqual(viewModel.filteredOrders.map { $0.id }, ["o2", "o3", "o1"]) 

        // When - descending status priority
        viewModel.sortOrders(by: .status, ascending: false)
        XCTAssertEqual(viewModel.filteredOrders.map { $0.id }, ["o1", "o3", "o2"]) 
    }

    func testSelectOrderShowsDetail() async {
        // Given
        let userId = "user-123"
        let order = makeOrder(id: "o1", customerId: userId, status: .pending, subtotal: 1000, createdAt: Date())
        mockRepo.mockOrders = [order]
        viewModel = OrderHistoryViewModel(userId: userId, userRole: .customer, orderRepository: mockRepo)
        await viewModel.loadOrderHistory()

        // When
        viewModel.selectOrder(order)

        // Then
        XCTAssertEqual(viewModel.selectedOrder?.id, order.id)
        XCTAssertTrue(viewModel.showingOrderDetail)
    }

    func testErrorHandling() async {
        // Given
        let userId = "user-123"
        mockRepo.shouldThrowError = true
        viewModel = OrderHistoryViewModel(userId: userId, userRole: .customer, orderRepository: mockRepo)

        // When
        await viewModel.loadOrderHistory()

        // Then
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        // After clearing
        viewModel.clearError()
        XCTAssertFalse(viewModel.showingError)
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }
}
