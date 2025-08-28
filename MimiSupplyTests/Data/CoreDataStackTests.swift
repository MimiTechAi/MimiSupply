//
//  CoreDataStackTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 13.08.25.
//

import XCTest
import CoreData
import CloudKit
@testable import MimiSupply

final class CoreDataStackTests: XCTestCase {
    
    var sut: CoreDataStack!
    
    override func setUpWithError() throws {
        super.setUp()
        // Use in-memory store for testing
        sut = CoreDataStack.shared
        
        // Configure for testing
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        sut.persistentContainer.persistentStoreDescriptions = [description]
        
        sut.persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load test store: \(error)")
            }
        }
    }
    
    override func tearDownWithError() throws {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Core Data Stack Tests
    
    func testPersistentContainerInitialization() {
        XCTAssertNotNil(sut.persistentContainer)
        XCTAssertNotNil(sut.viewContext)
    }
    
    func testBackgroundContextCreation() {
        let backgroundContext = sut.newBackgroundContext()
        XCTAssertNotNil(backgroundContext)
        XCTAssertNotEqual(backgroundContext, sut.viewContext)
    }
    
    func testSaveContext() {
        // Given
        let context = sut.viewContext
        
        // When
        sut.save()
        
        // Then
        XCTAssertFalse(context.hasChanges)
    }
    
    // MARK: - Cart Management Tests
    
    func testSaveAndLoadCartItems() {
        // Given
        let cartItems = createMockCartItems()
        
        // When
        sut.saveCartItems(cartItems)
        
        // Wait for background save to complete
        let expectation = XCTestExpectation(description: "Cart items saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let loadedItems = sut.loadCartItems()
        
        // Then
        XCTAssertEqual(loadedItems.count, cartItems.count)
        XCTAssertEqual(loadedItems.first?.id, cartItems.first?.id)
        XCTAssertEqual(loadedItems.first?.quantity, cartItems.first?.quantity)
    }
    
    func testClearCart() {
        // Given
        let cartItems = createMockCartItems()
        sut.saveCartItems(cartItems)
        
        // When
        sut.clearCart()
        
        // Wait for background operation to complete
        let expectation = XCTestExpectation(description: "Cart cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let loadedItems = sut.loadCartItems()
        
        // Then
        XCTAssertTrue(loadedItems.isEmpty)
    }
    
    // MARK: - Partner Caching Tests
    
    func testCacheAndLoadPartners() {
        // Given
        let partners = createMockPartners()
        
        // When
        sut.cachePartners(partners)
        
        // Wait for background save to complete
        let expectation = XCTestExpectation(description: "Partners cached")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let cachedPartners = sut.loadCachedPartners()
        
        // Then
        XCTAssertEqual(cachedPartners.count, partners.count)
        XCTAssertEqual(cachedPartners.first?.id, partners.first?.id)
        XCTAssertEqual(cachedPartners.first?.name, partners.first?.name)
    }
    
    // MARK: - Product Caching Tests
    
    func testCacheAndLoadProducts() {
        // Given
        let products = createMockProducts()
        let partnerId = "test-partner-id"
        
        // When
        sut.cacheProducts(products, for: partnerId)
        
        // Wait for background save to complete
        let expectation = XCTestExpectation(description: "Products cached")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        let cachedProducts = sut.loadCachedProducts(for: partnerId)
        
        // Then
        XCTAssertEqual(cachedProducts.count, products.count)
        XCTAssertEqual(cachedProducts.first?.id, products.first?.id)
        XCTAssertEqual(cachedProducts.first?.name, products.first?.name)
    }
    
    // MARK: - CloudKit Status Tests
    
    func testCheckCloudKitStatus() async {
        // When
        let status = await sut.checkCloudKitStatus()
        
        // Then
        XCTAssertTrue([
            .available,
            .noAccount,
            .restricted,
            .couldNotDetermine,
            .temporarilyUnavailable
        ].contains(status))
    }
    
    // MARK: - Helper Methods
    
    private func createMockCartItems() -> [CartItem] {
        let product = createMockProduct()
        let cartItem = CartItem(
            product: product,
            quantity: 2,
            specialInstructions: "Extra sauce"
        )
        return [cartItem]
    }
    
    private func createMockPartners() -> [Partner] {
        let address = Address(
            street: "123 Test St",
            city: "Test City",
            state: "CA",
            postalCode: "12345",
            country: "US"
        )
        
        let partner = Partner(
            name: "Test Restaurant",
            category: .restaurant,
            description: "A test restaurant",
            address: address,
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "test@restaurant.com",
            rating: 4.5,
            reviewCount: 100
        )
        
        return [partner]
    }
    
    private func createMockProducts() -> [Product] {
        let product = createMockProduct()
        return [product]
    }
    
    private func createMockProduct() -> Product {
        return Product(
            partnerId: "test-partner-id",
            name: "Test Pizza",
            description: "Delicious test pizza",
            priceCents: 1500,
            category: .food,
            imageURLs: [],
            isAvailable: true
        )
    }
}