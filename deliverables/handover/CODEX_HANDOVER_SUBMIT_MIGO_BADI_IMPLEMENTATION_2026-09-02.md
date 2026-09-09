# Submit MIGO via BAdI on the standard service — implementation handover

**Date:** 2026-09-02 · **System:** QS4/700 · **Method:** read-only SE16/SE38 + SE37 test runs
**Audience:** Codex, or any agent/developer picking up the build.
**Nothing was posted. All SE37 runs used `TESTRUN = 'X'`.**

---

## Verdict

**The complete Submit MIGO requirement can be met through supported SAP extensibility, using the
standard OData service `API_MATERIAL_DOCUMENT_SRV` and BAdI implementations the customer already
owns. No custom service. No implicit enhancement. No modification. No access key.**

This reverses the earlier recommendation in
`LEGACY_SUBMIT_MIGO_BUILD_PROCESS_2026-09-02.md`, which concluded a custom wrapper was required.
That conclusion rested on an unverified assumption — that the BAdI on the BAPI runs too late to
influence the posting. It does not. Evidence below.

---

## The decisive evidence

### 1. Call sequence inside `BAPI_GOODSMVT_CREATE`

Source: `LMB_BUS2017U04` (function group `MB_BUS2017`, include 04), 762 lines.

| Line | Statement |
|---|---|
| 223 | `CALL FUNCTION 'MAP2I_B2017_GM_ITEM_TO_IMSEG'` — BAPI item → `IMSEG` |
| **546** | **`CALL BADI lo_mb_bapi_goodsmvt_create->extensionin_to_matdoc`** |
| **632** | **`PERFORM mb_create_goods_movement.`** ← document is built here |
| 635 | `PERFORM return_handling TABLES return.` |
| 640 | `CHECK f_testrun IS INITIAL.` |
| 643 | `PERFORM mb_post_goods_movement TABLES return` |

The BAdI runs **86 lines before** the goods movement is created. Only date-plausibility checks sit
between them. **Changes made to `ct_imseg` in the BAdI are honoured by the posting.**

### 2. BAdI signature

`IF_EX_MB_BAPI_GOODSMVT_CREATE~EXTENSIONIN_TO_MATDOC` (the interface has exactly one method):

| Parameter | Direction |
|---|---|
| `EXTENSION_IN` | importing |
| `CS_IMKPF` | **changing** — document header |
| `CT_IMSEG` | **changing** — document items |
| `CT_RETURN` | **changing** — messages back to the caller |

`CT_RETURN` being changing means validation errors raised here travel back through the BAPI to the
OData response. That covers the "meaningful SAP errors" requirement.

### 3. Field mapping, BAPI structure → `IMSEG`

Source: `LMB_BUS2017U17` (`MAP2I_B2017_GM_ITEM_TO_IMSEG`).

| `BAPI2017_GM_ITEM_CREATE` | `IMSEG` |
|---|---|
| `DELIV_NUMB` | `VBELN` |
| `DELIV_ITEM` | `POSNR` |
| `DELIV_NUMB_TO_SEARCH` | `VLIEF_AVIS` |
| `DELIV_ITEM_TO_SEARCH` | `VBELP_AVIS` |
| `PO_NUMBER` | `EBELN` |
| `PO_ITEM` | `EBELP` |

`MAP2I` is pure field movement — it raises no errors relevant to this path.

### 4. What the standard OData service sends for an outbound delivery

Source: `CL_MATERIAL_DOCUMENT_API======CM00V` (`MAP_ITEM_INPUT`), lines 34–48:

```abap
IF lo_delivery_handler->is_inbound_delivery( ).
  es_goodsmvt_item_input-deliv_numb_to_search = ir_item->delivery.
  es_goodsmvt_item_input-deliv_item_to_search = ir_item->deliveryitem.
ELSEIF lo_delivery_handler->is_outbound_delivery( ).
  es_goodsmvt_item_input-deliv_numb = ir_item->delivery.
  es_goodsmvt_item_input-deliv_item = ir_item->deliveryitem.
```

C&F uses **outbound** deliveries (`LIKP-VBTYP = 'J'`), so the service sets `DELIV_NUMB`/`DELIV_ITEM`
only. These reach the BAdI as `IMSEG-VBELN` / `IMSEG-POSNR`.

**Consequence:** the BAdI receives the delivery number and item, and can derive everything else.

### 5. Why the standard service fails today, unaided

SE37 test run, delivery `9004952595` item `000010`, plant `1005`, movement `101`, `MVT_IND='B'`,
no PO, **without** the `_TO_SEARCH` fields:

```
E  M7 030  Purchase order   does not exist
```

The same payload **with** `DELIV_NUMB_TO_SEARCH` / `DELIV_ITEM_TO_SEARCH` populated returns
`RETURN` = 0 entries. The error originates in `mb_create_goods_movement` (line 632), i.e. **after**
the BAdI — so the BAdI can prevent it.

---

## The design

The BAdI implementation fills the gap between what the standard service sends and what the posting
needs.

```
OData request  ─►  CL_MATERIAL_DOCUMENT_API  ─►  BAPI_GOODSMVT_CREATE
   Delivery                                          MAP2I (line 223)
   DeliveryItem                                          │
   Plant                                                 ▼
   GoodsMovementType 101                    ZCL_MM_GOODSMVT_BAPI_CUSTOM (line 546)
   GoodsMovementRefDocType B                    derive + fill CT_IMSEG
                                                     validate → CT_RETURN
                                                          │
                                                          ▼
                                            mb_create_goods_movement (632)
                                                          │
                                                          ▼
                                            ZCL_IM_ZEMPL_MB_DOC
                                            MB_DOCUMENT_BEFORE_UPDATE
                                                write ZMMT_MIGO_HDR
```

### Requirement placement

| Requirement | Where | Status |
|---|---|---|
| Delivery + Item as input | OData request | native |
| PO not supplied | BAdI derives and sets `IMSEG-VLIEF_AVIS`/`VBELP_AVIS` or `EBELN`/`EBELP` | build |
| Derive material, SLoc, qty, unit, batch | BAdI fills `CT_IMSEG` | build |
| Derive token, LR, transporter, vehicle | BAdI, from ILMS tables | build |
| Post movement 101 | standard BAPI | native |
| Persist `ZMMT_MIGO_HDR` | `MB_DOCUMENT_BEFORE_UPDATE` | build |
| Custom validations | BAdI → `CT_RETURN`, or `MB_CHECK_LINE_BADI` | build |
| Material doc number, year, errors | standard OData response + `CT_RETURN` | native |

**Plant must still be supplied in the request.** `GET_RELEVANT_FIELDS` marks `Plant` mandatory
(`CL_MATERIAL_DOCUMENT_API======CM00D` line 65) and `ITEM_CHECK_ALLOWED_FIELDS` rejects the request
without it. This is an OData-service rule, not a BAPI rule. So the contract is
**Delivery + DeliveryItem + Plant**, not delivery and item alone.

---

## Implementation plan

### Step 1 — extend `ZCL_MM_GOODSMVT_BAPI_CUSTOM~EXTENSIONIN_TO_MATDOC`

Class exists, is active, registered as `ZEI_MM_GOODSMVT_BAPI_CUSTOM` on BAdI
`MB_BAPI_GOODSMVT_CREATE`, `BADI_IMPL` POS 7. Currently handles only `MSEG`/`LSMNG` with an empty
`MKPF` branch. **Note:** the existing `LSMNG` branch reads
`ct_imseg WITH KEY line_id = ls_extension-valuepart1` where `valuepart1` is the literal `'LSMNG'`.
That looks like a defect — confirm by test before relying on or copying it.

Add, gated (see gating below), per item in `CT_IMSEG`:

1. Read `LIPS` on `VBELN` = `imseg-vbeln`, `POSNR` = `imseg-posnr`.
2. Set the delivery search fields so SAP resolves the PO:
   `imseg-vlief_avis = imseg-vbeln`, `imseg-vbelp_avis = lips-uecha`.
   (`ZLEIILMSDOCUMENTS_GRN_BTST` passes `LIPS-UECHA` for `deliv_item_to_search`, not `POSNR`.)
   Alternative: set `imseg-ebeln = lips-vgbel`, `imseg-ebelp = lips-vgpos` directly.
   **Prefer the search fields** — that is the pattern SAP intends and the production programme uses.
3. Fill from `LIPS`: `matnr`, `erfmg` (`lfimg`), `erfme` (`meins`), `charg`.
4. Storage location: derive from `MARD` for the receiving plant. For material `14000035` there is
   exactly one storage location per plant (`RMYD`). Confirm the rule with the process owner —
   the three production programmes hardcode it (`'GDF'`, `'RMYD'`, silo-based at plant 3791).
5. Derive token, LR number, transporter, vehicle from `ZLETILMSTOKEN` / `ZLETILMSDELIVERY` /
   `ZLETILMSTRANS` and stash for step 3 (see "carrying data" below).

### Step 2 — validations

Eight rules, gated on goods receipt against outbound delivery. Source of truth:
`ZCLMM_MB_MIGO_BADI~CHECK_ITEM` (`CM002`), which gates on `action = 'A01'` and `refdoc = 'R05'`.

| Message | Rule | Data |
|---|---|---|
| `ZMM 068` | Invoice not created/cancelled for outbound delivery | `VBRP`/`VBRK`, `vgbel = delivery`, `vbrk-rfbsk <> 'E'` |
| `ZMM 077` | PO reference not allowed — must use outbound delivery | scenario check |
| `ZMM 078` | Only one outbound delivery per document | count distinct `vbeln` |
| `ZMM 067` | GRN quantity exceeds delivery quantity | `LIPS-LFIMG` |
| `ZMM 070` | GRN quantity must equal delivery quantity | `LIPS-LFIMG` |
| `ZMM 075` | Receiving SLoc must be `RSD` | `LIKP-VSART='03'` and `LIPS-MFRGR='A0000001'` |
| `ZMM 074` | Receiving SLoc must be `GDRK` | `LIPS-LGORT='GDRK'` |
| `ZMM 079` | Delivery note cannot be changed | `MKPF-XBLNR` vs `LIPS-VBELN` |

Storage-location rules carry a cutoff `LIPS-ERDAT >= '20240723'`.

Raise into `CT_RETURN` as `BAPIRET2` with `TYPE = 'E'`. Do **not** use `MESSAGE ... TYPE 'E'` —
it will dump or short-circuit the caller.

Also add the idempotency guard, lifted from `ZLEIILMSDOCUMENTS_GOODSREC`:

```abap
SELECT SINGLE MAX( mblnr ) FROM matdoc
  WHERE vbeln_im = @<delivery> AND vbelp_im = @<item>
    AND bwart = '101' AND cancelled = @space.
```

Non-initial means already received — reject.

### Step 3 — persist `ZMMT_MIGO_HDR`

`ZCL_IM_ZEMPL_MB_DOC~MB_DOCUMENT_BEFORE_UPDATE` (BAdI `MB_DOCUMENT_BADI`, `BADI_IMPL` POS 32).
Signature: `XMKPF`, `XMSEG`, `XDM07M`, `XVM07M`.

Runs inside the posting LUW, so the write is atomic with the document. `XMKPF` carries `MBLNR`
and `MJAHR`, which are not known at BAdI step 1.

Existing body is gated on `IF sy-tcode = 'IFCU'` — leave that branch alone and add a new,
separately gated branch.

`ZMMT_MIGO_HDR` fields, from `ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` (`CM00F`):
`MBLNR`, `MJAHR`, `AFRNO`, `AFRDT`, `LOVCT`, `GTPAS`, `LRDAT`, `TOKEN`, `POST1`, `LFSNR`, `ZFLAG`.

**Carrying data from step 1 to step 3:** the two BAdIs are separate calls. Options, in order of
preference: (a) a small buffer class with static attributes, keyed by delivery/item, written in
step 1 and read in step 3; (b) re-derive from `XMSEG-VBELN_IM`/`VBELP_IM` in step 3. Do **not** use
`EXPORT/IMPORT TO MEMORY` or dynamic `ASSIGN` — that is the mistake the existing MIGO code makes.

### Step 4 — the request contract

```
POST /sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader
{
  "GoodsMovementCode": "01",
  "to_MaterialDocumentItem": [{
    "Material": "",                          // omitted - BAdI derives
    "Plant": "1005",                         // MANDATORY
    "GoodsMovementType": "101",
    "GoodsMovementRefDocType": "B",          // required for Delivery to be whitelisted
    "Delivery": "9004952595",
    "DeliveryItem": "000010"
  }]
}
```

`GoodsMovementRefDocType = 'B'` is required — `Delivery`/`DeliveryItem` are only whitelisted inside
`IF iv_goodsmovementrefdoctype = sc_goodsmovementrefdoctype-gm_for_purchase_order`
(`CM00D` lines 124–130). `PurchaseOrder`/`PurchaseOrderItem` stay empty.

---

## Gating — do this first, not last

Every one of these BAdIs fires for **every goods movement in the system**: MIGO, `MB1B`, IDoc
inbound via `IDOC_INPUT_MBGMCR` (same function group), every other interface and background job.

Gate on all of:

- `imseg-bwart = '101'`
- `imseg-kzbew = 'B'`
- `imseg-vbeln` is not initial **and** the delivery is outbound (`LIKP-VBTYP = 'J'`)
- the delivery references an STO (`LIPS-VGBEL` starts `56`, or check `EKKO-BSART`)
- a plant or document-type restriction agreed with the process owner

Exit immediately if any fails. An ungated implementation will affect processes nobody has told you
about — there are already six active `MB_MIGO_BADI` implementations and 36 SAP enhancements in
MIGO's own function group.

---

## Extension surface — full inventory

| Path | Enhancement spot | Spot implementations | BAdIs | Customer code |
|---|---|---|---|---|
| OData `API_MATERIAL_DOCUMENT_SRV` | **none** | — | **none** | — |
| BAPI, FG `MB_BUS2017` | `ES_SAPLMB_BUS2017` (10 objects) | 4, all SAP (ISU, IUID, OIA, VL_SFWS) | `MB_BAPI_GOODSMVT_CREATE`, `MB_DOCUMENT_BADI`, `MB_CHECK_LINE_BADI` | 3 impls |
| MIGO, FG `MIGO` | `ES_SAPLMIGO` (74 objects) | 36, all SAP | `MB_MIGO_BADI` | 6 impls + 2 raw implicit enhancements |

The OData service classes (`CL_MATERIAL_DOCUMENT_API`, `CL_API_MATERIAL_DOCUME_DPC`, `_DPC_EXT`)
have **no** enhancement spot and **no** BAdI call — verified via `ENHSPOTOBJ` and a full-source grep.
All six service classes are `SRCSYSTEM=SAP`, package `ODATA_MM_IM_API_MATERIAL_DOC`.

The existing MIGO customisation cannot be reused: `ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` gates on
`sy-ucomm EQ 'OK_POST1' OR 'OK_POST'` and reads its data via
`ASSIGN ('(ZMMR_MIGO_SCREEN_ADD)GS_MIGO_HDR')`. Headless, both fail silently. Seven such dynamic
accesses across that class. Its logic is **studied, not called**.

---

## Test data

From the 2026-09-02 sweep, STO `5600074803` → receiving plant `1005`, SLoc `RMYD`, ~4,958 TO open,
**18 interchangeable MIGO-pending deliveries**: `9004952595`–`9004952614`, material `14000035`,
~41–42 TO each, single item, no batch.

`9004952595` was used for the SE37 test runs (test run only — still un-receipted).
Full register: `sessions/2026-09-02-migo-candidate-recheck/CANDIDATE_REGISTER.csv`.

**Recheck before every test:** `MSEG VBELN_IM=<delivery> BWART=101` — any hit means already
receipted. Also check `EKET` (`WAMNG − WEMNG`) for PO-referenced GRs that never touch the delivery.

---

## Open items

| Item | Why it matters |
|---|---|
| **Does the derivation actually work end-to-end?** Only a real posting proves it. `TESTRUN` is shallow — it accepted quantity `9999 TO` against a 41.230 TO delivery without complaint | Highest priority. Needs an owner-confirmed candidate |
| Whether SAP derives `MATNR` when the PO is resolved via `_TO_SEARCH`. `ZMM_STO_AUTO_POSTING` omits material and plant with an explicit PO and works; `ZLEIILMSDOCUMENTS_GRN_BTST` supplies them with `_TO_SEARCH`. No production example does both | Determines how much step 1 must fill. Safe default: fill everything |
| Storage-location rule per plant — derived from `MARD` or a business rule? | Needs process-owner sign-off |
| The outbound `cl_http_client=>create_by_destination` call in `ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` — destination, payload, whether mandatory | Possible E-Way Bill/GST integration. `/DIGIGST/EWAY_GENERATE` and `/DIGIGST/EINV_GENERATE_SPOT` have active implementations and `/digigst/oward_h` holds `EWBNUMBER`, so it may already be handled on the billing side |
| Six active `MB_MIGO_BADI` implementations compete for one header subscreen (`check i_class_id = gv_class_id`) | Pre-existing MIGO issue, unrelated to this build, but worth raising |
| `BREAK ibmabap07 / 21 / 17` left in transported code across three classes | Debug remnants |

---

## Reference source, already captured

`sessions/2026-09-02-std-api-extension-feasibility/src/`
- `LMB_BUS2017U04.txt` — `BAPI_GOODSMVT_CREATE`, 762 lines
- `LMB_BUS2017U17.txt` — `MAP2I_B2017_GM_ITEM_TO_IMSEG`
- `CL_MATERIAL_DOCUMENT_API======CM00V.txt` — `MAP_ITEM_INPUT`
- `CL_MATERIAL_DOCUMENT_API======CM00D.txt` — `GET_RELEVANT_FIELDS` (the whitelist)
- `CL_MATERIAL_DOCUMENT_API======CM00F.txt` — `ITEM_CHECK_ALLOWED_FIELDS`
- `CL_API_MATERIAL_DOCUME_DPC_FLXCM008.txt` — key-user extensibility, enriches response only

`sessions/2026-09-02-migo-customisation-inventory/src/`
- `ZCLMM_MB_MIGO_BADI============CM002.txt` — `CHECK_ITEM`, the eight rules
- `ZCLMM_MB_MIGO_BADI============CM00F.txt` — `POST_DOCUMENT`, persistence + HTTP call
- `ZCL_MM_GOODSMVT_BAPI_CUSTOM===CM001.txt` — the BAdI to extend
- `ZCL_IM_ZEMPL_MB_DOC===========CM001.txt` — the persistence BAdI

Reusable scripts: `sessions/2026-09-02-std-api-extension-feasibility/scripts/`
- `bapi-testrun.vbs <delivery> <item> <plant> [material] [qty] [uom] [sloc] [proposeqty]` —
  `-` blanks a field; refuses to run unless `TESTRUN='X'`
- `se37-read-return.vbs`, `se37-read-item-result.vbs`
- `grab.ps1`, `open-include.vbs` — ABAP source capture via SE38 display

Prior analysis: `sessions/2026-09-01-bapi-field-derivation/FINDINGS.md` (the three production
BAPI callers), `sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md` (customisation sweep
method and full inventory).
