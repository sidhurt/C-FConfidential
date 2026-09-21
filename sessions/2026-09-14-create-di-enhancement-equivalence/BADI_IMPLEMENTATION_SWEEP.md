# Customer-enhancement implementation sweep — `LE_SHP_DELIVERY_PROC`

> **RECONCILED 2026-09-15.** Method-include coverage in this file was completed on
> 2026-09-15: every implementing class has **17** methods (`CM001`-`CM009` + `CM00A`-`CM00H`),
> confirmed by SE24 `RowCount` and by an exhaustive include probe. The REPOSRC census recorded
> here on 2026-09-14 was correct and is now fully backed by captured method bodies.
> See `CREATE_DI_ADDENDUM_2026-09-15_HEX_INCLUDES.md`.
>
> Evidence-class separation used across this session:
> **Verified source restriction** (a gate read in active code) /
> **Verified configuration behaviour** (a table or set read in QS4/700) /
> **Strong inference** (BAPI/OData reachability implied by source but not traced) /
> **Runtime unknown** (requires T0-T11, none executed).



**Date:** 2026-09-14
**System:** QS4, client 700, `vhresqs4ci` (verified in the status bar before each sequence)
**Mode:** Read-only. SE18 / SE24 / SE16 (REPOSRC) / SE38 display only. No Save, no Activate, no Change, no write of any kind.

**Evidence labels:** Verified · Strong inference · Hypothesis · Contradicted · Unknown

---

## 1. Implementation inventory (Phase 1) — Verified

`LE_SHP_DELIVERY_PROC` (spot = definition, migrated from classic BAdI; **Multiple Use**, not filter-dependent, context-specific instantiation, no fallback class) has **85 implementations**. Six are customer (software component `HOME`); all six are **active**.

| Enhancement implementation | BAdI implementation | Class | Active |
|---|---|---|---|
| ZEI_LE_DELIVERY_PROCESS | ZEI_LE_DELIVERY_PROCESS | ZCLLE_DELIVERY_PROCESS | Yes |
| ZENH_SHP_DELV_INTCO | ZLE_SHP_DELV_INTECO | ZCL_IM_LE_SHP_DELV_INTECO | Yes |
| ZLE_SHP_DELIVERY_PROC | ZLE_SHP_DELIVERY_PROC | ZCL_IM_LE_SHP_DELIVERY_PROC | Yes |
| ZSDEI_DELIVERY | ZSDEI_DELIVERY | ZCL_IM_SDEI_DELIVERY | Yes |
| ZSD_DELV_ATT_EHC | ZSD_DELV_ATT_ENHC | ZCL_IM_SD_DELV_ATT_ENHC | Yes |
| ZUCCSDE034_LIC_NOTIF | ZSDE034_LIC_NOTIF | ZCL_IM_SDE034_LIC_NOTIF | Yes |

The enhancement-implementation ↔ BAdI-implementation mapping supplied in the brief is **confirmed exactly** by the SE18 spot implementation list, including the three asymmetric names (`ZENH_SHP_DELV_INTCO`→`ZLE_SHP_DELV_INTECO`, `ZSD_DELV_ATT_EHC`→`ZSD_DELV_ATT_ENHC`, `ZUCCSDE034_LIC_NOTIF`→`ZSDE034_LIC_NOTIF`). No correction required.

`SHP_EXTEND_ODATA` / `SHP_EXTEND_ODATA` (S4CORE, application component **LE-SHP-API**) is present and **active** — preserved for Phase 7 source inspection. Not yet inspected.

## 2. Candidate non-empty method census (Phase 2) — screening result

Method bodies of a class are stored as class-pool includes `<CLASS padded to 30 with '='>CM<hex seq>`. An empty redefinition (`method X. endmethod.`) is often ~90–110 bytes. Querying **SE16 → REPOSRC** with `R3STATE = A` and `DATALG` between 200 and 9,999,999 is therefore a useful prioritisation technique, but it does **not** prove exact non-empty counts: a short active method can also be below 200 bytes. Reconcile every `CM###` include against the SE24 method list and open all sub-200-byte includes before calling the census complete.

Result (58 rows across the target classes; `CP`/`CT`/`CU` rows are class-pool technical includes, not methods):

| Class | Non-empty method includes | Count |
|---|---|---|
| ZCLLE_DELIVERY_PROCESS | CM002, CM008, CM00A, CM00B, CM00F, CM00G | **6** |
| ZCL_IM_LE_SHP_DELV_INTECO | CM001, CM009, CM00E, CM00F | **4** |
| ZCL_IM_LE_SHP_DELIVERY_PROC | CM001, CM002, CM00H | **3** |
| ZCL_IM_SDE034_LIC_NOTIF | CM008, CM00A | **2** |
| ZCL_IM_SDEI_DELIVERY | CM00E | **1** |
| **ZCL_IM_SD_DELV_ATT_ENHC** | **none** | **0** |
| ZCLLE_UPDATE_DELIVERY_CUSTOM | CM001 | 1 |
| ZCLLE_UPDATE_DELIVERY_CUSTOM1 | CM001 | 1 |

**Provisional count of method includes at or above 200 bytes across the six BAdI implementations: 16.** Plus 2 in the BAPI-extension classes. Exact active/non-empty counts remain pending inspection of the shorter includes.

### Candidate result — one implementation may be entirely inert

**Verified:** `ZSD_DELV_ATT_ENHC` / `ZCL_IM_SD_DELV_ATT_ENHC` returns **no `CM###` include at or above 200 bytes**. **Unknown:** whether every shorter method include is an empty stub. Do not exclude the implementation from Create DI equivalence analysis until all of its `CM###` includes are listed without the size filter and opened or otherwise source-compared.

**Caution on `CM###` ordering:** the sequence number reflects the order methods were redefined *in that class*, not a fixed interface order, and it differs between classes. Method identity must be read from the first line of each include, never inferred from the number.

## 3. Source-ownership reconciliation (Phase 6 / item 1)

**Verified — ownership of the `DELIVERY_FINAL_CHECK` body is confirmed, not contradicted.**
`ZCL_IM_LE_SHP_DELIVERY_PROC==CM001` opens as `METHOD if_ex_le_shp_delivery_proc~delivery_final_check.` and its opening block matches the previously supplied body: the `SY-TCODE = 'VL01N' OR 'VL02N'` guard, the `it_xlips` / `it_ylips` merge, the `DELETE ADJACENT DUPLICATES ... COMPARING matnr`, the `TVARVC` name `ZDEL_SPLIT` lookup on `vtweg,spart`, and message `ZSD 002 (E)` with `pruefung = '99'`. This independently corroborates `SRC-SID-20260914-01` — the file `methods for ZLE_SHP_DELIVERY_PROC.txt` does belong to BAdI implementation `ZLE_SHP_DELIVERY_PROC`.

**Available outside Downloads — not blocked.** The two bodies are present at:

- `C:\Users\sidmy\OneDrive\Desktop\METHODS for BADI - LE_SHP_DELIVERY_PROC.txt`
- `C:\Users\sidmy\OneDrive\Desktop\METHOD for ZENH_SHP_DELV_INTCO.txt`

Compare those files against the live classes. The census above is a useful matching key:

- A body containing **6** methods incl. `CHANGE_FIELD_ATTRIBUTES`, `DELIVERY_FINAL_CHECK`, `SAVE_DOCUMENT_PREPARE`-shaped code ⇒ `ZCLLE_DELIVERY_PROCESS` (`ZEI_LE_DELIVERY_PROCESS`).
- A body containing exactly **4** methods ⇒ `ZCL_IM_LE_SHP_DELV_INTECO` (`ZLE_SHP_DELV_INTECO`).
- A body containing exactly **3** methods ⇒ `ZCL_IM_LE_SHP_DELIVERY_PROC` (already bound).

## 4. Rules extracted so far

### `ZCL_IM_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` (ZLE_SHP_DELIVERY_PROC) — partial capture

- **Rule:** for a delivery whose first item's `VTWEG,SPART` combination is listed in TVARVC variable `ZDEL_SPLIT`, the delivery may not contain more than one distinct material. Violation raises `ZSD 002` type **E** with `pruefung = '99'`.
- **Trigger/guard:** `IF ( sy-tcode = 'VL01N' OR sy-tcode = 'VL02N' )` — wraps the whole block.
- **Inputs:** `IT_XLIPS`, `IT_YLIPS` (rows with `UPDKZ = 'D'` excluded), fields `POSNR`, `MATNR`, `VTWEG`, `SPART`, `VBELN`.
- **Config dependency:** TVARVC `ZDEL_SPLIT`; constant `lc_setname = 'ZSD_MFG_SHIPSKIP'` declared (a set name, used later in the uncaptured remainder).
- **Effect:** blocks processing (error message), does not change data.
- **Classification: `SCREEN-ONLY VERIFIED`** — explicit transaction-code restriction.
- **Coverage:** applies to Initial Create DI *via VL01N only*; the same rule cannot fire for an OData/BAPI request because `SY-TCODE` is not VL01N/VL02N there.
- **Not yet captured:** everything from the `Validations for Depo Automation` banner onward.

### `ZCLLE_DELIVERY_PROCESS~CHANGE_FIELD_ATTRIBUTES` (ZEI_LE_DELIVERY_PROCESS) — partial capture

- **Rule:** for delivery types `ZNL`, `ZNP`, `ZLF` and items whose material freight group `MFRGR` is in a configured list (`A0000001`, `A0000002`, `A0000003`, `A0000022…`), make `LIKP-BTGEW`, `LIKP-GEWEI`, `LIKP-NTGEW` and `LIPS-NTGEW` display-only (`input = 0`, still visible).
- **Trigger/guard:** `IF sy-tcode = 'VL02N' OR sy-tcode = 'VL01N'`.
- **Effect:** UI control only — appends to `CT_FIELD_ATTRIBUTES`. Changes no document data, blocks nothing.
- **Classification: `SCREEN-ONLY VERIFIED`** — transaction-code guard *and* dynpro field-attribute semantics.
- **Coverage:** weight-field protection is a VL01N/VL02N-only control. An API caller is not prevented from supplying these weights by this hook.

## 5. Open items

- **Unknown:** source of the remaining 14 method includes at or above 200 bytes (ZCLLE_DELIVERY_PROCESS CM008/CM00A/CM00B/CM00F/CM00G; ZCL_IM_LE_SHP_DELV_INTECO CM001/CM009/CM00E/CM00F; ZCL_IM_LE_SHP_DELIVERY_PROC CM002/CM00H; ZCL_IM_SDEI_DELIVERY CM00E; ZCL_IM_SDE034_LIC_NOTIF CM008/CM00A), plus whether any sub-200-byte includes contain active statements.
- **Unknown:** the uncaptured remainder of both methods above (viewport truncation; long lines cut at the right edge).
- **Unknown:** `SHP_EXTEND_ODATA` (Phase 7) — not yet opened.
- **Partially resolved 2026-09-15:** Siddharth supplied the body of `ZLEF_DELIVERY_VALIDATONS`; its normalized capture and rule extraction are now in `source-captures/` and `FINDINGS.md` (`SRC-SID-20260915-03`). `FORM UPDATE_LOG`, text symbols `E01`–`E11`, a byte-for-byte SAP export and other callers remain open. The other called Z objects (`ZCLSG_ABAP_UTILITIES=>CHECK_TVARVC_VALUES` / `CHECK_SET_VALUE`, `ZSDF_FETCH_PROCESS_ORDER`, `ZOTC_SHIPMENT_SCD_DELETE`, `ZM_KREDA_CDS`) remain unknown.
- **Unknown:** the two BAPI-extension classes' single methods (Phase 5).

## 6. Session-state note

The VL01N session that held the unsaved delivery (QS4 session 2) has since been navigated to SE37 by the user. **The unsaved delivery is no longer on screen.** Phase 9's class-specific non-writing runtime sweep will need the delivery re-staged before it can run. No action was taken by this agent against that session.
