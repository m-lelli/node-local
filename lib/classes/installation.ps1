# Classe che rappresenta una singola installazione di Node.js
class InstallationClass {
    [string]$name
    [string]$version
    [System.IO.DirectoryInfo]$folder
    [bool]$use
    [bool]$cache
    [bool]$downloaded
    [bool]$remote      # true se proviene da nodejs.org API
    [bool]$lts         # true se è una versione LTS
    [string]$ltsName   # nome codename LTS (es. "iron", "hydrogen"), vuoto se non LTS
    [bool]$current     # true se è la versione più recente disponibile su nodejs.org
    [string[]]$aliases # lista degli alias locali che usano questa versione

    # Costruttore per installazioni locali (retrocompatibile)
    InstallationClass([string]$name, [string]$version, $folder, [bool]$use, [bool]$cache, [bool]$downloaded) {
        $this.name = $name
        $this.version = $version
        $this.folder = $folder
        $this.use = $use
        $this.cache = $cache
        $this.downloaded = $downloaded
        $this.remote = $false
        $this.lts = $false
        $this.ltsName = ""
        $this.current = $false
        $this.aliases = @()
    }

    # Costruttore completo con tutti i flag
    InstallationClass([string]$name, [string]$version, $folder, [bool]$use, [bool]$cache, [bool]$downloaded, [bool]$remote, [bool]$lts, [string]$ltsName, [bool]$current) {
        $this.name = $name
        $this.version = $version
        $this.folder = $folder
        $this.use = $use
        $this.cache = $cache
        $this.downloaded = $downloaded
        $this.remote = $remote
        $this.lts = $lts
        $this.ltsName = $ltsName
        $this.current = $current
        $this.aliases = @()
    }

    # Costruttore completo con aliases
    InstallationClass([string]$name, [string]$version, $folder, [bool]$use, [bool]$cache, [bool]$downloaded, [bool]$remote, [bool]$lts, [string]$ltsName, [bool]$current, [string[]]$aliases) {
        $this.name = $name
        $this.version = $version
        $this.folder = $folder
        $this.use = $use
        $this.cache = $cache
        $this.downloaded = $downloaded
        $this.remote = $remote
        $this.lts = $lts
        $this.ltsName = $ltsName
        $this.current = $current
        $this.aliases = $aliases
    }

    [string] getFolderName() {
        if ($this.folder) {
            return $this.folder.Name
        }
        return $this.name
    }

    [string] getVersion() {
        return $this.version
    }

    [string] getPath() {
        if ($this.folder) {
            return $this.folder.FullName
        }
        return $null
    }

    [string] getNodeJsExePath() {
        if ($this.folder) {
            return Join-Path $this.folder.FullName "node.exe"
        }
        return $null
    }

    # Restituisce il nome LTS formattato (es. "lts (iron)") o stringa vuota se non LTS
    [string] getLtsLabel() {
        if ($this.lts -and $this.ltsName) {
            return "lts ($($this.ltsName.ToLower()))"
        } elseif ($this.lts) {
            return "lts"
        }
        return ""
    }

    # Restituisce le note formattate (current, lts)
    [string] getNotesLabel() {
        $notes = @()
        if ($this.current) { $notes += "current" }
        if ($this.lts) {
            $notes += $this.getLtsLabel()
        }
        return ($notes -join ", ")
    }

    # Restituisce gli alias formattati come stringa (es. "prod, staging")
    [string] getAliasesLabel() {
        if ($this.aliases -and $this.aliases.Count -gt 0) {
            return ($this.aliases -join ", ")
        }
        return ""
    }

    # =============================================================================
    # METODI PER INSTALLAZIONE
    # =============================================================================

    # Scarica Node.js (gestisce cache, download, checksum) - ritorna il path del file ZIP
    [string] DownloadNode([string]$tempDir) {
        # Delega tutto alla classe Network
        return [Network]::DownloadNodeVersion($this.version, $tempDir)
    }

    # Installa da ZIP
    [void] InstallFromZip([string]$zipPath) {
        # Verifica integrità ZIP
        [Network]::VerifyZipIntegrity($zipPath)
        
        # Estrazione
        $tempDir = Split-Path $zipPath -Parent
        $extractPath = Join-Path $tempDir "extracted"
        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
        
        $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $expectedFolder = "node-v$($this.version)-win-$arch"
        
        $extractedFolder = Expand-ZipFile `
            -ZipFile $zipPath `
            -OutputDirectory $extractPath `
            -ExpectedFolderName $expectedFolder `
            -Message "Estrazione..."
        
        if (-not $extractedFolder) {
            throw [InstallationException]::ExtractionFailed()
        }
        
        # Copia
        $copySuccess = Copy-DirectoryWithRobocopy `
            -Source $extractedFolder.FullName `
            -Destination $this.getPath() `
            -Message "Copia..."
        
        if (-not $copySuccess) {
            throw [InstallationException]::CopyFailed()
        }
        
        # Cleanup
        $cleanupJob = Remove-TempDirectory -Path $tempDir -Message "Pulizia file temporanei..."
        if ($cleanupJob) {
            Wait-WithSpinner -Job $cleanupJob -Message "Pulizia..." -Color Cyan | Out-Null
        }
    }

    # Verifica se l'installazione è valida (ha node.exe)
    [bool] IsValid() {
        $nodeExe = $this.getNodeJsExePath()
        if ($nodeExe) {
            return (Test-Path $nodeExe)
        }
        return $false
    }
}
