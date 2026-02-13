# =============================================================================
# proxies.ps1 - Classe Proxies per gestione collezione proxy
# =============================================================================

# Import della classe Proxy (dipendenza)
. "$PSScriptRoot\proxy.ps1"

class Proxies {
    # Array statico con i nomi dei package manager supportati
    static [string[]] $PackageManagers = @(
        "npm",
        "yarn",
        "yarnpkg",
        "pnpm",
        "ni",
        "nun",
        "nup",
        "bun"
    )

    # Array statico con i file da non eliminare mai
    static [string[]] $NotDelete = @(
        "node-local.ps1"
    )

    # Proprietà per i path
    hidden [string] $binPath
    hidden [string] $templatesPath
    hidden [string] $settingsFile
    hidden [string] $versionsPath
    hidden [string] $scriptPath
    hidden [bool] $bashAvailable

    # Costruttore
    Proxies() {
        $config = [ConfigurationClass]::GetInstance()
        $this.binPath = $config.binPath
        $this.settingsFile = $config.settingsFile
        $this.versionsPath = $config.versionsPath
        $this.templatesPath = $config.templatesPath
        $this.scriptPath = $config.scriptPath
        $this.bashAvailable = $null -ne (Get-Command bash -ErrorAction SilentlyContinue)
    }

    # =============================================================================
    # Metodi hidden per creazione proxy
    # =============================================================================

    # Converte path Windows in path Git Bash
    hidden [string] convertToGitBashPath([string]$windowsPath) {
        $bashPath = $windowsPath -replace '\\', '/'
        if ($bashPath -match '^([A-Za-z]):') {
            $drive = $matches[1].ToLower()
            $bashPath = '/' + $drive + ($bashPath -replace '^[A-Za-z]:', '')
        }
        return $bashPath
    }

    # Crea un proxy CMD per COMMAND (node, npx, tsc, etc.)
    hidden [bool] newCommandProxy([string]$commandName, [string]$commandExe, [string]$outputPath) {
        $templatePath = Join-Path $this.templatesPath "generic-proxy.cmd.template"
        
        if (-not (Test-Path $templatePath)) {
            return $false
        }
        
        try {
            $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
            $content = $template -replace '\{\{SETTINGS_FILE\}\}', $this.settingsFile
            $content = $content -replace '\{\{VERSIONS_PATH\}\}', $this.versionsPath
            $content = $content -replace '\{\{COMMAND_NAME\}\}', $commandName.ToUpper()
            $content = $content -replace '\{\{COMMAND_EXE\}\}', $commandExe
            $content | Out-File -FilePath $outputPath -Encoding ASCII -NoNewline
            return $true
        } catch {
            return $false
        }
    }

    # Crea un proxy Bash per COMMAND
    hidden [bool] newCommandBashProxy([string]$commandName, [string]$commandExe, [string]$outputPath) {
        $templatePath = Join-Path $this.templatesPath "generic-proxy.bash.template"
        
        if (-not (Test-Path $templatePath)) {
            return $false
        }
        
        try {
            $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
            $settingsFileGit = $this.convertToGitBashPath($this.settingsFile)
            $versionsPathGit = $this.convertToGitBashPath($this.versionsPath)
            
            $content = $template -replace '\{\{SETTINGS_FILE\}\}', $settingsFileGit
            $content = $content -replace '\{\{VERSIONS_PATH\}\}', $versionsPathGit
            $content = $content -replace '\{\{COMMAND_NAME\}\}', $commandName.ToUpper()
            $content = $content -replace '\{\{COMMAND_EXE\}\}', $commandExe
            
            $content = $content -replace "`r`n", "`n"
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($outputPath, $content, $utf8NoBom)
            return $true
        } catch {
            return $false
        }
    }

    # Crea un proxy .exe per node (shim C# compilato)
    hidden [bool] newNodeExeShim([string]$outputPath, [string]$targetExe) {
        $templatePath = Join-Path $this.templatesPath "node-shim.cs.template"
        
        if (-not (Test-Path $templatePath)) {
            return $false
        }
        try {
            # Leggi il template C#
            $csharpCode = Get-Content -Path $templatePath -Raw -Encoding UTF8
            
            # Sostituisci i placeholder
            $csharpCode = $csharpCode -replace '\{\{SETTINGS_FILE\}\}', $this.settingsFile
            $csharpCode = $csharpCode -replace '\{\{VERSIONS_PATH\}\}', $this.versionsPath
            $csharpCode = $csharpCode -replace '\{\{TARGET_EXE\}\}', $targetExe
            
            # Strategia di compilazione basata sulla versione di PowerShell
            $psVersion = (Get-Variable -Name PSVersionTable -Scope Global).Value.PSVersion.Major
            if ($psVersion -ge 7) {
                # PowerShell 7+: usa csc.exe (Add-Type -OutputType non supportato)
                $cscPath = Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework*" -Recurse -Filter "csc.exe" -ErrorAction SilentlyContinue |
                    Sort-Object FullName -Descending |
                    Select-Object -First 1 -ExpandProperty FullName
                
                if (-not $cscPath) {
                    Write-Error "Compilatore C# (csc.exe) non trovato nel sistema"
                    return $false
                }
                
                # Crea un file temporaneo .cs
                $tempCs = [System.IO.Path]::GetTempFileName() + ".cs"
                $csharpCode | Out-File -FilePath $tempCs -Encoding UTF8
                
                # Compila con csc.exe
                $compileOutput = & $cscPath /target:exe /out:$outputPath $tempCs /nologo 2>&1
                $compileSuccess = $LASTEXITCODE -eq 0
                
                # Rimuovi il file temporaneo
                Remove-Item $tempCs -Force -ErrorAction SilentlyContinue
                
                if (-not $compileSuccess) {
                    Write-Error "Errore nella compilazione dello shim .exe per $targetExe : $compileOutput"
                    return $false
                }
            } else {
                # PowerShell 5.x: usa Add-Type (metodo nativo)
                Add-Type -TypeDefinition $csharpCode -OutputAssembly $outputPath -OutputType ConsoleApplication
            }
            
            return $true
        } catch {
            Write-Error "Errore nella creazione dello shim .exe per $targetExe : $_"
            return $false
        }
    }

    # Crea un proxy CMD per MANAGER (npm, yarn, pnpm, etc.)
    hidden [bool] newManagerProxy([string]$packageManager, [string]$outputPath) {
        $templatePath = Join-Path $this.templatesPath "package-manager.cmd.template"
        
        if (-not (Test-Path $templatePath)) {
            return $false
        }
        
        try {
            $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
            $content = $template -replace '\{\{SETTINGS_FILE\}\}', $this.settingsFile
            $content = $content -replace '\{\{VERSIONS_PATH\}\}', $this.versionsPath
            $content = $content -replace '\{\{PM_NAME\}\}', $packageManager
            $content = $content -replace '\{\{SCRIPT_PATH\}\}', $this.scriptPath
            $content | Out-File -FilePath $outputPath -Encoding ASCII -NoNewline
            return $true
        } catch {
            return $false
        }
    }

    # Crea un proxy Bash per MANAGER
    hidden [bool] newManagerBashProxy([string]$packageManager, [string]$outputPath) {
        $templatePath = Join-Path $this.templatesPath "package-manager.bash.template"
        
        if (-not (Test-Path $templatePath)) {
            return $false
        }
        
        try {
            $template = Get-Content -Path $templatePath -Raw -Encoding UTF8
            $settingsFileGit = $this.convertToGitBashPath($this.settingsFile)
            $versionsPathGit = $this.convertToGitBashPath($this.versionsPath)
            $scriptPathGit = $this.convertToGitBashPath($this.scriptPath)
            
            $content = $template -replace '\{\{SETTINGS_FILE\}\}', $settingsFileGit
            $content = $content -replace '\{\{VERSIONS_PATH\}\}', $versionsPathGit
            $content = $content -replace '\{\{PM_NAME\}\}', $packageManager
            $content = $content -replace '\{\{SCRIPT_PATH\}\}', $scriptPathGit
            
            $content = $content -replace "`r`n", "`n"
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($outputPath, $content, $utf8NoBom)
            return $true
        } catch {
            return $false
        }
    }

    # Crea un proxy (CMD + Bash se disponibile) in base al ruolo
    hidden [bool] createProxy([string]$name, [string]$commandExe, [ProxyRole]$role, [string]$mode) {
        # Determina il nome del file in base alla modalità
        $prefix = if ($mode -eq "isolated") { "nlocal-" } else { "" }
        
        $cmdFileName = "$prefix$name.cmd"
        $bashFileName = "$prefix$name"
        
        $cmdPath = Join-Path $this.binPath $cmdFileName
        $bashPath = Join-Path $this.binPath $bashFileName
        
        $success = $false
        
        if ($role -eq [ProxyRole]::COMMAND) {
            # Per node, crea uno shim .exe invece di .cmd
            if ($name -ieq "node") {
                $exeFileName = "$prefix$name.exe"
                $exePath = Join-Path $this.binPath $exeFileName
                
                # Prova a creare lo shim .exe (può fallire se esiste già)
                $exeSuccess = $this.newNodeExeShim($exePath, $commandExe)
                
                # Se lo shim esiste (creato ora o già presente), consideralo un successo
                if (Test-Path $exePath) {
                    $success = $true
                } else {
                    $success = $exeSuccess
                }
                
                # Crea SEMPRE il proxy bash per Git Bash (indipendente dallo shim .exe)
                if ($this.bashAvailable) {
                    $this.newCommandBashProxy($name, $commandExe, $bashPath) | Out-Null
                }
            } else {
                # Per tutti gli altri comandi, comportamento normale
                $success = $this.newCommandProxy($name, $commandExe, $cmdPath)
                if ($success -and $this.bashAvailable) {
                    $this.newCommandBashProxy($name, $commandExe, $bashPath) | Out-Null
                }
            }
        } elseif ($role -eq [ProxyRole]::MANAGER) {
            $success = $this.newManagerProxy($name, $cmdPath)
            if ($success -and $this.bashAvailable) {
                $this.newManagerBashProxy($name, $bashPath) | Out-Null
            }
        }
        
        return $success
    }

    # =============================================================================
    # Metodi pubblici per creazione proxy
    # =============================================================================

    # Crea i proxy per un'installazione
    # $installation: oggetto InstallationClass
    # $onlyCommands: se true crea solo COMMAND, se false crea anche MANAGER
    # Ritorna array con conteggio [commandsCreated, managersCreated]
    [int[]] createProxies([object]$installation, [bool]$onlyCommands, [string]$mode) {
        $commandsCreated = 0
        $managersCreated = 0
        
        $versionPath = $installation.getPath()
        
        if (-not (Test-Path $versionPath)) {
            return @($commandsCreated, $managersCreated)
        }
        
        # Trova tutti i file .cmd e .exe nella cartella dell'installazione
        $files = Get-ChildItem -Path $versionPath -File -ErrorAction SilentlyContinue | 
            Where-Object { $_.Extension -in @('.cmd', '.exe') }
                
        foreach ($file in $files) {
            $baseName = $file.BaseName
            $commandExe = $file.Name
            
            # Determina se è un MANAGER o un COMMAND
            $isManager = $baseName -in [Proxies]::PackageManagers
            
            # Se onlyCommands è true, salta i manager
            if ($onlyCommands -and $isManager) {
                continue
            }
            
            # Crea il proxy
            if ($isManager) {
                if ($this.createProxy($baseName, $commandExe, [ProxyRole]::MANAGER, $mode)) {
                    $managersCreated++
                }
            } else {
                if ($this.createProxy($baseName, $commandExe, [ProxyRole]::COMMAND, $mode)) {
                    $commandsCreated++
                }
            }
        }
        
        return @($commandsCreated, $managersCreated)
    }

    # =============================================================================
    # Metodi esistenti per gestione proxy
    # =============================================================================

    # Metodo privato che restituisce tutti i nomi file dei package manager
    # (con e senza estensione, modalità override e isolated)
    hidden [string[]] getAllManagersFilesName() {
        $files = @()
        
        foreach ($pm in [Proxies]::PackageManagers) {
            $files += $pm              # bash (senza estensione)
            $files += "$pm.cmd"        # cmd
            $files += "nlocal-$pm"     # bash isolated
            $files += "nlocal-$pm.cmd" # cmd isolated
        }
        
        return $files
    }

    # Metodo privato che elimina tutti i file dalla cartella bin
    # eccetto i package manager e i file in NotDelete
    hidden [void] deleteAllButNotManagers() {
        $allProxies = $this.getProxies()
        
        foreach ($proxy in $allProxies) {
            if ($proxy.isCommand()) {
                Remove-Item -Path $proxy.path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Metodo privato che elimina tutti i file dei package manager dalla cartella bin
    hidden [void] deleteAllManagers() {
        $allProxies = $this.getProxies()
        
        foreach ($proxy in $allProxies) {
            if ($proxy.isManager()) {
                Remove-Item -Path $proxy.path -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # Elimina tutti i comandi dinamici (mantiene package manager e NotDelete)
    [void] clearDynamicCommands() {
        $this.deleteAllButNotManagers()
    }

    # Elimina tutti i comandi (dinamici + package manager, mantiene solo NotDelete)
    [void] clearAllCommands() {
        $this.deleteAllButNotManagers()
        $this.deleteAllManagers()
    }

    # Restituisce un array di oggetti Proxy per tutti i file nella cartella bin
    [Proxy[]] getProxies() {
        if (-not (Test-Path $this.binPath)) {
            return @()
        }

        $proxies = @()
        $managerFiles = $this.getAllManagersFilesName()

        Get-ChildItem -Path $this.binPath -File -ErrorAction SilentlyContinue | ForEach-Object {
            # Salta i file in NotDelete
            if ($_.Name -in [Proxies]::NotDelete) {
                return
            }

            $fileName = $_.Name
            $filePath = $_.FullName

            # Determina il tipo di proxy (CMD o BASH)
            $type = if ($_.Extension -eq '.cmd') { 
                [ProxyType]::CMD 
            } else { 
                [ProxyType]::BASH 
            }

            # Determina il ruolo (MANAGER o COMMAND)
            $role = if ($fileName -in $managerFiles) { 
                [ProxyRole]::MANAGER 
            } else { 
                [ProxyRole]::COMMAND 
            }

            $proxy = [Proxy]::new($fileName, $filePath, $type, $role)
            $proxies += $proxy
        }

        return $proxies
    }
}