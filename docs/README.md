# 📚 Documentazione node-local

Questa cartella contiene tutta la documentazione dettagliata del progetto.

## 📄 Documenti Disponibili

### 📖 Guide Utente

#### [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)
Esempi pratici di utilizzo di node-local con casi d'uso reali.

**Quando leggerlo:**
- Dopo aver installato node-local
- Per vedere scenari pratici
- Per imparare workflow avanzati

**Contenuto:**
- Esempi base (install, use, list)
- Gestione alias
- Workflow multi-progetto
- Best practices

---

### 🔄 Comandi Upgrade/Downgrade

#### [UPGRADE_COMMAND.md](UPGRADE_COMMAND.md)
Documentazione completa del comando `node-local upgrade`.

**Quando leggerlo:**
- Prima di fare upgrade di una versione Node.js
- Per capire il flusso interattivo two-step
- Per vedere tutti i casi d'uso (singola/multipla installazione)

**Contenuto:**
- Modalità singola installazione (upgrade rapido alla latest)
- Modalità multiple installazioni (menu two-step)
- Flusso operativo dettagliato (major → subversion)
- Esempi per ogni scenario
- Gestione pacchetti globali

#### [DOWNGRADE_COMMAND.md](DOWNGRADE_COMMAND.md)
Documentazione completa del comando `node-local downgrade`.

**Quando leggerlo:**
- Per passare a versioni Node.js precedenti
- Per gestire progetti legacy
- Per test di compatibilità con versioni più vecchie

**Contenuto:**
- Flusso interattivo two-step (senza limitazioni)
- Differenze tra upgrade e downgrade
- Casi d'uso comuni (rollback, compatibilità)
- Behavior (rimozione, duplicati, ripristino)
- Best practices e backup

#### [MODIFICHE_UPGRADE_DOWNGRADE.md](MODIFICHE_UPGRADE_DOWNGRADE.md)
Riepilogo modifiche flusso upgrade/downgrade (two-step).

**Quando leggerlo:**
- Per capire i cambiamenti all'UX
- Per migration notes
- Per reference implementazione

**Contenuto:**
- Comparison one-step vs two-step
- File modificati e nuovi moduli
- Testing results
- Backwards compatibility

#### [IMPLEMENTAZIONE_UPGRADE.md](IMPLEMENTAZIONE_UPGRADE.md)
Dettagli tecnici implementazione comando upgrade.

**Quando leggerlo:**
- Per contribuire al codice
- Per capire architettura upgrade/downgrade
- Per debug o troubleshooting

**Contenuto:**
- File creati/modificati
- Funzionalità implementate
- Architettura decisionale
- Test e validazione

#### [MODIFICHE_UPGRADE_SINGOLA.md](MODIFICHE_UPGRADE_SINGOLA.md)
Changelog modifiche per gestione singola installazione.

**Quando leggerlo:**
- Per capire il nuovo comportamento upgrade rapido
- Se hai una sola installazione Node.js
- Per vedere il flusso decisionale

**Contenuto:**
- Differenze singola vs multipla installazione
- Flusso upgrade rapido alla latest
- Esempi pratici con output
- Vantaggi nuovo approccio

---

## 🗂️ Organizzazione

### Tipi di Documenti

**Guide Utente** (`USAGE_*.md`)
- Target: Utenti finali
- Linguaggio: Semplice, esempi pratici
- Formato: Tutorial step-by-step

**Documentazione Comandi** (`*_COMMAND.md`)
- Target: Utenti intermedi/avanzati
- Linguaggio: Tecnico ma accessibile
- Formato: Reference con esempi

**Documentazione Implementazione** (`IMPLEMENTAZIONE_*.md`)
- Target: Sviluppatori/Contributors
- Linguaggio: Tecnico dettagliato
- Formato: Architettura + codice

**Changelog** (`MODIFICHE_*.md`)
- Target: Tutti
- Linguaggio: Descrittivo
- Formato: Prima/Dopo con esempi

---

## 📍 Navigazione Rapida

**Voglio iniziare ad usare node-local:**
→ Vai al [README principale](../README.md)
→ Poi leggi [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)

**Voglio fare upgrade di Node.js:**
→ Leggi [UPGRADE_COMMAND.md](UPGRADE_COMMAND.md)

**Voglio contribuire al progetto:**
→ Leggi [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md)
→ Poi [IMPLEMENTAZIONE_UPGRADE.md](IMPLEMENTAZIONE_UPGRADE.md)

**Ho una sola installazione e voglio upgrade rapido:**
→ Leggi [MODIFICHE_UPGRADE_SINGOLA.md](MODIFICHE_UPGRADE_SINGOLA.md)

---

## 🔄 Mantenimento

### Quando aggiungere nuova documentazione

**Crea nuovo file in questa cartella se:**
- ✅ Documenti una feature complessa (>100 righe)
- ✅ Serve reference dettagliata per un comando
- ✅ Changelog importante per utenti

**Aggiorna README principale se:**
- ✅ Quick start o overview generale
- ✅ Esempi base per iniziare
- ✅ Info installazione/rimozione

**Convenzioni naming:**
```
USAGE_*.md           → Guide utente pratiche
*_COMMAND.md         → Reference comandi
IMPLEMENTAZIONE_*.md → Dettagli tecnici
MODIFICHE_*.md       → Changelog modifiche
```

---

**Ultima revisione:** Ottobre 2025
