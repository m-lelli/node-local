# node-local

**Gestore versioni Node.js per Windows**

node-local permette di installare e gestire più versioni di Node.js su Windows senza privilegi amministratore. Usa un sistema folder-based dove ogni versione o alias corrisponde a una cartella indipendente. Non usa symlink, ma un sistema di proxy template-driven per il routing dei comandi.

## Caratteristiche

- Nessun privilegio amministratore richiesto
- Alias semantici (`production`, `client-legacy`, ecc.)
- Ogni installazione è una cartella separata con i suoi pacchetti globali
- Switch rapido tra versioni
- Auto-sync dei pacchetti globali dopo ogni installazione
- Verifica SHA256 automatica dei download
- Cache locale delle versioni scaricate
- Supporto Git Bash

## Installazione

```powershell
# 1. Clona il repository
git clone https://github.com/user/node-local.git
cd node-local

# 2. Esegui lo script di installazione
.\install.ps1

# 3. Riavvia il terminale
```

Dopo l'installazione avrai a disposizione i comandi `nlocal-node`, `nlocal-npm` e `nlocal-npx`. Questa modalità isolata permette di testare node-local senza interferire con Node.js installato a livello di sistema.

### Modalità Override

Se vuoi usare direttamente `node`, `npm` e `npx` invece di `nlocal-*`:

```powershell
.\install.ps1 -OverrideNodejs
```

⚠️ **Nota**: Su Windows `node.exe` ha sempre precedenza su `node.cmd`. Se hai Node.js di sistema installato, usa la modalità isolata o disinstalla Node.js di sistema.
Se usi NVM, puoi semplicemente eseguire
```powershell
nvm off
```

## Uso

### Installare una versione

```powershell
# Esplora versioni disponibili online
node-local list-remote [-LtsOnly] [-All]

```powershell
# Installare versioni specifiche
node-local install 20.11.0
node-local install 18.20.0 --alias production
node-local install 20.11.0 --alias client-a

# Installare ultima versione disponibile
node-local install --latest
node-local install --latest-lts

# Elencare versioni installate
node-local list

# Elencare versioni disponibili da nodejs.org
node-local list-remote
node-local list-remote --lts
node-local list-remote --limit 10

# Attivare una versione
node-local use production
node-local use 20.11.0
node-local use                    # Menu interattivo se ci sono più versioni

# Rimuovere una versione
node-local remove production
node-local remove 18.20.0

# Rinominare un'installazione
node-local rename 20.11.0 stable

# Cambiare modalità operativa
node-local -OverrideNodejs        # Usa node/npm/npx
node-local -SetLocalNodejs        # Usa nlocal-node/nlocal-npm/nlocal-npx

# Cache
node-local cache --list           # Mostra versioni in cache
node-local cache --clear          # Svuota cache

# Diagnostica
node-local debug
node-local sync                   # Rigenera proxy comandi globali
node-local sync --force           # Rigenera tutti i proxy
```

### Alias e Isolamento

Ogni installazione è una cartella separata con i propri pacchetti globali. Puoi avere la stessa versione di Node.js con configurazioni diverse:

```powershell
node-local install 20.11.0 --alias client-a
node-local install 20.11.0 --alias client-b

node-local use client-a
npm install -g typescript@4.9.0

node-local use client-b
npm install -g typescript@5.3.0
```

I pacchetti globali sono completamente isolati tra installazioni.

## Disinstallazione

```powershell
.\uninstall.ps1
```

Lo script rimuove:
- La cartella `%APPDATA%\node-local` con tutte le installazioni
- La voce PATH dall'ambiente utente

Puoi anche rimuovere manualmente cancellando la cartella e togliendo `%APPDATA%\node-local\bin` dalle variabili d'ambiente.

## Come Funziona

node-local usa un sistema di proxy template-driven. Quando installi una versione e la attivi con `use`, vengono generati file `.cmd` in `%APPDATA%\node-local\bin` che reindirizzano ai binari della versione attiva.

Ogni comando globale installato (es. `typescript`, `@angular/cli`) genera automaticamente il suo proxy. Il sistema intercetta i comandi npm con flag `-g` o `--global` e rigenera i proxy dopo ogni installazione/rimozione globale.

Non usa symlink o junction, solo file `.cmd` generati da template.

### Struttura Directory

```
%APPDATA%\node-local\
├── bin\                  # Proxy e script principale
├── versions\             # Installazioni (una cartella per versione/alias)
│   ├── production\       # Installazione con alias
│   ├── 20.11.0\          # Installazione per versione
│   └── client-a\         # Altro alias
├── cache\                # ZIP scaricati (per reinstallazioni veloci)
├── settings.txt          # Versione attualmente attiva
└── templates\            # Template proxy
```

## Risoluzione Problemi

**Comando non trovato dopo installazione:**
- Riavvia il terminale per ricaricare il PATH
- Verifica con `node-local debug`

**Pacchetto globale non disponibile:**
- Esegui `node-local sync` per rigenerare i proxy
- Verifica la versione attiva con `node-local list`

**Conflitto con Node.js di sistema:**
- Usa la modalità isolata (`nlocal-*` comandi) invece di override
- Oppure disinstalla Node.js di sistema

## Requisiti

- Windows 10/11 o Windows Server 2016+
- PowerShell 5.0+ (incluso in Windows)
- Connessione Internet per scaricare versioni
