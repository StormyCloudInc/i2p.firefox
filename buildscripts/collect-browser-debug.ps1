param(
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
  $OutDir = Join-Path $PWD "build\browser-debug-$stamp"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$sources = @(
  "$env:LOCALAPPDATA\I2P\i2pbrowser-launch.log",
  "$env:LOCALAPPDATA\I2P\i2pbrowser-cmd.log",
  "$env:LOCALAPPDATA\I2P\logs\log-0.txt",
  "$env:LOCALAPPDATA\I2P\plugins\i2pfirefox\clients.config",
  "$env:LOCALAPPDATA\I2P\plugins\i2pfirefox\browser.config"
)

foreach ($src in $sources) {
  if (Test-Path $src) {
    Copy-Item -Force $src (Join-Path $OutDir (Split-Path $src -Leaf))
  }
}

$meta = @()
$meta += "timestamp=$(Get-Date -Format o)"
$meta += "machine=$env:COMPUTERNAME"
$meta += "user=$env:USERNAME"
$meta += "localappdata=$env:LOCALAPPDATA"
$meta += "i2p_browser_debug=$env:I2P_BROWSER_DEBUG"
$meta += "pwd=$PWD"
$meta += ""
$meta += "firefox_processes:"
$procs = Get-CimInstance Win32_Process -Filter "name='firefox.exe' or name='java.exe'" |
  Select-Object ProcessId,ParentProcessId,Name,CommandLine
foreach ($p in $procs) {
  $meta += ("pid={0} ppid={1} name={2} cmd={3}" -f $p.ProcessId, $p.ParentProcessId, $p.Name, $p.CommandLine)
}

$meta | Set-Content -Path (Join-Path $OutDir "metadata.txt") -Encoding UTF8
Write-Output "debug_bundle=$OutDir"
