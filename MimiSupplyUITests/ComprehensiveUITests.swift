//
//  ComprehensiveUITests.swift
//  MimiSupplyUITests
//
//  Created by Kiro on 16.08.25.
//

import XCTest

/// Comprehensive UI tests covering all screens and user interactions
final class ComprehensiveUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure app for testing
        app.launchArguments = ["--uitesting"]
        app.launchEnvironment = [
            "UITEST_DISABLE_ANIMATIONS": "1",
            "UITEST_MOCK_DATA": "1"
        ]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - App Launch and Navigation Tests
    
    func testAppLaunchAndInitialState() throws {
        app.launch()
        
        // Verify app launches successfully
        XCTAssertTrue(app.state == .runningForeground)
        
        // Verify initial screen is ExploreHomeView
        let exploreTitle = app.navigationBars["Explore"].firstMatch
        XCTAssertTrue(exploreTitle.waitForExistence(timeout: 5.0))
        
        // Verify key UI elements are present
        let searchBar = app.searchFields["Search partners and products"]
        XCTAssertTrue(searchBar.exists)
        
        let mapToggle = app.buttons["Map Toggle"]
        XCTAssertTrue(mapToggle.exists)
        
        let cartButton = app.buttons["Cart"]
        XCTAssertTrue(cartButton.exists)
    }
    
    func testTabBarNavigation() throws {
        app.launch()
        
        // Test navigation to different tabs
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3.0))
        
        // Navigate to Orders tab
        let ordersTab = tabBar.buttons["Orders"]
        ordersTab.tap()
        
        let ordersTitle = app.navigationBars["Orders"].firstMatch
        XCTAssertTrue(ordersTitle.waitForExistence(timeout: 2.0))
        
        // Navigate to Settings tab
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()
        
        let settingsTitle = app.navigationBars["Settings"].firstMatch
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2.0))
        
        // Navigate back to Explore
        let exploreTab = tabBar.buttons["Explore"]
        exploreTab.tap()
        
        let exploreTitle = app.navigationBars["Explore"].firstMatch
        XCTAssertTrue(exploreTitle.waitForExistence(timeout: 2.0))
    }
    
    // MARK: - Explore Flow Tests
    
    func testPartnerBrowsingFlow() throws {
        app.launch()
        
        // Wait for partners to load
        let firstPartnerCard = app.buttons.matching(identifier: "PartnerCard").firstMatch
        XCTAssertTrue(firstPartnerCard.waitForExistence(timeout: 5.0))
        
        // Tap on first partner
        firstPartnerCard.tap()
        
        // Verify partner detail view opens
        let partnerDetailView = app.scrollViews["PartnerDetailView"]
        XCTAssertTrue(partnerDetailView.waitForExistence(timeout: 3.0))
        
        // Verify partner information is displayed
        let partnerName = app.staticTexts.matching(identifier: "PartnerName").firstMatch
        XCTAssertTrue(partnerName.exists)
        
        let partnerRating = app.staticTexts.matching(identifier: "PartnerRating").firstMatch
        XCTAssertTrue(partnerRating.exists)
        
        // Verify products are displayed
        let productList = app.scrollViews["ProductList"]
        XCTAssertTrue(productList.exists)
        
        let firstProduct = app.buttons.matching(identifier: "ProductRow").firstMatch
        XCTAssertTrue(firstProduct.waitForExistence(timeout: 3.0))
    }
    
    func testSearchFunctionality() throws {
        app.launch()
        
        // Tap search bar
        let searchBar = app.searchFields["Search partners and products"]
        searchBar.tap()
        
        // Type search query
        searchBar.typeText("pizza")
        
        // Wait for search results
        let searchResults = app.scrollViews["SearchResults"]
        XCTAssertTrue(searchResults.waitForExistence(timeout: 3.0))
        
        // Verify search results are displayed
        let resultItems = app.buttons.matching(identifier: "SearchResultItem")
        XCTAssertGreaterThan(resultItems.count, 0)
        
        // Clear search
        let clearButton = searchBar.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }
        
        // Verify search is cleared
        XCTAssertEqual(searchBar.value as? String ?? "", "")
    }
    
    func testMapToggleFunctionality() throws {
        app.launch()
        
        // Initially should be in list view
        let partnerList = app.scrollViews["PartnerList"]
        XCTAssertTrue(partnerList.waitForExistence(timeout: 3.0))
        
        // Toggle to map view
        let mapToggle = app.buttons["Map Toggle"]
        mapToggle.tap()
        
        // Verify map view is displayed
        let mapView = app.maps["PartnerMap"]
        XCTAssertTrue(mapView.waitForExistence(timeout: 3.0))
        
        // Toggle back to list view
        mapToggle.tap()
        
        // Verify list view is displayed again
        XCTAssertTrue(partnerList.waitForExistence(timeout: 2.0))
    }
    
    // MARK: - Cart and Checkout Flow Tests
    
    func testAddToCartFlow() throws {
        app.launch()
        
        // Navigate to partner detail
        let firstPartnerCard = app.buttons.matching(identifier: "PartnerCard").firstMatch
        firstPartnerCard.tap()
        
        // Add product to cart
        let firstAddButton = app.buttons.matching(identifier: "AddToCartButton").firstMatch
        XCTAssertTrue(firstAddButton.waitForExistence(timeout: 3.0))
        firstAddButton.tap()
        
        // Verify cart badge updates
        let cartButton = app.buttons["Cart"]
        XCTAssertTrue(cartButton.waitForExistence(timeout: 2.0))
        // Some apps expose count via accessibility value or appended in the label
        let cartTextAfterFirstAdd = (cartButton.value as? String) ?? cartButton.label
        XCTAssertTrue(cartTextAfterFirstAdd.contains("1"), "Cart indicator should reflect count 1")
        
        // Add another product
        let secondAddButton = app.buttons.matching(identifier: "AddToCartButton").element(boundBy: 1)
        if secondAddButton.exists {
            secondAddButton.tap()
            
            // Verify cart indicator updates to 2
            let cartTextAfterSecondAdd = (cartButton.value as? String) ?? cartButton.label
            XCTAssertTrue(cartTextAfterSecondAdd.contains("2"), "Cart indicator should reflect count 2")
        }
    }
    
    func testCartViewAndManagement() throws {
        app.launch()
        
        // Add items to cart first
        addItemsToCart()
        
        // Open cart
        let cartButton = app.buttons["Cart"]
        cartButton.tap()
        
        // Verify cart view opens
        let cartView = app.scrollViews["CartView"]
        XCTAssertTrue(cartView.waitForExistence(timeout: 3.0))
        
        // Verify cart items are displayed
        let cartItems = app.buttons.matching(identifier: "CartItemRow")
        XCTAssertGreaterThan(cartItems.count, 0)
        
        // Test quantity adjustment
        let quantityButton = app.buttons.matching(identifier: "IncreaseQuantity").firstMatch
        if quantityButton.exists {
            quantityButton.tap()
            
            // Verify quantity updated
            let quantityLabel = app.staticTexts.matching(identifier: "ItemQuantity").firstMatch
            XCTAssertTrue(quantityLabel.waitForExistence(timeout: 2.0))
        }
        
        // Test item removal
        let removeButton = app.buttons.matching(identifier: "RemoveItem").firstMatch
        if removeButton.exists {
            removeButton.tap()
            
            // Confirm removal if alert appears
            let confirmButton = app.alerts.buttons["Remove"]
            if confirmButton.exists {
                confirmButton.tap()
            }
        }
        
        // Verify checkout button exists
        let checkoutButton = app.buttons["Proceed to Checkout"]
        XCTAssertTrue(checkoutButton.exists)
    }
    
    func testCheckoutFlow() throws {
        app.launch()
        
        // Add items to cart and proceed to checkout
        addItemsToCart()
        
        let cartButton = app.buttons["Cart"]
        cartButton.tap()
        
        let checkoutButton = app.buttons["Proceed to Checkout"]
        XCTAssertTrue(checkoutButton.waitForExistence(timeout: 3.0))
        checkoutButton.tap()
        
        // Handle authentication if required
        handleAuthenticationIfNeeded()
        
        // Verify checkout view
        let checkoutView = app.scrollViews["CheckoutView"]
        XCTAssertTrue(checkoutView.waitForExistence(timeout: 5.0))
        
        // Verify delivery address section
        let addressSection = app.staticTexts["Delivery Address"]
        XCTAssertTrue(addressSection.exists)
        
        // Verify payment section
        let paymentSection = app.staticTexts["Payment Method"]
        XCTAssertTrue(paymentSection.exists)
        
        // Verify order summary
        let orderSummary = app.staticTexts["Order Summary"]
        XCTAssertTrue(orderSummary.exists)
        
        // Test place order (in test mode, this should succeed)
        let placeOrderButton = app.buttons["Place Order"]
        XCTAssertTrue(placeOrderButton.exists)
        XCTAssertTrue(placeOrderButton.isEnabled)
    }
    
    // MARK: - Authentication Flow Tests
    
    func testAuthenticationFlow() throws {
        app.launch()
        
        // Navigate to settings to trigger authentication
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()
        
        // If not authenticated, should see sign in screen
        let signInButton = app.buttons["Sign in with Apple"]
        if signInButton.waitForExistence(timeout: 3.0) {
            signInButton.tap()
            
            // In test mode, authentication should succeed automatically
            let roleSelectionView = app.scrollViews["RoleSelectionView"]
            if roleSelectionView.waitForExistence(timeout: 5.0) {
                // Select customer role
                let customerRole = app.buttons["Customer"]
                customerRole.tap()
                
                let continueButton = app.buttons["Continue"]
                continueButton.tap()
            }
            
            // Verify authentication succeeded
            let profileSection = app.staticTexts["Profile"]
            XCTAssertTrue(profileSection.waitForExistence(timeout: 3.0))
        }
    }
    
    func testRoleSelectionFlow() throws {
        app.launch()
        
        // Trigger authentication flow
        triggerAuthentication()
        
        // Verify role selection screen
        let roleSelectionView = app.scrollViews["RoleSelectionView"]
        XCTAssertTrue(roleSelectionView.waitForExistence(timeout: 5.0))
        
        // Verify all role options are present
        let customerRole = app.buttons["Customer"]
        XCTAssertTrue(customerRole.exists)
        
        let driverRole = app.buttons["Driver"]
        XCTAssertTrue(driverRole.exists)
        
        let partnerRole = app.buttons["Partner"]
        XCTAssertTrue(partnerRole.exists)
        
        // Select customer role
        customerRole.tap()
        
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.exists)
        XCTAssertTrue(continueButton.isEnabled)
        
        continueButton.tap()
        
        // Verify role selection succeeded
        let exploreView = app.navigationBars["Explore"]
        XCTAssertTrue(exploreView.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - Settings and Profile Tests
    
    func testSettingsNavigation() throws {
        app.launch()
        
        // Navigate to settings
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()
        
        // Authenticate if needed
        handleAuthenticationIfNeeded()
        
        // Test profile editing
        let editProfileButton = app.buttons["Edit Profile"]
        if editProfileButton.exists {
            editProfileButton.tap()
            
            let profileEditView = app.scrollViews["ProfileEditView"]
            XCTAssertTrue(profileEditView.waitForExistence(timeout: 3.0))
            
            // Test form fields
            let nameField = app.textFields["Full Name"]
            if nameField.exists {
                nameField.tap()
                nameField.clearAndEnterText("Test User")
            }
            
            let saveButton = app.buttons["Save"]
            if saveButton.exists && saveButton.isEnabled {
                saveButton.tap()
            }
        }
        
        // Test language selection
        let languageButton = app.buttons["Language"]
        if languageButton.exists {
            languageButton.tap()
            
            let languageView = app.scrollViews["LanguageSelectionView"]
            XCTAssertTrue(languageView.waitForExistence(timeout: 3.0))
            
            // Go back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            backButton.tap()
        }
        
        // Test notification settings
        let notificationButton = app.buttons["Notifications"]
        if notificationButton.exists {
            notificationButton.tap()
            
            // Go back
            let backButton = app.navigationBars.buttons.element(boundBy: 0)
            backButton.tap()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() throws {
        app.launchArguments.append("--simulate-network-error")
        app.launch()
        
        // Should show error state
        let errorView = app.staticTexts["Network Error"]
        XCTAssertTrue(errorView.waitForExistence(timeout: 5.0))
        
        // Test retry functionality
        let retryButton = app.buttons["Retry"]
        if retryButton.exists {
            retryButton.tap()
            
            // Should attempt to reload
            let loadingIndicator = app.activityIndicators.firstMatch
            XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 2.0))
        }
    }
    
    func testEmptyStateHandling() throws {
        app.launchArguments.append("--empty-state")
        app.launch()
        
        // Navigate to cart (should be empty)
        let cartButton = app.buttons["Cart"]
        cartButton.tap()
        
        // Verify empty state
        let emptyStateView = app.staticTexts["Your cart is empty"]
        XCTAssertTrue(emptyStateView.waitForExistence(timeout: 3.0))
        
        let browseButton = app.buttons["Browse Partners"]
        XCTAssertTrue(browseButton.exists)
        
        browseButton.tap()
        
        // Should navigate back to explore
        let exploreView = app.navigationBars["Explore"]
        XCTAssertTrue(exploreView.waitForExistence(timeout: 2.0))
    }
    
    // MARK: - Performance Tests
    
    func testScrollingPerformance() throws {
        app.launch()
        
        // Wait for content to load
        let partnerList = app.scrollViews["PartnerList"]
        XCTAssertTrue(partnerList.waitForExistence(timeout: 5.0))
        
        // Measure scrolling performance
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            // Scroll down
            partnerList.swipeUp()
            partnerList.swipeUp()
            partnerList.swipeUp()
            
            // Scroll back up
            partnerList.swipeDown()
            partnerList.swipeDown()
            partnerList.swipeDown()
        }
    }
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            
            // Wait for initial content to load
            let exploreTitle = app.navigationBars["Explore"].firstMatch
            _ = exploreTitle.waitForExistence(timeout: 10.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func addItemsToCart() {
        // Navigate to partner detail
        let firstPartnerCard = app.buttons.matching(identifier: "PartnerCard").firstMatch
        if firstPartnerCard.waitForExistence(timeout: 5.0) {
            firstPartnerCard.tap()
            
            // Add first product
            let firstAddButton = app.buttons.matching(identifier: "AddToCartButton").firstMatch
            if firstAddButton.waitForExistence(timeout: 3.0) {
                firstAddButton.tap()
            }
            
            // Add second product if available
            let secondAddButton = app.buttons.matching(identifier: "AddToCartButton").element(boundBy: 1)
            if secondAddButton.exists {
                secondAddButton.tap()
            }
        }
    }
    
    private func handleAuthenticationIfNeeded() {
        let signInButton = app.buttons["Sign in with Apple"]
        if signInButton.waitForExistence(timeout: 2.0) {
            signInButton.tap()
            
            // Handle role selection if needed
            let roleSelectionView = app.scrollViews["RoleSelectionView"]
            if roleSelectionView.waitForExistence(timeout: 5.0) {
                let customerRole = app.buttons["Customer"]
                customerRole.tap()
                
                let continueButton = app.buttons["Continue"]
                continueButton.tap()
            }
        }
    }
    
    private func triggerAuthentication() {
        // Navigate to settings to trigger authentication
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()
        
        let signInButton = app.buttons["Sign in with Apple"]
        if signInButton.waitForExistence(timeout: 3.0) {
            signInButton.tap()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}