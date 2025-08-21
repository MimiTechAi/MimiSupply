//
//  NavigationTests.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

@MainActor
final class NavigationTests: XCTestCase {
    
    var container: AppContainer!
    var router: AppRouter!
    var navigationManager: NavigationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        container = AppContainer.shared
        router = AppRouter(container: container)
        navigationManager = NavigationManager()
    }
    
    override func tearDown() async throws {
        navigationManager.clearNavigationState()
        try await super.tearDown()
    }
    
    // MARK: - Basic Navigation Tests
    
    func testNavigateToRoute() {
        // Given
        let initialRoute = router.currentRoute
        let targetRoute = AppRoute.settings
        
        // When
        router.navigate(to: targetRoute)
        
        // Then
        XCTAssertEqual(router.currentRoute, targetRoute)
        XCTAssertNotEqual(router.currentRoute, initialRoute)
    }
    
    func testPushAndPopNavigation() {
        // Given
        let initialRoute = router.currentRoute
        let targetRoute = AppRoute.settings
        
        // When
        router.push(targetRoute)
        
        // Then
        XCTAssertEqual(router.navigationPath.count, 1)
        
        // When
        router.pop()
        
        // Then
        XCTAssertEqual(router.navigationPath.count, 0)
    }
    
    func testPopToRoot() {
        // Given
        router.push(.settings)
        router.push(.profile)
        router.push(.orderHistory)
        
        // When
        router.popToRoot()
        
        // Then
        XCTAssertEqual(router.navigationPath.count, 0)
    }
    
    // MARK: - Sheet Presentation Tests
    
    func testPresentAndDismissSheet() {
        // Given
        let sheet = SheetRoute.cart
        
        // When
        router.presentSheet(sheet)
        
        // Then
        XCTAssertEqual(router.presentedSheet, sheet)
        
        // When
        router.dismissSheet()
        
        // Then
        XCTAssertNil(router.presentedSheet)
    }
    
    func testPresentAndDismissFullScreen() {
        // Given
        let fullScreen = FullScreenRoute.onboarding
        
        // When
        router.presentFullScreen(fullScreen)
        
        // Then
        XCTAssertEqual(router.presentedFullScreen, fullScreen)
        
        // When
        router.dismissFullScreen()
        
        // Then
        XCTAssertNil(router.presentedFullScreen)
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabSelection() {
        // Given
        let tab = TabRoute.orders
        
        // When
        router.selectTab(tab)
        
        // Then
        XCTAssertEqual(router.selectedTab, tab)
    }
    
    func testRoleBasedTabs() {
        // Test customer tabs
        let customerTabs = router.getTabsForRole(.customer)
        XCTAssertEqual(customerTabs, [.explore, .orders, .profile])
        
        // Test driver tabs
        let driverTabs = router.getTabsForRole(.driver)
        XCTAssertEqual(driverTabs, [.dashboard, .orders, .profile])
        
        // Test partner tabs
        let partnerTabs = router.getTabsForRole(.partner)
        XCTAssertEqual(partnerTabs, [.dashboard, .orders, .profile])
        
        // Test admin tabs
        let adminTabs = router.getTabsForRole(.admin)
        XCTAssertEqual(adminTabs, [.explore, .orders, .profile])
    }
    
    func testRoleBasedHomeNavigation() {
        // Test customer navigation
        router.navigateToRoleBasedHome(for: .customer)
        XCTAssertEqual(router.selectedTab, .explore)
        XCTAssertEqual(router.currentRoute, .customerHome)
        
        // Test driver navigation
        router.navigateToRoleBasedHome(for: .driver)
        XCTAssertEqual(router.selectedTab, .dashboard)
        XCTAssertEqual(router.currentRoute, .driverDashboard)
        
        // Test partner navigation
        router.navigateToRoleBasedHome(for: .partner)
        XCTAssertEqual(router.selectedTab, .dashboard)
        XCTAssertEqual(router.currentRoute, .partnerDashboard)
    }
    
    // MARK: - Deep Linking Tests
    
    func testOrderDeepLink() {
        // Given
        let orderId = "order123"
        let url = URL(string: "mimisupply://order?id=\(orderId)")!
        
        // When
        router.handleDeepLink(url)
        
        // Then
        if case .orderTracking(let receivedOrderId) = router.currentRoute {
            XCTAssertEqual(receivedOrderId, orderId)
        } else {
            XCTFail("Expected orderTracking route")
        }
    }
    
    func testAuthDeepLink() {
        // Given
        let url = URL(string: "mimisupply://auth?action=signin")!
        
        // When
        router.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(router.presentedSheet, .authentication)
    }
    
    func testExploreDeepLink() {
        // Given
        let url = URL(string: "mimisupply://explore")!
        
        // When
        router.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(router.currentRoute, .explore)
    }
    
    func testInvalidDeepLink() {
        // Given
        let initialRoute = router.currentRoute
        let url = URL(string: "mimisupply://invalid")!
        
        // When
        router.handleDeepLink(url)
        
        // Then
        XCTAssertEqual(router.currentRoute, initialRoute)
    }
    
    // MARK: - Universal Links Tests
    
    func testUniversalLinkGeneration() {
        // Test order tracking link
        let orderId = "order123"
        let orderRoute = AppRoute.orderTracking(orderId)
        let orderLink = router.generateShareableLink(for: orderRoute)
        XCTAssertEqual(orderLink?.absoluteString, "https://mimisupply.app/order?id=\(orderId)")
        
        // Test partner detail link
        let partner = createSamplePartner()
        let partnerRoute = AppRoute.partnerDetail(partner)
        let partnerLink = router.generateShareableLink(for: partnerRoute)
        XCTAssertEqual(partnerLink?.absoluteString, "https://mimisupply.app/partner?id=\(partner.id)")
    }
    
    func testUniversalLinkHandling() {
        // Given
        let orderId = "order123"
        let url = URL(string: "https://mimisupply.app/order?id=\(orderId)")!
        
        // When
        let success = navigationManager.handleUniversalLink(url, router: router)
        
        // Then
        XCTAssertTrue(success)
        if case .orderTracking(let receivedOrderId) = router.currentRoute {
            XCTAssertEqual(receivedOrderId, orderId)
        } else {
            XCTFail("Expected orderTracking route")
        }
    }
    
    // MARK: - Navigation State Persistence Tests
    
    func testNavigationStatePersistence() {
        // Given
        let targetRoute = AppRoute.settings
        let targetTab = TabRoute.profile
        
        // When
        router.navigate(to: targetRoute)
        router.selectTab(targetTab)
        navigationManager.saveNavigationState(router)
        
        // Create new router and restore state
        let newRouter = AppRouter(container: container)
        navigationManager.restoreNavigationState(to: newRouter)
        
        // Then
        XCTAssertEqual(newRouter.currentRoute, targetRoute)
        XCTAssertEqual(newRouter.selectedTab, targetTab)
    }
    
    func testNavigationStateClearing() {
        // Given
        router.navigate(to: .settings)
        navigationManager.saveNavigationState(router)
        
        // When
        navigationManager.clearNavigationState()
        
        // Create new router and try to restore
        let newRouter = AppRouter(container: container)
        navigationManager.restoreNavigationState(to: newRouter)
        
        // Then - should have default values
        XCTAssertEqual(newRouter.currentRoute, .explore)
        XCTAssertEqual(newRouter.selectedTab, .explore)
    }
    
    // MARK: - Route Encoding/Decoding Tests
    
    func testRouteEncoding() throws {
        let routes: [AppRoute] = [
            .explore,
            .customerHome,
            .driverDashboard,
            .partnerDashboard,
            .orderTracking("order123"),
            .orderHistory,
            .cart,
            .checkout,
            .profile,
            .settings,
            .authentication,
            .roleSelection,
            .onboarding
        ]
        
        for route in routes {
            let encoded = try JSONEncoder().encode(route)
            let decoded = try JSONDecoder().decode(AppRoute.self, from: encoded)
            
            // For routes with associated values, we need special handling
            switch (route, decoded) {
            case (.orderTracking(let original), .orderTracking(let restored)):
                XCTAssertEqual(original, restored)
            case (.explore, .explore),
                 (.customerHome, .customerHome),
                 (.driverDashboard, .driverDashboard),
                 (.partnerDashboard, .partnerDashboard),
                 (.orderHistory, .orderHistory),
                 (.cart, .cart),
                 (.checkout, .checkout),
                 (.profile, .profile),
                 (.settings, .settings),
                 (.authentication, .authentication),
                 (.roleSelection, .roleSelection),
                 (.onboarding, .onboarding):
                // These should match exactly
                break
            default:
                XCTFail("Route encoding/decoding mismatch: \(route) != \(decoded)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testNavigationPerformance() {
        measure {
            for i in 0..<1000 {
                router.navigate(to: i % 2 == 0 ? .explore : .settings)
            }
        }
    }
    
    func testDeepLinkPerformance() {
        let urls = (0..<100).map { URL(string: "mimisupply://order?id=order\($0)")! }
        
        measure {
            for url in urls {
                router.handleDeepLink(url)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSamplePartner() -> Partner {
        return Partner(
            id: "partner123",
            name: "Test Restaurant",
            category: .restaurant,
            description: "A test restaurant",
            address: Address(
                street: "123 Test St",
                city: "Test City",
                state: "TS",
                postalCode: "12345",
                country: "US"
            ),
            location: .init(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "test@restaurant.com",
            isVerified: true,
            isActive: true,
            rating: 4.5,
            reviewCount: 100,
            openingHours: [:],
            deliveryRadius: 5.0,
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: 30
        )
    }
}

// MARK: - Navigation Integration Tests

@MainActor
final class NavigationIntegrationTests: XCTestCase {
    
    var container: AppContainer!
    var router: AppRouter!
    
    override func setUp() async throws {
        try await super.setUp()
        container = AppContainer.shared
        router = AppRouter(container: container)
    }
    
    func testCompleteNavigationFlow() {
        // Test a complete user journey
        
        // 1. Start at explore
        XCTAssertEqual(router.currentRoute, .explore)
        
        // 2. Navigate to authentication
        router.presentSheet(.authentication)
        XCTAssertEqual(router.presentedSheet, .authentication)
        
        // 3. Dismiss authentication and navigate to customer home
        router.dismissSheet()
        router.navigateToRoleBasedHome(for: .customer)
        XCTAssertEqual(router.currentRoute, .customerHome)
        XCTAssertEqual(router.selectedTab, .explore)
        
        // 4. Switch to orders tab
        router.selectTab(.orders)
        XCTAssertEqual(router.selectedTab, .orders)
        
        // 5. Navigate to order tracking via deep link
        let url = URL(string: "mimisupply://order?id=order123")!
        router.handleDeepLink(url)
        
        if case .orderTracking(let orderId) = router.currentRoute {
            XCTAssertEqual(orderId, "order123")
        } else {
            XCTFail("Expected orderTracking route")
        }
        
        // 6. Navigate back to profile
        router.selectTab(.profile)
        XCTAssertEqual(router.selectedTab, .profile)
    }
    
    func testRoleBasedNavigationFlow() {
        // Test navigation for different user roles
        
        // Customer flow
        router.navigateToRoleBasedHome(for: .customer)
        let customerTabs = router.getTabsForRole(.customer)
        XCTAssertTrue(customerTabs.contains(.explore))
        XCTAssertFalse(customerTabs.contains(.dashboard))
        
        // Driver flow
        router.navigateToRoleBasedHome(for: .driver)
        let driverTabs = router.getTabsForRole(.driver)
        XCTAssertTrue(driverTabs.contains(.dashboard))
        XCTAssertFalse(driverTabs.contains(.explore))
        
        // Partner flow
        router.navigateToRoleBasedHome(for: .partner)
        let partnerTabs = router.getTabsForRole(.partner)
        XCTAssertTrue(partnerTabs.contains(.dashboard))
        XCTAssertFalse(partnerTabs.contains(.explore))
    }
}

// MARK: - Deep Linking Edge Cases Tests

@MainActor
final class DeepLinkingEdgeCasesTests: XCTestCase {
    
    var router: AppRouter!
    var navigationManager: NavigationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        router = AppRouter(container: AppContainer.shared)
        navigationManager = NavigationManager()
    }
    
    func testMalformedURLs() {
        let malformedURLs = [
            "not-a-url",
            "mimisupply://",
            "mimisupply://order",
            "mimisupply://order?",
            "mimisupply://order?id=",
            "https://mimisupply.app/order",
            "https://mimisupply.app/order?",
            "https://mimisupply.app/order?id="
        ]
        
        let initialRoute = router.currentRoute
        
        for urlString in malformedURLs {
            if let url = URL(string: urlString) {
                router.handleDeepLink(url)
                // Route should not change for malformed URLs
                XCTAssertEqual(router.currentRoute, initialRoute, "Route changed for malformed URL: \(urlString)")
            }
        }
    }
    
    func testUnsupportedSchemes() {
        let unsupportedURLs = [
            "http://mimisupply.app/order?id=123",
            "ftp://mimisupply.app/order?id=123",
            "file://mimisupply.app/order?id=123",
            "custom://mimisupply.app/order?id=123"
        ]
        
        let initialRoute = router.currentRoute
        
        for urlString in unsupportedURLs {
            if let url = URL(string: urlString) {
                let success = navigationManager.handleUniversalLink(url, router: router)
                XCTAssertFalse(success, "Unsupported scheme should return false: \(urlString)")
                XCTAssertEqual(router.currentRoute, initialRoute, "Route should not change for unsupported scheme: \(urlString)")
            }
        }
    }
    
    func testConcurrentDeepLinks() {
        let urls = (0..<10).compactMap { URL(string: "mimisupply://order?id=order\($0)") }
        
        // Simulate concurrent deep link handling
        let expectation = XCTestExpectation(description: "Concurrent deep links")
        expectation.expectedFulfillmentCount = urls.count
        
        for url in urls {
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.router.handleDeepLink(url)
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Should end up with one of the order tracking routes
        if case .orderTracking = router.currentRoute {
            // Success - we handled at least one deep link
        } else {
            XCTFail("Expected to end up with an orderTracking route")
        }
    }
}