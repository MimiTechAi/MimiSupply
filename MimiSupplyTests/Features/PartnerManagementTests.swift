import XCTest
import CloudKit
@testable import MimiSupply

@MainActor
class PartnerManagementTests: XCTestCase {
    var viewModel: PartnerDashboardViewModel!
    var mockCloudKitService: MockCloudKitService!
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() {
        super.setUp()
        mockCloudKitService = MockCloudKitService()
        mockAuthService = MockAuthenticationService()
        viewModel = PartnerDashboardViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockCloudKitService = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Dashboard Tests
    
    func testInitializeLoadsAllData() async throws {
        // Given
        let mockUser = UserProfile.mockPartner
        let mockOrders = [Order.mockPendingOrder, Order.mockDeliveredOrder]
        let mockStats = PartnerStats(
            todayOrderCount: 5,
            todayRevenueCents: 12500,
            averageRating: 4.5,
            totalOrders: 150,
            totalRevenueCents: 250000
        )
        
        mockAuthService.currentUser = mockUser
        mockCloudKitService.mockOrders = mockOrders
        mockCloudKitService.mockPartnerStats = mockStats
        
        // When
        await viewModel.initialize()
        
        // Then
        XCTAssertEqual(viewModel.todayOrders, 5)
        XCTAssertEqual(viewModel.todayRevenue, 12500)
        XCTAssertEqual(viewModel.averageRating, 4.5)
        XCTAssertEqual(viewModel.pendingOrders.count, 1)
        XCTAssertEqual(viewModel.recentOrders.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testToggleOnlineStatusUpdatesCorrectly() async throws {
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        viewModel.isOnline = false
        
        // When
        viewModel.toggleOnlineStatus()
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(viewModel.isOnline)
        XCTAssertTrue(mockCloudKitService.updatePartnerStatusCalled)
    }
    
    func testUpdateOrderStatusCallsService() async throws {
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        let orderId = "test-order-id"
        let newStatus = OrderStatus.preparing
        
        // When
        viewModel.updateOrderStatus(orderId, status: newStatus)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockCloudKitService.updateOrderStatusCalled)
        XCTAssertEqual(mockCloudKitService.lastUpdatedOrderId, orderId)
        XCTAssertEqual(mockCloudKitService.lastUpdatedOrderStatus, newStatus)
    }
    
    func testErrorHandlingDisplaysError() async throws {
        // Given
        mockAuthService.currentUser = nil // This will cause an authentication error
        
        // When
        await viewModel.initialize()
        
        // Then
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }
    
    // MARK: - Product Management Tests
    
    func testProductManagementViewModel() async throws {
        let productViewModel = ProductManagementViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        let mockProducts = [Product.mockProduct1, Product.mockProduct2]
        mockAuthService.currentUser = mockUser
        mockCloudKitService.mockProducts = mockProducts
        
        // When
        await productViewModel.loadProducts()
        
        // Then
        XCTAssertEqual(productViewModel.products.count, 2)
        XCTAssertEqual(productViewModel.filteredProducts.count, 2)
        XCTAssertFalse(productViewModel.isLoading)
    }
    
    func testProductSearchFiltering() async throws {
        let productViewModel = ProductManagementViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        let mockProducts = [Product.mockProduct1, Product.mockProduct2, Product.mockProduct3]
        mockAuthService.currentUser = mockUser
        mockCloudKitService.mockProducts = mockProducts
        
        await productViewModel.loadProducts()
        
        // When
        productViewModel.searchText = "Pizza"
        
        // Then
        XCTAssertEqual(productViewModel.filteredProducts.count, 1)
        XCTAssertEqual(productViewModel.filteredProducts.first?.name, "Margherita Pizza")
    }
    
    func testToggleProductAvailability() async throws {
        let productViewModel = ProductManagementViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        let mockProduct = Product.mockProduct1
        mockAuthService.currentUser = mockUser
        mockCloudKitService.mockProducts = [mockProduct]
        
        await productViewModel.loadProducts()
        
        // When
        productViewModel.toggleProductAvailability(mockProduct)
        
        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertTrue(mockCloudKitService.updateProductCalled)
    }
    
    // MARK: - Analytics Tests
    
    func testAnalyticsViewModelLoadsData() async throws {
        let analyticsViewModel = AnalyticsDashboardViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        // When
        await analyticsViewModel.loadAnalytics(for: .week)
        
        // Then
        XCTAssertGreaterThan(analyticsViewModel.keyMetrics.totalRevenue, 0)
        XCTAssertGreaterThan(analyticsViewModel.keyMetrics.totalOrders, 0)
        XCTAssertFalse(analyticsViewModel.revenueData.isEmpty)
        XCTAssertFalse(analyticsViewModel.ordersData.isEmpty)
        XCTAssertFalse(analyticsViewModel.isLoading)
    }
    
    // MARK: - Business Hours Tests
    
    func testBusinessHoursViewModel() async throws {
        let hoursViewModel = BusinessHoursViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        // When
        await hoursViewModel.loadBusinessHours()
        
        // Then
        XCTAssertFalse(hoursViewModel.businessHours.isEmpty)
        XCTAssertGreaterThan(hoursViewModel.preparationTime, 0)
        XCTAssertGreaterThan(hoursViewModel.deliveryRadius, 0)
    }
    
    func testUpdateBusinessHours() async throws {
        let hoursViewModel = BusinessHoursViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        let openTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let closeTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        
        // When
        hoursViewModel.updateHours(for: .monday, hours: .open(openTime, closeTime))
        await hoursViewModel.saveChanges()
        
        // Then
        XCTAssertTrue(mockCloudKitService.updateBusinessSettingsCalled)
        XCTAssertEqual(hoursViewModel.businessHours[.monday], .open(openTime, closeTime))
    }
    
    // MARK: - Settings Tests
    
    func testPartnerSettingsViewModel() async throws {
        let settingsViewModel = PartnerSettingsViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        // When
        await settingsViewModel.loadSettings()
        
        // Then
        XCTAssertFalse(settingsViewModel.businessName.isEmpty)
        XCTAssertFalse(settingsViewModel.email.isEmpty)
        XCTAssertFalse(settingsViewModel.phoneNumber.isEmpty)
    }
    
    func testSaveSettingsUpdatesPartner() async throws {
        let settingsViewModel = PartnerSettingsViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        settingsViewModel.businessName = "Updated Business Name"
        settingsViewModel.email = "updated@example.com"
        
        // When
        await settingsViewModel.saveSettings()
        
        // Then
        XCTAssertTrue(mockCloudKitService.updatePartnerCalled)
        XCTAssertFalse(settingsViewModel.isSaving)
    }
    
    // MARK: - Integration Tests
    
    func testCompletePartnerWorkflow() async throws {
        // Given
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        // Initialize dashboard
        await viewModel.initialize()
        XCTAssertFalse(viewModel.isLoading)
        
        // Update order status
        let orderId = "test-order"
        viewModel.updateOrderStatus(orderId, status: .preparing)
        
        // Wait for async operations
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Verify all operations completed successfully
        XCTAssertTrue(mockCloudKitService.updateOrderStatusCalled)
        XCTAssertFalse(viewModel.showingError)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() async throws {
        // Given
        mockCloudKitService.shouldThrowError = true
        mockAuthService.currentUser = UserProfile.mockPartner
        
        // When
        await viewModel.initialize()
        
        // Then
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
    }
    
    func testAuthenticationErrorHandling() async throws {
        // Given
        mockAuthService.currentUser = nil
        
        // When
        await viewModel.initialize()
        
        // Then
        XCTAssertTrue(viewModel.showingError)
        XCTAssertTrue(viewModel.errorMessage.contains("authentication") || viewModel.errorMessage.contains("authenticated"))
    }
    
    // MARK: - Performance Tests
    
    func testDashboardLoadPerformance() throws {
        let mockUser = UserProfile.mockPartner
        mockAuthService.currentUser = mockUser
        
        measure {
            Task {
                await viewModel.initialize()
            }
        }
    }
    
    func testProductSearchPerformance() throws {
        let productViewModel = ProductManagementViewModel(
            cloudKitService: mockCloudKitService,
            authService: mockAuthService
        )
        
        // Create large dataset
        var products: [Product] = []
        for i in 0..<1000 {
            products.append(Product.mockProduct1.copy(id: "product\(i)", name: "Product \(i)"))
        }
        mockCloudKitService.mockProducts = products
        
        measure {
            Task {
                await productViewModel.loadProducts()
                productViewModel.searchText = "Product 500"
            }
        }
    }
}

// MARK: - Mock Extensions
extension UserProfile {
    static let mockPartner = UserProfile(
        id: "partner123",
        appleUserID: "apple123",
        email: "partner@example.com",
        fullName: PersonNameComponents(givenName: "John", familyName: "Doe"),
        role: .partner,
        phoneNumber: "+1234567890",
        profileImageURL: nil,
        isVerified: true,
        createdAt: Date().addingTimeInterval(-86400),
        lastActiveAt: Date()
    )
}

extension Product {
    func copy(id: String? = nil, name: String? = nil) -> Product {
        return Product(
            id: id ?? self.id,
            partnerId: self.partnerId,
            name: name ?? self.name,
            description: self.description,
            priceCents: self.priceCents,
            originalPriceCents: self.originalPriceCents,
            category: self.category,
            imageURLs: self.imageURLs,
            isAvailable: self.isAvailable,
            stockQuantity: self.stockQuantity,
            nutritionInfo: self.nutritionInfo,
            allergens: self.allergens,
            tags: self.tags,
            weight: self.weight,
            dimensions: self.dimensions,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}

// MARK: - Mock Services
class MockCloudKitService: CloudKitService {
    var mockOrders: [Order] = []
    var mockProducts: [Product] = []
    var mockPartnerStats: PartnerStats?
    var shouldThrowError = false
    
    // Tracking method calls
    var updateOrderStatusCalled = false
    var updatePartnerStatusCalled = false
    var updateProductCalled = false
    var updatePartnerCalled = false
    var updateBusinessSettingsCalled = false
    
    var lastUpdatedOrderId: String?
    var lastUpdatedOrderStatus: OrderStatus?
    
    func fetchOrders(for userId: String, userType: UserType, statuses: [OrderStatus]) async throws -> [Order] {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
        return mockOrders.filter { statuses.contains($0.status) }
    }
    
    func fetchRecentOrders(for userId: String, userType: UserType, limit: Int) async throws -> [Order] {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
        return Array(mockOrders.prefix(limit))
    }
    
    func fetchPartnerStats(partnerId: String) async throws -> PartnerStats {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
        return mockPartnerStats ?? PartnerStats(
            todayOrderCount: 0,
            todayRevenueCents: 0,
            averageRating: 0.0,
            totalOrders: 0,
            totalRevenueCents: 0
        )
    }
    
    func fetchPartner(id: String) async throws -> Partner {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
        return Partner.mockPartner
    }
    
    func updatePartnerStatus(partnerId: String, isActive: Bool) async throws {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
        updatePartnerStatusCalled = true
    }
    
    func updateOrderStatus(_ orderId: String, status: OrderStatus) async throws {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
        updateOrderStatusCalled = true
        lastUpdatedOrderId = orderId
        lastUpdatedOrderStatus = status
    }
    
    func subscribeToOrderUpdates(for userId: String) async throws {
        if shouldThrowError {
            throw AppError.network(.connectionFailed)
        }
    }
}

extension Partner {
    static let mockPartner = Partner(
        id: "partner123",
        name: "Test Restaurant",
        category: .restaurant,
        description: "A great test restaurant",
        address: Address(street: "123 Test St", city: "Test City", state: "TS", postalCode: "12345", country: "US"),
        location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        phoneNumber: "+1234567890",
        email: "test@restaurant.com",
        heroImageURL: nil,
        logoURL: nil,
        isVerified: true,
        isActive: true,
        rating: 4.5,
        reviewCount: 100,
        openingHours: [:],
        deliveryRadius: 5.0,
        minimumOrderAmount: 1000,
        estimatedDeliveryTime: 30,
        createdAt: Date()
    )
}