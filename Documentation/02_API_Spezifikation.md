# MimiSupply - API-Spezifikation

## Überblick

MimiSupply nutzt CloudKit als Backend-as-a-Service mit einer hybriden Architektur aus öffentlichen und privaten Datenbanken. Die API-Kommunikation erfolgt über CloudKit's native iOS SDK.

## CloudKit Datenbank-Architektur

### Public Database
Enthält öffentlich zugängliche Daten, die von allen Benutzern gelesen werden können.

### Private Database
Enthält benutzerspezifische und sensible Daten, die nur für den authentifizierten Benutzer zugänglich sind.

## Record Types und Schemas

### 1. Partner (Public Database)

**Record Type**: `Partner`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `name` | String | Name des Partners | ✓ |
| `category` | String | Kategorie (restaurant, grocery, etc.) | ✓ |
| `description` | String | Beschreibung des Geschäfts | ✓ |
| `street` | String | Straßenadresse | ✓ |
| `city` | String | Stadt | ✓ |
| `state` | String | Bundesland/Staat | ✓ |
| `postalCode` | String | Postleitzahl | ✓ |
| `country` | String | Land | ✓ |
| `latitude` | Double | Breitengrad | ✓ |
| `longitude` | Double | Längengrad | ✓ |
| `phoneNumber` | String | Telefonnummer | ✗ |
| `email` | String | E-Mail-Adresse | ✗ |
| `heroImage` | CKAsset | Hero-Bild | ✗ |
| `logo` | CKAsset | Logo | ✗ |
| `isVerified` | Int64 | Verifizierungsstatus | ✓ |
| `isActive` | Int64 | Aktivitätsstatus | ✓ |
| `rating` | Double | Durchschnittsbewertung | ✓ |
| `reviewCount` | Int64 | Anzahl Bewertungen | ✓ |
| `deliveryRadius` | Double | Lieferradius in km | ✓ |
| `minimumOrderAmount` | Int64 | Mindestbestellwert in Cent | ✓ |
| `estimatedDeliveryTime` | Int64 | Geschätzte Lieferzeit in Minuten | ✓ |
| `openingHours` | String | JSON-String der Öffnungszeiten | ✓ |
| `createdAt` | Date/Time | Erstellungsdatum | ✓ |

### 2. Product (Public Database)

**Record Type**: `Product`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `partnerId` | String | Referenz zum Partner | ✓ |
| `name` | String | Produktname | ✓ |
| `description` | String | Produktbeschreibung | ✓ |
| `priceCents` | Int64 | Aktueller Preis in Cent | ✓ |
| `originalPriceCents` | Int64 | Originalpreis in Cent | ✗ |
| `category` | String | Produktkategorie | ✓ |
| `images` | List<CKAsset> | Produktbilder | ✗ |
| `isAvailable` | Int64 | Verfügbarkeitsstatus | ✓ |
| `stockQuantity` | Int64 | Lagerbestand | ✗ |
| `nutritionInfo` | String | JSON-String der Nährwertinformationen | ✗ |
| `allergens` | List<String> | Liste der Allergene | ✗ |
| `tags` | List<String> | Produkt-Tags | ✗ |
| `weight` | Double | Gewicht in Gramm | ✗ |
| `dimensions` | String | JSON-String der Abmessungen | ✗ |
| `createdAt` | Date/Time | Erstellungsdatum | ✓ |
| `updatedAt` | Date/Time | Aktualisierungsdatum | ✓ |

### 3. UserProfile (Private Database)

**Record Type**: `UserProfile`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `appleUserID` | String | Apple User Identifier | ✓ |
| `email` | String | E-Mail-Adresse | ✗ |
| `fullName` | String | Vollständiger Name | ✗ |
| `role` | String | Benutzerrolle (customer, driver, partner, admin) | ✓ |
| `phoneNumber` | String | Telefonnummer | ✗ |
| `profileImage` | CKAsset | Profilbild | ✗ |
| `isVerified` | Int64 | Verifizierungsstatus | ✓ |
| `createdAt` | Date/Time | Erstellungsdatum | ✓ |
| `lastActiveAt` | Date/Time | Letzte Aktivität | ✓ |
| `deviceToken` | String | Push-Notification Token | ✗ |

### 4. Order (Private Database)

**Record Type**: `Order`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `customerId` | String | Kunden-ID | ✓ |
| `partnerId` | String | Partner-ID | ✓ |
| `driverId` | String | Fahrer-ID | ✗ |
| `items` | String | JSON-String der Bestellpositionen | ✓ |
| `status` | String | Bestellstatus | ✓ |
| `subtotalCents` | Int64 | Zwischensumme in Cent | ✓ |
| `deliveryFeeCents` | Int64 | Liefergebühr in Cent | ✓ |
| `platformFeeCents` | Int64 | Plattformgebühr in Cent | ✓ |
| `taxCents` | Int64 | Steuern in Cent | ✓ |
| `tipCents` | Int64 | Trinkgeld in Cent | ✗ |
| `totalCents` | Int64 | Gesamtsumme in Cent | ✓ |
| `deliveryAddress` | String | JSON-String der Lieferadresse | ✓ |
| `deliveryInstructions` | String | Lieferanweisungen | ✗ |
| `estimatedDeliveryTime` | Date/Time | Geschätzte Lieferzeit | ✓ |
| `actualDeliveryTime` | Date/Time | Tatsächliche Lieferzeit | ✗ |
| `paymentMethod` | String | Zahlungsmethode | ✓ |
| `paymentStatus` | String | Zahlungsstatus | ✓ |
| `createdAt` | Date/Time | Erstellungsdatum | ✓ |
| `updatedAt` | Date/Time | Aktualisierungsdatum | ✓ |

### 5. Driver (Private Database)

**Record Type**: `Driver`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `userId` | String | Benutzer-ID | ✓ |
| `name` | String | Name des Fahrers | ✓ |
| `phoneNumber` | String | Telefonnummer | ✓ |
| `profileImage` | CKAsset | Profilbild | ✗ |
| `vehicleType` | String | Fahrzeugtyp | ✓ |
| `licensePlate` | String | Kennzeichen | ✓ |
| `isOnline` | Int64 | Online-Status | ✓ |
| `isAvailable` | Int64 | Verfügbarkeitsstatus | ✓ |
| `currentLatitude` | Double | Aktuelle Breite | ✗ |
| `currentLongitude` | Double | Aktuelle Länge | ✗ |
| `rating` | Double | Fahrer-Bewertung | ✓ |
| `completedDeliveries` | Int64 | Anzahl abgeschlossener Lieferungen | ✓ |
| `verificationStatus` | String | Verifizierungsstatus | ✓ |
| `createdAt` | Date/Time | Erstellungsdatum | ✓ |

### 6. DriverLocation (Private Database)

**Record Type**: `DriverLocation`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `driverId` | String | Fahrer-ID | ✓ |
| `latitude` | Double | Breitengrad | ✓ |
| `longitude` | Double | Längengrad | ✓ |
| `heading` | Double | Fahrtrichtung | ✗ |
| `speed` | Double | Geschwindigkeit | ✗ |
| `accuracy` | Double | GPS-Genauigkeit | ✗ |
| `timestamp` | Date/Time | Zeitstempel | ✓ |

### 7. DeliveryCompletion (Private Database)

**Record Type**: `DeliveryCompletion`

| Feld | Typ | Beschreibung | Erforderlich |
|------|-----|--------------|--------------|
| `orderId` | String | Bestell-ID | ✓ |
| `driverId` | String | Fahrer-ID | ✓ |
| `completedAt` | Date/Time | Abschlusszeitpunkt | ✓ |
| `photoAsset` | CKAsset | Liefernachweis-Foto | ✗ |
| `notes` | String | Notizen zur Lieferung | ✗ |
| `customerRating` | Int64 | Kundenbewertung | ✗ |
| `customerFeedback` | String | Kundenfeedback | ✗ |

## API-Operationen

### Authentifizierung

#### Sign in with Apple
```swift
// Implementierung über AuthenticationService
func signInWithApple() async throws -> UserProfile
```

**Flow:**
1. Apple ID Authentifizierung
2. CloudKit User Discovery
3. UserProfile Erstellung/Aktualisierung
4. Rollenbasierte Navigation

### CRUD-Operationen

#### Partner-Verwaltung

**Alle Partner abrufen**
```swift
func fetchPartners(in region: CLRegion) async throws -> [Partner]
```

**Partner nach Kategorie filtern**
```swift
func fetchPartners(category: PartnerCategory, in region: CLRegion) async throws -> [Partner]
```

#### Produkt-Verwaltung

**Produkte eines Partners abrufen**
```swift
func fetchProducts(for partnerId: String) async throws -> [Product]
```

**Produkt nach ID abrufen**
```swift
func fetchProduct(id: String) async throws -> Product?
```

#### Bestell-Verwaltung

**Neue Bestellung erstellen**
```swift
func createOrder(_ order: Order) async throws -> Order
```

**Bestellstatus aktualisieren**
```swift
func updateOrderStatus(orderId: String, status: OrderStatus) async throws
```

**Bestellungen des Benutzers abrufen**
```swift
func fetchUserOrders() async throws -> [Order]
```

#### Fahrer-Verwaltung

**Fahrer-Position aktualisieren**
```swift
func updateDriverLocation(_ location: DriverLocation) async throws
```

**Verfügbare Fahrer abrufen**
```swift
func fetchAvailableDrivers(in region: CLRegion) async throws -> [Driver]
```

## Real-time Subscriptions

### CloudKit Subscriptions

**Order Updates**
- Subscription ID: `order-updates`
- Trigger: Änderungen an Order Records
- Zielgruppe: Kunden und Fahrer

**Driver Location Updates**
- Subscription ID: `driver-location-updates`
- Trigger: Neue DriverLocation Records
- Zielgruppe: Kunden mit aktiven Bestellungen

**Partner Order Updates**
- Subscription ID: `partner-order-updates`
- Trigger: Neue Orders für Partner
- Zielgruppe: Partner

### Push Notifications

**Notification Payloads:**
```json
{
  "aps": {
    "alert": {
      "title": "Bestellupdate",
      "body": "Ihre Bestellung ist unterwegs!"
    },
    "badge": 1,
    "sound": "default"
  },
  "orderid": "order_123",
  "status": "en_route"
}
```

## Fehlerbehandlung

### CloudKit Error Codes

| Error Code | Beschreibung | Behandlung |
|------------|--------------|------------|
| `CKErrorNetworkUnavailable` | Keine Netzwerkverbindung | Offline-Modus aktivieren |
| `CKErrorNotAuthenticated` | Benutzer nicht angemeldet | Re-Authentifizierung |
| `CKErrorQuotaExceeded` | CloudKit Quota überschritten | Graceful Degradation |
| `CKErrorZoneBusy` | Zone temporär nicht verfügbar | Retry mit Backoff |
| `CKErrorServerRecordChanged` | Konflikt bei gleichzeitiger Änderung | Conflict Resolution |

### Custom Error Types

```swift
enum MimiSupplyError: Error {
    case networkUnavailable
    case authenticationRequired
    case partnerNotFound
    case productUnavailable
    case orderCreationFailed
    case driverNotAvailable
    case paymentFailed
}
```

## Rate Limiting und Performance

### CloudKit Limits
- **Requests per second**: 40 pro Benutzer
- **Database size**: 1 PB pro App
- **Asset size**: 1 GB pro Asset
- **Record size**: 1 MB pro Record

### Performance-Optimierungen
- Batch-Operationen für mehrere Records
- Lokales Caching mit CoreData
- Predictive Prefetching
- Background Sync

## Sicherheit

### Datenvalidierung
- Server-side Validation über CloudKit
- Client-side Validation vor Upload
- Input Sanitization

### Zugriffskontrolle
- Rollenbasierte Berechtigungen
- Private Database für sensible Daten
- Asset-Verschlüsselung

### Audit Logging
- Alle kritischen Operationen werden geloggt
- Benutzeraktionen werden verfolgt
- Compliance-konforme Datenaufbewahrung
