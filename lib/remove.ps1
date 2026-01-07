# Rimuove un'installazione di Node.js 
function Remove-NodeVersion {
    param([string]$InstallationName)

    $instMgr = [Installations]::new()

    try {
        $installation = $instMgr.findExistence($installationName, $false);
    } catch [InstallationsNotFoundError]{
        Write-ErrorMessage "Nessuna installazione trovata." -Hint "Usa 'node-local install <version>' per installare una versione."
        Install-Usage-Example
        return
    } catch [InstallationNotFoundError]{
        Write-ErrorMessage "Nessuna installazione trovata: $($_.Exception.Name)" -Hint "Verifica il nome o usa 'node-local install <version>' per installare una versione."
        Install-Usage-Example
        return
    }

    $isCurrentInstallation = $installation.use

    Write-WarningMessage "Stai per eliminare la versione di nodejs: $($installation.name)" -Hint "Path: $($installation.getPath())"
    if ($isCurrentInstallation) {
        Write-WarningMessage "L'installazione è correntemente in uso."
    }
    $confirm = Read-Host $Script:CONTINUE_MESSAGE
    if ($confirm -ne 's') {
        Write-ErrorMessage $Script:CANCELLED_MESSAGE_OPERATION
        exit 1
    }

    Write-InfoMessage "Eliminazione della versione $($installation.name)"

    # Gestione use
    if ($isCurrentInstallation -and (Test-Path $Script:SettingsFile)) {
        try {
            Remove-Item -Path $Script:SettingsFile -Force
            $proxies = [Proxies]::new()
            $proxies.clearAllCommands()
            Write-SuccessMessage "Rimossa da use"
        } catch {
            Write-ErrorMessage "Impossibile rimuovere la cartella da use." -Hint "Rimuovi a mano il file: $($Script:SettingsFile)"
        }
    }
    
    # Gestione cartella
    try {
        # Usa robocopy per rimuovere cartelle con percorsi lunghi
        $emptyDir = Join-Path $env:TEMP "node-local-empty-$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        
        # Usa robocopy per svuotare la cartella
        $robocopyResult = robocopy "$emptyDir" "$($installation.Path)" /MIR /R:0 /W:0 /NP /NFL /NDL /NJH /NJS 2>&1
        
        # Rimuovi la cartella ora vuota e la cartella temporanea
        Remove-Item -Path $installation.getPath() -Force -ErrorAction SilentlyContinue -Recurse
        Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
        Write-SuccessMessage "Versione $($installation.name) correttamente eliminata!"
    } catch {
        # Suggerimenti in base all'errore
        if ($_.Exception.Message -like "*access*" -or $_.Exception.Message -like "*permission*") {
            Write-ErrorMessage "La cartella potrebbe essere in uso. Chiudi tutti i terminali e riprova."
        } elseif ($_.Exception.Message -like "*not found*") {
            Write-ErrorMessage "La cartella è già stata rimossa."
        }
    }
}