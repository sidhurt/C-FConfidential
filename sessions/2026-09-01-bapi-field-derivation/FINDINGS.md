# BAPI field-derivation investigation — 2026-09-01

## Question

Do existing Shree Cement Z-programs derive the technical values required by `BAPI_GOODSMVT_CREATE`, and is there evidence of a delivery-number/item-only posting pattern?

## Current conclusion - updated 1 September, evening

**This supersedes the earlier conclusion.** A complete `Delivery + Delivery Item`-only movement-101 derivation path *does* exist in QS4, in production custom code. It is the ILMS (yard/token) goods-receipt path.

Two callers post movement 101 against an outbound delivery with **no PO number and no PO item passed to the BAPI at all**:

- `ZLEIILMSDOCUMENTS_GOODSREC`
- `ZLEIILMSDOCUMENTS_GRN_BTST`

Both read `LIPS`/`LIKP` and derive Material, Plant, Quantity, UoM and Batch from the delivery item. Storage Location is a constant or a rule. This is the pattern the C&F Submit MIGO wrapper needs, and it already runs in this system.

A third caller, `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01`, does supply PO - but derives it from the delivery item's source document (`LIPS-VGBEL` / `LIPS-VGPOS`) rather than taking it from its caller. That is the fallback if the BAPI turns out to want PO for a given movement/reference combination.

This now supports three statements:

1. PO Number and PO Item do not need to be caller-facing inputs.
2. PO Number and PO Item do not need to be passed to `BAPI_GOODSMVT_CREATE` at all for a delivery-referenced 101, on the evidence of the ILMS callers.
3. Where PO is needed internally, it is derivable from the delivery item in one read.

Still not proved: that `API_MATERIAL_DOCUMENT_SRV` accepts the same minimal shape. The ILMS callers go straight to the BAPI, not through OData.

## `ZMM_MIGO_POSTING` / transaction `ZMM063`

The 101 branch reads an Excel row containing PO Number, PO Item, dates, reference, custom values, quantity, unit, storage location and batch.

It supplies the BAPI with:

- movement indicator `B`;
- PO Number and PO Item;
- batch;
- movement type `101`;
- storage location;
- quantity;
- unit.

It does not explicitly supply Material or Plant in this branch, so those are left for reference-based BAPI determination. Its delivery-number assignment is commented out. Therefore this is a PO-referenced caller, not evidence of delivery-only derivation.

Although the Excel structure contains Token/LR/AFR/E-Way-Bill-style values and an `EXTENSIONIN` table is passed to the BAPI, population of that extension table was not established in the inspected 101 code.

Source captured in the pasted program/include for `ZMM_MIGO_POSTING_FORMS`; the earlier study guide records the same finding.

## `ZMM_STO_AUTO_POSTING`

This program automates a larger chain: PO, outbound delivery, PGI, billing and then goods receipt.

Before calling `BAPI_GOODSMVT_CREATE`, it derives/builds values from documents already created in the same process:

- header dates from billing date;
- reference document from the delivery;
- storage location from the STO/PO item data held by the program;
- quantity and unit from billing item data;
- PO/item and delivery/item from document references;
- movement type `101` and movement indicator `B` as constants.

It does not explicitly populate Material or Plant in the captured BAPI item, leaving them to reference-based SAP/BAPI determination.

This is strong evidence that a custom program can hide technical derivation from its caller. It is not evidence that the standard Material Document OData endpoint accepts only Delivery + Item, because the program performs its own reads and supplies both PO and delivery references internally.

Source: `sessions/2026-08-18-runtime-certification/sto/ZMM_STO_AUTO_POSTING_src.txt`.

## `ZMMR_MIGO_SCREEN_ADD` and `MB_MIGO_BADI`

The custom MIGO screen logic derives custom operational data including Token, LR date/number, transporter, vehicle, vehicle type, invoice date and challan information.

The inspected lookup reads MIGO `GOITEM-EBELN/EBELP` and header delivery-note/reference information, then queries `ZLETILMSDELIVERY`, `ZLETILMSTOKEN`, `ZLET_VEHICLE`, `MATDOC` and `ZMMT_MIGO_HDR`.

The post-document implementation persists `ZMMT_MIGO_HDR`, evaluates delivery quantities using MSEG/MATDOC and LIPS data, and prepares GRN information for downstream processing.

This custom derivation is tied to MIGO runtime structures and is PO-aware. It is not proof that the same processing runs through `BAPI_GOODSMVT_CREATE` or `API_MATERIAL_DOCUMENT_SRV`.

## Standard Material Document API mapping

The inspected standard API mapping copies caller-supplied values directly into the BAPI item:

- Material;
- Plant;
- Storage Location;
- Quantity;
- Unit;
- PO/item;
- Delivery/item.

It classifies the supplied delivery as inbound or outbound and maps its reference fields accordingly. The inspected mapping itself does not fetch Material, Plant, Storage Location, Quantity or Unit from the delivery.

Mandatory/allowed-field checks occur before the BAPI call based on movement type, special stock and reference type. A live PO-free test is still required to establish the exact accepted field minimum for this QS4 configuration.

## The delivery-only pattern - `ZLEIILMSDOCUMENTS_GRN_BTST`

The minimal, cleanest form found. Guarded by a duplicate check, then:

```abap
ls_bapi_header-pstng_date = sy-datum.
ls_bapi_header-doc_date   = sy-datum.
ls_bapi_gmcode-gm_code    = '01'.

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

Read this as the reference implementation for the C&F wrapper: the caller supplies delivery and item, the server reads `LIPS`/`LIKP` and fills the rest.

## `ZLEIILMSDOCUMENTS_GOODSREC` - the fuller pattern

Same shape, plus the business rules C&F will also need. Signature is `f_goodsrec_create USING ps_token TYPE zletilmstoken ps_stageset ... CHANGING pv_error pt_return TYPE bapiret2_tt` - the caller passes a **token**, not a PO, and gets back a `BAPIRET2` table.

### Derivation

| BAPI field | Source |
|---|---|
| `material` | `LIPS-MATNR` |
| `plant` | `LIPS-WERKS`, or `LIKP-WERKS`, or `ZLETILMSTOKEN-UMWRK` of the reference token for STO, or `ZLETILMSTOKEN-DOCPLANT` - branch-dependent |
| `stge_loc` | constant `'RMYD'`; `ZLETILMSTRANS-SILO` when plant `3791` |
| `move_type` | constant `'101'` |
| `mvt_ind` | constant `'B'` |
| `entry_qnt` | weighbridge quantity (gross `stageid 08` minus tare `stageid 04`), capped at `LIPS-LFIMG` |
| `entry_uom` | `LIPS-MEINS` |
| `batch` | `LIPS-CHARG` |
| `deliv_numb` / `deliv_item` | `LIPS-VBELN` / `LIPS-POSNR` |
| `po_number` / `po_item` | **not passed** |
| header `ref_doc_no` | delivery number, or DDC GST invoice number |
| header `bill_of_lading` | `ZLETILMSDELIVERY-LRNUMBER` / DDC bilty number |
| header dates | `sy-datum`, or DDC GST invoice date |

### Controls worth reusing

- **Duplicate GR guard:** `SELECT SINGLE MAX( mblnr ) FROM matdoc WHERE vbeln_im = <delivery> AND vbelp_im = <item> AND bwart = '101' AND cancelled = ' '`. Non-initial means already received; raises `ZLE/203` carrying the existing material document number. A ready-made idempotency check at delivery-item level.
- **Replay/concurrency guard:** `ZLETILMSDELIVERY-ZMIGO_PROC` is set to `X` before processing and cleared after; a second attempt while set raises `ZLE/070`.
- **Over-receipt control:** quantity is capped at the delivery quantity, never the PO quantity - exactly the behaviour the 31 August meeting asked for.
- **Shortage handling:** the difference is appended as a **second BAPI item** with `stck_type = '3'` (blocked stock), rather than rejected. Incoterm-dependent (`EXW`/`FOR`/`EXN`/`FON`).
- **Open PO quantity cap:** for rail/multimodal (`EKPV-VSBED = '04'`) it calls `BAPI_PO_GETDETAIL` and caps at `withdr_qty - deliv_qty`.

### EXTENSIONIN is populated

This closes an open question. The DDC branch passes structure `MSEG`, field `LSMNG`, with the quantity as the value. The extension mechanism is in live use on the BAPI path, not merely declared.

### Custom MIGO header is written by the caller, not by the BAdI

After a successful commit the program does `MODIFY zmmt_migo_hdr` itself with `mblnr`, `mjahr`, `lifnr` (forwarding agent), `vhcle`, `token`, `model` (from `ZLET_VEHICLE`), `tname` (from `I_CUSTOMER`), and where DDC applies `lrdat`, `lfsnr`, `ebill`, `edate`, `afrno`, `afrdt`, `lovct`, `chldt`, `chlno`.

This is the most consequential finding for the API design: **the custom C&F additional data does not depend on the MIGO screen or on `MB_MIGO_BADI` firing.** A BAPI caller populates `ZMMT_MIGO_HDR` directly after commit. A C&F wrapper can do the same.

## How PO stays out of the request but not out of SAP

The ILMS callers set `mvt_ind = 'B'` - in BAPI terms, *goods receipt for purchase order* - while supplying `deliv_numb`/`deliv_item` and no PO fields. SAP is therefore told the receipt is PO-referenced and resolves the purchase order from the delivery itself.

This reconciles the two positions held during this investigation:

- The underlying PO/STO relationship **is** still followed inside SAP. The earlier prediction was right about that.
- But the caller supplies no PO, **and the wrapper does not need to derive one either**. SAP resolves it from the delivery reference.

The one exception is the rail/multimodal branch in `ZLEIILMSDOCUMENTS_GOODSREC` (`EKPV-VSBED = '04'`), which deliberately reads the PO via `BAPI_PO_GETDETAIL` to cap the receipt at the remaining open quantity. That is a quantity control, not a reference requirement.

Worth confirming at runtime: whether `mvt_ind = 'B'` with delivery-only references behaves the same through `API_MATERIAL_DOCUMENT_SRV` as it does on the direct BAPI path.

## Two things the sweep did not close

**Storage Location is not derived from the delivery.** It is a constant or a plant rule in every caller inspected - `'GDF'` in `ZLEIILMSDOCUMENTS_GRN_BTST`, `'RMYD'` in `ZLEIILMSDOCUMENTS_GOODSREC`, silo-based at plant `3791`. For C&F this is a business rule that has to be supplied, not something the wrapper can work out.

**`MB_MIGO_BADI` validations still do not fire on a BAPI or OData path.** The *data capture* concern is resolved - the ILMS callers write `ZMMT_MIGO_HDR` directly after commit, so the custom fields do not depend on the MIGO screen. The *validations* in `ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` are a separate matter and would have to be reimplemented in any C&F wrapper that needs them.

## Derivation matrix

| Caller | Reference | PO to BAPI | Material | Plant | SLoc | Quantity | Unit | Custom processing |
|---|---|---|---|---|---|---|---|---|
| `ZLEIILMSDOCUMENTS_GRN_BTST` | Delivery + item | **None** | `LIPS-MATNR` | `LIKP-WERKS` | const `'GDF'` | `LIPS-LFIMG` | `LIPS-MEINS` | Duplicate-GR guard; writes `ZMMT_MIGO_HDR` |
| `ZLEIILMSDOCUMENTS_GOODSREC` | Delivery + item | **None** | `LIPS-MATNR` | `LIPS`/`LIKP`/token | const `'RMYD'` or silo | Weighbridge, capped at `LFIMG` | `LIPS-MEINS` | Duplicate + replay guards, shortage to blocked stock, `EXTENSIONIN` `MSEG-LSMNG`, writes `ZMMT_MIGO_HDR` |
| `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01` | Delivery + item | Derived from `LIPS-VGBEL/VGPOS` | From `LIPS` | - | - | - | - | PO derived, not caller-supplied |
| `ZMMR_STO_GR_SUB` | Delivery + item + PO | Supplied from own selection | - | - | - | - | - | - |
| `ZMM_MIGO_POSTING` | Delivery commented out | Input | BAPI/reference | BAPI/reference | Input | Input | Input | Extension population unproven in 101 branch |
| `ZMM_STO_AUTO_POSTING` | Derived and supplied | Derived and supplied | BAPI/reference | BAPI/reference | From STO/PO context | From billing | From billing | No MIGO-screen proof |

## What this means for Submit MIGO

Option B in the handover - one business POST with SAP-side derivation - is no longer only "architecturally feasible". A working delivery-referenced 101 posting path with duplicate control, delivery-quantity capping, shortage handling and custom-header population already exists in QS4 and can be read as a specification.

Two things remain genuinely open:

1. Whether `API_MATERIAL_DOCUMENT_SRV` accepts the same minimal field set, or whether its `item_check_allowed_fields` demands Material/Plant/Quantity/Unit anyway. The ILMS callers bypass OData entirely. This still needs the fresh-delivery runtime test.
2. Which of the ILMS business rules are C&F rules and which are yard/ILMS-specific. The weighbridge quantity, token and DDC register are ILMS concepts; C&F may have a different quantity source. That is a business question for the client, not a discovery question.

## The decisive untested case - OData vs BAPI

The historical pre-review Postman pack (excluded from Git after review) carried saved SAP responses that constrain this question directly.

| `GoodsMovementRefDocType` | PO + Delivery sent | Delivery only, no PO |
|---|---|---|
| omitted | **400** - `MM_IM_ODATA_API_MDOC/011` "Property PURCHASEORDER is not supported for GoodsMovementType 101" | - |
| `L` | - | **400** - "Property DELIVERY is not supported for GoodsMovementType 101" |
| `B` | **201** - material document `5007138616/2026` | **never sent** |

The service enforces an allowed/mandatory property set per movement type and reference document type, consistent with `item_check_allowed_fields` calling `get_relevant_fields`. The earlier delivery-only attempt used reference type `L` and was rejected.

The ILMS callers use **`mvt_ind = 'B'` with delivery references and no PO**, and post successfully in production. That proves the combination is valid at BAPI level. It does **not** prove `API_MATERIAL_DOCUMENT_SRV` permits it, because the OData allowed-field check runs before the BAPI is reached and has already been shown to reject properties the BAPI itself would accept.

The reviewed collection (`... - Reviewed/CNF_SubmitMIGO.postman_collection.json`) sends exactly that untested combination - reference type `B`, `Delivery` + `DeliveryItem`, no PO - and has never been fired at SAP.

Outcomes:

- **201** - the standard service supports delivery-referenced receipts. A wrapper is still wanted, because Material, Plant, Storage Location, Quantity and Unit remain caller fields on that path.
- **400 "Property DELIVERY is not supported"** - the wrapper becomes mandatory rather than optional, with a quotable reason.

This is the single highest-value outstanding test, and the request is already built. It needs one fresh PGI-complete, GR-pending delivery item allocated to it.

## Method note

Sources captured read-only via SAP GUI scripting: SE38 `Program > Display`, `SelectAll`, `Utilities > Block/Clipboard > Copy to Clipboard`, clipboard read into `src/`. No program was opened in Change mode, edited, activated or executed. Scripts: `outputs/sap-gui-script/grab-se38-source.vbs` and `sweep-sources.ps1`.

## Sources captured

`src/` holds 14 of the `BAPI_GOODSMVT_CREATE` callers from the QS4 where-used list: `ZLEIILMSDOCUMENTS_GOODSREC`, `ZLEIILMSDOCUMENTS_GRN_BTST`, `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01`, `ZMMR_STO_GR_SUB`, `ZDACE_GOODS_MOVEMENT_CLS`, `ZSD_BACK_SHORTAGE_CLASS`, `ZEWME001_CUSTOM_MIGO_TR_FORM`, `ZEWM_CUSTOM_MIGO_TR_FORM`, `ZMMR_GAS_CYL_FRM`, `ZMM_GI_LOAN`, `ZMM_INITIAL_STOCK_UPLOAD_F`, `ZMM_INITIAL_STOCK_UPLOAD_F_STG`, `ZPP_MP_DIVERSION_AUTOPGI_PAI`, `ZMM_MIGO_POSTING_FORMS`.

`LZSD_PURULIAU05` resolves to function module `ZSD_INTRCO_MIGO` and is saved as `src/ZSD_INTRCO_MIGO.txt`.

## `ZSD_INTRCO_MIGO` - a transaction envelope, not a derivation wrapper

Function group `ZSD_PURULIA` ("Delivery Create"), short text "Intercompany Sales Migo". **Processing type: Regular Function Module - not remote-enabled.** So it is an internal ABAP helper, not a callable service endpoint.

Its whole body:

- takes `GOODSMVT_HEADER` and the `GOODSMVT_ITEM` table straight from its caller and passes them through unchanged;
- hardcodes `goodsmvt_code = '01'`;
- calls `BAPI_GOODSMVT_CREATE`;
- `BAPI_TRANSACTION_COMMIT WAIT = 'X'` when a material document comes back, `BAPI_TRANSACTION_ROLLBACK` when it does not;
- returns material document, year, `GOODSMVT_HEADRET` and the `BAPIRET2` table.

It performs **no derivation at all** - no `LIPS` read, no field defaulting, no validation, no `EXTENSIONIN`.

Relevance to C&F: low as a derivation model, but it is a clean precedent for the **commit/rollback envelope** the Submit MIGO wrapper needs - post, commit on success, roll back on failure, return document number/year plus messages in one call. The ILMS callers remain the model for derivation. Its caller was not traced; not worth the time given the delivery-only question is already answered.
