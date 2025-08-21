# Comprehensive Error Handling System

This document describes the comprehensive error handling and recovery system implemented for the MimiSupply app.

## Overview

The error handling system provides:

1. **Global Error Handling** - Centralized error processing and user notification
2. **Network Error Recovery** - Automatic retry mechanisms with exponential backoff
3. **Offline Mode Support** - Cached data and sync queues for offline functionality
4. **Error Logging and Reporting** - Comprehensive error tracking and analytics
5. **Graceful Degradation** - Service failure handling with fallback strategies
6. **Error State UI Components** - User-friendly error displays and recovery actions
7. **Comprehensive Testing** - Unit, integration, and UI tests for all error scenarios

## Architecture

### Core Components

#### 1. ErrorHandler
- **Purpose**: Global error handling and user notification
- **Location**: `Foundation/Error/ErrorHandler.swift`
- **Usage**: Singleton that processes all errors and shows appropriate UI

```swift
// Handle an error with user notification
ErrorHandler.shared.handle(error, showToUser: true, context: "user_action")

// Show specific error to user
ErrorHandler.shared.showError(AppError.network(.noConnection))
```

#### 2. RetryManager
- **Purpose**: Automatic retry logic with exponential backoff
- **Location**: `Foundation/Error/RetryManager.swift`
- **Usage**: Retry failed operations with configurable parameters

```swift
// Retry an operation up to 3 times
let result = try await RetryManager.shared.retry(maxAttempts: 3) {
    try await someNetworkOperation()
}

// Retry when network becomes available
let result = try await RetryManager.shared.retryWhenNetworkAvailable {
    try await someNetworkOperation()
}
```

#### 3. OfflineManager
- **Purpose**: Offline functionality and data synchronization
- **Location**: `Data/Services/OfflineManager.swift`
- **Usage**: Queue operations for offline sync and manage cached data

```swift
// Queue an operation for offline sync
let operation = SyncOperation(type: .createOrder, data: order)
OfflineManager.shared.queueForSync(operation)

// Force sync now (if online)
await OfflineManager.shared.forceSyncNow()
```

#### 4. GracefulDegradationService
- **Purpose**: Service failure handling with fallback strategies
- **Location**: `Data/Services/GracefulDegradationService.swift`
- **Usage**: Monitor service health and implement fallback strategies

```swift
// Execute operation with fallback to cached data
let result = await GracefulDegradationService.shared.executeWithFallback(
    serviceType: .cloudKit,
    cacheKey: "partners_cache"
) {
    try await cloudKitService.fetchPartners()
}
```

#### 5. NetworkMonitor
- **Purpose**: Network connectivity monitoring
- **Location**: `Foundation/Error/RetryManager.swift` (embedded)
- **Usage**: Monitor network status and wait for connectivity

```swift
// Check if connected
if NetworkMonitor.shared.isConnected {
    // Perform network operation
}

// Wait for connection
await NetworkMonitor.shared.waitForConnection()
```

### UI Components

#### 1. ErrorStateView
- **Purpose**: Full-screen error state with recovery actions
- **Location**: `DesignSystem/Components/Error/ErrorStateView.swift`
- **Usage**: Show when primary functionality fails

```swift
ErrorStateView(
    error: AppError.network(.noConnection),
    onRetry: { await viewModel.retryOperation() },
    onDismiss: { viewModel.dismissError() }
)
```

#### 2. ErrorToast
- **Purpose**: Non-intrusive error notifications
- **Location**: `Foundation/Error/ErrorAlertModifier.swift`
- **Usage**: Show temporary error messages

```swift
// Show toast notification
ErrorToastManager.shared.showToast(for: error)

// Add toast support to view
SomeView()
    .errorToasts()
```

#### 3. InlineErrorView
- **Purpose**: Form validation and inline errors
- **Location**: `DesignSystem/Components/Error/ErrorStateView.swift`
- **Usage**: Show validation errors in forms

```swift
InlineErrorView("Please enter a valid email address")
```

#### 4. ServiceStatusIndicator
- **Purpose**: Show service degradation status
- **Location**: `Data/Services/GracefulDegradationService.swift`
- **Usage**: Inform users about service issues

```swift
ServiceStatusIndicator() // Automatically shows when services are degraded
```

## Error Types

### AppError Hierarchy

```swift
enum AppError: LocalizedError {
    case authentication(AuthenticationError)
    case network(NetworkError)
    case cloudKit(CKError)
    case location(LocationError)
    case payment(PaymentError)
    case validation(ValidationError)
    case dataNotFound(String)
    case unknown(Error)
}
```

### Specific Error Types

- **AuthenticationError**: Sign-in failures, token expiration
- **NetworkError**: Connection issues, timeouts, server errors
- **CloudKitError**: Sync failures, quota exceeded, permission issues
- **LocationError**: Permission denied, location unavailable
- **PaymentError**: Payment processing failures, Apple Pay issues
- **ValidationError**: Form validation, data format issues

## Usage Patterns

### 1. Service Layer Error Handling

```swift
final class SomeService {
    private let retryManager = RetryManager.shared
    private let degradationService = GracefulDegradationService.shared
    
    func performOperation() async throws -> Result {
        return try await retryManager.retry {
            do {
                let result = try await networkOperation()
                degradationService.reportServiceRecovery(.someService)
                return result
            } catch {
                degradationService.reportServiceFailure(.someService, error: error)
                throw error
            }
        }
    }
}
```

### 2. ViewModel Error Handling

```swift
@MainActor
final class SomeViewModel: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingErrorState = false
    
    private let errorHandler = ErrorHandler.shared
    
    func performAction() async {
        do {
            let result = try await service.performOperation()
            // Handle success
        } catch {
            let appError = convertToAppError(error)
            
            // Show error to user
            currentError = appError
            showingErrorState = true
            
            // Log error
            errorHandler.handle(appError, showToUser: false, context: "perform_action")
        }
    }
}
```

### 3. View Error Handling

```swift
struct SomeView: View {
    @StateObject private var viewModel = SomeViewModel()
    
    var body: some View {
        VStack {
            if viewModel.showingErrorState {
                ErrorStateView(
                    error: viewModel.currentError ?? AppError.unknown(NSError()),
                    onRetry: { await viewModel.retryAction() },
                    onDismiss: { viewModel.dismissError() }
                )
            } else {
                // Normal content
            }
        }
        .handleErrors() // Global error handling
        .errorToasts() // Toast notifications
    }
}
```

## Integration with App

### 1. App Setup

```swift
@main
struct MimiSupplyApp: App {
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var offlineManager = OfflineManager.shared
    @StateObject private var degradationService = GracefulDegradationService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(errorHandler)
                .environmentObject(offlineManager)
                .environmentObject(degradationService)
                .handleErrors()
                .errorToasts()
        }
    }
}
```

### 2. Service Registration

```swift
final class AppContainer {
    lazy var cloudKitService: CloudKitService = EnhancedCloudKitService()
    // Other services...
}
```

## Testing

### Unit Tests
- **Location**: `MimiSupplyTests/Error/ErrorHandlingTests.swift`
- **Coverage**: All error handling components and scenarios

### UI Tests
- **Location**: `MimiSupplyUITests/ErrorHandlingUITests.swift`
- **Coverage**: Error state views, alerts, toasts, and user interactions

### Integration Tests
- **Coverage**: End-to-end error handling flows and service integration

## Best Practices

### 1. Error Handling Strategy

1. **Catch Early**: Handle errors at the service layer
2. **Convert Consistently**: Always convert to AppError types
3. **Log Everything**: Use ErrorHandler for consistent logging
4. **User-Friendly**: Show appropriate UI based on error type
5. **Provide Recovery**: Always offer retry or alternative actions

### 2. Offline Support

1. **Cache Aggressively**: Cache all user-facing data
2. **Queue Operations**: Queue write operations for offline sync
3. **Graceful Degradation**: Provide limited functionality when offline
4. **Sync Intelligently**: Sync when network becomes available

### 3. User Experience

1. **Non-Intrusive**: Use toasts for minor errors
2. **Clear Messaging**: Provide clear, actionable error messages
3. **Recovery Actions**: Always provide ways to recover from errors
4. **Status Indicators**: Show service status and offline mode

### 4. Performance

1. **Efficient Caching**: Use memory and disk caching appropriately
2. **Background Processing**: Handle sync operations in background
3. **Resource Management**: Clean up resources and cancel operations
4. **Monitoring**: Track error rates and performance metrics

## Monitoring and Analytics

The error handling system integrates with analytics to provide:

- **Error Rates**: Track error frequency by type and context
- **Recovery Success**: Monitor retry success rates
- **Service Health**: Track service degradation patterns
- **User Impact**: Measure error impact on user experience

## Future Enhancements

1. **Machine Learning**: Predictive error handling based on patterns
2. **A/B Testing**: Test different error handling strategies
3. **Real-time Monitoring**: Live service health dashboards
4. **Advanced Caching**: Intelligent cache invalidation and prefetching
5. **Cross-Platform**: Extend error handling to other platforms

## Troubleshooting

### Common Issues

1. **Errors Not Showing**: Check if `handleErrors()` modifier is applied
2. **Toasts Not Appearing**: Ensure `errorToasts()` modifier is applied
3. **Offline Sync Not Working**: Verify network monitoring is active
4. **Service Status Not Updating**: Check service failure reporting

### Debug Tools

1. **Error Logs**: Check console for error handler logs
2. **Service Status**: Monitor degradation service status
3. **Network Status**: Check network monitor connectivity
4. **Sync Queue**: Monitor offline manager pending operations

For more detailed information, see the individual component documentation and test files.