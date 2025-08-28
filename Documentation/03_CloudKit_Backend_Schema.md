# MimiSupply - CloudKit/Backend Schema Dokumentation

## Überblick

MimiSupply nutzt CloudKit als Backend-as-a-Service mit einer hybriden Datenbank-Architektur. Die Daten sind zwischen öffentlichen und privaten Datenbanken aufgeteilt, um optimale Performance, Sicherheit und Skalierbarkeit zu gewährleisten.

## Datenbank-Architektur

### Public Database
- **Zweck**: Öffentlich zugängliche Daten, die von allen Benutzern gelesen werden können
- **Inhalte**: Partner-Informationen, Produktkataloge, Kategorien
- **Zugriff**: Lesezugriff für alle, Schreibzugriff nur für verifizierte Partner/Admins

### Private Database
- **Zweck**: Benutzerspezifische und sensible Daten
- **Inhalte**: Benutzerprofile, Bestellungen, Zahlungsinformationen, Fahrer-Daten
- **Zugriff**: Nur für den authentifizierten Benutzer

## Record Types im Detail

### 1. Partner (Public Database)

```swift
// CloudKit Record Type: "Partner"
struct PartnerRecord {
    let recordID: CKRecord.ID
    let recordType = "Partner"
    
    // Grundinformationen
    var name: String                    // Geschäftsname
    var category: String                // PartnerCategory.rawValue
    var description: String             // Geschäftsbeschreibung
    
    // Adressinformationen
    var street: String                  // Straße und Hausnummer
    var city: String                    // Stadt
    var state: String                   // Bundesland/Staat
    var postalCode: String              // Postleitzahl
    var country: String                 // Land (ISO Code)
    var latitude: Double                // GPS Breitengrad
    var longitude: Double               // GPS Längengrad
    
    // Kontaktinformationen
    var phoneNumber: String?            // Telefonnummer
    var email: String?                  // E-Mail-Adresse
    
    // Media Assets
    var heroImage: CKAsset?             // Hero-Bild (max 5MB)
    var logo: CKAsset?                  // Logo (max 2MB)
    
    // Status und Bewertungen
    var isVerified: Bool                // Verifizierungsstatus
    var isActive: Bool                  // Aktivitätsstatus
    var rating: Double                  // Durchschnittsbewertung (0.0-5.0)
    var reviewCount: Int                // Anzahl Bewertungen
    
    // Geschäftsinformationen
    var deliveryRadius: Double          // Lieferradius in Kilometern
    var minimumOrderAmount: Int         // Mindestbestellwert in Cent
    var estimatedDeliveryTime: Int      // Geschätzte Lieferzeit in Minuten
    var openingHours: String            // JSON-String der Öffnungszeiten
    
    // Metadaten
    var createdAt: Date                 // Erstellungsdatum
}
```

**Öffnungszeiten JSON-Schema:**
```json
{
  "monday": {"isOpen": true, "openTime": "09:00", "closeTime": "22:00"},
  "tuesday": {"isOpen": true, "openTime": "09:00", "closeTime": "22:00"},
  "wednesday": {"isOpen": true, "openTime": "09:00", "closeTime": "22:00"},
  "thursday": {"isOpen": true, "openTime": "09:00", "closeTime": "22:00"},
  "friday": {"isOpen": true, "openTime": "09:00", "closeTime": "23:00"},
  "saturday": {"isOpen": true, "openTime": "10:00", "closeTime": "23:00"},
  "sunday": {"isOpen": false}
}
```

### 2. Product (Public Database)

```swift
// CloudKit Record Type: "Product"
struct ProductRecord {
    let recordID: CKRecord.ID
    let recordType = "Product"
    
    // Referenzen
    var partnerId: String               // Referenz zum Partner
    
    // Grundinformationen
    var name: String                    // Produktname
    var description: String             // Produktbeschreibung
    var category: String                // ProductCategory.rawValue
    
    // Preisinformationen
    var priceCents: Int                 // Aktueller Preis in Cent
    var originalPriceCents: Int?        // Originalpreis (für Rabatte)
    
    // Media und Darstellung
    var images: [CKAsset]               // Produktbilder (max 10, je 3MB)
    
    // Verfügbarkeit und Lager
    var isAvailable: Bool               // Verfügbarkeitsstatus
    var stockQuantity: Int?             // Lagerbestand (-1 = unbegrenzt)
    
    // Produktdetails
    var nutritionInfo: String?          // JSON-String der Nährwerte
    var allergens: [String]             // Liste der Allergene
    var tags: [String]                  // Produkt-Tags (vegan, bio, etc.)
    var weight: Double?                 // Gewicht in Gramm
    var dimensions: String?             // JSON-String der Abmessungen
    
    // Metadaten
    var createdAt: Date                 // Erstellungsdatum
    var updatedAt: Date                 // Aktualisierungsdatum
}
```

**Nährwerte JSON-Schema:**
```json
{
  "calories": 250,
  "protein": 12.5,
  "carbohydrates": 30.0,
  "fat": 8.0,
  "fiber": 5.0,
  "sugar": 15.0,
  "sodium": 500,
  "servingSize": "100g"
}
```

### 3. UserProfile (Private Database)

```swift
// CloudKit Record Type: "UserProfile"
struct UserProfileRecord {
    let recordID: CKRecord.ID
    let recordType = "UserProfile"
    
    // Apple ID Integration
    var appleUserID: String             // Apple User Identifier
    
    // Persönliche Informationen
    var email: String?                  // E-Mail-Adresse
    var fullName: String?               // Vollständiger Name
    var phoneNumber: String?            // Telefonnummer
    var profileImage: CKAsset?          // Profilbild
    
    // Rollen und Berechtigungen
    var role: String                    // UserRole.rawValue
    var isVerified: Bool                // Verifizierungsstatus
    
    // Aktivitätsdaten
    var createdAt: Date                 // Registrierungsdatum
    var lastActiveAt: Date              // Letzte Aktivität
    
    // Push Notifications
    var deviceToken: String?            // APNs Device Token
}
```

### 4. Order (Private Database)

```swift
// CloudKit Record Type: "Order"
struct OrderRecord {
    let recordID: CKRecord.ID
    let recordType = "Order"
    
    // Referenzen
    var customerId: String              // Kunden-ID
    var partnerId: String               // Partner-ID
    var driverId: String?               // Fahrer-ID (optional)
    
    // Bestellinhalt
    var items: String                   // JSON-String der OrderItems
    var status: String                  // OrderStatus.rawValue
    
    // Preisinformationen (alle in Cent)
    var subtotalCents: Int              // Zwischensumme
    var deliveryFeeCents: Int           // Liefergebühr
    var platformFeeCents: Int           // Plattformgebühr
    var taxCents: Int                   // Steuern
    var tipCents: Int                   // Trinkgeld
    var totalCents: Int                 // Gesamtsumme
    
    // Lieferinformationen
    var deliveryAddress: String         // JSON-String der Adresse
    var deliveryInstructions: String?   // Lieferanweisungen
    var estimatedDeliveryTime: Date     // Geschätzte Lieferzeit
    var actualDeliveryTime: Date?       // Tatsächliche Lieferzeit
    
    // Zahlungsinformationen
    var paymentMethod: String           // PaymentMethod.rawValue
    var paymentStatus: String           // PaymentStatus.rawValue
    
    // Metadaten
    var createdAt: Date                 // Bestelldatum
    var updatedAt: Date                 // Letzte Aktualisierung
}
```

**OrderItems JSON-Schema:**
```json
[
  {
    "id": "item_123",
    "productId": "product_456",
    "productName": "Pizza Margherita",
    "quantity": 2,
    "unitPriceCents": 1200,
    "totalPriceCents": 2400,
    "customizations": [
      {
        "id": "custom_1",
        "name": "Extra Käse",
        "value": "Ja",
        "priceCents": 150
      }
    ],
    "specialInstructions": "Gut durchgebacken"
  }
]
```

### 5. Driver (Private Database)

```swift
// CloudKit Record Type: "Driver"
struct DriverRecord {
    let recordID: CKRecord.ID
    let recordType = "Driver"
    
    // Referenzen
    var userId: String                  // Referenz zum UserProfile
    
    // Persönliche Informationen
    var name: String                    // Name des Fahrers
    var phoneNumber: String             // Telefonnummer
    var profileImage: CKAsset?          // Profilbild
    
    // Fahrzeuginformationen
    var vehicleType: String             // VehicleType.rawValue
    var licensePlate: String            // Kennzeichen
    
    // Status und Verfügbarkeit
    var isOnline: Bool                  // Online-Status
    var isAvailable: Bool               // Verfügbar für neue Aufträge
    var currentLatitude: Double?        // Aktuelle Position (Breite)
    var currentLongitude: Double?       // Aktuelle Position (Länge)
    
    // Bewertungen und Statistiken
    var rating: Double                  // Fahrer-Bewertung (0.0-5.0)
    var completedDeliveries: Int        // Anzahl abgeschlossener Lieferungen
    var verificationStatus: String      // Verifizierungsstatus
    
    // Metadaten
    var createdAt: Date                 // Registrierungsdatum
}
```

### 6. DriverLocation (Private Database)

```swift
// CloudKit Record Type: "DriverLocation"
struct DriverLocationRecord {
    let recordID: CKRecord.ID
    let recordType = "DriverLocation"
    
    // Referenzen
    var driverId: String                // Fahrer-ID
    
    // GPS-Daten
    var latitude: Double                // Breitengrad
    var longitude: Double               // Längengrad
    var heading: Double?                // Fahrtrichtung (0-360°)
    var speed: Double?                  // Geschwindigkeit (m/s)
    var accuracy: Double?               // GPS-Genauigkeit (Meter)
    
    // Zeitstempel
    var timestamp: Date                 // Zeitpunkt der Positionsmeldung
}
```

### 7. DeliveryCompletion (Private Database)

```swift
// CloudKit Record Type: "DeliveryCompletion"
struct DeliveryCompletionRecord {
    let recordID: CKRecord.ID
    let recordType = "DeliveryCompletion"
    
    // Referenzen
    var orderId: String                 // Bestell-ID
    var driverId: String                // Fahrer-ID
    
    // Abschlussdaten
    var completedAt: Date               // Abschlusszeitpunkt
    var photoAsset: CKAsset?            // Liefernachweis-Foto
    var notes: String?                  // Notizen zur Lieferung
    
    // Bewertungen
    var customerRating: Int?            // Kundenbewertung (1-5)
    var customerFeedback: String?       // Kundenfeedback
}
```

## Synchronisations-Strategien

### Offline → Online Synchronisation

#### 1. Conflict Resolution
```swift
enum ConflictResolutionStrategy {
    case lastWriteWins          // Für einfache Felder
    case merge                  // Für komplexe Objekte
    case userIntervention       // Für kritische Konflikte
}
```

#### 2. Sync-Prioritäten
1. **Hoch**: Bestellungen, Zahlungen, Fahrer-Positionen
2. **Mittel**: Benutzerprofile, Produktverfügbarkeit
3. **Niedrig**: Analytics, Bewertungen, Bilder

#### 3. Batch-Operationen
- Mehrere Records in einer Operation
- Transaktionale Konsistenz
- Optimierte Netzwerknutzung

### Real-time Subscriptions

#### CloudKit Subscriptions
```swift
// Order Updates Subscription
let orderPredicate = NSPredicate(format: "customerId == %@", currentUserId)
let orderSubscription = CKQuerySubscription(
    recordType: "Order",
    predicate: orderPredicate,
    subscriptionID: "order-updates"
)

// Driver Location Updates
let locationPredicate = NSPredicate(format: "driverId == %@", assignedDriverId)
let locationSubscription = CKQuerySubscription(
    recordType: "DriverLocation",
    predicate: locationPredicate,
    subscriptionID: "driver-location-updates"
)
```

## Datenvalidierung und Constraints

### Validierungsregeln

#### Partner
- `name`: 3-100 Zeichen
- `category`: Muss gültiger PartnerCategory-Wert sein
- `rating`: 0.0-5.0
- `deliveryRadius`: 0.1-50.0 km
- `minimumOrderAmount`: 0-10000 Cent

#### Product
- `name`: 3-200 Zeichen
- `priceCents`: > 0
- `images`: Max 10 Bilder, je max 3MB
- `stockQuantity`: >= -1 (-1 = unbegrenzt)

#### Order
- `totalCents`: Muss Summe aller Komponenten sein
- `status`: Muss gültiger OrderStatus-Wert sein
- `estimatedDeliveryTime`: Muss in der Zukunft liegen

### Datenintegrität

#### Referentielle Integrität
- Orphaned Records werden automatisch bereinigt
- Cascade Delete für abhängige Records
- Foreign Key Validierung

#### Konsistenz-Checks
- Bestellsummen-Validierung
- Status-Transition-Validierung
- Verfügbarkeits-Checks

## Performance-Optimierungen

### Indexierung
```swift
// Wichtige Indizes für Queries
let partnerCategoryIndex = CKRecord.ID(recordName: "partner_category_idx")
let productPartnerIndex = CKRecord.ID(recordName: "product_partner_idx")
let orderCustomerIndex = CKRecord.ID(recordName: "order_customer_idx")
let driverLocationIndex = CKRecord.ID(recordName: "driver_location_idx")
```

### Caching-Strategien
- **L1 Cache**: In-Memory Cache für aktuelle Session
- **L2 Cache**: CoreData für persistente lokale Daten
- **L3 Cache**: CloudKit für Cloud-Synchronisation

### Query-Optimierung
- Verwendung von Predicates für gefilterte Abfragen
- Batch-Loading für große Datenmengen
- Pagination für Listen-Views

## Backup und Disaster Recovery

### Automatische Backups
- CloudKit erstellt automatische Backups
- Point-in-Time Recovery möglich
- Cross-Region Replikation

### Datenexport
- Programmatischer Export über CloudKit API
- JSON-Format für Portabilität
- Compliance mit DSGVO-Anforderungen

## Migration und Versionierung

### Schema-Änderungen
- Additive Änderungen sind sicher
- Breaking Changes erfordern App-Update
- Backward Compatibility für 2 Versionen

### Migrations-Strategien
```swift
enum SchemaVersion: Int, CaseIterable {
    case v1_0 = 1
    case v1_1 = 2
    case v1_2 = 3
    
    var migrationSteps: [MigrationStep] {
        // Definiert notwendige Migrations-Schritte
    }
}
```

## Monitoring und Analytics

### CloudKit Metriken
- Request Count und Response Times
- Error Rates nach Typ
- Database Size und Growth
- Subscription Performance

### Custom Metriken
- Sync Success Rate
- Conflict Resolution Rate
- Offline Usage Patterns
- Data Freshness Metrics
