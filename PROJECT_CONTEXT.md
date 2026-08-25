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

AI is intended to serve as project memory, analysis support, and drafting support before approval. After Siddharth gives an unambiguous, target-specific instruction, AI becomes a bounded execution assistant and should use available authorized access for the approved SAP inspection, test, or change. QAS and PRD writes require separate explicit authority.

## Known landscape

| Claim | Confidence | Basis |
|---|---|---|
| Commerce/Hybris Tenant 1 is an operational consumer/source | Verified from conversation context | Architecture discussions |
| CPI is the orchestration and message movement layer | Verified from conversation context | Architecture and team structure |
| S/4HANA contains transactional business truth | Strong inference | Architecture and described workflows |
| Datasphere contains replicated, modeled, or analytical data used by the product | Verified from conversation context | Existing access and BRD summary |
| Siddharth and another ABAP developer form part of the SAP backend team | Verified from conversation context | Team description |
| A CPI consultant and a Basis consultant exist | Verified from conversation context | Team description |
| QS4 exposes 2,626 SAP SEGW design-time projects in the unrestricted Open Project catalogue | Verified system observation | `SRC-SYS-20260815-01` catalogue export |
| Gateway registration is a separate runtime fact: the normalized local catalogue contains 522 registered services, not 2,626 callable endpoints | Verified system observation | `SRC-SYS-20260805-02` and Tier-A findings |
| The leading released integration candidates are `API_MATERIAL_DOCUMENT`, `API_OUTBOUND_DELIVERY_0002`, `API_BILLING_DOCUMENT`, `API_PURCHASEORDER_PROCESS`, and `API_MATERIAL_STOCK` | Verified design-time fit; runtime unproven | `sessions/2026-08-15-standard-api-discovery/` |
| The five released services above are not registered in the observed QS4 Gateway catalogue | Verified local runtime-catalogue observation | `CNF_STANDARD_API_MATRIX.tsv` |
| `MMIM_MATDOC_SRV` and `SD_CUSTOMER_INVOICES_CREATE` are registered, but registration alone does not prove callability or integration suitability | Verified registration; runtime unproven | Tier-A deep dives |
| The prior proposed `ZCNF_AGENT_SRV` / `ZCNF_*` portfolio is a historical technical proposal, not the current build plan | Superseded implementation assumption | 2026-08-15 standard-first pivot |

## Current implementation posture

Use standard SAP services for the covered document operations, activate and prove them in DEV, and build only the residual behavior that the standard contracts cannot supply. The residual work is material: CPI/T2 idempotency and error shaping, multi-stage dispatch orchestration, client configuration mapping, stock-ageing source correction, statutory commands, and a shipment-calculation endpoint if the existing `BAPI_SHIPMENT_COST_ESTIMATE` path is validated and no approved OData surface exists.

“Project exists in SEGW,” “service is registered,” “`$metadata` returns,” and “business transaction succeeded” are four different evidence levels. Only the last two support a Monday runtime claim.

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
