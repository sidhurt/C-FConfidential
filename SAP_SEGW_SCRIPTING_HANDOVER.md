# SAP SEGW Scripting Handover

> **Superseded scope (2026-08-15):** this describes the first six-project inspection only. Do not use its six-project boundary or “no metadata extracted” state as current truth. The complete catalogue and Tier-A evidence live in `sessions/2026-08-15-standard-api-discovery/`; current implementation direction is `deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md`.

**Date:** 2026-08-05  
**System:** `QS4`, client `700`, user `QNOVATE8`  
**Scope:** only the six SEGW projects shown by Siddharth. The 522-row Gateway export is lookup evidence, not the deliverable scope.

## Current state

- SAP GUI scripting works against the user's logged-in session.
- The session was verified as SAP QAS / `QS4` / client `700` / user `QNOVATE8`.
- No SAP writes were made.
- No `cscript.exe` process is currently running.
- The last six-project tree exporter completed even though the surrounding Codex command was interrupted. Its output is `sources/SRC-SYS-20260805-05_QS4_700_SIX_SEGW_TREE.tsv`, with 242 loaded tree nodes across all six projects.
- No `$metadata`, entity data, or ABAP class source has been extracted yet.
- No final six-service briefing workbook has been built yet.

## Important correction

The first project is `API_SALES_ORDER`, not `ZAPI_SALES_ORDER`.

The earlier failed attempt to open `ZAPI_SALES_ORDER` used the wrong name and is not evidence of a missing project. The correct layers are:

- SEGW project: `API_SALES_ORDER`
- SEGW runtime service: `API_SALES_ORDER_SRV`
- Gateway technical registration: `ZAPI_SALES_ORDER_SRV`
- Gateway external service: `API_SALES_ORDER_SRV`

All six displayed entries are genuine `R3TR/IWPR` SEGW projects. One is SAP-delivered and five are custom projects originating in DS4.

## Verified six-project summary

| SEGW project | Purpose | Gateway registration | Origin/package | Loaded model summary | Main DPC extension |
|---|---|---|---|---|---|
| `API_SALES_ORDER` | Remote API for SD Sales Order | `ZAPI_SALES_ORDER_SRV` -> `API_SALES_ORDER_SRV` | SAP; `ODATA_SD_SALESORDER_API`; component `S4CORE`, release 107 | SADL/CDS exposure; functions `rejectApprovalRequest`, `releaseApprovalRequest` | `CL_SD_API_SALES_ORDER_DPC_EXT` |
| `ZAPI_PLANT_WEIGHBRIDGE_RMC` | RMC Plant Weigh Bridge Data | `ZAPI_PLANT_WEIGHBRIDGE_RMC_SRV` | DS4; package `ZSD`; author `IBMABAP16` | `Rmc_data` / `Rmc_dataSet` | `ZCL_ZAPI_PLANT_WEIGHBR_DPC_EXT` |
| `ZCRM_SO_REJECT` | CRM: Sales order rejection | `ZCRM_SO_REJECT_SRV` | DS4; package `Z001`; author `IBMABAP05` | `ISSOREJECT` / `ISSOREJECTSet`; loaded fields include `Vbeln`, `Posnr`, `Abgru`, `Msg` | `ZCL_ZCRM_SO_REJECT_DPC_EXT` |
| `ZCRM_STAGEGATE` | CRM: Stage Gate | `ZCRM_STAGEGATE_SRV` | DS4; package `Z001`; author `IBMABAP05` | `deliveriesItems`, `STAGEGATE`; two corresponding entity sets | `ZCL_ZCRM_STAGEGATE_DPC_EXT` |
| `ZCUSTOMER_DETAIL` | Customer Detail - CPI | `ZCUSTOMER_DETAIL_SRV` | DS4; package `ZSD`; author `IBMABAP07` | `CUSTOMERMASTER` / `CUSTOMERMASTERSET` | `ZCL_ZCUSTOMER_DETAIL_DPC_EXT` |
| `ZMM_SCRUM_SER_PO` | Scrum to SAP Service PO | `ZMM_SCRUM_SER_PO_SRV` | DS4; package `ZMM`; author `IBMABAP34` | `poHeader`, `poItem`; association `HeaderToItem` | `ZCL_ZMM_SCRUM_SER_PO_DPC_EXT` |

Common registration facts for all six:

- version `1`;
- type `BEP`;
- processing mode `Routing-based`;
- soft state `Not Supported`;
- active `ODATA` ICF node in Standard Mode;
- system alias `LOCAL`.

`ZCUSTOMER_DETAIL_SRV` is the only one where the `LOCAL` default flag is blank; the ICF node is still active. The SEGW tree also shows `E8H_000` under Service Maintenance for all six. Keep that observation separate from the `/IWFND/MAINT_SERVICE` alias until its meaning is confirmed.

The tree export expands each project and its immediate standard branches, but it is not fully recursive. It is authoritative for the nodes present, not proof that every property or operation has been enumerated. Generic SEGW nodes such as Create/Update/Delete also do not prove that the DPC_EXT method is implemented.

## Method used so far

1. Preserved the supplied Gateway Excel export and six-project screenshot under `sources/`.
2. Attached to the existing SAP GUI session through `GetObject("SAPGUI")`; no credentials were used or stored.
3. Used a generic GUI component inspector to identify the actual grid/tree control IDs.
4. Reconciled the six project names against `/IWFND/MAINT_SERVICE` to capture technical name, external name, version, ICF status, and alias.
5. Queried `TADIR` with `PGMID=R3TR`, `OBJECT=IWPR` to verify project origin, package, author, and deletion flag.
6. Expanded the six SEGW trees and exported the loaded data-model, service-implementation, runtime-artifact, and service-maintenance nodes.
7. Kept the interrupted full-catalog extraction marked `.partial.tsv` and switched to a six-service targeted exporter after Siddharth narrowed the scope.

## Scripts written

All SAP scripts assume connection `0`, session `0`. Run the probe before continuing.

| Script | Arguments | Purpose and status |
|---|---|---|
| `tmp/sap_gui_probe.vbs` | none | Lists SAP GUI connections/sessions and prints SID, client, user, transaction, and program. Use first. |
| `tmp/sap_gui_inspect.vbs` | `[transaction] [action]` | Navigates and recursively dumps GUI components. Supports SEGW open/F4/project actions, SE16 table navigation, exact `TADIR_IWPR=<name>`, `TADIR_IWPR_Z`, `DISMISS_MODAL`, and `DUMP_MAIN`. |
| `tmp/sap_dump_grids.vbs` | optional zero-based service row | Dumps all current ALV grids. With a row argument, selects that `/IWFND/MAINT_SERVICE` row and dumps its service, ICF, and alias details. |
| `tmp/sap_export_gateway_catalog.vbs` | `<output-directory>` | Attempted the full 522-row service/ICF/alias export. Too slow; stopped partway. Do not use its `.partial.tsv` files as complete evidence. |
| `tmp/sap_export_target_gateway_details.vbs` | `<output-directory>` | Complete targeted exporter for the six Gateway technical registrations. Produced `SRC-SYS-20260805-04_*`. |
| `tmp/sap_dump_segw_tree.vbs` | none, `EXPAND_ROOTS`, or `EXPAND_PROJECT=<name>` | Prints the current SEGW tree. Project mode expands one project's immediate branches. Output is stdout only. |
| `tmp/sap_export_six_segw_tree.vbs` | `<output-directory>` | Targets exactly the six project roots and writes the loaded tree to `SRC-SYS-20260805-05_*`. Completed with 242 rows. Not recursive below the immediate branches. |
| `tmp/segw_workbook_20260805/inspect_export.mjs` | none; paths are hard-coded | Imports the supplied Excel workbook, normalizes the 522 catalog rows, writes JSON/TSV analysis, and renders a preview. It is not a final workbook builder. |

Useful commands from the repository root:

```powershell
cscript.exe //nologo ".\tmp\sap_gui_probe.vbs"

cscript.exe //nologo ".\tmp\sap_gui_inspect.vbs" "SE16" "TADIR_IWPR=API_SALES_ORDER"
cscript.exe //nologo ".\tmp\sap_dump_grids.vbs"

cscript.exe //nologo ".\tmp\sap_dump_segw_tree.vbs" "EXPAND_PROJECT=ZCRM_SO_REJECT"

cscript.exe //nologo ".\tmp\sap_export_target_gateway_details.vbs" ".\sources"
cscript.exe //nologo ".\tmp\sap_export_six_segw_tree.vbs" ".\sources"
```

SAP GUI attach notifications are enabled, so a user confirmation popup can delay a script. A shell timeout can also close the command wrapper while `cscript.exe` continues; check the process and output file before rerunning.

## Evidence already captured

| Source | What it contains | Status |
|---|---|---|
| `SRC-SYS-20260805-01_*partial.tsv` | Interrupted broad service/ICF/alias extraction | Partial; not authoritative for completeness |
| `SRC-SYS-20260805-02_QS4_700_GATEWAY_SERVICE_CATALOG.xlsx` | Supplied 522-row Gateway catalog | Preserved original; used only to reconcile the six services |
| `SRC-SYS-20260805-03_QS4_700_SEGW_PROJECT_LIST.png` | Supplied screenshot with the six project names/descriptions | Primary visual evidence |
| `SRC-SYS-20260805-04_QS4_700_TARGET_GATEWAY_SERVICES.tsv` | Six service registrations | Complete |
| `SRC-SYS-20260805-04_QS4_700_TARGET_GATEWAY_ICF_NODES.tsv` | Six ICF rows | Complete |
| `SRC-SYS-20260805-04_QS4_700_TARGET_GATEWAY_ALIASES.tsv` | Six alias rows | Complete |
| `SRC-SYS-20260805-05_QS4_700_SIX_SEGW_TREE.tsv` | Loaded tree nodes for all six projects | Complete for the script's non-recursive scope |

The TADIR findings were printed from live SAP but have not yet been saved as one combined raw six-row file.

## Next scripting work

1. Run `sap_gui_probe.vbs` and confirm the intended `QS4/700` session.
2. Persist a bounded six-row TADIR extract instead of rerunning the wider `Z*` query.
3. Use `/IWFND/GW_CLIENT` to issue read-only `GET` requests for each service root and `$metadata`; save HTTP status and metadata XML.
4. Parse entity types, keys, properties, entity sets, navigation properties, and function imports from metadata.
5. Inspect the five custom DPC_EXT classes read-only and record which methods are actually redefined/implemented.
6. Expand deeper SEGW nodes only where metadata or class source leaves a gap.
7. Build the final briefing around these six services only: purpose, naming layers, origin/package, endpoint, model, implemented operations, runtime classes, and open questions.

Do not rerun the broad catalog exporter. The user's focus is the six visible/exposed APIs, not the rest of the system.
