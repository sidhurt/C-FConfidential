# PGI scope sweep: findings

**Date:** 2026-09-18
**System:** QS4 / 700, user `QNOVATE8`, SAP GUI scripting
**Posture:** read-only throughout. Nothing was posted, created, changed, activated or saved.
The SAP interactions were SE16 display, SE38 display and the Enhancement Editor in display
mode.
**Status:** Priorities 1 and 3 answered. Priority 2 partly done. Priority 4 partly done.
Priorities 5 and 6 not run.

**Framing, set by Siddharth mid-session:** custom service development is out of scope.
Research is aimed at **how the standard service works**. Client enhancements matter only
where the standard call has to pass them or live with them. See "Standard-first view".

---

## Headline

1. **The standard OData delivery API runs the client's delivery save code. Verified.**
   Create DI on 21.08.2026 (`API_OUTBOUND_DELIVERY_SRV;v=2`, delivery `9004953174`)
   triggered the unguarded client plug-in `ZEI_LE_UPDATE_DELIVERY_HEAD` in `SAPMV50A`
   `USEREXIT_SAVE_DOCUMENT`. It created **and released** process order `003004365654`.
2. **That Create DI test left a live, released process order in QS4** that nobody knew about.
   It needs to go to the functional owner.
3. **The client's business rules come along with the standard API.** They don't need
   rebuilding the way the Submit MIGO rules do. For PGI this is good news: the standard call
   inherits them.
4. **No coded "shipment before PGI" rule was found.** `ZSD_SHIP_CHECK` is a GSTIN check.
5. **The `LIKP-ZZ*` transport fields cannot be carried by the standard delivery API.** This
   matters for **Modify DI**, not for PGI. See "Modify DI".

---

## Priority 3: the decisive experiment (answered)

### The prescribed test could not decide

`ZCLLE_UPDATE_DELIVERY_CUSTOM1` (`BADI_DLV_CREATE_STO_EXTIN`) has one method,
`additional_input`. It copies `IT_EXTENSION_IN` values into `ZZLRGRNO`, `ZZLRGRDATE`,
`ZZVEHICLE_NO`, `ZZDRIVER_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB`, `ZZPARTNER` and `ZZVHCLTYP`.
It has no guard and does nothing else (`src/ZCLLE_UPDATE_DELIVERY_CUSTOM1=CM001.txt`). The
21.08 OData request sent no extension data, so the loop had nothing to process whether or not
the BAdI was called. Every `ZZ*` field on `9004953174` is blank (`evidence/E1_LIKP_9004953174.txt`).
**Verdict: inconclusive by construction.**

Two secondary tests were also inconclusive:

- **`LIKP-TRATY`.** It is blank on `9004953174`, but so is `EKPO-EVERS` on STO
  `5600084209/00010`, and `ZLETSHIPMAP` has no blank key (`P3_EKPO_5600084209.txt`,
  `P3_ZLETSHIPMAP_ALL.txt`). A blank result was expected either way.
- **YSTO check.** Freight group `A0000001` is in set `ZSD_MFG_YSTO`, so the check passes
  either way (`E2_LIPS_9004953174.txt`, `P3_SETLEAF_ZSD_MFG_YSTO.txt`).

### The test that decided it: the ILMS process order

`ZEI_LE_UPDATE_DELIVERY_HEAD` (id 3) sits at the end of `USEREXIT_SAVE_DOCUMENT` with no
guard. It calls `ZLEF_ILMS_CREATE_PROCORD` `DESTINATION 'NONE'` (`src/MV50AFZ1.txt`). That FM
(`src/LZLEGILMSTOKENU26.txt`) works as follows:

- For each item with `MFRGR` `A0000001` or `A0000022`, where the plant is not excluded in
  `ZGPT_SD_PARAM` and no `AFPO` row already has `ABLAD` = the delivery number…
- …it calls `BAPI_PROCORD_CREATE`: order type `ZPFG`, version `FG01`, quantity = `LFIMG`,
  `unloading_point` = delivery number. Then it calls `BAPI_PROCORD_RELEASE`.

`9004953174/000010` has `MFRGR = A0000001` at plant 1002. **Result:**

| Read | Value | Evidence |
|---|---|---|
| `AFPO` | `AUFNR 003004365654`, `DWERK 1002`, `DAUAT ZPFG`, `VERID FG01`, `PSMNG 1 TO`, **`ABLAD 9004953174`** | `P3_AFPO_003004365654.txt`, `P3_AFPO_MATNR_15000177_AUFNR_3004365590-3004365835.txt` |
| `AUFK` | `ERNAM QNOVATE8`, `ERDAT 21.08.2026`, **`ERFZEIT 17:09:07`** (delivery `ERZET 17:09:06`), `KTEXT FG Packing` | `P3_AUFK_003004365654.txt` |
| `JEST` | `I0002` (REL) active, `I0001` (CRTD) inactive | `P3_JEST_OR003004365654.txt` |

**Verified:** the OData Create DI executed `SAPMV50A` `USEREXIT_SAVE_DOCUMENT`, including
unguarded client code. **Verified:** it left a released process order.

The same mechanism is active across plants. `ZPFG` orders carry recent delivery numbers in
`ABLAD`, including plant 1002 (`P3_AFPO_*` windows).

`AFPO` could only be filtered on material and `AUFNR` (`ABLAD` is not a selectable field
here), so it was searched in `AUFNR` windows until one returned fewer than 200 rows. The
windows are in the evidence folder.

**Changes to `DELIVERY_GI_ENHANCEMENT_FINDINGS.md`:**

- It called it a "strong inference" that `…CUSTOM1` fired. That is downgraded: its effect is
  impossible without extension data.
- Its "Layer 4 reachability is not determinable" is now **answered** for the save exits:
  they are reached.

---

## Priority 1: the 13 transaction-layer plug-ins

Positions come from `ENHINCINX` (`evidence/A3_*`). Guards come from active source (`src/`).

| Enhancement | Routine | Guard | Effect |
|---|---|---|---|
| `ZEI_LE_UPDATE_DELIVERY_HEAD` (2) | `USEREXIT_MOVE_FIELD_TO_LIPS` end | none | Sets `LIKP-TRATY` from `ZLETSHIPMAP` by `EKPO-EVERS` |
| `ZEI_LE_UPDATE_DELIVERY_HEAD` (3) | `USEREXIT_SAVE_DOCUMENT` end | none | **ILMS process order create and release** (above) |
| `ZEI_LE_VALIDATE_YSTO` | `USEREXIT_SAVE_DOCUMENT` end | none; `ZNL` only | Error `ZLE 182` if `MFRGR` is not in `ZSD_MFG_YSTO` and there is no valued `YSTO` condition |
| `ZEI_SD_CHANGE_CALC_TPE` | `PREISFINDUNG_GESAMT` end | none | Re-runs `PRICING_COMPLETE` with type `C` |
| `ZEI_LE_VALIDATE_TRANSPOTER` | `USEREXIT_SAVE_DOCUMENT` end | `VL02N` | Transporter-change authority check |
| `ZZCRM_DI_SEND` | `USEREXIT_SAVE_DOCUMENT` end | VL01N/VL02N/VL03N/ZLE020/ZSD094 | `SUBMIT zcrm_delivery_send` |
| `ZZ_LE_BIDDING_QTY` | nested in `ZZCRM_DI_SEND` | `VL02N` and TVARVC flag | Bidding quantity include |
| `ZEI_SD_UPDATE_DELBILLINGTYPE` | `USEREXIT_SAVE_DOCUMENT_PREPARE` begin | VL01N/VL02N or memory `ZLV_DEL_IND`; `ZRMC`/`ZRM2` only | Billing type, pickup-code and batch-quantity checks |
| `ZSD_SHIP_CHECK` | `USEREXIT_SAVE_DOCUMENT_PREPARE` begin | VL01N/VL02N | **GSTIN-inactive check** on the sold-to. No shipment logic |
| `ZSD_DEL_SAVE_CHECK` | `USEREXIT_SAVE_DOCUMENT_PREPARE` end | VL01N/VL02N/VL03N and date | Blocks EWM storage locations |
| `ZEI_LE_ADD_CHECK_BUTTON_HEAD` | `CUA_SETZEN` end | `VL02N`, screen 1000 | PF-status. Dialog only |
| `ZEI_LE_ADD_CHECK_BUTTON_PAI` | `FCODE_BEARBEITEN` begin | `VL02N` and fcode `CHECK` | `ZLEF_DELIVERY_VALIDATONS`. Dialog only |
| `ZSDENH_CLEAR_SHIPPING_DATA` | `SAPFV50C` `DATEN_KOPIEREN_002` end | tcodes or memory `ZTOKEN`; `ZLF`/`ZNP` only | Clears `SDABW`/`TRATY` |
| `ZSD_RESTRICT_GRN` | **no `ENHINCINX` row**, no block in active source | — | Strong inference: no active code position |

**Strong inference:** the `sy-tcode`-guarded plug-ins don't fire for an OData caller. The
save exits run (Verified above), but a Gateway request doesn't carry `VL0xN`.
`sy-tcode` under a Gateway request was not captured.

**Verified:** there are no `Y*` plug-ins on `SAPMV50A` or `LE_SHP_DELIVERY_PROC`. This is not
the full `Y*` sweep.

---

## Priority 2: class source (partial)

The implementing classes are resolved (`evidence/P2_BADI_IMPL_*.txt`). The previously
unnamed ones are `ZCL_IM_SD_DELV_ATT_ENHC` and `ZCL_IM_SDE034_LIC_NOTIF`. The two
`ES_SAPLV50I_BADI` implementations sit on the `EXTENSION_IN` BAdIs
`BADI_DLV_CREATE_STO_EXTIN` and `BADI_DLV_CREATE_SLS_EXTIN`.

Source has been read only for `ZCLLE_UPDATE_DELIVERY_CUSTOM1`. Method includes for the other
seven are enumerated in `P2_REPOSRC_*.txt`. They were **deliberately not read further**,
under the standard-first framing: they would only matter if a standard PGI call failed on
them.

Change dates of note: `ZCL_IM_LE_SHP_DELIVERY_PROC=CM001` was changed 21.08.2026 13:23 by
`SEHAJTECH`, the day of Create DI. Delivery-processing code is changing actively in QS4.

---

## Priority 4: shipment dependency (partial)

`LIKP` for this user exposes only `VBELN`, a date field and one other field for selection.
Filtering on `LFART`/`WBSTK` would need an SE16 personalisation change, which was not made.
Instead, the deliveries created on 10.08.2026 were sampled (200, capped; filter confirmed) and
filtered locally (`B1_LIKP_ERDAT_10.08.2026.txt`).

`VTTP` was checked with `txtI3` = `VBELN`. A positive control returned exactly one row
(`B1_VTTP_control_9003512710.txt`). All **47** goods-issued `ZNL` deliveries in the sample
have a shipment (`B1_VTTP_9004944*.txt`).

**Result:** no counter-example. This does **not** show that PGI requires a shipment. It shows
that in this sample, practice always includes one. Non-`ZNL` types (`ZLF`, `ZNP`, `ZRMC`, `EL`
in the same sample) were not checked.

---

## Priorities 5 and 6: not run

Settlement gating, storage-location determination (`T184L`), `TVLP`/`TVLK`, completed `ZNL`
line structure, `MSEG`/`VBFA`, the full `Y*` sweep, and `MCHB` batch candidates.

---

## Standard-first view of Create PGI

For PGI through `API_OUTBOUND_DELIVERY_SRV` (`PostGoodsIssue`) on `9004953174`:

| Question | Position |
|---|---|
| Do the client's rules run? | Yes. The save exits are reached (Verified on create; Strong inference for PGI, which uses the same delivery save) |
| Will the unguarded `ZNL` YSTO check block it? | No. `A0000001` is exempt (Verified) |
| Will the ILMS hook duplicate the process order? | No. It checks `AFPO-ABLAD` first, and an order exists (Verified in source) |
| Is a shipment coded as a prerequisite? | None found (Verified for the plug-ins read) |
| What blocks PGI today? | Picking mechanics: no storage location, batch or picked quantity on the item |

**Next, standard-first:** item-category picking relevance (`TVLP`), storage-location
determination (`T184L`, plant 1002), batches with stock (`MCHB`), and the line structure of
completed `ZNL` deliveries. These settle which standard actions (`PickAndBatchSplitOneItem`,
`PostGoodsIssue`) the caller needs and what it must send.

**For the functional owner:** process order `003004365654` (released, `ABLAD 9004953174`)
was created as a side effect of the 21.08 Create DI test. Every API-created delivery with
freight group `A0000001`/`A0000022` will do the same. That is the client's intended behaviour,
but it needs to be known and owned.

---

## Modify DI (raised in session; out of this sweep's scope)

The SD consultant confirmed that a **Modify DI** API is needed: what VL02N does for them.

- The `ZZ*` transport fields (`ZZVEHICLE_NO`, `ZZLRGRNO`, `ZZLRGRDATE`, `ZZDRIVER_NAME`, …)
  are customer fields appended to the **standard table `LIKP`**. The append-structure name
  has not been read.
- They are **entered, not derived**. On create, the STO BAdI passes through whatever the
  caller supplies. No save exit fills them.
- In the 10.08.2026 sample, `ZZVEHICLE_NO` is filled on 99 of 200 deliveries and `TRAID` on
  **0**. `ZZLRGRNO` is filled on 4, `BOLNR` on **0**. The business uses the `ZZ` fields only;
  there is no existing mapping to standard fields.
- `API_OUTBOUND_DELIVERY_SRV` metadata (captured from **DS4**,
  `sessions/2026-08-18-runtime-certification/evidence/META_API_OUTBOUND_DELIVERY_V2_response.xml`)
  shows the following:
  - it has **no `ZZ` properties**;
  - the header accepts updates to `BillOfLading`, `MeansOfTransport`, `MeansOfTransportType`,
    dates and weights;
  - items accept `Batch`, `StorageLocation` and quantities;
  - **`A_OutbDeliveryPartner` is not updatable**, so the transporter (`SP`) cannot be changed
    through it.
- The Gateway validates payload properties against metadata, so sending `ZZ` values in the
  body would be rejected (Strong inference; not tested, because it is a write attempt).

Standard options:

1. carry the values in the standard fields (consumers of the `ZZ` fields have to switch);
2. keep the `ZZ` fields in VL02N, outside the API;
3. key-user Custom Fields and Logic, if enabled for this API (creates new fields, not the
   `ZZ` ones).

Otherwise the fields need an extension. The Submit MIGO team has just shown a pattern for
that; see `sessions/2026-09-18-submit-migo-header-fields/FINDINGS.md`.

**Question for the SD consultant:** must the portal write these exact `ZZ` fields, can the
same information go into standard fields, or can it stay in VL02N? And can the transporter
change after DI creation?

---

## Could not determine

| Item | Why |
|---|---|
| `sy-tcode` under a Gateway request | Needs a debugged live request |
| PGI-specific save path (`WS_DELIVERY_UPDATE_2` → `delivery_save` → `SAPMV50A`) | `LV50SU16` is captured, but the form include holding `delivery_save` was not read |
| Bodies of the `LE_SHP_DELIVERY_PROC` and `SLS_EXTIN` classes | Parked under the standard-first framing |
| `ZSD_RESTRICT_GRN` state | `ENHHEADER` not re-read |
| Priorities 5 and 6, non-`ZNL` shipment check | Not run |

---

## Session events

- **The QS4 GUI connection dropped** mid-sweep (`Connections=0`) while listing `EKPO` fields.
  Siddharth re-logged in and the sweep resumed. No partial evidence from that call exists.
- **Two unfiltered reads were caught and discarded** (`TFDIR` and `JEST`, where the first
  field is `ctxt`, not `txt`; `SELFIELD_ERR` in the output). Both were re-run with the correct
  id. No retained evidence file carries `SELFIELD_ERR`.
- **One lookup navigated the user's session** away from an SE16N `T001W` display. Nothing was
  changed.

## Tooling added (all QS4/700-guarded, all read-only)

- `scripts/qs4_grab_se38_source.vbs`: a guarded copy of
  `outputs/sap-gui-script/grab-se38-source.vbs`. It replaces index-based session lookup with
  the QS4/700 guard and accepts only SE38's "Choose Program for …" chooser.
- `scripts/grab.ps1`: clipboard capture driver.
- `scripts/qs4_find_shells.vbs`: lists GuiShell controls on the current screen.
- `scripts/qs4_read_grid.vbs`: dumps a GridView's cells.
- `scripts/qs4_cancel_named_modal.vbs`: presses F12 only on a modal whose title matches
  exactly. Used once.

Enhancement includes (`…====E`) open in the Enhancement Editor, not a text control. Their
active blocks were captured from the host include (for example `MV50AFZ1`), which shows them
inline. `qs4_se16_read.vbs` prints `SELFIELD|` lines, not `FILTER|`; they serve the same
purpose.
