# CNF standard SAP API solution and runtime-proof plan

**Date:** 2026-08-15  
**System evidence:** QS4 / client 700  
**Business baseline:** `sources/SRC-DOC-20260815-01_CNF_API_Request_Response_Specification_v1.7.xlsx`  
**Evidence baseline:** `sessions/2026-08-15-standard-api-discovery/`  
**Status:** current SAP solution proposal; design-time evidence verified, runtime proof pending

## 1. Executive answer

The project is not a greenfield portfolio of 12 custom SAP APIs. The catalogue and deep dives show that SAP-delivered services can execute most of the authoritative document work:

1. `API_MATERIAL_DOCUMENT_SRV` — accepted goods-receipt/material-document posting.
2. `API_OUTBOUND_DELIVERY_SRV;v=2` — outbound-delivery create/read/update, picking/batch split and PGI surface.
3. `API_BILLING_DOCUMENT_SRV` — released billing read/read-back surface.
4. `API_PURCHASEORDER_PROCESS_SRV` — STO purchase-order read and create.
5. `API_MATERIAL_STOCK_SRV` — live book stock at the required inventory grain.

Two registered services may complement the released set:

- `MMIM_MATDOC_SRV` — material-document item read-back; application-internal but read-only.
- `SD_CUSTOMER_INVOICES_CREATE` — genuine billing-create action; application-internal and therefore conditional on architecture approval and runtime proof.

The remaining work is not “activate five services and finish.” The full solution still requires:

- client-specific document/configuration mapping;
- CPI/T2 orchestration, correlation, idempotency and stable error shaping;
- a shipment-calculation callable surface, likely a narrow wrapper after `BAPI_SHIPMENT_COST_ESTIMATE` is validated;
- identification and proof of the existing DigiGST/EY/eDocument route for E-Way extension and invoice correction;
- resolution of the DMG/STG rejection ledger and receipt-status/balance response;
- runtime `$metadata`, safe-read and authorised DEV write evidence.

## 2. Evidence facts that must not be collapsed

| Evidence level | What it proves | What it does not prove |
|---|---|---|
| SEGW project exists | SAP delivered a design-time project in this release | Registered, reachable, authorised or business-fit |
| Gateway registration exists | A runtime service entry is configured | ICF/alias health, authorisation, stable integration use or transaction success |
| `$metadata` returns HTTP 200 | The local runtime service and version respond and expose a contract | The business operation posts correctly with client configuration |
| Representative read succeeds | Query, key/filter and authorisation work for test data | Write behavior, idempotency or downstream processing |
| Authorised DEV write succeeds | The service creates/changes the expected SAP document | Production readiness, retry safety or end-to-end CPI/T2 behavior |

The current repository proves the first level for all selected services and registration status for the observed 522-service catalogue. It does not yet prove local callability for the five released core services.

## 3. v1.7 business requirement to solution map

### API-01 — Submit MIGO

**Business requirement.** Post partial/full goods receipt against the selected delivery context; allocate the current accepted quantity across receiving storage locations; return material document/year, posted items, receipt status and remaining quantity. DMG/STG are rejection classifications and must not increase accepted stock.

**SAP solution.** Use `API_MATERIAL_DOCUMENT_SRV` as the primary posting service. One deep-create request can carry multiple material-document items, one per accepted storage-location allocation, and returns the material-document header key. Use `MMIM_MATDOC_SRV` as a conditional read-back for item numbers and posted quantities if the create response does not echo them.

**Coverage.** Direct for accepted multi-SLoc GR, posting/document dates, material/plant/unit, material document and year. `API_MATERIAL_DOCUMENT` does not return computed `ReceiptStatus`, `RemainingQuantity`, idempotent replay fields or an allocation-index error array.

**What must be changed or built.**

- MM must confirm the authoritative reference—PO, inbound delivery or dispatching outbound delivery—and the `GoodsMovementCode`/movement type.
- Only accepted allocations may be posted. The DMG/STG classification and replacement-demand ledger require an existing process/source to be identified or a narrow persistence/update gap to be built.
- Receipt status and remaining quantity must come from an authoritative purchase/delivery-history read, not be fabricated from the create response.
- CPI/T2 must own `RequestId` replay protection and stable portal error mapping unless architecture assigns an SAP idempotency store.

**Disposition:** `PRIMARY + COMPLEMENTARY`, conditional on movement/reference mapping, activation and DEV write proof.

### API-02 — Create DI

**Business requirement.** Create one SAP outbound delivery/DI from a sales order for Trade/Non-trade or an STO PO for STO, with caller-controlled delivery quantity, and return the delivery number and derived context.

**SAP solution.** Use `API_OUTBOUND_DELIVERY_SRV;v=2`, generated by SEGW project `API_OUTBOUND_DELIVERY_0002`. SAP documents creation with reference to both a sales order and a stock-transport order.

**Rejected alternatives.** Registered `LE_SHP_OD_CREATE_SRV` is a collective due-list worklist with no delivery quantity, STO predecessor or single delivery response. Registered `LE_SHP_QC_DLVREF_SRV` creates only a narrow sales-order/header case and has no quantity, item or STO surface.

**What must be changed or built.** CPI must translate the minimal v1.7 request into the released service's create operation and derive rather than trust plant, shipping point, material, sales area and Incoterm. Idempotency and stable error codes remain outside the standard contract.

**Disposition:** `PRIMARY`, pending activation, local v2 `$metadata`, one sales-order create test and one STO create test.

### API-03 — Create Invoice / Billing Documents

**Business requirement.** The portal presents one Generate Billing Documents journey, but the approved document flow has independent stages: batch/picking, shipment, shipment cost, PGI, billing, e-Invoice and E-Way Bill.

**SAP solution.** Treat this as orchestration, not one SAP LUW:

1. `API_OUTBOUND_DELIVERY_SRV;v=2` — batch split/picking operations and `PostGoodsIssue`.
2. Shipment creation/costing — existing client route still to identify; API-04 supplies the calculation gap.
3. `SD_CUSTOMER_INVOICES_CREATE` — conditional billing creation through POST `CreateBillingDocuments`.
4. `API_BILLING_DOCUMENT_SRV` — released billing read-back including billing/accounting document fields.
5. Existing DigiGST/EY/eDocument route — e-Invoice and E-Way Bill stages.

**What must be changed or built.** CPI/T2 must hold `ProcessId`, stage state, retry policy and compensation/recovery. If architecture rejects the internal billing-create service, validate the approved OData V4 or `BAPI_BILLINGDOC_CREATEMULTIPLE` path and expose only the narrow billing command that is missing. Do not build one ABAP call that pretends all stages can roll back atomically.

**Disposition:** `CONDITIONAL COMPOSITION`. Billing creation is real but not yet approved as a released integration endpoint; the complete chain requires multiple services/routes.

### API-04 — Shipment Calculation

**Business requirement.** Given an existing DI and selected transporter, return a read-only delivery-context freight estimate; SAP derives plant, destination, material, quantity, Incoterm and route.

**SAP solution.** No credible integration-fit SEGW service emerged from the full catalogue. The local fallback evidence includes `BAPI_SHIPMENT_COST_ESTIMATE`.

**What must be changed or built.** Confirm whether the client uses LE-TRA, TM or a custom freight engine; inspect the actual shipment/shipment-cost documents and pricing configuration; execute the BAPI in SE37 with an approved representative delivery; then expose a narrow non-posting endpoint only if no existing callable service exists. The endpoint should accept the DI/transporter/pricing date, derive the commercial context, and return amount/currency/rate basis/condition trace.

**Disposition:** `PROVEN SEGW GAP`; likely targeted ABAP build after LE/TM validation.

### API-05 — Stock Availability

**Business requirement.** Return authoritative current system stock for a plant/depot at material × storage-location grain for physical inventory reconciliation, optionally filtered by material/storage location. This is book stock, not plant-level ATP and not stock ageing.

**SAP solution.** Use `API_MATERIAL_STOCK_SRV`. `A_MatlStkInAcctMod` includes material, plant, storage location, batch, stock type and `MatlWrhsStkQtyInMatlBaseUnit`, and is pageable.

**Rejected/limited alternatives.** `API_PRODUCT_AVAILY_INFO_BASIC` is plant-level ATP for one material and has no storage-location parameter. `MMIM_STOCKINDATERANGE` reports opening/closing stock and movements over a period, not holding age.

**What must be changed or built.** MM must select the included `InventoryStockType` values. Descriptions may come from T2/master data or a separate read. `StockAgeingDays` must remain sourced from the existing `ZMM5013`-derived Datasphere D-1 feed unless architecture deliberately changes the contract.

**Disposition:** `PRIMARY`, pending activation, stock-category decision and representative filtered reads.

### API-06 — E-Way Bill Extension

**Business requirement.** Permit extension only in the final eight hours of validity and add exactly 24 hours on success.

**SAP solution.** The landscape already contains SAP eDocument/DigiGST and approximately 50 `EY_*` HTTP destinations including extension operations. No credible generic SEGW service was found.

**What must be changed or built.** Trace the live existing ABAP/CPI/EY implementation from the destination to the invoking class/FM/BAdI and persisted e-document status. Prove one approved non-production extension request/response if test credentials and a valid document are available. Build a thin CNF command only if the existing route has no supported callable boundary; do not create a competing GSP integration.

**Disposition:** `EXISTING ROUTE TO PROVE`, with a narrow gap endpoint possible.

### API-07 — Invoice Correction

**Business requirement.** Update only the validated Part A/Part B correction delta—transporter identity/distance and transport mode/vehicle details—while preserving separate e-Invoice and E-Way outcomes.

**SAP solution.** Use the existing DigiGST/EY/eDocument correction/cancel/regenerate path after identifying its SAP implementation. No credible SEGW project closes this requirement by itself.

**What must be changed or built.** Confirm the billing/e-document key, eligibility, whether Update Details cancels/regenerates either statutory document, and the exact persistence object. Reuse the existing implementation. If it has no callable boundary, expose a narrow command around it with no duplicate statutory submission.

**Disposition:** `EXISTING ROUTE TO PROVE`, with a narrow gap endpoint possible.

### API-08 — STO Orders

**Business requirement.** Read STO purchase orders with document type, organisation, supplying/receiving plant, material, quantity, delivery date, status and change watermark.

**SAP solution.** Use `API_PURCHASEORDER_PROCESS_SRV`. The model covers 13 of the 14 v1.7 output groups directly, including `PurchaseOrderType` and `LastChangeDateTime`; status needs mapping.

**Rejected alternative.** `MMIM_STO` lacks document type, company/purchasing organisation/group, status, watermark and paging.

**What must be changed or built.** Confirm the client STO type (`ZP06` is stated in v1.7), item category and normalized status mapping. CPI/T2 must implement the approved delta/paging contract.

**Disposition:** `PRIMARY`, pending activation and client STO mapping.

### API-09 — STO Deliveries

**Business requirement.** Read outbound deliveries whose predecessor is an STO PO, including PO/delivery/item relationships, quantity, plants, PGI status/document and change watermark.

**SAP solution.** `API_OUTBOUND_DELIVERY_SRV;v=2` is the leading released service because the same family creates from an STO and exposes outbound-delivery headers/items/document flow.

**What must be completed.** Produce the exact requirement-level field/delta matrix for API-09, confirm the STO predecessor filter/join, PGI material-document exposure and last-change semantics from local `$metadata` and representative data. This is one of the two remaining material deep-dive closures; it must not be reported as finished merely because API-02 uses the same service.

**Disposition:** `LEADING PRIMARY CANDIDATE`, not yet fully proven against the v1.7 read contract.

### API-10 — STO Invoice

**Business requirement.** Read invoice records associated with STO dispatches, with PO/delivery links, date, organisation, quantity/amount/currency, status and delta watermark.

**SAP solution.** `API_BILLING_DOCUMENT_SRV` directly covers the SD billing header/item, delivery reference, status indicators and `LastChangeDateTime`.

**Hard gate.** The functional label does not establish whether the client object is SD billing/intercompany billing, MM supplier invoice or an India GST stock-transfer document. The service is correct only for the SD-billing case.

**Disposition:** `CONDITIONAL PRIMARY`, blocked by the exact STO-invoice object decision and activation.

### API-11 — Create STO Purchase Order

**Business requirement.** Create the STO PO that API-02 later uses as its predecessor, carrying source/receiving plants, organisation, product, quantity, delivery date, requisition references and returning the PO key.

**SAP solution.** Use `API_PURCHASEORDER_PROCESS_SRV` deep create across header, item and schedule line.

**What must be changed or built.** Confirm document type/item category and derivations. The v1.7 `ShippingType` input has no home on the purchase-order model; functional/product must move it to the later delivery, make it derived, or remove it. CPI/T2 must provide idempotency because the standard create has no `RequestId` replay contract.

**Disposition:** `PRIMARY`, pending activation, client STO configuration and contract correction.

### API-12 — Update DI Quantity

**Business requirement.** Change only the quantity of an open outbound delivery before batch determination; successful change requires fresh batch determination.

**SAP solution.** `API_OUTBOUND_DELIVERY_SRV;v=2` is the leading service; the model contains item quantities and updatable delivery entities.

**What must be completed.** Prove the exact writable quantity property, `If-Match`/ETag behavior, open-status restrictions, unit handling, and whether the client's “reset batch determination” effect is SAP behavior or a portal workflow rule. Test one authorised DEV update and one expected rejection after the cutoff state.

**Disposition:** `LEADING PRIMARY CANDIDATE`, pending exact operation and runtime proof.

## 4. Minimum provisioning set

### Released services to request in DEV

| Service | Version/path requirement | Target operations |
|---|---|---|
| `API_MATERIAL_DOCUMENT_SRV` | no version selector currently documented | API-01 create/read-back basis |
| `API_OUTBOUND_DELIVERY_SRV` | **version 2**, runtime path `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/` | API-02, API-03 delivery/PGI stages, API-09, API-12 |
| `API_BILLING_DOCUMENT_SRV` | V2 service | API-03 read-back and API-10 if SD billing |
| `API_PURCHASEORDER_PROCESS_SRV` | confirm V2/V4 policy before commitment | API-08 and API-11 |
| `API_MATERIAL_STOCK_SRV` | V2 service | API-05 |

Basis/Security must supply for each: registration/activation evidence, system alias, active ICF node, service version, technical user/role assignment, CSRF/session behavior and a DEV test URL. A row in `/IWFND/MAINT_SERVICE` is not the completion criterion.

### Already registered services to test, not automatically adopt

| Service | Purpose | Adoption gate |
|---|---|---|
| `MMIM_MATDOC_SRV` | API-01 material-document item read-back | `$metadata`/GET proof and permission to use a read-only Fiori service |
| `SD_CUSTOMER_INVOICES_CREATE` | API-03 billing creation | Architecture permits internal service; POST works on representative DEV due-list item; accounting/read-back behavior understood |

## 5. `/IWFND/GW_CLIENT` evidence protocol

### 5.1 Metadata proof

For each selected OData V2 service, run in `/IWFND/GW_CLIENT`:

```http
GET /sap/opu/odata/sap/<SERVICE>/$metadata
Accept: application/xml
```

Use `API_OUTBOUND_DELIVERY_SRV;v=2` exactly for the delivery family. Save:

- request URI and headers;
- HTTP status and response headers;
- complete metadata XML;
- screenshot showing system/client/user and status;
- the entity sets/actions/function imports and writable annotations used by the requirement.

If a selected service is OData V4, provision it through `/IWFND/V4_ADMIN` and use its actual V4 service group/path. Do not force a V4 successor into a V2 URL.

### 5.2 Safe read proof

After metadata succeeds, run the narrowest representative GET using approved non-sensitive DEV/QAS data. Capture the request and complete response. Examples:

- material document by document/year;
- outbound delivery header/items/document flow by delivery key;
- billing document header/items by billing key;
- purchase order/header/item/schedule line by STO PO;
- material stock with plant/material/storage-location filters and small `$top`.

The purpose is to prove key syntax, navigation, filters, paging, local authorisation and field population—not to export production-like datasets.

### 5.3 CSRF and write proof

Only in an authorised DEV client with functional test documents:

1. Send a GET to the service root with `X-CSRF-Token: Fetch`.
2. Reuse the returned token and session cookies.
3. Send the exact POST/PATCH/action request with `Content-Type: application/json` and the required ETag/`If-Match` header where documented.
4. Save request body, response status/headers/body and created/changed SAP key.
5. Validate the resulting document in the relevant SAP transaction/app and capture status/document flow.
6. For a negative case, send one controlled invalid or stale request and capture the standard error plus `/IWFND/ERROR_LOG` or `/IWBEP/ERROR_LOG` evidence.

Do not perform posting tests in QS4 or another shared client without explicit write authority. Metadata and safe reads do not authorise business writes.

### 5.4 Minimum runtime test cases

| Service/route | Positive proof | Required negative/boundary proof |
|---|---|---|
| Material document | partial accepted GR with two valid SLoc items; material document/year returned | over-receipt or invalid SLoc rejected; replay protection demonstrated at CPI/T2 layer |
| Outbound delivery v2 | create from sales order; create from STO PO | quantity above open balance rejected; invalid/blocked predecessor; quantity update after cutoff rejected |
| Outbound delivery PGI | pick/batch/PGI on approved DEV delivery | insufficient/ineligible batch or stale ETag rejected |
| Billing create route | create billing from eligible DI and read it through billing API | ineligible/already-billed reference handled without duplicate billing |
| Purchase order processing | read STO and create one test STO PO | invalid plant pair/type/category rejected; duplicate request does not create a second PO through envelope control |
| Material stock | filtered plant/SLoc/material result reconciled to SAP stock display | excluded stock type demonstrably absent or separately identified |
| Shipment calculation | estimate for configured DI/transporter | missing rate/route returns controlled no-rate result |
| Statutory routes | approved test extension/correction request and persisted status | outside-window/invalid-state request rejected without duplicate external submission |

## 6. Proof pack structure

Create one evidence directory per runtime service/test. Each directory must contain:

1. `01_metadata_request.txt`
2. `02_metadata_response.xml`
3. `03_read_request.txt`
4. `04_read_response.json`
5. `05_write_request.json` where applicable
6. `06_write_response.json` where applicable
7. `07_sap_document_validation.md`
8. `08_error_log.md`
9. `MANIFEST.tsv` with filename, byte count, SHA-256, system, client, timestamp, tester and test-data key

Redact credentials, cookies, CSRF tokens and personal data before placing evidence in a shareable deliverable. Preserve unredacted evidence only in the approved client workspace.

## 7. Work ownership

| Work | Primary owner | Siddharth's responsibility |
|---|---|---|
| Service registration, ICF, alias, roles | Basis/Security | Issue exact activation set; verify rather than perform unauthorised changes |
| Business document/config mapping | MM/SD/LE/FI/Tax | Drive precise questions; map the confirmed answer into requests/tests |
| Standard API validation | ABAP/Siddharth | Own metadata analysis, SAP request/response, document verification and gap decision |
| Thin SAP endpoint for proven gap | ABAP/Siddharth + ABAP lead | Build only after standard/existing route is disproven; use reusable class and narrow contract |
| Cross-service orchestration and process status | CPI/T2 | Supply SAP operations, error semantics and compensation constraints; do not absorb iFlow ownership |
| Idempotency/replay envelope | CPI/T2/architecture, with SAP input | Prove the standard calls are non-idempotent and define SAP-side duplicate checks where unavoidable |
| Stock ageing and replicated reads | Datasphere/T2 | Keep live API separate; supply/validate SAP extraction logic if assigned |
| Functional acceptance | Business and functional leads | Supply created document evidence; never self-approve semantics |

## 8. What must be completed before Monday

### Strike 1 — close the remaining design-time gaps

- Complete requirement-level API-09 mapping against outbound delivery v2.
- Complete API-12 writable-field/operation analysis against outbound delivery v2.
- Trace the actual SAP object and call path for shipment costing, E-Way extension and invoice correction.
- Get functional answers for movement/reference type, STO document type/item category, stock categories, STO invoice object and API-11 `ShippingType`.

### Strike 2 — provision and prove runtime

- Submit the exact five-service DEV activation request.
- Capture `$metadata` for every activated service and for the two registered complements.
- Execute safe reads first.
- Execute authorised writes in risk order: STO/PO and DI test documents as functional data permits; material-document and PGI only with controlled quantities; billing/statutory only with the named owner present or written approval.

### Strike 3 — freeze the build-gap backlog

For each v1.7 field/operation, assign one of four implementation outcomes:

- `STANDARD-DIRECT`
- `STANDARD + CPI/T2 ADAPTER`
- `EXISTING CLIENT ROUTE`
- `PROVEN CUSTOM GAP`

No row may remain “standard API exists but not activated.” It must state the service/version, exact operation, missing fields/behavior, activation/configuration, owner, test result and evidence path.

## 9. Monday deliverable

The Monday submission should contain five things:

1. This requirement-to-solution map, with dispositions updated from runtime results.
2. The exact service activation/provisioning sheet and role/config dependencies.
3. `$metadata` plus representative request/response proof for every service that is claimed callable.
4. A short, named build backlog for genuine gaps—shipment calculation, statutory callable boundary, billing-create fallback, DMG/STG ledger—only where the weekend evidence still requires it.
5. Siddharth's ABAP execution plan for DEV: classes/endpoint only for gaps, standard-service test harnesses, logs, negative tests, transports and functional sign-off gates.

The defensible statement is:

> We inspected the full local SEGW catalogue, compared the strongest candidates field-by-field against v1.7, rejected misleading registered application services, selected the released standard core, and identified the exact remaining configuration, orchestration and custom gaps. Runtime claims are backed by local metadata and controlled request/response evidence; anything not yet proven is named as a gate, not disguised as available functionality.

## 10. Evidence references

- `sources/SRC-DOC-20260815-01_CNF_API_Request_Response_Specification_v1.7.xlsx`
- `sessions/2026-08-15-standard-api-discovery/CNF_FULL_CATALOG_DISCOVERY_REPORT.md`
- `sessions/2026-08-15-standard-api-discovery/TIER_A_DEEP_DIVE_FINDINGS.md`
- `sessions/2026-08-15-standard-api-discovery/CNF_STANDARD_API_MATRIX.tsv`
- `sessions/2026-08-15-standard-api-discovery/API_MATERIAL_DOCUMENT_DEEP_DIVE.md`
- `sessions/2026-08-15-standard-api-discovery/OUTBOUND_DELIVERY_DELTA.md`
- `sessions/2026-08-15-standard-api-discovery/INBOUND_DELIVERY_DELTA.md`
- `PROJECT_BRAIN.md`, `DECISION_LOG.md`, `OPEN_QUESTIONS.md`, `SYSTEM_OF_RECORD_MATRIX.md`
