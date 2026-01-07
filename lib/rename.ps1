# ============================================================================
# Modulo: Rename
# Descrizione: Rinomina alias di installazioni Node.js
# ============================================================================

function Invoke-RenameAlias {
    param(
        [string]$From,
        [string]$To
    )
    
    # Verifica che entrambi i parametri siano presenti
    if ([string]::IsNullOrWhiteSpace($From) -or [string]::IsNullOrWhiteSpace($To)) {
        Write-ErrorMessage "Parametri mancanti. Devi specificare sia --from che --to."
        Rename-Usage-Example
        return
    }
    
    # Ottieni le installazioni
    $instMgr = [Installations]::new()
    
    # Cerca l'installazione da rinominare
    $installation = $instMgr.find($From)
    
    if (-not $installation) {
        Write-ErrorMessage "Installazione '$From' non trovata." -Hint "Usa 'node-local list' per vedere le installazioni disponibili."
        return
    }
    
    # Verifica che non sia lo stesso nome
    if ($To.Trim() -eq $From) {
        Write-WarningMessage "Il nuovo nome e' identico a quello attuale. Operazione annullata."
        return
    }
    
    $oldName = $installation.getFolderName()
    $oldVersion = $installation.getVersion()
    
    # Verifica se l'installazione è attualmente in uso
    $currentInstallation = $instMgr.getCurrent()
    $isActive = ($currentInstallation -and $currentInstallation.getFolderName() -eq $oldName)
    
    # Esegui rinomina
    Write-InfoMessage "Rinomina '$oldName' -> '$To'..."
    
    try {
        # Usa renameIfNotExist che valida e rinomina
        $instMgr.renameIfNotExist($installation, $To)
        
        # Se l'installazione era attiva, sincronizza i proxy
        if ($isActive) {
            Sync-GlobalCommands | Out-Null
        }
        
        # Messaggio di successo
        Write-SuccessMessage "Rinomina completata: $oldName -> $To (Node.js $oldVersion)"
        
        if ($isActive) {
            Write-InfoMessage "L'installazione e' ancora attiva con il nuovo nome."
        }
        
    } catch [AliasAlreadyExistError] {
        Write-ErrorMessage $_.Exception.Message
        return
    } catch [AliasNotValidError] {
        Write-ErrorMessage $_.Exception.Message
        return
    } catch {
        Write-ErrorMessage "Errore durante la rinomina: $_"
        return
    }
}
