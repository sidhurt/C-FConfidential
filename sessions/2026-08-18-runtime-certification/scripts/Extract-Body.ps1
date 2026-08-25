param([Parameter(Mandatory=$true)][string]$RawPath,
      [Parameter(Mandatory=$true)][string]$OutPath)

if (-not (Test-Path $RawPath)) { throw "raw export missing: $RawPath" }
$raw = Get-Content -LiteralPath $RawPath -Raw -Encoding UTF8

$m = [regex]::Match($raw, '<HTTP_BODY>(?<b>.*)</HTTP_BODY>', 'Singleline')
if (-not $m.Success) { throw "no HTTP_BODY element in $RawPath" }
$b = $m.Groups['b'].Value

# The exporter XML-escapes the payload; unescape it back to the wire body.
$b = $b -replace '&lt;','<' -replace '&gt;','>' -replace '&quot;','"' -replace '&apos;',"'" -replace '&#39;',"'" -replace '&amp;','&'

# Never let a captured session artefact reach the evidence tree.
$b = [regex]::Replace($b,'(?i)(SAP_SESSIONID_[A-Z0-9_]+=)[^;"<\s]+','$1[REDACTED]')
$b = [regex]::Replace($b,'(?i)(x-csrf-token"?\s*[:=]\s*"?)[^",<\s]+','$1[REDACTED]')

Set-Content -LiteralPath $OutPath -Value $b -Encoding UTF8 -NoNewline
$len = (Get-Item -LiteralPath $OutPath).Length
$sha = (Get-FileHash -LiteralPath $OutPath -Algorithm SHA256).Hash
"{0}`t{1}`t{2}" -f (Split-Path $OutPath -Leaf), $len, $sha
