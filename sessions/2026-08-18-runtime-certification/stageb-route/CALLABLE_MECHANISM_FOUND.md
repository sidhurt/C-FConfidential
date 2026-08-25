# Shipment-cost callable mechanism — identified

**System:** DS4/200, read-only repository queries (`TSTC`, `TFDIR`). **Date:** 2026-08-18.

## The transactions

| Tcode | Program | Text | Source |
|---|---|---|---|
| `VI01` | `SAPMV54A` | Create shipment costs | `TSTC`, DS4/200 |
| `VI02` | `SAPMV54A` | Change shipment costs | `TSTC`, DS4/200 |
| `VI04` | *(none in `TSTC-PGMNA`)* | Create shipment cost worklist | `TSTC`, DS4/200 |

Corroborated independently by the client-supplied document `sources/extracted/SRC-DOC-20260803-01_extracted.txt`, which lists the operational chain as
`VL02N … VT01N / VT02N (shipment) … VI01 / VI02 / VI03 (Shipment cost) … PGI … VF01/VF02/VF03 (invoice)`.

`SAPMV54A` is a dialog module pool. It is **not** externally callable.

## The function modules behind it

Complete `SD_SCDS_*` family in DS4/200 (`TFDIR`, 9 rows):

| Function module | Program | Role |
|---|---|---|
| **`SD_SCDS_CREATE`** | `SAPLV54C` | **create the shipment-cost document** |
| `SD_SCDS_CHANGE` | `SAPLV54C` | change |
| **`SD_SCDS_RELEASE`** | `SAPLV54R` | **release** |
| `SD_SCDS_REVERSE` | `SAPLV54R` | reverse |
| **`SD_SCDS_SAVE`** | `SAPLV54U` | **persist / commit boundary** |
| `SD_SCDS_SHIPMENT_UPDATE` | `SAPLV54U` | writes shipment status (`VTTK-FBGST` / `ARGST`) |
| `SD_SCDS_CHECK_CHANGES` | `SAPLV54U` | validation |
| `SD_SCDS_CHECK_COMPLETE` | `SAPLV54U` | validation |
| `SD_SCDS_HEAD_DETERMINE_STATUS` | `SAPLV54S` | status determination |

Related `SD_SCD_*` (document/item level) includes `SD_SCD_ITEM_CALCULATE`, `SD_SCD_ITEM_ACCT_ASSIGNMENT`, `SD_SCD_HISTORY_SETTLEMENT`, `SD_SCD_AUTH_CHECK_TPLST`.

## The decisive attribute

**None of the nine `SD_SCDS_*` modules is remote-enabled.**

`TFDIR-FMODE` (column 104) is blank for all nine. Positive control on the same view and column: `BAPI_SHIPMENT_CREATE` returns `FMODE = R`. So the blank is a real "not RFC-enabled", not a parsing artefact.

## What this settles

1. **Cost-document creation has a named callable mechanism** — `SD_SCDS_CREATE` — but it is internal-only.
2. **Release has a named callable mechanism** — `SD_SCDS_RELEASE` — also internal-only. The project no longer has to guess where release lives; it is a function module, not a status field.
3. **The commit boundary is `SD_SCDS_SAVE`**, separate from create and release. Create and release therefore operate on an in-memory document and are persisted by a distinct call — which is why a caller must own the sequence.
4. **`SD_SCDS_SHIPMENT_UPDATE` is what writes `VTTK-FBGST`/`ARGST`**, explaining the shipment-level statuses observed in QS4.
5. **There is no released, externally callable standard interface for cost creation or release.** This is now an evidenced `CUSTOM SAP GAP`, not an absence of searching.

## The actual client route — traced end to end

The client does **not** drive shipment costing through the standard VI01/VI02 dialog. The real chain, established by where-used analysis in DS4/200:

```
ZDACE_WT  "Weight Bridge"           (custom transaction, TSTC)
  program SAPMZACE_WEIGHMENT, screen 9000
    └─ include MZACE_WEIGHMENT_I_FORM
         └─ ZDACE_CL_STO_PROCESS     (custom class — the orchestrator)
              ├─ RUN_WEIGHT_IN  / RUN_WEIGHT_OUT   weighbridge capture
              ├─ SHIP_DOC_CRT   / SHIP_DOC_CHG     shipment create / change
              ├─ SHIP_COST_CRT                     shipment cost create
              ├─ DELIVERY_CHANGE
              ├─ DELIVERY_PGI                      goods issue
              └─ COMMIT_LUW / ROLLBACK_LUW         explicit LUW control
                   └─ SD_SCDS_CREATE               SAP standard, not RFC
                        └─ VFKK / VFKP, VTTK-FBGST / ARGST
```

Evidence chain:

| Step | Method | Result |
|---|---|---|
| `SD_SCDS_CREATE` where-used (full scope) | SE37 btn[39], Select All | **8 hits, all custom**: classes `ZCLDACE_POST_UTILITY`, `ZCLDACE_WT_TRNASFER`, `ZDACE_CL_STO_PROCESS` (each method `SHIP_COST_CRT`); programs `ZLEIILMSDOCUMENTS_SHIPMENTCOST`, `ZLEIILMSDOCUMENTS_INTERCOMPANY`, `ZLERA2SALAUTO`, `ZLERBTSTSALAUTO`, `ZSDC013_SHIPMENT_UPLOAD_SUB` |
| Index coverage control | where-used on `SD_SCD_ITEM_CALCULATE` | 2 hits, **`LV54CF02` / `LV54CF03`** — SAP standard V54C includes. So the index does cover standard code; the custom-only result for `SD_SCDS_CREATE` is real. |
| Class components | `SEOCOMPO` | 20 rows — the method list above |
| Class where-used | SE24 btn[39] + "include components" = Yes | 14 hits: 13 self-references, **1 external caller `MZACE_WEIGHMENT_I_FORM`** |
| Transaction | `TSTC` where `PGMNA = SAPMZACE_WEIGHMENT` | **`ZDACE_WT` — "Weight Bridge"**, screen 9000 |

### What this changes

1. **The orchestration already exists.** `ZDACE_CL_STO_PROCESS` performs shipment create → cost create → delivery change → PGI with its own `COMMIT_LUW` / `ROLLBACK_LUW`. CNF does not need to invent this sequence.
2. **Its entry point is a dialog screen**, so it is not callable as-is. The gap is an *exposure* layer, not orchestration logic.
3. **`SD_SCDS_CREATE` is the reusable standard engine** — short text "Frachtkosten anlegen (online, batch)", has `I_OPT_COMMIT`, takes a range of reference objects. It is the documented mass entry point and is already wrapped by the client three times.
4. **The process is weighbridge-driven**, which explains `VTTK-ZZGROSS_WT` / `ZZNET_WT` / `ZZTARE_WT` and the `RUN_WEIGHT_IN` / `RUN_WEIGHT_OUT` methods.
5. `ZDACE_FM_WEIGH_BRIDGE_INT` (the only RFC-enabled module in the `*DACE*` family) is **not** the dispatch entry point — its interface is `IM_URL` in, `TERMINAL_ID`/`DATE_TIME`/`WEIGHT` out. It reads a weighbridge REST API. Do not mistake it for the orchestrator.

### Settlement note

No caller was found for `SD_SCDS_RELEASE` even at full scope, and the class has no explicit settlement method. Since the index demonstrably covers standard code, `SD_SCDS_RELEASE` is likely invoked dynamically or from screen flow logic not captured by the static index. **Settlement therefore remains the one stage whose invoker is still unidentified.**

## What this does *not* settle

- Whether `BAPI_SHIPMENT_CREATE` internally triggers `SD_SCDS_CREATE` on save — needs source inspection of `SAPLV56I_BAPI`.
- The exact interfaces, mandatory inputs and commit semantics of `SD_SCDS_CREATE` / `SD_SCDS_RELEASE` / `SD_SCDS_SAVE` — needs SE37 interface capture, then execution.
- Whether release is a technical PGI prerequisite — still requires the DS4 experiment.
- Nothing here has been **executed**. This is repository evidence identifying the mechanism, not an evidence run.
