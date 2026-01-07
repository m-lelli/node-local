# Esempio di utilizzo di node-local

## Scenario 1: Installazione automatica (CONSIGLIATO)

# 1. Installare node-local
.\install.ps1

# 2. Chiudere e riaprire il terminale

# 3. Scaricare e installare Node.js 18.20.0 automaticamente
node-local install 18.20.0

# Output atteso:
# === Installazione Node.js 18.20.0 ===
# URL: https://nodejs.org/dist/v18.20.0/node-v18.20.0-win-x64.zip
# ...
# === Node.js 18.20.0 installato con successo! ===

# 4. Installare anche Node.js 20.11.0
node-local install 20.11.0

# 5. Verificare le versioni installate
node-local list

# Output atteso:
# versioni disponibili:
#     - 18.20.0
#     - 20.11.0

# 6. Selezionare Node.js 18.20.0
node-local use 18.20.0

# 7. Chiudere e riaprire il terminale

# 8. Verificare che Node.js funzioni
nlocal-node --version
# Output: v18.20.0

nlocal-npm --version
# Output: 10.x.x (o simile)

# 9. Switchare a Node.js 20.11.0
node-local use 20.11.0

# 10. Chiudere e riaprire il terminale

# 11. Verificare la nuova versione
nlocal-node --version
# Output: v20.11.0

# 12. Verificare lo stato corrente
node-local list

# Output atteso:
# versioni disponibili:
#     - 18.20.0
#     - 20.11.0 (*)

## Scenario 2: Installazione manuale

# 1. Installare node-local
.\install.ps1

# 2. Chiudere e riaprire il terminale

# 3. Scaricare Node.js 18.20.0 e 20.11.0 da nodejs.org
# Estrarre in cartelle temporanee e copiarle nelle versioni

# Esempio per Windows (assumendo che hai estratto in C:\temp):
xcopy /E /I "C:\temp\node-v18.20.0-win-x64" "%APPDATA%\node-local\versions\18.20.0"
xcopy /E /I "C:\temp\node-v20.11.0-win-x64" "%APPDATA%\node-local\versions\20.11.0"

# 4. Continuare come nello Scenario 1 dal punto 5...
node-local debug

# Mostra informazioni dettagliate sulla configurazione
