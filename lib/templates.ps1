# lib/templates.ps1 - Gestione template per proxy CMD
# Questo modulo fornisce funzioni per generare proxy CMD da template

function New-GenericProxy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$SettingsFile,
        
        [Parameter(Mandatory=$true)]
        [string]$VersionsPath,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandName,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandExe
    )
    
    try {
        # Leggi il template
        if (-not (Test-Path $TemplatePath)) {
            throw "Template non trovato: $TemplatePath"
        }
        
        $template = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
        
        # Sostituisci i placeholder
        $content = $template -replace '\{\{SETTINGS_FILE\}\}', $SettingsFile
        $content = $content -replace '\{\{VERSIONS_PATH\}\}', $VersionsPath
        $content = $content -replace '\{\{COMMAND_NAME\}\}', $CommandName.ToUpper()
        $content = $content -replace '\{\{COMMAND_EXE\}\}', $CommandExe
        
        # Scrivi il file proxy
        $content | Out-File -FilePath $OutputPath -Encoding ASCII -NoNewline
        
        return $true
    }
    catch {
        Write-Error "Errore nella generazione del proxy generico: $_"
        return $false
    }
}

function New-PackageManagerProxy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$SettingsFile,
        
        [Parameter(Mandatory=$true)]
        [string]$VersionsPath,
        
        [Parameter(Mandatory=$true)]
        [string]$PackageManager,
        
        [Parameter(Mandatory=$false)]
        [string]$ScriptPath = ""
    )
    
    try {
        # Leggi il template
        if (-not (Test-Path $TemplatePath)) {
            throw "Template non trovato: $TemplatePath"
        }
        
        $template = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
        
        # Sostituisci i placeholder
        $content = $template -replace '\{\{SETTINGS_FILE\}\}', $SettingsFile
        $content = $content -replace '\{\{VERSIONS_PATH\}\}', $VersionsPath
        $content = $content -replace '\{\{PM_NAME\}\}', $PackageManager
        
        # Se ScriptPath è specificato, sostituiscilo, altrimenti usa il path del proxy
        if ($ScriptPath) {
            $content = $content -replace '\{\{SCRIPT_PATH\}\}', $ScriptPath
        } else {
            $content = $content -replace '\{\{SCRIPT_PATH\}\}', "%APPDATA%\node-local\bin\node-local.ps1"
        }
        
        # Scrivi il file proxy
        $content | Out-File -FilePath $OutputPath -Encoding ASCII -NoNewline
        
        return $true
    }
    catch {
        Write-Error "Errore nella generazione del proxy package manager: $_"
        return $false
    }
}

function Get-TemplatesPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ScriptDir
    )
    
    return Join-Path $ScriptDir "templates"
}

# =============================================================================
# Path Conversion Utilities
# =============================================================================

# Converte un path Windows in formato Git Bash
# Es: C:\Users\mlelli\AppData\Roaming\node-local\settings.txt
#  → /c/Users/mlelli/AppData/Roaming/node-local/settings.txt
function ConvertTo-GitBashPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WindowsPath
    )
    
    # Converti backslash a forward slash
    $bashPath = $WindowsPath -replace '\\', '/'
    
    # Converti drive letter (C: → /c)
    if ($bashPath -match '^([A-Za-z]):') {
        $drive = $matches[1].ToLower()
        $bashPath = '/' + $drive + ($bashPath -replace '^[A-Za-z]:', '')
    }
    
    return $bashPath
}

# =============================================================================
# Verifica disponibilità bash
# =============================================================================

function Test-BashAvailable {
    $bashCmd = Get-Command bash -ErrorAction SilentlyContinue
    return $null -ne $bashCmd
}

# =============================================================================
# Proxy Bash (per Git Bash e shell UNIX-like)
# =============================================================================

function New-GenericBashProxy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$SettingsFile,
        
        [Parameter(Mandatory=$true)]
        [string]$VersionsPath,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandName,
        
        [Parameter(Mandatory=$true)]
        [string]$CommandExe
    )
    
    try {
        # Leggi il template bash
        if (-not (Test-Path $TemplatePath)) {
            throw "Template bash non trovato: $TemplatePath"
        }
        
        $template = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
        
        # Converti i path Windows in path Git Bash
        $settingsFileGit = ConvertTo-GitBashPath -WindowsPath $SettingsFile
        $versionsPathGit = ConvertTo-GitBashPath -WindowsPath $VersionsPath
        
        # Sostituisci i placeholder SENZA escapare - sono path semplici
        $content = $template -replace '\{\{SETTINGS_FILE\}\}', $settingsFileGit
        $content = $content -replace '\{\{VERSIONS_PATH\}\}', $versionsPathGit
        $content = $content -replace '\{\{COMMAND_NAME\}\}', $CommandName.ToUpper()
        $content = $content -replace '\{\{COMMAND_EXE\}\}', $CommandExe
        
        # Scrivi il file proxy in UTF-8 senza BOM, con line endings LF per bash
        $content = $content -replace "`r`n", "`n"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($OutputPath, $content, $utf8NoBom)
        
        return $true
    }
    catch {
        Write-Error "Errore nella generazione del proxy bash generico: $_"
        return $false
    }
}

function New-PackageManagerBashProxy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$SettingsFile,
        
        [Parameter(Mandatory=$true)]
        [string]$VersionsPath,
        
        [Parameter(Mandatory=$true)]
        [string]$PackageManager,
        
        [Parameter(Mandatory=$false)]
        [string]$ScriptPath = ""
    )
    
    try {
        # Leggi il template bash
        if (-not (Test-Path $TemplatePath)) {
            throw "Template bash package-manager non trovato: $TemplatePath"
        }
        
        $template = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
        
        # Converti i path Windows in path Git Bash
        $settingsFileGit = ConvertTo-GitBashPath -WindowsPath $SettingsFile
        $versionsPathGit = ConvertTo-GitBashPath -WindowsPath $VersionsPath
        
        # Sostituisci i placeholder SENZA escapare - sono path semplici
        $content = $template -replace '\{\{SETTINGS_FILE\}\}', $settingsFileGit
        $content = $content -replace '\{\{VERSIONS_PATH\}\}', $versionsPathGit
        $content = $content -replace '\{\{PM_NAME\}\}', $PackageManager
        
        # Converti ScriptPath
        if ($ScriptPath) {
            $scriptPathGit = ConvertTo-GitBashPath -WindowsPath $ScriptPath
            $content = $content -replace '\{\{SCRIPT_PATH\}\}', $scriptPathGit
        }
        
        # Scrivi il file proxy in UTF-8 senza BOM, con line endings LF per bash
        $content = $content -replace "`r`n", "`n"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($OutputPath, $content, $utf8NoBom)
        
        return $true
    }
    catch {
        Write-Error "Errore nella generazione del proxy bash package-manager: $_"
        return $false
    }
}