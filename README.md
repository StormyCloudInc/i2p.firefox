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

