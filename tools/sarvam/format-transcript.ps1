param([string]$RawJson,[string]$OutTxt)
$ErrorActionPreference='Stop'
$j = Get-Content $RawJson -Raw -Encoding UTF8 | ConvertFrom-Json
$e = $j.diarized_transcript.entries | Sort-Object start_time_seconds
$max = ($e | Measure-Object -Property start_time_seconds -Maximum).Maximum
$sb = New-Object System.Text.StringBuilder
foreach ($x in $e) {
  $t = [int][math]::Floor($x.start_time_seconds)
  if ($max -ge 3600) { $ts = '{0:d2}:{1:d2}:{2:d2}' -f [int][math]::Floor($t/3600), [int][math]::Floor(($t%3600)/60), ($t%60) }
  else { $ts = '{0:d2}:{1:d2}' -f [int][math]::Floor($t/60), ($t%60) }
  $txt = ($x.transcript -replace '\s+',' ').Trim()
  if ($txt.Length -eq 0) { continue }
  [void]$sb.AppendLine("[$ts] S$($x.speaker_id): $txt")
}
[System.IO.File]::WriteAllText($OutTxt, $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
$speakers = ($e | Select-Object -ExpandProperty speaker_id -Unique | Sort-Object) -join ','
Write-Output "$OutTxt : $($e.Count) entries, speakers [$speakers], duration $([int]$max)s, lang $($j.language_code) ($($j.language_probability))"
