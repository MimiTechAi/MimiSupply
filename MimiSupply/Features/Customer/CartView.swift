//
//  CartView.swift
//  MimiSupply
//
//  Created by Kiro on 14.08.25.
//

import SwiftUI

/// Shopping cart view with item management and checkout functionality
struct CartView: View {
    @StateObject private var viewModel = CartViewModel()
    @State private var showingCheckout = false
    @State private var showingOrderTracking = false
    @State private var completedOrder: Order?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.cartItems.isEmpty {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !viewModel.cartItems.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            Task {
                                await viewModel.clearCart()
                            }
                        }
                        .foregroundColor(.error)
                    }
                }
            }
            .sheet(isPresented: $showingCheckout) {
                CheckoutView(
                    cartItems: viewModel.cartItems,
                    paymentService: AppContainer.shared.paymentService,
                    cloudKitService: AppContainer.shared.cloudKitService,
                    onOrderComplete: { order in
                        handleOrderComplete(order)
                    },
                    onCancel: {
                        showingCheckout = false
                    }
                )
            }
            .sheet(isPresented: $showingOrderTracking) {
                if let order = completedOrder {
                    OrderTrackingView(
                        order: order,
                        cloudKitService: AppContainer.shared.cloudKitService,
                        onClose: {
                            showingOrderTracking = false
                            dismiss() // Close the entire cart flow
                        }
                    )
                }
            }
            .task {
                await viewModel.loadCartItems()
            }
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray300)
            
            VStack(spacing: Spacing.md) {
                Text("Your cart is empty")
                    .font(.headlineSmall)
                    .foregroundColor(.graphite)
                
                Text("Add some delicious items from our partners to get started")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }
            
            PrimaryButton(
                title: "Start Shopping",
                action: {
                    dismiss()
                }
            )
            .padding(.horizontal, Spacing.xl)
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cart is empty. Start shopping to add items.")
    }
    
    private var cartContentView: some View {
        VStack(spacing: 0) {
            // Cart items list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.cartItems) { item in
                        CartItemRow(
                            item: item,
                            onQuantityChange: { newQuantity in
                                Task {
                                    await viewModel.updateItemQuantity(
                                        itemId: item.id,
                                        quantity: newQuantity
                                    )
                                }
                            },
                            onRemove: {
                                Task {
                                    await viewModel.removeItem(withId: item.id)
                                }
                            }
                        )
                        
                        if item.id != viewModel.cartItems.last?.id {
                            AppDivider()
                                .padding(.horizontal, Spacing.md)
                        }
                    }
                }
                .padding(.vertical, Spacing.md)
            }
            
            // Order summary and checkout
            orderSummarySection
        }
    }
    
    private var orderSummarySection: some View {
        VStack(spacing: 0) {
            AppDivider()
            
            VStack(spacing: Spacing.md) {
                // Price breakdown
                OrderSummaryView(
                    subtotal: viewModel.subtotal,
                    deliveryFee: viewModel.deliveryFee,
                    platformFee: viewModel.platformFee,
                    tax: viewModel.tax,
                    tip: viewModel.tip,
                    total: viewModel.total,
                    onTipChange: { tipAmount in
                        viewModel.updateTip(amount: tipAmount)
                    }
                )
                
                // Checkout button
                PrimaryButton(
                    title: "Proceed to Checkout",
                    action: {
                        showingCheckout = true
                    },
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.cartItems.isEmpty
                )
            }
            .padding(Spacing.md)
            .background(Color.white)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleOrderComplete(_ order: Order) {
        showingCheckout = false
        completedOrder = order
        
        Task {
            // Clear cart after successful order
            await viewModel.clearCart()
            
            // Small delay to let checkout sheet dismiss
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Show order tracking
            showingOrderTracking = true
        }
    }
}

// MARK: - Supporting Views

struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Product image
            AsyncImage(url: item.product.imageURLs.first) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray200)
                    .overlay(
                        Image(systemName: item.product.category.iconName)
                            .foregroundColor(.gray400)
                            .font(.title2)
                    )
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Product name
                Text(item.product.name)
                    .font(.titleSmall)
                    .foregroundColor(.graphite)
                    .lineLimit(2)
                
                // Special instructions
                if let instructions = item.specialInstructions, !instructions.isEmpty {
                    Text("Note: \(instructions)")
                        .font(.caption)
                        .foregroundColor(.gray600)
                        .lineLimit(2)
                }
                
                // Price per item
                Text(item.product.formattedPrice)
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                
                Spacer()
                
                // Quantity controls and total
                HStack {
                    // Quantity controls
                    HStack(spacing: Spacing.sm) {
                        Button(action: {
                            onQuantityChange(max(0, item.quantity - 1))
                        }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(item.quantity > 1 ? .emerald : .gray400)
                                .font(.title3)
                        }
                        .disabled(item.quantity <= 1)
                        
                        Text("\(item.quantity)")
                            .font(.titleSmall)
                            .foregroundColor(.graphite)
                            .frame(minWidth: 25)
                        
                        Button(action: {
                            onQuantityChange(item.quantity + 1)
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.emerald)
                                .font(.title3)
                        }
                    }
                    
                    Spacer()
                    
                    // Total price
                    Text(item.formattedTotalPrice)
                        .font(.titleSmall)
                        .foregroundColor(.graphite)
                        .fontWeight(.medium)
                }
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "trash")
                    .foregroundColor(.error)
                    .font(.title3)
            }
            .accessibilityLabel("Remove \(item.product.name) from cart")
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.product.name), quantity \(item.quantity), \(item.formattedTotalPrice)")
    }
}

struct OrderSummaryView: View {
    let subtotal: Int
    let deliveryFee: Int
    let platformFee: Int
    let tax: Int
    let tip: Int
    let total: Int
    let onTipChange: ((Int) -> Void)?
    
    init(
        subtotal: Int,
        deliveryFee: Int,
        platformFee: Int,
        tax: Int,
        tip: Int,
        total: Int,
        onTipChange: ((Int) -> Void)? = nil
    ) {
        self.subtotal = subtotal
        self.deliveryFee = deliveryFee
        self.platformFee = platformFee
        self.tax = tax
        self.tip = tip
        self.total = total
        self.onTipChange = onTipChange
    }
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            SummaryRow(label: "Subtotal", amount: subtotal)
            SummaryRow(label: "Delivery Fee", amount: deliveryFee)
            SummaryRow(label: "Platform Fee", amount: platformFee)
            SummaryRow(label: "Tax", amount: tax)
            
            if let onTipChange = onTipChange {
                TipSelectionRow(
                    subtotal: subtotal,
                    currentTip: tip,
                    onTipChange: onTipChange
                )
            } else {
                SummaryRow(label: "Tip", amount: tip)
            }
            
            AppDivider()
            
            SummaryRow(
                label: "Total",
                amount: total,
                isTotal: true
            )
        }
    }
}

struct SummaryRow: View {
    let label: String
    let amount: Int
    let isTotal: Bool
    
    init(label: String, amount: Int, isTotal: Bool = false) {
        self.label = label
        self.amount = amount
        self.isTotal = isTotal
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .titleMedium : .bodyMedium)
                .foregroundColor(isTotal ? .graphite : .gray600)
            
            Spacer()
            
            Text(formatPrice(amount))
                .font(isTotal ? .titleMedium : .bodyMedium)
                .foregroundColor(.graphite)
                .fontWeight(isTotal ? .semibold : .regular)
        }
    }
    
    private func formatPrice(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

struct TipSelectionRow: View {
    let subtotal: Int
    let currentTip: Int
    let onTipChange: (Int) -> Void
    
    @State private var selectedTipPercentage: Double = 0.15
    @State private var customTipAmount: String = ""
    @State private var showingCustomTip: Bool = false
    
    private let tipPercentages: [Double] = [0.10, 0.15, 0.18, 0.20]
    
    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Tip")
                    .font(.bodyMedium)
                    .foregroundColor(.gray600)
                
                Spacer()
                
                Text(formatPrice(currentTip))
                    .font(.bodyMedium)
                    .foregroundColor(.graphite)
            }
            
            // Tip percentage buttons
            HStack(spacing: Spacing.sm) {
                ForEach(tipPercentages, id: \.self) { percentage in
                    Button(action: {
                        selectedTipPercentage = percentage
                        showingCustomTip = false
                        let tipAmount = Int(Double(subtotal) * percentage)
                        onTipChange(tipAmount)
                    }) {
                        Text("\(Int(percentage * 100))%")
                            .font(.labelMedium)
                            .foregroundColor(selectedTipPercentage == percentage ? .white : .emerald)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(selectedTipPercentage == percentage ? Color.emerald : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.emerald, lineWidth: 1)
                            )
                            .cornerRadius(6)
                    }
                }
                
                Button(action: {
                    showingCustomTip.toggle()
                }) {
                    Text("Custom")
                        .font(.labelMedium)
                        .foregroundColor(showingCustomTip ? .white : .emerald)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(showingCustomTip ? Color.emerald : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.emerald, lineWidth: 1)
                        )
                        .cornerRadius(6)
                }
            }
            
            if showingCustomTip {
                HStack {
                    Text("$")
                        .font(.bodyMedium)
                        .foregroundColor(.gray600)
                    
                    TextField("0.00", text: $customTipAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: customTipAmount) { _, newValue in
                            if let amount = Double(newValue) {
                                let tipCents = Int(amount * 100)
                                onTipChange(tipCents)
                            }
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

#Preview {
    CartView()
}