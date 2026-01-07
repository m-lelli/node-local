class ConfigurationClass {
    static [ConfigurationClass] $Instance = $null
    
    [string]$appDataPath
    [string]$versionsPath
    [string]$binPath
    [string]$cachePath
    [string]$settingsFile
    [string]$templatesPath
    [string]$scriptPath
    [string]$lockFilePath

    static [ConfigurationClass] GetInstance() {
        if ($null -eq ([ConfigurationClass]::Instance)) {
            [ConfigurationClass]::Instance = [ConfigurationClass]::new()
        }
        return [ConfigurationClass]::Instance
    }
    
    # Costruttore (singleton pattern)
    ConfigurationClass() {
        $this.appDataPath = Join-Path $env:APPDATA "node-local"
        $this.versionsPath = Join-Path $this.appDataPath "versions"
        $this.binPath = Join-Path $this.appDataPath "bin"
        $this.cachePath = Join-Path $this.appDataPath "cache"
        $this.settingsFile = Join-Path $this.appDataPath "settings.txt"
        $this.templatesPath = Join-Path $this.binPath "templates"
        $this.scriptPath = Join-Path $this.binPath "node-local.ps1"
        $this.lockFilePath = Join-Path $this.appDataPath ".lock"
    }
    
    # Metodo statico per ottenere l'istanza singleton
    
}

# Alias per retrocompatibilità (deprecato)
class ConfigurationsClass {
    static [ConfigurationClass] GetInstance() {
        return [ConfigurationClass]::GetInstance()
    }
}