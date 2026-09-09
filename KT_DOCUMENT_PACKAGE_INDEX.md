# Shree Cement C&F — Knowledge Transfer Document Package

Prepared from the latest project files present on 2026-09-07.

This is the curated KT set. Internal AI handovers, raw SAP extracts, temporary files, scripts, screenshots, duplicate renders, and superseded API-contract workbooks are excluded.

Read [`CURRENT_STATE.md`](CURRENT_STATE.md) first. It supersedes implementation-status claims in older technical plans and workbooks when later runtime or source evidence conflicts.

## 1. Start here: project and business context

- [Project Context](PROJECT_CONTEXT.md) — concise project scope and background.
- [Project Brain](PROJECT_BRAIN.md) — consolidated project knowledge.
- [Domain Glossary](DOMAIN_GLOSSARY.md) — project and SAP terminology.
- [System of Record Matrix](SYSTEM_OF_RECORD_MATRIX.md) — ownership and authoritative-source mapping.
- [CNF v1.8 Study Guide](deliverables/CNF_v1.8_STUDY_GUIDE.md) — detailed functional/process walkthrough.
- [CNF v1.8 Study Guide Reader](deliverables/CNF_v1.8_STUDY_GUIDE_READER.html) — browser-friendly version.

## 2. API portfolio and solution design

- [CNF API Request/Response Specification v1.9](deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx) — latest canonical API contract workbook.
- [Shree CNF SAP API Documentation Pre-Dev V2](deliverables/SHREE_CNF_SAP_API_DOCUMENTATION_PRE_DEV_V2.md) — consolidated pre-development API documentation.
- [Shree CNF SAP API Documentation Pre-Dev V2 (Word)](deliverables/SHREE_CNF_SAP_API_DOCUMENTATION_PRE_DEV_V2.docx) — shareable Word version.
- [API Specification Proposal](deliverables/API_SPECIFICATION_PROPOSAL.md) — proposed API structure and approach.
- [API Specification Proposal (PDF)](deliverables/API_SPECIFICATION_PROPOSAL.pdf) — shareable PDF version.
- [CNF API Classification](deliverables/CNF_API_Classification.xlsx) — API classification workbook.
- [CNF API Classification (PDF)](deliverables/CNF_API_CLASSIFICATION.pdf) — classification snapshot.
- [CNF Standard API Solution and Test Plan](deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md) — standard API choices and validation plan.
- [SAP API Dossier](SAP_API_DOSSIER.md) — detailed API research and findings.
- [Latest API Service Implementation Matrix](outputs/cnf-matrix-bapi-proof-20260825/CNF_API_Service_Implementation_Matrix.xlsx) — implementation status and proof mapping.

## 3. Submit MIGO and Create DI deep-dive

- [CNF Submit MIGO API Design](deliverables/CNF_SUBMIT_MIGO_API_DESIGN_2026-09-01.md) — proposed Submit MIGO contract and processing design.
- [CNF MIGO Customisation Disposition](deliverables/CNF_MIGO_CUSTOMISATION_DISPOSITION_2026-09-04.md) — latest customisation position and recommendation.
- [DI/MIGO ABAP Study Guide](deliverables/study-guides/DI_MIGO_ABAP_Study_Guide_2026-08-31.md) — technical learning and flow guide.
- [DI/MIGO ABAP Study Guide (Word)](deliverables/study-guides/DI_MIGO_ABAP_Study_Guide_2026-08-31.docx) — editable/shareable version.
- [DI/MIGO ABAP Study Guide (PDF)](output/pdf/DI_MIGO_ABAP_Study_Guide_2026-08-31.pdf) — final PDF version.
- [Z Program Reference — MIGO](deliverables/study-guides/Z_PROGRAM_REFERENCE_MIGO_2026-09-01.md) — custom-program reference.
- [BAPI Demo Candidates](deliverables/BAPI_DEMO_CANDIDATES_2026-08-25.md) — validated candidate shortlist.
- [Create DI SD Consultant Handoff](deliverables/CREATE_DI_SD_CONSULTANT_HANDOFF.md) — SD-specific Create DI transfer notes.
- [ZMM STO Auto Posting Payload](deliverables/ZMM_STO_AUTO_POSTING_PAYLOAD.md) — payload and field detail.

## 4. Pre-PGI knowledge pack

- [Pre-PGI Decision](deliverables/pre-pgi/PRE_PGI_DECISION.pdf) — final decision record.
- [Pre-PGI Stakeholder Brief](deliverables/pre-pgi/PRE_PGI_STAKEHOLDER_BRIEF.pdf) — concise stakeholder-facing explanation.
- [Pre-PGI Study Guide](deliverables/pre-pgi/PRE_PGI_STUDY_GUIDE.pdf) — detailed KT guide.
- [Pre-PGI Decision (HTML)](deliverables/pre-pgi/PRE_PGI_DECISION.html) — browser version.
- [Pre-PGI Stakeholder Brief (HTML)](deliverables/pre-pgi/PRE_PGI_STAKEHOLDER_BRIEF.html) — browser version.
- [Pre-PGI Study Guide (HTML)](deliverables/pre-pgi/PRE_PGI_STUDY_GUIDE.html) — browser version.

## 5. Testing, runtime proof, and execution

- [SAP Manual Verification Runbook](deliverables/SAP_MANUAL_VERIFICATION_RUNBOOK.md) — SAP-side verification procedure.
- [CNF SAP API Reference](deliverables/postman/CNF_SAP_API_REFERENCE.md) — endpoint reference for testers and developers.
- [cURL Runbook](deliverables/postman/CURL_RUNBOOK.md) — command-line test procedure.
- [Reviewed Postman Pack Readme](deliverables/postman/review-support/README.md) — current Postman-package usage guidance.
- [Live Demo Script](deliverables/LIVE_DEMO_SCRIPT.md) — guided demonstration sequence.
- [QS4 Create DI Postman Runtime Evidence](deliverables/QS4_CREATE_DI_POSTMAN_RUNTIME_EVIDENCE_2026-08-26.docx) — evidence of tested runtime behavior.
- [SAP Outbound Delivery Request/Response Workbook](deliverables/SAP_API_OUTBOUND_DELIVERY_SRV_Request_Response.xlsx) — service payload reference.
- [QS4 Submit MIGO Success Evidence](evidence/qs4-migo-2026-08-25/QS4_SUBMIT_MIGO_SUCCESS.md) — successful runtime case.
- [Route Constraints and Candidate Selection](evidence/qs4-migo-2026-08-25/ROUTE_CONSTRAINTS_AND_CANDIDATE_SELECTION.md) — candidate-selection limitations.
- [Create DI Sales-Order Inheritance Limitation](evidence/qs4-migo-2026-08-25/CREATE_DI_SALES_ORDER_INHERITANCE_NOT_TESTABLE.md) — documented test limitation.

## 6. Reviewed Postman assets

- [Reviewed CNF SAP/Create DI Collection](deliverables/postman/Postman%20collection%20-%20SubmitMIGO%20CreateDI%20-%20Reviewed/CNF_SAP.postman_collection%20createDI.json)
- [Reviewed CNF SAP/Create DI QS4 Environment](deliverables/postman/Postman%20collection%20-%20SubmitMIGO%20CreateDI%20-%20Reviewed/CNF_SAP_QS4.postman_environment%20createDI.json)
- [Reviewed Submit MIGO Collection](deliverables/postman/Postman%20collection%20-%20SubmitMIGO%20CreateDI%20-%20Reviewed/CNF_SubmitMIGO.postman_collection.json)
- [Reviewed Submit MIGO QS4 Environment](deliverables/postman/Postman%20collection%20-%20SubmitMIGO%20CreateDI%20-%20Reviewed/CNF_SubmitMIGO_QS4.postman_environment.json)
- [Reviewed Pack Readme](deliverables/postman/review-support/README.md)

## 7. Decisions, open items, and latest status

- [Decision Log](DECISION_LOG.md) — key project decisions and rationale.
- [Open Questions](OPEN_QUESTIONS.md) — unresolved points requiring ownership.
- [CNF Submit MIGO State of Things — 2026-09-04](deliverables/handover/CNF_SUBMIT_MIGO_STATE_OF_THINGS_2026-09-04.md) — latest concise status handover.
- [CNF Submit MIGO Status Brief — 2026-09-03](deliverables/handover/CNF_SUBMIT_MIGO_STATUS_BRIEF_2026-09-03.md) — preceding status brief.
- [Submit MIGO Build Process](deliverables/handover/LEGACY_SUBMIT_MIGO_BUILD_PROCESS_2026-09-02.md) — historical build and implementation sequence.
- [Submit MIGO BAdI Implementation Handover](deliverables/handover/CODEX_HANDOVER_SUBMIT_MIGO_BADI_IMPLEMENTATION_2026-09-02.md) — technical implementation state.
- [QS4 MIGO Test-Data Sweep Handover](deliverables/handover/CODEX_HANDOVER_QS4_MIGO_TESTDATA_SWEEP_2026-09-02.md) — test-data findings.
- [CNF Delivery Planning](deliverables/CNF_Delivery_Planning.xlsx) — delivery planning workbook.
- [CNF Timeline](deliverables/CNF_Timeline.xlsx) — project timeline.

## Recommended KT reading order

1. Project Context
2. CNF v1.8 Study Guide
3. CNF API Request/Response Specification v1.9
4. Shree CNF SAP API Documentation Pre-Dev V2
5. CNF Standard API Solution and Test Plan
6. Submit MIGO API Design and MIGO Customisation Disposition
7. DI/MIGO ABAP Study Guide
8. Pre-PGI Stakeholder Brief and Study Guide
9. SAP Manual Verification Runbook and reviewed Postman pack
10. Decision Log, Open Questions, and latest State of Things
