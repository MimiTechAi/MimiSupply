# Automated Program Repair (APR) Pipeline – MimiSupply

This repo contains a minimal, provider-agnostic APR pipeline you can run locally or in CI. It follows PDCA and uses small "Nano-Schritte" to minimize risk.

## Ziele
- Fehler automatisch erkennen (Compiler/Tests)
- Kontext gezielt sammeln (Retrieval)
- Reparaturvorschläge generieren (LLM, optional – stub)
- Patches sicher anwenden (Guardrails)
- Build/Tests validieren und bei Fehlschlag rollback

## Struktur
- `apr.config.json`: Konfiguration, Guardrails, Xcode-Einstellungen
- `MimiSupply/Scripts/apr/`:
  - `run_apr.py`: Orchestrator
  - `failure_parser.py`: Extrahiert Compiler-/Testfehler aus `build.log`
  - `context_retriever.py`: Sammelt relevante Dateien gemäß Scopes/Excludes
  - `repair_agent.py`: LLM-Stub (kein externer Call bis konfiguriert)
  - `patch_applier.py`: Wendet Patches an (Backups + Max-Change-Lines)
  - `validator.py`: Optional Lint, führt `xcodebuild test` aus und schreibt `build.log`
  - `reporter.py`: Erstellt `apr-report.json`

## PDCA + Nano-Schritte
- Plan
  - Konfiguration in `apr.config.json` prüfen (Scheme, Destination, Scopes)
  - Guardrails: `max_change_lines`, Excludes, Testpflicht
- Do
  - `python3 MimiSupply/Scripts/apr/run_apr.py --generate-log` ausführen
  - Optional ohne Testlauf: `--log build.log`
- Check
  - `apr-report.json` ansehen: Failures, angewendete Patches, Testresultate
- Act
  - Provider/Model setzen, Secrets einrichten, Trigger in CI aktivieren

Nano-Schritte (sicher, iterativ):
1) Nur Parser + Validator nutzen (kein Patch) – Ist-Zustand erfassen
2) LLM-Stub aktiv lassen (keine Änderungen), nur Prompt prüfen
3) LLM aktivieren, aber `--dry-run` verwenden
4) Kleine Patch-Umfänge (`max_change_lines` klein halten), nur Tests-Module
5) CI-Trigger auf Label `apr-run` begrenzen
6) Metriken beobachten, dann Reichweite erhöhen

## Lokale Nutzung
```bash
# 1) Log generieren (führt Tests aus)
python3 MimiSupply/Scripts/apr/run_apr.py --generate-log

# 2) Nur existierendes build.log verwenden
python3 MimiSupply/Scripts/apr/run_apr.py --log build.log

# 3) Trockenlauf (LLM aktiv, aber keine Dateien schreiben)
python3 MimiSupply/Scripts/apr/run_apr.py --generate-log --dry-run
```

## LLM aktivieren
- In `apr.config.json` Felder setzen: `provider`, `model`, `api_env_var`
- API-Key als Secret in der Shell/CI setzen, z. B. `export OPENAI_API_KEY=...`
- In `repair_agent.py` die gewünschte Provider-Integration ergänzen (SDK-Aufruf)

## CI-Integration (Kurz)
- GitHub Actions (empfohlen): Workflow `apr.yml` mit Trigger auf Label `apr-run`
- Jobs: Checkout → Xcode Setup → `run_apr.py --generate-log` → Artefakte (Report)
- Review-Gates: PR aus APR-Branch nur mergen, wenn Tests grün sind

## Sicherheit/Guardrails
- Allowlist `file_scopes`, Excludes (kein `project.pbxproj` etc.)
- `max_change_lines` limitiert Patchgröße
- Backups `.apr.bak` pro Datei + automatisches Rollback bei Testfehlschlag

## Output
- `build.log` – letzter Build-/Test-Run
- `apr-report.json` – Gesamtbericht der Pipeline

## Erweiterungen (optional)
- Static-Analysis einschalten (`swiftlint`, `swiftformat`)
- Retrieval verfeinern (Symbol-gesteuert, Test-Abdeckung)
- Prompt-Engineering und Multi-try (`retries`) mit differenziellen Patches
