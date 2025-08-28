# MimiSupply - Security & Privacy Dokumentation

## Überblick

MimiSupply implementiert umfassende Sicherheits- und Datenschutzmaßnahmen gemäß DSGVO, Apple's Privacy Guidelines und modernen Security Best Practices. Die App priorisiert Benutzerdatenschutz und -sicherheit in allen Aspekten der Datenverarbeitung.

## DSGVO-Compliance

### Rechtliche Grundlagen

#### Datenverarbeitung nach Art. 6 DSGVO
- **Vertragserfüllung (Art. 6 Abs. 1 lit. b)**: Bestellabwicklung, Lieferung, Zahlung
- **Berechtigte Interessen (Art. 6 Abs. 1 lit. f)**: Betrugsschutz, Systemsicherheit
- **Einwilligung (Art. 6 Abs. 1 lit. a)**: Marketing, Analytics, Standortdaten

#### Besondere Kategorien (Art. 9 DSGVO)
- **Gesundheitsdaten**: Nur bei expliziter Einwilligung für Ernährungsempfehlungen
- **Standortdaten**: Präzise Lokalisierung nur mit Einwilligung

### Betroffenenrechte

#### Implementierte Rechte
```swift
// Auskunftsrecht (Art. 15 DSGVO)
func requestDataExport(for userId: String) async throws -> DataExportPackage {
    let userData = try await userRepository.fetchCompleteUserData(userId)
    let orderHistory = try await orderRepository.fetchUserOrders(userId)
    let preferences = try await preferencesRepository.fetchUserPreferences(userId)
    
    return DataExportPackage(
        personalData: userData,
        orderHistory: orderHistory,
        preferences: preferences,
        exportDate: Date(),
        format: .json
    )
}

// Löschungsrecht (Art. 17 DSGVO)
func deleteUserAccount(userId: String) async throws {
    // 1. Anonymisiere aktive Bestellungen
    try await anonymizeActiveOrders(for: userId)
    
    // 2. Lösche persönliche Daten
    try await userRepository.deleteUser(userId)
    
    // 3. Lösche CloudKit Daten
    try await cloudKitService.deleteUserData(userId)
    
    // 4. Lösche lokale Caches
    try await cacheManager.clearUserData(userId)
    
    // 5. Informiere Partner über Anonymisierung
    try await notifyPartnersOfDeletion(userId)
}

// Berichtigungsrecht (Art. 16 DSGVO)
func updateUserData(userId: String, updates: UserDataUpdate) async throws {
    let currentData = try await userRepository.fetchUser(userId)
    let updatedData = currentData.applying(updates)
    
    try await userRepository.update(updatedData)
    try await cloudKitService.syncUserData(updatedData)
    
    // Audit Log
    auditLogger.log(.dataCorrection, userId: userId, changes: updates)
}
```

#### Datenportabilität (Art. 20 DSGVO)
```swift
struct DataExportPackage: Codable {
    let personalData: UserProfile
    let orderHistory: [Order]
    let preferences: UserPreferences
    let paymentMethods: [PaymentMethod]
    let addresses: [Address]
    let exportDate: Date
    let format: ExportFormat
    
    enum ExportFormat: String, Codable {
        case json = "application/json"
        case csv = "text/csv"
        case xml = "application/xml"
    }
}
```

### Einwilligungsmanagement

#### Granulare Einwilligungen
```swift
struct ConsentManager {
    enum ConsentType: String, CaseIterable {
        case essential = "essential"           // Immer erforderlich
        case analytics = "analytics"           // Nutzungsanalyse
        case marketing = "marketing"           // Werbung und Empfehlungen
        case location = "location"             // Standortdaten
        case notifications = "notifications"   // Push-Benachrichtigungen
        case personalization = "personalization" // Personalisierung
    }
    
    func requestConsent(for types: [ConsentType]) async -> [ConsentType: Bool] {
        var results: [ConsentType: Bool] = [:]
        
        for type in types {
            let granted = await presentConsentDialog(for: type)
            results[type] = granted
            
            // Speichere Einwilligung mit Zeitstempel
            try? await storeConsent(type: type, granted: granted, timestamp: Date())
        }
        
        return results
    }
    
    func withdrawConsent(for type: ConsentType) async throws {
        try await storeConsent(type: type, granted: false, timestamp: Date())
        
        // Lösche entsprechende Daten
        switch type {
        case .analytics:
            try await analyticsService.deleteUserData()
        case .marketing:
            try await marketingService.removeUserFromLists()
        case .location:
            try await locationService.clearLocationHistory()
        case .personalization:
            try await recommendationService.clearUserProfile()
        default:
            break
        }
    }
}
```

## Datenschutz-Implementierung

### Apple Privacy Manifest

#### Erfasste Datentypen
```xml
<!-- Standortdaten -->
<dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeLocation</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <true/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        <string>NSPrivacyCollectedDataTypePurposeProductPersonalization</string>
    </array>
</dict>

<!-- Kontaktinformationen -->
<dict>
    <key>NSPrivacyCollectedDataType</key>
    <string>NSPrivacyCollectedDataTypeContactInfo</string>
    <key>NSPrivacyCollectedDataTypeLinked</key>
    <true/>
    <key>NSPrivacyCollectedDataTypeTracking</key>
    <false/>
    <key>NSPrivacyCollectedDataTypePurposes</key>
    <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        <string>NSPrivacyCollectedDataTypePurposeCustomerSupport</string>
    </array>
</dict>
```

#### Verwendete APIs
```xml
<!-- File Timestamp APIs -->
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>C617.1</string> <!-- App-Funktionalität -->
    </array>
</dict>

<!-- User Defaults APIs -->
<dict>
    <key>NSPrivacyAccessedAPIType</key>
    <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
    <key>NSPrivacyAccessedAPITypeReasons</key>
    <array>
        <string>CA92.1</string> <!-- App-Funktionalität -->
    </array>
</dict>
```

### Datenminimierung

#### Privacy by Design
```swift
struct PrivacyAwareDataCollection {
    // Nur notwendige Daten sammeln
    func collectOrderData(_ order: Order) -> PrivacyAwareOrder {
        return PrivacyAwareOrder(
            id: order.id,
            items: order.items.map { anonymizeProduct($0) },
            totalAmount: order.totalCents,
            timestamp: order.createdAt,
            // Persönliche Daten werden nicht gespeichert
            deliveryLocation: order.deliveryAddress.anonymized
        )
    }
    
    // Daten-Anonymisierung
    func anonymizeProduct(_ item: OrderItem) -> AnonymizedOrderItem {
        return AnonymizedOrderItem(
            category: item.productCategory,
            price: item.unitPriceCents,
            quantity: item.quantity
            // Produktname wird nicht gespeichert
        )
    }
}
```

### Datenspeicherung und -aufbewahrung

#### Aufbewahrungsfristen
```swift
enum DataRetentionPolicy {
    case essential(years: Int)      // Vertragserfüllung: 7 Jahre
    case analytics(days: Int)       // Analytics: 90 Tage
    case marketing(days: Int)       // Marketing: 365 Tage
    case logs(days: Int)           // System-Logs: 30 Tage
    case temporary(hours: Int)      // Temporäre Daten: 24 Stunden
    
    var retentionPeriod: TimeInterval {
        switch self {
        case .essential(let years):
            return TimeInterval(years * 365 * 24 * 60 * 60)
        case .analytics(let days), .marketing(let days), .logs(let days):
            return TimeInterval(days * 24 * 60 * 60)
        case .temporary(let hours):
            return TimeInterval(hours * 60 * 60)
        }
    }
}

class DataRetentionManager {
    func scheduleDataCleanup() {
        // Tägliche Bereinigung
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            Task {
                await self.performDataCleanup()
            }
        }
    }
    
    private func performDataCleanup() async {
        // Lösche abgelaufene Analytics-Daten
        try? await analyticsRepository.deleteDataOlderThan(
            DataRetentionPolicy.analytics(days: 90).retentionPeriod
        )
        
        // Lösche alte System-Logs
        try? await logRepository.deleteLogsOlderThan(
            DataRetentionPolicy.logs(days: 30).retentionPeriod
        )
        
        // Anonymisiere alte Bestelldaten
        try? await anonymizeOldOrders()
    }
}
```

## Sicherheitsarchitektur

### Authentifizierung und Autorisierung

#### Sign in with Apple Integration
```swift
class SecureAuthenticationService {
    func signInWithApple() async throws -> AuthenticationResult {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        // Nonce für Replay-Attack Schutz
        let nonce = generateSecureNonce()
        request.nonce = sha256(nonce)
        
        let result = try await performSignIn(request)
        
        // Validiere Apple's Response
        guard validateAppleResponse(result, nonce: nonce) else {
            throw AuthenticationError.invalidResponse
        }
        
        // Erstelle sichere Session
        let session = try await createSecureSession(from: result)
        
        return AuthenticationResult(
            user: session.user,
            token: session.token,
            expiresAt: session.expiresAt
        )
    }
    
    private func generateSecureNonce() -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = 32
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}
```

#### Rollenbasierte Zugriffskontrolle
```swift
enum UserRole: String, CaseIterable {
    case customer, driver, partner, admin
    
    var permissions: Set<Permission> {
        switch self {
        case .customer:
            return [.placeOrders, .viewOrderHistory, .editProfile]
        case .driver:
            return [.acceptJobs, .updateLocation, .completeDeliveries]
        case .partner:
            return [.manageProducts, .viewAnalytics, .manageOrders]
        case .admin:
            return Set(Permission.allCases)
        }
    }
}

class AuthorizationService {
    func checkPermission(_ permission: Permission, for user: UserProfile) -> Bool {
        return user.role.permissions.contains(permission)
    }
    
    func requirePermission(_ permission: Permission, for user: UserProfile) throws {
        guard checkPermission(permission, for: user) else {
            throw AuthorizationError.insufficientPermissions
        }
    }
}
```

### Verschlüsselung

#### Daten-Verschlüsselung
```swift
class EncryptionService {
    private let keychain = Keychain(service: "com.mimisupply.app")
    
    // AES-256 Verschlüsselung für sensible Daten
    func encrypt(_ data: Data, key: String) throws -> Data {
        let keyData = try getOrCreateEncryptionKey(key)
        
        let cipher = try AES(key: keyData.bytes, blockMode: CBC(iv: AES.randomIV(AES.blockSize)))
        let encrypted = try cipher.encrypt(data.bytes)
        
        return Data(encrypted)
    }
    
    func decrypt(_ encryptedData: Data, key: String) throws -> Data {
        let keyData = try getEncryptionKey(key)
        
        let cipher = try AES(key: keyData.bytes, blockMode: CBC(iv: Array(encryptedData.prefix(AES.blockSize))))
        let decrypted = try cipher.decrypt(Array(encryptedData.dropFirst(AES.blockSize)))
        
        return Data(decrypted)
    }
    
    // Keychain für sichere Schlüsselspeicherung
    private func getOrCreateEncryptionKey(_ identifier: String) throws -> Data {
        if let existingKey = try? keychain.getData(identifier) {
            return existingKey
        }
        
        // Generiere neuen Schlüssel
        var keyData = Data(count: 32) // 256 bit
        let result = keyData.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, 32, bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard result == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }
        
        try keychain.set(keyData, key: identifier)
        return keyData
    }
}
```

#### CloudKit Verschlüsselung
```swift
class SecureCloudKitService {
    // Sensible Daten werden vor CloudKit-Upload verschlüsselt
    func saveSecureRecord<T: Codable>(_ object: T, recordType: String) async throws {
        let jsonData = try JSONEncoder().encode(object)
        let encryptedData = try encryptionService.encrypt(jsonData, key: "cloudkit_\(recordType)")
        
        let record = CKRecord(recordType: recordType)
        record["encryptedData"] = encryptedData
        record["dataVersion"] = "1.0"
        
        try await database.save(record)
    }
    
    func fetchSecureRecord<T: Codable>(_ type: T.Type, recordID: CKRecord.ID) async throws -> T {
        let record = try await database.record(for: recordID)
        
        guard let encryptedData = record["encryptedData"] as? Data else {
            throw CloudKitError.invalidRecord
        }
        
        let decryptedData = try encryptionService.decrypt(encryptedData, key: "cloudkit_\(record.recordType)")
        return try JSONDecoder().decode(type, from: decryptedData)
    }
}
```

### Netzwerksicherheit

#### Certificate Pinning
```swift
class SecureNetworkService: NSURLSessionDelegate {
    private let pinnedCertificates: Set<Data>
    
    init() {
        // Lade gepinnte Zertifikate
        self.pinnedCertificates = Set([
            loadCertificate("icloud.com"),
            loadCertificate("apple.com")
        ])
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validiere Certificate Chain
        guard validateCertificateChain(serverTrust) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    }
    
    private func validateCertificateChain(_ serverTrust: SecTrust) -> Bool {
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            let certificateData = SecCertificateCopyData(certificate)
            let data = Data(bytes: CFDataGetBytePtr(certificateData), count: CFDataGetLength(certificateData))
            
            if pinnedCertificates.contains(data) {
                return true
            }
        }
        
        return false
    }
}
```

#### Request Signing
```swift
class RequestSigner {
    private let privateKey: SecKey
    
    func signRequest(_ request: URLRequest) throws -> URLRequest {
        var signedRequest = request
        
        // Erstelle Signature Payload
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let method = request.httpMethod ?? "GET"
        let path = request.url?.path ?? ""
        let bodyHash = request.httpBody?.sha256 ?? ""
        
        let payload = "\(method)\n\(path)\n\(timestamp)\n\(bodyHash)"
        
        // Signiere Payload
        let signature = try signPayload(payload)
        
        // Füge Headers hinzu
        signedRequest.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        signedRequest.setValue(signature, forHTTPHeaderField: "X-Signature")
        
        return signedRequest
    }
    
    private func signPayload(_ payload: String) throws -> String {
        let data = payload.data(using: .utf8)!
        
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            data as CFData,
            &error
        ) else {
            throw SigningError.signatureFailed
        }
        
        return Data(bytes: CFDataGetBytePtr(signature), count: CFDataGetLength(signature)).base64EncodedString()
    }
}
```

## Audit Logging und Monitoring

### Security Event Logging
```swift
class SecurityAuditLogger {
    enum SecurityEvent: String {
        case loginAttempt = "login_attempt"
        case loginSuccess = "login_success"
        case loginFailure = "login_failure"
        case dataAccess = "data_access"
        case dataModification = "data_modification"
        case permissionDenied = "permission_denied"
        case suspiciousActivity = "suspicious_activity"
        case dataExport = "data_export"
        case accountDeletion = "account_deletion"
    }
    
    func log(_ event: SecurityEvent, userId: String? = nil, details: [String: Any] = [:]) {
        let logEntry = SecurityLogEntry(
            timestamp: Date(),
            event: event,
            userId: userId,
            deviceId: UIDevice.current.identifierForVendor?.uuidString,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            details: details
        )
        
        // Lokales Logging
        writeToSecureLog(logEntry)
        
        // Remote Logging (verschlüsselt)
        Task {
            await sendToSecureLogServer(logEntry)
        }
    }
    
    private func writeToSecureLog(_ entry: SecurityLogEntry) {
        let logData = try? JSONEncoder().encode(entry)
        let encryptedData = try? encryptionService.encrypt(logData!, key: "audit_log")
        
        // Schreibe in sichere Log-Datei
        secureFileManager.appendToLog(encryptedData!)
    }
}
```

### Anomalie-Erkennung
```swift
class SecurityMonitor {
    private let anomalyDetector = AnomalyDetector()
    
    func monitorUserActivity(_ activity: UserActivity) {
        // Erkenne ungewöhnliche Muster
        if anomalyDetector.isAnomalous(activity) {
            handleSuspiciousActivity(activity)
        }
        
        // Rate Limiting
        if isRateLimitExceeded(activity) {
            handleRateLimit(activity)
        }
        
        // Geo-Location Anomalien
        if isLocationAnomalous(activity) {
            handleLocationAnomaly(activity)
        }
    }
    
    private func handleSuspiciousActivity(_ activity: UserActivity) {
        // Log Security Event
        securityLogger.log(.suspiciousActivity, userId: activity.userId, details: [
            "activity_type": activity.type,
            "risk_score": activity.riskScore,
            "location": activity.location
        ])
        
        // Temporäre Account-Sperre bei hohem Risiko
        if activity.riskScore > 0.8 {
            Task {
                await accountSecurityService.temporaryLock(activity.userId)
            }
        }
    }
}
```

## Incident Response

### Security Incident Handling
```swift
class SecurityIncidentManager {
    enum IncidentSeverity: Int {
        case low = 1, medium = 2, high = 3, critical = 4
    }
    
    func handleSecurityIncident(_ incident: SecurityIncident) async {
        // 1. Sofortige Maßnahmen
        await executeImmediateResponse(incident)
        
        // 2. Incident Logging
        securityLogger.log(.suspiciousActivity, details: [
            "incident_id": incident.id,
            "severity": incident.severity.rawValue,
            "type": incident.type
        ])
        
        // 3. Benachrichtigungen
        await notifySecurityTeam(incident)
        
        // 4. Betroffene Benutzer informieren (falls erforderlich)
        if incident.requiresUserNotification {
            await notifyAffectedUsers(incident)
        }
        
        // 5. Forensische Analyse
        await performForensicAnalysis(incident)
    }
    
    private func executeImmediateResponse(_ incident: SecurityIncident) async {
        switch incident.severity {
        case .critical:
            // Sofortiger Service-Stopp für betroffene Komponenten
            await emergencyServiceShutdown(incident.affectedServices)
            
        case .high:
            // Temporäre Einschränkungen
            await implementTemporaryRestrictions(incident)
            
        case .medium, .low:
            // Verstärkte Überwachung
            await enhanceMonitoring(incident.affectedAreas)
        }
    }
}
```

### Data Breach Response
```swift
class DataBreachResponseManager {
    func handleDataBreach(_ breach: DataBreach) async {
        // 1. Sofortige Eindämmung
        await containBreach(breach)
        
        // 2. Schadensbewertung
        let assessment = await assessBreachImpact(breach)
        
        // 3. Behörden-Meldung (DSGVO Art. 33)
        if assessment.requiresAuthorityNotification {
            await notifyDataProtectionAuthority(breach, assessment)
        }
        
        // 4. Betroffene Personen informieren (DSGVO Art. 34)
        if assessment.requiresUserNotification {
            await notifyAffectedUsers(breach, assessment)
        }
        
        // 5. Forensische Untersuchung
        await conductForensicInvestigation(breach)
        
        // 6. Verbesserungsmaßnahmen
        await implementSecurityImprovements(breach.lessons)
    }
    
    private func assessBreachImpact(_ breach: DataBreach) async -> BreachImpactAssessment {
        return BreachImpactAssessment(
            affectedUsers: await countAffectedUsers(breach),
            dataTypes: breach.compromisedDataTypes,
            severity: calculateSeverity(breach),
            requiresAuthorityNotification: shouldNotifyAuthority(breach),
            requiresUserNotification: shouldNotifyUsers(breach),
            estimatedCosts: calculateEstimatedCosts(breach)
        )
    }
}
```

## Compliance und Zertifizierungen

### DSGVO-Compliance Checkliste
- ✅ **Privacy by Design**: Datenschutz von Anfang an berücksichtigt
- ✅ **Datenminimierung**: Nur notwendige Daten werden erhoben
- ✅ **Zweckbindung**: Daten nur für angegebene Zwecke verwendet
- ✅ **Speicherbegrenzung**: Automatische Löschung nach Aufbewahrungsfristen
- ✅ **Betroffenenrechte**: Vollständige Implementierung aller Rechte
- ✅ **Einwilligungsmanagement**: Granulare, widerrufbare Einwilligungen
- ✅ **Datenschutz-Folgenabschätzung**: Regelmäßige DSFA-Durchführung
- ✅ **Auftragsverarbeitung**: Verträge mit allen Dienstleistern

### Apple Privacy Guidelines
- ✅ **Privacy Manifest**: Vollständige Deklaration aller Datentypen
- ✅ **App Tracking Transparency**: Kein Cross-App Tracking
- ✅ **Data Minimization**: Nur notwendige Berechtigungen angefordert
- ✅ **User Control**: Benutzer kann alle Einstellungen kontrollieren
- ✅ **Transparency**: Klare Kommunikation über Datenverwendung

### Security Standards
- ✅ **OWASP Mobile Top 10**: Alle Risiken adressiert
- ✅ **ISO 27001**: Security Management System implementiert
- ✅ **SOC 2 Type II**: Jährliche Compliance-Audits
- ✅ **PCI DSS**: Sichere Zahlungsverarbeitung

## Regelmäßige Security Reviews

### Monatliche Reviews
- Überprüfung der Audit Logs
- Anomalie-Analyse
- Vulnerability Scans
- Penetration Testing

### Quartalsweise Reviews
- DSGVO-Compliance Audit
- Privacy Impact Assessment
- Security Architecture Review
- Incident Response Testing

### Jährliche Reviews
- Vollständiges Security Audit
- Datenschutz-Folgenabschätzung
- Compliance Zertifizierung
- Business Continuity Testing

## Kontakt und Verantwortlichkeiten

### Datenschutzbeauftragter
- **E-Mail**: privacy@mimisupply.com
- **Telefon**: +49 (0) 123 456789
- **Postadresse**: MimiSupply GmbH, Datenschutz, Musterstraße 1, 12345 Berlin

### Security Team
- **E-Mail**: security@mimisupply.com
- **Incident Hotline**: +49 (0) 123 456790 (24/7)
- **PGP Key**: [Public Key für verschlüsselte Kommunikation]

### Meldung von Sicherheitslücken
- **Responsible Disclosure**: security-disclosure@mimisupply.com
- **Bug Bounty Program**: https://mimisupply.com/security/bounty
- **Verschlüsselte Kommunikation**: Verwendung von PGP empfohlen
