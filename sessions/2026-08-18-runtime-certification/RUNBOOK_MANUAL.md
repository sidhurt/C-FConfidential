# Manual runbook — payloads to push, DS4/200

**System: DS4 client 200.** Everything here is a write-authorised test system.
**Payload folder:** `sessions/2026-08-18-runtime-certification/payloads/odata/`

Report back: HTTP status, the **response body text**, and any document number.

---

## THE ONE THING ONLY YOU CAN DO

I can drive the GUI but I **cannot read the response body pane** — it's an HTML control that scripting can't extract, and the Gateway error log came back with **0 rows**, so the 400 wasn't logged there either.

You can just look at the screen.

**So on every OData run below: read the response pane on the right and tell me the `<message>` text.** That single thing unblocks everything else.

---

# PART 1 — OData, in `/IWFND/GW_CLIENT`

## How to load a body (this works, I verified it)

1. Set **HTTP Method = POST**
2. Paste the **Request URI**
3. On the **HTTP Request** panel (left), click **Add File**
4. In the dialog: **Directory** = the payload folder path, **File Name** = the json file
5. Press **Continue** (green tick)
6. Press **Execute** (F8)
7. **Read the response pane on the right**

---

## Run 1 — STO PO create *(already run once, need the message)*

**Method:** `POST`
**URI:**
```
/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder
```
**Body file:** `STO_PO_CREATE_UB_min.json`

**Already got:** HTTP **400 Bad Request**, 742-byte XML body, 4.8 s.
**Need:** the `<message>` text inside that XML.

Likely candidates — the message will tell us which:
- material `MAT18` not extended to plant `PLQ1`
- plant `PLQ1` not assigned to purchasing org `0001`
- company code `1000` wrong for those plants
- `UB` not allowed for that plant combination

**Then try `STO_PO_CREATE_UB_full.json`** (adds currency, dates, schedule line) and report that message too — the difference between the two tells us which fields are mandatory.

---

## Run 2 — Does the STO PO service read at all

**Method:** `GET`
```
/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?$top=5&$format=json
```
Expect an empty collection. Confirms routing works and the 400 is genuinely validation, not plumbing.

---

## Run 3 — Prove the delivery service is v2

**Method:** `GET`
```
/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/$metadata
```
Search the response for `PickAndBatchSplitOneItem`. If present, v2 is right. If you drop the `;v=2` it should be missing — worth doing both to have the contrast on record.

---

## Run 4 — Book stock

**Method:** `GET`
```
/sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/A_MatlStkInAcctMod?$filter=Material eq 'MAT18'&$format=json
```
Expect empty (`MARD` is empty). Confirms the read path.

---

# PART 2 — BAPIs, in `SE37`

For each: enter the name → **Display** → **F8** (Test).

Structures show as a row — **double-click the row name** to open it, fill fields, **F3** to come back.

### Reaching fields that are off-screen

Structures are laid out left-to-right and the wide ones run off the edge. In the structure editor use the **Column** button (tooltip *Position, Ctrl+Shift+F8*) and type the field name to jump straight to it. That's how you reach `SUPPL_PLNT`.

---

## Run 5 — STO PO via BAPI, simulation *(highest value)*

**`BAPI_PO_CREATE1`**

Set **`TESTRUN = X`** first — field is on the main test screen, row 12, the value column. Nothing gets created.

**POHEADER** (row 9 — double-click it):

| Field | Value | Where it sits |
|---|---|---|
| `COMP_CODE` | `1000` | col 12 |
| `DOC_TYPE` | `UB` | col 17 |
| `PURCH_ORG` | `0001` | col 107 |
| `PUR_GROUP` | `001` | col 112 |
| **`SUPPL_PLNT`** | **`PLQ3`** | **off-screen — use Column/Position** |

Leave `VENDOR` empty. STOs have no vendor.

**POHEADERX** (row 10) — set `X` in every one of the same fields. **If you skip this the BAPI silently ignores the values.** This is the single most common failure.

**POITEM** (row 29):

| Field | Value |
|---|---|
| `PO_ITEM` | `00010` |
| `MATERIAL` | `MAT18` |
| `PLANT` | `PLQ1` |
| `ITEM_CAT` | `7` |
| `QUANTITY` | `1` |
| `PO_UNIT` | `EA` |

**POITEMX** (row 30) — `PO_ITEM` = `00010` plus `X` in each of the others.

**Execute (F8).** Open the `RETURN` table on the result screen and report **every row**: type, ID, number, message.

Compare against the `ZP06` run, which gave `ME 013 — Document type ZP06 not allowed with doc. category F`. If `UB` gets past that, we know it's purely a config gap; if it fails elsewhere, that's the real prerequisite list.

---

## Run 6 — Goods movement, simulation

**`BAPI_GOODSMVT_CREATE`**

- `GOODSMVT_CODE` = `01` (goods receipt for PO — from `T158G`)
- `TESTRUN` = `X`
- `GOODSMVT_HEADER`: `PSTNG_DATE` and `DOC_DATE` = today
- `GOODSMVT_ITEM` one row: `MATERIAL` `MAT18`, `PLANT` `PLQ3`, `STGE_LOC` (pick one), `MOVE_TYPE` `101`, `ENTRY_QNT` `1`, `ENTRY_UOM` `EA`

Report the whole `RETURN`. This tests whether `01` is the right movement code in this client, which is still an open item in the workbook.

---

## Run 7 — Billing create, simulation

**`BAPI_BILLINGDOC_CREATEMULTIPLE`**

- `TESTRUN` = `X`
- `BILLINGDATAIN` one row: `REF_DOC` = a delivery number, `REF_DOC_CA` = `J`

DS4 has no deliveries, so expect it to fail on the reference — **that failure message is still useful**, it tells us what it validates first.

---

## Run 8 — Shipment cost settle *(the real unknown)*

**`SD_SCDS_RELEASE`**

Only worth running once a freight document exists. Two things to note when you do:

- `I_OPT_WITH_DIALOG` defaults to `X` — **set it to blank** for an unattended call
- `I_REFOBJ_TAB` takes the reference object, same shape as the create: `VBTYP` = `8`, `REBEL` = the shipment number

This is the one step with zero known callers anywhere in the system. Whatever it does is new information.

---

# PART 3 — What already exists in DS4 from tonight

| Object | Number | State |
|---|---|---|
| Shipment | **`1001`** | Created and committed. Type `0001`, planning point `0001`, no deliveries. Delete via `VT02N` when done. |
| Shipment | `1000` | Number consumed, document never saved — nothing to clean up. |

Shipment `1001` is a valid target for `SD_SCDS_CREATE` experiments.

---

# PART 4 — What to send back

For each run:

1. Which run number
2. HTTP status **or** the full `RETURN` table
3. **The response body / message text** — this is the bit I can't get
4. Any document number created
5. Whether anything appeared in `VTTK` / `VFKK` / `EKKO` afterwards

Even a one-line message from Run 1 moves this forward more than anything else on the list.
