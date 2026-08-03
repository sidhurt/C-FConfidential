# Role Boundaries

## Siddharth / ABAP team — primary ownership

- Interpret approved functional workflow on the SAP side.
- Identify S/4 system of record, tables, CDS entities, and document relationships.
- Prefer released standard APIs; validate BAPIs before adoption.
- Design and implement ABAP application/service classes.
- Build or extend SEGW/OData V2 services when approved.
- Implement SAP-side validation, authorization checks, error mapping, logging, and idempotency.
- Own commit/rollback policy within the SAP unit of work.
- Unit-test backend behavior and provide CPI-consumable contracts.
- Diagnose Gateway and ABAP runtime failures.
- Explain the authoritative SAP document/result to downstream teams.

## Shared ownership

| Concern | ABAP | CPI | Functional | Datasphere | Basis | Commerce |
|---|---|---|---|---|---|---|
| Business rule | Implements | Aware | Decides/signs off | Aware | — | Supplies use case |
| Request/response schema | SAP semantics | Mapping/transport | Meaning | Analytical fields | Connectivity | Consumer semantics |
| Retry | Idempotency | Retry policy | Business outcome | — | Timeouts | User experience |
| Correlation | Persist/log | Generate/propagate | — | Reconciliation | Trace support | Return/display |
| Errors | Business/API contract | Route/transform | User-safe meaning | Data-quality errors | Connection errors | Presentation |
| End-to-end test | SAP evidence | Middleware evidence | Acceptance | Analytical reconciliation | Environment | Consumer validation |

## Other teams — primary ownership

### CPI consultant/team

- iFlows, adapters, routes, transformations, credentials/destinations within CPI.
- Message monitoring and middleware retry policy.
- Propagation of correlation IDs.
- External REST orchestration unless architecture assigns it elsewhere.

### SD/MM and other functional consultants

- Business process, document model, customizing expectations, exceptions, and acceptance criteria.
- Approval of SO/STO/PO/delivery/MIGO/billing semantics.
- Definition of “available stock,” “pending,” “DI,” “MRN,” and correction/cancellation behavior.

### Datasphere team

- Spaces, connections, remote/replicated objects, views, transformations, analytic models, refresh jobs, and consumption exposure.
- Source lineage, grain, latency, reconciliation, and report semantics.

### Basis/security

- Landscape, system aliases, RFC/HTTP destinations, ICF/service activation, certificates, roles, developer access, transports, and approved SAP GUI scripting.

### Commerce/Hybris

- Portal behavior, Commerce data model, user identity, frontend validation, and Commerce-side APIs.

### UI/UX and business analysis

- User journey, presentation behavior, BRD stewardship, process scenarios, and business acceptance.

## Explicitly out of Siddharth's default scope

- Frontend/UI implementation.
- Native iFlow construction unless explicitly assigned.
- Datasphere model construction unless explicitly assigned.
- Basis parameter or role changes.
- Functional sign-off.
- External tax/GSP credential ownership.
- Production postings or destructive actions.

## Boundary rule

Collaborate across every boundary, but do not silently accept ownership. Record unresolved ownership in `OPEN_QUESTIONS.md` and decisions in `DECISION_LOG.md`.

