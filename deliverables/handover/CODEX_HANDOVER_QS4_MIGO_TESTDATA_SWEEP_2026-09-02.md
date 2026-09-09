# Handover — QS4 MIGO-pending STO/delivery sweep

**Date:** 2026-09-02  
**System:** QS4 / client 700  
**User:** QNOVATE8  
**Scope:** Read-only SAP GUI Scripting. No posting, update, reservation, BAPI execution, or commit was performed.

## Objective

Find the best STO outbound-delivery items for Submit MIGO testing where:

- movement 641 / PGI is complete;
- invoice exists in document flow;
- no movement 101 / GR-MIGO exists for the delivery item;
- the case is preferably a simple single item, non-batch-split delivery;
- multiple usable deliveries under one STO are preferred.

The real test object is **STO + Outbound Delivery + Delivery Item**, not the PO alone.

## SAP GUI scripting used

Session selection and checks were performed through SAP GUI Scripting only:

- `outputs/sap-gui-script/list-sap-sessions.vbs`
- `sessions/2026-08-31-testdata-revalidation/scripts/qs4_se16_read.vbs`

The reader starts SE16, selects QS4/700 by `SystemName` and `Client`, maps selection fields by name, and only reads table data.

Last observed session before handover:

- one connection / one session;
- QS4/700;
- SAP was in SE16, most recently reading VBFA;
- there was no modal and no transaction was posted.

## Live findings

### Best immediately usable pair

Both deliveries belong to **STO `5600074808`, item `00010`** and are simple, single-line, non-batch deliveries.

| Rank | Delivery / item | Qty | Material | Supplying plant/SLoc | PGI | Invoice | GR/MIGO |
|---|---|---:|---|---|---|---|---|
| 1 | `9004952820 / 000010` | `45.560 TO` | `14000035` | `1000 / CLYC` | `4918168082` | `1108024701` | **None in VBFA** |
| 2 | `9004952850 / 000010` | `46.340 TO` | `14000035` | `1000 / CLYC` | `4918167768` | `1108024611` | **None in VBFA** |

Verified delivery properties from LIPS:

- `PSTYV = ZNL`
- `BWART = 641`
- `WBSTA = C`
- `UECHA = 000000`
- batch blank
- `MEINS = VRKME = TO`
- referenced STO/item `5600074808 / 000010`

Verified receiving context from EKPO and earlier same-STO runtime evidence:

- receiving plant: `1006`
- `EKPO-LGORT` is blank;
- proven receiving SLoc from an earlier posted 101 on this same STO: `RMYD`;
- STO is not deleted or delivery-complete.

These two are the strongest candidates because they share one STO and directly support the delivery-level test: each delivery can be receipted independently without asking the caller for PO details.

### Candidate consumed since the previous sweep

Do **not** use `9004952821 / 000010`.

- It was previously preserved as the demo candidate.
- Live VBFA now contains GR material document `5007138761`, category `i`, quantity `45.610 TO`, posted `31.08.2026 17:52:07`.
- This proves the candidate pool changes and every delivery must be rechecked immediately before testing.

### Additional live backup candidates found

1. **Delivery `9004953166 / 000010`**
   - STO/item: `5600084215 / 000010`
   - material: `14000035`
   - delivery qty: `100 TO`
   - supplying plant/SLoc: `1000 / CLYC`
   - `PSTYV ZNL`, movement `641`, `WBSTA C`, no batch split
   - PGI: `4918168379`
   - invoice: `1108024807`
   - no `i`/GR row in live VBFA
   - EKPO receiving plant: `1025`; receiving SLoc is blank and still needs to be derived from a posted same-STO reference before using it.

2. **Delivery `9004953183 / 000010`**
   - STO/item: `5600084252 / 000010`
   - material: `17098816`
   - delivery qty: `1 EA`
   - supplying plant/SLoc: `1024 / RCPT`
   - `PSTYV ZNL`, movement `641`, `WBSTA C`, no batch split
   - PGI: `4918168434`
   - invoice: `1108024820`
   - no `i`/GR row in live VBFA
   - receiving plant/SLoc still need live EKPO and same-STO GR-pattern validation.

Candidate `9004953166` is the better backup because it matches the cement/TO shape, but do not test it until plant `1025` receiving SLoc is proven.

## Evidence interpretation

In this QS4 document flow:

- `R` = PGI/material movement;
- `M` = invoice;
- lowercase `i` = goods receipt/material document.

A candidate is accepted only when its delivery flow contains `R` and `M` but no active `i`. LIPS `WBSTA = C` alone is not enough, and absence from a small sampled list is not enough.

## Recommended continuation strategy

1. **Recheck `9004952820` and `9004952850` immediately before any test.** Query VBFA by `VBELV`; reject either if category `i` has appeared.
2. **Reserve one delivery for SE37 and the other for Postman/custom-wrapper testing.** Do not consume both in the same test.
3. **Complete the backup details:**
   - query EKPO for `5600084252/00010`;
   - identify a posted 101 on the same STO/receiving plant to prove receiving SLoc;
   - for `5600084215`, use posted delivery `9004953152` or `9004953184` to trace material documents `5007138556` / `5007138598` in MSEG and confirm the receiving SLoc for plant `1025`.
4. **Extend the sweep in bounded delivery-number ranges:**
   - read LIPS for `PSTYV ZNL`, `BWART 641`, `WBSTA C`, STO reference in `VGBEL`;
   - prefer `POSNR 000010`, `UECHA 000000`, positive `LFIMG`, blank batch;
   - group VBFA by delivery and keep only `R + M` without `i`;
   - then read EKPO/EKET and a same-STO posted MSEG precedent for receiving plant/SLoc.
5. **Do not post or commit during discovery.** Final execution should use a dedicated, owner-confirmed delivery with an open posting period.

## Bottom line

The current best test set is:

- **Primary:** `9004952820 / 000010`
- **Secondary:** `9004952850 / 000010`
- **Backup after SLoc validation:** `9004953166 / 000010`
- **Alternative non-cement EA case:** `9004953183 / 000010`

Do not use `9004952821`; it has already been receipted.
