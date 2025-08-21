//
//  CheckoutView.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI

/// Complete checkout flow including address, payment, and order confirmation
struct CheckoutView: View {
    let cartItems: [CartItem]
    let onOrderComplete: (Order) -> Void
    let onCancel: () -> Void
    
    @StateObject private var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(
        cartItems: [CartItem],
        paymentService: PaymentService,
        cloudKitService: CloudKitService,
        onOrderComplete: @escaping (Order) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.cartItems = cartItems
        self.onOrderComplete = onOrderComplete
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: CheckoutViewModel(
            cartItems: cartItems,
            paymentService: paymentService,
            cloudKitService: cloudKitService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
                CheckoutProgressView(currentStep: viewModel.currentStep)
                
                // Content based on current step
                switch viewModel.currentStep {
                case .deliveryAddress:
                    DeliveryAddressStep(
                        address: $viewModel.deliveryAddress,
                        instructions: $viewModel.deliveryInstructions,
                        onContinue: {
                            viewModel.proceedToPayment()
                        }
                    )
                    
                case .payment:
                    PaymentStep(
                        order: viewModel.pendingOrder!,
                        paymentService: viewModel.paymentService,
                        onPaymentSuccess: { result in
                            viewModel.handlePaymentSuccess(result)
                        },
                        onPaymentFailure: { error in
                            viewModel.handlePaymentFailure(error)
                        },
                        onBack: {
                            viewModel.goBackToAddress()
                        }
                    )
                    
                case .confirmation:
                    OrderConfirmationStep(
                        order: viewModel.completedOrder!,
                        paymentResult: viewModel.paymentResult!,
                        onComplete: {
                            onOrderComplete(viewModel.completedOrder!)
                        }
                    )
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .alert("Checkout Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Checkout Progress View

struct CheckoutProgressView: View {
    let currentStep: CheckoutStep
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(CheckoutStep.allCases, id: \.self) { step in
                HStack(spacing: Spacing.sm) {
                    Circle()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.emerald : Color.gray300)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(step.rawValue)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(step.rawValue <= currentStep.rawValue ? .white : .gray600)
                        )
                    
                    if step != CheckoutStep.allCases.last {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.emerald : Color.gray300)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.chalk)
    }
}

// MARK: - Delivery Address Step

struct DeliveryAddressStep: View {
    @Binding var address: Address?
    @Binding var instructions: String
    let onContinue: () -> Void
    
    @State private var street = ""
    @State private var apartment = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = "US"
    @State private var isValidatingAddress = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Delivery Address")
                    .font(.titleLarge)
                    .foregroundColor(.graphite)
                    .padding(.horizontal, Spacing.md)
                
                VStack(spacing: Spacing.md) {
                    AppTextField(
                        title: "Street Address",
                        placeholder: "123 Main Street",
                        text: $street
                    )
                    
                    AppTextField(
                        title: "Apartment/Unit (Optional)",
                        placeholder: "Apt 4B",
                        text: $apartment
                    )
                    
                    HStack(spacing: Spacing.md) {
                        AppTextField(
                            title: "City",
                            placeholder: "San Francisco",
                            text: $city
                        )
                        
                        AppTextField(
                            title: "State",
                            placeholder: "CA",
                            text: $state
                        )
                        .frame(maxWidth: 100)
                    }
                    
                    AppTextField(
                        title: "ZIP Code",
                        placeholder: "94105",
                        text: $postalCode
                    )
                    .keyboardType(.numberPad)
                    
                    AppTextField(
                        title: "Delivery Instructions (Optional)",
                        placeholder: "Leave at door, ring bell, etc.",
                        text: $instructions
                    )
                }
                .padding(.horizontal, Spacing.md)
                
                Spacer()
                
                PrimaryButton(
                    title: "Continue to Payment",
                    action: {
                        updateAddress()
                        onContinue()
                    },
                    isLoading: isValidatingAddress,
                    isDisabled: !isAddressValid || isValidatingAddress
                )
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
            }
        }
        .onAppear {
            loadExistingAddress()
        }
    }
    
    private var isAddressValid: Bool {
        !street.isEmpty && !city.isEmpty && !state.isEmpty && !postalCode.isEmpty
    }
    
    private func loadExistingAddress() {
        if let address = address {
            street = address.street
            apartment = address.apartment ?? ""
            city = address.city
            state = address.state
            postalCode = address.postalCode
            country = address.country
        }
    }
    
    private func updateAddress() {
        address = Address(
            street: street,
            city: city,
            state: state,
            postalCode: postalCode,
            country: country,
            apartment: apartment.isEmpty ? nil : apartment,
            deliveryInstructions: instructions.isEmpty ? nil : instructions
        )
    }
}

// MARK: - Payment Step

struct PaymentStep: View {
    let order: Order
    let paymentService: PaymentService
    let onPaymentSuccess: (PaymentResult) -> Void
    let onPaymentFailure: (Error) -> Void
    let onBack: () -> Void
    
    var body: some View {
        PaymentView(
            order: order,
            paymentService: paymentService,
            onPaymentSuccess: onPaymentSuccess,
            onPaymentFailure: onPaymentFailure,
            onCancel: onBack
        )
    }
}

// MARK: - Order Confirmation Step

struct OrderConfirmationStep: View {
    let order: Order
    let paymentResult: PaymentResult
    let onComplete: () -> Void
    
    var body: some View {
        CompletedCheckoutView(
            order: order,
            onTrackOrder: {
                onComplete()
            },
            onContinueShopping: {
                onComplete()
            }
        )
    }
}

// MARK: - Checkout View Model

@MainActor
class CheckoutViewModel: ObservableObject {
    @Published var currentStep: CheckoutStep = .deliveryAddress
    @Published var deliveryAddress: Address?
    @Published var deliveryInstructions = ""
    @Published var isProcessing = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var estimatedDeliveryTime: Date?
    @Published var selectedDeliveryTime: Date?
    @Published var availableDeliverySlots: [DeliveryTimeSlot] = []
    
    // Order state
    @Published var pendingOrder: Order?
    @Published var completedOrder: Order?
    @Published var paymentResult: PaymentResult?
    
    private let cartItems: [CartItem]
    let paymentService: PaymentService
    private let cloudKitService: CloudKitService
    
    init(
        cartItems: [CartItem],
        paymentService: PaymentService,
        cloudKitService: CloudKitService
    ) {
        self.cartItems = cartItems
        self.paymentService = paymentService
        self.cloudKitService = cloudKitService
    }
    
    func proceedToPayment() {
        guard let address = deliveryAddress else {
            showError("Please enter a delivery address")
            return
        }
        
        Task {
            await calculateDeliveryTimeAndProceed(with: address)
        }
    }
    
    private func calculateDeliveryTimeAndProceed(with address: Address) async {
        isProcessing = true
        
        do {
            // Calculate delivery time estimation
            let deliveryTime = await calculateDeliveryTime(for: address)
            estimatedDeliveryTime = deliveryTime
            
            // Generate available delivery slots
            availableDeliverySlots = generateDeliverySlots(from: deliveryTime)
            selectedDeliveryTime = deliveryTime
            
            // Create pending order with estimated delivery time
            pendingOrder = createOrder(with: address, estimatedDeliveryTime: deliveryTime)
            currentStep = .payment
            
        } catch {
            showError("Failed to calculate delivery time: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    func goBackToAddress() {
        currentStep = .deliveryAddress
    }
    
    func handlePaymentSuccess(_ result: PaymentResult) {
        paymentResult = result
        
        Task {
            await createOrderInCloudKitAndAssignDriver()
        }
    }
    
    func handlePaymentFailure(_ error: Error) {
        showError(error.localizedDescription)
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
    }
    
    private func createOrder(with address: Address, estimatedDeliveryTime: Date? = nil) -> Order {
        let orderItems = cartItems.map { cartItem in
            OrderItem(
                productId: cartItem.product.id,
                productName: cartItem.product.name,
                quantity: cartItem.quantity,
                unitPriceCents: cartItem.product.priceCents
            )
        }
        
        let subtotal = orderItems.reduce(0) { $0 + $1.totalPriceCents }
        let deliveryFee = calculateDeliveryFee(for: address)
        let platformFee = calculatePlatformFee(subtotal: subtotal)
        let tax = calculateTax(subtotal: subtotal, deliveryFee: deliveryFee, platformFee: platformFee)
        
        return Order(
            customerId: "current_user_id", // Would come from auth service
            partnerId: cartItems.first?.product.partnerId ?? "",
            items: orderItems,
            subtotalCents: subtotal,
            deliveryFeeCents: deliveryFee,
            platformFeeCents: platformFee,
            taxCents: tax,
            deliveryAddress: address,
            deliveryInstructions: deliveryInstructions.isEmpty ? nil : deliveryInstructions,
            estimatedDeliveryTime: (selectedDeliveryTime ?? estimatedDeliveryTime) ?? Date(),
            paymentMethod: .applePay
        )
    }
    
    private func calculateDeliveryFee(for address: Address) -> Int {
        // Enhanced delivery fee calculation based on distance and time
        // In a real implementation, this would use location services to calculate distance
        let baseDeliveryFee = 299 // $2.99
        
        // Add surge pricing during peak hours
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isPeakHour = (hour >= 11 && hour <= 14) || (hour >= 17 && hour <= 20)
        
        if isPeakHour {
            return Int(Double(baseDeliveryFee) * 1.5) // 50% surge
        }
        
        return baseDeliveryFee
    }
    
    private func calculatePlatformFee(subtotal: Int) -> Int {
        // Platform fee as percentage of subtotal
        return Int(Double(subtotal) * 0.05) // 5%
    }
    
    private func calculateTax(subtotal: Int, deliveryFee: Int, platformFee: Int) -> Int {
        // Tax calculation (simplified)
        let taxableAmount = subtotal + deliveryFee + platformFee
        return Int(Double(taxableAmount) * 0.08) // 8% tax
    }
    
    private func createOrderInCloudKitAndAssignDriver() async {
        guard let order = pendingOrder else { return }
        
        isProcessing = true
        
        do {
            // Update order status to payment confirmed
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
                deliveryAddress: order.deliveryAddress,
                deliveryInstructions: order.deliveryInstructions,
                estimatedDeliveryTime: order.estimatedDeliveryTime,
                paymentMethod: order.paymentMethod,
                paymentStatus: .completed
            )
            
            // Save to CloudKit
            completedOrder = try await cloudKitService.createOrder(confirmedOrder)
            
            // Attempt to assign a driver
            await assignDriverToOrder(completedOrder!)
            
            // Set up real-time order tracking
            await setupOrderTracking(completedOrder!)
            
            currentStep = .confirmation
            
        } catch {
            showError("Failed to create order: \(error.localizedDescription)")
        }
        
        isProcessing = false
    }
    
    private func assignDriverToOrder(_ order: Order) async {
        // In a real implementation, this would find the nearest available driver
        // For now, we'll simulate driver assignment
        do {
            // Simulate driver assignment delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Update order with assigned driver (simulated)
            try await cloudKitService.updateOrderStatus(order.id, status: .accepted)
            
        } catch {
            // Driver assignment failed, but order is still valid
            print("Driver assignment failed: \(error.localizedDescription)")
        }
    }
    
    private func setupOrderTracking(_ order: Order) async {
        do {
            // Subscribe to order updates for real-time tracking
            try await cloudKitService.subscribeToOrderUpdates(for: order.customerId)
            
            // If driver is assigned, subscribe to location updates
            if let driverId = order.driverId {
                try await cloudKitService.subscribeToDriverLocationUpdates(for: order.id)
            }
            
        } catch {
            print("Failed to setup order tracking: \(error.localizedDescription)")
        }
    }
    
    private func calculateDeliveryTime(for address: Address) async -> Date {
        // Enhanced delivery time calculation
        let baseDeliveryTime = 30 // 30 minutes base
        
        // Add time based on current order volume (simulated)
        let additionalTime = Int.random(in: 0...15) // 0-15 minutes additional
        
        // Add time for peak hours
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let isPeakHour = (hour >= 11 && hour <= 14) || (hour >= 17 && hour <= 20)
        let peakTimeAddition = isPeakHour ? 10 : 0
        
        let totalMinutes = baseDeliveryTime + additionalTime + peakTimeAddition
        return Date().addingTimeInterval(TimeInterval(totalMinutes * 60))
    }
    
    private func generateDeliverySlots(from estimatedTime: Date) -> [DeliveryTimeSlot] {
        var slots: [DeliveryTimeSlot] = []
        
        // ASAP slot
        slots.append(DeliveryTimeSlot(
            id: "asap",
            displayName: "ASAP",
            estimatedTime: estimatedTime,
            isAvailable: true
        ))
        
        // Generate 3 additional slots at 15-minute intervals
        for i in 1...3 {
            let slotTime = estimatedTime.addingTimeInterval(TimeInterval(i * 15 * 60))
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            slots.append(DeliveryTimeSlot(
                id: "slot_\(i)",
                displayName: formatter.string(from: slotTime),
                estimatedTime: slotTime,
                isAvailable: true
            ))
        }
        
        return slots
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Supporting Types

enum CheckoutStep: Int, CaseIterable {
    case deliveryAddress = 1
    case payment = 2
    case confirmation = 3
}

struct DeliveryTimeSlot: Identifiable, Equatable {
    let id: String
    let displayName: String
    let estimatedTime: Date
    let isAvailable: Bool
}

// CartItem model is defined in Data/Models/CartItem.swift

// MARK: - Preview

#if DEBUG
struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        CheckoutView(
            cartItems: sampleCartItems,
            paymentService: PaymentServiceImpl(),
            cloudKitService: CloudKitServiceImpl(),
            onOrderComplete: { _ in },
            onCancel: { }
        )
    }
    
    static var sampleCartItems: [CartItem] {
        [
            CartItem(
                product: Product(
                    partnerId: "partner1",
                    name: "Pizza Margherita",
                    description: "Classic Italian pizza",
                    priceCents: 1200,
                    category: .food
                ),
                quantity: 1
            ),
            CartItem(
                product: Product(
                    partnerId: "partner1",
                    name: "Coca Cola",
                    description: "Refreshing soft drink",
                    priceCents: 300,
                    category: .beverages
                ),
                quantity: 2
            )
        ]
    }
}
#endif