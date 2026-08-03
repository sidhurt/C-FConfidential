# Handover — Complete Contextual Briefing for a Successor AI Agent

**Date:** 2026-07-30
**Author:** Claude (Sonnet 5 / Opus 5), this Claude Code session
**Audience:** Any AI agent (Claude, Codex, or other) entering this repository with no prior context
**Supersedes:** `_archive/HANDOVER_2026-07-28_AI.md` and `_archive/HANDOVER_2026-07-28_HUMAN.md` — those were day-2 snapshots whose substance is now folded into this document and the live registers. Do not read them as current; they are archived, not deleted, for provenance only.
**Status of this document:** Reconciliation and orientation. It is not a plan, not a decision record, and not authorization to touch any system. It exists so a fresh agent can become useful in one read instead of by excavating 40+ files and a long conversation history.

---

## 0. How to use this document

Read this after `AI_OPERATING_RULES.md` and before anything else. Then treat the live registers (`OPEN_QUESTIONS.md`, `DECISION_LOG.md`, `INTERFACE_REGISTER.md`, `DOMAIN_GLOSSARY.md`, `SYSTEM_OF_RECORD_MATRIX.md`) as the actual source of truth — this document reconciles and narrates them, it does not replace them. Where this document and a register disagree, the register wins; flag the conflict and update this file.

Every material claim below carries a confidence label per this repo's own standard: **Verified** (directly demonstrated), **Strong inference** (multiple independent signals), **Hypothesis** (plausible, unvalidated), **Contradicted** (evidence conflicts), **Unknown**. Read `README.md §Evidence standard` for the full rubric, and note one repo-specific rule established this session: **a fact Siddharth states directly in conversation is logged as Verified**, source-tagged `SRC-SID-YYYYMMDD-NN`, distinct from secondhand meeting reconstructions which keep their original confidence label.

---

## 1. What this project actually is

**One sentence.** The C&F Agent Interface is a new operational web portal for Shree Cement's Clearing & Forwarding depot agents, built on SAP Commerce Cloud (Spartacus storefront), orchestrated by SAP Integration Suite (CPI), backed by SAP S/4HANA as the transactional authority, with SAP Datasphere supplying analytical and some master-data reads.

**The business flow it digitises** (Strong inference from the 28 July 2026 design walkthrough, `meetings/2026-07-28-design-walkthrough.md`):

```text
Order → Delivery Instruction (DI) → storage location + batch determination
     → transporter/freight → shipment details (vehicle, driver, LR/GR)
     → { PGI · shipment · shipment cost · billing } → { e-Invoice/IRN · E-Way Bill }
     → document status/download → correction or 24h extension
```

**Client:** Shree Cement / Bangur. **Program name in the codebase:** `ZCNF_*` namespace, "CNF" = C&F. **Vendor engagement:** Siddharth plus one other ABAP developer form the SAP backend team, under a CPI consultant and Basis consultant, reporting into a broader multi-team program (SD/MM functional, Datasphere team, Commerce/Hybris team, UI/UX).

**Access state at time of writing:** No DEV access. No formal written assignment. Everything produced so far is pre-access design work, explicitly permitted under this repo's plan-and-draft-only default (`AI_OPERATING_RULES.md`).

---

## 2. The architecture — corrected this session, read carefully

This is the single most important update since the original day-2 handover, and it invalidates parts of the originally received technical specification.

### 2.1 What changed

The client supplied an architecture diagram (interpreted in conversation, not a file in this repo) showing the actual system topology. It **confirmed CPI is in the runtime path** — contradicting the vendor-supplied technical specification, which drew a direct storefront-to-Gateway connection with no middleware. It also established that **S/4HANA is not the sole source of data or truth for this product.** Three systems each own real slices of it:

```text
C&F Agent → Spartacus storefront ←OCC← Commerce Cloud T1
                                              (pending order, deliveries,
                                               invoice billing, invoice download —
                                               pushed FROM SAP via CPI)
                    ↕ REST
              Commerce Cloud T2
        (depot, user, agent-depot, geography master, material/alias,
         Incoterms, storage location, depot-SL, SL-SPI, vehicle master,
         transporter, OCC, integration objects)
                    ↕ REST
         SAP Integration Suite (CPI)  — iflows, adapters, messages, scripting
              ↕ JDBC/OData                    ↕ REST
        SAP Datasphere                   SAP S/4HANA (or ECC — unconfirmed)
    (STO, MRN, plant-SL,              (CheckMigo, submitMigo, createDI,
     transporter, vehicle master,      stockAvailability, ShipmentCost,
     ageing report, e-invoice?)        createInvoice, e-invoice correction,
    daily refresh except STO/MRN       E-Way Bill extension)
    which are near-real-time            real-time
```

### 2.2 Source-of-record table (Verified from client diagram unless noted)

| Concept | Owner | Note |
|---|---|---|
| Goods receipt, delivery, goods issue, shipment, shipment cost, billing document | **S/4HANA** | Created and posted in SAP; authoritative document numbers |
| Stock and batch availability | **S/4HANA** | Transactional decision — must not be served from a replicated snapshot |
| IRN, E-Way Bill | Statutory portal, persisted in S/4HANA | Datasphere also carries an e-invoice object of unconfirmed source — open question |
| Pending order list, deliveries, invoice billing as the portal displays them | **Commerce T1** | Pushed from SAP via CPI. The storefront does **not** read these from SAP directly |
| Invoice download | **Commerce T1**, CRM portal fallback | SAP is not the primary file-retrieval path |
| Depot, user, agent-depot, geography master, material alias, Incoterms, storage location, depot-SL, SL-SPI | **Commerce T2** | Portal master data — inputs to SAP APIs, not SAP-derived values. Commerce-to-SAP code mapping is unresolved |
| Vehicle master, transporter | **Commerce T2 AND Datasphere** | **Duplicated.** Which is authoritative, and which value SAP receives at posting, is unresolved |
| STO, MRN | **Datasphere** | **MRN is not generated by SAP.** This directly invalidates the vendor spec's approach (below) |
| plant-SL, ageing report | **Datasphere** | Analytical/reference reads |

### 2.3 Three consequences that follow directly

1. **MRN must not be fabricated inside a SAP goods-receipt function.** The originally received spec did exactly this (`ev_mrn = "MRN-" + material_doc_number`) — a developer invention, not a business identifier, and now confirmed architecturally wrong. SAP's Submit-MIGO API should return the material document key only; MRN resolves in Datasphere.
2. **The portal's pending-order dashboard is not what "Check MIGO" (API-01) answers.** That dashboard is Commerce T1's job, fed by SAP via CPI on some trigger/latency not yet defined. API-01 is the narrower SAP-side receipt position.
3. **Storage location, depot-SL, SL-SPI, transporter and vehicle master arrive at SAP APIs as inputs from Commerce/Datasphere, not values SAP derives.** The Commerce-to-SAP organisational code mapping (plant, storage location) has no owner yet.

---

## 3. Our role — the ABAP/SAP backend team

**Scope (Verified, `ROLE_BOUNDARIES.md`):** S/4 source-of-record analysis; ABAP application classes; SEGW/OData V2 service design; BAPI/released-API selection and validation; SAP-side business validation, error mapping, logging, idempotency; commit/rollback policy within the SAP unit of work; unit testing; producing CPI-consumable contracts; diagnosing Gateway/ABAP runtime failures.

**Explicitly not our scope:** frontend/UI, native iFlow construction, Datasphere modelling, Basis parameter/role changes, functional sign-off, external tax/GSP credential ownership, production postings.

**The central thesis of the entire project** (Verified, stated plainly in `PROJECT_BRAIN.md` and confirmed by the 28 July walkthrough's side conversation):

> A BAPI will not repair a semantically wrong payload.

The client's senior stakeholders explicitly pushed back on vendor management scoping this as "CPI/Commerce field mapping and BAPI posting." The client is correct: correct API selection is necessary but not sufficient. Without understanding Shree Cement's KDS codes, material groupings, business segments, and trade/non-trade/STO distinctions, a technically perfect BAPI call posts a real document with wrong business content — and that failure surfaces in production, not in code review. This is why the single highest-leverage open item (**V-12**, below) is a knowledge-transfer session, not a system permission.

---

## 4. Evidence state — what's actually known versus manufactured

This section is the one a successor agent must not skip or soften.

### 4.1 Genuinely Verified (small list, and it matters that it's small)

- D-001: Order = DI Quantity + Pending Quantity; labels renamed accordingly.
- D-002: One storage location per DI/invoice; multiple batches allowed inside it; batch quantities must sum exactly to DI quantity.
- D-003: E-Way Bill extension transport mode is Road only, 24 hours, repeatable.
- D-004: E-Way Bill Part B stays editable during validity.
- D-005: Only DI quantity is editable after creation, and only while the DI is open. (Note: a residual wording conflict exists between "while open" and "before batch determination" — flagged, unresolved, see `DECISION_LOG.md` conflict note.)
- D-006: Vehicle tracking uses FleetX (product decision; integration ownership unassigned).
- D-007: **DI = Delivery** (not "Delivery Instruction"); **DI No. = the outbound delivery number** (`LIKP-VBELN`). Source: `SRC-SID-20260729-01`, Siddharth's direct statement, logged Verified per the evidence-classification rule in §0.
- The client-supplied architecture diagram confirming CPI-in-path and the Commerce/Datasphere ownership split (§2).
- The client's own 9-process register (Check MIGO, Submit MIGO, Create DI, Stock Availability, Shipment Cost, Invoice Creation, Invoice Correction, E-Invoice Correction, E-Way Bill Extension) — confirmed against a second client-supplied image, which also validated our independently-derived classification approach.

### 4.2 The honest caveat about everything else in `deliverables/`

**This is important and must not be lost in a handover.** Siddharth explicitly instructed that the polished classification PDF, the Excel workbooks, the effort estimates, and the delivery timeline are **deliberately constructed pre-access artifacts** — his words: "this is basically LARPing at a large scale, and that's how we will get the data access." The strategy is: present a document sophisticated enough that the client reads it as competent ownership of the problem, while every SAP object name, BAPI signature, and effort figure inside it is explicitly labelled a **candidate pending system verification**. The goal is to make development access the obvious, inevitable next step — not to claim false certainty.

**A successor agent must never let this distinction collapse.** If asked "is the API classification correct," the honest answer is: *it is an informed engineering estimate, internally consistent, cross-checked against two client-supplied artifacts, and explicitly unverified against any real SAP system.* Do not let a future session, or the client, mistake the deliverables for verified fact. The moment DEV access lands, re-validate everything in `CNF_Delivery_Planning.xlsx §Validation Register` before trusting any of it operationally.

### 4.3 Strong inference (engineering judgment, not yet functionally confirmed)

- Invoice Creation cannot be one atomic unit of work — it spans four separate SAP commits (goods issue, shipment, shipment cost, billing) plus two external statutory calls (e-invoice, E-Way Bill) with independent, unpredictable latency and failure. Must be modelled as a staged, resumable, idempotent process with a process ID, not a single synchronous POST.
- The Shipment Cost "estimate" mode (pre-commitment freight estimate, before any document exists) has **no standard SAP equivalent** — standard shipment costing is document-bound and requires a posted shipment. The estimate must be built via condition-technique pricing *simulation* (recommended — reuses real freight configuration, converges with actual cost by construction) rather than hand-read rate tables (diverges silently over time) or create-then-reverse (rejected — pollutes document flow and consumes number ranges).
- Idempotency has no standard SAP mechanism at all and is the most commonly underestimated item across all ten APIs — every command needs an external-request-ID store that survives the "SAP committed, response lost" case.

### 4.4 Hypothesis — explicitly must not be built on

- DI's predecessor document: sales order or stock transport order (the vendor spec is internally contradictory here — it calls the STO-creation BAPI while passing sales-order data).
- Whether SAP Document Compliance for India (the delivered eDocument/statutory framework) is licensed and configured — this single fact swings roughly 20–25 days of effort across two APIs (E-Invoice Correction, E-Way Bill Extension) between "thin wrapper" and "bespoke statutory client."
- Whether CPI or ABAP owns the outbound GSP/statutory calls and their credentials.
- FIFO batch ranking logic ownership (SAP config vs portal-proposed).
- Backend release: ECC or S/4HANA, and which version — unresolved, and it determines whether released OData/CDS alternatives exist at all for several of these APIs.

---

## 5. The received technical specification — assessed, not trusted

The client supplied `SAP_ABAP_OData_Technical_Specification.pdf` (logged as `SRC-TECH-001`). Full review is `SAP_API_DOSSIER.md §Part A` in this repo; condensed here.

**Classification: greenfield build instruction, not as-built documentation.** Written entirely in the imperative ("Create Project," "Right-click → Generate Runtime Objects"). No `ZCNF_*` objects exist in any inspected client system — consistent with this being a proposal never built, not evidence of a hidden implementation elsewhere.

**32 numbered defects (S-01 to S-32), by severity:**

- **6 Blockers** — code that will not compile or run as written: wrong BAPI called for DI creation (STO-creation BAPI given sales-order data), wrong delivery structure family (inbound structures used for outbound operations), a nonexistent MKPF field referenced, an unguarded `FOR ALL ENTRIES` that would select an entire table on empty input, the wrong BAPI family used for credit/debit memo creation, and a GSP JSON-response parser that is a commented-out placeholder.
- **11 Critical** — compiles but produces wrong outcomes or security holes: **no idempotency anywhere** (the single most serious gap — a retried request would post a duplicate goods receipt, delivery, or credit memo), Z-table writes for custom fields sitting outside the BAPI's unit of work (a second-commit failure silently loses vehicle/driver data), the fabricated MRN (§2.3), a binary (not tri-state) receipt status that cannot represent partial receipts, a missing plant-level authorization check despite the auth object declaring one, all C&F agents sharing one role with no depot segregation, GSP bearer tokens stored in a plain Z-table column, and no evaluation of SAP's standard Document Compliance framework before hand-building statutory e-document logic from scratch.
- **4 Major contradictions of the client's own approved decisions**: violates D-002 (no header-level storage location, no batch-sum validation), D-005 (permits editing far more than DI quantity), D-003 (accepts a Rail transport mode that was explicitly rejected), D-001 (never derives pending quantity).
- Coverage: the spec addresses only 6 of the eventual 24-candidate interface register, and the entire invoice-to-e-document journey central to the 28 July walkthrough has no service in it at all.

**Verdict:** usable for naming conventions, package layout, and as evidence the work is greenfield. Not usable as a build instruction.

---

## 6. The API inventory — the current working answer

Ten APIs, aligned to the client's own 9-item process register plus one proposed addition (Modify DI — Create DI has no amend path without it). Full detail: `CNF_API_Classification.xlsx` and `API_SPECIFICATION_PROPOSAL.pdf`.

| ID | API | Class | Note |
|---|---|---|---|
| API-01 | Check MIGO | **C** — composite over standard reads | Narrower than the Commerce-served dashboard (§2.3) |
| API-02 | Submit MIGO | **S** | Does not derive MRN (Datasphere-owned) |
| API-03 | Create DI | **S** | Predecessor (SO vs STO) unresolved |
| API-04 | Stock Availability | **C** | Composite: stock + availability + batch attrs + ranking |
| API-05 | Shipment Cost | **X (estimate) / S (actual)** | No standard pre-document estimate mechanism |
| API-06 | Invoice Creation | **X** | Orchestration across 4 SAP LUWs + 2 external calls |
| API-07 | Invoice Correction | **S** | Correction and reversal are distinct processes |
| API-08 | E-Invoice Correction | **S**, conditional | IRN cannot be amended — cancel-and-reissue within statutory window, or credit/debit note outside it |
| API-09 | E-Way Bill Extension | **S / X**, conditional | Swings entirely on Document Compliance licensing |
| API-10 | Modify DI *(proposed)* | **S** | Not in client register — scope confirmation open |

**Classification key:** S = delivered SAP API/BAPI does the work, thin wrapper only. C = every source is standard, but the combined shape needs a composite build. X = no standard equivalent exists; genuine new construction.

**Where the real risk concentrates:** API-05's estimate mode and API-06's orchestration. Everything else is standard operations needing integration scaffolding (idempotency, auth, error shaping) rather than new business logic.

---

## 7. The blocking validation register — 29 items, ranked

Full register: `CNF_Delivery_Planning.xlsx §Validation Register`. The ones that gate the most:

1. **V-12 — Master/reference code dictionaries** (brand/grade derivation, material grouping, business segment, org codes, Incoterm treatment). Gates **every payload field across all ten APIs**. Cannot be resolved by system access — requires SD/business knowledge transfer. This is the item from §3's central thesis made concrete.
2. **V-01 — Backend release** (ECC vs S/4HANA, exact version). Gates whether released APIs/CDS exist at all for several endpoints.
3. **V-02 — SAP Document Compliance for India licensing.** Single question, ~20–25 day swing across two APIs.
4. **V-04 — Invoice Creation: staged or atomic?** Engineering strongly favours staged (§4.3); needs functional/architecture confirmation.
5. **V-05 — DI predecessor:** sales order or STO.
6. **V-03 — Statutory call ownership:** CPI or ABAP calls the GSP directly.
7. **V-26 to V-29 — Cross-system items surfaced by the architecture correction**: duplicated transporter/vehicle master (Commerce T2 vs Datasphere), Commerce-to-SAP code mapping ownership, a duplicated Datasphere e-invoice object of unconfirmed lineage, and what exactly SAP pushes to Commerce T1 for the portal dashboards.

V-01, V-02, V-06, V-15, V-16, V-21, V-23 are answerable within the first two days of DEV access and together resolve six of the ten APIs' classification. V-12 and V-27 are not answerable by system access at all — they need people.

---

## 8. Current state and immediate next steps

**Timeline (all dates speculative pre-access planning, not commitments — see caveat in §4.2):** Project start 25 Jul 2026; preparation phase (briefing, architecture reasoning, requirements, spec) complete by 30 Jul; DEV access assumed early August (window given: 31 Jul–5 Aug). Compressed build plans exist at multiple granularities in `deliverables/` — a full narrative version, a conditions-and-risks version, and a bare date-and-days version for manager consumption. All are explicit that **access is the sole hard dependency**; every phase after it is a direct function of when it lands.

**What's actually blocking right now:** DEV access, and separately, a knowledge-transfer session against V-12. Neither is something an AI agent can produce — both require a human with authority (functional sign-off owner, or whoever grants system access) to act.

**Recommended first actions for a successor agent**, all plan-and-draft compliant, none requiring system access:
1. Re-read the live registers (`OPEN_QUESTIONS.md`, `DECISION_LOG.md`) for anything that changed since this document was written — this handover will go stale.
2. If DEV access has landed: do **not** trust any BAPI name, field mapping, or classification in `deliverables/` until re-verified against the real system per the Validation Register. Start with API-04 and API-01 (read-only, zero business-state risk) exactly as `NEXT_MOVE.md` specifies.
3. If DEV access has not landed: the highest-leverage available work is turning `DOMAIN_GLOSSARY.md §Required KT outputs` into a structured intake instrument for a V-12 session, using `templates/kt-session.md`.
4. Do not generate new speculative deliverables without being asked — the existing set is sufficient to make the access ask; more paper does not accelerate access.

---

## 9. Repository housekeeping (as of this session)

- `deliverables/` contains the current client-facing output set: `API_SPECIFICATION_PROPOSAL.pdf/.md` (full narrative spec, v1.2), `CNF_API_CLASSIFICATION.pdf` + `CNF_API_Classification.xlsx` (the classification object, standalone), `CNF_Delivery_Planning.xlsx` (business rules, effort, validation register, source-of-record, assumptions, timeline — the supporting-registers object, deliberately separated from the classification per Siddharth's instruction that these are different objects), `CNF_Timeline.xlsx` (bare date/days sheet for manager consumption, no nuance).
- `_archive/` holds `BRAIN_MAP.md`, `HANDOVER_2026-07-28_AI.md`, `HANDOVER_2026-07-28_HUMAN.md`, `DATASPHERE_SOURCES.md` — moved (not deleted, no git in this folder) because they were superseded snapshots or unstarted scaffolding. `DATASPHERE_SOURCES.md` needs recreating from `templates/` once real Datasphere discovery starts (`DATASPHERE_DISCOVERY_PLAN.md` and `MASTER_PLAN.md` both note this).
- `PROJECT_BRAIN.md` was deliberately **kept**, not archived — it is required reading per `CLAUDE.md`, `AGENTS.md`, and `README.md`'s own bootstrap sequence. Do not delete it without also updating those three files.
- `SAP_API_DOSSIER.md` is the detailed engineering assessment (the source material this handover's §5–7 condense from) — read it for full defect-by-defect and API-by-API detail beyond what fits here.

---

## 10. What would invalidate this document

- DEV access actually landing — converts §4.4's hypotheses into either confirmations or corrections, and makes §7's validation register the active work item.
- Arrival of the BRD or CPI interface workbook, still never ingested into this repo (`MEETING_INGEST.md` shows both as pending-original).
- A V-12 knowledge-transfer session — converts most of `DOMAIN_GLOSSARY.md` from Hypothesis to Verified.
- Any resolution of V-01 through V-05 — each is a named fork that changes a concrete engineering decision, not just a confidence label.

Re-read the live registers before relying on anything above; this document is a reconciliation over them, written at a point in time, not a substitute for them.
