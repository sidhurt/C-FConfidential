# Meeting Intelligence — 28 July 2026

## Sources

- `SRC-MTG-20260728-01`: `Chaayos_3.hi.txt` / `Chaayos_3.en.md`
- `SRC-MTG-20260728-02`: `Chaayos_4.hi.txt` / `Chaayos_4.en.md`
- `SRC-MTG-20260728-03`: `Chaayos_6.hi.txt` / `Chaayos_6.en.md`
- `SRC-MTG-20260728-04`: `New_Recording_12.hi.txt` / `New_Recording_12.en.md`
- `SRC-MTG-20260728-SUM`: `MEETING-SUMMARY.md`

The English translations were used as the primary reading layer. The original Hindi/Hinglish transcripts remain the validation source for disputed terms. Session 3 contains heavy crosstalk and has lower evidentiary confidence.

## Meeting purpose

Day 2 of a design/WRD walkthrough for the C&F/secondary-dispatch application. The team reviewed previous feedback, invoice creation, document flow, E-Way Bill correction/extension, and unresolved SAP feasibility questions.

## Verified workflow

### Pending orders and DI

- Dashboard begins with total pending orders split into credit-free and credit-blocked.
- Pending-order data includes order quantity, DI quantity, pending quantity, customer, ship-to, distribution channel, Incoterm, CRM remarks, distance/lead, source plant, and product.
- The intended relationship is `Order Quantity = DI Quantity + Pending Quantity`.
- Blocked-order behavior is not finalized.

### Invoice preparation

- An open DI moves into an in-progress invoice flow.
- Exactly one storage location is selected for a DI/invoice.
- Multiple batches may be used inside that storage location.
- Batch quantities must equal the DI quantity; neither under- nor over-allocation is allowed.
- Only positive quantities are allowed according to the walkthrough; decimal/tonnage precision still needs reconciliation with other requirements.
- Applicable storage locations and batches should be filtered for the warehouse.
- FIFO recommendation was proposed but its present SAP behavior is disputed.
- SPI defaults to `01` in the design; the acronym and SAP meaning require validation.

### Transport, freight, and shipment

- Transporter can be searched by code/name.
- The system calculates an estimated shipment cost for user validation.
- Shipment input includes LR/GR number/date, vehicle, driver code/name/mobile, and pickup code.
- Driver mobile is mandatory because documents are sent by SMS.
- Pickup code is currently specified for FTP; EX-works treatment is open.

### Background document creation

The design presents these as simultaneous/in-progress steps:

- PGI
- shipment number
- shipment cost
- invoice
- E-Way Bill
- e-Invoice status is also displayed

The exact orchestration, atomicity, and count of steps remain unclear. Document Flow must display status and related identifiers and enable download after required completion.

### E-Way Bill correction

- Part A covers transporter/distance-type corrections.
- Part B covers vehicle changes and remains editable during E-Way Bill validity.
- Pin-to-pin distance can fail because the government portal uses its own pin-code distance and tolerance.
- A Ship-To pin-code error may require correction even when SAP's maintained route lead is internally consistent.

### E-Way Bill extension

- Uses current vehicle location, state/pin code, and a reason.
- Transport mode is fixed to Road.
- Vehicle change belongs to Part B, not extension.
- Extension is 24 hours and may be repeated.

### MIGO/receipt

- Partial inward quantity and storage-location allocation must be visible.
- The remaining quantity stays pending.
- Vehicle tracking link is expected from FleetX.
- Detailed MIGO semantics were not fully resolved in this meeting.

## Decisions

1. Rename fields to Order Quantity and DI Quantity.
2. One DI/invoice uses one storage location; multiple batches are permitted.
3. Transport mode for E-Way Bill extension is Road only.
4. E-Way Bill Part B remains editable during validity.
5. Only open DI quantity is editable, before batch determination.
6. Add FleetX vehicle tracking link.

## Open functional/technical decisions

- Select storage location during DI creation?
- Block DI when stock is insufficient?
- Block DI when route/freight is missing?
- Exact current and desired batch recommendation?
- Display and lock DI storage location downstream?
- Pickup code behavior for FTP and EX-works?
- Meaning and source of invoice/ODN/accounting document identifiers?
- Show accounting impact/GL heads?
- Exact synchronous/asynchronous document orchestration?
- Error display and document-download source?

## Project risk exposed

The side conversation identified an unresolved scope and competence gap:

- Client seniors expect SD/MM/KDS and master-data literacy.
- Vendor management described the task more narrowly as CPI/Commerce field mapping and BAPI posting.
- The client correctly argued that field mapping cannot be valid without business/SAP semantics.
- Historical recordings for trade, non-trade, and STO flows and KT from Harish were recommended.

This is a direct dependency for ABAP API correctness, not an optional learning activity.

## Consequences for the SAP workstream

- Create a KDS/master-data dictionary before freezing payload fields.
- Trace successful SAP examples for trade, non-trade, FTP, EX-works, and STO.
- Split the invoice journey into explicit commands/statuses before selecting BAPIs.
- Do not assume a single BAPI or single SEGW POST implements the whole process.
- Treat Datasphere as a candidate source for history/dashboard/ageing, not current posting decisions.
- Treat proposed UI validation as a business requirement; decide whether it belongs in SAP, CPI, Commerce, or multiple layers.

