# Findings — MIGO-pending candidate pool, extended sweep

**Date:** 2026-09-02
**System:** QS4 / client 700, user QNOVATE8
**Scope:** Read-only SE16 via SAP GUI Scripting. No posting, no update, no BAPI execution, no commit.
**Picks up from:** `deliverables/handover/CODEX_HANDOVER_QS4_MIGO_TESTDATA_SWEEP_2026-09-02.md`

The previous sweep found 4 candidates. This one swept the entire live delivery range and found
**33 usable MIGO-pending STO delivery items across 8 STOs** — 29 of them new.

## What was swept

Three bounded bands covering every delivery from `9004952400` to the highest number in the
system (`9004953367`, confirmed as the ceiling — LIPS returns nothing above it):

| Band | Delivery range | LIPS items read | ZNL/641/WBSTA C with quantity |
|---|---|---:|---:|
| C | `9004952400..9004952850` | 439 | 64 |
| B | `9004952851..9004953183` | 329 | 54 |
| A | `9004953184..9004954999` | 181 | 62 |

## Method — faster than per-delivery VBFA

Filtering happens locally, because the SE16 selection screen for LIPS exposes only
`VBELN, POSNR, WERKS, LICHN`. Read the band with `POSNR=000010`, then filter in the shell for
`PSTYV=ZNL`, `BWART=641`, `WBSTA=C`, `UECHA=000000`, blank `CHARG`, `LFIMG > 0`, `VGBEL` starting `56`.

To find which of those are already receipted, **query MSEG by `VBELN_IM` over the band with
`BWART=101`** rather than pulling VBFA per delivery. `VBELN_IM` *is* on the MSEG selection screen
(`EBELN` is not). One 66-row read replaced 333 individual VBFA queries. Candidates are then
`PGI-complete MINUS receipted`.

Both methods were run against band C independently and agreed on all 28 rows — the MSEG
subtraction and the VBFA `R + M + no i` grouping produce identical answers.

## The trap this method exposes

**A delivery with no GR in its own document flow can still be unusable.** Delivery `9004953151`
(STO `5600084239`, 2 EA) has no `i` row and no delivery-referenced material document — but the
STO line is fully received: EKET shows `MENGE 2.000 = WEMNG 2.000 = WAMNG 2.000`, consumed by
material document `5007138597`, which was posted **PO-referenced with `VBELN_IM` blank**. A
delivery-referenced MIGO against it would fail on zero open quantity.

So delivery-level flow is necessary but not sufficient. **Every candidate below has been checked
against EKET open quantity (`WAMNG − WEMNG`) as well.**

## The candidate pool

All rows: `PSTYV ZNL`, `BWART 641`, `WBSTA C`, `POSNR 000010`, `UECHA 000000`, no batch,
material `14000035` unless stated, flow `R + M` with no `i`, and STO open quantity confirmed.

### STO `5600074803` → plant 1005, SLoc `RMYD`, open **4,958.330 TO** — 18 deliveries

Supplying `1002 / CLYC`. The largest single pool by far.

`9004952595` 41.230 · `9004952596` 41.720 · `9004952597` 42.410 · `9004952598` 41.540
`9004952599` 41.040 · `9004952600` 41.750 · `9004952601` 41.090 · `9004952603` 42.140
`9004952604` 42.360 · `9004952605` 41.890 · `9004952606` 42.050 · `9004952607` 42.730
`9004952608` 42.220 · `9004952610` 42.040 · `9004952611` 41.910 · `9004952612` 41.930
`9004952613` 42.300 · `9004952614` 42.190   (all TO)

### STO `5600074902` → plant 1009, SLoc `RMYD`, open **1,588.960 TO** — 4 deliveries

Supplying `1002 / CLYC`. `9004952727` 41.160 · `9004952728` 41.260 · `9004952729` 41.900 · `9004952733` 41.200 TO

### STO `5600074903` → plant 1009, SLoc `RMYD`, open **1,007.580 TO** — 4 deliveries

Supplying `1002 / CLYC`. `9004952736` 41.540 · `9004952737` 41.840 · `9004952738` 41.430 · `9004952739` 41.420 TO

### STO `5600074808` → plant 1006, SLoc `RMYD`, open **364.190 TO** — 3 deliveries

Supplying `1000 / CLYC`. The previous sweep's primaries, plus one it missed:

- `9004952620` 44.920 TO — **new**
- `9004952820` 45.560 TO — rechecked, still clean
- `9004952850` 46.340 TO — rechecked, still clean

### STO `5600006418` → plant 1073, SLoc `RMYD`, open **1,473.600 TO** — 1 delivery

`9004952762` 57.480 TO, supplying `1070 / CLYC`. Largest single quantity in the pool.

### STO `5600083620` → plant 1000, SLoc `RMYD`, open **136.490 TO** — 1 delivery

`9004953014` 29.640 TO, material `14000009`, supplying `1000 / SGLM`.
Intra-plant STO — same plant on both sides, storage location `SGLM` → `RMYD`.
Receiving SLoc proven by many posted delivery-referenced 101s on this STO
(`5007137578`, `5007137684`, `5007137719`, `5007137730`, `5007137763`, `5007137764`, …).

### STO `5600084215` → plant 1025, SLoc `RMYD`, open **100 TO** — 1 delivery

`9004953166` 100 TO. SLoc proven by MSEG `5007138556` and `5007138598`, both `RMYD` at plant 1025.

### STO `5600084252` → plant 1022, SLoc `RCPT`, open **1 EA** — 1 delivery

`9004953183` 1 EA, material `17098816`. Correction to the previous handover: receiving plant is
**1022**, not 1024 — `1024 / RCPT` is the *supplying* side. SLoc derived from MARD: material
`17098816` at plant 1022 is extended to exactly one storage location, `RCPT`, `LVORM` blank.
No posted 101 precedent exists for this material at this plant, but the derivation is
unambiguous. Do not generalise from the `17035056` pattern at plant 1022 — that material
received into both `RCPT` and `FKGU`, so SLoc there is material-specific, not plant-wide.

## Receiving storage locations

Derived from MARD; material `14000035` has exactly one storage location at every receiving plant
in the pool, so there is no ambiguity:

| Plant | 1000 | 1005 | 1006 | 1009 | 1022 | 1025 | 1073 |
|---|---|---|---|---|---|---|---|
| SLoc | `RMYD` | `RMYD` | `RMYD` | `RMYD` | `RMYD` | `RMYD` | `RMYD` |

(`CLYC` appears only on supplying plants. Plant 1022's `RCPT` above applies to material
`17098816`, not to `14000035`.)

## Rejected

| Delivery | Why |
|---|---|
| `9004953151` (STO `5600084239`) | STO fully received via PO-referenced GR `5007138597`; no open quantity |
| `9004952821` | Receipted 31.08.2026, material document `5007138761` |
| `9004952843` | `WBSTA = A` — no PGI |
| `9004953211`–`9004953216`, `9004953273` | ZNL/641/C but `LFIMG = 0` |
| `9004953231` (STO `5600084257`) | Pending and open (1 EA, plant 1002) but batch-managed, `CHARG = TEST`, and material `17035251` is extended to nine storage locations at plant 1002 — receiving SLoc not derivable. Usable only as a deliberate batch case with owner-confirmed SLoc. |

## Corroboration that 9004952821 was consumed

EKET for `5600074808 / 00010`, `WEMNG`: 141,994.020 on 2026-08-31 → **142,039.630** today.
Delta **45.610 TO**, exactly the quantity receipted against `9004952821`. Confirms the previous
sweep's finding independently from the PO side.

## Recommended allocation

The `5600074803` cluster is the right default now: 18 interchangeable deliveries, one STO, one
receiving plant, ~4,958 TO of headroom. It can absorb SE37, Postman, custom-wrapper and
regression runs without any two tests colliding.

- SE37 / BAPI: `9004952595`
- Postman / custom wrapper: `9004952596`
- Regression and repeat runs: `9004952597` onward
- Second plant (1009) for a cross-plant case: `9004952727`
- EA / non-cement case: `9004953183` (plant 1022, `RCPT`)
- Intra-plant SLoc-to-SLoc case: `9004953014` (plant 1000, `SGLM` → `RMYD`)

Keep `9004952820` and `9004952850` in reserve — they are the two most thoroughly documented.

## Standing rule

The pool changes. `9004952821` was consumed between sweeps. Re-run the MSEG check immediately
before any test — one query covers the whole pool:

```
MSEG  VBELN_IM=9004952595..9004953183  BWART=101
```

Any candidate appearing in `VBELN_IM` has been receipted. Also re-read EKET for the STO to catch
PO-referenced GRs that never touch the delivery.

## Method notes for the next agent

- LIPS SE16 selection screen exposes only `VBELN, POSNR, WERKS, LICHN`. Filter the rest locally.
- MSEG SE16 selection screen exposes only `MBLNR, MJAHR, ZEILE, BWART, MATNR, WERKS, CHARG, VBELN_IM`.
  No `EBELN`. Reach a PO's material documents via `VBELN_IM`, or via `WERKS` + `BWART` + `MATNR`
  and read `EBELN` out of the result columns.
- **SE16 range reads drop the lowest-keyed entries.** `EKET EBELN=5600084215..5600084252` omitted
  `5600084215`; `EKET EBELN=5600074803..5600074903` started at `5600074805`. Single-value reads
  return them correctly. Verify any range-read boundary with a single-value read before trusting it.

## Evidence

`evidence/`, raw script output, one file per query.

Sweep: `LIPS_SWEEP_BAND_A/B/C.txt`, `MSEG_GR_BAND_B/C.txt`, `VBFA_SWEEP_BAND_A.txt`,
`VBFA_BAND_C_CANDIDATES.txt`
Derived: `BAND_*_PGI_DONE.txt`, `BAND_*_RECEIPTED.txt`, `BAND_*_NEW_CANDIDATES.txt`,
`BAND_C_FLOWSTATE.txt`
Per-object: `EKPO_*.txt`, `EKET_*.txt`, `MARD_*.txt`, `MSEG_*.txt`, `VBFA_9004952820/850/…txt`
