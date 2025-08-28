# MimiSupply - Frontend-UI/UX-Dokumentation

## Überblick

MimiSupply nutzt SwiftUI als primäres UI-Framework und folgt modernen iOS-Design-Prinzipien. Die App unterstützt drei Hauptbenutzerrollen mit jeweils angepassten Benutzeroberflächen und Workflows.

## Design System

### Farbpalette
```swift
// Primäre Farben
struct MimiColors {
    static let primary = Color("PrimaryColor")          // Hauptfarbe der App
    static let secondary = Color("SecondaryColor")      // Sekundärfarbe
    static let accent = Color("AccentColor")            // Akzentfarbe
    
    // Semantische Farben
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // Neutrale Farben
    static let background = Color("BackgroundColor")
    static let surface = Color("SurfaceColor")
    static let onSurface = Color("OnSurfaceColor")
}
```

### Typografie
```swift
struct MimiTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.medium)
    static let headline = Font.headline.weight(.semibold)
    static let body = Font.body
    static let caption = Font.caption
    static let footnote = Font.footnote
}
```

### Komponenten-Bibliothek

#### Buttons
- **PrimaryButton**: Hauptaktionen (Bestellen, Anmelden)
- **SecondaryButton**: Sekundäre Aktionen (Abbrechen, Zurück)
- **IconButton**: Icon-basierte Aktionen
- **FloatingActionButton**: Schwebende Aktionen

#### Cards
- **PartnerCard**: Partner-Darstellung in Listen
- **ProductCard**: Produkt-Darstellung
- **OrderCard**: Bestellübersicht
- **StatCard**: Statistik-Anzeige

#### Navigation
- **TabBar**: Hauptnavigation
- **NavigationBar**: Seitennavigation
- **Breadcrumbs**: Pfad-Navigation

## Navigations-Flow

### 1. Onboarding-Flow
```
App Start → Splash Screen → Authentication → Role Selection → Tutorial → Main App
```

**Screens:**
- **SplashScreen**: App-Logo und Ladeanimation
- **WelcomeScreen**: Willkommensnachricht und Features
- **AuthenticationScreen**: Sign in with Apple
- **RoleSelectionScreen**: Auswahl der Benutzerrolle
- **TutorialScreen**: Rollenspezifische Einführung

### 2. Customer-Flow
```
Explore → Partner Detail → Product Detail → Cart → Checkout → Order Tracking → Order History
```

**Hauptscreens:**
- **ExploreScreen**: Partner-Suche und -Entdeckung
- **PartnerDetailScreen**: Partner-Informationen und Produktkatalog
- **ProductDetailScreen**: Detaillierte Produktansicht
- **CartScreen**: Warenkorb-Verwaltung
- **CheckoutScreen**: Bestellabschluss und Zahlung
- **OrderTrackingScreen**: Live-Verfolgung der Bestellung
- **OrderHistoryScreen**: Vergangene Bestellungen

### 3. Driver-Flow
```
Dashboard → Available Jobs → Job Detail → Navigation → Delivery Completion → Earnings
```

**Hauptscreens:**
- **DriverDashboardScreen**: Übersicht und Status-Toggle
- **AvailableJobsScreen**: Verfügbare Lieferaufträge
- **JobDetailScreen**: Auftragsdetails und Annahme
- **NavigationScreen**: GPS-Navigation zum Ziel
- **DeliveryCompletionScreen**: Lieferbestätigung
- **EarningsScreen**: Verdienst-Übersicht

### 4. Partner-Flow
```
Dashboard → Order Management → Product Management → Analytics → Settings
```

**Hauptscreens:**
- **PartnerDashboardScreen**: Geschäftsübersicht
- **OrderManagementScreen**: Eingehende Bestellungen
- **ProductManagementScreen**: Produktkatalog-Verwaltung
- **AnalyticsScreen**: Geschäftsstatistiken
- **BusinessSettingsScreen**: Geschäftseinstellungen

## Screen-Details

### ExploreScreen (Customer)

**Layout:**
```
┌─────────────────────────────────┐
│ Search Bar                      │
├─────────────────────────────────┤
│ Category Filter (Horizontal)    │
├─────────────────────────────────┤
│ Featured Partners              │
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │Card │ │Card │ │Card │        │
│ └─────┘ └─────┘ └─────┘        │
├─────────────────────────────────┤
│ Nearby Partners                │
│ ┌─────────────────────────────┐ │
│ │ Partner List Item           │ │
│ │ ┌───┐ Name     ★4.8        │ │
│ │ │IMG│ Category  25-30min    │ │
│ │ └───┘ Distance  $2.99 fee  │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

**Features:**
- Echtzeit-Suche mit Debouncing
- Kategorie-Filter mit horizontalem Scrolling
- Standortbasierte Partner-Sortierung
- Lazy Loading für Performance

### PartnerDetailScreen (Customer)

**Layout:**
```
┌─────────────────────────────────┐
│ Hero Image                      │
│ ┌─────────────────────────────┐ │
│ │ Partner Name        ★4.8    │ │
│ │ Category • 25-30min         │ │
│ │ Min Order: $15 • $2.99 fee  │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Product Categories (Tabs)       │
├─────────────────────────────────┤
│ Product Grid                    │
│ ┌─────┐ ┌─────┐                │
│ │Prod │ │Prod │                │
│ │$12  │ │$8   │                │
│ └─────┘ └─────┘                │
└─────────────────────────────────┘
```

**Features:**
- Parallax-Scrolling für Hero Image
- Sticky Category Tabs
- Pull-to-Refresh für Produktaktualisierung
- Favoriten-Funktionalität

### DriverDashboardScreen (Driver)

**Layout:**
```
┌─────────────────────────────────┐
│ Status Toggle: [ONLINE/OFFLINE] │
├─────────────────────────────────┤
│ Today's Stats                   │
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ $85 │ │  7  │ │4.9★ │        │
│ │Earn │ │Jobs │ │Rate │        │
│ └─────┘ └─────┘ └─────┘        │
├─────────────────────────────────┤
│ Current Job (if active)         │
│ ┌─────────────────────────────┐ │
│ │ Order #1234                 │ │
│ │ Pickup: Restaurant Name     │ │
│ │ Deliver: 123 Main St        │ │
│ │ [Navigate] [Contact]        │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Available Jobs                  │
│ [View All Jobs]                 │
└─────────────────────────────────┘
```

**Features:**
- Einfacher Online/Offline Toggle
- Echtzeit-Statistiken
- Aktuelle Job-Anzeige mit Quick Actions
- Push-Benachrichtigungen für neue Jobs

### PartnerDashboardScreen (Partner)

**Layout:**
```
┌─────────────────────────────────┐
│ Business Status: [OPEN/CLOSED]  │
├─────────────────────────────────┤
│ Today's Overview                │
│ ┌─────┐ ┌─────┐ ┌─────┐        │
│ │ $450│ │ 23  │ │ 89% │        │
│ │Sales│ │Order│ │Rate │        │
│ └─────┘ └─────┘ └─────┘        │
├─────────────────────────────────┤
│ Pending Orders (3)              │
│ ┌─────────────────────────────┐ │
│ │ Order #1234    $25.50       │ │
│ │ 2x Pizza, 1x Salad          │ │
│ │ [Accept] [Decline]          │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ Quick Actions                   │
│ [Manage Products] [View Analytics] │
└─────────────────────────────────┘
```

**Features:**
- Business Status Toggle
- Echtzeit-Bestellbenachrichtigungen
- Quick Accept/Decline für Bestellungen
- Schnellzugriff auf wichtige Funktionen

## Accessibility (WCAG 2.2)

### Unterstützte Features

#### Visuell
- **Dynamic Type**: Unterstützung für alle iOS-Schriftgrößen
- **High Contrast**: Erhöhter Kontrast für bessere Lesbarkeit
- **Reduce Motion**: Reduzierte Animationen
- **Color Blind Support**: Farbunabhängige Informationsdarstellung

#### Motor
- **Voice Control**: Vollständige Sprachsteuerung
- **Switch Control**: Externe Schalter-Unterstützung
- **Touch Accommodations**: Angepasste Touch-Gesten

#### Auditiv
- **VoiceOver**: Vollständige Screenreader-Unterstützung
- **Audio Descriptions**: Beschreibungen für visuelle Inhalte
- **Haptic Feedback**: Taktiles Feedback für Aktionen

### Implementierung
```swift
// Accessibility Labels
Text("Pizza Margherita")
    .accessibilityLabel("Pizza Margherita, 12 Dollar 50")
    .accessibilityHint("Doppeltippen zum Hinzufügen zum Warenkorb")

// Accessibility Actions
Button("Add to Cart") { }
    .accessibilityAction(.default) { addToCart() }
    .accessibilityAction(.escape) { dismissModal() }

// Semantic Markup
VStack {
    Text("Restaurant Name")
        .accessibilityAddTraits(.isHeader)
    Text("Description")
        .accessibilityRemoveTraits(.isButton)
}
```

## Responsive Design

### Geräteanpassungen

#### iPhone (Compact Width)
- Einzelspaltige Layouts
- Bottom Sheet für Modals
- Tab Bar Navigation

#### iPad (Regular Width)
- Mehrspaltige Layouts
- Sidebar Navigation
- Popover für Modals

#### Landscape Orientierung
- Angepasste Layouts für Querformat
- Optimierte Navigation
- Bessere Raumnutzung

### Adaptive Layouts
```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var body: some View {
    if horizontalSizeClass == .compact {
        CompactLayout()
    } else {
        RegularLayout()
    }
}
```

## Animationen und Transitions

### Micro-Interactions
- **Button Press**: Leichte Scale-Animation
- **Card Tap**: Gentle Bounce-Effekt
- **Loading States**: Skeleton Loading
- **Pull-to-Refresh**: Custom Refresh Indicator

### Page Transitions
- **Push/Pop**: Standard iOS Navigation
- **Modal Presentation**: Slide Up/Down
- **Tab Switching**: Cross Fade
- **Deep Link**: Custom Transition basierend auf Kontext

### Performance-Optimierungen
```swift
// Lazy Loading für große Listen
LazyVStack {
    ForEach(items) { item in
        ItemView(item: item)
    }
}

// Async Image Loading
AsyncImage(url: imageURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

## Internationalisierung (i18n)

### Unterstützte Sprachen
- **Primär**: Deutsch, Englisch
- **Sekundär**: Spanisch, Französisch, Italienisch, Portugiesisch
- **Erweitert**: 35+ Sprachen (siehe Info.plist)

### Lokalisierung
```swift
// String Lokalisierung
Text("welcome_message")
    .localizedStringKey("welcome_message")

// Formatierung
Text("price_format \(price)")
    .environment(\.locale, Locale.current)

// RTL Support
HStack {
    Text("Label")
    Spacer()
    Text("Value")
}
.environment(\.layoutDirection, .rightToLeft)
```

## Dark Mode Support

### Adaptive Farben
```swift
// Automatische Anpassung an System Theme
Color("BackgroundColor") // Definiert in Assets.xcassets
    .colorScheme(.light)  // Light Mode Variante
    .colorScheme(.dark)   // Dark Mode Variante
```

### Theme-spezifische Assets
- Separate Bilder für Light/Dark Mode
- Angepasste Icons und Illustrationen
- Optimierte Kontraste

## Performance-Monitoring

### UI Performance Metriken
- **Frame Rate**: 60 FPS Ziel
- **Launch Time**: < 2 Sekunden
- **Memory Usage**: < 100MB für UI
- **Battery Impact**: Minimal

### Monitoring Tools
- Xcode Instruments
- Custom Performance Logger
- Real-time FPS Counter (Debug)
- Memory Leak Detection

## Testing Strategy

### UI Testing
- **Snapshot Tests**: Visuelle Regression Tests
- **Accessibility Tests**: VoiceOver und Dynamic Type
- **Interaction Tests**: User Journey Tests
- **Performance Tests**: Scroll Performance, Animation Smoothness

### A/B Testing
- Feature Flag basierte UI Varianten
- Conversion Rate Optimierung
- User Experience Experimente
