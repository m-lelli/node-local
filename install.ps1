# install.ps1 - Script di installazione per node-local
# Configura il sistema per usare node-local senza privilegi amministratore

param(
    [switch]$OverrideNodejs
)

# =============================================================================
# MODULI
# =============================================================================
$ScriptDir = $PSScriptRoot
$labelsModule = Join-Path $PSScriptRoot "lib\labels.ps1"
$errorModules = Join-Path $PSScriptRoot ".\lib\errors.ps1"
$uiModule = Join-Path $PSScriptRoot "lib\ui.ps1"
$templatesModule = Join-Path $ScriptDir "lib\templates.ps1"
$coreModule = Join-Path $ScriptDir "lib\core.ps1"

# =============================================================================
# PATHS
# =============================================================================
$AppDataPath = Join-Path $env:APPDATA "node-local"
$mainScript = Join-Path $ScriptDir "node-local.ps1"
$mainScriptDest = Join-Path $AppDataPath "node-local.ps1"
$BinPath = Join-Path $AppDataPath "bin"
$verionsDir = Join-Path $AppDataPath "versions"
$libSource = Join-Path $ScriptDir "lib"
$libDest = Join-Path $BinPath "lib"
$templatesSource = Join-Path $ScriptDir "templates"
$templatesDest = Join-Path $BinPath "templates"

if (Test-Path $errorModules) {
    . $errorModules
} else {
    Write-Host "[ERRORE] Modulo errors non trovato. $Script:CANCELLED_MESSAGE" -ForegroundColor Red
    exit 1;
}

if ((Test-Path $labelsModule) -and (Test-Path $uiModule) -and (Test-Path $templatesModule) -and (Test-Path $coreModule)) {
    . $labelsModule
    . $uiModule
    . $templatesModule

    # CoreModule
    $Script:AppDataPath = $AppDataPath
    $Script:VersionsPath = Join-Path $AppDataPath "versions"
    $Script:BinPath = $BinPath
    $Script:SettingsFile = Join-Path $AppDataPath "settings.txt"
    
    . $coreModule
} else {
    Write-ErrorMessage "Moduli installazione non trovati. $Script:CANCELLED_MESSAGE"
    exit 1;
}

Show-Banner

# =============================================================================
# VERIFICA NODE DI SISTEMA
# =============================================================================
$systemNode = Get-Command node.exe -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*node-local*" }
if ($systemNode) {
    Write-WarningMessage "Rilevato node.exe installato!" -Hint "Rimuovi node.exe dal sistema, rischi conflitti nel path."
}

# =============================================================================
# VERIFICA NVM DI SISTEMA
# =============================================================================
$systemNvmExe = Get-Command nvm -ErrorAction SilentlyContinue | Where-Object { $_.Source -notlike "*node-local*" }
if ($systemNvmExe) {
    Write-WarningMessage "Rilevato nvm installato!" -Hint "Usa nvm off per disabilitarlo."
}

# =============================================================================
# VERIFICA MODALITA'
# =============================================================================
if ($OverrideNodejs) {
    Write-InfoMessage "Hai selezionato la modalità override, i tuoi comandi non avranno prefissi."
} else {
    Write-InfoMessage "Hai selezionato la modalità isolated, i tuoi comandi avranno prefissi nlocal-*."
}

# =============================================================================
# VERIFICA SE node-local È GIÀ INSTALLATO
# =============================================================================

if ((Test-Path $BinPath) -or (Test-Path $mainScriptDest)) {
    Write-ErrorMessage "node-local è già installato in: $BinPath. $Script:CANCELLED_MESSAGE" -Hint "Usa la funzione di update o disinstalla node-local prima di proseguire."
    exit 1
}

Write-SuccessMessage "Tutti i check pre-installazione completati!"
$confirm = Read-Host $Script:CONTINUE_MESSAGE
if ($confirm -ne 's') {
    Write-ErrorMessage $Script:CANCELLED_MESSAGE
    exit 1
}

# Crea le cartelle necessarie
Write-InfoMessage "Creazione struttura cartelle."
try {
    New-Item -ItemType Directory -Path $AppDataPath -Force | Out-Null
    New-Item -ItemType Directory -Path $BinPath -Force | Out-Null
    New-Item -ItemType Directory -Path $verionsDir -Force | Out-Null
    Write-SuccessMessage "Ok!"
} catch {
    Write-ErrorMessage "Impossibile creare la struttura delle cartelle. $Script:CANCELLED_MESSAGE"
    exit 1;
}

# Ho creato le cartelle, sono sicuro di avere i permessi di scrittura.

Write-InfoMessage "Copia scripts."
try {
    Copy-Item -Path $mainScript -Destination $BinPath -Force
    Write-SuccessMessage "Script principale."
} catch {
    Write-ErrorMessage "Impossibile copiare lo script principale. $Script:CANCELLED_MESSAGE"
    exit 1;
}

try {
    Copy-Item -Path $libSource -Destination $libDest -Recurse -Force
    Write-SuccessMessage "Librerie."
} catch {
    Write-ErrorMessage "Impossibile copiare le librerie. $Script:CANCELLED_MESSAGE"
    exit 1;
}

try {
    Copy-Item -Path $templatesSource -Destination $templatesDest -Recurse -Force
    Write-SuccessMessage "Templates."
} catch {
    Write-ErrorMessage "Impossibile copiare i templates. $Script:CANCELLED_MESSAGE"
    exit 1;
}

# Salva la modalità nel file mode.txt
Write-InfoMessage "Configurazione."
$modeToSet = if ($OverrideNodejs) { "override" } else { "isolated" }
if (Set-CurrentMode -Mode $modeToSet) {
    Write-SuccessMessage "Modalità salvata: $modeToSet"
} else {
    Write-ErrorMessage "Errore nel salvataggio della modalità" -Hint "Verifica sia presente in $Script:SettingsFile dopo l'installazione."
    Write-InfoMessage "Puoi creare a mano il file $Script:SettingsFile scrivendoci dentro $modeToSet"
}

# Aggiorna il PATH dell'utente
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")

$pathsToAdd = @($BinPath)
$pathUpdated = $false

foreach ($pathToAdd in $pathsToAdd) {
    if ($userPath -notlike "*$pathToAdd*") {
        if ($userPath -and -not $userPath.EndsWith(';')) {
            $userPath += ';'
        }
        $userPath += $pathToAdd
        $pathUpdated = $true
        Write-SuccessMessage "Aggiunto al PATH: $pathToAdd"
    } else {
        Write-WarningMessage "Già nel PATH: $pathToAdd"
    }
}

# Scrivi il PATH aggiornato nell'ambiente
if ($pathUpdated) {
    try {
        [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
        Write-SuccessMessage "PATH aggiornato correttamente!"
    } catch {
        Write-ErrorMessage "Impossibile aggiornare il PATH dell'utente" -Hint "Aggiungi manualmente $BinPath al PATH utente."
    }
}

Write-SuccessMessage "INSTALLAZIONE COMPLETATA! Chiudi e riapri il terminale per aggiornare il path."
