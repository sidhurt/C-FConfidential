# VL01N screen-path BAdI runtime trace

**Date:** 2026-09-14
**System:** QS4, client 700, server `vhresqs4ci` (verified from the SAP status bar before every action)
**Transaction:** VL01N, unsaved Outbound Delivery (delivery number blank throughout)
**Test data:** Shipping Point 7683, Sales Order 0005270471 item 000010, Material 15000179, 2.660 TO
**Safety:** Read-only. Debugger configuration plus two non-writing triggers only. No Save, no Post Goods Issue, no BAPI, no commit, no rollback. The delivery was still unsaved at the end of the session.

## Headline answers

1. **`DELIVERY_FINAL_CHECK` did NOT execute during either non-writing trigger.** Neither a plain Enter (PAI round-trip) nor the Incompleteness check (Shift+F9) reached `ZCL_IM_LE_SHP_DELIVERY_PROC~IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK`.
   This is **inconclusive, not negative** — the method's own SAP short text is *"Last Checks Before Saving the Delivery"*, so a Save-only call is the expected behaviour. Proving it requires a Save, which was not performed.
2. **The `LE_SHP_DELIVERY_PROC` BAdI dispatcher is definitely live on the VL01N screen path** — three interface methods were caught being dispatched under transaction VL01N. The captured stacks do not by themselves identify which customer implementation classes executed for each method; class-specific breakpoints are still required for that.
3. **`ZLE_SHP_DELIVERY_PROC` is registered and active** in QS4/700 as an *enhancement implementation* (version A) on the migrated enhancement spot `LE_SHP_DELIVERY_PROC`.

## Method note: Ctrl+F2 is not bound in VL01N

The brief specified Ctrl+F2 (Check) as the trigger. The VL01N `Edit` menu offers only Pack (Shift+F6), Copy Pack/Picked Quantities (Shift+F7), Confirm Pick Order, Check Doc. Distribution (greyed), Dangerous Goods Check (greyed), Post Goods Issue (Shift+F8), Error Log (F9), **Incompleteness (Shift+F9)** and Cancel (F12). There is no Check function code. Two non-writing substitutes were used instead:

- **Enter** — full PAI/PBO round-trip through `SAPMV50A` screen 1000.
- **Shift+F9 Incompleteness** — the delivery incompletion check. Result: item 10, *"Batches / valuation types not completely allocated"* (General + Goods Movement).

## Breakpoint configuration

Set inside the debugger session attached to the VL01N session holding the unsaved delivery (`/h` then Enter, giving ABAP Debugger(2) `vhresqs4ci_QS4_00`):

| Type | Target | Purpose |
|---|---|---|
| ABAP Command | `GET BADI` | catch kernel BAdI dispatch |
| ABAP Command | `CALL BADI` | catch kernel BAdI invocation |
| Method | `CL_EXITHANDLER=>GET_INSTANCE` | catch classic BAdI dispatch |
| Method | `ZCL_IM_LE_SHP_DELIVERY_PROC=>IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | the target |

The two statement breakpoints were deleted part-way through, once the PBO field-attribute loop began repeating per subscreen. The two method breakpoints remain set as session breakpoints in that VL01N session.

## Observed hit list (VL01N screen path)

Ordered as encountered. `SY-TCODE = VL01N` throughout; stack bottom is `TRANSACTION VL01N(VL01N)` in every case.

| # | BAdI / interface / method | Calling program | Calling FORM / module | Stage | Classification |
|---|---|---|---|---|---|
| 1 | `BADI_MATN1` (`GET BADI g_badi_matn1_new`) | SAPLOMCV (`LOMCVF01`) | FORM `BADI_MATN1_CHECK_INIT` <- FUNCTION `CONVERSION_EXIT_MATN...` <- SAPCNVE `CONVERSION_EXIT` <- SAPMV50A `SYSTEM-EXIT` <- MODULE (PAI) `ILIPS_AENDERN` | PAI transport, field `LIPS-MATNR` line 1, subscreen 1102 | Unrelated — material number conversion exit |
| 2 | **`IF_EX_LE_SHP_DELIVERY_PROC~CHANGE_DELIVERY_HEADER`** | CL_EX_LE_SHP_DELIVERY_PROC | FORM `CALL_BADI_CHANGE_DELIVERY_HEADER` (SAPFV50K) <- `LIKP_AENDERN` <- `LIKP_BEARBEITEN` <- MODULE (PAI) `LIKP_BEARBEITEN` (SAPMV50A) | PAI screen 1000, header change | **Shared candidate** — header data change hook, also reachable by BAPI |
| 3 | `CL_EXITHANDLER=>GET_INSTANCE` | CL_EXITHANDLER | FUNCTION `WB2_BADI_ADD_DATA_INSTANCE_GET` <- `WB2_TRADE_GET_MASTER_DATA` <- `WB2_HANDLE_EXPENSE_I...` <- `WB2_PROCESS_DL_DATA...` <- METHOD `IF_EX_LE_SHP_DELIVERY_PROC~...` (**CL_IM_WB2_PROCESS_DL**) <- CL_EX_LE_SHP_DELIVERY_PROC <- `CALL_BADI_CHANGE_DEL...` | inside hit #2's dispatch | Standard SAP Global Trade implementation of the same BAdI |
| 4 | `WB2_BADI_ADD_DATA_INSTANCE_GET` / `WB2_TRADE_GET_MASTER_DATA` | SAPLWB2_BADI_SERVICE / SAPLWB2B_SCREEN_HANDLING | as above | inside hit #2's dispatch | Standard, trading-contract chain |
| 5 | **`BADI_LE_SHP_MODIFY_HEAD`** (cloud extensibility) | SAPMV50A (`MV50A_CLOUD_EXTENSIBILITY`) | FORM `BADI_LE_SHP_MODIFY_HEAD` <- `LIKP_AENDERN` <- `LIKP_BEARBEITEN` <- MODULE (PAI) `LIKP_BEARBEITEN` | PAI screen 1000, header modify | Shared candidate — cloud/key-user extensibility header hook |
| 6 | **`BADI_SD_COM_COUNTRY`** | SAPFV50P (`FV50PF0P_P_KOMK_KOMP_FUELLEN`) | FORM `BADI_SD_COM_COUNTRY` <- `P_KOMK_KOMP_FUELLEN` <- **`PREISFINDUNG_LIEFERUNG`** <- `POSITION_GEWICHTSUPDATE` <- MODULE (PAI) `FCODE_BEARBEITEN` (x2) | PAI screen 1000, delivery pricing | **Critical for the freight-scale rule** — see below |
| 7 | **`IF_EX_LE_SHP_DELIVERY_PROC~CHANGE_FCODE_ATTRIBUTES`** | CL_EX_LE_SHP_DELIVERY_PROC | FORM `CALL_BADI_CHANGE_FCODE_ATTRIBUTES` (SAPMV50A) <- `CUA_EXCLUDE_DYNAMIC` <- `CUA_SETZEN` <- MODULE (PBO) `INITIALISIEREN` | PBO screen 1000, CUA build | **Screen-related candidate** — SAP short text: *"Control Activation of Function Codes"* |
| 8 | **`SHP_BADI_CUA_FCODE_ALLOW`** | SAPMV50A (`MV50AF0C_CUA_FCODE_BADI`) | FORM `CUA_EXCLUDE_BADI` <- `CUA_EXCLUDE_DYNAMIC` <- `CUA_SETZEN` <- MODULE (PBO) `INITIALISIEREN` | PBO screen 1000, CUA build | **Screen-related candidate** — EhP4 fcode enable/disable |
| 9 | **`IF_EX_BADI_SD_SALES_BASIC~HEADER_STATUS`** | CL_EX_BADI_SD_SALES_BASIC | FORM `STATUS_KOPF` (SAPLV45P) <- FUNCTION `RV_XVBUK_MAINTAIN` <- FORM `XVBUK_PFLEGEN` (SAPFV50K) <- `LIKP_BEARBEITEN_VORBEREITEN` <- MODULE (PBO) `LIKP_BEARBEITEN_VOR` | PBO screen 1000, header status | Shared candidate — document status maintenance |
| 10 | **`IF_EX_LE_SHP_DELIVERY_PROC~CHANGE_FIELD_ATTRIBUTES`** | CL_EX_LE_SHP_DELIVERY_PROC | FORM `CALL_BADI_CHANGE_FIELD_ATTRIBUTES` (SAPMV50A) <- `FELDAUSWAHL` <- MODULE (PBO) `FELDAUSWAHL` | PBO subscreens **1502** and **1102** (repeats per subscreen) | **Screen-related candidate** — SAP short text: *"Control Input Attributes of Delivery Fields"* |
| 11 | `CL_EXITHANDLER=>GET_INSTANCE` | CL_EXITHANDLER | FUNCTION `REUSE_ALV_GRID_DISPLAY` <- FORM `XVBUV_DISPLAY` (SAPFV50U) <- `FCODE_UCSH` (SAPMV50A) <- `FCODE_BEARBEITEN` (SAPLV00F) <- FUNCTION `SCREEN_SEQUENCE_CONTROL` | **Shift+F9 Incompleteness** | ALV display BAdI; the incompletion check itself ran without reaching `DELIVERY_FINAL_CHECK` |

Hit #10's `CALL BADI l_badi->CHANGE_FIELD_ATTRIBUTES` signature was captured: `IS_LIKPD, IS_LIKP, IS_LIPSD, IS_LIPS, IT_YVBUP, IT_XVBUP, IT_YVBUK, IT_XVBUK, IT_YVBFA, IT_XVBFA, ...`

## `(SAPMV50A)TKOMV[]` — pricing runs on the screen path

Hit #6 places `PREISFINDUNG_LIEFERUNG` -> `P_KOMK_KOMP_FUELLEN` inside VL01N's PAI under `FCODE_BEARBEITEN`. That is the routine chain that fills the delivery pricing condition table. **Verified:** delivery pricing executes during ordinary VL01N screen processing, before any Save.

This matters because the freight-scale maximum-quantity rule in `ZLE_SHP_DELIVERY_PROC` depends on `(SAPMV50A)TKOMV[]`. `TKOMV` is a global of the **module pool SAPMV50A**. **Unknown on OData/BAPI:** a headless entry point does not prove that `SAPMV50A` is absent from the internal delivery-processing call chain, and source alone does not prove whether the dynamic assignment succeeds. The screen trace proves only that pricing runs and the module-pool context exists in VL01N. The actual `TKOMV[]` assignment and contents must be inspected at runtime in both the Save/BAPI paths before classifying `ZLE 077` as bypassed.

## Registry evidence (SE18, read-only)

**BAdI definition `LE_SHP_DELIVERY_PROC`** — package `LE_SHP_BADI`, short text *"Enhancements in Delivery Processing"*, generated class `CL_EX_LE_SHP_DELIVERY_PROC`, **Multiple Use**, not filter-dependent, **migrated to enhancement spot `LE_SHP_DELIVERY_PROC`** (context-specific instantiation, no fallback class).

**Enhancement implementations on the spot (all version A / active)** include: `ZLE_SHP_DELIVERY_PROC`, `ZENH_SHP_DELV_INTCO`, `ZSDEI_DELIVERY`, `WB2_PROCESS_DL`, `LE_SHP_ICO_VCM_INTEGRATION`, `/SAPSLL/PI_CON_DELV_PROC`, `/SAPSLL/PI_CUS_DELV_PROC`, `/SAPSLL/PI_RSK_DELV_PROC_CMS`, `EOM_CRM_ORD_NOTIF`, `MSR_TRC_DLV_CONTROLLER`, `/KJEDM/DELIVERY_PROC_EDM`, `SHP_OM1_SFWS_DELIVERY_PROC`, `SHP_SE_OUTPUT_CONTROL`, `CIN_SUS_INBDEL_ENHANCEMENT`, `O0_ECC_DELIVERY_PROC`, `FLOG_ENH_STO_OBD`, `LEINT_DELIVER_SAVE`, `EI_EDOCUMENT_GI_POSTING`, `BADI_DFS_DELIVERY`, `WMD_LE_SHP_DELIVERY_PROC`.

**Verified:** `ZLE_SHP_DELIVERY_PROC` is active in QS4/700. Its absence from the *classic* SE18 implementation list is expected for a migrated spot and is not evidence of inactivity.

**Reconciled with existing registry evidence:** `ZCLLE_DELIVERY_PROCESS` is not an unidentified second class inside `ZLE_SHP_DELIVERY_PROC`. It is already mapped to the separate active customer implementation `ZEI_LE_DELIVERY_PROCESS`. `ZCL_IM_LE_SHP_DELIVERY_PROC` belongs to active implementation `ZLE_SHP_DELIVERY_PROC`. Because this is a multiple-use BAdI, both implementations may participate in the same delivery event. The remaining unknown is the authoritative binding of the first supplied general method dump to `ZEI_LE_DELIVERY_PROCESS`, not the class's registered implementation or activation state.

**Relevant to the API path:** the spot also carries the SAP implementation **`SHP_EXTEND_ODATA` — *"Fill extension fields for OData APIs"***. Worth inspecting when the OData comparison is authorised.

## Classification so far

| BAdI / method | VL01N hit | OData SLS hit | OData STO hit | SY-TCODE | Classification |
|---|---|---|---|---|---|
| `LE_SHP_DELIVERY_PROC~CHANGE_DELIVERY_HEADER` interface dispatch | Yes (PAI) | not tested | not tested | VL01N | Shared candidate; customer-class hits not isolated |
| `LE_SHP_DELIVERY_PROC~CHANGE_FCODE_ATTRIBUTES` interface dispatch | Yes (PBO/CUA) | not tested | not tested | VL01N | Screen-related candidate; customer-class hits not isolated |
| `LE_SHP_DELIVERY_PROC~CHANGE_FIELD_ATTRIBUTES` interface dispatch | Yes (PBO/field select) | not tested | not tested | VL01N | Screen-related candidate; customer-class hits not isolated |
| `LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` | **No hit on Enter or Incompleteness** | not tested | not tested | n/a | **Unknown — likely Save-only** |
| `BADI_LE_SHP_MODIFY_HEAD` | Yes (PAI) | not tested | not tested | VL01N | Shared candidate |
| `SHP_BADI_CUA_FCODE_ALLOW` | Yes (PBO/CUA) | not tested | not tested | VL01N | Screen-related candidate |
| `BADI_SD_COM_COUNTRY` (via `PREISFINDUNG_LIEFERUNG`) | Yes (PAI) | not tested | not tested | VL01N | Shared candidate; pricing fills `TKOMV` |
| `BADI_SD_SALES_BASIC~HEADER_STATUS` | Yes (PBO) | not tested | not tested | VL01N | Shared candidate |
| `BADI_MATN1` | Yes (PAI conversion) | not tested | not tested | VL01N | Unrelated |

No entry qualifies as **screen-only verified** yet. Per the brief, that label requires either the API-path comparison or an explicit transaction/screen restriction in source. `CHANGE_FCODE_ATTRIBUTES`, `CHANGE_FIELD_ATTRIBUTES` and `SHP_BADI_CUA_FCODE_ALLOW` are strong candidates on semantics alone (CUA function codes and dynpro field attributes have no meaning without a dynpro), but that is inference, not a traced negative.

## Not done / blocked

- **Save-path proof of `DELIVERY_FINAL_CHECK`** — requires clicking Save. Not performed; awaiting explicit approval.
- **Runtime capture of `SY-UCOMM`, `SY-CPROG`, `IF_TRTYP`, `IT_XLIKP` (LFART/VSTEL/ROUTE/SDABW/ZZVBELN/UPDKZ), `IT_XLIPS` (POSNR/MATNR/WERKS/LGORT/MFRGR/LFIMG/VGBEL/VGPOS/UPDKZ/UECHA) and `(SAPMV50A)TKOMV[]`** — all require the target method to stop, i.e. a Save-time or BAPI-time break.
- **Phase 6 API/BAPI comparison** — not started. Requires explicit authorisation for a controlled write/rollback test.
- **Static read of `MV50AFZ1` and the customer PBO/PAI enhancements** — not performed in this session.
- **Source-body binding for `ZCLLE_DELIVERY_PROCESS` / `ZEI_LE_DELIVERY_PROCESS`** — open. Registry identity and active implementation state are already verified.

## State left behind

- VL01N session (QS4 session 2): delivery still **unsaved**, delivery number blank, data unchanged.
- Two method breakpoints (`CL_EXITHANDLER=>GET_INSTANCE`, `ZCL_IM_LE_SHP_DELIVERY_PROC~...~DELIVERY_FINAL_CHECK`) remain active as session breakpoints in that session. They will fire on the next VL01N action, including a Save.
- A second SAP session (QS4 session 5) is parked on SE18 display. Read-only.
