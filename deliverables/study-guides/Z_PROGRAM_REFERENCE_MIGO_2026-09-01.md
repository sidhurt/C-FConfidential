# Custom MIGO logic — the three questions, and what answers them

**1 September 2026. QS4/700.** Sources in `sessions/2026-09-01-bapi-field-derivation/src/`.

---

## Two programs answer everything

Both are includes of the same ILMS (yard) program. Everything else in the where-used list is noise.

| The question | Answered by | The answer |
|---|---|---|
| **1. No PO** | `ZLEIILMSDOCUMENTS_GRN_BTST` | Posts 101 against a delivery with `po_number` and `po_item` never set |
| **2. Standard fields** | `ZLEIILMSDOCUMENTS_GRN_BTST` | Material, plant, quantity, unit, batch all read from `LIPS` / `LIKP` |
| **3. Custom fields** | `ZLEIILMSDOCUMENTS_GOODSREC` | Writes `ZMMT_MIGO_HDR` itself after commit, from the yard tables |

That is the whole finding.

---

## 1 & 2 — no PO, and the standard fields

`ZLEIILMSDOCUMENTS_GRN_BTST`, about 60 lines:

```abap
material   = LIPS-MATNR      entry_qnt  = LIPS-LFIMG
plant      = LIKP-WERKS      entry_uom  = LIPS-MEINS
stge_loc   = 'GDF'           batch      = LIPS-CHARG
move_type  = '101'           mvt_ind    = 'B'
deliv_numb = LIPS-VBELN      deliv_item = LIPS-POSNR
```

Header is posting date, document date, `gm_code = '01'`. Then `BAPI_GOODSMVT_CREATE`, then `BAPI_TRANSACTION_COMMIT`.

Delivery in, material document out. No PO anywhere.

**Note `mvt_ind = 'B'`** — that tells SAP "goods receipt for purchase order" while supplying only delivery numbers. SAP resolves the PO from the delivery itself. So the PO relationship still exists inside SAP; we just never supply it and never derive it.

*If SAP ever does demand it:* `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01` shows the one-line fallback — `po_number = LIPS-VGBEL`, `po_item = LIPS-VGPOS`. Still not a caller input.

---

## 3 — the custom fields

The risk was that Token, LR, transporter and vehicle only get captured through the MIGO screen, and would be lost on an API path.

They aren't. `ZLEIILMSDOCUMENTS_GOODSREC` posts the receipt, commits, then does `MODIFY zmmt_migo_hdr` itself with the new document number and year. No MIGO session involved.

The values chain off the delivery:

```
delivery + item → ZLETILMSDELIVERY  → token, LR number, AFR manifest
                → ZLETILMSTOKEN     → vehicle no, forwarding agent, DDC ref
                → ZLET_VEHICLE      → vehicle type
                → I_CUSTOMER        → transporter name
                → ZLETDDCREGISTER   → challan, GST invoice, e-way bill
```

**`ZMMR_MIGO_SCREEN_ADD` is not the source.** It reads live MIGO memory and *displays* these values. It's the screen, not the origin. The origin is the tables above.

---

## What `GOODSREC` also gives us for free

Same program, worth taking wholesale:

- **Duplicate check** — `MATDOC` on `vbeln_im` + `vbelp_im` + `bwart 101` + not cancelled. Found → return the existing document instead of posting again. Permanent, unlike the 5-minute repeatability window in the Postman pack.
- **Replay guard** — a processing flag set before and cleared after.
- **Quantity capped at the delivery**, never the PO.
- **Shortage** → second BAPI item with `stck_type = '3'`, blocked stock.
- **`EXTENSIONIN`** is genuinely used (`MSEG` / `LSMNG`), so extensions work on the BAPI path.

---

## The two things not answered

**Storage location.** Nobody derives it. It's `'GDF'` in one program, `'RMYD'` in the other, silo-based at plant `3791`. C&F needs its own rule — a value, a per-plant table, whatever. This is the only field in the whole design resting on nothing.

**The BAdI validations.** `ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` holds quantity checks, shortage rules and GRN preparation. It will **not** fire on a BAPI or OData path. The data-capture half doesn't matter — GOODSREC proves the caller can write the custom header itself. The *rules* are the question, and it's a functional one: which of them are C&F rules versus yard rules. No amount of further code reading answers that.

---

## Appendix — why the where-used list was misleading

24 hits, and almost none of them matter:

- **Not goods receipts at all** (different movement types, filtered out immediately): `ZSD_BACK_SHORTAGE_CLASS` 551, `ZEWME001_CUSTOM_MIGO_TR_FORM` and `ZEWM_CUSTOM_MIGO_TR_FORM` transfers, `ZMMR_GAS_CYL_FRM` 309, `ZMM_GI_LOAN` issues, `ZPP_MP_DIVERSION_AUTOPGI_PAI` 344/413, `ZMM_INITIAL_STOCK_UPLOAD_F` and `_STG` from upload files. Standard SAP plant-maintenance callers ignored.
- **101, but everything supplied upstream — no derivation to learn from:** `ZMMR_STO_GR_SUB`, `ZDACE_GOODS_MOVEMENT_CLS`, `ZMM_MIGO_POSTING` (Excel), `ZMM_STO_AUTO_POSTING` (its own document chain).
- **Useful as templates only:** `ZSD_INTRCO_MIGO` — a 40-line post/commit/rollback envelope, no logic. `ZMM_IFMS_AUTO` — an existing custom HTTP endpoint taking JSON, deriving internally, posting, returning JSON. Proof the one-call architecture is already accepted here.
