param(
  [Parameter(Mandatory=$true)][string]$Uri,
  [Parameter(Mandatory=$true)][string]$BaseName,
  [string]$EvidenceDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'evidence'),
  [ValidateSet('xml','json','txt')][string]$Ext = 'xml'
)
$ErrorActionPreference = 'Stop'
$vbs = Join-Path $PSScriptRoot 'gw_get.vbs'

$head = & cscript.exe //nologo $vbs GET $Uri $EvidenceDir $BaseName 2>&1
$headText = ($head | Out-String).Trim()
Write-Host $headText

if ($headText -notmatch 'OK\|STATUS=') {
    [pscustomobject]@{ Base=$BaseName; Status='HARNESS-FAIL'; Bytes=0; Sha=''; Note=$headText }
    return
}
$status = ([regex]::Match($headText,'STATUS=([^|]*)')).Groups[1].Value.Trim()
$ctype  = ([regex]::Match($headText,'CTYPE=([^|]*)')).Groups[1].Value.Trim()
if ($ctype -match 'json') { $Ext = 'json' } elseif ($ctype -match 'xml') { $Ext = 'xml' }

$out = Join-Path $EvidenceDir "$($BaseName)_response.$Ext"
$res = & (Join-Path $PSScriptRoot 'Copy-EditorBody.ps1') -OutPath $out
Write-Host $res
$len = (Get-Item -LiteralPath $out).Length
$sha = (Get-FileHash -LiteralPath $out -Algorithm SHA256).Hash
[pscustomobject]@{ Base=$BaseName; Status=$status; Bytes=$len; Sha=$sha; Note=$ctype }
