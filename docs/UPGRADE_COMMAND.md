# Comando Upgrade - Documentazione

## Panoramica

Il comando `upgrade` permette di aggiornare un'installazione esistente di Node.js a una nuova versione in modo guidato e interattivo.

## Utilizzo

```powershell
node-local upgrade
```

## Flusso Operativo

Il comando ha **due modalità** a seconda del numero di installazioni presenti:

### 🚀 Modalità Singola Installazione (Semplificata)

Quando hai **una sola installazione** Node.js, il comando offre un flusso rapido:

#### 1. Selezione Automatica
L'installazione viene selezionata automaticamente:

```
=== Upgrade Node.js ===

Installazione rilevata: production (Node.js 18.20.0)
```

#### 2. Proposta Upgrade Latest
Ti viene proposta direttamente la versione **latest**:

```
────────────────────────────────────────────────────────────────
UPGRADE RAPIDO DISPONIBILE
────────────────────────────────────────────────────────────────

Versione corrente: Node.js 18.20.0
Versione latest:   Node.js 23.1.0

Vuoi aggiornare direttamente alla versione latest? [S/n]:
```

- **Se accetti (S)**: Upgrade diretto alla latest
- **Se rifiuti (n)**: Mostra il menu completo con versioni organizzate per major

### 📋 Modalità Multiple Installazioni (Completa)

Quando hai **più installazioni**, il comando usa il flusso completo:

#### 1. Selezione Installazione
Menu interattivo per scegliere quale installazione aggiornare:

```
=== Upgrade Node.js ===

Seleziona l'installazione da aggiornare:

  [1]    18.20.0              Node.js 18.20.0
  [2]    20.11.0              Node.js 20.11.0
  [3]    production           Node.js 20.15.0

Digita il numero dell'installazione (o 'q' per uscire):
```

### 2. Visualizzazione Versioni Disponibili
Dopo aver selezionato l'installazione, il comando:
- Recupera tutte le versioni disponibili da nodejs.org
- Le organizza per **major release** (10.x, 11.x, 12.x, ecc.)
- Mostra solo le versioni >= alla versione corrente (upgrade forward)
- Per ogni major release mostra le prime 10 versioni

Esempio di output:

```
Versione corrente: v18.20.0 (Node.js 18.x)
────────────────────────────────────────────────────────────────────────────────

▼ Node.js 18.x (versione corrente)
  [1]    v18.20.5         [LTS: hydrogen]
  [2]    v18.20.4         [LTS: hydrogen]
  [3]    v18.20.3         [LTS: hydrogen]
  [4]    v18.20.2         [LTS: hydrogen]
  [5]    v18.20.1         [LTS: hydrogen]
  [6]    v18.20.0         [LTS: hydrogen] ← versione corrente
  ... e altre 45 versioni della serie 18.x

▼ Node.js 20.x
  [7]    v20.18.0         [LTS: iron]
  [8]    v20.17.0         [LTS: iron]
  [9]    v20.16.0         [LTS: iron]
  [10]   v20.15.1         [LTS: iron]
  [11]   v20.15.0         [LTS: iron]
  ... e altre 32 versioni della serie 20.x

▼ Node.js 22.x
  [12]   v22.11.0
  [13]   v22.10.0
  [14]   v22.9.0
  [15]   v22.8.0
  ... e altre 8 versioni della serie 22.x

Legenda: [LTS] = Long Term Support (consigliato per produzione)
```

### 3. Selezione Versione
L'utente digita il numero della versione desiderata:

```
Digita il numero della versione da installare (o 'q' per uscire): 7
```

### 4. Conferma Upgrade
Viene mostrato un riepilogo e richiesta conferma:

```
────────────────────────────────────────────────────────────────────────────────
RIEPILOGO UPGRADE:
  Installazione: 18.20.0
  Versione attuale: 18.20.0
  Nuova versione: 20.18.0
────────────────────────────────────────────────────────────────────────────────

L'upgrade sostituirà la versione esistente con quella nuova.
I pacchetti globali NON verranno preservati automaticamente.

Procedere con l'upgrade? [S/n]:
```

### 5. Esecuzione Upgrade

Il processo di upgrade si articola in 3 step:

#### Step 1: Salvataggio Pacchetti Globali
Se l'installazione da aggiornare è quella **attualmente in uso**, il comando:
- Salva la lista dei pacchetti globali installati
- Mostra l'elenco dei pacchetti trovati

```
Step 1/3: Salvataggio lista pacchetti globali...
  ✓ Trovati 3 pacchetti globali
    - typescript
    - eslint
    - prettier
```

Se l'installazione non è attiva:
```
Step 1/3: Salvataggio pacchetti globali (saltato - installazione non attiva)
```

#### Step 2: Rimozione Versione Precedente
```
Step 2/3: Rimozione versione precedente...
  ✓ Versione precedente rimossa
```

#### Step 3: Installazione Nuova Versione
```
Step 3/3: Installazione nuova versione...

=== Installazione Node.js 20.18.0 ===

URL: https://nodejs.org/dist/v20.18.0/node-v20.18.0-win-x64.zip
Architettura: x64

Download in corso...
...
```

### 6. Ripristino Pacchetti Globali (Opzionale)

Se erano presenti pacchetti globali, viene chiesto se reinstallarli:

```
────────────────────────────────────────────────────────────────────────────────
RIPRISTINO PACCHETTI GLOBALI

Vuoi reinstallare i 3 pacchetti globali? [S/n]:
```

Se confermato:
```
Reinstallazione pacchetti globali in corso...
Riattivazione installazione...
  Installazione typescript... ✓
  Installazione eslint... ✓
  Installazione prettier... ✓

Ripristino completato: 3 successi, 0 fallimenti
```

### 7. Riepilogo Finale

```
────────────────────────────────────────────────────────────────────────────────
✅ UPGRADE COMPLETATO!
────────────────────────────────────────────────────────────────────────────────

Installazione '18.20.0' aggiornata a Node.js 20.18.0

⚠️  Chiudi e riapri il terminale per applicare le modifiche.
```

## Caratteristiche

### Organizzazione per Major Release
Le versioni sono raggruppate per major (10.x, 11.x, 12.x, ...) per facilitare:
- Upgrade minori (18.20.0 → 18.20.5) per patch/bugfix
- Upgrade major (18.x → 20.x) per nuove funzionalità

### Visualizzazione Intelligente
- Mostra solo versioni >= alla corrente (no downgrade)
- Evidenzia la versione corrente
- Mostra badge [LTS] con nome codename (hydrogen, iron, ecc.)
- Colori diversi per versioni LTS (verde) e standard (bianco)

### Sicurezza
- Richiede conferma prima di procedere
- Avvisa che i pacchetti globali verranno rimossi
- Offre il ripristino automatico dei pacchetti

### Gestione Errori
- Permette di uscire in qualsiasi momento digitando 'q'
- Verifica che l'installazione sia andata a buon fine
- In caso di errore, non lascia installazioni parziali

## Casi d'Uso

### Upgrade Patch (Stesso Major)
Per aggiornamenti di sicurezza o bugfix:
```
18.20.0 → 18.20.5
```

### Upgrade Minor (Stesso Major)
Per nuove funzionalità compatibili:
```
20.11.0 → 20.18.0
```

### Upgrade Major
Per passare a una nuova major release:
```
18.20.0 → 20.18.0
20.18.0 → 22.11.0
```

## Note Importanti

1. **Pacchetti Globali**: L'upgrade rimuove i pacchetti globali. Assicurati di accettare il ripristino o reinstallarli manualmente.

2. **Alias Preservati**: Il nome dell'installazione (alias) viene mantenuto. Se hai `production` con Node.js 18, dopo l'upgrade avrai sempre `production` ma con Node.js 20.

3. **Installazione Attiva**: Se l'installazione da aggiornare è quella corrente, dovrai riavviare il terminale dopo l'upgrade.

4. **Connessione Internet**: Richiede connessione per scaricare la lista versioni e la nuova versione Node.js.

5. **Spazio Disco**: Durante l'upgrade, temporaneamente occuperà spazio per download e estrazione prima di rimuovere la vecchia versione.

## Esempi

### Esempio 1: Upgrade Patch
```powershell
PS> node-local upgrade
# Selezione: [1] 18.20.0
# Scelta versione: [1] v18.20.5 [LTS: hydrogen]
# Conferma: S
# Risultato: 18.20.0 → 18.20.5
```

### Esempio 2: Upgrade Major con Alias
```powershell
PS> node-local upgrade
# Selezione: [3] production (Node.js 18.20.0)
# Scelta versione: [7] v20.18.0 [LTS: iron]
# Conferma: S
# Ripristino pacchetti: S
# Risultato: production (18.20.0 → 20.18.0)
```

### Esempio 3: Annullamento
```powershell
PS> node-local upgrade
# Selezione: q
# Risultato: Operazione annullata
```

## Integrazione con Altri Comandi

### Dopo un Upgrade
```powershell
# Verifica la versione installata
node-local list

# Se l'installazione era attiva, riavvia il terminale e verifica
nlocal-node --version

# Se hai dimenticato di reinstallare pacchetti globali
nlocal-npm install -g typescript eslint prettier
node-local sync  # Sincronizza i nuovi comandi globali
```

### Prima di un Upgrade
```powershell
# Controlla quali versioni sono disponibili
node-local list-remote -LtsOnly

# Salva manualmente la lista dei pacchetti (opzionale)
nlocal-npm list -g --depth=0 > packages.txt
```
