# Canonical Reconciliation Backlog

## Safety rule for the cleanup session

Do not delete first. Promote evidence and decisions into the canonical registers, verify cross-links, then archive or mark superseded material. Older files may contain useful provenance even when their conclusions are obsolete.

## Recommended execution order

1. Register the new `SRC-FIG-*`, `SRC-DOC-*` and `SRC-SID-*` records in `sources/README.md` and `MEETING_INGEST.md`.
2. Promote resolved business rules and explicit removals into `DECISION_LOG.md`.
3. Update conflicts/questions in `PROJECT_BRAIN.md` and `OPEN_QUESTIONS.md` without deleting genuinely open SAP gates.
4. Correct `DOMAIN_GLOSSARY.md` and `SYSTEM_OF_RECORD_MATRIX.md`.
5. Refresh `HANDOVER_AI.md` and `ONBOARDING_AI.md` from the now-reconciled registers.
6. Repair `README.md` navigation.
7. Reconcile the remaining v1.7 validation gates; the API-08 E-Way rewrite and candidate API-11 STO PO contract have already landed.
8. Only then review obsolete deliverables/files for archive or deletion.

## File-by-file changes

| Target | Stale/current problem | Required reconciliation |
|---|---|---|
| `sources/README.md` | New evidence ends at FIG-08 | Add FIG-09..13, DOC-02..04, and direct-clarification record with hashes/confidence |
| `MEETING_INGEST.md` | Direct clarifications and latest Figma not indexed | Add source rows; do not mislabel the Codex session as a meeting |
| `DECISION_LOG.md` | Does not contain removal of the standalone E-Invoice Correction/separate Inventory Reconciliation operations, current API numbering, shared STO flow, two ageing definitions or FIFO clarification | Add source-backed decisions; keep SAP implementation questions open |
| `OPEN_QUESTIONS.md` Q-063 | Still describes twelve slots/API-12 | Close the duplicate-slot question; replace with the remaining physical-variance-posting question |
| `OPEN_QUESTIONS.md` Q-028/Q-015 | FIFO business behavior marked unresolved | Resolve business ordering rule; retain determination owner/date-field/SAP config as open |
| `OPEN_QUESTIONS.md` Q-031 | STO predecessor broadly unresolved | Record stock-transport PO as business predecessor; keep exact SAP type/API/BAPI and Create PO ownership open |
| `PROJECT_BRAIN.md` C-16 | Says expanded 10/12-API workbooks | Reframe: formal seven-operation baseline vs current API-01..10 working catalogue plus candidate API-11 |
| `PROJECT_BRAIN.md` C-10 | 1000/1300 conflict | Preserve until system/config owner validates organizational binding |
| `DOMAIN_GLOSSARY.md` | STO deferred/FIFO disputed/ageing conflated or incomplete | Define Trade, Non-trade, STO; DI; Order Ageing; Stock Ageing; FIFO with ownership caveat |
| `SYSTEM_OF_RECORD_MATRIX.md` | Physical reconciliation/API-12 and FIFO model lag | API-04 is sole stock read; variance posting remains open; separate order vs stock ageing |
| `HANDOVER_AI.md` | Header/register ranges/workbook version stale | Update to current v1.7 path, user-authoritative API-01..11 numbering and today's validation gates |
| `ONBOARDING_AI.md` | Says STO deferred and workbook has twelve APIs | Replace with three-flow model and current retained catalogue; preserve MRN conflict |
| `README.md` | Navigation points to files moved into `_archive/` | Align read order to `AGENTS.md`; link this session delta until fully promoted |
| `SAP_API_DOSSIER.md` | Older access/status and proposed catalogue | Keep system-observed defect/source findings; mark superseded proposals explicitly |
| `outputs/.../v1.7.xlsx` | API-02/API-04 DMG/STG conflict and C-10 organizational mapping remain; API-08 and candidate API-11 are current | Resolve only with owner/system evidence; continue editing v1.7 in place and render every changed sheet |

## Decisions that can be promoted now

- DI/outbound delivery terminology.
- Three business flows: Trade, Non-trade, STO.
- STO business predecessor is a stock-transport PO; post-DI journey is shared.
- Standalone E-Invoice Correction operation removed; current API-08 is E-Way Bill Extension.
- Separate Inventory Reconciliation operation removed; API-04 is the sole stock/physical-inventory read.
- Current v1.7 numbering is API-01..API-11; API-11 Create STO Purchase Order is candidate pending formal MM/architecture approval.
- Two distinct ageing concepts.
- FIFO as the outbound business ordering rule.
- Division 10 = Cement.
- E-Way management list and extension action are separate concerns.
- API-08 eligibility is only the eight hours immediately before expiry, with no after-expiry window; success adds exactly 24 hours. Duration remains fixed and is not a request field.

## Items that must remain open

- Pending-MRN lifecycle, expansion and returned identifier (`C-14`).
- API-01 source/ownership (`C-15`).
- DMG/STG persistence and actual SAP posting behavior.
- Exact STO PO document type, Create PO ownership, BAPI/OData operation and idempotency.
- Physical inventory variance posting, FI impact, approval and audit store.
- API-05 calculation ownership and contract.
- API-06 LUWs, failure recovery, stage polling/read semantics and DDIC mappings.
- API-07 cancel/regenerate behavior.
- API-08 provider payload, reason-code mapping, eligible caller and error mapping. The pre-expiry-only window and fixed 24-hour result are confirmed.
- `1000`/`1300` organizational-field conflict.
- Incoterm active allowlist vs KDS configured values.
- FIFO determination owner and authoritative ageing/date field.

## Archive/delete review candidates for tomorrow

Review these only after canonical promotion:

- older API workbooks under `outputs/cnf_api_contract_v13` through `v16*` — retain as provenance or move under `_archive/outputs`, do not present as current;
- `deliverables/API_SPECIFICATION_PROPOSAL.md` — contains older API structures;
- `deliverables/SHREE_CNF_SAP_API_DOCUMENTATION_PRE_DEV_V2.md` and `.docx` — contains superseded statutory/API assumptions;
- `PROJECT_CONTEXT.md` — duplicates newer onboarding/brain content;
- stale temporary builders and preview artifacts under `tmp/` after the final workbook is safely saved and verified;
- Excel lock files such as `~$...` only after confirming Excel has closed them and they are not active.

Never delete `sources/` evidence or `_archive/` provenance merely because its conclusions were superseded.
