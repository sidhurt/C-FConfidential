# Read-only ABAP source capture via SE38 Display + clipboard.
# Usage: powershell -File grab.ps1 -OutDir <dir> NAME1 NAME2 ...
# Never enters change mode. Skips names already captured.
param(
  [string]$OutDir = "C:\Users\sidmy\Downloads\shree-cement-cnf-agent-cowork-20260729T062834Z-1-001\shree-cement-cnf-agent-cowork\sessions\2026-09-02-std-api-extension-feasibility\src",
  [Parameter(ValueFromRemainingArguments=$true)][string[]]$Names
)

$root = "C:\Users\sidmy\Downloads\shree-cement-cnf-agent-cowork-20260729T062834Z-1-001\shree-cement-cnf-agent-cowork"
$grab = "$root\outputs\sap-gui-script\grab-se38-source.vbs"
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

foreach ($n in $Names) {
  $target = Join-Path $OutDir "$n.txt"
  if (Test-Path $target) { Write-Output "SKIP  $n"; continue }
  Set-Clipboard -Value "SENTINEL_EMPTY"
  $res = & cscript //nologo $grab $n 2>&1
  if (-not (($res -join "`n") -match "OK prog=")) {
    Write-Output "MISS  $n"
    continue
  }
  $txt = Get-Clipboard -Raw
  if (-not $txt -or $txt -eq "SENTINEL_EMPTY") { Write-Output "EMPTY $n"; continue }
  $txt | Out-File -FilePath $target -Encoding utf8
  # first METHOD/FORM line makes the include self-identifying
  $first = ($txt -split "`r?`n" | Where-Object { $_ -match '^\s*(METHOD|FORM|CLASS|REPORT|FUNCTION)\s' } | Select-Object -First 1)
  Write-Output ("OK    {0}  chars={1}  {2}" -f $n, $txt.Length, $first)
}
