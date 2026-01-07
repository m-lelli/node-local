# Changelog

## [0.2.0] - 2025-12-06

### Modifiche Architetturali

- **ConfigurationClass**: Creata classe singleton per centralizzare la gestione di tutti i percorsi di configurazione
  - Eliminati 13 percorsi hardcoded distribuiti nel codice
  - Tutti i moduli ora usano `ConfigurationClass::GetInstance()` per accedere ai percorsi
  - Preparata infrastruttura per lock file (concurrency control prevista per v0.3)

### Correzioni Bug

- **Cache**: Corretto bug critico in `Save-ToCache` che usava hardcoded `x64` invece di rilevare l'architettura dal file sorgente
  - Ora supporta correttamente sia x86 che x64
  - Utilizza `[System.IO.Path]::GetFileName($SourcePath)` per il nome file

### Miglioramenti

- **Refactoring classi**: Aggiornate `Installations`, `Network` e `Proxies` per usare `ConfigurationClass`
- **Ordine import**: Ottimizzato l'ordine di caricamento delle classi in `classes.ps1`

### Note di Sviluppo

- Rimossi comandi `upgrade` e `downgrade` (previsti per versioni future)
- Versione stabile per uso in produzione come tool ufficiale del team

---

## [0.1.0] - 2025-12-05

### Prima Release

- Installazione e gestione versioni Node.js senza privilegi amministratore
- Sistema di alias folder-based (il filesystem è la configurazione)
- Supporto per due modalità operative: isolata (`nlocal-*`) e override (`node`, `npm`, `npx`)
- Auto-sync dei pacchetti globali
- Verifica SHA256 automatica per ogni download
- Cache locale delle versioni scaricate
- Supporto Git Bash con proxy dedicati
- Sistema di proxy template-driven per routing comandi
