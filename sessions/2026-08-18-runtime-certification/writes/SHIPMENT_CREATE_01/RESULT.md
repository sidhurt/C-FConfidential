# EVIDENCE RUN — BAPI_SHIPMENT_CREATE, commit-boundary experiment

**System:** DS4 client 200 · **User:** QNOVATE8 · **Date:** 2026-08-19
**Type:** real write. `BAPI_SHIPMENT_CREATE` has **no `TESTRUN`** parameter — every execution is a live create.
**Documents created:** shipment `0000001001` (persisted). Shipment number `0000001000` was allocated but **never persisted**.

## Pre-state

All four tables empty in DS4/200 before the run — a clean baseline:

| Table | Rows before |
|---|---|
| `VTTK` | 0 |
| `VTTP` | 0 |
| `VFKK` | 0 |
| `VFKP` | 0 |

## Input

Minimum viable header. No master data was fabricated; both values are existing DS4 configuration.

| Parameter | Field | GUI id | Value | Source |
|---|---|---|---|---|
| `HEADERDATA` | `SHIPMENT_TYPE` | `txt[35,3]` | `0001` | `TVTK` |
| `HEADERDATA` | `TRANS_PLAN_PT` | `txt[40,3]` | `0001` | `TTDS` |

All table parameters (`ITEMDATA`, `STAGEDATA`, `HEADERDEADLINE`, `STAGEDEADLINE`, `ITEMONSTAGE`, `ADDRESS`, `HDUNHEADER`, `HDUNITEM`) left at 0 entries.

## Run 1 — create alone, no commit

**Exports:** `TRANSPORT = 1000` · `SHIPMENTGUID = 2t{C9pId7z6cyPcOjZL1}0` · runtime 13,697,497 µs

**`RETURN` — 7 rows:**

| # | Type | ID | No. | Message |
|---|---|---|---|---|
| 1 | `S` | `VW` | 487 | Processing shipment : Start |
| 2 | `S` | `VW` | 511 | Processing shipment 0000001000 : Header data |
| 3 | `S` | `VW` | 513 | Processing shipment 0000001000 : Items |
| 4 | `S` | `VW` | 512 | Processing shipment 0000001000 : Set status |
| 5 | `S` | `VW` | 515 | Processing shipment 0000001000 : End |
| 6 | **`W`** | `VW` | 094 | **shipments without Outbound deliveries** |
| 7 | `S` | `VW` | 488 | **Save shipment 0000001000** |

No error rows. The BAPI reported success and explicitly said *"Save shipment 0000001000"*.

**Post-state after Run 1: `VTTK` still 0 rows.**

> The document did not persist. The success messages and the returned shipment number were produced inside an uncommitted LUW, which was discarded when the session moved on.

## Run 2 — create + commit, one LUW

Executed through SE37 **Execute → Test Sequences** with `BAPI_SHIPMENT_CREATE` then `BAPI_TRANSACTION_COMMIT`, so both ran in a single LUW.

- `BAPI_SHIPMENT_CREATE` → `TRANSPORT = 1001` · `SHIPMENTGUID = 2t{C9pId7z6cyR3NRXX2q0`
- `BAPI_TRANSACTION_COMMIT` with `WAIT = X` → runtime 194,849 µs

**Post-state after Run 2 — `VTTK` has exactly 1 row:**

| `MANDT` | `TKNUM` | `VBTYP` | `SHTYP` | `TPLST` | `ERNAM` | `ERDAT` | `ERZET` |
|---|---|---|---|---|---|---|---|
| 200 | **0000001001** | 8 | 0001 | 0001 | QNOVATE8 | 19.08.2026 | 10:49 |

## What this proves

1. **`BAPI_SHIPMENT_CREATE` does not commit internally.** Proven by controlled contrast: identical call, one without commit (not persisted) and one with `BAPI_TRANSACTION_COMMIT` (persisted). **The caller owns the commit.**
2. **The shipment number is allocated before commit.** Run 1 returned `TRANSPORT = 1000` and a "Save shipment" success message for a document that never existed. **A caller that trusts the returned number without committing gets a phantom shipment number** — and number range `1000` is now consumed. This is a concrete integration hazard for the API contract.
3. **`RETURN` type `S` does not mean persisted.** Every row in Run 1 was success-or-warning, with no error, for a document that was discarded.
4. **A header-only shipment is accepted.** `W VW 094` flags the missing deliveries as a warning, not an error — the BAPI does not require `ITEMDATA` to create.
5. **No shipment-cost document was auto-created.** `VFKK` and `VFKP` are still 0 rows after the committed shipment.

## Limits of claim 5

This shipment has **no deliveries, no service agent, no route**. Cost determination may legitimately have had nothing to act on. So this shows *shipment creation alone did not trigger costing here* — it does **not** yet prove that a fully-populated shipment would not trigger it. Closing that needs a shipment with deliveries and a carrier, which needs the DS4 master data still outstanding.

## Cleanup register

| Document | Status | Action |
|---|---|---|
| Shipment `0000001000` | Never persisted — number consumed only | None possible or required |
| Shipment `0000001001` | **Exists in DS4/200** | Disposable test artefact. Delete via `VT02N` when no longer needed for reference. |

## Evidence files

`RUN.txt` (Run 1 full result screen) · `RESULT_FULL.txt` (paged result) · `RETURN.txt` (7 rows) · `SEQ_RUN.txt` (Run 2 create) · `COMMIT_RUN.txt` (commit) · `POST_VTTK_no_commit.txt` · `POST_VTTK_after_commit.txt` · `VTTK_1001.txt`
