param([string]$EvidenceDir = (Join-Path (Split-Path $PSScriptRoot -Parent) 'evidence'),
      [string]$OutDir      = (Join-Path (Split-Path $PSScriptRoot -Parent) 'analysis'))
$ErrorActionPreference='Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$SAP = 'http://www.sap.com/Protocols/SAPData'
$MD  = 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata'
function A($n,$name){ $v = $n.GetAttribute($name,$SAP); if([string]::IsNullOrEmpty($v)){ $v = $n.GetAttribute($name) }; return $v }

$props=@(); $sets=@(); $fis=@(); $navs=@()

foreach ($f in Get-ChildItem $EvidenceDir -Filter 'META_*_response.xml') {
  $svc = $f.BaseName -replace '^META_','' -replace '_response$',''
  [xml]$x = Get-Content -LiteralPath $f.FullName -Raw
  $ns = New-Object System.Xml.XmlNamespaceManager($x.NameTable)
  $ns.AddNamespace('edmx','http://schemas.microsoft.com/ado/2007/06/edmx')
  $schemas = $x.SelectNodes('//*[local-name()="Schema"]')
  foreach ($sc in $schemas) {
    $nsName = $sc.GetAttribute('Namespace')

    foreach ($et in $sc.SelectNodes('*[local-name()="EntityType"]')) {
      $etName = $et.GetAttribute('Name')
      $keys = @()
      foreach ($k in $et.SelectNodes('*[local-name()="Key"]/*[local-name()="PropertyRef"]')) { $keys += $k.GetAttribute('Name') }
      foreach ($p in $et.SelectNodes('*[local-name()="Property"]')) {
        $pn = $p.GetAttribute('Name')
        $props += [pscustomobject]@{
          Service=$svc; Namespace=$nsName; EntityType=$etName; Property=$pn
          EdmType=$p.GetAttribute('Type'); Nullable=$p.GetAttribute('Nullable')
          MaxLength=$p.GetAttribute('MaxLength'); Precision=$p.GetAttribute('Precision'); Scale=$p.GetAttribute('Scale')
          IsKey=$(if($keys -contains $pn){'X'}else{''})
          Creatable=(A $p 'creatable'); Updatable=(A $p 'updatable'); Sortable=(A $p 'sortable')
          Filterable=(A $p 'filterable'); RequiredInFilter=(A $p 'required-in-filter')
          Unit=(A $p 'unit'); Label=(A $p 'label'); Heading=(A $p 'heading')
        }
      }
      foreach ($nv in $et.SelectNodes('*[local-name()="NavigationProperty"]')) {
        $navs += [pscustomobject]@{ Service=$svc; EntityType=$etName; Nav=$nv.GetAttribute('Name')
          Relationship=$nv.GetAttribute('Relationship'); FromRole=$nv.GetAttribute('FromRole'); ToRole=$nv.GetAttribute('ToRole') }
      }
    }

    foreach ($cont in $sc.SelectNodes('*[local-name()="EntityContainer"]')) {
      foreach ($es in $cont.SelectNodes('*[local-name()="EntitySet"]')) {
        $sets += [pscustomobject]@{
          Service=$svc; EntitySet=$es.GetAttribute('Name'); EntityType=$es.GetAttribute('EntityType')
          Creatable=(A $es 'creatable'); Updatable=(A $es 'updatable'); Deletable=(A $es 'deletable')
          Pageable=(A $es 'pageable'); Addressable=(A $es 'addressable'); Searchable=(A $es 'searchable')
          ContentVersion=(A $es 'content-version')
        }
      }
      foreach ($fi in $cont.SelectNodes('*[local-name()="FunctionImport"]')) {
        $pars = @()
        foreach ($pp in $fi.SelectNodes('*[local-name()="Parameter"]')) {
          $pars += ('{0}:{1}{2}{3}' -f $pp.GetAttribute('Name'), $pp.GetAttribute('Type'),
                    $(if($pp.GetAttribute('Mode')){'/'+$pp.GetAttribute('Mode')}else{''}),
                    $(if($pp.GetAttribute('Nullable') -eq 'false'){'/REQ'}else{''}))
        }
        $fis += [pscustomobject]@{
          Service=$svc; FunctionImport=$fi.GetAttribute('Name')
          HttpMethod=$fi.GetAttribute('HttpMethod',$MD); ActionFor=(A $fi 'action-for')
          ReturnType=$fi.GetAttribute('ReturnType'); EntitySet=$fi.GetAttribute('EntitySet')
          ParamCount=$pars.Count; Parameters=($pars -join ' ; ')
        }
      }
    }
  }
}

$props | Export-Csv (Join-Path $OutDir 'RUNTIME_PROPERTY_INDEX.tsv') -Delimiter "`t" -NoTypeInformation -Encoding UTF8
$sets  | Export-Csv (Join-Path $OutDir 'RUNTIME_ENTITYSETS.tsv')     -Delimiter "`t" -NoTypeInformation -Encoding UTF8
$fis   | Export-Csv (Join-Path $OutDir 'RUNTIME_FUNCTIONIMPORTS.tsv')-Delimiter "`t" -NoTypeInformation -Encoding UTF8
$navs  | Export-Csv (Join-Path $OutDir 'RUNTIME_NAVPROPS.tsv')       -Delimiter "`t" -NoTypeInformation -Encoding UTF8

"properties`t$($props.Count)"
"entitysets`t$($sets.Count)"
"functionimports`t$($fis.Count)"
"navprops`t$($navs.Count)"
