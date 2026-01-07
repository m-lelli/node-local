# Copilot Prompt Template - Analisi Codebase

## Contesto Generale
[Descrizione breve del progetto - 1-2 frasi]
- **Linguaggio principale:** [es. PowerShell, TypeScript, Python]
- **Piattaforma target:** [es. Windows, Linux, Cross-platform]
- **Architettura:** [es. CLI tool, web app, library]

## Principi Architetturali

### [Principio Chiave 1]
[Spiegazione del principio fondamentale del progetto]
- Punto chiave 1
- Punto chiave 2
- Esempio pratico dal codice

### [Principio Chiave 2]
[Altro principio importante]
- Dettaglio 1
- Dettaglio 2

## Struttura Modulare

**File/Moduli principali:**
- `[file1]` - [responsabilità]
- `[file2]` - [responsabilità]
- `[file3]` - [responsabilità]

**Variabili condivise:** [se applicabile]
```[linguaggio]
# Esempio di variabili condivise tra moduli
$Shared:Config = "..."
```

## Workflow Critici

### [Workflow 1: Nome]
```[linguaggio]
# Comando di esempio
comando install --opzione valore
```

**Cosa succede:**
1. Step 1 - [descrizione]
2. Step 2 - [descrizione]
3. Step 3 - [descrizione]

**File coinvolti:** `file1.ext`, `file2.ext`

### [Workflow 2: Nome]
```[linguaggio]
# Altro comando importante
comando use <parametro>
```

**Comportamento:**
- Azione 1
- Azione 2
- ⚠️ **Attenzione:** [punto critico]

## Convenzioni del Progetto

### Gestione [Aspetto Specifico]
- **Input:** [formato accettato]
- **Storage:** [come vengono salvati i dati]
- **Output:** [formato di visualizzazione]
- **Esempio:** `[caso concreto]`

### Messaggi Utente
- `Write-Host` con colori semantici:
  - 🔴 Red: Errori
  - 🟡 Yellow: Warning
  - 🟢 Green: Successo
  - 🔵 Cyan: Info
- Sempre suggerire azione successiva

### Encoding File [se rilevante]
- **Script:** [encoding]
- **Config:** [encoding]
- **Output:** [encoding]

## Testing & Debug

```[linguaggio]
# Test in isolamento
.\test-script.ext

# Debug configurazione
comando debug

# Comandi manuali utili
comando sync           # Sincronizzazione
comando list           # Visualizza stato
```

## Punti di Integrazione

### Dipendenze Esterne
- **[API/Service 1]:** `[URL]` - [scopo]
- **[API/Service 2]:** `[URL]` - [scopo]

### Comunicazione Cross-Component
- Modulo A → Modulo B: [pattern di comunicazione]
- Pattern condiviso: [descrizione]

## Trappole Comuni

**❌ [Problema 1]**
- **Causa:** [spiegazione]
- **Soluzione:** [fix]
- **Esempio:** `[comando]`

**❌ [Problema 2]**
- **Causa:** [spiegazione]
- **Soluzione:** [fix]

**❌ [Problema 3]**
- **Causa:** [spiegazione tecnica]
- **Workaround:** [soluzione temporanea]

## File Chiave per Context

Per comprendere rapidamente il progetto, leggi in ordine:
1. `[file-entry-point]` - Entry point principale
2. `[file-core]` - Logica core
3. `[file-config]` - Configurazione
4. `[README.md]` - Documentazione utente

## Linee Guida Sviluppo

- ✅ **DO:** [buona pratica 1]
- ✅ **DO:** [buona pratica 2]
- ❌ **DON'T:** [anti-pattern 1]
- ❌ **DON'T:** [anti-pattern 2]
- 💡 **PREFER:** [pattern raccomandato]

---

## Template Prompt per AI

Quando chiedi assistenza a Copilot su questo progetto, usa questo formato:

```markdown
## Contesto
Sto lavorando su [nome-progetto], un [descrizione].

## Obiettivo
Voglio [azione specifica].

## Vincoli
- Devo mantenere [vincolo 1]
- Non posso modificare [vincolo 2]
- Preferisco usare [approccio]

## Domanda/Richiesta
[La tua domanda specifica]
```

### Esempi di Prompt Efficaci

**Esempio 1: Aggiunta Feature**
```
Voglio aggiungere supporto per [feature]. Come integro questa funzionalità
mantenendo l'architettura [principio-chiave]? Mostrami dove modificare i file
esistenti e quali nuovi moduli creare.
```

**Esempio 2: Debug Issue**
```
Sto riscontrando [problema]. Ho verificato [cosa hai controllato].
Il comportamento atteso è [X] ma ottengo [Y]. Quali moduli devo analizzare
per identificare la causa?
```

**Esempio 3: Refactoring**
```
Il codice in [file] sta diventando complesso. Come posso refactorizzarlo
seguendo il pattern [pattern-del-progetto]? Mostra esempio concreto.
```
