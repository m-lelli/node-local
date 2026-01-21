# lib/shim.ps1 - Generazione di shim .exe per proxy trasparenti
# Crea veri file .exe che leggono settings.txt e chiamano il node.exe corretto

function New-ExeShim {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,        # Es: C:\...\bin\node.exe
        
        [Parameter(Mandatory=$true)]
        [string]$SettingsFile,      # Es: C:\...\settings.txt
        
        [Parameter(Mandatory=$true)]
        [string]$VersionsPath,      # Es: C:\...\versions
        
        [Parameter(Mandatory=$true)]
        [string]$TargetExe          # Es: node.exe
    )
    
    try {
        # Trova il template C#
        $templatePath = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "templates\node-shim.cs.template"
        
        # Se siamo nella bin (installato), cerca nel percorso installato
        if (-not (Test-Path $templatePath)) {
            $templatePath = Join-Path $PSScriptRoot "..\templates\node-shim.cs.template"
        }
        
        if (-not (Test-Path $templatePath)) {
            throw "Template C# non trovato: $templatePath"
        }
        
        # Leggi il template
        $csharpCode = Get-Content -Path $templatePath -Raw -Encoding UTF8
        
        # Sostituisci i placeholder
        $csharpCode = $csharpCode -replace '\{\{SETTINGS_FILE\}\}', $SettingsFile
        $csharpCode = $csharpCode -replace '\{\{VERSIONS_PATH\}\}', $VersionsPath
        $csharpCode = $csharpCode -replace '\{\{TARGET_EXE\}\}', $TargetExe
        
        # Compila il codice C# in un .exe
        Add-Type -TypeDefinition $csharpCode -OutputAssembly $OutputPath -OutputType ConsoleApplication
        
        Write-Host "Shim .exe creato: $OutputPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Errore nella generazione dello shim .exe: $_"
        return $false
    }
}
