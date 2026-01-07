# =============================================================================
# network.ps1 - Classe per gestire download e operazioni di rete
# =============================================================================

class Network {
    
    # =============================================================================
    # DOWNLOAD
    # =============================================================================
    
    # Scarica un file da un URL
    static [void] DownloadFile([string]$url, [string]$destinationPath) {
        $downloadJob = Start-Job -ScriptBlock {
            param($url, $dest)
            $webClient = New-Object System.Net.WebClient
            try {
                $webClient.DownloadFile($url, $dest)
                return $true
            } catch {
                return $false
            } finally {
                $webClient.Dispose()
            }
        } -ArgumentList $url, $destinationPath
        
        $downloadResult = Wait-WithSpinner -Job $downloadJob -Message "Download..." -Color Cyan
        
        if (-not $downloadResult -or -not (Test-Path $destinationPath)) {
            throw [NetworkException]::DownloadFailed($url)
        }
    }
    
    # =============================================================================
    # CHECKSUM
    # =============================================================================
    
    # Verifica il checksum SHA256 di un file Node.js
    static [void] VerifyNodeChecksum([string]$version, [string]$filename, [string]$filePath) {
        # Usa la funzione esistente di verifica checksum
        $isValid = Verify-NodeChecksum -Version $version -Filename $filename -FilePath $filePath
        
        if (-not $isValid) {
            throw [NetworkException]::ChecksumFailed($filePath)
        }
    }
    
    # =============================================================================
    # VERIFICA INTEGRITÀ FILE
    # =============================================================================
    
    # Verifica che un file ZIP sia valido
    static [void] VerifyZipIntegrity([string]$zipPath) {
        $isValid = Test-ZipIntegrity -ZipPath $zipPath
        
        if (-not $isValid) {
            throw [NetworkException]::CorruptedFile($zipPath)
        }
    }
    
    # =============================================================================
    # CACHE
    # =============================================================================
    
    # Verifica se una versione Node.js è in cache e ritorna il path
    static [string] GetCachedNodeZip([string]$version) {
        $config = [ConfigurationClass]::GetInstance()
        $cleanVersion = $version -replace '^v', ''
        $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $zipFileName = "node-v$cleanVersion-win-$arch.zip"
        $cachePath = $config.cachePath
        $cachedZipPath = Join-Path $cachePath $zipFileName
        
        if (Test-Path $cachedZipPath) {
            # Verifica che il file non sia corrotto (dimensione minima 20MB)
            $fileInfo = Get-Item $cachedZipPath
            if ($fileInfo.Length -gt 20MB) {
                return $cachedZipPath
            } else {
                # File corrotto, rimuovilo
                Remove-Item $cachedZipPath -Force -ErrorAction SilentlyContinue
                return $null
            }
        }
        
        return $null
    }
    
    # Salva un file ZIP in cache
    static [void] SaveToCache([string]$zipPath, [string]$version) {
        # Usa la funzione esistente per salvare in cache
        Save-ToCache -SourcePath $zipPath -Version $version -Message "Salvataggio in cache..." | Out-Null
    }
    
    # =============================================================================
    # DOWNLOAD NODE.JS (tutto in uno)
    # =============================================================================
    
    # Scarica una versione di Node.js (con cache, checksum, verifica)
    # Ritorna il path del file ZIP pronto per l'installazione
    static [string] DownloadNodeVersion([string]$version, [string]$tempDir) {
        $cleanVersion = $version -replace '^v', ''
        $arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }
        $filename = "node-v$cleanVersion-win-$arch.zip"
        $zipPath = Join-Path $tempDir $filename
        $downloadUrl = "https://nodejs.org/dist/v$cleanVersion/$filename"
        
        # Step 1: Verifica cache
        $cachedPath = [Network]::GetCachedNodeZip($cleanVersion)
        if ($cachedPath) {
            # Copia da cache a temp
            Copy-Item -Path $cachedPath -Destination $zipPath -Force
            return $zipPath
        }
        
        # Step 2: Download
        [Network]::DownloadFile($downloadUrl, $zipPath)
        
        # Step 3: Verifica checksum
        [Network]::VerifyNodeChecksum($cleanVersion, $filename, $zipPath)
        
        # Step 4: Salva in cache (non bloccante)
        try {
            [Network]::SaveToCache($zipPath, $cleanVersion)
        } catch {
            # Ignora errori di cache saving
        }
        
        return $zipPath
    }
}
