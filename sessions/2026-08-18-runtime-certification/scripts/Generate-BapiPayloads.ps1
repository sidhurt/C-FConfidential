param(
  [string]$SessionRoot = (Split-Path $PSScriptRoot -Parent)
)
$ErrorActionPreference = 'Stop'
$bapiDir = Join-Path $SessionRoot 'bapi'
$outDir = Join-Path $SessionRoot 'payloads\bapi'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Base-Type([string]$type) {
  if ($type -match '^([A-Za-z0-9_/]+)-') { return $Matches[1] }
  return $type
}

function Structure-Fields([string]$type) {
  $base = Base-Type $type
  $path = Join-Path $bapiDir ($base + '_fields.tsv')
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  return @(
    Import-Csv -Delimiter "`t" -LiteralPath $path |
      Where-Object { $_.FieldName -and -not $_.FieldName.StartsWith('.') } |
      Sort-Object { [int]$_.Position } |
      ForEach-Object {
        [ordered]@{
          field = $_.FieldName
          position = $_.Position
          dataElement = $_.DataElement
          checkTable = $_.CheckTable
          value = '<populate only when required by the scenario>'
        }
      }
  )
}

$scenario = @{
  BAPI_MATERIAL_AVAILABILITY = [ordered]@{
    mode = 'READ_ONLY_EXECUTED'
    request = [ordered]@{ PLANT='PLQ3'; MATERIAL='MAT18'; UNIT='EA'; WMDVSX=@() }
    observedResponse = [ordered]@{ AV_QTY_PLT='0.000'; DIALOGFLAG=''; RETURN=''; interpretation='Valid DEV material/plant master; no ATP quantity returned.' }
  }
  BAPI_GOODSMVT_CREATE = [ordered]@{
    mode = 'SIMULATION_ONLY'
    request = [ordered]@{ TESTRUN='X'; GOODSMVT_CODE=[ordered]@{GM_CODE='<MM must confirm; likely goods-receipt scenario>'}; GOODSMVT_HEADER=[ordered]@{PSTNG_DATE='<YYYYMMDD>'; DOC_DATE='<YYYYMMDD>'; HEADER_TXT='CNF DEV simulation'}; GOODSMVT_ITEM=@([ordered]@{MOVE_TYPE='101'; MATERIAL='<DEV material>'; PLANT='<DEV plant>'; STGE_LOC='<DEV storage location>'; ENTRY_QNT='<quantity>'; ENTRY_UOM='<unit>'; PO_NUMBER='<DEV STO>'; PO_ITEM='00010'; DELIV_NUMB='<DEV delivery if required>'; DELIV_ITEM='000010'}) }
    successEvidence = 'RETURN contains no E/A messages; MATERIALDOCUMENT remains non-persistent in TESTRUN; compare with API-01 payload semantics.'
  }
  BAPI_PO_CREATE1 = [ordered]@{
    mode = 'SIMULATION_ONLY'
    request = [ordered]@{ TESTRUN='X'; POHEADER=[ordered]@{DOC_TYPE='ZP06'; PURCH_ORG='1000'; PUR_GROUP='801'; SUPPL_PLNT='<DEV supplying plant>'}; POHEADERX=[ordered]@{DOC_TYPE='X'; PURCH_ORG='X'; PUR_GROUP='X'; SUPPL_PLNT='X'}; POITEM=@([ordered]@{PO_ITEM='00010'; MATERIAL='<DEV material>'; PLANT='<DEV receiving plant>'; QUANTITY='<quantity>'; PO_UNIT='<unit>'; ITEM_CAT='7'}); POITEMX=@([ordered]@{PO_ITEM='00010'; PO_ITEMX='X'; MATERIAL='X'; PLANT='X'; QUANTITY='X'; PO_UNIT='X'; ITEM_CAT='X'}); POSCHEDULE=@([ordered]@{PO_ITEM='00010'; SCHED_LINE='0001'; DELIVERY_DATE='<YYYYMMDD>'; QUANTITY='<quantity>'}); POSCHEDULEX=@([ordered]@{PO_ITEM='00010'; SCHED_LINE='0001'; PO_ITEMX='X'; SCHED_LINEX='X'; DELIVERY_DATE='X'; QUANTITY='X'}) }
    successEvidence = 'RETURN contains no E/A messages in TESTRUN; no purchase order is committed.'
  }
  BAPI_BILLINGDOC_CREATEMULTIPLE = [ordered]@{
    mode = 'SIMULATION_ONLY'
    request = [ordered]@{ TESTRUN='X'; POSTING=''; BILLINGDATAIN=@([ordered]@{REF_DOC='<DEV delivery>'; REF_DOC_CA='<confirm category>'; REF_ITEM='000010'; BILL_DATE='<YYYYMMDD>'; BILL_TYPE='<confirm billing type>'; REQ_QTY='<quantity>'; SALES_UNIT='<unit>'}) }
    successEvidence = 'RETURN/ERRORS contain no E/A messages and SUCCESS describes the simulated billing outcome; no billing document is posted.'
  }
  BAPI_BILLINGDOC_CANCEL1 = [ordered]@{
    mode = 'SIMULATION_ONLY'
    request = [ordered]@{ BILLINGDOCUMENT='<DEV billing document>'; TESTRUN='X'; NO_COMMIT='X'; BILLINGDATE='<YYYYMMDD>' }
    successEvidence = 'RETURN has no E/A message for an approved cancellable DEV invoice; no cancellation is committed.'
  }
  BAPI_SHIPMENT_COST_ESTIMATE = [ordered]@{
    mode = 'NOT_EXECUTED_NOT_RELEASED'
    request = [ordered]@{ HEADERDATA=[ordered]@{SHIPMENT_TYPE='<configured DEV type>'; TRANS_PLAN_PT='<transportation planning point>'; SERVICE_AGENT_ID='<DEV transporter>'; SHPMNT_COST_REL='X'}; ITEMDATA=@([ordered]@{DELIVERY='<approved DEV delivery>'; ITENERARY='<if required>'}) }
    successEvidence = 'RETURNCOSTS returns carrier/cost candidates and RETURN contains no E/A messages. Do not treat remote-enabled as released.'
  }
}

Get-ChildItem -LiteralPath $bapiDir -Filter '*_interface.tsv' | Sort-Object Name | ForEach-Object {
  $rows = @(Import-Csv -Delimiter "`t" -LiteralPath $_.FullName)
  $fm = $_.BaseName -replace '_interface$',''
  $attrs = [ordered]@{}
  $rows | Where-Object RecordType -eq 'ATTRIBUTE' | ForEach-Object { $attrs[$_.Parameter] = $_.Value }
  $params = @($rows | Where-Object RecordType -eq 'PARAMETER' | Group-Object Section,Parameter | ForEach-Object { $_.Group[0] })
  $sections = [ordered]@{}
  foreach ($section in @('IMPORT','EXPORT','CHANGING','TABLES','EXCEPTIONS')) {
    $sections[$section] = @(
      $params | Where-Object Section -eq $section | ForEach-Object {
        [ordered]@{
          parameter = $_.Parameter
          associatedType = $_.AssociatedType
          optional = ($_.Optional -eq 'X')
          passByValue = ($_.PassByValue -eq 'X')
          defaultValue = $_.DefaultValue
          shortText = $_.ShortText
          structureFields = @(Structure-Fields $_.AssociatedType)
        }
      }
    )
  }
  $release = if ($attrs.ReleaseStatus -like 'Released*') { 'Released' } else { $attrs.ReleaseStatus }
  $doc = [ordered]@{
    meta = [ordered]@{
      system = 'DS4'
      client = '200'
      user = $attrs.User
      functionModule = $fm
      functionGroup = $attrs.FunctionGroup
      remoteEnabled = ($attrs.RemoteEnabled -eq 'X')
      releaseStatus = $release
      capturedFrom = 'SE37 display + DD03L in live DS4/200'
      executionPolicy = 'READ or TESTRUN only. Never call BAPI_TRANSACTION_COMMIT for simulation cases.'
    }
    interface = $sections
    cnfScenario = if ($scenario.ContainsKey($fm)) { $scenario[$fm] } else { [ordered]@{ mode='INTERFACE_CAPTURED_NOT_EXECUTED'; request='<build from exact interface below using approved DEV test data>'; successEvidence='Inspect RETURN/BAPIRET* and business document state.' } }
  }
  $json = $doc | ConvertTo-Json -Depth 20
  Set-Content -LiteralPath (Join-Path $outDir ($fm + '.json')) -Value $json -Encoding utf8
}

Get-ChildItem -LiteralPath $outDir -Filter '*.json' | ForEach-Object {
  Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json | Out-Null
}
Write-Output ('GENERATED_BAPI_PAYLOADS|' + (Get-ChildItem -LiteralPath $outDir -Filter '*.json').Count + '|' + $outDir)
