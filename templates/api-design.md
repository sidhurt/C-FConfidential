# API Design — [Interface ID / Version]

## Business contract

- Purpose:
- Preconditions:
- Success outcome:
- Side effects:
- Non-goals:

## Endpoint

- Method/path:
- EntitySet/action pattern:
- Authentication/authorization:
- Sync/async:

## Request

| Field | Type/length | Required | Unit/format | Authority | SAP mapping |
|---|---|---:|---|---|---|

## Response

| Field | Type/length | Meaning | SAP source |
|---|---|---|---|

## Error contract

| Business code | HTTP | Meaning | Retryable |
|---|---:|---|---:|

## Processing sequence

## Class design

| Component | Responsibility |
|---|---|
| DPC_EXT method | Protocol mapping only |
| Application service | Use-case orchestration |
| Validator | Business preconditions |
| API/BAPI wrapper | SAP operation |
| Repository | Queries/idempotency |
| Logger | Correlation/application log |

## Transaction and reliability

- Locking:
- Commit/rollback:
- Idempotency key:
- Duplicate result behavior:
- Timeout reconciliation:

## Performance

- Filters/pagination:
- Expected volume:
- Query plan concerns:

## Approval and evidence

