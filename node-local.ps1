# =============================================================================
# node-local.ps1 - Node.js Version Manager per Windows
# =============================================================================
# Gestore versioni Node.js locale senza privilegi amministratore
# Architettura modulare con dot-sourcing

param(
    [Parameter(Position = 0)]
    [string]$Command,
    
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)]
    [string[]]$Args,
    
    [switch]$OverrideNodejs,
    [switch]$SetLocalNodejs,
    [switch]$v,
    [switch]$h
)

# =============================================================================
# CONFIGURAZIONE GLOBALE
# =============================================================================

# Versione di node-local
$Script:NodeLocalVersion = "0.2"

# Configurazione paths (variabili Script-scope per condivisione tra moduli)
$Script:AppDataPath = Join-Path $env:APPDATA "node-local"
$Script:VersionsPath = Join-Path $Script:AppDataPath "versions"
$Script:NodePath = Join-Path $Script:AppDataPath "node"
$Script:SettingsFile = Join-Path $Script:AppDataPath "settings.txt"
$Script:BinPath = Join-Path $Script:AppDataPath "bin"

# =============================================================================
# CARICAMENTO MODULI
# =============================================================================

# Determina il percorso dello script corrente
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Carica tutti i moduli della libreria
try {
    # Base
    . "$ScriptRoot\lib\exceptions\exceptions.ps1"
    . "$ScriptRoot\lib\classes\classes.ps1"

    # Utils
    . "$ScriptRoot\lib\labels.ps1"
    . "$ScriptRoot\lib\errors.ps1"
    . "$ScriptRoot\lib\argparser.ps1"

    
    # Scripts
    . "$ScriptRoot\lib\core.ps1"
    . "$ScriptRoot\lib\filesystem.ps1"
    . "$ScriptRoot\lib\cache.ps1"
    . "$ScriptRoot\lib\versions.ps1"
    . "$ScriptRoot\lib\installation.ps1"
    . "$ScriptRoot\lib\sync.ps1"
    . "$ScriptRoot\lib\shim.ps1"
    . "$ScriptRoot\lib\remote.ps1"
    . "$ScriptRoot\lib\security.ps1"
    . "$ScriptRoot\lib\ui.ps1"
    . "$ScriptRoot\lib\modes.ps1"
    # DEPRECATO: aliases.ps1 sostituito dalla classe Installations in lib/classes/installations.ps1
    # . "$ScriptRoot\lib\aliases.ps1"
    . "$ScriptRoot\lib\remove.ps1"
    # DISABILITATO: upgrade e downgrade richiedono refactoring per supportare nuova architettura a classi
    # . "$ScriptRoot\lib\upgrade.ps1"
    # . "$ScriptRoot\lib\downgrade.ps1"
    . "$ScriptRoot\lib\rename.ps1"
}
catch {
    Write-Host "[ERRORE] Caricamento dei moduli non ossibile: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Verifica che la cartella 'lib' sia presente e contenga tutti i file necessari." -ForegroundColor cyan
    exit 1
}

# =============================================================================
# GESTIONE PARAMETRI SWITCH
# =============================================================================

# Gestisci parametri switch prima dei comandi
if ($OverrideNodejs) {
    Set-OverrideMode
    exit
}

if ($SetLocalNodejs) {
    Set-LocalMode
    exit
}

if ($v) {
    Show-Version
    exit
}

if ($h) {
    Show-Help
    exit
}

# =============================================================================
# ROUTING COMANDI
# =============================================================================

switch ($Command.ToLower()) {
    { $_ -in "help", "-h", "--help", "/?" } {
        Show-Help
    }
    { $_ -in "version", "-v", "--version" } {
        Show-Version
    }
    "list" {
        Show-VersionList
    }
    "list-remote" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        $limitParam = if ($parsed.Limit) { $parsed.Limit } else { 20 }
        Show-RemoteVersionList -Limit $limitParam -LtsOnly:$parsed.LtsOnly -All:$parsed.All
    }
    "install" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        if (-not $parsed.FirstPositional -and -not $parsed.Latest -and -not $parsed.LatestLts) {
            Write-VersionNotFoundError
            Install-Usage-Example
        }
        else {
            $installVersion = $parsed.FirstPositional
            if ($parsed.Latest) {
                Write-InfoMessage "Cerco l'ultima versione disponibile..."
                $installVersion = Get-LatestVersion
                if (-not $installVersion) {
                    Write-ErrorMessage "Impossibile determinare l'ultima versione."
                    return
                }
                Write-SuccessMessage "Ultima versione: v$installVersion"
            }
            elseif ($parsed.LatestLts) {
                Write-InfoMessage "Cerco l'ultima versione LTS disponibile..."
                $installVersion = Get-LatestVersion -LtsOnly
                if (-not $installVersion) {
                    Write-ErrorMessage "Impossibile determinare l'ultima versione LTS."
                    return
                }
                Write-SuccessMessage "Ultima versione LTS: v$installVersion"
            }

            $aliasName = $parsed.Alias
            Install-NodeVersion -Version $installVersion -AliasName $aliasName
        }
    }
    "use" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        # Positional arg (first remaining token) is treated as installation name
        if (-not $parsed.FirstPositional) {
            Write-VersionNotFoundError
            Use-Usage-Example
        }
        else {
            $installationName = $parsed.FirstPositional
            if (-not $installationName -and $parsed.RemainingPositionals.Count -gt 0) { $installationName = $parsed.RemainingPositionals[0] }
            Switch-NodeVersion -InstallationName $installationName
        }
    }
    "remove" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        $installationName = $parsed.FirstPositional
        if (-not $installationName -and $parsed.RemainingPositionals.Count -gt 0) {
            $installationName = $parsed.RemainingPositionals[0]
        }
        if (-not $installationName) {
            Write-VersionNotFoundError
            Remove-Usage-Example
        }
        else {
            Remove-NodeVersion -InstallationName $installationName
        }
    }
    # "upgrade" {
    #     Start-NodeUpgrade
    # }
    # "downgrade" {
    #     Start-NodeDowngrade
    # }
    "rename" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        Invoke-RenameAlias -From $parsed.From -To $parsed.To
    }
    "sync" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        if ($parsed.Force) { Sync-GlobalCommands -Force } else { Sync-GlobalCommands }
    }
    "cache" {
        $parsed = Get-ParsedArgs -RawArgs $Args
        if ($parsed.List) {
            # Mostra stato cache
            Show-CacheStatus
        }
        elseif ($parsed.Clear -or $parsed.Clean) {
            # Pulisci cache
            Clear-Cache
        }
        else {
            Show-Cache-Usage-Example
        }
    }
    default {
        if ($Command) {
            Write-WarningMessage "Comando sconosciuto: $Command"
        }
        Show-Help
    }
}