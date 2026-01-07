# =============================================================================
# installationExceptions.ps1 - Eccezioni per le installazioni
# =============================================================================

class InstallationNotFoundError : System.Exception {
    [string]$Name
    [int]$HowMany

    InstallationNotFoundError([string]$message) : base($message) {}
    
    InstallationNotFoundError([string]$message, [string]$Name) : base($message) {
        $this.Name = $Name
    }

    InstallationNotFoundError([string]$message, [string]$Name, [int]$HowMany) : base($message) {
        $this.Name = $Name
        $this.HowMany = $HowMany
    }
}

class InstallationsNotFoundError : System.Exception {
    InstallationsNotFoundError() : base("Nessuna installazione presente") {}
}

# =============================================================================
# Factory class per eccezioni Installation
# =============================================================================

class InstallationException {
    # Lancia quando un'installazione specifica non viene trovata
    static [InstallationNotFoundError] NotFound([string]$message, [string]$name, [int]$howMany) {
        return [InstallationNotFoundError]::new($message, $name, $howMany)
    }

    static [InstallationNotFoundError] NotFound([string]$message, [string]$name) {
        return [InstallationNotFoundError]::new($message, $name)
    }

    static [InstallationNotFoundError] NotFound([string]$message) {
        return [InstallationNotFoundError]::new($message)
    }

    # Lancia quando non ci sono installazioni
    static [InstallationsNotFoundError] NoneFound() {
        return [InstallationsNotFoundError]::new()
    }
}
