# Repository operating guide

This repository is Siddharth's evidence-backed control plane for the SAP side of the Shree Cement C&F Agent programme.

## Start here

Read `CURRENT_STATE.md` before any older handover, workbook or discovery report. It is the current implementation-status authority. The v1.9 workbook defines the business API list and payload baseline, but later runtime and source evidence controls technical classification.

## Evidence discipline

- Label material claims as Verified, Strong inference, Hypothesis, Contradicted or Unknown.
- System observation and captured source outrank documents; controlled client documents outrank meeting reconstruction.
- A fact stated directly by Siddharth is logged with a `SRC-SID-*` source ID.
- Do not promote metadata, HTTP 200, allocated document numbers or BAPI success messages into persistence claims. Re-read the created document.
- Certification does not transfer between a transaction, BAPI and OData service. Trace the executed path and account for client enhancements on that path.

## Current technical posture

- Standard reads remain preferred when representative data is proven.
- Standard writes require runtime persistence plus enhancement-equivalence and replay testing.
- Submit MIGO uses the standard Material Document service only if the required delivery-led derivation and business rules can be implemented through supported enhancement points and proven end to end.
- Create DI is proven for the STO predecessor only. Trade and Non-trade remain separate certification cases.
- Pre-PGI, STO creation and billing creation require controlled external command boundaries around existing SAP logic.
- Statutory operations must reuse the installed eDocument/DigiGST route unless tracing proves no supported boundary exists.

## Safety

- Never commit passwords, cookies, authorization headers, CSRF tokens or populated credential files.
- Run one SAP GUI automation at a time and verify `SystemName` and `Client` before any scripted action.
- Do not execute business writes without an approved test case and explicit authorization.
- Keep personal notes, generated render directories and local recovery bundles out of Git.

## Repository structure

- `sources/` — primary supplied evidence
- `sessions/` — dated investigations and captured system evidence
- `deliverables/` — reviewed working/client artifacts
- `meetings/` — reconciled meeting intelligence
- `evidence/` — focused runtime proof
- `_archive/` — superseded material retained for traceability
