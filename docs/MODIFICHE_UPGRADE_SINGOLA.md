# 🔄 Upgrade Script - Modifiche Flusso Singola Installazione

## ✅ Modifiche Implementate

### Comportamento Adattivo

Lo script `upgrade` ora ha **due modalità operative** in base al numero di installazioni:

#### 🚀 Una Sola Installazione (NUOVO)
- ✅ **Selezione automatica** - Non mostra menu, seleziona direttamente l'unica installazione
- ✅ **Proposta latest** - Offre immediatamente upgrade alla versione più recente
- ✅ **Scelta rapida** - L'utente può accettare (S) o rifiutare (n)
- ✅ **Fallback completo** - Se rifiuta, mostra il menu completo con versioni per major

#### 📋 Multiple Installazioni (INVARIATO)
- Menu interattivo per selezione installazione
- Visualizzazione versioni organizzate per major release
- Selezione manuale versione target

---

## 📝 Codice Modificato

### File: `lib/upgrade.ps1`

**Funzione modificata:** `Start-NodeUpgrade`

**Modifiche:**
1. Aggiunto controllo numero installazioni all'inizio
2. Branch condizionale per singola vs multiple installazioni
3. Nuova sezione "UPGRADE RAPIDO DISPONIBILE" per caso singolo
4. Recupero automatico versione latest
5. Prompt S/n per upgrade rapido
6. Fallback al menu completo se utente rifiuta

---

## 🎯 Flusso Decisionale

```
┌─────────────────────────┐
│  node-local upgrade     │
└───────────┬─────────────┘
            │
            ▼
    ┌───────────────┐
    │ Conta         │
    │ installazioni │
    └───────┬───────┘
            │
     ┌──────┴──────┐
     │             │
     ▼             ▼
┌─────────┐   ┌─────────┐
│ Singola │   │Multiple │
└────┬────┘   └────┬────┘
     │             │
     ▼             ▼
 Selezione     Menu di
 automatica    selezione
     │             │
     ▼             │
 Proposta          │
 latest            │
     │             │
 ┌───┴───┐         │
 │ S / n │         │
 └───┬───┘         │
     │             │
 ┌───┴───┐         │
 ▼       ▼         ▼
Upgrade  Menu    Menu
latest   major   major
```

---

## 💡 Esempio Pratico

### Scenario 1: Una sola installazione

```powershell
PS> node-local list

Installazioni Node.js:

NOME             VERSIONE  USE   PATH
---------------- --------- ----- -------------------------
production       18.20.0   YES   %APPDATA%\node-local\...

PS> node-local upgrade

=== Upgrade Node.js ===

Installazione rilevata: production (Node.js 18.20.0)

Recupero versioni disponibili...
✓ Trovate 157 versioni disponibili

────────────────────────────────────────────────────────────────
UPGRADE RAPIDO DISPONIBILE
────────────────────────────────────────────────────────────────

Versione corrente: Node.js 18.20.0
Versione latest:   Node.js 23.1.0

Vuoi aggiornare direttamente alla versione latest? [S/n]: s

✓ Upgrade alla latest selezionato

────────────────────────────────────────────────────────────────
RIEPILOGO UPGRADE:
  Installazione: production
  Versione attuale: 18.20.0
  Nuova versione: 23.1.0
────────────────────────────────────────────────────────────────

Procedere con l'upgrade? [S/n]: s
```

### Scenario 2: Una sola installazione, utente rifiuta latest

```powershell
PS> node-local upgrade

=== Upgrade Node.js ===

Installazione rilevata: production (Node.js 18.20.0)

Recupero versioni disponibili...
✓ Trovate 157 versioni disponibili

────────────────────────────────────────────────────────────────
UPGRADE RAPIDO DISPONIBILE
────────────────────────────────────────────────────────────────

Versione corrente: Node.js 18.20.0
Versione latest:   Node.js 23.1.0

Vuoi aggiornare direttamente alla versione latest? [S/n]: n

ok, ti mostro tutte le versioni disponibili...

Versione corrente: v18.20.0 (Node.js 18.x)
────────────────────────────────────────────────────────────────

▼ Node.js 18.x (versione corrente)
  [1]    v18.20.5         [LTS: hydrogen]
  [2]    v18.20.4         [LTS: hydrogen]
  ...

▼ Node.js 20.x
  [7]    v20.18.0         [LTS: iron]
  ...

▼ Node.js 22.x
  [12]   v22.11.0
  ...

Digita il numero della versione da installare (o 'q' per uscire):
```

### Scenario 3: Multiple installazioni (comportamento invariato)

```powershell
PS> node-local list

Installazioni Node.js:

NOME             VERSIONE  USE   PATH
---------------- --------- ----- -------------------------
production       18.20.0   YES   %APPDATA%\node-local\...
staging          20.15.0   NO    %APPDATA%\node-local\...
legacy           16.20.0   NO    %APPDATA%\node-local\...

PS> node-local upgrade

=== Upgrade Node.js ===

Seleziona l'installazione da aggiornare:

  [1]    legacy               Node.js 16.20.0
  [2]    production           Node.js 18.20.0
  [3]    staging              Node.js 20.15.0

Digita il numero dell'installazione (o 'q' per uscire): 2

✓ Selezionato: production (attualmente Node.js 18.20.0)

Recupero versioni disponibili...
✓ Trovate 157 versioni disponibili

Versione corrente: v18.20.0 (Node.js 18.x)
────────────────────────────────────────────────────────────────

▼ Node.js 18.x (versione corrente)
  [1]    v18.20.5         [LTS: hydrogen]
  ...
```

---

## 🧪 Test

Esegui `.\test-upgrade-behavior.ps1` per vedere quale modalità si attiverebbe nel tuo sistema.

---

## 📚 Vantaggi

### Per utenti con singola installazione:
- ⚡ **Più veloce** - 2 passaggi invece di 4
- 🎯 **Più semplice** - Proposta diretta della latest
- 🔄 **Flessibile** - Opzione di vedere tutte le versioni

### Per utenti con multiple installazioni:
- ✅ **Nessun cambiamento** - Comportamento identico a prima
- 📊 **Controllo completo** - Scelta dettagliata tra tutte le versioni

---

## 📖 Documentazione Aggiornata

- ✅ `UPGRADE_COMMAND.md` - Aggiunta sezione modalità singola/multipla
- ✅ `IMPLEMENTAZIONE_UPGRADE.md` - Aggiornato con nuovi esempi
- ✅ `test-upgrade-behavior.ps1` - Nuovo script per visualizzare comportamento

---

## ✨ Stato

**COMPLETATO E TESTATO**

Lo script è pronto all'uso e gestisce correttamente entrambi i casi.
