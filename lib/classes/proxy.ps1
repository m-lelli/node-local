# =============================================================================
# proxy.ps1 - Classe Proxy per rappresentare un template di proxy
# =============================================================================

enum ProxyType {
    CMD
    BASH
}

enum ProxyRole {
    MANAGER
    COMMAND
}

class Proxy {
    [string]$name
    [string]$path
    [ProxyType]$proxyType
    [ProxyRole]$proxyRole

    Proxy([string]$name, [string]$path, [ProxyType]$proxyType, [ProxyRole]$proxyRole) {
        $this.name = $name
        $this.path = $path
        $this.proxyType = $proxyType
        $this.proxyRole = $proxyRole
    }

    [string] getName() {
        return $this.name
    }

    [string] getPath() {
        return $this.path
    }

    [ProxyType] getProxyType() {
        return $this.proxyType
    }

    [ProxyRole] getProxyRole() {
        return $this.proxyRole
    }

    [bool] isCMD() {
        return $this.proxyType -eq [ProxyType]::CMD
    }

    [bool] isBash() {
        return $this.proxyType -eq [ProxyType]::BASH
    }

    [bool] isManager() {
        return $this.proxyRole -eq [ProxyRole]::MANAGER
    }

    [bool] isCommand() {
        return $this.proxyRole -eq [ProxyRole]::COMMAND
    }
}
