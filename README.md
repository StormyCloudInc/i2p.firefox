Current Status / Recent Changes (Feb 2026)
=========================================

This branch includes several installer and launcher improvements:

- Fixed the Windows double-launcher/double-tray behavior by patching internal desktop GUI tray launch handling.
- Updated I2P app/icon assets so taskbar/console/installer use the new I2P icon set.
- Added detection of existing I2P installs before uninstall/reinstall flow, to handle fresh-build replacement more safely.
- Switched install target to Program Files instead of AppData.
- Added automatic Firefox download support.
- Added M-Lab speed test integration and automatic bandwidth tuning, including share ratio setup.
- Added UPNP selection and additional router.config setup defaults during install/config.

Known Regression / Open Issue
-----------------------------

In attempting to fully eliminate double-launch behavior, Firefox Safe/Flexible launches are currently not fully reliable:

- Safe mode may open regular Firefox behavior unexpectedly.
- Flexible mode may appear to load Safe-mode-style profile/plugin behavior.
- Tabs can fail to load reliably (intermittent white/frozen tab state).

Current debugging points to launch-path contention/race behavior around Firefox invocation and profile handoff. This remains an active fix area.
I2P Easy-Install Bundle for Windows
===================================

This repository builds the NSIS-based Windows installer for I2P using a
jpackage app-image (bundled JVM + launcher + router files).

Supported build path
--------------------

Only this path is supported:

1. `./buildscripts/unsigned.sh`

Equivalent manual steps:

1. `./buildscripts/build.sh`
2. `./buildscripts/nsis.sh`

What the build produces
-----------------------

- `I2P-Easy-Install-Bundle-<version>.exe` (root)
- `build/I2P/` (staging app-image copy)
- `I2P-Prebuilt.zip` (staging artifact)

Prerequisites
-------------

- Windows host (Git Bash/MSYS environment)
- JDK 21+ with `JAVA_HOME` set
- Apache Ant
- NSIS 3.x (`makensis` available in PATH)
- Git

Notes
-----

- Building without jpackage is not supported.
- Legacy alternate packaging paths (EXE/MSI/portable ZIP/TGZ) were removed.
- See `docs/JPACKAGE-MIGRATION.md` for migration/cleanup notes.

Release
-------

- Build unsigned installer: `./buildscripts/unsigned.sh`
- Build + sign installer: `./buildscripts/release.sh`


