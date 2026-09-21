# Read-only ABAP source capture via SE38 Display + clipboard, QS4/700 only.
# Adapted from sessions/2026-09-02-std-api-extension-feasibility/scripts/grab.ps1;
# the only change is that it calls the QS4/700-guarded grab script beside it.
# Usage: powershell -File grab.ps1 -OutDir <dir> NAME1 NAME2 ...
param(
  [Parameter(Mandatory=$true)][string]$OutDir,
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Names
)

$grab = Join-Path $PSScriptRoot "qs4_grab_se38_source.vbs"
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

foreach ($n in $Names) {
  # namespaced names (/SPE/...) cannot be file names; '/' becomes '#'
  $target = Join-Path $OutDir (($n -replace '/', '#') + ".txt")
  if (Test-Path $target) { Write-Output "SKIP  $n"; continue }
  Set-Clipboard -Value "SENTINEL_EMPTY"
  $res = & C:\Windows\System32\cscript.exe //nologo $grab $n 2>&1
  if (-not (($res -join "`n") -match "OK prog=")) {
    Write-Output ("MISS  {0}  {1}" -f $n, ($res -join " | "))
    continue
  }
  $txt = Get-Clipboard -Raw
  if (-not $txt -or $txt -eq "SENTINEL_EMPTY") { Write-Output "EMPTY $n"; continue }
  $txt | Out-File -FilePath $target -Encoding utf8
  $first = ($txt -split "`r?`n" | Where-Object { $_ -match '^\s*(METHOD|FORM|CLASS|REPORT|FUNCTION|ENHANCEMENT)\s' } | Select-Object -First 1)
  Write-Output ("OK    {0}  chars={1}  {2}" -f $n, $txt.Length, $first)
}
