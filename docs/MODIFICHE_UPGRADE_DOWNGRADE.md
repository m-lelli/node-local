# Modifiche Upgrade/Downgrade - Flusso Two-Step

## Riepilogo modifiche

Data: 2025-01-XX

### Obiettivi raggiunti

1. ✅ **Upgrade refactoring**: Cambio da one-step a **two-step flow**
   - Prima: Mostrava tutte le versioni organizzate per major con indici numerici continui
   - Dopo: Step 1 = selezione major release, Step 2 = selezione subversion dalla major scelta

2. ✅ **Nuovo comando downgrade**: Stessa logica di upgrade ma **senza limitazioni**
   - Permette di passare a versioni precedenti (es: da 20.x a 18.x)
   - Nessun filtro `>= currentMajor`
   - Nessuna proposta "latest" (sempre two-step)

## File modificati

### 1. `lib/upgrade.ps1` (REFACTORED)

**Prima (one-step):**
```powershell
Show-VersionsByMajor         # Mostrava TUTTE le versioni con indici 1,2,3...
Select-UpgradeVersion        # Prompt per numero versione
Start-NodeUpgrade           # Chiamava Show-VersionsByMajor, poi Select-UpgradeVersion
```

**Dopo (two-step):**
```powershell
Get-VersionsByMajor          # Helper per raggruppare versioni (con filtro OnlyUpgrade)
Select-MajorRelease          # STEP 1: Menu major releases (18.x, 20.x, 22.x...)
Select-VersionFromMajor      # STEP 2: Menu versioni dalla major scelta
Select-InstallationToUpgrade # Invariato (scelta installazione se multiple)
Start-NodeUpgrade           # Orchestrazione con two-step flow
```

**Funzionalità preservate:**
- ✅ Proposta "latest" per singola installazione (upgrade rapido)
- ✅ Filtro versioni >= corrente (solo upgrade forward, no downgrade)
- ✅ LTS badge e colori

**Cambio logico principale:**
```powershell
# PRIMA: Mostra tutto insieme
$versionMap = Show-VersionsByMajor -CurrentVersion $version -RemoteVersions $remote
$selected = Select-UpgradeVersion -VersionMap $versionMap

# DOPO: Two-step
$majorSelection = Select-MajorRelease -CurrentVersion $version -RemoteVersions $remote -OnlyUpgrade
$selected = Select-VersionFromMajor -Major $majorSelection.Major -Versions $majorSelection.Versions
```

### 2. `lib/downgrade.ps1` (NUOVO)

Basato su `upgrade.ps1` ma con differenze chiave:

| Funzione upgrade.ps1 | Funzione downgrade.ps1 | Differenza |
|----------------------|------------------------|------------|
| `Get-VersionsByMajor` | `Get-VersionsByMajorForDowngrade` | **Nessun parametro `OnlyUpgrade`** - accetta tutte le major |
| `Select-MajorRelease` | `Select-MajorReleaseForDowngrade` | **Nessun filtro `>= currentMajor`** |
| `Select-VersionFromMajor` | `Select-VersionFromMajorForDowngrade` | Identica, ma separata per chiarezza |
| `Select-InstallationToUpgrade` | `Select-InstallationToDowngrade` | Testo diverso ("Downgrade" invece di "Upgrade") |
| `Start-NodeUpgrade` | `Start-NodeDowngrade` | **No proposta "latest"** - sempre two-step |

**Logica Start-NodeDowngrade:**
```powershell
# Sempre two-step, senza fast-track "latest"
$majorSelection = Select-MajorReleaseForDowngrade -CurrentVersion $version -RemoteVersions $remote
$selected = Select-VersionFromMajorForDowngrade -Major $majorSelection.Major -Versions $majorSelection.Versions

# Poi: rimuovi installazione corrente + installa nuova versione
```

### 3. `node-local.ps1` (AGGIUNTO ROUTING)

```powershell
# Caricamento moduli
. "$ScriptRoot\lib\downgrade.ps1"

# Routing comando
switch ($Command.ToLower()) {
    "downgrade" {
        Start-NodeDowngrade
    }
}
```

### 4. `lib/ui.ps1` (AGGIUNTO HELP)

```powershell
Write-Host "  node-local downgrade" -ForegroundColor White
Write-Host "    Cambia un'installazione a una versione diversa (anche precedente)" -ForegroundColor Gray
Write-Host "    Funziona come upgrade ma senza limitazioni sulla versione target" -ForegroundColor Gray
Write-Host "    Puoi passare da Node.js 20.x a 18.x, 10.x, ecc." -ForegroundColor Gray
```

### 5. `tests/test-upgrade-downgrade.ps1` (NUOVO)

Test automatici per verificare:
- ✅ Caricamento moduli upgrade.ps1 e downgrade.ps1
- ✅ Presenza di tutte le funzioni richieste
- ✅ Sintassi PowerShell corretta
- ✅ Parametro `OnlyUpgrade` presente in upgrade, assente in downgrade
- ✅ Flusso two-step in entrambi (chiamate a `Select-MajorRelease*` + `Select-VersionFrom*`)
- ✅ Help aggiornato con entrambi i comandi

### 6. `docs/DOWNGRADE_COMMAND.md` (NUOVO)

Documentazione completa per il comando downgrade:
- Panoramica e sintassi
- Flusso interattivo dettagliato (two-step)
- Differenze tra upgrade e downgrade (tabella comparativa)
- Casi d'uso comuni
- Comportamento (rimozione, duplicati, ripristino)
- Architettura tecnica (funzioni e integrazione)
- Testing (automatico e manuale)
- Best practice e limitazioni

## UX Comparison

### Upgrade (before)
```
Versione corrente: v20.11.0 (Node.js 20.x)
────────────────────────────────────────────────────────────────────────────────

▼ Node.js 22.x
  [1]    v22.13.1         [LTS: jod]
  [2]    v22.13.0         [LTS: jod]
  ...

▼ Node.js 21.x
  [11]   v21.7.3
  [12]   v21.7.2
  ...

▼ Node.js 20.x (versione corrente)
  [25]   v20.11.0         ← versione corrente
  ...

Digita il numero della versione da installare (o 'q' per uscire):
```

**Problemi:** 
- Troppi numeri (potenzialmente 100+)
- Difficile trovare versione specifica
- Scroll lungo per esplorare

### Upgrade (after) - Two-step

**Step 1:**
```
Seleziona la major release:

  [1]    Node.js 22.x         67 versioni disponibili [LTS: jod]
  [2]    Node.js 21.x         89 versioni disponibili
  [3]    Node.js 20.x         125 versioni disponibili [LTS: iron] ← corrente

Digita il numero della major release (o 'q' per uscire):
```

**Step 2 (dopo selezione [1]):**
```
──── Node.js 22.x - Versioni disponibili ──────────────────────────────────────

  [1]    v22.13.1         [LTS: jod]
  [2]    v22.13.0         [LTS: jod]
  [3]    v22.12.0         [LTS: jod]
  ...

Digita il numero della versione (o 'q' per uscire):
```

**Vantaggi:**
- ✅ Massimo 10-20 opzioni per schermata
- ✅ Navigazione intuitiva (categoria → dettaglio)
- ✅ Informazioni aggregate (conta versioni, LTS name)
- ✅ Possibilità di tornare indietro ('q')

### Downgrade - Same two-step, no filter

**Differenza chiave:** Step 1 mostra **TUTTE** le major (anche precedenti):

```
Seleziona la major release:

  [1]    Node.js 23.x         45 versioni disponibili
  [2]    Node.js 22.x         67 versioni disponibili [LTS: jod]
  [3]    Node.js 21.x         89 versioni disponibili
  [4]    Node.js 20.x         125 versioni disponibili [LTS: iron] ← corrente
  [5]    Node.js 18.x         156 versioni disponibili [LTS: hydrogen]
  [6]    Node.js 16.x         104 versioni disponibili [LTS: gallium]
  [7]    Node.js 14.x         93 versioni disponibili
  ...
```

Puoi selezionare [5] per passare a 18.x, [6] per 16.x, ecc.

## Codice chiave - Get-VersionsByMajor

```powershell
# UPGRADE: Con filtro
function Get-VersionsByMajor {
    param(
        [array]$RemoteVersions,
        [switch]$OnlyUpgrade,    # ← PARAMETRO CHIAVE
        [int]$CurrentMajor
    )
    
    $versionsByMajor = @{}
    foreach ($version in $RemoteVersions) {
        $major = [int]($version.version -replace '^v', '' -split '\.')[0]
        
        # Filtra solo major >= corrente se OnlyUpgrade
        if ($OnlyUpgrade -and $major -lt $CurrentMajor) {
            continue  # ← SKIP versioni precedenti
        }
        
        # Aggiungi a hashtable...
    }
    return $versionsByMajor
}
```

```powershell
# DOWNGRADE: Senza filtro
function Get-VersionsByMajorForDowngrade {
    param(
        [array]$RemoteVersions
        # ← NESSUN PARAMETRO OnlyUpgrade
    )
    
    $versionsByMajor = @{}
    foreach ($version in $RemoteVersions) {
        $major = [int]($version.version -replace '^v', '' -split '\.')[0]
        
        # NESSUN FILTRO - accetta tutte le major
        
        # Aggiungi a hashtable...
    }
    return $versionsByMajor
}
```

## Testing results

```
=== Test Upgrade e Downgrade ===

[Test 1] Caricamento moduli...                    ✓
[Test 2] Funzioni upgrade...                      ✓ (5/5)
[Test 3] Funzioni downgrade...                    ✓ (5/5)
[Test 4] Sintassi upgrade.ps1...                  ✓
[Test 5] Sintassi downgrade.ps1...                ✓
[Test 6] Help comandi...                          ✓
[Test 7] Struttura Get-VersionsByMajor...         ✓ (OnlyUpgrade presente)
[Test 8] Struttura Get-VersionsByMajorForDowngrade... ✓ (OnlyUpgrade assente)
[Test 9] Flusso two-step in upgrade...            ✓
[Test 10] Flusso two-step in downgrade...         ✓

TUTTI I TEST PASSATI! ✓
```

## Backwards compatibility

✅ **Nessuna breaking change:**
- Comandi esistenti (`install`, `use`, `remove`, `list`, ecc.) invariati
- `upgrade` ancora disponibile e funzionale (comportamento migliorato)
- Sintassi comandi invariata
- Template proxy non modificati

✅ **Nuove funzionalità additive:**
- `upgrade` ora più user-friendly (two-step)
- Nuovo comando `downgrade` per casi d'uso precedentemente impossibili

## Prossimi passi (opzionali)

**Possibili miglioramenti futuri:**
1. [ ] Comando `rollback` - torna alla versione precedente senza menu (storia versioni)
2. [ ] Backup automatico pacchetti globali prima di upgrade/downgrade
3. [ ] Flag `--yes` per skip conferma (automation-friendly)
4. [ ] Mostrare diff pacchetti globali tra versione corrente e target
5. [ ] Cache remoteVersions per evitare download ripetuti
6. [ ] Filtro per EOL versions (nascondi versioni fuori supporto)

## Files created/modified summary

```
Modified:
  lib/upgrade.ps1              (refactor: one-step → two-step)
  node-local.ps1               (add: downgrade routing)
  lib/ui.ps1                   (add: downgrade help)

Created:
  lib/downgrade.ps1            (412 lines, complete module)
  tests/test-upgrade-downgrade.ps1 (225 lines, 10 test cases)
  docs/DOWNGRADE_COMMAND.md    (370 lines, full documentation)
  docs/MODIFICHE_UPGRADE_DOWNGRADE.md (this file)

Backup:
  lib/upgrade.ps1.backup       (original one-step version)
```

## Migration notes

**Per utenti esistenti:**
- Nessuna azione richiesta
- `upgrade` continua a funzionare (UX migliorata)
- Nuovo comando `downgrade` disponibile per nuovi use case

**Per sviluppatori/contributori:**
- `Show-VersionsByMajor` rimosso - ora split in `Get-VersionsByMajor` + `Select-MajorRelease` + `Select-VersionFromMajor`
- `Select-UpgradeVersion` rimosso - sostituito da `Select-VersionFromMajor`
- Nuovi parametri: `-OnlyUpgrade` switch in `Get-VersionsByMajor`
- Pattern riutilizzabile per futuri comandi simili (es: `switch-version`)

## References

- [UPGRADE_COMMAND.md](./UPGRADE_COMMAND.md) - Documentazione comando upgrade
- [DOWNGRADE_COMMAND.md](./DOWNGRADE_COMMAND.md) - Documentazione comando downgrade
- [IMPLEMENTAZIONE_UPGRADE.md](./IMPLEMENTAZIONE_UPGRADE.md) - Dettagli tecnici implementazione
- [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md) - Struttura progetto e convenzioni
