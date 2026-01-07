# =============================================================================
# security.ps1 - Funzioni per la sicurezza e verifica integrità
# =============================================================================
# Gestione checksum SHA256 e verifica integrità dei download

# Calcola il checksum SHA256 di un file
function Get-FileHash256 {
    param([string]$FilePath)
    
    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash.ToLower()
    }
    catch {
        Write-Host "Errore nel calcolo SHA256: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Scarica e verifica il checksum SHA256 da nodejs.org
function Verify-NodeChecksum {
    param(
        [string]$Version,
        [string]$Filename,
        [string]$FilePath
    )    
    try {
        # URL del file SHASUMS256.txt
        $shasumsUrl = "https://nodejs.org/dist/v$Version/SHASUMS256.txt"
        
        # Scarica il file dei checksum
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "node-local/1.0")
        
        $shasumsContent = $webClient.DownloadString($shasumsUrl)
        $webClient.Dispose()
        
        # Cerca il checksum per il nostro file
        $lines = $shasumsContent -split "`n"
        $targetLine = $lines | Where-Object { $_ -match [regex]::Escape($Filename) }
        
        if (-not $targetLine) {
            Write-Host "Attenzione: Checksum non trovato per $Filename" -ForegroundColor Yellow
            Write-Host "Continuando senza verifica checksum..." -ForegroundColor Gray
            return $true
        }
        
        # Estrai il checksum atteso (prima parte della riga)
        $expectedHash = ($targetLine -split '\s+')[0].ToLower()
        
        # Calcola il checksum del file scaricato
        $actualHash = Get-FileHash256 -FilePath $FilePath
        
        if (-not $actualHash) {
            Write-Host "Errore nel calcolo del checksum locale" -ForegroundColor Red
            return $false
        }
        
        # Confronta i checksum
        if ($actualHash -eq $expectedHash) {
            Write-Host "[OK] Checksum verificato con successo!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERRORE] Checksum non corrisponde!" -ForegroundColor Red
            Write-Host "  Atteso:   $expectedHash" -ForegroundColor Red
            Write-Host "  Ottenuto: $actualHash" -ForegroundColor Red
            Write-Host "`nIl file potrebbe essere corrotto o compromesso." -ForegroundColor Red
            Write-Host "Non installare questo file per motivi di sicurezza." -ForegroundColor Red
            return $false
        }
    }
    catch [System.Net.WebException] {
        Write-Host "Attenzione: Impossibile scaricare i checksum da nodejs.org" -ForegroundColor Yellow
        Write-Host "Errore di rete: $($_.Exception.Message)" -ForegroundColor Gray
        Write-Host "Continuando senza verifica checksum..." -ForegroundColor Gray
        return $true
    }
    catch {
        Write-Host "Errore durante la verifica checksum: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Continuando senza verifica checksum..." -ForegroundColor Gray
        return $true
    }
}