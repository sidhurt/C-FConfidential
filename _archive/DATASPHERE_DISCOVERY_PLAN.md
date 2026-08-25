# Datasphere Discovery Plan

## Objective

Determine which product data should come from Datasphere, its business meaning, lineage, grain, refresh latency, and approved way of reaching CPI. Do not “scrape everything.”

## Permission and access boundary

- Use approved Datasphere access and export/API mechanisms.
- Confirm whether browser automation or scripted metadata extraction is permitted.
- Do not harvest row-level business data merely to build context.
- Prefer metadata, lineage, definitions, sample schemas, and aggregate validation.
- Keep credentials/session state outside AI prompts and repositories.

## Discovery order

### 1. Space and ownership inventory

For relevant spaces record:

- space name and owner;
- business domain;
- connected source systems;
- development/deployment state;
- consumers and security.

### 2. Object catalogue

Search business terms:

- order, pending, credit;
- DI/delivery;
- stock, batch, ageing;
- STO/in-transit;
- shipment, transporter, vehicle;
- MIGO/MRN/material document;
- invoice/billing;
- E-Way Bill/e-Invoice;
- warehouse/depot/plant/storage location.

For each object record:

- technical and business name;
- object type;
- source lineage;
- input/output grain;
- key fields;
- measures and calculated dimensions;
- filters;
- refresh mode/frequency;
- last successful load;
- consumers.

### 3. Field lineage

Map:

```text
Datasphere output field
→ transformation/calculation
→ source remote/replicated object
→ S/4 CDS/table/field
→ business definition
```

### 4. Suitability decision

Classify each need:

- `S4_CURRENT` — current operational validation or command.
- `DSP_ANALYTICAL` — historical, aggregated, or pre-modeled.
- `HYBRID_RECONCILED` — both sources with explicit latency/reconciliation.
- `UNKNOWN` — insufficient evidence.

### 5. Exposure to CPI

With Datasphere/CPI owners, establish:

- approved protocol/API/SQL exposure;
- authentication;
- filters and pagination;
- expected volume;
- caching;
- latency SLA;
- error ownership;
- contract versioning.

## High-priority meeting-derived candidates

| Candidate | Likely role | Required validation |
|---|---|---|
| Historical order/report data | Datasphere | Retention and grain |
| Inventory ageing | Datasphere | Calculation and source |
| Billed quantity | Datasphere or S/4 | Freshness requirement |
| STO in transit | Datasphere or S/4 | Current status need |
| Available stock | S/4 likely for transactions | Physical/ATP definition |
| Document history | Datasphere for reporting | Source keys and latency |

## Deliverable

Recreate `DATASPHERE_SOURCES.md` (archived 2026-07-30 as empty scaffolding — DS-001..DS-008 were all Hypothesis/TBD; recreate from `templates/` once real discovery starts) and update `SYSTEM_OF_RECORD_MATRIX.md`. No Datasphere object becomes an API source until its owner, lineage, grain, freshness, and access contract are verified.

