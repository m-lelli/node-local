# =============================================================================
# core.ps1 - Funzioni core di node-local
# =============================================================================
# Gestione inizializzazione, configurazione e versione corrente

# Inizializza le directory e file necessari per node-local
function Initialize-NodeLocal {
    if (-not (Test-Path $Script:AppDataPath)) {
        New-Item -ItemType Directory -Path $Script:AppDataPath -Force | Out-Null
    }
    if (-not (Test-Path $Script:VersionsPath)) {
        New-Item -ItemType Directory -Path $Script:VersionsPath -Force | Out-Null
    }
    if (-not (Test-Path $Script:BinPath)) {
        New-Item -ItemType Directory -Path $Script:BinPath -Force | Out-Null
    }
    if (-not (Test-Path $Script:SettingsFile)) {
        "" | Out-File -FilePath $Script:SettingsFile -Encoding UTF8
    }
}

# Helper function per creare proxy generico con verifica
function New-GenericProxyIfExists {
    param(
        [string]$CommandName,
        [string]$CommandExe,
        [string]$ProxyName,
        [string]$VersionPath,
        [string]$BinPath,
        [string]$TemplatePath,
        [string]$SettingsFile,
        [string]$VersionsPath
    )
    
    # Verifica che il comando esista nella versione
    $exePath = Join-Path $VersionPath $CommandExe
    if (-not (Test-Path $exePath)) {
        return $false  # Non esiste
    }
    
    $proxyPath = Join-Path $BinPath $ProxyName
    return (New-GenericProxy -TemplatePath $TemplatePath -OutputPath $proxyPath -SettingsFile $SettingsFile -VersionsPath $VersionsPath -CommandName $CommandName -CommandExe $CommandExe)
}

# Helper function per creare proxy package manager con verifica
function New-PackageManagerProxyIfExists {
    param(
        [string]$PackageManager,
        [string]$ProxyName,
        [string]$VersionPath,
        [string]$BinPath,
        [string]$TemplatePath,
        [string]$SettingsFile,
        [string]$VersionsPath,
        [string]$ScriptPath
    )
    
    # Verifica che il package manager esista nella versione
    $pmCmdPath = Join-Path $VersionPath "$PackageManager.cmd"
    if (-not (Test-Path $pmCmdPath)) {
        return $false  # Non esiste
    }
    
    $proxyPath = Join-Path $BinPath $ProxyName
    return (New-PackageManagerProxy -TemplatePath $TemplatePath -OutputPath $proxyPath -SettingsFile $SettingsFile -VersionsPath $VersionsPath -PackageManager $PackageManager -ScriptPath $ScriptPath)
}

# Legge la versione corrente dal file settings
function Get-CurrentVersion {
    $instMgr = [Installations]::new()
    $currentInstallation = $instMgr.getCurrent()
    
    if ($currentInstallation) {
        return $currentInstallation.name
    }
    return $null
}

# Salva la versione corrente nel file settings
function Set-CurrentVersion {
    param([string]$Version)
    
    # Assicurati che la directory esista
    $settingsDir = Split-Path -Parent $Script:SettingsFile
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }
    
    # Usa UTF8 senza BOM per evitare caratteri strani
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Script:SettingsFile, $Version, $utf8NoBom)
}

# Legge la modalità corrente dal file mode.txt
function Get-CurrentMode {
    $modeFile = Join-Path $Script:AppDataPath "mode.txt"
    if (Test-Path $modeFile) {
        $content = Get-Content $modeFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            $mode = $content.Trim() -replace '^\uFEFF', ''
            if ($mode -in @("isolated", "override")) {
                return $mode
            }
        }
    }
    # Default: modalità isolata
    return "isolated"
}

# Salva la modalità corrente nel file mode.txt
function Set-CurrentMode {
    param([string]$Mode)
    if ($Mode -notin @("isolated", "override")) {
        Write-Host "Errore: Modalità non valida: '$Mode'. Usa 'isolated' o 'override'." -ForegroundColor Red
        return $false
    }
    $modeFile = Join-Path $Script:AppDataPath "mode.txt"
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($modeFile, $Mode, $utf8NoBom)
    return $true
}

# Crea i proxy files core (nlocal-node, nlocal-npm, nlocal-npx) o (node, npm, npx) in base alla modalità
function New-CoreProxyFiles {
    param(
        [string]$ScriptRootPath,
        [string]$Mode = "isolated"  # Default: isolated
    )
    
    # Carica le funzioni template
    $templatesModule = Join-Path $ScriptRootPath "lib\templates.ps1"
    if (-not (Test-Path $templatesModule)) {
        Write-Host "Errore: Modulo templates non trovato in: $templatesModule" -ForegroundColor Red
        return $false
    }
    
    . $templatesModule
    
    $binPath = Join-Path $Script:AppDataPath "bin"
    $templatesPath = Get-TemplatesPath $ScriptRootPath
    $settingsFile = Join-Path $Script:AppDataPath "settings.txt"
    $versionsPath = $Script:VersionsPath
    
    $success = $true
    
    # Determina il prefisso dei nomi in base alla modalità
    if ($Mode -eq "override") {
        $nodeCmd = "node.cmd"
        $npmCmd = "npm.cmd"
        $npxCmd = "npx.cmd"
    } else {
        $nodeCmd = "nlocal-node.cmd"
        $npmCmd = "nlocal-npm.cmd"
        $npxCmd = "nlocal-npx.cmd"
    }
    
    # Verifica che la versione attuale esista
    $currentVersion = Get-CurrentVersion
    if (-not $currentVersion) {
        Write-Host "Errore: Nessuna versione selezionata" -ForegroundColor Red
        return $false
    }
    
    $versionPath = Join-Path $Script:VersionsPath $currentVersion
    if (-not (Test-Path $versionPath)) {
        Write-Host "Errore: Versione $currentVersion non trovata in $versionPath" -ForegroundColor Red
        return $false
    }
    
    # Crea proxy usando helper function
    $genericTemplate = Join-Path $templatesPath "generic-proxy.cmd.template"
    $genericBashTemplate = Join-Path $templatesPath "generic-proxy.bash.template"
    $pmTemplate = Join-Path $templatesPath "package-manager.cmd.template"
    $pmBashTemplate = Join-Path $templatesPath "package-manager.bash.template"
    $scriptPath = Join-Path $ScriptRootPath "node-local.ps1"
    
    # Nomi per proxy bash (senza estensione)
    $nodeBash = $nodeCmd -replace '\.cmd$', ''
    $npmBash = $npmCmd -replace '\.cmd$', ''
    $npxBash = $npxCmd -replace '\.cmd$', ''
    
    # Verifica se bash è disponibile
    $bashAvailable = Test-BashAvailable
    
    # CMD proxies - Solo npm e npx (node usa .exe shim)
    $npmResult = New-PackageManagerProxyIfExists -PackageManager "npm" -ProxyName $npmCmd -VersionPath $versionPath -BinPath $binPath -TemplatePath $pmTemplate -SettingsFile $settingsFile -VersionsPath $versionsPath -ScriptPath $scriptPath
    $npxResult = New-GenericProxyIfExists -CommandName "NPX" -CommandExe "npx.cmd" -ProxyName $npxCmd -VersionPath $versionPath -BinPath $binPath -TemplatePath $genericTemplate -SettingsFile $settingsFile -VersionsPath $versionsPath
    
    # # Genera shim .exe per node (per compatibilità con script .bat che non usano call)
    # $nodeResult = $false
    # try {
    #     # Rimuovi node.cmd se esiste (ora usiamo solo node.exe)
    #     $nodeCmdPath = Join-Path $binPath $nodeCmd
    #     if (Test-Path $nodeCmdPath) {
    #         Remove-Item -Path $nodeCmdPath -Force | Out-Null
    #         Write-Host "  Rimosso vecchio node.cmd" -ForegroundColor Gray
    #     }
        
    #     # Genera node.exe
    #     $nodeExePath = Join-Path $binPath ($nodeCmd -replace '\.cmd$', '.exe')
    #     Write-Host "Generazione shim .exe per node..." -ForegroundColor Cyan
    #     $nodeResult = New-ExeShim -OutputPath $nodeExePath -SettingsFile $settingsFile -VersionsPath $versionsPath -TargetExe "node.exe"
    #     if ($nodeResult) {
    #         Write-Host "  Shim .exe creato: $nodeExePath" -ForegroundColor Green
    #     }
    # }
    # catch {
    #     Write-Host "  Avviso: Non è stato possibile creare lo shim .exe" -ForegroundColor Yellow
    #     Write-Host "  Verrà generato node.cmd come fallback" -ForegroundColor Yellow
    #     # Fallback: genera node.cmd se l'exe fallisce
    #     $nodeResult = New-GenericProxyIfExists -CommandName "NODE" -CommandExe "node.exe" -ProxyName $nodeCmd -VersionPath $versionPath -BinPath $binPath -TemplatePath $genericTemplate -SettingsFile $settingsFile -VersionsPath $versionsPath
    # }
    
    # Bash proxies (per Git Bash) - SOLO se bash è disponibile
    if ($bashAvailable -and (Test-Path $genericBashTemplate)) {
        $nodeBashPath = Join-Path $binPath $nodeBash
        $npxBashPath = Join-Path $binPath $npxBash
        New-GenericBashProxy -TemplatePath $genericBashTemplate -OutputPath $nodeBashPath -SettingsFile $settingsFile -VersionsPath $versionsPath -CommandName "NODE" -CommandExe "node.exe" | Out-Null
        New-GenericBashProxy -TemplatePath $genericBashTemplate -OutputPath $npxBashPath -SettingsFile $settingsFile -VersionsPath $versionsPath -CommandName "NPX" -CommandExe "npx.cmd" | Out-Null
    }
    
    if ($bashAvailable -and (Test-Path $pmBashTemplate)) {
        $npmBashPath = Join-Path $binPath $npmBash
        New-PackageManagerBashProxy -TemplatePath $pmBashTemplate -OutputPath $npmBashPath -SettingsFile $settingsFile -VersionsPath $versionsPath -PackageManager "npm" -ScriptPath $scriptPath | Out-Null
    }
    
    if (-not ($nodeResult -and $npmResult -and $npxResult)) {
        $success = $false
    }
    
    # Pulizia finale: rimuovi node.cmd se node.exe esiste
    # $nodeExePath = Join-Path $binPath ($nodeCmd -replace '\.cmd$', '.exe')
    # $nodeCmdPath = Join-Path $binPath $nodeCmd
    # if ((Test-Path $nodeExePath) -and (Test-Path $nodeCmdPath)) {
    #     Remove-Item -Path $nodeCmdPath -Force | Out-Null
    # }
    
    return $success
}

# =============================================================================
# Configurazione Package Manager
# =============================================================================

# Configura Yarn per usare una directory globale isolata per versione
function Set-YarnGlobalPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VersionPath
    )
    
    # Verifica che Yarn sia disponibile nella versione corrente
    $yarnPath = Join-Path $VersionPath "yarn.cmd"
    if (-not (Test-Path $yarnPath)) {
        return $false
    }
    
    # Imposta prefix e global-folder nella directory della versione Node.js
    $yarnGlobalPath = Join-Path $VersionPath "yarn_global"
    $yarnGlobalBin = Join-Path $yarnGlobalPath "bin"
    
    # Crea le directory se non esistono
    if (-not (Test-Path $yarnGlobalPath)) {
        New-Item -ItemType Directory -Path $yarnGlobalPath -Force | Out-Null
    }
    if (-not (Test-Path $yarnGlobalBin)) {
        New-Item -ItemType Directory -Path $yarnGlobalBin -Force | Out-Null
    }
    
    # Configura Yarn (usando il path completo per evitare conflitti)
    $yarnExe = Join-Path $VersionPath "yarn.cmd"
    
    # Imposta prefix (directory dove vanno i binari)
    & $yarnExe config set prefix $yarnGlobalPath --global 2>&1 | Out-Null
    
    # Imposta global-folder (directory dove vanno i node_modules)
    & $yarnExe config set global-folder $yarnGlobalPath --global 2>&1 | Out-Null
    
    return $true
}

# Configura pnpm per usare una directory globale isolata per versione
function Set-PnpmGlobalPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VersionPath
    )
    
    # Verifica che pnpm sia disponibile nella versione corrente
    $pnpmPath = Join-Path $VersionPath "pnpm.cmd"
    if (-not (Test-Path $pnpmPath)) {
        return $false
    }
    
    # Imposta global-bin-dir e global-dir nella directory della versione Node.js
    $pnpmGlobalPath = Join-Path $VersionPath "pnpm_global"
    $pnpmGlobalBin = Join-Path $pnpmGlobalPath "bin"
    
    # Crea le directory se non esistono
    if (-not (Test-Path $pnpmGlobalPath)) {
        New-Item -ItemType Directory -Path $pnpmGlobalPath -Force | Out-Null
    }
    if (-not (Test-Path $pnpmGlobalBin)) {
        New-Item -ItemType Directory -Path $pnpmGlobalBin -Force | Out-Null
    }
    
    # Crea un package.json minimo se non esiste
    # (pnpm richiede un manifest file nella sua directory globale)
    $packageJsonPath = Join-Path $pnpmGlobalPath "package.json"
    if (-not (Test-Path $packageJsonPath)) {
        '{"type":"module"}' | Out-File -FilePath $packageJsonPath -Encoding UTF8 -NoNewline
    }
    
    # Inizializza la directory globale con pnpm
    # (crea la struttura corretta con package.json nella sottocartella versione-specifica)
    $pnpmExe = Join-Path $VersionPath "pnpm.cmd"
    & $pnpmExe config set prefer-symlinked-executables false --global 2>&1 | Out-Null
    
    # Configura pnpm
    
    # Imposta global-bin-dir (directory dove vanno i binari)
    & $pnpmExe config set global-bin-dir $pnpmGlobalBin --global 2>&1 | Out-Null
    
    # Imposta global-dir (directory dove vanno i node_modules)
    & $pnpmExe config set global-dir $pnpmGlobalPath --global 2>&1 | Out-Null
    
    # Disabilita il check del PATH (i nostri proxy gestiscono tutto)
    & $pnpmExe config set manage-package-manager-versions false --global 2>&1 | Out-Null
    
    return $true
}

# Configura bun per usare una directory globale isolata per versione
function Set-BunGlobalPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VersionPath
    )
    
    # Verifica che bun sia disponibile nella versione corrente
    $bunPath = Join-Path $VersionPath "bun.cmd"
    if (-not (Test-Path $bunPath)) {
        return $false
    }
    
    # Bun usa la variabile d'ambiente BUN_INSTALL per configurare la directory globale
    # Non ha configurazione persistente, ma il nostro wrapper imposta BUN_INSTALL per ogni chiamata
    
    # Creiamo la directory per i globali di bun
    $bunGlobalPath = Join-Path $VersionPath "bun_global"
    $bunGlobalBin = Join-Path $bunGlobalPath "bin"
    
    if (-not (Test-Path $bunGlobalPath)) {
        New-Item -ItemType Directory -Path $bunGlobalPath -Force | Out-Null
    }
    if (-not (Test-Path $bunGlobalBin)) {
        New-Item -ItemType Directory -Path $bunGlobalBin -Force | Out-Null
    }
    
    # Il wrapper package-manager.cmd.template imposta BUN_INSTALL per ogni esecuzione
    return $true
}

# Configura ni (usa npm sotto il cofano, quindi eredita la configurazione npm)
function Set-NiGlobalPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VersionPath
    )
    
    # Verifica che ni sia disponibile nella versione corrente
    $niPath = Join-Path $VersionPath "ni.cmd"
    if (-not (Test-Path $niPath)) {
        return $false
    }
    
    # ni usa npm/yarn/pnpm sotto il cofano, quindi non ha bisogno di configurazione
    # Rileva automaticamente quale package manager usare e usa le sue configurazioni
    
    return $true
}