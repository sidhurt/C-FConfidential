# Submit MIGO (MIGO-02) — persisted success in QS4/700

Date: 2026-08-25
System/client: QS4/700
User: QNOVATE8
Service: `API_MATERIAL_DOCUMENT_SRV` (plain path; `;v=1` not required)
Transport: external HTTPS via `https://vhresqs4ci.sap.shreecement.com:44300`

## Result

**HTTP 201 Created. Material document `5007138597` / year `2026`.**

This is a real, persisted SAP material document, not a connectivity or validation-reachability
result. Creating POST attempts against this purchase order: exactly two — one rejected with no
document created, one accepted.

## The decisive field: `GoodsMovementRefDocType`

The first attempt sent `PurchaseOrder` + `PurchaseOrderItem` with `GoodsMovementType 101` and
`GoodsMovementCode 01`, and was rejected:

```
HTTP 400
MM_IM_ODATA_API_MDOC/011  Property PURCHASEORDER is not supported for GoodsMovementType 101
MM_IM_ODATA_API_MDOC/011  Property PURCHASEORDERITEM is not supported for GoodsMovementType 101
MM_IM_ODATA_API_MDOC/014  Material Document processing failed
```

Adding **`"GoodsMovementRefDocType": "B"`** to the item — and changing nothing else — produced
`201 Created`.

`GoodsMovementRefDocType` is the OData equivalent of `MVT_IND` in `BAPI_GOODSMVT_CREATE`, where
`B` = goods movement for purchase order. Without it the API does not interpret the item as a
PO-referenced receipt, and therefore rejects the PO fields themselves. The error message names
the PO properties, which points the reader at the wrong field; the missing field is the
reference-document type.

**This must be written into the API contract.** A developer following the metadata alone will
send the PO fields, get this error, and reasonably conclude the API does not support PO
receipts. It does.

## Accepted request

```http
POST /sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader?sap-client=700
Content-Type: application/json
Accept: application/json
X-CSRF-Token: <fetched>
```

```json
{
  "PostingDate": "/Date(1787616000000)/",
  "DocumentDate": "/Date(1787616000000)/",
  "GoodsMovementCode": "01",
  "MaterialDocumentHeaderText": "CNF API TEST",
  "to_MaterialDocumentItem": [
    {
      "Material": "000000000017035056",
      "Plant": "1022",
      "StorageLocation": "FKGU",
      "GoodsMovementType": "101",
      "GoodsMovementRefDocType": "B",
      "QuantityInEntryUnit": "2",
      "EntryUnit": "EA",
      "PurchaseOrder": "5600084239",
      "PurchaseOrderItem": "00010"
    }
  ]
}
```

`CtrlPostgForExtWhseMgmtSyst` was deliberately omitted.

## Response

`201 Created`, header echoed: `MaterialDocument 5007138597`, `MaterialDocumentYear 2026`,
`InventoryTransactionType WE`, `GoodsMovementCode 01`, `CreatedByUser QNOVATE8`.

**Trap for the build team:** the create response returns
`"to_MaterialDocumentItem":{"results":[]}` — an empty item array despite the items having
posted. Do not treat an empty item collection in the create response as failure, and do not
derive posted quantities from it. Re-read with `$expand` instead.

## Verification — three independent reads

### 1. OData re-read with `$expand`

`GET A_MaterialDocumentHeader(MaterialDocumentYear='2026',MaterialDocument='5007138597')?$expand=to_MaterialDocumentItem`
→ `200 OK`

Item `1`: `Material 17035056`, `Plant 1022`, `StorageLocation FKGU`, `GoodsMovementType 101`,
`GoodsMovementRefDocType B`, `PurchaseOrder 5600084239`, `PurchaseOrderItem 10`,
`QuantityInEntryUnit 2`, `EntryUnit EA`.

### 2. Independent database readback — `MSEG`

Read through SAP GUI, not through the API:

```
MBLNR=5007138597/2026  ZEILE=0001  BWART=101  MATNR=000000000017035056
WERKS=1022  LGORT=FKGU  MENGE=2 EA  EBELN/EBELP=5600084239/00010
SHKZG=S  BUKRS=1000  WAERS=INR  DMBTR=0.00
```

### 3. Predecessor consumption — `EKET`

| | before | after |
|---|---|---|
| `MENGE` (scheduled) | 2.000 | 2.000 |
| `WEMNG` (goods receipt) | **0.000** | **2.000** |

The purchase order schedule line is now fully received. The receipt is linked to its
predecessor, not free-standing.

## Observation carried forward

`MSEG-DMBTR = 0.00` on the receipt. For a stock transfer the receiving value derives from the
issuing plant's valuation. Whether zero is correct for this material, or indicates missing
valuation on `17035056`, is **not established** and should be confirmed with MM before the
value fields are put into any external contract.

## What this certifies, and what it does not

Certified: the standard OData create path for Submit MIGO works end to end in QS4 against a
real stock-transport order, and persists a material document linked to its predecessor.

Not certified: cancellation/reversal (movement 102), duplicate-request behaviour,
authorization-failure behaviour, non-STO (vendor) receipts, batch-managed materials, and
partial receipts. `GoodsMovementRefDocType` for a delivery-referenced receipt (`B` vs `L`) has
not been tested — the `Delivery` / `DeliveryItem` item properties exist but were not exercised.
