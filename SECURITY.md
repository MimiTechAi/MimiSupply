# Sicherheitsrichtlinien - MimiSupply

## API-Schlüssel Konfiguration

### Lokale Entwicklung
1. Kopiere `MimiSupply/APIKeys.plist.template` zu `MimiSupply/APIKeys.plist`
2. Ersetze `YOUR_GOOGLE_PLACES_API_KEY_HERE` mit deinem echten API-Schlüssel
3. Die `APIKeys.plist` Datei ist in `.gitignore` und wird NIEMALS committed

### Produktionsumgebung
- API-Schlüssel werden über Xcode Build Settings oder CI/CD Environment Variables injiziert
- Niemals API-Schlüssel in Quellcode oder Konfigurationsdateien hardcoden

## Gemeldete Sicherheitslücken melden
Bei Sicherheitsproblemen kontaktiere: security@mimisupply.com

## Letzte Sicherheitsupdates
- 2025-08-28: Google Places API Key aus Git-Historie entfernt
