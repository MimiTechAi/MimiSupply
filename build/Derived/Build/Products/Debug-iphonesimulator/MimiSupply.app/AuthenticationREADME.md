# Authentication System

This directory contains the comprehensive authentication system for MimiSupply, implementing secure Sign in with Apple integration with role-based access control.

## Overview

The authentication system provides:

- **Sign in with Apple Integration**: Secure authentication using Apple ID
- **Role-Based Access Control**: Support for Customer, Driver, Partner, and Admin roles
- **Automatic State Management**: Handles authentication state changes and credential refresh
- **Secure Storage**: Uses Keychain for secure credential storage
- **Comprehensive Error Handling**: User-friendly error messages and recovery options
- **Accessibility Support**: Full VoiceOver and assistive technology support

## Architecture

### Core Components

1. **AuthenticationService**: Protocol and implementation for authentication operations
2. **KeychainService**: Secure storage for user credentials and data
3. **AuthenticationManager**: SwiftUI-friendly manager for authentication state
4. **AuthenticationGate**: View component that handles authentication flow
5. **RoleSelectionView**: UI for new users to select their role

### Authentication Flow

```
App Launch → Check Stored Credentials → Validate with Apple → 
  ↓
Authenticated → Role-Based Navigation
  ↓
Unauthenticated → Show Sign In → Apple Authentication → 
  ↓
New User → Role Selection → Store Profile → Authenticated
  ↓
Existing User → Load Profile → Authenticated
```

## Usage

### Basic Integration

```swift
// Wrap your app content with AuthenticationGate
struct MyApp: View {
    var body: some View {
        AuthenticationGate {
            MainAppContent()
        }
    }
}
```

### Role-Based Content

```swift
struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack {
            // Content for all authenticated users
            Text("Welcome!")
            
            // Customer-only content
            if case .authenticated(let user) = authManager.authenticationState,
               user.role == .customer {
                CustomerDashboard()
            }
            
            // Using permission-based modifier
            DriverContent()
                .requiresPermission(for: .acceptDeliveryJobs)
        }
    }
}
```

### Manual Authentication Control

```swift
struct SignInView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        Button("Sign In") {
            Task {
                await authManager.signInWithApple()
            }
        }
        
        Button("Sign Out") {
            Task {
                await authManager.signOut()
            }
        }
    }
}
```

## Security Features

### Keychain Storage

- Uses `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for maximum security
- Encrypts all stored data using iOS Keychain Services
- Isolates data per user and service

### Role-Based Access Control

```swift
enum AuthenticationAction {
    case viewCustomerContent    // Available to all
    case placeOrder            // Customer only
    case acceptDeliveryJobs    // Driver only
    case manageBusinessProfile // Partner only
    case adminAccess          // Admin only
}

// Check permissions
let canAccess = await authManager.hasPermission(for: .placeOrder)
```

### Automatic Credential Refresh

- Validates Apple ID credentials every hour
- Handles credential revocation gracefully
- Automatic sign-out on credential expiration

## Error Handling

The system provides comprehensive error handling with user-friendly messages:

```swift
enum AuthenticationError {
    case signInFailed
    case tokenExpired
    case userCancelled
    case networkUnavailable
    case roleSelectionRequired
    // ... and more
}
```

Each error includes:
- Localized description
- Recovery suggestion
- Appropriate user actions

## Testing

### Unit Tests

- `AuthenticationServiceTests`: Core authentication logic
- `KeychainServiceTests`: Secure storage functionality
- `AuthenticationManagerTests`: State management

### Integration Tests

- `AuthenticationIntegrationTests`: End-to-end authentication flows
- `AuthenticationUITests`: User interface testing
- `AuthenticationSecurityTests`: Security and privacy validation

### Running Tests

```bash
# Run all authentication tests
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MimiSupplyTests/Authentication

# Run specific test class
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:MimiSupplyTests/AuthenticationServiceTests
```

## Accessibility

The authentication system is fully accessible:

- **VoiceOver**: All elements have descriptive labels and hints
- **Dynamic Type**: Supports all text sizes including accessibility sizes
- **High Contrast**: WCAG 2.2 AA+ compliant color schemes
- **Switch Control**: Logical navigation paths
- **Reduce Motion**: Alternative animations when motion is reduced

### Accessibility Testing

```swift
// Test VoiceOver support
func testVoiceOverSupport() {
    let view = AuthenticationView()
    let elements = findAllAccessibilityElements(in: view)
    
    for element in elements {
        XCTAssertFalse(element.accessibilityLabel?.isEmpty ?? true)
    }
}
```

## Performance

### Optimization Features

- Lazy loading of authentication state
- Efficient credential caching
- Background credential refresh
- Minimal memory footprint

### Performance Metrics

- Cold start authentication: < 500ms
- Credential refresh: < 200ms
- Role switching: < 100ms

## Privacy

### Data Minimization

- Only stores essential user data
- No tracking without explicit consent
- Secure deletion of user data

### Privacy Compliance

- GDPR compliant data handling
- CCPA compliant data deletion
- Apple's privacy guidelines adherence

## Configuration

### Required Entitlements

```xml
<!-- MimiSupply.entitlements -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>

<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.mimisupply.app</string>
</array>
```

### Info.plist Configuration

```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to securely access your account</string>

<key>NSAppleSignInUsageDescription</key>
<string>Sign in with your Apple ID to access MimiSupply</string>
```

## Troubleshooting

### Common Issues

1. **Sign in fails**: Check Apple ID configuration and network connectivity
2. **Keychain errors**: Verify app entitlements and provisioning profile
3. **Role selection not showing**: Check authentication result flags
4. **State not updating**: Ensure proper SwiftUI environment object setup

### Debug Logging

```swift
// Enable debug logging (development only)
#if DEBUG
AuthenticationService.enableDebugLogging = true
#endif
```

## Migration Guide

### From Previous Authentication

If migrating from a previous authentication system:

1. Export existing user data
2. Map user roles to new system
3. Migrate to Keychain storage
4. Update UI to use new components
5. Test authentication flows thoroughly

## Contributing

When contributing to the authentication system:

1. Follow security best practices
2. Add comprehensive tests
3. Update documentation
4. Verify accessibility compliance
5. Test on multiple devices and iOS versions

## Security Considerations

- Never log sensitive authentication data
- Use secure coding practices
- Regularly audit dependencies
- Follow OWASP mobile security guidelines
- Implement proper session management

## Support

For authentication-related issues:

1. Check the troubleshooting section
2. Review test cases for examples
3. Consult Apple's Sign in with Apple documentation
4. Contact the development team for complex issues