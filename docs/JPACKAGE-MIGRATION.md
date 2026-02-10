# jpackage Migration Notes

This repository now uses a jpackage-first Windows installer flow.

## Canonical Build Pipeline

1. `buildscripts/build.sh`
2. `buildscripts/nsis.sh`

Or use the wrapper:

1. `buildscripts/unsigned.sh`

## What Changed

- IzPack-style install behavior is no longer the primary packaging path.
- The NSIS installer now installs a jpackage app-image layout:
  - `$INSTDIR\app`
  - `$INSTDIR\runtime`
  - `$INSTDIR\config`
- Writable runtime data is under:
  - `$LOCALAPPDATA\I2P`

## Cleanup Policy

- `build/` is a generated directory.
- Root-level installer outputs (`I2P-Easy-Install-Bundle-*.exe`) are generated artifacts.
- `src/nsis/i2pbrowser-jpackage.nsi` is obsolete and should not be generated.
- Legacy scripts for alternate packaging formats were removed:
  - `buildscripts/exe.sh`
  - `buildscripts/msi.sh`
  - `buildscripts/zip.sh`
  - `buildscripts/targz.sh`
  - related helper scripts for those outputs
- Legacy GitHub daily/edit release helper scripts were removed:
  - `buildscripts/daily.sh`
  - `buildscripts/daily-unstable.sh`
  - `buildscripts/edit-release.sh`
  - `buildscripts/edit-release-unstable.sh`

## Documentation Scope

- `README.md` is the authoritative build entrypoint guide.
- Legacy architecture details in older docs should be treated as historical unless
  they match the scripts in `buildscripts/` and the installer in
  `src/nsis/i2pbrowser-installer.nsi`.
