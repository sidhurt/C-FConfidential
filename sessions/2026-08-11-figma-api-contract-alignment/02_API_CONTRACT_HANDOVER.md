# API Contract Handover

## 1. Current v1.7 catalogue

The workbook on disk has one Overview sheet and eleven API sheets. Siddharth's current v1.7 numbering is authoritative and consecutive from API-01 through API-11.

| ID | Current name | Role | Today's state | Main unresolved gate |
|---|---|---|---|---|
| API-01 | Check MIGO / Pending Receipt | Read/composite | Retained | Confirm whether T2/Datasphere serves the list and whether ABAP owns validation, extraction, both or neither (`C-15`) |
| API-02 | Submit MIGO | Command | Retained; contract correction required | Remove DMG/STG as stock-location posting inputs; settle exact posting reference and returned identifier (`C-14`) |
| API-03 | Create DI | Command | Aligned to Trade, Non-trade and STO | Validate SO vs stock-transport PO document types, mapping and SAP operation |
| API-04 | Stock Availability | Read/composite | Sole physical-inventory/stock read | Correct DMG example; confirm SAP source/DDIC and keep variance posting outside this read |
| API-05 | Shipment Cost Estimate | Read/calculation | Retained | Confirm calculation owner, inputs, response and pre-document feasibility |
| API-06 | Shipment, PGI & Invoice | Orchestration | Figma-aligned provisional contract | Validate transaction boundaries, recovery, DDIC fields, batch/SPI ownership and stage-status behavior |
| API-07 | Invoice Correction | Command | Narrowed to invoice/e-document transport-detail correction | Confirm cancel/regenerate mechanics and authoritative identifiers |
| API-08 | E-Way Bill Extension | Command | Figma-aligned; timing and fixed duration confirmed | Validate government/GSP fields, reason codes and response mapping |
| API-09 | Modify DI | Command | Quantity-only, open/pre-batch | Confirm SAP eligibility/status checks; do not claim batch reset internals |
| API-10 | Valid Storage Locations | Read/composite | Retained for MIGO initiation | Confirm source, allowed classifications and response filtering |
| API-11 | Create STO Purchase Order | STO-only command candidate | Figma validates the action; added to working v1.7 | Confirm formal scope, SAP MM ownership, PO type/item model and service/BAPI |

Removed operations, not reusable numbers:

- **Standalone E-Invoice Correction:** removed because it is not a required interface (`SRC-SID-20260811-09`). Current API-08 is E-Way Bill Extension.
- **Separate Inventory Reconciliation API:** removed because API-04 already owns the stock/physical-inventory read (`SRC-SID-20260811-09`).

## 2. Formal-list mapping

The manager/team baseline shows seven real-time T2→S/4 operations:

1. SubmitMigo
2. CreateDI
3. CreateInvoice
4. Shipment Calculation
5. Stock Availability
6. eWay bill extension
7. invoice correction

The v1.7 catalogue adds API-01 and API-10 because later UI/KT work exposes those needs. API-11 is a further STO-only candidate grounded in the validated Create Purchase Order Figma. These must be described as inferred/screen-supported extensions until the owner maps them into the formal interface register. The eleven-sheet workbook must not be called “the original formal eleven APIs.”

## 3. How to read the request fields

The user does not need to memorize every row as a separate business fact. Fields fall into four buckets:

| Bucket | Examples | Cognitive meaning |
|---|---|---|
| Technical envelope | `RequestId`, `SourceSystem` | Integration control; generated/injected by the application or middleware |
| Audit identity | `RequestedBy` | Prefer the authenticated principal; not a user-entered business decision |
| Business choice | delivery quantity, selected batch, reason, current location | What the C&F user or calling workflow actually chooses/asserts |
| Derived/assertion-only | material, plant, unit, org context | SAP should derive from the authoritative referenced document; optional assertion can detect mismatch |

`RequestId` is a contract-design control for replay/idempotency, especially around non-idempotent postings. It is not an SAP business field. `SourceSystem` should normally be injected. `RequestedBy` should normally be derived from authentication. Their presence in every sheet does not mean a depot agent enters or memorizes them.

## 4. API-specific contract rules established today

### API-02 — Submit MIGO

Authoritative success identity should be the SAP material document plus material-document year. The UI wording “MRN Document Number” remains unresolved and must not replace that key without MM/SD/ABAP confirmation.

The current v1.7 sheet is not safe to implement unchanged: it says DMG/STG are SAP storage-location inputs and returns posted material-document items for every allocation. The latest direct business rule says DMG/STG are rejected/non-stock classifications. A corrected contract must separate:

- accepted quantities that SAP posts to real receiving storage locations;
- rejected/non-stock DMG/STG quantities used for operational exception/replacement tracking;
- total classified/handled quantity;
- actual GR-posted quantity;
- remaining/replacement quantity.

The exact system of record for the rejection ledger remains open.

### API-03 — Create DI

Keep the caller contract minimal:

- selected predecessor document;
- workflow-fixed predecessor type (`SALES_ORDER` or `STO_PO`), if routing does not already determine it;
- delivery quantity;
- technical envelope/audit fields.

SAP derives material, unit, plant and organizational context and revalidates open quantity/blocks. Trade/Non-trade use a sales-order predecessor; STO uses a stock-transport PO. Do not add a separate DI object: DI is the outbound delivery.

The Create New Purchase Order action visible in STO Figma is now **candidate API-11** in working v1.7. It is invoked only for STO/intra-warehouse. On success, its returned `PurchaseOrder` feeds this API as `PredecessorDocument`, with `PredecessorType = STO_PO`. The exact SAP MM document type, item model, service/BAPI, commit behavior and ownership are still approval gates.

### API-04 — Stock Availability

Request grain:

- `Plant` — mandatory;
- `Material` — optional filter;
- `StorageLocation` — optional filter;
- technical envelope/audit fields as required by the service convention.

Response grain is product/material × storage location, with live SAP system quantity and units. `StockAgeingDays` may be returned when its authoritative stock-age source and grain are validated. API-04 contains no DI context and performs no physical-difference posting.

Remove DMG/STG from stock-location examples unless SAP system evidence proves they are real posting locations; the current direct clarification says they are non-stock rejection classifications.

### API-06 — Shipment, PGI & Invoice

The Figma-aligned business inputs are:

- DI reference;
- storage location and SPI;
- batch allocations and quantities, following oldest eligible stock first;
- transporter;
- LR/GR number and date;
- road vehicle/driver details;
- pickup code only when the configured Incoterm rule requires it.

The output is a correlated chain of stage/document states, not a single invoice number only. A real-time request can return an authoritative acceptance/result and still expose later Generated/Processing/Not Generated stage states. Exact LUWs, commits, compensations and retry behavior require SAP design.

### API-07 — Invoice Correction

The production design keeps invoice, DI, product, customer and document fields as context. The editable scope is narrow and transport/e-document-related. Do not reintroduce a generic E-Invoice Correction endpoint; API-08 now means E-Way Bill Extension.

### API-08 — E-Way Bill Extension

The current workbook sheet still says it is awaiting Figma validation; therefore it is not today's target contract. The intended next revision is:

**Caller/business inputs**

- technical envelope and authenticated audit identity;
- `EWayBillNumber`;
- current/replacement `VehicleNumber` for the Road flow;
- `FromPlace`, `FromStateCode`, `FromPincode`;
- operational extension-reason label mapped to the provider code;
- mandatory remarks, 200-character UI limit.

**Integration-derived or technically validated fields**

- remaining distance;
- consignment status;
- conditional transit type;
- transport mode and existing Part-B/LR-GR context;
- eligible transporter/generator identity.

**Response**

- technical result envelope;
- E-Way Bill number;
- authoritative updated-valid-until timestamp;
- retained vehicle number;
- optional provider response code for audit/support.

Do not include invoice, DI, customer, product or other management-list display columns simply because they are visible beside the action. Per `SRC-SID-20260812-01`, accept the extension only during the eight hours immediately before expiry; there is no after-expiry window. Success adds exactly 24 hours. Do not include `ExtensionHours`; return the authoritative `UpdatedValidUpto` timestamp.

Official technical validation reference: [E-Way Bill Extend Validity API](https://docs.ewaybillgst.gov.in/apidocs/version1.03/extend-validity.html).

### API-09 — Modify DI

Keep this a quantity-only change while the DI is open and before batch determination. After success, the portal routes to batch determination. The contract may report that batch determination is required, but must not claim how SAP clears or resets internal batch state without system evidence.

### API-11 — Create STO Purchase Order (candidate)

This command exists only for the STO/intra-warehouse entry path shown by the validated Figma. Trade and Non-trade continue from an existing sales order and must never call it.

Core caller business fields are source plant, receiving plant, company code, shipping type, purchasing group, product, PO quantity, delivery date, requisition number and requisitioner, plus the technical envelope. The success response must return the authoritative SAP stock-transport purchase-order number. Purchasing organization and unit should be SAP-derived wherever configuration permits.

The business action is validated; the interface remains candidate until SAP MM/architecture confirms the PO document type, item/category model, field domains, approval behavior, implementation and ownership.

## 5. Verified workbook state and defects

In-place update and render verification of `CNF_API_Request_Response_Specification_v1.7.xlsx` on 12 August found:

- sheets present: Overview and API-01 through API-11;
- current numbering: API-08 E-Way Bill Extension, API-09 Modify DI, API-10 Valid Storage Locations, API-11 Create STO Purchase Order candidate;
- API-03 and API-06 contain the shared STO downstream model;
- API-04 is marked as the sole stock/physical-inventory read;
- API-09 avoids an unsupported reset claim;
- API-08 reflects the confirmed pre-expiry-only eligibility window and fixed 24-hour extension;
- API-11 is visibly separated as a candidate and links its PO result to API-03;
- Overview/API-02 incorrectly call DMG/STG SAP storage locations;
- API-04 contains a DMG stock-location example that conflicts with the latest direct clarification;
- Overview describes `1300` as a sales organisation even though `C-10` is unresolved;
- FIFO is written as settled in the workbook while its SAP implementation ownership remains unvalidated.

Treat the workbook as the latest **working contract**, not as a signed or implementation-ready specification.
