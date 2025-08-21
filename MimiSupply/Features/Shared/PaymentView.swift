//
//  PaymentView.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import SwiftUI
import PassKit

/// View for handling Apple Pay payments
struct PaymentView: View {
    let order: Order
    let onPaymentSuccess: (PaymentResult) -> Void
    let onPaymentFailure: (Error) -> Void
    let onCancel: () -> Void
    
    @StateObject private var viewModel: PaymentViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(
        order: Order,
        paymentService: PaymentService,
        onPaymentSuccess: @escaping (PaymentResult) -> Void,
        onPaymentFailure: @escaping (Error) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.order = order
        self.onPaymentSuccess = onPaymentSuccess
        self.onPaymentFailure = onPaymentFailure
        self.onCancel = onCancel
        self._viewModel = StateObject(wrappedValue: PaymentViewModel(
            order: order,
            paymentService: paymentService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: Spacing.lg) {
                // Order Summary
                OrderSummarySection(order: order)
                
                // Payment Method Section
                PaymentMethodSection(
                    isApplePayAvailable: viewModel.isApplePayAvailable,
                    isProcessing: viewModel.isProcessingPayment
                )
                
                Spacer()
                
                // Apple Pay Button
                if viewModel.isApplePayAvailable {
                    ApplePayButton(
                        order: order,
                        isProcessing: viewModel.isProcessingPayment,
                        onPaymentRequest: {
                            await viewModel.processPayment()
                        }
                    )
                    .frame(height: 50)
                    .padding(.horizontal, Spacing.md)
                } else {
                    ApplePayUnavailableView()
                }
                
                // Cancel Button
                SecondaryButton(
                    title: "Cancel",
                    action: onCancel,
                    isDisabled: viewModel.isProcessingPayment
                )
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.lg)
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .disabled(viewModel.isProcessingPayment)
                }
            }
            .alert("Payment Error", isPresented: $viewModel.showingError) {
                Button("OK") {
                    viewModel.clearError()
                }
                Button("Retry") {
                    Task {
                        await viewModel.processPayment()
                    }
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onReceive(viewModel.$paymentResult) { result in
                if let result = result {
                    onPaymentSuccess(result)
                }
            }
            .onReceive(viewModel.$paymentError) { error in
                if let error = error {
                    onPaymentFailure(error)
                }
            }
        }
    }
}

// MARK: - Order Summary Section

struct OrderSummarySection: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Order Summary")
                .font(.titleLarge)
                .foregroundColor(.graphite)
            
            AppCard {
                VStack(spacing: Spacing.sm) {
                    // Order Items
                    ForEach(order.items) { item in
                        HStack {
                            Text("\(item.productName) × \(item.quantity)")
                                .font(.bodyMedium)
                                .foregroundColor(.graphite)
                            Spacer()
                            Text(formatPrice(item.totalPriceCents))
                                .font(.bodyMedium)
                                .foregroundColor(.graphite)
                        }
                    }
                    
                    AppDivider()
                    
                    // Fees and Totals
                    PriceBreakdownRow(label: "Subtotal", amount: order.subtotalCents)
                    
                    if order.deliveryFeeCents > 0 {
                        PriceBreakdownRow(label: "Delivery Fee", amount: order.deliveryFeeCents)
                    }
                    
                    if order.platformFeeCents > 0 {
                        PriceBreakdownRow(label: "Service Fee", amount: order.platformFeeCents)
                    }
                    
                    if order.taxCents > 0 {
                        PriceBreakdownRow(label: "Tax", amount: order.taxCents)
                    }
                    
                    if order.tipCents > 0 {
                        PriceBreakdownRow(label: "Tip", amount: order.tipCents)
                    }
                    
                    AppDivider()
                    
                    HStack {
                        Text("Total")
                            .font(.titleMedium)
                            .foregroundColor(.graphite)
                        Spacer()
                        Text(formatPrice(order.totalCents))
                            .font(.titleMedium)
                            .foregroundColor(.graphite)
                    }
                }
                .padding(Spacing.md)
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Price Breakdown Row

struct PriceBreakdownRow: View {
    let label: String
    let amount: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.bodyMedium)
                .foregroundColor(.gray600)
            Spacer()
            Text(formatPrice(amount))
                .font(.bodyMedium)
                .foregroundColor(.gray600)
        }
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Payment Method Section

struct PaymentMethodSection: View {
    let isApplePayAvailable: Bool
    let isProcessing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Payment Method")
                .font(.titleLarge)
                .foregroundColor(.graphite)
                .padding(.horizontal, Spacing.md)
            
            AppCard {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "creditcard")
                        .font(.title2)
                        .foregroundColor(isApplePayAvailable ? .emerald : .gray400)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Apple Pay")
                            .font(.titleSmall)
                            .foregroundColor(.graphite)
                        
                        Text(isApplePayAvailable ? "Ready to pay" : "Not available")
                            .font(.bodySmall)
                            .foregroundColor(isApplePayAvailable ? .success : .error)
                    }
                    
                    Spacer()
                    
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .emerald))
                            .scaleEffect(0.8)
                    } else if isApplePayAvailable {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.success)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.warning)
                    }
                }
                .padding(Spacing.md)
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Apple Pay Button

struct ApplePayButton: View {
    let order: Order
    let isProcessing: Bool
    let onPaymentRequest: () async -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await onPaymentRequest()
            }
        }) {
            HStack {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.labelLarge)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "apple.logo")
                        .font(.title3)
                        .foregroundColor(.white)
                    Text("Pay with Apple Pay")
                        .font(.labelLarge)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .cornerRadius(8)
        }
        .disabled(isProcessing)
        .accessibilityLabel("Pay \(order.formattedTotal) with Apple Pay")
        .accessibilityHint(isProcessing ? "Processing payment" : "Double tap to pay with Apple Pay")
    }
}

// MARK: - Apple Pay Unavailable View

struct ApplePayUnavailableView: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.warning)
            
            Text("Apple Pay Not Available")
                .font(.titleMedium)
                .foregroundColor(.graphite)
            
            Text("Please add a payment method to Apple Wallet or use a different device.")
                .font(.bodyMedium)
                .foregroundColor(.gray600)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .padding(Spacing.lg)
    }
}

// MARK: - Payment View Model

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var isProcessingPayment = false
    @Published var isApplePayAvailable = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var paymentResult: PaymentResult?
    @Published var paymentError: Error?
    
    private let order: Order
    private let paymentService: PaymentService
    
    init(order: Order, paymentService: PaymentService) {
        self.order = order
        self.paymentService = paymentService
        checkApplePayAvailability()
    }
    
    func processPayment() async {
        guard !isProcessingPayment else { return }
        
        isProcessingPayment = true
        clearError()
        
        do {
            let result = try await paymentService.processPayment(for: order)
            paymentResult = result
        } catch {
            paymentError = error
            handlePaymentError(error)
        }
        
        isProcessingPayment = false
    }
    
    func clearError() {
        showingError = false
        errorMessage = ""
        paymentError = nil
    }
    
    private func checkApplePayAvailability() {
        isApplePayAvailable = paymentService.validateMerchantCapability()
    }
    
    private func handlePaymentError(_ error: Error) {
        if let appError = error as? AppError,
           case .payment(let paymentError) = appError {
            errorMessage = paymentError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
}

// MARK: - Preview

#if DEBUG
struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView(
            order: sampleOrder,
            paymentService: PaymentServiceImpl(),
            onPaymentSuccess: { _ in },
            onPaymentFailure: { _ in },
            onCancel: { }
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
                ),
                OrderItem(
                    productId: "product2",
                    productName: "Coca Cola",
                    quantity: 2,
                    unitPriceCents: 300
                )
            ],
            subtotalCents: 1800,
            deliveryFeeCents: 200,
            platformFeeCents: 100,
            taxCents: 168,
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