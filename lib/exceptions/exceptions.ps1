# =============================================================================
# exceptions.ps1 - Master script per le eccezioni
# =============================================================================
# Carica tutti i moduli di eccezioni

$ExceptionsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$ExceptionsRoot\installationExceptions.ps1"
. "$ExceptionsRoot\aliasExceptions.ps1"
. "$ExceptionsRoot\networkExceptions.ps1"
