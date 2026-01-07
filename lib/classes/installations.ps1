# Classe per gestire la collezione di installazioni
class Installations {

    # Metodo privato per leggere il nome dell'installazione corrente da settings.txt
    hidden [string] _getCurrentInstallationName() {
        $config = [ConfigurationClass]::GetInstance()
        $sFile = $config.settingsFile
        if (Test-Path $sFile) {
            $content = Get-Content $sFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content) {
                return $content.Trim() -replace '^\uFEFF', ''
            }
        }
        return $null
    }

    [InstallationClass[]] getAll() {
        $config = [ConfigurationClass]::GetInstance()
        $vPath = $config.versionsPath
        $sFile = $config.settingsFile
        
        if (-not (Test-Path $vPath)) {
            return @()
        }
        $installations = @()
        $folders = Get-ChildItem -Path $vPath -Directory -ErrorAction SilentlyContinue

        # Ottieni il nome dell'installazione corrente
        $currentName = $null
        if (Test-Path $sFile) {
            $content = Get-Content $sFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content) {
                $currentName = $content.Trim() -replace '^\uFEFF', ''
            }
        }

        foreach ($folder in $folders) {
            $nodeExe = Join-Path $folder.FullName "node.exe"
            if (Test-Path $nodeExe) {
                try {
                    # Ottieni versione Node dall'eseguibile
                    $versionOutput = & $nodeExe --version 2>$null
                    if ($versionOutput) {
                        $version = $versionOutput.TrimStart('v')
                        $isCurrentInstallation = ($folder.Name -eq $currentName)
                        $inst = [InstallationClass]::new(
                            $folder.name,
                            $version,
                            $folder,
                            [bool]$isCurrentInstallation,
                            $false,  # cache
                            $false   # downloaded
                        )
                        $installations += $inst
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

    # Ottiene le installazioni dalla cache (file zip)
    [InstallationClass[]] getAllFromCache() {
        $config = [ConfigurationClass]::GetInstance()
        $cPath = $config.cachePath
        
        if (-not (Test-Path $cPath)) {
            return @()
        }
        $installations = @()
        $zipFiles = Get-ChildItem -Path $cPath -Filter "*.zip" -File -ErrorAction SilentlyContinue

        foreach ($zipFile in $zipFiles) {
            # Estrai la versione dal nome del file (es. node-v20.11.0-win-x64.zip -> 20.11.0)
            if ($zipFile.Name -match 'node-v(\d+\.\d+\.\d+)') {
                $version = $matches[1]
                $inst = [InstallationClass]::new(
                    $version,
                    $version,
                    $zipFile.Directory,
                    $false,  # use
                    $true,   # cache
                    $true    # downloaded
                )
                $installations += $inst
            }
        }
    
        return $installations
    }

    # Cerca un'installazione per nome (nome cartella)
    [InstallationClass] find([string]$name) {
        $installations = $this.getAll()
        foreach ($installation in $installations) {
            if ($installation.getFolderName() -eq $name) {
                return $installation
            }
        }
        return $null
    }

    [InstallationClass] findExistence([string]$name, [bool]$returnIfOnlyOneExists) {
        $installations = $this.getAll()
        if ($installations.Count -eq 0) {
            throw [InstallationException]::NoneFound()
        }
        if (($installations.Count -eq 1) -and $returnIfOnlyOneExists) {
            # Se ce n'è una sola, ritornala se flag è attivo
            return $installations[0]
        }
        foreach ($installation in $installations) {
            if ($installation.getFolderName() -eq $name) {
                return $installation
            }
        }
        throw [InstallationException]::NotFound(
            "Impossibile trovare l'installazione",
            $name,
            $installations.Count
        )
    }

    # Verifica se un'installazione esiste
    [bool] exists([string]$name) {
        return $null -ne $this.find($name)
    }

    # Ottiene l'installazione corrente (da settings.txt)
    [InstallationClass] getCurrent() {
        $currentName = $this._getCurrentInstallationName()
        if ($currentName) {
            return $this.find($currentName)
        }
        return $null
    }

    # Rinomina un'installazione solo se il nuovo nome non esiste già e non è invalido
    # Lancia AliasAlreadyExistError se esiste già un'installazione con quel nome
    # Lancia AliasNotValidError se il nome contiene caratteri non validi
    [void] renameIfNotExist([InstallationClass]$installation, [string]$newName) {
        # Normalizza il nome
        $normalizedName = $newName.Trim().ToLower()
        
        # Verifica caratteri non validi nel nome file
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        foreach ($char in $invalidChars) {
            if ($normalizedName.Contains($char)) {
                if ([string]::IsNullOrWhiteSpace($newName)) {
                    throw [AliasException]::NotValid()
                } else {
                    throw [AliasException]::NotValid($newName)
                }
            }
        }
        
        # Verifica che il nome non sia vuoto dopo il trim
        if ([string]::IsNullOrWhiteSpace($normalizedName)) {
            throw [AliasException]::NotValid()
        }
        
        # Verifica che non esista già un'installazione con quel nome
        $allInstallations = $this.getAll()
        foreach ($inst in $allInstallations) {
            if ($inst.getFolderName().ToLower() -eq $normalizedName) {
                throw [AliasException]::AlreadyExist($newName)
            }
        }
        
        # Rinomina la cartella dell'installazione
        $oldPath = $installation.getPath()
        $newPath = Join-Path (Split-Path $oldPath -Parent) $newName
        
        Rename-Item -Path $oldPath -NewName $newName -Force
        
        # Se l'installazione rinominata è quella corrente, aggiorna settings.txt
        $currentName = $this._getCurrentInstallationName()
        if ($currentName -eq $installation.getFolderName()) {
            $config = [ConfigurationClass]::GetInstance()
            $sFile = $config.settingsFile
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($sFile, $newName, $utf8NoBom)
        }
    }

    # Ottiene le versioni remote da nodejs.org API
    # Incrocia con le installazioni locali per settare downloaded e use
    [InstallationClass[]] getAllRemote([int]$limit, [bool]$ltsOnly) {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("User-Agent", "node-local/1.0")
            
            $jsonData = $webClient.DownloadString("https://nodejs.org/dist/index.json")
            $remoteVersions = $jsonData | ConvertFrom-Json
            
            # Ottieni le versioni locali per incrociare i dati
            $localInstallations = $this.getAll()
            
            # Crea mappa versione -> lista di alias
            # Una versione può avere più alias (es. "prod" e "staging" usano la stessa 24.11.1)
            $versionToAliases = @{}
            $versionToFolder = @{}
            foreach ($local in $localInstallations) {
                $ver = $local.version
                if (-not $versionToAliases.ContainsKey($ver)) {
                    $versionToAliases[$ver] = @()
                    $versionToFolder[$ver] = $local.folder
                }
                $versionToAliases[$ver] += $local.name
            }
            
            # Ottieni versioni dalla cache
            $cachedInstallations = $this.getAllFromCache()
            $cachedVersions = @{}
            foreach ($cached in $cachedInstallations) {
                $cachedVersions[$cached.version] = $cached
            }
            
            # Versione corrente in uso
            $currentInstallation = $this.getCurrent()
            $currentVersion = if ($currentInstallation) { $currentInstallation.version } else { $null }
            
            # Filtra LTS se richiesto
            if ($ltsOnly) {
                $remoteVersions = $remoteVersions | Where-Object { $_.lts -ne $false }
            }
            
            # Limita il numero
            if ($limit -gt 0) {
                $remoteVersions = $remoteVersions | Select-Object -First $limit
            }
            
            $installations = @()
            $isFirst = $true
            
            foreach ($rv in $remoteVersions) {
                $versionNumber = $rv.version -replace '^v', ''
                
                # Determina se è scaricata (locale o cache)
                $isDownloaded = $versionToAliases.ContainsKey($versionNumber) -or $cachedVersions.ContainsKey($versionNumber)
                
                # Determina se è in uso
                $isUse = ($currentVersion -eq $versionNumber)
                
                # Determina se è LTS
                $isLts = $rv.lts -ne $false
                $ltsName = if ($rv.lts -is [string]) { $rv.lts } else { "" }
                
                # La prima versione nella lista è sempre "current"
                $isCurrent = $isFirst
                $isFirst = $false
                
                # Folder è null per installazioni remote non scaricate
                $folder = $null
                if ($versionToFolder.ContainsKey($versionNumber)) {
                    $folder = $versionToFolder[$versionNumber]
                }
                
                # Ottieni gli alias per questa versione
                $aliases = @()
                if ($versionToAliases.ContainsKey($versionNumber)) {
                    $aliases = $versionToAliases[$versionNumber]
                }
                
                $inst = [InstallationClass]::new(
                    $versionNumber,      # name
                    $versionNumber,      # version
                    $folder,             # folder (null se non scaricata)
                    $isUse,              # use
                    $cachedVersions.ContainsKey($versionNumber),  # cache
                    $isDownloaded,       # downloaded
                    $true,               # remote (proviene da nodejs.org)
                    $isLts,              # lts
                    $ltsName,            # ltsName
                    $isCurrent,          # current
                    $aliases             # aliases
                )
                $installations += $inst
            }
            
            return $installations
        }
        catch {
            # Rilancia l'eccezione - la gestione del messaggio è compito del chiamante
            throw
        }
        finally {
            if ($webClient) {
                $webClient.Dispose()
            }
        }
    }

    # Overload senza parametri (default: 20 versioni, tutte)
    [InstallationClass[]] getAllRemote() {
        return $this.getAllRemote(20, $false)
    }

    # Overload con solo LTS flag
    [InstallationClass[]] getAllRemoteLts([int]$limit) {
        return $this.getAllRemote($limit, $true)
    }

    # =============================================================================
    # METODI PER PREPARAZIONE INSTALLAZIONE
    # =============================================================================

    # Factory: crea richiesta installazione validata
    # Ritorna un oggetto InstallationClass "preparato" (non ancora installato fisicamente)
    [InstallationClass] PrepareInstallation([string]$version, [string]$alias) {
        $cleanVersion = $version -replace '^v', ''
        $name = if ($alias) { $alias } else { $cleanVersion }
        
        # Validazione nome (caratteri invalidi)
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        foreach ($char in $invalidChars) {
            if ($name.Contains($char)) {
                throw [AliasException]::NotValid($name)
            }
        }
        
        # Verifica se nome è vuoto
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw [AliasException]::NotValid($name)
        }
        
        # Verifica se esiste già - se sì, errore
        if ($this.exists($name)) {
            $existing = $this.find($name)
            $existingVersion = $existing.version
            throw [InstallationException]::NotFound("L'installazione '$name' esiste già (versione: v$existingVersion)", $name)
        }
        
        # Crea oggetto installazione "preparato"
        $config = [ConfigurationClass]::GetInstance()
        $versionsPath = $config.versionsPath
        $installPath = (Join-Path $config.versionsPath $name)
        
        # Assicura che la directory versions esista
        if (-not (Test-Path $versionsPath)) {
            New-Item -ItemType Directory -Path $versionsPath -Force | Out-Null
        }
        
        return [InstallationClass]::new(
            $name,
            $cleanVersion,
            [System.IO.DirectoryInfo]::new($installPath),
            $false,  # use
            $false,  # cache
            $false   # downloaded
        )
    }
}
