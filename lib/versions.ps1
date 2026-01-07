# =============================================================================
# versions.ps1 - Gestione versioni Node.js
# =============================================================================
# Funzioni per visualizzare e cambiare versioni Node.js
# Le funzioni di installazione sono in installation.ps1
# Le funzioni di sincronizzazione sono in sync.ps1

# Import delle classi necessarie
. "$PSScriptRoot\classes\installations.ps1"

# Mostra la lista delle versioni installate in formato tabellare
function Show-VersionList {
    $instMgr = [Installations]::new()
    $installations = $instMgr.getAll()

    if ($installations.Count -eq 0) {
        Write-WarningMessage "Nessuna installazione trovata." -Hint "Puoi installare una nuova versione di nodejs usando il comando install."
        Install-Usage-Example
        return
    }

    # Header della tabella
    Write-TableHeader -Columns @("NOME", "VERSIONE", "USE", "PATH") -Widths @(25, 15, 6, 50)

    foreach ($installation in $installations | Sort-Object { $_.getFolderName() }) {
        $name = $installation.getFolderName()
        $version = $installation.getVersion()
        $isCurrentInstallation = $installation.use
        $installationPath = $installation.getPath()

        # Tronca il nome se troppo lungo
        if ($name.Length -gt 25) {
            $name = $name.Substring(0, 22) + "..."
        }

        # Colonna USE
        $useStatus = if ($isCurrentInstallation) { "YES" } else { "NO" }

        # Colonna PATH (abbreviata per leggibilità)
        $shortPath = $installationPath -replace [regex]::Escape($env:APPDATA), "%APPDATA%"

        # Determina il colore della riga
        $color = if ($isCurrentInstallation) { "Green" } else { "White" }

        Write-TableHeader -Columns @($name, $version, $useStatus, $shortPath) -Widths @(25, 15, 6, 50) -Header $false -Color $color
    }
}

# Switch alla versione specificata
function Switch-NodeVersion {
    param([string]$InstallationName)

    $instMgr = [Installations]::new()

    try {
        $installation = $instMgr.findExistence($installationName, $true);
    } catch [InstallationsNotFoundError]{
        Write-ErrorMessage "Nessuna installazione trovata." -Hint "Usa 'node-local install <version>' per installare una versione."
        Install-Usage-Example
        return
    } catch [InstallationNotFoundError]{
        Write-ErrorMessage "Nessuna installazione trovata: $($_.Exception.Name)" -Hint "Verifica il nome o usa 'node-local install <version>' per installare una versione."
        Install-Usage-Example
        return
    }

    
    $currentInstallation = $instMgr.getCurrent()
    $currentInstallationName = if ($currentInstallation) { $currentInstallation.getFolderName() } else { $null }

    if ($currentInstallationName) {
        Write-SuccessMessage (switchChanging $currentInstallationName $installation.getFolderName() $installation.getVersion())
    } else {
        Write-InfoMessage (switchSetting $installation.getFolderName() $installation.getVersion())
    }

    # Salva il nome dell'installazione corrente
    Set-CurrentVersion -Version $installation.getFolderName()

    # Sincronizza i comandi globali (importata da sync.ps1) con --force
    Sync-GlobalCommands -Force

    Write-SuccessMessage $Script:SWITCH_COMPLETED
}
