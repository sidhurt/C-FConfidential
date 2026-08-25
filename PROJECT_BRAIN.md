# Project Brain

The mental model. For current state, open questions and register navigation, read `HANDOVER_AI.md` — this file is how to *think* about the project, not a status report.

**Last reconciled:** 2026-08-15

## One-sentence model

The C&F Agent Interface is a new operational portal over Shree Cement's existing SAP dispatch processes: a Spartacus storefront presents the journey, Commerce Cloud serves most reads, SAP Integration Suite moves messages, S/4HANA validates and creates the authoritative business documents, Datasphere supplies analytical and replicated data, and DigiGST handles statutory e-documents.

## Current standard-first position — 2026-08-15

The earlier custom-only model is retired. Read-only inspection of the unrestricted SEGW Open Project catalogue established **2,626 design-time projects**, while the separate Gateway catalogue contains **522 registered services**. Neither count means “callable integration APIs.” The full business-led screen retained 41 unique candidates; the Tier-A deep dives then separated released A2X contracts from internal Fiori/application services and semantic false positives.

| v1.7 operation | Current SAP position | Disposition before runtime testing |
|---|---|---|
| API-01 Submit MIGO | `API_MATERIAL_DOCUMENT` for the accepted GR posting; `MMIM_MATDOC` for read-back; receipt balance/status require a companion source | Primary + complementary, conditional on reference/movement mapping and activation |
| API-02 Create DI | `API_OUTBOUND_DELIVERY_SRV;v=2` from project `API_OUTBOUND_DELIVERY_0002` | Primary; registered LE_SHP alternatives rejected on operation shape |
| API-03 Create Invoice / Billing Documents | Outbound delivery v2 for pick/batch/PGI; registered `SD_CUSTOMER_INVOICES_CREATE` for billing creation; `API_BILLING_DOCUMENT` for read-back; CPI/T2 owns process state | Conditional composition, not one atomic SAP API |
| API-04 Shipment Calculation | No credible SEGW integration service found; `BAPI_SHIPMENT_COST_ESTIMATE` is the fallback evidence to validate | Proven SEGW gap; thin SAP endpoint may be required |
| API-05 Stock Availability | `API_MATERIAL_STOCK` at material × plant × storage location, with batch/stock-type dimensions | Primary; stock category needs MM confirmation |
| API-06 E-Way Bill Extension | Existing DigiGST/EY/eDocument plumbing is outside the generic SEGW catalogue | Existing statutory route to identify and prove; do not create a parallel service blindly |
| API-07 Invoice Correction | Existing DigiGST/EY/eDocument correction/cancel/regenerate path is outside the credible SEGW candidates | Existing statutory route or thin command gap; exact object/BAdI/FM still required |
| API-08 STO Orders | `API_PURCHASEORDER_PROCESS` | Primary, conditional on STO document type/item category and activation |
| API-09 STO Deliveries | `API_OUTBOUND_DELIVERY_SRV;v=2` | Leading candidate; exact v1.7 read/delta proof still required |
| API-10 STO Invoice | `API_BILLING_DOCUMENT` only if the business object is SD billing | Conditional on SD-vs-MM/GST document decision |
| API-11 Create STO PO | `API_PURCHASEORDER_PROCESS` | Primary; `ShippingType` has no PO field and must move, derive or be removed |
| API-12 Update DI Quantity | `API_OUTBOUND_DELIVERY_SRV;v=2` item update | Leading candidate; writable-field, ETag and open-status behavior require runtime proof |

This is a **design-time solution map**, not a callability claim. The next evidence ladder is registration/ICF/alias → local `$metadata` → safe reads → authorised DEV writes → SAP document validation and log capture.

## The two user journeys and the operational spine

The 10 August KT frames the current portal work as two top-level user journeys (`SRC-MTG-20260810-02 @10:03–10:22`, Tier 4):

1. **Inbound receipt:** a plant/depot movement appears as a Pending MRN work item from the DSP/T2 read model; the user allocates received quantity to storage locations and submits MIGO to S/4; completion later returns to the read model.
2. **Outbound order fulfilment:** trade/non-trade demand is read from T1; the user creates the DI in S/4, selects stock/batches and shipment inputs, and advances billing/e-document processing; the portal continues to read orders, deliveries and invoices from T1.

The meeting's working sequence is MIGO and trade/non-trade fulfilment first, with STO creation deferred. This is delivery sequencing, not a signed scope decision (Q-006/Q-031).

The outbound spine is:

```text
Sales Order / STO
  → Delivery ("DI")                    the central operational object
  → one storage location → 1..n batches
  → transporter · route · freight
  → PGI · shipment · shipment cost · billing
  → e-Invoice (IRN) · E-Way Bill
  → document status · download
  → correction · extension
```

Adjacent journeys: warehouse-to-warehouse STO creation, physical inventory reconciliation, reports and dashboard/notification surfaces.

**Everything the SAP team builds hangs off one of these two read/write journeys.** When a requirement arrives, first identify the business station, then whether the portal reads replicated/display data or commands authoritative SAP state.

## The central thesis

> **A BAPI will not repair a semantically wrong payload.**

This is the most important sentence in the repository and it has survived every piece of evidence since.

The failure mode this guards against is specific: a technically correct API call, with correct syntax and a valid signature, carrying a business value that means the wrong thing. It posts successfully. Nothing errors. The defect surfaces weeks later in production, as wrong stock in the wrong place or an invoice a customer disputes.

Client senior stakeholders raised exactly this in the 28 July walkthrough, pushing back on the work being scoped as "field mapping and BAPI posting". They were right.

**What has changed since:** the KDS catalogue (`sources/`) substantially closes the reference-data gap — material groups, customer groups, storage locations, special procurement indicators and org structure. The process/field-lineage gap is not closed: the 10 August KT requires every screen attribute to be traced through the BRD/Figma and introduces C-14 on the core MIGO response term. The team is no longer blind to codes, but payload semantics still require owner-confirmed lineage.

## How to think about the four systems

Not "SAP plus some other things". Four systems that each genuinely own something:

| System | Owns | Do not ask it for |
|---|---|---|
| **S/4HANA** | Creating and posting business documents. Business validity, locking, document numbers, duplicate prevention | Portal display data. Under Option C most reads are served elsewhere |
| **Commerce Cloud** | The user journey; portal masters (depot, geography, material alias, Incoterms, storage location); and — under Option C — serving orders, deliveries and invoices live from T1 | Business validity. Commerce must never decide what SAP will accept |
| **↳ T1 (Terminal 1)** | The existing **Udaan** Hybris instance: order booking and aggregation between clients, customers and supply-chain logisticians. Already writes into S/4 (`ZCRM_SO_REJECT`) and pulls progression (`ZCRM_STAGEGATE`) | — |
| **↳ T2 (Terminal 2)** | The CNF portal being built: aggregates from T1, applies sourcing logic, lands orders in S/4, and **persists recurring data from SAP, DSP and T1** | — |
| **Datasphere** | Analytical, consolidated and replicated data — MRN, STO list, stock ageing, vehicle and transporter masters | Transactional decisions. A batch allocation cannot be made from a 15-minute-old snapshot |
| **Integration Suite (CPI)** | Message movement, routing, transformation, transport retry, correlation | Business rules. CPI must not become the hidden home of SAP logic |

The recurring mistake to guard against: **conflating "created in" with "read from".** S/4 creates the delivery; the portal reads it from Commerce T1. Both statements are true and they imply different work.

The 10 August walkthroughs sharpen that distinction (`SRC-MTG-20260810-01`, `SRC-MTG-20260810-02`):

- Submit MIGO and Create DI are intended to return an authoritative SAP identifier immediately; they do not wait for a read-model round trip.
- Pending MRN is intended to display from DSP/T2, while trade/non-trade orders, deliveries and invoices display from T1.
- A later T1/DSP projection makes the command visible in lists. The full-document S/4→T1 interface is described in the meeting as an existing SAP→CPI→T1 trigger, but it is not yet named or system-observed (Q-037).
- Dashboard/ageing stock is display data and can be stale; live stock/batch validation must stop an invalid fulfilment transaction (Q-014/Q-038).

## Who owns what

Siddharth's lane, and the boundary to defend when work drifts across it.

| Concern | Siddharth / ABAP | Someone else |
|---|---|---|
| SAP source selection, document execution | **Owns** | — |
| Released API / BAPI choice and validation | **Owns** | — |
| Standard API runtime proof; ABAP extension only for proven gaps | **Owns** | — |
| SAP locking/commit behavior; idempotency and correlation design | **Owns SAP part jointly** | **CPI/T2 owns the cross-call envelope unless architecture assigns otherwise** |
| API error contract and HTTP mapping | **Owns** (jointly with the integration architect) | — |
| Business rules, document semantics, acceptance | Implements | **SD/MM functional decides** |
| iFlows, routing, middleware retry | Supplies the contract | **CPI team** |
| Datasphere models, lineage, refresh | Supplies extraction views | **Datasphere team** |
| Landscape, roles, destinations, service activation, transports | Requests | **Basis/security** |
| Portal behaviour, Commerce data model, frontend validation | — | **Commerce** |
| User journey, BRD stewardship, business sign-off | — | **UI/UX and BA** |

**Explicitly not Siddharth's:** frontend implementation, iFlow construction, Datasphere modelling, Basis parameter or role changes, functional sign-off, production postings.

The rule: collaborate across every boundary, but do not silently accept ownership. Unassigned work at a boundary drifts to whoever is nearest, and that is usually the ABAP developer.

## The domains, and what the brain must answer for each

| Domain | Questions that must have answers before building |
|---|---|
| Order | Predecessor type (SO or STO), credit status, open quantity, source plant |
| Delivery (DI) | Creation API per predecessor, editable fields and cutoff, storage-location immutability |
| Stock | Unrestricted vs availability-check, batch grain, eligibility, allocation ranking |
| Batch | Determination ownership, FIFO rule, reset behaviour on quantity change |
| Freight | Route, rate, Incoterm treatment (FTP/FTB/EX), pre-document estimate feasibility |
| Shipment | Document model, where vehicle and driver belong, LR/GR mapping |
| PGI | Trigger, movement type, material document, reversal policy |
| Billing | Billing type, ODN vs billing document number, accounting consequence |
| E-documents | IRN lifecycle and cancellation window, E-Way Part A/B, extension ownership |
| Receipt | Reference model, partial receipt, MRN ownership |
| Master / KDS | Code meanings, derivations, system of record, valid combinations |

## What makes an interface implementation-ready

An API is ready to build only when the brain can answer all ten:

1. What business outcome is required?
2. Which SAP document or process represents it?
3. Which fields are input, derived, and output?
4. What does each code mean — and which system owns it?
5. Which released API, BAPI, query or existing custom object is correct?
6. What statuses and exceptions are valid?
7. What does the caller send, retry and correlate?
8. How does SAP prevent duplicates and log the request?
9. Is this a real-time SAP read, or is it served from Commerce or Datasphere?
10. How is success proven — in SAP, and downstream?

Question 9 is new, and it is the one Option C forces. Several things assumed to be SAP APIs are not.

## Evidence model

Every claim carries: source ID, confidence, owner, environment, and validation date. Confidence labels are in `README.md §Evidence standard`.

The discipline that makes this work: **every new document either confirms something, contradicts something, or opens a question.** Never merely "adds information". A document that changes no register has not been read properly.

Two rules learned the hard way:

- **Record conflicts rather than resolving them by preference.** C-8 (pickup code) and C-10 (sales org vs company code) are live because the sources genuinely disagree.
- **Remove superseded beliefs rather than annotating them.** Three assumptions in this project were confidently wrong — SPI as shipping point, brand/grade as classification characteristics, SAP Document Compliance as the statutory framework. They are gone from the current documents, not footnoted, so nobody reasons from them again.

## The standing risk

The project's original risk was semantic — a technical team mapping fields whose meaning nobody knew. The KDS/reference-data part is largely mitigated; process and field-lineage semantics are not, as C-14 and the still-uningested BRD demonstrate.

The current risk is different: **unowned work at system boundaries.** Unassigned SAP-side work drifts to the ABAP developer by default, unnamed and unfunded.

The original instance — what moves deliveries and invoices S/4 → T1 — has narrowed but is not closed. System observation proves that `ZCRM_STAGEGATE_SRV` serves progression in a pull-shaped exchange. The 10 August KT separately describes an existing, trigger-shaped SAP→CPI→T1 projection for order/DI/invoice changes (`SRC-MTG-20260810-02 @20:45–21:18, @23:20–23:26`). These may be two different feeds. Q-037 now asks for their exact identities, payloads, owners, retry behavior and latency rather than whether anything exists.

Two other gaps remain genuinely SAP-side and outside the API-01..API-10 estimate:

- **Datasphere extraction views (Q-053).** Option C needs Pending MRN, STO List and Stock Ageing in DSP. No delta queues exist for them. The pattern is established and `zsd_mrn_pending_cds_opt` is ready to build on — but nobody is named.
- **ILMS (Q-054).** Stage-gate data lives in `ZLETILMS*`, owned by Logistics Execution, and the 4 August meeting could not agree whether CNF needs stage gates at all (C-13).

The countermeasure is unchanged: collaborate across every boundary, but name ownership out loud rather than absorbing it silently.

## Live conflicts

Recorded rather than resolved, per the evidence discipline.

| ID | Conflict | Sources |
|---|---|---|
| **C-11** | **T2 as persistent store vs Option C.** Siddharth states T2 holds recurring data from SAP, DSP and T1 (D-027). Option C (D-014) is *"direct T1 query + scheduled DSP sync"*; a Hybris-managed persistent store is **Option B**. The 4 Aug meeting contradicts itself within 35 minutes — "nothing is being stored locally in T2" (@00:12:08) then "store it locally" (@00:45:44) | `SRC-SID-20260804-01`, `SRC-ARCH-20260803-01`, `SRC-MTG-20260804-01` |
| **C-12** | **STO / MRN source and cadence conflict.** D-014 says both DSP→T2 every 15 min. The 4 Aug meeting says S4→T2 direct and DSP→T2 four minutes apart. The formal interface summary now separates them: STO orders/deliveries/invoices S4→T2 real-time, but MRN DSP→T2 batch every 30 min. No delta queue exists for Pending MRN or STO in QS4 (D-038) | `SRC-ARCH-20260803-01`, `SRC-MTG-20260804-01`, `SRC-ARCH-20260811-01`, `SRC-CPI-20260811-01`, `SRC-SYS-20260805-07` |
| **C-13** | **Stage-gate scope in CNF.** *"In the architecture of CNF, there is no such thing as a stage gate. CNF starts getting visibility after the invoice is issued"* (@01:06:09) — contradicted three minutes later by a description of stage gates that already occur today (@01:09:14), and by the existence of `ZCRM_STAGEGATE_SRV` itself | `SRC-MTG-20260804-01`, `SRC-SYS-20260805-05` |
| **C-14** | **MRN identity, expansion and lifecycle.** System-derived D-021 defines Pending MRN as the derived in-transit position (dispatched minus received) and the glossary expands MRN as Material Receipt Note. The first 10 Aug meeting gives two incompatible timings—plant creates it before MIGO, then a correction says MRN follows inward receipt and no separate Pending-MRN number exists. The second calls it Movement Reference Number, loosely equates it with MIGO, and expects Submit MIGO to return an MRN number. Keep D-021 as the higher-tier current model; confirm the UI label, posting reference and returned SAP key under Q-004 | `SRC-CODE-20260804-01`, `SRC-MTG-20260810-01 @04:10–06:04`, `SRC-MTG-20260810-02 @10:52–14:47, @27:30–27:43` |
| **C-15** | **API-01's scope.** The drafted request/response workbook specifies API-01 as a SAP read returning the full Pending-MRN column set. But the 10 Aug KT walks DSP → Hybris → front end, and both newly supplied formal documents put MRN on DSP→T2 batch rather than among the seven T2→S/4 APIs. SAP source code still proves the derivation exists. The remaining question is whether ABAP owns only the extraction view/logic, a real-time validation read, both, or neither. **Do not build API-01 until this is settled** | `deliverables/CNF_API_Request_Response_Specification.xlsx`, `SRC-MTG-20260810-02 @13:30–13:54`, `SRC-ARCH-20260811-01`, `SRC-CPI-20260811-01`, `SRC-CODE-20260804-01` |
| **C-16** | **Seven formal commands vs the current 12-slot v1.7 model.** The formal manager/team documents enumerate seven T2→S/4 operations, now mapped cleanly to v1.7 API-01..API-07. v1.7 additionally carries three S/4→T2 STO feeds (API-08..10) and two candidate commands (API-11 Create STO PO, API-12 Update DI Quantity). The technical model is clear; approval and ownership of those five additions remain open under Q-063 | `SRC-ARCH-20260811-01`, `SRC-CPI-20260811-01`, `SRC-DOC-20260815-01` |
| **C-17** | **Pending Order direction differs inside the formal documentation.** The architecture diagram labels Pending Order under T1→T2. The interface-summary screenshot row 11 says T2→T1 Pending Order. This may be data direction versus caller/request direction, but the documents do not define that convention. Confirm provider, consumer and OCC endpoint before freezing the cross-system contract | `SRC-ARCH-20260811-01`, `SRC-CPI-20260811-01` |

## Design artifacts as evidence

`SRC-FIG-20260810-01` (the Figma file) is now an ingested source and the richest description of intended behaviour the project has. It sits at **tier 2 — client-produced artifact — never tier 1.** Three rules for reading it:

- **It states intent, not SAP capability.** The 3 August record has the UI designer stating they do not know the product semantics (Q-027). Where a screen and the system disagree, the system wins and the difference is logged as a conflict.
- **The Order Fulfilment page carries a "Discarded Iterations" section.** Those are rejected designs. Reading them yields requirements that were thrown away.
- **Screens answer "what does the portal need", not "where does the data come from."** A column on a screen says nothing about whether it is served by S/4, T1 or Datasphere — which is exactly how C-15 arose.

Its highest-value contribution so far is field-level: the MIGO allocation model (D-039), the quantity triple that answers Q-048 (D-041), the reconciliation model (D-042), and confirmation that Edit DI is real scope rather than a proposal (D-040).

## Previously observed registered CNF-adjacent surface — six services (QS4, 2026-08-05)

Sources: `SRC-SYS-20260805-03/-04/-05` (selected SEGW projects, Gateway registrations, expanded model trees), captured from QS4 client 700. All six are registered `BEP`, routing-based, active `ODATA` ICF node, system alias `LOCAL`. All five custom projects originate in DS4 and are authored by the IBM ABAP pool (`IBMABAP05/07/16/34`) — the same pool that maintains the Z-reports. Four touch the CNF domain and remain useful evidence of client patterns. They are **not** the complete SEGW catalogue; the unrestricted Open Project export later established 2,626 design-time projects.

| Service | Direction (inferred) | Model | What it establishes |
|---|---|---|---|
| `ZCRM_STAGEGATE_SRV` | S/4 **serves** order-progression data; CRM/T1 side pulls | `STAGEGATE` (6-field key: `Erporderid`, `Crmordrcode`, `Dinumber`, `Deliverylinenumber`, `Erplineitemid`, `Entrynumber`) → nav → `deliveriesItems` (32 fields) | **"Stage gate" is now a concrete data structure, not meeting vocabulary** — see below |
| `ZCRM_SO_REJECT_SRV` | CRM/T1 **writes into** S/4 | `ISSOREJECT`: `Vbeln`, `Posnr`, `Abgru`, `Msg` | An existing T1→S/4 write API: order-item rejection (`VBAP-ABGRU`). Precedent for every CNF write API |
| `ZCUSTOMER_DETAIL_SRV` | S/4 serves; **CPI is the consumer** (its own description says so) | `CUSTOMERMASTER`: CustomerNumber, PartyName, Mobileno, OrgId, Regio, CustomerFlag, EmailId, PanNo, CustomerGstNo, **LastUpdateDate**, Bahne | CPI confirmed in the landscape for master-data sync; `LastUpdateDate` implies a delta-pull pattern |
| `ZAPI_PLANT_WEIGHBRIDGE_RMC_SRV` | S/4 serves material master per plant (inferred) | `Rmc_data`: Werks, Matnr, Maktx, Bismt, Mtart, Matkl, Meins, Gewei, Lvorm, Mstae… | All 13 fields are **material-master attributes** — this is a material feed for the RMC weighbridge system, not weighbridge readings into SAP. RMC is a live, separately-integrated process |
| `ZMM_SCRUM_SER_PO_SRV` | External system ("SCRUM") creates service POs (inferred) | `poHeader` / `poItem`, `HeaderToItem` | Unrelated to CNF; properties not yet enumerated (tree not expanded that deep) |
| `API_SALES_ORDER_SRV` (project `API_SALES_ORDER`) | SAP-delivered A2X | SADL/CDS exposure; function imports `rejectApprovalRequest` / `releaseApprovalRequest` | The one standard API registered — under Z technical name `ZAPI_SALES_ORDER_SRV`, consistent with the all-Z-copies Gateway catalogue |

### What `ZCRM_STAGEGATE` settles

The `deliveriesItems` entity carries, per delivery line item, the timestamps and values of the order's physical progression:

`OrderCreationDateAndTime` → `DiCreationDateAndTime` / `DiQuantity` → `TokenNumber` → `TruckAllocatedDate` / `TruckAllocatedQty` / `TruckNo` → `TruckDispatchedDateAndTime` → `InvoiceCreationDateAndTime` / `InvoiceNumber` / `InvoiceQuantity` → `InvoiceCancelDate` / `InvoiceCancelQuantity`

plus transporter identity (`CarrierId`, `TransporterName`, `TransporterPhoneNumber`, `ErpDriverNumber`) and dual correlation keys (`Erporderid` **and** `Crmordrcode`; also `IntegrationKey`, `ParentId`).

Consequences:

- **Stage gates are order→invoice progression checkpoints on the delivery line item.** The 4 Aug meeting's "truck allocation happens when I enter the truck number in DI" (@01:09:14) matches `TruckNo` → `TruckAllocatedDate` exactly. The feed **ends at invoice** — no PGI, shipment-cost, e-Way Bill or receipt fields — consistent with stage gates being a dispatch-visibility concept, not the full document chain.
- **"Token" is a real process object** (`TokenNumber`), corroborating `DELE_QTY`/`QTY_TOKEN` in the pending-order report. It sits between DI and truck allocation.
- **Q-037 is partially answered in shape**: a pull-shaped S/4→T1 path for delivery/invoice progression **already exists** — OData served from SAP, consumed by the CRM/T1 side. A later meeting also describes a trigger-shaped SAP→CPI→T1 projection for full order/DI/invoice changes. The feeds may coexist; their identities, consumers, payload coverage and latency must be observed before the model treats them as one path.
- **The dual-key correlation architecture is confirmed**: ERP and CRM order identifiers travel together, corroborating `CUSTOMER_REF` in the pending-order report.
- **Model smell to check before reuse**: near-duplicate properties differing only in casing (`Dinumber`/`DiNumber`, `Deliverylinenumber`/`DeliveryLineNumber`, `Erporderid`/`ErpOrderNumber`) — iterative patching; consumers may depend on either copy.

### What the implementation classes revealed (source read 2026-08-05)

Three `*_DPC_EXT` classes were read in full. This closed the "tree nodes ≠ implemented methods" caveat and produced the most consequential findings in the project so far.

**Generic CRUD nodes prove nothing.** `ZCRM_SO_REJECT` shows five operations in the SEGW tree and implements **two** — `CREATE_ENTITY` and `GET_ENTITY` (D-029). Never infer capability from the tree.

**An API-06-shaped orchestration already exists.** `ZMM_SCRUM_SER_PO` runs `BAPI_PO_CREATE1` → `BAPI_ENTRYSHEET_CREATE` → `BAPI_INCOMINGINVOICE_PARK` behind a single OData call, three documents across three commits, with process state persisted in Z-table `zmm_scrum_ser_po` (D-030). The sequencing is not the hard part and never was. What is absent is exactly what makes API-06 class **X**: no compensating rollback when a later stage fails after an earlier one committed, and the final invoice commits without checking whether it succeeded. **The client's own system demonstrates both that the pattern is achievable and why the estimate is what it is.**

**Nothing is idempotent.** No write API carries a caller request ID, duplicate check or replay guard (D-031). `ZCRM_SO_REJECT` is safe by accident — setting a rejection reason is a state-set. `BAPI_PO_CREATE1` is not: the same payload twice creates two purchase orders. **Create-DI, MIGO and invoice creation are all non-idempotent, so the existing pattern does not transfer to any CNF write.**

**`ZCRM_STAGEGATE` is a read wearing a POST.** It implements only `create_deep_entity` and writes nothing — POST is used because OData V2 `GET` cannot carry a compound key (D-032). This is the house pattern for class-C composite reads and applies directly to API-01 and API-04.

**Stage gates come from ILMS, not from SAP.** `ZLETILMSDELIVERY` / `ZLETILMSTOKEN` / `ZLETILMSTRANS` hold token, truck allocation, driver, vehicle and dispatch timestamps, with a `stageid` field (D-033). A fallback path reads `LIKP-ZZVEHICLE_NO` and `LIKP-ZZDRIVERMOB` directly — which also refines D-025: the vehicle Z-field exists on the **delivery header** as well as the shipment header (D-037).

**Cross-cutting concerns are systematically absent.** Four objects examined, four with no authorization check (D-036). Empty `CATCH` blocks, `SELECT` inside `LOOP`, hardcoded placeholder values (`ref_doc_no = 'Test'`, a literal user ID in `preq_name`) and dead code appear throughout. **This is not a quality complaint — it is the evidence that "wrap the existing pattern" and "not difficult" are different claims.** The skeleton (read payload → map to BAPI → call → check return → commit or roll back → return message) is sound and should be reused. The cross-cutting layer around it does not exist and is where the effort sits.

### What is still unverified on this surface

- ~~`E8H_000`~~ — **withdrawn 2026-08-05.** Routinely present in SEGW Service Maintenance and carries no significance (Siddharth, from prior workflows). The "hub Gateway" reading was inference and was wrong. Gateway embedded-vs-hub is still open, but under **Q-002**, where it always belonged.
- **QS4 versus PS4.** Every source-derived decision is read from QS4. Objects arrived by transport from DS4, but production import status is unconfirmed — **Q-052**. This affects line-level detail, not the structural findings.
- Direction/consumer for the weighbridge and SCRUM services is inferred from field shape and naming, not from configuration.
- `ZMM_SCRUM_SER_PO`'s `poHeader`/`poItem` properties were never enumerated (tree not expanded that deep), though the DPC_EXT read now supplies the working field set.
