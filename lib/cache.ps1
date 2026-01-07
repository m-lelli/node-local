# =============================================================================
# cache.ps1 - Gestione cache locale versioni Node.js
# =============================================================================
# Sistema di cache per velocizzare installazioni e supportare installazioni offline

# Path cache (Script-scope, condiviso con altri moduli)
$Script:CachePath = Join-Path $Script:AppDataPath "cache"

# =============================================================================
# FUNZIONI CACHE
# =============================================================================

function Initialize-CacheDirectory {
    <#
    .SYNOPSIS
    Inizializza la directory cache se non esiste
    #>
    
    if (-not (Test-Path $Script:CachePath)) {
        New-Item -ItemType Directory -Path $Script:CachePath -Force | Out-Null
    }
}

function Get-CachedVersion {
    <#
    .SYNOPSIS
    Verifica se una versione è presente in cache e restituisce il path
    
    .PARAMETER Version
    Versione Node.js da cercare (es: "20.11.0")
    
    .OUTPUTS
    Path al file ZIP in cache, o $null se non trovato
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Version
    )
    
    Initialize-CacheDirectory
    
    # Rimuovi 'v' prefix se presente
    $cleanVersion = $Version -replace '^v', ''
    
    # Nome file ZIP in cache
    $zipFileName = "node-v$cleanVersion-win-x64.zip"
    $cachedZipPath = Join-Path $Script:CachePath $zipFileName
    
    if (Test-Path $cachedZipPath) {
        # Verifica che il file non sia corrotto (dimensione minima 20MB)
        $fileInfo = Get-Item $cachedZipPath
        if ($fileInfo.Length -gt 20MB) {
            return $cachedZipPath
        } else {
            Write-Host "  ⚠️  File cache corrotto (troppo piccolo), verra riscaricato" -ForegroundColor Yellow
            Remove-Item $cachedZipPath -Force -ErrorAction SilentlyContinue
            return $null
        }
    }
    
    return $null
}

function Save-ToCache {
    <#
    .SYNOPSIS
    Salva una copia del file ZIP scaricato nella cache
    
    .PARAMETER SourcePath
    Path del file ZIP scaricato
    
    .PARAMETER Version
    Versione Node.js (es: "20.11.0")
    
    .PARAMETER Message
    Messaggio da mostrare durante la copia (opzionale)
    
    .OUTPUTS
    $true se salvato con successo, $false altrimenti
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Version,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = $null
    )
    
    try {
        Initialize-CacheDirectory
        
        # Usa il nome del file originale (include già arch corretta)
        $zipFileName = [System.IO.Path]::GetFileName($SourcePath)
        $cachedZipPath = Join-Path $Script:CachePath $zipFileName
        
        # Copia file in cache con spinner
        $copySuccess = Copy-FileWithProgress `
            -SourcePath $SourcePath `
            -DestinationPath $cachedZipPath `
            -Message $Message
        
        return $copySuccess
    }
    catch {
        return $false
    }
}

function Get-CacheInfo {
    <#
    .SYNOPSIS
    Ottiene informazioni su tutte le versioni in cache
    
    .OUTPUTS
    Array di oggetti con: Version, FileName, Size, LastAccess
    #>
    
    Initialize-CacheDirectory
    
    $cacheFiles = Get-ChildItem -Path $Script:CachePath -Filter "node-v*.zip" -ErrorAction SilentlyContinue
    
    if (-not $cacheFiles) {
        return @()
    }
    
    $cacheInfo = @()
    
    foreach ($file in $cacheFiles) {
        # Estrai versione dal nome file: node-v20.11.0-win-x64.zip
        if ($file.Name -match 'node-v(\d+\.\d+\.\d+)-win-x64\.zip') {
            $version = $matches[1]
            
            $cacheInfo += [PSCustomObject]@{
                Version = $version
                FileName = $file.Name
                SizeMB = [math]::Round($file.Length / 1MB, 2)
                LastAccess = $file.LastAccessTime
                Path = $file.FullName
            }
        }
    }
    
    return $cacheInfo | Sort-Object -Property Version -Descending
}

function Show-CacheStatus {
    <#
    .SYNOPSIS
    Mostra lo stato della cache
    #>
    
    Write-Host ""
    Write-Host "=== Gestione Cache ===" -ForegroundColor Cyan
    Write-Host ""
    
    $cacheInfo = Get-CacheInfo
    
    if ($cacheInfo.Count -eq 0) {
        Write-Host "Cache vuota - Nessuna versione salvata localmente." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Le versioni vengono salvate automaticamente in cache durante l'installazione." -ForegroundColor Gray
        Write-Host "Path cache: $Script:CachePath" -ForegroundColor Gray
        return
    }
    
    # Calcola dimensione totale
    $totalSizeMB = ($cacheInfo | Measure-Object -Property SizeMB -Sum).Sum
    
    Write-Host "Versioni in cache: $($cacheInfo.Count)" -ForegroundColor White
    Write-Host "Spazio occupato: $([math]::Round($totalSizeMB, 2)) MB" -ForegroundColor White
    Write-Host "Path: $Script:CachePath" -ForegroundColor Gray
    Write-Host ""
    
    # Tabella versioni
    Write-Host "  # ".PadRight(6) -NoNewline -ForegroundColor Cyan
    Write-Host "Versione".PadRight(15) -NoNewline -ForegroundColor Cyan
    Write-Host "Dimensione".PadRight(15) -NoNewline -ForegroundColor Cyan
    Write-Host "Ultimo accesso" -ForegroundColor Cyan
    
    $index = 1
    foreach ($item in $cacheInfo) {
        $indexStr = "[$index]".PadRight(6)
        $versionStr = "v$($item.Version)".PadRight(15)
        $sizeStr = "$($item.SizeMB) MB".PadRight(15)
        $dateStr = $item.LastAccess.ToString("dd/MM/yyyy HH:mm")
        
        Write-Host "  $indexStr" -NoNewline -ForegroundColor White
        Write-Host "$versionStr" -NoNewline -ForegroundColor Green
        Write-Host "$sizeStr" -NoNewline -ForegroundColor Yellow
        Write-Host "$dateStr" -ForegroundColor Gray
        
        $index++
    }
}

function Clear-Cache {
    <#
    .SYNOPSIS
    Menu interattivo per pulire la cache
    #>
    
    Show-CacheStatus
    
    $cacheInfo = Get-CacheInfo
    
    if ($cacheInfo.Count -eq 0) {
        return
    }
    
    Write-Host ""
    Write-Host "Azioni disponibili:" -ForegroundColor Yellow
    Write-Host "  [numero]    Elimina versione specifica" -ForegroundColor White
    Write-Host "  [all]       Elimina tutte le versioni" -ForegroundColor White
    Write-Host "  [q]         Annulla e torna indietro" -ForegroundColor White
    Write-Host ""
    Write-Host "Digita la tua scelta: " -ForegroundColor Cyan -NoNewline
    
    $choice = Read-Host
    
    if ($choice -eq 'q' -or $choice -eq 'Q') {
        Write-Host "`nOperazione annullata." -ForegroundColor Yellow
        return
    }
    
    if ($choice -eq 'all' -or $choice -eq 'ALL') {
        Write-Host ""
        Write-Host "⚠️  ATTENZIONE: Stai per eliminare TUTTE le versioni in cache!" -ForegroundColor Yellow
        Write-Host "   Spazio da liberare: $([math]::Round(($cacheInfo | Measure-Object -Property SizeMB -Sum).Sum, 2)) MB" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Confermi eliminazione? [s/n]: " -ForegroundColor Red -NoNewline
        
        $confirm = Read-Host
        
        if ($confirm -ne 's' -and $confirm -ne 'S') {
            Write-Host "`nOperazione annullata." -ForegroundColor Yellow
            return
        }
        
        Write-Host ""
        Write-Host "Eliminazione cache in corso..." -ForegroundColor Yellow
        
        $deletedCount = 0
        foreach ($item in $cacheInfo) {
            try {
                Remove-Item -Path $item.Path -Force -ErrorAction Stop
                Write-Host "  [OK] v$($item.Version) eliminata" -ForegroundColor Green
                $deletedCount++
            }
            catch {
                Write-Host "  [ERRORE] Impossibile eliminare v$($item.Version): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Easter Egg - Thanos per eliminazione intera cache!
        Show-ThanosSnap
        
        Write-Host "Cache pulita: $deletedCount/$($cacheInfo.Count) versioni eliminate." -ForegroundColor Green
        return
    }
    
    # Elimina versione specifica
    $selectedIndex = $null
    if ([int]::TryParse($choice, [ref]$selectedIndex)) {
        if ($selectedIndex -lt 1 -or $selectedIndex -gt $cacheInfo.Count) {
            Write-Host "`nErrore: Selezione non valida." -ForegroundColor Red
            return
        }
        
        $selectedItem = $cacheInfo[$selectedIndex - 1]
        
        Write-Host ""
        Write-Host "Elimino v$($selectedItem.Version) dalla cache ($($selectedItem.SizeMB) MB)..." -ForegroundColor Yellow
        
        try {
            Remove-Item -Path $selectedItem.Path -Force -ErrorAction Stop
            
            # Easter Egg - Thanos per eliminazione singola versione!
            Show-ThanosSnap
            
            Write-Host "[OK] Versione v$($selectedItem.Version) eliminata dalla cache." -ForegroundColor Green
        }
        catch {
            Write-Host "[ERRORE] Impossibile eliminare: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`nErrore: Input non valido." -ForegroundColor Red
    }
}
