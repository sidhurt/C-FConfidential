# Create DI validation matrix — source and configuration certified

**System:** QS4 client 700 (verified before every automated action), user QNOVATE8
**Date:** 2026-09-15
**Method:** SAP GUI Scripting, read-only. SE38 source display, SE16 display, SE18 lookup.
**Writes:** none. No delivery created or changed, no BAPI executed, no commit, no OData call.
**Editor setting** was temporarily switched to Text-Based Editor to make source scriptable, then
restored and verified — see `EDITOR_SETTING_BASELINE.md`.

**Amended 2026-09-15** — read with `CREATE_DI_ADDENDUM_2026-09-15_HEX_INCLUDES.md`, which
corrects a completeness error and adds rule V12 plus derivations D1–D3.

**Runtime status:** every VL01N / BAPI / OData column below is **Not yet tested**. Runtime tests
are staged in `RUNTIME_TEST_PLAN.md` and await per-case approval.

Evidence: `source-captures/2026-09-15-QS4-scripted/` — complete active method bodies and
configuration table dumps.

---

## Where the rules actually live

> **SUPERSEDED on 2026-09-15.** An earlier version of this section claimed each class has
> "exactly nine methods" and that the capture was complete. That was wrong — method includes
> continue `CM00A`–`CM00H` after `CM009`. See
> `CREATE_DI_ADDENDUM_2026-09-15_HEX_INCLUDES.md`.

Six BAdI implementations are active on `LE_SHP_DELIVERY_PROC`. Each implementing class has
**17** method includes: `CM001`–`CM009` plus `CM00A`–`CM00H`. Confirmed two ways — SE24
Methods tab `RowCount` = 17, and an include probe covering `CM001`–`CM009`, `CM00A`–`CM00Z`
and `CM010`–`CM025`. The table below covers rules in the first nine; rules and derivations in
`CM00A`–`CM00H` are in the addendum.

| Implementation | Class | Active initial-Create-DI content |
|---|---|---|
| `ZEI_LE_DELIVERY_PROCESS` | `ZCLLE_DELIVERY_PROCESS` | `DELIVERY_FINAL_CHECK` — V03, V07, V08, V09a, V09b |
| `ZLE_SHP_DELIVERY_PROC` | `ZCL_IM_LE_SHP_DELIVERY_PROC` | `DELIVERY_FINAL_CHECK` — V01, V02, V04, V05, V06, V10 |
| `ZLE_SHP_DELV_INTECO` | `ZCL_IM_LE_SHP_DELV_INTECO` | ZRMC/ZRM2/EL only — **out of scope** |
| `ZSDEI_DELIVERY` | `ZCL_IM_SDEI_DELIVERY` | **Correction:** `CM00E` `CHANGE_DELIVERY_HEADER` is active (ZRMC/ZRM2, out of scope). Not empty. |
| `ZSD_DELV_ATT_ENHC` | `ZCL_IM_SD_DELV_ATT_ENHC` | **None — all 17 methods empty** (verified by body) |
| `ZSDE034_LIC_NOTIF` | `ZCL_IM_SDE034_LIC_NOTIF` | `DELIVERY_FINAL_CHECK` informational; **`SAVE_DOCUMENT_PREPARE` (`CM00A`) holds rule V12** — see addendum |

`ZCL_IM_LE_SHP_DELIVERY_PROC~SAVE_DOCUMENT_PREPARE` is **entirely commented out** — verified by
reading the body, not by size. It holds the VL09 shipment-deletion logic in commented form.

Both BAPI extension classes (`ZCLLE_UPDATE_DELIVERY_CUSTOM` and `...CUSTOM1`) have exactly one
method, `ADDITIONAL_INPUT`, which maps `EXTENSION_IN` fields only. No validation. Confirmed.

---

## Validation matrix

Path column legend. **Code-open** = no transaction-code gate in source, so the rule is reachable
on any path *if* the method is called and the fields are populated. **Screen-gated** = source
requires a specific `SY-TCODE`. **Config-dead** = cannot fire in QS4 today because the
configuration it depends on is absent or holds no qualifying value.

| ID | Requirement | Class / method | Applicability conditions | VL01N | BAPI STO | BAPI SLS | OData STO | OData SLS | Required fields | Message | Classification |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **V01** | One distinct material per configured delivery | `ZCL_IM_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | `SY-TCODE = VL01N/VL02N` AND TVARVC `ZDEL_SPLIT` contains `<VTWEG>,<SPART>`. Configured: `10,10` `20,10` `20,16` | Screen-gated, applies | **cannot apply** | **cannot apply** | **cannot apply** | **cannot apply** | `LIPS-VTWEG`, `LIPS-SPART`, `LIPS-MATNR` | `ZSD 002` + TEXT-E01 | **Verified screen-only** (source) |
| **V02** | One storage location per depot delivery | same | `SY-TCODE = VL01N/VL02N` AND `KNA1-KDKG1 = A2` for customer `P<LIPS-WERKS>` | Screen-gated, applies | **cannot apply** | **cannot apply** | **cannot apply** | **cannot apply** | `LIPS-WERKS`, `LIPS-LGORT`, `LIPS-UECHA` | `00 398` + TEXT-E02 | **Verified screen-only** (source) |
| **V03** | SLoc + SPI combination permitted for depot | `ZCLLE_DELIVERY_PROCESS~DELIVERY_FINAL_CHECK` | **No tcode gate, no `IF_TRTYP` gate.** `KDKG1=A2` on `P<LIPS-WERKS>`; `LIPS-LGORT` not initial; bypass only if `LIKP-LFART` in `ZSDN, ZRMC, ZRM2` | Code-open | Code-open | Code-open | Code-open | Code-open | `LIPS-LGORT`, `LIKP-SDABW`, `LIKP-LFART` | `ZLE 104` | **Strong inference — hard blocker risk** |
| **V04** | Route must have current overweight configuration | `ZCL_IM_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | **No tcode gate AND no `IF_TRTYP` gate** — runs on every call. Gate is a `ZTA_PMD_VALID` row for the **first item's** `WERKS/MFRGR/VTWEG` | Code-open | Code-open | Code-open | Code-open | Code-open | `LIPS-WERKS`, `LIPS-MFRGR`, `LIPS-VTWEG`, `LIKP-ROUTE` | `ZLE 210` | **Strong inference** |
| **V05** | Delivery qty within vehicle/load capacity | same | Same gate as V04, then current `ZLET_ROUTE_OVRWT` row feeds `ZTA_WHEELER_WGHT` `MAX(ZTOWEIGHT)` by `MFRGR` + `ZZLOAD_TYPE` | Code-open | Code-open | Code-open | Code-open | Code-open | `LIPS-LFIMG` (**first item only**), `LIPS-MFRGR` | `ZLE 208` | **Strong inference** |
| **V06a** | Route overweight config completeness | same | `IF_TRTYP` in B/H/V; `LIKP-ERDAT >= 20250823`; every item must match `ZTA_PMD_VALID` | Code-open | Code-open | Code-open | Code-open | Code-open | `LIKP-ROUTE`, `LIKP-ERDAT` | `ZLE 079` no row / `ZLE 078` blank ZOVERWT | **Strong inference.** `ZLE 078` is **config-dead** — no blank `ZOVERWT` in 86 rows |
| **V06b** | Qty within freight-pricing scale when overweight prohibited | same | Same gate, then `ASSIGN ('(SAPMV50A)TKOMV[]')`, condition `KAPPL=F`/`KSCHL=ZFB0` to `KONM-KSTBM`, plant `KDKG1=A1`, and route `ZOVERWT = 'No'` | **Config-dead** | **Config-dead** | **Config-dead** | **Config-dead** | **Config-dead** | `(SAPMV50A)TKOMV[]`, `ZFB0`, `LIPS-LFIMG` | `ZLE 077` | **Verified config-dead in QS4** — `ZOVERWT` holds only `PL`/`CL`, never `No` |
| **V07** | Blocked sales order must not be delivered | `ZCLLE_DELIVERY_PROCESS~DELIVERY_FINAL_CHECK` | `IF_TRTYP` in B/H/V AND `LIKP-ZZVBELN` not initial. Blocks on `VBAK-CMGST=B`, non-blank `LIFSK`, or non-blank `FAKSK` | Code-open | Code-open | Code-open | Code-open | Code-open | **`LIKP-ZZVBELN`** | `ZLE 088` | **Strong inference — silent-skip risk** |
| **V08** | Cumulative qty must not exceed sales-order qty | same | `IF_TRTYP` in B/H/V AND `LIKP-ZZVBELN` not initial. Sums `LIPS-LFIMG` across all deliveries sharing `ZZVBELN` against `SUM(VBAP-KWMENG)` | Code-open | Code-open | Code-open | Code-open | Code-open | **`LIKP-ZZVBELN`**, `LIPS-LFIMG` | `ZLE 087` | **Strong inference — silent-skip risk** |
| **V09a** | FTB self-transporter prohibited | same | `IF_TRTYP` in B/H/V; `KDKG1=A2` on `P<LIPS-WERKS>`; `LIKP-INCO1=FTB`; partner `PARVW=SP` with `LIFNR`; `LIKP-ERDAT >= 20250901`; vendor in `ZLE_SELF_TRANSPORTER` | Code-open | Code-open | Code-open | Code-open | Code-open | `LIKP-INCO1`, `VBPA PARVW=SP`, `LIKP-ERDAT` | `ZLE 205` | **Strong inference — silent-skip risk** |
| **V09b** | Depot transporter must be assigned to shipping point | same | `IF_TRTYP` in B/H/V; `LIKP-ERDAT >= 20251015`; partner `PARVW=SP`; `KDKG1=A2` on **`P<LIKP-VSTEL>`**; vendor must exist in `ZM_KREDA_CDS` for that pseudo-customer | Code-open | Code-open | Code-open | Code-open | Code-open | `LIKP-VSTEL`, `VBPA PARVW=SP` | `ZLE 207` | **Strong inference — silent-skip risk** |
| **V10** | Primary-plant SPI behaviour | `ZCL_IM_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | `IF_TRTYP` in B/H/V, not PGI; returns early if `LIKP-SDABW(2) = NC`; item `MFRGR` not blank; plant `KDKG1=A1` via `T001W-KUNNR`; `MFRGR` in set `ZSPIWERKS` | **Config-dead** | **Config-dead** | **Config-dead** | **Config-dead** | **Config-dead** | `LIKP-SDABW`, `LIPS-MFRGR`, `LIPS-WERKS` | `ZLE 187` | **Verified config-dead in QS4** — set `ZSPIWERKS` absent from `SETLEAF` and `SETHEADER` |
| **V11** *(new)* | ZNL delivery needs a YSTO freight condition | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT` / enhancement `ZEI_LE_VALIDATE_YSTO` | **No tcode gate.** `LIKP-LFART = ZNL` only. For each non-deleted, non-batch-split item whose `MFRGR` is **not** in set `ZSD_MFG_YSTO`, a `TKOMV` entry `KSCHL=YSTO` with non-initial `KBETR` is required | Code-open | Code-open | Code-open | Code-open | Code-open | `LIPS-MFRGR`, `TKOMV` | `ZLE 182` (hard `MESSAGE E`) | **Strong inference.** Near-dead by config — `ZSD_MFG_YSTO` covers `A0000001`–`A0000022`; **fires only for blank or uncovered `MFRGR`** |

### Rules confirmed out of initial-Create-DI scope

| Rule | Location | Why excluded |
|---|---|---|
| Deletion authorisation `ZSD 013` | `ZCL_IM_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | Only when `UPDKZ=D` |
| Token qty/deletion `ZLE 099/100` | `ZCLLE_DELIVERY_PROCESS~DELIVERY_FINAL_CHECK` | `SY-TCODE = VL02N/VL03N` |
| Shipment and shipment-cost before PGI | `ZCL_IM_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | PGI triggers only |
| `ZEI_LE_VALIDATE_TRANSPOTER` (`ZLE 181`) | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT` | `SY-TCODE = VL02N` |
| `ZSD_SHIP_CHECK` (GSTIN inactive) | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT_PREPARE` | `SY-TCODE = VL01N/VL02N` — **screen-only** |
| `ZSD_DEL_SAVE_CHECK` (EWM SLoc) | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT_PREPARE` | `SY-TCODE = VL01N/VL02N/VL03N` — **screen-only** |
| `ZSD_RESTRICT_GRN` | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT_PREPARE` | `SY-UCOMM = WABU/WABU_T` — PGI/PGR only |
| `ZEI_SD_UPDATE_DELBILLINGTYPE` | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT_PREPARE` | `ZRMC`/`ZRM2` only. **Note:** outer gate is `VL01N OR VL02N OR lv_del_ind = X`, where `lv_del_ind` is imported from memory ID `ZLV_DEL_IND` — a deliberate non-screen entry point |
| `ZZCRM_DI_SEND`, `ZZ_LE_BIDDING_QTY` | `MV50AFZ1` / `USEREXIT_SAVE_DOCUMENT` | Tcode-gated; side effects, not validations |
| `ZEI_LE_UPDATE_DELIVERY_HEAD` | `MV50AFZ1`, two enhancements | Derivation only — `LIKP-TRATY` from `ZLETSHIPMAP`, and a call to `ZLEF_ILMS_CREATE_PROCORD`. No validation |
| `ZSDE034_LIC_NOTIF` | `ZCL_IM_SDE034_LIC_NOTIF` | `msgty = I`, and gated by `ZGPT_SD_PARAM` on `SY-TCODE` and `LFART` |

**`SHP_EXTEND_ODATA` — corrected 2026-09-15.** It is a BAdI *implementation* of
`LE_SHP_DELIVERY_PROC` (class `CL_IM_SHP_EXTEND_ODATA`, per `SXC_CLASS`/`SXC_EXIT`), not a
definition or spot. It performs inbound OData extension-field mapping in
`SAVE_DOCUMENT_PREPARE` and contains no business validation. See addendum section 5.

---

## Configuration evidence

| Object | Content | Consequence |
|---|---|---|
| TVARVC `ZDEL_SPLIT` | `10,10` `20,10` `20,16` | V01 population |
| TVARVC `ZSD_PREREQ_DEL` | one entry, `ZSDN,ZRMC,ZRM2`, comma-split in code | **ZNL/ZLF/ZNP are not bypassed** from V03 |
| TVARVC `ZLE_WHEELER_FREIGHT` | `20250823` | V06 cutoff passed — block active |
| TVARVC `ZLE_HIRING_TRANS_DATE` | `20250901` | V09a active |
| TVARVC `ZLE_DEPOT_TRANSPORTER` | `20251015` | V09b active |
| TVARVC `ZLE_SELF_TRANSPORTER` | `0013000911`, `0013000912`, `0013000913` | V09a population |
| `ZTA_PMD_VALID` | 36 rows — plants **1000, 1005, 1012, 1045** × MFRGR `A0000001/A0000002/A0000022` × VTWEG `10/20/99` | Sole eligibility gate for V04–V06 |
| `KNA1` `P1000/P1005/P1012/P1045` | `KDKG1 = A1` for all four | Those four plants are **all Primary** |
| `ZLET_ROUTE_OVRWT` | 86 rows; `ZOVERWT` only `PL` or `CL`; none blank | `ZLE 077` and `ZLE 078` unreachable; `ZLE 079` and `ZLE 210` very reachable |
| `ZTA_WHEELER_WGHT` | 24 rows, `MFRGR` `A0000001` and `A0000022` only | **`A0000002` has no weight row** — V05 silently passes for it |
| `ZLETSPIMAP` | 23 rows of `LGORT` + `SDABW`; **no row has a blank `SDABW`** | V03 fails closed when `SDABW` is blank |
| Set `ZSPIWERKS` | **absent** from `SETLEAF` and `SETHEADER` | V10 cannot fire |
| Set `ZSD_MFG_YSTO` | 22 entries, `A0000001`–`A0000022` | V11 near-dead |
| Set `ZSD_MFG_SHIPSKIP` | 8 entries from `A0000015` | PGI exemption only |

---

## Corrections to the previous session's register

1. ~~`SAVE_AND_PUBLISH_BEFORE_OUTPUT` is not a method of `ZCL_IM_LE_SHP_DELIVERY_PROC`.~~
   **RETRACTED 2026-09-15.** It is include `CM00H`, active and non-empty. The 2026-09-14
   register's rule `ZLE-REV-01` was **correct**. Evidence:
   `source-captures/2026-09-15-QS4-scripted/ZCL_IM_LE_SHP_DELIVERY_PROC===CM00H.txt`.
2. The register flagged `SELECT COUNT( * ) ... IF sy-subrc = 0` as a possibly broken gate. It is
   **not** broken — `SELECT COUNT(*)` sets `SY-SUBRC = 0` only when at least one row matches. The
   `ZDEL_SPLIT` and `ZTA_PMD_VALID` gates work as intended.
3. V03/V07/V08/V09 were previously attributed to an unbound dump. They are now bound — all four
   live in `ZCLLE_DELIVERY_PROCESS` (`ZEI_LE_DELIVERY_PROCESS`), **not** `ZLE_SHP_DELIVERY_PROC`.
4. V04 was described as having "no transaction-code restriction". It is stronger than that — it
   has **no `IF_TRTYP` gate either**, so it executes on every `DELIVERY_FINAL_CHECK` call,
   including change and PGI.

## Code defects found (reported only, nothing changed)

1. **`LV_KSTBM_MAX` is never cleared per header** in the V06b loop; `CLEAR` covers only
   `LV_LFIMG`. If `READ TABLE lt_komv` fails for a later delivery, the previous delivery's maximum
   scale is reused. Latent cross-delivery contamination, currently masked because V06b is
   config-dead.
2. **Dead `IF` in V06b** — `IF sy-subrc EQ 0 AND lv_kstbm_max IS NOT INITIAL. ENDIF.` has an empty
   body, so the guarded logic was never written.
3. **V04/V05 evaluate only `it_xlips[ 1 ]`.** A multi-item delivery is weight-checked on its first
   item alone. `DATA(lw_lips) = it_xlips[ 1 ].` also sits outside any `TRY`, so an empty item table
   would raise an uncaught `CX_SY_ITAB_LINE_NOT_FOUND`.
4. **V03 loops `it_xlips` without excluding `UPDKZ = D`**, unlike every neighbouring rule, so
   deleted items are still SPI-validated.
5. **`lv_bypass_for_shortage_entry` is never reset** inside the V03 item loop.
6. Every rule in both `DELIVERY_FINAL_CHECK` implementations inserts **only while `CT_FINCHDEL` is
   initial**. The first error suppresses all later ones, so a negative test can prove only one rule
   at a time, and a real delivery may hide several faults behind a single message.
