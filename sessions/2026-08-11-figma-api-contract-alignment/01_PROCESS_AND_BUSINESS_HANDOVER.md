# Process and Business Handover

## 1. The operational change being built

Today, depot C&F users are expected to know SAP well enough to execute the complete inbound receipt and outbound fulfilment journeys directly. The portal's job is to replace that operational friction with guided business screens, validations and auditability while preserving S/4HANA as the transactional authority (`SRC-SID-20260811-12`).

The architecture still contains T1, T2, CPI, Datasphere and statutory services. For the current ABAP workstream, the learning priority is narrower: understand each SAP-facing operational API, what the caller chooses, what SAP derives, what SAP validates, what document is created, and what authoritative key is returned. Detailed batch/event synchronization study is intentionally deferred.

## 2. Two foundational journeys

### 2.1 Inbound receipt — the MIGO journey

```text
Plant dispatch / outbound delivery
        ↓
Goods travel to receiving depot
        ↓
Pending-receipt / “Pending MRN” work item is displayed
        ↓
C&F user records the new receipt-classification delta
        ↓
SAP validates the live delivery/PO/plant/quantity state
        ↓
MIGO goods-receipt posting
        ↓
SAP material document + material-document year
        ↓
Pending / Partial / Completed receipt state is refreshed
```

Clinical ABAP distinction:

- **MIGO** is the SAP transaction/process used to post the goods movement; it is not itself the returned business document.
- A successful GR creates a **material document**. In S/4, the authoritative key includes the material-document number and material-document year.
- “Pending MRN” is currently best understood as a derived in-transit/pending-receipt position, not a proven separately created SAP document (`D-021`, `C-14`).
- The Figma success toast says “MRN Document Number,” but that label does not prove that Submit MIGO returns an MRN object. Until MM/SD/ABAP confirmation, the API should preserve SAP's material-document key and treat the UI term as unresolved.

The validated MIGO UI separates cumulative history from the current attempt. The current attempt is a classification delta and must not exceed the displayed pending quantity. Values use 0.05-MT increments (`SRC-FIG-20260811-08`).

Latest direct business rule for exceptional quantities:

- accepted classifications can become GR-posted stock;
- `DMG` and `STG` are rejected/non-stock outcomes;
- those quantities remain/add to replacement demand and require a later Order → DI → MIGO cycle (`SRC-SID-20260811-07`).

This directly conflicts with parts of the current v1.7 workbook that model DMG/STG as storage-location allocations. Do not implement from those workbook rows until corrected.

### 2.2 Outbound fulfilment — the DI/invoice journey

```text
Open predecessor quantity
        ↓
Create DI / SAP outbound delivery
        ↓
Optional DI quantity modification while still open
        ↓
Storage location + SPI selection
        ↓
FIFO batch proposal/allocation, with live SAP revalidation
        ↓
Transporter + LR/GR + vehicle/driver/pickup details
        ↓
Shipment cost calculation
        ↓
PGI → billing document → e-Invoice → E-Way Bill
        ↓
Document-flow status and downloads
```

Validated product rules:

- DI and SAP outbound delivery are the same project object (`D-007`, `SRC-SID-20260811-02`).
- The Create DI modal asks the user for delivery quantity; SAP derives document context already available from the selected predecessor (`SRC-FIG-20260811-02`).
- A DI quantity change is a quantity-only action while the DI is still open and before batch determination. The next portal step is batch determination; exact SAP reset behavior is not proven.
- FIFO means oldest **eligible** inventory/batch first. SAP must still validate batch eligibility, live stock and quantity before PGI (`SRC-SID-20260811-10`).
- Document Flow exposes PGI, shipment, shipment cost, invoice, e-Invoice, E-Way Bill and download as independently Generated, Processing or Not Generated (`SRC-FIG-20260811-04`).

All SAP-facing operational calls are treated as real-time request/response interactions for this workstream. That does not force the entire downstream chain to complete inside one blocking LUW; the product itself exposes intermediate document states.

## 3. Trade, Non-trade and STO

| Flow | Predecessor business document | What changes | What stays shared |
|---|---|---|---|
| Trade | Sales order | Customer/channel context | DI and downstream fulfilment |
| Non-trade | Sales order | Customer/channel context | DI and downstream fulfilment |
| STO / intra-warehouse | Stock-transport purchase order | Internal source/receiving plant context and SAP predecessor maintenance | DI, shipment/PGI/billing/e-document journey; receiving-side GR later |

The validated STO Figma chronology is (`SRC-FIG-20260811-09`..`12`):

1. **Purchase Order:** list/open quantities plus a Create New Purchase Order modal.
2. **Create DI:** create a full or partial DI against the PO's pending quantity.
3. **In Process:** use the same quantity, batch, transporter, freight and shipment journey as the sales-order flow.
4. **Document Flow:** DI → PGI → shipment → shipment cost → invoice → e-Invoice → E-Way Bill → receiving-side GR.

Important boundary: the UI proves a purchase-order creation action exists in the validated product design. Working v1.7 now models it as **candidate API-11 Create STO Purchase Order**, only for the STO/intra-warehouse path. The formal manager-shared T2→S/4 interface list does not include it, so exact SAP MM ownership, document type and service/BAPI remain open. A successful API-11 PO number feeds API-03 as the `STO_PO` predecessor.

## 4. Physical inventory and stock availability

API-04 is the sole live stock read required for the physical-inventory screen (`SRC-FIG-20260811-05`, `SRC-SID-20260811-04`, `SRC-SID-20260811-09`). Its grain is:

```text
selected plant/depot
  → products/materials
    → storage locations
      → SAP system quantity and stock-age context
```

- no DI context belongs in this read;
- plant is required;
- material and storage location may act as optional filters;
- API-04 does not by itself post a variance;
- removing API-12 removes a duplicate read contract, not the unresolved physical-count posting/audit workflow.

Do not conflate this with outbound batch eligibility. The same S/4 stock authority may be reused internally, but API-06 must still perform live transactional validation before PGI.

## 5. E-Way Bill management and extension

The complete design (`SRC-FIG-20260811-13`) contains two different concerns:

1. **Management/list read:** searchable rows with invoice, document, DI, E-Way Bill, validity, order, product, ship-to, customer, LR/GR, vehicle and driver context.
2. **Extension command:** select one E-Way Bill, review context, enter the current road/location and reason details, and request an extension.

The management-list columns must not inflate API-08's command payload. They are selected-document context or a separate read model.

Visible extension inputs include Road transport mode, vehicle, From Place, From State, Pincode, reason and remarks. Government/provider payload needs such as remaining distance, consignment status and conditional transit type are integration/SAP/GSP mapping questions if they are not entered on the screen.

Confirmed policy statement (`SRC-SID-20260812-01`):

- extension is eligible only during the eight hours immediately before the current expiry;
- there is no after-expiry eligibility window;
- a successful extension adds exactly 24 hours;
- the duration is fixed, so the caller does not send an `ExtensionHours` field; the response returns the authoritative updated-valid-until timestamp.

## 6. Configuration and master-data knowledge added today

| Concept | Today's understanding | Evidence boundary |
|---|---|---|
| Incoterms | Business scope states FTP, FTB, EXW/EX Works | KDS also contains EXP and EXR; reconcile allowlist vs configured universe |
| Organization | Session states 1000 = Shree Cement Limited; 1300 = Shree Cement East | `C-10`: existing client mapping treats 1300 as company code; do not bind to `VKORG` yet |
| Division | 10 = Cement; `TSPA-SPART` | Supplied mapping screenshot supports the code/table/field |
| Order ageing | PO/SO creation to arrival, or current date while still open/in transit | Exact arrival event and calculation owner remain to validate |
| Stock ageing | Days inventory has remained in stock | Supplied stock-age mapping shows inventory-age/report fields; source timestamp and batch grain need validation |
| FIFO | Oldest eligible stock/batch proposed first | SAP determination owner and exact age/date field remain open |
