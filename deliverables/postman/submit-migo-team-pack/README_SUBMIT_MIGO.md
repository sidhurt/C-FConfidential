# Submit MIGO — Postman test pack

**Runtime-certified on QS4/700, 2026-08-25.**
v1.9 sheet **MIGO-02, Submit MIGO**.

| File | What it is |
|---|---|
| `CNF_SubmitMIGO.postman_collection.json` | 9 requests, 4 saved example responses |
| `CNF_SubmitMIGO_QS4.postman_environment.json` | QS4/700 environment. **No password stored** |

---

## The headline: the request carries BOTH the purchase order and the delivery

**One purchase order line can have many deliveries, and a goods receipt is raised per
delivery.** So purchase order plus item alone does not identify what you are receiving.

This is not theoretical. Live QS4 data:

| STO | Delivery items against ONE PO line |
|---|---|
| `5600071885` item 10 | ~16 |
| `5600071018` item 10 | ~12 |
| `5600084209` item 10 | 3 |

**But you do not send the delivery *instead of* the purchase order.** That is rejected:

```
GoodsMovementRefDocType = "L" + Delivery only
HTTP 400  Property DELIVERY is not supported for GoodsMovementType 101
```

SAP wants **both references together**, with `GoodsMovementRefDocType = "B"`.

That is confirmed independently by the client's own live receipts. Every sampled STO goods
receipt in QS4 carries `MSEG-KZBEW = B` (purchase order) **and** a populated
`MSEG-VBELN_IM` (delivery):

```
5007138549   KZBEW=B   PO 5600084213/00010   VBELN_IM 9004953132/000010   MIGO_GR
5007138552   KZBEW=B   PO 5600075302/00010   VBELN_IM 9004953107/900001   MIGO_GR
5007138553   KZBEW=B   PO 5600075921/00010   VBELN_IM 9004953138/900001   MB01
```

The delivery is an **additional** reference, not a replacement.

---

## What has been proven

```
POST /sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader
HTTP 201 Created
Material document 5007138616 / year 2026
```

4 EA of material `17035056` into plant `1022` / `FKGU`, purchase order `5600084238` item
`00010`, **delivery `9004953150` item `000010`**.

Verified independently of the API's own answer:

1. **OData `$expand` readback** returned the item, echoing `Delivery 9004953150/10`
2. **`MSEG` read directly in SAP** — `BWART 101`, `KZBEW B`, `WERKS 1022`, `LGORT FKGU`,
   `EBELN/EBELP 5600084238/00010`, **`VBELN_IM 9004953150/000010`**

That document is now shape-identical to the client's own `MIGO_GR` receipts.

Both rejection cases are proven too, and both are in the collection as runnable requests.

---

## Setup, once

1. Import both files.
2. Select the **CNF Submit MIGO — QS4/700** environment.
3. Put your own password in `sap-pass`. It ships empty on purpose — do not commit it back.
4. **Settings → General → SSL certificate verification = OFF** (internal CA), or install the CA chain.
5. **Leave cookie handling ON.** The CSRF token is worthless without its session cookie, and
   the failure looks like an auth error rather than a CSRF error.

---

## Run order

### Folder 0 — Setup
Run **Fetch CSRF token**. Stores it in `{{csrf}}`. Re-run if you get a `403` on the POST.

### Folder 1 — Find an eligible STO item

An item is receivable only when **both** hold:

- **(a)** a goods issue (movement `641`) has posted, so **stock in transit** exists, and
- **(b)** that delivery has not already been received

**Candidate STO items in plant** narrows the list. **Deliveries raised against this STO** then
lists the deliveries — this is where you pick the one you are receiving.

**Neither can check condition (a).** The purchase order OData service exposes **no
goods-received quantity at all** — `A_PurchaseOrderScheduleLine` has
`ScheduleLineOrderQuantity` and nothing on the receipt side. Confirm the `641` in SAP GUI:

- **`MB5T`** — stock in transit, or
- **`ME23N`** → item → **Purchase Order History** → a `VGABE=6 / BEWTP=U` row with movement `641`

### Folder 2 — Submit MIGO

Set from the delivery you chose:

| Variable | Notes |
|---|---|
| `material` | **zero-padded to 18** |
| `receivingPlant`, `storageLocation` | |
| `quantity`, `unit` | |
| `purchaseOrder` | |
| `purchaseOrderItem` | **zero-padded to 5**, e.g. `00010` |
| `delivery` | |
| `deliveryItem` | **zero-padded to 6**, e.g. `000010` — or `900001` for a batch split |

Set **`confirmSubmitMIGO = YES`**, run the POST, then run the **readback**.

Both negatives are safe and create nothing. Run them once so you recognise the errors.

### Folder 3 — Verify in SAP GUI
Not callable. The manual checks that prove the posting independently.

---

## The four things that will trip you up

### 1. `GoodsMovementRefDocType: "B"` is mandatory and the error names the wrong field

Omit it:

```
MM_IM_ODATA_API_MDOC/011  Property PURCHASEORDER is not supported for GoodsMovementType 101
```

It points at the purchase order fields. The field actually missing is the **reference document
type** — the OData equivalent of `MVT_IND` in `BAPI_GOODSMVT_CREATE`, where `B` = goods
movement for a purchase order. Reproduced on two different purchase orders, so it is
structural. Negative request A.

### 2. Do not send the delivery instead of the purchase order

`RefDocType = L` with `Delivery`/`DeliveryItem` and no PO is rejected with
*Property DELIVERY is not supported for GoodsMovementType 101*. Send both. Negative request B.

### 3. Batch splits — post against the item carrying the quantity

For batch-managed materials the delivery has **pairs**: a parent item `000010` with quantity
`0.000` and a child item `900001` with the real quantity. Post the one with the quantity. Two
of the three sampled live receipts reference `VBELP_IM = 900001`.

### 4. The create response returns an EMPTY item array — on success

```json
"to_MaterialDocumentItem": { "results": [] }
```

Normal. **Do not treat it as failure and do not read quantities from it.** Always run the
readback. The `location` response header also carries the created key.

---

## Other things worth knowing

- There is **no test run**. OData has no `TESTRUN`. A success posts a real document, undone by
  a **reversal** (movement `102`), not a delete.
- Service path is **plain** — `API_MATERIAL_DOCUMENT_SRV`, no `;v=1`.
  (Contrast: `API_OUTBOUND_DELIVERY_SRV` **does** require `;v=2`.)
- `PurchaseOrderItem` and `DeliveryItem` are sent padded and returned **unpadded**. Not a mismatch.
- The key is **composite and the year comes first**:
  `A_MaterialDocumentHeader(MaterialDocumentYear='2026',MaterialDocument='5007138616')`
- `PostingDate` is set by the pre-request script to today at UTC midnight — the form SAP accepted.
- The **MM period must be open**. QS4 company code `1000` is on period `2026/05`, April–March
  fiscal variant. A closed period gives `M7/053`.
- `CtrlPostgForExtWhseMgmtSyst` is deliberately omitted — it can produce a delivery instead of
  a material document.

---

## Scope

**Certified:** the standard OData create path posts a real goods receipt against a real STO
delivery, persists it, and records both the purchase order and the delivery link.

**Not certified:** reversal (`102`), duplicate-request behaviour, authorization failure, vendor
(non-STO) receipts, batch-managed materials end to end, partial receipts, and over-delivery.

**Open item for MM:** on the earlier certified posting, `EKBE` showed the goods issue valued at
`10,867.50 INR` and the goods receipt at `0.00`, and `MSEG-DMBTR` was likewise `0.00`. For a
stock transfer the receiving value normally derives from the issuing plant. **Not established**
either way — needs an MM answer before any value field enters an external contract.

---

## Note on the default environment values

The environment ships pointing at the **exact proven combination** — PO `5600084238` item
`00010`, delivery `9004953150` item `000010`, 4 EA.

**That delivery has now been received and cannot be reused.** Use folder 1 to pick a fresh one
and re-confirm stock in transit before posting. The payload shape is what is proven, not the
availability of any particular document.
