# SEGW / OData V2 Plan

## Purpose

Create stable SAP-facing APIs for CPI only after the business operation, ownership, and source data are verified. SEGW is one possible implementation mechanism; do not create a custom SEGW service when a suitable released SAP API already exists.

## Preferred layering

```text
OData V2 request
  → generated DPC_EXT method
  → mapper
  → application service class
  → domain validation / authorization
  → repository or BAPI wrapper
  → S/4 document or query
  → response mapper / OData exception
```

Generated classes remain thin. Business logic belongs in testable custom classes.

## Proposed shared components

Names are placeholders until the project namespace is approved.

- Application services by domain: receipt, delivery, stock, billing, document flow.
- Request/response mapper.
- BAPI/API wrapper interfaces.
- Business exception hierarchy.
- Standard error response builder.
- Application logging utility.
- External request/idempotency repository.
- Authorization service.
- Unit conversion and SAP key normalization utilities.

## Contract standards

### Keys and types

- Preserve leading zeros for SAP keys.
- Define decimal precision and unit for all quantities.
- Use explicit date/time and timezone rules.
- Do not expose internal types accidentally as public semantics.
- Use stable external field names and version consciously.

### Reads

- Mandatory filters for potentially large datasets.
- Server-side pagination and deterministic ordering.
- Explicit maximum page size.
- Delta only when a stable change timestamp/token exists.
- Avoid N+1 selects and unbounded document-flow traversal.

### Writes

- Require external request/correlation ID where retries are possible.
- Validate business preconditions before creating state.
- Acquire suitable locks.
- Store successful request/result association.
- Return the original successful result for a safe retry.
- Commit only after all SAP-side work succeeds.
- Do not hide partial completion.

### Errors

Return a stable structure containing:

- HTTP status;
- business error code;
- SAP message ID/number/type;
- safe message text;
- correlation ID;
- retryable flag;
- optional field/item context.

Do not return dumps, HTML error pages, credentials, tokens, or uncontrolled technical detail.

## Endpoint design questions

- Is an EntitySet operation semantically appropriate?
- Is a deep entity required?
- Is action-like behavior better represented by a POST command entity?
- Are PATCH semantics truly partial and supported?
- Is synchronous processing realistic?
- Does CPI need `$batch`, and if so, what are transaction boundaries?
- How will CSRF handling work?
- What is the service versioning policy?

## Implementation sequence

1. Receive approved workflow and acceptance criteria.
2. Verify system of record and SAP document chain.
3. Evaluate standard API before custom development.
4. Agree CPI contract and idempotency behavior.
5. Define DDIC/internal structures.
6. Implement/test application and wrapper classes independently.
7. Define SEGW model and generate runtime.
8. Implement thin `DPC_EXT` methods.
9. Unit and negative-test in DEV.
10. Register/activate through approved Basis/Gateway process.
11. Test `$metadata`, endpoint behavior, logs, retries, and authorization.
12. Joint CPI test.
13. Reconcile SAP document and Datasphere result if relevant.

## Evidence required

Every endpoint must link to:

- requirement ID;
- interface ID;
- approved schema;
- SAP API validation record;
- unit/negative tests;
- Gateway test evidence;
- CPI message/correlation evidence;
- resulting SAP document;
- downstream reconciliation evidence where applicable.

