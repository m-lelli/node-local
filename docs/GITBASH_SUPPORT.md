# Test Git Bash Compatibility

Questo documento spiega come testare che node-local funziona correttamente in Git Bash dopo l'aggiunta del supporto ai proxy bash.

## Cosa è stato implementato

1. **Template proxy bash** (`generic-proxy.bash.template` e `package-manager.bash.template`)
   - Script bash senza estensione che Git Bash può trovare ed eseguire
   - Leggono la versione corrente da `settings.txt`
   - Reindirizzano i comandi ai corrispettivi `.cmd` Windows

2. **Funzioni di generazione** in `templates.ps1`
   - `Test-BashAvailable` - Verifica che bash sia disponibile nel PATH
   - `New-GenericBashProxy` - Genera proxy bash generici
   - `New-PackageManagerBashProxy` - Genera proxy bash per package manager
   - Converte i path Windows nel formato Git Bash (`/c/Users/...`)

3. **Integrazione nei core e sync**
   - `New-CoreProxyFiles` in `core.ps1` genera proxy bash **SOLO se bash è disponibile**
   - `Sync-GlobalCommands` in `sync.ps1` genera proxy bash per comandi dinamici **SOLO se bash è disponibile**

## Verifica bash disponibilità

I proxy bash vengono generati SOLO se:
- `bash` è disponibile nel PATH di PowerShell (verificato con `Get-Command bash`)
- I file template bash esistono
- È stata fatta una richiesta di generazione (durante `New-CoreProxyFiles` o `Sync-GlobalCommands`)

Se bash non è nel PATH, niente verrà creato. Nessun errore, nessun proxy bash inutile.

## Struttura dei proxy bash generati

Con modalità **isolated**:
- `nlocal-node` - Bash proxy per node
- `nlocal-npm` - Bash proxy per npm
- `nlocal-npx` - Bash proxy per npx
- `nlocal-tsc` - Bash proxy per altri comandi (dinamici)

Con modalità **override**:
- `node` - Bash proxy per node
- `npm` - Bash proxy per npm
- `npx` - Bash proxy per npx

## Test in Git Bash

### 1. Test base (dopo installazione)

```bash
# Apri Git Bash e verifica che i comandi siano trovabili
which nlocal-node      # Dovrebbe mostrare il path
which nlocal-npm
which nlocal-npx

# Esegui il comando (dovrebbe mostrare la versione di Node.js configurata)
nlocal-node --version
nlocal-npm --version
nlocal-npx --version
```

### 2. Test di installazione package globale

```bash
# Installa un package globale con auto-sync
nlocal-npm install -g typescript

# Verifica che tsc sia ora disponibile
which nlocal-tsc
nlocal-tsc --version
```

### 3. Test con cd in diverse directory

```bash
# Git Bash dovrebbe trovare i comandi da qualsiasi directory
cd ~
nlocal-node --version

cd /tmp
nlocal-npm list -g

cd /c/Windows/System32
nlocal-npx --version
```

### 4. Test di cambio versione

```bash
# Cambia versione con PowerShell
nlocal-node use <altra-versione>

# Torna a Git Bash e verifica
nlocal-node --version  # Dovrebbe essere la nuova versione
```

## Troubleshooting

### Comando non trovato in Git Bash

**Causa**: Probabilmente PATH non include `%APPDATA%\node-local\bin`

**Soluzione**:
```bash
# Verifica il PATH in Git Bash
echo $PATH

# Dovrebbe includere il percorso convertito a formato Git Bash
# Formato atteso: /c/Users/[username]/AppData/Roaming/node-local/bin

# Se non è presente, aggiungi manualmente (temporaneamente per test):
export PATH="/c/Users/mlelli/AppData/Roaming/node-local/bin:$PATH"
nlocal-node --version
```

### Lo script bash esiste ma non è eseguibile

**Causa**: Problemi di permessi o encoding

**Soluzione**:
```bash
# Verifica che il file esista e abbia permessi di esecuzione
ls -la /c/Users/mlelli/AppData/Roaming/node-local/bin/nlocal-node

# Se necessario, dai permessi di esecuzione
chmod +x /c/Users/mlelli/AppData/Roaming/node-local/bin/nlocal-node
```

### Lo script esiste e è eseguibile, ma non funziona

**Causa**: Il comando eseguito dal proxy bash non funziona

**Soluzione**:
```bash
# Esegui manualmente per vedere l'errore
/c/Users/mlelli/AppData/Roaming/node-local/bin/nlocal-node --version

# Oppure apri lo script con un editor per controllare la sintassi
cat /c/Users/mlelli/AppData/Roaming/node-local/bin/nlocal-node
```

## File interessati

- `templates/generic-proxy.bash.template` - Template per proxy bash generico
- `templates/package-manager.bash.template` - Template per proxy bash package manager
- `lib/templates.ps1` - Funzioni per generare proxy bash
- `lib/core.ps1` - Integrazione nella generazione dei core proxy
- `lib/sync.ps1` - Integrazione nella sincronizzazione dinamica
- `install.ps1` - Copia automatica dei template
