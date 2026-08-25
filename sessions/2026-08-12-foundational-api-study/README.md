# CNF API Foundations — Siddharth's Single Study Guide

**Date:** 2026-08-12  
**Purpose:** build a reliable personal mental model before studying implementation alternatives  
**Status:** evidence-constrained study guide; not an approved technical specification  
**Read rule:** use this file as the only entry point for the present study phase

## Your first session—do only this

Do not attempt the whole guide today.

Your first 40-minute objective is:

> **Explain how an existing sales order becomes a DI, and how changing that DI differs from creating it.**

Read only:

1. §1 — The mental model
2. the Sales order and DI rows in §2
3. §3.0 and §3.1 — the outbound rail, then Trade and Non-trade
4. the API-03 and API-09 cards in §6
5. functional challenge cases 1 and 2 in §10

Pass condition, without notes:

- draw `Sales order → API-03 → DI/outbound delivery`;
- explain why Delivery Quantity is a caller choice but material/plant/org context is SAP-derived;
- explain why API-09 changes an existing DI instead of creating another;
- identify the SD functional seam crossed by each call and the SAP state before/after it;
- state exactly where your knowledge stops.

Only after you pass should you move to API-01/API-02. This prevents broad familiarity from impersonating mastery.

## Why this floor matters

Your professional danger is not “I do not remember the BAPI name.” That is searchable.

The real danger is being unable to answer, under pressure:

- What existed before this call?
- What changed in SAP?
- Which document proves it changed?
- What did the user choose versus what SAP derived?
- What happens if the caller retries after a timeout?

An experienced SAP person can forgive an unknown method name. They will not trust an API owner who confuses PGI with GR, a screen with a contract, a read with a reservation, or an invoice with an E-Way Bill.

These mistakes have weight:

- a weak read returns a bad screen;
- a weak DI command can create a duplicate delivery;
- a weak MIGO command can change the wrong stock;
- a weak invoice/statutory command can leave commercially or legally inconsistent documents;
- a weak explanation makes the ABAP team stop treating you as the owner.

The standard is therefore not “I have seen all the files.” It is:

> **I can reconstruct the process from first principles, identify the state transition, and refuse to invent what the evidence does not prove.**

That is the floor.

## Your three invariants

Every endpoint must be reduced to three facts:

```text
STATE BEFORE
    + CALLER'S DELTA
    = AUTHORITATIVE STATE AFTER
```

Examples:

```text
Open sales-order quantity
    + requested delivery quantity
    = SAP outbound delivery / DI

Pending receivable quantity
    + current accepted receipt allocation
    = GR material document + refreshed pending balance

Existing E-Way Bill near expiry
    + approved extension reason/current location delta
    = provider-authoritative UpdatedValidUpto
```

When a contract looks complex, return to this equation. Context fields may surround it, but the business action is usually a small delta against an existing object.

## 0. The boundary of this study

This phase covers only:

1. the business event;
2. the SAP document or state involved;
3. the endpoint's responsibility;
4. the meaning of its request;
5. the authoritative result;
6. the failure stakes.

This phase deliberately excludes:

- the API-06 decomposition/fork;
- one endpoint versus many endpoints for the downstream chain;
- SEGW service count or grouping;
- T2-versus-S/4 orchestration placement;
- detailed BAPI, class, CDS and table predictions;
- effort estimates and build sequencing.

Those questions matter later. Learning them now would mix a stable business foundation with an unsettled design discussion. This boundary is direct instruction `SRC-SID-20260812-04`.

### Priority inside the foundation

**Primary track — study first**

```text
SAP functional process
  → document sequence
  → process precondition
  → API collision point
  → SAP state after the call
  → next functional step
```

**Secondary track — study after the process map is automatic**

```text
request/response purity
  → idempotency
  → authorization/security
  → error normalization
  → technical envelopes
```

The secondary track protects the operation. It cannot tell you what operation the business actually needs. If you secure and retry the wrong state transition perfectly, you have simply built a more reliable mistake.

---

## 1. The mental model to own

Never collapse these layers:

| Layer | Question | Example |
|---|---|---|
| User journey | What is the depot user trying to complete? | Receive goods, create a DI, generate billing documents |
| Business operation | What single business change or lookup occurs? | Post GR, change DI quantity, estimate freight |
| SAP document/state | What is read, created or changed in S/4? | Outbound delivery, material document, billing document |
| API contract | What does the caller send and what must SAP return? | DI + revised quantity → accepted quantity/status |
| ABAP implementation | How will SAP perform it? | Read logic or an approved standard/custom operation |

The first four layers are the current study target. The fifth is deliberately shallow for now.

### The one-sentence test

You understand an endpoint only when you can say:

> Given **this existing business/SAP state**, the caller supplies **this small decision or reference**, SAP performs **this one authoritative job**, and returns **this document key or current state**.

If your explanation starts with a BAPI name, you are starting too low. If it starts with a screen full of fields, you are confusing UI context with the API contract.

### The traps your brain must actively resist

| Instinct | Why it feels intelligent | Why it weakens you | Correct move |
|---|---|---|---|
| Jump to BAPIs/classes | Feels close to implementation | You may automate the wrong business operation precisely | Name the state transition first |
| Unify the whole flow | Produces a clean grand model | Erases document, commit and ownership boundaries | Track one document/state change at a time |
| Copy the screen into JSON | Feels evidence-based | Display context becomes untrusted caller input | Isolate the editable delta |
| Treat a successful call as the whole journey | Simplifies narration | Later documents may still be processing or fail | Separate immediate result from later state |
| Build more documentation | Feels like progress and control | Can substitute for recall and judgment | Close the file and explain from memory |

Whenever you feel the urge to design the larger system, answer the three invariants for the current endpoint first. You do not earn architecture until the state transition is obvious.

---

## 2. The SAP documents you must recognize instantly

| Object | What it means here | What it is not |
|---|---|---|
| Sales order | Customer-facing predecessor for Trade and Non-trade fulfilment | Not a DI |
| Stock-transport PO | Internal-transfer predecessor for STO/intra-warehouse fulfilment | Not the destination GR |
| DI / Delivery Instruction | The project's business name for the SAP outbound delivery; DI number is the outbound-delivery number (`SRC-SID-20260811-02`, D-007) | Not a separate instruction that later creates a delivery |
| Shipment | Transportation document/context for moving the delivery | Not PGI and not billing |
| Shipment cost | Freight-cost document/calculation associated with transportation | Not the commercial invoice |
| PGI | Post Goods Issue: the source-side inventory issue against the outbound delivery | Not destination receipt |
| Billing document / invoice | SAP commercial billing result | Not the statutory e-Invoice or E-Way Bill |
| e-Invoice | Government/GST electronic invoice outcome with IRN/acknowledgement context | Not the ordinary SAP billing document |
| E-Way Bill | Statutory road-movement document | Not a shipment document |
| GR | Goods Receipt at the receiving location | Not part of source-side PGI |
| Material document | SAP evidence of the goods movement. For the GR result, preserve number **and year** as the authoritative key | Not “MIGO number” by default |
| Pending MRN position | Current higher-tier model: a derived pending/in-transit quantity, calculated from dispatched/invoiced quantity minus received quantity per delivery (`SRC-CODE-20260804-01`, D-021) | Not yet proven to be a separately created SAP document |

### PGI versus GR

This distinction must become automatic:

```text
Source side:       outbound delivery → PGI → source stock leaves
Goods in transit
Destination side: physical arrival → GR/MIGO → receiving stock enters
```

For STO, both sides belong to one end-to-end transfer, but they are different business events. GR appearing in Document Flow does not make it part of the source-side outbound posting (`SRC-SID-20260811-08`).

---

## 3. The three business flows

### 3.0 The SAP functional rails and API collision points

“Collision” here means the controlled seam where an external API meets an SAP-owned process. The API does not invent a parallel process. It enters SAP at a specific state, asks SAP to perform or expose a specific functional step, and leaves SAP as the authority.

#### Outbound rail

```text
BUSINESS DEMAND
Sales order (Trade/Non-trade) or STO PO
        │
        │ API-03 crosses demand → logistics execution
        ▼
DI / SAP outbound delivery
        │
        │ API-09 may change quantity while the delivery is still eligible
        ▼
Delivery preparation
storage location / SPI / batch eligibility / transport context
        │
        │ API-05 exposes the shipment-cost calculation seam
        ▼
Prepared dispatch
        │
        │ API-06 is the current downstream business boundary
        ▼
Shipment / PGI / shipment cost / billing / statutory outcomes
        │
        ├─ API-07 later corrects permitted invoice/e-document transport data
        └─ API-08 later extends an eligible existing E-Way Bill
```

Do not use this diagram to freeze the internal creation order or endpoint split inside API-06. Its purpose is to show the stable **functional movement**: demand becomes a delivery; the delivery is prepared; source stock is issued; billing/statutory outcomes follow.

#### Inbound rail

```text
Dispatched delivery / transfer
        ▼
Goods in transit and a pending receipt position
        │
        │ API-01 observes what remains receivable
        ▼
Physical arrival at receiving depot
        │
        │ API-02 crosses expected receipt → posted goods receipt
        ▼
GR material document + year
        ▼
Receiving stock and pending status refresh
```

API-01 lives on the **observation side** of the seam. API-02 crosses the **inventory-changing side**. That is why they are related but never interchangeable.

#### Inventory-visibility rail

```text
Current SAP stock state
        │
        │ API-04 observes and reshapes it for the physical-inventory screen
        ▼
Plant × material × storage-location system-stock view
```

There is no posting arrow. API-04 does not change stock. A later physical-count or reconciliation action is a different functional concern.

#### Collision map

| API | SAP functional seam | State before | State after / observation |
|---|---|---|---|
| API-11 candidate | MM Purchasing / stock-transfer demand | No STO PO for the intended transfer | STO PO exists and can precede delivery creation |
| API-03 | SD/LE order-to-delivery | Open sales-order or STO-PO quantity | DI/outbound delivery exists |
| API-09 | LE delivery maintenance | Open, change-eligible DI | Same DI with SAP-accepted revised quantity |
| API-04 | MM inventory visibility | Current SAP stock | Same stock, reshaped as a read result |
| API-05 | Transportation/freight calculation | Prepared DI + transport context | Same business documents plus a cost estimate |
| API-06 | Outbound completion/billing boundary | Prepared DI/dispatch context | Downstream document references and stage states |
| API-07 | Billing/statutory correction | Existing billing/e-document context | Permitted transport details and statutory states updated |
| API-08 | E-Way Bill statutory lifecycle | Existing eligible E-Way Bill | Same E-Way Bill with authoritative new validity |
| API-01 | In-transit/receipt visibility | Dispatched versus already received quantities | Current pending receipt position returned |
| API-02 | MM Inventory Management receipt | Physically received, still-unposted quantity | GR material document exists; receiving stock/status changes |

This table is the primary curriculum. Contract fields and technical safeguards are learned only after you can redraw it from memory.

### 3.1 Trade and Non-trade

```text
Sales order
  → Create DI / outbound delivery
  → optionally change DI quantity while still open
  → select fulfilment stock/batches and transport details
  → calculate/confirm shipment cost
  → PGI, shipment, billing and statutory-document journey
```

Trade and Non-trade differ in business/customer context. Their SAP predecessor for this study is a sales order; the downstream DI-based journey is shared (`SRC-SID-20260811-08`).

### 3.2 STO / intra-warehouse

```text
Create or select stock-transport PO
  → Create DI / outbound delivery at the supplying side
  → source-side dispatch journey and PGI
  → goods travel
  → receiving depot performs MIGO/GR
```

The distinctive starting object is the stock-transport PO. Candidate API-11 exists only for this path. Its successful PO number becomes API-03's predecessor (`SRC-SID-20260812-02`, `SRC-FIG-20260812-01`).

### 3.3 MIGO / depot receipt
```text
Pending receipt position
  → user opens the current receivable position
  → user records the current receipt/classification delta
  → SAP re-reads live pending quantity and validates the posting
  → GR is posted
  → material document + year return
  → status becomes partial or complete
```

Prior inward history and the current submission are different. The current request must never replay old allocations (`SRC-FIG-20260811-08`, D-054).

### 3.4 The callback chain

The endpoints are easier to remember when each one resolves a question created by the previous one:

```text
API-11 asks: what starts an STO journey?
  → It creates the STO PO.

API-03 asks: how does an SO/STO PO become executable logistics work?
  → It creates the DI/outbound delivery.

API-09 asks: what if the DI quantity changes before fulfilment?
  → It changes that existing delivery; it does not create another one.

API-05 asks: what will the prepared shipment cost?
  → It calculates; it does not post PGI or billing.

API-06 asks: what business outcome follows a prepared DI?
  → It is the current downstream Create Invoice/Generate Billing Documents boundary; internal design is deferred.

API-07 and API-08 ask: what if an already-existing statutory outcome needs correction or extension?
  → They act on existing documents, not on the original order.

API-01 asks: what is still receivable at the destination?
  → It reads the current pending position.

API-02 asks: what happens when those goods physically arrive?
  → It posts GR and returns the material-document key.
```

This is separation of concerns with memory hooks:

- API-11 creates **the predecessor** that API-03 consumes.
- API-03 creates **the DI** that API-09 changes.
- API-05 calculates; API-06 advances the business journey.
- API-07/API-08 act on **results already created**, not on the predecessor.
- API-01 sees; API-02 commits.
- PGI is the source-side exit; GR is the destination-side entry.

---

## 4. The portfolio you should study now

The manager/team formal baseline contains seven real-time T2→S/4 operations: Submit MIGO, Create DI, Create Invoice, Shipment Calculation, Stock Availability, E-Way Bill Extension and Invoice Correction (`SRC-ARCH-20260811-01`, `SRC-CPI-20260811-01`, D-047).

The working study portfolio also contains screen- or process-supported additions. They are not all equally approved:

| Working ID | Study name | Type | Foundation status |
|---|---|---|---|
| API-01 | Check MIGO / Pending Receipt | Read | Derived workflow capability; exact source/ownership remains open |
| API-02 | Submit MIGO / Post GR | Command | Formal operation |
| API-03 | Create DI | Command | Formal operation |
| API-04 | Stock Availability | Read | Formal operation; physical-inventory/system-stock use case |
| API-05 | Shipment Cost Estimate | Calculation/read | Formal operation |
| API-06 | Create Invoice / Generate Billing Documents journey | Business command boundary | Formal operation; learn only its stable business boundary in this phase |
| API-07 | Invoice Correction | Command | Formal operation |
| API-08 | E-Way Bill Extension | Command | Formal operation; current working number |
| API-09 | Modify DI | Command | Derived but strongly SAP-bound operation |
| API-11 | Create STO Purchase Order | Command candidate | Functionally supported for STO only; SAP interface approval remains open |

There is deliberately no API-10 study card. The standalone Valid Storage Locations contract was removed. Storage-location choices are still required by the business flows, but the responsible source/contract remains unresolved (`SRC-SID-20260812-04`).

---

## 5. Secondary layer — how to read every request and response

Do not study this section until you can redraw §3.0 and place every API on its SAP functional rail. Contract purity, idempotency and authorization protect a known process; they are not substitutes for understanding that process.

### 5.1 Request fields fall into four buckets

| Bucket | Examples | What to understand |
|---|---|---|
| Technical envelope | `RequestId`, `SourceSystem` | Integration control; not entered by the depot user |
| Authenticated/audit identity | `RequestedBy` | Normally derived from the signed-in principal |
| Business reference | Sales order, STO PO, DI, billing document, E-Way Bill | Identifies the SAP object already in existence |
| Business delta/choice | Delivery quantity, new DI quantity, receipt allocation, reason, current vehicle/location | The actual change or choice the caller is asking SAP to accept |
| SAP-derived context | Material, plant, unit, organizational data, current status | Re-read from the authoritative SAP object; not blindly trusted because the screen displays it |

`RequestId` exists because a caller can time out after SAP has already committed. A retry must not create the same delivery, GR or statutory action twice. It is a technical control, not business master data.

### 5.2 A response must answer four things

1. Was the request accepted or rejected?
2. What authoritative SAP/government key or current state resulted?
3. What stable code/message explains a rejection or warning?
4. What should the caller display or refresh next?

### 5.3 Displayed does not mean requested

A screen may show customer, product, plant, quantity, driver, invoice, DI and E-Way Bill context together. That does not prove all those fields belong in a command request. The request should carry the authoritative reference plus the smallest caller-controlled delta. SAP should derive and revalidate the rest (`SRC-FIG-20260811-02`, `SRC-FIG-20260811-06`, D-049/D-053).

---

## 6. Endpoint foundation cards

### API-01 — Check MIGO / Pending Receipt

**Business trigger:** the receiving depot needs to know what goods remain receivable.

**Existing state:** an outbound delivery/dispatch exists and some or all quantity is still pending receipt.

**Caller supplies:** filters or a work-position reference sufficient to retrieve the current receivable state. The final stable business key is still unresolved.

**SAP/data job:** assemble the pending receipt position. Verified source logic calculates pending quantity from dispatched/invoiced quantity less already received quantity per delivery (`SRC-CODE-20260804-01`, D-021).

**Returns:** current receipt context, received-to-date, pending quantity and state needed to open the MIGO action.

**Changes SAP?** No. It is a read and creates no reservation.

**Main danger:** teaching stale screen data as posting authority. API-02 must re-read live state before committing.

**Owner sentence:**

> API-01 tells the depot what is currently receivable; it never proves that the same quantity will still be postable a moment later.

---

### API-02 — Submit MIGO / Post Goods Receipt

**Business trigger:** goods have physically arrived and the depot confirms the current receipt quantity/classification.

**Existing state:** a valid pending receipt position against an existing delivery/transfer.

**Caller supplies:** the authoritative receipt/delivery reference, posting context and **only the current allocation/classification delta**, plus the technical request ID.

**SAP job:** lock/re-read the live state, validate quantity and permitted receiving destinations, then post GR for accepted quantity.

**Returns:** authoritative material-document number, material-document year, posted quantity and refreshed partial/complete state. The UI's “MRN Document Number” wording does not yet replace the SAP key (`SRC-FIG-20260811-08`, C-14).

**Changes SAP?** Yes. This changes inventory and creates a material document.

**Validated quantity rules:** the current handled total is positive, uses the screen's 0.05-MT increment and cannot exceed displayed pending quantity (`SRC-FIG-20260811-08`, D-054).

**Main danger:** duplicate GR, stale pending quantity, wrong receiving location, or incorrectly mixing rejected quantity with GR-posted stock.

**Do not memorize yet:** the final DMG/STG SAP treatment. Direct clarification and the later BRD treatment conflict; keep this as an explicit MM/functional validation point.

**Owner sentence:**

> API-02 turns a physical receipt decision into an authoritative SAP goods movement and must return the material document plus year.

---

### API-03 — Create DI

**Business trigger:** the user chooses to fulfil some or all of an open predecessor quantity.

**Existing state:** a valid sales order for Trade/Non-trade or a valid stock-transport PO for STO.

**Caller supplies:** `PredecessorDocument`, route-fixed `PredecessorType` when needed, `DeliveryQuantity` and the technical envelope.

**SAP derives:** material, unit, plant, organizational context, current open quantity, blocks and status.

**SAP job:** revalidate the predecessor and create the SAP outbound delivery.

**Returns:** authoritative DI/outbound-delivery number and accepted quantity/status.

**Changes SAP?** Yes. It creates the outbound delivery.

**Validated rules:** quantity must be positive, must not exceed live pending quantity, may be partial and is blocked for an ineligible/credit-blocked predecessor (`SRC-FIG-20260811-02`, D-049).

**Main danger:** duplicate delivery, wrong predecessor type, stale open quantity or trusting copied screen context instead of SAP.

**Owner sentence:**

> API-03 takes an existing SO or STO PO plus the requested delivery quantity and returns the SAP outbound delivery—the DI.

---

### API-04 — Stock Availability

**Business trigger:** the physical-inventory/system-stock screen needs the live SAP stock population for a depot.

**Caller supplies:** Plant is mandatory; Material and Storage Location are optional filters.

**SAP/data job:** read live stock at product/material × storage-location grain.

**Returns:** material/product, storage location, system quantity and unit. Stock-age information belongs only if its source and grain are validated.

**Changes SAP?** No.

**It does not:** take a DI, allocate batches, authorize PGI, or post a physical-inventory difference (`SRC-FIG-20260811-05`, `SRC-SID-20260811-04`, D-051).

**Main danger:** returning the wrong stock category or teaching a stale/aggregate quantity as transactionally available stock.

**Owner sentence:**

> API-04 is a plant-scoped system-stock read for physical inventory; it has no DI context and performs no posting.

---

### API-05 — Shipment Cost Estimate

**Business trigger:** a DI is being prepared for dispatch and the user needs the calculated freight before proceeding.

**Existing state:** an open DI plus sufficient transporter/shipment context.

**Caller supplies:** the DI/reference and the business inputs that genuinely affect the estimate, such as transporter and route/shipment context once finalized.

**SAP job:** calculate or retrieve the applicable shipment-cost estimate without creating the final transport/accounting document.

**Returns:** estimated freight, currency/unit, calculation status and explanatory messages.

**Changes SAP?** Foundation assumption: no permanent business posting; it is a calculation/read boundary. Exact SAP calculation owner and rate source remain open.

**Main danger:** presenting a number that does not match the actual configured freight basis.

**Owner sentence:**

> API-05 answers “what should this shipment cost under the configured rules?” before final dispatch processing.

---

### API-06 — Create Invoice / Generate Billing Documents journey

**Business trigger:** the user has a prepared DI, fulfilment allocation and shipment context and submits the downstream dispatch/billing journey.

**Stable business foundation:** the validated product flow relates storage location/SPI, FIFO batch allocation, transporter, LR/GR, vehicle/driver, shipment cost, PGI, shipment, billing, e-Invoice and E-Way Bill (`SRC-FIG-20260811-03`, `SRC-FIG-20260811-04`, D-049).

**Caller supplies at business level:** the DI reference and the caller-controlled fulfilment/transport details established by the flow. SAP must revalidate live stock, batch eligibility and document state.

**Returns at business level:** authoritative created-document references and per-stage status such as Generated, Processing or Not Generated.

**Changes SAP?** Yes. The journey contains document-creating and stock-changing stages.

**Main danger:** assuming that one user button, one business label and one technical transaction are the same thing.

**Deliberate stop point:** do not currently learn how many internal endpoints, services, calls, LUWs or BAPIs implement this journey. That is the deferred fork. The only correct answer today is:

> API-06 is the current business-facing Create Invoice/Generate Billing Documents boundary. It sits after DI preparation and exposes the downstream document outcome. Its internal operation split is deliberately not frozen in this foundation phase.

---

### API-07 — Invoice Correction

**Business trigger:** an existing generated or errored invoice/e-document record needs permitted transport-related details corrected.

**Existing state:** an authoritative billing/invoice reference and existing e-Invoice/E-Way Bill status.

**Caller supplies:** the billing reference and only the approved editable correction delta.

**SAP/statutory job:** validate eligibility, apply the permitted correction through the existing invoice/e-document integration path and preserve independent e-Invoice/E-Way Bill outcomes.

**Returns:** corrected values, result messages and refreshed e-Invoice/E-Way Bill status/references.

**Changes SAP/external state?** Yes.

**Field discipline:** invoice, DI, product, customer and document identifiers are primarily context. The BRD identifies Distance, Vehicle Type and Vehicle Number as editable while transporter identity and transport mode are auto-populated/non-editable; final contract reconciliation remains required (`SRC-FIG-20260811-07`, D-053; Operation Evidence Matrix §2.2).

**It is not:** a generic price, quantity or accounting correction API; and it does not justify a standalone E-Invoice Correction endpoint.

**Owner sentence:**

> API-07 changes only the permitted transport/e-document delta for an existing invoice context and must return the independent statutory outcomes.

---

### API-08 — E-Way Bill Extension

**Business trigger:** an existing E-Way Bill is approaching expiry and the consignment cannot complete its journey in time.

**Existing state:** an active, eligible E-Way Bill.

**Caller business inputs:** E-Way Bill number, current/replacement vehicle number, From Place, From State, Pincode, extension reason and mandatory remarks.

**Integration-derived/validated context:** transport mode, remaining-distance/provider fields, consignment status, eligible caller identity and existing Part-B/LR-GR context.

**External/SAP job:** validate the eligibility window and submit the extension through the existing statutory integration.

**Returns:** E-Way Bill number, authoritative `UpdatedValidUpto`, retained vehicle/result context and provider message/code as needed.

**Confirmed timing rule:** eligible only during the eight hours immediately before expiry; never after expiry in this project. Success adds exactly 24 hours. The caller does not send `ExtensionHours` (`SRC-SID-20260812-01`).

**Main danger:** retrying an external command without correlation, requesting outside the window, or making provider-only fields into user-entered fields.

**Owner sentence:**

> API-08 extends one eligible existing E-Way Bill during its final eight pre-expiry hours and returns the government/provider-authoritative new validity.

---

### API-09 — Modify DI

**Business trigger:** the user needs to change an already-created DI quantity before fulfilment allocation/batch determination.

**Existing state:** an open, change-eligible SAP outbound delivery.

**Caller supplies:** DI/outbound-delivery number, new delivery quantity and the technical envelope.

**SAP derives and validates:** current DI status, predecessor/open quantity, locks, allowed quantity and whether later processing already blocks the change.

**SAP job:** change the delivery quantity.

**Returns:** authoritative DI number, accepted quantity, current status and next-step/result message.

**Changes SAP?** Yes.

**It does not prove:** how SAP internally clears or resets batch state. The product routes back to batch determination; the internal reset mechanism remains unverified (`SRC-FIG-20260811-03`).

**Main danger:** changing a delivery after picking/batch/PGI-relevant processing has already begun or overwriting a concurrent change.

**Owner sentence:**

> API-09 changes only the quantity of an eligible open DI and returns SAP's accepted quantity/state.

---

### API-11 — Create STO Purchase Order (candidate)

**Business trigger:** the STO/intra-warehouse journey needs its internal-transfer predecessor created.

**Caller business inputs shown by the validated design:** source plant, receiving plant, company code, shipping type, purchasing group, product, PO quantity, delivery date, requisition number and requisitioner.

**SAP job if approved:** create the stock-transport purchase order.

**Returns:** authoritative SAP purchase-order number, which becomes API-03's `STO_PO` predecessor.

**Changes SAP?** Yes.

**Applies to:** STO/intra-warehouse only. Trade and Non-trade start from sales orders and never call it (`SRC-SID-20260812-02`, `SRC-FIG-20260812-01`).

**Status:** the business action is strongly supported; the SAP API remains a candidate until MM/architecture confirms ownership, document configuration and implementation.

**Owner sentence:**

> Candidate API-11 creates the STO PO that begins the internal-transfer path; it is not part of customer sales fulfilment.

---

## 7. The ABAP relationship—only what you need now

At foundation level, every SAP-facing endpoint follows this reasoning pattern:

```text
Request arrives
  → identify the authoritative SAP object
  → read current state
  → validate business rules and authorization
  → for commands, prevent duplicate/concurrent execution
  → execute approved SAP logic
  → commit or roll back the current operation
  → return normalized result and authoritative key/state
```

Three truths to retain:

1. **A read may need no BAPI.** CDS/views/repository logic may be the correct implementation.
2. **A command should use approved SAP business logic.** Never learn “update the table” as an implementation strategy.
3. **A candidate BAPI name is not project truth.** The exact callable, signature, status checks and configuration must be validated in Shree's SAP system before you claim ownership of the implementation.

That is enough ABAP implementation knowledge for this phase.

---

## 8. What not to study from today's older responses

The following are superseded or deliberately quarantined:

- Do not learn API-09 as E-Way Bill Extension. The current working study number is API-08.
- Do not learn API-10 as Modify DI. The current working study number is API-09.
- Do not learn a standalone API-10 Valid Storage Locations contract. It was removed; only the unresolved supporting data need remains (`SRC-SID-20260812-04`).
- Do not restore standalone E-Invoice Correction or a duplicate Inventory Reconciliation read.
- Do not learn the API-06 service/endpoint decomposition yet.
- Do not memorize predictive BAPI/table/class mappings as fact.
- Do not memorize a final DMG/STG posting design while higher-tier evidence conflicts.
- Do not assume every field visible on a Figma/BRD screen belongs in a request.

---

## 9. The study order

### Phase A — functional floor

Use this order because each step supplies SAP process concepts required by the next:

1. **Document vocabulary:** SO, STO PO, DI/outbound delivery, PGI, GR, material document, billing document, e-Invoice, E-Way Bill.
2. **Redraw §3.0:** learn the outbound, inbound and inventory-visibility rails.
3. **API-03 and API-09:** learn creation versus change of the same DI object inside the outbound process.
4. **API-01 and API-02:** learn observe-current-receipt versus post an irreversible GR inside the inbound process.
5. **API-04 and API-05:** learn business reads/calculations that touch the process without posting a document.
6. **Candidate API-11:** learn how the STO predecessor enters the same outbound rail.
7. **API-07 and API-08:** learn later actions against already-existing billing/statutory outcomes.
8. **API-06 foundation card:** learn the stable downstream business boundary only, then stop.

For every step, first answer: **where am I in SAP's functional process, what document exists, and what document/state exists next?**

### Phase B — API protection layer

Only after Phase A is automatic, study:

1. business reference versus caller delta versus SAP-derived context;
2. response identity and messages;
3. idempotency/retry behavior;
4. stale-state and concurrency handling;
5. authorization and audit identity;
6. normalized error contracts.

Do not open the predictive implementation map during Phase A.

### The 40-minute flow-state loop

Use one endpoint per round. No browsing across ten files.

1. **Blank-page reconstruction — 5 minutes**  
   Write the state-before + delta = state-after equation from memory.

2. **Focused study — 10 minutes**  
   Read only that endpoint card. Circle the business reference, the caller delta and the authoritative result.

3. **Closed-book narration — 5 minutes**  
   Explain it aloud using the eight-line ownership format in §11.

4. **Functional disturbance — 10 minutes**  
   Ask: What prerequisite document is missing? What if the delivery is no longer open? Does this step belong to source dispatch or destination receipt? Which SAP object should exist afterward?

5. **Contrast — 5 minutes**  
   Explain why this endpoint is not its nearest look-alike: API-01 versus API-02, API-03 versus API-09, API-04 versus fulfilment stock validation, API-07 versus API-08.

6. **One-line compression — 5 minutes**  
   Write the owner sentence without looking. If it is vague, repeat the round.

Stop after two strong rounds. Flow comes from a narrow objective and immediate feedback, not from reading until your attention decays.

After you pass the functional round, run a shorter secondary round for request/response shape, retries, authorization and errors. Do not let secondary mechanics interrupt the first process reconstruction.

### Mastery gates

| Gate | You can do this | Pass condition |
|---|---|---|
| 1 — Vocabulary | Name the SAP objects correctly | No confusion between DI, PGI, GR, billing, e-Invoice and E-Way Bill |
| 2 — Causality | Draw predecessor → operation → result | Correct for all three business flows |
| 3 — API placement | Place each endpoint on the correct SAP functional seam | No read/post, source/destination or predecessor/result confusion |
| 4 — Contract | Separate reference, delta, derived context and response | No screen-to-JSON copying |
| 5 — Protection | Explain retry, authorization, stale-state and duplicate risk | At least one concrete safeguard per command |
| 6 — Ownership | Defend what is known and explicitly stop at what is open | No invented BAPI, service or API-06 decomposition |

You do not advance because you read the section. You advance because you pass the gate without notes.

---

## 10. Explain-back examination

Answer these without the document. Any hesitation identifies the next study target.

### Process floor

1. What is the difference between a sales order, STO PO and DI?
2. Why are DI and outbound delivery one object in this project?
3. What does PGI do, and what does GR do?
4. Why is destination GR later and separate even when it appears in one Document Flow?
5. What is the current higher-tier meaning of Pending MRN?

### Contract floor

6. Why is a displayed customer/material/plant value not automatically a request field?
7. What is the difference between a business reference and a business delta?
8. Why does a command need `RequestId` when the user never enters it?
9. What four things must every response make clear?
10. Why must API-02 return material-document number and year?

### Endpoint floor

11. Why is API-04 not a DI/batch-allocation API?
12. What one caller-controlled value is central to API-03?
13. When is API-09 allowed to change a DI?
14. Why is API-05 a calculation rather than a posting?
15. What exact timing rule governs API-08?
16. Why is API-11 never used for Trade or Non-trade?
17. Why is there no API-10 card in this study guide?
18. What can you safely say about API-06 today—and where must you stop?

### Stakes floor

19. Which endpoint can incorrectly increase receiving stock?
20. Which endpoint can duplicate an outbound delivery?
21. Which endpoints interact with statutory-document state?
22. Which reads must never be treated as reservations or posting authority?

### Functional collision challenges — primary

Do these first. Do not answer with BAPI, HTTP or SEGW terminology.

1. A Trade sales order has 30 MT open. The user wants a 25-MT DI. Which SAP object exists before the call, which API crosses the seam, what exists afterward, and what remains open?
2. That 25-MT DI now needs to become 20 MT before batch determination. Why is API-09 correct and API-03 wrong?
3. An STO request exists only as a portal intention; no stock-transport PO exists in SAP. What must happen before API-03 can create the DI?
4. The source plant has posted PGI for an STO, but the truck has not reached the destination. Which side of the process is complete, which side is still pending, and why must API-02 not run yet?
5. API-04 shows 42.5 MT system stock, and an open DI needs 30 MT. Why does this not by itself prove that 30 MT is eligible for fulfilment?
6. An invoice exists and its E-Way Bill will expire in six hours. The truck is delayed. Is this API-07 or API-08, and which existing document anchors the call?
7. A truck arrives at the depot with less acceptable quantity than dispatched. Is this problem solved in the outbound API-06 boundary or the inbound API-01/API-02 process? Explain the state transition.
8. The STO Document Flow says invoice and E-Way Bill are generated while GR is still pending. Is the process inconsistent?

<details>
<summary>Functional answer key — open only after drawing the rails</summary>

1. The sales order/open quantity exists. API-03 creates a 25-MT DI/SAP outbound delivery. Five MT remains open on the predecessor, subject to SAP's authoritative result.
2. The DI already exists. API-09 changes the existing delivery quantity. Calling API-03 would ask SAP to create another delivery and crosses the wrong functional seam.
3. Candidate API-11 must first create the STO PO. The returned PO then becomes API-03's STO predecessor.
4. Source-side issue/dispatch is complete to the proven stage; destination-side physical receipt is pending. API-02 belongs to the receiving event and cannot post goods that have not arrived.
5. API-04 is system-stock visibility, not DI-specific eligibility. Batch status, stock type, allocation, concurrent movements and other fulfilment rules still require transactional validation.
6. API-08. It acts on the existing E-Way Bill. API-07 is for permitted invoice/e-document transport-detail correction, not validity extension.
7. Inbound. API-01 exposes what is still receivable; API-02 posts the current accepted receipt delta and refreshes partial/pending state. API-06 belongs to source-side downstream dispatch/billing, not destination receipt.
8. No. The consolidated view spans source-side dispatch and later destination receipt. GR can legitimately remain pending until physical arrival.

</details>

### Contract and protection adversarial cases — secondary

Write your answer before opening the answer key.

1. API-03 times out, but SAP may already have created the DI. The portal retries with the same business data. What must prevent a second delivery?
2. API-01 displayed 30 MT pending. Two depot users open the same row. One posts 20 MT; the other then submits 20 MT. Why is the earlier read insufficient?
3. API-04 shows 42.5 MT at a storage location. Can the outbound flow treat all 42.5 MT as eligible for PGI? Why not?
4. A user changes a DI after batch/picking-relevant processing has begun. Should API-09 trust the portal's earlier “Open” status?
5. An E-Way Bill expires at 18:00. At 09:59 the user requests extension. At 10:01 they try again. Which time is potentially eligible, assuming all other rules pass?
6. Candidate API-11 returns a PO number. What does the next operation consume, and what new SAP document does it create?
7. The Invoice Correction screen displays customer, material and invoice amount. Should API-07 accept all three as editable request fields?
8. Submit MIGO returns only material-document number, without year. What is wrong with the result identity?
9. The UI has one Generate Invoice button. What are you allowed to claim about API-06 today?
10. GR is displayed after E-Way Bill in the STO Document Flow. Why does that not make GR an outbound sub-step?

<details>
<summary>Contract/protection answer key — open only after writing</summary>

1. The same `RequestId`/idempotency record must return the original result or expose the already-created delivery; blindly repeating the create is unsafe.
2. API-02 must lock and re-read current pending quantity. API-01 was a read, not a reservation. The second 20-MT request may now exceed the remaining 10 MT.
3. No. API-04 exposes system-stock visibility at its own grain. Transactional eligibility may exclude stock because of batch status, stock type, allocation, concurrent movement or other SAP rules.
4. No. SAP must re-read the delivery's current state under the command's validation/lock boundary and reject an ineligible change.
5. 10:01 is inside the final eight hours; 09:59 is one minute too early. Eligibility still depends on the E-Way Bill being otherwise valid.
6. API-03 consumes the PO as `PredecessorDocument` with STO context and creates the DI/SAP outbound delivery.
7. No. They are context. API-07 accepts only the approved correction delta against the authoritative billing/e-document reference.
8. SAP material-document identity includes the material-document year. The number alone is not the complete authoritative key.
9. It is the current business-facing Create Invoice/Generate Billing Documents boundary after DI preparation, with downstream document outcomes. Its internal endpoint/service/LUW split is deliberately not frozen in this phase.
10. GR occurs at the receiving side after physical arrival. One consolidated status view does not merge source-side dispatch and destination-side receipt into one transaction.

</details>

---

## 11. The ownership standard

For each endpoint, write and speak a 30-second answer in this exact format:

```text
It starts when ...
The existing SAP object is ...
The caller genuinely chooses/sends ...
SAP derives and validates ...
SAP reads/creates/changes ...
Success returns ...
The dangerous failure is ...
The main unresolved point is ...
```

Your foundation is complete only when you can produce those eight lines for every study card without referring to the workbook and without inventing an implementation detail.
