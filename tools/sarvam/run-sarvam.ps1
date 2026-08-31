# Sarvam batch speech-to-text / speech-to-translation for meeting audio.
#
# Runs one whole audio file through the Sarvam batch job API and writes the raw
# result JSON. Run it twice over the same audio - once with -Mode transcribe and
# once with -Mode translate - and cross-read the two passes; each catches the
# other's errors.
#
# This machine has no ffmpeg and no real Python, so chunking is not possible.
# The batch API takes whole files up to about two hours.
#
#   .\run-sarvam.ps1 -Mode transcribe -AudioPath 'C:\path\meeting.m4a' -OutDir '.\out'
#   .\run-sarvam.ps1 -Mode translate  -AudioPath 'C:\path\meeting.m4a' -OutDir '.\out'
#
# The audio is uploaded under its own file name, so use a name without spaces.
# Never commit the API key, the presigned blob URLs, or the audio itself.

param(
  [Parameter(Mandatory=$true)][ValidateSet('transcribe','translate')][string]$Mode,
  [Parameter(Mandatory=$true)][string]$AudioPath,
  [Parameter(Mandatory=$true)][string]$OutDir,
  [string]$KeyFile = 'C:\Users\sidmy\OneDrive\Documents\sarvam.apikey.txt',
  [string]$Model = 'saaras:v3',
  [string]$LanguageCode = 'unknown'
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$key = (Get-Content $KeyFile -Raw).Trim()
$hdr = @{ 'api-subscription-key' = $key }
$base = 'https://api.sarvam.ai/speech-to-text/job/v1'
$fileName = Split-Path $AudioPath -Leaf
if ($fileName -match '\s') { throw "audio file name must not contain spaces: $fileName" }

$out = Join-Path $OutDir $Mode
New-Item -ItemType Directory -Force $out | Out-Null

function Redact([string]$s) { [regex]::Replace($s, 'https://[^"\s]+', 'https://REDACTED') }

# 1. create the job
$body = @{ job_parameters = @{
    language_code    = $LanguageCode
    model            = $Model
    mode             = $Mode
    with_timestamps  = $true
    with_diarization = $true
} } | ConvertTo-Json -Depth 5
$job = Invoke-RestMethod -Method Post -Uri $base -Headers $hdr -ContentType 'application/json' -Body $body
$jobId = $job.job_id
Write-Output "[$Mode] job_id=$jobId"

# 2. ask for a presigned upload URL
$upBody = @{ job_id = $jobId; files = @($fileName) } | ConvertTo-Json
$up = Invoke-RestMethod -Method Post -Uri "$base/upload-files" -Headers $hdr -ContentType 'application/json' -Body $upBody
$putUrl = $up.upload_urls.$fileName.file_url
if (-not $putUrl) { throw "no upload url: $(Redact ($up | ConvertTo-Json -Depth 8))" }

# 3. PUT the blob. Both content-type headers matter: without them curl stamps the
#    blob application/x-www-form-urlencoded and the job start fails on "Invalid file type",
#    even though the PUT itself still returns 201.
$code = & curl.exe -s -o "$out\put_resp.txt" -w '%{http_code}' -X PUT $putUrl `
  -H 'x-ms-blob-type: BlockBlob' -H 'Content-Type: audio/x-m4a' -H 'x-ms-blob-content-type: audio/x-m4a' `
  --data-binary "@$AudioPath"
Write-Output "[$Mode] upload http=$code"
if ("$code" -ne '201') { throw "upload failed http=$code" }

# 4. start
$st = Invoke-RestMethod -Method Post -Uri "$base/$jobId/start" -Headers $hdr -ContentType 'application/json' -Body '{}'
Write-Output "[$Mode] start state=$($st.job_state)"

# 5. poll. A 35 minute file completes in roughly five minutes.
$terminal = @('Completed','PartiallyCompleted','Failed')
$deadline = (Get-Date).AddMinutes(40)
$s = $null
do {
  Start-Sleep -Seconds 15
  $s = Invoke-RestMethod -Method Get -Uri "$base/$jobId/status" -Headers $hdr
  Write-Output "[$Mode] $(Get-Date -Format HH:mm:ss) state=$($s.job_state)"
} while (($terminal -notcontains $s.job_state) -and ((Get-Date) -lt $deadline))
$s | ConvertTo-Json -Depth 12 | Out-File -Encoding utf8 "$out\status.json"
if ($s.job_state -eq 'Failed') { throw "[$Mode] job Failed - see $out\status.json" }
if ($terminal -notcontains $s.job_state) { throw "[$Mode] timed out in state $($s.job_state)" }

# 6. download the result
$dlBody = @{ job_id = $jobId; files = @('0.json') } | ConvertTo-Json
$dl = Invoke-RestMethod -Method Post -Uri "$base/download-files" -Headers $hdr -ContentType 'application/json' -Body $dlBody
$dlJson = $dl | ConvertTo-Json -Depth 10
$getUrl = $null
try { $getUrl = $dl.download_urls.'0.json'.file_url } catch {}
if (-not $getUrl) {
  $m = [regex]::Match($dlJson, '"file_url"\s*:\s*"([^"]+)"')
  if ($m.Success) { $getUrl = $m.Groups[1].Value }
}
if (-not $getUrl) { throw "no download url: $(Redact $dlJson)" }
& curl.exe -s -o "$out\raw.json" $getUrl
Write-Output "[$Mode] raw.json bytes=$((Get-Item "$out\raw.json").Length)"
Write-Output "[$Mode] DONE"
