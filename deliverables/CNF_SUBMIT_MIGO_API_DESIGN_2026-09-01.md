# C&F Submit MIGO — API design

> **Target contract, not current implementation.** The delivery-led request remains the intended external shape. `CURRENT_STATE.md` and the 4 September customisation disposition control implementation status: the supported BAdI path is not proven and required transaction-side validations are not yet available on the API path.

**1 September 2026**
**Scope:** Goods receipt for C&F against outbound delivery, movement type 101

---

## The call

One POST. The C&F application sends the delivery reference. SAP does everything else and returns the material document.

**Request**

| Field | Mandatory | Notes |
|---|---|---|
| `DeliveryNumber` | Yes | Outbound delivery |
| `DeliveryItem` | Yes | Delivery item |
| `Quantity` | No | Omit to receive the full open delivery quantity. If supplied, validated against it and rejected if higher. |

Nothing else. No PO Number, no PO Item, no Material, no Plant, no Storage Location, no Unit, no Movement Type, no dates.

**Response**

| Field | Notes |
|---|---|
| `MaterialDocument` | Document number |
| `MaterialDocumentYear` | Document year |
| `Messages` | SAP messages, type and text |

On failure: no document, and the SAP messages explaining why.

---

## Everything SAP derives

This is the whole point of the design: every value the posting needs is already reachable from the delivery. Nothing below is asked of the caller.

### Posting fields

| Field | Derived from |
|---|---|
| Material | Delivery item |
| Receiving Plant | Delivery header, with plant rules applied |
| Storage Location | Standing rule for the receiving plant |
| Quantity | Open delivery item quantity (or the requested quantity, capped at it) |
| Unit of Measure | Delivery item |
| Batch | Delivery item |
| Movement Type | Fixed, 101 |
| Movement Indicator | Fixed, goods receipt against delivery |
| Posting Date / Document Date | System date |
| Reference | Delivery number |
| PO Number / PO Item | Read from the delivery item's own source document, only where SAP needs it internally. Never asked of the caller, never in the response contract. |

### C&F additional fields

These come from the delivery's yard record and its token, all reachable from the delivery number and item:

| Field | Derived from |
|---|---|
| Token | Yard delivery record for this delivery item |
| LR Number | Yard delivery record |
| AFR / hazardous manifest number, date, count | Yard delivery record |
| Vehicle Number | Token |
| Vehicle Type / Model | Vehicle master, by vehicle number |
| Transporter / Forwarding Agent | Token |
| Transporter Name | Customer master, by forwarding agent |
| Challan Number and Date | DDC register, where a DDC reference exists on the token |
| GST Invoice Number and Date | DDC register |
| E-Way Bill Number and Date | DDC register |

After the goods receipt is posted and confirmed, these are written to the custom MIGO header table against the new material document number and year — the same way the existing yard receipt programs do it.

---

## Controls applied inside the call

The caller does not have to check any of this first. It is part of the same POST.

**Duplicate receipt.** Before posting, SAP checks whether a 101 goods receipt already exists for that delivery item and has not been cancelled. If one does, the call is rejected and the existing material document number is returned in the message. A retry or a double-tap in the C&F app cannot create a second receipt.

**Concurrency.** A processing flag on the yard delivery record prevents two simultaneous calls from posting the same delivery item.

**Over-receipt.** The quantity can never exceed the delivery item quantity. Where an open PO limit also applies, it is additionally capped at the remaining open quantity.

**Short receipt.** Where the received quantity is less than the delivery quantity, the shortfall is posted as a second line into blocked stock rather than the call failing. *Subject to confirmation for C&F — see below.*

**Transaction integrity.** Post and confirm happen as one unit. If the posting fails, it is rolled back and nothing partial remains.

---

## Where the derivation logic comes from

For the build team, so nobody has to rediscover this:

| What | Source in QS4 |
|---|---|
| Delivery-based 101 posting with no PO passed at all | `ZLEIILMSDOCUMENTS_GRN_BTST` — the minimal form |
| The same plus quantity capping, shortage-to-blocked-stock, duplicate and concurrency guards, and the custom-header write | `ZLEIILMSDOCUMENTS_GOODSREC` |
| PO derived from the delivery item's source document rather than supplied | `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01` |
| Post-and-commit / rollback envelope in a single callable unit | `ZSD_INTRCO_MIGO` |

The derivation chain from `DeliveryNumber` + `DeliveryItem`:

```
LIPS / LIKP            → material, plant, quantity, unit, batch, source PO
ZLETILMSDELIVERY       → token, LR number, AFR manifest fields
ZLETILMSTOKEN          → vehicle number, forwarding agent, DDC reference
ZLET_VEHICLE           → vehicle type
I_CUSTOMER             → transporter name
ZLETDDCREGISTER        → challan, GST invoice, e-way bill
MATDOC                 → duplicate-receipt check
```

Two clarifications on programs discussed earlier:

- `ZMM_MIGO_POSTING` and `ZMM_STO_AUTO_POSTING` are **not** the derivation model. The first takes material, plant, quantity and unit from an uploaded file; the second builds them from a document chain it has just created itself. Neither reads a delivery to work them out. The yard programs above are the model.
- `ZMMR_MIGO_SCREEN_ADD` is the **MIGO screen** program. It reads live MIGO session memory, so it cannot be called from an interface. The custom fields are not sourced from it — they are sourced from the yard tables listed above, which is why they remain available on an API path.

---

## How it is built

The standard material document service maps caller fields straight through to the posting BAPI and derives nothing. A delivery-only contract therefore needs a thin SAP-side wrapper. Almost all of its logic already exists in QS4 and is being reused rather than invented.

### The sequence

**1. Read the delivery item**

`LIPS` by delivery + item, `LIKP` by delivery. Gives material, plant, delivery quantity, unit, batch, and the source document (`VGBEL`/`VGPOS`).
Not found, or item deleted, → reject.

**2. Check it is receivable**

`LIPS-WBSTA = 'C'` (goods movement status complete) with `LIPS-BWART = '641'`. Confirmed against live QS4 delivery data on 2 September; this is the item-level PGI-complete test.

Note that `WBSTA = 'C'` alone is not sufficient - it says the issue happened, not that the receipt has not. The `MATDOC` check in step 3 is what establishes GR-pending.

**3. Duplicate check** — lifted from `ZLEIILMSDOCUMENTS_GOODSREC`

```abap
SELECT SINGLE MAX( mblnr ) FROM matdoc
  WHERE vbeln_im  = @lv_vbeln
    AND vbelp_im  = @lv_posnr
    AND bwart     = '101'
    AND cancelled = @space
  INTO @lv_existing.
```

Non-initial → return the existing material document with an "already received" message rather than an error. This is the idempotency behaviour the C&F app and CPI need for retries.

**4. Lock the delivery item**

Prevents two simultaneous calls posting the same item. ILMS uses a processing flag on its own table; for C&F a standard enqueue on delivery + item is cleaner and does not depend on a yard record existing.

**5. Work out the open quantity**

Delivery item quantity less anything already received on it. Requested quantity, if supplied, is capped at that. Where the delivery came in by rail or multimodal, additionally capped at the remaining open PO quantity via `BAPI_PO_GETDETAIL`, as `ZLEIILMSDOCUMENTS_GOODSREC` does.

**6. Build the BAPI item** — the `ZLEIILMSDOCUMENTS_GRN_BTST` shape

| Field | Value |
|---|---|
| `material` | `LIPS-MATNR` |
| `plant` | `LIKP-WERKS` |
| `stge_loc` | C&F storage location rule — **see open point 3** |
| `move_type` | `'101'` |
| `mvt_ind` | `'B'` |
| `entry_qnt` | open quantity from step 5 |
| `entry_uom` | `LIPS-MEINS` |
| `batch` | `LIPS-CHARG` |
| `deliv_numb` / `deliv_item` | request input |
| `deliv_numb_to_search` / `deliv_item_to_search` | delivery, and `LIPS-UECHA` where the item is a batch split |
| `po_number` / `po_item` | **not set** |

Header: posting and document date `sy-datum`, `ref_doc_no` the delivery, `bill_of_lading` the LR number from step 7, goods movement code `'01'`.

**7. Derive the C&F additional fields**

```
ZLETILMSDELIVERY  by delivery + item  → token, LR number, AFR manifest fields
ZLETILMSTOKEN     by token            → vehicle number, forwarding agent, DDC reference
ZLET_VEHICLE      by vehicle number   → vehicle type
I_CUSTOMER        by forwarding agent → transporter name
ZLETDDCREGISTER   by DDC reference    → challan, GST invoice, e-way bill
```

**8. Post, then commit or roll back** — the `ZSD_INTRCO_MIGO` envelope

Call `BAPI_GOODSMVT_CREATE`. If a material document comes back, `BAPI_TRANSACTION_COMMIT WAIT = 'X'`. If not, `BAPI_TRANSACTION_ROLLBACK` and return the messages. Nothing partial is ever left behind.

**9. Write the custom header**

`MODIFY zmmt_migo_hdr` with the new material document and year plus the step 7 values, exactly as the ILMS programs do after their commit.

**10. Return**

Material document, year, and the SAP messages.

### What is reused and what is new

| Reused as-is | New for C&F |
|---|---|
| Delivery-only BAPI item shape | Storage location rule |
| Duplicate-receipt check | Open-quantity calculation across partial receipts |
| Quantity capping and open-PO cap | Enqueue-based locking |
| Custom-field derivation chain | Any `MB_MIGO_BADI` validation C&F depends on |
| Custom header write | Error message mapping for the portal |
| Commit / rollback envelope | |

### How it is exposed

`ZMM_IFMS_AUTO` already proves the pattern in QS4: a custom HTTP handler that accepts JSON business fields, derives everything internally, calls the posting BAPI, commits, and returns a simplified JSON result. A C&F endpoint built the same way gives one POST with no business GET in front of it.

A custom endpoint is also what makes the session and token handling a decision we control, rather than one inherited from the standard OData service. Whether a CSRF token is required remains a landscape and security decision to be confirmed with Basis and the CPI team — it is not something the wrapper design settles on its own.

## Three points to confirm before build

**1. The yard record dependency.** The C&F additional fields — token, vehicle, transporter, LR, e-way bill — are derived from the yard delivery record and its token. They are only derivable if the C&F delivery has one.

Three possible answers, and the design differs for each:

- C&F deliveries always pass through the yard and carry a token → derivation works exactly as above, nothing more needed.
- C&F deliveries sometimes have no token → those fields become optional request inputs, used only when derivation finds nothing.
- These fields are not required for a C&F receipt at all → they are dropped from the C&F path entirely.

This is the one question that changes the request contract. Everything else in this document holds regardless of the answer.

**2. Quantity behaviour.** The design above defaults to the full open delivery quantity and accepts an optional lower quantity. Confirm whether C&F agents may receive a part quantity, and whether short receipts should go to blocked stock as they do in the yard process or be handled differently.

---

**3. The storage location rule.** This is the one field in the design that cannot be derived from the delivery. The existing programs use a fixed value per process - `'GDF'` in one, `'RMYD'` in the other, and a silo-based value at plant `3791`. C&F needs its own rule: a single value, a value per receiving plant, or a small configuration table if it varies by material or depot. Whatever the answer, it should be configuration rather than hardcoded, so it can change without a transport.

## What this replaces

The earlier Submit MIGO request carried Material, Plant, Storage Location, Quantity, Unit, Movement Type, Delivery and Delivery Item. PO Number and PO Item have already been removed from it.

This design reduces that to **Delivery Number and Delivery Item**, with quantity optional. The remaining fields are not removed from SAP — the goods receipt still posts with all of them — they are simply no longer the caller's responsibility.
