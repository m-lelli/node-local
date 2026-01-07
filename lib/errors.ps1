# =============================================================================
# errors.ps1 - Gestione centralizzata errori e messaggi utente
# =============================================================================
# Sistema unificato per output utente consistente e localizzato

# =============================================================================
# COSTANTI MESSAGGI
# =============================================================================

# Prefissi e simboli per i messaggi
$Script:ErrorPrefix = "[ERRORE]"
$Script:WarningPrefix = "[AVVISO]"
$Script:SuccessPrefix = "[OK]"
$Script:InfoPrefix = "[INFO]"
$Script:PromptPrefix = "[?]"
$Script:HintPrefix = "[HINT]"
$Script:DetailsPrefix = "[DETTAGLI]"

# =============================================================================
# FUNZIONI MESSAGGI BASE
# =============================================================================

function Write-ErrorMessage {
    <#
    .SYNOPSIS
    Mostra un messaggio di errore standardizzato in rosso
    
    .PARAMETER Message
    Il messaggio di errore principale
    
    .PARAMETER Hint
    Suggerimento opzionale su come risolvere il problema
    
    .PARAMETER Details
    Dettagli tecnici aggiuntivi (mostrati in grigio)
    
    .EXAMPLE
    Write-ErrorMessage -Message "Versione non trovata" -Hint "Usa 'node-local list-remote' per vedere le versioni disponibili"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Hint,
        
        [Parameter(Mandatory=$false)]
        [string]$Details
    )
    
    Write-Host "$Script:ErrorPrefix $Message" -ForegroundColor Red
    
    if ($Hint) {
        Write-Host "$Script:HintPrefix $Hint" -ForegroundColor Cyan
    }
    
    if ($Details) {
        Write-Host "$Script:DetailsPrefix $Details" -ForegroundColor Gray
    }
}

function Write-WarningMessage {
    <#
    .SYNOPSIS
    Mostra un messaggio di avviso standardizzato in giallo
    
    .PARAMETER Message
    Il messaggio di avviso
    
    .PARAMETER Hint
    Suggerimento opzionale
    
    .EXAMPLE
    Write-WarningMessage -Message "L'installazione esiste già" -Hint "Usa '--force' per sovrascrivere"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Hint
    )
    
    Write-Host "$Script:WarningPrefix $Message" -ForegroundColor Yellow
    
    if ($Hint) {
        Write-Host "$Script:HintPrefix $Hint" -ForegroundColor Cyan
    }
}

function Write-SuccessMessage {
    <#
    .SYNOPSIS
    Mostra un messaggio di successo standardizzato in verde
    
    .PARAMETER Message
    Il messaggio di successo
    
    .PARAMETER Details
    Dettagli aggiuntivi opzionali
    
    .EXAMPLE
    Write-SuccessMessage -Message "Versione installata con successo" -Details "Node.js 20.11.0"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Details
    )
    
    Write-Host "$Script:SuccessPrefix $Message" -ForegroundColor Green
    
    if ($Details) {
        Write-Host "$Script:DetailsPrefix $Details" -ForegroundColor Gray
    }
}

function Write-InfoMessage {
    <#
    .SYNOPSIS
    Mostra un messaggio informativo standardizzato in cyan
    
    .PARAMETER Message
    Il messaggio informativo
    
    .PARAMETER Prefix
    Prefisso personalizzato (opzionale, default: [INFO])
    
    .EXAMPLE
    Write-InfoMessage -Message "Download in corso..."
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$Prefix = $Script:InfoPrefix
    )
    
    Write-Host "$Prefix $Message" -ForegroundColor Cyan
}

function Write-PromptMessage {
    <#
    .SYNOPSIS
    Mostra un prompt per l'utente (senza andare a capo)
    
    .PARAMETER Message
    Il testo del prompt
    
    .EXAMPLE
    $response = Write-PromptMessage -Message "Vuoi continuare? (S/N)"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "$Script:PromptPrefix $Message " -ForegroundColor Yellow -NoNewline
}

# =============================================================================
# FUNZIONI ERRORI COMUNI
# =============================================================================

function Write-VersionNotFoundError {
    <#
    .SYNOPSIS
    Errore standardizzato per versione non trovata
    
    .PARAMETER Version
    La versione che non è stata trovata
    
    .EXAMPLE
    Write-VersionNotFoundError -Version "20.11.0"
    #>
    param(
        [Parameter(Mandatory=$false)]
        [string]$Version
    )
    
    if ($Version) {
        Write-ErrorMessage `
        -Message "Versione '$Version' non trovata" `
        -Hint "Usa 'node-local list-remote' per vedere le versioni disponibili su nodejs.org"
    } else {
        Write-ErrorMessage `
        -Message "Versione di nodejs non trovata" `
        -Hint "Usa 'node-local list-remote' per vedere le versioni disponibili su nodejs.org"
    }
    
}

function Write-InstallationNotFoundError {
    <#
    .SYNOPSIS
    Errore standardizzato per installazione non trovata
    
    .PARAMETER Name
    Il nome dell'installazione che non è stata trovata
    
    .EXAMPLE
    Write-InstallationNotFoundError -Name "production"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    Write-ErrorMessage `
        -Message "Installazione '$Name' non trovata" `
        -Hint "Usa 'node-local list' per vedere le installazioni disponibili"
}

function Write-InstallationExistsError {
    <#
    .SYNOPSIS
    Errore standardizzato per installazione già esistente
    
    .PARAMETER Name
    Il nome dell'installazione che esiste già
    
    .PARAMETER ExistingVersion
    La versione già installata (opzionale)
    
    .EXAMPLE
    Write-InstallationExistsError -Name "production" -ExistingVersion "20.11.0"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$ExistingVersion
    )
    
    $details = if ($ExistingVersion) { "Versione attuale: $ExistingVersion" } else { $null }
    
    Write-ErrorMessage `
        -Message "L'installazione '$Name' esiste già" `
        -Details $details
}

function Write-InvalidNameError {
    <#
    .SYNOPSIS
    Errore standardizzato per nome installazione non valido
    
    .PARAMETER Name
    Il nome non valido fornito
    
    .EXAMPLE
    Write-InvalidNameError -Name "my@project"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    
    Write-ErrorMessage `
        -Message "Nome installazione non valido: '$Name'" `
        -Hint "Il nome deve contenere solo lettere, numeri, punti, trattini e underscore"
}

function Write-NoVersionSelectedError {
    <#
    .SYNOPSIS
    Errore standardizzato per nessuna versione selezionata
    
    .EXAMPLE
    Write-NoVersionSelectedError
    #>
    Write-ErrorMessage `
        -Message "Nessuna versione di Node.js attualmente in uso" `
        -Hint "Usa 'node-local use <version>' per selezionare una versione"
}

function Write-DownloadFailedError {
    <#
    .SYNOPSIS
    Errore standardizzato per download fallito
    
    .PARAMETER Url
    L'URL che ha causato l'errore
    
    .PARAMETER ErrorDetails
    Dettagli dell'errore (opzionale)
    
    .EXAMPLE
    Write-DownloadFailedError -Url "https://nodejs.org/..." -ErrorDetails "Timeout"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$false)]
        [string]$ErrorDetails
    )
    
    Write-ErrorMessage `
        -Message "Download fallito" `
        -Hint "Controlla la connessione internet e riprova" `
        -Details $ErrorDetails
}

function Write-SHA256VerificationError {
    <#
    .SYNOPSIS
    Errore standardizzato per verifica SHA256 fallita
    
    .PARAMETER FilePath
    Il file che ha fallito la verifica
    
    .EXAMPLE
    Write-SHA256VerificationError -FilePath "C:\...\node.zip"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    Write-ErrorMessage `
        -Message "Verifica SHA256 fallita per $FilePath" `
        -Hint "Il file potrebbe essere corrotto. Prova a riscaricare la versione" `
        -Details "Il file verrà eliminato per sicurezza"
}

# =============================================================================
# FUNZIONI MESSAGGI DI USAGE/HELP
# =============================================================================

function Write-CommandUsage {
    <#
    .SYNOPSIS
    Mostra l'uso corretto di un comando
    
    .PARAMETER Command
    Il comando di cui mostrare l'uso
    
    .PARAMETER Usage
    Stringa di utilizzo (es: "install <version> [--alias <name>]")
    
    .PARAMETER Examples
    Array di esempi di utilizzo
    
    .EXAMPLE
    Write-CommandUsage -Command "install" -Usage "install <version> [--alias <name>]" -Examples @(
        "node-local install 20.11.0",
        "node-local install 18.20.0 --alias legacy"
    )
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Mandatory=$true)]
        [string]$Usage,
        
        [Parameter(Mandatory=$false)]
        [string[]]$Examples
    )
    
    Write-Host ""
    Write-Host "Uso:" -ForegroundColor Yellow
    Write-Host "  node-local $Usage" -ForegroundColor White
    
    if ($Examples -and $Examples.Count -gt 0) {
        Write-Host ""
        Write-Host "Esempi:" -ForegroundColor Yellow
        foreach ($example in $Examples) {
            Write-Host "  $example" -ForegroundColor Gray
        }
    }
    Write-Host ""
}

# =============================================================================
# FUNZIONI PROGRESS/STATUS
# =============================================================================

function Write-ProgressStep {
    <#
    .SYNOPSIS
    Mostra uno step di progresso numerato
    
    .PARAMETER Step
    Numero dello step corrente
    
    .PARAMETER Total
    Numero totale di step
    
    .PARAMETER Message
    Messaggio dello step
    
    .EXAMPLE
    Write-ProgressStep -Step 1 -Total 5 -Message "Download Node.js..."
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$Step,
        
        [Parameter(Mandatory=$true)]
        [int]$Total,
        
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host ""
    Write-Host "[$Step/$Total] " -ForegroundColor Cyan -NoNewline
    Write-Host "$Message" -ForegroundColor White
}

function Write-StatusLine {
    <#
    .SYNOPSIS
    Mostra una riga di stato con prefisso colorato
    
    .PARAMETER Status
    Lo stato (es: "OK", "FAIL", "SKIP", "INFO")
    
    .PARAMETER Message
    Il messaggio da mostrare
    
    .EXAMPLE
    Write-StatusLine -Status "OK" -Message "File scaricato correttamente"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("OK", "FAIL", "SKIP", "INFO", "WAIT")]
        [string]$Status,
        
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    $color = switch ($Status) {
        "OK"   { "Green" }
        "FAIL" { "Red" }
        "SKIP" { "Yellow" }
        "INFO" { "Cyan" }
        "WAIT" { "Gray" }
    }
    
    $symbol = switch ($Status) {
        "OK"   { "[OK]" }
        "FAIL" { "[FAIL]" }
        "SKIP" { "[SKIP]" }
        "INFO" { "[INFO]" }
        "WAIT" { "[WAIT]" }
    }
    
    Write-Host "$symbol " -ForegroundColor $color -NoNewline
    Write-Host "$Message" -ForegroundColor White
}

# =============================================================================
# FUNZIONI CONFERMA UTENTE
# =============================================================================

function Write-MultiChoice {
    <#
    .SYNOPSIS
    Mostra un menu di scelta multipla e ritorna la scelta dell'utente
    
    .PARAMETER Message
    Il messaggio/domanda da mostrare all'utente
    
    .PARAMETER Choices
    Array di PSCustomObject con proprietà Value (valore ritornato) e Label (testo mostrato)
    Oppure array di hashtable con chiavi 'Value' e 'Label'
    
    .PARAMETER DefaultChoice
    Il valore della scelta predefinita (opzionale)
    
    .OUTPUTS
    Il Value della scelta selezionata dall'utente
    
    .EXAMPLE
    $choice = Write-MultiChoice -Message "Cosa vuoi fare?" -Choices @(
        @{ Value = "overwrite"; Label = "Sovrascrivere la versione esistente" },
        @{ Value = "cancel"; Label = "Annullare l'installazione" }
    )
    
    .EXAMPLE
    $choices = @(
        [PSCustomObject]@{ Value = 1; Label = "Continua" },
        [PSCustomObject]@{ Value = 2; Label = "Salta" },
        [PSCustomObject]@{ Value = 3; Label = "Annulla" }
    )
    $result = Write-MultiChoice -Message "Seleziona un'opzione" -Choices $choices
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [array]$Choices,
        
        [Parameter(Mandatory=$false)]
        [object]$DefaultChoice = $null
    )
    
    if ($Choices.Count -eq 0) {
        throw "Write-MultiChoice: Nessuna scelta fornita"
    }
    
    Write-Host ""
    Write-Host "$Message" -ForegroundColor Cyan
    
    # Mostra le opzioni
    for ($i = 0; $i -lt $Choices.Count; $i++) {
        $choice = $Choices[$i]
        
        # Supporta sia hashtable che PSCustomObject
        $value = if ($choice -is [hashtable]) { $choice['Value'] } else { $choice.Value }
        $label = if ($choice -is [hashtable]) { $choice['Label'] } else { $choice.Label }
        
        $index = $i + 1
        Write-Host "  [$index] $label" -ForegroundColor White
    }
    
    Write-Host ""
    
    # Costruisci prompt con range valido
    $validRange = "1-$($Choices.Count)"
    if ($DefaultChoice -ne $null) {
        # Trova l'indice della scelta predefinita
        $defaultIndex = -1
        for ($i = 0; $i -lt $Choices.Count; $i++) {
            $value = if ($Choices[$i] -is [hashtable]) { $Choices[$i]['Value'] } else { $Choices[$i].Value }
            if ($value -eq $DefaultChoice) {
                $defaultIndex = $i + 1
                break
            }
        }
        
        if ($defaultIndex -gt 0) {
            Write-Host "Scelta [$validRange, default=$defaultIndex]: " -ForegroundColor Yellow -NoNewline
        } else {
            Write-Host "Scelta [$validRange]: " -ForegroundColor Yellow -NoNewline
        }
    } else {
        Write-Host "Scelta [$validRange]: " -ForegroundColor Yellow -NoNewline
    }
    
    $input = Read-Host
    
    # Se input vuoto e c'è default, usa il default
    if ([string]::IsNullOrWhiteSpace($input) -and $DefaultChoice -ne $null) {
        return $DefaultChoice
    }
    
    # Valida input
    $selectedIndex = 0
    if (-not [int]::TryParse($input, [ref]$selectedIndex)) {
        Write-Host "[ERRORE] Input non valido. Inserisci un numero." -ForegroundColor Red
        return $null
    }
    
    if ($selectedIndex -lt 1 -or $selectedIndex -gt $Choices.Count) {
        Write-Host "[ERRORE] Scelta non valida. Inserisci un numero tra 1 e $($Choices.Count)." -ForegroundColor Red
        return $null
    }
    
    # Ritorna il Value della scelta selezionata
    $selectedChoice = $Choices[$selectedIndex - 1]
    $result = if ($selectedChoice -is [hashtable]) { $selectedChoice['Value'] } else { $selectedChoice.Value }
    
    return $result
}

function Confirm-Action {
    <#
    .SYNOPSIS
    Chiede conferma all'utente per un'azione
    
    .PARAMETER Message
    Il messaggio di conferma
    
    .PARAMETER DefaultYes
    Se $true, la risposta predefinita è "Sì" (default: $false)
    
    .OUTPUTS
    $true se l'utente conferma, $false altrimenti
    
    .EXAMPLE
    if (Confirm-Action -Message "Vuoi procedere con l'installazione?") {
        # Procedi...
    }
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [bool]$DefaultYes = $false
    )
    
    $prompt = if ($DefaultYes) { "[S/n]" } else { "[s/N]" }
    Write-PromptMessage "$Message $prompt"
    
    $response = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $DefaultYes
    }
    
    return $response -match '^[sS]'
}

# =============================================================================
# FUNZIONI TABELLE/LISTE
# =============================================================================

function Write-TableHeader {
    <#
    .SYNOPSIS
    Mostra un header per una tabella
    
    .PARAMETER Columns
    Array di nomi delle colonne
    
    .PARAMETER Widths
    Array di larghezze delle colonne (opzionale)
    
    .EXAMPLE
    Write-TableHeader -Columns @("Nome", "Versione", "Stato") -Widths @(20, 15, 10)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Columns,
        
        [Parameter(Mandatory=$false)]
        [int[]]$Widths,

        [Parameter(Mandatory=$false)]
        [bool]$Header=$true,

        [Parameter(Mandatory=$false)]
        [string]$Color="Cyan"
    )
    
    for ($i = 0; $i -lt $Columns.Count; $i++) {
        $width = if ($Widths -and $i -lt $Widths.Count) { $Widths[$i] } else { 20 }
        Write-Host $Columns[$i].PadRight($width) -ForegroundColor $Color -NoNewline
    }
    Write-Host ""
    
    if ($header) {
        # Linea separatrice
        $totalWidth = if ($Widths) { ($Widths | Measure-Object -Sum).Sum } else { $Columns.Count * 20 }
        Write-Host ("-" * $totalWidth) -ForegroundColor Gray
    }
}

# =============================================================================
# EXPORT (opzionale, per modularità futura)
# =============================================================================

# Se in futuro si usassero moduli PowerShell veri:
# Export-ModuleMember -Function Write-ErrorMessage, Write-WarningMessage, Write-SuccessMessage, ...
