# 🎭 Easter Egg - L'Animazione di Thanos

## Che cos'è?

Un divertente easter egg nascosto che mostra l'animazione ASCII di **Thanos che schiocca le dita** (lo Snap) ogni volta che elimini:

- Una versione di Node.js (`node-local remove`)
- Una singola versione dalla cache (`node-local cache clear` → selezione versione)
- Tutte le versioni dalla cache (`node-local cache clear` → all)

## Quando appare?

L'animazione viene visualizzata automaticamente durante queste operazioni:

### Eliminazione Installazione

```powershell
node-local remove <installation-name>
```

Mostra un'animazione di 4 secondi con il testo:

- "Tis a simple calculus."
- "Destiny arrives all the same"
- "And now it's here."
- **LO SNAP** 💥
- "I dati di Node.js sono stati ridotti a polvere..."

### Eliminazione Singola Versione Cache

```powershell
node-local cache clear
# Seleziona il numero di una versione
```

Mostra un'animazione di 2 secondi (versione breve).

### Eliminazione Intera Cache

```powershell
node-local cache clear
# Seleziona 'all'
```

Mostra un'animazione di 3 secondi (versione media).

## Caratteristiche dell'Animazione

✨ **Effetti visivi:**

- ASCII art ASCII Thanos
- Colori vivaci (Magenta, Cyan, Yellow, Red)
- Animazione del "SNAP" lampeggiante
- Particellini che scompaiono
- Testo tematico italiano

🎬 **Sequenze:**

1. Thanos appare con il messaggio iniziale
2. Alza il dito (posa minacciosa)
3. Lo **SNAP** - l'animazione principale in 6 frame
4. Dissolvenza con particellini
5. Messaggio finale: "I dati di Node.js sono stati ridotti a polvere..."

## Implementazione Tecnica

La funzione `Show-ThanosSnap` è definita in `lib/ui.ps1`:

```powershell
function Show-ThanosSnap {
    param([int]$Duration = 3)
    
    # Pulisce lo schermo
    Clear-Host
    
    # Mostra 6 frame dell'animazione SNAP
    # Con effetti di timing
    # E messaggio tematico
}
```

Parametri:

- `Duration`: Durata totale dell'animazione in secondi (default: 3)

## Possibili Futuri Miglioramenti

🎥 **Idee per potenziare l'easter egg:**

- [ ] Aggiungere l'emoji Thanos 👾 all'inizio
- [ ] Supporto per animazioni ANSI code più avanzate
- [ ] Varianti diverse dell'animazione (random)
- [ ] Audio (beep) durante lo snap ⚠️ (da testare su Windows)
- [ ] Effetto di "dusting" progressivo per le versioni rimosse

## Disabilitare l'Easter Egg

Se preferisci disabilitare l'animazione, puoi commentare le righe che chiamano `Show-ThanosSnap` in:

- `lib/remove.ps1` (linea ~73)
- `lib/cache.ps1` (linee ~255 e ~287)

Oppure modificare le funzioni per un check su una variabile globale:

```powershell
if ($Script:EnableEasterEggs -ne $false) {
    Show-ThanosSnap -Duration 3
}
```

## Test

Per testare l'animazione senza eliminare versioni:

```powershell
.\lib\ui.ps1
Show-ThanosSnap -Duration 2
```

---

### Finale

"I dati di Node.js sono stati ridotti a polvere... ashes to ashes..." 🌍→💨
