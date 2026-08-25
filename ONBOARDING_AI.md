# Onboarding — For an AI Picking This Project Up

> **2026-08-15 current-state override:** retain this file for business-process understanding, not API implementation selection. The old custom-first assumptions are retired. Read `PROJECT_BRAIN.md`, `deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md`, and `sessions/2026-08-15-standard-api-discovery/TIER_A_DEEP_DIVE_FINDINGS.md` before making any SAP API claim.

**Written:** 2026-08-10 · **Audience:** an AI assistant with full read access to this repository, working with Siddharth over many sessions.

---

## 0. What this document is

`HANDOVER_AI.md` is the **state** document — what is currently known, versioned, maintained jointly with Codex. Read it second.

This document is the **understanding** document. It exists because three things are not in the registers:

1. **What the product actually is**, narrated end to end, including what the finished screens look like — I walked the Figma file in a browser and most of that picture never made it into a register.
2. **Siddharth's actual position** — his role, what he is accountable for, what he is being judged on, and where he is being stretched.
3. **The judgement** — traps already fallen into, corrections already made, and how to be useful here rather than merely correct.

Facts live in the registers. Read them for detail; read this for shape.

---

## 1. The project in one paragraph

Shree Cement sells cement through depots. At each depot sits a **C&F agent** — a carrying-and-forwarding agent, an employee who receives stock arriving from plants and dispatches it against customer orders. Today they do all of that **inside SAP GUI**. The C&F Agent Interface project takes that work out of SAP GUI and into a purpose-built web application. Nothing about the business changes. The documents are the same, the rules are the same, SAP remains the system of record. What changes is that a depot agent uses a browser instead of transaction codes.

**That framing is the single most useful thing to hold.** It means every screen maps to an existing SAP transaction, every field already exists somewhere, and the semantics were settled years ago by people who are still employed. Nobody is inventing a process. The project's risk is not novelty — it is *fidelity*.

---

## 2. The business, end to end

A depot agent has exactly two jobs. The 10 August KT states it plainly: *"I only have two tasks: one is to put the goods that are coming in, inside me, and the customer's orders, I have to fulfil them."*

### Job one — inbound receipt (the MIGO journey)

A plant in Rajasthan sends cement to a depot in Uttar Pradesh. That movement is an **STO** — a stock transfer order. Against it, an outbound delivery is created at the plant, goods are issued, and a truck or rail rake moves.

At the depot, the agent sees a **pending receipt** — 30 tonnes despatched, nothing received yet. They open it and do one thing: **allocate the arriving quantity across storage locations by condition.**

This is the part outsiders find surprising. A storage location here is not a shelf — it is a *condition bucket*:

| Code | Meaning |
|---|---|
| `GDF` | Fresh GD — good stock |
| `CUT` | Cut & Torn — damaged bags |
| `DMG` | Damage — rejected/non-stock; returns to replacement demand |
| `RDFR` | Fresh RD |
| `GDRK` | GDRK Sale |
| `RDSH` | Short RD |
| `RSD` | Siding Sale — sold from the rail siding |
| `STG` | **Shortage** — operational storage-location label, but rejected/non-stock |

The eight boxes classify the quantity handled in the attempt; they do **not** all become SAP stock. Accepted categories can be posted by MIGO. `STG` and `DMG` are rejected outcomes: no stock is stored under them, and their quantity contributes to pending replacement goods requiring a later Order → DI → MIGO cycle. Therefore `classified total` and `GR-posted total` diverge whenever damage or shortage exists.

Receipts can be **partial** — 12 tonnes now, 18 later. The list shows `Pending` / `Partial` / `Completed`.

### Job two — outbound fulfilment (the order journey)

A dealer places an order in **Udaan** — the existing customer-facing portal, called **T1**. The depot agent sees that order in their app, and:

1. **Creates a DI** — a delivery instruction, which is simply an SAP outbound delivery. One order can have many deliveries; **one order carries exactly one product**.
2. **Selects batches** — which physical stock fulfils it.
3. **Enters shipment details** — transporter, vehicle, driver, mobile, LR/GR number.
4. **Generates the invoice** — which triggers goods issue, shipment, shipment costing, billing, e-Invoice (IRN) and E-Way Bill.

There are three order types. **Trade** — sold through a dealer from the depot. **Non-trade** — large institutional buyers like L&T or Sobha buying direct from the company. **STO** — internal transfer, currently deferred from scope.

### What ties them together

Everything is one document chain, and SAP records it in `VBFA`:

```
Sales Order / STO → Outbound Delivery ("DI") → Goods Issue
   → Shipment → Shipment Cost → Billing → Accounting
   → e-Invoice (IRN) → E-Way Bill
```

When someone asks *"will document flow still work if the portal creates the delivery?"* — the answer is yes, because the portal doesn't create documents. It calls SAP, SAP creates them, and SAP writes `VBFA` exactly as it does from `VL01N`. This is worth saying confidently; it is the question business stakeholders ask first.

---

## 3. What the product actually looks like

I walked the Figma file (`SRC-FIG-20260810-01`) in a browser. This is the production picture the registers only partially capture.

**Shell.** Shree Cement / Bangur Cement branding. A **warehouse selector** top-right (`3778 UP BC DEORIA TR RSD`) — the agent's depot context for everything. Notification bell. User panel bottom-left showing name and a **SAP Code**.

**Navigation, which is effectively the scope statement:**

```
DASHBOARD        Overview
FUNCTIONALITY    MIGO · Order Fulfilment · Edit DI · Invoice Management
                 E-Way Bill Extension · Intra-Warehouse Movement
                 Inventory Reconciliation
VISIBILITY       MRN · Orders · Pending STO · Stock · Historical Billing
```

Seven things the agent *does*, five things they *look at*. No "Create STO" — consistent with STO being deferred.

**MIGO screen.** A paginated, sortable, filterable grid: DI Number · Invoice Number · Invoice Date · LR/GR · Product · **Ageing (Days)** (colour-coded amber/red) · Vehicle · Dispatch Qty (MT) · Inward Qty (MT) · Pending Qty (MT) · **Status** badge · Source Plant · Transporter Name · **Vehicle Tracking Link**. Clicking a row opens the allocation modal. On a Partial item, expandable **Inward Quantity** is prior history; **Allocate Pending Quantity** is the new classification delta. Values use non-negative 0.05-MT increments, at least one must be positive, and the handled total cannot exceed displayed pending. SAP must revalidate against live state. Within that delta, accepted categories can create GR stock lines; `DMG`/`STG` are rejected and do not increase inventory. The screen's “MRN Document Number” label still does not settle the SAP response identifier (C-14).

**Order Fulfilment.** Three tabs — **Pending · In Progress · Document Flow**. Filters include Inco Term and Distribution Channel. Columns: Order ID · Order Date · **Credit Blocked Status** · Product · Quantity (MT) · Pending Qty · Customer · Ship To.

**Edit DI.** DI Number · Order ID · Order Date · Product · **Order Qty 42.5 · DI Qty 30.5 · Pending Qty 12**. Those three numbers add up, which is how we confirmed the portal needs three quantities rather than the nine SAP tracks.

**Inventory Reconciliation.** Select warehouse → name the reconciler → walk product by product (`Next Product →`), entering **physical count in bags** which displays as MT. Variance shows against system quantity; a reason becomes mandatory when it isn't zero. An audit history lists every past count.

**Two operating details worth carrying:** every list is paginated and sortable, and every list has a free-text search. Contracts that ignore that produce APIs which return ten thousand rows.

---

## 4. The systems, and how they actually connect

| | What it is |
|---|---|
| **T1** | *Udaan* — the existing dealer portal. Terminal 1. Dealers place trade and non-trade orders here. Already integrated with SAP in both directions |
| **T2** | The new C&F app. Terminal 2. Same Hybris estate, Spartacus storefront |
| **CPI** | SAP Integration Suite. **Consumes the OData services we publish** and moves messages to T2 |
| **S/4HANA** | The system of record. On-premise, 2022. Three systems: DS4 dev, QS4 quality, PS4 production |
| **Datasphere** | Analytical replication — pending MRN, STO lists, stock ageing, masters |
| **DigiGST (EY)** | Statutory e-Invoice and E-Way Bill. Already wired, ~50 destinations exist |

**Command path:** T2 → CPI → SAP Gateway → our ABAP → SAP document.
**Read paths:** orders/deliveries/invoices from T1; pending MRN and ageing from Datasphere; live stock and batches from SAP.

The recurring confusion — and it recurs constantly — is **"created in" versus "read from."** S/4 creates the delivery. The portal reads it back from T1. Both true, different work.

---

## 5. Siddharth's role — be precise about this

He is the **SAP ABAP backend developer**. He builds and publishes the OData services SAP exposes. CPI consumes them.

**His deliverable is a URL and a contract.** Not a connection, not an iFlow, not a screen. He designs the service, models the entities, writes the logic, and hands over the endpoint plus its `$metadata`, error codes and idempotency semantics.

**He owns:** SAP source selection · released API/BAPI choice · ABAP classes and SEGW/RAP services · locking, commit policy, **idempotency**, correlation · the API error contract.

**He does not own:** business rules (SD/MM decide) · iFlows (CPI team) · Datasphere models · landscape, roles, service activation (Basis) · portal behaviour · functional sign-off · frontend anything.

**The standing risk, and the thing to protect him from:** unowned work at system boundaries drifts to whoever is nearest, and that is usually the ABAP developer. Three instances are live right now — the S/4→T1 push, the Datasphere extraction views, and ILMS ownership. When one surfaces, name the owner out loud. Do not let him absorb it silently, and do not let him be the one who quietly makes it work.

---

## 6. Siddharth himself — context for working well with him

He joined this project on **29 July 2026**. Everyone else has years on the domain. He is a capable ABAP developer being asked to hold his own in architecture rooms against people who have run Udaan for years — and he feels that gap acutely.

**What actually works for him:**

- **Evidence he gathered himself.** His strongest position all project has come from reading QS4 and the client's own ABAP source. In one day he produced nine verified findings while a 77-minute architecture meeting cited zero pieces of system evidence. That asymmetry is his entire leverage — protect it.
- **Short, usable outputs.** He has told me directly, more than once, that long documents defeat him. When he says *"keep it simpler"* or *"don't make a Mahabharata out of it"*, he means it. Give three sentences and a next action.
- **Being told which questions to ask.** He does not need to out-recall anyone on cement. He needs the one question in the room that nobody can answer.

**What does not work:**

- Walls of text. He will say so.
- Being told what he already decided. He owns the client relationship and the engagement judgement.
- Hedging. If something is verified, say so flatly. If it is inference, label it and move on.

**One boundary that held all project and should keep holding:** he has repeatedly asked for an agent to drive SAP GUI directly. The answer has been no — not because of capability, but because the Basis scripting approval he obtained was explicitly framed as *"my own session and login only, nothing remote or unattended."* Help him build scripts **he** runs. Do the analysis on what comes back. That division has been productive and is the reason his findings are defensible.

---

## 7. Where the work stands

**Done and solid:**

- Landscape verified from the system, not from documents — including that the vendor specification was wrong about the release and the landscape.
- The client's own ABAP read in depth: the pending-order report, the MRN report, and three `*_DPC_EXT` implementation classes.
- The complete OData surface enumerated — six SEGW services, **none of which implements any of the CNF APIs.**
- An API contract workbook, now at v1.3, twelve APIs, request and response, one sheet each.
- The Figma walked and its findings logged.

**The three findings that carry the most weight in a room:**

1. **Nothing is idempotent.** Neither existing write API has a duplicate guard. `ZCRM_SO_REJECT` survives only because setting a rejection reason is naturally idempotent; `BAPI_PO_CREATE1` will happily create two purchase orders from the same payload. Every CNF write is non-idempotent. The pattern does not transfer.
2. **An API-06-shaped orchestration already exists.** `ZMM_SCRUM_SER_PO` commits a PO, then a service entry sheet, then a parked invoice, behind one OData call — with no compensating rollback and a final commit that never checks success. The sequencing was never the hard part; recovery is.
3. **Nobody has measured the invoice chain.** Open since 3 August. Two traced documents gave 21 seconds and 3 days. Until it is measured, API-06's shape cannot be fixed.

**Blocked or unresolved:** the MRN identity conflict (C-14), API-01's true scope (C-15), the DI predecessor, SPI determination, what *Post* means for inventory reconciliation, and the sync-versus-poll decision.

---

## 8. Traps — mistakes already made here

Written so they are not repeated.

- **I over-scoped API-01.** I built its response from the MRN *report's* output structure, which is the dashboard. The KT walks that read as Datasphere → Hybris → front end, and the proposal already said MRN is not a SAP output. That is **C-15** and it is unresolved.
- **I asserted Intra-Warehouse Movement was not an STO.** It is. The senior says so explicitly. Corrected in D-045.
- **I accepted "plant and storage location are interchangeable."** They are not — warehouse/plant/depot are interchangeable, storage locations are children. Corrected in D-043.
- **I used "Cond." as a mandatory value** without saying conditional on *what*. A senior caught it within a day. Every mandatory field is now Yes, No, or the full condition spelled out.
- **I put `ErpOrderId` in the shared envelope**, where it was redundant with each API's own scope key. Also caught. Removed.
- **I claimed CPI was barely present** from one transcript's silence. The destination list disproved it.

The pattern in all six: **inferring from one source and stating it flatly.** The registers have a four-tier evidence hierarchy for exactly this reason. Use it.

Two more, structural:

- **Never read `_archive/`.** It is provenance. Reasoning from it reintroduces beliefs that were removed deliberately.
- **Codex writes these registers too.** Check `git status` before editing. Files have changed mid-edit more than once.

---

## 9. How to work here

**Evidence tiers, higher overrides lower:** (1) system observation from QS4 · (2) client documents · (3) direct statement from Siddharth, tagged `SRC-SID-*` · (4) meeting transcript — secondhand, ASR-noisy, speaker identity unknown.

Design artifacts like Figma sit at tier 2 and describe **intent, not SAP capability**. Where a screen and the system disagree, the system wins and it becomes a conflict.

**The discipline that makes this repository work:** every new source either confirms something, contradicts something, or opens a question. A source that changes no register has not been read properly. Conflicts get recorded as `C-nn` rather than resolved to the convenient reading. Superseded beliefs get **deleted**, not annotated — except in the explicit "known wrong" list.

Never promote one agent's inference into another agent's verified fact.

---

## 10. The study programme

He wants to run **study sessions** with you — structured learning, not just task execution. This is the syllabus. It is ordered by dependency, not by count: each block assumes the previous one landed, and a block takes as many sessions as it takes.

**How a study session should run.** Pick one topic. Ground it in something real from this project — a table he can query, a class he can read, a screen he can open — never abstract theory. Have him do the looking; you do the synthesis. End with one thing written into a register. Forty-five focused minutes beats three unfocused hours, and he has said so himself.

### Block A · Foundations

The two journeys, until he can narrate both without notes. The document chain and `VBFA` — have him trace one real trade order and one real STO in QS4 and draw the chain from memory. How the register system works and which ID lives where.

### Block B · The client's own code

`ZSD_PENDING_ORDER_REP_PP` and `ZLE_MRN_PENDING_REPORT` — the field catalogue *is* the API contract, and the defect history in the comments is business rules learned the hard way. Then the three `DPC_EXT` classes: what the house pattern is, and precisely what it lacks. Pull `ZSD_PENDING_ORDER_FM` — still the largest unread artifact in the project.

### Block C · One API at a time

For each: what the screen needs, what SAP provides, which BAPI does the work, what is derived versus supplied, and what is still open. Start with **API-02 and API-03** — the first two he will actually build.

### Block D · Integration ABAP as a discipline

This is the block that separates him from a report-writing ABAPer. Idempotency with a persisted request key. Error contracts mapped from `BAPIRET2` to stable codes. `ENQUEUE` and commit discipline. Released APIs versus BAPIs versus custom construction. RAP versus SEGW, until he has a recommendation he can defend. Authorization — `ZLE_PLNT` as a filter, not a gate.

### Block E · The landscape around him

How CPI consumes what he publishes. Cloud Connector, and why an ERP is never exposed directly. Datasphere extraction views — work likely to land on him. The statutory layer, and how much of API-08/09 already exists.

### Block F · Build

The first vertical slice in DEV: ABAP class → service → Gateway test → measured latency → evidence back into the registers. Then hand it to CPI with a real contract.

**The rule that holds across every block:** end each session with something written into a register — a verified finding or a sharpened question. Notes decay and convince nobody; a `D-0xx` with a source ID compounds and is citable in a room where he is outranked on domain knowledge. That is the mechanism by which he stops being the person who cannot answer and becomes the person whose questions nobody else can.

---

## 11. What to do next, ranked

1. **Measure the invoice chain** (Q-032). Highest-value single action available. It unblocks API-06's entire shape.
2. **Resolve C-15** — is API-01 a SAP read at all? Blocks a contract already in a manager's hands.
3. **Resolve C-14** — what does Submit MIGO actually return? Blocks current v1.7 API-01's response.
4. **Get the four A2X services activated in DEV** (Q-045). May remove several custom builds from scope.
5. **Settle SEGW versus RAP** (Q-046) before a single service is created.
6. **Name owners** for the Datasphere extraction views and ILMS before they default to him.
7. **Get Q-006 answered** — the first formally assigned interface with acceptance criteria. Still unanswered since 29 July. It is the only question that protects his scope rather than improving the design.

---

## 12. The one-line version

*A depot agent's SAP GUI work is moving into a browser; Siddharth builds the SAP-side OData services that CPI will call; the business logic already exists and the real risk is fidelity, idempotency, and work drifting across boundaries onto him.*
