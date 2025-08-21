//
//  SnapshotTestRunner.swift
//  MimiSupplyTests
//
//  Created by Kiro on 15.08.25.
//

import XCTest
import SwiftUI
@testable import MimiSupply

/// Comprehensive snapshot testing for UI consistency across devices and configurations
final class SnapshotTestRunner: XCTestCase {
    
    var snapshotManager: SnapshotManager!
    
    override func setUp() {
        super.setUp()
        snapshotManager = SnapshotManager()
    }
    
    override func tearDown() {
        snapshotManager = nil
        super.tearDown()
    }
    
    // MARK: - Design System Component Snapshots
    
    func testDesignSystemComponentSnapshots() throws {
        let configurations = DeviceConfiguration.allTestConfigurations
        
        for config in configurations {
            // Test buttons
            try snapshotManager.captureSnapshot(
                of: createButtonTestView(),
                configuration: config,
                identifier: "buttons-\(config.identifier)"
            )
            
            // Test text fields
            try snapshotManager.captureSnapshot(
                of: createTextFieldTestView(),
                configuration: config,
                identifier: "textfields-\(config.identifier)"
            )
            
            // Test cards
            try snapshotManager.captureSnapshot(
                of: createCardTestView(),
                configuration: config,
                identifier: "cards-\(config.identifier)"
            )
            
            // Test badges
            try snapshotManager.captureSnapshot(
                of: createBadgeTestView(),
                configuration: config,
                identifier: "badges-\(config.identifier)"
            )
        }
    }
    
    // MARK: - Screen Layout Snapshots
    
    func testExploreHomeViewSnapshots() throws {
        let configurations = DeviceConfiguration.allTestConfigurations
        
        for config in configurations {
            let viewModel = ExploreHomeViewModel()
            viewModel.mockData = createMockExploreData()
            
            let view = ExploreHomeView()
                .environmentObject(viewModel)
            
            try snapshotManager.captureSnapshot(
                of: view,
                configuration: config,
                identifier: "explore-home-\(config.identifier)"
            )
        }
    }
    
    func testPartnerDetailViewSnapshots() throws {
        let configurations = DeviceConfiguration.allTestConfigurations
        let testPartner = createTestPartner()
        
        for config in configurations {
            let view = PartnerDetailView(partner: testPartner)
            
            try snapshotManager.captureSnapshot(
                of: view,
                configuration: config,
                identifier: "partner-detail-\(config.identifier)"
            )
        }
    }
    
    func testCartViewSnapshots() throws {
        let configurations = DeviceConfiguration.allTestConfigurations
        
        for config in configurations {
            // Test empty cart
            let emptyCartView = CartView()
                .environmentObject(createEmptyCartViewModel())
            
            try snapshotManager.captureSnapshot(
                of: emptyCartView,
                configuration: config,
                identifier: "cart-empty-\(config.identifier)"
            )
            
            // Test cart with items
            let filledCartView = CartView()
                .environmentObject(createFilledCartViewModel())
            
            try snapshotManager.captureSnapshot(
                of: filledCartView,
                configuration: config,
                identifier: "cart-filled-\(config.identifier)"
            )
        }
    }
    
    // MARK: - Accessibility Snapshots
    
    func testAccessibilitySnapshots() throws {
        let accessibilityConfigs = DeviceConfiguration.accessibilityConfigurations
        
        for config in accessibilityConfigs {
            // Test with large text
            let view = createAccessibilityTestView()
            
            try snapshotManager.captureSnapshot(
                of: view,
                configuration: config,
                identifier: "accessibility-\(config.identifier)"
            )
        }
    }
    
    // MARK: - Dark Mode Snapshots
    
    func testDarkModeSnapshots() throws {
        let darkModeConfigs = DeviceConfiguration.darkModeConfigurations
        
        for config in darkModeConfigs {
            let view = createDarkModeTestView()
            
            try snapshotManager.captureSnapshot(
                of: view,
                configuration: config,
                identifier: "darkmode-\(config.identifier)"
            )
        }
    }
    
    // MARK: - Localization Snapshots
    
    func testLocalizationSnapshots() throws {
        let locales = ["en", "es", "fr", "de", "ja", "ar"]
        let baseConfig = DeviceConfiguration.iPhone15Pro
        
        for locale in locales {
            let config = DeviceConfiguration(
                device: baseConfig.device,
                orientation: baseConfig.orientation,
                colorScheme: baseConfig.colorScheme,
                sizeCategory: baseConfig.sizeCategory,
                locale: Locale(identifier: locale)
            )
            
            let view = createLocalizationTestView()
            
            try snapshotManager.captureSnapshot(
                of: view,
                configuration: config,
                identifier: "localization-\(locale)"
            )
        }
    }
    
    // MARK: - Error State Snapshots
    
    func testErrorStateSnapshots() throws {
        let configurations = [DeviceConfiguration.iPhone15Pro, DeviceConfiguration.iPadPro]
        
        for config in configurations {
            // Network error
            let networkErrorView = ErrorStateView(
                error: AppError.network(.noConnection),
                retryAction: {}
            )
            
            try snapshotManager.captureSnapshot(
                of: networkErrorView,
                configuration: config,
                identifier: "error-network-\(config.identifier)"
            )
            
            // Authentication error
            let authErrorView = ErrorStateView(
                error: AppError.authentication(.signInFailed("Test error")),
                retryAction: {}
            )
            
            try snapshotManager.captureSnapshot(
                of: authErrorView,
                configuration: config,
                identifier: "error-auth-\(config.identifier)"
            )
        }
    }
    
    // MARK: - Loading State Snapshots
    
    func testLoadingStateSnapshots() throws {
        let configurations = [DeviceConfiguration.iPhone15Pro, DeviceConfiguration.iPadPro]
        
        for config in configurations {
            let loadingView = LoadingView(message: "Loading partners...")
            
            try snapshotManager.captureSnapshot(
                of: loadingView,
                configuration: config,
                identifier: "loading-\(config.identifier)"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createButtonTestView() -> some View {
        VStack(spacing: Spacing.md) {
            PrimaryButton(title: "Primary Button") {}
            SecondaryButton(title: "Secondary Button") {}
            PrimaryButton(title: "Loading", action: {}, isLoading: true)
            PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        }
        .padding()
    }
    
    private func createTextFieldTestView() -> some View {
        VStack(spacing: Spacing.md) {
            AppTextField(
                title: "Email",
                placeholder: "Enter your email",
                text: .constant("")
            )
            
            AppTextField(
                title: "Password",
                placeholder: "Enter password",
                text: .constant(""),
                isSecure: true
            )
            
            AppTextField(
                title: "Error Field",
                placeholder: "This has an error",
                text: .constant("invalid@"),
                errorMessage: "Please enter a valid email"
            )
        }
        .padding()
    }
    
    private func createCardTestView() -> some View {
        VStack(spacing: Spacing.md) {
            AppCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Card Title")
                        .font(.titleMedium)
                    Text("This is a sample card content.")
                        .font(.bodyMedium)
                }
            }
            
            AppCard(padding: Spacing.sm, cornerRadius: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.warning)
                    Text("Compact Card")
                        .font(.labelMedium)
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    private func createBadgeTestView() -> some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Badge(text: "New", style: .primary, size: .small)
                Badge(text: "Available", style: .success, size: .medium)
                Badge(text: "Urgent", style: .error, size: .large)
            }
            
            HStack(spacing: Spacing.sm) {
                Badge(text: "Warning", style: .warning)
                Badge(text: "Info", style: .info)
                Badge(text: "Neutral", style: .neutral)
            }
        }
        .padding()
    }
    
    private func createMockExploreData() -> ExploreData {
        return ExploreData(
            featuredPartners: [
                createTestPartner(name: "Featured Restaurant", rating: 4.8),
                createTestPartner(name: "Featured Pharmacy", rating: 4.9)
            ],
            categories: PartnerCategory.allCases,
            partners: [
                createTestPartner(name: "Local Restaurant", category: .restaurant),
                createTestPartner(name: "Corner Pharmacy", category: .pharmacy),
                createTestPartner(name: "Grocery Store", category: .grocery)
            ]
        )
    }
    
    private func createTestPartner(
        name: String = "Test Partner",
        category: PartnerCategory = .restaurant,
        rating: Double = 4.5
    ) -> Partner {
        return Partner(
            id: UUID().uuidString,
            name: name,
            category: category,
            description: "Test description for \(name)",
            address: Address(
                street: "123 Test Street",
                city: "Test City",
                state: "CA",
                postalCode: "12345",
                country: "US"
            ),
            location: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            phoneNumber: "+1234567890",
            email: "test@example.com",
            heroImageURL: URL(string: "https://picsum.photos/400/200"),
            logoURL: URL(string: "https://picsum.photos/100/100"),
            isVerified: true,
            isActive: true,
            rating: rating,
            reviewCount: 100,
            openingHours: [:],
            deliveryRadius: 5.0,
            minimumOrderAmount: 1000,
            estimatedDeliveryTime: 30,
            createdAt: Date()
        )
    }
    
    private func createEmptyCartViewModel() -> CartViewModel {
        let viewModel = CartViewModel(cartService: MockCartService())
        return viewModel
    }
    
    private func createFilledCartViewModel() -> CartViewModel {
        let mockService = MockCartService()
        mockService.mockCartItems = [
            CartItem(
                id: "item-1",
                productId: "product-1",
                productName: "Delicious Pizza",
                quantity: 2,
                unitPrice: 1500,
                totalPrice: 3000,
                specialInstructions: "Extra cheese"
            ),
            CartItem(
                id: "item-2",
                productId: "product-2",
                productName: "Fresh Salad",
                quantity: 1,
                unitPrice: 800,
                totalPrice: 800,
                specialInstructions: nil
            )
        ]
        
        let viewModel = CartViewModel(cartService: mockService)
        return viewModel
    }
    
    private func createAccessibilityTestView() -> some View {
        VStack(spacing: Spacing.lg) {
            Text("Accessibility Test")
                .font(.headlineLarge)
                .accessibilityLabel("Main heading: Accessibility Test")
            
            Text("This text should scale with Dynamic Type and be readable in high contrast mode.")
                .font(.bodyMedium)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: "Accessible Button") {}
                .accessibilityLabel("Primary action button")
                .accessibilityHint("Tap to perform the main action")
        }
        .padding()
    }
    
    private func createDarkModeTestView() -> some View {
        VStack(spacing: Spacing.lg) {
            Text("Dark Mode Test")
                .font(.headlineLarge)
                .foregroundColor(.primary)
            
            AppCard {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Dark Mode Card")
                        .font(.titleMedium)
                        .foregroundColor(.primary)
                    
                    Text("This card should look good in both light and dark modes.")
                        .font(.bodyMedium)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: Spacing.md) {
                PrimaryButton(title: "Primary") {}
                SecondaryButton(title: "Secondary") {}
            }
        }
        .padding()
    }
    
    private func createLocalizationTestView() -> some View {
        VStack(spacing: Spacing.lg) {
            Text("localization.test.title")
                .font(.headlineLarge)
            
            Text("localization.test.description")
                .font(.bodyMedium)
                .multilineTextAlignment(.center)
            
            HStack(spacing: Spacing.md) {
                PrimaryButton(title: NSLocalizedString("button.continue", comment: "Continue button")) {}
                SecondaryButton(title: NSLocalizedString("button.cancel", comment: "Cancel button")) {}
            }
        }
        .padding()
    }
}

// MARK: - Snapshot Manager

class SnapshotManager {
    private let snapshotDirectory: URL
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        snapshotDirectory = documentsPath.appendingPathComponent("Snapshots")
        
        // Create snapshots directory if it doesn't exist
        try? FileManager.default.createDirectory(at: snapshotDirectory, withIntermediateDirectories: true)
    }
    
    func captureSnapshot<Content: View>(
        of view: Content,
        configuration: DeviceConfiguration,
        identifier: String
    ) throws {
        let hostingController = UIHostingController(rootView: view)
        
        // Configure the hosting controller based on the device configuration
        configureHostingController(hostingController, with: configuration)
        
        // Capture the snapshot
        let snapshot = try captureImage(from: hostingController, configuration: configuration)
        
        // Save or compare the snapshot
        try saveOrCompareSnapshot(snapshot, identifier: identifier, configuration: configuration)
    }
    
    private func configureHostingController<Content: View>(
        _ hostingController: UIHostingController<Content>,
        with configuration: DeviceConfiguration
    ) {
        // Set size based on device
        let size = configuration.device.screenSize
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        
        // Configure traits
        let traitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: configuration.colorScheme == .dark ? .dark : .light),
            UITraitCollection(preferredContentSizeCategory: configuration.sizeCategory.uiContentSizeCategory),
            UITraitCollection(layoutDirection: configuration.locale.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight)
        ])
        
        hostingController.setOverrideTraitCollection(traitCollection, forChild: hostingController)
        
        // Force layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }
    
    private func captureImage<Content: View>(
        from hostingController: UIHostingController<Content>,
        configuration: DeviceConfiguration
    ) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: hostingController.view.bounds.size)
        
        return renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
    }
    
    private func saveOrCompareSnapshot(
        _ snapshot: UIImage,
        identifier: String,
        configuration: DeviceConfiguration
    ) throws {
        let filename = "\(identifier).png"
        let fileURL = snapshotDirectory.appendingPathComponent(filename)
        
        guard let snapshotData = snapshot.pngData() else {
            throw SnapshotError.failedToGenerateImageData
        }
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // Compare with existing snapshot
            let existingData = try Data(contentsOf: fileURL)
            
            if !snapshotData.elementsEqual(existingData) {
                // Snapshots don't match - save the new one with a different name for comparison
                let failedURL = snapshotDirectory.appendingPathComponent("FAILED_\(filename)")
                try snapshotData.write(to: failedURL)
                
                throw SnapshotError.snapshotMismatch(identifier: identifier, failedURL: failedURL)
            }
        } else {
            // Save new snapshot
            try snapshotData.write(to: fileURL)
        }
    }
}

// MARK: - Device Configuration

struct DeviceConfiguration {
    let device: Device
    let orientation: UIDeviceOrientation
    let colorScheme: ColorScheme
    let sizeCategory: ContentSizeCategory
    let locale: Locale
    
    var identifier: String {
        return "\(device.identifier)-\(orientation.identifier)-\(colorScheme.identifier)-\(sizeCategory.identifier)-\(locale.identifier)"
    }
    
    static let iPhone15Pro = DeviceConfiguration(
        device: .iPhone15Pro,
        orientation: .portrait,
        colorScheme: .light,
        sizeCategory: .medium,
        locale: Locale(identifier: "en")
    )
    
    static let iPadPro = DeviceConfiguration(
        device: .iPadPro,
        orientation: .portrait,
        colorScheme: .light,
        sizeCategory: .medium,
        locale: Locale(identifier: "en")
    )
    
    static let allTestConfigurations: [DeviceConfiguration] = [
        iPhone15Pro,
        iPadPro,
        DeviceConfiguration(device: .iPhone15Pro, orientation: .landscape, colorScheme: .light, sizeCategory: .medium, locale: Locale(identifier: "en")),
        DeviceConfiguration(device: .iPhone15Pro, orientation: .portrait, colorScheme: .dark, sizeCategory: .medium, locale: Locale(identifier: "en"))
    ]
    
    static let accessibilityConfigurations: [DeviceConfiguration] = [
        DeviceConfiguration(device: .iPhone15Pro, orientation: .portrait, colorScheme: .light, sizeCategory: .accessibilityExtraExtraExtraLarge, locale: Locale(identifier: "en")),
        DeviceConfiguration(device: .iPhone15Pro, orientation: .portrait, colorScheme: .dark, sizeCategory: .accessibilityLarge, locale: Locale(identifier: "en"))
    ]
    
    static let darkModeConfigurations: [DeviceConfiguration] = [
        DeviceConfiguration(device: .iPhone15Pro, orientation: .portrait, colorScheme: .dark, sizeCategory: .medium, locale: Locale(identifier: "en")),
        DeviceConfiguration(device: .iPadPro, orientation: .portrait, colorScheme: .dark, sizeCategory: .medium, locale: Locale(identifier: "en"))
    ]
}

// MARK: - Device Types

enum Device {
    case iPhone15Pro
    case iPadPro
    
    var screenSize: CGSize {
        switch self {
        case .iPhone15Pro:
            return CGSize(width: 393, height: 852)
        case .iPadPro:
            return CGSize(width: 1024, height: 1366)
        }
    }
    
    var identifier: String {
        switch self {
        case .iPhone15Pro:
            return "iPhone15Pro"
        case .iPadPro:
            return "iPadPro"
        }
    }
}

// MARK: - Extensions

extension UIDeviceOrientation {
    var identifier: String {
        switch self {
        case .portrait:
            return "portrait"
        case .landscape:
            return "landscape"
        default:
            return "unknown"
        }
    }
}

extension ColorScheme {
    var identifier: String {
        switch self {
        case .light:
            return "light"
        case .dark:
            return "dark"
        @unknown default:
            return "unknown"
        }
    }
}

extension ContentSizeCategory {
    var identifier: String {
        switch self {
        case .small:
            return "small"
        case .medium:
            return "medium"
        case .large:
            return "large"
        case .accessibilityLarge:
            return "accessibilityLarge"
        case .accessibilityExtraExtraExtraLarge:
            return "accessibilityXXXL"
        default:
            return "default"
        }
    }
    
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .small:
            return .small
        case .medium:
            return .medium
        case .large:
            return .large
        case .accessibilityLarge:
            return .accessibilityLarge
        case .accessibilityExtraExtraExtraLarge:
            return .accessibilityExtraExtraExtraLarge
        default:
            return .medium
        }
    }
}

extension Locale {
    var identifier: String {
        return self.languageCode ?? "en"
    }
    
    var characterDirection: Locale.CharacterDirection {
        return Locale.characterDirection(forLanguage: self.languageCode ?? "en")
    }
}

// MARK: - Supporting Types

struct ExploreData {
    let featuredPartners: [Partner]
    let categories: [PartnerCategory]
    let partners: [Partner]
}

enum SnapshotError: Error, LocalizedError {
    case failedToGenerateImageData
    case snapshotMismatch(identifier: String, failedURL: URL)
    
    var errorDescription: String? {
        switch self {
        case .failedToGenerateImageData:
            return "Failed to generate image data from snapshot"
        case .snapshotMismatch(let identifier, let failedURL):
            return "Snapshot mismatch for \(identifier). Failed snapshot saved to: \(failedURL.path)"
        }
    }
}