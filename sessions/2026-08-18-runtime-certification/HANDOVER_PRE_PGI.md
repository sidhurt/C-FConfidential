# Handover — pre-PGI mechanism and API-03 decision

**Date:** 2026-08-18 · **DS4/200** write-authorised, nothing written · **QS4/700** read-only throughout.
Supersedes the Stage-B sections of `HANDOVER_V18_SESSION.md`.

## 1. The pre-PGI chain — six separately committed states

| # | State | Persisted in | Completion marker |
|---|---|---|---|
| 1 | Shipment created | `VTTK` / `VTTP` | `TKNUM` |
| 2 | Cost document created | `VFKK` / `VFKP` | `FKNUM` |
| 3 | Calculated | `VFKP` | `STBER=C`, `DTBER`/`UZBER` |
| 4 | Account assigned | `VFKP` | `STFRE=C`, `DTFRE`/`UZFRE` |
| 5 | Settled / transferred | `VFKP` | `STABR=C`, `DTABR`/`UZABR`, **`EBELN` + `LBLNI` populated** |
| 6 | PGI | `MKPF`/`MSEG` | material doc, movement 601 |

Shipment-level mirrors on `VTTK`: **`FBGST`** (calculation) and **`ARGST`** (settlement).

## 2. Callability — the load-bearing fact

| Stage | Mechanism | Released? | RFC? |
|---|---|---|---|
| Shipment create | `BAPI_SHIPMENT_CREATE` | Yes | **Yes** |
| Freight estimate | `BAPI_SHIPMENT_COST_ESTIMATE` | **No** | Yes — estimate only, creates nothing |
| Cost doc create | `SD_SCDS_CREATE` | No | **No** |
| Calculate | `SD_SCD_ITEM_CALCULATE` | No | **No** |
| Account assign | `SD_SCD_ITEM_ACCT_ASSIGNMENT` | No | **No** |
| Settle / transfer | `SD_SCDS_RELEASE` | No | **No** |
| Persist | `SD_SCDS_SAVE` | No | **No** |
| PGI | OData `PostGoodsIssue` (delivery v2) | Yes | **Yes** |

**Four of seven pre-PGI stages have no callable interface.** Custom SAP development is therefore mandatory, not a design preference.

Search rigour: `TFDIR` patterns (`SD_SCD*`, `SD_SCDS*`, `*SHIPMENT_COST*`, `*SHIPMENTCOST*`, `BAPI_SHIPMENT*`) plus full-scope SE37/SE24 where-used. Positive control: where-used on `SD_SCD_ITEM_CALCULATE` returned SAP-standard includes `LV54CF02`/`LV54CF03`, proving the index covers standard code. `FMODE` control: `BAPI_SHIPMENT_CREATE` = `R`; all `SD_SCDS_*` blank.

## 3. Terminology correction — carry this forward

- **`VFKK-STFRE` is account assignment, not release.** Domain `STFRE_K`; blank = *"Not relevant for account assignment"*, **not** "not done". The earlier "999/999 blank ⇒ release never happens" conclusion was invalid.
- **`VFKK` has no release field.** Business "cost release" = **settlement/transfer** = `STABR` = `SD_SCDS_RELEASE`, whose German text is *"Überleitung der Frachtkostenpositionen"*.
- **Cost doc number ≠ shipment number.** Join is **`VFKP-REBEL → VTTK-TKNUM`**. Observed: `FKNUM 1100608871 → REBEL 1100605471`; `FKNUM 2100005093 → REBEL 2100005099`.

## 4. Wrappability of the internal modules

| Module | Coupling | Wrappable? |
|---|---|---|
| `SD_SCDS_CREATE` | No `T180`. Has `I_OPT_COMMIT`. Range-based (`C_REFOBJ_RANGE`), returns `E_REFOBJ_RANGE_LOCKED`. Short text: *"Frachtkosten anlegen (online, batch)"* | **Best candidate** — designed for online *and* batch |
| `SD_SCDS_RELEASE` | `I_REFOBJ_TAB` + `C_SCD_TAB`, no `T180` | Moderate — needs the SCD structure built first |
| `SD_SCDS_SAVE` | Requires `I_T180`; `I_OPT_UPDATE_TASK` controls commit | Dialog-bound |
| `SD_SCD_ITEM_CALCULATE` | Requires `I_T180` | Dialog-bound |
| `SD_SCD_ITEM_ACCT_ASSIGNMENT` | Requires `T185`/`T185V`, `SY-CPROG`, returns `E_FCODE` | **Heavily screen-flow bound — do not wrap directly** |
| `SD_SCD_HISTORY_SETTLEMENT` | `I_VFKP` in, `E_SETTL_HIST` out | Clean read API for freight PO / service entry |

## 5. Implementation precedent (reference only — not CNF)

`ZDACE_CL_STO_PROCESS` calls `SD_SCDS_CREATE` directly and exposes `SHIP_DOC_CRT`, `SHIP_DOC_CHG`, `SHIP_COST_CRT`, `DELIVERY_CHANGE`, `DELIVERY_PGI`, `COMMIT_LUW`, `ROLLBACK_LUW`. Two sibling classes and five Z programs call the same FM.

**Scope caveat:** this is weighbridge processing, which is **out of C&F scope**. It is cited only as proof that direct internal-FM calls are the route this system already uses when no standard API exists. It is **not** the CNF process, not a proposed CNF entry point, and does not prove CNF needs only a wrapper. Method source was not extracted — deprioritised on scope correction.

## 6. API-03 recommendation

**One external command, resumable, explicitly non-atomic.**

Rationale:
- A custom SAP wrapper is required regardless, so three endpoints = three wrappers, not less build.
- Stage state lives in SAP (`VTTK`, `VFKK`/`VFKP`, `LIKP`). Only SAP can answer "where did it get to". CPI orchestrating three calls would guess at state it does not own.
- Check-then-act against those documents makes retry naturally safe and prevents duplicate shipments.

Mandatory conditions to state openly:
- **Not atomic.** Once the shipment commits it is committed; recovery is reversal, not rollback.
- Response must be **stage-level**, e.g. `{ shipment, costDoc, calculated, accountAssigned, settled, stage }`.
- CNF owns process id, stage status, duplicate prevention, resume, partial completion, monitoring, reversal. **It is not a thin passthrough.**

## 7. CLOSED — settlement is NOT a technical PGI prerequisite

**Answer: PGI is not technically blocked by unsettled shipment cost. The "release before PGI" rule is business process, not SAP enforcement.**

Evidence chain, QS4/700 read-only:

```
VFKK 1300105310   FKART=Z003  STBER=C  STFRE=A  STABR=A     ← settlement RELEVANT, NOT done
  └─ VFKP 000001  FKPTY=Z002  12,144.00 INR  TDLNR=0013000913
                  EBELN=blank  LBLNI=blank                  ← no freight PO, no service entry
       └─ REBEL → shipment 1300105363
            └─ VTTP → delivery 0080387199
                 └─ LIKP: LFART=ZLF  WBSTK=C  WADAT_IST=13.03.2024  FKSTK=C
                                     ↑ PGI COMPLETE          ↑ and billed
```

Why this is decisive where the earlier `Z006` case was not:

| | Earlier counter-example | This one |
|---|---|---|
| Delivery type | `EL` — not a dispatch type | **`ZLF`** — real dispatch, same family as the settled example `9004953084` |
| `STABR` | blank = *"not relevant for transfer"* | **`A` = "not transferred"** — relevant, started, unfinished |
| Proves | PGI proceeds when settlement is irrelevant | **PGI proceeds when settlement is relevant and incomplete** |

Population: 200 rows returned for `VFKK` where `STABR=A`, all `FKART=Z003`, all `STBER=C` / `STFRE=A` / `STABR=A`. So this is a standing configuration state, not a one-off.

**Design consequence:** PGI can be decoupled from settlement without SAP objecting. If CNF wants "no PGI before release" it must **enforce that itself** — SAP will not. Conversely, an orchestration that stalls waiting for settlement is imposing a constraint SAP does not require.

Evidence: `stageb-qs4/VFKK_STABR_A.txt`, `VFKP_1300105310.txt`, `VTTP_1300105363.txt`, `LIKP_0080387199.txt`.

## 8. Blocker

DS4/200 cannot run any Stage-B evidence run. `LFA1` empty (no transporter), `MBEW` empty (no valuation), `MARD` empty (no stock), `MCHA` empty (no batches), `MARC` 2 rows both plant `PLQ3`, `VBAK`/`LIKP` empty. Config is present (`TVTK` 7, `TTDS` 30+, `TVRO` 25+, `TVFT` 6, `T161` incl. `UB`). CNF types absent, each with positive control: `ZP06`, `ZNL` (control `LF`=1 row), `ZSTO` (control `F2`=1 row).

Exact request: `PRE_PGI_EVIDENCE_RUN_BLOCKER_PACKET.md`, 15 items. Cannot be self-served — fabricating master data to force a passing result is outside authorization.

## 9. Evidence runs actually executed: 2

`BAPI_MATERIAL_AVAILABILITY` (×2, read-only) and `BAPI_PO_CREATE1` (`TESTRUN=X`, → `ME 013` for ZP06). Everything else is interface/metadata capture, explicitly not an evidence run.

## 10. Next session

1. DS4 PGI-prerequisite experiment once data lands (§7).
2. `SD_SCDS_RELEASE` invoker — no static caller found at full scope; likely dynamic or screen-flow. Needs SAT/ST05 during a real VI02 settlement.
3. `BAPI_SHIPMENT_CREATE` → does saving trigger `SD_SCDS_CREATE`? Inspect `SAPLV56I_BAPI`.
4. Reconstruct CNF API-03 contract from `deliverables/CNF_API_Request_Response_Specification_v1.8.xlsx` + `meetings/2026-08-17-create-invoice-orchestration-design.md`.

**Working rules:** one SAP script at a time (concurrent scripts corrupt the session); DS4 guard on `SystemName`+`Client`, never process name; no SendKeys/clipboard/COPY_BODY/blanket modal loops; verify positional SE16 field ids with a positive control before trusting a filter.
