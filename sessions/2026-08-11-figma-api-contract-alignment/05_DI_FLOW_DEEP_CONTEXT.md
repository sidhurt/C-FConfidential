# Delivery Instruction Flow — Deep Context for the Next AI

## Precision guard before reading

In the current v1.7 catalogue:

- **API-03 = Create DI** — creates the SAP outbound delivery.
- **API-09 = Modify DI** — changes its quantity while it is still open and before batch determination.
- **API-04 = Stock Availability** — the plant-scoped product × storage-location read used for physical-inventory/system-stock visibility. It has **no DI context**.
- **API-06 = Shipment, PGI & Invoice orchestration** — carries the later DI-specific storage-location/SPI, batch, shipment and billing journey.
- **API-11 = Create STO Purchase Order candidate** — creates the predecessor used only by the STO/intra-warehouse path before API-03.

An earlier iteration inferred that formal API-04 was a DI/batch-availability API because stock validation appears inside the outbound Figma journey. That interpretation was superseded by the validated Physical Inventory Reconciliation flow and direct clarification `SRC-SID-20260811-04`. Do not restore the old DI-shaped API-04 contract.

The valid relationship is narrower: the DI journey needs live SAP stock/batch validation, but that transactional validation belongs inside the outbound fulfilment design/API-06 or an explicitly approved reusable stock service. It does not change API-04's caller contract into a DI request.

## 1. DI means outbound delivery

“Delivery Instruction,” “DI,” and “SAP outbound delivery” refer to the same project document (`D-007`, `SRC-SID-20260811-02`). There is no second instruction object that later creates an outbound delivery.

The portal uses business language; S/4 remains authoritative for:

- predecessor validity;
- open quantity;
- delivery blocks and status;
- material, unit and plant context;
- delivery number and internal item;
- whether a change or later PGI is allowed.

## 2. Entry states by business flow

| Flow | Starting work item | SAP predecessor selected by the user/workflow | Shared result |
|---|---|---|---|
| Trade | Pending sales order | Sales order | DI/outbound delivery |
| Non-trade | Pending sales order | Sales order | DI/outbound delivery |
| STO / intra-warehouse | Pending stock-transfer PO | Stock-transport purchase order | DI/outbound delivery |

The predecessor changes. The post-DI product journey is shared (`SRC-SID-20260811-08`, `SRC-FIG-20260811-09`..`12`).

If an STO work item does not yet have a PO, the validated Create Purchase Order action invokes candidate API-11 first. Its authoritative SAP `PurchaseOrder` result becomes API-03's `PredecessorDocument`; the workflow fixes `PredecessorType = STO_PO`.

## 3. Validated Create DI interaction

```text
Pending order/PO row
   ↓ select
Read-only order and logistics context
   ↓
Enter Delivery Quantity
   ↓
Portal pre-checks obvious errors
   ↓
API-03 sends predecessor + quantity + technical envelope
   ↓
SAP revalidates live state and creates outbound delivery
   ↓
Response returns authoritative DI number
   ↓
Work item becomes Partial/Fulfilled and DI enters In Progress
```

The production design shows these user-facing rules (`SRC-FIG-20260811-02`, `SRC-FIG-20260811-10`):

- credit-blocked sales-order work cannot create a DI;
- delivery quantity must be positive;
- delivery quantity cannot exceed current pending quantity;
- quantity uses the screen's 0.05-MT increment convention;
- partial quantity is allowed and leaves a remaining predecessor quantity;
- success returns a DI number.

The screen displays order number/date, product, customer/ship-to or source/receiving plant, organization, Incoterm and other context. Display does not make each value a request field.

## 4. Minimal API-03 caller contract

| Field category | Data | Why |
|---|---|---|
| Technical | `RequestId`, injected `SourceSystem`, authenticated `RequestedBy` | Replay control, routing and audit; not depot-user business inputs |
| Required business reference | `PredecessorDocument` | Tells SAP which sales order or stock-transport PO is being fulfilled |
| Workflow discriminator | `PredecessorType`, only if route/context does not already fix it | Prevents ambiguous SO/PO interpretation; not a free-form user choice |
| Required business choice | `DeliveryQuantity` | The one editable value in the validated Create DI modal |
| Optional correlation | T1/CRM order code | Logging/correlation only; not the SAP predecessor key |
| Derived/assertion-only | material, unit, plant, organization, Incoterm | SAP already owns these on the predecessor; use only for mismatch protection if approved |

Expected success identity is the SAP outbound-delivery number. Exact DDIC lengths, document types, BAPI/OData implementation, commit behavior and idempotency store remain design/validation work.

## 5. What happens after DI creation

### 5.1 Optional quantity change — API-09

While the DI is open and before batch determination, the user may change quantity. The contract sends the DI number and new quantity. SAP must revalidate status and limits.

After a successful change, the portal proceeds to batch determination. The product flow establishes that batch determination is required next; it does not prove how SAP internally clears or resets prior batch state.

### 5.2 Batch and storage allocation — API-06 context

The validated In Process flow captures:

1. DI quantity confirmation/change;
2. storage location;
3. SPI;
4. candidate batches and available quantity;
5. batch allocation equal to DI quantity;
6. FIFO ordering — oldest eligible stock first;
7. SAP revalidation of stock, eligibility and quantity before PGI.

This is where DI-specific live stock matters. The screen may use the same underlying S/4 stock authority as API-04, but the business grain is different:

| Concern | Grain | Contract owner in v1.7 |
|---|---|---|
| Physical/system stock visibility | Plant → material → storage location | API-04 |
| DI fulfilment eligibility | DI → source SLoc/SPI → eligible batches → allocated quantity | API-06/SAP transactional validation |

Never use stale dashboard/ageing stock as permission to PGI.

### 5.3 Transport and shipment

After batch determination, the user selects or confirms:

- transporter/forwarding agent;
- LR/GR number and date;
- Road vehicle number;
- driver code/name/mobile where maintained;
- pickup code when the configured Incoterm requires it.

API-05 supplies or validates the shipment-cost estimate. The exact rate source, calculation owner and response contract remain open.

### 5.4 PGI, billing and statutory documents

The shared downstream sequence is:

```text
DI
 → PGI
 → Shipment Number
 → Shipment Cost
 → Billing/Invoice Number
 → e-Invoice/IRN
 → E-Way Bill
 → Download/status visibility
```

The UI exposes each stage independently as Generated, Processing or Not Generated (`SRC-FIG-20260811-04`). A synchronous API interaction and a multi-stage document chain are compatible: the call returns an immediate authoritative result/correlation, while downstream stages can have their own states.

For STO, receiving-side GR appears later in document flow (`SRC-FIG-20260811-12`). It belongs to the receiving MIGO journey and must not be represented as an API-06 outbound stage.

## 6. Failure and correction boundaries

- **Create DI rejected:** no DI number; return stable error code/message and do not manufacture a portal document.
- **Quantity change rejected:** retain the original SAP quantity/state.
- **Batch/stock failure:** block progress before PGI and refresh live eligibility.
- **Later invoice/e-document failure:** retain already-created SAP document keys and expose stage-level failure/retry behavior; do not pretend the whole chain vanished.
- **Invoice Correction/API-07:** deals with the validated correction scope and must not revive a generic E-Invoice Correction interface.
- **E-Way extension/API-08:** occurs against an existing E-Way Bill and is outside DI creation.

## 7. State model another AI should retain

```text
PREDECESSOR_PENDING
  ├─ create full quantity ─→ DI_CREATED / predecessor fulfilled
  └─ create partial qty ───→ DI_CREATED + predecessor partially fulfilled

DI_CREATED
  ├─ eligible quantity edit ─→ DI_CHANGED → BATCH_DETERMINATION_REQUIRED
  └─ no edit ────────────────→ BATCH_DETERMINATION_REQUIRED

BATCH_DETERMINED
  → SHIPMENT_DETAILS_READY
  → PGI / shipment / cost stages
  → BILLING
  → E_INVOICE
  → E_WAY_BILL
  → DOCUMENTS_AVAILABLE

STO only, later at receiver:
  → PENDING_RECEIPT
  → MIGO / GR
```

Names above are conceptual states for reasoning, not confirmed SAP status codes.

## 8. Open SAP questions that must survive handover

1. Which exact SO and stock-transport PO types are in scope?
2. Which standard/custom operation creates the outbound delivery for each predecessor?
3. Candidate API-11 is now present in working v1.7; who formally owns it, and which exact SAP MM service/BAPI and PO document type implement it?
4. What exact block/status checks gate Create DI and Modify DI?
5. Where are SPI and FIFO batch determination implemented/configured?
6. Which date/field drives stock age, and how are ties/blocked batches handled?
7. What are API-05's authoritative freight inputs and rate source?
8. How are API-06 stages committed, correlated, retried and compensated?
9. Which read model supplies the document-flow screen and at what SLA?
10. What exact identifier/key is returned at each stage?
