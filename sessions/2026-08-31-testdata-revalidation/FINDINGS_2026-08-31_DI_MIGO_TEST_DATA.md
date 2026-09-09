# DI and MIGO replacement test data — read-only revalidation

**Date:** 2026-08-31 · **System/client:** QS4/700 · **User:** QNOVATE8 · **Method:** SAP GUI Scripting, SE16 only.

**Nothing was posted, changed, executed or reserved.** No BAPI was run, no delivery created, no PGI,
no goods receipt, no configuration. Session was selected by `SystemName=QS4` + `Client=700`, never by
connection index. All evidence files are new; no existing evidence was overwritten.

**Availability is not a posting guarantee.** QS4 is shared. Every candidate below must be rechecked
immediately before any execution — the 25 Aug pack is proof of exactly that (see §1).

## Label key

| Label | Meaning |
|---|---|
| **historical candidate** | Named in `deliverables/BAPI_DEMO_CANDIDATES_2026-08-25.md`; status as of 25 Aug |
| **currently checked candidate** | Read from live QS4 tables today, 31 Aug |
| **runtime-proven** | An actual posted SAP document observed today (not an inference) |

---

## 1. What changed since 25 August — read this first

The 25 Aug pack is **materially stale**. Two of its four candidates moved.

| 25 Aug claim | Today's reading | Verdict |
|---|---|---|
| DI A `5600084222` — `EKET-WEMNG = 0` | `WEMNG = 100.000`, `WAMNG = 100.000` | **changed** |
| DI B `5600084223` — `EKET-WEMNG = 0`, "reserved for tomorrow" | `WEMNG = 100.000`, `WAMNG = 100.000`; **4 further deliveries created** | **changed; reservation stale** |
| MIGO A `9004952821` — no 101 | still no 101 | **holds** |
| MIGO B `9004953161` — "exact query for 101 returned no rows" | **101 posted 26.08.2026** | **CONSUMED** |

**MIGO candidate B is gone.** Runtime-proven: material document `5007138638/2026`, movement `101`,
`52.330 TO`, `WERKS 1025`, `LGORT RMYD`, `EBELN 5600084246/00010`, `VBELN_IM 9004953161/000010`,
`SMBLN` blank (not reversed). Evidence: `evidence/MSEG_5007138638.txt`.

It was posted on 26 Aug — the day after it was written down as "reserved for tomorrow — do not touch".
Do not present it as a fresh candidate.

## 2. Method note — how "no goods receipt" was proven

The brief forbids treating a sampled absence as proof. Absence was therefore established through
`VBFA` document flow, and **the method was validated against a known-positive control**:

- Control: delivery `9004953161` (known consumed) → `VBFA` returns `VBTYP_N = i`, `VBELN 5007138638`,
  `RFMNG 52.330`. Evidence: `evidence/VBFA_9004953161_CONTROL.txt`.
- So `VBTYP_N = 'i'` **does** record the goods receipt in this system, and its absence is meaningful.
- Candidate queries were run as bounded ranges that returned **without** the "Selection restricted"
  status, i.e. complete for the range, not truncated samples.

`VBFA` range `9004952818..9004952852` returned 91 rows uncapped — complete.
Evidence: `evidence/VBFA_9004952818_9004952852.txt`.

## 3. MIGO alternatives — ranked

All three sit on **STO `5600074808/00010`**, so they share one verified PO context.

**Shared PO context** (`evidence/EKPO_5600074808.txt`, `evidence/EKET_5600074808.txt`):

| Field | Value |
|---|---|
| `EKPO-LOEKZ` / `ELIKZ` | blank / blank — not deleted, not delivery-complete |
| `EKPO-PSTYP` | `7` (stock transfer) |
| `EKPO-MATNR` | `14000035` |
| `EKPO-WERKS` (receiving plant) | `1006` |
| `EKPO-LGORT` | **blank** — receiving SLoc must be supplied on the posting |
| `EKET-MENGE` | `500,000.000 TO` |
| `EKET-WEMNG` (received) | `141,994.020 TO` |
| `EKET-WAMNG` (issued) | `142,403.820 TO` |
| **Open receivable** | **`358,005.980 TO`** |
| **Currently in transit** | `409.800 TO` (issued − received) |

`WEMNG` is unchanged from the 25 Aug figure, so no GR has been posted on this STO since.

**Receiving storage location — runtime-proven.** The 25 Aug pack inferred `RMYD` from "500 sampled
historical rows". Today it is proven from a real posted document *on this same STO*: material document
`5007138493/2026`, movement `101`, `WERKS 1006`, `LGORT RMYD`, `MATNR 14000035`, `CHARG` blank,
`EBELN 5600074808/00010`, `VBELN_IM 9004946805/000010`. Evidence: `evidence/MSEG_5007138493_STO_GR_PATTERN.txt`.

Note that GRs on this STO post as **two lines** (e.g. `45.980` + `0.180`) — a quantity-variance split.
A single-line GR is still valid; just do not be surprised by the historical pattern.

### Ranked candidates

| Rank | Delivery / item | Qty | Label | GI (641) | GR (101) |
|---|---|---|---|---|---|
| **1** | `9004952821 / 000010` | `45.610 TO` | historical candidate A — **revalidated, still clean** | `4918167646` | **none** |
| **2** | `9004952820 / 000010` | `45.560 TO` | currently checked candidate (new) | `4918168082` | **none** |
| **3** | `9004952850 / 000010` | `46.340 TO` | currently checked candidate (new) | `4918167768` | **none** |

All three, from `evidence/LIPS_MIGO_CANDIDATES.txt`:

- `PSTYV = ZNL`, `MATNR = 14000035`, `VGBEL = 5600074808`, `VGPOS = 000010`, `BWART = 641`
- Supplying `WERKS 1000`, `LGORT CLYC`
- `CHARG` blank and `UECHA = 000000` → **non-batch, no batch split**
- Single item each (`POSNR 000010` only)
- `WBSTA = C` → **fully goods-issued**, stock is in transit
- `VRKME = MEINS = TO`

Document flow per candidate (`evidence/VBFA_9004952821.txt`, `evidence/VBFA_9004952818_9004952852.txt`):
each shows shipment (`VBTYP_N=8`), goods issue (`R`) and invoice (`M`) — and **no `i` row**.

**Also checked and rejected:** every other TO delivery on this STO in the `9004952974..9004952988`
band is already receipted (`9004952975/78/79/84/85/87` all carry an `i` row);
`9004952843`, `9004952974`, `9004952988` have no document flow at all, i.e. never goods-issued, so they
cannot be received. Evidence: `evidence/VBFA_9004952974_9004952988.txt`.

## 4. DI alternatives — ranked

| Rank | STO / item | Material | Recv. plant | `VSTEL` | Route | PO qty | Delivered | **Open** | Label |
|---|---|---|---|---|---|---|---|---|---|
| **1** | `5600084274 / 00010` | `14000020` | `1026` | `1002` | `N10000` | `5,000 TO` | `100 TO` | **`4,900 TO`** | currently checked candidate (new) |
| **2** | `5600084222 / 00010` | `14000035` | `1022` | `1002` | `R56407` | `1,000 TO` | `101 TO` | **`899 TO`** | historical candidate A — revalidated |
| **3** | `5600084223 / 00010` | `14000035` | `1023` | `1002` | `R56408` | `1,000 TO` | `250 TO` | **`750 TO`** | historical candidate B — revalidated, reservation stale |

All three: `LOEKZ` blank, `ELIKZ` blank, `PSTYP = 7`, `MEINS = TO`, single item.
Evidence: `evidence/EKPO_DI_CANDIDATES.txt`, `evidence/EKET_DI_CANDIDATES.txt`,
`evidence/EKPV_DI_CANDIDATES.txt`, `evidence/EKPO_STO_POOL.txt`, `evidence/EKET_STO_POOL.txt`,
`evidence/EKPV_STO_POOL.txt`, `evidence/EKBE_DI_CANDIDATES.txt`, `evidence/EKBE_5600084274.txt`.

**Rank 1 detail — `5600084274/00010`.** `EINDT = 30.09.2026`, `WEMNG = 0`, `WAMNG = 0`, `DABMG = 0`,
`KUNNR = P1026`. Five deliveries already created against it on 27.08 (`9004953317`–`9004953321`,
20 TO each), **none goods-issued**. That is *runtime-proven evidence that delivery creation works on
this STO* — stronger than an untouched STO with no track record. It is not in the 25 Aug pack, so it
carries no reservation history.

*Caveat:* `EINDT` is `30.09.2026`, in the future. The 27.08 deliveries prove creation still succeeds,
but set `DUE_DATE` to cover the schedule date rather than copying today's date blindly.

**Rank 2 detail — `5600084222/00010`.** `EINDT = 20.08.2026`. Deliveries: `9004953191` (50 TO, GI+GR),
**`9004953278` (1 TO, open — no GI)**, `9004953303` (50 TO, GI+GR). The 1 TO delivery is the 25 Aug
rehearsal, created 26.08 and never dispatched.

**Rank 3 detail — `5600084223/00010`.** Deliveries: `9004953192` (50, GI+GR), `9004953304`,
`9004953314`, `9004953325` (50 TO each, **open, no GI**), `9004953332` (50, GI+GR). It was flagged
"reserved for tomorrow — do not touch" on 25 Aug and has since taken four more deliveries; treat the
reservation as expired, but confirm with the owner before use.

### Rejected during the bounded search

Untouched STOs with open quantity but **blank `EKPV-ROUTE`** — `5600084259` (`VSTEL 5002`),
`5600084260`, `5600084262`, `5600084267` (all `VSTEL 1022`, 500 TO each, material `15000114`).
Zero `EKBE` rows, so genuinely unused — but a blank route is a plausible delivery-creation blocker
and none has a success track record. Not recommended without a route check first.
`5600084276` and `5600084271` are multi-item `EA` spare-parts STOs — not simple cases.

## 5. Connected end-to-end flow (DI → dispatch → MIGO)

**Not available as a single ready-made case today, and none can be made without postings.**

The DI candidates (§4) and MIGO candidates (§3) sit on **different STOs** — `5600084274`/`5600084222`
versus `5600074808`. They are separate cases and must not be presented as one connected flow. This is
the same distinction the brief draws about DI `9004953174` and MIGO `5007138616`.

**Closest available starting point:** STO `5600084222/00010` already carries delivery
**`9004953278/000010`** — 1 TO, non-batch, `UECHA = 000000`, `WBSTA = A` (not goods-issued),
`VGBEL 5600084222/000010`. The DI leg is already done; only dispatch and receipt remain.

Steps still required, none of which were executed:

1. **Assign the supplying storage location.** `LIPS-LGORT` on `9004953278` is **blank** (supplying
   `WERKS 1002`). PGI will not post without a source SLoc. The proven MIGO deliveries by contrast
   carry `LGORT = CLYC`. This is the first concrete blocker.
2. **Post goods issue (641)** — `VL02N`/`VL06O` or `BAPI_OUTB_DELIVERY_CONFIRM_DEC`. Moves stock to
   in-transit and sets `WBSTA = C`.
3. **Post goods receipt (101)** — `BAPI_GOODSMVT_CREATE`, `MVT_IND = B`, referencing PO `5600084222/00010`
   and delivery `9004953278/000010`, receiving plant `1022`.

Other blockers to clear first: stock availability at the supplying plant/SLoc at PGI time; posting
period open for the intended posting date; and the receiving SLoc for plant `1022` (`EKPO-LGORT` is
blank on this STO too, and the `RMYD` precedent proven in §3 is for plant `1006`, **not** `1022` —
do not carry it across).

Same shape applies to the three open deliveries on `5600084223` (`9004953304`, `9004953314`,
`9004953325`, 50 TO each) and the five on `5600084274` (`9004953317`–`9004953321`, 20 TO each).

## 6. Test versus preserve

| Purpose | Recommendation | Why |
|---|---|---|
| **Preserve for demonstration** | MIGO `9004952821/000010` | Historical candidate A; the 25 Aug pack already carries a complete pre-computed `GOODSMVT_ITEM` payload (`ENTRY_QNT 45.610`, `STGE_LOC RMYD`, `MVT_IND B`). Keep it clean. |
| **Use for duplicate-submission testing** | MIGO `9004952820/000010`, then `9004952850/000010` | Newly identified, identical shape and STO, no documentation dependency. Burning one costs nothing. |
| **Use for DI testing** | DI `5600084274/00010` | 4,900 TO open, proven creation track record, no reservation history. |
| **Preserve for demonstration** | DI `5600084222/00010` | Documented in the 25 Aug pack with a ready `STOCK_TRANS_ITEMS` payload; 899 TO still open. |
| **Confirm before use** | DI `5600084223/00010` | Reservation is stale but was explicitly flagged "do not touch"; ask the owner. |

## 7. Recommendation

Replacement data exists and is sufficient — **two MIGO alternatives and two DI alternatives are
available today without touching anything reserved.**

For duplicate-submission testing use **MIGO delivery `9004952820/000010`** (45.560 TO, STO
`5600074808/00010`, receive into plant `1006` / SLoc `RMYD`), keeping `9004952850/000010` as the
second, and **preserve `9004952821` for the demonstration**. For DI use **STO `5600084274/00010`**.

Treat MIGO candidate B (`9004953161`) as consumed and remove it from the pack.

No connected DI→MIGO flow is available without executing a PGI, which is outside this task's
boundaries. If one is needed, the cheapest route is delivery `9004953278/000010` on STO
`5600084222/00010` — but its blank supplying storage location must be resolved first, and the
receiving SLoc for plant `1022` established independently rather than assumed from the plant `1006`
precedent.

Recheck every value immediately before execution.

## 8. Evidence index

| File | Contents |
|---|---|
| `evidence/EKPO_DI_CANDIDATES.txt` | `EKPO` for `5600084222`–`5600084223` |
| `evidence/EKET_DI_CANDIDATES.txt` | `EKET` schedule/quantities, same STOs |
| `evidence/EKPV_DI_CANDIDATES.txt` | `EKPV` shipping point / route, same STOs |
| `evidence/EKBE_DI_CANDIDATES.txt` | Full PO history, same STOs |
| `evidence/VBFA_DI_CANDIDATES.txt` | `VBFA` on the STO numbers — nil (STO deliveries link via `LIPS-VGBEL`) |
| `evidence/EKBE_MIGO_5600084246.txt` | PO history showing candidate B's GR |
| `evidence/MSEG_5007138638.txt` | **Proof candidate B was consumed 26.08** |
| `evidence/VBFA_9004953161_CONTROL.txt` | **Positive control validating the `VBTYP_N=i` method** |
| `evidence/VBFA_9004952821.txt` | Candidate 1 flow — no `i` row |
| `evidence/VBFA_9004952818_9004952852.txt` | Complete (91 rows, uncapped) flow for candidates 2 and 3 |
| `evidence/VBFA_9004952974_9004952988.txt` | Neighbouring deliveries — all consumed |
| `evidence/LIPS_MIGO_CANDIDATES.txt` | Delivery items for all three MIGO candidates |
| `evidence/LIPS_OPEN_DELIVERIES.txt` | Open (non-GI) deliveries incl. `9004953278` |
| `evidence/EKPO_5600074808.txt`, `evidence/EKET_5600074808.txt` | MIGO PO context and open receivable |
| `evidence/MSEG_5007138493_STO_GR_PATTERN.txt` | **Runtime-proven receiving SLoc `RMYD` on this STO** |
| `evidence/MSEG_5007138391_SLOC_REF.txt` | Rejected reference — belongs to STO `5600083620`, not ours |
| `evidence/EKPO_STO_POOL.txt`, `EKET_STO_POOL.txt`, `EKPV_STO_POOL.txt`, `EKBE_STO_POOL.txt`, `EKBE_5600084274.txt` | Bounded search for DI alternatives |
| `evidence/FIELDMAP_EKPO.txt`, `FIELDMAP_VBFA.txt`, `FIELDMAP_LIPS.txt` | SE16 selection-screen field maps |
| `scripts/qs4_se16_read.vbs` | Read-only SE16 reader used for all of the above |

### Tooling note

`sessions/2026-08-31-testdata-revalidation/scripts/qs4_se16_read.vbs` was written for this task because
the existing helpers were not adequate: `tmp/qs4_se16_bounded.vbs` caps output at 10 rows and has no
column set for `EKBE`/`MSEG`, and its filters take raw GUI control ids rather than field names. The new
reader maps selection fields by name from the screen labels and dumps only the requested columns.

A first attempt used `SE16N`; its filter failed to bind and it ran an **unfiltered 500-row `LIPS`
select**, then hung dumping ~300 columns per row. That script was killed. It was a read-only `SELECT`
— no data was changed — and SAP was left on the SE16N result screen, verified clean afterwards.
`SE16N` was abandoned in favour of `SE16` for this reason.
