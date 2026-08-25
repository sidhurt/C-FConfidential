# Shree Cement C&F Agent Interface — AI Co-work Repository

This repository is Siddharth's working control plane for the SAP side of the C&F Agent Interface program.

Its purpose is to help turn meetings, specifications, system observations, and implementation evidence into a coherent SAP integration plan.

## Current posture

- **Standard-first discovery is complete at design time.** The QS4 SEGW catalogue contains 2,626 projects; the full business-led scan retained 41 unique candidates, and the first 11 Tier-A competitors have complete tree/grid evidence.
- Five released A2X services now lead the transactional core: material document, outbound delivery v2, billing document, purchase order processing, and material stock. They are design-time candidates until registration, local `$metadata`, authorisation and representative runtime tests prove them.
- The old assumption that CNF required a new portfolio of `ZCNF_*` OData services is retired. Custom ABAP is now permitted only for a proven gap after the standard service, existing client implementation and orchestration options have been tested.
- Siddharth's core ownership is the S/4HANA communication boundary: standard API validation, SAP-side source and document mapping, fallback ABAP for genuine gaps, SAP errors/logging, and CPI-facing technical evidence. Basis owns activation; CPI/T2 own cross-call orchestration and the agreed idempotency envelope unless architecture assigns otherwise.
- Datasphere is a separate source for analytical or consolidated data. ABAP does not automatically own Datasphere exposure.
- Frontend and UI implementation are out of scope.

## Start here

1. **`PROJECT_BRAIN.md`** — current mental model and the standard-first correction.
2. **`deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md`** — current Monday solution, build-gap and `/IWFND/GW_CLIENT` proof plan.
3. **`sessions/2026-08-15-standard-api-discovery/TIER_A_DEEP_DIVE_FINDINGS.md`** and **`CNF_STANDARD_API_MATRIX.tsv`** — material SEGW evidence and requirement-level coverage.
4. Live registers: `DECISION_LOG.md`, `OPEN_QUESTIONS.md`, `DOMAIN_GLOSSARY.md`, `SYSTEM_OF_RECORD_MATRIX.md`.
5. `sources/` for primary evidence; `MEETING_INGEST.md` for source IDs and intake.

**Legacy warning:** `SAP_API_DOSSIER.md` Part C, `deliverables/SHREE_CNF_SAP_API_DOCUMENTATION_PRE_DEV_V2.md`, and earlier `ZCNF_*` build plans are historical evidence only. They are not the current implementation backlog. Earlier handovers remain useful for process and scripting protocol only where they do not conflict with the 2026-08-15 findings.

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
| `DOMAIN_GLOSSARY.md` | Client vocabulary, KDS codes, and validation status |
| `SYSTEM_OF_RECORD_MATRIX.md` | Authority for cross-system business concepts |
| `HANDOVER_AI.md` | Consolidated historical/current-state briefing; the 2026-08-15 standard-first section overrides its older service-surface sections |
| `SAP_API_DOSSIER.md` | Historical received-spec assessment and process evidence; Part C custom portfolio is superseded |
| `SAP_GUI_DISCOVERY_PLAN.md` | Approved read-only SAP discovery/automation method |
| `OPEN_QUESTIONS.md` | Prioritized uncertainty register |
| `DECISION_LOG.md` | Decisions with owners and evidence |
| `MEETING_INGEST.md` | How to convert meetings into project memory |
| `meetings/` | Reconciled meeting intelligence |
| `WORKFLOW.md` | End-to-end co-work procedure |
| `templates/` | Reusable working templates |
| `sources/` | **Primary evidence** — originals by source ID, plus plain-text extractions |
| `sessions/2026-08-15-standard-api-discovery/` | Full catalogue scan, deep dives, sibling deltas, and requirement-level candidate matrix |
| `deliverables/` | Client-facing output; use the standard API solution/test plan as the current SAP implementation view |
| `_archive/` | Superseded documents and retired numbering, with old-to-new mapping |

## Definition of success

For any assigned interface, this repository should allow Siddharth to state:

> This is the signed-off business intent, the system of record for every field, the S/4 and/or Datasphere source, the selected SAP API, the OData contract consumed by CPI, the ownership boundary, the failure model, and the evidence proving the implementation.
