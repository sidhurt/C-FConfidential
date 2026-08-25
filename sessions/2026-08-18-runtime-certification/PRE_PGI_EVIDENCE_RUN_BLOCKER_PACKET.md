# Pre-PGI evidence run — blocker packet

**Status:** every Stage-B evidence run is BLOCKED BY DATA in DS4/200.
**This is a stakeholder action request.** It is not a technical finding, and no further table inspection will resolve it.
**Target:** DS4 client 200 only. Nothing is requested in QS4.

## The one-line problem

DS4/200 has the **configuration** for Stage B but essentially none of the **master or transaction data**. There is no delivery to pick, no stock to issue, no valuation to post against, and — critically — **no vendor master at all, therefore no transporter**.

## Evidence for the blocker

Read-only from DS4/200, 2026-08-18:

| Object | Table | Observed | What it blocks |
|---|---|---|---|
| Vendors / forwarding agents | `LFA1` | **0 rows** | Shipment creation and every cost document — `VFKP-TDLNR` and partner function `SP` cannot be filled |
| Storage-location stock | `MARD` | **0 rows** | Picking, batch split, PGI |
| Material valuation | `MBEW` | **0 rows** | Any goods movement — material cannot be valued |
| Batches | `MCHA` | **0 rows** | Batch split, `PickAndBatchSplitOneItem` |
| Material/plant views | `MARC` | **2 rows** — `MAT18`, `MAT19`, both plant `PLQ3` | STO (needs one material in two plants) |
| Sales orders | `VBAK` | **0 rows** | Trade / Non-trade delivery predecessor |
| Deliveries | `LIKP` / `LIPS` | **0 rows** | The entire Stage-B chain |
| Purchase orders | `EKKO` | 2 empty shells | STO predecessor |
| Material documents | `MKPF` | **0 rows** | — |
| Shipment costs | `VFKK` | **0 rows** | — |

Configuration that **is** present and usable:

| Object | Table | Observed |
|---|---|---|
| Shipment types | `TVTK` | 7 (`0001`–`0006`, `0010`) |
| Transportation planning points | `TTDS` | 30+ |
| Routes | `TVRO` | 25+ |
| Shipment cost doc types | `TVFT` | 6 (`0001` Transportation costs, `0002` General, `0003` Insurance, …) |
| PO document types | `T161` | 35 standard, incl. `UB`/`UB2` stock transport orders |
| Plants / storage locations | `T001W` / `T001L` | 40+ / 30+ |
| Purchasing org | `T024E` | `0001` only |
| Customers | `KNA1` | 20+ |

CNF-specific types are **absent**, each proven with a positive control: `ZP06` (`T161`), `ZNL` (`TVLK`, control `LF` returned 1), `ZSTO` (`TVFK`, control `F2` returned 1).

## What is needed — exact minimum to run Stage B once

| # | Item | Exact requirement | Blocks stage |
|---|---|---|---|
| 1 | **Material** | One material with `MBEW` valuation extended to the test plant: valuation class, price control, standard/moving price, base unit. `MAT18`/`MAT19` have `MARC` only — **no valuation record**, so they cannot be moved. | 2, 3, 9 |
| 2 | **Supplying plant** | Named plant from `T001W`, with the material extended (`MARC` + `MBEW`). | 1–9 |
| 3 | **Storage location** | Named `T001L` location under that plant. | 3, 9 |
| 4 | **Stock quantity** | A posted opening balance (e.g. movement 561) — suggest ≥ 100 base units so partial picking and split are meaningful. | 3, 4, 9 |
| 5 | **Batches** | If batch split is in scope: material flagged batch-managed, with **at least two batches** carrying stock in the same storage location. | 4 |
| 6 | **Sales order or STO** | One open order line for that material/plant. For Trade use a sales order; for STO use `UB` (generic) — see the parity note below. | 1 |
| 7 | **Delivery** | One disposable delivery created from #6, **not PGI-complete**, not picked. | 1–9 |
| 8 | **Shipping point** | Valid `VSTEL` for the plant, consistent with the route. | 1, 5 |
| 9 | **Route** | One `TVRO` route valid for the plant → ship-to lane. | 5, 6 |
| 10 | **Transporter** | **At least one vendor master with partner function `SP`.** `LFA1` is empty — this is the single hardest blocker for Stage B. | 5, 6, 7, 8 |
| 11 | **Shipment type** | Which of the 7 `TVTK` types to use, consistent with route and transporter. | 5 |
| 12 | **Transportation planning point** | Which `TTDS` point to use. | 5 |
| 13 | **Cost document type** | Which `TVFT` type applies. | 7 |
| 14 | **Freight pricing procedure + rate** | Condition records for the shipment-cost procedure keyed on transporter/route/shipping type, so a **non-zero rate** returns and a genuine "no rate" negative case is distinguishable from "no configuration at all". | 6, 7 |
| 15 | **Cost create/settle route** | **The transaction, button or job the functional user actually runs** to create the shipment-cost document and to settle it. No BAPI for either was found by the searches performed. Without this the route cannot be traced or exposed. | 7, 8 |

## Decision required — generic vs CNF parity

Two options answering different questions. Please choose.

- **Option A — generic DEV validation.** Use SAP standard types (`UB` STO, a standard delivery type, a standard billing type). Certifies API mechanics, payload shape, commit boundaries, retry and orchestration. **Proves nothing about ZP06/ZNL/ZSTO determination or derived values**, and I will label every result accordingly.
- **Option B — CNF parity.** Bring `ZP06`, `ZNL`, `ZSTO` and their determination configuration into DS4/200. Slower, requires a customizing transport, but is the only route to certifying actual CNF behaviour.

**Recommendation: A now, B before sign-off.** Option A unblocks eight of nine Stage-B stages immediately and is reversible; Option B is required before anyone signs a contract that names ZP06/ZNL/ZSTO.

## What I will run the moment items 1–15 land

Serially, one SAP script at a time, stopping before PGI, capturing REQUEST / RESPONSE / PRE_STATE / POST_STATE / RECONCILIATION per run:

1. Positive delivery GET via `API_OUTBOUND_DELIVERY_SRV;v=2` — baseline header/items/status, proof no PGI material document exists.
2. `PickOneItemWithBaseQuantity` / `PickAllItems`, then `ConfirmPickingAllItems` — with a deliberate insufficient-quantity negative and a duplicate retry.
3. `PickAndBatchSplitOneItem` / `CreateBatchSplitItem` — main line vs `9000xx` split-line quantities, ineligible-batch negative.
4. `BAPI_SHIPMENT_CREATE` once — full `HEADERDATA`/`ITEMDATA`/stages/deadlines + `ZZ*` append fields; capture `TRANSPORT`, `SHIPMENTGUID`, complete `RETURN`; determine whether `BAPI_TRANSACTION_COMMIT` is required; reconcile `VTTK`/`VTTP`; retry without creating a duplicate.
5. Immediate `VFKK`/`VFKP` re-read to establish whether cost creation is automatic on shipment save.
6. `BAPI_SHIPMENT_COST_ESTIMATE` — only after source inspection of update-task/COMMIT behaviour, with before/after `VFKK`/`VFKP` key counts proving whether it persisted anything; plus missing-rate, invalid-carrier, unroutable and non-existent-delivery negatives.
7. The client's actual cost-create action (item 15), traced.
8. The client's actual settle action, traced, with before/after on the full status surface (`STBER`/`STFRE`/`STABR`, `FBGST`/`ARGST`, `EBELN`/`LBLNI`).
9. Final checkpoint, then `STAGEB_PRE_PGI_EVIDENCE_REPORT.md` before any PGI.

## Note on what is already settled

The timestamp trace is complete and needs no further data. On QS4 delivery `9004953084`: settlement `11:11:30` → PGI `11:11:31` → billing `11:11:32`. That establishes **observed ordering only**. Whether SAP technically refuses PGI on an unsettled delivery is a DS4 experiment that requires exactly the chain requested above.
