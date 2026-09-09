> **SUPERSEDED, 2026-09-02.** The conclusion below — that a custom wrapper is required — rested on
> an unverified assumption: that the BAdI on `BAPI_GOODSMVT_CREATE` runs too late to influence the
> posting. It does not. The BAdI is called at line 546 of `LMB_BUS2017U04`; the document is created
> at line 632. Changes to `CT_IMSEG` survive. The requirement can be met through supported
> extensibility on the standard service.
>
> **Current plan: `CODEX_HANDOVER_SUBMIT_MIGO_BADI_IMPLEMENTATION_2026-09-02.md`.**
>
> The evidence in this document about the OData service's own extension surface (no BAdI, no
> enhancement spot, hardcoded field whitelist, key-user extensibility enriching only the response)
> and about the MIGO customisation being dialog-bound remains accurate and is still cited.

# Submit MIGO — build decision and evidence

**Date:** 2026-09-02 · **System observed:** QS4/700 · **Method:** read-only SE16 and SE38 display via SAP GUI Scripting
**Nothing was posted, activated, committed or changed.**

This document supersedes earlier drafts. It states one position, with the evidence for each part.

---

## Verdict

**Build a custom OData service in the customer namespace, wrapping `BAPI_GOODSMVT_CREATE`.**

Extending `API_MATERIAL_DOCUMENT_SRV` is **NOT POSSIBLE THROUGH SUPPORTED EXTENSIBILITY**.
Extending `BAPI_GOODSMVT_CREATE` does not solve the problem either. Neither conclusion depends on
the custom fields — both rest on a simpler fact established below.

---

## The contract

**Request:** Delivery Number + Delivery Item. Nothing else.

**Derived inside the service:**

| Value | Source |
|---|---|
| Material, quantity, unit, batch | `LIPS` |
| Receiving plant | `EKPO` via the STO on `LIPS-VGBEL` |
| Storage location | `MARD` — one per plant for these materials |
| Open quantity | `EKET` (`WAMNG − WEMNG`) |
| Purchase order | **not derived** — SAP resolves it from the delivery |
| Token, LR number, transporter, vehicle | ILMS tables |

**Response:** Material Document Number, Year, mapped SAP messages.

---

## Why the derivation cannot live anywhere else

`BAPI_GOODSMVT_CREATE` requires material, plant and quantity **as input**. Every BAdI on the BAPI —
including `MB_BAPI_GOODSMVT_CREATE~EXTENSIONIN_TO_MATDOC` — fires *after* those inputs are set.

So the derivation must happen **before** the BAPI is called. The standard OData service has no step
before that call. That single fact settles the architecture, independently of everything else in
this document.

`EXTENSION_IN` is for stamping custom values onto a finished document. It is not a derivation
mechanism.

---

## Requirement-by-requirement

| # | Requirement | Standard OData service | Disposition | Evidence |
|---|---|---|---|---|
| 1 | Delivery + Item as the only input | **No** | Custom wrapper | `Plant` is mandatory in `GET_RELEVANT_FIELDS`; no derivation step exists before the BAPI call |
| 2 | PO Number / PO Item not supplied | **No — for outbound deliveries** | Custom wrapper, **to expose an existing standard capability** | The capability is standard: MIGO does it (`A01` + `R05`), `BAPI_GOODSMVT_CREATE` does it with `MVT_IND='B'` + `DELIV_*_TO_SEARCH`, and `ZLEIILMSDOCUMENTS_GRN_BTST` already does it in this system. The **service** does not: `MAP_ITEM_INPUT` lines 34–44 set `DELIV_*_TO_SEARCH` for inbound deliveries only; outbound gets `DELIV_NUMB`/`DELIV_ITEM` alone. C&F is outbound (`LIKP-VBTYP='J'`), and that payload returns `M7 030 Purchase order does not exist` — demonstrated in SE37 |
| 3 | Derive material, plant, SLoc, quantity, unit, batch | **No** | Custom wrapper | Fields are *optional*, meaning the API won't reject their absence — not that SAP fills them. Every production caller derives them from `LIPS`/`LIKP` and supplies them |
| 4 | Derive token, LR number, transporter, vehicle | **No** | Custom wrapper | ILMS tables `ZLETILMSTOKEN`, `ZLETILMSDELIVERY`, `ZLETILMSTRANS`; pattern used by `ZLEIILMSDOCUMENTS_GOODSREC` |
| 5 | Post movement 101 | **Yes** | **Standard BAPI, out of the box** | `BAPI_GOODSMVT_CREATE`, `GM_CODE='01'`, `MVT_IND='B'` |
| 6 | Persist `ZMMT_MIGO_HDR` | **No** | Custom wrapper | No enhancement point on the standard path; the existing write is MIGO-dialog-bound |
| 7 | Custom validations | **No** | Custom wrapper | Eight `ZMM` rules; no hook to run them |
| 8 | Material document number, year, meaningful errors | Partial | Custom wrapper | Number and year yes; no control over error content or contract shape |

**Note the empty column.** Not one requirement falls under "possible through supported extension."
Requirement 5 works out of the box; everything else needs the wrapper. Nothing sits in between.
That is the argument in one table.

**What the wrapper is not.** It does not invent behaviour SAP lacks. Receiving against an outbound
delivery without a purchase order is standard SAP and is how MIGO already works at Shree Cement —
their own `ZMM 077` message *forbids* PO reference and requires outbound delivery. The wrapper's job
is to make that existing behaviour reachable through an API, and to run the derivation and custom
logic that no standard path offers. Expect the MIGO reference-document dropdown
(`A01` Goods Receipt + `R05` Outbound Delivery) to be raised as a counter-argument; it is correct,
and it is about the dialog transaction, not about the OData service.

Nothing in the SAP standard is modified. No object access key is required.

### Correction to earlier drafts

An earlier version of this document said requirement 2 worked out of the box on the standard
service. That was based on `Delivery`/`DeliveryItem` being whitelisted properties and
`PurchaseOrder` being optional — both true, but incomplete. `MAP_ITEM_INPUT` only populates the
`_TO_SEARCH` fields for **inbound** deliveries. C&F uses outbound deliveries, so the standard
service constructs a BAPI payload that cannot resolve the purchase order.

SAP built the capability and did not wire it for this delivery type. The standard service is not
merely inconvenient here — it fails.

---

## Why the standard service is excluded

**1. No enhancement point exists.** A search for `badi`, `get_instance`, `cl_exithandler` and
`enhancement` across all 20 method includes and declaration sections of `CL_MATERIAL_DOCUMENT_API`
returns **zero matches**. There is no BAdI and no enhancement spot anywhere in
`CREATE_MATERIAL_DOCUMENT` → `PREPARE_ITEMS` → `ITEM_CHECK_ALLOWED_FIELDS` → `MAP_ITEM_INPUT`.

**2. The service classes are SAP's.** All six are `SRCSYSTEM=SAP`, `AUTHOR=SAP`, package
`ODATA_MM_IM_API_MATERIAL_DOC`: `CL_API_MATERIAL_DOCUME_DPC`, `_DPC_EXT`, `_DPC_FLX`, `_MPC`,
`_MPC_EXT`, `_MPC_FLX`. In a service you build, `_DPC_EXT` is yours to redefine; here it is
SAP-delivered and fully implemented (33 components). Redefining it is a modification.

**3. Key-user extensibility runs after the posting.**
`CL_API_MATERIAL_DOCUME_DPC_FLX~CREATE_ENTITY`:

```abap
" ----------------   !! GENERATED CODE !! --------------------
" !!  DO NOT CHANGE, WILL BE OVERWRITTEN AT NEXT GENERATION !!

super->/iwbep/if_mgw_appl_srv_runtime~create_entity( ... IMPORTING er_entity = er_entity ).
IF er_entity IS INITIAL.
  RETURN.
ENDIF.
flx_load_runtime_api( ).
mo_flx_runtime_api->enrich_create_entity( ir_entity = er_entity ).
```

`super->create_entity( )` performs the posting. The extensibility code runs afterwards, on the
**response**. It enriches the reply; it cannot feed the posting or populate `EXTENSION_IN`.

**4. The field whitelist is hardcoded.** `ITEM_CHECK_ALLOWED_FIELDS` rejects any property not on
the list built by `GET_RELEVANT_FIELDS`, which uses a hardcoded ABAP `CASE`. Only the
mandatory/optional *level* is configurable. `Plant` is mandatory.

**What the standard service *can* do:** `Delivery` and `DeliveryItem` are supported properties when
`GoodsMovementRefDocType` = purchase order, with `PurchaseOrder`/`PurchaseOrderItem` optional
(SAP comment: *"delivery shall only be enabled for processes where also a PO is in place"*).
`Material`, `Batch`, `EntryUnit`, `QuantityInEntryUnit` and `StorageLocation` are optional —
but "optional" means the API will not reject their absence, **not** that SAP fills them in. Every
production caller supplies them.

---

## Why the existing MIGO logic cannot be reused

`ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` (include `CM00F`):

```abap
line 90:  IF ( sy-ucomm EQ 'OK_POST1' OR sy-ucomm EQ 'OK_POST' ).
line 94:  ASSIGN ('(ZMMR_MIGO_SCREEN_ADD)GS_MIGO_HDR') TO <fs_mkpf>.
line 95:  IF sy-subrc = 0.
line 163:       MODIFY zmmt_migo_hdr FROM ls_migo_hdr.
```

The `ZMMT_MIGO_HDR` write is gated on `sy-ucomm` — the GUI function code of a button press — and its
data comes from a dynamic ASSIGN into a dynpro program's global memory. Headless, the gate is false
and the ASSIGN fails, so the write never happens. Silently: every access is guarded, so it does not
dump.

Seven such accesses across the class: `(SAPLMIGO)GOHEAD` ×3, `(SAPLMIGO)GODYNPRO` ×2,
`(SAPLMIGO)GODYNPRO-ACTION`, `(ZMMR_MIGO_SCREEN_ADD)GS_MIGO_HDR`.

**The rules are therefore studied, not reused.** Nothing in the existing MIGO code is modified,
moved or called.

### Customisation landscape

Ten customisations on the MIGO/goods-movement path, all active (registered in `BADI_IMPL`):

| BAdI | POS | Enhancement | Class |
|---|---:|---|---|
| `MB_MIGO_BADI` | 15 | `ZDACE_CUSTOM_MIGO_HEADER_TAB` | `ZDACE_CL_CUSTOM_MIGO_HEAD_TAB` |
| `MB_MIGO_BADI` | 16 | `ZDACE_CUSTOM_MIGO_HEADER_TAB_N` | `ZDACE_CL_CUSTOM_MIGO_HEAD_TABN` |
| `MB_MIGO_BADI` | 17 | `ZEI_MM_DELIVERY_NOTE` | `ZCL_IM_SDEI_DELIVERY_NOTE` |
| `MB_MIGO_BADI` | 18 | `ZEI_MM_MB_MIGO_BADI` | `ZCLMM_MB_MIGO_BADI` |
| `MB_MIGO_BADI` | 19 | `ZIML_CAN_CHECK` | `ZCL_CAN` |
| `MB_MIGO_BADI` | 20 | `ZMM_SEND_MAIL` | `ZCL_IM_MM_SEND_MAIL` |
| `MB_BAPI_GOODSMVT_CREATE` | 7 | `ZEI_MM_GOODSMVT_BAPI_CUSTOM` | `ZCL_MM_GOODSMVT_BAPI_CUSTOM` |
| `MB_DOCUMENT_BADI` | 32 | `ZMB_DOCUMENT_BADI` | `ZCL_IM_ZEMPL_MB_DOC` |

Plus two source-code plug-ins inside SAP's MIGO includes — `ZDACE_MODIFY_MIGO_ITEM_QTY` (`LMIGOKC2`)
and `ZMM_MIGO_DATA_CHECK` (`LMIGOKG1`) — which are not BAdIs and are equally MIGO-bound.

The two on the BAPI path were read in full and carry almost nothing:
`EXTENSIONIN_TO_MATDOC` handles only `MSEG`/`LSMNG` with an empty `MKPF` branch;
`MB_DOCUMENT_BEFORE_UPDATE` is gated on `sy-tcode = 'IFCU'`; `MB_DOCUMENT_UPDATE` is empty.

**No SAP MIGO object has been modified by hand** — `SMODILOG` for `OBJ_NAME=MI..MJ` returns nothing.

---

## The rules to implement

`CHECK_ITEM` gates on `action = 'A01'` (goods receipt) and `refdoc = 'R05'` (outbound delivery) —
the Submit MIGO scenario exactly. Within that gate:

| Message | Rule | Source |
|---|---|---|
| `ZMM 068` | Invoice not created/cancelled for outbound delivery | `VBRP`/`VBRK`, `vgbel = delivery`, `vbrk-rfbsk <> 'E'` |
| `ZMM 077` | PO reference not allowed — must use outbound delivery | scenario check |
| `ZMM 078` | Only one outbound delivery per MIGO | count of distinct `vbeln` |
| `ZMM 067` | GRN quantity exceeds delivery quantity | `LIPS` |
| `ZMM 070` | GRN quantity must equal delivery quantity | `LIPS` |
| `ZMM 075` | Receiving SLoc must be `RSD` | `LIKP-VSART='03'` and `LIPS-MFRGR='A0000001'` |
| `ZMM 074` | Receiving SLoc must be `GDRK` | `LIPS-LGORT='GDRK'` |
| `ZMM 079` | Delivery note cannot be changed | `MKPF-XBLNR` vs `LIPS-VBELN` |

Storage-location rules carry a cutoff of `LIPS-ERDAT >= '20240723'`.

`ZMM 077` is worth showing the client: **their own MIGO already forbids PO reference and requires
outbound delivery.** The proposed contract matches how they work.

Most of `CHECK_ITEM`'s 18KB is out of scope — gated to movement `201`, or `261`, or commented out.

---

## Reference implementation already in the system

`ZLEIILMSDOCUMENTS_GRN_BTST` — the proven no-PO call:

```abap
ls_bapi_gmcode-gm_code = '01'.
ls_bapi_item-material  = ls_lips-matnr.
ls_bapi_item-plant     = ls_likp-werks.
ls_bapi_item-stge_loc  = 'GDF'.
ls_bapi_item-move_type = '101'.
ls_bapi_item-entry_qnt = ls_lips-lfimg.
ls_bapi_item-entry_uom = ls_lips-meins.
ls_bapi_item-mvt_ind   = 'B'.
ls_bapi_item-deliv_numb = ls_lips-vbeln.
ls_bapi_item-deliv_item = ls_lips-posnr.
ls_bapi_item-deliv_numb_to_search = ls_lips-vbeln.
ls_bapi_item-deliv_item_to_search = ls_lips-uecha.
ls_bapi_item-batch = ls_lips-charg.
```

No `po_number`, no `po_item`. Followed by `BAPI_TRANSACTION_COMMIT`.

`ZLEIILMSDOCUMENTS_GOODSREC` is the fuller pattern, driven by a **token** rather than a PO, returning
`BAPIRET2`. Two controls worth reusing directly:

- **Idempotency:** `SELECT SINGLE MAX( mblnr ) FROM matdoc WHERE vbeln_im = <delivery> AND vbelp_im = <item> AND bwart = '101' AND cancelled = ' '` — non-initial means already received.
- **Concurrency:** `ZLETILMSDELIVERY-ZMIGO_PROC` set before processing, cleared after.

The derivation this service needs is not new to Shree Cement. It already runs; it is simply not
reachable from outside SAP.

---

## Build steps

1. Entity model: Delivery, DeliveryItem in; material document number, year, messages out.
2. Derivation: `LIPS` → `EKPO` → `MARD` → `EKET`, plus the ILMS lookup for token, LR, transporter, vehicle.
3. Validation: the eight rules above.
4. Post: `BAPI_GOODSMVT_CREATE` with the proven field set, then `BAPI_TRANSACTION_COMMIT WAIT='X'`.
5. Persist `ZMMT_MIGO_HDR` in the same LUW.
6. Re-read the document after commit — an allocated number is not persistence.
7. Map `BAPIRET2` and the `ZMM` messages to the response.

---

## Open items

| Item | Impact |
|---|---|
| Outbound HTTP call in `POST_DOCUMENT` (`cl_http_client=>create_by_destination`) — destination, payload, whether mandatory. Not read. | **Could add material work.** Highest priority. |
| Runtime proof that the no-PO pattern posts for a C&F STO delivery. First SE37 attempt returned `M7 030 Purchase order does not exist` because `DELIV_*_TO_SEARCH` was omitted; corrected payload not yet run. | Confirms the estimate |
| ILMS join path from a C&F outbound delivery to the token record | Confirms the four custom fields are reachable |
| Whether `ZMMT_MIGOITEM` must also be written | Minor |
| `MODATTR` activation status of CMOD project `ZMM_RESE` → `MBCF0007`; `Y*` namespace; BTEs | Completeness only |

**Note on production claims.** The ILMS programmes were observed in QS4. The statement that they run
in production comes from `sessions/2026-09-01-bapi-field-derivation/FINDINGS.md`, not from
independent verification of PRD. Confirm before repeating it to the client.

---

## Pre-existing issue to raise with the ABAP owner

`ZCLMM_MB_MIGO_BADI~PBO_HEADER` carries SAP's own warning:

```abap
* (If there would be more than one implementation of BAdI MB_MIGO_BADI,
* only one subscreen would be displayed).
  check i_class_id = gv_class_id.
```

Six implementations are active and at least three implement `PBO_HEADER`. Only one can display.
Unrelated to Submit MIGO, but someone may have adapted to it without knowing why.

Also: `BREAK ibmabap07`, `BREAK ibmabap21`, `BREAK ibmabap17` — developer break-points left in
transported code across three classes.

---

## Client-facing statement

> A goods receipt can be posted against an outbound delivery without supplying a purchase order —
> SAP works the purchase order out from the delivery itself. Two programmes at Shree Cement already
> do this today, so the approach is established rather than experimental.
>
> What SAP does not do is work out the rest. The material, plant, storage location, quantity, unit
> and batch all have to be supplied to SAP by whatever calls it, and every existing programme looks
> those up from the delivery first. SAP's standard interface has no step where that lookup can
> happen — it expects the values to arrive already filled in.
>
> That lookup is the core of what the new interface provides, and it is what keeps the request as
> simple as the business asked for: the delivery number and item go in, and the interface works out
> everything SAP needs behind the scenes, records the token and transport details, applies the same
> checks the business already uses in MIGO, and returns the material document number.
>
> Nothing in SAP's standard software is altered, so there is no impact on future upgrades or on SAP
> support.

---

## Evidence

Source captured under `sessions/2026-09-02-migo-customisation-inventory/src/` and
`sessions/2026-09-02-std-api-extension-feasibility/src/`; registry reads in the matching `evidence/`
folders. Customisation inventory and method:
`sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md`. BAPI caller analysis:
`sessions/2026-09-01-bapi-field-derivation/FINDINGS.md`. Test candidates:
`sessions/2026-09-02-migo-candidate-recheck/`.
