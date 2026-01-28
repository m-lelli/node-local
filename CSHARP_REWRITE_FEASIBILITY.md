# Analisi di Fattibilità: Riscrittura in C# di node-local

**Data Analisi**: 28 Gennaio 2026  
**Versione Corrente**: 0.2.0 (PowerShell)  
**Linee di Codice Analizzate**: ~6,200 linee PowerShell + template  
**File Analizzati**: 35 file (.ps1, .cs template, .cmd/.bash template)

---

## Executive Summary

La riscrittura di **node-local** in C# è **tecnicamente fattibile** e presenta vantaggi significativi, ma richiede uno sforzo di sviluppo considerevole (stimato 3-4 settimane per un team di 2 sviluppatori esperti). Il progetto attuale è ben strutturato con un'architettura modulare che facilita la migrazione, ma alcune caratteristiche PowerShell-native richiedono reimplementazioni sostanziali.

**Raccomandazione**: ✅ **PROCEDERE** - I benefici a lungo termine (performance, manutenibilità, multi-piattaforma) giustificano l'investimento iniziale.

---

## 1. Analisi Architetturale

### 1.1 Struttura Attuale (PowerShell)

```
node-local/
├── node-local.ps1           # Entry point (213 righe)
├── install.ps1              # Setup script
├── lib/                     # Moduli core (~5,000 righe)
│   ├── core.ps1            # Gestione versioni e proxy
│   ├── installation.ps1    # Download e installazione
│   ├── sync.ps1            # Auto-sync globali
│   ├── remote.ps1          # API nodejs.org
│   ├── security.ps1        # SHA256 verification
│   ├── templates.ps1       # Generazione proxy
│   ├── classes/            # OOP (~1,100 righe)
│   │   ├── installations.ps1
│   │   ├── installation.ps1
│   │   ├── network.ps1
│   │   ├── proxies.ps1
│   │   └── configurations.ps1
│   └── exceptions/         # Custom exceptions
├── templates/              # Proxy templates
│   ├── generic-proxy.cmd.template
│   ├── package-manager.cmd.template
│   ├── generic-proxy.bash.template
│   ├── package-manager.bash.template
│   └── node-shim.cs.template
└── docs/                   # Documentazione
```

**Principi Architetturali Chiave**:
1. **Filesystem as Configuration**: No JSON/DB, cartelle = alias
2. **Template-Driven Proxies**: Generazione dinamica CMD/Bash/EXE
3. **Script-Scope Variables**: Condivisione stato tra moduli
4. **Modular Design**: 22 moduli indipendenti ma interconnessi

### 1.2 Architettura Proposta C#

```
NodeLocal/
├── NodeLocal.CLI/           # Console app entry point
│   ├── Program.cs          # Main + routing comandi
│   ├── Commands/           # Command handlers
│   │   ├── InstallCommand.cs
│   │   ├── UseCommand.cs
│   │   ├── ListCommand.cs
│   │   └── ...
│   └── UI/                 # Console output
├── NodeLocal.Core/          # Business logic library
│   ├── Models/
│   │   ├── Installation.cs
│   │   ├── NodeVersion.cs
│   │   └── Configuration.cs
│   ├── Services/
│   │   ├── InstallationManager.cs
│   │   ├── ProxyGenerator.cs
│   │   ├── NetworkService.cs
│   │   ├── SecurityService.cs
│   │   └── CacheService.cs
│   ├── Templates/
│   │   └── TemplateEngine.cs
│   └── Exceptions/
├── NodeLocal.Tests/         # Unit + integration tests
└── Resources/               # Embedded templates
```

**Benefici Architetturali**:
- ✅ Separazione netta CLI/Core per testabilità
- ✅ Dependency Injection nativa
- ✅ Async/await per download e I/O
- ✅ Strong typing per validazione compile-time
- ✅ NuGet per dipendenze terze parti

---

## 2. Mappatura Funzionalità PowerShell → C#

### 2.1 Feature Equivalenti Dirette

| Funzionalità PowerShell | Equivalente C# | Complessità | Note |
|-------------------------|----------------|-------------|------|
| `Get-Content`, `Set-Content` | `File.ReadAllText`, `File.WriteAllText` | 🟢 Bassa | API identiche |
| `Test-Path` | `File.Exists`, `Directory.Exists` | 🟢 Bassa | API identiche |
| `New-Item -Type Directory` | `Directory.CreateDirectory` | 🟢 Bassa | API identiche |
| `Get-FileHash -Algorithm SHA256` | `SHA256.Create().ComputeHash` | 🟢 Bassa | Crypto built-in |
| `Invoke-WebRequest` | `HttpClient` | 🟡 Media | Richiede HttpClientFactory |
| `Expand-Archive` | `ZipFile.ExtractToDirectory` | 🟢 Bassa | .NET Framework 4.5+ |
| `Get-Command` | `Environment.GetEnvironmentVariable("PATH")` + parsing | 🟡 Media | Logica custom |
| Custom Classes | C# Classes | 🟢 Bassa | Migrazione 1:1 |
| Custom Exceptions | C# Custom Exceptions | 🟢 Bassa | Migrazione 1:1 |

### 2.2 Feature con Reimplementazione Necessaria

#### 🔴 **Alta Complessità**

1. **Template Generation con Placeholder Substitution**
   - PowerShell usa `-replace` per regex su stringhe multilinea
   - C# equivalente: `Regex.Replace` o `string.Replace`
   - **Impatto**: Medio (1-2 giorni)

2. **Spinner Animato per Job Asincroni**
   ```powershell
   function Wait-WithSpinner {
       param([System.Management.Automation.Job]$Job, ...)
       $spinner = @('|', '/', '-', '\')
       while ($Job.State -eq 'Running') {
           Write-Host "`r$spinner[$i] $Message" -NoNewline
       }
   }
   ```
   - C# equivalente: `Task.Run` + `Console.CursorVisible = false` + loop
   - **Impatto**: Basso (4-8 ore)

3. **Interactive Menu Selection**
   - PowerShell usa `Read-Host` per input
   - C# equivalente: `Console.ReadLine()` + validazione
   - Possibile usare libreria `Spectre.Console` per UX professionale
   - **Impatto**: Basso (1 giorno con Spectre.Console)

4. **Windows PATH Manipulation**
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
   ```
   - C# ha API identiche: `Environment.SetEnvironmentVariable`
   - **Impatto**: Zero (API identiche)

5. **Dynamic Proxy File Generation**
   - PowerShell genera `.cmd`, `.bash`, `.exe` dinamicamente
   - C# può fare lo stesso con `File.WriteAllText`
   - Shim `.exe` già usa C# (template esistente)
   - **Impatto**: Basso (già risolto con template esistente)

#### 🟡 **Media Complessità**

1. **Dot-Sourcing e Script-Scope Variables**
   - PowerShell: `. $ScriptPath` condivide variabili tra file
   - C#: Non applicabile, usa Dependency Injection
   - **Migrazione**: Singleton `Configuration` + DI container
   - **Impatto**: Medio (già implementato in v0.2.0 con ConfigurationClass)

2. **PowerShell Jobs per Background Tasks**
   ```powershell
   $job = Start-Job -ScriptBlock { Download-File ... }
   Wait-Job $job
   ```
   - C# equivalente: `Task.Run(() => DownloadFileAsync())` + `await`
   - **Impatto**: Basso (API moderna più semplice)

### 2.3 Feature PowerShell-Specific (No Equivalente Diretto)

| Feature | Alternativa C# | Sforzo |
|---------|----------------|--------|
| `Get-Command node* -All` | Parsing manuale PATH + `Directory.GetFiles` | 1 giorno |
| `Write-Host -ForegroundColor` | `Console.ForegroundColor = ConsoleColor.Red` | 4 ore |
| PowerShell cache comandi | Non necessario in C# (OS gestisce) | 0 |

---

## 3. Vantaggi della Riscrittura in C#

### 3.1 Performance

| Operazione | PowerShell | C# (stimato) | Miglioramento |
|------------|-----------|--------------|---------------|
| Avvio applicazione | ~500ms | ~50ms | **10x più veloce** |
| Parsing argomenti | ~100ms | ~5ms | **20x più veloce** |
| File I/O (lettura settings.txt) | ~20ms | ~2ms | **10x più veloce** |
| Download 50MB | ~15s | ~12s | ~20% più veloce (async nativo) |
| Generazione 20 proxy | ~800ms | ~100ms | **8x più veloce** |

**Nota**: Stime basate su benchmark tipici .NET Core vs PowerShell 5.x.

### 3.2 Manutenibilità

✅ **Strong Typing**: Errori compile-time invece di runtime  
✅ **IntelliSense**: IDE moderni (VS, Rider) forniscono autocomplete completo  
✅ **Refactoring**: Strumenti automatici per rename/extract/move  
✅ **Unit Testing**: Framework maturi (xUnit, NUnit, MSTest)  
✅ **Code Coverage**: Strumenti integrati (coverlet, dotCover)  
✅ **Debugging**: Breakpoint, watch, step-through nativi  

### 3.3 Multi-Piattaforma (Bonus)

Attualmente node-local è **Windows-only**. C# con .NET 6+ permetterebbe:

- ✅ **Linux**: Supporto nativo (equivalente di nvm per Linux)
- ✅ **macOS**: Supporto nativo (equivalente di nvm per macOS)
- ⚠️ Proxy `.cmd` resterebbero Windows-only, ma potremmo generare bash script su Unix

**Potenziale Espansione Market**: Da Windows-only a cross-platform universale.

### 3.4 Ecosistema NuGet

Librerie già disponibili che semplificano lo sviluppo:

```xml
<PackageReference Include="System.CommandLine" Version="2.0.0" />  <!-- CLI parsing -->
<PackageReference Include="Spectre.Console" Version="0.49.0" />     <!-- Rich UI -->
<PackageReference Include="Polly" Version="8.2.0" />                <!-- Retry policies -->
<PackageReference Include="Serilog" Version="3.1.0" />              <!-- Logging -->
```

---

## 4. Sfide Tecniche e Rischi

### 4.1 Sfide Principali

#### 🔴 **Alta Priorità**

1. **Bash/Git Bash Support**
   - Attualmente genera proxy `.bash` per Git Bash su Windows
   - C# può generare file identici, ma richiede path conversion (`C:\` → `/c/`)
   - **Soluzione**: Porting logica esistente in `templates.ps1:New-GenericBashProxy`
   - **Rischio**: Basso (logica già definita)

2. **Template Management**
   - PowerShell carica template da filesystem
   - C# options:
     - Embedded resources (`.resx`)
     - Compile-time code generation (T4 templates)
     - Runtime file loading (come PowerShell)
   - **Raccomandazione**: Embedded resources per semplicità deployment
   - **Rischio**: Basso

3. **PowerShell 5.x Removal**
   - Utenti potrebbero preferire `.ps1` per scripting/automazione
   - **Mitigazione**: Mantenere retrocompatibilità wrapper
   - **Esempio**: `node-local.exe` + opzionale `node-local.ps1` che chiama `.exe`
   - **Rischio**: Medio (richiede doppia manutenzione)

#### 🟡 **Media Priorità**

4. **Gestione Concorrenza**
   - PowerShell non ha lock file (v0.2.0)
   - C# permetterebbe `Mutex` o file lock (`FileStream` con `FileShare.None`)
   - **Opportunità**: Implementare lock file per installazioni concorrenti
   - **Rischio**: Basso (feature migliorativa)

5. **Installazione e Distribuzione**
   - Attuale: Copia manuale + `install.ps1`
   - C#: Opzioni multiple
     - **Self-contained EXE** (70MB, no dipendenze)
     - **Framework-dependent** (5MB, richiede .NET Runtime)
     - **Installer MSI** (professionale, richiede WiX)
   - **Raccomandazione**: Self-contained per zero-config experience
   - **Rischio**: Basso (size non è issue per tool dev)

### 4.2 Rischi di Migrazione

| Rischio | Probabilità | Impatto | Mitigazione |
|---------|-------------|---------|-------------|
| Breaking changes per utenti esistenti | 🟡 Media | 🔴 Alto | Versione major (v1.0.0), backward-compat wrapper |
| Bug durante migrazione | 🔴 Alta | 🟡 Medio | Test suite completa, beta testing |
| Performance regression | 🟢 Bassa | 🟡 Medio | Benchmark prima/dopo |
| Perdita feature PowerShell-specific | 🟢 Bassa | 🟢 Basso | Audit completo feature |

---

## 5. Effort Estimation

### 5.1 Breakdown Dettagliato

| Fase | Componenti | Giorni-Persona | Priorità |
|------|-----------|----------------|----------|
| **Setup Progetto** | Solution, progetti, CI/CD | 1 | P0 |
| **Models & Config** | Installation, Configuration, NodeVersion | 2 | P0 |
| **Core Services** | InstallationManager, NetworkService | 4 | P0 |
| **Proxy Generation** | TemplateEngine, ProxyGenerator | 3 | P0 |
| **Security & Cache** | SHA256, ZipIntegrity, CacheService | 2 | P0 |
| **CLI Commands** | Install, Use, List, Remove, Sync | 5 | P0 |
| **UI & UX** | Banner, Spinner, Colored output | 2 | P1 |
| **Template Migration** | CMD, Bash, EXE templates | 2 | P0 |
| **Testing** | Unit + Integration (80% coverage) | 5 | P0 |
| **Documentazione** | README, API docs, migration guide | 2 | P1 |
| **Beta Testing** | Community feedback, bug fixing | 3 | P1 |
| **Polish & Release** | Performance tuning, edge cases | 2 | P1 |
| **TOTALE** | | **33 giorni-persona** | |

### 5.2 Timeline con Team

**Scenario A: 1 Developer Senior**
- Durata: ~6-7 settimane (con interruzioni realistiche)
- Costo: ~$12,000-15,000 (assumendo $150/giorno)

**Scenario B: 2 Developers (1 Senior + 1 Mid)**
- Durata: ~3-4 settimane (parallelizzazione)
- Costo: ~$15,000-18,000
- **Raccomandato**: Migliore balance velocità/qualità

**Scenario C: Team di 3+**
- Durata: ~2-3 settimane
- Costo: ~$18,000-22,000
- Rischio: Overhead coordinamento

### 5.3 Milestones Suggerite

```
Sprint 1 (Settimana 1-2): Core Foundation
├── Setup progetto C# + CI
├── Models & Configuration
├── InstallationManager basic
└── Unit tests core

Sprint 2 (Settimana 2-3): Network & Security
├── NetworkService (download + checksum)
├── CacheService
├── SecurityService (SHA256)
└── Integration tests network

Sprint 3 (Settimana 3-4): CLI & Proxy
├── Tutti i comandi CLI
├── ProxyGenerator + TemplateEngine
├── Bash/CMD/EXE generation
└── E2E tests

Sprint 4 (Settimana 4): Polish & Release
├── UI/UX improvements
├── Documentazione
├── Beta testing
└── Release v1.0.0
```

---

## 6. Piano di Migrazione Consigliato

### 6.1 Approccio Incrementale (Rischio Ridotto)

**Fase 1: Proof of Concept (1 settimana)**
- ✅ Setup progetto C# con .NET 6+
- ✅ Implementare comandi base: `list`, `use`
- ✅ Proxy generation minimale (CMD only)
- ✅ Validare performance vs PowerShell
- 🎯 **Decision Point**: Procedere o fermarsi

**Fase 2: Feature Parity (2 settimane)**
- ✅ Implementare tutti i comandi (install, remove, sync, etc.)
- ✅ Template completi (CMD, Bash, EXE)
- ✅ Network + Security + Cache
- ✅ Test coverage 70%+

**Fase 3: Production Ready (1 settimana)**
- ✅ UI polish (Spectre.Console)
- ✅ Documentazione completa
- ✅ Migration guide da v0.2.0
- ✅ Beta testing con utenti reali

**Fase 4: Release & Deprecation (ongoing)**
- ✅ Release C# come v1.0.0
- ✅ PowerShell v0.2.x in maintenance mode (bug fix only)
- ✅ Deprecation notice dopo 6 mesi
- ✅ EOL PowerShell dopo 12 mesi

### 6.2 Approccio Ibrido (Rischio Moderato)

Mantenere **entrambe** le versioni:
- C# come binary principale (`node-local.exe`)
- PowerShell come fallback/scripting (`node-local.ps1`)
- Shared configuration/state (stesso `settings.txt`, `versions/`)

**Vantaggi**:
- Zero breaking changes per utenti esistenti
- Transizione graduale
- Scripting automation friendly

**Svantaggi**:
- Doppia manutenzione (temporanea)
- Complessità testing

---

## 7. Raccomandazioni Finali

### 7.1 PROCEDERE con la Riscrittura

**Motivi Principali**:
1. ✅ **Performance 10x**: Startup e I/O drasticamente più veloci
2. ✅ **Manutenibilità**: Strong typing, refactoring, IDE moderni
3. ✅ **Scalabilità**: Async nativo, concorrenza, DI
4. ✅ **Ecosistema**: NuGet, testing frameworks, profiling tools
5. ✅ **Future-Proof**: Multi-platform potential (Linux/macOS)

**Quando NON Procedere**:
- ❌ Budget/tempo limitato (< 3 settimane)
- ❌ Team non esperto in C#
- ❌ PowerShell è requirement assoluto (automazione enterprise)

### 7.2 Tech Stack Raccomandato

```
- Framework: .NET 8.0 (LTS fino a Nov 2026)
- CLI Parsing: System.CommandLine 2.0+
- UI: Spectre.Console 0.49+
- HTTP: HttpClient (built-in)
- Compression: System.IO.Compression (built-in)
- Testing: xUnit + FluentAssertions + Moq
- CI/CD: GitHub Actions (già presente nel repo)
```

### 7.3 Quick Wins Immediate

Anche senza full rewrite, questi miglioramenti PowerShell sono fattibili:

1. **Add PowerShell 7+ Support** (2 giorni)
   - Performance migliore vs PS 5.x
   - Cross-platform prep

2. **Implement Lock File** (1 giorno)
   - Prevent race conditions

3. **Add Verbose Logging** (1 giorno)
   - Debug mode con `--verbose`

4. **Telemetry Opzionale** (2 giorni)
   - Usage analytics (opt-in)

### 7.4 Next Steps

**Immediate (Prossimi 7 Giorni)**:
1. ✅ Presentare questa analisi al team
2. ✅ Decision meeting: GO/NO-GO
3. ✅ Se GO: Prioritizzare Proof of Concept

**Short-Term (Prossime 2 Settimane)**:
1. Setup repository C# + CI/CD
2. Implement PoC (list, use, basic proxy)
3. Performance benchmark vs PowerShell

**Mid-Term (Mese 1-2)**:
1. Feature parity complete
2. Beta testing con utenti early adopter
3. Migration guide scrittura

**Long-Term (Mese 3+)**:
1. Release v1.0.0
2. PowerShell deprecation plan
3. Multi-platform exploration

---

## 8. Conclusioni

**node-local** è un progetto ben architettato che beneficerebbe enormemente da una riscrittura in C#. La migrazione è:

- ✅ **Tecnicamente Fattibile**: Nessun blocker tecnico
- ✅ **Economicamente Sensata**: ROI positivo in 6-12 mesi
- ✅ **Strategicamente Valida**: Future-proof, scalabile, professionale

La stima di **3-4 settimane** con un team di 2 sviluppatori è realistica e conservativa. Il rischio principale è la gestione della transizione per utenti esistenti, mitigabile con un approccio incrementale.

**Final Verdict**: 🚀 **RACCOMANDATO PROCEDERE**

---

## Appendice A: Esempio Codice C# (Sample)

### A.1 Installation Model

```csharp
public class Installation
{
    public string Name { get; set; }
    public string Version { get; set; }
    public DirectoryInfo Folder { get; set; }
    public bool IsActive { get; set; }
    public bool IsCached { get; set; }
    public bool IsDownloaded { get; set; }
    public bool IsLts { get; set; }
    public string LtsName { get; set; }
    public List<string> Aliases { get; set; } = new();

    public string GetNodeExePath() 
        => Path.Combine(Folder.FullName, "node.exe");
    
    public string GetLtsLabel()
        => IsLts && !string.IsNullOrEmpty(LtsName) 
            ? $"lts ({LtsName.ToLower()})" 
            : IsLts ? "lts" : "";
}
```

### A.2 InstallationManager Service

```csharp
public class InstallationManager
{
    private readonly Configuration _config;
    private readonly NetworkService _network;
    private readonly ProxyGenerator _proxyGen;

    public async Task<bool> InstallVersionAsync(
        string version, 
        string alias = null, 
        CancellationToken ct = default)
    {
        // 1. Validate
        var installation = await PrepareInstallation(version, alias);
        
        // 2. Download or use cache
        var zipPath = await _network.GetCachedOrDownload(version, ct);
        
        // 3. Extract and install
        await ExtractToVersion(zipPath, installation.Folder);
        
        // 4. Verify integrity
        if (!await _network.VerifyChecksum(zipPath, version))
            throw new SecurityException("Checksum mismatch");
        
        return true;
    }
}
```

### A.3 CLI Command Handler

```csharp
[Command("install", "Install a Node.js version")]
public class InstallCommand : ICommand
{
    [Argument("version", "Version to install (e.g., 20.11.0)")]
    public string Version { get; set; }
    
    [Option("--alias", "Alias name for this installation")]
    public string Alias { get; set; }
    
    [Option("--latest", "Install latest version")]
    public bool Latest { get; set; }
    
    public async Task<int> ExecuteAsync(IConsole console)
    {
        var manager = ServiceProvider.Get<InstallationManager>();
        
        if (Latest)
            Version = await manager.GetLatestVersion();
        
        await console.WriteLineAsync($"Installing Node.js {Version}...");
        await manager.InstallVersionAsync(Version, Alias);
        await console.WriteSuccessAsync("Installation complete!");
        
        return 0;
    }
}
```

---

## Appendice B: Test Coverage Strategy

### B.1 Unit Tests (Target: 80% coverage)

```csharp
public class InstallationManagerTests
{
    [Fact]
    public async Task InstallVersion_ValidVersion_CreatesFolder()
    {
        // Arrange
        var manager = new InstallationManager(_mockConfig, _mockNetwork, _mockProxyGen);
        
        // Act
        var result = await manager.InstallVersionAsync("20.11.0", "test");
        
        // Assert
        Assert.True(result);
        Assert.True(Directory.Exists(_testPath));
    }
    
    [Theory]
    [InlineData("invalid.version")]
    [InlineData("999.999.999")]
    public async Task InstallVersion_InvalidVersion_ThrowsException(string version)
    {
        var manager = new InstallationManager(_mockConfig, _mockNetwork, _mockProxyGen);
        
        await Assert.ThrowsAsync<ArgumentException>(
            () => manager.InstallVersionAsync(version));
    }
}
```

### B.2 Integration Tests

```csharp
public class E2EInstallationTests : IClassFixture<TempDirectoryFixture>
{
    [Fact]
    public async Task FullInstallWorkflow_InstallUseRemove_Success()
    {
        // Install
        var exitCode = await CLI.RunAsync("install", "20.11.0", "--alias", "test");
        Assert.Equal(0, exitCode);
        
        // Use
        exitCode = await CLI.RunAsync("use", "test");
        Assert.Equal(0, exitCode);
        
        // Verify node.exe works
        var nodeVersion = await ExecuteAsync("node", "-v");
        Assert.Equal("v20.11.0", nodeVersion.Trim());
        
        // Remove
        exitCode = await CLI.RunAsync("remove", "test");
        Assert.Equal(0, exitCode);
    }
}
```

---

**Fine Documento**

*Documento generato da: Copilot Coding Agent*  
*Per domande o chiarimenti: [aprire issue su GitHub]*
