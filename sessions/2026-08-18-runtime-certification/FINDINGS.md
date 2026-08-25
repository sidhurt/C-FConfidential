# Runtime certification — DS4 / client 200 — 2026-08-18

**System:** DS4 · **Client:** 200 · **User:** QNOVATE8 · **Alias:** LOCAL
**Method:** `/IWFND/GW_CLIENT` and SE16, driven by SAP GUI scripting against the operator's existing session.
**Mutations executed:** none. Every call in this session was GET, `$metadata`, or an SE16 read.

---

## 1. Headline

All seven services are **live and correctly modelled** in DS4/200. Every `$metadata` returned HTTP 200 and every CNF-relevant property in the v1.8 workbook is confirmed against the runtime contract.

**But DS4 client 200 contains no business data and no client configuration.** Reads return HTTP 200 with zero rows. `ZP06` does not exist. There is therefore **no document in DS4/200 against which any mutation test can be run**, and no approval packet can honestly be written yet.

The blocker has moved. It is no longer "nothing is activated" — activation is proven. It is now **"the activated client has nothing in it."**

---

## 2. What was proven

### 2.1 Service reachability — all HTTP 200

| Service | Version | Path used | Status | Metadata bytes |
|---|---|---|---|---|
| `API_MATERIAL_DOCUMENT_SRV` | 1 | `/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/` | 200 | 40,835 |
| `API_OUTBOUND_DELIVERY_SRV` | **2** | `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/` | 200 | 159,228 |
| `API_BILLING_DOCUMENT_SRV` | 1 | `/sap/opu/odata/sap/API_BILLING_DOCUMENT_SRV/` | 200 | 143,849 |
| `API_PURCHASEORDER_PROCESS_SRV` | 1 | `/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/` | 200 | 119,171 |
| `API_MATERIAL_STOCK_SRV` | 1 | `/sap/opu/odata/sap/API_MATERIAL_STOCK_SRV/` | 200 | 16,608 |
| `MMIM_MATDOC_SRV` | 1 | `/sap/opu/odata/sap/MMIM_MATDOC_SRV/` | 200 | 71,809 |
| `SD_CUSTOMER_INVOICES_CREATE` | 1 | `/sap/opu/odata/sap/SD_CUSTOMER_INVOICES_CREATE/` | 200 | 225,238 |

Host resolved from the metadata references: `vhresds4ci.sap.shreecement.com:44300`.

Parsed from those bodies: **1,854 properties · 110 entity sets · 23 function imports · 81 navigation properties.**

### 2.2 Write capability, from `sap:` annotations — runtime-confirmed

| Entity set | Creatable | Updatable | Deletable | Meaning for CNF |
|---|---|---|---|---|
| `A_MaterialDocumentHeader` | *(default true)* | false | false | API-01 create is header-deep-insert only |
| `A_MaterialDocumentItem` | **false** | false | false | items cannot be posted standalone — confirms deep insert |
| `A_OutbDeliveryHeader` | *(default true)* | *(true)* | *(true)* | API-02 create supported |
| `A_OutbDeliveryItem` | **false** | *(true)* | *(true)* | API-12 PATCH supported; item cannot be created standalone |
| `A_PurchaseOrder` / `Item` / `ScheduleLine` | *(true)* | *(true)* | *(true)* | API-11 deep create supported |
| `A_MaterialStock`, `A_MatlStkInAcctMod` | false | false | false | API-05 is read-only — as required |
| **all 8 `A_BillingDocument*` sets** | **false** | **false** | **false** | **billing cannot be created through this service** |

The last row is decisive: `API_BILLING_DOCUMENT_SRV` is read-only apart from its `Cancel` function import. It confirms billing creation must go through `SD_CUSTOMER_INVOICES_CREATE` or a BAPI, exactly as the v1.8 study guide argued.

### 2.3 Function imports — HTTP method taken from live metadata, not inferred

Every function import on the delivery, billing-create and material-document services is **`m:HttpMethod="POST"`**. The single exception is `API_BILLING_DOCUMENT/GetPDF`, which is **GET**.

Delivery v2, exact runtime signatures (`ActionFor` = `A_OutbDeliveryHeaderType` unless noted):

| Function import | Parameters (all `Edm` types, mode `In`) |
|---|---|
| `PostGoodsIssue` | `DeliveryDocument` |
| `ReverseGoodsIssue` | `DeliveryDocument`, `ActualGoodsMovementDate:Edm.DateTime` |
| `ConfirmPickingAllItems` | `DeliveryDocument` |
| `ConfirmPickingOneItem` | `DeliveryDocumentItem`, `DeliveryDocument` |
| `PickAllItems` | `DeliveryDocument` |
| `PickOneItem` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `PickOneItemWithBaseQuantity` | `DeliveryDocument`, `DeliveryDocumentItem`, `ActualDeliveredQtyInBaseUnit:Edm.Decimal`, `BaseUnit` |
| `PickOneItemWithSalesQuantity` | `ActualDeliveryQuantity:Edm.Decimal`, `DeliveryDocument`, `DeliveryDocumentItem`, `DeliveryQuantityUnit` |
| `SetPickingQuantityWithBaseQuantity` | `ActualDeliveredQtyInBaseUnit`, `BaseUnit`, `DeliveryDocument`, `DeliveryDocumentItem` |
| `PickAndBatchSplitOneItem` | `DeliveryDocument`, `DeliveryDocumentItem`, `Batch`, `SplitQuantity:Edm.Decimal`, **`SplitQuantityUnit`** |
| `CreateBatchSplitItem` *(ActionFor `A_OutbDeliveryItemType`)* | `PickQuantityInSalesUOM:Edm.Decimal`, `Batch`, `DeliveryDocument`, `DeliveryDocumentItem`, `ActualDeliveryQuantity:Edm.Decimal`, `DeliveryQuantityUnit` |

**Correction to the brief:** `PickAndBatchSplitOneItem` takes **five** parameters — `SplitQuantityUnit` was not in the brief's list and is required to disambiguate the split quantity. `CreateBatchSplitItem` takes six.

Return types are `Collection(PickingReport)` for the picking family, `Collection(Return)` for `ReverseGoodsIssue`, and `CreatedDeliveryItem` for `CreateBatchSplitItem`.

`SD_CUSTOMER_INVOICES_CREATE/CreateBillingDocuments` is POST with **16** parameters, all `Edm.String/In`, including the four the brief named (`ReferenceSDDocument`, `ReferenceSDDocumentCategory`, `ReferenceSDDocumentItem`, `BillingDocumentReleaseRequested`) plus `BillingDocumentType`, `RequestedBillingDocumentType`, `SalesOrganization`, `ToBeBilledQuantity`, `SeparateBilllingDocumentsRequested` *(SAP's spelling, three L's)*, `SnapshotRequested`, `BillingDocumentDate`, `RequestedBillingDocumentDate`, `DestinationCountry`, `OldBillToPartyAddressId`, `NewBillToPartyAddressId`, `RefSDDocWithInvalidPartner`.

**Parameter encoding is not yet proven.** OData V2 POST function imports conventionally carry parameters in the query string, but that is an inference and is marked as such until a live call demonstrates it.

### 2.4 The two load-bearing open questions — metadata half answered

**API-10 / `SalesDocument` ↔ `VBRP-AUBEL`.** `SalesDocument` and `SalesDocumentItem` **exist** on `A_BillingDocumentItemType`, alongside `ReferenceSDDocument`/`Item`/`Category` and `OriginSDDocument`/`Item`. Their existence is now runtime-confirmed. Whether `SalesDocument` carries `AUBEL` for a ZSTO billing document **cannot be settled in DS4** — there are no billing documents. Still **OPEN**, and it must be closed by a read against a system that has ZSTO data.

**API-01 reference model.** All candidate fields are runtime-confirmed on the item type: `GoodsMovementType`, `PurchaseOrder`, `PurchaseOrderItem`, `Delivery`, `DeliveryItem`, `Plant`, `StorageLocation`, `Material`, `QuantityInEntryUnit`, `EntryUnit`, `Batch`. `GoodsMovementCode` is confirmed on the **header** type. A further field the brief did not list is present and probably decisive: **`GoodsMovementRefDocType`** — it is the property that tells SAP whether the receipt references the PO or the delivery. Its permitted values are configuration, not metadata, so the reference question stays **OPEN** pending a functional answer plus one live post.

`GoodsMovementCode` remains a value-level blocker. Metadata gives the field, never the allowed value.

### 2.5 API-12 update surface — runtime-confirmed

On `A_OutbDeliveryItemType`: `ActualDeliveryQuantity` is creatable and updatable. **`DeliveryQuantityUnit` is `updatable="false"`** — the unit cannot be changed on a PATCH, only the quantity. `Batch` is `creatable="false"` but updatable. `HigherLvlItmOfBatSpltItm` is both false — SAP owns the batch-split hierarchy; the caller cannot set it.

### 2.6 SEGW extract vs DS4 runtime — reconciliation

| SEGW project (QS4) | Runtime service (DS4) | Extract props | Runtime props | Confirmed | Absent from runtime |
|---|---|---|---|---|---|
| `API_OUTBOUND_DELIVERY_0002` | `API_OUTBOUND_DELIVERY_SRV;v=2` | 398 | 361 | 361 | 23 |
| `API_PURCHASEORDER_PROCESS` | same | 288 | 248 | 248 | 39 |
| `API_BILLING_DOCUMENT` | same | 280 | 275 | 275 | 2 |
| `API_MATERIAL_DOCUMENT` | same | 102 | 94 | 94 | 8 |
| `API_MATERIAL_STOCK` | same | 13 | 13 | 13 | 0 |
| `MMIM_MATDOC` | same | 107 | 120 | 92 | 0 |
| `SD_CUSTOMER_INVOICES_CREATE` | same | 391 | 403 | 374 | 0 |

**Zero runtime properties are missing from the workbook.** The workbook invented nothing.

The properties absent from DS4 runtime are, without exception, **SAP Fashion Management (FMS) and Value-Added-Service extension fields** — `ProductCharacteristic1-3`, `ProductCollection`, `ProductSeason`, `ProductSeasonYear`, `ProductTheme`, `CrossPlantConfigurableProduct`, the whole `ValAddedSrvc*`/`ValueAddedService*` block — plus two address UUIDs on billing. **None is used by the CNF contract.** The difference is a business-function delta between QS4 and DS4, not a contract gap.

*Method note:* the raw delta counts also included function-import parameters and complex-type members that my entity-type parser does not index. Those were separated by direct text search against the runtime XML before the table above was written.

### 2.7 BAPI inventory — existence confirmed in DS4/200

All twelve named BAPIs are present in `TFDIR` in DS4/200 (one row each):

`BAPI_SHIPMENT_COST_ESTIMATE`, `BAPI_SHIPMENT_CREATE`, `BAPI_SHIPMENT_CHANGE`, `BAPI_GOODSMVT_CREATE`, `BAPI_OUTB_DELIVERY_CREATE_STO`, `BAPI_OUTB_DELIVERY_CREATE_SLS`, `BAPI_OUTB_DELIVERY_CHANGE`, `BAPI_OUTB_DELIVERY_CONFIRM_DEC`, `BAPI_PO_CREATE1`, `BAPI_BILLINGDOC_CREATEMULTIPLE`, `BAPI_BILLINGDOC_CANCEL1`, `BAPI_MATERIAL_AVAILABILITY`.

**The shipment-cost gap is confirmed independently in DS4.** `TFDIR` pattern `*SHIPMENTCOST*` returns *"No table entries found for specified key"*. Pattern `BAPI_SHIPMENT*` returns exactly **3** rows — create, change, cost-estimate. This reproduces the QS4 finding in a second system: **there is no BAPI to create or release a shipment-cost document.**

---

## 3. Why no mutation test can run in DS4/200

| Probe | Method | Result |
|---|---|---|
| `A_PurchaseOrder` filter `PurchaseOrderType eq 'ZP06'` | OData GET | HTTP 200, **0 rows** |
| `A_PurchaseOrder` unfiltered, `$top=15` | OData GET | HTTP 200, **0 rows** |
| `A_OutbDeliveryHeader` unfiltered, `$top=10` | OData GET | HTTP 200, **0 rows** |
| `A_MatlStkInAcctMod` unfiltered, `$top=10` | OData GET | HTTP 200, **0 rows** |
| `EKKO` | SE16 | **2 rows**, both empty shells — one blank `EBELN`, one `3100000012` with blank `BSART` and `AEDAT 00.00.0000` |
| `LIKP`, `LIPS`, `MKPF`, `VFKK` | SE16 | no entries |
| `T001W` (plants) | SE16 | ≥20 rows — master data present |
| `MARA` (materials) | SE16 | ≥20 rows — master data present |
| `T161` (PO document types) | SE16 | **35 rows, all SAP standard** |
| `T161` filter `BSART = ZP06` | SE16 | **No table entries found** |

Two independent conclusions:

1. **The services are healthy.** An empty OData collection with HTTP 200 and a well-formed `{"d":{"results":[]}}` envelope proves the service resolved, the CDS view was queried and authorisation passed. This is a data absence, not a failure.
2. **DS4/200 is a near-vanilla shell client.** Master data exists; transactional data and client configuration do not. `ZP06` — the STO document type the entire CNF STO chain depends on — is not configured.

Consequently **API-11 cannot be tested in DS4/200 as specified**, and every downstream test that needs its output (API-02 → API-03 → API-01 → API-12) is blocked behind it.

---

## 4. Status by business API

| API | Operation | Status | What is proven | What blocks it |
|---|---|---|---|---|
| API-01 | POST material document | **BLOCKED** | contract, deep-insert shape, all candidate fields | `GoodsMovementCode` value (MM); `GoodsMovementRefDocType` semantics; no DS4 PO/delivery to receive against |
| API-02 | POST outbound delivery | **BLOCKED** | header creatable, item not | no STO predecessor exists in DS4 |
| API-03 | picking / PGI / billing | **BLOCKED** | all function imports, exact params, POST method, non-atomic staging | no delivery exists |
| API-05 | GET book stock | **PASS (contract) / NOT TESTED (data)** | read-only model, all required fields, HTTP 200 | no stock rows to reconcile to MMBE/MB52 |
| API-08 | GET STO PO | **PASS (contract) / NOT TESTED (data)** | full read model, HTTP 200, filter accepted | no ZP06 POs; ZP06 not configured |
| API-09 | GET STO delivery | **PASS (contract) / NOT TESTED (data)** | full read model incl. `HigherLvlItmOfBatSpltItm` | no deliveries; ZNL filter unprovable |
| API-10 | GET STO invoice | **BLOCKED** | `SalesDocument` exists on the item type | `SalesDocument` ↔ `VBRP-AUBEL` unprovable without ZSTO data |
| API-11 | POST STO PO | **BLOCKED** | deep create supported on all three levels | **`ZP06` does not exist in DS4/200** |
| API-12 | PATCH delivery quantity | **BLOCKED** | `ActualDeliveryQuantity` updatable; unit not updatable | no delivery to patch |

No row is claimed as PASS on business behaviour. Contract-level PASS means the runtime model matches the requirement; it does not mean the operation was executed.

---

## 5. Evidence integrity

One capture in this session was contaminated: a clipboard read did not reach the SAP window and silently captured unrelated text. It was detected, deleted, and the harness was rebuilt with a hard content guard that rejects any payload not beginning with an XML or JSON token, retries three times, and fails loudly. All other captures were re-verified by inspecting their opening bytes. Every file listed in `MANIFEST.tsv` was confirmed to begin with `<?xml` or `{`.

Response headers are stored with `set-cookie`, `x-csrf-token` and `authorization` values replaced by `[REDACTED]`. No credential, cookie or session token is written to this evidence tree.

---

## 6. Layout

```
sessions/2026-08-18-runtime-certification/
  FINDINGS.md                  this file
  MANIFEST.tsv                 15 rows, SHA-256 per artefact
  evidence/                    request/headers/response per call + screenshots
  analysis/                    parsed indexes and the SEGW-vs-runtime reconciliation
  scripts/                     read-only capture harness (GET/HEAD enforced)
```

The harness refuses any method other than GET or HEAD and aborts unless the live session reports DS4/200.
