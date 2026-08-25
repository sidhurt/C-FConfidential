# Stage-B finding — what "cost release" actually is

**Source:** QS4/700, strictly read-only SE16 (`DD03L`, `DD07L`, `DD07T`, `VFKK`, `VFKP`, `VTTK`, `VTTP`, `LIKP`), 2026-08-18.
**Status:** HISTORICAL document evidence. It establishes what SAP records and in what order. It is **not** proof of a callable route.

## 1. The old assumption was wrong

`HANDOVER_V18_SESSION.md` treated `VFKK-STFRE` as the cost-release field and noted that 999/999 sampled documents had it blank.

`STFRE` is **not** release. Domain texts read from `DD07T`:

| Field | Domain | Actual meaning | blank means |
|---|---|---|---|
| `STBER` | `STBER_K` | **Calculation** status | not relevant for calculation |
| `STFRE` | `STFRE_K` | **Account assignment** status | *"Not relevant for account assignment"* |
| `STABR` | `STABR_K` | **Transfer** status (settlement into MM) | *"Not relevant for transfer"* |

Values for all three: blank / `A` not done / `B` partially done / `C` fully done.

Two errors followed from the old reading:
1. The field measured account assignment, not release.
2. **Blank means "not relevant", not "not done"** — so the 999-blank sample never supported the conclusion drawn from it.

`VFKK` has exactly 18 fields and **contains no release field at all**.

## 2. Where completion is actually recorded

Two levels carry it, and they agree.

**Cost document item `VFKP`** — each status has its own date and time:
`STBER`/`DTBER`/`UZBER` · `STFRE`/`DTFRE`/`UZFRE` · `STABR`/`DTABR`/`UZABR`

**Shipment header `VTTK`** carries the mirrored shipment-level statuses:
- **`FBGST`** — shipment cost **calculation** status
- **`ARGST`** — shipment cost **settlement** status

The hard, unambiguous evidence that settlement completed is not a status flag at all — it is that `VFKP-EBELN` (freight purchase order) and `VFKP-LBLNI` (service entry sheet) become populated.

## 3. Positive settled examples

From a 200-row `VFKP` sample:

| Status | Distribution |
|---|---|
| `STBER` | `C` = **200 / 200** |
| `STFRE` | blank = 195, `A` = 2, `C` = **3** |
| `STABR` | blank = 195, `A` = 2, `C` = **3** |
| `EBELN` populated | **3** |

The three `STFRE=C` rows are exactly the three `STABR=C` rows and exactly the three with a purchase order. Those are the positive examples:

| `FKNUM` | `FKPTY` | Net | `REBEL` (shipment) | `UZFRE` | `UZABR` | `EBELN` | `LBLNI` | User |
|---|---|---|---|---|---|---|---|---|
| 1100608871 | Z001 | 7,460.00 INR | 1100605471 | 11:11:28 | 11:11:30 | 6000105831 | 1003382363 | S019423 |
| 1100608872 | Z001 | 4,222.36 INR | 1100605472 | 17:01:45 | 17:01:45 | 6000105831 | 1003382365 | S011625 |
| 1100608873 | Z001 | 2,984.00 INR | 1100605473 | 17:29:14 | 17:29:14 | 6000105831 | 1003382366 | S011625 |

All dated 17.08.2026. Forwarding agent `0013000730` on all three.

Three things follow:

1. **`STBER=C` on all 200 rows.** Calculation is universal and automatic — in the one document inspected in full, the calculation timestamp equalled the creation timestamp to the second.
2. **Account assignment and transfer are effectively one action.** `UZFRE` and `UZABR` are identical in two cases and 2 seconds apart in the third. They are not two separately-scheduled business steps.
3. **Settlement creates MM documents.** All three settled against the **same** freight purchase order `6000105831` but each received its **own** service entry sheet. So the settlement step is the one with financial consequence, and it is the strongest candidate for what the business calls "release".

The two `A` rows ("not completed" / "not transferred") are the contrast state: relevant, but not yet done.

## 4. Reconstructed chain for one settled example

| Time (17.08.2026) | Object | Evidence |
|---|---|---|
| 10:26:23 | Delivery **9004953084** created — type **`ZLF`**, shipping point 7683, ship-to 0020313426, route E36881 | `LIKP` |
| 11:11:28 | Shipment **1100605471** created — type `Z001`, planning point 7683, carrier 0013000730, route E36881, 484 KM, `ZZVEHICLE_NO = HR55AZ3800` | `VTTK`, `VTTP` |
| 11:11:28 | Shipment planned (`STDIS=X`) and completed (`STABF=X`); `STTRG=5` | `VTTK` |
| 11:11:28 | Cost document **1100608871** created, calculated, account-assigned | `VFKP` |
| 11:11:30 | Cost **transferred** → PO `6000105831`, service entry `1003382363`; `VTTK-ARGST=C` | `VFKP`, `VTTK` |
| same day | Delivery PGI complete — `WBSTK=C`, `WADAT_IST=17.08.2026`; billing complete `FKSTK=C` | `LIKP` |

Shipment created, planned, completed, costed and settled inside **2 seconds**, by a single user id. This corroborates the earlier finding that the dispatch process already runs end to end automatically; CNF supplies an entry point, it does not build the process.

Note the delivery type here is **`ZLF`**, not `ZNL` — this is a sales/Trade dispatch, not the STO route. It is the first Trade-route Stage-B evidence in the project.

## 5. Correction: the cost document number is not the shipment number

`HANDOVER_V18_SESSION.md` records `FKNUM = REBEL = TKNUM`. Both examples contradict it:

| `FKNUM` | `REBEL` |
|---|---|
| 2100005093 | 2100005099 |
| 1100608871 | 1100605471 |

The number ranges are similar enough to be mistaken for each other. **The correct join is `VFKP-REBEL → VTTK-TKNUM`.** Do not key on `FKNUM = TKNUM`.

This also means the cost document previously attributed to shipment `2100005093` actually belongs to shipment `2100005099`, and the forwarding agent recorded for it (`0013000434`) is not the one on shipment `2100005093` (`0013000913`).

## 6. Completed timestamp trace — settlement precedes PGI by one second

`VBFA` successors of delivery `9004953084` (filter `txtI2-LOW` = `VBELV`), joined with `LIKP` and `VFKP`:

| Time (17.08.2026) | Event | Document | Source |
|---|---|---|---|
| 10:26:23 | Delivery created | `9004953084` (`ZLF`) | `LIKP-ERDAT/ERZET` |
| **11:11:28** | Shipment created | `1100605471` (`VBTYP 8`) | `VBFA` |
| 11:11:28 | Cost doc created, calculated, account-assigned | `1100608871` — `DTBER/UZBER`, `UZFRE` | `VFKP` |
| **11:11:30** | **Cost transferred / settled** → PO `6000105831`, service entry `1003382363` | `UZABR` | `VFKP` |
| **11:11:31** | **PGI material document** — movement **601** | **`4918168265`** (`VBTYP R`, `MJAHR 2026`) | `VBFA` |
| 11:11:31 | Transfer-order/WM record | `2293084000` (`VBTYP R`) | `VBFA` |
| 11:11:32 | Billing created | `1108024764` (`VBTYP M`) | `VBFA` |
| 12:33:05 → 14:48:31 | Five invoice-cancellation (`VBTYP N`) and re-invoice (`M`) cycles | `1900109233…37` / `1108024766…71` | `VBFA` |

### How this must be read

- **Settlement (11:11:30) preceded PGI (11:11:31) by one second.** Per the evidence rule, this establishes **observed ordering only**. It does **not** prove SAP technically blocks PGI before settlement. A technical dependency can only be shown by attempting PGI on an unsettled document.
- Shipment → settlement → PGI → billing spans four seconds. **Proximity does not prove one LUW and does not prove one action.** They remain separate business states.
- Delivery creation is 45 minutes earlier and is clearly a separate operation.
- `ERNAM`/`AENAM` carry real user ids (S019423, S011625). **A real user id does not prove manual operation** — it is equally consistent with a job or interface running under that id.
- The five cancel/re-invoice cycles after PGI are relevant to API-07 (invoice correction), not to Stage B.

## 7. Still open

> **Updated 2026-08-18 (later same day).** Items 2 and 3 below have moved substantially. See [`stageb-route/CALLABLE_MECHANISM_FOUND.md`](stageb-route/CALLABLE_MECHANISM_FOUND.md) and [`stageb-route/STAGEB_CALLABLE_INTERFACE_ANALYSIS.md`](stageb-route/STAGEB_CALLABLE_INTERFACE_ANALYSIS.md).

1. **Is settlement a technical PGI prerequisite or only procedural?** Observed ordering is settlement-then-PGI, but that is not proof of enforcement. Only a DS4 attempt to PGI an unsettled delivery can decide it. **Unchanged — still open.**
2. ~~**Which transaction, job or function performs cost creation and settlement.**~~ **Resolved as to mechanism.** Cost creation is `SD_SCDS_CREATE`, settlement is `SD_SCDS_RELEASE`, persistence is `SD_SCDS_SAVE`, status write-back is `SD_SCDS_SHIPMENT_UPDATE` — all in package `VTRA`, all **not released and not RFC-enabled**. The BAPI searches missed them because they are not BAPIs. The client's own route is `ZDACE_WT` (Weight Bridge) → `ZDACE_CL_STO_PROCESS`, which already calls `SD_SCDS_CREATE` via `SHIP_COST_CRT`. **Still open:** no static caller was found for `SD_SCDS_RELEASE`, so the settlement invoker specifically remains unidentified.
3. **Whether "release" in the client's vocabulary means the transfer step or a prior approval.** **Strengthened, not closed.** SAP's own German short text for `SD_SCDS_RELEASE` is *Überleitung der Frachtkostenpositionen* — transfer. That is a second independent line agreeing with the `STABR` status analysis in §3. Functional must still confirm the client uses the word the same way before it is minuted.
