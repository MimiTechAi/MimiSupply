# MimiSupply Localization Integration Guide

## Overview

This guide explains how to integrate the comprehensive localization system into MimiSupply app components.

## Key Components

### 1. LocalizationManager
- Manages current language and locale
- Provides formatting utilities
- Handles language switching without app restart

### 2. String Localization
- Use `String.localized` extension for simple localization
- Use `LocalizationKeys` enum for type-safe keys
- Support for parameterized strings

### 3. RTL Support
- Automatic layout direction handling
- RTL-aware components and modifiers
- Icon and navigation adaptations

### 4. Cultural Adaptations
- Locale-specific colors, icons, and spacing
- Cultural greetings and politeness levels
- Regional formatting preferences

## Integration Examples

### Basic String Localization

```swift
// Before
Text("Add to Cart")

// After
Text(LocalizationKeys.Cart.addToCart.localized)
// or
Text("cart.add_to_cart".localized)
```

### Parameterized Strings

```swift
// Before
Text("Found \(count) restaurants")

// After
Text("explore.found_restaurants".localized(with: count))
```

### Currency Formatting

```swift
// Before
Text("$\(String(format: "%.2f", price))")

// After
Text(LocaleFormatter.shared.formatCurrency(priceInCents))
```

### Date Formatting

```swift
// Before
Text(DateFormatter().string(from: date))

// After
Text(LocaleFormatter.shared.formatDate(date, style: .medium))
```

### RTL-Aware Layouts

```swift
// Before
HStack {
    Image(systemName: "chevron.right")
    Text("Next")
}

// After
RTLAwareHStack {
    LocalizedSystemImage(systemName: "chevron.right", rtlVariant: "chevron.left")
    Text(LocalizationKeys.Common.next.localized)
}
```

### RTL-Aware Padding

```swift
// Before
.padding(.leading, 16)

// After
.rtlPadding(leading: 16)
// or
.localizedLeadingPadding(16)
```

### Cultural Adaptations

```swift
// Before
.foregroundColor(.green)

// After
.foregroundColor(CulturalAdaptations.adaptedColor(for: .success))
```

### Localized Images

```swift
// Before
Image("welcome_banner")

// After
LocalizedImage("welcome_banner") // Automatically loads welcome_banner_es.png for Spanish
```

## View Integration Pattern

```swift
struct MyView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack {
            Text(LocalizationKeys.Common.welcome.localized)
                .rtlTextAlignment()
            
            PrimaryButton(
                title: LocalizationKeys.Common.continue.localized,
                action: { /* action */ }
            )
            .rtlPadding(leading: 16, trailing: 16)
        }
        .rtlAware()
        .observeLanguageChanges()
    }
}
```

## ViewModel Integration

```swift
class MyViewModel: ObservableObject {
    private let localizationManager = LocalizationManager.shared
    private let formatter = LocaleFormatter.shared
    
    var formattedPrice: String {
        formatter.formatCurrency(priceInCents)
    }
    
    var localizedTitle: String {
        "my_view.title".localized
    }
    
    init() {
        // Observe language changes
        NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
```

## Testing Integration

```swift
func testLocalizedContent() {
    // Given
    let spanish = SupportedLanguage(code: "es", nativeName: "Español", englishName: "Spanish")
    LocalizationManager.shared.changeLanguage(to: spanish)
    
    // When
    let localizedText = "common.ok".localized
    
    // Then
    XCTAssertEqual(localizedText, "Aceptar")
}
```

## Best Practices

### 1. Always Use Localization Keys
```swift
// ❌ Don't
Text("Settings")

// ✅ Do
Text(LocalizationKeys.Common.settings.localized)
```

### 2. Handle RTL Layouts
```swift
// ❌ Don't
HStack {
    Text("Name")
    Spacer()
    Text(name)
}

// ✅ Do
RTLAwareHStack {
    Text("profile.name".localized)
    Spacer()
    Text(name)
}
.rtlAware()
```

### 3. Use Cultural Adaptations
```swift
// ❌ Don't
Image(systemName: "fork.knife")

// ✅ Do
Image(systemName: CulturalAdaptations.adaptedIcon(for: .restaurant))
```

### 4. Format Numbers and Dates Properly
```swift
// ❌ Don't
Text("$\(price)")

// ✅ Do
Text(LocaleFormatter.shared.formatCurrency(priceInCents))
```

### 5. Test All Supported Languages
```swift
func testAllSupportedLanguages() {
    for language in SupportedLanguage.allLanguages {
        LocalizationManager.shared.changeLanguage(to: language)
        // Test your UI components
    }
}
```

## Migration Checklist

- [ ] Replace hardcoded strings with localization keys
- [ ] Add RTL support to custom layouts
- [ ] Update currency and date formatting
- [ ] Add cultural adaptations where appropriate
- [ ] Test with different languages and RTL layouts
- [ ] Update accessibility labels and hints
- [ ] Add localization tests
- [ ] Update UI tests for different languages

## Performance Considerations

1. **String Caching**: Localized strings are cached automatically
2. **Formatter Reuse**: LocaleFormatter instances are reused
3. **Language Switching**: No app restart required
4. **Memory Usage**: Minimal overhead for localization infrastructure

## Troubleshooting

### Common Issues

1. **Missing Translations**: Falls back to key or English
2. **RTL Layout Issues**: Use RTL-aware components
3. **Date Format Problems**: Use LocaleFormatter instead of system formatters
4. **Performance Issues**: Avoid creating formatters in view body

### Debug Tips

1. Enable localization debugging in scheme
2. Test with pseudo-localization
3. Use Xcode's localization preview
4. Test on device with different system languages