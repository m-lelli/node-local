# =============================================================================
# downgrade.ps1 - Gestione downgrade versioni Node.js
# =============================================================================
# Funzioni per il downgrade guidato delle versioni installate

# Confronta due versioni semantiche (ritorna -1 se v1 < v2, 0 se uguali, 1 se v1 > v2)
function Compare-SemanticVersionForDowngrade {
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

# Raggruppa versioni per major release (solo versioni < corrente per downgrade)
function Get-VersionsByMajorForDowngrade {
    param(
        [array]$RemoteVersions,
        [string]$CurrentVersion
    )
    
    $versionsByMajor = @{}
    foreach ($version in $RemoteVersions) {
        $versionNumber = $version.version -replace '^v', ''
        
        # Filtra solo versioni < corrente (downgrade)
        $comparison = Compare-SemanticVersionForDowngrade -Version1 $versionNumber -Version2 $CurrentVersion
        if ($comparison -ge 0) {
            # Versione >= corrente, skip
            continue
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

# Step 1: Selezione Major Release (tutte, senza filtro)
function Select-MajorReleaseForDowngrade {
    param(
        [string]$CurrentVersion,
        [array]$RemoteVersions
    )
    
    $currentMajor = [int]($CurrentVersion -split '\.')[0]
    
    Write-Host "`nVersione corrente: v$CurrentVersion (Node.js $currentMajor.x)" -ForegroundColor Cyan

    
    # Raggruppa versioni per major (solo versioni < corrente)
    $versionsByMajor = Get-VersionsByMajorForDowngrade -RemoteVersions $RemoteVersions -CurrentVersion $CurrentVersion
    
    if ($versionsByMajor.Count -eq 0) {
        Write-Host "`nNon ci sono versioni precedenti disponibili per il downgrade." -ForegroundColor Yellow
        return $null
    }
    
    # Ordina major releases (decrescente)
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
function Select-VersionFromMajorForDowngrade {
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

# Prompt per selezione installazione da aggiornare (riuso funzione upgrade)
function Select-InstallationToDowngrade {
    $installations = Get-AllInstallations
    
    if ($installations.Count -eq 0) {
        Write-Host "`nNessuna installazione trovata." -ForegroundColor Yellow
        Write-Host "Usa 'node-local install `<version`>' per installare una versione." -ForegroundColor Gray
        return $null
    }
    
    Write-Host "`n=== Downgrade Node.js ===" -ForegroundColor Cyan
    Write-Host "`nSeleziona l'installazione da cambiare versione:" -ForegroundColor Yellow
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

# Funzione principale di downgrade
function Start-NodeDowngrade {
    
    # Step 1: Seleziona installazione da cambiare
    $installation = Select-InstallationToDowngrade
    
    if (-not $installation) {
        return
    }
    
    Write-Host "`n[OK] Selezionato: $($installation.Name) (attualmente Node.js $($installation.Version))" -ForegroundColor Green
    
    # Step 2: Scarica lista versioni remote
    Write-Host "`nRecupero versioni disponibili..." -ForegroundColor Yellow
    
    $remoteVersions = Get-RemoteVersions
    
    if (-not $remoteVersions) {
        Write-Host "`nImpossibile recuperare le versioni remote. Verifica la connessione." -ForegroundColor Red
        return
    }
    
    Write-Host "[OK] Trovate $($remoteVersions.Count) versioni disponibili" -ForegroundColor Green
    
    # Step 3: Menu TWO-STEP diretto (senza proposta latest)
    
    # Step 3a: Selezione major release (tutte, senza filtro)
    $majorSelection = Select-MajorReleaseForDowngrade -CurrentVersion $installation.Version -RemoteVersions $remoteVersions
    
    if (-not $majorSelection) {
        return
    }
    
    # Step 3b: Selezione versione specifica dalla major scelta
    $selectedVersion = Select-VersionFromMajorForDowngrade -Major $majorSelection.Major -Versions $majorSelection.Versions -CurrentVersion $installation.Version
    
    if (-not $selectedVersion) {
        return
    }
    
    Write-Host "`n[OK] Versione selezionata: v$selectedVersion" -ForegroundColor Green
    
    # Step 4: Conferma operazione
    Write-Host ""
    Write-Host "RIEPILOGO CAMBIO VERSIONE:" -ForegroundColor Cyan
    Write-Host "  Installazione: $($installation.Name)" -ForegroundColor White
    Write-Host "  Versione attuale: $($installation.Version)" -ForegroundColor Yellow
    Write-Host "  Nuova versione: $selectedVersion" -ForegroundColor Green
    Write-Host ""
    Write-Host "Vuoi procedere con il cambio versione? [S/n]: " -ForegroundColor Cyan -NoNewline
    
    $confirm = Read-Host
    
    if ($confirm -eq 'n' -or $confirm -eq 'N') {
        Write-Host "`nOperazione annullata." -ForegroundColor Yellow
        return
    }
    
    # Step 5: Verifica se la versione e gia installata nella stessa cartella
    if ($selectedVersion -eq $installation.Version) {
        Write-Host "`nLa versione selezionata e gia installata!" -ForegroundColor Yellow
        return
    }
    
    # Step 6: Verifica se esiste gia un'altra installazione con questa versione
    $allInstallations = Get-AllInstallations
    $existingWithVersion = $allInstallations | Where-Object { $_.Version -eq $selectedVersion }
    
    if ($existingWithVersion.Count -gt 0) {
        Write-Host "`nATTENZIONE: Esiste gia un'installazione con Node.js $selectedVersion" -ForegroundColor Yellow
        foreach ($existing in $existingWithVersion) {
            Write-Host "  - $($existing.Name)" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Puoi:" -ForegroundColor White
        Write-Host "  1. Usare quella esistente: node-local use $($existingWithVersion[0].Name)" -ForegroundColor Cyan
        Write-Host "  2. Rimuovere questa e reinstallare: node-local remove $($installation.Name) && node-local install $selectedVersion --alias $($installation.Name)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Vuoi comunque sovrascrivere l'installazione '$($installation.Name)' con Node.js $selectedVersion? [s/N]: " -ForegroundColor Yellow -NoNewline
        
        $overwrite = Read-Host
        
        if ($overwrite -ne 's' -and $overwrite -ne 'S') {
            Write-Host "`nOperazione annullata." -ForegroundColor Yellow
            return
        }
    }
    
    # Step 7: Prepara sovrascrittura
    $targetFolder = $installation.Name
    $targetAlias = $installation.Name
    $wasActive = (Get-CurrentVersion) -eq $targetFolder
    
    Write-Host "`nProcedo con l'installazione..." -ForegroundColor Cyan
    
    # Step 8: Rimuovi installazione corrente
    Write-Host "`n[1/3] Rimozione versione attuale..." -ForegroundColor Yellow
    
    $installationPath = Join-Path $Script:VersionsPath $targetFolder
    
    if (Test-Path $installationPath) {
        try {
            # Usa robocopy per rimuovere cartelle con percorsi lunghi
            # Crea una cartella temporanea vuota
            $emptyDir = Join-Path $env:TEMP "node-local-empty-$(Get-Random)"
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            
            # Usa robocopy per "mirror" (sincronizzare) la cartella vuota con quella da eliminare
            # Questo svuota efficacemente la cartella target
            $robocopyResult = robocopy "$emptyDir" "$installationPath" /MIR /R:0 /W:0 /NP /NFL /NDL /NJH /NJS 2>&1
            
            # Rimuovi la cartella ora vuota e la cartella temporanea
            Remove-Item -Path $installationPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
            
            Write-Host "[OK] Versione precedente rimossa" -ForegroundColor Green
        } catch {
            Write-Host "`nErrore durante la rimozione: $_" -ForegroundColor Red
            return
        }
    }
    
    # Step 9: Installa nuova versione
    Write-Host "`n[2/3] Download e installazione Node.js $selectedVersion..." -ForegroundColor Yellow
    
    # Richiama Install-NodeVersion (da installation.ps1)
    Install-NodeVersion -Version $selectedVersion -Alias $targetAlias
    
    Write-Host "[OK] Node.js $selectedVersion installato correttamente" -ForegroundColor Green
    
    # Step 10: Mostra installazioni disponibili e chiedi quale usare
    Write-Host "`n[3/3] Selezione versione da attivare..." -ForegroundColor Yellow
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
        $isCurrent = if ($instName -eq $targetAlias) { " [NUOVA]" } else { "" }
        Write-Host "  [$index]    $($instName.PadRight(20)) Node.js $instVersion$isCurrent" -ForegroundColor White
        $index++
    }
    
    Write-Host ""
    Write-Host "Digita il numero dell'installazione da attivare (o 'q' per saltare): " -ForegroundColor Yellow -NoNewline
    $choice = Read-Host
    
    if ($choice -eq 'q' -or $choice -eq 'Q') {
        Write-Host ""

        Write-Host "DOWNGRADE COMPLETATO" -ForegroundColor Green

        Write-Host "  Node.js $selectedVersion installato come: $targetAlias" -ForegroundColor White
        Write-Host "  Stato: Non attivata" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Per attivare una versione in seguito, usa:" -ForegroundColor White
        Write-Host "  node-local use <installation-name>" -ForegroundColor Cyan

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

        Write-Host "DOWNGRADE COMPLETATO" -ForegroundColor Green

        Write-Host "  Node.js $selectedVersion installato come: $targetAlias" -ForegroundColor White
        Write-Host "  Versione attiva: $selectedName (Node.js $selectedVer)" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "La versione selezionata e ora attiva." -ForegroundColor White

    } else {
        Write-Host ""
        Write-Host "Selezione non valida. Nessuna versione attivata." -ForegroundColor Red
        Write-Host "Usa 'node-local use <installation-name>' per attivare una versione." -ForegroundColor Yellow
    }
}
