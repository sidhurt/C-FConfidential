# QS4 read — plant classification and `LIKP-ZZVBELN` population

**Date:** 2026-09-17 · **System/client:** QS4/700 · **User:** QNOVATE8
**Method:** SAP GUI Scripting, SE16 display only, via
`sessions/2026-08-31-testdata-revalidation/scripts/qs4_se16_read.vbs`.
**Writes:** none.

## 1. Plant classification (`KNA1-KDKG1` on `P<plant>`)

Read in uncapped key ranges (`P0000..P9999`, 4,381 rows; no range hit the row cap).
Evidence: `evidence-2026-09-17/KNA1_P_CUSTOMERS_KDKG1.csv`.

| `KDKG1` | Rows |
|---|---:|
| `A2` depot | 3,951 |
| `A1` primary | 53 |
| `A4` | 36 |
| `A3` | 7 |
| blank | 334 |

| Pseudo-customer | Name | `KDKG1` | Relevance |
|---|---|---|---|
| `P1002` | SCL Ras | **A1** | Supplying plant and shipping point of every STO Create DI candidate |
| `P1022` / `P1023` / `P1026` | Khushkhera / Suratgarh / RNCU | A1 | STO receiving plants |
| `P5412` | RJ MANDI CHOURAHA SC NT | A1 | Ship-to of certified delivery `9004953174` |
| `P7683` | RJ BEAWAR NT LP | **A2** | Plant and shipping point of sales order `5270471` |

An earlier single read capped at 600 rows returned an incomplete, unordered subset (it omitted
`P1000`/`P1005`). Capped SE16 reads must not be used for classification.

**Verified consequence:** the depot-gated rules (V02, V03, V09a on `P<LIPS-WERKS>`; V09b on
`P<LIKP-VSTEL>`) cannot apply to STO candidates `5600084222`, `5600084223` or `5600084274`,
because plant and shipping point `1002` are A1. Sales order `5270471` (plant/shipping point
`7683`, A2, item category `ZO99`, 42 TO) is on a depot.

## 2. Who carries `LIKP-ZZVBELN`

Query: `LIKP` with `ZZVBELN` in `0000000001..ZZZZZZZZZZ`, `ERDAT` in 2026. 995 rows, uncapped.
Evidence: `evidence-2026-09-17/LIKP_ZZVBELN_FILLED_2026.csv`.

- **All 995 are delivery type `ZNL` (STO).** No sales-order delivery type carries it.
- Ship-to is always a BTST/primary pseudo-customer: `P3813` RJ BEAWAR BTST (490), `P3814` RJ
  SURATGARH BTST (195), `P5412` (170), `P3839` RJ RNCU BTST (138), `P8353` RJ KHUSHKHERA2 BTST (2).
- Shipping points `1000`, `1008`, `1002`, `1003`, `1022` — all primary plants.
- 625 distinct referenced orders; created by named dialog users (`S0…`).
- Referenced documents read: `4315389`, `4319285` = `AUART ZNTR`, `VTWEG 20`, external customer;
  `5284874`, `5284875` = `AUART ZTRD`, `VTWEG 10`, plant `8353`, 500/400 TO, created 16.09.2026.

Live QS4 example from 16.09.2026, user `S019423`: trade orders `5284874`/`5284875` → STO
`5600084307/000010` from plant `1022` → `ZNL` deliveries `9004953473`/`9004953474` to `P8353`,
batch-split item `900001`, SLoc `FKGU`, 13 TO each, `ZZVBELN` = the trade order.

**Verified:** `ZZVBELN` links an STO delivery to the customer sales order it fulfils (BTST flow
from a primary plant). **Strong inference:** V07 (order block) and V08 (cumulative quantity vs
order) protect that customer order during STO dispatch; they are not sales-order-route rules.

**Verified:** certified API delivery `9004953174` (STO `5600084209`, `1002` → `P5412`) has no
`ZZVBELN`, while 170 production-copy deliveries on the same shipping point/ship-to carry it.
**Unknown:** whether STO `5600084209` belongs to a BTST order. If it does, the API path dropped the
order link and V07/V08 silently skipped.

**Unknown:** the transaction/program that writes `ZZVBELN`. No captured delivery enhancement
assigns it. Next: identify the transaction used by `S019423` on 16.09.2026 (STAD) or ask the
BTST process owner, then where-used on `LIKP-ZZVBELN`.

## 3. Open scope questions raised

1. Is the BTST flow (primary plant → BTST pseudo-customer, `ZZVBELN` set) in C&F Create DI scope?
   If not, V07/V08 do not apply to C&F; if yes, the API must carry the order link.
2. Depot rules need a depot (A2) delivery population. C&F depot dispatch appears to be the
   sales-order route from A2 plants (e.g. `7683`), which is still uncertified on OData.

## 4. Delivery population 25.07.2026–17.09.2026 (full export)

**Method:** `scripts/qs4_likp_chunk_export.vbs` — SE16 `LIKP`, `VBELN 9004800000..9004999999`,
reduced ALV layout, SAP List > Export > Local File (text with tabs), 20,000-number chunks.
153,514 rows exported, equal to the SE16 *Number of Entries* count. No popup was answered.
Evidence: `evidence-2026-09-17/likp-export/LIKP_*.txt` (14 columns: `VBELN, ERNAM, ERDAT, VSTEL,
LFART, INCO1, ROUTE, LIFSK, KUNNR, WADAT_IST, WERKS, SDABW, WBSTK, ZZVBELN`).
Origin class is taken from `P<VSTEL>`; supplying plant (`LIPS-WERKS`) was not exported.

| Origin | `LFART` | Deliveries |
|---|---|---:|
| **A2 depot** | **`ZNP`** | **47,887** |
| A2 depot | `ZLF` | 3,219 |
| A2 depot | `ZNL` | 834 |
| A2 depot | `ZSDN` | 546 |
| A1 primary | `ZNP` / `ZNL` / `ZLF` | 34,985 / 33,571 / 22,637 |
| A4 RMC | `ZRMC` / `ZRM2` | 7,415 / 459 |

- **`ZZVBELN`:** filled on **2 of 153,514** deliveries — the two 16.09.2026 factory test deliveries
  (`9004953473/474`). **0 of 53,322 depot deliveries**, and 33,571 factory `ZNL` deliveries in this
  window carry none. The 995 filled rows in section 2 are March–April 2026.
- **Depot Incoterm:** `ZNP` FTP 29,509 / FTB 15,278 / EXP 3,100; `ZLF` FTB 2,636 / EXP 528 / EXW 55;
  `ZNL` FTB 533 / FTP 291.
- **Depot SPI (`SDABW`):** filled on all but 2 `ZNP`, all `ZLF`, 818 of 834 `ZNL`; blank on all
  546 `ZSDN` (a type bypassed by V03 through TVARVC `ZSD_PREREQ_DEL`). These are mostly
  goods-issued deliveries, so this shows SPI at dispatch, not at creation.
- **Depot delivery blocks (`LIFSK`):** none.
- **Depot deliveries not fully goods-issued (`WBSTK` A or blank):** `ZNP` 385, `ZLF` 114, `ZNL` 30,
  `ZSDN` 74.
- Post-15.08 depot activity in QS4 is small and mostly `S019423`.

**Strong inference:** `ZZVBELN` is effectively unused in the current delivery population and is
not used by depot deliveries. V07/V08 cannot fire on C&F depot deliveries unless its writer
starts populating it there. The writer itself is still unidentified.

## 5. Open depot sales-order candidates (read 17.09.2026)

**Method:** SE16 `VBAP`/`VBAK`, `VBELN 0005284000..0005289999` (948 items / 899 headers, uncapped);
`TVAK`. Filter: plant `KDKG1 = A2`, `VBAP-LFSTA` A/B, no rejection reason.
118 open depot items; no delivery or billing blocks on any header.

**Verified (`TVAK-LFARV`):** `ZTRD` (Trade) → delivery type **`ZNP`**; `ZNTR` (Non-trade) → **`ZLF`**.
The dominant depot delivery type `ZNP` (47,887) is therefore Trade.

Credit status (`VBAK-CMGST`) of the 118: A 35, D 23, **B 60** (credit check failed — SAP will not
deliver).

| Use | Order / item | Type → delivery | Depot plant | Material | Qty | Credit | Delivery status | Created |
|---|---|---|---|---|---|---|---|---|
| Trade positive | `5284812/000010` | `ZTRD` → `ZNP` | 5346 UP SHAHJAHANPUR SC TR RSD | 15000444 | 42 TO | D | A | 12.09.2026 |
| Trade backup | `5284813/000010`, `5284803/000010` | `ZTRD` → `ZNP` | 5346 | 15000444 / 15000069 | 50 TO | D | A | 12.09.2026 |
| Trade backup (credit A) | `5284855/000010` | `ZTRD` → `ZNP` | 3961 UP GHAZIABAD RSD | 15000266 | 5 TO | A | A | 15.09.2026 |
| Non-trade positive | `5284692/000010` | `ZNTR` → `ZLF` | 4215 BR CHHAPRA SC TR | 15000177 | 1 TO | D | A | 03.09.2026 |
| Non-trade two-item | `5284541/000010,000020` | `ZNTR` → `ZLF` | 5374 BR CHHAPRA SC TR RSD | 15000177 (both) | 5 + 5 TO | D | A | 20.08.2026 |
| Credit-block negative | `5284664`, `5284680`, `5284686` | `ZNTR` → `ZLF` | 5374 | 15000177 | 100 TO | **B** | A | 02–03.09.2026 |

Not established: remaining open quantity on status-B items, stock at the depot, and whether
delivery creation re-runs the credit check. No depot order with two **different** materials in a
`ZDEL_SPLIT` channel exists in this range (rule 1). Re-read immediately before any write.

## 6. Bill-to-ship-to (BTST) link located (read 17.09.2026)

- STO header `EKKO` custom fields: `ZZLD_CLAUSE`, `ZZORDERING_REASON`, `ZZVENDOR_TYPE`; `EKPO` has none.
  **The STO does not store the customer order.**
- `ZZVBELN` is a delivery append field (`ZSDA_CUSTOM_FIELDS1`) propagated to `LIKP`, the delivery BAPI
  extension structures (`SHP_BAPIDLVREFTOSTO_EXT`, `SHP_BAPIDLVREFTOSALESORDER_EXT`,
  `LESHP_BAPI_EXTENSION`), `SHP_EXTENSIBILITY_DATA` and `AOUTBDELIVERYHEADER`.
- BTST tables: `ZLETILMSBTSTDLV` "Bill-to/Ship-to Delivery Mapping" (key `VBELV`, `VBELN`);
  `ZBTST_CUSTOMER` "Customer maintenance table" (key `KUNNR`, empty in QS4/700); view `ZLETILMSBTST_CDS`.

**Verified live chain (16.09.2026, user `S019423`):**

| Step | Document | Detail |
|---|---|---|
| Customer order | `5284875` (`ZTRD`) | plant/shipping point `8353` RJ KHUSHKHERA2 BTST (A1), 400 TO, material `15000114` |
| Stock transfer | STO `5600084307` (`ZP06`) | supplying plant `1022` SCL-KKG |
| STO delivery | `9004953473` (`ZNL`) | `1022` → `P8353`, 13 TO, SLoc `FKGU`, **`ZZVBELN 5284875`**, goods issued |
| Customer delivery | `9004953505` (`ZNP`) | shipping point `8353`, ship-to `11031330`, reference `5284875/000010`, 13 TO batch split, SLoc `GDF`, goods issued |
| Mapping | `ZLETILMSBTSTDLV` | `VBELV 9004953473` → `VBELN 9004953505` |

The same pattern ran on 17.09.2026: STO deliveries `9004953532`/`9004953533` (11 TO each) mapped to
customer deliveries `9004953535` (order `5284875`) and `9004953536` (order `5284874`).

**Verified:** BTST pairs a factory STO delivery (carrying the customer order in `ZZVBELN`) with a
customer sales-order delivery from the BTST plant, linked in `ZLETILMSBTSTDLV`. Both BTST plants
observed (`8353`) are A1. **Unknown:** the program writing `ZZVBELN` and the mapping row (table
names suggest the ILMS interface).
