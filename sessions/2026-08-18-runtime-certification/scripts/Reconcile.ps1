$ErrorActionPreference='Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$seg  = Join-Path $root '2026-08-16-sto-flow-trace\evidence\21_SEGW_PROPERTY_INDEX.tsv'
$run  = Join-Path (Split-Path $PSScriptRoot -Parent) 'analysis\RUNTIME_PROPERTY_INDEX.tsv'
$out  = Join-Path (Split-Path $PSScriptRoot -Parent) 'analysis'

$map = @{
 'API_OUTBOUND_DELIVERY_0002' = 'API_OUTBOUND_DELIVERY_V2'
 'API_BILLING_DOCUMENT'       = 'API_BILLING_DOCUMENT'
 'API_PURCHASEORDER_PROCESS'  = 'API_PURCHASEORDER_PROCESS'
 'API_MATERIAL_DOCUMENT'      = 'API_MATERIAL_DOCUMENT'
 'API_MATERIAL_STOCK'         = 'API_MATERIAL_STOCK'
 'MMIM_MATDOC'                = 'MMIM_MATDOC'
 'SD_CUSTOMER_INVOICES_CREATE'= 'SD_CUSTOMER_INVOICES_CREATE'
}

$segRows = Import-Csv $seg -Delimiter "`t"
$runRows = Import-Csv $run -Delimiter "`t"
$rep=@()
foreach ($k in $map.Keys) {
  $s = $segRows | Where-Object { $_.Project -eq $k } | ForEach-Object { $_.Property } | Sort-Object -Unique
  $r = $runRows | Where-Object { $_.Service -eq $map[$k] } | ForEach-Object { $_.Property } | Sort-Object -Unique
  if ($s.Count -eq 0 -and $r.Count -eq 0) { continue }
  $onlySeg = @($s | Where-Object { $r -notcontains $_ })
  $onlyRun = @($r | Where-Object { $s -notcontains $_ })
  $both    = @($s | Where-Object { $r -contains $_ })
  $rep += [pscustomobject]@{
    SegwProject=$k; RuntimeService=$map[$k]
    SegwProps=$s.Count; RuntimeProps=$r.Count
    Confirmed=$both.Count; OnlyInSegwExtract=$onlySeg.Count; OnlyInRuntime=$onlyRun.Count
  }
  if ($onlySeg.Count) { $onlySeg | Set-Content (Join-Path $out "DELTA_${k}_only_in_segw_extract.txt") }
  if ($onlyRun.Count) { $onlyRun | Set-Content (Join-Path $out "DELTA_${k}_only_in_runtime.txt") }
}
$rep | Sort-Object SegwProject | Format-Table -AutoSize
$rep | Export-Csv (Join-Path $out 'RECONCILIATION_SEGW_vs_RUNTIME.tsv') -Delimiter "`t" -NoTypeInformation
