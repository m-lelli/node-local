# =============================================================================
# remote.ps1 - Gestione versioni remote di Node.js
# =============================================================================
# Funzioni per interrogare l'API di nodejs.org e visualizzare versioni disponibili

# Ottiene la lista delle versioni disponibili dall'API di nodejs.org
# NOTA: Questa funzione è mantenuta per retrocompatibilità
# Preferire $installations.getAllRemote() per nuovi sviluppi
function Get-RemoteVersions {
    try {
        Write-Host "Scaricando lista versioni da nodejs.org..." -ForegroundColor Yellow
        
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "node-local/1.0")
        
        $jsonData = $webClient.DownloadString("https://nodejs.org/dist/index.json")
        $versions = $jsonData | ConvertFrom-Json
        
        return $versions
    }
    catch [System.Net.WebException] {
        Write-Host "`nErrore: Impossibile scaricare la lista delle versioni." -ForegroundColor Red
        Write-Host "Verifica la connessione internet e riprova." -ForegroundColor Yellow
        return $null
    }
    catch {
        Write-Host "`nErrore: Problema durante il parsing delle versioni: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
    finally {
        if ($webClient) {
            $webClient.Dispose()
        }
    }
}

# Ottiene l'ultima versione disponibile (o l'ultima LTS se specificato)
function Get-LatestVersion {
    param(
        [switch]$LtsOnly
    )
    
    try {
        $limit = 1
        $inst = [Installations]::new()
        $remoteVersions = $inst.getAllRemote($limit, $LtsOnly)
        
        if ($remoteVersions -and $remoteVersions.Count -gt 0) {
            return $remoteVersions[0].version
        }
        
        return $null
    }
    catch [System.Net.WebException] {
        Write-ErrorMessage `
            -Message "Impossibile scaricare la lista delle versioni" `
            -Hint "Verifica la connessione internet e riprova"
        return $null
    }
    catch {
        Write-ErrorMessage `
            -Message "Errore durante il recupero delle versioni: $($_.Exception.Message)"
        return $null
    }
}

# Mostra la lista delle versioni remote disponibili in formato tabellare
# Refactoring: usa $installations.getAllRemote() invece di Get-RemoteVersions
function Show-RemoteVersionList {
    param(
        [int]$Limit = 20,
        [switch]$LtsOnly,
        [switch]$All
    )
    
    Write-InfoMessage "Scaricando lista versioni da nodejs.org..."
    
    try {
        # Determina il limite (0 = tutte)
        $queryLimit = if ($All) { 0 } else { $Limit }
        
        # Usa la classe Installations per ottenere le versioni remote
        $inst = [Installations]::new()
        $remoteVersions = $inst.getAllRemote($queryLimit, $LtsOnly)
        
        if (-not $remoteVersions -or $remoteVersions.Count -eq 0) {
            Write-WarningMessage "Nessuna versione disponibile"
            return
        }
    }
    catch [System.Net.WebException] {
        Write-Host ""
        Write-ErrorMessage `
            -Message "Impossibile scaricare la lista delle versioni" `
            -Hint "Verifica la connessione internet e riprova"
        return
    }
    catch {
        Write-Host ""
        Write-ErrorMessage `
            -Message "Errore durante il parsing delle versioni: $($_.Exception.Message)"
        return
    }
    
    Write-SuccessMessage "Versioni Node.js disponibili:"
    
    if ($LtsOnly) {
        Write-InfoMessage "(Solo versioni LTS)"
    }
    
    # Header della tabella
    Write-TableHeader -Columns @("VERSIONE", "CACHE", "USE", "ALIAS", "NOTE") -Widths @(17, 7, 6, 31, 40)
    
    foreach ($ver in $remoteVersions) {
        # Colonna VERSIONE
        $versionFormatted = $ver.version
        
        # Colonna CACHE
        $cacheFormatted = if ($ver.downloaded) { "YES" } else { "NO" }
        
        # Colonna USE
        $useFormatted = if ($ver.use) { "YES" } else { "NO" }
        
        # Colonna ALIAS (usa il metodo della classe)
        $aliasText = $ver.getAliasesLabel()
        # Tronca se troppo lungo
        if ($aliasText.Length -gt 30) {
            $aliasText = $aliasText.Substring(0, 27) + "..."
        }
        # Se vuoto, metti uno spazio (Write-TableHeader non accetta stringhe vuote)
        if ([string]::IsNullOrEmpty($aliasText)) { $aliasText = " " }
        
        # Colonna NOTE (usa il metodo della classe)
        $noteText = $ver.getNotesLabel()
        # Se vuoto, metti uno spazio
        if ([string]::IsNullOrEmpty($noteText)) { $noteText = " " }
        
        # Determina il colore della riga
        $color = "White"
        if ($ver.use) {
            $color = "Green"  # Versione in uso
        } elseif ($ver.downloaded) {
            $color = "Yellow"  # Versione scaricata ma non in uso
        } elseif ($ver.current -or $ver.lts) {
            $color = "Cyan"   # Versione importante (current/LTS)
        }
        
        Write-TableHeader -Columns @($versionFormatted, $cacheFormatted, $useFormatted, $aliasText, $noteText) -Widths @(17, 7, 6, 31, 40) -Header $false -Color $color
    }
    
    if (-not $All -and $remoteVersions.Count -eq $Limit) {
        Write-InfoMessage "Sto mostrando le prime $Limit versioni. Usa 'node-local list-remote --all' per vedere tutte."
    }

    ListRemote-Usage-Example
}