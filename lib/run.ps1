# =============================================================================
# run.ps1 - Esecuzione temporanea di comandi con versioni specifiche
# =============================================================================

function Invoke-TemporaryCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$VersionAlias,
        
        [Parameter(Mandatory=$false)]
        [string[]]$Arguments = @()
    )
    
    # Validazione versione target
    Write-InfoMessage "Ricerca versione '$VersionAlias'..."
    
    $installations = [Installations]::new()
    $targetInstallation = $installations.find($VersionAlias)
    
    if (-not $targetInstallation) {
        Write-ErrorMessage "Versione '$VersionAlias' non trovata"
        Write-Host ""
        Write-Host "Versioni disponibili:" -ForegroundColor Cyan
        $installations.getAll() | ForEach-Object {
            Write-Host "  - $($_.getFolderName()) (Node.js $($_.version))" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Suggerimento: Usa 'node-local list' per vedere tutte le versioni installate" -ForegroundColor Yellow
        return 1
    }
    
    $versionPath = $targetInstallation.getPath()
    $versionNumber = $targetInstallation.version
    
    Write-SuccessMessage "Trovata versione '$VersionAlias' -> Node.js v$versionNumber"
    
    # Ricerca comando
    Write-InfoMessage "Ricerca comando '$Command' in '$VersionAlias'..."
    
    $commandExePath = Join-Path $versionPath "$Command.exe"
    $commandCmdPath = Join-Path $versionPath "$Command.cmd"
    $globalBinPath = Join-Path $versionPath "node_modules\.bin\$Command.cmd"
    $globalBinBashPath = Join-Path $versionPath "node_modules\.bin\$Command"
    
    $targetCommandPath = $null
    $commandType = ""
    
    if (Test-Path $commandExePath) {
        $targetCommandPath = $commandExePath
        $commandType = "eseguibile core"
    }
    elseif (Test-Path $commandCmdPath) {
        $targetCommandPath = $commandCmdPath
        $commandType = "script root"
    }
    elseif (Test-Path $globalBinPath) {
        $targetCommandPath = $globalBinPath
        $commandType = "pacchetto globale"
    }
    elseif (Test-Path $globalBinBashPath) {
        $targetCommandPath = $globalBinBashPath
        $commandType = "pacchetto globale (bash)"
    }
    else {
        Write-ErrorMessage "Comando '$Command' non trovato nella versione '$VersionAlias'"
        Write-Host ""
        Write-Host "Path verificati:" -ForegroundColor Gray
        Write-Host "  - $commandExePath" -ForegroundColor DarkGray
        Write-Host "  - $commandCmdPath" -ForegroundColor DarkGray
        Write-Host "  - $globalBinPath" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Suggerimento: Installa il pacchetto nella versione specificata" -ForegroundColor Yellow
        return 1
    }
    
    Write-SuccessMessage "Comando trovato: $targetCommandPath ($commandType)"
    
    # Preparazione ambiente
    $originalPath = $env:PATH
    $originalNodePath = $env:NODE_PATH
    $exitCode = 0
    
    try {
        # Override PATH e NODE_PATH
        $env:PATH = "$versionPath;$originalPath"
        
        $globalModulesPath = Join-Path $versionPath "node_modules"
        if (Test-Path $globalModulesPath) {
            $env:NODE_PATH = $globalModulesPath
        }
        
        # Esecuzione comando
        Write-Host ""
        Write-Host "================================================================" -ForegroundColor DarkGray
        Write-Host " Esecuzione comando con Node.js v$versionNumber" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor DarkGray
        Write-Host ""
        
        $displayCommand = $Command
        if ($Arguments -and $Arguments.Count -gt 0) {
            $displayCommand += " " + ($Arguments -join " ")
        }
        Write-Host "$ $displayCommand" -ForegroundColor Green
        Write-Host ""
        
        # Esegui il comando usando Start-Process per garantire che stdin/stdout/stderr
        # siano collegati correttamente (importante per CLI interattive)
        if ($Arguments -and $Arguments.Count -gt 0) {
            $argString = $Arguments -join " "
            $process = Start-Process -FilePath $targetCommandPath -ArgumentList $argString -NoNewWindow -Wait -PassThru
            $exitCode = $process.ExitCode
        }
        else {
            $process = Start-Process -FilePath $targetCommandPath -NoNewWindow -Wait -PassThru
            $exitCode = $process.ExitCode
        }
    }
    catch {
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor DarkGray
        Write-ErrorMessage "Errore durante l'esecuzione del comando"
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "===============================================================" -ForegroundColor DarkGray
        Write-Host ""
        $exitCode = 1
    }
    finally {
        # Ripristina ambiente
        $env:PATH = $originalPath
        
        if ($originalNodePath) {
            $env:NODE_PATH = $originalNodePath
        }
        else {
            Remove-Item Env:\NODE_PATH -ErrorAction SilentlyContinue
        }
    }
    
    # Resoconto
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor DarkGray
    
    if ($exitCode -eq 0 -or $null -eq $exitCode) {
        Write-Host " Comando completato con successo" -ForegroundColor Green
        $exitCode = 0
    }
    else {
        Write-Host " Comando terminato con exit code: $exitCode" -ForegroundColor Yellow
    }
    
    Write-Host "================================================================" -ForegroundColor DarkGray
    Write-Host ""
    
    return $exitCode
}

function Show-RunUsageExamples {
    Write-Host ""
    Write-Host "Esempi:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  # Eseguire comando globale con versione specifica" -ForegroundColor Gray
    Write-Host '  node-local run "tsc --version" --with-version production' -ForegroundColor White
    Write-Host ""
    Write-Host "  # Eseguire npm di altra versione" -ForegroundColor Gray
    Write-Host '  node-local run "npm test" --with-version latest' -ForegroundColor White
    Write-Host ""
    Write-Host "  # Eseguire npx con versione moderna" -ForegroundColor Gray
    Write-Host '  node-local run "npx cowsay hello" --with-version 20.11.0' -ForegroundColor White
    Write-Host ""
}
