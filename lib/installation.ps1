# lib/installation.ps1 - Gestione download e installazione Node.js
# Questo modulo fornisce funzioni per scaricare e installare versioni Node.js

# =============================================================================
# Installazione Node.js
# =============================================================================

function Install-NodeVersion {
    param(
        [string]$Version,
        [string]$AliasName = $null,
        [bool]$Interactive = $true
    )
    
    # Validazione parametri
    if (-not $Version) {
        Write-ErrorMessage `
            -Message "Specifica una versione" `
            -Hint "Usa 'node-local install <version> [--alias <alias-name>]'"
        Write-CommandUsage `
            -Command "install" `
            -Usage "install <version> [--alias <alias-name>]" `
            -Examples @(
                "node-local install 20.11.0",
                "node-local install 20.11.0 --alias project-legacy"
            )
        return
    }
    
    if ($AliasName) {
        Write-InfoMessage "Alias: $AliasName"
    }
    
    $instMgr = [Installations]::new()
    
    try {
        # Validazione e preparazione
        Write-ProgressStep -Step 1 -Total 3 -Message "Validazione e preparazione"
        $installation = $instMgr.PrepareInstallation($Version, $AliasName)
        Write-StatusLine -Status "OK" -Message "Installazione preparata: $($installation.name)"
        
        # Download o recupero da cache
        Write-ProgressStep -Step 2 -Total 3 -Message "Download o recupero da cache"
        $tempDir = New-TempDirectory -Prefix "node-install-"
        
        $cachedPath = [Network]::GetCachedNodeZip($installation.version)
        if ($cachedPath) {
            Write-StatusLine -Status "OK" -Message "Versione trovata in cache"
            $zipPath = $cachedPath
        } else {
            Write-InfoMessage "Download da nodejs.org..."
            $zipPath = $installation.DownloadNode($tempDir)
            Write-StatusLine -Status "OK" -Message "Download e verifica completati"
        }
        
        # Installazione
        Write-ProgressStep -Step 3 -Total 3 -Message "Installazione in corso"
        Write-InfoMessage "Estrazione e copia file..."
        $installation.InstallFromZip($zipPath)
        Write-StatusLine -Status "OK" -Message "Installazione completata"
        
        # Successo
        Write-SuccessMessage "Node.js $($installation.version) installato con successo!"
        Write-InfoMessage "Path: $($installation.getPath())"
        Write-InfoMessage "Per utilizzare: node-local use $($installation.name)"
        
        return $true
        
    } catch [AliasException] {
        Write-InvalidNameError -Name $AliasName
        return $false
        
    } catch [NetworkDownloadError] {
        Write-ErrorMessage `
            -Message "Download fallito da $($_.Exception.Url)" `
            -Hint "Verifica la connessione internet e che la versione esista"
        return $false
        
    } catch [NetworkChecksumError] {
        Write-ErrorMessage `
            -Message "Verifica checksum SHA256 fallita per $($_.Exception.FilePath)" `
            -Hint "Il file scaricato potrebbe essere corrotto, riprova"
        return $false
        
    } catch [NetworkCorruptedFileError] {
        Write-ErrorMessage `
            -Message "File corrotto: $($_.Exception.FilePath)" `
            -Hint "Riprova il download"
        return $false
        
    } catch {
        $exceptionMessage = $_.Exception.Message
        
        if ($exceptionMessage -like "*esiste già*") {
            Write-ErrorMessage `
                -Message $exceptionMessage `
                -Hint "Usa un nome diverso o rimuovi l'installazione esistente con 'node-local remove'"
        }
        elseif ($exceptionMessage -like "*ExtractionFailed*") {
            Write-ErrorMessage `
                -Message "Estrazione archivio fallita" `
                -Hint "Verifica lo spazio su disco"
        }
        elseif ($exceptionMessage -like "*CopyFailed*") {
            Write-ErrorMessage `
                -Message "Copia file fallita" `
                -Hint "Verifica i permessi e lo spazio su disco"
        }
        else {
            Write-ErrorMessage -Message $exceptionMessage
        }
        
        return $false
    }
}