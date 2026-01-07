# labels.ps1 - Messaggi e costanti centralizzate per node-local

# Simboli e separatori
$Script:MSG_TEMPLATE = "`n{0}"

# Funzione helper per formattare messaggi con newline
function msg {
    param([string]$message)
    return $Script:MSG_TEMPLATE -f $message
}

# Messaggi di conferma
$Script:CONTINUE_MESSAGE = "Continuare? (s/n)"

# Messaggi di annullamento
$Script:CANCELLED_MESSAGE = "Installazione annullata."

# Messaggi di annullamento
$Script:CANCELLED_MESSAGE_UPDATE = "Aggiornamento annullato."

$Script:CANCELLED_MESSAGE_OPERATION = "Operazione annullata."

# =============================================================================
# Messaggi Sync
# =============================================================================

# Funzione helper per messaggi sync
function syncMsg {
    param([string]$version, [string]$mode, [bool]$force = $false)
    
    if ($force) {
        return "Rigenerazione completa comandi globali per Node.js $version (inclusi core)... ($mode)"
    } else {
        return "Sincronizzazione comandi globali per Node.js $version... ($mode)"
    }
}

# Template per resoconto proxy creati
$Script:PROXY_SUMMARY_TEMPLATE = "{0} proxy creati per comandi globali`n{1} proxy creati per package manager"

# Funzione helper per resoconto proxy creati
function proxySummary {
    param([int]$globalProxies, [int]$pmProxies)
    return $Script:PROXY_SUMMARY_TEMPLATE -f $globalProxies, $pmProxies
}

# =============================================================================
# Messaggi Switch Versione
# =============================================================================

# Messaggi statici
$Script:SWITCH_VERSION_NOT_FOUND = "Errore: La versione '{0}' non è stata trovata."
$Script:SWITCH_LIST_HINT = "Usa 'node-local list' per vedere le installazioni disponibili."
$Script:SWITCH_ALREADY_IN_USE = "L'installazione '{0}' (Node.js {1}) è già in uso, nulla da fare."
$Script:SWITCH_CHANGING_FROM = "Cambio da '{0}' a '{1}' (Node.js {2}) ..."
$Script:SWITCH_SETTING = "Imposto installazione '{0}' (Node.js {1}) ..."
$Script:SWITCH_COMPLETED = "Fatto! Cambio versione completato"

# Messaggi dinamici
function switchNotFound {
    param([string]$name)
    return $Script:SWITCH_VERSION_NOT_FOUND -f $name
}

function switchAlreadyInUse {
    param([string]$name, [string]$version)
    return $Script:SWITCH_ALREADY_IN_USE -f $name, $version
}

function switchChanging {
    param([string]$from, [string]$to, [string]$version)
    return $Script:SWITCH_CHANGING_FROM -f $from, $to, $version
}

function switchSetting {
    param([string]$name, [string]$version)
    return $Script:SWITCH_SETTING -f $name, $version
}
