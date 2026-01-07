$ExceptionsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Configuration deve essere prima di tutto (singleton, usata da tutte le classi)
. "$ExceptionsRoot\configurations.ps1"
. "$ExceptionsRoot\network.ps1"
. "$ExceptionsRoot\installation.ps1"
. "$PSScriptRoot\proxy.ps1"
. "$ExceptionsRoot\installations.ps1"
. "$ExceptionsRoot\proxies.ps1"