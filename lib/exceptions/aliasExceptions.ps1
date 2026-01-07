# =============================================================================
# aliasExceptions.ps1 - Eccezioni per gli alias/nomi installazioni
# =============================================================================

class AliasAlreadyExistError : System.Exception {
    [string]$Alias

    AliasAlreadyExistError([string]$alias) : base("L'installazione $alias esiste gia'") {
        $this.Alias = $alias
    }
}

class AliasNotValidError : System.Exception {
    [string]$Alias

    AliasNotValidError() : base("Nome non valido") {
        $this.Alias = $null
    }

    AliasNotValidError([string]$alias) : base("$alias e' un nome non valido") {
        $this.Alias = $alias
    }
}

# =============================================================================
# Factory class per eccezioni Alias
# =============================================================================

class AliasException {
    # Lancia quando un alias esiste già
    static [AliasAlreadyExistError] AlreadyExist([string]$alias) {
        return [AliasAlreadyExistError]::new($alias)
    }

    # Lancia quando un alias non è valido (con nome)
    static [AliasNotValidError] NotValid([string]$alias) {
        return [AliasNotValidError]::new($alias)
    }

    # Lancia quando un alias non è valido (senza nome)
    static [AliasNotValidError] NotValid() {
        return [AliasNotValidError]::new()
    }
}
