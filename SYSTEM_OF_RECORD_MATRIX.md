# System-of-Record Matrix

Values marked `TBD` must be resolved before contract freeze.

## Architecture Option C — portal read paths (D-014, 2026-08-03)

**Creation authority and read path are different questions.** S/4 creates the documents; under Option C the portal mostly reads them somewhere else. Do not confuse the two.

| Concept | Created / authoritative in | Portal reads it from | Freshness |
|---|---|---|---|
| Orders | S/4 (or CRM) | **Hybris T1 (CRM)** — live OCC | Real-time |
| Deliveries | **S/4** | **Hybris T1 (CRM)** — live OCC | Immediate create response comes from S/4; T1 projection latency unmeasured. A meeting claims existing SAP→CPI→T1 trigger; reconcile with pull-shaped stage gate under Q-037 |
| Invoices | **S/4** | **Hybris T1 (CRM)** — live OCC | T1 projection mechanism/latency unverified; same two-path question as deliveries (Q-037) |
| Invoice PDF download | S/4 / DigiGST | **Hybris T1** — OCC query | Real-time |
| Pending MRN | S/4 (derived; `ZLE526`) | **T2**, synced from Datasphere | **Cadence conflict:** Option C says 15 min; formal interface summary says 30 min. Extraction queue is still missing (Q-004/Q-053/C-12/C-14) |
| STO List | S/4 | **T2** | **Path conflict:** Option C says DSP→T2 every 15 min; formal interface summary says S/4→T2 real-time for STO orders, deliveries and invoices (C-12) |
| Stock Ageing | S/4 (derived; `ZMM5013`) | **T2**, synced from Datasphere | Daily / D-1; display-only for fulfilment decisions |
| Depot → Storage Location | S/4 (`T001L`) | **T2**, daily from Datasphere | Daily |
| Vehicle Master | Commerce T2 / Datasphere | **T2** | Daily |
| Transporter Master | S/4 vendor (`LFA1`) / Datasphere | **T2** | Daily |
| **Inventory stock listing for reconciliation (current v1.7 API-05)** | **S/4 — live system stock** | Physical Inventory Reconciliation screen | Product × storage location for the selected plant/depot; no DI context and Material is an optional filter (D-051) |
| **Stock/batch eligibility for outbound allocation** | **S/4 — must be real-time** | Interface identity unresolved — see Q-038 | Separate need from API-05 book-stock listing unless the architect explicitly approves another operation on the same service; must block unavailable batch allocation |
| Shipment cost estimate | **S/4 — live call** | S/4 via CPI (per D-013) | Real-time |

**Consequence for the ABAP workstream:** Option C removes most read APIs from SAP scope and leaves the write commands plus two real-time reads (stock availability, shipment cost estimate). It also depends on S/4 → T1 projection whose existence is now meeting-supported but whose technical identity, owner, payload coverage and SLA remain unresolved (Q-037).

**Command/read-model split added 2026-08-10:** Create DI and Submit MIGO are intended to return their authoritative SAP identifier synchronously. Portal list visibility can follow later through T1 or DSP. The create response must therefore not depend on read-model propagation, and the UI/support model needs a correlation key and propagation SLA (`SRC-MTG-20260810-02 @20:45–21:18, @25:41–27:43`).

| Concept | Candidate authority | Secondary representation | Transaction use | Notes |
|---|---|---|---|---|
| SAP order number | S/4 | Commerce/Datasphere | S/4 | Generated only after SAP order creation |
| Order open quantity | S/4 | Datasphere snapshot/Commerce display | S/4 | Current document flow required |
| Credit status | S/4 | Commerce display | S/4 | Defines blocked-order behavior |
| DI number/status/quantity | S/4 | Commerce/Datasphere | S/4 | Delivery Instruction / DI = SAP outbound delivery; DI No. = `LIKP-VBELN` (D-007, clarified 2026-08-11). Predecessor SO vs STO still open — Q-031 |
| Plant/source warehouse | S/4 master/customizing | Commerce/Datasphere | S/4 | External depot mapping required |
| Storage location | S/4 | Commerce display | S/4 | DI timing/locking unresolved. For MIGO, 10 Aug KT allocates receipt quantity across receiving storage locations; physical reconciliation is also product+SLoc grain (Q-004/Q-017) |
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
| MIGO/material document | S/4 | Datasphere/Commerce | S/4 | Prior inward is history; the new UI delta contains both accepted and rejected classifications. Only accepted quantity increases stock. `DMG`/`STG` remain/add to replacement demand and require a later Order→DI→MIGO cycle (D-052). Exact posting reference/identifier and rejection persistence remain Q-004/Q-066/C-14 |
| Physical inventory reconciliation | System stock: S/4 via current v1.7 API-05. Physical count/workflow: portal candidate | Portal audit history | Read grain settled by D-051; SAP adjustment vs portal record remains Q-017 | Product × storage-location count, variance reason and material-specific UoM conversion |
| ePOD | TBD | Portal dashboard candidate | Completion use TBD | Code issuer, validator, persistence, eligible flows and rollout are Q-056 |

## Standard-service execution map — 2026-08-15

This table answers where an authoritative transaction is executed. It does not replace the portal read paths above.

| Business operation | Authoritative object/source | Current service or route | What remains outside that service |
|---|---|---|---|
| Submit accepted goods receipt | S/4 material document | `API_MATERIAL_DOCUMENT_SRV`; `MMIM_MATDOC_SRV` read-back | Reference/movement mapping, rejected DMG/STG persistence, receipt balance/status, idempotency/error envelope |
| Create/update/read DI and post PGI | S/4 outbound delivery | `API_OUTBOUND_DELIVERY_SRV;v=2` | Client status mapping, batch/stock eligibility, idempotency, exact API-09/API-12 proof |
| Create/read billing | S/4 billing document if SD billing | `SD_CUSTOMER_INVOICES_CREATE` conditional create + `API_BILLING_DOCUMENT_SRV` read | Integration-release decision for internal create service, orchestration, accounting/e-document stages |
| Shipment calculation | S/4 LE/TM configuration | No credible SEGW candidate; validate `BAPI_SHIPMENT_COST_ESTIMATE` | Thin callable endpoint and exact pricing/configuration rules if no existing approved route exists |
| Live book stock | S/4 inventory stock | `API_MATERIAL_STOCK_SRV` | Included stock types and descriptive master data |
| Stock ageing | `ZMM5013`-derived model | Datasphere D-1/read model | Remove from the live stock API contract unless architecture deliberately changes the source |
| Read/create STO PO | S/4 purchase order | `API_PURCHASEORDER_PROCESS_SRV` | Client STO document type/item category, status mapping, `ShippingType` correction, idempotency |
| E-Way extension and invoice correction | DigiGST/EY/eDocument plus S/4 persistence | Existing `EY_*`/eDocument route, exact implementation not yet named | Identify and test existing FM/BAdI/service; build a thin command only if no approved callable surface exists |

## Resolution rule

When two systems contain the same attribute:

1. Identify which one creates/owns it.
2. Record latency and transformation in the other.
3. Use the authoritative source for commands and validation.
4. Define reconciliation rather than silently choosing the value that is easier to retrieve.
