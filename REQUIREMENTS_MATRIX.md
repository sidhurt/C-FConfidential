# Requirements Matrix

Status values: `Candidate`, `Clarification`, `Approved`, `Designing`, `Building`, `Testing`, `Done`, `Deferred`.

| ID | Capability | Likely authority | SAP-side responsibility | Likely interface | Status | Key uncertainty |
|---|---|---|---|---|---|---|
| R-001 | List pending/partial goods receipts | S/4 | Derive open receipt state and document flow | GET OData/query | Candidate | Exact predecessor: STO, PO, inbound/outbound delivery, or DI |
| R-002 | Confirm MIGO/GR | S/4 | Validate, post, commit, return material document | POST OData → class → SAP API | Candidate | Movement code/type and reference model |
| R-003 | List pending secondary orders | S/4 or Datasphere | Expose current open-order truth or analytical view | GET OData or Datasphere-native | Candidate | Required freshness and exact open quantity |
| R-004 | Create Delivery Instruction | S/4 | Validate source and create delivery/custom DI | POST OData → delivery service | Candidate | Is DI a delivery, custom object, SO-based, or STO-based? |
| R-005 | Modify Delivery Instruction | S/4 | Enforce allowed changes/status | PATCH/PUT OData | Candidate | Editable fields and cutoff status |
| R-006 | Stock/availability and FIFO batch proposal | S/4 | Define stock semantic and derive eligible batches | GET OData/query | Candidate | ATP vs physical stock; who owns FIFO |
| R-007 | Invoice orchestration | S/4 + CPI/GSP | Delivery/batch/PGI/shipment/billing SAP stages | Command API(s) | Clarification | One synchronous call or staged workflow |
| R-008 | Shipment and shipment cost | S/4 | Create/read shipment and costing documents | API/query | Candidate | LE-TRA/TM/custom process |
| R-009 | E-Way Bill/e-Invoice | CPI/GSP + S/4 | Validate SAP context and persist authoritative result | Orchestrated API | Clarification | CPI versus direct ABAP external call |
| R-010 | Correct e-document metadata/retry | S/4 + CPI/GSP | Update permitted attributes and retrigger | POST/PATCH | Candidate | Not necessarily billing correction |
| R-011 | Document-flow status | S/4 + CPI/GSP | Return related document keys/statuses | GET OData/query | Candidate | Ownership of external processing status |
| R-012 | Download invoice/e-documents | S/4/repository/GSP | Provide metadata/content only if SAP owns file | Media/API | Clarification | Actual storage technology |
| R-013 | Intra-warehouse transfer | S/4 | Support STO/PO → delivery → PGI → GR chain | Multiple APIs | Candidate | Exact document model |
| R-014 | Inventory ageing | Datasphere | Confirm SAP keys/source only | Datasphere-native read | Candidate | Model, grain, refresh |
| R-015 | Physical inventory reconciliation | Mixed | Current stock and possible difference posting | Query + workflow/API | Clarification | Portal-only review or SAP inventory posting |
| R-016 | Cancellation request | Workflow + S/4 | Validate document and status; avoid direct cancellation by default | POST request/query | Candidate | Approval workflow and executor |
| R-017 | Operational/historical reports | Datasphere/S/4 | Confirm real-time vs analytical source | Mixed | Candidate | Report catalogue and freshness |
| R-018 | Edit open DI quantity only | S/4 | Validate open status and change quantity | PATCH/POST OData | Candidate | Exact DI object/change API |
| R-019 | One storage location and multiple batches per DI | S/4 | Persist/enforce location and batch totals | Query + command | Approved rule | Selection timing at DI creation |
| R-020 | Transporter search | S/4/master source TBD | Search by code/name and return valid partner | GET OData/query | Candidate | Master and partner-function source |
| R-021 | Freight/route validation | S/4 | Validate maintained route/rate and estimate cost | Query/command | Clarification | DI-stage enforcement and SPI dependence |
| R-022 | Invoice-process status | S/4 + external e-doc status | Expose PGI/shipment/cost/billing/e-doc stages | GET OData | Candidate | Status sources and orchestration |
| R-023 | E-Way Part A correction | SAP/GSP via CPI TBD | Correct allowed transporter/distance values | POST/PATCH | Candidate | Ownership, eligibility and audit |
| R-024 | E-Way Part B update | SAP/GSP via CPI TBD | Change vehicle during validity | POST/PATCH | Approved rule | Exact external/SAP API |
| R-025 | E-Way extension | SAP/GSP via CPI TBD | Current location/reason; Road; 24 hours | POST | Approved rule | Exact external/SAP API |
| R-026 | Vehicle tracking | FleetX | Supply tracking link | External API/link | Candidate | Integration owner and persistence |
| R-027 | KDS/master dictionary | S/4/business governance | Explain/validate codes used by payloads | Metadata/knowledge asset | Required dependency | KT owner and source |

## Completion rule

No row advances to `Building` until:

- business owner approves intent and acceptance criteria;
- source system and field ownership are recorded;
- SAP document model is verified;
- interface owner and CPI consumer agree on contract;
- BAPI/API choice is validated in the actual release;
- error, logging, retry, and idempotency behavior are defined.
