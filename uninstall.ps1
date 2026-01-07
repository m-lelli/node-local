# uninstall.ps1 - Rimuove completamente node-local

# Carica il modulo UI
$uiModule = Join-Path $PSScriptRoot "lib\ui.ps1"
if (Test-Path $uiModule) {
    . $uiModule
}

Write-Host "=== Disinstallazione node-local ===" -ForegroundColor Cyan

$AppDataPath = Join-Path $env:APPDATA "node-local"
$BinPath = Join-Path $AppDataPath "bin"

Write-Host "`nQuesta operazione:" -ForegroundColor Yellow
Write-Host "  - Rimuoverà la cartella $AppDataPath" -ForegroundColor White
Write-Host "  - Rimuoverà $BinPath dal PATH utente" -ForegroundColor White
Write-Host "  - NON toccherà il tuo setup Node.js/npm di sistema" -ForegroundColor Green

$confirm = Read-Host "`nContinuare? (s/n)"
if ($confirm -ne 's') {
    Write-Host "Disinstallazione annullata." -ForegroundColor Yellow
    exit
}

# Rimuovi dal PATH
Write-Host "`nRimozione dal PATH..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$BinPath*") {
    $newPath = ($userPath -split ';' | Where-Object { $_ -notlike "*node-local*" }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  PATH aggiornato" -ForegroundColor Green
} else {
    Write-Host "  PATH già pulito" -ForegroundColor Gray
}

# Rimuovi la cartella
Write-Host "`nRimozione cartella..." -ForegroundColor Yellow
if (Test-Path $AppDataPath) {
    try {
        # Usa robocopy per rimuovere cartelle con percorsi lunghi
        # Crea una cartella temporanea vuota
        $emptyDir = Join-Path $env:TEMP "node-local-empty-$(Get-Random)"
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        
        Write-Host ""
        
        # Crea un job in background per robocopy così possiamo mostrare un'animazione
        $robocopyJob = Start-Job -ScriptBlock {
            param($empty, $target)
            $result = robocopy "$empty" "$target" /MIR /R:0 /W:0 /NP /NFL /NDL /NJH /NJS 2>&1
            return $LASTEXITCODE
        } -ArgumentList $emptyDir, $AppDataPath
        
        # Animazione mentre robocopy lavora
        $spinChars = @('|', '/', '-', '\')
        $spinIndex = 0
        
        while ($robocopyJob.State -eq 'Running') {
            Write-Host "`r  $($spinChars[$spinIndex]) Rimozione in corso..." -NoNewline -ForegroundColor Cyan
            $spinIndex = ($spinIndex + 1) % 4
            Start-Sleep -Milliseconds 100
        }
        
        # Ottieni risultato
        $exitCode = Receive-Job -Job $robocopyJob
        Remove-Job -Job $robocopyJob
        
        # Cancella la riga dell'animazione
        Write-Host "`r" -NoNewline
        
        # Rimuovi la cartella ora vuota e la cartella temporanea
        Remove-Item -Path $AppDataPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $emptyDir -Force -ErrorAction SilentlyContinue
        
        # Easter Egg - Thanos per disinstallazione completa!
        Show-ThanosSnap
        
        Write-Host "  [OK] Cartella rimossa: $AppDataPath" -ForegroundColor Green
    } catch {
        Write-Host "  Errore nella rimozione: $_" -ForegroundColor Red
        Write-Host "  Impossibile rimuovere automaticamente." -ForegroundColor Red
        Write-Host "  Puoi rimuovere manualmente la cartella: $AppDataPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Cartella già rimossa" -ForegroundColor Gray
}

Write-Host "`n=== Disinstallazione completata! ===" -ForegroundColor Cyan
Write-Host "Chiudi e riapri il terminale per applicare le modifiche al PATH." -ForegroundColor Yellow
Write-Host ""
