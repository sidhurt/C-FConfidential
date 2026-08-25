# Pre-PGI DEV data and configuration request — DS4 client 200

**Requested by:** Siddharth (SAP integration, CNF C&F Agent programme)
**Target system:** DS4 client 200 only. No QS4 changes are requested or wanted.
**Purpose:** DS4/200 currently cannot run a single pre-PGI stage. This lists the exact minimum needed to execute and certify the Stage-B chain.

## Why this is needed — what DS4/200 contains today

All findings below are read-only observations from DS4/200 on 2026-08-18.

| Object | Table | Observed | Consequence |
|---|---|---|---|
| Vendors | `LFA1` | **empty** | No forwarding agent / transporter can be entered on a shipment or cost document. |
| Storage-location stock | `MARD` | **empty** | Nothing can be picked, issued or split. |
| Material valuation | `MBEW` | **empty** | No goods movement can be valued or posted. |
| Batches | `MCHA` | **empty** | Batch split cannot be tested. |
| Material/plant views | `MARC` | **2 rows** — `MAT18` and `MAT19`, both plant `PLQ3` only | A stock transfer needs one material in two plants; not possible today. |
| Sales orders | `VBAK` | **empty** | No Trade / Non-trade delivery predecessor. |
| Deliveries | `LIKP` / `LIPS` | **empty** | No delivery to pick, ship, cost or PGI. |
| Purchase orders | `EKKO` | 2 rows, both empty shells (no `BSART`, no dates) | No usable PO predecessor. |
| Material documents | `MKPF` | **empty** | No goods movement history. |
| Shipment costs | `VFKK` | **empty** | Nothing to release or settle. |

**Configuration is largely present** — this is a master-data and transaction-data gap, not a customizing gap, except where noted in section 3.

| Config object | Table | Observed |
|---|---|---|
| Plants | `T001W` | 40+ |
| Storage locations | `T001L` | 30+ |
| Purchasing organisation | `T024E` | `0001` only (`0002` is an empty stub) |
| Plant → purch. org | `T024W` | assignments exist |
| PO document types | `T161` | 35, all SAP standard, incl. **`UB` / `UB2`** stock transport orders |
| Shipment types | `TVTK` | 7 (`0001`–`0006`, `0010`) |
| Transportation planning points | `TTDS` | 30+ |
| Routes | `TVRO` | 25+ |
| Shipment cost doc types | `TVFT` | 6 (`0001` Transportation costs, `0002` General costs, `0003` Insurance, …) |
| Delivery types | `TVLK` | 73 |
| Billing types | `TVFK` | 83 |
| Goods movement codes | `T158G` | 7 (see section 4) |

## 1. Minimum disposable test chain requested

Please create, or authorise me to create, the following in **DS4/200** as disposable DEV test data.

| # | Item | Detail required |
|---|---|---|
| 1 | **A valued material** | One material with `MBEW` valuation extended to a plant, price control and standard/moving price set, base unit, and a purchasing view. Existing `MAT18`/`MAT19` have `MARC` only — no valuation. |
| 2 | **Stock** | A posted opening balance for that material in a named plant + storage location (e.g. movement 561), so picking and PGI have something to consume. |
| 3 | **A batch-managed variant** | One batch-managed material with at least two batches carrying stock in the same storage location, so batch split and `PickAndBatchSplitOneItem` can be exercised. |
| 4 | **A second plant** | The same material extended to a second plant, if the STO route is to be tested (`UB` for generic, or `ZP06` if CNF parity is wanted — see section 3). |
| 5 | **A customer** | One ship-to customer with a sales area, so a sales-order → delivery route can be tested. `KNA1` has rows; please confirm one usable for the relevant sales org. |
| 6 | **A transporter / forwarding agent** | At least one vendor master with partner function `SP`, since `LFA1` is empty. Required by shipment and shipment-cost documents. |
| 7 | **A route** | One route valid for the plant/ship-to combination, with the transporter assigned. |
| 8 | **Freight rate configuration** | Condition records for the shipment-cost pricing procedure, keyed on the transporter/route/shipping type, so `BAPI_SHIPMENT_COST_ESTIMATE` can return a non-zero rate and a "no rate" negative case can be distinguished from "no configuration". |
| 9 | **Shipment type + planning point** | Confirm which of the 7 `TVTK` types and which `TTDS` planning point to use, and that they are consistent with the route and transporter. |
| 10 | **Cost document type** | Confirm which `TVFT` type applies, and the pricing procedure to be used. |

## 2. Process questions only functional can answer

These are **not** data requests — they are the unresolved route questions that block the Stage-B design.

1. **How is the shipment-cost document actually created in your process?** No BAPI exists for this in either DS4 or QS4. Is it a transaction a user runs, a button on the shipment, or a background job? Please name it.
2. **What does "cost release" mean in your process, and where is it stored?** Evidence shows `VFKK-STFRE` is the **account-assignment** status, not release, and `VFKK` has no release field at all. Candidates are the transfer status `STABR`, a shipment-level status, or an approval outside SAP. Please confirm which.
3. **Is cost release a technical prerequisite for PGI, or a business rule?** i.e. will SAP physically refuse the goods issue if the cost document is not released/settled, or is it only procedurally required?
4. **Is cost-document creation automatic when the shipment is saved?** Evidence shows *calculation* is automatic at cost-document creation (calculation timestamp equals creation timestamp to the second), but not whether the document itself is created automatically.
5. **Who performs cost creation and release day to day** — which user or job, so the DEV equivalent can be run once and traced.

## 3. CNF-specific configuration gap

DS4/200 does **not** contain the client's CNF document types. Each was checked with a positive control to prove the filter worked:

| Object | Table | Result | Positive control |
|---|---|---|---|
| `ZP06` STO purchase order type | `T161` | **absent** | BAPI validation returned `ME 013 — Document type ZP06 not allowed with doc. category F` |
| `ZNL` delivery type | `TVLK` | **absent** | filter `LF` returned exactly 1 row |
| `ZSTO` billing type | `TVFK` | **absent** | filter `F2` returned exactly 1 row |

**Decision required.** Two options, and they answer different questions:

- **Option A — generic validation.** Test with SAP standard types (`UB` stock transport order, a standard delivery and billing type). This certifies the API mechanics, payload shapes, commit behaviour and orchestration. It proves **nothing** about the client's ZP06/ZNL/ZSTO configuration or derived values.
- **Option B — CNF parity.** Transport or replicate `ZP06`, `ZNL`, `ZSTO` and their determination configuration into DS4/200. Slower, but the only way to certify the actual CNF behaviour.

My recommendation is **A now, B before sign-off** — but Option A results must never be reported as CNF configuration parity, and I will label them accordingly.

## 4. One question already answered — API-01 `GoodsMovementCode`

This no longer needs functional input for the value set. `GM_CODE` has check table `T158G`, read in DS4/200:

| `GMCODE` | Transaction | Meaning |
|---|---|---|
| `01` | `MB01` | Goods receipt for purchase order |
| `02` | `MB31` | Goods receipt for production order |
| `03` | `MB1A` | Goods issue |
| `04` | `MB1B` | Transfer posting |
| `05` | `MB1C` | Other goods receipt |
| `06` | `MB11` | Goods movement |
| `07` | `MB04` | Subsequent adjustment |

For the CNF STO goods receipt against a purchase order, the value is **`01`**. What still needs functional confirmation is only whether the create request must carry the **PO reference, the delivery reference, or both** — the metadata field `GoodsMovementRefDocType` on the material-document item is the likely control and its permitted values are configuration.

## 5. What I will do the moment the data exists

Serially, one SAP script at a time, stopping before PGI:

1. Capture delivery baseline (header, items, statuses, document flow, proof that no PGI material document exists).
2. Picking and batch split via the v2 OData function imports; reconcile in `VL03N`/`LIPS`.
3. `BAPI_SHIPMENT_CREATE` once; capture `TRANSPORT`, `SHIPMENTGUID`, full `RETURN`, and resulting `VTTK`/`VTTP` including the `ZZ*` append fields.
4. Immediately re-read `VFKK`/`VFKP` to determine whether cost creation is automatic on save.
5. `BAPI_SHIPMENT_COST_ESTIMATE` — only after source inspection supports non-posting, with before/after `VFKK`/`VFKP` row counts proving it created nothing.
6. The client's actual cost-create action, traced.
7. The client's actual release action, traced, with before/after on the full status surface.
8. Final checkpoint: shipment exists, cost document exists, release state positively identified, delivery still not PGI-complete, no PGI material document.

Then stop and issue the Stage-B report before touching PGI.
