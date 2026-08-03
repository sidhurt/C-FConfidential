# System-of-Record Matrix

Values marked `TBD` must be resolved before contract freeze.

## Architecture Option C — portal read paths (D-014, 2026-08-03)

**Creation authority and read path are different questions.** S/4 creates the documents; under Option C the portal mostly reads them somewhere else. Do not confuse the two.

| Concept | Created / authoritative in | Portal reads it from | Freshness |
|---|---|---|---|
| Orders | S/4 (or CRM) | **Hybris T1 (CRM)** — live OCC | Real-time |
| Deliveries | **S/4** | **Hybris T1 (CRM)** — live OCC | Real-time — *push mechanism unspecified, see Q-037* |
| Invoices | **S/4** | **Hybris T1 (CRM)** — live OCC | Real-time — *same gap, Q-037* |
| Invoice PDF download | S/4 / DigiGST | **Hybris T1** — OCC query | Real-time |
| Pending MRN | S/4 (derived; `ZLE526`) | **T2**, synced from Datasphere | 15 min — *derivation parity risk, Q-039* |
| STO List | S/4 | **T2**, synced from Datasphere | 15 min |
| Stock Ageing | S/4 (derived; `ZMM5013`) | **T2**, synced from Datasphere | Daily |
| Depot → Storage Location | S/4 (`T001L`) | **T2**, daily from Datasphere | Daily |
| Vehicle Master | Commerce T2 / Datasphere | **T2** | Daily |
| Transporter Master | S/4 vendor (`LFA1`) / Datasphere | **T2** | Daily |
| **Stock availability for batch allocation** | **S/4 — must be real-time** | **Not shown in Option C — see Q-038** | Must be real-time |
| Shipment cost estimate | **S/4 — live call** | S/4 via CPI (per D-013) | Real-time |

**Consequence for the ABAP workstream:** Option C removes most read APIs from SAP scope and leaves the write commands plus two real-time reads (stock availability, shipment cost estimate). It simultaneously creates an unowned outbound S/4 → T1 flow (Q-037).

| Concept | Candidate authority | Secondary representation | Transaction use | Notes |
|---|---|---|---|---|
| SAP order number | S/4 | Commerce/Datasphere | S/4 | Generated only after SAP order creation |
| Order open quantity | S/4 | Datasphere snapshot/Commerce display | S/4 | Current document flow required |
| Credit status | S/4 | Commerce display | S/4 | Defines blocked-order behavior |
| DI number/status/quantity | S/4 | Commerce/Datasphere | S/4 | DI = outbound delivery, DI No. = LIKP-VBELN (D-007, 2026-07-29). Predecessor SO vs STO still open — Q-031 |
| Plant/source warehouse | S/4 master/customizing | Commerce/Datasphere | S/4 | External depot mapping required |
| Storage location | S/4 | Commerce display | S/4 | DI timing/locking unresolved |
| Batch stock | S/4 | Datasphere snapshot | S/4 | Current stock and eligibility |
| FIFO recommendation | S/4 logic or application rule TBD | Commerce display | Approved rule source TBD | Current behavior disputed |
| Material number | S/4 | Commerce product/alias, Datasphere | S/4 | Alias resolution needs owner |
| Material alias/product label | Commerce or master hub TBD | S/4/Datasphere | Depends | Do not assume |
| Customer/Ship-To | S/4 likely | Commerce/Datasphere | S/4 | Pin code quality affects E-Way Bill |
| Incoterm | S/4 order | Commerce display | S/4 | FTP/EX treatment needs KT |
| Route/lead/distance | S/4 master/customizing | Government portal has independent distance | S/4 plus external validation | Distinct meanings |
| Transporter master/code | S/4 or Commerce TBD | CPI/Datasphere | S/4 posting | Search by code/name |
| Vehicle/driver details | Commerce input/master TBD | S/4/custom/FleetX | Process-dependent | Driver mobile used for SMS |
| Vehicle live location | FleetX | Commerce link | No SAP posting by default | CPI/external integration |
| Freight/rate | S/4 likely | Commerce estimate | S/4 | Route/SPI/transporter dependencies |
| Shipment number/status | S/4 | Commerce/Datasphere | S/4 | Object model TBD |
| Shipment cost | S/4 | Commerce/Datasphere | S/4 | Estimate vs posted cost distinction |
| PGI status/document | S/4 | Commerce/Datasphere | S/4 | Current state |
| Billing document | S/4 | Commerce/Datasphere | S/4 | SAP generates invoice |
| ODN/display invoice number | S/4 likely | Commerce/Datasphere | S/4 | Field ambiguity |
| Accounting document | S/4 | Datasphere | S/4 | FI consequence |
| IRN/E-Invoice status | SAP eDocument/GSP/CPI TBD | Commerce/Datasphere | External/SAP | Architecture TBD |
| E-Way Bill/status | GSP/government plus SAP persistence | Commerce/Datasphere | External/SAP | Correction/extension |
| Downloadable invoice/e-doc | Output repository/GSP/SAP TBD | Commerce link | No decision | Storage TBD |
| Historical billing/stock ageing | Datasphere likely | Commerce | No transactional decision | Model/latency required |
| MIGO/material document | S/4 | Datasphere/Commerce | S/4 | Partial receipt support |

## Resolution rule

When two systems contain the same attribute:

1. Identify which one creates/owns it.
2. Record latency and transformation in the other.
3. Use the authoritative source for commands and validation.
4. Define reconciliation rather than silently choosing the value that is easier to retrieve.

