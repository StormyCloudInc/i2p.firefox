# I2P Easy-Install Bundle for Windows - Repository Analysis

## Table of Contents

1. [Project Overview](#project-overview)
2. [Repository Structure](#repository-structure)
3. [Architecture Overview](#architecture-overview)
4. [Windows NSIS Installer (The "Easy Installer")](#windows-nsis-installer)
5. [Java Launcher System](#java-launcher-system)
6. [Build System & Pipeline](#build-system--pipeline)
7. [Configuration Files](#configuration-files)
8. [CI/CD Workflows](#cicd-workflows)
9. [Update Mechanism](#update-mechanism)
10. [Browser Integration Philosophy](#browser-integration-philosophy)
11. [Known Issues & Areas for Improvement](#known-issues--areas-for-improvement)

---

## Project Overview

**Repository:** `i2p.firefox` (mirrors: [GitHub](https://github.com/i2p/i2p.firefox) / [i2pgit.org](https://i2pgit.org/i2p-hackers/i2p.firefox))
**Current Version:** 2.6.0 (latest tag), master defaults to 2.8.1
**License:** MIT (2018)
**Primary Author:** idk (with contributions from zab, zzz, and others)

This project creates the **I2P Easy-Install Bundle for Windows** - a self-contained Windows installer that bundles:
- A complete I2P router (via Java jpackage with bundled JVM)
- Automatic browser profile configuration for I2P
- Browser extensions for privacy and security
- Pre-configured tunnels (HTTP proxy, IRC, eepsite, SMTP, POP3, HTTPS proxy, Git SSH)

The goal is to make I2P post-install configuration trivially simple for end users. No separate Java installation is needed - everything is self-contained.

---

## Repository Structure

```
i2p.firefox/
├── .github/workflows/       # CI/CD (5 workflow files)
│   ├── ant.yml              # Main build pipeline (NSIS, EXE, MSI, ZIP, TGZ)
│   ├── ant-latest.yml       # Build from latest I2P release
│   ├── release.yml          # GitHub release publishing
│   ├── release-nightly.yml  # Nightly release automation
│   └── release-nightly-latest.yml
│
├── buildscripts/            # 28 build automation scripts
│   ├── unsigned.sh          # MAIN ENTRY POINT - orchestrates build
│   ├── build.sh             # Core build (clone I2P, jpackage, compile launcher)
│   ├── launcher.sh          # Compiles Java launcher + builds launcher.jar
│   ├── nsis.sh              # Runs makensis to produce .exe installer
│   ├── clean.sh             # Cleanup script
│   ├── version.sh           # Version extraction from git tags
│   ├── licenses.sh          # License aggregation (max 28752 bytes for NSIS)
│   ├── sign.sh              # Code-signing for release builds
│   ├── exe.sh               # Alternative: jpackage EXE output
│   ├── msi.sh               # Alternative: Windows MSI output
│   ├── zip.sh               # Portable ZIP (bundles Tor Browser)
│   ├── targz.sh             # Linux tar.gz archive
│   ├── release.sh           # Full release build + signing
│   ├── daily*.sh            # Nightly/daily build variants
│   ├── getprebuilt.sh       # Downloads pre-built jpackage for Mac/Linux
│   └── wine-jpackage.sh     # Experimental: jpackage via Wine
│
├── java/net/i2p/router/     # Java source code (7 files)
│   ├── WinLauncher.java     # ENTRY POINT - launches I2P router
│   ├── I2PAppUtil.java      # Detects existing I2P installs
│   ├── WindowsAppUtil.java  # Path resolution for jpackage
│   ├── WindowsServiceUtil.java  # Windows service detection/management
│   ├── WinUpdatePostProcessor.java  # Handles downloaded updates
│   ├── WinUpdateProcess.java       # Runs EXE update installers
│   └── ZipUpdateProcess.java       # Extracts ZIP updates
│
├── src/
│   ├── nsis/                # NSIS installer scripts
│   │   ├── i2pbrowser-installer.nsi   # Main installer script (285 lines)
│   │   ├── i2pbrowser-version.nsi     # Version definitions
│   │   └── FindProcess.nsh            # Process detection macro
│   ├── win/                 # Windows launcher helpers
│   │   └── torbrowser-windows.sh      # Tor Browser downloader (Windows)
│   ├── unix/                # Unix launcher helpers
│   │   └── torbrowser.sh             # Tor Browser downloader (Linux)
│   ├── icons/               # Application icons (.ico, .png)
│   └── I2P/config/          # Template config directory for jpackage
│
├── docs/
│   ├── GOALS.md             # Feature goals checklist
│   ├── PRINCIPLES.md        # Design philosophy
│   └── RELEASE.md           # Release notes template
│
├── license/                 # 55 license files for bundled components
├── Makefile                 # Build orchestration (57 lines)
├── config.sh                # Build environment configuration
├── i2pversion               # Version management (sources from git tags)
├── router.config            # I2P router configuration template
├── i2ptunnel.config         # Tunnel configuration template
├── changelog.txt            # Full changelog
├── Dockerfile               # Docker build support
└── README.md                # Build instructions
```

---

## Architecture Overview

### Class Hierarchy

```
WindowsServiceUtil          (Windows service detection via `sc query`)
    └── WindowsAppUtil      (jpackage path resolution)
        └── I2PAppUtil      (existing I2P install detection, update URLs)
            └── WinLauncher (ENTRY POINT - router initialization + launch)

WinUpdatePostProcessor      (intercepts downloaded SU3 updates)
    ├── WinUpdateProcess    (runs EXE installer silently post-shutdown)
    └── ZipUpdateProcess    (extracts ZIP updates for portable installs)
```

### Data Flow: Installation

```
User runs I2P-Easy-Install-Bundle-X.Y.Z.exe
    → NSIS license page
    → NSIS directory selection page
    → routerDetect() function copies jpackage files:
        - I2P/app/      → $INSTDIR/app/
        - I2P/runtime/   → $INSTDIR/runtime/
        - I2P/config/    → $INSTDIR/config/
        - I2P/I2P.exe    → $INSTDIR/I2P.exe
        - certificates/  → $INSTDIR/certificates/
        - geoip/         → $INSTDIR/geoip/
    → installerFunction() creates:
        - Desktop shortcut: "Browse I2P.lnk"
        - Start Menu: "i2peasy/Browse I2P.lnk"
        - Start Menu: "i2peasy/Uninstall I2P Easy-Install Bundle.lnk"
        - Uninstaller: uninstall-i2pbrowser.exe
        - Preserves existing eepsite/docroot if present
    → Optional: Launch I2P post-install
```

### Data Flow: Runtime Launch

```
User clicks "Browse I2P" shortcut
    → I2P.exe (jpackage native launcher)
    → WinLauncher.main()
        → Sets system properties:
            - i2p.dir.base = {install}/config
            - i2p.dir.config = {install}/config
            - router.pid = current PID
            - user.dir = {install} (CRITICAL for Win11)
        → Creates Router instance with router.config
        → promptServiceStartIfAvailable("i2p")
            → If Windows service detected: prompt user
        → promptUserInstallStartIfAvailable()
            → If Program Files I2P found: prompt user
        → Starts UPP registration thread (for updates)
        → i2pRouter.runRouter()
```

---

## Windows NSIS Installer

**File:** `src/nsis/i2pbrowser-installer.nsi` (285 lines)

### Key Characteristics

| Property | Value |
|----------|-------|
| Installer Type | NSIS v3 (Unicode) |
| Execution Level | `user` (no admin required) |
| Default Install Dir | `%LOCALAPPDATA%\i2peasy\` |
| Output Filename | `I2P-Easy-Install-Bundle-{VERSION}.exe` |
| Languages | 60+ (English, French, German, Chinese, Japanese, Arabic, etc.) |

### Installer Pages (in order)

1. **License Page** - Shows aggregated licenses from all bundled components
2. **Directory Page** - User selects install location (triggers `routerDetect()` which immediately copies files)
3. **Install Files Page** - Runs `installerFunction()` for shortcuts, licenses, uninstaller
4. **Finish Page** - Optional "Start I2P?" checkbox

### Critical Design Decisions

- **Files are copied in `routerDetect()`** (the directory page callback), NOT in the main install section. This means files are copied as soon as the user confirms the directory.
- **User-mode installation only** - `RequestExecutionLevel user` means no UAC prompt
- **Silent install support** - `/S` flag with `/D=` for directory; waits for any running I2P.exe to exit
- **`jpackaged` marker file** - Used during uninstall to determine if configs were created by the installer (safe to delete) vs. user-created (must preserve)

### Uninstaller Behavior

1. Checks if I2P.exe is running; if so, shows message and waits
2. Removes `app/`, `config/`, `runtime/` directories
3. Removes I2P.exe and icons
4. Removes desktop and Start Menu shortcuts
5. Only removes user configs if `jpackaged` marker file exists

### Potential Improvement Areas

- **No progress bar** during file copy (files are copied in the directory page callback)
- **No component selection** - all-or-nothing install
- **No custom UI branding** beyond the icon
- **Rudimentary error handling** - no rollback on partial install failure
- **Silent update uses `/S /D=`** which overrides install directory
- **Release workflow uses 20-minute sleep** to wait for build artifacts (fragile)
- **No Add/Remove Programs entry** (no registry keys written for `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall`)
- **No bandwidth/connection speed selection** during install
- **No firewall rule creation** for the I2P router
- **No option to install as Windows service** (checkbox in GOALS.md is unchecked)
- **eepsite directory preservation** uses simple `IfFileExists` check

---

## Java Launcher System

### WinLauncher.java (Entry Point)

**File:** `java/net/i2p/router/WinLauncher.java` (166 lines)

This is the `main-class` for the jpackage. Key responsibilities:

1. **Set critical system properties:**
   - `i2p.dir.base` / `i2p.dir.config` → `{install}/config`
   - `router.pid` → current process PID (Java 9+ `ProcessHandle` API)
   - `user.dir` → install directory root (**critical fix for Windows 11**)

2. **Service detection:** Checks for Windows service named "i2p" via `sc query`
3. **Unbundled I2P detection:** Checks `%PROGRAMFILES%/i2p/i2p.exe`
4. **Update registration:** Spawns daemon thread that waits for RouterContext, ClientAppManager, and UpdateManager, then registers `WinUpdatePostProcessor` for `ROUTER_SIGNED_SU3` and `ROUTER_DEV_SU3` update types

### WindowsServiceUtil.java

Queries Windows services via `sc query` command and parses output.

**States tracked:** STOPPED(1), START_PENDING(2), STOP_PENDING(3), RUNNING(4), CONTINUE_PENDING(5), PAUSE_PENDING(6), PAUSED(7)

**Notable:** Uses `JOptionPane` Swing dialogs for user interaction. Cannot directly start services (permission issue) - opens `services.msc` instead.

**Bug:** `osName() != "windows"` on line 113 uses reference equality (`!=`) instead of `.equals()` - this comparison always returns `true` in Java since string literals from different methods may not be interned.

### WindowsAppUtil.java

Resolves paths relative to the jpackage app-image structure:
- **Windows:** `java.home` parent = app-image root (1 level up)
- **Linux/Mac:** `java.home` parent.parent = app-image root (2 levels up)

**Bug:** The `appImageConfig()` switch statement for `"windows"` case falls through to `"mac"`/`"linux"` case (missing `break` statement).

### I2PAppUtil.java

Detects existing I2P installations in `%PROGRAMFILES%` and `%PROGRAMFILES86%` (note: correct env var is `ProgramFiles(x86)`, not `PROGRAMFILES86`).

Defines update feed URLs:
- Update: `ekm3fu6fr5pxudhwjmdiea5dovc3jdi66hjgop4c7z7dfaw7spca.b32.i2p`
- News: `dn3tvalnjz432qkqsvpfdqrwpqkw3ye4n4i2uyfr4jexvo3sp5ka.b32.i2p`
- Backup: `tc73n4kivdroccekirco7rhgxdg5f3cjvbaapabupeyzrqwv5guq.b32.i2p`

---

## Build System & Pipeline

### Build Entry Point

```
./buildscripts/unsigned.sh
    → clean.sh           # Remove old build artifacts
    → build.sh           # Full build (see below)
    → nsis.sh            # Package into NSIS installer
```

### build.sh / launcher.sh Flow

```
1. Source i2pversion, config.sh
2. Run version.sh + licenses.sh
3. Detect platform (Linux/Mac → download prebuilt; Windows → build from source)
4. Clone i2p.i2p repository (tagged version or master)
5. Set EXTRA = "-win" in RouterVersion.java
6. Run `ant distclean pkg` to build I2P jars
7. Run `ant jbigi` for native acceleration
8. Copy config files (router.config, i2ptunnel.config, hosts.txt, certificates, etc.)
9. Download dependencies:
   - JNA 5.12.1 (jna.jar, jna-platform.jar)
   - i2pfirefox plugin (plugin.zip from GitHub releases)
   - GeoLite2-Country.mmdb.gz
10. Pack Windows DLLs into jbigi.jar
11. Compile 7 Java source files into build/ directory
12. Create launcher.jar
13. Run jpackage:
    --type app-image
    --name I2P
    --main-jar launcher.jar
    --main-class net.i2p.router.WinLauncher
    --java-options "-Xmx512m" + module opens
    --app-content config, scripts, icons
14. Create I2P-Prebuilt.zip
```

### nsis.sh Flow

```
1. Copy .nsi, .nsh, .ico files to build/
2. Run makensis i2pbrowser-installer.nsi
3. Copy output .exe to repo root
```

### Alternative Build Formats

| Format | Script | Output | Notes |
|--------|--------|--------|-------|
| NSIS | `nsis.sh` | `I2P-Easy-Install-Bundle-X.Y.Z.exe` | Main installer, requires NSIS |
| EXE | `exe.sh` | `I2P-EXE-X.Y.Z.exe` | jpackage native EXE, experimental |
| MSI | `msi.sh` | `I2P-MSI-X.Y.Z.msi` | Windows Installer format |
| ZIP | `zip.sh` | `I2P-windows-portable.zip` | Portable, includes Tor Browser |
| TGZ | `targz.sh` | `I2P.tar.gz` | Linux portable |

### Build Dependencies

**Build-time:**
- Java 14+ (Java 21 used in CI, 17+ recommended)
- NSIS 3.x + ShellExecAsUser plugin
- Apache Ant
- Git, curl/wget, jq, dos2unix, 7zip, GPG
- WSL (Ubuntu 20.04) or Cygwin for Windows builds

**Runtime (all bundled):**
- JVM (via jpackage)
- I2P router libraries
- JNA 5.12.1
- i2pfirefox browser plugin
- jbigi native acceleration

---

## Configuration Files

### router.config

```ini
router.updateURL=http://ekm3fu6fr5...b32.i2p/i2pwinupdate.su3
router.newsURL=http://dn3tva...b32.i2p/news/win/beta/news.su3
router.backupNewsURL=http://tc73n4...b32.i2p/win/beta/news.su3
routerconsole.browser=I2P.exe -noproxycheck
router.disableTunnelTesting=false
```

### i2ptunnel.config - Pre-configured Tunnels

| Tunnel | Type | Port | Target | Auto-Start |
|--------|------|------|--------|------------|
| HTTP Proxy | httpclient | 4444 | exit.stormycloud.i2p (outproxy) | Yes |
| IRC (Irc2P) | ircclient | 6668 | irc.postman.i2p, irc.echelon.i2p | Yes |
| POP3 | client | 7660 | pop.postman.i2p:110 | Yes |
| I2P Webserver | httpserver | 7658 | localhost (eepsite) | No |
| SMTP | client | 7659 | smtp.postman.i2p:25 | Yes |
| HTTPS Proxy | connectclient | 4445 | outproxy-tor.meeh.i2p | Yes |
| Git SSH | client | 7670 | gitssh.idk.i2p | No |

All tunnels use 3-hop inbound/outbound lengths with ed25519 signatures where applicable.

---

## CI/CD Workflows

### ant.yml - Main Build (triggers on push)

Runs 5 parallel jobs on `windows-latest`:
1. **nsis** - NSIS installer (uses WSL for makensis)
2. **buildjpackagexe** - jpackage EXE
3. **buildjpackagmsi** - MSI installer
4. **buildzip** - Portable ZIP (uses WSL + choco)
5. **buildtgz** - Linux tar.gz (runs on `ubuntu-latest`)

### release.yml - GitHub Release (triggers on tag `i2p-firefox-*.*.*`)

1. Waits **20 minutes** (via repeated `sleep 1m`) for ant.yml artifacts
2. Downloads artifacts from ant.yml using `dawidd6/action-download-artifact@v3`
3. Generates SHA256 checksums
4. Creates GitHub release with all artifacts

---

## Update Mechanism

### Two Update Paths

1. **EXE Updates (Windows bundled installs):**
   - `WinUpdatePostProcessor` intercepts SU3 updates
   - Moves installer to `{config}/i2p_update_win/`
   - Registers shutdown hook (`WinUpdateProcess`)
   - On router shutdown: runs installer with `/S /D={workDir}`
   - Sets `RESTART_I2P=true` env var if graceful restart requested

2. **ZIP Updates (portable/Linux installs):**
   - `WinUpdatePostProcessor` intercepts ZIP-type updates
   - Registers shutdown hook (`ZipUpdateProcess`)
   - On router shutdown: extracts ZIP to config directory

### Update Channels

- **Signed releases:** `UpdateType.ROUTER_SIGNED_SU3`
- **Development releases:** `UpdateType.ROUTER_DEV_SU3`
- Both registered at startup via daemon thread

---

## Browser Integration Philosophy

From `docs/PRINCIPLES.md`:

### Core Principles

1. **Browser is integral** to I2P use for most users
2. **Effective browser config is impossible for individual users** - anti-fingerprinting only works en masse
3. **Host browser provides security** (runtime sandboxing, exploit mitigation)
4. **Easy-Install provides privacy** (proxy config, extension loadout, fingerprint reduction)
5. **Reduce coarse fingerprints** to exactly 18: 9 browsers x 2 modes

### Supported Browsers (priority order)

**Firefox-based (preferred):** Tor Browser > Firefox > Waterfox > LibreWolf
**Chromium-based (fallback):** Ungoogled-Chromium > Chromium > Brave > Chrome > Edge

### Operating Modes

| Mode | JavaScript | Primary Defense | Use Case |
|------|-----------|-----------------|----------|
| **Strict** (default) | Disabled (NoScript) | Anti-fingerprinting | Maximum security |
| **Usability** | Restricted (jShelter) | Ad blocking + CDN caching | Balanced browsing |
| **App** | N/A | Restricted to I2P apps only | Router console access |

---

## Known Issues & Areas for Improvement

### Windows Installer Specific

1. **No Add/Remove Programs entry** - The installer doesn't write uninstall registry keys to `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall`, so the app doesn't appear in Windows Settings > Apps
2. **File copy in directory callback** - `routerDetect()` copies all files during the directory selection page rather than the install section; no progress feedback
3. **No component selection** - Users can't choose what to install (e.g., skip browser integration)
4. **No install progress bar** during the large file copy operation
5. **No firewall rule setup** - Users must manually allow I2P through Windows Firewall
6. **No Windows service install option** (listed as unchecked goal in GOALS.md)
7. **Fragile release pipeline** - 20-minute sleep waiting for artifacts to be ready
8. **No upgrade detection** - Doesn't detect or handle existing installations gracefully beyond the `jpackaged` marker
9. **No bandwidth/performance configuration** during install
10. **No autostart configuration** during install (startup with Windows)

### Java Code Issues

11. **String comparison bug** - `WindowsServiceUtil.java:113` and `I2PAppUtil.java:53` use `!=` instead of `.equals()` for string comparison
12. **Switch fall-through** - `WindowsAppUtil.java:121` Windows case falls through to Mac/Linux case (missing `break`)
13. **Environment variable name** - `I2PAppUtil.java` checks `PROGRAMFILES86` but the correct Windows env var is `ProgramFiles(x86)`
14. **ZipUpdateProcess** doesn't check for zip-slip vulnerability (acknowledged in comments as acceptable since updates are signed)
15. **Swing dialogs** (`JOptionPane`) for service prompts may be jarring; no native Windows notifications

### Build System

16. **`build.sh` has a typo** on line 47: `"$SCRIPT_DI"$SCRIPT_DIR"/buildscripts/launcher.sh"` - broken string quoting
17. **Platform detection** is duplicated across multiple scripts
18. **No reproducible builds** - depends on external downloads (JNA, i2pfirefox plugin) at build time
19. **Mac/Linux on build.sh** just download prebuilt and exit - can't build from source on those platforms

### UX/User Experience

20. **No first-run wizard** - After install, user is dropped into the I2P router console with no guided setup
21. **No system tray integration** in the launcher
22. **No visual feedback** during router startup (just a blank wait)
23. **Browser auto-detection** happens at runtime with no user override in installer
24. **No localization of installer messages** beyond NSIS language packs (the custom message strings are English-only)

---

## Version Management

Version is derived from git tags:

```
git describe --tags --abbrev=0  →  i2p-firefox-X.Y.Z
    VERSIONMAJOR = X
    VERSIONMINOR = Y
    VERSIONBUILD = Z
```

If no tag is found (master branch), defaults to version `2.8.1` with `I2P_VERSION=master`.

JNA version is pinned at `5.12.1`.

---

## File Size Constraints

- **License file total:** Must be < 28,752 bytes (NSIS v3.03 crash bug)
- **Installer output:** Typically ~120-150 MB (includes full JVM + I2P + browser extensions)

---

## Key External Dependencies

| Dependency | Source | Purpose |
|-----------|--------|---------|
| I2P Router | i2pgit.org/i2p-hackers/i2p.i2p | Core router |
| i2pfirefox | github.com/eyedeekay/i2p.plugins.firefox | Browser profile management |
| JNA 5.12.1 | Maven Central | Windows API access |
| NSIS 3.x | nsis.sourceforge.io | Installer creation |
| ShellExecAsUser | NSIS plugin | User-mode execution |
| Tor Browser | torproject.org | Downloaded for portable builds |
| GeoLite2 | i2p.i2p resources | Country-level GeoIP |
| jbigi | i2p.i2p build | Native crypto acceleration |
