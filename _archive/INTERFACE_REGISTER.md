> **SUPERSEDED — 2026-08-03. Do not use.**
> This numbering system has been retired. The current API inventory is `API-01`..`API-10` in
> `deliverables/CNF_API_Classification.xlsx`, aligned 1:1 with the client's own process register.
> See `_archive/README.md` for the full old-to-new mapping.
> Retained for provenance only.
# Interface Register

This is the canonical interface inventory. Create one detailed record from `templates/interface-discovery.md` for each approved interface.

Proposed endpoints, service decomposition, and build sequence for these IF-IDs are in `SAP_API_DOSSIER.md` Part C (API IDs `A-01`..`A-31`). The client-supplied specification `SRC-TECH-001` covers only IF-001, 002, 003, 004, 008 and 023; its defect register is `SAP_API_DOSSIER.md` Â§A.4.

| ID | Working name | Direction | Source â†’ target | Type | SAP handler | SAP API | CPI iFlow | State | Confidence |
|---|---|---|---|---|---|---|---|---|---|
| IF-001 | Check MIGO / pending receipt | Outbound read | S/4 â†’ CPI | OData V2 GET | TBD | Query/CDS TBD | TBD | Candidate | Supported |
| IF-002 | Submit MIGO | Inbound command | CPI â†’ S/4 | OData V2 POST | TBD | `BAPI_GOODSMVT_CREATE` candidate | TBD | Candidate | Supported |
| IF-003 | Create DI | Inbound command | CPI â†’ S/4 | OData V2 POST | TBD | Sales/STO delivery API TBD | TBD | Candidate | Hypothesis |
| IF-004 | Modify DI | Inbound command | CPI â†’ S/4 | OData V2 PATCH/PUT | TBD | `BAPI_OUTB_DELIVERY_CHANGE` candidate | TBD | Candidate | Hypothesis |
| IF-005 | Stock/batch availability | Outbound read | S/4 â†’ CPI | OData/query | TBD | Query/availability API TBD | TBD | Candidate | Supported |
| IF-006 | Invoice/PGI orchestration | Inbound command | CPI â†’ S/4 | API(s) TBD | TBD | Multiple APIs TBD | TBD | Clarification | Hypothesis |
| IF-007 | E-Way Bill extension/retry | Bidirectional | CPI â†” S/4/GSP | Orchestration TBD | TBD | No BAPI assumed | TBD | Clarification | Supported |
| IF-008 | Invoice/e-doc correction | Inbound command | CPI â†’ S/4 | POST/PATCH | TBD | TBD | TBD | Clarification | Supported |
| IF-009 | Document flow/status | Outbound read | S/4 â†’ CPI | OData V2 GET | TBD | Query/CDS TBD | TBD | Candidate | Supported |
| IF-010 | Datasphere analytical feed | Outbound read | Datasphere â†’ CPI | Native API/SQL TBD | N/A | N/A | TBD | Discovery | Verified concept |
| IF-011 | Inventory reconciliation | Mixed | Commerce/CPI â†” S/4/DSP | TBD | TBD | Physical inventory APIs TBD | TBD | Clarification | Hypothesis |
| IF-012 | Cancellation request | Inbound request | CPI â†’ workflow/S/4 | POST | TBD | No cancellation BAPI by default | TBD | Candidate | Supported |
| IF-013 | Pending order list | Outbound read | S/4/DSP â†’ CPI | OData or DSP-native | TBD | Query/CDS/model TBD | TBD | Discovery | Verified need |
| IF-014 | Open DI list/details | Outbound read | S/4 â†’ CPI | OData V2 GET | TBD | Query/CDS TBD | TBD | Discovery | Verified need |
| IF-015 | Edit open DI quantity | Inbound command | CPI â†’ S/4 | PATCH/POST TBD | TBD | Delivery/custom API TBD | TBD | Candidate | Verified need |
| IF-016 | Batch proposal | Outbound read | S/4 â†’ CPI | OData/query | TBD | Batch/stock logic TBD | TBD | Clarification | Verified need, rule unknown |
| IF-017 | Transporter lookup | Outbound read | S/4/master source â†’ CPI | OData/query | TBD | Master query TBD | TBD | Discovery | Verified need |
| IF-018 | Freight/route validation | Query/command | CPI â†” S/4 | API TBD | TBD | Pricing/shipment cost TBD | TBD | Clarification | Verified need |
| IF-019 | Invoice process command | Inbound orchestration | CPI â†’ S/4 | One or more commands TBD | TBD | PGI/shipment/billing APIs TBD | TBD | Clarification | Verified need |
| IF-020 | Process/document status | Outbound read | S/4/external status â†’ CPI | OData GET | TBD | Document flow/query TBD | TBD | Discovery | Verified need |
| IF-021 | E-Way Part A correction | Inbound command | CPI â†’ SAP/GSP | API TBD | TBD | External/e-doc API TBD | TBD | Clarification | Verified need |
| IF-022 | E-Way Part B vehicle update | Inbound command | CPI â†’ SAP/GSP | API TBD | TBD | External/e-doc API TBD | TBD | Clarification | Verified need |
| IF-023 | E-Way extension | Inbound command | CPI â†’ SAP/GSP | API TBD | TBD | External/e-doc API TBD | TBD | Candidate | Verified need |
| IF-024 | FleetX tracking link | Outbound/external | FleetX â†’ CPI/Commerce | REST/link TBD | N/A unless persisted | N/A | TBD | Discovery | Verified product decision |

## Required fields before implementation

- Signed-off business purpose and owner.
- Source/target systems and direction.
- Trigger, frequency, and sync/async behavior.
- Field-level system of record.
- SAP tables/CDS/API and Datasphere object if applicable.
- Filter, pagination, delta, time-zone, unit, and key rules.
- Request/response/error schemas.
- Authentication and authorization.
- Correlation, logging, retry, and idempotency.
- Test data, acceptance tests, and support ownership.
