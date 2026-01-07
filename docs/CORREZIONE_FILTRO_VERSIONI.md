# Correzione Filtro Versioni - Upgrade/Downgrade

## Problema identificato

Il filtro delle versioni per upgrade/downgrade funzionava solo a livello di **major release**, non a livello di **versione completa**.

### Comportamento errato

**Esempio con versione corrente: `10.16.1`**

- **Upgrade** mostrava tutte le versioni `>= 10.x`, includendo:
  - ✅ `10.16.3`, `10.16.2` (corretto - versioni superiori)
  - ❌ `10.16.1` (errato - versione corrente)
  - ❌ `10.16.0`, `10.15.3` (errato - versioni inferiori)

- **Downgrade** mostrava TUTTE le versioni di tutte le major (nessun filtro)

### Comportamento corretto richiesto

**Upgrade** deve mostrare solo versioni **strettamente superiori** (`> currentVersion`):
- Da `10.16.1` → mostra `10.16.2`, `10.16.3`, `10.17.0`, ...

**Downgrade** deve mostrare solo versioni **strettamente inferiori** (`< currentVersion`):
- Da `10.16.1` → mostra `10.16.0`, `10.15.3`, `10.15.2`, ...

## Soluzione implementata

### 1. Funzione di confronto versioni semantiche

Aggiunta funzione helper per confrontare versioni complete (major.minor.patch):

**`lib/upgrade.ps1`:**
```powershell
function Compare-SemanticVersion {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    $v1Parts = $Version1 -split '\.' | ForEach-Object { [int]$_ }
    $v2Parts = $Version2 -split '\.' | ForEach-Object { [int]$_ }
    
    for ($i = 0; $i -lt [Math]::Max($v1Parts.Count, $v2Parts.Count); $i++) {
        $v1Part = if ($i -lt $v1Parts.Count) { $v1Parts[$i] } else { 0 }
        $v2Part = if ($i -lt $v2Parts.Count) { $v2Parts[$i] } else { 0 }
        
        if ($v1Part -lt $v2Part) { return -1 }
        if ($v1Part -gt $v2Part) { return 1 }
    }
    
    return 0  # Versioni uguali
}
```

**Ritorna:**
- `-1` se `Version1 < Version2`
- `0` se `Version1 == Version2`
- `1` se `Version1 > Version2`

### 2. Modifica `Get-VersionsByMajor` (upgrade)

**Prima:**
```powershell
function Get-VersionsByMajor {
    param(
        [array]$RemoteVersions,
        [switch]$OnlyUpgrade,
        [int]$CurrentMajor  # ← Solo major
    )
    
    # Filtrava solo major >= currentMajor
    if ($OnlyUpgrade -and $major -lt $CurrentMajor) {
        continue
    }
}
```

**Dopo:**
```powershell
function Get-VersionsByMajor {
    param(
        [array]$RemoteVersions,
        [string]$CurrentVersion,  # ← Versione completa
        [switch]$OnlyUpgrade
    )
    
    foreach ($version in $RemoteVersions) {
        $versionNumber = $version.version -replace '^v', ''
        
        # Filtra solo versioni > corrente (confronto completo)
        if ($OnlyUpgrade) {
            $comparison = Compare-SemanticVersion -Version1 $versionNumber -Version2 $CurrentVersion
            if ($comparison -le 0) {
                # Skip versioni <= corrente
                continue
            }
        }
        
        # Aggiungi a hashtable...
    }
}
```

### 3. Modifica `Get-VersionsByMajorForDowngrade` (downgrade)

**Prima:**
```powershell
function Get-VersionsByMajorForDowngrade {
    param(
        [array]$RemoteVersions
        # Nessun filtro - mostrava TUTTE le versioni
    )
}
```

**Dopo:**
```powershell
function Get-VersionsByMajorForDowngrade {
    param(
        [array]$RemoteVersions,
        [string]$CurrentVersion  # ← Versione completa
    )
    
    foreach ($version in $RemoteVersions) {
        $versionNumber = $version.version -replace '^v', ''
        
        # Filtra solo versioni < corrente (confronto completo)
        $comparison = Compare-SemanticVersionForDowngrade -Version1 $versionNumber -Version2 $CurrentVersion
        if ($comparison -ge 0) {
            # Skip versioni >= corrente
            continue
        }
        
        # Aggiungi a hashtable...
    }
}
```

### 4. Aggiornamento chiamate

**`Select-MajorRelease` (upgrade.ps1):**
```powershell
# Prima
$versionsByMajor = Get-VersionsByMajor -RemoteVersions $RemoteVersions -OnlyUpgrade:$OnlyUpgrade -CurrentMajor $currentMajor

# Dopo
$versionsByMajor = Get-VersionsByMajor -RemoteVersions $RemoteVersions -CurrentVersion $CurrentVersion -OnlyUpgrade:$OnlyUpgrade
```

**`Select-MajorReleaseForDowngrade` (downgrade.ps1):**
```powershell
# Prima
$versionsByMajor = Get-VersionsByMajorForDowngrade -RemoteVersions $RemoteVersions

# Dopo
$versionsByMajor = Get-VersionsByMajorForDowngrade -RemoteVersions $RemoteVersions -CurrentVersion $CurrentVersion
```

## Testing

### Test unitario - `tests/test-version-filter.ps1`

```powershell
# Versione corrente: 10.16.1
# Versioni mock: 10.16.3, 10.16.2, 10.16.1, 10.16.0, 10.15.3, 10.15.2

# UPGRADE: Deve mostrare solo 10.16.2, 10.16.3
# DOWNGRADE: Deve mostrare solo 10.16.0, 10.15.3, 10.15.2

# Risultato: ✓ TEST PASSATO!
```

### Test completo - `tests/test-upgrade-downgrade.ps1`

```
[Test 7] Struttura Get-VersionsByMajor...
  ✓ Funzione Compare-SemanticVersion presente
  ✓ Get-VersionsByMajor ha parametri corretti
  ✓ Get-VersionsByMajor filtra versioni > corrente

[Test 8] Struttura Get-VersionsByMajorForDowngrade...
  ✓ Funzione Compare-SemanticVersionForDowngrade presente
  ✓ Downgrade NON ha parametro OnlyUpgrade
  ✓ Get-VersionsByMajorForDowngrade ha parametri corretti
  ✓ Downgrade filtra versioni < corrente (skip >= 0)

TUTTI I TEST PASSATI! ✓
```

## Esempi pratici

### Esempio 1: Versione corrente `10.16.1`

**Prima della correzione:**

```
Upgrade:   10.x (tutte), 12.x, 14.x, ...
           ↑ Include 10.16.1, 10.16.0 (errato)

Downgrade: Tutte le major (0.x, 4.x, 6.x, 8.x, 10.x, ...)
           ↑ Include 10.16.1, 10.16.2, 10.16.3 (errato)
```

**Dopo la correzione:**

```
Upgrade:   10.16.2, 10.16.3, 10.17.0, ..., 12.x, 14.x, ...
           ↑ Solo versioni > 10.16.1

Downgrade: 10.16.0, 10.15.3, ..., 8.x, 6.x, ...
           ↑ Solo versioni < 10.16.1
```

### Esempio 2: Versione corrente `20.11.0`

**Upgrade mostra:**
- `20.11.1`, `20.12.0`, `20.13.0`, ...
- `22.x` (tutte)
- `23.x`, `24.x`, ...

**Downgrade mostra:**
- `20.10.0`, `20.9.0`, ...
- `18.x` (tutte)
- `16.x`, `14.x`, ...

### Esempio 3: Versione corrente `25.1.0` (latest)

**Upgrade mostra:**
- Nessuna versione (sei già alla più recente)
- Messaggio: "Non ci sono versioni più recenti disponibili per l'upgrade."

**Downgrade mostra:**
- `25.0.0`, `24.x`, `23.x`, ...
- Tutte le versioni precedenti

## File modificati

```
Modified:
  lib/upgrade.ps1
    + Compare-SemanticVersion (linee 7-26)
    ~ Get-VersionsByMajor (parametro CurrentVersion invece di CurrentMajor)
    ~ Select-MajorRelease (chiamata aggiornata)

  lib/downgrade.ps1
    + Compare-SemanticVersionForDowngrade (linee 7-26)
    ~ Get-VersionsByMajorForDowngrade (aggiunto filtro < currentVersion)
    ~ Select-MajorReleaseForDowngrade (chiamata aggiornata)

  tests/test-upgrade-downgrade.ps1
    ~ Test 7 e 8 aggiornati per nuova logica

Created:
  tests/test-version-filter.ps1 (test unitario filtro)
  docs/CORREZIONE_FILTRO_VERSIONI.md (questo documento)
```

## Breaking changes

**Nessuna breaking change per l'utente finale:**
- ✅ Interfaccia comandi invariata
- ✅ Comportamento UX migliorato (mostra solo versioni rilevanti)
- ✅ Test automatici aggiornati e passati

**Cambiamenti interni (API):**
- ⚠️ Firma `Get-VersionsByMajor` cambiata (parametro `CurrentVersion` invece di `CurrentMajor`)
- ⚠️ Firma `Get-VersionsByMajorForDowngrade` cambiata (aggiunto parametro `CurrentVersion`)

## Conclusione

Il filtro ora funziona correttamente a livello di **versione completa** (major.minor.patch), non solo major:

- **Upgrade:** Mostra solo versioni `> currentVersion` (strettamente superiori)
- **Downgrade:** Mostra solo versioni `< currentVersion` (strettamente inferiori)

**Benefici:**
- ✅ Precisione: nessuna versione uguale o irrilevante mostrata
- ✅ UX migliorata: liste più corte e focalizzate
- ✅ Logica corretta: segue semantica upgrade/downgrade standard
