# update.ps1 - Script di aggiornamento per node-local
# Aggiorna i file di node-local installati in %APPDATA%\node-local\bin

param(
    [switch]$Force
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
    Write-Host "[ERRORE] Modulo errors non trovato. $Script:CANCELLED_MESSAGE_UPDATE" -ForegroundColor Red
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
    Write-ErrorMessage "Moduli installazione non trovati. $Script:CANCELLED_MESSAGE_UPDATE"
    exit 1;
}

if ((Test-Path $BinPath) -or (Test-Path $mainScript) -or (Test-Path $templatesDest)) {} else {
    Write-ErrorMessage "Alcuni path non correttamente presenti" -Hint "Usa la funzione di disinstallazione di node-local prima di proseguire."
    Write-Warning "Attenzione, disinstallando node-local perderai le tue installazioni di nodejs, puoi sempre copiare il contenuto di $versionsPath e ripristinarlo successivamente."
    exit 1
}

Show-Banner

Write-SuccessMessage "Tutti i check pre-update completati!"
$confirm = Read-Host $Script:CONTINUE_MESSAGE
if ($confirm -ne 's') {
    Write-ErrorMessage $Script:CANCELLED_MESSAGE_UPDATE
    exit 1
}

# Copia node-local.ps1
Write-InfoMessage "Aggiornamento."
try {
    Copy-Item -Path $mainScript -Destination $BinPath -Force
    Write-SuccessMessage "Script principale."
} catch {
    Write-ErrorMessage "Impossibile copiare lo script principale. $Script:CANCELLED_MESSAGE_UPDATE"
    exit 1;
}

try {
    if (-not (Test-Path $libDest)) { New-Item -ItemType Directory -Path $libDest | Out-Null }
    Copy-Item -Path (Join-Path $libSource '*') -Destination $libDest -Recurse -Force
    Write-SuccessMessage "Librerie."
} catch {
    Write-ErrorMessage "Impossibile copiare le librerie. $Script:CANCELLED_MESSAGE_UPDATE"
    exit 1;
}

try {
    if (-not (Test-Path $templatesDest)) { New-Item -ItemType Directory -Path $templatesDest | Out-Null }
    Copy-Item -Path (Join-Path $templatesSource '*') -Destination $templatesDest -Recurse -Force
    Write-SuccessMessage "Templates."
} catch {
    Write-ErrorMessage "Impossibile copiare i templates. $Script:CANCELLED_MESSAGE_UPDATE"
    exit 1;
}

Write-SuccessMessage "AGGIORNAMENTO COMPLETATO."
