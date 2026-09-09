# Shree Cement C&F Agent Interface — AI Co-work Repository

This repository is Siddharth's working control plane for the SAP side of the C&F Agent Interface program.

Its purpose is to help turn meetings, specifications, system observations, and implementation evidence into a coherent SAP integration plan.

## Current posture

- **The project is in execution-path reconciliation, not service discovery.** Five SAP-delivered services are active in QS4, but availability is no longer treated as proof that the externally invoked path preserves client-specific business behavior.
- Standard reads remain preferred. Material Stock and STO/PO reads have representative QS4 proof.
- Create DI is path-proven for an STO predecessor through `API_OUTBOUND_DELIVERY_SRV;v=2`; Trade and Non-trade remain separate certification cases.
- Submit MIGO is no longer classified as simple standard-direct. The standard service posted one PO+delivery receipt, but later BAPI/BAdI work proved a delivery-led mapping gap and a transaction-versus-API validation split. The supported enhancement implementation is not yet proven.
- Pre-PGI, STO creation and billing creation require controlled external command boundaries around existing BAPI/FM logic. PGI remains an unexecuted standard-action candidate.
- eDocument/DigiGST operations remain trace-first: reuse the installed route before proposing competing custom code.
- `CURRENT_STATE.md` is the authority for implementation status.

## Start here

1. **`CURRENT_STATE.md`** — authoritative API-by-API implementation disposition and next gates.
2. **`deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx`** — business contract baseline; do not treat its runtime notes as current.
3. **`deliverables/CNF_MIGO_CUSTOMISATION_DISPOSITION_2026-09-04.md`** — current MIGO transaction/BAPI enhancement analysis.
4. **`sessions/2026-09-01-bapi-field-derivation/FINDINGS.md`** and **`sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md`** — primary September implementation findings.
5. Live registers: `DECISION_LOG.md`, `OPEN_QUESTIONS.md`, `DOMAIN_GLOSSARY.md`, `SYSTEM_OF_RECORD_MATRIX.md`.
6. `sources/` for supplied evidence; `MEETING_INGEST.md` for source IDs and intake.

**Legacy warning:** the 15–25 August standard-first plans, implementation matrices and handovers remain valuable evidence, but their certification language is partially superseded by `CURRENT_STATE.md`. `SAP_API_DOSSIER.md` Part C, `deliverables/SHREE_CNF_SAP_API_DOCUMENTATION_PRE_DEV_V2.md`, and earlier `ZCNF_*` portfolios are historical rather than the current backlog.

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
| `CURRENT_STATE.md` | Current implementation authority and API disposition |
| `PROJECT_BRAIN.md` | Reconciled mental model and knowledge graph |
| `PROJECT_CONTEXT.md` | Program context, objectives, known facts, and assumptions |
| `DOMAIN_GLOSSARY.md` | Client vocabulary, KDS codes, and validation status |
| `SYSTEM_OF_RECORD_MATRIX.md` | Authority for cross-system business concepts |
| `HANDOVER_AI.md` | Historical consolidated briefing; use only where it does not conflict with `CURRENT_STATE.md` |
| `SAP_API_DOSSIER.md` | Historical received-spec assessment and process evidence; Part C custom portfolio is superseded |
| `SAP_GUI_DISCOVERY_PLAN.md` | Approved read-only SAP discovery/automation method |
| `OPEN_QUESTIONS.md` | Prioritized uncertainty register |
| `DECISION_LOG.md` | Decisions with owners and evidence |
| `MEETING_INGEST.md` | How to convert meetings into project memory |
| `meetings/` | Reconciled meeting intelligence |
| `WORKFLOW.md` | End-to-end co-work procedure |
| `templates/` | Reusable working templates |
| `sources/` | **Primary evidence** — originals by source ID, plus plain-text extractions |
| `sessions/2026-08-15-standard-api-discovery/` | Historical catalogue scan, deep dives and candidate matrix |
| `sessions/2026-09-*` | BAPI derivation, enhancement inventory and MIGO implementation evidence |
| `deliverables/` | Client-facing output; use the standard API solution/test plan as the current SAP implementation view |
| `_archive/` | Superseded documents and retired numbering, with old-to-new mapping |

## Definition of success

For any assigned interface, this repository should allow Siddharth to state:

> This is the signed-off business intent, the system of record for every field, the S/4 and/or Datasphere source, the selected SAP API, the OData contract consumed by CPI, the ownership boundary, the failure model, and the evidence proving the implementation.
