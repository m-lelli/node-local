# =============================================================================
# upgrade.ps1 - Gestione upgrade versioni Node.js
# =============================================================================
# Funzioni per l'upgrade guidato delle versioni installate

# Confronta due versioni semantiche (ritorna -1 se v1 < v2, 0 se uguali, 1 se v1 > v2)
function Compare-SemanticVersion {
    param(
        [string]$Version1,
        [string]$Version2
    )
    
    $v1Parts = $Version1 -split '\.' | ForEach-Object { [int]$_ }
    $v2Parts = $Version2 -split '\.' | ForEach-Object { [int]$_ }
    
    for ($i = 0; $i -lt [Math]::Max($v1Parts.Count, $v2Parts.Count); $i++) {
        $v1Part = if ($i -lt $v1Parts.Count) { $v1Parts[$i] } else { 0 }
        $v2Part = if ($i -lt $v2Parts.Count) { $v2Parts[$i] } else { 0 }
        
        if ($v1Part -lt $v2Part) { return -1 }
        if ($v1Part -gt $v2Part) { return 1 }
    }
    
    return 0
}

# Raggruppa versioni per major release (solo versioni > corrente per upgrade)
function Get-VersionsByMajor {
    param(
        [array]$RemoteVersions,
        [string]$CurrentVersion,
        [switch]$OnlyUpgrade
    )
    
    $versionsByMajor = @{}
    foreach ($version in $RemoteVersions) {
        $versionNumber = $version.version -replace '^v', ''
        
        # Filtra solo versioni > corrente se OnlyUpgrade
        if ($OnlyUpgrade) {
            $comparison = Compare-SemanticVersion -Version1 $versionNumber -Version2 $CurrentVersion
            if ($comparison -le 0) {
                # Versione <= corrente, skip
                continue
            }
        }
        
        $major = [int]($versionNumber -split '\.')[0]
        
        if (-not $versionsByMajor.ContainsKey($major)) {
            $versionsByMajor[$major] = @()
        }
        
        $versionsByMajor[$major] += @{
            Number = $versionNumber
            IsLTS = $version.lts -ne $false
            LTSName = if ($version.lts -is [string]) { $version.lts } else { $null }
        }
    }
    
    return $versionsByMajor
}

# Step 1: Selezione Major Release
function Select-MajorRelease {
    param(
        [string]$CurrentVersion,
        [array]$RemoteVersions,
        [switch]$OnlyUpgrade
    )
    
    $currentMajor = [int]($CurrentVersion -split '\.')[0]
    
    Write-Host "`nVersione corrente: v$CurrentVersion (Node.js $currentMajor.x)" -ForegroundColor Cyan


    
    # Raggruppa versioni per major
    $versionsByMajor = Get-VersionsByMajor -RemoteVersions $RemoteVersions -CurrentVersion $CurrentVersion -OnlyUpgrade:$OnlyUpgrade
    
    if ($versionsByMajor.Count -eq 0) {
        if ($OnlyUpgrade) {
            Write-Host "`nNon ci sono versioni piu recenti disponibili per l'upgrade." -ForegroundColor Yellow
        } else {
            Write-Host "`nNessuna versione disponibile." -ForegroundColor Yellow
        }
        return $null
    }
    
    # Ordina major releases
    $sortedMajors = $versionsByMajor.Keys | Sort-Object -Descending
    
    Write-Host "`nSeleziona la major release:" -ForegroundColor Yellow
    Write-Host ""
    
    # Mostra menu major releases
    $index = 1
    $majorMap = @{}
    
    foreach ($major in $sortedMajors) {
        $majorMap[$index] = $major
        $versions = $versionsByMajor[$major]
        
        # Conta versioni LTS in questa major
        $ltsCount = ($versions | Where-Object { $_.IsLTS }).Count
        $totalCount = $versions.Count
        
        # Trova nome LTS se presente
        $ltsName = ($versions | Where-Object { $_.IsLTS } | Select-Object -First 1).LTSName
        
        $indexStr = "[$index]".PadRight(6)
        $majorStr = "Node.js $major.x".PadRight(20)
        
        # Badge e info
        $info = "$totalCount versioni disponibili"
        if ($ltsCount -gt 0) {
            if ($ltsName) {
                $info += " [LTS: $ltsName]"
            } else {
                $info += " [$ltsCount LTS]"
            }
        }
        
        # Colore e marker
        if ($major -eq $currentMajor) {
            Write-Host "  $indexStr $majorStr $info <- corrente" -ForegroundColor Yellow
        } elseif ($ltsCount -gt 0) {
            Write-Host "  $indexStr $majorStr $info" -ForegroundColor Green
        } else {
            Write-Host "  $indexStr $majorStr $info" -ForegroundColor White
        }
        
        $index++
    }
    
    Write-Host ""
    Write-Host "Digita il numero della major release (o 'q' per uscire): " -ForegroundColor Cyan -NoNewline
    
    $selection = Read-Host
    
    if ($selection -eq 'q' -or $selection -eq 'Q') {
        Write-Host "Operazione annullata." -ForegroundColor Yellow
        return $null
    }
    
    if (-not ($selection -match '^\d+$')) {
        Write-Host "`nErrore: Inserisci un numero valido." -ForegroundColor Red
        return $null
    }
    
    $selectedIndex = [int]$selection
    
    if (-not $majorMap.ContainsKey($selectedIndex)) {
        Write-Host "`nErrore: Selezione non valida." -ForegroundColor Red
        return $null
    }
    
    $selectedMajor = $majorMap[$selectedIndex]
    return @{
        Major = $selectedMajor
        Versions = $versionsByMajor[$selectedMajor]
    }
}

# Step 2: Selezione versione specifica all'interno della major
function Select-VersionFromMajor {
    param(
        [int]$Major,
        [array]$Versions,
        [string]$CurrentVersion
    )
    
    Write-Host ""
    Write-Host "--- Node.js $Major.x - Versioni disponibili " -ForegroundColor Cyan -NoNewline
    Write-Host ("-" * 40) -ForegroundColor Gray
    Write-Host ""
    
    $index = 1
    $versionMap = @{}
    
    foreach ($ver in $Versions) {
        $versionMap[$index] = $ver.Number
        
        $indexStr = "[$index]".PadRight(6)
        $versionStr = "v$($ver.Number)".PadRight(15)
        
        # Badge LTS
        $badge = ""
        if ($ver.IsLTS) {
            $ltsName = if ($ver.LTSName) { $ver.LTSName.ToLower() } else { "lts" }
            $badge = " [LTS: $ltsName]"
        }
        
        # Colore
        $color = if ($ver.IsLTS) { "Green" } else { "White" }
        
        # Marker versione corrente
        if ($ver.Number -eq $CurrentVersion) {
            Write-Host "  $indexStr $versionStr $badge <- versione corrente" -ForegroundColor Yellow
        } else {
            Write-Host "  $indexStr $versionStr $badge" -ForegroundColor $color
        }
        
        $index++
    }
    
    Write-Host ""
    Write-Host "Digita il numero della versione (o 'q' per uscire): " -ForegroundColor Cyan -NoNewline
    
    $selection = Read-Host
    
    if ($selection -eq 'q' -or $selection -eq 'Q') {
        Write-Host "Operazione annullata." -ForegroundColor Yellow
        return $null
    }
    
    if (-not ($selection -match '^\d+$')) {
        Write-Host "`nErrore: Inserisci un numero valido." -ForegroundColor Red
        return $null
    }
    
    $selectedIndex = [int]$selection
    
    if (-not $versionMap.ContainsKey($selectedIndex)) {
        Write-Host "`nErrore: Selezione non valida." -ForegroundColor Red
        return $null
    }
    
    return $versionMap[$selectedIndex]
}

# Prompt per selezione installazione da aggiornare
function Select-InstallationToUpgrade {
    $installations = Get-AllInstallations
    
    if ($installations.Count -eq 0) {
        Write-Host "`nNessuna installazione trovata." -ForegroundColor Yellow
        Write-Host "Usa 'node-local install `<version`>' per installare una versione." -ForegroundColor Gray
        return $null
    }
    
    Write-Host "`n=== Upgrade Node.js ===" -ForegroundColor Cyan
    Write-Host "`nSeleziona l'installazione da aggiornare:" -ForegroundColor Yellow
    Write-Host ""
    
    # Mostra lista installazioni con indici
    $index = 1
    $installationMap = @{}
    
    foreach ($installation in $installations | Sort-Object Name) {
        $installationMap[$index] = $installation
        
        $indexStr = "[$index]".PadRight(6)
        $nameStr = $installation.Name.PadRight(20)
        $versionStr = "Node.js $($installation.Version)"
        
        Write-Host "  $indexStr $nameStr $versionStr" -ForegroundColor White
        $index++
    }
    
    Write-Host ""
    Write-Host "Digita il numero dell'installazione (o 'q' per uscire): " -ForegroundColor Cyan -NoNewline
    
    $selection = Read-Host
    
    # Gestisci uscita
    if ($selection -eq 'q' -or $selection -eq 'Q') {
        Write-Host "Operazione annullata." -ForegroundColor Yellow
        return $null
    }
    
    # Valida input
    if (-not ($selection -match '^\d+$')) {
        Write-Host "`nErrore: Inserisci un numero valido." -ForegroundColor Red
        return $null
    }
    
    $selectedIndex = [int]$selection
    
    if (-not $installationMap.ContainsKey($selectedIndex)) {
        Write-Host "`nErrore: Selezione non valida." -ForegroundColor Red
        return $null
    }
    
    return $installationMap[$selectedIndex]
}

# Funzione principale di upgrade
function Start-NodeUpgrade {
    
    # Step 0: Verifica numero installazioni
    $allInstallations = Get-AllInstallations
    $isSingleInstallation = $allInstallations.Count -eq 1
    
    # Step 1: Seleziona installazione da aggiornare
    if ($isSingleInstallation) {
        # Caso singola installazione - selezione automatica
        $installation = $allInstallations[0]
        Write-Host "`n=== Upgrade Node.js ===" -ForegroundColor Cyan
        Write-Host "`nInstallazione rilevata: $($installation.Name) (Node.js $($installation.Version))" -ForegroundColor White
    } else {
        # Caso multiple installazioni - menu interattivo
        $installation = Select-InstallationToUpgrade
        
        if (-not $installation) {
            return
        }
        
        Write-Host "`n[OK] Selezionato: $($installation.Name) (attualmente Node.js $($installation.Version))" -ForegroundColor Green
    }
    
    # Step 2: Scarica lista versioni remote
    Write-Host "`nRecupero versioni disponibili..." -ForegroundColor Yellow
    
    $remoteVersions = Get-RemoteVersions
    
    if (-not $remoteVersions) {
        Write-Host "`nImpossibile recuperare le versioni remote. Verifica la connessione." -ForegroundColor Red
        return
    }
    
    Write-Host "[OK] Trovate $($remoteVersions.Count) versioni disponibili" -ForegroundColor Green
    
    # Step 3: Logica diversa per singola vs multiple installazioni
    $selectedVersion = $null
    
    if ($isSingleInstallation) {
        # CASO SINGOLA INSTALLAZIONE: Proposta upgrade alla latest
        $latestVersion = $remoteVersions[0].version -replace '^v', ''
        $isLTS = $remoteVersions[0].lts -ne $false
        $ltsName = if ($remoteVersions[0].lts -is [string]) { $remoteVersions[0].lts } else { "" }
        
        Write-Host ""


        Write-Host "UPGRADE RAPIDO DISPONIBILE" -ForegroundColor Cyan


        Write-Host ""
        Write-Host "Versione corrente: " -ForegroundColor White -NoNewline
        Write-Host "Node.js $($installation.Version)" -ForegroundColor Yellow
        Write-Host "Versione latest:   " -ForegroundColor White -NoNewline
        if ($isLTS) {
            Write-Host "Node.js $latestVersion [LTS: $ltsName]" -ForegroundColor Green
        } else {
            Write-Host "Node.js $latestVersion" -ForegroundColor Cyan
        }
        Write-Host ""
        Write-Host "Vuoi aggiornare direttamente alla versione latest? [S/n]: " -ForegroundColor Cyan -NoNewline
        
        $latestChoice = Read-Host
        
        if ($latestChoice -eq '' -or $latestChoice -eq 'S' -or $latestChoice -eq 's') {
            # Utente accetta upgrade alla latest
            $selectedVersion = $latestVersion
            Write-Host "`n[OK] Upgrade alla latest selezionato" -ForegroundColor Green
        } else {
            # Utente rifiuta - mostra menu TWO-STEP
            Write-Host "`nok, ti mostro tutte le versioni disponibili..." -ForegroundColor Yellow
            
            # Step 3a: Selezione major release
            $majorSelection = Select-MajorRelease -CurrentVersion $installation.Version -RemoteVersions $remoteVersions -OnlyUpgrade
            
            if (-not $majorSelection) {
                return
            }
            
            # Step 3b: Selezione versione specifica dalla major scelta
            $selectedVersion = Select-VersionFromMajor -Major $majorSelection.Major -Versions $majorSelection.Versions -CurrentVersion $installation.Version
            
            if (-not $selectedVersion) {
                return
            }
        }
    } else {
        # CASO MULTIPLE INSTALLAZIONI: Menu TWO-STEP diretto
        
        # Step 3a: Selezione major release
        $majorSelection = Select-MajorRelease -CurrentVersion $installation.Version -RemoteVersions $remoteVersions -OnlyUpgrade
        
        if (-not $majorSelection) {
            return
        }
        
        # Step 3b: Selezione versione specifica dalla major scelta
        $selectedVersion = Select-VersionFromMajor -Major $majorSelection.Major -Versions $majorSelection.Versions -CurrentVersion $installation.Version
        
        if (-not $selectedVersion) {
            return
        }
    }
    
    Write-Host "`n[OK] Versione selezionata: v$selectedVersion" -ForegroundColor Green
    
    # Step 5: Conferma operazione
    Write-Host ""


    Write-Host "RIEPILOGO UPGRADE:" -ForegroundColor Cyan
    Write-Host "  Installazione: $($installation.Name)" -ForegroundColor White
    Write-Host "  Versione attuale: $($installation.Version)" -ForegroundColor Yellow
    Write-Host "  Nuova versione: $selectedVersion" -ForegroundColor Green


    Write-Host ""
    Write-Host "L'upgrade sostituira la versione esistente con quella nuova." -ForegroundColor Yellow
    Write-Host "I pacchetti globali NON verranno preservati automaticamente." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Procedere con l'upgrade? [S/n]: " -ForegroundColor Cyan -NoNewline
    
    $confirm = Read-Host
    
    if ($confirm -ne '' -and $confirm -ne 'S' -and $confirm -ne 's') {
        Write-Host "`nUpgrade annullato." -ForegroundColor Yellow
        return
    }
    
    # Step 6: Prepara upgrade
    $targetAlias = $installation.Name
    $originalInstallation = $installation
    
    Write-Host ""
    Write-Host "=== Inizio procedura di upgrade ===" -ForegroundColor Cyan
    
    # 6a: Salva lista pacchetti globali correnti (se l'installazione e attiva)
    $currentInstallation = Get-CurrentInstallationName
    $shouldRestorePackages = $false
    $globalPackages = @()
    
    if ($currentInstallation -eq $installation.Name) {
        Write-Host "`nStep 1/3: Salvataggio lista pacchetti globali..." -ForegroundColor Yellow
        
        try {
            $npmListOutput = & (Join-Path $installation.Path "npm.cmd") list -g --depth=0 --json 2>$null
            if ($npmListOutput) {
                $npmList = $npmListOutput | ConvertFrom-Json
                if ($npmList.dependencies) {
                    $globalPackages = $npmList.dependencies.PSObject.Properties.Name | Where-Object { $_ -ne 'npm' }
                    
                    if ($globalPackages.Count -gt 0) {
                        Write-Host "  [OK] Trovati $($globalPackages.Count) pacchetti globali" -ForegroundColor Green
                        $shouldRestorePackages = $true
                        
                        foreach ($pkg in $globalPackages) {
                            Write-Host "    - $pkg" -ForegroundColor Gray
                        }
                    } else {
                        Write-Host "  $([char]0x2139) Nessun pacchetto globale installato" -ForegroundColor Gray
                    }
                }
            }
        } catch {
            Write-Host "  $([char]0x26A0) Impossibile leggere i pacchetti globali: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`nStep 1/3: Salvataggio pacchetti globali (saltato - installazione non attiva)" -ForegroundColor Gray
    }
    
    # 6b: Rimuovi vecchia installazione
    Write-Host "`nStep 2/3: Rimozione versione precedente..." -ForegroundColor Yellow
    
    try {
        # Usa robocopy per rimuovere cartelle con percorsi lunghi
        # Crea una cartella temporanea vuota
        $emptyDir = Join-Path $env:TEMP "node-local-empty-$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        
        # Usa robocopy per "mirror" (sincronizzare) la cartella vuota con quella da eliminare
        # Questo svuota efficacemente la cartella target
        $robocopyResult = robocopy "$emptyDir" "$($installation.Path)" /MIR /R:0 /W:0 /NP /NFL /NDL /NJH /NJS 2>&1
        
        # Rimuovi la cartella ora vuota e la cartella temporanea
        Remove-Item -Path $installation.Path -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
        
        Write-Host "  [OK] Versione precedente rimossa" -ForegroundColor Green
    } catch {
        Write-Host "  $([char]0x2717) Errore durante la rimozione: $_" -ForegroundColor Red
        Write-Host "`nUpgrade fallito. La vecchia installazione potrebbe essere ancora presente." -ForegroundColor Red
        return
    }
    
    # 6c: Installa nuova versione
    Write-Host "`nStep 3/3: Installazione nuova versione..." -ForegroundColor Yellow
    
    Install-NodeVersion -Version $selectedVersion -AliasName $targetAlias
    
    # Verifica che l'installazione sia andata a buon fine
    $newInstallationPath = Join-Path $Script:VersionsPath $targetAlias
    if (-not (Test-Path $newInstallationPath)) {
        Write-Host "`nInstallazione fallita. Verifica gli errori sopra." -ForegroundColor Red
        return
    }
    
    # 6d: Reinstalla pacchetti globali (opzionale)
    if ($shouldRestorePackages -and $globalPackages.Count -gt 0) {
        Write-Host ""


        Write-Host "RIPRISTINO PACCHETTI GLOBALI" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Vuoi reinstallare i $($globalPackages.Count) pacchetti globali? [S/n]: " -ForegroundColor Yellow -NoNewline
        
        $restoreConfirm = Read-Host
        
        if ($restoreConfirm -eq '' -or $restoreConfirm -eq 'S' -or $restoreConfirm -eq 's') {
            Write-Host "`nReinstallazione pacchetti globali in corso..." -ForegroundColor Yellow
            
            # Se l'installazione era attiva, riattivala prima di installare i pacchetti
            if ($currentInstallation -eq $originalInstallation.Name) {
                Write-Host "Riattivazione installazione..." -ForegroundColor Gray
                Set-CurrentVersion -Name $targetAlias
                Sync-GlobalCommands -Force | Out-Null
            }
            
            $successCount = 0
            $failCount = 0
            
            foreach ($package in $globalPackages) {
                Write-Host "  Installazione $package..." -ForegroundColor Gray -NoNewline
                
                try {
                    $npmPath = Join-Path $newInstallationPath "npm.cmd"
                    & $npmPath install -g $package 2>&1 | Out-Null
                    
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host " [OK]" -ForegroundColor Green
                        $successCount++
                    } else {
                        Write-Host " $([char]0x2717)" -ForegroundColor Red
                        $failCount++
                    }
                } catch {
                    Write-Host " $([char]0x2717) (errore: $_)" -ForegroundColor Red
                    $failCount++
                }
            }
            
            Write-Host ""
            Write-Host "Ripristino completato: $successCount successi, $failCount fallimenti" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
            
            # Risincronizza i comandi dopo aver installato i pacchetti
            if ($currentInstallation -eq $originalInstallation.Name) {
                Sync-GlobalCommands | Out-Null
            }
        }
    }
    
    # Step 7: Mostra installazioni disponibili e chiedi quale usare
    Write-Host ""


    Write-Host "$([char]0x2705) UPGRADE COMPLETATO!" -ForegroundColor Green


    Write-Host ""
    Write-Host "Installazione '$($installation.Name)' aggiornata a Node.js $selectedVersion" -ForegroundColor Cyan
    Write-Host ""
    
    # Ottieni tutte le installazioni disponibili
    $installations = Get-AllInstallations
    
    if ($installations.Count -eq 0) {
        Write-Host "Nessuna installazione trovata." -ForegroundColor Red
        return
    }
    
    # Mostra lista installazioni
    Write-Host "Installazioni disponibili:" -ForegroundColor Cyan
    Write-Host ""
    
    $index = 1
    foreach ($inst in $installations) {
        $instName = $inst.Name
        $instVersion = $inst.Version
        $isCurrent = if ($instName -eq $targetAlias) { " [AGGIORNATA]" } else { "" }
        Write-Host "  [$index]    $($instName.PadRight(20)) Node.js $instVersion$isCurrent" -ForegroundColor White
        $index++
    }
    
    Write-Host ""
    Write-Host "Digita il numero dell'installazione da attivare (o 'q' per saltare): " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host
    
    if ($choice -eq 'q' -or $choice -eq 'Q') {
        Write-Host ""
        Write-Host "Nessuna versione attivata." -ForegroundColor Gray
        Write-Host "Per attivare una versione in seguito, usa:" -ForegroundColor White
        Write-Host "  node-local use <installation-name>" -ForegroundColor Cyan
        Write-Host ""


        return
    }
    
    $selectedIndex = $null
    if ([int]::TryParse($choice, [ref]$selectedIndex) -and $selectedIndex -ge 1 -and $selectedIndex -le $installations.Count) {
        $selectedInstallation = $installations[$selectedIndex - 1]
        $selectedName = $selectedInstallation.Name
        $selectedVer = $selectedInstallation.Version
        
        Write-Host ""
        Write-Host "Attivazione di '$selectedName' (Node.js $selectedVer)..." -ForegroundColor Yellow
        
        Set-CurrentVersion -Name $selectedName
        Sync-GlobalCommands
        
        Write-Host ""
        Write-Host "Versione attiva: $selectedName (Node.js $selectedVer)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "$([char]0x26A0)  Chiudi e riapri il terminale per applicare le modifiche." -ForegroundColor Yellow
        Write-Host ""


    } else {
        Write-Host ""
        Write-Host "Selezione non valida. Nessuna versione attivata." -ForegroundColor Red
        Write-Host "Usa 'node-local use <installation-name>' per attivare una versione." -ForegroundColor Yellow
        Write-Host ""


    }
}
