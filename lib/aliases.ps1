# =============================================================================
# aliases.ps1 - Gestione alias per versioni Node.js (Sistema Cartelle)
# =============================================================================
# Sistema alias basato su nomi cartelle invece di JSON

# Ottiene tutte le "installazioni" (cartelle in versions/)
function Get-AllInstallations {
    if (-not (Test-Path $Script:VersionsPath)) {
        return @()
    }
    
    $installations = @()
    $folders = Get-ChildItem -Path $Script:VersionsPath -Directory -ErrorAction SilentlyContinue
    
    foreach ($folder in $folders) {
        $nodeExe = Join-Path $folder.FullName "node.exe"
        if (Test-Path $nodeExe) {
            try {
                # Ottieni versione Node dall'eseguibile
                $versionOutput = & $nodeExe --version 2>$null
                if ($versionOutput) {
                    $version = $versionOutput.TrimStart('v')
                    $installations += @(
                        @{
                            Name = $folder.Name
                            Version = $version
                            Path = $folder.FullName
                            NodeExe = $nodeExe
                        }
                    )
                }
            } catch {
                # Se non riesce a leggere la versione, salta
                continue
            }
        }
    }
    
    # Ritorna sempre un array, anche se vuoto o con 1 elemento
    return $installations
}

# Trova un'installazione per nome (alias o versione)
function Find-Installation {
    param([string]$NameOrVersion)
    
    $installations = Get-AllInstallations
    
    # Prima cerca per nome esatto
    $installation = $installations | Where-Object { $_.Name -eq $NameOrVersion }
    if ($installation) {
        return $installation
    }
    
    # Poi cerca per versione
    $installation = $installations | Where-Object { $_.Version -eq $NameOrVersion }
    if ($installation) {
        return $installation
    }
    
    return $null
}

# Verifica se un nome di installazione esiste già
function Test-InstallationExists {
    param([string]$Name)
    
    $installationPath = Join-Path $Script:VersionsPath $Name
    return Test-Path $installationPath
}

# Ottiene il nome dell'installazione corrente
function Get-CurrentInstallationName {
    return Get-CurrentVersion  # Ora settings.txt contiene il nome cartella
}

# Ottiene l'installazione corrente come oggetto completo
function Get-CurrentInstallation {
    $currentName = Get-CurrentInstallationName
    if ($currentName) {
        return Find-Installation -Name $currentName
    }
    return $null
}

# Valida nome per installazione/alias
function Test-ValidInstallationName {
    param([string]$Name)
    
    # Valida caratteri (solo alfanumerici, trattini, underscore e punti)
    if ($Name -notmatch '^[a-zA-Z0-9._-]+$') {
        return $false
    }
    
    # Non permettere nomi che iniziano con punto
    if ($Name.StartsWith('.')) {
        return $false
    }
    
    # Non permettere nomi riservati di Windows
    $reservedNames = @('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9')
    if ($reservedNames -contains $Name.ToUpper()) {
        return $false
    }
    
    return $true
}