# Shree Cement C&F Agent — repository orientation

This repository is Siddharth's working control plane for the SAP side of the Shree Cement C&F Agent (CNF) Interface programme. It turns meetings, specifications, system observations and runtime evidence into a coherent integration plan and a client-facing API surface.

This file exists to orient you quickly, not to constrain you. Ask Siddharth what he wants; he will tell you.

## Where the project stands

The standard-first discovery is finished and the activation exercise is complete. Five SAP-delivered services lead the transactional core — material document, outbound delivery v2, billing document, purchase order processing, material stock — and all five have been transported, activated and read-tested in QS4/700.

The work has moved into **ABAP build transition**: closing the gaps the standard services cannot cover, for the v1.9 business API list. The planned custom builds are `ZCNF_STO_SRV`, `ZCNF_BILLING_SRV` and `ZCNF_PREPGI_SRV`.

Siddharth's ownership is the S/4HANA communication boundary — standard API validation, SAP-side source and document mapping, fallback ABAP for gaps, SAP errors and logging, and CPI-facing technical evidence. Basis owns activation. CPI/T2 own cross-call orchestration and the idempotency envelope. Frontend and UI are out of scope.

## The files

**Handovers** — written for an AI picking the project up, newest first:

- `HANDOVER_AI_2026-08-25.md` — runtime status per service, v1.9 disposition, the ABAP build programme, execution queue.
- `HANDOVER_AI_2026-08-19.md` — runtime certification, BAPI and freight investigation.
- `HANDOVER_AI.md` (v5.0, 08-15) — consolidated briefing and background.
- Topic handovers: `HANDOVER_SE37_BAPI_TEST_METHOD.md`, `HANDOVER_SEGW_CANDIDATE_DEEP_DIVES.md`, `HANDOVER_STANDARD_API_DISCOVERY.md`, `HANDOVER_V18_SESSION.md`, `SAP_SEGW_SCRIPTING_HANDOVER.md`.

**Project state:**

- `PROJECT_BRAIN.md` — reconciled mental model.
- `PROJECT_CONTEXT.md` — programme context and objectives.
- `DECISION_LOG.md`, `OPEN_QUESTIONS.md`, `DOMAIN_GLOSSARY.md`, `SYSTEM_OF_RECORD_MATRIX.md` — live registers.
- `MEETING_INGEST.md` — source IDs and how evidence gets filed.

**Key artefacts:**

- `deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx` — the business API list and request/response baseline.
- `deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md` — solution and proof plan (08-15).
- `outputs/simple-api-implementation-matrix-20260824/CNF_API_Service_Implementation_Matrix.xlsx` — per-service standard/custom classification with the BAPI or FM underneath.

## Things learned the expensive way

- HTTP 200, an allocated number, or a success message is not persistence. Re-read the document after commit.
- Confirm `SystemName` and `Client` from the SAP session before any scripted action, and run one SAP GUI script at a time — concurrent scripting plus manual use destabilises the session.
- Never commit passwords, cookies, authorization headers or CSRF tokens into handovers or evidence files.

## Map

| Path | What's in it |
|---|---|
| `sources/` | Primary evidence, filed by source ID |
| `sessions/` | Dated investigation sessions with raw evidence |
| `deliverables/` | Client-facing output |
| `outputs/` | Generated matrices and analyses |
| `meetings/` | Reconciled meeting intelligence |
| `evidence/` | Captured system observations |
| `templates/` | Reusable working templates |
| `_archive/` | Earlier documents, with old-to-new mapping |

Note: `README.md`'s repository map still lists `SAP_GUI_DISCOVERY_PLAN.md` and `WORKFLOW.md` at top level; both now live in `_archive/`.
