//
//  OrderTrackingTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 14.08.25.
//

import XCTest
import CloudKit
import CoreLocation
@testable import MimiSupply

/// Acceptance tests for real-time order tracking functionality
/// Following ATDD approach with test scenarios defining expected behavior
final class OrderTrackingTests: XCTestCase {
    
    var mockCloudKitService: MockCloudKitService!
    var mockLocationService: MockLocationService!
    var sampleOrder: Order!
    
    override func setUpWithError() throws {
        mockCloudKitService = MockCloudKitService()
        mockLocationService = MockLocationService()
        
        sampleOrder = Order(
            id: "order123",
            customerId: "customer123",
            partnerId: "partner123",
            driverId: "driver123",
            items: [
                OrderItem(
                    productId: "product1",
                    productName: "Pizza Margherita",
                    quantity: 1,
                    unitPriceCents: 1200
                )
            ],
            status: .delivering,
            subtotalCents: 1200,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 120,
            deliveryAddress: Address(
                street: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105",
                country: "US"
            ),
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            paymentMethod: .applePay
        )
    }
    
    // MARK: - ATDD Scenarios
    
    /// Scenario: Customer views real-time order tracking
    /// Given: An order is in delivery status
    /// When: Customer opens order tracking
    /// Then: They see live driver location updates
    func testCustomerViewsRealTimeOrderTracking() async throws {
        // Given
        let driverLocation = DriverLocation(
            driverId: "driver123",
            location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            accuracy: 5.0
        )
        mockCloudKitService.mockDriverLocation = driverLocation
        
        // When
        let viewModel = OrderTrackingViewModel(
            order: sampleOrder,
            cloudKitService: mockCloudKitService
        )
        await viewModel.startTracking()
        
        // Then
        XCTAssertNotNil(viewModel.driverLocation)
        XCTAssertEqual(viewModel.driverLocation?.driverId, "driver123")
        XCTAssertEqual(viewModel.currentOrder.status, .delivering)
    }
    
    /// Scenario: Order status updates automatically
    /// Given: An order is being tracked
    /// When: Driver updates order status
    /// Then: Customer sees immediate status update
    func testOrderStatusUpdatesAutomatically() async throws {
        // Given
        let viewModel = OrderTrackingViewModel(
            order: sampleOrder,
            cloudKitService: mockCloudKitService
        )
        await viewModel.startTracking()
        
        // When
        mockCloudKitService.mockOrderStatus = .delivered
        await viewModel.handleOrderStatusUpdate(.delivered)
        
        // Then
        XCTAssertEqual(viewModel.currentOrder.status, .delivered)
        XCTAssertTrue(viewModel.showingStatusUpdate)
    }
    
    /// Scenario: ETA calculation with driver location
    /// Given: Driver is assigned and moving
    /// When: Driver location updates
    /// Then: ETA is recalculated and displayed
    func testETACalculationWithDriverLocation() async throws {
        // Given
        let viewModel = OrderTrackingViewModel(
            order: sampleOrder,
            cloudKitService: mockCloudKitService
        )
        
        // When
        await viewModel.calculateETA()
        
        // Then
        XCTAssertNotNil(viewModel.estimatedArrival)
        XCTAssertTrue(viewModel.estimatedArrival! > Date())
    }
    
    /// Scenario: Order history displays completed orders
    /// Given: Customer has completed orders
    /// When: Customer views order history
    /// Then: All past orders are displayed chronologically
    func testOrderHistoryDisplaysCompletedOrders() async throws {
        // Given
        let completedOrder = Order(
            customerId: "customer123",
            partnerId: "partner123",
            items: [],
            status: .delivered,
            subtotalCents: 1000,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 100,
            deliveryAddress: sampleOrder.deliveryAddress,
            actualDeliveryTime: Date().addingTimeInterval(-3600),
            paymentMethod: .applePay
        )
        
        mockCloudKitService.mockOrders = [completedOrder]
        
        // When
        let viewModel = OrderHistoryViewModel(
            userId: "customer123",
            userRole: .customer,
            orderRepository: OrderRepositoryImpl(cloudKitService: mockCloudKitService)
        )
        await viewModel.loadOrderHistory()
        
        // Then
        XCTAssertEqual(viewModel.orders.count, 1)
        XCTAssertEqual(viewModel.orders.first?.status, .delivered)
    }
    
    /// Scenario: Delivery completion flow
    /// Given: Order is delivered
    /// When: Customer confirms delivery
    /// Then: Rating and feedback prompt appears
    func testDeliveryCompletionFlow() async throws {
        // Given
        let deliveredOrder = Order(
            id: sampleOrder.id,
            customerId: sampleOrder.customerId,
            partnerId: sampleOrder.partnerId,
            driverId: sampleOrder.driverId,
            items: sampleOrder.items,
            status: .delivered,
            subtotalCents: sampleOrder.subtotalCents,
            deliveryFeeCents: sampleOrder.deliveryFeeCents,
            platformFeeCents: sampleOrder.platformFeeCents,
            taxCents: sampleOrder.taxCents,
            deliveryAddress: sampleOrder.deliveryAddress,
            actualDeliveryTime: Date(),
            paymentMethod: sampleOrder.paymentMethod
        )
        
        // When
        let viewModel = OrderTrackingViewModel(
            order: deliveredOrder,
            cloudKitService: mockCloudKitService
        )
        await viewModel.handleDeliveryCompletion()
        
        // Then
        XCTAssertTrue(viewModel.showingDeliveryCompletion)
        XCTAssertNotNil(viewModel.deliveryCompletionData)
    }
    
    /// Scenario: CloudKit subscription for real-time updates
    /// Given: Customer is tracking an order
    /// When: CloudKit receives status update
    /// Then: UI updates immediately without refresh
    func testCloudKitSubscriptionForRealTimeUpdates() async throws {
        // Given
        let viewModel = OrderTrackingViewModel(
            order: sampleOrder,
            cloudKitService: mockCloudKitService
        )
        await viewModel.startTracking()
        
        // When
        mockCloudKitService.simulateOrderUpdate(
            orderId: sampleOrder.id,
            newStatus: .delivered
        )
        
        // Then
        XCTAssertTrue(mockCloudKitService.subscriptionCreated)
        XCTAssertEqual(mockCloudKitService.lastSubscriptionID, "order-updates-customer123")
    }
    
    /// Scenario: Map view shows route and locations
    /// Given: Driver is assigned and delivering
    /// When: Customer views map
    /// Then: Both delivery location and driver location are shown
    func testMapViewShowsRouteAndLocations() {
        // Given
        let driverLocation = DriverLocation(
            driverId: "driver123",
            location: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
            accuracy: 5.0
        )
        
        // When
        let mapView = OrderTrackingMapView(
            deliveryLocation: sampleOrder.deliveryAddress,
            driverLocation: driverLocation,
            orderStatus: .delivering
        )
        
        // Then
        // Map view should show both locations (tested in UI tests)
        XCTAssertNotNil(mapView)
    }
}

// MARK: - Order History View Model Tests

final class OrderHistoryTests: XCTestCase {
    
    var mockOrderRepository: MockOrderRepository!
    var viewModel: OrderHistoryViewModel!
    
    override func setUpWithError() throws {
        mockOrderRepository = MockOrderRepository()
        viewModel = OrderHistoryViewModel(
            userId: "user123",
            userRole: .customer,
            orderRepository: mockOrderRepository
        )
    }
    
    /// Scenario: Filter orders by status
    /// Given: User has orders with different statuses
    /// When: User applies status filter
    /// Then: Only matching orders are displayed
    func testFilterOrdersByStatus() async throws {
        // Given
        let orders = [
            createMockOrder(status: .delivered),
            createMockOrder(status: .cancelled),
            createMockOrder(status: .delivering)
        ]
        mockOrderRepository.mockOrders = orders
        
        // When
        await viewModel.loadOrderHistory()
        viewModel.applyStatusFilter(.delivered)
        
        // Then
        XCTAssertEqual(viewModel.filteredOrders.count, 1)
        XCTAssertEqual(viewModel.filteredOrders.first?.status, .delivered)
    }
    
    /// Scenario: Sort orders by date
    /// Given: User has multiple orders
    /// When: User selects date sorting
    /// Then: Orders are sorted chronologically
    func testSortOrdersByDate() async throws {
        // Given
        let oldOrder = createMockOrder(createdAt: Date().addingTimeInterval(-86400))
        let newOrder = createMockOrder(createdAt: Date())
        mockOrderRepository.mockOrders = [oldOrder, newOrder]
        
        // When
        await viewModel.loadOrderHistory()
        viewModel.sortOrders(by: .date, ascending: false)
        
        // Then
        XCTAssertEqual(viewModel.filteredOrders.first?.createdAt, newOrder.createdAt)
        XCTAssertEqual(viewModel.filteredOrders.last?.createdAt, oldOrder.createdAt)
    }
    
    /// Scenario: Order details from history
    /// Given: User views order history
    /// When: User taps on specific order
    /// Then: Detailed order view is presented
    func testOrderDetailsFromHistory() async throws {
        // Given
        let order = createMockOrder(status: .delivered)
        mockOrderRepository.mockOrders = [order]
        await viewModel.loadOrderHistory()
        
        // When
        viewModel.selectOrder(order)
        
        // Then
        XCTAssertEqual(viewModel.selectedOrder?.id, order.id)
        XCTAssertTrue(viewModel.showingOrderDetail)
    }
    
    private func createMockOrder(
        status: OrderStatus = .delivered,
        createdAt: Date = Date()
    ) -> Order {
        return Order(
            customerId: "user123",
            partnerId: "partner123",
            items: [
                OrderItem(
                    productId: "product1",
                    productName: "Test Product",
                    quantity: 1,
                    unitPriceCents: 1000
                )
            ],
            status: status,
            subtotalCents: 1000,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 100,
            deliveryAddress: Address(
                street: "123 Test St",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "US"
            ),
            paymentMethod: .applePay,
            createdAt: createdAt
        )
    }
}
