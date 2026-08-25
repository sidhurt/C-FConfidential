# CNF SAP API — curl runbook (DS4/200)

**Established 2026-08-19.** Everything below was verified from the system itself, not assumed.

| | |
|---|---|
| Application server | `vhresds4ci`, system no. `00` |
| **Base URL** | **`https://vhresds4ci.sap.shreecement.com:44300`** |
| Client | `200` |
| Reachability | **PROVEN** — HTTPS/44300 returned `401` in 0.51 s from outside SAP |
| HTTP/8000 | **Do not use.** Times out from outside; not routed. |

The ICM also lists HTTPS `20400`. Untested — 44300 is the one confirmed to answer.

TLS is likely a self-signed or internal-CA certificate, so `-k` is used below. Get the CA
chain from Basis before anyone puts this in a pipeline; `-k` is for interactive testing only.

---

## 1. The connectivity proof

```bash
curl -sS -k -o /dev/null -w "%{http_code}\n" "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/\$metadata?sap-client=200"
```

Returns `401`. **That is the expected and correct result** — it proves the gateway is
reachable and enforcing authentication. Anything else means a network or routing problem,
not an SAP one.

> **Important:** a bogus service name also returns `401`. Authentication is enforced
> *before* routing, so an unauthenticated probe **cannot** tell an activated service from
> a non-existent one. Do not use `401` as evidence a service exists.

## 2. Authenticated read

```bash
curl -sS -k -u 'QNOVATE8' "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/\$metadata?sap-client=200"
```

`-u 'USER'` without a colon makes curl prompt for the password so it stays out of shell
history and out of this file.

## 3. Fetch a CSRF token (required for every write)

```bash
curl -sS -k -u 'QNOVATE8' -c cookies.txt -D headers.txt -H "x-csrf-token: Fetch" -o /dev/null "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/?sap-client=200" && grep -i x-csrf-token headers.txt
```

The token **and** the session cookie must both be sent on the write. A token without its
cookie is rejected.

## 4. Write, using that token and cookie

```bash
curl -sS -k -u 'QNOVATE8' -b cookies.txt -H "x-csrf-token: <TOKEN>" -H "Content-Type: application/json" -X POST --data @body.json "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200"
```

---

## Activated services confirmed in `/IWFND/MAINT_SERVICE`

782 services are activated on DS4. These are the CNF-relevant ones. The **external** name
is what goes in the URL — the internal implementation is `Z`-prefixed, which is normal and
does not change the path.

| External name (use this in the URL) | Internal | Ver | Contract captured |
|---|---|---|---|
| `API_PURCHASEORDER_PROCESS_SRV` | `ZAPI_PURCHASEORDER_PROCESS_SRV` | 1 | yes |
| `API_OUTBOUND_DELIVERY_SRV` | `ZAPI_OUTBOUND_DELIVERY_SRV` | **2** | yes |
| `API_MATERIAL_STOCK_SRV` | `ZAPI_MATERIAL_STOCK_SRV` | 1 | yes |
| `API_MATERIAL_DOCUMENT_SRV` | `ZAPI_MATERIAL_DOCUMENT_SRV` | 1 | yes |
| `API_BILLING_DOCUMENT_SRV` | `ZAPI_BILLING_DOCUMENT_SRV` | 1 | yes |
| `MMIM_MATDOC_SRV`, `MMIM_MATDOC_OV_SRV` | `ZMMIM_*` | 1 | partial |
| `SD_CUSTOMER_INVOICES_CREATE`, `..._MANAGE` | `ZSD_*` | 1 | partial |

**Delivery must be called as `API_OUTBOUND_DELIVERY_SRV;v=2`.** Version 2 is the only
version registered. Without `;v=2` the call returns **HTTP 403** with `/IWFND/MED/170
No service found ... version '0001'`. With it: 200, 149,516 bytes, 12 entity sets.

---

## What the team should expect

**Reads return `200` with zero rows.** DS4 has no purchase orders, no deliveries, no
valuated stock, no billing documents. A `200` with an empty collection proves routing and
authorisation work. It does **not** prove the operation works.

**Writes will not succeed on DS4 today.** No `ZP06` document type, no vendor master, no
valuated stock, and MM periods open only for 1998. This is a test-data condition, not a
defect — do not raise it as one.

**The STO create POST returns `400` by design.** `API_PURCHASEORDER_PROCESS_SRV` restricts
creation to `NB` and NB-derived types (`APPL_MM_PUR_PO/064`) and to a limited item-category
set (`APPL_MM_PUR_PO/065`). Their real STO type `ZP06` is a copy of `UB` (`T161-BREFN = UBF`)
and their live STO items carry `EKPO-PSTYP = 7`. Both locks apply. **STO creation is not
available through this service and no data fix changes that** — it goes through
`BAPI_PO_CREATE1`, which is what the custom service will wrap.

## Not testable from Postman or curl at all

`BAPI_PO_CREATE1`, `BAPI_SHIPMENT_CREATE`, `BAPI_GOODSMVT_CREATE`,
`BAPI_MATERIAL_AVAILABILITY`, `BAPI_TRANSACTION_COMMIT` and the entire `SD_SCDS_*` freight
chain are RFC function modules. They have no URL. Their request contracts are documented in
folder 7 of the Postman collection so the payloads are ready the moment the custom services
wrap them.

---

# Submit MIGO in QS4/700 — the certified write

**Added 2026-08-25.** Everything above targets DS4/200. This section targets **QS4/700**,
`https://vhresqs4ci.sap.shreecement.com:44300`, and is the first goods receipt actually
created through the API.

The DS4 credential does **not** authenticate against QS4. They are separate passwords.

## 1. Fetch the CSRF token and session cookies

```bash
curl -k -s -D csrf_hdr.txt -o /dev/null \
  -u "QNOVATE8:$QS4_PASS" \
  -H "X-CSRF-Token: Fetch" -H "Accept: application/json" \
  -c cookies.txt \
  "https://vhresqs4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/?sap-client=700"
```

The plain service path resolves. `;v=1` is **not** required for this service, unlike
`API_OUTBOUND_DELIVERY_SRV`, which still requires `;v=2`.

## 2. Post the goods receipt

Body in a file — do not inline JSON, Windows argument handling mangles the quoting.

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

```bash
curl -k -s -u "QNOVATE8:$QS4_PASS" \
  -H "X-CSRF-Token: $TOKEN" \
  -H "Content-Type: application/json" -H "Accept: application/json" \
  -b cookies.txt --data-binary @migo_body.json \
  -X POST ".../API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader?sap-client=700"
```

Result: **`201 Created`, material document `5007138597` year `2026`.**

## 3. The one field that decides the call

`"GoodsMovementRefDocType": "B"`.

It is the OData equivalent of `MVT_IND` in `BAPI_GOODSMVT_CREATE`, where `B` means goods
movement for a purchase order. Omit it and SAP returns:

```
HTTP 400
MM_IM_ODATA_API_MDOC/011  Property PURCHASEORDER is not supported for GoodsMovementType 101
MM_IM_ODATA_API_MDOC/011  Property PURCHASEORDERITEM is not supported for GoodsMovementType 101
```

The message names the PO properties, which sends you looking at the wrong field. Reproduced
on two different purchase orders, so it is structural, not document-specific.

## 4. Always read back

The create response returns `"to_MaterialDocumentItem":{"results":[]}` — an **empty item
array on success**. Never treat that as failure and never derive posted quantities from it.

```bash
curl -k -s -u "QNOVATE8:$QS4_PASS" -H "Accept: application/json" \
  ".../A_MaterialDocumentHeader(MaterialDocumentYear='2026',MaterialDocument='5007138597')?\$expand=to_MaterialDocumentItem&sap-client=700"
```

The key is composite and the **year comes first**. `PurchaseOrderItem` is returned unpadded
(`10`) although it is sent padded (`00010`).

## 5. Choosing a test item

A purchase order item is only receivable when **both** hold:

- a `641` has posted for it, so stock in transit exists at the receiving plant — check `MSEG`
- `EKET-WEMNG` is less than `EKET-MENGE` — the receipt is still open

Most open STOs fail the first test. `5600084239` is now fully received;
`5600084238` item `00010` (4 EA) is the next valid candidate.

The MM period must also be open for the company code. QS4 company code `1000` sits on period
`2026/05` with an April–March fiscal variant. The `M7/053` seen in DS4 was company code
`0001`, which is still on `1998/03` — a stale DEV company code, not a system-wide block.
