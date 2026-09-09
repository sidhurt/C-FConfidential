# Shree Cement C&F Agent Interface

> **SUPERSEDED IMPLEMENTATION BASELINE — retained for traceability.** This pre-access proposal predates the unrestricted 2,626-project SEGW catalogue and completed Tier-A deep dives. Its business/process analysis remains evidence; its `ZCNF_*` service recommendations do not. Use `CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md` for the current standard-first solution.

## SAP API Documentation and Pre-Development Proposal

**Document ID:** CNF-SAP-API-DOC-002  
**Version:** 2.0  
**Date:** 30 July 2026  
**Audience:** Shree Cement SAP, Integration, Commerce, Datasphere, Basis, Security, Tax and functional teams  
**Owner:** SAP backend integration workstream  
**Status:** PRE-DEV WORKING DOCUMENT - NOT AN APPROVED BUILD SPECIFICATION

> This document consolidates the API material received to date, meeting intelligence, the five latest delivery artifacts, and the repository registers available when it was written. Development-system access was pending at that time. All SAP object names, BAPIs, released APIs, CDS views, DDIC fields, service names, payload fields and effort estimates in this dated document remain subject to later system evidence and owner approval.

# 1. Executive summary

The latest delivery package defines ten business-facing API capabilities for the SAP workstream. Five are estimated as predominantly standard SAP operations, two as custom composite reads over standard SAP data, two as new construction or orchestration, and two have a delivery route that depends on whether SAP Document Compliance for India is licensed and configured. These categories overlap for conditional APIs and must not be read as ten mutually exclusive counts.

SAP Integration Suite is now represented as part of the runtime path between Commerce Cloud and S/4HANA. S/4HANA remains authoritative for goods receipt, delivery, goods issue, shipment, shipment cost and billing documents. Commerce T1 serves selected portal views, Commerce T2 owns several portal master-data concepts, and Datasphere owns or serves STO, MRN, plant-storage-location and ageing information. The statutory portal is authoritative for IRN and E-Way Bill issuance, with results persisted in S/4HANA.

The ten-API list is a business-capability view. It does not automatically supersede the repository's 24-interface discovery register or the 31-endpoint technical decomposition in `SAP_API_DOSSIER.md`. Those models use different levels of granularity and require an owner-approved mapping before one becomes the canonical implementation backlog.

The largest pre-access risks are:

- availability of released APIs and CDS views in the actual S/4HANA release;
- availability and configuration of SAP Document Compliance for India;
- ownership of outbound statutory calls and credentials between Integration Suite and ABAP;
- the synchronous versus staged design of invoice creation;
- the sales-order versus stock-transport-order delivery predecessor;
- the master-data dictionary and Commerce-to-SAP organisational mapping;
- idempotency, correlation, logging and stable error contracts;
- the scope of Modify DI and the fields editable before goods issue.

Indicative SAP effort is 97-144 person-days if Document Compliance is available, plus 20-25 person-days if bespoke statutory integration is required. This is an engineering range for sequencing, not a committed schedule. It excludes functional analysis, CPI work, end-to-end test cycles and defect resolution.

# 2. Evidence basis and confidence

## 2.1 Sources consumed

| Source ID | Artifact | Evidence class | Use in this document |
|---|---|---|---|
| SRC-DEL-001 | `CNF_API_CLASSIFICATION.pdf` | Derived technical proposal | API classification, candidate SAP mechanisms and pre-access caveats |
| SRC-DEL-002 | `CNF_API_Classification.xlsx` | Derived technical register | Ten-API inventory and standard-versus-custom rationale |
| SRC-DEL-003 | `CNF_Delivery_Planning.xlsx` | Derived planning register | Business rules, effort, validations, assumptions and source-of-record model |
| SRC-DEL-004 | `API_SPECIFICATION_PROPOSAL.md` | Derived proposal summary | Latest architecture changes, API catalogue and requested next steps |
| SRC-DEL-005 | `API_SPECIFICATION_PROPOSAL.pdf` | Derived full proposal | Detailed API behaviour, service decomposition, NFRs and validation plan |
| SRC-MTG-20260728-01..04 | Four design-walkthrough transcripts/translations | Meeting evidence, originals not present in this copy | Workflow, terminology, decisions, risks and open questions |
| SRC-MTG-20260728-SUM | Consolidated meeting summary | Derived meeting evidence | Cross-session reconciliation |
| SRC-SID-20260729-01 | Direct clarification that DI means delivery | Direct stakeholder statement | Terminology and delivery-object interpretation |
| SRC-PROJ-001 | `SAP_API_DOSSIER.md` | Repository technical analysis | Defect findings, 31-endpoint decomposition and known contradictions |

## 2.2 Evidence limitations

- DEV, QAS and PRD access has not been granted to this workstream.
- Exact S/4HANA product release, component levels, installed business functions and Gateway topology are unverified.
- No released-API or released-CDS inspection has been completed in the target landscape.
- The four original recordings and their source transcript files are not present in this repository copy; the meeting note is therefore second-hand for re-adjudication.
- The client process-register extract and landscape diagram cited by the latest proposal are not attached as primary sources in this repository copy.
- The BRD and CPI interface workbook remain pending as approved originals.
- No proposed object, contract or estimate in this document is authorization to create or change anything in SAP.

## 2.3 Evidence classification

**Newly verified from the supplied package**

- The package contains five internally consistent delivery artifacts dated 29-30 July 2026.
- The package describes Integration Suite in the Commerce-to-S/4 runtime path.
- The package contains a ten-API business catalogue, a 29-item validation register and an indicative effort model.
- The spreadsheets and PDFs are readable and internally usable as planning artifacts.

**Supported but not landscape-verified**

- Candidate standard BAPIs, released services and document-compliance routes.
- Proposed service decomposition and payload fields.
- S/4 document-flow and orchestration assumptions.
- Source-of-record claims that rely on a client landscape diagram not attached here.

**Contradictory or unresolved**

- Ten business APIs versus 24 interface requirements versus 31 technical endpoints.
- Meeting decision D-005 permits only open DI quantity editing, while API-10 also discusses batch reallocation and vehicle substitution.
- API-03 proposes atomic delivery creation plus logistics attributes, while standard vehicle/driver ownership may sit on shipment or a separate extension.
- Earlier architecture notes left exclusive Commerce-to-CPI routing open; the latest package marks Integration Suite in-path as confirmed.
- The Markdown summary says the validation register has 25 items in one section, while the latest workbook contains 29 items.
- The Markdown summary references `CNF_API_Register.xlsx` with eight sheets, but the supplied companion workbooks are `CNF_API_Classification.xlsx` and `CNF_Delivery_Planning.xlsx`, with nine sheets in total.

# 3. Latest cross-system architecture

## 3.1 Runtime path

The proposed runtime is:

Commerce Cloud -> SAP Integration Suite -> SAP Gateway/API layer -> ABAP application services -> released SAP APIs, BAPIs and approved query models.

Responses travel back through Integration Suite to Commerce. Correlation, retry and external-contract transformation must be agreed across layers. Integration Suite being in the path does not yet answer whether CPI or ABAP owns calls to statutory/GSP services.

## 3.2 Source-of-record model

| Concept | Authoritative or serving system | Currency | SAP API consequence |
|---|---|---|---|
| Goods receipt, delivery, goods issue, shipment, shipment cost, billing document | S/4HANA | Real time | SAP creates, validates, locks and numbers these documents |
| Stock and batch availability | S/4HANA | Real time | Posting decisions must not use replicated snapshots |
| IRN and E-Way Bill | Statutory portal; result persisted in S/4HANA | Real time | Verify Document Compliance and outbound-call ownership |
| Portal pending orders, deliveries and invoice-billing views | Commerce T1, pushed from SAP through CPI | Flow-dependent | API-01 is narrower than a general portal dashboard read |
| Invoice download | Commerce T1; CRM portal fallback | Not stated | Do not assume SAP API is the primary file-download route |
| Depot, user, agent-depot, geography, material alias, Incoterms, storage location, depot-SL and SL-SPI | Commerce T2 | Commerce-maintained | Define and own mapping to SAP organisational values |
| Vehicle master and transporter | Commerce T2 and Datasphere | Duplicated; DSP daily | Resolve authoritative value and posting payload |
| STO and MRN | Datasphere | Near real time | SAP returns material-document keys; it must not fabricate MRN |
| Plant-SL and ageing report | Datasphere | Daily | Analytical/reference reads are outside real-time SAP availability |

## 3.3 Boundary principles

- Commerce owns the user experience; frontend ownership is not assigned by this document.
- Integration Suite owns transport-level integration only to the extent confirmed by architecture owners.
- S/4HANA owns transactional validity and document posting for SAP documents.
- Datasphere is not a substitute for real-time SAP stock or posting validation.
- Portal-owned master values require an explicit mapping contract before SAP payloads can be frozen.
- Statutory credentials must never be placed in application tables.

# 4. API classification framework

**S - Standard-oriented:** a released SAP API, BAPI or delivered service performs the core business operation. A thin wrapper may still be needed for contract stability, authorization, correlation and error mapping.

**C - Custom over standard:** no single standard interface provides the required business answer, but it can be composed from standard document flow, released views or approved tables without creating a new business transaction.

**X - New construction:** the capability requires orchestration state, simulation logic, resumability, external coordination or another application service not delivered as a single standard SAP operation.

Classification is about the core business mechanism, not total implementation effort. Every production API still needs security, logging, idempotency where applicable, stable errors and integration testing.

# 5. Proposed SAP API portfolio

| ID | Capability | Mode | Pre-access class | Proposed SAP service |
|---|---|---|---|---|
| API-01 | Check MIGO / receipt position | Read | C | `ZCNF_RECEIPT_SRV` |
| API-02 | Submit MIGO | Command | S | `ZCNF_RECEIPT_SRV` |
| API-03 | Create DI / outbound delivery | Command | S | `ZCNF_DELIVERY_SRV` |
| API-04 | Stock and batch availability | Read | C | `ZCNF_STOCK_SRV` |
| API-05 | Shipment cost estimate or actual | Read/simulation | X for estimate; S for actual | `ZCNF_DISPATCH_SRV` |
| API-06 | Invoice creation orchestration | Command/status | X | `ZCNF_BILLING_SRV` |
| API-07 | Invoice correction or reversal | Command | S | `ZCNF_BILLING_SRV` |
| API-08 | E-Invoice correction | Command | S if Document Compliance is available; otherwise X | `ZCNF_EDOC_SRV` |
| API-09 | E-Way Bill extension | Command | S if Document Compliance supports it; otherwise X | `ZCNF_EDOC_SRV` |
| API-10 | Modify DI | Command | S | `ZCNF_DELIVERY_SRV` |

The `ZCNF_*` service names are placeholders. Package, namespace, protocol version, service split and public resource names require development-standards approval.

# 6. Common contract requirements

## 6.1 Request envelope

Each command should carry:

- an external request ID that is unique in the agreed retention window;
- a correlation ID propagated end to end;
- the calling business identity and authorised organisational scope;
- an explicit contract version;
- document keys and item keys with SAP leading-zero handling defined;
- quantities and amounts as decimal values with UOM or currency;
- dates and times in agreed ISO formats and timezone;
- optional client reference fields only when an owner and purpose are defined.

## 6.2 Response envelope

Responses should contain:

- outcome status;
- SAP document keys actually created or read;
- stage and document-flow status where the process is multi-step;
- stable machine-readable error code;
- user-safe message and technical correlation ID;
- retryability indicator where useful;
- warnings separated from blocking errors;
- no fabricated business identifiers.

## 6.3 Idempotency

Every command that can post or change a business document must be safely replayable. The external request ID must map to the original result. If the same ID arrives with a different payload, return a conflict and do not post. Where standard APIs do not support external idempotency directly, an approved persistence and locking design is required.

## 6.4 Transactions

- API-02 and API-03 should be atomic for their defined SAP transaction scope.
- API-06 spans multiple SAP units of work and external/statutory actions; it must expose partial progress and safe resume.
- No design may commit a standard SAP document and then silently fail a separate custom-table write.
- Rollback and compensation behaviour must be explicit for every stage.

## 6.5 Error handling

The landscape must agree one error schema and HTTP mapping. At minimum distinguish:

- malformed request;
- unauthorised or forbidden organisational scope;
- business validation failure;
- duplicate or conflicting request;
- not found;
- lock or temporary unavailability;
- completed-with-warning;
- partial orchestration state;
- non-retryable statutory rejection.

## 6.6 Security and audit

- Use standard SAP authorisation objects wherever available.
- Enforce plant, sales-area, depot and storage-location scope server-side.
- Audit request ID, correlation ID, caller, action, timestamps, document keys and before/after values for regulated changes.
- Keep secrets and statutory credentials in approved secure stores.
- Mask personal data and sensitive statutory payloads in operational logs.

# 7. Detailed API proposals

## API-01 - Check MIGO / receipt position

**Purpose:** Return the SAP-side receipt position for a referenced inbound business document. This is not the general Commerce pending-order dashboard API.

**Candidate class:** C - composite read.

**Candidate inputs**

- plant, mandatory;
- posting or document date range, mandatory and bounded;
- reference document and item, optional;
- status filter, optional;
- pagination and sort fields.

**Candidate outputs**

- reference document and item;
- material, plant and storage location;
- ordered or expected quantity;
- posted quantity and pending quantity;
- UOM;
- receipt status: Pending, Partial or Complete;
- related SAP material-document keys.

**Rules**

- pending quantity is derived, never stored or fabricated for convenience;
- partial receipts remain visible until fully received;
- MRN is not generated by this API;
- use approved document flow and quantity semantics;
- define date basis and reversal handling.

**Primary validations:** V-01, V-05, V-09, V-12 and V-27.

## API-02 - Submit MIGO

**Purpose:** Post a goods receipt and return the authoritative SAP material-document key.

**Candidate class:** S - standard posting with integration wrapper.

**Candidate SAP mechanisms:** `BAPI_GOODSMVT_CREATE` or a permitted released material-document API, subject to release inspection.

**Candidate inputs**

- reference document and item;
- posting date and document date;
- plant and storage location;
- material, quantity and UOM;
- batch where required;
- challan or external reference where approved;
- external request ID and correlation ID.

**Candidate outputs**

- material document number and fiscal year;
- posting status and warnings;
- correlation ID.

**Rules**

- validate quantities, UOM, batch, plant and storage location before posting;
- no partial commit within the API transaction;
- safe duplicate replay is mandatory;
- reverse or error documents must not be counted as successful receipt;
- do not create an `MRN-<material document>` value; MRN is a Datasphere-owned concept in the latest source model.

**Primary validations:** V-01, V-05, V-09, V-12, V-20, V-21 and V-27.

## API-03 - Create DI / outbound delivery

**Purpose:** Create the outbound delivery represented by “DI” in the C&F process.

**Candidate class:** S - standard delivery creation with approved extension logic.

**Candidate SAP mechanisms:** released outbound-delivery API or the appropriate sales-order/STO delivery BAPI. Selection depends on V-05.

**Candidate inputs**

- predecessor document and item;
- shipping point and requested dates;
- one storage location for the delivery scope;
- material, quantity, UOM and batch allocations if creation-time batch entry is approved;
- vehicle, driver and transporter only if the SAP document ownership is confirmed;
- external request ID and correlation ID.

**Candidate outputs**

- outbound-delivery number;
- created items and quantities;
- document status and warnings.

**Rules**

- DI means outbound delivery; DI number means delivery number;
- one DI/invoice uses one storage location;
- multiple batches may be used within that storage location;
- batch quantities must sum exactly to DI quantity;
- driver mobile is mandatory when documents are sent by SMS;
- stock, route and freight blocking behaviour remains a functional decision;
- logistics attributes must not be placed in an ungoverned custom table;
- if vehicle/driver belong to shipment, delivery creation must not pretend otherwise.

**Primary validations:** V-01, V-05, V-07, V-08, V-11, V-12, V-21, V-26 and V-27.

## API-04 - Stock and batch availability

**Purpose:** Return real-time SAP stock and batch information suitable for a dispatch allocation decision.

**Candidate class:** C - composite read over standard stock, batch and approved allocation logic.

**Candidate inputs**

- plant and material, mandatory;
- storage location and batch, optional;
- stock semantic, mandatory after V-07;
- requested quantity and UOM, optional;
- bounded result size and pagination.

**Candidate outputs**

- plant, storage location, material and batch;
- unrestricted, quality-inspection and blocked quantities as approved;
- allocatable quantity under the chosen semantic;
- manufacture and expiry dates where maintained;
- UOM and point-in-time timestamp;
- proposed issue sequence with reason.

**Rules**

- serve real-time transactional SAP data, not a replicated Datasphere snapshot;
- do not label unrestricted stock as ATP unless it is actually the availability-check result;
- proposed FIFO based on manufacture date requires an owner and configuration validation;
- show blocked and quality stock separately;
- do not reserve stock unless reservation is explicitly added to scope;
- proposed p95 response target is two seconds and requires performance validation.

**Primary validations:** V-01, V-07, V-08, V-12, V-21 and V-27.

## API-05 - Shipment cost

**Purpose:** Return either a non-binding pre-document estimate or the actual cost from an existing shipment-cost document.

**Candidate class:** X for ESTIMATE mode; S for ACTUAL mode.

**Candidate inputs**

- mode: ESTIMATE or ACTUAL;
- route, transporter, distance and relevant pricing inputs for estimate;
- shipment or shipment-cost document key for actual;
- currency and pricing date where applicable.

**Candidate outputs**

- estimated or actual amount and currency;
- rate/condition provenance where permitted;
- “no valid rate” as an explicit business outcome;
- estimate timestamp and non-binding indicator.

**Rules**

- do not create and reverse a productive document merely to calculate an estimate;
- prefer approved pricing or condition simulation;
- never return zero when no valid rate exists;
- the estimate must be labelled non-binding;
- actual cost must be read from the authoritative SAP document;
- classic shipment and shipment-costing use is not yet verified.

**Primary validations:** V-01, V-04, V-06, V-10, V-12 and V-26.

## API-06 - Invoice creation orchestration

**Purpose:** Coordinate the dispatch-to-invoice journey and expose progress, identifiers and recoverable failure states.

**Candidate class:** X - application orchestration.

**Proposed stages**

1. Post goods issue.
2. Create or update shipment.
3. Create shipment-cost document.
4. Create billing document.
5. Generate or obtain e-Invoice/IRN.
6. Generate or obtain E-Way Bill.

**Candidate inputs**

- outbound delivery and items;
- batch allocation and final quantity;
- shipment, route, transporter, vehicle and driver data as approved;
- billing and statutory context;
- external process request ID and correlation ID.

**Candidate outputs**

- process ID;
- overall state;
- per-stage state and timestamps;
- SAP document-flow keys;
- statutory identifiers and status where available;
- retryable/non-retryable error details.

**Rules**

- treat stages as separate units of work unless V-04 proves otherwise;
- use process-level and stage-level idempotency;
- resume from the last safe state and never repeat a completed posting;
- preserve partial completion visibly;
- keep original SAP and statutory rejection details in approved logs;
- provide a separate status read even if the initial command waits synchronously;
- do not promise immediate completion until the interaction model is approved.

**Primary validations:** V-01, V-02, V-03, V-04, V-06, V-12, V-14, V-18, V-19, V-20, V-22, V-24, V-26, V-27, V-28 and V-29.

## API-07 - Invoice correction or reversal

**Purpose:** Execute an approved billing correction or reversal path while preserving the original audit trail and statutory constraints.

**Candidate class:** S - standard billing documents with statutory guard logic.

**Candidate SAP mechanisms:** invoice correction request/document flow or billing cancellation BAPI, subject to the functional scenario.

**Candidate inputs**

- original billing document;
- action type: correction or reversal;
- approved reason code;
- changed values allowed by the selected process;
- external request ID and correlation ID.

**Candidate outputs**

- correction, reversal or replacement document key;
- relationship to the original billing document;
- accounting and statutory follow-on status;
- warnings and blocking reasons.

**Rules**

- correction and reversal are different business actions;
- a correction creates a new controlled document; it does not rewrite the original;
- determine IRN and E-Way Bill eligibility before billing change;
- preserve document flow and audit;
- do not conflate billing correction with E-Invoice correction.

**Primary validations:** V-01, V-12, V-14, V-20 and V-22.

## API-08 - E-Invoice correction

**Purpose:** Apply the permitted statutory remediation path for an invoice with an issued IRN.

**Candidate class:** S when SAP Document Compliance supports the required India flow; X if bespoke statutory integration and state storage are required.

**Proposed branches**

- before IRN generation: correct the underlying business document through the approved SAP process;
- within the statutory cancellation window: cancel IRN and reissue as permitted;
- outside the cancellation window: use the approved credit/debit-note or business correction route;
- when an active E-Way Bill blocks action: resolve the statutory dependency first.

**Rules**

- an issued IRN is not amended in place;
- calculate eligibility server-side using the authoritative timestamp;
- capture statutory reason, caller, previous state and new state;
- prevent duplicate cancellation or reissue;
- keep statutory-call credentials outside application tables.

**Primary validations:** V-02, V-03, V-14, V-22, V-24 and V-28.

## API-09 - E-Way Bill extension

**Purpose:** Extend an eligible E-Way Bill using current vehicle location and an approved reason.

**Candidate class:** S if delivered Document Compliance functionality is available; X for a custom CPI/ABAP statutory route.

**Candidate inputs**

- E-Way Bill number;
- current vehicle location, state and PIN code;
- approved extension reason and remarks;
- current vehicle details where required by the statutory contract;
- external request ID and correlation ID.

**Candidate outputs**

- prior and extended validity;
- statutory acknowledgement/status;
- audit reference and correlation ID.

**Rules**

- transport mode is Road only;
- each approved extension is 24 hours;
- repeated extensions are allowed only when statutory eligibility is satisfied;
- vehicle change is Part B update, not extension;
- validate the active E-Way Bill and server time;
- preserve the statutory response and audit history.

**Primary validations:** V-02, V-03, V-13, V-14 and V-20.

## API-10 - Modify DI

**Purpose:** Change an open outbound delivery before goods issue.

**Candidate class:** S - standard delivery change.

**Candidate SAP mechanism:** `BAPI_OUTB_DELIVERY_CHANGE` or a permitted released delivery-change API.

**Candidate inputs**

- outbound-delivery number and item;
- revised quantity;
- batch reallocation or logistics attributes only if explicitly approved;
- change reason;
- external request ID and correlation ID.

**Candidate outputs**

- delivery and item status;
- revised quantities;
- warnings and rejected fields.

**Rules**

- reject changes after goods issue or another approved lock status;
- meeting decision D-005 currently supports only open DI quantity editing before batch determination;
- the broader proposal for batch reallocation and vehicle substitution is not approved;
- enforce one storage location and exact batch-total rules if those fields enter scope;
- preserve before/after audit.

**Primary validations:** V-05, V-11, V-20, V-25, V-26 and V-27.

# 8. Service and ABAP layering proposal

## 8.1 Candidate service groups

- `ZCNF_RECEIPT_SRV`: API-01 and API-02.
- `ZCNF_DELIVERY_SRV`: API-03 and API-10.
- `ZCNF_STOCK_SRV`: API-04.
- `ZCNF_DISPATCH_SRV`: API-05.
- `ZCNF_BILLING_SRV`: API-06 and API-07.
- `ZCNF_EDOC_SRV`: API-08 and API-09.

## 8.2 Internal layering

Gateway or released-service adapter -> contract mapper -> application service -> validator -> standard-API wrapper/query provider -> SAP standard object.

Gateway classes should remain thin. Business rules, idempotency, locking, document-flow composition and orchestration belong in testable application services. Standard APIs should be wrapped behind small interfaces so an API/BAPI choice can change after release inspection without changing the external contract.

## 8.3 Shared components

- request/correlation context;
- idempotency store and lock manager;
- stable error builder;
- application log integration;
- authorisation checks;
- quantity, UOM, date and key normalisation;
- document-flow reader;
- statutory-call abstraction;
- contract-version compatibility layer.

# 9. Indicative effort and sequencing

| Item | Class | Low days | High days | Note |
|---|---|---:|---:|---|
| Cross-cutting foundations | - | 15 | 20 | Idempotency, correlation, logging, errors, authorisation and type discipline |
| API-01 Check MIGO | C | 8 | 12 | Composite read |
| API-02 Submit MIGO | S | 5 | 8 | Standard posting plus integration safeguards |
| API-03 Create DI | S | 6 | 10 | Standard creation plus approved logistics fields |
| API-04 Stock Availability | C | 8 | 12 | Composite real-time read |
| API-05 Shipment Cost | X/S | 12 | 18 | Estimate is new construction |
| API-06 Invoice Creation | X | 25 | 35 | Highest-risk orchestration |
| API-07 Invoice Correction | S | 5 | 8 | Standard document path plus statutory guards |
| API-08 E-Invoice Correction | S | 6 | 10 | Assumes Document Compliance |
| API-09 E-Way Bill Extension | S | 3 | 5 | Assumes Document Compliance |
| API-10 Modify DI | S | 4 | 6 | Proposed addition |
| **Total with Document Compliance** |  | **97** | **144** | Excludes functional, CPI and testing cycles |
| **Contingency without Document Compliance** | X | **+20** | **+25** | Bespoke API-08/API-09 statutory route |

Recommended sequence after access:

1. Verify release, components, topology, standards and Document Compliance.
2. Confirm source-of-record and mapping ownership.
3. Build shared contract, error, logging, security and idempotency foundations.
4. Start low-risk reads: API-04 and the narrowed API-01.
5. Build isolated document commands: API-02, API-03 and approved API-10.
6. Validate and implement API-05 simulation/actual modes.
7. Implement billing correction and statutory routes.
8. Build API-06 only after its state model and ownership are approved.

# 10. Development-access validation register

## 10.1 Critical decisions before contract freeze

| Ref | Decision or inspection | Owner | Main impact |
|---|---|---|---|
| V-01 | Exact backend release, components, released APIs and CDS views | Basis / ABAP | All ten APIs |
| V-02 | Document Compliance India licence, installation and configured actions | Basis / Tax | API-06, API-08, API-09 and largest effort swing |
| V-03 | CPI versus ABAP ownership of statutory calls and credentials | Architect | Statutory services and security |
| V-04 | Synchronous command versus staged invoice process | SD / Architect | API-06 and API-05 |
| V-05 | Sales order versus STO predecessor by scenario | SD | API-01, API-03 and API-10 |
| V-12 | Master/reference dictionary and derivation rules | SD / Business master data | Every payload |
| V-15 | DEV/QAS/PRD clients and transport route | Basis | Delivery governance |
| V-16 | Embedded versus hub Gateway topology | Basis | All services |
| V-27 | Commerce-to-SAP code mapping and execution owner | Architect / SD / Commerce | API-01..06 and API-10 |

## 10.2 High-priority functional and architecture validations

- V-06 transport solution in use.
- V-07 operational definition of available stock.
- V-08 batch issue-sequence ownership.
- V-09 material-document-to-MRN linkage.
- V-10 freight simulation feasibility.
- V-11 editable delivery fields and status limits.
- V-14 IRN cancellation window and E-Way linkage.
- V-17 package, namespace, exception and transport conventions.
- V-18 error schema and HTTP mapping.
- V-19 correlation and logging standard.
- V-20 external request-ID persistence by document type.
- V-26 transporter and vehicle authority.
- V-29 SAP-to-Commerce T1 triggers and latency.

## 10.3 Remaining validations

- V-13 E-Way extension reason codes.
- V-21 batch-management and shelf-life applicability.
- V-22 portal invoice identifier by process stage.
- V-23 authorisation objects and depot/plant role scoping.
- V-24 invoice and statutory output-document storage/retrieval.
- V-25 whether Modify DI is in scope.
- V-28 authoritative e-Invoice status for portal reads.

# 11. Meeting intelligence incorporated

## 11.1 Decisions retained

- Use “Order Quantity” and “DI Quantity”.
- DI means outbound delivery.
- One DI/invoice uses one storage location; multiple batches may be permitted within it.
- Batch quantities must equal DI quantity.
- E-Way extension uses Road mode, current location and reason, and extends by 24 hours.
- E-Way Part B remains editable during validity for vehicle change.
- Only open DI quantity is currently approved as editable, before batch determination.
- FleetX is the proposed source of the vehicle tracking link; no SAP posting is assumed by default.

## 11.2 Requirements retained

- Pending and partial receipt positions must be visible.
- Transporter search by code or name is needed.
- Freight estimate is shown for validation and must not silently default to zero.
- Driver mobile is mandatory for SMS document delivery.
- Document flow must show the status and identifiers of PGI, shipment, shipment cost, billing, E-Way Bill and e-Invoice.
- Statutory correction must distinguish E-Way Part A, Part B and extension.

## 11.3 Still-open meeting questions

- stock insufficiency and missing freight/route blocking;
- storage-location selection timing and downstream lock;
- FIFO/current SAP batch behaviour;
- FTP and EX-works pickup-code treatment;
- exact invoice/ODN/accounting identifiers;
- synchronous versus asynchronous orchestration;
- download source and error-display ownership.

# 12. Reconciliation with repository registers

## 12.1 API and interface ID mapping

| Latest API | Closest current IF IDs | Reconciliation note |
|---|---|---|
| API-01 | IF-001 | Narrow SAP receipt-position read; not Commerce pending-order view |
| API-02 | IF-002 | Direct alignment |
| API-03 | IF-003 | Predecessor and logistics-field ownership open |
| API-04 | IF-005, IF-016 | Combines stock read and batch proposal |
| API-05 | IF-018 | Estimate and actual modes need separate contracts internally |
| API-06 | IF-006, IF-009, IF-019, IF-020 | One business capability decomposes into commands/statuses |
| API-07 | IF-008, IF-012 | Billing correction/reversal requires scenario split |
| API-08 | IF-008, IF-021 and statutory status | Do not conflate billing and IRN correction |
| API-09 | IF-007, IF-023 | Extension only; Part B vehicle update remains separate |
| API-10 | IF-004, IF-015 | Proposed addition; currently quantity-only decision |

IF-010, IF-011, IF-013, IF-014, IF-017, IF-022 and IF-024 remain visible requirements or cross-system interfaces outside the ten business APIs. The 31 `A-*` endpoints in `SAP_API_DOSSIER.md` are a finer technical decomposition and should be mapped, not discarded.

## 12.2 Affected registers

The following registers need an owner-approved update after this document is reviewed:

- `MEETING_INGEST.md`: add the five supplied artifacts with unique source IDs and correct duplicate `SRC-TECH-001`.
- `PROJECT_BRAIN.md`: mark DI terminology and Integration Suite runtime evidence at the right confidence.
- `ARCHITECTURE.md`: replace the stale “whether Commerce calls CPI exclusively” wording with the confirmed in-path statement while keeping external statutory ownership open.
- `SYSTEM_OF_RECORD_MATRIX.md`: add Commerce T1/T2 and Datasphere ownership claims with provenance and unresolved duplication.
- `INTERFACE_REGISTER.md`: add explicit API-01..API-10 mappings without deleting broader IF requirements.
- `REQUIREMENTS_MATRIX.md`: distinguish business capabilities from technical endpoint decomposition.
- `OPEN_QUESTIONS.md`: map Q-items to V-01..V-29 and close only those backed by authorised evidence.
- `DECISION_LOG.md`: record only owner-approved decisions, never engineering assumptions.
- `CONFLICT_REGISTER.md`: log DI-edit scope, vehicle/driver document ownership, API-count granularity and metadata drift.

No register is updated by this document alone.

# 13. Highest-impact missing decisions

1. **Landscape fact set:** release, components, Document Compliance, Gateway topology, authorisation model and transport route.
2. **Invoice interaction model:** synchronous request, staged process or hybrid with status polling.
3. **Statutory ownership:** CPI or ABAP for outbound calls, credentials, retries and persistence.
4. **Delivery model:** sales order versus STO and the exact SAP home for vehicle, driver and transporter.
5. **Master-data contract:** authoritative codes and Commerce-to-SAP mapping owner.
6. **Stock and batch semantics:** unrestricted versus ATP versus batch-eligible; SAP versus portal sequencing.
7. **Modify DI scope:** quantity-only decision versus proposed additional editable fields.
8. **External idempotency design:** storage, lock, retention and replay behaviour for every command.
9. **Canonical backlog:** ten business APIs, 24 interfaces and 31 endpoints mapped into one governed model.

# 14. Bounded pre-access plan

## Before DEV access

- Freeze no SAP object names or DDIC fields.
- Obtain the approved BRD, CPI workbook, client API register and landscape diagram.
- Assign source IDs and reconcile contradictions.
- Schedule owner sessions for V-03, V-04, V-05, V-12, V-25, V-26, V-27 and V-29.
- Draft contract examples only as non-binding samples.
- Agree acceptance evidence for each validation.

## First two days after DEV access

- capture system status and component levels;
- inspect Document Compliance and transport solution;
- confirm Gateway topology and service-registration process;
- verify batch management, shelf life and authorisation objects;
- locate approved package, namespace, message and exception conventions;
- record findings against V-01, V-02, V-06, V-15, V-16, V-21 and V-23.

## First two weeks after access

- trace successful trade, non-trade, FTP, EX-works and STO examples;
- validate candidate released APIs/BAPIs and CDS views;
- agree the master-data dictionary and mapping ownership;
- prove one read contract and one safely idempotent command;
- decide the API-06 state machine before build;
- reclassify APIs and narrow the effort estimate;
- publish the verified specification for approval.

# Appendix A - Non-functional acceptance checklist

- Every command is idempotent and concurrency-safe.
- Correlation ID is visible across Commerce, CPI and SAP logs.
- No API fabricates MRN, IRN, E-Way Bill or other business identifiers.
- All quantity, amount, UOM, currency, key and time fields have explicit types.
- Read APIs are filtered, paginated and performance-tested.
- Authorisation is enforced in SAP, not trusted from the caller.
- Errors use stable codes and agreed HTTP status mapping.
- Multi-stage processes expose partial state and safe resume.
- Standard SAP application logging is used where suitable.
- Secrets are held in approved secure stores.
- Reversals and corrections preserve document flow and audit.
- Payload changes follow an approved versioning policy.
- Tests cover duplicate retry, locks, partial completion, authorisation and negative business cases.

# Appendix B - Document-control notes

This v2.0 reconstruction replaces the missing local pre-development documentation files only as a consolidated working artifact. It does not replace the five supplied source artifacts, the meeting record, the interface register or the technical dossier. The Markdown proposal's internal references to an eight-sheet `CNF_API_Register.xlsx` and a 25-item validation register are recorded as metadata drift; the delivered planning workbook's 29-item register is used here.

Approval is required before any SAP build, configuration, transport, external statutory call or production-facing action.
