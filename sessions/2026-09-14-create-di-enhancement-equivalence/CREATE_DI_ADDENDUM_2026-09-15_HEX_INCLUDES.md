# Addendum — completing the method sweep (hexadecimal include band)

**System:** QS4 client 700, user QNOVATE8, single session (verified before each run)
**Date:** 2026-09-15
**Mode:** read-only. SE38 / SE24 / SE16 / SE18 display only. No write, no BAPI, no OData, no commit.
**Editor setting:** switched to Text-Based Editor for capture, then restored to
`SEUCUSTOM-ABAPCNTRL` and verified field-by-field against `EDITOR_SETTING_BASELINE.md`.

## 1. The completeness error

`CREATE_DI_VALIDATION_MATRIX.md` (first version) claimed each implementing class has
"exactly nine methods" and that the capture was complete. **That was wrong.**

ABAP method includes are numbered in base-36: `CM001`–`CM009`, then **`CM00A`–`CM00Z`**, then
`CM010`. The original sweep probed `CM001`–`CM009` and then jumped to `CM010`–`CM025`, skipping
the entire `CM00A`–`CM00Z` band where eight further methods live.

**Authoritative count, now established two independent ways:**

- SE24 → Methods tab → `RowCount` = 17 populated rows for every implementing class.
- Include probe now covering `CM001`–`CM009`, `CM00A`–`CM00Z`, `CM010`–`CM025`:
  exactly `CM001`–`CM009` + `CM00A`–`CM00H` exist = **17 methods**. All others absent.

This also matches the REPOSRC census already recorded in `BADI_IMPLEMENTATION_MATRIX.tsv` on
2026-09-14 — the correct include list was in the repository and the first sweep ignored it.

## 2. Newly captured non-empty methods

| Class | Include | Method | Content | Create DI relevance |
|---|---|---|---|---|
| `ZCLLE_DELIVERY_PROCESS` | `CM00A` | `SAVE_DOCUMENT_PREPARE` | **D1** derives `VBPA PARVW='SP'` from `LIKP-ZZPARTNER`; **D2** derives `LIKP-SDABW` from `ZLET_VEHICLE` | **High** — supplies the very fields V09a/V09b/V03/V10 test |
| `ZCLLE_DELIVERY_PROCESS` | `CM00B` | `FILL_DELIVERY_HEADER` | `EL` → `VSART='01'`; for `LFART` in `ZSD_PREREQ_DEL` fills dummy route from TVARVC `SHORTAGE_DEFAULT_ROUTE` | Medium — route-validation bypass, but **not** for ZNL/ZLF/ZNP |
| `ZCLLE_DELIVERY_PROCESS` | `CM00F` | `SAVE_AND_PUBLISH_BEFORE_OUTPUT` | Entire body commented out except an empty `IF if_trtyp = 'H'` shell | None |
| `ZCLLE_DELIVERY_PROCESS` | `CM00G` | `CHANGE_DELIVERY_ITEM` | ILMS: overwrites `LIPS-LGORT` from memory ID `BATCH` | Change path only |
| `ZCL_IM_LE_SHP_DELIVERY_PROC` | `CM00H` | `SAVE_AND_PUBLISH_BEFORE_OUTPUT` | `SY-TCODE='VL09'` + `LFART='ZNL'` → `ZOTC_SHIPMENT_SCD_DELETE` | Out of scope (reversal) |
| `ZCL_IM_LE_SHP_DELV_INTECO` | `CM00E` | `CHANGE_DELIVERY_HEADER` | ZRMC/ZRM2 process-order and vehicle derivation | Out of scope |
| `ZCL_IM_LE_SHP_DELV_INTECO` | `CM00F` | `CHANGE_DELIVERY_ITEM` | ZRMC/ZRM2 derivation from memory IDs | Out of scope |
| `ZCL_IM_SDEI_DELIVERY` | `CM00E` | `CHANGE_DELIVERY_HEADER` | ZRMC/ZRM2 route defaulting. **Contains an active `BREAK ibmabap17.` statement** | Out of scope, but see defect 7 |
| `ZCL_IM_SDE034_LIC_NOTIF` | `CM00A` | `SAVE_DOCUMENT_PREPARE` | **V12** trade-licence delivery block + `VSART`/`LIFEX`/`SDABW` derivations | **High** |
| `CL_IM_SHP_EXTEND_ODATA` | `CM001` | `SAVE_DOCUMENT_PREPARE` | SAP standard: OData SOA extension-field mapping into `CT_XLIKP`/`CT_XLIPS` | **High** |

`ZCL_IM_SD_DELV_ATT_ENHC`: all **17** method bodies read and confirmed empty. The earlier
"entirely empty" verdict survives, now on complete evidence.

## 3. New rule

### V12 — trade-licence expiry sets a delivery block

- **Location:** `ZCL_IM_SDE034_LIC_NOTIF~IF_EX_LE_SHP_DELIVERY_PROC~SAVE_DOCUMENT_PREPARE`
  (`CM00A`).
- **Gate:** `ZGPT_SD_PARAM` rows for program `ZUCCSDE005_TRADE_LICENSE`, object `SDE005`,
  matched on `FIELD='TCODE'` + `PARAM1 = SY-TCODE`, then `FIELD='LFART'` + `PARAM1 = LIKP-LFART`,
  both with `ACTIVE_FLAG = 'X'`.
- **Behaviour:** if the sold-to (`LIKP-KUNAG`) has **no** `BUT0ID` record of type `ZTRLIC`, it
  sets `LIKP-LIFSK = <PARAM2>` on **every** header. If a record exists but expired more than 30
  days ago, it sets `LIFSK` on headers with `UPDKZ='I'` (newly created only).
- **Message:** `ZUCC_SD 001` / `ZUCC_SD 002`, both `msgty='I'` into `CT_LOG`.
- **Why this matters:** it is **not** a blocking check — it is a **silent mutation**. The save
  succeeds and a *delivery-blocked* document is created. An integration would see success.
- **Status in QS4: config-dead.** `ZGPT_SD_PARAM` is **empty** in client 700, so neither gate
  can be satisfied. Classification: **Verified config-dead**; the code path is live if the table
  is ever populated, and the `TCODE` gate is what would decide screen-vs-API applicability.

## 4. New derivations that change how V03 / V07–V10 must be read

These are not validations, but they populate the fields the validations test.

- **D1 — transporter partner derived from `LIKP-ZZPARTNER`**
  (`ZCLLE_DELIVERY_PROCESS~SAVE_DOCUMENT_PREPARE`). If `ZZPARTNER` is set and no `PARVW='SP'`
  row exists, one is appended with `UPDKZ='I'`, `ADRNR` from `LFA1` and `ASSIGNED_BP` from
  `CVI_VEND_LINK`/`BUT000`. `ZZPARTNER` is one of the fields the BAPI extension class
  `ZCLLE_UPDATE_DELIVERY_CUSTOM~ADDITIONAL_INPUT` maps from `EXTENSION_IN`. **So the API does
  have a route to supply the transporter** — previously recorded as an open risk.
- **D2 — SPI derived from the vehicle** (same method). If any item has `MFRGR='A0000003'` and
  `LIKP-ZZVEHICLE_NO` is set, `ZLET_VEHICLE` is read and `LIKP-SDABW` is overwritten with
  `'NC' && V_TYP` (vehicle status `04`) or `'VT' && V_TYP`. **This is the "SPI auto-fill" the V10
  comment refers to**, and it explains V10's early `RETURN` on `SDABW(2) = 'NC'`.
- **D3 — `LIKP-SDABW` and `LIKP-LIFEX` from ABAP memory**
  (`ZCL_IM_SDE034_LIC_NOTIF~SAVE_DOCUMENT_PREPARE`, `CM00A`). Read from memory IDs `LV_SDABW`
  and `LV_LIFEX`. **Not** gated by `ZGPT_SD_PARAM` — these run for every non-deleted header.
  Memory IDs are set by a calling ABAP program, so a Z report or screen caller can populate them
  and a pure external OData request cannot.

### The sequencing consequence — the sharpest new finding

All three derivations, **and the SAP OData extension mapping in `CL_IM_SHP_EXTEND_ODATA`**, run
in `SAVE_DOCUMENT_PREPARE`. Every validation V03, V07, V08, V09a, V09b, V10 runs in
`DELIVERY_FINAL_CHECK`.

In standard LE delivery processing `DELIVERY_FINAL_CHECK` executes **before**
`SAVE_DOCUMENT_PREPARE`. If that holds at runtime, then fields arriving through the OData
extension channel or through D1/D2/D3 land **after** the checks that test them — so those
validations would evaluate against unpopulated fields and silently pass, on the API path, even
when the caller did supply the data.

**Classification: strong inference.** BAdI method call order is the one thing source cannot
prove. It is directly observable by comparing breakpoint hit order in T0 and costs nothing extra.

## 5. `SHP_EXTEND_ODATA` — contradiction resolved

The earlier statement "`SHP_EXTEND_ODATA` does not exist in QS4" was **wrong in kind**: it was
searched for as an enhancement spot and as a BAdI *definition*, and it is neither.

**It is a BAdI implementation of `LE_SHP_DELIVERY_PROC`:**

| Field | Value | Source |
|---|---|---|
| `IMP_NAME` | `SHP_EXTEND_ODATA` | `SXC_CLASS` |
| `INTER_NAME` | `IF_EX_LE_SHP_DELIVERY_PROC` | `SXC_CLASS` |
| `IMP_CLASS` | `CL_IM_SHP_EXTEND_ODATA` | `SXC_CLASS` |
| Registered on | `LE_SHP_DELIVERY_PROC` | `SXC_EXIT` (38 implementations listed) |

`LE_SHP_DELIVERY_PROC` is a classic BAdI **migrated to enhancement spot** of the same name
(SE18 Properties tab, generated class `CL_EX_LE_SHP_DELIVERY_PROC`), which is why the customer
implementations appear in the spot list while SAP's classic ones appear in `SXC_EXIT`.

**What it does:** exactly one of its 17 methods is non-empty — `SAVE_DOCUMENT_PREPARE`. It calls
`/SPE/CL_INB_ACTION_INFO=>GET_EXTENSION_FIELDS` and copies the returned changed header fields
into `CT_XLIKP` and changed item fields into `CT_XLIPS` by dynamic `ASSIGN COMPONENT`. Its only
messages (`LE_SHP_ODATA_API_OD` 013/014/015/016) fire when a named field does not exist in the
target structure.

**Verdict: inbound OData extension-field mapping. No business validation, and nothing that
blocks on business grounds.** Its significance to Create DI is the timing point in section 4 —
it is the mechanism by which OData-supplied custom fields reach `LIKP`/`LIPS`, and it runs in
`SAVE_DOCUMENT_PREPARE`.

## 6. Corrections to earlier conclusions

| # | Earlier claim | Status |
|---|---|---|
| 1 | "Each implementation has exactly nine methods; the capture is complete." | **Wrong.** 17 methods each. Corrected. |
| 2 | "`SAVE_AND_PUBLISH_BEFORE_OUTPUT` is not a method of `ZCL_IM_LE_SHP_DELIVERY_PROC`; rule `ZLE-REV-01` does not exist as active code." | **Wrong — retracted.** It is `CM00H`, active, non-empty. The 2026-09-14 register's `ZLE-REV-01` was **correct**. My "correction 1" is withdrawn. |
| 3 | "`ZSDEI_DELIVERY` has no active code in any method." | **Wrong.** `CM00E` (`CHANGE_DELIVERY_HEADER`) is active. Out of Create DI scope, but not empty. |
| 4 | "`SHP_EXTEND_ODATA` does not exist in QS4." | **Wrong.** It is a BAdI implementation; see section 5. |
| 5 | "`ZSD_DELV_ATT_ENHC` is entirely empty." | **Stands**, now on all 17 bodies rather than 9. |
| 6 | "`ZCL_IM_LE_SHP_DELIVERY_PROC~SAVE_DOCUMENT_PREPARE` is entirely commented out." | **Stands** (`CM002`). |
| 7 | Licence notification is informational only. | **Refined.** `DELIVERY_FINAL_CHECK` is informational, but `SAVE_DOCUMENT_PREPARE` (V12) silently sets `LIKP-LIFSK`. Both are config-dead in QS4 because `ZGPT_SD_PARAM` is empty. |

All V01–V11 source and configuration conclusions in `CREATE_DI_VALIDATION_MATRIX.md` are
**unaffected** by this error — none of them depended on a `CM00A`–`CM00H` method. What changed is
the surrounding derivation and sequencing picture, plus V12.

## 7. Additional defect

7. `ZCL_IM_SDEI_DELIVERY~CHANGE_DELIVERY_HEADER` (`CM00E`) contains an **active
   `BREAK ibmabap17.`** statement in productive code. For that user it opens the debugger; in a
   background or API context a hard break can terminate or hang processing. Report to the client.

## 8. Evidence file paths

All relative to
`sessions/2026-09-14-create-di-enhancement-equivalence/`:

- `source-captures/2026-09-15-QS4-scripted/` — 132 files, complete active bodies for all 17
  methods of all six customer implementations, both BAPI-extension classes, and
  `CL_IM_SHP_EXTEND_ODATA`, plus `MV50AFZ1.txt` and `CONFIG_TABLES.txt`.
- Key new files:
  - `ZCLLE_DELIVERY_PROCESS========CM00A.txt` — D1, D2
  - `ZCLLE_DELIVERY_PROCESS========CM00B.txt` — route defaulting
  - `ZCL_IM_SDE034_LIC_NOTIF=======CM00A.txt` — V12, D3
  - `ZCL_IM_LE_SHP_DELIVERY_PROC===CM00H.txt` — retraction evidence for correction 2
  - `ZCL_IM_SDEI_DELIVERY==========CM00E.txt` — `BREAK` statement
  - `CL_IM_SHP_EXTEND_ODATA========CM001.txt` — OData extension mapping
- `EDITOR_SETTING_BASELINE.md` — setting baseline and restore proof
- `CREATE_DI_VALIDATION_MATRIX.md` — V01–V11 matrix (amended)
- `RUNTIME_TEST_PLAN.md` — staged tests, unchanged except T0
