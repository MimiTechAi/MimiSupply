# MimiSupply - Interne Entwicklerdokumentation

## Überblick

Diese Dokumentation enthält alle technischen Informationen für Entwickler, Architekten, QA-Teams und Operations-Teams zur Entwicklung, Wartung und Weiterentwicklung der MimiSupply iOS-App.

MimiSupply ist eine moderne iOS-Lieferservice-Plattform mit drei Hauptbenutzerrollen: **Customer** (Kunde), **Driver** (Fahrer) und **Partner** (Geschäftspartner). Die App nutzt SwiftUI, CloudKit und moderne iOS-Entwicklungsstandards.

## Dokumentations-Struktur

### 📋 [01_Systemarchitektur.md](./01_Systemarchitektur.md)
**Übersicht über iOS-App, Backend (CloudKit), APIs, Datenflüsse**
- App-Schicht und Dependency Injection
- Daten-Schicht mit CloudKit + CoreData
- Business Logic Layer
- Presentation Layer (SwiftUI)
- Service-Abhängigkeiten und Datenfluss
- Performance-Optimierungen
- Skalierbarkeit und Monitoring

### 🔌 [02_API_Spezifikation.md](./02_API_Spezifikation.md)
**CloudKit-basierte API-Dokumentation**
- CloudKit Datenbank-Architektur (Public/Private)
- Record Types und Schemas
- CRUD-Operationen für alle Entitäten
- Real-time Subscriptions
- Push Notifications
- Fehlerbehandlung und Rate Limiting
- Sicherheit und Zugriffskontrolle

### 🗄️ [03_CloudKit_Backend_Schema.md](./03_CloudKit_Backend_Schema.md)
**Detaillierte Backend-Schema Dokumentation**
- Alle Record Types (Partner, Order, Product, UserProfile, Driver)
- Felder, Typen, Constraints und Validierungsregeln
- Synchronisations-Strategien (Offline → Online)
- Conflict Resolution und Datenintegrität
- Performance-Optimierungen und Indexierung
- Migration und Versionierung

### 🎨 [04_Frontend_UI_UX_Dokumentation.md](./04_Frontend_UI_UX_Dokumentation.md)
**SwiftUI-basierte Frontend-Dokumentation**
- Design System (Farben, Typografie, Komponenten)
- Navigations-Flows für alle Benutzerrollen
- Screen-Details und Layouts
- Accessibility (WCAG 2.2 AA+ Compliance)
- Responsive Design für iPhone/iPad
- Internationalisierung (35+ Sprachen)
- Dark Mode Support

### 🚀 [05_Deployment_CI_CD_Dokumentation.md](./05_Deployment_CI_CD_Dokumentation.md)
**GitHub Actions CI/CD Pipeline**
- Pipeline-Architektur und Quality Gates
- Multi-Device Testing Matrix
- Performance und Snapshot Tests
- TestFlight und App Store Deployment
- APR (Automated Pull Request) System
- Secrets Management und Build-Optimierungen
- Monitoring, Alerting und Rollback-Strategien

### 🧪 [06_Test_QA_Dokumentation.md](./06_Test_QA_Dokumentation.md)
**Umfassende Test-Strategie**
- Test-Pyramide (Unit, Integration, UI Tests)
- ATDD-Szenarien (Given/When/Then)
- Performance-Benchmarks und Coverage-Anforderungen
- Accessibility Testing (VoiceOver, Dynamic Type)
- Mock-Daten und Test-Fixtures
- Continuous Testing Strategy
- Qualitätsmetriken und Monitoring

### 🔒 [07_Security_Privacy_Dokumentation.md](./07_Security_Privacy_Dokumentation.md)
**DSGVO-konforme Sicherheit und Datenschutz**
- DSGVO-Compliance und Betroffenenrechte
- Apple Privacy Manifest und Guidelines
- Verschlüsselung (AES-256, CloudKit, Keychain)
- Authentifizierung (Sign in with Apple)
- Netzwerksicherheit (Certificate Pinning)
- Audit Logging und Incident Response
- Security Standards und Compliance

## Schnellstart für Entwickler

### Voraussetzungen
- **Xcode 16.0+** mit iOS 18.0 SDK
- **macOS 15+** (Sequoia)
- **Apple Developer Account** mit CloudKit-Berechtigung
- **Git** und **GitHub CLI** (optional)

### Projekt Setup
```bash
# Repository klonen
git clone https://github.com/mimisupply/MimiSupply.git
cd MimiSupply

# Xcode öffnen
open MimiSupply.xcodeproj

# Dependencies installieren (falls SPM verwendet wird)
# Xcode → File → Add Package Dependencies
```

### Erste Schritte
1. **CloudKit Dashboard** konfigurieren
2. **Provisioning Profiles** einrichten
3. **Environment Variables** setzen (für APR: `ZAI_API_KEY`)
4. **Simulator** oder **Device** für Testing auswählen
5. **Build & Run** (⌘+R)

### Wichtige Konfigurationsdateien
- `MimiSupply.xcodeproj` - Xcode Projekt
- `Info.plist` - App-Konfiguration und Berechtigungen
- `PrivacyInfo.xcprivacy` - Privacy Manifest
- `MimiSupply.entitlements` - App Entitlements
- `.github/workflows/ios.yml` - CI/CD Pipeline
- `apr.config.json` - APR Konfiguration

## Architektur-Übersicht

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   │
│  │   Customer  │ │   Driver    │ │     Partner     │   │
│  │   Features  │ │   Features  │ │    Features     │   │
│  └─────────────┘ └─────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                 Business Logic Layer                    │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   │
│  │    Order    │ │   Driver    │ │    Analytics    │   │
│  │ Management  │ │ Assignment  │ │    Service      │   │
│  └─────────────┘ └─────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   Data Layer                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────┐   │
│  │  CloudKit   │ │  CoreData   │ │     Keychain    │   │
│  │   Service   │ │    Stack    │ │    Service      │   │
│  └─────────────┘ └─────────────┘ └─────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Entwicklungsworkflow

### Feature-Entwicklung
1. **Branch erstellen**: `git checkout -b feature/neue-funktion`
2. **Code schreiben** mit Tests
3. **Lokale Tests** ausführen
4. **Pull Request** erstellen
5. **Code Review** abwarten
6. **CI/CD Pipeline** durchlaufen lassen
7. **Merge** nach Approval

### Testing
```bash
# Alle Tests ausführen
xcodebuild test -scheme MimiSupply -destination 'platform=iOS Simulator,name=iPhone 16'

# Nur Unit Tests
xcodebuild test -scheme MimiSupply -only-testing:MimiSupplyTests

# Performance Tests
xcodebuild test -scheme MimiSupply -only-testing:MimiSupplyTests/Performance
```

### Debugging
- **Xcode Debugger** für lokales Debugging
- **Instruments** für Performance-Analyse
- **Console.app** für Device-Logs
- **CloudKit Dashboard** für Backend-Debugging

## Bekannte Probleme und Lösungen

### Compile-Fehler (Stand: August 2025)
Basierend auf dem APR-Report gibt es aktuell Compile-Fehler in:
- `EnhancedCloudKitService.swift`
- `BusinessHoursManagementView.swift`
- `OrderHistoryView.swift`

**Lösung**: APR-System nutzen mit Label `apr-run` oder manuelle Fixes gemäß Compiler-Fehlermeldungen.

### APR (Automated Pull Request) Setup
```bash
# Environment Variable setzen
export ZAI_API_KEY="your-api-key"

# APR manuell triggern
gh issue create --label "apr-run" --title "Fix compile errors" --body "Automated fix request"
```

## Kontakt und Support

### Entwicklungsteam
- **Lead Developer**: [Name] - [email]
- **iOS Architect**: [Name] - [email]
- **QA Lead**: [Name] - [email]

### Externe Services
- **CloudKit Support**: Apple Developer Support
- **CI/CD**: GitHub Actions
- **APR Service**: ZAI (glm-4.5 Model)

## Weitere Ressourcen

### Apple Dokumentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit/)
- [iOS App Distribution](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

### Best Practices
- [iOS Security Best Practices](https://developer.apple.com/documentation/security/)
- [Accessibility Guidelines](https://developer.apple.com/accessibility/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

**Letzte Aktualisierung**: 27. August 2025  
**Version**: 1.0  
**Dokumentations-Status**: ✅ Vollständig
