# CPI-Facing Contracts

## Principle

CPI owns message movement and orchestration. ABAP owns the correctness of the SAP operation and authoritative SAP response.

## Contract dossier per interface

### Identity

- Interface ID and version.
- Business operation.
- Source/target and direction.
- CPI iFlow owner/name.
- SAP service/entity/method.

### Transport

- Protocol and endpoint path.
- Authentication mechanism.
- CSRF behavior.
- Sync/async.
- Timeout and size limits.
- Content type and encoding.

### Request

- Required and optional fields.
- Type, length, decimal, unit, timezone.
- SAP conversion exits/leading-zero rules.
- Field owner and transformation owner.
- External request/correlation ID.
- Example with synthetic data.

### Response

- Authoritative SAP document keys.
- Overall and item statuses.
- Warnings.
- Correlation ID.
- Stable error structure.

### Reliability

- Which errors may be retried?
- Maximum retries/backoff owned by CPI.
- How SAP detects an already successful request.
- What CPI does when SAP succeeds but the response is lost.
- Ordering and concurrency requirements.
- Reconciliation endpoint or procedure.

### Observability

Trace chain:

```text
Commerce request ID
→ CPI message ID
→ OData correlation ID
→ SAP application log
→ SAP document key
→ Datasphere business key
```

## Error classification

| Class | Example | HTTP | Retry? | Primary owner |
|---|---|---:|---|---|
| Schema | Missing required field | 400 | No | Commerce/CPI |
| Business validation | Quantity exceeds pending | 422 or approved 4xx | No until corrected | Functional/ABAP |
| Authorization | Plant/action denied | 403 | No | Basis/ABAP |
| Not found | Source document absent | 404 | Usually no | Source owner |
| Conflict | Duplicate/incompatible status | 409 | Reconcile | ABAP/CPI |
| Temporary SAP | Lock/temporary dependency | 503/approved | Possibly | ABAP/Basis |
| Middleware transport | Timeout/routing | N/A at SAP | Per policy | CPI |
| Unexpected defect | Dump/unhandled error | 500 | Controlled only | ABAP |

Use the project's approved status-code standard; do not invent inconsistent mappings per endpoint.

## Field ownership example

| External field | Meaning | Authority | CPI action | SAP field/derivation |
|---|---|---|---|---|
| `requestId` | Idempotency key | Calling system | Propagate unchanged | Persist/check |
| `depotCode` | Business depot | TBD | Map only if approved | Plant/storage mapping TBD |
| `materialAlias` | Commerce identifier | Commerce | Resolve or pass per design | MATNR mapping TBD |
| `quantity` | Requested quantity | Caller | Preserve precision/unit | Convert/validate |
| `deliveryStatus` | Current SAP status | S/4 | Pass through | Derive from document |

## Contract gate

No CPI build handoff until the ABAP and CPI owners agree on schema, key formats, timeout, retry, idempotency, error model, and sample test cases.

