# Shree Cement C&F Agent Interface — AI Co-work Repository

This repository is Siddharth's working control plane for the SAP side of the C&F Agent Interface program.

Its purpose is to help Codex or Claude turn meetings, specifications, system observations, and implementation evidence into a coherent SAP integration plan. It is not an authorization to operate SAP, change code, enable scripting, create transports, post documents, or move client data outside approved systems.

## Current posture

- Scope is still being established across ABAP, SD/MM, CPI, Commerce, Datasphere, Basis, business analysis, and UI/UX teams.
- Siddharth's likely core ownership is the S/4HANA communication boundary: ABAP application logic, SEGW/OData V2, BAPI/API selection, SAP-side validation, errors, logging, idempotency, and CPI-facing contracts.
- Datasphere is a separate source for analytical or consolidated data. ABAP does not automatically own Datasphere exposure.
- Frontend and UI implementation are out of scope.
- Until formal assignment and DEV access arrive, AI output is limited to understanding, evidence classification, questions, plans, and drafts.

## Start here

1. Read `AI_OPERATING_RULES.md`.
2. Read `PROJECT_BRAIN.md`, `PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, and `ROLE_BOUNDARIES.md`.
3. Ingest original source documents through `MEETING_INGEST.md` and the templates.
4. Follow `MASTER_PLAN.md`; never silently replace uncertainty with assumptions.
5. Use `NEXT_MOVE.md` when DEV access and a formal assignment arrive.

## Evidence standard

Every material claim must be labeled:

- **Verified** — directly demonstrated in an authoritative source or system.
- **Strong inference** — supported by multiple independent signals.
- **Hypothesis** — plausible, but awaiting validation.
- **Contradicted** — evidence currently conflicts.
- **Unknown** — not yet established.

Conversation summaries are context, not primary evidence. Uploaded originals, signed-off requirements, system observations, and owner confirmations take precedence.

**Exception:** a fact Siddharth states directly to the AI in conversation is logged as **Verified**, source-cited as `SRC-SID-YYYYMMDD-NN` (see `MEETING_INGEST.md`), not as a hypothesis or inference awaiting confirmation. This is distinct from secondhand meeting reconstructions, which keep their original confidence label. Confirmed 2026-07-29.

## Repository map

| File | Purpose |
|---|---|
| `PROJECT_BRAIN.md` | Reconciled mental model and knowledge graph |
| `PROJECT_CONTEXT.md` | Program context, objectives, known facts, and assumptions |
| `ARCHITECTURE.md` | System topology and operational/analytical paths |
| `ROLE_BOUNDARIES.md` | Team ownership and collaboration boundaries |
| `MASTER_PLAN.md` | Phased SAP-side delivery and knowledge plan |
| `DOMAIN_GLOSSARY.md` | Client vocabulary, KDS codes, and validation status |
| `SYSTEM_OF_RECORD_MATRIX.md` | Authority for cross-system business concepts |
| `KNOWLEDGE_GRAPH_SCHEMA.md` | Schema for the living project brain |
| `REQUIREMENTS_MATRIX.md` | Business capability to interface traceability |
| `INTERFACE_REGISTER.md` | Canonical inventory of candidate interfaces |
| `HANDOVER_2026-07-30_AI.md` | Current complete contextual handover for a successor AI agent — read this after the operating rules |
| `SAP_API_DOSSIER.md` | Received spec assessment, meeting-derived process model, and the proposed SAP API set |
| `BAPI_CANDIDATES.md` | Candidate SAP APIs and required validation |
| `SEGW_ODATA_PLAN.md` | OData V2 design and implementation standards |
| `DATASPHERE_DISCOVERY_PLAN.md` | Controlled Datasphere inventory/lineage method (owns the discovery register once recreated) |
| `SAP_GUI_DISCOVERY_PLAN.md` | Approved read-only SAP discovery/automation method |
| `CPI_CONTRACTS.md` | CPI-facing contract principles and checklist |
| `CODEX_CLAUDE_COLLABORATION.md` | Shared-agent roles and handoff protocol |
| `OPEN_QUESTIONS.md` | Prioritized uncertainty register |
| `DECISION_LOG.md` | Decisions with owners and evidence |
| `MEETING_INGEST.md` | How to convert meetings into project memory |
| `meetings/` | Reconciled meeting intelligence |
| `WORKFLOW.md` | End-to-end co-work procedure |
| `AI_OPERATING_RULES.md` | Safety, approval, confidentiality, and agent rules |
| `NEXT_MOVE.md` | Short execution plan for DEV and first assignment |
| `templates/` | Reusable working templates |

## Definition of success

For any assigned interface, this repository should allow Siddharth to state:

> This is the signed-off business intent, the system of record for every field, the S/4 and/or Datasphere source, the selected SAP API, the OData contract consumed by CPI, the ownership boundary, the failure model, and the evidence proving the implementation.
