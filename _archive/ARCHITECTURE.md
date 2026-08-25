# Architecture

## Working topology

```text
Commerce / C&F portal
          │
          │ operational requests and responses
          ▼
SAP Integration Suite (CPI)
        ┌─┴─────────────────┐
        │                   │
        ▼                   ▼
SAP Gateway / S/4HANA   SAP Datasphere
        │                   │
        ▼                   └─ analytical/modelled reads
ABAP classes / BAPIs
        │
        ▼
SAP documents, tables, CDS views, logs
```

This topology is a working model. Exact Gateway placement, connection routes, and Datasphere consumption mechanisms require validation.

## Operational command path

Use for current validation and state-changing processes:

```text
Commerce → CPI → OData/API → ABAP application service
         → released API/BAPI/configuration → S/4 document
         → stable response → CPI → Commerce
```

Examples: MIGO, delivery creation/change, PGI, invoice creation/correction.

S/4HANA is the expected authority for:

- current document status;
- business validity;
- locks and authorization;
- posting and commit;
- authoritative document numbers;
- duplicate prevention.

## Analytical observation path

Use for historical, consolidated, ageing, or report-oriented data:

```text
S/4 sources → replication/federation → Datasphere models
           → approved service/consumer → CPI/Commerce
```

Examples: inventory ageing, historical billing, aggregated depot performance.

Datasphere should not be placed in a synchronous SAP commit path unless an approved architecture explicitly requires it.

## Boundary principles

### Commerce

- Owns portal/user experience and Commerce-native representations.
- May own aliases, depot-facing labels, or operational input fields.
- Must not define SAP business validity.

### CPI

- Owns connection, routing, transformation, orchestration, and middleware monitoring.
- Generates or propagates correlation/request IDs.
- Defines transport retry behavior jointly with ABAP.
- Must not become the hidden home of core SAP business rules.

### S/4HANA / ABAP

- Owns SAP source selection and business-document execution.
- Exposes stable APIs and errors.
- Persists external request IDs when required for idempotency.
- Produces authoritative document keys and application logs.

### Datasphere

- Owns analytical model semantics, transformations, grain, refresh, and exposure.
- Must publish source lineage and latency.
- Is not assumed to be transactionally current.

### Basis/security

- Owns system connectivity, service activation policy, certificates, roles, destinations, transports, and scripting configuration.

## Required architecture decisions per interface

1. Business operation or query?
2. Authoritative system for each field?
3. Real-time or analytical latency acceptable?
4. Standard SAP API available?
5. Custom CDS or SEGW service required?
6. Synchronous or asynchronous?
7. Retry and idempotency design?
8. Correlation and application logging?
9. Authentication and authorization boundary?
10. Failure ownership and support route?

## Unverified topology items

- S/4 release and component levels.
- Embedded versus hub Gateway.
- DEV/QAS/PRD clients and transport route.
- Direct CPI-to-Datasphere protocol.
- Whether Commerce calls CPI exclusively.
- Whether E-Way Bill/GSP is called by CPI or ABAP.
- Exact source of downloadable invoice/e-document files.

