# =============================================================================
# modes.ps1 - Gestione modalità di funzionamento
# =============================================================================
# Funzioni per passare tra modalità Override e Local

# Cambia modalità a Override (node, npm, npx)
function Set-OverrideMode {
    Write-Host "`n=== Cambio Modalità: Override Node.js ===" -ForegroundColor Cyan
    Write-Host "`nQuesta operazione:" -ForegroundColor Yellow
    Write-Host "  - Rigenererà TUTTI i proxy con nomi 'node', 'npm', 'npx', 'yarn', 'tsc', etc." -ForegroundColor White
    Write-Host "  - I comandi node-local sostituiranno quelli di sistema nel PATH" -ForegroundColor White
    Write-Host "  - Tutti i global packages saranno accessibili senza prefisso nlocal-" -ForegroundColor White
    
    $confirm = Read-Host "`nContinuare? (s/n)"
    if ($confirm -ne "s") {
        Write-Host "Operazione annullata." -ForegroundColor Yellow
        return
    }
    
    # Salva la modalità PRIMA di rigenerare i proxy
    if (-not (Set-CurrentMode -Mode "override")) {
        Write-Host "`nErrore nel salvataggio della modalità." -ForegroundColor Red
        return
    }
    Write-Host "`nModalità salvata: override" -ForegroundColor Green
    
    # Rigenera TUTTI i proxy con la nuova modalità
    Write-Host "`nRigenerazione completa di tutti i proxy..." -ForegroundColor Yellow
    Sync-GlobalCommands -Force
    
    Write-Host "`n=== Modalità Override attivata! ===" -ForegroundColor Cyan
    Write-Host "Tutti i comandi ora usano i nomi standard (node, npm, yarn, tsc, etc.)" -ForegroundColor Green
    
    Write-Host "`nRicarico il PATH e refresh cache comandi..." -ForegroundColor Yellow
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Refresh della cache dei comandi PowerShell
    Get-Command node* -All -ErrorAction SilentlyContinue | Out-Null
    Get-Command npm* -All -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "PATH ricaricato!" -ForegroundColor Green
    
    # Controlla se esiste node.exe nel PATH di sistema
    $systemNode = Get-Command node.exe -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*node-local*" }
    if ($systemNode) {
        Write-Host "`n⚠️  ATTENZIONE: Rilevato node.exe di sistema in:" -ForegroundColor Yellow
        Write-Host "   $($systemNode.Source)" -ForegroundColor Gray
        Write-Host "`nWindows dà precedenza a .exe su .cmd, quindi:" -ForegroundColor Yellow
        Write-Host "  - 'node' eseguirà ancora il sistema (node.exe)" -ForegroundColor Red
        Write-Host "  - 'node.cmd' eseguirà node-local" -ForegroundColor Green
        Write-Host "  - 'npm' e 'npx' funzioneranno correttamente" -ForegroundColor Green
        Write-Host "`nPer usare node-local per node, hai queste opzioni:" -ForegroundColor Cyan
        Write-Host "  1. Usa 'node.cmd -v' invece di 'node -v'" -ForegroundColor White
        Write-Host "  2. Rimuovi/rinomina C:\Program Files\nodejs (richiede admin)" -ForegroundColor White
        Write-Host "  3. Usa 'nlocal-node' (torna in modalità isolata con -SetLocalNodejs)" -ForegroundColor White
    } else {
        Write-Host "Puoi usare subito i nuovi comandi!" -ForegroundColor Green
    }
}

# Cambia modalità a Local (nlocal-node, nlocal-npm, nlocal-npx) 
function Set-LocalMode {
    Write-Host "`n=== Cambio Modalità: Comandi Isolati ===" -ForegroundColor Cyan
    Write-Host "`nQuesta operazione:" -ForegroundColor Yellow
    Write-Host "  - Rigenererà TUTTI i proxy con prefisso 'nlocal-' (nlocal-node, nlocal-npm, nlocal-yarn, nlocal-tsc, etc.)" -ForegroundColor White
    Write-Host "  - I comandi di sistema torneranno disponibili (node, npm, yarn, tsc, etc.)" -ForegroundColor White
    Write-Host "  - Tutti i comandi node-local richiederanno il prefisso nlocal-" -ForegroundColor White
    
    $confirm = Read-Host "`nContinuare? (s/n)"
    if ($confirm -ne "s") {
        Write-Host "Operazione annullata." -ForegroundColor Yellow
        return
    }
    
    # Salva la modalità PRIMA di rigenerare i proxy
    if (-not (Set-CurrentMode -Mode "isolated")) {
        Write-Host "`nErrore nel salvataggio della modalità." -ForegroundColor Red
        return
    }
    Write-Host "`nModalità salvata: isolated" -ForegroundColor Green
    
    # Rigenera TUTTI i proxy con la nuova modalità
    Write-Host "`nRigenerazione completa di tutti i proxy..." -ForegroundColor Yellow
    Sync-GlobalCommands -Force
    
    Write-Host "`n=== Modalità Isolata attivata! ===" -ForegroundColor Cyan
    Write-Host "Tutti i comandi ora usano il prefisso nlocal- (nlocal-node, nlocal-npm, nlocal-yarn, etc.)" -ForegroundColor Green
    Write-Host "I tuoi comandi di sistema sono di nuovo disponibili." -ForegroundColor Green
    
    Write-Host "`nRicarico il PATH e refresh cache comandi..." -ForegroundColor Yellow
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Refresh della cache dei comandi PowerShell
    Get-Command node* -All -ErrorAction SilentlyContinue | Out-Null
    Get-Command npm* -All -ErrorAction SilentlyContinue | Out-Null
    Get-Command nlocal* -All -ErrorAction SilentlyContinue | Out-Null
    
    Write-Host "PATH ricaricato! Puoi usare subito i nuovi comandi." -ForegroundColor Green
    Write-Host "`nATTENZIONE: Se i comandi non funzionano correttamente," -ForegroundColor Yellow
    Write-Host "chiudi e riapri il terminale (PowerShell cache dei comandi)." -ForegroundColor Yellow
}