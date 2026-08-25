$ErrorActionPreference='Stop'
$base = Split-Path $PSScriptRoot -Parent
$ev   = Join-Path $base 'evidence'
$an   = Join-Path $base 'analysis'
$ts   = '2026-08-18'
$rows = @()

function Add-Row($id,$svc,$op,$res,$doc,$file) {
    $p = Join-Path $ev $file
    if (-not (Test-Path $p)) { $p = Join-Path $an $file }
    if (-not (Test-Path $p)) { return }
    $script:rows += [pscustomobject]@{
        TestID=$id; System='DS4'; Client='200'; User='QNOVATE8'; Timestamp=$ts
        ServiceOrBAPI=$svc; Operation=$op; Result=$res; DocumentCreatedChanged=$doc
        EvidenceFile=$file; Bytes=(Get-Item $p).Length
        SHA256=(Get-FileHash $p -Algorithm SHA256).Hash
    }
}

$meta = @(
 @('RT-A01-META','API_MATERIAL_DOCUMENT_SRV','GET $metadata','HTTP 200','none','META_API_MATERIAL_DOCUMENT_response.xml'),
 @('RT-A02-META','API_OUTBOUND_DELIVERY_SRV;v=2','GET $metadata','HTTP 200','none','META_API_OUTBOUND_DELIVERY_V2_response.xml'),
 @('RT-A10-META','API_BILLING_DOCUMENT_SRV','GET $metadata','HTTP 200','none','META_API_BILLING_DOCUMENT_response.xml'),
 @('RT-A08-META','API_PURCHASEORDER_PROCESS_SRV','GET $metadata','HTTP 200','none','META_API_PURCHASEORDER_PROCESS_response.xml'),
 @('RT-A05-META','API_MATERIAL_STOCK_SRV','GET $metadata','HTTP 200','none','META_API_MATERIAL_STOCK_response.xml'),
 @('RT-MM-META','MMIM_MATDOC_SRV','GET $metadata','HTTP 200','none','META_MMIM_MATDOC_response.xml'),
 @('RT-SD-META','SD_CUSTOMER_INVOICES_CREATE','GET $metadata','HTTP 200','none','META_SD_CUSTOMER_INVOICES_CREATE_response.xml')
)
foreach ($m in $meta) { Add-Row $m[0] $m[1] $m[2] $m[3] $m[4] $m[5] }

$reads = @(
 @('RT-A08-R01','API_PURCHASEORDER_PROCESS_SRV',"GET A_PurchaseOrder filter PurchaseOrderType eq 'ZP06' top 5",'HTTP 200 / 0 rows','none','A08_STO_PO_ZP06_probe_response.json'),
 @('RT-A08-R02','API_PURCHASEORDER_PROCESS_SRV','GET A_PurchaseOrder unfiltered top 15','HTTP 200 / 0 rows','none','A08_PO_any_probe_response.json'),
 @('RT-A09-R01','API_OUTBOUND_DELIVERY_SRV;v=2','GET A_OutbDeliveryHeader unfiltered top 10','HTTP 200 / 0 rows','none','A09_DELIV_any_probe_response.json'),
 @('RT-A05-R01','API_MATERIAL_STOCK_SRV','GET A_MatlStkInAcctMod unfiltered top 10','HTTP 200 / 0 rows','none','A05_STOCK_any_probe_response.json')
)
foreach ($m in $reads) { Add-Row $m[0] $m[1] $m[2] $m[3] $m[4] $m[5] }

$an_files = @(
 @('RT-AN-01','(analysis)','parsed runtime property index','1854 properties','none','RUNTIME_PROPERTY_INDEX.tsv'),
 @('RT-AN-02','(analysis)','parsed runtime entity sets','110 entity sets','none','RUNTIME_ENTITYSETS.tsv'),
 @('RT-AN-03','(analysis)','parsed runtime function imports','23 function imports','none','RUNTIME_FUNCTIONIMPORTS.tsv'),
 @('RT-AN-04','(analysis)','SEGW-extract vs runtime reconciliation','see file','none','RECONCILIATION_SEGW_vs_RUNTIME.tsv')
)
foreach ($m in $an_files) { Add-Row $m[0] $m[1] $m[2] $m[3] $m[4] $m[5] }

$rows | Export-Csv (Join-Path $base 'MANIFEST.tsv') -Delimiter "`t" -NoTypeInformation -Encoding UTF8
"manifest rows: $($rows.Count)"
