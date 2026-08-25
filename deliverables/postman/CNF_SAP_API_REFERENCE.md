# CNF C&F Agent — SAP OData API Reference

**System: DS4 · client 200 · OData V2 · verified 2026-08-19.**
Five services, 20 entity sets, 11 delivery function imports, and `$metadata` per service.

---

## 1. Connect (DS4 dev system)

| | |
|---|---|
| Host | `vhresds4ci.sap.shreecement.com` |
| Port | **`44300` (HTTPS)** |
| SAP client | `200` |
| Username | `QNOVATE8` |
| Base URL | `https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/` |

**Password is not written into this document.** Get it from Basis, or let curl prompt with
`-u 'QNOVATE8'` (no colon) so it stays out of shell history.

**Do not use port 8000.** It is listed in `SMICM` as an HTTP service but times out from
outside — not routed. `44300` is the only port confirmed to answer.

**TLS is an internal CA.** Use `curl -k`, and switch Postman's SSL verification OFF.
Get the CA chain from Basis before this goes anywhere near a pipeline.

Reachability proof — this is the "is it live" check:

```bash
curl -sS -k -o /dev/null -w "%{http_code}\n" "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/\$metadata?sap-client=200"
```

Returns `401` in about half a second. **That is the correct result** — gateway reachable,
service routed, auth enforced. Anything else is a network problem, not an SAP one.

---

## 2. Authentication

* Every request needs HTTP Basic auth. No anonymous access, no API key.
* Reads (GET) need only Basic auth. Writes (POST / PATCH) also need a CSRF token — section 9.
* `401` = bad or expired credentials. `403` = user lacks authorization.

**A wrong service name also returns `401`, not `404`.** Authentication fires before routing,
so you cannot use an unauthenticated `401` to prove a service exists. Confirmed by probing
a deliberately fake service name — it returned `401` identically.

---

## 3. Response format (OData V2 — read this)

* Add `&$format=json` or header `Accept: application/json`. Default is XML.
* Collections are wrapped — the array is at `d.results`:

```
{ "d": { "results": [ { ...row... }, { ...row... } ] } }
```

* A single entity is at `d` (no `results`).
* Errors: read `error.message.value`.

**Expect `200` with zero rows on every read.** DS4 has no purchase orders, no deliveries,
no valuated stock and no billing documents. An empty `200` proves routing and authorisation
work — it does **not** prove the operation works. This is a test-data condition, not a defect.

---

## 4. Purchase orders / STO — `API_PURCHASEORDER_PROCESS_SRV`

Base: `.../sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/`

### Endpoints

| Method | Endpoint | Notes |
|---|---|---|
| GET | `A_PurchaseOrder` | header |
| GET | `A_PurchaseOrder('<PO>')` | single |
| GET | `A_PurchaseOrderItem` | items |
| GET | `A_PurchaseOrderScheduleLine` | schedule lines |
| GET | `A_PurOrdAccountAssignment` | account assignment |
| GET | `A_PurOrdPricingElement` | conditions |
| GET | `A_PurchaseOrderNote` / `A_PurchaseOrderItemNote` | texts |
| GET | `A_POSubcontractingComponent` | subcontracting |
| POST | `A_PurchaseOrder` | **works for NB only — see §10** |

### `A_PurchaseOrder` — key fields

* `PurchaseOrder` — String(10), **key**
* `CompanyCode` — String(4)
* `PurchaseOrderType` — String(4). `NB` standard, `UB` stock transfer, `ZP06` their STO type
* `PurchasingOrganization` — String(4)
* `PurchasingGroup` — String(3)
* `Supplier` — String(10). **blank on an STO**
* `SupplyingPlant` — String(4). the STO source plant (`EKKO-RESWK`)
* `DocumentCurrency` — String(5)
* `PurchaseOrderDate` — DateTime
* `IncotermsClassification`, `IncotermsLocation1/2`, `IncotermsVersion`
* `PurchasingProcessingStatus` — String(2)
* `CreationDate` — DateTime · `LastChangeDateTime` — DateTimeOffset

### `A_PurchaseOrderItem` — key fields

* `PurchaseOrder` + `PurchaseOrderItem` — **composite key**
* `Material` — String(40)
* `Plant` — String(4). the receiving plant on an STO
* `StorageLocation` — String(4)
* `PurchaseOrderItemCategory` — String(1). **`7` = stock transfer**
* `OrderQuantity` — Decimal · `PurchaseOrderQuantityUnit` — String(3)
* `NetPriceAmount` — Decimal

### Read

```bash
curl -sS -k -u 'QNOVATE8' "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200&\$format=json&\$top=5"
```

Header + items + schedule lines in one call:

```bash
curl -sS -k -u 'QNOVATE8' "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200&\$format=json&\$top=1&\$expand=to_PurchaseOrderItem/to_ScheduleLine"
```

---

## 5. Outbound deliveries — `API_OUTBOUND_DELIVERY_SRV;v=2`

Base: `.../sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/`

**The `;v=2` is required.** Version 2 is the only version registered on this system.
Drop it and the call fails outright: **HTTP 403** with `/IWFND/MED/170 No service found
for namespace '', name 'API_OUTBOUND_DELIVERY_SRV', version '0001'`. Verified 2026-08-19.

### Endpoints

| Method | Endpoint | Notes |
|---|---|---|
| GET / POST | `A_OutbDeliveryHeader` | creatable |
| GET / PATCH | `A_OutbDeliveryItem` | **`creatable=false`** — items only via deep insert on the header |
| GET | `A_OutbDeliveryPartner`, `A_OutbDeliveryAddress`, `A_OutbDeliveryDocFlow` | read-only |
| GET | `A_HandlingUnitHeaderDelivery`, `A_HandlingUnitItemDelivery` | read-only |
| GET | `A_OutbDeliveryHeaderText`, `A_OutbDeliveryItemText` | texts |
| GET | `A_SerialNmbrDelivery` | read-only |

### `A_OutbDeliveryHeader` — key fields

* `DeliveryDocument` — String(10), **key**
* `DeliveryDocumentType` — String(4)
* `ShippingPoint` — String(4)
* `SoldToParty` — String(10)
* `ActualGoodsMovementDate` — DateTime
* `OverallPickingStatus` — String(1) · `OverallGoodsMovementStatus` — String(1)

### `A_OutbDeliveryItem` — key fields

* `DeliveryDocument` + `DeliveryDocumentItem` — **composite key**
* `Material`, `Plant`, `Batch`
* `ActualDeliveryQuantity` — Decimal. **updatable**
* `DeliveryQuantityUnit` — **`updatable=false`**, you cannot change the UoM
* `HigherLvlItmOfBatSpltItm` — **not creatable, not updatable.** SAP owns the batch-split
  hierarchy; do not try to set it

### Function imports — all POST, parameters in the query string

| Function | Params |
|---|---|
| `PostGoodsIssue` | 1 |
| `ReverseGoodsIssue` | 2 |
| `ConfirmPickingAllItems` | 1 |
| `ConfirmPickingOneItem` | 2 |
| `PickAllItems` | 1 |
| `PickOneItem` | 2 |
| `PickOneItemWithBaseQuantity` | 4 |
| `PickOneItemWithSalesQuantity` | 4 |
| `SetPickingQuantityWithBaseQuantity` | 4 |
| `PickAndBatchSplitOneItem` | **5** — incl. `SplitQuantityUnit` |
| `CreateBatchSplitItem` | **6** — incl. `PickQuantityInSalesUOM` |

Signatures are runtime-confirmed from `$metadata`. **None has been executed.**
Query-string parameter encoding is the OData V2 convention but is **inferred, not proven** —
treat a `400` as a possible encoding issue before concluding the operation is unsupported.

```bash
curl -sS -k -u 'QNOVATE8' -X POST -H "x-csrf-token: <TOKEN>" -b cookies.txt "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/PostGoodsIssue?DeliveryDocument='0080000123'&sap-client=200"
```

Update a delivery quantity:

```bash
curl -sS -k -u 'QNOVATE8' -X PATCH -H "Content-Type: application/json" -H "x-csrf-token: <TOKEN>" -H "If-Match: *" -b cookies.txt -d '{"ActualDeliveryQuantity":"5"}' "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryItem(DeliveryDocument='0080000123',DeliveryDocumentItem='000010')?sap-client=200"
```

`If-Match: *` is fine for testing. Production callers should send the real ETag.

---

## 6. Stock — `API_MATERIAL_STOCK_SRV`

Base: `.../sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/`

| Method | Endpoint |
|---|---|
| GET | `A_MaterialStock` |
| GET | `A_MatlStkInAcctMod` |

**Read-only service.** Both entity sets are `creatable=false`, `updatable=false`,
`deletable=false`. There is no write path here.

`A_MatlStkInAcctMod` has an **11-part composite key**: `Material`, `Plant`,
`StorageLocation`, `Batch`, `Supplier`, `Customer`, `WBSElementInternalID`, `SDDocument`,
`SDDocumentItem`, `InventorySpecialStockType`, `InventoryStockType`. Addressing a single
entity by key is impractical — **filter the collection instead**.

```bash
curl -sS -k -u 'QNOVATE8' "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/A_MatlStkInAcctMod?sap-client=200&\$format=json&\$filter=Material%20eq%20'MAT18'"
```

**This is book stock, not availability.** ATP is a different question and needs
`BAPI_MATERIAL_AVAILABILITY`, which has no HTTP endpoint — see §11. Do not substitute one
for the other.

---

## 7. Material documents — `API_MATERIAL_DOCUMENT_SRV`

Base: `.../sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/`

| Method | Endpoint | Notes |
|---|---|---|
| GET / POST | `A_MaterialDocumentHeader` | creatable; **`updatable=false`, `deletable=false`** |
| GET | `A_MaterialDocumentItem` | |
| GET | `A_SerialNumberMaterialDocument` | |

`A_MaterialDocumentHeader` — key fields:

* `MaterialDocumentYear` + `MaterialDocument` — **composite key**
* `DocumentDate`, `PostingDate` — DateTime
* `GoodsMovementCode` — String(2). `01` = goods receipt for PO (from `T158G`)
* `ReferenceDocument` — String(16)

Posting is create-only — a material document cannot be changed or deleted through this
service. Reversal is a separate movement.

`GoodsMovementCode = 01` is a **candidate**, not confirmed for the CNF step. A `TESTRUN`
of the equivalent BAPI reached MM period control without rejecting `01`, which means the
code and item structure were accepted — it does not prove `01` is the right code for this
business process.

---

## 8. Billing — `API_BILLING_DOCUMENT_SRV`

Base: `.../sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/`

| Method | Endpoint |
|---|---|
| GET | `A_BillingDocument` |
| GET | `A_BillingDocumentItem` |
| GET | `A_BillingDocumentPartner` / `A_BillingDocumentItemPartner` |
| GET | `A_BillingDocumentPrcgElmnt` / `A_BillingDocumentItemPrcgElmnt` |
| GET | `A_BillingDocumentText` / `A_BillingDocumentItemText` |
| GET | `GetPDF` (function import) |

**All 8 entity sets are `creatable=false`. Billing documents cannot be created through this
service.** It is read plus PDF only. Anything in the workbook that assumes billing creation
here is wrong.

`A_BillingDocument` — key fields: `BillingDocument` (key), `BillingDocumentType`,
`BillingDocumentDate`, `SDDocumentCategory`, `SoldToParty`.

---

## 9. Writes — CSRF token

Step A — fetch the token and keep the cookie:

```bash
curl -sS -k -u 'QNOVATE8' -c cookies.txt -D headers.txt -o /dev/null -H "x-csrf-token: Fetch" "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/?sap-client=200" && grep -i x-csrf-token headers.txt
```

Step B — send the token **and** the cookie on the write:

```bash
curl -sS -k -u 'QNOVATE8' -b cookies.txt -H "x-csrf-token: <TOKEN>" -H "Content-Type: application/json" -X POST --data @body.json "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200"
```

A token without its session cookie is rejected.

---

## 10. STO creation does not work through this API — read before testing

`POST A_PurchaseOrder` with a stock transport order returns **HTTP 400**:

```
APPL_MM_PUR_PO/064   Use purchase order type Standard (NB) or a type copied from NB
APPL_MM_PUR_PO/065   Use a supported purchase order item category
```

Why this is permanent rather than a data problem, checked against their real configuration:

| Lock | Their live config | Result |
|---|---|---|
| Document type | `ZP06` → `T161-BREFN = UBF` — a copy of **UB**, not of NB | fails 064 |
| Item category | `EKPO-PSTYP = 7` on live STO `5600084210` | fails 065 |

Two independent locks. Master data, plant pairing, or transporting `ZP06` into DS4 change
neither. **STO creation goes through `BAPI_PO_CREATE1`**, which is what the custom service
will wrap. The `A_PurchaseOrder` **read** endpoints work normally for STOs — only create is
blocked.

Keep the failing POST in your test set. It is the evidence, and it should stay reproducible.

---

## 11. Not available over HTTP at all

These have no URL. They are RFC function modules and cannot be called from Postman or curl
by any means. They are listed so nobody spends a day looking for an endpoint that was never
there.

| Module | Purpose | State |
|---|---|---|
| `BAPI_PO_CREATE1` | **STO creation** | released, RFC-enabled |
| `BAPI_SHIPMENT_CREATE` | shipment | released, RFC-enabled |
| `BAPI_GOODSMVT_CREATE` | goods movement | released, RFC-enabled |
| `BAPI_MATERIAL_AVAILABILITY` | ATP | released, RFC-enabled |
| `BAPI_TRANSACTION_COMMIT` | commit | released, RFC-enabled |
| `SD_SCDS_CREATE` → `SD_SCDS_RELEASE` | freight cost chain | **not released, not RFC-enabled** |

Full request contracts for each are in folder 5 of the Postman collection. The `SD_SCDS_*`
modules need an ABAP wrapper before any exposure is possible — they cannot be reached even
by RFC.

---

## 12. Must-know rules

1. **`;v=2` on the delivery service is mandatory.** Without it the call returns **403**,
   not a smaller contract - version 1 is not registered at all.
2. **Collections are at `d.results`**, single entities at `d`. OData V2, not V4.
3. **Empty `200` is normal on DS4** and proves only routing and auth.
4. **`401` for an unknown service.** Never treat `401` as proof a service exists.
5. **Writes need CSRF token *and* session cookie.** Reads need neither.
6. **Billing cannot be created** through `API_BILLING_DOCUMENT_SRV` — all sets read-only.
7. **Stock is read-only** through `API_MATERIAL_STOCK_SRV`, and it is book stock, not ATP.
8. **Delivery items are `creatable=false`** — create them by deep insert on the header.
9. **`DeliveryQuantityUnit` is not updatable**, and SAP owns the batch-split hierarchy.
10. **STO creation returns 400 by design** — use the BAPI route.
11. **Port 8000 does not work from outside.** HTTPS 44300 only.
12. **SSL verification off** for testing; get the CA chain before production.

---

## 13. Schema

`GET $metadata` per service returns the full machine-readable schema — point your OData
client or codegen at it:

```
https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/$metadata?sap-client=200
https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/$metadata?sap-client=200
https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/$metadata?sap-client=200
https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/$metadata?sap-client=200
https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/$metadata?sap-client=200
```

---

## Evidence status

| Claim | Basis |
|---|---|
| Host, port, reachability | `SMICM` + an unauthenticated `curl` returning `401` in 0.51 s |
| Services activated | `/IWFND/MAINT_SERVICE` on DS4 |
| Entity sets, properties, `creatable`/`updatable` flags | live `$metadata`, captured |
| Reads return empty `200` | executed in `/IWFND/GW_CLIENT` |
| STO `POST` returns 400 with 064/065 | executed |
| `ZP06` is a UB copy; `PSTYP = 7` | QS4 `T161` and `EKPO` |
| **Authenticated GET and POST from outside SAP** | **DONE — 2026-08-19.** See below. |

### End-to-end confirmation, executed 2026-08-19

Authenticated `curl` from a workstation outside SAP, over HTTPS 44300.

| Call | Result |
|---|---|
| `GET $metadata` | **200**, 109,658 bytes, 1.17 s — real schema, 8 entity sets |
| `GET A_PurchaseOrder?$top=5&$format=json` | **200**, 20 bytes — `{"d":{"results":[]}}` |
| CSRF fetch | token returned (24 chars) + 2 session cookies |
| `POST A_PurchaseOrder` | **400**, error body read in full |

**The document-type restriction, proven by single-variable contrast.** Same payload each
time; only the marked field changed:

| `PurchaseOrderType` | `PurchaseOrderItemCategory` | Errors returned |
|---|---|---|
| `UB` | `7` | **064** *and* **065** |
| `NB` | `7` | **065 only** — 064 gone |
| `NB` | blank | **neither** — fails on `088 Document currency is not determined` |

This settles it three ways:

1. **064 is purely about the document type.** Changing `UB` to `NB` removes it and changes
   nothing else.
2. **065 is independent of 064.** It survives the document-type change, so an STO is blocked
   on item category even if the type were acceptable.
3. **The service itself works.** With a standard NB purchase order it clears both scope
   checks and proceeds to genuine business validation (currency derivation). The 400 on an
   STO is a deliberate API scope restriction, not a broken service and not a data problem.

Verbatim message text from the `UB` response:

```
APPL_MM_PUR_PO/064  Use purchase order type "Standard" ("NB") or a type copied from "NB".
APPL_MM_PUR_PO/065  Use a supported purchase order item category for item . See long text.
```

No purchase order was created by any of these calls.

Raw request and response bodies:
`sessions/2026-08-18-runtime-certification/evidence/external-http-2026-08-19/`
