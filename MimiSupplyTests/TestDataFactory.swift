//
//  TestDataFactory.swift
//  MimiSupplyTests
//
//  Created by Kiro on 16.08.25.
//

import Foundation
import CoreLocation
@testable import MimiSupply

/// Factory for creating consistent test data across all test suites
class TestDataFactory {
    
    // MARK: - User Test Data
    
    static func createTestUser(
        id: String = "test-user-123",
        role: UserRole = .customer,
        email: String = "test@example.com",
        isVerified: Bool = true
    ) -> UserProfile {
        return UserProfile(
            id: id,
            appleUserID: "apple-\(id)",
            email: email,
            fullName: PersonNameComponents(givenName: "Test", familyName: "User"),
            role: role,
            phoneNumber: "+1234567890",
            profileImageURL: URL(string: "https://example.com/avatar.jpg"),
            isVerified: isVerified,
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            lastActiveAt: Date()
        )
    }
    
    static func createTestDriver(
        id: String = "test-driver-123",
        isOnline: Bool = true,
        isAvailable: Bool = true
    ) -> Driver {
        return Driver(
            id: id,
            userId: "user-\(id)",
            vehicleType: .car,
            licensePlate: "TEST123",
            isOnline: isOnline,
            isAvailable: isAvailable,
            currentLocation: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            rating: 4.8,
            completedDeliveries: 150,
            verificationStatus: .verified,
            createdAt: Date().addingTimeInterval(-2592000) // 30 days ago
        )
    }
    
    // MARK: - Partner Test Data
    
    static func createTestPartner(
        id: String = "test-partner-123",
        name: String = "Test Restaurant",
        category: PartnerCategory = .restaurant,
        isActive: Bool = true,
        rating: Double = 4.5
    ) -> Partner {
        return Partner(
            id: id,
            name: name,
            category: category,
            description: "A test restaurant for unit testing",
            address: createTestAddress(),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "test@restaurant.com",
            heroImageURL: URL(string: "https://picsum.photos/400/200"),
            logoURL: URL(string: "https://picsum.photos/100/100"),
            isVerified: true,
            isActive: isActive,
            rating: rating,
            reviewCount: 100,
            openingHours: createTestOpeningHours(),
            deliveryRadius: 5.0,
            minimumOrderAmount: 1000, // $10.00
            estimatedDeliveryTime: 30,
            createdAt: Date().addingTimeInterval(-86400)
        )
    }
    
    static func createTestPartners(count: Int = 5) -> [Partner] {
        return (1...count).map { index in
            createTestPartner(
                id: "test-partner-\(index)",
                name: "Test Partner \(index)",
                category: PartnerCategory.allCases[index % PartnerCategory.allCases.count],
                rating: Double.random(in: 3.5...5.0)
            )
        }
    }
    
    // MARK: - Product Test Data
    
    static func createTestProduct(
        id: String = "test-product-123",
        partnerId: String = "test-partner-123",
        name: String = "Test Product",
        priceCents: Int = 999,
        isAvailable: Bool = true,
        stockQuantity: Int? = nil
    ) -> Product {
        return Product(
            id: id,
            partnerId: partnerId,
            name: name,
            description: "A delicious test product",
            priceCents: priceCents,
            originalPriceCents: priceCents + 200,
            category: .food,
            imageURLs: [
                URL(string: "https://picsum.photos/300/300")!,
                URL(string: "https://picsum.photos/300/301")!
            ],
            isAvailable: isAvailable,
            stockQuantity: stockQuantity,
            nutritionInfo: createTestNutritionInfo(),
            allergens: [.gluten, .dairy],
            tags: ["popular", "spicy"],
            weight: Measurement(value: 250, unit: UnitMass.grams),
            dimensions: ProductDimensions(
                length: 10,
                width: 10,
                height: 5,
                unit: .centimeters
            ),
            createdAt: Date().addingTimeInterval(-3600),
            updatedAt: Date()
        )
    }
    
    static func createTestProducts(
        partnerId: String = "test-partner-123",
        count: Int = 10
    ) -> [Product] {
        return (1...count).map { index in
            createTestProduct(
                id: "test-product-\(index)",
                partnerId: partnerId,
                name: "Test Product \(index)",
                priceCents: Int.random(in: 500...2000),
                isAvailable: index % 5 != 0, // Make every 5th product unavailable
                stockQuantity: index % 3 == 0 ? Int.random(in: 1...10) : nil
            )
        }
    }
    
    // MARK: - Order Test Data
    
    static func createTestOrder(
        id: String = "test-order-123",
        customerId: String = "test-customer-123",
        partnerId: String = "test-partner-123",
        driverId: String? = "test-driver-123",
        status: OrderStatus = .created,
        itemCount: Int = 2
    ) -> Order {
        let items = createTestOrderItems(count: itemCount)
        let subtotal = items.reduce(0) { $0 + $1.totalPriceCents }
        let deliveryFee = 299 // $2.99
        let platformFee = 199 // $1.99
        let tax = Int(Double(subtotal) * 0.08) // 8% tax
        let tip = 500 // $5.00
        
        return Order(
            id: id,
            customerId: customerId,
            partnerId: partnerId,
            driverId: driverId,
            items: items,
            status: status,
            subtotalCents: subtotal,
            deliveryFeeCents: deliveryFee,
            platformFeeCents: platformFee,
            taxCents: tax,
            tipCents: tip,
            totalCents: subtotal + deliveryFee + platformFee + tax + tip,
            deliveryAddress: createTestAddress(),
            deliveryInstructions: "Leave at door",
            estimatedDeliveryTime: Date().addingTimeInterval(1800), // 30 minutes
            actualDeliveryTime: status == .delivered ? Date() : nil,
            paymentMethod: .applePay,
            paymentStatus: status == .created ? .pending : .completed,
            createdAt: Date().addingTimeInterval(-600), // 10 minutes ago
            updatedAt: Date()
        )
    }
    
    static func createTestOrderItems(count: Int = 2) -> [OrderItem] {
        return (1...count).map { index in
            let unitPrice = Int.random(in: 500...1500)
            let quantity = Int.random(in: 1...3)
            
            return OrderItem(
                id: "test-order-item-\(index)",
                productId: "test-product-\(index)",
                productName: "Test Product \(index)",
                quantity: quantity,
                unitPriceCents: unitPrice,
                totalPriceCents: unitPrice * quantity,
                specialInstructions: index == 1 ? "Extra spicy" : nil
            )
        }
    }
    
    // MARK: - Cart Test Data
    
    static func createTestCartItem(
        id: String = "test-cart-item-123",
        product: Product? = nil,
        quantity: Int = 1,
        specialInstructions: String? = nil
    ) -> CartItem {
        let testProduct = product ?? createTestProduct()
        
        return CartItem(
            id: id,
            product: testProduct,
            quantity: quantity,
            specialInstructions: specialInstructions
        )
    }
    
    static func createTestCartItems(count: Int = 3) -> [CartItem] {
        return (1...count).map { index in
            createTestCartItem(
                id: "test-cart-item-\(index)",
                product: createTestProduct(
                    id: "test-product-\(index)",
                    name: "Cart Product \(index)",
                    priceCents: Int.random(in: 500...2000)
                ),
                quantity: Int.random(in: 1...3),
                specialInstructions: index == 1 ? "No onions" : nil
            )
        }
    }
    
    // MARK: - Address Test Data
    
    static func createTestAddress(
        street: String = "123 Test Street",
        city: String = "San Francisco",
        state: String = "CA",
        postalCode: String = "94102"
    ) -> Address {
        return Address(
            street: street,
            city: city,
            state: state,
            postalCode: postalCode,
            country: "US",
            apartment: "Apt 4B",
            deliveryInstructions: "Ring doorbell twice"
        )
    }
    
    // MARK: - Location Test Data
    
    static func createTestDriverLocation(
        driverId: String = "test-driver-123",
        latitude: Double = 37.7749,
        longitude: Double = -122.4194
    ) -> DriverLocation {
        return DriverLocation(
            driverId: driverId,
            location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            heading: 45.0,
            speed: 25.0, // mph
            accuracy: 5.0,
            timestamp: Date()
        )
    }
    
    // MARK: - Payment Test Data
    
    static func createTestPaymentResult(
        transactionId: String = "test-txn-123",
        status: PaymentStatus = .completed,
        amount: Int = 2500
    ) -> PaymentResult {
        return PaymentResult(
            transactionId: transactionId,
            status: status,
            amount: amount,
            timestamp: Date()
        )
    }
    
    static func createTestPaymentReceipt(
        orderId: String = "test-order-123",
        transactionId: String = "test-txn-123"
    ) -> PaymentReceipt {
        let order = createTestOrder(id: orderId)
        
        return PaymentReceipt(
            id: "test-receipt-123",
            orderId: orderId,
            transactionId: transactionId,
            amount: order.totalCents,
            paymentMethod: order.paymentMethod,
            status: .completed,
            timestamp: Date(),
            items: order.items.map { item in
                PaymentReceiptItem(
                    name: item.productName,
                    quantity: item.quantity,
                    unitPrice: item.unitPriceCents,
                    totalPrice: item.totalPriceCents
                )
            },
            subtotal: order.subtotalCents,
            deliveryFee: order.deliveryFeeCents,
            platformFee: order.platformFeeCents,
            tax: order.taxCents,
            tip: order.tipCents,
            total: order.totalCents,
            merchantName: "MimiSupply",
            customerEmail: "test@example.com",
            refundAmount: nil,
            refundDate: nil
        )
    }
    
    // MARK: - Helper Methods
    
    private static func createTestOpeningHours() -> [WeekDay: OpeningHours] {
        let standardHours = OpeningHours(
            open: DateComponents(hour: 9, minute: 0),
            close: DateComponents(hour: 22, minute: 0),
            isOpen: true
        )
        
        return [
            .monday: standardHours,
            .tuesday: standardHours,
            .wednesday: standardHours,
            .thursday: standardHours,
            .friday: standardHours,
            .saturday: OpeningHours(
                open: DateComponents(hour: 10, minute: 0),
                close: DateComponents(hour: 23, minute: 0),
                isOpen: true
            ),
            .sunday: OpeningHours(
                open: DateComponents(hour: 11, minute: 0),
                close: DateComponents(hour: 21, minute: 0),
                isOpen: true
            )
        ]
    }
    
    private static func createTestNutritionInfo() -> NutritionInfo {
        return NutritionInfo(
            calories: 250,
            protein: 15.0,
            carbohydrates: 30.0,
            fat: 8.0,
            fiber: 3.0,
            sugar: 5.0,
            sodium: 450.0
        )
    }
    
    // MARK: - Error Test Data
    
    static func createTestErrors() -> [AppError] {
        return [
            .authentication(.signInFailed("Test authentication error")),
            .network(.noConnection),
            .cloudKit(CKError(.networkUnavailable)),
            .location(.permissionDenied),
            .payment(.paymentFailed),
            .validation(.invalidEmail("test@invalid")),
            .unknown(NSError(domain: "TestDomain", code: 999, userInfo: [NSLocalizedDescriptionKey: "Test error"]))
        ]
    }
    
    // MARK: - Performance Test Data
    
    static func createLargeDataSet(partnerCount: Int = 100, productsPerPartner: Int = 50) -> (partners: [Partner], products: [Product]) {
        let partners = (1...partnerCount).map { index in
            createTestPartner(
                id: "partner-\(index)",
                name: "Partner \(index)",
                category: PartnerCategory.allCases[index % PartnerCategory.allCases.count]
            )
        }
        
        let products = partners.flatMap { partner in
            createTestProducts(partnerId: partner.id, count: productsPerPartner)
        }
        
        return (partners: partners, products: products)
    }
}

// MARK: - Supporting Types

struct ProductDimensions: Codable {
    let length: Double
    let width: Double
    let height: Double
    let unit: DimensionUnit
}

enum DimensionUnit: String, Codable {
    case centimeters = "cm"
    case inches = "in"
}

struct NutritionInfo: Codable {
    let calories: Int
    let protein: Double // grams
    let carbohydrates: Double // grams
    let fat: Double // grams
    let fiber: Double // grams
    let sugar: Double // grams
    let sodium: Double // milligrams
}

enum Allergen: String, CaseIterable, Codable {
    case gluten
    case dairy
    case nuts
    case soy
    case eggs
    case shellfish
    case fish
    case sesame
}

struct OpeningHours: Codable {
    let open: DateComponents
    let close: DateComponents
    let isOpen: Bool
}

enum WeekDay: String, CaseIterable, Codable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

enum VerificationStatus: String, Codable {
    case pending
    case verified
    case rejected
}

struct PaymentReceiptItem: Codable {
    let name: String
    let quantity: Int
    let unitPrice: Int
    let totalPrice: Int
}