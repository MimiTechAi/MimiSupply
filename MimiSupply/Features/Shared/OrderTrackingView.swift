//
//  OrderTrackingView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI
import MapKit
import CloudKit

/// Real-time order tracking view with driver location and status updates
struct OrderTrackingView: View {
    let order: Order
    let onClose: () -> Void
    
    @StateObject private var viewModel: OrderTrackingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(
        order: Order,
        cloudKitService: CloudKitService,
        onClose: @escaping () -> Void
    ) {
        self.order = order
        self.onClose = onClose
        self._viewModel = StateObject(wrappedValue: OrderTrackingViewModel(
            order: order,
            cloudKitService: cloudKitService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Order Status Header
                OrderStatusHeader(
                    order: viewModel.currentOrder,
                    estimatedArrival: viewModel.estimatedArrival
                )
                
                // Map View
                if viewModel.showMap {
                    OrderTrackingMapView(
                        deliveryLocation: viewModel.currentOrder.deliveryAddress,
                        driverLocation: viewModel.driverLocation,
                        orderStatus: viewModel.currentOrder.status
                    )
                    .frame(height: 300)
                } else {
                    OrderStatusTimeline(
                        order: viewModel.currentOrder,
                        statusUpdates: viewModel.statusUpdates
                    )
                }
                
                // Toggle Map/Timeline
                HStack {
                    Button(action: { viewModel.showMap = false }) {
                        HStack {
                            Image(systemName: "list.bullet")
                            Text("Timeline")
                        }
                        .font(.labelMedium)
                        .foregroundColor(viewModel.showMap ? .gray600 : .emerald)
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.showMap = true }) {
                        HStack {
                            Image(systemName: "map")
                            Text("Map")
                        }
                        .font(.labelMedium)
                        .foregroundColor(viewModel.showMap ? .emerald : .gray600)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(Color.gray50)
                
                // Order Details
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Driver Information
                        if let driver = viewModel.assignedDriver {
                            DriverInfoCard(driver: driver)
                        }
                        
                        // Order Items
                        OrderItemsList(items: viewModel.currentOrder.items)
                        
                        // Delivery Information
                        DeliveryInfoCard(order: viewModel.currentOrder)
                        
                        // Contact Options
                        ContactOptionsCard(
                            onCallDriver: viewModel.callDriver,
                            onCallSupport: viewModel.callSupport,
                            onReportIssue: viewModel.reportIssue
                        )
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.lg)
                }
            }
            .navigationTitle("Order Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose()
                    }
                }
            }
            .alert("Order Update", isPresented: $viewModel.showingStatusUpdate) {
                Button("OK") {
                    viewModel.clearStatusUpdate()
                }
            } message: {
                Text(viewModel.statusUpdateMessage)
            }
        }
        .task {
            await viewModel.startTracking()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
    }
}

// MARK: - Order Status Header

struct OrderStatusHeader: View {
    let order: Order
    let estimatedArrival: Date?
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Order #\(String(order.id.prefix(8)).uppercased())")
                        .font(.titleMedium)
                        .foregroundColor(.graphite)
                    
                    Text(order.status.displayName)
                        .font(.bodyMedium)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                Image(systemName: order.status.iconName)
                    .font(.title2)
                    .foregroundColor(statusColor)
            }
            
            if let arrival = estimatedArrival {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.emerald)
                    Text("Estimated arrival: \(formatTime(arrival))")
                        .font(.bodyMedium)
                        .foregroundColor(.graphite)
                    Spacer()
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color.gray200)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private var statusColor: Color {
        switch order.status {
        case .delivered:
            return .success
        case .cancelled, .failed:
            return .error
        case .delivering, .pickedUp:
            return .info
        default:
            return .warning
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Order Status Timeline

struct OrderStatusTimeline: View {
    let order: Order
    let statusUpdates: [OrderStatusUpdate]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Order Progress")
                    .font(.titleMedium)
                    .foregroundColor(.graphite)
                    .padding(.horizontal, Spacing.md)
                
                LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                    ForEach(statusUpdates) { update in
                        TimelineItem(
                            status: update.status,
                            timestamp: update.timestamp,
                            message: update.message,
                            isCompleted: update.isCompleted,
                            isActive: update.status == order.status
                        )
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.lg)
        }
    }
}

struct TimelineItem: View {
    let status: OrderStatus
    let timestamp: Date?
    let message: String
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                if !isActive {
                    Rectangle()
                        .fill(Color.gray300)
                        .frame(width: 2, height: 40)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(status.displayName)
                    .font(.labelMedium)
                    .foregroundColor(isCompleted ? .graphite : .gray500)
                
                Text(message)
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                
                if let timestamp = timestamp {
                    Text(formatTimestamp(timestamp))
                        .font(.caption)
                        .foregroundColor(.gray500)
                }
            }
            
            Spacer()
        }
    }
    
    private var indicatorColor: Color {
        if isCompleted {
            return .success
        } else if isActive {
            return .info
        } else {
            return .gray300
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Driver Info Card

struct DriverInfoCard: View {
    let driver: Driver
    
    var body: some View {
        AppCard {
            HStack(spacing: Spacing.md) {
                // Driver Avatar
                AsyncImage(url: driver.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray300)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray500)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(driver.name)
                        .font(.titleSmall)
                        .foregroundColor(.graphite)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.warning)
                            .font(.caption)
                        Text(String(format: "%.1f", driver.rating))
                            .font(.bodySmall)
                            .foregroundColor(.gray600)
                        Text("• \(driver.completedDeliveries) deliveries")
                            .font(.bodySmall)
                            .foregroundColor(.gray500)
                    }
                    
                    Text("\(driver.vehicleType.displayName) • \(driver.licensePlate)")
                        .font(.bodySmall)
                        .foregroundColor(.gray600)
                }
                
                Spacer()
                
                Button(action: {
                    // Call driver
                }) {
                    Image(systemName: "phone.fill")
                        .font(.title3)
                        .foregroundColor(.emerald)
                }
                .accessibilityLabel("Call driver")
            }
        }
    }
}

// MARK: - Order Items List

struct OrderItemsList: View {
    let items: [OrderItem]
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Order Items")
                    .font(.titleSmall)
                    .foregroundColor(.graphite)
                
                ForEach(items) { item in
                    HStack {
                        Text("\(item.quantity)x")
                            .font(.bodyMedium)
                            .foregroundColor(.gray600)
                            .frame(width: 30, alignment: .leading)
                        
                        Text(item.productName)
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                        
                        Spacer()
                        
                        Text(formatPrice(item.totalPriceCents))
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                    }
                    
                    if item.specialInstructions != nil {
                        Text("Note: \(item.specialInstructions!)")
                            .font(.bodySmall)
                            .foregroundColor(.gray500)
                            .padding(.leading, 30)
                    }
                }
            }
        }
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Delivery Info Card

struct DeliveryInfoCard: View {
    let order: Order
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Delivery Information")
                    .font(.titleSmall)
                    .foregroundColor(.graphite)
                
                HStack(alignment: .top) {
                    Image(systemName: "location")
                        .foregroundColor(.emerald)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Delivery Address")
                            .font(.labelMedium)
                            .foregroundColor(.gray600)
                        
                        Text(order.deliveryAddress.formattedAddress)
                            .font(.bodyMedium)
                            .foregroundColor(.graphite)
                        
                        if let instructions = order.deliveryInstructions {
                            Text("Instructions: \(instructions)")
                                .font(.bodySmall)
                                .foregroundColor(.gray500)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Contact Options Card

struct ContactOptionsCard: View {
    let onCallDriver: () -> Void
    let onCallSupport: () -> Void
    let onReportIssue: () -> Void
    
    var body: some View {
        AppCard {
            VStack(spacing: Spacing.md) {
                Text("Need Help?")
                    .font(.titleSmall)
                    .foregroundColor(.graphite)
                
                VStack(spacing: Spacing.sm) {
                    SecondaryButton(
                        title: "Call Driver",
                        action: onCallDriver
                    )
                    
                    SecondaryButton(
                        title: "Contact Support",
                        action: onCallSupport
                    )
                    
                    SecondaryButton(
                        title: "Report Issue",
                        action: onReportIssue
                    )
                }
            }
        }
    }
}

// MARK: - Order Tracking View Model

@MainActor
class OrderTrackingViewModel: ObservableObject {
    @Published var currentOrder: Order
    @Published var driverLocation: DriverLocation?
    @Published var assignedDriver: Driver?
    @Published var estimatedArrival: Date?
    @Published var statusUpdates: [OrderStatusUpdate] = []
    @Published var showMap = true
    @Published var showingStatusUpdate = false
    @Published var statusUpdateMessage = ""
    @Published var showingDeliveryCompletion = false
    @Published var deliveryCompletionData: DeliveryCompletionData?
    
    private let cloudKitService: CloudKitService
    private var trackingTimer: Timer?
    
    init(order: Order, cloudKitService: CloudKitService) {
        self.currentOrder = order
        self.cloudKitService = cloudKitService
        self.estimatedArrival = order.estimatedDeliveryTime
        generateInitialStatusUpdates()
    }
    
    func startTracking() async {
        // Start real-time tracking
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await self.updateOrderStatus()
                await self.updateDriverLocation()
            }
        }
        
        // Initial load
        await updateOrderStatus()
        await updateDriverLocation()
        await loadAssignedDriver()
    }
    
    func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }
    
    func callDriver() {
        // Implement driver calling functionality
        if let phoneNumber = assignedDriver?.phoneNumber,
           let url = URL(string: "tel:\(phoneNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    func callSupport() {
        // Implement support calling functionality
        if let url = URL(string: "tel:+1-800-MIMISUPPLY") {
            UIApplication.shared.open(url)
        }
    }
    
    func reportIssue() {
        // Implement issue reporting functionality
        statusUpdateMessage = "Issue reporting feature coming soon"
        showingStatusUpdate = true
    }
    
    func clearStatusUpdate() {
        showingStatusUpdate = false
        statusUpdateMessage = ""
    }
    
    func handleOrderStatusUpdate(_ newStatus: OrderStatus) async {
        currentOrder = Order(
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
        
        statusUpdateMessage = "Order status updated to \(newStatus.displayName)"
        showingStatusUpdate = true
        
        if newStatus == .delivered {
            await handleDeliveryCompletion()
        }
    }
    
    func calculateETA() async {
        guard let driverLoc = driverLocation else {
            estimatedArrival = currentOrder.estimatedDeliveryTime
            return
        }
        
        // Simple ETA calculation based on distance and average speed
        let deliveryCoordinate = geocodeAddress(currentOrder.deliveryAddress)
        let driverCoordinate = driverLoc.location
        
        let distance = calculateDistance(from: driverCoordinate.clLocationCoordinate2D, to: deliveryCoordinate)
        let averageSpeedKmh = 30.0 // Average city driving speed
        let etaMinutes = (distance / 1000.0) / averageSpeedKmh * 60.0
        
        estimatedArrival = Date().addingTimeInterval(etaMinutes * 60)
    }
    
    func handleDeliveryCompletion() async {
        deliveryCompletionData = DeliveryCompletionData(
            orderId: currentOrder.id,
            driverId: assignedDriver?.id ?? "unknown",
            completedAt: Date()
        )
        showingDeliveryCompletion = true
    }
    
    private func updateOrderStatus() async {
        // In a real implementation, this would fetch the latest order status
        // For now, we'll simulate status updates
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
    
    private func geocodeAddress(_ address: Address) -> CLLocationCoordinate2D {
        // In a real implementation, this would use CLGeocoder
        // For now, return a mock coordinate for San Francisco
        return CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
    
    private func updateDriverLocation() async {
        guard let driverId = currentOrder.driverId else { return }
        
        do {
            driverLocation = try await cloudKitService.fetchDriverLocation(for: driverId)
        } catch {
            print("Failed to update driver location: \(error)")
        }
    }
    
    private func loadAssignedDriver() async {
        // In a real implementation, this would fetch driver details
        // For now, we'll create a mock driver
        if currentOrder.driverId != nil {
            assignedDriver = Driver(
                id: "driver123",
                userId: "user123",
                name: "John Doe",
                phoneNumber: "+1-555-0123",
                vehicleType: .car,
                licensePlate: "ABC-123",
                isOnline: true,
                isAvailable: false,
                rating: 4.8,
                completedDeliveries: 247,
                verificationStatus: .verified
            )
        }
    }
    
    private func generateInitialStatusUpdates() {
        statusUpdates = [
            OrderStatusUpdate(
                id: "1",
                status: .created,
                timestamp: currentOrder.createdAt,
                message: "Order placed successfully",
                isCompleted: true
            ),
            OrderStatusUpdate(
                id: "2",
                status: .paymentConfirmed,
                timestamp: currentOrder.createdAt.addingTimeInterval(30),
                message: "Payment confirmed",
                isCompleted: currentOrder.status.rawValue >= OrderStatus.paymentConfirmed.rawValue
            ),
            OrderStatusUpdate(
                id: "3",
                status: .accepted,
                timestamp: currentOrder.createdAt.addingTimeInterval(120),
                message: "Restaurant accepted your order",
                isCompleted: currentOrder.status.rawValue >= OrderStatus.accepted.rawValue
            ),
            OrderStatusUpdate(
                id: "4",
                status: .preparing,
                timestamp: nil,
                message: "Your order is being prepared",
                isCompleted: currentOrder.status.rawValue >= OrderStatus.preparing.rawValue
            ),
            OrderStatusUpdate(
                id: "5",
                status: .readyForPickup,
                timestamp: nil,
                message: "Order ready for pickup",
                isCompleted: currentOrder.status.rawValue >= OrderStatus.readyForPickup.rawValue
            ),
            OrderStatusUpdate(
                id: "6",
                status: .pickedUp,
                timestamp: nil,
                message: "Driver picked up your order",
                isCompleted: currentOrder.status.rawValue >= OrderStatus.pickedUp.rawValue
            ),
            OrderStatusUpdate(
                id: "7",
                status: .delivering,
                timestamp: nil,
                message: "On the way to you",
                isCompleted: currentOrder.status.rawValue >= OrderStatus.delivering.rawValue
            ),
            OrderStatusUpdate(
                id: "8",
                status: .delivered,
                timestamp: nil,
                message: "Order delivered",
                isCompleted: currentOrder.status == .delivered
            )
        ]
    }
}

// MARK: - Supporting Models

struct OrderStatusUpdate: Identifiable {
    let id: String
    let status: OrderStatus
    let timestamp: Date?
    let message: String
    let isCompleted: Bool
}

// MARK: - Preview

#if DEBUG
struct OrderTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        OrderTrackingView(
            order: sampleOrder,
            cloudKitService: CloudKitServiceImpl(),
            onClose: { }
        )
    }
    
    static var sampleOrder: Order {
        Order(
            customerId: "customer123",
            partnerId: "partner123",
            items: [
                OrderItem(
                    productId: "product1",
                    productName: "Pizza Margherita",
                    quantity: 1,
                    unitPriceCents: 1200
                )
            ],
            status: .preparing,
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
}
#endif
