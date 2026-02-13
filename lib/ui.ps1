# =============================================================================
# ui.ps1 - Interfaccia utente e funzioni di visualizzazione
# =============================================================================
# Gestione help, debug e output utente

# =============================================================================
# Banner
# =============================================================================

function Show-Banner {
    Write-Host ""
    Write-Host "   ╔═══════════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "   ║                                                                                       ║" -ForegroundColor Cyan
    Write-Host "   ║  ███╗   ██╗ ██████╗ ██████╗ ███████╗      ██╗       ██████╗  ██████╗  █████╗ ██╗      ║" -ForegroundColor Green
    Write-Host "   ║  ████╗  ██║██╔═══██╗██╔══██╗██╔════╝      ██║      ██╔═══██╗██╔════╝ ██╔══██╗██║      ║" -ForegroundColor Green  
    Write-Host "   ║  ██╔██╗ ██║██║   ██║██║  ██║█████╗  █████╗██║      ██║   ██║██║      ███████║██║      ║" -ForegroundColor Yellow
    Write-Host "   ║  ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════╝██║      ██║   ██║██║      ██╔══██║██║      ║" -ForegroundColor Yellow
    Write-Host "   ║  ██║ ╚████║╚██████╔╝██████╔╝███████╗      ███████╗ ╚██████╔╝╚██████╗ ██║  ██║███████  ║" -ForegroundColor Cyan
    Write-Host "   ║  ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝      ╚══════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════  ║" -ForegroundColor Cyan
    Write-Host "   ║                                                                                       ║" -ForegroundColor Cyan
    Write-Host "   ║             Windows Node.js Version Manager - Zero Admin Required                     ║" -ForegroundColor White
    Write-Host "   ║                                                                                       ║" -ForegroundColor Cyan
    Write-Host "   ╚═══════════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Install-Usage-Example {
    Write-CommandUsage -Command "install" -Usage "install <version> [--alias <name>]" -Examples @(
        "node-local install 20.11.0 [--alias <name>]",
        "node-local install --latest [--alias <name>]",
        "node-local install --latest-lts [--alias <name>]"
    )
}

function ListRemote-Usage-Example {
    Write-CommandUsage -Command "list-remote" -Usage "list-remote [--lts] [--all] [--limit <n>]" -Examples @(
        "node-local list-remote",
        "node-local list-remote --all",
        "node-local list-remote --lts",
        "node-local list-remote --limit 10",
        "node-local list-remote --lts --all --limit 5"
    )
}

function Use-Usage-Example {
    Write-CommandUsage -Command "use" -Usage "use <version-name>" -Examples @(
        "node-local use 20.11.0",
        "node-local use my_alias"
    )
}

function Remove-Usage-Example {
    Write-CommandUsage -Command "remove" -Usage "remove <version-name>" -Examples @(
        "node-local remove 20.11.0",
        "node-local remove my_alias"
    )
}

function Rename-Usage-Example {
    Write-CommandUsage -Command "rename" -Usage "rename --from <nome-attuale> --to <nuovo-nome>" -Examples @(
        "node-local rename --from production --to staging",
        "node-local rename --from 20.11.0 --to my-project"
    )
}

function Run-Usage-Example {
    Write-CommandUsage -Command "run" -Usage "run `"<comando>`" --with-version <alias>" -Examples @(
        "node-local run `"tsc --version`" --with-version production",
        "node-local run `"npm test`" --with-version latest",
        "node-local run `"npx cowsay hello`" --with-version 20.11.0"
    )
}

function Show-Cache-Usage-Example {
    Write-CommandUsage -Command "cache" -Usage "cache <command>" -Examples @(
        "node-local cache --list",
        "node-local cache --clear",
        "node-local cache --clean"
    )
}

# =============================================================================
# Spinner - Animazione riutilizzabile
# =============================================================================

<#
.SYNOPSIS
Mostra uno spinner animato mentre un job è in esecuzione.

.PARAMETER Job
Il job che sta eseguendo (creato con Start-Job).

.PARAMETER Message
Il messaggio da mostrare accanto allo spinner.

.PARAMETER Color
Il colore dello spinner (default: Cyan).

.EXAMPLE
$job = Start-Job -ScriptBlock { robocopy $source $dest /E }
Wait-WithSpinner -Job $job -Message "Copia in corso..."
#>
function Wait-WithSpinner {
    param(
        [System.Management.Automation.Job]$Job,
        [string]$Message = "Operazione in corso...",
        [string]$Color = "Cyan"
    )
    
    $spinChars = @('|', '/', '-', '\')
    $spinIndex = 0
    
    # Mostra spinner mentre il job è in esecuzione
    while ($Job.State -eq 'Running') {
        Write-Host "`r  $($spinChars[$spinIndex]) $Message" -NoNewline -ForegroundColor $Color
        $spinIndex = ($spinIndex + 1) % 4
        Start-Sleep -Milliseconds 100
    }
    
    # Cancella la riga dello spinner
    Write-Host "`r$(' ' * ($Message.Length + 4))" -NoNewline
    Write-Host "`r" -NoNewline
    
    # Ritorna il risultato del job
    $result = Receive-Job -Job $Job
    Remove-Job -Job $Job
    
    return $result
}

# =============================================================================
# Easter Egg - Animazione Thanos
# =============================================================================

function Show-ThanosSnap {
    <#
    .SYNOPSIS
    Easter egg: Mostra l'animazione di Thanos che schiocca le dita
    
    .DESCRIPTION
    Easter egg Thanos - Scritte sequenziali con delay di 3 secondi.
    #>
    
    Write-Host ""
    Write-Host "           IO SONO INELUTTABILE!" -ForegroundColor Magenta
    Start-Sleep -Seconds 2
    
    Write-Host ""
    Write-Host "                    SNAP!" -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    
    Write-Host ""
    Write-Host "        I dati di Node.js si trasformano in polvere..." -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 800
    Write-Host "        I dati di Node.js si tras••••••  po•••••" -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 800
    Write-Host "        I dati ••   Node.js •• •••••••••••  •••••" -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 800
    Write-Host "        •• •••••  •••  Node.••• ••  ••••••••  •••••" -ForegroundColor DarkGray
    Write-Host "        •• •••••  ••• ••• ••  ••••••••  •••••" -ForegroundColor DarkGray
    Start-Sleep -Milliseconds 800
    
    Write-Host ""
    Write-Host "        Mi diedero del folle..." -ForegroundColor Cyan
    Write-Host "        L'universo richiedeva un correttivo..." -ForegroundColor Cyan
    Write-Host ""
}


# Mostra la versione di node-local e la modalità attiva
function Show-Version {
    Show-Banner
    Write-InfoMessage "node-local versione $Script:NodeLocalVersion"
    
    $currentMode = Get-CurrentMode
    if ($currentMode -eq "override") {
        Write-InfoMessage "Stai usando la modalità override (node, npm, npx)"
    } else {
        Write-InfoMessage "Stai usando la modalità isolated (nlocal-node, nlocal-npm, nlocal-npx)"
    }
    
    $config = [ConfigurationClass]::GetInstance()
    Write-InfoMessage "Path installazione: $($config.appDataPath)"
}

# Mostra la schermata di aiuto con tutti i comandi disponibili
function Show-Help {
    Show-Banner
    Install-Usage-Example
    ListRemote-Usage-Example
    Use-Usage-Example
    Remove-Usage-Example
    Rename-Usage-Example
    Run-Usage-Example
    Show-Cache-Usage-Example
}