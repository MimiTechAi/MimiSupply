# Analytics and Monitoring System

This document describes the comprehensive analytics and monitoring system implemented for MimiSupply, including privacy-compliant event tracking, performance monitoring, crash reporting, feature flags, and business intelligence.

## Overview

The analytics system is designed with privacy-first principles, ensuring GDPR compliance and user consent management. It provides:

- **Event Tracking**: User interactions, screen views, and business events
- **Performance Monitoring**: App performance metrics and custom measurements
- **Crash Reporting**: Error tracking and crash analytics
- **Feature Flags**: A/B testing and gradual feature rollouts
- **Business Intelligence**: Partner dashboard with analytics and insights

## Architecture

```
AnalyticsService (Protocol)
├── AnalyticsServiceImpl (Implementation)
├── FeatureFlagService (Protocol)
├── FeatureFlagServiceImpl (Implementation)
├── AnalyticsManager (Singleton)
└── BusinessIntelligenceDashboard (UI)
```

## Core Components

### 1. AnalyticsService

The main analytics service handles all event tracking, performance monitoring, and crash reporting.

```swift
// Track user events
await analytics.trackEvent(.userSignIn, parameters: ["method": "apple"])

// Track screen views
await analytics.trackScreenView("ExploreHomeView", parameters: ["source": "tab"])

// Track performance metrics
let measurement = analytics.startPerformanceMeasurement("api_call")
// ... perform operation
let metric = measurement.end()
await analytics.trackPerformanceMetric(metric)

// Track errors
await analytics.trackError(error, context: ["action": "checkout"])
```

### 2. FeatureFlagService

Manages feature flags and A/B testing experiments.

```swift
// Check if feature is enabled
let isEnabled = await featureFlags.isFeatureEnabled(.enhancedSearch)

// Get experiment variant
let variant = await featureFlags.getExperimentVariant("checkout_flow")
```

### 3. AnalyticsManager

Singleton that coordinates all analytics services and provides convenient access.

```swift
// Initialize in app startup
AnalyticsManager.shared.configure()

// Track events
AnalyticsManager.shared.trackEvent(.productViewed, parameters: ["id": "123"])

// Check feature flags
let isEnabled = await AnalyticsManager.shared.isFeatureEnabled(.darkMode)
```

## Privacy and Compliance

### Data Collection Principles

1. **Data Minimization**: Only collect necessary data for app functionality
2. **User Consent**: Respect user preferences for analytics and crash reporting
3. **PII Protection**: Automatically filter out personally identifiable information
4. **Transparency**: Clear disclosure of what data is collected and why

### PII Filtering

The system automatically filters out potentially sensitive data:

```swift
// These parameters would be filtered out
let parameters = [
    "email": "user@example.com",     // Filtered
    "phone": "123-456-7890",         // Filtered
    "user_role": "customer",         // Allowed
    "app_version": "1.0.0"           // Allowed
]
```

### User Controls

Users can control their privacy settings:

- Analytics enabled/disabled
- Crash reporting enabled/disabled
- Performance monitoring enabled/disabled

## Event Types

### User Events
- `user_sign_in`: User authentication
- `user_sign_out`: User logout
- `role_selected`: User role selection

### Navigation Events
- `screen_view`: Screen navigation
- `tab_switch`: Tab navigation
- `deep_link_opened`: Deep link handling

### Commerce Events
- `product_viewed`: Product detail view
- `add_to_cart`: Add item to cart
- `checkout_started`: Begin checkout
- `payment_completed`: Payment success
- `order_placed`: Order creation

### Performance Events
- `app_launch`: App startup time
- `screen_load`: Screen load time
- `api_call`: API response time

### Error Events
- `error_occurred`: Application errors
- `crash_reported`: App crashes

## Performance Monitoring

### Custom Metrics

Track custom performance metrics:

```swift
let metric = PerformanceMetric(
    name: "image_load_time",
    value: 250.0,
    unit: "ms",
    metadata: ["image_size": "large"]
)
await analytics.trackPerformanceMetric(metric)
```

### Signposts

Uses os_signpost for detailed performance analysis:

```swift
let measurement = analytics.startPerformanceMeasurement("complex_operation")
// ... perform operation
let metric = measurement.end(metadata: ["items_processed": "100"])
```

## Feature Flags

### Available Features

```swift
enum FeatureFlag: String, CaseIterable {
    // UI/UX Features
    case newOnboardingFlow = "new_onboarding_flow"
    case enhancedSearch = "enhanced_search"
    case darkModeEnabled = "dark_mode_enabled"
    
    // Performance Features
    case imageOptimization = "image_optimization"
    case backgroundSync = "background_sync"
    
    // Business Features
    case loyaltyProgram = "loyalty_program"
    case scheduledDelivery = "scheduled_delivery"
    
    // Experimental Features
    case aiRecommendations = "ai_recommendations"
    case voiceOrdering = "voice_ordering"
}
```

### A/B Testing

Configure experiments with traffic allocation:

```swift
let experiment = ExperimentConfig(
    name: "checkout_flow_experiment",
    variants: ["control", "single_page", "progressive"],
    trafficAllocation: [
        "control": 0.4,
        "single_page": 0.3,
        "progressive": 0.3
    ],
    isActive: true
)
```

## SwiftUI Integration

### View Modifiers

Track screens automatically:

```swift
struct MyView: View {
    var body: some View {
        VStack {
            // Content
        }
        .trackScreen("MyView", parameters: ["source": "navigation"])
        .trackPerformance("my_view_load")
    }
}
```

### Feature Flag Conditional Views

```swift
struct MyView: View {
    var body: some View {
        VStack {
            Text("Always visible")
            
            Text("Feature flag controlled")
                .showIf(featureEnabled: .enhancedSearch)
        }
    }
}
```

### Experiment Variants

```swift
struct MyView: View {
    var body: some View {
        VStack {
            // Content
        }
        .experimentVariant("checkout_flow", variants: [
            "single_page": { SinglePageCheckout() },
            "progressive": { ProgressiveCheckout() }
        ], default: { StandardCheckout() })
    }
}
```

## Business Intelligence

### Partner Dashboard

The business intelligence dashboard provides:

- **Key Metrics**: Revenue, orders, customers, ratings
- **Revenue Trends**: Time-series charts with multiple time ranges
- **Order Analytics**: Completion rates, average order value, delivery times
- **Customer Insights**: New vs returning customers, lifetime value, churn
- **Performance Metrics**: App performance, API response times, crash rates
- **Top Products**: Best-selling items with revenue data

### Usage

```swift
struct PartnerDashboard: View {
    var body: some View {
        NavigationStack {
            BusinessIntelligenceDashboard()
        }
    }
}
```

## Data Storage

### Local Storage

- Events are buffered locally before transmission
- Failed events are retried automatically
- Old analytics files are cleaned up automatically

### File Structure

```
Documents/
├── analytics/
│   ├── events_2024-01-15_10-30-00.json
│   ├── events_2024-01-15_11-00-00.json
│   └── ...
└── reports/
    ├── business_report_2024-01-15_12-00-00.md
    └── ...
```

## Testing

### Unit Tests

Comprehensive test coverage for:

- Event tracking accuracy
- PII filtering
- Performance measurement precision
- Feature flag evaluation
- Error handling

### Privacy Tests

Specific tests for privacy compliance:

- PII data filtering
- User consent respect
- Data retention compliance

### Performance Tests

- Event tracking performance
- Memory usage monitoring
- Concurrent access safety

## Configuration

### UserDefaults Keys

```swift
// Privacy settings
"analytics_enabled" -> Bool
"crash_reporting_enabled" -> Bool

// Feature flags
"feature_flags" -> Data (JSON)
"user_variants" -> Data (JSON)

// User identification
"user_experiment_id" -> String
```

### Environment Variables

For production deployment:

- `ANALYTICS_ENDPOINT`: Analytics backend URL
- `FEATURE_FLAGS_ENDPOINT`: Feature flags service URL
- `CRASH_REPORTING_KEY`: Crash reporting service key

## Best Practices

### Event Naming

Use consistent naming conventions:

- Use snake_case for event names
- Include action and object: `product_viewed`, `cart_updated`
- Be specific but not verbose: `checkout_started` not `user_started_checkout_process`

### Parameter Guidelines

- Use consistent parameter names across events
- Include context when helpful: `source`, `screen_name`, `user_role`
- Avoid nested objects when possible
- Always sanitize user input

### Performance Considerations

- Events are batched and sent asynchronously
- Local buffering prevents blocking UI
- Automatic retry for failed transmissions
- Configurable flush intervals and buffer sizes

### Error Handling

- Graceful degradation when analytics fails
- No user-facing errors from analytics
- Comprehensive logging for debugging
- Fallback to local storage when network unavailable

## Monitoring and Alerting

### Key Metrics to Monitor

- Event ingestion rate
- Error rates and types
- Performance metric trends
- Feature flag evaluation frequency
- User engagement metrics

### Alerts

Set up alerts for:

- High crash rates
- Performance degradation
- Analytics service failures
- Unusual user behavior patterns

## Future Enhancements

### Planned Features

1. **Real-time Analytics**: Live dashboard updates
2. **Advanced Segmentation**: User cohort analysis
3. **Predictive Analytics**: ML-powered insights
4. **Custom Dashboards**: Partner-specific views
5. **Export Capabilities**: Data export in multiple formats

### Integration Opportunities

- Third-party analytics services
- Business intelligence tools
- Customer support systems
- Marketing automation platforms

## Support and Troubleshooting

### Common Issues

1. **Events not appearing**: Check user consent settings
2. **Performance impact**: Verify async processing
3. **Feature flags not updating**: Check refresh intervals
4. **Memory usage**: Monitor buffer sizes

### Debug Mode

Enable debug logging:

```swift
// In development builds
UserDefaults.standard.set(true, forKey: "analytics_debug_mode")
```

### Contact

For questions or issues with the analytics system:

- Technical Lead: [Your Name]
- Product Manager: [PM Name]
- Data Team: [Data Team Contact]