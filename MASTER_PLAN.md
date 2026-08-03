# SAP-Side Master Plan

## Outcome

Deliver correct, supportable SAP and Datasphere interfaces to CPI while building a durable evidence-backed understanding of Shree Cement's SD/MM/warehouse processes.

## Phase 1 — Establish authority and access

- Obtain formal assignment, DEV access, landscape/topology, package/transport standards.
- Confirm approved use of external AI, meeting transcripts, Datasphere automation, and SAP GUI scripting.
- Identify functional decision owners for SD, MM, FI/tax, logistics, Datasphere, CPI, and Basis.

**Exit:** documented authority, environments, owners, and allowed tooling.

## Phase 2 — Repair the knowledge-transfer gap

- Obtain old trade, non-trade, STO, and related process recordings.
- Arrange KT with Harish or the named SD/MM owners.
- Build `DOMAIN_GLOSSARY.md`, especially KDS codes, organizational codes, material groups, Incoterms, route/freight, and document types.
- Confirm the exact SAP meaning of DI, SPI, MRN, ODN, GD/GDF, TP/DTP, and RD.

**Exit:** approved process vocabulary and code dictionary sufficient to map fields.

## Phase 3 — Map representative document chains

In approved systems, manually trace:

1. Order → DI.
2. DI → storage location/batches.
3. DI → shipment/freight/PGI/billing/accounting.
4. Billing → e-Invoice/E-Way Bill/output.
5. Partial receipt/MIGO.
6. STO/warehouse transfer.

Record documents, statuses, fields, enhancements, logs, and source objects.

**Exit:** evidence-backed process maps, not inferred table lists.

## Phase 4 — Catalogue Datasphere

- Inventory relevant spaces and models.
- Trace source lineage, grain, keys, transformations, and refresh.
- Classify each requirement as S/4-current, Datasphere-analytical, hybrid, or unknown.
- Agree the approved Datasphere-to-CPI consumption pattern.

**Exit:** `DATASPHERE_SOURCES.md` (recreate from `templates/` — archived 2026-07-30 as unstarted scaffolding) and system-of-record matrix verified by owners.

## Phase 5 — Decompose interfaces

Do not build one “all SAP data” API. Define bounded capabilities:

- pending orders;
- DI creation/edit;
- stock/batch proposal;
- transporter/freight validation;
- invoice-process command(s);
- process/document-flow status;
- e-document correction/extension;
- receipt/MIGO;
- analytical/dashboard reads.

For each, complete discovery, API design, BAPI validation, CPI contract, reliability, and tests.

**Exit:** implementation-ready interface dossiers.

## Phase 6 — Prove the shared SAP API pattern

Select the smallest formally assigned vertical slice. Prefer a read service first if it proves source, authorization, errors, pagination, CPI connectivity, and logging. Then implement one bounded write command.

Build shared foundations:

- thin `DPC_EXT`;
- application classes;
- API/BAPI wrappers;
- request/response mapping;
- business exceptions/error contract;
- correlation/application logging;
- idempotency repository;
- authorization;
- ABAP Unit/test doubles where practical.

**Exit:** one CPI-to-SAP flow proven end to end with evidence.

## Phase 7 — Expand by dependency order

Suggested order, subject to formal priorities:

1. Read/reference/master-data endpoints.
2. Pending order and DI status.
3. DI create/edit.
4. Stock/batch and freight validation.
5. MIGO/receipt or another bounded posting.
6. Shipment/PGI/billing staged orchestration.
7. E-document correction/extension.
8. Datasphere analytical reads.
9. Warehouse transfer and reconciliation.

**Exit:** signed-off interface set with regression evidence.

## Phase 8 — Operationalize the brain

- Ingest each meeting and incident.
- Link code and transports to requirements.
- Record CPI message/SAP document/Datasphere keys.
- Maintain runbooks and regression packs.
- Use approved automation for repeatable reads/tests.
- Periodically retire contradicted hypotheses and stale mappings.

**Exit:** the project no longer depends on tribal memory.

## First-week output once work begins

- One-page workflow approved by the functional owner.
- One representative document-chain evidence record.
- One completed interface-discovery dossier.
- One BAPI/released API validation result.
- One draft CPI contract.
- One prioritized list of unresolved decisions.

