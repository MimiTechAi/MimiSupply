# MimiSupply - Deployment- & CI/CD-Dokumentation

## Überblick

MimiSupply nutzt GitHub Actions für die CI/CD-Pipeline mit automatisierten Tests, Code-Qualitätsprüfungen und TestFlight-Deployment. Die Pipeline ist für iOS-spezifische Workflows optimiert und unterstützt mehrere Deployment-Umgebungen.

## CI/CD-Pipeline Architektur

### Pipeline-Struktur
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Quality Gates   │    │ Build & Test    │    │ Deploy          │
│ - Lint & Format │    │ - Unit Tests    │    │ - Archive       │
│ - Privacy Check │    │ - UI Tests      │    │ - TestFlight    │
│ - Concurrency   │    │ - Performance   │    │ - App Store     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Trigger-Bedingungen
- **Push**: `main`, `develop` Branches
- **Pull Request**: Gegen `main`, `develop`
- **Manual**: APR (Automated Pull Request) mit Label `apr-run`

## GitHub Actions Workflow

### 1. Quality Gates (Parallel)

#### Lint & Format Check
```yaml
lint-and-format:
  name: 🔍 Lint & Format
  runs-on: macos-15
  steps:
    - name: Run SwiftLint
      run: swiftlint lint --reporter github-actions-logging
    
    - name: Check Swift formatting
      run: swift-format lint --recursive MimiSupply/
```

**Prüfungen:**
- SwiftLint Code-Qualität
- Swift-Format Konsistenz
- Cached Dependencies für Performance

#### Privacy Manifest Validation
```yaml
privacy-manifest-check:
  name: 🔒 Privacy Manifest Validation
  steps:
    - name: Validate Privacy Manifest exists
      run: |
        if [ ! -f "MimiSupply/PrivacyInfo.xcprivacy" ]; then
          echo "❌ Privacy Manifest missing"
          exit 1
        fi
```

**Validierungen:**
- Existenz der PrivacyInfo.xcprivacy
- XML-Struktur-Validierung
- DSGVO-Compliance-Check

#### Swift 6 Concurrency Check
```yaml
concurrency-check:
  name: 🔄 Swift 6 Concurrency Check
  steps:
    - name: Check for concurrency warnings
      run: |
        xcodebuild build | tee build.log
        if grep -i "concurrency" build.log | grep -i "warning"; then
          exit 1
        fi
```

### 2. Build & Test Matrix

#### Multi-Device Testing
```yaml
strategy:
  matrix:
    scheme: [MimiSupply]
    destination: 
      - 'platform=iOS Simulator,name=iPhone 16,OS=18.0'
      - 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation),OS=18.0'
```

#### Test-Kategorien
- **Unit Tests**: Business Logic, Services, Models
- **UI Tests**: User Journeys, Accessibility
- **Performance Tests**: Memory, CPU, Network
- **Snapshot Tests**: Visual Regression (Light/Dark/Accessibility)

### 3. Performance & Quality Checks

#### Performance Smoke Tests
```yaml
performance-smoke-test:
  steps:
    - name: Run Performance Tests
      run: |
        xcodebuild test \
          -only-testing:MimiSupplyTests/Performance \
          -resultBundlePath PerformanceResults.xcresult
```

#### Snapshot Testing Matrix
```yaml
strategy:
  matrix:
    appearance: [light, dark]
    accessibility: [default, large-text, high-contrast]
```

### 4. Archive & Distribution

#### Code Signing
```yaml
- name: Import Code-Signing Certificates
  uses: Apple-Actions/import-codesign-certs@v2
  with:
    p12-file-base64: ${{ secrets.CERTIFICATES_P12 }}
    p12-password: ${{ secrets.CERTIFICATES_P12_PASSWORD }}

- name: Download Provisioning Profiles
  uses: Apple-Actions/download-provisioning-profiles@v2
  with:
    bundle-id: com.mimisupply.app
    issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
```

#### TestFlight Upload
```yaml
- name: Upload to TestFlight
  uses: Apple-Actions/upload-testflight-build@v1
  with:
    app-path: MimiSupply.ipa
    issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
    api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
```

## Deployment-Umgebungen

### 1. Development
- **Trigger**: Feature Branch Push
- **Ziel**: Lokale Entwicklung
- **Tests**: Unit Tests, Lint Checks
- **Dauer**: ~5 Minuten

### 2. Staging (TestFlight Internal)
- **Trigger**: Develop Branch Push
- **Ziel**: Internal Testing Team
- **Tests**: Vollständige Test-Suite
- **Dauer**: ~15 Minuten

### 3. Production (TestFlight External)
- **Trigger**: Main Branch Push
- **Ziel**: Beta Tester
- **Tests**: Vollständige Test-Suite + Performance
- **Dauer**: ~20 Minuten

### 4. App Store Release
- **Trigger**: Manual über App Store Connect
- **Ziel**: Öffentliche Veröffentlichung
- **Review**: Apple Review Process
- **Dauer**: 24-48 Stunden

## APR (Automated Pull Request) System

### Konfiguration
```json
{
  "provider": "zai",
  "model": "glm-4.5",
  "api_env_var": "ZAI_API_KEY",
  "triggers": {
    "mode": "manual", 
    "label": "apr-run"
  },
  "xcode": {
    "project_kind": "xcodeproj",
    "project_path": "MimiSupply.xcodeproj",
    "scheme": "MimiSupply",
    "destination": "platform=iOS Simulator,name=iPhone 16"
  }
}
```

### Workflow
1. **Trigger**: Label `apr-run` auf Issue/PR
2. **Analysis**: AI analysiert Build-Fehler
3. **Fix Generation**: Automatische Code-Fixes
4. **PR Creation**: Pull Request mit Fixes
5. **Review**: Manueller Review-Prozess

## Secrets Management

### GitHub Secrets
```
CERTIFICATES_P12              # iOS Distribution Certificate
CERTIFICATES_P12_PASSWORD     # Certificate Password
APPSTORE_ISSUER_ID           # App Store Connect Issuer ID
APPSTORE_KEY_ID              # App Store Connect Key ID
APPSTORE_PRIVATE_KEY         # App Store Connect Private Key
ZAI_API_KEY                  # APR AI Service Key
```

### Sicherheitsmaßnahmen
- Secrets Rotation alle 90 Tage
- Least Privilege Access
- Audit Logging für Secret Usage
- Encrypted Storage

## Build-Optimierungen

### Caching-Strategien
```yaml
# DerivedData Cache
- uses: actions/cache@v4
  with:
    path: ~/Library/Developer/Xcode/DerivedData
    key: ${{ runner.os }}-deriveddata-${{ hashFiles('**/*.pbxproj') }}

# SPM Dependencies Cache
- uses: actions/cache@v4
  with:
    path: |
      ~/Library/Caches/org.swift.swiftpm
      ~/Library/org.swift.swiftpm
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
```

### Performance-Metriken
- **Cold Build**: ~8 Minuten
- **Cached Build**: ~3 Minuten
- **Test Execution**: ~5 Minuten
- **Archive & Upload**: ~7 Minuten

## Monitoring & Alerting

### Build-Monitoring
- **Success Rate**: >95% Ziel
- **Build Duration**: Trend-Monitoring
- **Flaky Tests**: Automatische Erkennung
- **Resource Usage**: CPU/Memory Tracking

### Alerting-Kanäle
- **Slack**: Build-Status Notifications
- **Email**: Critical Failures
- **GitHub**: PR Status Checks
- **Dashboard**: Real-time Metrics

## Rollback-Strategien

### Automatisches Rollback
```yaml
- name: Rollback on Critical Failure
  if: failure() && contains(github.event.head_commit.message, '[critical]')
  run: |
    # Revert to last known good build
    git revert ${{ github.sha }}
    # Trigger emergency deployment
```

### Manuelles Rollback
1. **TestFlight**: Vorherige Version aktivieren
2. **App Store**: Expedited Review für Hotfix
3. **Feature Flags**: Problematische Features deaktivieren
4. **Database**: Schema-Rollback falls nötig

## Compliance & Governance

### Code-Qualität Gates
- **SwiftLint**: Keine Errors, max 5 Warnings
- **Test Coverage**: >80% für kritische Pfade
- **Performance**: Keine Regression >10%
- **Security**: Keine High/Critical Vulnerabilities

### Approval-Prozess
```
Developer → PR → Code Review → Quality Gates → Staging → Production
     ↓           ↓              ↓               ↓          ↓
   Feature    Peer Review   Automated Tests   QA Test   Release
```

## Disaster Recovery

### Backup-Strategien
- **Source Code**: GitHub Repository Backup
- **Certificates**: Encrypted Vault Storage
- **Build Artifacts**: 30-Tage Retention
- **Test Results**: 7-Tage Retention

### Recovery-Prozeduren
1. **Repository Corruption**: Restore from Backup
2. **Certificate Expiry**: Emergency Re-signing
3. **Pipeline Failure**: Fallback to Manual Build
4. **Apple Services Down**: Queue Builds for Retry

## Metriken & KPIs

### Deployment-Metriken
- **Deployment Frequency**: 2-3x pro Woche
- **Lead Time**: <2 Stunden (Feature → Production)
- **MTTR**: <30 Minuten (Mean Time To Recovery)
- **Change Failure Rate**: <5%

### Qualitäts-Metriken
- **Test Success Rate**: >98%
- **Build Success Rate**: >95%
- **Performance Regression**: <2%
- **Security Vulnerabilities**: 0 High/Critical

## Zukünftige Verbesserungen

### Geplante Features
- **Parallel Testing**: Weitere Parallelisierung
- **ML-basierte Test Selection**: Intelligente Test-Auswahl
- **Progressive Deployment**: Canary Releases
- **Advanced Monitoring**: Real-time Performance Tracking

### Technische Roadmap
- **Xcode 16**: Migration auf neueste Version
- **Swift 6**: Vollständige Concurrency-Unterstützung
- **iOS 18**: Neue Framework-Features
- **Cloud Build**: Migration zu Apple Cloud Build
