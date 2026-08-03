# Project Brain

## One-sentence model

The C&F Agent Interface is a new operational application over Shree Cement's existing SAP dispatch processes: Commerce presents the user journey, CPI moves and coordinates messages, S/4HANA validates and creates authoritative business documents, and Datasphere supplies selected analytical or historical views.

## What the 28 July meeting established

The project is not a generic data-extraction exercise. The application is attempting to reproduce and simplify a connected SD/MM/warehouse flow:

```text
Order
  → Delivery Instruction (DI)
  → storage-location and batch determination
  → transporter and freight
  → PGI + shipment + shipment cost + billing
  → e-Invoice + E-Way Bill
  → document status/download
  → correction or extension
```

Goods receipt/MIGO, warehouse-to-warehouse movement, physical inventory reconciliation, dashboards, and reports sit around this dispatch spine.

The essential SAP task is therefore:

> Understand the Shree Cement meaning of every process, code, master-data field, and document relationship; then expose only the approved SAP operations and data through reliable CPI-facing APIs.

## The real technical problem

The portal screen contains fields. A field cannot be mapped correctly until the team knows:

- what the business term means at Shree Cement;
- which SAP object/field represents it;
- whether it is user input, derived, or configuration/master data;
- which process state permits it;
- which system owns it;
- which validations and accounting/logistics consequences follow.

The side conversation exposed a serious knowledge-transfer gap. Senior business participants expect the technical team to understand Shree Cement's KDS/master-data vocabulary, SD treatment, trade/non-trade differences, product families, Incoterms, order/STO processes, and SAP field derivation. A BAPI will not repair a semantically wrong payload.

## Current evidence map

### Verified from the 28 July meeting

- SAP remains the authoritative system that generates the invoice.
- The new application presents and initiates existing SAP-backed processes.
- Invoice work begins from an open DI.
- The proposed flow uses one storage location per DI/invoice, with multiple batches allowed inside that location.
- Batch quantities must sum to the DI quantity before further processing.
- Only the DI quantity is intended to be editable after DI creation, while the DI is still open.
- Transporter selection, freight estimation, shipment details, PGI, shipment, shipment cost, invoice, E-Way Bill, and e-Invoice are part of the desired invoice journey.
- E-Way Bill Part B must remain editable within validity for vehicle changes.
- E-Way Bill extension uses the vehicle's current location and reason, stays in Road mode, and extends by 24 hours.
- FleetX is the proposed source of the live vehicle tracking link.
- Open business questions remain around stock/freight checks at DI creation, FIFO behavior, pickup code, invoice identifiers, and document errors.

### Strong inferences

- The ABAP work will include more query/status services than the original six-interface proposal suggested.
- “Generate Invoice” is probably a multi-step orchestration rather than a single atomic BAPI call.
- DI is closely related to a delivery but its exact SAP object semantics are still unverified.
- Current transactional reads should normally come from S/4; dashboard/history/ageing may come from Datasphere.
- A shared semantic/KDS dictionary is a prerequisite for dependable mappings.

### Hypotheses requiring validation

- DI maps one-to-one to an SAP outbound delivery.
- “SPI” is the correct acronym and maps to a specific SAP shipping/storage concept.
- SAP currently proposes batches by largest quantity rather than FIFO.
- Commerce retains 60 days of operational history.
- The invoice workflow can run synchronously end to end.

## Project domains

| Domain | Questions the brain must answer |
|---|---|
| Order | SO/STO/PO type, credit status, open quantity, customer, source plant |
| DI | SAP object, creation API, edit rules, storage-location relationship |
| Stock | physical vs ATP, plant/sloc/batch grain, blocked/unrestricted |
| Batch | eligibility, FIFO/quantity ranking, manual reallocation |
| Freight | route, rate, SPI, transporter, Incoterm, estimated shipment cost |
| Shipment | shipment object, vehicle/driver/LR-GR, FleetX relationship |
| PGI | trigger, status, material document, retry and reversal |
| Billing | billing API, invoice identifiers, accounting treatment, output |
| E-documents | IRN, acknowledgement, E-Way Bill, correction, extension, files |
| Receipt | partial GR, storage-location split, pending quantity, MRN |
| Analytics | dashboard/history/ageing objects and latency |
| Master/KDS | code meanings, derivations, system of record, valid combinations |

## Knowledge graph

The project brain should represent these node types:

- Requirement
- BusinessTerm
- BusinessRule
- ProcessStep
- System
- Team/Owner
- MasterDataCode
- SAPDocument
- SAPField
- Table/CDS/API
- ABAPObject
- ODataInterface
- CPIFlow
- DatasphereObject
- Decision
- Question
- Test
- Incident
- EvidenceSource

Important relationships:

```text
Requirement REQUIRES ProcessStep
ProcessStep CREATES SAPDocument
ProcessStep READS BusinessTerm
BusinessTerm REPRESENTED_BY SAPField
SAPField SOURCED_FROM Table/CDS/API
MasterDataCode MEANS BusinessTerm
ODataInterface IMPLEMENTED_BY ABAPObject
ABAPObject CALLS SAPAPI
CPIFlow CONSUMES ODataInterface
DatasphereObject DERIVED_FROM SAP source
Decision RESOLVES Question
EvidenceSource SUPPORTS Claim
Test VERIFIES Requirement
```

Every node or relationship carries evidence, confidence, owner, environment, and validation date.

## Definition of an implementation-ready interface

An interface is ready only when the brain can answer:

1. What business outcome is required?
2. What SAP document/process represents it?
3. Which fields are input, derived, and output?
4. What does each code mean?
5. Which system owns each value?
6. Which released API/BAPI/query is correct?
7. What statuses and exceptions are valid?
8. What does CPI send, retry, and correlate?
9. How does SAP prevent duplicates and log the request?
10. How is success proven in SAP and, where relevant, Datasphere?

## Immediate strategy

The first workstream is not mass extraction. It is controlled semantic discovery:

1. obtain SD/MM/KDS knowledge transfer and historical process recordings;
2. trace representative SAP document chains;
3. inventory relevant Datasphere models and lineage;
4. build the glossary and system-of-record matrix;
5. select one formally assigned vertical slice;
6. validate the standard SAP API;
7. agree one CPI contract;
8. implement and prove it end to end.

