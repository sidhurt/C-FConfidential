# Project Context

## Program

The project is building a C&F Agent Operations Interface for Shree Cement. The product spans operational workflows performed by C&F/depot users and connects a Commerce/Hybris tenant, SAP Integration Suite (CPI), SAP S/4HANA, and SAP Datasphere.

The business has experienced analysts, managers, and functional consultants defining scenarios and exceptions. The technical landscape is multi-team and the precise responsibility boundaries are evolving.

## Siddharth's objective

Become a dependable SAP backend integration contributor who converts approved workflows into:

- correct S/4HANA source analysis;
- reusable ABAP classes;
- SEGW/OData V2 services where appropriate;
- correctly selected and validated BAPIs or released SAP APIs;
- stable CPI-facing request, response, and error contracts;
- observable, idempotent, testable transactional behavior;
- clear traceability from requirement to SAP document and downstream data.

AI is intended to serve as project memory, analysis support, drafting support, and—only after explicit approval—a bounded test/inspection assistant.

## Known landscape

| Claim | Confidence | Basis |
|---|---|---|
| Commerce/Hybris Tenant 1 is an operational consumer/source | Verified from conversation context | Architecture discussions |
| CPI is the orchestration and message movement layer | Verified from conversation context | Architecture and team structure |
| S/4HANA contains transactional business truth | Strong inference | Architecture and described workflows |
| Datasphere contains replicated, modeled, or analytical data used by the product | Verified from conversation context | Existing access and BRD summary |
| Siddharth and another ABAP developer form part of the SAP backend team | Verified from conversation context | Team description |
| A CPI consultant and a Basis consultant exist | Verified from conversation context | Team description |
| A proposed `ZCNF_AGENT_SRV` and `ZCNF_*` object set exists in a technical document | Supported, not system-verified | Prior document summary |
| No matching CNF objects were found in the currently inspected Quality client | Observed, limited scope | Manual SE80/SEGW search |
| The API build may be greenfield or not yet transported | Strong inference | Proposed naming plus absence in QAS |

## Candidate business capabilities

The BRD summary indicates these capabilities may be in program scope:

- pending/partial goods receipt and MIGO confirmation;
- secondary sales-order fulfilment;
- Delivery Instruction creation and modification;
- stock and FIFO batch visibility;
- shipment, shipment cost, PGI, billing, E-Way Bill, and e-Invoice flow;
- invoice/e-document correction and retry;
- intra-warehouse or stock-transfer flow;
- document-flow status and document retrieval;
- physical inventory reconciliation;
- cancellation-request workflow;
- operational and historical reports.

These are candidate program capabilities, not approved ABAP assignments.

## Important distinctions

- C&F Agent refers to the business user/operational portal, not an autonomous AI agent.
- SAP GUI is an engineering and diagnostic surface, not a runtime integration hop.
- Operational commands should use S/4HANA truth.
- Datasphere is normally an analytical/replicated source and should not be assumed current enough for transactional decisions.
- CPI should orchestrate and transform messages; SAP business validity remains in S/4/ABAP or standard configuration.
- A technical design document is not proof that an object exists or that a proposed BAPI is correct.

## 28 July meeting update

The design walkthrough verified the intended operational spine from Order to DI, storage-location/batch determination, shipment/freight, PGI, billing, and e-documents. It also exposed a material SD/MM/KDS knowledge-transfer gap. Correct payload mapping now explicitly depends on understanding client codes, master data, document types, Incoterms, and SAP treatment—not merely matching similarly named fields.

See `PROJECT_BRAIN.md` and `meetings/2026-07-28-design-walkthrough.md`.

## Source material to ingest

When available in the approved workspace, attach and index:

1. Business Requirements Document (BRD).
2. SAP ABAP/OData technical specification.
3. CPI interface workbook.
4. Architecture diagrams.
5. Datasphere model/export inventory.
6. Meeting notes and transcripts.
7. Approved payload samples with sensitive data masked where required.
8. System observations from DEV/QAS.

Record each source in `MEETING_INGEST.md` and connect resulting claims to the registers.

## Non-goals

- Frontend/UI implementation.
- Silent ownership of iFlows, Datasphere modeling, Basis configuration, or functional decisions.
- Autonomous SAP changes.
- Treating AI suggestions as verified SAP behavior.
- Exporting client data or credentials to unapproved AI services.
