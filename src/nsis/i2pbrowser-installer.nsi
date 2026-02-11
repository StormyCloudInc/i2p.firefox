# This now requires v3
UniCode true

!define APPNAME "I2P"
!define COMPANYNAME "I2P"
!define DESCRIPTION "This is a tool which contains an I2P router, a bundled JVM, and a tool for automatically configuring a browser to use with I2P."
!define I2P_MESSAGE "Please choose an installation directory."
!define LAUNCH_TEXT "Start I2P?"
!define LICENSE_TITLE "Many Licenses"
!define CONSOLE_URL "http://127.0.0.1:7657/home"

!include i2pbrowser-version.nsi
!include FindProcess.nsh

SetOverwrite on

!define RAM_NEEDED_FOR_64BIT 0x80000000

InstallDir "$PROGRAMFILES64\${APPNAME}"

# Data directory for writable config/data (set in .onInit)
Var DATADIR

# rtf or txt file - remember if it is txt, it must be in the DOS text format (\r\n)
LicenseData "licenses\LICENSE.txt"
# This will be in the installer/uninstaller's title bar
Name "${COMPANYNAME} - ${APPNAME}"
Icon i2p.ico
OutFile "I2P-Easy-Install-Bundle-${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.exe"

RequestExecutionLevel admin

!include LogicLib.nsh
!include x64.nsh
!include FileFunc.nsh
!include nsDialogs.nsh
!include WordFunc.nsh
!define MUI_ICON i2p.ico
!define MUI_FINISHPAGE
!include "MUI2.nsh"

# --- Variables for configuration wizard ---
Var BandwidthIn
Var BandwidthOut
Var SharePercent
Var UPnPEnabled
Var HiddenMode
Var FloodfillEnabled
Var I2PPort
Var InstallFirefox
Var FirefoxDetected
Var BwInHandle
Var BwOutHandle
Var DlResultLabel
Var UlResultLabel
Var RecResultLabel
Var SpeedTestBtn
Var SpeedTestProgress

PageEx license
    licensetext "${LICENSE_TITLE}"
    licensedata "licenses\LICENSE.txt"
PageExEnd
PageEx directory
    dirtext "${I2P_MESSAGE}"
    dirvar $INSTDIR
PageExEnd
# Firefox detection page
Page custom FirefoxDetectPage FirefoxDetectLeave
# Configuration wizard pages
Page custom SpeedTestPage SpeedTestPageLeave
Page custom BandwidthPage BandwidthPageLeave
Page custom NetworkPage NetworkPageLeave
Page instfiles

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "${LAUNCH_TEXT}"
!define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"
!insertmacro MUI_PAGE_FINISH

### Available languages (must come after all MUI_PAGE_* macros)
  !insertmacro MUI_LANGUAGE "English"
  !insertmacro MUI_LANGUAGE "French"
  !insertmacro MUI_LANGUAGE "German"
  !insertmacro MUI_LANGUAGE "Spanish"
  !insertmacro MUI_LANGUAGE "SpanishInternational"
  !insertmacro MUI_LANGUAGE "SimpChinese"
  !insertmacro MUI_LANGUAGE "TradChinese"
  !insertmacro MUI_LANGUAGE "Japanese"
  !insertmacro MUI_LANGUAGE "Korean"
  !insertmacro MUI_LANGUAGE "Italian"
  !insertmacro MUI_LANGUAGE "Dutch"
  !insertmacro MUI_LANGUAGE "Danish"
  !insertmacro MUI_LANGUAGE "Swedish"
  !insertmacro MUI_LANGUAGE "Norwegian"
  !insertmacro MUI_LANGUAGE "NorwegianNynorsk"
  !insertmacro MUI_LANGUAGE "Finnish"
  !insertmacro MUI_LANGUAGE "Greek"
  !insertmacro MUI_LANGUAGE "Russian"
  !insertmacro MUI_LANGUAGE "Portuguese"
  !insertmacro MUI_LANGUAGE "PortugueseBR"
  !insertmacro MUI_LANGUAGE "Polish"
  !insertmacro MUI_LANGUAGE "Ukrainian"
  !insertmacro MUI_LANGUAGE "Czech"
  !insertmacro MUI_LANGUAGE "Slovak"
  !insertmacro MUI_LANGUAGE "Croatian"
  !insertmacro MUI_LANGUAGE "Bulgarian"
  !insertmacro MUI_LANGUAGE "Hungarian"
  !insertmacro MUI_LANGUAGE "Thai"
  !insertmacro MUI_LANGUAGE "Romanian"
  !insertmacro MUI_LANGUAGE "Latvian"
  !insertmacro MUI_LANGUAGE "Macedonian"
  !insertmacro MUI_LANGUAGE "Estonian"
  !insertmacro MUI_LANGUAGE "Turkish"
  !insertmacro MUI_LANGUAGE "Lithuanian"
  !insertmacro MUI_LANGUAGE "Slovenian"
  !insertmacro MUI_LANGUAGE "Serbian"
  !insertmacro MUI_LANGUAGE "SerbianLatin"
  !insertmacro MUI_LANGUAGE "Arabic"
  !insertmacro MUI_LANGUAGE "Farsi"
  !insertmacro MUI_LANGUAGE "Hebrew"
  !insertmacro MUI_LANGUAGE "Indonesian"
  !insertmacro MUI_LANGUAGE "Mongolian"
  !insertmacro MUI_LANGUAGE "Luxembourgish"
  !insertmacro MUI_LANGUAGE "Albanian"
  !insertmacro MUI_LANGUAGE "Breton"
  !insertmacro MUI_LANGUAGE "Belarusian"
  !insertmacro MUI_LANGUAGE "Icelandic"
  !insertmacro MUI_LANGUAGE "Malay"
  !insertmacro MUI_LANGUAGE "Bosnian"
  !insertmacro MUI_LANGUAGE "Kurdish"
  !insertmacro MUI_LANGUAGE "Irish"
  !insertmacro MUI_LANGUAGE "Uzbek"
  !insertmacro MUI_LANGUAGE "Galician"
  !insertmacro MUI_LANGUAGE "Afrikaans"
  !insertmacro MUI_LANGUAGE "Catalan"
  !insertmacro MUI_LANGUAGE "Esperanto"
  !insertmacro MUI_LANGUAGE "Basque"
  !insertmacro MUI_LANGUAGE "Welsh"
  !insertmacro MUI_LANGUAGE "Asturian"
  !insertmacro MUI_LANGUAGE "Pashto"
  !insertmacro MUI_LANGUAGE "ScotsGaelic"
  !insertmacro MUI_LANGUAGE "Georgian"
  !insertmacro MUI_LANGUAGE "Vietnamese"
  !insertmacro MUI_LANGUAGE "Armenian"
  !insertmacro MUI_LANGUAGE "Corsican"
  !insertmacro MUI_LANGUAGE "Tatar"
  !insertmacro MUI_LANGUAGE "Hindi"
### END LANGUAGES

# small speed optimization
!insertmacro MUI_RESERVEFILE_LANGDLL
# show all languages, regardless of codepage
!define MUI_LANGDLL_ALLLANGUAGES

Function ForceKillI2PProcess
    # Force-stop any running router process so uninstall/upgrade can proceed.
    nsExec::ExecToLog 'taskkill /F /T /IM I2P.exe'
    Sleep 1000
FunctionEnd

Function un.ForceKillI2PProcess
    # Uninstaller namespace variant.
    nsExec::ExecToLog 'taskkill /F /T /IM I2P.exe'
    Sleep 1000
FunctionEnd

Function .onInit
    StrCpy $DATADIR "$LOCALAPPDATA\I2P"
    !insertmacro MUI_LANGDLL_DISPLAY

    # Ensure no running instance blocks old-install detection or removal.
    Call ForceKillI2PProcess

    # Check for existing IzPack I2P installation (has lib/ directory, ours has app/)
    # Check via registry first
    ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\i2p" "UninstallString"
    StrCmp $0 "" checkI2PDir removeOldI2P

checkI2PDir:
    # Also check common install locations for IzPack I2P (lib/ directory distinguishes from our app/ layout)
    IfFileExists "$PROGRAMFILES64\i2p\lib\router.jar" 0 checkI2PDir86
    Goto foundOldI2P
checkI2PDir86:
    IfFileExists "$PROGRAMFILES\i2p\lib\router.jar" 0 noOldI2P
    Goto foundOldI2P

removeOldI2P:
    # Registry uninstaller found
    MessageBox MB_YESNO "An existing I2P installation was detected.$\n$\nWould you like to uninstall it first?$\nThis is recommended to avoid conflicts." IDNO noOldI2P
    Call ForceKillI2PProcess
    ExecWait '$0 _?=$PROGRAMFILES64\i2p'
    Goto noOldI2P

foundOldI2P:
    # IzPack directory found but no registry entry
    MessageBox MB_OK "An existing I2P installation was found in Program Files.$\n$\nPlease uninstall it manually before proceeding$\nto avoid conflicts with the I2P Easy-Install Bundle."

noOldI2P:
    # Set default config wizard values
    StrCpy $BandwidthIn "256"
    StrCpy $BandwidthOut "128"
    StrCpy $SharePercent "80"
    StrCpy $UPnPEnabled "true"
    StrCpy $HiddenMode "false"
    StrCpy $FloodfillEnabled "false"
    StrCpy $InstallFirefox "0"
    StrCpy $FirefoxDetected "0"

    # Generate a random port between 9000-31000 for I2P
    # NSIS doesn't have a random function, so use tick count as seed
    System::Call 'kernel32::GetTickCount() i .r0'
    IntOp $0 $0 % 22000
    IntOp $I2PPort $0 + 9000
FunctionEnd

# --- Firefox Detection Page ---
Function FirefoxDetectPage
    # Check if Firefox is installed via registry
    ReadRegStr $0 HKLM "Software\Mozilla\Mozilla Firefox" "CurrentVersion"
    StrCmp $0 "" 0 firefoxFound
    ReadRegStr $0 HKLM "Software\Wow6432Node\Mozilla\Mozilla Firefox" "CurrentVersion"
    StrCmp $0 "" firefoxNotFound firefoxFound

firefoxNotFound:
    StrCpy $FirefoxDetected "0"
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}
    ${NSD_CreateLabel} 0 0 100% 24u "Firefox was not detected on your system."
    Pop $0
    ${NSD_CreateLabel} 0 28u 100% 16u "Firefox is required to use the I2P browser profile."
    Pop $0
    ${NSD_CreateCheckBox} 0 52u 100% 14u "Install Firefox (will download and install automatically)"
    Pop $1
    ${NSD_Check} $1
    StrCpy $InstallFirefox "1"
    ${NSD_OnClick} $1 OnFirefoxCheckToggle
    nsDialogs::Show
    Return

firefoxFound:
    StrCpy $FirefoxDetected "1"
    # Firefox found, skip this page
    Abort
FunctionEnd

Function OnFirefoxCheckToggle
    Pop $0
    ${NSD_GetState} $0 $1
    ${If} $1 == ${BST_CHECKED}
        StrCpy $InstallFirefox "1"
    ${Else}
        StrCpy $InstallFirefox "0"
    ${EndIf}
FunctionEnd

Function FirefoxDetectLeave
    # Nothing to validate, just proceed
FunctionEnd

# --- Speed Test Page (powered by M-Lab) ---
Function SpeedTestPage
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 16u "Internet Speed Test"
    Pop $0
    CreateFont $1 "$(^Font)" "11" "700"
    SendMessage $0 ${WM_SETFONT} $1 0

    ${NSD_CreateLabel} 0 20u 100% 36u "Measure your internet speed to set optimal I2P bandwidth.$\nPowered by Measurement Lab (M-Lab), a free open-source tool.$\nResults will pre-fill the bandwidth settings on the next page."
    Pop $0

    ${NSD_CreateButton} 30% 62u 40% 20u "Run Speed Test"
    Pop $1
    StrCpy $SpeedTestBtn $1
    ${NSD_OnClick} $1 OnRunSpeedTest

    ${NSD_CreateLabel} 30% 86u 40% 12u ""
    Pop $0
    StrCpy $SpeedTestProgress $0

    ${NSD_CreateGroupBox} 0 100u 100% 50u "Results"
    Pop $0

    ${NSD_CreateLabel} 10u 116u 88% 12u "Download: not yet tested"
    Pop $0
    StrCpy $DlResultLabel $0

    ${NSD_CreateLabel} 10u 132u 88% 12u "Upload: not yet tested"
    Pop $0
    StrCpy $UlResultLabel $0

    ${NSD_CreateLabel} 0 156u 100% 12u "Recommended I2P bandwidth: (run test first)"
    Pop $0
    StrCpy $RecResultLabel $0

    ${NSD_CreateLabel} 0 172u 100% 12u "Click Next to skip this test and set bandwidth manually."
    Pop $0

    nsDialogs::Show
FunctionEnd

Function OnRunSpeedTest
    Pop $0

    # Disable button to prevent double-click
    EnableWindow $SpeedTestBtn 0

    # Clean up any old files
    Delete "$TEMP\i2p_speedtest_result.txt"
    Delete "$TEMP\i2p_speedtest_status.txt"
    Delete "$TEMP\i2p_speedtest.ps1"

    # Show starting status
    ${NSD_SetText} $SpeedTestProgress "Starting test..."
    ${NSD_SetText} $DlResultLabel "Download: testing..."
    ${NSD_SetText} $UlResultLabel "Upload: waiting..."
    ${NSD_SetText} $RecResultLabel "Recommended I2P bandwidth: (testing...)"

    # Write the M-Lab ndt7 speed test script with status updates
    FileOpen $R0 "$TEMP\i2p_speedtest.ps1" w
    FileWrite $R0 "$$ErrorActionPreference = 'Stop'$\r$\n"
    FileWrite $R0 "$$rf = Join-Path $$env:TEMP 'i2p_speedtest_result.txt'$\r$\n"
    FileWrite $R0 "$$sf = Join-Path $$env:TEMP 'i2p_speedtest_status.txt'$\r$\n"
    FileWrite $R0 "try {$\r$\n"
    FileWrite $R0 "  'locating' | Out-File $$sf -NoNewline -Encoding ascii$\r$\n"
    FileWrite $R0 "  $$loc = Invoke-RestMethod -Uri 'https://locate.measurementlab.net/v2/nearest/ndt/ndt7' -UseBasicParsing$\r$\n"
    FileWrite $R0 "  $$dlUrl = $$loc.results[0].urls.'wss:///ndt/v7/download'$\r$\n"
    FileWrite $R0 "  $$ulUrl = $$loc.results[0].urls.'wss:///ndt/v7/upload'$\r$\n"
    FileWrite $R0 "  if (-not $$dlUrl) { throw 'No server found' }$\r$\n"
    FileWrite $R0 "  Add-Type -AssemblyName System.Net.Http$\r$\n"
    FileWrite $R0 "  $$ct = New-Object System.Threading.CancellationToken($$false)$\r$\n"
    # Download test
    FileWrite $R0 "  'downloading' | Out-File $$sf -NoNewline -Encoding ascii$\r$\n"
    FileWrite $R0 "  $$ws = New-Object System.Net.WebSockets.ClientWebSocket$\r$\n"
    FileWrite $R0 "  $$ws.Options.AddSubProtocol('net.measurementlab.ndt.v7')$\r$\n"
    FileWrite $R0 "  [void]$$ws.ConnectAsync([Uri]$$dlUrl, $$ct).GetAwaiter().GetResult()$\r$\n"
    FileWrite $R0 "  $$buf = New-Object byte[] 131072$\r$\n"
    FileWrite $R0 "  $$seg = New-Object System.ArraySegment[byte] -ArgumentList @(,$$buf)$\r$\n"
    FileWrite $R0 "  $$start = Get-Date; $$total = [long]0$\r$\n"
    FileWrite $R0 "  while ($$ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {$\r$\n"
    FileWrite $R0 "    try { $$task = $$ws.ReceiveAsync($$seg, $$ct)$\r$\n"
    FileWrite $R0 "      if ($$task.Wait(15000)) { $$r = $$task.Result; $$total += $$r.Count$\r$\n"
    FileWrite $R0 "        if ($$r.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) { break }$\r$\n"
    FileWrite $R0 "      } else { break } } catch { break } }$\r$\n"
    FileWrite $R0 "  $$secs = [math]::Max(((Get-Date) - $$start).TotalSeconds, 1)$\r$\n"
    FileWrite $R0 "  $$dlMbps = [math]::Round(($$total * 8) / ($$secs * 1000000), 2)$\r$\n"
    FileWrite $R0 "  try { [void]$$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, '', $$ct).Wait(3000) } catch {}$\r$\n"
    FileWrite $R0 "  $$ws.Dispose()$\r$\n"
    # Upload test
    FileWrite $R0 "  'uploading' | Out-File $$sf -NoNewline -Encoding ascii$\r$\n"
    FileWrite $R0 "  $$ws2 = New-Object System.Net.WebSockets.ClientWebSocket$\r$\n"
    FileWrite $R0 "  $$ws2.Options.AddSubProtocol('net.measurementlab.ndt.v7')$\r$\n"
    FileWrite $R0 "  [void]$$ws2.ConnectAsync([Uri]$$ulUrl, $$ct).GetAwaiter().GetResult()$\r$\n"
    FileWrite $R0 "  $$sbuf = New-Object byte[] 131072$\r$\n"
    FileWrite $R0 "  $$sseg = New-Object System.ArraySegment[byte] -ArgumentList @(,$$sbuf)$\r$\n"
    FileWrite $R0 "  $$start2 = Get-Date; $$upTotal = [long]0$\r$\n"
    FileWrite $R0 "  while ($$ws2.State -eq [System.Net.WebSockets.WebSocketState]::Open -and ((Get-Date) - $$start2).TotalSeconds -lt 10) {$\r$\n"
    FileWrite $R0 "    try { [void]$$ws2.SendAsync($$sseg, [System.Net.WebSockets.WebSocketMessageType]::Binary, $$true, $$ct).GetAwaiter().GetResult()$\r$\n"
    FileWrite $R0 "      $$upTotal += $$sbuf.Length } catch { break } }$\r$\n"
    FileWrite $R0 "  $$secs2 = [math]::Max(((Get-Date) - $$start2).TotalSeconds, 1)$\r$\n"
    FileWrite $R0 "  $$ulMbps = [math]::Round(($$upTotal * 8) / ($$secs2 * 1000000), 2)$\r$\n"
    FileWrite $R0 "  try { [void]$$ws2.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, '', $$ct).Wait(3000) } catch {}$\r$\n"
    FileWrite $R0 "  $$ws2.Dispose()$\r$\n"
    # Calculate recommendations (30% of measured, no artificial cap)
    FileWrite $R0 "  $$dlK = [math]::Floor($$dlMbps * 125)$\r$\n"
    FileWrite $R0 "  $$ulK = [math]::Floor($$ulMbps * 125)$\r$\n"
    FileWrite $R0 "  $$rIn = [math]::Floor($$dlK * 0.3)$\r$\n"
    FileWrite $R0 "  $$rOut = [math]::Floor($$ulK * 0.3)$\r$\n"
    FileWrite $R0 "  if ($$rIn -lt 64) { $$rIn = 64 }$\r$\n"
    FileWrite $R0 "  if ($$rOut -lt 32) { $$rOut = 32 }$\r$\n"
    FileWrite $R0 "  $\"$$dlK|$$ulK|$$rIn|$$rOut|$$dlMbps|$$ulMbps$\" | Out-File $$rf -NoNewline -Encoding ascii$\r$\n"
    FileWrite $R0 "} catch {$\r$\n"
    FileWrite $R0 "  '0|0|256|128|0|0' | Out-File $$rf -NoNewline -Encoding ascii$\r$\n"
    FileWrite $R0 "}$\r$\n"
    FileClose $R0

    # Launch PowerShell in background (non-blocking, hidden window)
    ExecShell "" "$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$TEMP\i2p_speedtest.ps1"' SW_HIDE

    # Start polling timer (every 1 second)
    ${NSD_CreateTimer} SpeedTestPoll 1000
FunctionEnd

Function SpeedTestPoll
    # Check if final result file exists (test complete)
    IfFileExists "$TEMP\i2p_speedtest_result.txt" 0 checkStatus

    # Test complete - kill timer
    ${NSD_KillTimer} SpeedTestPoll

    # Read results
    FileOpen $R0 "$TEMP\i2p_speedtest_result.txt" r
    FileRead $R0 $R1
    FileClose $R0

    # Parse pipe-delimited: dlKBps|ulKBps|recIn|recOut|dlMbps|ulMbps
    ${WordFind} $R1 "|" "+1" $R2  # dlKBps
    ${WordFind} $R1 "|" "+2" $R3  # ulKBps
    ${WordFind} $R1 "|" "+3" $R4  # recommended inbound
    ${WordFind} $R1 "|" "+4" $R5  # recommended outbound
    ${WordFind} $R1 "|" "+5" $R6  # dlMbps
    ${WordFind} $R1 "|" "+6" $R7  # ulMbps

    ${If} $R2 == "0"
    ${AndIf} $R3 == "0"
        ${NSD_SetText} $SpeedTestProgress "Test failed"
        ${NSD_SetText} $DlResultLabel "Download: failed"
        ${NSD_SetText} $UlResultLabel "Upload: failed"
        ${NSD_SetText} $RecResultLabel "Set bandwidth values manually on the next page."
        EnableWindow $SpeedTestBtn 1
        Goto pollCleanup
    ${EndIf}

    # Update recommended bandwidth for the next page
    StrCpy $BandwidthIn $R4
    StrCpy $BandwidthOut $R5

    # Update result labels
    ${NSD_SetText} $SpeedTestProgress "Complete!"
    ${NSD_SetText} $DlResultLabel "Download: $R6 Mbit/s ($R2 KB/s)"
    ${NSD_SetText} $UlResultLabel "Upload: $R7 Mbit/s ($R3 KB/s)"
    ${NSD_SetText} $RecResultLabel "Recommended: $R4 KB/s inbound, $R5 KB/s outbound (30%)"

    # Re-enable button
    EnableWindow $SpeedTestBtn 1
    Goto pollCleanup

checkStatus:
    # Check for status file to show progress
    IfFileExists "$TEMP\i2p_speedtest_status.txt" 0 pollDone
    FileOpen $R0 "$TEMP\i2p_speedtest_status.txt" r
    FileRead $R0 $R1
    FileClose $R0

    StrCmp $R1 "locating" 0 +3
        ${NSD_SetText} $SpeedTestProgress "Finding nearest server..."
        Goto pollDone
    StrCmp $R1 "downloading" 0 +4
        ${NSD_SetText} $SpeedTestProgress "Testing download speed..."
        ${NSD_SetText} $DlResultLabel "Download: testing..."
        Goto pollDone
    StrCmp $R1 "uploading" 0 pollDone
        ${NSD_SetText} $SpeedTestProgress "Testing upload speed..."
        ${NSD_SetText} $UlResultLabel "Upload: testing..."

pollDone:
    Return

pollCleanup:
    # Clean up temp files
    Delete "$TEMP\i2p_speedtest.ps1"
    Delete "$TEMP\i2p_speedtest_result.txt"
    Delete "$TEMP\i2p_speedtest_status.txt"
FunctionEnd

Function SpeedTestPageLeave
    # Nothing to validate, just proceed to bandwidth page
FunctionEnd

# --- Bandwidth Configuration Page ---
Function BandwidthPage
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateGroupBox} 0 0 100% 78u "Bandwidth Settings"
    Pop $0

    ${NSD_CreateLabel} 10u 16u 45% 12u "Inbound bandwidth (KB/s):"
    Pop $0
    ${NSD_CreateNumber} 58% 14u 18% 12u "$BandwidthIn"
    Pop $1
    StrCpy $BwInHandle $1

    ${NSD_CreateLabel} 10u 36u 45% 12u "Outbound bandwidth (KB/s):"
    Pop $0
    ${NSD_CreateNumber} 58% 34u 18% 12u "$BandwidthOut"
    Pop $2
    StrCpy $BwOutHandle $2

    ${NSD_CreateLabel} 10u 56u 45% 12u "Share percentage:"
    Pop $0
    ${NSD_CreateDropList} 58% 53u 18% 100u ""
    Pop $3
    ${NSD_CB_AddString} $3 "10"
    ${NSD_CB_AddString} $3 "20"
    ${NSD_CB_AddString} $3 "30"
    ${NSD_CB_AddString} $3 "40"
    ${NSD_CB_AddString} $3 "50"
    ${NSD_CB_AddString} $3 "60"
    ${NSD_CB_AddString} $3 "70"
    ${NSD_CB_AddString} $3 "80"
    ${NSD_CB_AddString} $3 "90"
    ${NSD_CB_AddString} $3 "100"
    ${NSD_CB_SelectString} $3 "$SharePercent"

    ${NSD_CreateLabel} 0 84u 100% 24u "Adjust these values based on your speed test results.$\nThese settings control how much bandwidth I2P will use."
    Pop $0

    ${NSD_CreateLabel} 0 112u 100% 40u "I2P works best when you share bandwidth generously. The share$\npercentage controls how much of your configured bandwidth is$\nmade available to the I2P network for relaying traffic."
    Pop $0

    nsDialogs::Show
FunctionEnd

Function BandwidthPageLeave
    ${NSD_GetText} $BwInHandle $BandwidthIn
    ${NSD_GetText} $BwOutHandle $BandwidthOut
    ${NSD_GetText} $3 $SharePercent

    # Validate inbound bandwidth (1-99999)
    ${If} $BandwidthIn < 1
    ${OrIf} $BandwidthIn > 99999
        MessageBox MB_OK "Inbound bandwidth must be between 1 and 99999 KB/s."
        Abort
    ${EndIf}

    # Validate outbound bandwidth (1-99999)
    ${If} $BandwidthOut < 1
    ${OrIf} $BandwidthOut > 99999
        MessageBox MB_OK "Outbound bandwidth must be between 1 and 99999 KB/s."
        Abort
    ${EndIf}

    # Share percentage comes from dropdown, no validation needed
FunctionEnd

# --- Network Settings Page ---
Function NetworkPage
    nsDialogs::Create 1018
    Pop $0
    ${If} $0 == error
        Abort
    ${EndIf}

    ${NSD_CreateCheckBox} 0 0 100% 12u "Enable UPnP (recommended for most users)"
    Pop $1
    ${If} $UPnPEnabled == "true"
        ${NSD_Check} $1
    ${EndIf}

    ${NSD_CreateCheckBox} 0 16u 100% 12u "Hidden mode (do not publish IP address)"
    Pop $2
    ${If} $HiddenMode == "true"
        ${NSD_Check} $2
    ${EndIf}

    ${NSD_CreateCheckBox} 0 32u 100% 12u "Participate as floodfill (advanced, requires good bandwidth)"
    Pop $3
    ${If} $FloodfillEnabled == "true"
        ${NSD_Check} $3
    ${EndIf}

    ${NSD_CreateLabel} 0 50u 40% 12u "I2P TCP/UDP port:"
    Pop $0
    ${NSD_CreateNumber} 42% 48u 20% 12u "$I2PPort"
    Pop $4
    ${NSD_CreateLabel} 64% 50u 34% 12u "(9000-31000)"
    Pop $0

    # Keep this near the port controls to avoid clipping on smaller wizard page heights.
    ${NSD_CreateLink} 0 64u 72% 12u "Need manual port forwarding? Open portforward.com"
    Pop $5
    ${NSD_OnClick} $5 OnPortForwardLink

    nsDialogs::Show
FunctionEnd

Function OnPortForwardLink
    Pop $0
    ExecShell "open" "https://portforward.com/"
FunctionEnd

Function NetworkPageLeave
    ${NSD_GetState} $1 $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $UPnPEnabled "true"
    ${Else}
        StrCpy $UPnPEnabled "false"
    ${EndIf}

    ${NSD_GetState} $2 $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $HiddenMode "true"
    ${Else}
        StrCpy $HiddenMode "false"
    ${EndIf}

    ${NSD_GetState} $3 $0
    ${If} $0 == ${BST_CHECKED}
        StrCpy $FloodfillEnabled "true"
    ${Else}
        StrCpy $FloodfillEnabled "false"
    ${EndIf}

    # Read user-specified port
    ${NSD_GetText} $4 $I2PPort

    # Validate port range (9000-31000)
    ${If} $I2PPort < 9000
    ${OrIf} $I2PPort > 31000
        MessageBox MB_OK "I2P port must be between 9000 and 31000."
        Abort
    ${EndIf}
FunctionEnd

# --- File Installation Functions ---

Function installBinaries
    # Install binaries to Program Files ($INSTDIR)
    createDirectory $INSTDIR
    SetOutPath $INSTDIR\app
    File /a /r "I2P\app\"
    SetOutPath $INSTDIR\runtime
    File /a /r "I2P\runtime\"
    # Install read-only config (certificates, geoip, defaults) for i2p.dir.base
    SetOutPath $INSTDIR\config
    File /a /r "I2P\config\"
    # Install eepsite at install root (clients.config resolves "eepsite/jetty.xml" relative to user.dir)
    SetOutPath $INSTDIR\eepsite
    File /a /r "I2P\config\eepsite\"
    # FastCGI context requires jetty-fcgi jars not included in this bundle.
    Delete "$INSTDIR\eepsite\contexts\cgi-context.xml"
    SetOutPath $INSTDIR
    File /a /r "I2P\I2P.exe"
    File i2p.ico
FunctionEnd

Function installConfig
    # Install config/data to AppData ($DATADIR)
    # Files must be at the ROOT of $DATADIR, not in a config/ subdirectory,
    # because the router resolves i2p.dir.config to $DATADIR directly.
    createDirectory "$DATADIR"
    SetOutPath "$DATADIR"
    File "I2P\config\clients.config"
    File "I2P\config\i2ptunnel.config"
    File "I2P\config\hosts.txt"
    File /a /r "I2P\config\certificates\"
    File /a /r "I2P\config\geoip\"
    createDirectory "$DATADIR\plugins"

    # Install i2pfirefox plugin (Firefox profile manager for I2P)
    # Must be in $DATADIR/plugins/ where the router looks for plugins
    createDirectory "$DATADIR\plugins\i2pfirefox"
    SetOutPath "$DATADIR\plugins\i2pfirefox"
    File /a /r "I2P\config\plugins\i2pfirefox\"
    # Pre-seed the Firefox profile so it is not empty in Firefox profile manager
    # even before plugin startup has a chance to rebuild it.
    createDirectory "$DATADIR\plugins\i2pfirefox\profile"
    IfFileExists "$DATADIR\plugins\i2pfirefox\profile\prefs.js" +3 0
        SetOutPath "$DATADIR\plugins\i2pfirefox\profile"
        File /a /r "..\i2p.firefox.base.profile\*"
    FileOpen $0 "$DATADIR\plugins.config" a
    FileWrite $0 "i2pfirefox.startOnLoad=true$\r$\n"
    FileClose $0

    # Preserve existing eepsite if present
    SetOutPath "$DATADIR"
    IfFileExists "$DATADIR\eepsite\docroot" +2 0
        File /a /r "I2P\config\eepsite\"
    # Remove stale optional FastCGI context on upgrades too.
    Delete "$DATADIR\eepsite\contexts\cgi-context.xml"
FunctionEnd

Function writeRouterConfig
    # Write router.config with user-selected settings
    FileOpen $0 "$DATADIR\router.config" w
    FileWrite $0 "router.updateURL=http://ekm3fu6fr5pxudhwjmdiea5dovc3jdi66hjgop4c7z7dfaw7spca.b32.i2p/i2pwinupdate.su3$\r$\n"
    FileWrite $0 "router.newsURL=http://dn3tvalnjz432qkqsvpfdqrwpqkw3ye4n4i2uyfr4jexvo3sp5ka.b32.i2p/news/win/beta/news.su3$\r$\n"
    FileWrite $0 "router.backupNewsURL=http://tc73n4kivdroccekirco7rhgxdg5f3cjvbaapabupeyzrqwv5guq.b32.i2p/win/beta/news.su3$\r$\n"
    FileWrite $0 "routerconsole.browser=NUL$\r$\n"
    FileWrite $0 "router.disableTunnelTesting=false$\r$\n"
    FileWrite $0 "i2np.bandwidth.inboundKBytesPerSecond=$BandwidthIn$\r$\n"
    FileWrite $0 "i2np.bandwidth.outboundKBytesPerSecond=$BandwidthOut$\r$\n"
    FileWrite $0 "router.sharePercentage=$SharePercent$\r$\n"
    FileWrite $0 "i2np.upnp.enable=$UPnPEnabled$\r$\n"
    FileWrite $0 "router.isHidden=$HiddenMode$\r$\n"
    FileWrite $0 "i2np.ntcp.port=$I2PPort$\r$\n"
    FileWrite $0 "i2np.udp.port=$I2PPort$\r$\n"
    ${If} $FloodfillEnabled == "true"
        FileWrite $0 "router.floodfillParticipant=true$\r$\n"
    ${EndIf}
    FileClose $0
FunctionEnd

Function registerFirefoxProfile
    # Register the I2P Firefox profile in Firefox's profiles.ini so it appears in profile manager.
    Delete "$TEMP\i2p_register_ff_profile.ps1"
    FileOpen $R0 "$TEMP\i2p_register_ff_profile.ps1" w
    FileWrite $R0 "$$ErrorActionPreference = 'Stop'$\r$\n"
    FileWrite $R0 "$$log = Join-Path $$env:TEMP 'i2p_register_ff_profile.log'$\r$\n"
    FileWrite $R0 "$$profPath = '$DATADIR\plugins\i2pfirefox\profile'$\r$\n"
    FileWrite $R0 "New-Item -ItemType Directory -Force -Path $$profPath | Out-Null$\r$\n"
    FileWrite $R0 "try {$\r$\n"
    FileWrite $R0 "  $$roots = @()$\r$\n"
    FileWrite $R0 "  if ($$env:APPDATA) { $$roots += (Join-Path $$env:APPDATA 'Mozilla\Firefox') }$\r$\n"
    FileWrite $R0 "  if ($$env:LOCALAPPDATA) { $$roots += (Join-Path $$env:LOCALAPPDATA 'Mozilla\Firefox') }$\r$\n"
    FileWrite $R0 "  $$roots = $$roots | Select-Object -Unique$\r$\n"
    FileWrite $R0 "  foreach ($$ffDir in $$roots) {$\r$\n"
    FileWrite $R0 "    New-Item -ItemType Directory -Force -Path $$ffDir | Out-Null$\r$\n"
    FileWrite $R0 "    $$ini = Join-Path $$ffDir 'profiles.ini'$\r$\n"
    FileWrite $R0 "    if (-not (Test-Path $$ini)) {$\r$\n"
    FileWrite $R0 "      @('[General]','StartWithLastProfile=1','Version=2','') | Set-Content -Encoding Ascii $$ini$\r$\n"
    FileWrite $R0 "    }$\r$\n"
    FileWrite $R0 "    $$lines = Get-Content $$ini$\r$\n"
    FileWrite $R0 "    $$lines = $$lines | Where-Object { $$_.IndexOf('`r`n[Profile') -lt 0 }$\r$\n"
    FileWrite $R0 "    $$lines | Set-Content -Encoding Ascii $$ini$\r$\n"
    FileWrite $R0 "    $$content = Get-Content $$ini -Raw$\r$\n"
    FileWrite $R0 "    if ($$content -notmatch ('(?m)^Path=' + [regex]::Escape($$profPath) + '$$')) {$\r$\n"
    FileWrite $R0 "      $$matches = [regex]::Matches($$content, '(?m)^\[Profile(\d+)\]$$')$\r$\n"
    FileWrite $R0 "      $$next = 0$\r$\n"
    FileWrite $R0 "      foreach ($$m in $$matches) {$\r$\n"
    FileWrite $R0 "        $$n = [int]$$m.Groups[1].Value$\r$\n"
    FileWrite $R0 "        if ($$n -ge $$next) { $$next = $$n + 1 }$\r$\n"
    FileWrite $R0 "      }$\r$\n"
    FileWrite $R0 "      Add-Content -Encoding Ascii $$ini ''$\r$\n"
    FileWrite $R0 "      Add-Content -Encoding Ascii $$ini ('[Profile' + $$next + ']')$\r$\n"
    FileWrite $R0 "      Add-Content -Encoding Ascii $$ini 'Name=I2P'$\r$\n"
    FileWrite $R0 "      Add-Content -Encoding Ascii $$ini 'IsRelative=0'$\r$\n"
    FileWrite $R0 "      Add-Content -Encoding Ascii $$ini ('Path=' + $$profPath)$\r$\n"
    FileWrite $R0 "      Add-Content -Encoding Ascii $$ini 'Default=0'$\r$\n"
    FileWrite $R0 "    }$\r$\n"
    FileWrite $R0 "  }$\r$\n"
    FileWrite $R0 "  $$roots | Out-File -Encoding Ascii $$log$\r$\n"
    FileWrite $R0 "  Add-Content -Encoding Ascii $$log ('profile=' + $$profPath)$\r$\n"
    FileWrite $R0 "  foreach ($$ffDir in $$roots) { Add-Content -Encoding Ascii $$log ('ini=' + (Join-Path $$ffDir 'profiles.ini')) }$\r$\n"
    FileWrite $R0 "  Add-Content -Encoding Ascii $$log 'ok'$\r$\n"
    FileWrite $R0 "} catch {$\r$\n"
    FileWrite $R0 "  $$_.ToString() | Out-File -Encoding Ascii $$log$\r$\n"
    FileWrite $R0 "  exit 1$\r$\n"
    FileWrite $R0 "  }$\r$\n"
    FileClose $R0
    nsExec::ExecToLog '"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "$TEMP\i2p_register_ff_profile.ps1"'
    Delete "$TEMP\i2p_register_ff_profile.ps1"
FunctionEnd

Function installerFunction
    # Always force-stop running I2P before install/upgrade.
    Call ForceKillI2PProcess

    ${If} ${Silent}
        ${Do}
            ${FindProcess} "I2P.exe" $0
            Sleep 500
        ${LoopWhile} $0 <> 0
    ${EndIf}

    # Install binaries to Program Files
    Call installBinaries

    # Install config/data to AppData
    Call installConfig

    # Register the profile with Firefox profile manager
    Call registerFirefoxProfile

    # Write router.config with user preferences
    Call writeRouterConfig

    # Install Firefox if user opted in
    ${If} $InstallFirefox == "1"
        DetailPrint "Downloading Firefox installer..."
        NSISdl::download "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US" "$TEMP\FirefoxSetup.exe"
        Pop $0
        ${If} $0 == "success"
            DetailPrint "Installing Firefox silently..."
            ExecWait '"$TEMP\FirefoxSetup.exe" /S' $0
            DetailPrint "Firefox installation finished (exit code: $0)"
            Delete "$TEMP\FirefoxSetup.exe"
        ${Else}
            DetailPrint "Firefox download failed: $0"
            MessageBox MB_OK "Firefox download failed. You can install Firefox manually from https://www.mozilla.org/firefox/"
        ${EndIf}
    ${EndIf}

    # Install licenses
    createDirectory "$INSTDIR\licenses"
    SetOutPath "$INSTDIR\licenses"
    File /a /r "licenses\"

    # Create Start Menu shortcuts
    SetOutPath "$INSTDIR"
    createDirectory "$SMPROGRAMS\${APPNAME}"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\I2P.lnk" "$INSTDIR\I2P.exe" "" "$INSTDIR\i2p.ico"
    Delete "$SMPROGRAMS\${APPNAME}\Browse I2P.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Browse I2P - Temporary Identity.lnk"

    # Create desktop shortcut
    CreateShortCut "$DESKTOP\I2P.lnk" "$INSTDIR\I2P.exe" "" "$INSTDIR\i2p.ico"
    Delete "$DESKTOP\Browse I2P.lnk"
    Delete "$DESKTOP\Browse I2P - Temporary Identity.lnk"
    # Clean up shortcuts from standard IzPack I2P installer or router console
    Delete "$DESKTOP\Start I2P.lnk"
    Delete "$DESKTOP\Start I2P restartable.lnk"
    Delete "$DESKTOP\Browse Router Console.lnk"

    # Create the uninstaller
    WriteUninstaller "$INSTDIR\uninstall-i2pbrowser.exe"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\Uninstall I2P.lnk" "$INSTDIR\uninstall-i2pbrowser.exe" "" "$INSTDIR\i2p.ico"

    # Add/Remove Programs registry entries
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${COMPANYNAME} ${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" '"$INSTDIR\uninstall-i2pbrowser.exe"'
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$INSTDIR\i2p.ico"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1

FunctionEnd


# start default section
Section Install
    Call installerFunction
SectionEnd

# uninstaller section start
Section "uninstall"
    # Force-stop running router before uninstall.
    Call un.ForceKillI2PProcess
    ${un.FindProcess} "I2P.exe" $0
    ${If} $0 <> 0
        MessageBox MB_OK "I2P.exe is still running and could not be terminated automatically. Please close it and run uninstall again."
        Abort
    ${EndIf}

    # Stop and remove the I2P Windows service if it exists
    nsExec::ExecToLog 'sc stop i2p'
    nsExec::ExecToLog 'sc delete i2p'

    # Remove binaries from Program Files
    rmDir /r "$INSTDIR\app"
    rmDir /r "$INSTDIR\runtime"
    rmDir /r "$INSTDIR\config"
    rmDir /r "$INSTDIR\eepsite"
    rmDir /r "$INSTDIR\licenses"
    Delete "$INSTDIR\i2p.ico"
    Delete "$INSTDIR\windowsUItoopie2.png"
    Delete "$INSTDIR\I2P.exe"

    # Remove config/data from AppData
    # Ask user if they want to keep their configuration
    MessageBox MB_YESNO "Do you want to remove your I2P configuration and data?$\n$\nClick 'Yes' to remove everything.$\nClick 'No' to keep your configuration for future installations." IDYES removeData IDNO skipRemoveData
removeData:
    Delete "$LOCALAPPDATA\I2P\clients.config"
    Delete "$LOCALAPPDATA\I2P\i2ptunnel.config"
    Delete "$LOCALAPPDATA\I2P\hosts.txt"
    Delete "$LOCALAPPDATA\I2P\router.config"
    Delete "$LOCALAPPDATA\I2P\jpackaged"
    rmDir /r "$LOCALAPPDATA\I2P\certificates"
    rmDir /r "$LOCALAPPDATA\I2P\geoip"
    rmDir /r "$LOCALAPPDATA\I2P\eepsite"
    rmDir /r "$LOCALAPPDATA\I2P\plugins"
    rmDir /r "$LOCALAPPDATA\I2P\clients.config.d"
    rmDir /r "$LOCALAPPDATA\I2P\logs"
    rmDir /r "$LOCALAPPDATA\I2P"
skipRemoveData:

    # Remove shortcuts
    Delete "$SMPROGRAMS\${APPNAME}\I2P.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Browse I2P.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Uninstall I2P.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Uninstall I2P Easy-Install Bundle.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Browse I2P - Temporary Identity.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\Private Browsing-${APPNAME}.lnk"
    rmDir /r "$SMPROGRAMS\${APPNAME}"
    Delete "$DESKTOP\I2P.lnk"
    Delete "$DESKTOP\Browse I2P.lnk"
    Delete "$DESKTOP\Browse I2P - Temporary Identity.lnk"
    Delete "$DESKTOP\Start I2P.lnk"
    Delete "$DESKTOP\Start I2P restartable.lnk"
    Delete "$DESKTOP\Browse Router Console.lnk"

    # Remove Add/Remove Programs registry entry
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"

    # Clean up install directory
    Delete "$INSTDIR\uninstall-i2pbrowser.exe"
    rmDir "$INSTDIR"
    # uninstaller section end
SectionEnd

Function LaunchLink
  SetOutPath "$INSTDIR"
  StrCpy $OUTDIR $INSTDIR
  ${If} ${Silent}
    ReadEnvStr $0 RESTART_I2P
    ${If} $0 != ""
           ExecShell "" "$DESKTOP\I2P.lnk"
    ${EndIf}
  ${Else}
        ExecShell "" "$DESKTOP\I2P.lnk"
  ${EndIf}
FunctionEnd
