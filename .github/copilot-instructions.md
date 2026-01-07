# node-local - Copilot Instructions

## Project Overview
**node-local** is a Windows-native, folder-based Node.js version manager that requires no admin privileges. Written in PowerShell with a modular architecture, it uses semantic aliases and a template-driven proxy system for instant version switching. Italian language is used for user-facing messages and documentation.

## Architecture Principles

### Folder-Based Configuration
The filesystem IS the configuration. Each installation lives in `%APPDATA%\node-local\versions\<name>`:
- Standard installations: `versions\18.20.0\`, `versions\20.11.0\`
- Aliased installations: `versions\production\`, `versions\client-legacy\`
- Same Node version can exist multiple times with isolated global packages via different folder names
- **Critical insight:** Folder names ARE the alias names - no separate config/mapping needed

### Template-Driven Proxy System
All commands route through CMD proxies generated from templates in `templates/`:

**Four template types:**
1. `generic-proxy.cmd.template` - For `node.exe`, `npx.cmd`, and global packages (e.g., `tsc.cmd`, `ng.cmd`)
2. `package-manager.cmd.template` - For `npm.cmd` - intercepts `-g`/`--global` flags and triggers auto-sync after global installs
3. `generic-proxy.bash.template` - Bash wrapper for Git Bash/UNIX-like shells (no extension)
4. `package-manager.bash.template` - Bash wrapper for package managers in Git Bash/UNIX-like shells (no extension)

**Placeholder substitution:**
- `{{SETTINGS_FILE}}` → Current version storage (`%APPDATA%\node-local\settings.txt` for CMD, `/c/Users/.../AppData/Roaming/node-local/settings.txt` for Bash)
- `{{VERSIONS_PATH}}` → Versions directory (converted to Git Bash path format in bash templates)
- `{{COMMAND_NAME}}` → Command name (uppercase, e.g., `NODE`, `NPX`)
- `{{COMMAND_EXE}}` → Actual executable (e.g., `node.exe`, `npx.cmd`)
- `{{PM_NAME}}` → Package manager name (`npm`)
- `{{SCRIPT_PATH}}` → Main script for sync callback

**Bash-specific handling:**
- Path conversion: Windows paths (`C:\Users\...`) → Git Bash format (`/c/Users/...`)
- UTF-8 without BOM, LF line endings
- Aggressive whitespace/CRLF cleanup: `tr -d '\r\n '`
- Bash proxies generated ONLY if `bash` is in PATH (verified by `Test-BashAvailable`)

See `lib/templates.ps1` for `New-GenericProxy`, `New-GenericBashProxy`, `New-PackageManagerProxy`, `New-PackageManagerBashProxy` functions.

### Modular Library Structure (`lib/`)
All modules use **Script-scope variables** for shared state:
- `$Script:AppDataPath` - Root: `%APPDATA%\node-local`
- `$Script:VersionsPath` - Installations: `$AppDataPath\versions`
- `$Script:BinPath` - Proxy commands: `$AppDataPath\bin`
- `$Script:SettingsFile` - Current installation name: `$AppDataPath\settings.txt`

**Key modules:**
- `core.ps1` - Initialization, current version get/set, mode management, core proxy generation
- `templates.ps1` - Template-to-proxy generation engine (`New-GenericProxy`, `New-NpmProxy`)
- `versions.ps1` - List/switch installations (delegates to `aliases.ps1` for lookups)
- `aliases.ps1` - Folder-based "alias" system (reads `versions\` directory structure directly)
- `installation.ps1` - Download from nodejs.org, SHA256 verification, extract Node.js versions
- `sync.ps1` - Auto-sync global commands, dynamic proxy regeneration (`Sync-GlobalCommands`, `Clear-DynamicCommands`)
- `remote.ps1` - Query nodejs.org/dist/index.json for available versions
- `modes.ps1` - Switch between isolated (`nlocal-*`) and override (`node`, `npm`) modes
- `remove.ps1` - Uninstall specific installations
- `upgrade.ps1` - Interactive upgrade flow (major → version selection → package preservation)
- `downgrade.ps1` - Interactive downgrade flow (filters versions < current)
- `rename.ps1` - Rename installation folders (updates settings.txt if active)
- `ui.ps1` - Help, debug info, user-facing output formatting
- `security.ps1` - SHA256 verification against SHASUMS256.txt from nodejs.org

**Module loading:** `node-local.ps1` dot-sources all modules at startup, establishing shared Script-scope.

### Two Operating Modes
1. **Isolated (default):** `nlocal-node`, `nlocal-npm`, `nlocal-npx` - Coexists with system Node.js
2. **Override:** `node`, `npm`, `npx` - Replaces system commands (⚠️ Windows `.exe` always beats `.cmd`, so `node.exe` will still run system Node)

Switch modes: `node-local -SetLocalNodejs` or `node-local -OverrideNodejs`

### Git Bash Support
When bash is detected in PATH (via `Test-BashAvailable`), node-local automatically generates bash wrapper proxies alongside CMD proxies:

**Proxy generation:**
- CMD proxies: `node.cmd`, `npm.cmd`, `npx.cmd`, `nlocal-node.cmd`, etc.
- Bash proxies: `node`, `npm`, `npx`, `nlocal-node`, etc. (no extension)
- Both types generated during `New-CoreProxyFiles` and `Sync-GlobalCommands`

**Path handling in bash proxies:**
- Windows paths (`C:\Users\...`) converted to Git Bash format (`/c/Users/...`)
- Settings file read with aggressive cleanup: `tr -d '\r\n '` (removes CR/LF/spaces)
- UTF-8 without BOM, LF line endings for POSIX compliance

**Git Bash users can now:**
- Use `node -v`, `npm install`, `npx`, etc. directly in Git Bash
- Benefit from auto-sync on global package installs
- Switch versions and have proxies update automatically

See `docs/GITBASH_SUPPORT.md` for testing guide.

## Critical Workflows

### Installation Flow
```powershell
.\install.ps1 [-OverrideNodejs]  # Copies scripts/libs to %APPDATA%\node-local\bin, generates core proxies, adds to PATH
```
- Copies `node-local.ps1`, `lib\`, `templates\` to `%APPDATA%\node-local\bin\`
- Calls `New-CoreProxyFiles` to generate `nlocal-node.cmd`, `nlocal-npm.cmd`, `nlocal-npx.cmd`
- Adds `%APPDATA%\node-local\bin` to user PATH (not system-wide)
- ⚠️ Terminal restart required for PATH changes

### Version Install & Use Flow
```powershell
node-local install 20.11.0 --alias production
# → Downloads from nodejs.org, verifies SHA256, extracts to versions\production\
# → No auto-switch, must manually run 'use'

node-local use production
# → Writes "production" to settings.txt
# → Calls Sync-GlobalCommands (regenerates ALL dynamic proxies from versions\production\)
```

**Key insight:** `use` triggers full proxy regeneration. The `Sync-GlobalCommands` function:
1. Clears all dynamic `.cmd` files (keeps core: `nlocal-*.cmd`, `node.cmd`, `npm.cmd`, `npx.cmd`)
2. Scans active version's global `node_modules\.bin\` for installed packages
3. Generates generic proxies for each (e.g., `tsc.cmd` → routes to `versions\production\tsc.cmd`)

### Upgrade/Downgrade Flow (Interactive)
```powershell
node-local upgrade
# → Step 1: Select installation to upgrade (from list)
# → Step 2: Select major release (e.g., 18.x, 20.x, 22.x) - filters >= current version
# → Step 3: Select specific version from major
# → Step 4: Save global packages list
# → Step 5: Download & install new version to same folder
# → Step 6: Optionally restore global packages
# → Step 7: Auto-sync if currently active

node-local downgrade
# → Same flow but filters < current version only
```

**Critical details:**
- `Compare-SemanticVersion` used for version filtering (upgrade shows only newer, downgrade only older)
- Package preservation: saves `npm list -g --depth=0 --json` before upgrade
- In-place upgrade: overwrites folder content, preserves alias name
- Auto-triggers `Sync-GlobalCommands` if upgraded version is currently active

### Auto-Sync on Global Install
```powershell
nlocal-npm install -g typescript
# → package-manager.cmd.template detects "-g" flag
# → Runs npm install -g normally
# → On success (ERRORLEVEL 0), calls: powershell node-local.ps1 sync
# → Sync regenerates dynamic proxies (e.g., adds tsc.cmd)
```

**Auto-sync triggers:** Any command with `-g`, `--global`, or `global` in args.

## Conventions & Patterns

### Version String Handling
- **Input:** Accepts `20.11.0` or `v20.11.0`
- **Storage (settings.txt):** Folder name as-is (e.g., `production`, `20.11.0`)
- **Display:** Always shows semver format (e.g., `18.20.0`)
- **File naming:** No `v` prefix in folder names

### Error Messages (Italian Language)
- Use `Write-Host` with `-ForegroundColor` for user feedback
- Red for errors, Yellow for warnings, Green for success, Cyan for info
- Always suggest next action: `"Usa 'node-local list' per vedere le versioni disponibili."`
- Italian is MANDATORY for all user-facing text (error messages, prompts, confirmations)
- Code comments can be English or Italian, but consistency within a file is preferred

### File Encoding
- **PowerShell scripts:** UTF-8 with BOM
- **CMD proxies:** ASCII (no BOM) via `Out-File -Encoding ASCII -NoNewline`
- **settings.txt:** UTF-8 without BOM (see `Set-CurrentVersion` in `core.ps1`)

### Testing Commands
```powershell
# Test installation in isolation (doesn't modify system)
.\test-isolated.ps1

# Debug PATH and configuration
node-local debug

# Manual proxy regeneration
node-local sync          # Regenerates dynamic commands only
node-local sync --force  # Regenerates ALL commands (including core)
```

## Integration Points

### External Dependencies
- **nodejs.org API:** `https://nodejs.org/dist/index.json` for version list (see `remote.ps1`)
- **SHA256 verification:** Downloads `.zip` and compares against `SHASUMS256.txt` from nodejs.org
- **Windows PATH:** Manipulated via `[Environment]::SetEnvironmentVariable` (user scope only)

### Cross-Module Communication
- All modules share Script-scope variables (no return values for config)
- `aliases.ps1` provides lookup abstraction over filesystem
- `versions.ps1` delegates to `aliases.ps1` for installation resolution
- `sync.ps1` calls back to `core.ps1` for `New-CoreProxyFiles` on `--force`

## Common Pitfalls
- **Windows `.exe` precedence:** If system `node.exe` exists, it always runs before `node.cmd` (Windows PATH rules)
- **Terminal restart:** PATH changes require new terminal session
- **Template paths:** Functions expect templates at `$ScriptRoot\templates\` or `$BinPath\templates\` (copied during install)
- **Async execution:** `run_in_terminal` with `isBackground=true` for long-running commands (e.g., downloads)
- **Bash proxy generation:** Only happens if bash is in PATH. No bash = no bash proxies (silent, by design). Check with `which bash` in Git Bash.
- **Path conversion in bash:** Must convert Windows paths to Git Bash format (`C:\` → `/c/`). Never use `[regex]::Escape()` on paths - causes dots to be escaped (`settings\.txt`)
- **Line endings in bash files:** Must be LF, not CRLF. Use `[System.Text.UTF8Encoding]($false)` to write without BOM
- **Settings file reading in bash:** Must clean whitespace aggressively: `tr -d '\r\n '` handles CRLF and trailing spaces

## Key Files for AI Context
- `node-local.ps1` - Entry point, command routing, module loading
- `lib/core.ps1` - Core proxy generation, current version management, bash availability check
- `lib/templates.ps1` - Template substitution engine (CMD and Bash), path conversion logic
- `lib/sync.ps1` - Auto-sync logic, dynamic proxy lifecycle for both CMD and Bash
- `templates/*.template` - CMD and Bash proxy blueprints
- `README.md` - User-facing documentation (Italian)
- `docs/GITBASH_SUPPORT.md` - Git Bash testing and troubleshooting guide

## Development Guidelines
- **Keep it user-first:** No admin rights, no registry, no system modifications
- **Filesystem = truth:** No JSON/config files for aliases, folder names are aliases
- **Template-driven:** Never hard-code proxy logic, always use templates
- **Auto-sync everything:** Global installs/uninstalls must trigger proxy regeneration
- **Cross-shell support:** Generate both CMD and Bash proxies automatically when bash is available
- **Italian comments/messages:** User-facing text is in Italian
