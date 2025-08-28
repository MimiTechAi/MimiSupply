# 🍎 MimiSupply Demo & Test Plan - Apple Standards

## 📱 Demo-Accounts für alle Rollen

### Customer Accounts
```
Email: kunde@test.de
Password: kunde123
Name: Max Mustermann (Berlin)

Email: anna.schmidt@test.de  
Password: anna123
Name: Anna Schmidt (München)
```

### Partner Accounts
```
Email: mcdonalds@partner.de
Password: partner123
Business: McDonald's Berlin Mitte

Email: rewe@partner.de
Password: partner123  
Business: REWE Supermarket

Email: docmorris@partner.de
Password: partner123
Business: DocMorris Apotheke

Email: mediamarkt@partner.de
Password: partner123
Business: MediaMarkt Berlin
```

### Driver Accounts
```
Email: fahrer1@test.de
Password: fahrer123
Name: Thomas Weber (Fahrrad, 4.8⭐, 247 Lieferungen)

Email: fahrer2@test.de
Password: fahrer123
Name: Sarah Klein (Motorroller, 4.9⭐, 189 Lieferungen)

Email: fahrer3@test.de
Password: fahrer123
Name: Michael Fischer (Auto, 4.7⭐, 312 Lieferungen)
```

## 🎯 Apple-Standards Checkliste

### 1. Navigation & Scrolling
- [ ] **Smooth Scrolling**: 60fps ohne Ruckeln
- [ ] **Rubber Band Effect**: Natürliches Bounce-Verhalten
- [ ] **Momentum Scrolling**: Flüssige Deceleration
- [ ] **Tab Bar**: Immer erreichbar, korrekte Highlights
- [ ] **Navigation Bar**: Smooth Transitions, korrekte Buttons

### 2. Animationen & Transitions
- [ ] **View Transitions**: Smooth Push/Pop Animationen
- [ ] **Modal Presentations**: Korrekte Sheet-Animationen
- [ ] **Loading States**: Elegante Skeleton Views
- [ ] **Button Feedback**: Haptic Feedback bei Taps
- [ ] **Pull-to-Refresh**: Native iOS Verhalten

### 3. UI/UX Perfektion
- [ ] **Safe Areas**: Korrekte Behandlung aller Geräte
- [ ] **Dynamic Type**: Text skaliert mit Systemeinstellungen
- [ ] **Dark Mode**: Vollständige Unterstützung
- [ ] **Accessibility**: VoiceOver, Switch Control
- [ ] **Keyboard Handling**: Smooth Keyboard Avoidance

### 4. Performance Standards
- [ ] **App Launch**: < 2 Sekunden Cold Start
- [ ] **Memory Usage**: < 100MB normale Nutzung
- [ ] **Battery Efficient**: Keine Background-Drain
- [ ] **Network Handling**: Graceful Offline/Online
- [ ] **Image Loading**: Progressive, cached

## 🧪 Test-Szenarien pro Dashboard

### Customer Dashboard Tests
1. **Login & Onboarding**
   - Registrierung mit Email/Apple ID
   - Adresse eingeben und validieren
   - Zahlungsmethode hinzufügen

2. **Partner Discovery**
   - Liste vs. Karten-Ansicht wechseln
   - Filter nach Kategorie (Restaurant, Supermarkt, etc.)
   - Suche nach Namen/Produkten
   - Favoriten hinzufügen/entfernen

3. **Bestellprozess**
   - Produkte zum Warenkorb hinzufügen
   - Mengen ändern, Sonderwünsche
   - Checkout-Flow komplett durchlaufen
   - Lieferzeit und -adresse bestätigen

4. **Order Tracking**
   - Live-Tracking der Bestellung
   - Push-Notifications testen
   - Chat mit Fahrer
   - Bewertung nach Lieferung

### Driver Dashboard Tests
1. **Driver Onboarding**
   - Fahrzeug registrieren
   - Dokumente hochladen
   - Verfügbarkeit einstellen

2. **Job Management**
   - Verfügbare Aufträge anzeigen
   - Job annehmen/ablehnen
   - Navigation zum Pickup
   - Navigation zur Lieferadresse

3. **Earnings & Stats**
   - Tageseinnahmen anzeigen
   - Wochenstatistiken
   - Bewertungen einsehen
   - Auszahlungen verwalten

### Partner Dashboard Tests
1. **Business Management**
   - Öffnungszeiten verwalten
   - Produktkatalog bearbeiten
   - Preise aktualisieren
   - Verfügbarkeit togglen

2. **Order Management**
   - Eingehende Bestellungen
   - Zubereitungszeit schätzen
   - Bestellung als fertig markieren
   - Stornierungen handhaben

3. **Analytics & Reports**
   - Umsatzstatistiken
   - Beliebte Produkte
   - Kundenbewertungen
   - Performance-Metriken

## 🔧 Edge Cases & Error Handling

### Netzwerk-Szenarien
- [ ] **Offline-Modus**: App funktioniert ohne Internet
- [ ] **Schlechte Verbindung**: Graceful Degradation
- [ ] **Server-Fehler**: Benutzerfreundliche Fehlermeldungen
- [ ] **Timeout-Handling**: Retry-Mechanismen

### Device-Spezifische Tests
- [ ] **iPhone SE**: Kleine Bildschirme
- [ ] **iPhone 16 Pro Max**: Große Bildschirme
- [ ] **iPad**: Tablet-Layout
- [ ] **Landscape Mode**: Querformat-Optimierung

### Stress Tests
- [ ] **Großer Warenkorb**: 50+ Artikel
- [ ] **Lange Listen**: 1000+ Partner/Produkte
- [ ] **Schnelle Taps**: Rapid-Fire Interactions
- [ ] **Memory Pressure**: Viele Bilder laden

## 🚀 Performance Benchmarks

### Zielwerte (Apple Standard)
- **App Launch**: < 400ms bis erste Interaktion
- **View Transitions**: < 100ms
- **Network Requests**: < 2s für normale Requests
- **Image Loading**: < 500ms für Thumbnails
- **Scroll Performance**: 60fps konstant

### Monitoring Tools
- **Instruments**: Time Profiler, Allocations
- **Xcode Metrics**: Launch Time, Hang Rate
- **Console**: Memory Warnings, Crashes
- **TestFlight**: Beta User Feedback

## 📋 Finale Checkliste vor Release

### Code Quality
- [ ] Keine Compiler Warnings
- [ ] Alle Tests bestehen
- [ ] Code Review durchgeführt
- [ ] Performance optimiert

### App Store Readiness
- [ ] App Icons alle Größen
- [ ] Screenshots für alle Geräte
- [ ] App Store Description
- [ ] Privacy Policy aktuell

### Deployment
- [ ] TestFlight Beta erfolgreich
- [ ] Crash-freie Beta-Phase
- [ ] User Feedback eingearbeitet
- [ ] Final QA Sign-off

---

**Nächste Schritte**: 
1. App im Simulator starten
2. Mit Demo-Accounts testen
3. Jeden Dashboard-Typ durchgehen
4. Performance mit Instruments messen
5. Edge Cases systematisch abarbeiten
