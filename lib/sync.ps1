# lib/sync.ps1 - Gestione sincronizzazione proxy e package manager
# Questo modulo fornisce funzioni per sincronizzare comandi globali e gestire package manager

# Carica i label (messaggi centralizzati)
$labelsModule = Join-Path $PSScriptRoot "labels.ps1"
if (Test-Path $labelsModule) {
    . $labelsModule
}

# =============================================================================
# Sincronizzazione Package Manager
# =============================================================================

# Sincronizza i comandi globali dalla versione Node.js attiva
function Sync-GlobalCommands {
    param([switch]$Force)
    
    # Ottieni le installazioni e quella corrente
    $installations = [Installations]::new()
    $installation = $installations.getCurrent()
    
    if (-not $installation) {
        Write-ErrorMessage "Nessuna versione selezionata per la sincronizzazione"
        return
    }
    
    $currentVersion = $installation.getFolderName()
    $currentMode = Get-CurrentMode
    $versionPath = $installation.getPath()
    
    if (-not (Test-Path $versionPath)) {
        Write-ErrorMessage "Versione $currentVersion non trovata"
        return
    }
    
    # Mostra il messaggio iniziale
    Write-InfoMessage (syncMsg $currentVersion $currentMode $Force)
    
    # Crea istanza di Proxies per gestione comandi
    $proxies = [Proxies]::new()
    
    # Se --force, rimuovi TUTTI i comandi e ricrea tutto (onlyCommands = false)
    # Se non --force, rimuovi solo i comandi dinamici e ricrea solo COMMAND (onlyCommands = true)
    if ($Force) {
        $proxies.clearAllCommands()
        
        # Rigenera i comandi core
        $scriptRoot = Split-Path $PSScriptRoot -Parent
        New-CoreProxyFiles -ScriptRootPath $scriptRoot -Mode $currentMode | Out-Null
        
        # Crea tutti i proxy (comandi + manager)
        $result = $proxies.createProxies($installation, $false, $currentMode)
    } else {
        $proxies.clearDynamicCommands()
        
        # Crea solo i comandi (salta manager)
        $result = $proxies.createProxies($installation, $true, $currentMode)
    }
    
    # Resoconto finale
    $commandsCreated = $result[0]
    $managersCreated = $result[1]
    $totalCreated = $commandsCreated + $managersCreated
    Write-SuccessMessage "Sincronizzazione completata: $totalCreated proxy creati ($commandsCreated comandi, $managersCreated manager)"
}