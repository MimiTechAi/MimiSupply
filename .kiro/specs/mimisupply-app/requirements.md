# MimiSupply iOS App - Requirements Document

## Introduction

MimiSupply is a production-grade iOS 17+ SwiftUI app that connects customers, local businesses (restaurants, shops, pharmacies), and freelance drivers in a three-sided marketplace. The app follows an "Explore-First" approach where users can browse without authentication, with login gates only at critical interaction points. The app aims to outperform competitors like Grab/UberEats/Bolt in UX, accessibility, performance, and polish while maintaining Fortune-33 quality standards.

## Requirements

### Requirement 1: Explore-First User Experience

**User Story:** As a visitor, I want to explore partners, products, and build a cart without creating an account, so that I can evaluate the service before committing to registration.

#### Acceptance Criteria

1. WHEN a user opens the app for the first time THEN the system SHALL display the ExploreHomeView without requiring authentication
2. WHEN a user browses partners and products THEN the system SHALL load data from CloudKit Public Database without authentication
3. WHEN a user adds items to cart THEN the system SHALL store cart data locally using CoreData
4. WHEN a user attempts checkout THEN the system SHALL present authentication as a gate
5. WHEN a user switches between map and list views THEN the system SHALL maintain cart state and browsing context
6. WHEN the app launches THEN the system SHALL achieve first screen TTI < 1.0s on mid-range devices

### Requirement 2: Authentication and Role Management

**User Story:** As a user, I want to authenticate with Sign in with Apple and select my role, so that I can access role-specific features securely.

#### Acceptance Criteria

1. WHEN a user reaches an authentication gate THEN the system SHALL present Sign in with Apple as the only option
2. WHEN authentication is successful THEN the system SHALL store credentials securely in Keychain
3. WHEN a new user completes authentication THEN the system SHALL present role selection (Customer, Driver, Partner)
4. WHEN a user selects a role THEN the system SHALL sync the profile to CloudKit Private Database
5. WHEN a returning user opens the app THEN the system SHALL automatically authenticate and navigate to role-appropriate home screen
6. WHEN authentication fails THEN the system SHALL provide clear error messages and retry options

### Requirement 3: Customer Experience

**User Story:** As a customer, I want to browse local businesses, order products, pay with Apple Pay, and track my delivery, so that I can get what I need conveniently.

#### Acceptance Criteria

1. WHEN a customer views the home screen THEN the system SHALL display search, categories, featured partners, and map toggle
2. WHEN a customer searches for products THEN the system SHALL provide real-time search results with filtering options
3. WHEN a customer views a partner detail THEN the system SHALL show products, hours, ratings, and location
4. WHEN a customer proceeds to checkout THEN the system SHALL present Apple Pay with itemized pricing
5. WHEN payment is successful THEN the system SHALL create an order in CloudKit and assign a driver
6. WHEN an order is placed THEN the system SHALL show OrderTrackingView with real-time driver location and ETA
7. WHEN order status changes THEN the system SHALL send push notifications and update the tracking view

### Requirement 4: Driver Experience

**User Story:** As a driver, I want to receive job notifications, accept orders, navigate to pickup/delivery locations, and update order status, so that I can earn money efficiently.

#### Acceptance Criteria

1. WHEN a driver opens the app THEN the system SHALL display available jobs and earnings dashboard
2. WHEN a new order is available THEN the system SHALL send a push notification with order details
3. WHEN a driver accepts an order THEN the system SHALL provide navigation to pickup location using MapKit
4. WHEN a driver starts location sharing THEN the system SHALL update their location every 10 seconds in background
5. WHEN a driver picks up an order THEN the system SHALL update order status and notify customer
6. WHEN a driver completes delivery THEN the system SHALL update order status and process payment
7. WHEN a driver goes offline THEN the system SHALL stop location sharing and remove from available drivers

### Requirement 5: Partner (Business) Experience

**User Story:** As a business partner, I want to manage my products, view incoming orders, and update order statuses, so that I can serve customers effectively.

#### Acceptance Criteria

1. WHEN a partner opens the app THEN the system SHALL display their dashboard with pending orders and product management
2. WHEN a partner adds a product THEN the system SHALL sync it to CloudKit Public Database with proper indexing
3. WHEN a partner receives an order THEN the system SHALL send a push notification and display order details
4. WHEN a partner updates order status to "preparing" THEN the system SHALL notify the assigned driver
5. WHEN a partner marks an order as "ready for pickup" THEN the system SHALL update all stakeholders
6. WHEN a partner updates business hours THEN the system SHALL reflect changes in customer-facing views
7. WHEN a partner uploads product images THEN the system SHALL optimize and cache them efficiently

### Requirement 6: Real-Time Order Management

**User Story:** As a system, I want to manage orders in real-time across all stakeholders, so that everyone stays informed of order progress.

#### Acceptance Criteria

1. WHEN an order is created THEN the system SHALL assign it to the nearest available driver
2. WHEN order status changes THEN the system SHALL update all relevant parties via push notifications
3. WHEN a driver location updates THEN the system SHALL update customer's tracking view with new ETA
4. WHEN network connectivity is lost THEN the system SHALL queue updates locally and sync when reconnected
5. WHEN conflicts occur in order status THEN the system SHALL resolve them using timestamp-based conflict resolution
6. WHEN an order is cancelled THEN the system SHALL notify all parties and process appropriate refunds

### Requirement 7: Payment and Financial Management

**User Story:** As a customer, I want to pay securely with Apple Pay and receive receipts, so that my transactions are safe and trackable.

#### Acceptance Criteria

1. WHEN a customer proceeds to checkout THEN the system SHALL calculate total with taxes, delivery fees, and platform fees
2. WHEN Apple Pay is initiated THEN the system SHALL present itemized payment sheet with merchant information
3. WHEN payment is successful THEN the system SHALL store transaction details securely
4. WHEN payment fails THEN the system SHALL provide clear error messages and retry options
5. WHEN a transaction is completed THEN the system SHALL send digital receipt via email
6. WHEN refunds are needed THEN the system SHALL process them through Apple Pay
7. WHEN drivers complete deliveries THEN the system SHALL calculate and distribute earnings

### Requirement 8: Maps and Location Services

**User Story:** As a user, I want accurate location services for finding nearby businesses and tracking deliveries, so that I can make informed decisions and track my orders.

#### Acceptance Criteria

1. WHEN a customer views the map THEN the system SHALL show nearby partners with accurate locations
2. WHEN location permission is granted THEN the system SHALL use current location for relevant searches
3. WHEN a driver is in delivery mode THEN the system SHALL track location with background updates
4. WHEN tracking an order THEN the system SHALL show driver location and estimated route
5. WHEN location services are disabled THEN the system SHALL provide manual location entry options
6. WHEN battery optimization is needed THEN the system SHALL adjust location update frequency intelligently

### Requirement 9: Push Notifications and Communication

**User Story:** As a user, I want to receive timely notifications about order updates and important events, so that I stay informed without constantly checking the app.

#### Acceptance Criteria

1. WHEN order status changes THEN the system SHALL send targeted push notifications to relevant users
2. WHEN a driver accepts an order THEN the system SHALL notify the customer with driver details
3. WHEN delivery is imminent THEN the system SHALL send arrival notifications
4. WHEN notifications are disabled THEN the system SHALL respect user preferences and use in-app alerts
5. WHEN the app is in background THEN the system SHALL handle silent push notifications for data updates
6. WHEN critical errors occur THEN the system SHALL send appropriate notifications to affected users

### Requirement 10: Accessibility and Inclusive Design

**User Story:** As a user with accessibility needs, I want the app to be fully accessible with assistive technologies, so that I can use all features regardless of my abilities.

#### Acceptance Criteria

1. WHEN using VoiceOver THEN the system SHALL provide clear, descriptive labels for all interactive elements
2. WHEN using Dynamic Type THEN the system SHALL scale all text appropriately up to accessibility sizes
3. WHEN using high contrast mode THEN the system SHALL maintain WCAG 2.2 AA+ compliance
4. WHEN using Switch Control THEN the system SHALL provide logical navigation paths
5. WHEN Reduce Motion is enabled THEN the system SHALL minimize animations and transitions
6. WHEN using keyboard navigation THEN the system SHALL support full keyboard accessibility

### Requirement 11: Performance and Reliability

**User Story:** As a user, I want the app to be fast, reliable, and work offline when possible, so that I can depend on it for my daily needs.

#### Acceptance Criteria

1. WHEN the app launches cold THEN the system SHALL achieve startup time < 2.5s
2. WHEN scrolling through content THEN the system SHALL maintain smooth 120Hz performance
3. WHEN network is unavailable THEN the system SHALL provide offline functionality with cached data
4. WHEN images are loaded THEN the system SHALL use efficient caching and lazy loading
5. WHEN memory pressure occurs THEN the system SHALL gracefully manage resources
6. WHEN background tasks run THEN the system SHALL respect system limits and battery life

### Requirement 12: Data Privacy and Security

**User Story:** As a user, I want my personal data to be protected and used minimally, so that my privacy is respected.

#### Acceptance Criteria

1. WHEN collecting user data THEN the system SHALL follow data minimization principles
2. WHEN storing sensitive data THEN the system SHALL use appropriate encryption and security measures
3. WHEN syncing data THEN the system SHALL use CloudKit's built-in security and per-record permissions
4. WHEN tracking analytics THEN the system SHALL collect only non-PII data with user consent
5. WHEN handling payments THEN the system SHALL never store payment credentials locally
6. WHEN users request data deletion THEN the system SHALL provide complete data removal

### Requirement 13: Multi-Language and Localization

**User Story:** As a user in different regions, I want the app to support my language and local conventions, so that I can use it naturally.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL detect and use the device's preferred language
2. WHEN displaying prices THEN the system SHALL format them according to local currency conventions
3. WHEN showing dates and times THEN the system SHALL use local formatting preferences
4. WHEN content is not available in user's language THEN the system SHALL gracefully fall back to default language
5. WHEN switching languages THEN the system SHALL update all UI elements without requiring app restart

### Requirement 14: Analytics and Business Intelligence

**User Story:** As a business stakeholder, I want to understand user behavior and app performance, so that I can make data-driven decisions for improvements.

#### Acceptance Criteria

1. WHEN users interact with the app THEN the system SHALL log non-PII analytics events
2. WHEN errors occur THEN the system SHALL capture and report crash data and error logs
3. WHEN performance issues arise THEN the system SHALL track and report performance metrics
4. WHEN A/B tests are running THEN the system SHALL support feature flags and variant tracking
5. WHEN generating reports THEN the system SHALL provide insights on user engagement and conversion

### Requirement 15: App Store Readiness and Distribution

**User Story:** As a business owner, I want the app to meet all App Store requirements and be ready for distribution, so that I can launch successfully.

#### Acceptance Criteria

1. WHEN submitting to App Store THEN the system SHALL meet all Apple guidelines and requirements
2. WHEN users download the app THEN the system SHALL provide proper onboarding and privacy disclosures
3. WHEN the app updates THEN the system SHALL handle version migrations gracefully
4. WHEN App Store review occurs THEN the system SHALL provide demo accounts and clear functionality
5. WHEN launching publicly THEN the system SHALL have proper error monitoring and rollback capabilities