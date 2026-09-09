# Handover — AI-Facing State of Understanding

**Date:** 2026-07-28
**Author:** Prior AI-assisted session
**Audience:** Any successor entering this repository
**Status of this document:** Reconciliation snapshot. Not a plan, not an authorization, not a decision record.

---

## 0. Handoff protocol block

Per the former multi-assistant collaboration guide:

```text
Task ID:            HO-20260728-AI-01
Evidence read:      20 repository files (listed §1.2), both folder versions, folder diff
Facts added:        None. This document reconciles existing evidence; it introduces no new claims about SAP.
Inferences:         §5 (architectural consequences) — all labelled, none promoted to fact
Conflicts:          C-1 competing brains, C-2 non-citable Datasphere observations, C-3 spec-vs-system
Registers changed:  None. This file is additive only.
Questions:          No new Q-IDs proposed. Existing Q-001..Q-030 stand.
Proposed next:      §9
Approval needed:    None for this document. Everything in §9 requires approval before execution.
```

---

## 1. Read scope — what this understanding is actually built on

### 1.1 Provenance chain

```text
Day 1 (2026-07-27)
  SHREE_CEMENT_AI_PROJECT_HANDOVER.md                   [read]
  SHREE_CEMENT_MASTER_PLAN_CORRECTION_DIRECTIVE.md      [read]
        │
        └──> Codex produced: shree-cement-cnf-agent-cowork/     (23 files)
                             = governance + scaffolding, registers as empty frames

Day 2 (2026-07-28)
  Hindi meeting transcripts + translations:
    Chaayos_3 / Chaayos_4 / Chaayos_6 / New_Recording_12  [NOT read — not in these folders]
    MEETING-SUMMARY.md                                    [NOT read — not in these folders]
        │
        └──> Codex produced: shree-cement-cnf-agent-project-brain-2026-07-28/  (34 files)
                             = semantic layer + populated registers
```

The project-brain folder is a **superset** of the cowork folder. Treat cowork as superseded.

### 1.2 Files read in full

`README` · `AGENTS` · `AI_OPERATING_RULES` · `ROLE_BOUNDARIES` · `PROJECT_CONTEXT` · `PROJECT_BRAIN` · `BRAIN_MAP` · `ARCHITECTURE` · `MASTER_PLAN` · `NEXT_MOVE` · `WORKFLOW` · `REQUIREMENTS_MATRIX` · `INTERFACE_REGISTER` · `OPEN_QUESTIONS` · `DECISION_LOG` · `DOMAIN_GLOSSARY` · `SYSTEM_OF_RECORD_MATRIX` · `KNOWLEDGE_GRAPH_SCHEMA` · `BAPI_CANDIDATES` · `SEGW_ODATA_PLAN` · `CPI_CONTRACTS` · `DATASPHERE_SOURCES` · `SAP_GUI_DISCOVERY_PLAN` · `meetings/2026-07-28-design-walkthrough` · `templates/api-design` · `templates/interface-discovery`

### 1.3 NOT read — do not assume covered

| Item | Consequence |
|---|---|
| Raw Hindi transcripts + English translations | All meeting claims are **second-hand via Codex's reconciliation**. Disputed terms cannot be re-adjudicated from this repo alone. |
| `MEETING-SUMMARY.md` | Same. |
| `MEETING_INGEST.md`, `DATASPHERE_DISCOVERY_PLAN.md` | Method docs; unread. Read before running either discovery workstream. |
| `templates/bapi-validation`, `field-lineage`, `kt-session`, `meeting-notes`, `test-evidence` | Use them; they exist and are unread by this author. |
| The BRD, the ABAP/OData technical specification, the CPI interface workbook | **Never ingested by anyone into this repo.** `PROJECT_CONTEXT.md §Source material to ingest` lists them as still-required. This is a larger gap than any open question. |

---

## 2. Reconciled project model

### 2.1 One sentence

A new operational portal for C&F/depot users is being built over Shree Cement's existing SAP dispatch processes; Commerce renders the journey, CPI moves messages, S/4HANA remains the authority that validates and creates business documents, and Datasphere supplies selected analytical reads.

### 2.2 The operational spine (business intent — **not** a verified SAP call sequence)

```text
Order ──> Delivery Instruction (DI) ──> one storage location ──> 1..n batches
      ──> transporter + route + freight ──> shipment details (LR/GR, vehicle, driver)
      ──> { PGI · shipment · shipment cost · billing } ──> { e-Invoice/IRN · E-Way Bill }
      ──> document flow / status / download
      ──> E-Way Part A correction | Part B vehicle update | 24h extension
```

Peripheral to the spine: MIGO/partial receipt, warehouse-to-warehouse transfer, physical inventory reconciliation, dashboards, ageing reports.

### 2.3 Siddharth's boundary

Owns the **S/4HANA communication boundary**: S/4 source analysis, ABAP application classes, SEGW/OData V2, BAPI/released-API selection and validation, SAP-side validation, error contract, logging, correlation, idempotency, commit policy, CPI-facing contracts, layered tests.

Explicitly **not** his: frontend/UI, iFlow construction, Datasphere modelling, Basis parameters/roles, functional sign-off, GSP credential ownership, production postings.

---

## 3. The day-2 reframe — the single most important thing in this repository

Day 1 framed the task as *technical*: pick BAPIs, build SEGW, expose OData.

Day 2 established that the binding constraint is **semantic, not technical**.

> A BAPI will not repair a semantically wrong payload. — `PROJECT_BRAIN.md`

The design walkthrough exposed an unresolved scope-and-competence gap (`meetings/2026-07-28-design-walkthrough.md §Project risk exposed`):

- Client seniors expect SD/MM/**KDS** and master-data literacy from the technical team.
- Vendor management scoped the work narrowly as "CPI/Commerce field mapping and BAPI posting."
- The client's position is correct: field mapping cannot be validated without business/SAP semantics.

**Operational consequence for any agent:** do not produce BAPI selections, OData property lists, or CPI schemas as if they were ready. The glossary (`DOMAIN_GLOSSARY.md`) is the gate. Roughly a third of its terms — `DI`, `SPI`, `KDS`, `MRN`, `GD/GDF`, `TP/DTP`, `RD`, `1300`, business segment `10` — are **Hypothesis, Unresolved, or Critical unknown**. Payload fields built on those terms are unsafe.

---

## 4. Evidence ledger

Classification per `README.md §Evidence standard`.

### 4.1 Verified (approved in the 28 July walkthrough — `DECISION_LOG.md` D-001..D-006)

| ID | Content |
|---|---|
| D-001 | Labels are Order Quantity / DI Quantity; `Order = DI + Pending` |
| D-002 | One DI/invoice = one storage location; multiple batches permitted inside it |
| D-003 | E-Way Bill extension transport mode = Road only |
| D-004 | E-Way Bill Part B stays editable during validity |
| D-005 | Only DI quantity is editable post-creation, and only while DI is open |
| D-006 | Vehicle tracking will use FleetX (product decision; integration unassigned) |

Also verified: batch quantities must sum exactly to DI quantity (no under/over-allocation); SAP remains the invoice-generating authority; E-Way extension is 24h and repeatable, using current vehicle location + reason; driver mobile is mandatory (SMS document delivery).

### 4.2 Strong inference

- ABAP scope includes substantially more query/status services than the original six-interface proposal (register now carries **24** candidate interfaces, IF-001..IF-024).
- "Generate Invoice" is a multi-step orchestration, not one atomic BAPI call.
- DI is closely related to a delivery, but its SAP object identity is unverified.
- Current transactional reads belong to S/4; dashboard/history/ageing may belong to Datasphere.
- A shared semantic/KDS dictionary is a hard prerequisite for dependable mapping.

### 4.3 Hypothesis — must not be built on

- DI maps 1:1 to an SAP outbound delivery.
- "SPI" is the correct acronym and maps to a specific shipping/storage concept (defaults to `01` in the design).
- SAP currently proposes batches by largest quantity rather than FIFO.
- Commerce retains 60 days of operational history.
- The invoice workflow can run synchronously end to end.

### 4.4 Observed but non-citable

A prior session performed a live read-only metadata crawl of Datasphere tenant `shree-cement-q.ap10.hcs.cloud.sap`, space `SAP_S4_QA`. It returned real object inventory, layering conventions, flow topology, and cross-space dependencies. **The extract was lost before persistence.** Under this repo's evidence standard it is Strong Inference, not citable, and it does **not** advance `DATASPHERE_SOURCES.md` — DS-001..DS-008 remain TBD/Hypothesis.

Its only legitimate use is to make a future authorized re-capture faster and better targeted. Do not quote figures from it into any register.

### 4.5 Unknown / contradicted

Everything in `OPEN_QUESTIONS.md` Q-001..Q-030. The five Critical items are in §6.

---

## 5. Architectural consequences that follow from current evidence

Labelled inferences. None is a decision. Each is falsifiable by a specific open question.

**5.1 The invoice journey cannot be one LUW.** PGI, shipment, shipment cost, billing, and external e-document calls are separate SAP units of work, and the GSP/portal legs have unpredictable latency and independent failure. Any design that wraps them in a single synchronous OData POST inherits partial-completion states it cannot represent. → Falsified or confirmed by **Q-008 / Q-026**. Until then, model the journey as explicit commands + statuses (`meetings §Consequences`: *"Split the invoice journey into explicit commands/statuses before selecting BAPIs"*).

**5.2 DI resolution is a swap point, not a redesign point — if isolated early.** Three live candidates: outbound delivery, custom Z-object, instruction preceding delivery. If DI access is confined behind one adapter boundary from the start, resolving **Q-003** changes one implementation, not the model, the OData contract, or CPI's schema. If it is not isolated, Q-003 resolution invalidates work across IF-003/004/014/015/018/019.

**5.3 Idempotency requires the external request ID to reach the SAP document.** `SEGW_ODATA_PLAN.md` requires storing request→result association and replaying prior success. A Z-table alone cannot survive the *"SAP committed, response lost"* case unless the correlation ID is also persisted somewhere queryable **on the SAP document itself**. Where that field lives is per-document and unresolved. → **Q-010**.

**5.4 Prefer released APIs over classic BAPIs, but verify per release.** `BAPI_CANDIDATES.md` already lists candidates and instructs "prefer released standard APIs." In S/4, released OData/CDS equivalents frequently exist for goods movement, delivery, and billing. Which are available and permitted is **Q-013**, unanswerable without system access.

**5.5 Read-first vertical slice is correct and should not be renegotiated.** `NEXT_MOVE.md` and `MASTER_PLAN.md §Phase 6/7` both put a read/reference endpoint before any posting. This is the right sequencing: it proves source selection, authorization, error contract, pagination, correlation, logging, and CPI connectivity with zero business-state risk.

---

## 6. Blocking set — ranked

| Rank | ID | Question | Blocks |
|---|---|---|---|
| 1 | Q-021 | What is KDS; what are the approved code dictionaries (business segment, product families, material groups, sales orgs, `1300`)? | All field mapping, every payload |
| 2 | Q-003 | What is DI in S/4 — outbound delivery, custom object, or pre-delivery instruction? | IF-003/004/014/015/018/019 |
| 3 | Q-001 | Is the technical spec approved design, draft, estimate, or as-built elsewhere? | All implementation |
| 4 | Q-002 | Exact DEV/QAS/PRD landscape; Gateway embedded or hub? | Any development setup |
| 5 | Q-004 | Is the receipt flow PO-, STO-, inbound-delivery-, outbound-delivery-, or custom-referenced? | IF-001/002, MIGO design |
| 6 | Q-008 / Q-026 | Invoice: synchronous atomic command or staged/async? Which SAP documents/APIs per stage? | Entire invoice architecture |
| 7 | Q-005 | Which reads come from S/4 vs Datasphere? | Source design, IF-010/013/014 |
| 8 | Q-006 | First formally assigned interface + signed-off acceptance criteria? | Start of any work |
| 9 | Q-027 | Where are trade/non-trade/STO recordings; who delivers SD/MM KT? | Repairs the gap in §3 |
| 10 | Q-009 | Does CPI own GSP/E-Way Bill calls, or is ABAP expected to call directly? | IF-007/021/022/023 |

Q-006 and Q-027 are the two an agent should push hardest for: without Q-006 nothing is legitimately startable; without Q-027 nothing built is trustworthy.

---

## 7. Conflicts on the record

**C-1 — Competing brains (unresolved, action required).**
Former collaboration rule: *"Parallel assistants must not maintain competing memories."*
Two now exist:
- `…/shree-cement-cnf-agent-project-brain-2026-07-28/` — Codex-authored, evidence-rich, register-driven. **Canonical.**
- `C:\Users\lenovo\Desktop\Shree_Cement_Project\MASTER_PLAN.md` — AI-assisted, Rev. 3, built before this repo was seen. **Now redundant and partly non-compliant** (its capability-tier model is more permissive than `AI_OPERATING_RULES.md`'s plan-and-draft-only default).

Recommendation: retire the Desktop file; migrate only genuinely additive material as *proposals* — (a) 12-step runtime loop, (b) measurable tier-promotion tests, (c) temporal/environment fields on evidence nodes (SID · client · environment · valid-from/to · transport ref · object version · source hash), (d) agent-host vs LLM deployment split. Item (c) is the strongest candidate: `KNOWLEDGE_GRAPH_SCHEMA.md` has `environment` and `effective_date` but no transport reference or source hash, so it cannot yet distinguish pre- from post-transport truth.

**C-2 — Non-citable Datasphere observations.** See §4.4.

**C-3 — Spec vs system.** `ZCNF_AGENT_SRV` and the `ZCNF_*` object set appear in a technical document; SE80/SEGW search on Quality found no CNF objects. Both claims preserved. Absence of evidence in one client is not proof of non-existence (alternative namespace, DEV-only, different Gateway hub all remain live). → Q-001.

---

## 8. Anti-patterns — refuse these even if asked

From `AI_OPERATING_RULES.md`, `SAP_GUI_DISCOVERY_PLAN.md` and the former collaboration guide:

- Generating implementation from meeting prose without functional confirmation.
- Promoting another agent's inference into a verified fact.
- Merging two terms/codes because their labels look similar (`SPI`, `GD/GDF`, `DTP`, `ODN`, `KDS` stay separate unknowns).
- Building one "all SAP data" API instead of bounded capabilities.
- Embedding a business process inside a generated `DPC_EXT` method.
- Automating SAP writes because the GUI path has been learned.
- Enabling GUI scripting, touching RZ11/profile parameters, or modifying roles — **always prohibited to the agent**, regardless of approval level.
- Starting with the full invoice orchestration.
- Treating Datasphere as transactionally current.
- Scraping a system without business purpose and approved scope.

---

## 9. Bounded next actions — research only, no system access

All are `AI_OPERATING_RULES` plan-and-draft compliant. None requires DEV.

1. **Ingest the originals.** BRD, ABAP/OData technical spec, CPI interface workbook are still absent from the repo. This is the highest-value non-blocked action available.
2. **BAPI/released-API research dossier.** Extend `BAPI_CANDIDATES.md` per candidate with: released-vs-deprecated status by S/4 release, released OData/CDS alternative, mandatory predecessor keys, `BAPIRET2` shape, commit ownership, duplicate-on-timeout exposure, extension-field mechanism. Mark every row Candidate. Use `templates/bapi-validation.md`.
3. **Draft the OData modelling standard** — naming, type discipline (leading zeros preserved; decimal precision + unit pairing; date/timezone rule; no `'X'` booleans crossing the boundary), `sap:` annotation policy, ETag policy, service-versioning policy, shared DDIC structure strategy for cross-service coherence. Extends `SEGW_ODATA_PLAN.md §Contract standards`; introduces no SAP claims.
4. **Draft the service decomposition** — map IF-001..IF-024 onto a small number of bounded SEGW projects rather than one monolith or 24 services. Reversible on paper; expensive to change after build.
5. **Draft the DI adapter isolation boundary** (§5.2) so Q-003 remains a one-class swap.
6. **Draft the idempotency + correlation design** including the timeout-reconciliation path (§5.3), with the SAP-side persistence location marked TBD per document type.
7. **Draft the staged-invoice state model** as the working assumption, with the synchronous variant preserved as the alternative pending Q-008.
8. **Prepare the KT intake instrument** — turn `DOMAIN_GLOSSARY.md §Required KT outputs` into a fillable sheet so the SD/MM/KDS session produces structured output rather than notes.
9. **Prepare the day-one DEV checklist** — auth objects to verify (`S_DEVELOP`, `S_TCODE` for SEGW/SE80/SE11/SE24/SE37 and `/IWFND/*` `/IWBEP/*`, `S_SERVICE`, `S_RFC`, `S_TABU_DIS`/`S_TABU_NAM`), landscape facts to capture, package/namespace/transport standards to agree (Q-019). Note: `S_SCR` presence ≠ scripting enabled; server profile parameters and client settings also gate it, and **the agent never changes them**.

---

## 10. What would invalidate this document

- Arrival of the BRD / technical spec / CPI workbook (§1.3) — likely to resolve or reframe Q-001, Q-006, and much of the interface register.
- Any answer to Q-021 or Q-003 — either forces revision of §3 and §5.
- KT delivery against Q-027 — converts most of `DOMAIN_GLOSSARY.md` from Hypothesis to Verified.
- DEV access — converts Q-002, Q-013, and the entire `BAPI_CANDIDATES.md` validation column from theory to evidence.

Re-read the registers before relying on any section here; they are the source of truth, this is a reconciliation over them.
