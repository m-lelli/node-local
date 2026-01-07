# Comando `downgrade` - Documentazione

## Panoramica

Il comando `downgrade` permette di cambiare un'installazione Node.js esistente a una versione diversa, incluse versioni precedenti. Funziona come `upgrade` ma **senza limitazioni** sulla versione target: puoi passare da Node.js 20.x a 18.x, 10.x, o qualsiasi altra versione disponibile.

## Sintassi

```powershell
node-local downgrade
```

Il comando è completamente interattivo - non richiede parametri.

## Flusso Interattivo Two-Step

Il processo di downgrade segue un flusso a **due step** per semplificare la scelta tra centinaia di versioni disponibili:

### Step 1: Selezione installazione
Se hai **multiple installazioni**, ti viene mostrato un menu per scegliere quale modificare:

```
=== Downgrade Node.js ===

Seleziona l'installazione da cambiare versione:

  [1]    sgp                  Node.js 24.11.0
  [2]    new                  Node.js 25.1.0

Digita il numero dell'installazione (o 'q' per uscire):
```

Con **singola installazione**, viene selezionata automaticamente.

### Step 2: Selezione major release
Ti viene mostrato un elenco di **major releases** disponibili (senza filtro - tutte le versioni):

```
Versione corrente: v24.11.0 (Node.js 24.x)
────────────────────────────────────────────────────────────────────────────────

Seleziona la major release:

  [1]    Node.js 23.x         45 versioni disponibili
  [2]    Node.js 22.x         67 versioni disponibili [LTS: jod]
  [3]    Node.js 21.x         89 versioni disponibili
  [4]    Node.js 20.x         125 versioni disponibili [LTS: iron]
  [5]    Node.js 18.x         156 versioni disponibili [LTS: hydrogen]
  [6]    Node.js 16.x         104 versioni disponibili [LTS: gallium]
  ...

Digita il numero della major release (o 'q' per uscire):
```

**Differenza chiave con upgrade:** Mostra **TUTTE** le major releases, non solo quelle >= versione corrente.

### Step 3: Selezione versione specifica
Una volta scelta la major, vedi **tutte le versioni** di quella serie:

```
──── Node.js 18.x - Versioni disponibili ──────────────────────────────────────

  [1]    v18.20.5         [LTS: hydrogen]
  [2]    v18.20.4         [LTS: hydrogen]
  [3]    v18.20.3         [LTS: hydrogen]
  [4]    v18.20.2         [LTS: hydrogen]
  [5]    v18.20.1         [LTS: hydrogen]
  ...

Digita il numero della versione (o 'q' per uscire):
```

### Step 4: Conferma e installazione
Prima di procedere, viene mostrato un riepilogo:

```
────────────────────────────────────────────────────────────────────────────────
RIEPILOGO CAMBIO VERSIONE:
  Installazione: sgp
  Versione attuale: 24.11.0
  Nuova versione: 18.20.5
────────────────────────────────────────────────────────────────────────────────

Vuoi procedere con il cambio versione? [S/n]:
```

## Differenze tra `upgrade` e `downgrade`

| Caratteristica | `upgrade` | `downgrade` |
|----------------|-----------|-------------|
| **Versioni mostrate** | Solo major >= corrente | Tutte le major (anche precedenti) |
| **Proposta "latest"** | Sì (per singola installazione) | No |
| **Casi d'uso** | Aggiornamento alla versione più recente | Tornare a versioni precedenti per compatibilità |
| **Flusso** | Two-step (major → subversion) | Two-step (major → subversion) |

## Casi d'uso comuni

### 1. Tornare a una LTS precedente
Un progetto legacy richiede Node.js 16.x invece della tua 20.x attuale:

```powershell
node-local downgrade
# → Scegli installazione
# → Seleziona "Node.js 16.x"
# → Scegli 16.20.2 (ultima LTS)
```

### 2. Test di compatibilità
Devi verificare che il tuo codice funzioni su Node.js 12:

```powershell
node-local install 20.11.0 --alias test-compat
node-local downgrade
# → Scegli "test-compat"
# → Seleziona "Node.js 12.x"
# → Testa il codice
```

### 3. Rollback dopo problemi
Un aggiornamento ha causato regressioni, vuoi tornare alla versione precedente:

```powershell
node-local downgrade
# → Torna alla major precedente
```

## Comportamento dettagliato

### Rimozione sicura
Prima di installare la nuova versione, l'installazione corrente viene **completamente rimossa**:
- Cartella `%APPDATA%\node-local\versions\<nome>` eliminata
- Pacchetti globali inclusi (verranno reinstallati se necessario)

### Versione duplicata
Se la versione target esiste già in un'altra installazione, ricevi un avviso:

```
ATTENZIONE: Esiste già un'installazione con Node.js 18.20.5
  - project-legacy

Puoi:
  1. Usare quella esistente: node-local use project-legacy
  2. Rimuovere questa e reinstallare: node-local remove sgp && node-local install 18.20.5 --alias sgp

Vuoi comunque sovrascrivere l'installazione 'sgp' con Node.js 18.20.5? [s/N]:
```

### Ripristino versione attiva
Se l'installazione modificata era quella **attiva**, viene **automaticamente ripristinata** come attiva dopo l'installazione:

```
[3/3] Ripristino come versione attiva...
✓ Versione attiva ripristinata
```

In caso contrario, devi attivarla manualmente:

```
Per attivarla, usa:
  node-local use sgp
```

## Architettura tecnica

### Modulo: `lib/downgrade.ps1`

#### Funzioni principali

1. **`Get-VersionsByMajorForDowngrade`**
   - Raggruppa versioni remote per major release
   - **Nessun filtro** su versione corrente (differenza da `upgrade`)

2. **`Select-MajorReleaseForDowngrade`**
   - Menu interattivo per scegliere major release
   - Mostra **tutte** le major senza filtro `>= currentMajor`

3. **`Select-VersionFromMajorForDowngrade`**
   - Menu con tutte le versioni di una major specifica
   - Identico a upgrade, ma per completezza è separato

4. **`Select-InstallationToDowngrade`**
   - Menu per scegliere installazione (se multiple)
   - Identico a upgrade, ma con testo "Downgrade"

5. **`Start-NodeDowngrade`** *(entry point)*
   - Orchestrazione completa del flusso
   - **No proposta "latest"** (vai sempre al two-step)
   - Integrazione con `Install-NodeVersion` da `installation.ps1`

### Integrazione

```powershell
# node-local.ps1
. "$ScriptRoot\lib\downgrade.ps1"

switch ($Command.ToLower()) {
    "downgrade" {
        Start-NodeDowngrade
    }
    ...
}
```

### Help

```powershell
# lib/ui.ps1 - Show-Help
Write-Host "  node-local downgrade" -ForegroundColor White
Write-Host "    Cambia un'installazione a una versione diversa (anche precedente)" -ForegroundColor Gray
Write-Host "    Funziona come upgrade ma senza limitazioni sulla versione target" -ForegroundColor Gray
Write-Host "    Puoi passare da Node.js 20.x a 18.x, 10.x, ecc." -ForegroundColor Gray
```

## Testing

### Test automatici
```powershell
.\tests\test-upgrade-downgrade.ps1
```

Verifica:
- ✅ Caricamento modulo downgrade.ps1
- ✅ Presenza di tutte le funzioni
- ✅ Assenza filtro `OnlyUpgrade` (caratteristica chiave)
- ✅ Sintassi PowerShell corretta
- ✅ Integrazione con node-local.ps1
- ✅ Documentazione in help

### Test manuale
Con due installazioni esistenti:

```powershell
# Setup test
node-local install 20.11.0 --alias test-downgrade
node-local install 18.20.5 --alias test-old

# Test downgrade da 20.11.0 a 16.20.2
node-local downgrade
# → Scegli "test-downgrade" [1]
# → Seleziona "Node.js 16.x" [esempio: 6]
# → Scegli "16.20.2" [esempio: 1]
# → Conferma [S]

# Verifica
node-local list
# test-downgrade dovrebbe mostrare 16.20.2
```

## Backup e sicurezza

⚠️ **Attenzione:** Il downgrade è **distruttivo** - rimuove l'installazione esistente.

**Best practice:**
1. **Backup pacchetti globali** prima del downgrade:
   ```powershell
   nlocal-npm list -g --depth=0 > global-packages-backup.txt
   ```

2. **Usa alias separati** per test:
   ```powershell
   node-local install 20.11.0 --alias production
   node-local install 20.11.0 --alias test-downgrade
   node-local downgrade  # Cambia solo test-downgrade
   ```

3. **Verifica compatibilità** prima del downgrade su installazione di produzione

## Limitazioni note

1. **Nessun backup automatico** dei pacchetti globali
2. **Nessun undo** - una volta confermato, l'installazione vecchia è persa
3. **Richiede connessione internet** per scaricare la versione target
4. **Tempo di download** dipende dalla versione scelta

## Workflow consigliato

Per progetti legacy che richiedono versioni precedenti:

```powershell
# 1. Installa versione corrente con alias specifico
node-local install 20.11.0 --alias my-project

# 2. Esegui downgrade a versione richiesta
node-local downgrade
# → Scegli "my-project"
# → Seleziona major richiesta (es: 14.x)
# → Installa

# 3. Attiva e verifica
node-local use my-project
nlocal-node --version  # dovrebbe mostrare v14.x.x

# 4. Installa dipendenze globali se necessarie
nlocal-npm install -g <package>
```

## File modificati

- ✅ `lib/downgrade.ps1` - Nuovo modulo (412 righe)
- ✅ `node-local.ps1` - Aggiunto routing comando `downgrade`
- ✅ `lib/ui.ps1` - Aggiunto help per comando `downgrade`
- ✅ `tests/test-upgrade-downgrade.ps1` - Test automatici (completati)

## See also

- [UPGRADE_COMMAND.md](./UPGRADE_COMMAND.md) - Documentazione comando `upgrade`
- [IMPLEMENTAZIONE_UPGRADE.md](./IMPLEMENTAZIONE_UPGRADE.md) - Dettagli implementazione upgrade/downgrade
- [../README.md](../README.md#comandi-disponibili) - Lista completa comandi node-local
