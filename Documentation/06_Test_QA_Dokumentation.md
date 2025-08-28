# MimiSupply - Test- & QA-Dokumentation

## Überblick

MimiSupply implementiert eine umfassende Test-Strategie mit automatisierten Tests, Performance-Monitoring und Accessibility-Compliance. Die Test-Suite deckt alle Aspekte der Anwendung ab und gewährleistet hohe Qualitätsstandards.

## Test-Architektur

### Test-Pyramide
```
                    ┌─────────────────┐
                    │   E2E Tests     │ (5%)
                    │   UI Tests      │
                ┌───┴─────────────────┴───┐
                │   Integration Tests     │ (15%)
                │   Service Tests         │
            ┌───┴─────────────────────────┴───┐
            │        Unit Tests               │ (80%)
            │   Business Logic, Models        │
            └─────────────────────────────────┘
```

### Test-Kategorien

#### 1. Unit Tests (80%)
- **Business Logic**: Order Management, Driver Assignment, Cart Service
- **Data Layer**: Repositories, Services, Models
- **Utilities**: Extensions, Helpers, Validators

#### 2. Integration Tests (15%)
- **Service Integration**: CloudKit + CoreData Sync
- **Authentication Flow**: Sign in with Apple
- **Payment Processing**: Apple Pay Integration
- **Real-time Updates**: Push Notifications

#### 3. UI/E2E Tests (5%)
- **User Journeys**: Complete workflows
- **Cross-Platform**: iPhone, iPad
- **Accessibility**: VoiceOver, Dynamic Type

## Test-Struktur

### Unit Tests (`/MimiSupplyTests/`)

#### Business Logic Tests
```swift
// OrderManagementTests.swift
class OrderManagementTests: XCTestCase {
    func testOrderCreation() async throws {
        // Given
        let orderData = TestDataFactory.createOrderData()
        
        // When
        let order = try await orderService.createOrder(orderData)
        
        // Then
        XCTAssertEqual(order.status, .pending)
        XCTAssertEqual(order.totalCents, orderData.expectedTotal)
    }
    
    func testDriverAssignment() async throws {
        // Given
        let order = TestDataFactory.createOrder()
        let availableDrivers = TestDataFactory.createDrivers(count: 5)
        
        // When
        let assignedDriver = try await driverService.assignDriver(for: order)
        
        // Then
        XCTAssertNotNil(assignedDriver)
        XCTAssertTrue(availableDrivers.contains(assignedDriver!))
    }
}
```

#### Repository Tests
```swift
// UserRepositoryTests.swift
class UserRepositoryTests: XCTestCase {
    func testUserCRUDOperations() async throws {
        // Create
        let user = TestDataFactory.createUser()
        try await userRepository.save(user)
        
        // Read
        let fetchedUser = try await userRepository.fetch(by: user.id)
        XCTAssertEqual(fetchedUser?.id, user.id)
        
        // Update
        var updatedUser = user
        updatedUser.role = .driver
        try await userRepository.update(updatedUser)
        
        // Delete
        try await userRepository.delete(user.id)
        let deletedUser = try await userRepository.fetch(by: user.id)
        XCTAssertNil(deletedUser)
    }
}
```

### Integration Tests (`/Integration/`)

#### End-to-End Workflow Tests
```swift
// OrderWorkflowIntegrationTests.swift
class OrderWorkflowIntegrationTests: XCTestCase {
    func testCompleteOrderWorkflow() async throws {
        // 1. Customer places order
        let customer = TestDataFactory.createCustomer()
        let partner = TestDataFactory.createPartner()
        let products = TestDataFactory.createProducts(for: partner)
        
        let order = try await orderService.createOrder(
            customerId: customer.id,
            partnerId: partner.id,
            items: products.map { TestDataFactory.createOrderItem(from: $0) }
        )
        
        // 2. Partner accepts order
        try await partnerService.acceptOrder(order.id)
        let acceptedOrder = try await orderService.fetchOrder(order.id)
        XCTAssertEqual(acceptedOrder?.status, .confirmed)
        
        // 3. Driver is assigned
        let driver = try await driverService.assignDriver(for: order)
        XCTAssertNotNil(driver)
        
        // 4. Order is delivered
        try await driverService.completeDelivery(order.id, driver: driver!)
        let completedOrder = try await orderService.fetchOrder(order.id)
        XCTAssertEqual(completedOrder?.status, .delivered)
    }
}
```

#### Data Synchronization Tests
```swift
// DataLayerIntegrationTests.swift
class DataLayerIntegrationTests: XCTestCase {
    func testCloudKitCoreDataSync() async throws {
        // Create data locally
        let partner = TestDataFactory.createPartner()
        try await coreDataStack.save(partner)
        
        // Sync to CloudKit
        try await cloudKitService.syncToCloud()
        
        // Verify in CloudKit
        let cloudPartners = try await cloudKitService.fetchPartners()
        XCTAssertTrue(cloudPartners.contains { $0.id == partner.id })
        
        // Test conflict resolution
        var localPartner = partner
        localPartner.name = "Updated Locally"
        try await coreDataStack.save(localPartner)
        
        var cloudPartner = partner
        cloudPartner.description = "Updated in Cloud"
        try await cloudKitService.save(cloudPartner)
        
        // Sync and resolve conflicts
        try await syncService.resolveConflicts()
        
        let resolvedPartner = try await coreDataStack.fetch(Partner.self, id: partner.id)
        XCTAssertEqual(resolvedPartner?.name, "Updated Locally")
        XCTAssertEqual(resolvedPartner?.description, "Updated in Cloud")
    }
}
```

### UI Tests (`/MimiSupplyUITests/`)

#### Comprehensive UI Tests
```swift
// ComprehensiveUITests.swift
class ComprehensiveUITests: XCTestCase {
    func testCustomerOrderFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-data"]
        app.launch()
        
        // Navigate to partner
        let partnerCell = app.cells["partner-cell-0"]
        XCTAssertTrue(partnerCell.waitForExistence(timeout: 5))
        partnerCell.tap()
        
        // Add product to cart
        let productCell = app.cells["product-cell-0"]
        XCTAssertTrue(productCell.waitForExistence(timeout: 5))
        productCell.tap()
        
        let addToCartButton = app.buttons["add-to-cart"]
        XCTAssertTrue(addToCartButton.waitForExistence(timeout: 5))
        addToCartButton.tap()
        
        // Proceed to checkout
        let cartButton = app.buttons["cart"]
        cartButton.tap()
        
        let checkoutButton = app.buttons["checkout"]
        XCTAssertTrue(checkoutButton.waitForExistence(timeout: 5))
        checkoutButton.tap()
        
        // Complete order
        let placeOrderButton = app.buttons["place-order"]
        XCTAssertTrue(placeOrderButton.waitForExistence(timeout: 5))
        placeOrderButton.tap()
        
        // Verify order confirmation
        let confirmationText = app.staticTexts["order-confirmation"]
        XCTAssertTrue(confirmationText.waitForExistence(timeout: 10))
    }
}
```

#### Accessibility UI Tests
```swift
// AccessibilityUITests.swift
class AccessibilityUITests: XCTestCase {
    func testVoiceOverNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--voiceover"]
        app.launch()
        
        // Test VoiceOver navigation
        let firstElement = app.otherElements.firstMatch
        XCTAssertTrue(firstElement.isAccessibilityElement)
        XCTAssertNotNil(firstElement.accessibilityLabel)
        
        // Test all interactive elements have proper labels
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertNotNil(button.accessibilityLabel)
            XCTAssertFalse(button.accessibilityLabel!.isEmpty)
        }
    }
    
    func testDynamicTypeSupport() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--large-text"]
        app.launch()
        
        // Verify text scales properly
        let titleLabel = app.staticTexts["main-title"]
        XCTAssertTrue(titleLabel.waitForExistence(timeout: 5))
        
        // Text should be readable and not truncated
        XCTAssertFalse(titleLabel.label.contains("..."))
    }
}
```

### Performance Tests (`/Performance/`)

#### Startup Performance Tests
```swift
// StartupPerformanceTests.swift
class StartupPerformanceTests: XCTestCase {
    func testColdStartupTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
            
            // Wait for first screen to be interactive
            let firstInteractiveElement = app.buttons.firstMatch
            XCTAssertTrue(firstInteractiveElement.waitForExistence(timeout: 5))
        }
    }
    
    func testMemoryUsageDuringStartup() throws {
        let app = XCUIApplication()
        
        measure(metrics: [XCTMemoryMetric()]) {
            app.launch()
            
            // Navigate through key screens
            navigateToPartnerList(app)
            navigateToProductDetail(app)
            navigateToCart(app)
        }
    }
}
```

#### Runtime Performance Tests
```swift
// RuntimePerformanceTests.swift
class RuntimePerformanceTests: XCTestCase {
    func testScrollingPerformance() throws {
        let app = XCUIApplication()
        app.launch()
        
        let partnerList = app.scrollViews["partner-list"]
        XCTAssertTrue(partnerList.waitForExistence(timeout: 5))
        
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            // Perform scrolling
            partnerList.swipeUp()
            partnerList.swipeDown()
            partnerList.swipeUp()
        }
    }
    
    func testSearchResponseTime() throws {
        let app = XCUIApplication()
        app.launch()
        
        let searchField = app.searchFields["partner-search"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        
        measure {
            searchField.tap()
            searchField.typeText("pizza")
            
            // Wait for search results
            let firstResult = app.cells["search-result-0"]
            XCTAssertTrue(firstResult.waitForExistence(timeout: 2))
        }
    }
}
```

### Snapshot Tests (`/Snapshots/`)

```swift
// SnapshotTestRunner.swift
class SnapshotTestRunner: XCTestCase {
    func testExploreScreenSnapshots() throws {
        let configurations = TestConfiguration.TestDeviceConfigurations.iPhoneConfigurations
        
        for config in configurations {
            let view = ExploreView()
                .environment(\.colorScheme, config.colorScheme)
                .environment(\.sizeCategory, config.sizeCategory)
                .environment(\.locale, config.locale)
            
            assertSnapshot(
                matching: view,
                as: .image(layout: .device(config: config.device)),
                named: "explore-\(config.description)"
            )
        }
    }
    
    func testAccessibilitySnapshots() throws {
        let accessibilityConfigs = TestConfiguration.TestDeviceConfigurations.accessibilityConfigurations
        
        for config in accessibilityConfigs {
            let view = PartnerDetailView(partner: TestDataFactory.createPartner())
                .environment(\.sizeCategory, config.sizeCategory)
                .environment(\.colorScheme, config.colorScheme)
            
            assertSnapshot(
                matching: view,
                as: .image(layout: .device(config: config.device)),
                named: "partner-detail-accessibility-\(config.description)"
            )
        }
    }
}
```

## ATDD-Szenarien (Given/When/Then)

### Customer Journey Scenarios

#### Szenario: Erfolgreiche Bestellung
```gherkin
Feature: Customer Order Placement
  Als Kunde
  Möchte ich eine Bestellung aufgeben
  Damit ich Produkte geliefert bekomme

Scenario: Erfolgreiche Bestellung mit Apple Pay
  Given ich bin als Kunde angemeldet
  And es gibt verfügbare Partner in meiner Nähe
  When ich einen Partner auswähle
  And ich Produkte zum Warenkorb hinzufüge
  And ich zur Kasse gehe
  And ich Apple Pay als Zahlungsmethode wähle
  And ich die Bestellung bestätige
  Then wird die Bestellung erfolgreich erstellt
  And ich erhalte eine Bestätigungsnachricht
  And der Partner wird über die neue Bestellung informiert
```

#### Szenario: Bestellverfolgung
```gherkin
Scenario: Live-Verfolgung einer Bestellung
  Given ich habe eine aktive Bestellung
  And ein Fahrer wurde zugewiesen
  When der Fahrer die Bestellung abholt
  Then wird der Bestellstatus auf "unterwegs" aktualisiert
  And ich kann die Position des Fahrers live verfolgen
  And ich erhalte Push-Benachrichtigungen bei Statusänderungen
```

### Driver Journey Scenarios

#### Szenario: Auftragsannahme
```gherkin
Feature: Driver Job Management
  Als Fahrer
  Möchte ich Aufträge annehmen und abschließen
  Damit ich Geld verdienen kann

Scenario: Erfolgreiche Auftragsannahme
  Given ich bin als Fahrer angemeldet
  And ich bin online und verfügbar
  When eine neue Bestellung in meiner Nähe verfügbar wird
  And ich die Bestellung annehme
  Then wird mir die Route zum Abholort angezeigt
  And der Kunde wird über die Fahrer-Zuweisung informiert
  And mein Status wird auf "beschäftigt" gesetzt
```

### Partner Journey Scenarios

#### Szenario: Bestellverwaltung
```gherkin
Feature: Partner Order Management
  Als Partner
  Möchte ich eingehende Bestellungen verwalten
  Damit ich mein Geschäft effizient führen kann

Scenario: Bestellung annehmen und vorbereiten
  Given ich bin als Partner angemeldet
  And mein Geschäft ist geöffnet
  When eine neue Bestellung eingeht
  And ich die Bestellung annehme
  Then wird die Bestellung in meine Zubereitungsliste aufgenommen
  And der Kunde wird über die Annahme informiert
  And ein Fahrer wird automatisch zugewiesen
```

## Test-Konfiguration und Benchmarks

### Performance-Benchmarks
```swift
struct PerformanceBenchmarks {
    static let appStartupTime: TimeInterval = 2.5        // Sekunden
    static let warmStartupTime: TimeInterval = 1.0       // Sekunden
    static let firstScreenTTI: TimeInterval = 1.0        // Sekunden
    static let searchResponseTime: TimeInterval = 0.3    // Sekunden
    static let imageLoadTime: TimeInterval = 2.0         // Sekunden
    static let scrollingFPS: Double = 100.0              // Minimum FPS für 120Hz
    static let memoryIncreaseLimit: Double = 100.0       // MB
}
```

### Coverage-Anforderungen
```swift
struct CoverageRequirements {
    static let overallCoverage: Double = 0.85      // 85%
    static let businessLogicCoverage: Double = 0.90 // 90%
    static let uiCoverage: Double = 0.80           // 80%
    static let integrationCoverage: Double = 0.75   // 75%
}
```

### Accessibility-Anforderungen
```swift
struct AccessibilityRequirements {
    static let minimumContrastRatio: Double = 4.5        // WCAG AA
    static let minimumTouchTargetSize: CGFloat = 44.0     // Points
    static let maximumTextScaling: CGFloat = 2.0          // 200%
    
    static let supportedContentSizeCategories: [UIContentSizeCategory] = [
        .small, .medium, .large, .extraLarge, .extraExtraLarge,
        .extraExtraExtraLarge, .accessibilityMedium, .accessibilityLarge,
        .accessibilityExtraLarge, .accessibilityExtraExtraLarge,
        .accessibilityExtraExtraExtraLarge
    ]
}
```

## Test-Ausführung

### Lokale Ausführung
```bash
# Alle Tests ausführen
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 16'

# Nur Unit Tests
xcodebuild test -scheme MimiSupply -only-testing:MimiSupplyTests

# Nur UI Tests
xcodebuild test -scheme MimiSupply -only-testing:MimiSupplyUITests

# Performance Tests
xcodebuild test -scheme MimiSupply -only-testing:MimiSupplyTests/Performance
```

### CI/CD Integration
```yaml
# GitHub Actions Test Matrix
strategy:
  matrix:
    destination: 
      - 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
      - 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation),OS=18.0'
    test-type: [unit, integration, ui, performance, snapshot]
```

## Mock-Daten und Test-Fixtures

### Test Data Factory
```swift
struct TestDataFactory {
    static func createPartner() -> Partner {
        Partner(
            name: "Test Restaurant",
            category: .restaurant,
            description: "Test description",
            address: createAddress(),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            rating: 4.5,
            reviewCount: 100,
            minimumOrderAmount: 1500
        )
    }
    
    static func createOrder() -> Order {
        Order(
            customerId: "test-customer",
            partnerId: "test-partner",
            items: [createOrderItem()],
            subtotalCents: 2000,
            deliveryFeeCents: 299,
            platformFeeCents: 100,
            taxCents: 180,
            deliveryAddress: createAddress(),
            estimatedDeliveryTime: Date().addingTimeInterval(1800),
            paymentMethod: .applePay
        )
    }
}
```

## Qualitätsmetriken und Monitoring

### Test-Metriken
- **Test Success Rate**: >98%
- **Test Execution Time**: <5 Sekunden pro Test
- **Flaky Test Rate**: <5%
- **Code Coverage**: >85% gesamt

### Performance-Metriken
- **App Launch Time**: <2.5 Sekunden
- **Memory Usage**: <100MB Anstieg
- **Scroll Performance**: >100 FPS
- **Network Response**: <300ms für Suche

### Accessibility-Metriken
- **VoiceOver Compatibility**: 100%
- **Dynamic Type Support**: Alle Texte
- **Contrast Compliance**: WCAG 2.2 AA+
- **Touch Target Size**: ≥44pt

## Continuous Testing Strategy

### Automated Testing Pipeline
1. **Pre-Commit**: Lint, Format, Unit Tests
2. **PR Review**: Integration Tests, UI Tests
3. **Staging**: Performance Tests, Accessibility Tests
4. **Production**: Smoke Tests, Monitoring

### Test Maintenance
- **Weekly**: Review Flaky Tests
- **Monthly**: Update Test Data
- **Quarterly**: Performance Benchmark Review
- **Annually**: Accessibility Guidelines Update

## Fehlerbehandlung und Debugging

### Test-Debugging
```swift
// Debug-Hilfsmittel
func debugTest(_ testName: String, file: String = #file, line: Int = #line) {
    print("🐛 Debug: \(testName) at \(file):\(line)")
    
    // Screenshot für UI Tests
    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Debug-\(testName)"
        add(attachment)
    }
}
```

### Fehler-Simulation
```swift
struct ErrorSimulation {
    static let networkErrorRate: Double = 0.1      // 10% der Requests
    static let authenticationErrorRate: Double = 0.05 // 5% der Auth-Versuche
    static let paymentErrorRate: Double = 0.02     // 2% der Zahlungen
}
```

## Test-Dokumentation und Reporting

### Test Reports
- **Coverage Reports**: Xcode Code Coverage
- **Performance Reports**: XCTest Metrics
- **Accessibility Reports**: Accessibility Inspector
- **Visual Regression**: Snapshot Diff Reports

### Compliance Documentation
- **WCAG 2.2**: Accessibility Compliance Report
- **Performance**: Benchmark Compliance Report
- **Security**: Security Test Results
- **Privacy**: Data Handling Test Results
