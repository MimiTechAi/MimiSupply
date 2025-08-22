---
description: Repository Information Overview
alwaysApply: true
---

# MimiSupply iOS App Information

## Summary
MimiSupply is a comprehensive iOS application built with SwiftUI that facilitates supply chain management between customers, drivers, and partners. The app features real-time order tracking, payment processing, offline support, and multi-language localization.

## Structure
- **MimiSupply/**: Main application code
  - **App/**: App initialization and configuration
  - **Features/**: Feature modules (Authentication, Cart, Orders, etc.)
  - **Domain/**: Business logic and services
  - **Data/**: Data models and repositories
  - **Foundation/**: Core utilities and extensions
  - **DesignSystem/**: UI components and styling
  - **Presentation/**: View controllers and UI logic
  - **Resources/**: Localization and assets
- **MimiSupplyTests/**: Comprehensive test suite
- **MimiSupplyUITests/**: UI automation tests

## Language & Runtime
**Language**: Swift
**iOS Deployment Target**: iOS 17.0+
**Build System**: Xcode
**Architecture**: MVVM with SwiftUI

## Dependencies
**Main Dependencies**:
- **SwiftUI**: UI framework
- **CloudKit**: Data synchronization and storage
- **GooglePlaces**: Location services and mapping
- **StoreKit**: In-app purchases and payments

**System Frameworks**:
- CoreData: Local data persistence
- MapKit: Mapping and directions
- StoreKit: Payment processing
- BackgroundTasks: Background processing

## Build & Installation
```bash
# Build the app
xcodebuild -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Run tests
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Archive for distribution
xcodebuild -scheme MimiSupply archive -archivePath ./build/MimiSupply.xcarchive
```

## Testing
**Frameworks**: XCTest
**Test Location**: MimiSupplyTests/ and MimiSupplyUITests/
**Test Categories**:
- Unit Tests: Business logic, repositories, services
- Integration Tests: End-to-end workflows
- UI Tests: Screen interactions and navigation
- Performance Tests: Startup time, memory usage
- Accessibility Tests: WCAG 2.2 compliance

**Run Command**:
```bash
# Run all tests
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test category
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:MimiSupplyTests/Performance
```

## Features
**Core Functionality**:
- Multi-role support (Customer, Driver, Partner)
- Real-time order tracking and management
- Integrated payment processing
- Offline support with data synchronization
- Push notifications for order updates
- Location-based services
- Multi-language support (40+ languages)

**Technical Features**:
- CloudKit integration for data synchronization
- Background task processing
- Memory optimization
- Graceful degradation for service outages
- Comprehensive error handling
- Analytics tracking