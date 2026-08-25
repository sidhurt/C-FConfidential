# MIGO OData transport evidence — 2026-08-22

## Scope

- Source: DS4 client 200
- User: QNOVATE8
- Intended target: QS4
- Service: `ZAPI_MATERIAL_DOCUMENT_SRV` version `1`
- External service: `API_MATERIAL_DOCUMENT_SRV`
- System alias in DS4/200: `LOCAL` (default)
- Constraint: no release, import, deletion, or QS4 mutation was authorized or performed.

## Transport created

- Request: `DS4K963268`
- Description: `TOC : MIGO OData`
- Type/status: `TRFUNCTION=T`, `TRSTATUS=D` (modifiable Transport of Copies)
- Target: `QS4`
- Owner: `QNOVATE8`
- Created: `2026-08-22 14:19:00`

## Independently identified repository objects

| PGMID | Object | Object name | SAP description |
|---|---|---|---|
| R3TR | IWOM | `ZAPI_MATERIAL_DOCUMENT_MDL_0001_BE` | SAP Gateway: Model Metadata |
| R3TR | IWSG | `ZAPI_MATERIAL_DOCUMENT_SRV_0001` | SAP Gateway: Service Groups Metadata |
| R3TR | SICF | `DS420000000069300O2TMQPDL0AXGC2ZZH2Y8XW1` | ICF Service |

The SICF object was mapped through `ICFSERVICE`: internal node `DS4200000000693`, parent GUID `00O2TMQPDL0AXGC2ZZH2Y8XW1`, original alternative name `api_material_document_srv`.

## Direct CTS inclusion result

The broken `/IWFND/MAINT_SERVICE` **Add to Transport** pathway was not used. In `SE01`, request `DS4K963268` was selected and the three objects were entered under **Include Objects → Freely Selected Objects**.

SAP validated the object types and displayed their correct descriptions, but rejected inclusion with these messages:

- `ZAPI_MATERIAL_DOCUMENT_MDL_0001_BE cannot be added to request/task`
- `ZAPI_MATERIAL_DOCUMENT_SRV_0001 cannot be added to request/task`
- `DS420000000069300O2TMQPDL0AXGC2ZZH2Y8XW1 cannot be added to request/task`

## Root-cause evidence

Exact `TADIR` reads for all three objects show:

- `SRCSYSTEM=DS4`
- `AUTHOR=QNOVATE8`
- `DEVCLASS=$TMP`
- `KORRNUM` blank
- `EDTFLAG=L`

Therefore, the registration artifacts are local objects and CTS refuses to include them in a transportable request. This explains both the failed maintenance-service transport path and the failed direct-CTS path.

## Post-attempt integrity check

- `E070`: `DS4K963268` still exists, remains modifiable, and targets `QS4`.
- `E071`: zero rows for `DS4K963268` (`No table entries found for specified key`).
- No objects were persisted to the request.
- No request was released or imported.
- QS4 was not changed.

## Required remediation

Basis/ABAP must first assign/recreate the three service-registration objects in a transportable package (or perform the supported object-directory/package reassignment for this SAP release). After that, include the same three complete objects in `DS4K963268` or a replacement workbench/ToC request, then handle the client-dependent `LOCAL` system-alias customizing separately.

## Remediation completed and TOC populated

The service was subsequently re-registered under transportable package `ZSCL` using:

- Source Workbench request: `DS4K963269` — `TR : ABAP : Service flow`
- Child task: `DS4K963270`
- Source status: modifiable; target `QS4`

The child task contains the new transportable registration artifacts:

| Position | PGMID | Object | Object name |
|---:|---|---|---|
| 000001 | R3TR | IWOM | `ZAPI_MATERIAL_DOCUMENT_MDL_0001_BE` |
| 000002 | R3TR | IWSG | `ZAPI_MATERIAL_DOCUMENT_SRV_0001` |
| 000003 | R3TR | SICF | `DS420000000069700O2TMQPDL0AXGC2ZZH2Y8XW1` |

The re-registration created a new ICF node (`...697...`); the earlier local `$TMP` node (`...693...`) is not the object transported.

In `SE01`, **Include Objects → Object List from Request** was used on TOC `DS4K963268`, with source `DS4K963269`. SAP confirmed:

> The object entries from DS4K963269 were added to object list DS4K963268

Post-copy state:

- `DS4K963268` remains a modifiable Transport of Copies targeting `QS4`.
- `E071` stores position `000001` as `PGMID=CORR`, `OBJECT=MERG`, referencing `DS4K963269 20260822 150132 QNOVATE8`.
- The referenced source task `DS4K963270` contains the three exact repository rows listed above.
- No release/import/delete was performed and QS4 was not changed.
