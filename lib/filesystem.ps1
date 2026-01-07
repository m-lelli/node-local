# lib/filesystem.ps1 - Utilità filesystem riutilizzabili
# Funzioni DRY per operazioni su cartelle, file e directory

# =============================================================================
# Gestione Cartelle Temporanee
# =============================================================================

# Crea una cartella temporanea con cleanup garantito
# Usage: $tempDir = New-TempDirectory -Prefix "node-local-"
function New-TempDirectory {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prefix = "temp-"
    )
    
    $tempDir = Join-Path $env:TEMP "$Prefix$(Get-Random)"
    
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    return $tempDir
}

# Pulisci una cartella temporanea con job in background
# Usage: $job = Remove-TempDirectory -Path $tempDir
function Remove-TempDirectory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "Pulizia file temporanei..."
    )
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
    $cleanupJob = Start-Job -ScriptBlock {
        param($path)
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    } -ArgumentList $Path
    
    return $cleanupJob
}

# =============================================================================
# Rimozione Directory con Robocopy (supporta percorsi lunghi)
# =============================================================================

# Rimuove una directory usando robocopy /MIR trick (per percorsi lunghi)
# Ritorna $true se successo, $false altrimenti
function Remove-DirectoryWithRobocopy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "Rimozione directory...",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoSpinner = $false
    )
    
    if (-not (Test-Path $Path)) {
        Write-Host "  [INFO] Directory già assente: $Path" -ForegroundColor Gray
        return $true
    }
    
    try {
        # Crea cartella temporanea vuota per il /MIR
        $emptyDir = Join-Path $env:TEMP "node-local-empty-$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyDir -Force -ErrorAction Stop | Out-Null
        
        # Job background per robocopy con spinner
        $robocopyJob = Start-Job -ScriptBlock {
            param($empty, $target)
            robocopy "$empty" "$target" /MIR /R:0 /W:0 /NP /NFL /NDL /NJH /NJS 2>&1
            return $LASTEXITCODE
        } -ArgumentList $emptyDir, $Path
        
        # Attendi con spinner (opzionale)
        if ($NoSpinner) {
            $exitCode = Receive-Job -Job $robocopyJob -Wait
        } else {
            $exitCode = Wait-WithSpinner -Job $robocopyJob -Message $Message -Color Cyan
        }
        
        # Robocopy ritorna 0-7 per successo, 8+ per errori
        if ($exitCode -ge 8) {
            Write-Host "  [ERRORE] Robocopy exit code: $exitCode" -ForegroundColor Red
            Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
            return $false
        }
        
        # Rimuovi cartelle temporanee
        Remove-Item -Path $Path -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
        
        Write-Host "[OK] Directory rimossa!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  [ERRORE] Impossibile rimuovere directory: $_" -ForegroundColor Red
        return $false
    }
}

# =============================================================================
# Copia Directory con Robocopy
# =============================================================================

# Copia una directory usando robocopy (supporta percorsi lunghi)
# Ritorna $true se successo, $false altrimenti
function Copy-DirectoryWithRobocopy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source,
        
        [Parameter(Mandatory=$true)]
        [string]$Destination,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "Copia in corso...",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoSpinner = $false
    )
    
    if (-not (Test-Path $Source)) {
        Write-Host "  [ERRORE] Sorgente non esiste: $Source" -ForegroundColor Red
        return $false
    }
    
    try {
        # Assicurati che la destinazione esista
        if (-not (Test-Path $Destination)) {
            New-Item -ItemType Directory -Path $Destination -Force | Out-Null
        }
        
        # Job background per robocopy con spinner
        $robocopyJob = Start-Job -ScriptBlock {
            param($source, $dest)
            robocopy "$source" "$dest" /E /NP /NFL /NDL /NJH /NJS 2>&1
            return $LASTEXITCODE
        } -ArgumentList $Source, $Destination
        
        # Attendi con spinner (opzionale)
        if ($NoSpinner) {
            $exitCode = Receive-Job -Job $robocopyJob -Wait
        } else {
            $exitCode = Wait-WithSpinner -Job $robocopyJob -Message $Message -Color Cyan
        }
        
        # Robocopy ritorna 0-7 per successo, 8+ per errori
        if ($exitCode -ge 8) {
            Write-Host "  [ERRORE] Robocopy exit code: $exitCode" -ForegroundColor Red
            return $false
        }
        
        Write-Host "[OK] Copia completata!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  [ERRORE] Impossibile copiare directory: $_" -ForegroundColor Red
        return $false
    }
}

function Copy-FileWithProgress {
    <#
    .SYNOPSIS
    Copia un singolo file con spinner di progresso
    
    .PARAMETER SourcePath
    Path del file sorgente
    
    .PARAMETER DestinationPath
    Path del file di destinazione
    
    .PARAMETER Message
    Messaggio da mostrare durante la copia (opzionale)
    
    .OUTPUTS
    $true se copia riuscita, $false altrimenti
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = $null
    )
    
    if (-not (Test-Path $SourcePath)) {
        return $false
    }
    
    try {
        # Assicurati che la directory di destinazione esista
        $destDir = Split-Path -Parent $DestinationPath
        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        
        # Job background per copia file
        $copyJob = Start-Job -ScriptBlock {
            param($source, $dest)
            try {
                Copy-Item -Path $source -Destination $dest -Force
                return $true
            } catch {
                return $false
            }
        } -ArgumentList $SourcePath, $DestinationPath
        
        # Attendi con spinner se Message fornito
        if ($Message) {
            $result = Wait-WithSpinner -Job $copyJob -Message $Message -Color Cyan
        } else {
            $result = Receive-Job -Job $copyJob -Wait
        }
        
        Remove-Job -Job $copyJob -Force -ErrorAction SilentlyContinue
        
        # Verifica che il file esista
        if ($result -and (Test-Path $DestinationPath)) {
            return $true
        }
        
        return $false
    }
    catch {
        return $false
    }
}

# =============================================================================
# Estrazione ZIP (con supporto percorsi lunghi)
# =============================================================================

# Verifica l'integrità di un file ZIP
function Test-ZipIntegrity {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ZipPath
    )
    
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    
    try {
        $testZip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $entryCount = $testZip.Entries.Count
        $testZip.Dispose()
        
        return ($entryCount -gt 0)
    } catch {
        return $false
    }
}

# Estrae un file ZIP in una directory
# Ritorna l'oggetto con proprietà FullName e Name della cartella estratta
function Expand-ZipFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ZipFile,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory,
        
        [Parameter(Mandatory=$false)]
        [string]$ExpectedFolderName = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "Estrazione...",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoSpinner = $false
    )
    
    if (-not (Test-Path $ZipFile)) {
        throw "File ZIP non trovato: $ZipFile"
    }
    
    try {
        # Assicurati che la directory di output esista
        $longOutputPath = "\\?\$OutputDirectory"
        [System.IO.Directory]::CreateDirectory($longOutputPath) | Out-Null
        
        # Job per l'estrazione (sempre, anche per spinne r)
        $extractJob = Start-Job -ScriptBlock {
            param($zipFile, $outputDirectory, $expectedFolderName)
            
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            
            # Apri il file ZIP
            $zip = [System.IO.Compression.ZipFile]::OpenRead($zipFile)
            $totalEntries = $zip.Entries.Count
            
            if ($totalEntries -eq 0) {
                $zip.Dispose()
                throw "File ZIP vuoto o danneggiato"
            }
            
            # Estrai tutti i file
            foreach ($entry in $zip.Entries) {
                if ($entry.Name -eq "") { continue }
                
                $entryPath = $entry.FullName.Replace('/', '\')
                $destinationPath = "$outputDirectory\$entryPath"
                $longPathDestination = "\\?\$destinationPath"
                
                # Crea directory genitore
                $lastBackslash = $destinationPath.LastIndexOf('\')
                if ($lastBackslash -gt 0) {
                    $parentDir = $destinationPath.Substring(0, $lastBackslash)
                    [System.IO.Directory]::CreateDirectory("\\?\$parentDir") | Out-Null
                }
                
                try {
                    $entryStream = $entry.Open()
                    $fileStream = [System.IO.File]::Create($longPathDestination)
                    $entryStream.CopyTo($fileStream)
                    $fileStream.Flush()
                    $fileStream.Close()
                    $fileStream.Dispose()
                    $entryStream.Close()
                    $entryStream.Dispose()
                }
                catch {
                    if ($fileStream) { try { $fileStream.Close(); $fileStream.Dispose() } catch {} }
                    if ($entryStream) { try { $entryStream.Close(); $entryStream.Dispose() } catch {} }
                    throw $_
                }
            }
            
            $zip.Dispose()
            return $totalEntries
            
        } -ArgumentList $ZipFile, $OutputDirectory, $ExpectedFolderName
        
        # Attendi con spinner (opzionale)
        if ($NoSpinner) {
            $totalEntries = Receive-Job -Job $extractJob -Wait
        } else {
            $totalEntries = Wait-WithSpinner -Job $extractJob -Message $Message -Color Cyan
        }
        
        Write-Host "[OK] Estrazione completata! ($totalEntries file estratti)" -ForegroundColor Green
        
        # Trova la cartella estratta
        $extractedFolderPath = $null
        
        if ($ExpectedFolderName -and [System.IO.Directory]::Exists("\\?\$OutputDirectory\$ExpectedFolderName")) {
            $extractedFolderPath = "$OutputDirectory\$ExpectedFolderName"
        } else {
            # Altrimenti, cerca la prima directory top-level
            $directories = [System.IO.Directory]::GetDirectories("\\?\$OutputDirectory")
            if ($directories.Length -gt 0) {
                $extractedFolderPath = $directories[0]
            } else {
                throw "Nessuna cartella estratta trovata nel ZIP"
            }
        }
        
        return New-Object PSObject -Property @{
            FullName = $extractedFolderPath
            Name     = [System.IO.Path]::GetFileName($extractedFolderPath)
        }
    }
    catch {
        Write-Error "Errore durante l'estrazione ZIP: $_"
        throw $_
    }
}

# =============================================================================
# Utility per Directory
# =============================================================================

# Verifica e normalizza un nome di directory
# Valida caratteri consentiti: lettere, numeri, punti, trattini, underscore
function Test-ValidDirectoryName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    # Regex: solo alfanumerici, punti, trattini, underscore
    return $Name -match '^[a-zA-Z0-9._-]+$'
}

# Ottieni versione di Node.js da una cartella di installazione
# Ritorna la stringa di versione o $null se non trovata
function Get-NodeVersionFromPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$InstallationPath
    )
    
    $nodeExe = Join-Path $InstallationPath "node.exe"
    
    if (-not (Test-Path $nodeExe)) {
        return $null
    }
    
    try {
        $version = & $nodeExe --version 2>$null
        return $version
    }
    catch {
        return $null
    }
}

# Calcola la dimensione totale di una directory (in MB)
function Get-DirectorySize {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        return 0
    }
    
    try {
        $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        return [Math]::Round($size / 1MB, 2)
    }
    catch {
        return 0
    }
}
