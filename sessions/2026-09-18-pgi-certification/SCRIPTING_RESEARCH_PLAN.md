# PGI research via SAP GUI scripting — query plan

**Date:** 2026-09-18
**System:** QS4 / 700, user `QNOVATE8`
**Posture:** READ-ONLY throughout. Nothing posted, changed, activated or committed.
**Tooling:** reuse the proven scripts in
`sessions/2026-08-18-runtime-certification/scripts/`. No new tooling is needed.

---

## Ground rules

Carried forward from the August and September sessions. Each was learned the hard way.

1. **One SAP GUI automation at a time.** Verify `SystemName = QS4` and `Client = 700` before
   any action — `qs4_se16_read.vbs` already refuses anything else. Never locate the session by
   index.
2. **Run `qs4_se16_fields.vbs <TABLE>` before reading any table you have not read before.**
   SE16 selection fields are positional (`I1-LOW`, `I2-LOW`, …) and are `txt` on some tables
   and `ctxt` on others. Guessing produces a silent unfiltered read.
3. **The ALV lazy-loads.** `qs4_se16_read.vbs` pages via `FirstVisibleRow`, but it caps at 200
   rows. For anything wider, narrow the filter rather than raising the cap.
4. **`_` (0x5F) sorts above `Z` (0x5A).** A range ending `...ZZZZ` silently drops every name
   containing an underscore. Use `Z..Z~` (`~` = 0x7E).
5. **Names truncate at 30 characters** in class and service fields.
6. **Abort on any unexpected modal.** The scripts already do this. Do not add dismissals.
7. **Capture raw output per query to its own file.** Do not summarise in place.

Invocation, for reference:

```
cscript //nologo qs4_se16_read.vbs <TABLE> <MAXROWS> [<selFieldId>=<VALUE> ...]
cscript //nologo qs4_se16_fields.vbs <TABLE>
```

---

## Block A — Finish the enhancement registry

**Answers:** what custom logic exists on the delivery and goods-issue path.
**Status:** partially done — see `DELIVERY_GI_ENHANCEMENT_FINDINGS.md`. 24 enhancements
already identified from existing evidence. These queries close the gaps the September sweep
left open.

| # | Table | Filter | Answers |
|---|---|---|---|
| A1 | `ENHHEADER` | `ENHNAME = Y..Y~`, `VERSION = A` | **The `Y*` namespace was never swept.** A `Y` enhancement on the delivery path is invisible today. The current count of 24 is a floor. |
| A2 | `ENHOBJ` | `ENHNAME = Y..Y~`, `VERSION = A` | Which objects those touch |
| A3 | `ENHINCINX` | the 13 transaction-layer enhancement names | **The exact routine each plug-in sits in.** This is what decides whether an OData caller reaches it. Highest value in this block. |
| A4 | `MODATTR` | the CMOD projects from `MODACT_ALL.txt` | Whether the classic exits are actually active |
| A5 | `MODSAP` | delivery exits — `V02V*`, `V50*`, `V50S*`, `V50R*`, `LMELA*` | Classic customer exits on delivery processing |
| A6 | `SMODILOG` | `OBJ_NAME = MV5..MV6`, then `LV5..LV6`, then `SAPMV5..SAPMV6` | Hand modifications to delivery programs. MIGO came back clean; delivery is unchecked. |
| A7 | `TBE01` / `TBE31` / `TPS34` | — | Business Transaction Events. Never swept. |
| A8 | `GB01` / `GB92` | — | Validations and substitutions. Never swept. |
| A9 | `SXC_ATTR` / `SXC_EXIT` | `ZLE_SHP_DELV_INTECO`, `ZSDEI_DELIVERY` | Active flags on the classic BAdI implementations found in `ENHOBJ` |

---

## Block B — Does PGI actually require a shipment in this system

**Answers:** whether the client has a rule standard SAP does not impose.
**This is the question from the last discussion, and it is answerable read-only.**

### B1 — Find a goods-issued delivery with no shipment

The decisive query. If even one exists, PGI without a shipment is demonstrated **in their
configuration**, not just in standard SAP.

1. Read `LIKP` — `WBSTK = C`, `LFART = ZNL`, 50 rows. Capture the `VBELN` list.
2. For each `VBELN`, read `VTTP` filtered on it.
3. Any delivery with **zero** `VTTP` rows was goods-issued without ever being on a shipment.

Run the `VTTP` reads sequentially, one `VBELN` at a time. Do not batch — a blank result from a
mis-set filter is indistinguishable from a true zero, so each read must be individually
verifiable.

**Also run it for other delivery types.** A `ZNL`-only answer does not generalise, and a
non-`ZNL` positive still tells you the system permits it.

### B2 — Does settlement gate PGI

Flagged as the highest-value outstanding read since 2026-08-18 and still unrun.

1. Read `VFKK` where `STABR = A` — settlement relevant, started, **not finished**.
2. For each, `VFKP` → `REBEL` gives the shipment `TKNUM`.
3. `VTTP` on that `TKNUM` gives the deliveries.
4. `LIKP-WBSTK` on those deliveries.

**If any shows `WBSTK = C`,** goods were issued while a relevant settlement was incomplete —
settlement is a business rule, not a technical gate, and PGI can be exposed independently of
the freight chain. That materially shrinks the OF-05 dependency.

The existing counter-example (`0180915535`) does **not** answer this: its cost document was
type `Z006`, settlement-*irrelevant*. `STABR = A` is the relevant-but-incomplete case.

### B3 — Read the candidate rule in source

`ZSD_SHIP_CHECK` and `ZSD_DEL_SAVE_CHECK`, both on `MV50AFZ1`. If a coded shipment
prerequisite exists, it is most likely one of these. Pair with A3 to establish whether the
routine they sit in is reachable from outside the dialog.

---

## Block C — How storage location reaches the delivery item

**Answers:** whether the caller must supply it, and if so how.
**Removes the need to post anything to answer the picking question.**

| # | Table | Filter | Answers |
|---|---|---|---|
| C1 | `T184L` | plant `1002` | **Storage location determination config for deliveries.** If rules exist for this plant, SAP derives `LGORT` automatically and the caller never supplies it. Run `qs4_se16_fields.vbs T184L` first — key structure needs confirming. |
| C2 | `TVLP` | the item category on `9004953174/000010` | Picking relevance. If the item is not picking-relevant, the storage-location question changes shape entirely. |
| C3 | `TVLK` | `ZNL` | Delivery type config — picking, PGI relevance, number ranges |
| C4 | `LIPS` | a `ZNL` delivery with `WBSTK = C` on its header | **What a completed one looks like.** Is `LGORT` on the main line, only on `9000xx` split lines, or both? Compare `UECHA`, `CHARG`, `LGORT`, `LFIMG` across the line set. |

C4 is the direct empirical answer to the hypothesis in `PLAN.md` §3. **It needs no post.**
Take three or four completed `ZNL` deliveries rather than one — a single document could be
atypical.

---

## Block D — What a completed PGI looks like here

**Answers:** what to expect, and what to reconcile against afterwards.

| # | Table | Filter | Answers |
|---|---|---|---|
| D1 | `LIKP` | `LFART = ZNL`, `WBSTK = C`, recent | Pick reference documents |
| D2 | `MSEG` | the material document from D1's flow | **Actual movement type.** Settles `601` vs `641`, and whether it varies. |
| D3 | `MKPF` | same | Header — document type, posting date, user |
| D4 | `VBFA` | the delivery | What document flow PGI writes. `VBFA` is empty before PGI on an STO delivery — this shows what appears after. |
| D5 | `EKBE` | the STO | Which history row type a goods issue writes |

---

## Block E — Re-baseline the test document

| # | Table | Filter | Answers |
|---|---|---|---|
| E1 | `LIKP` | `VBELN = 9004953174` | Still `WBSTK = A`? Unchanged since 21.08.2026? |
| E2 | `LIPS` | `VBELN = 9004953174` | Still one line, `LGORT` blank, no batch? |
| E3 | `MCHB` | material `000000000015000177`, plant `1002` | **Which batches actually carry stock.** Needed to nominate a batch for the authorisation request — currently an open item in that document. |

E3 closes an open dependency in `QS4_WRITE_AUTHORISATION_REQUEST.md`: it asks the functional
owner to nominate a batch. Running E3 first lets you propose candidates rather than wait.

---

## Suggested order

Two sittings. Nothing here needs the write window.

**Sitting 1 — answers the scope question**
1. Read the two `MB_GOODSMOVEMENT` classes already on disk — no SAP needed
2. A3 (`ENHINCINX`) — settles the reachability of 13 enhancements
3. B3 — read `ZSD_SHIP_CHECK`, `ZSD_DEL_SAVE_CHECK`
4. Read `ZCLLE_UPDATE_DELIVERY_CUSTOM1`, then E1/E2 to check its effect on `9004953174`

**Sitting 2 — answers the sequencing and mechanics questions**
5. B1, B2 — shipment and settlement dependency
6. C1–C4 — storage location
7. D1–D5 — expected PGI result
8. A1, A2 — the `Y*` gap
9. E3 — batch candidates

---

## Output layout

```
sessions/2026-09-18-pgi-certification/
  evidence/
    A3_ENHINCINX_DELIVERY.txt
    B1_LIKP_WBSTK_C_ZNL.txt
    B1_VTTP_<VBELN>.txt          one per delivery checked
    B2_VFKK_STABR_A.txt
    C1_T184L_1002.txt
    C4_LIPS_<VBELN>.txt
    D2_MSEG_<MBLNR>.txt
    E1_LIKP_9004953174.txt
    E3_MCHB_15000177_1002.txt
  src/
    ZCLLE_UPDATE_DELIVERY_CUSTOM1.txt
    ZSD_SHIP_CHECK.txt
    ...
  FINDINGS.md
```

Keep the raw script output verbatim, including the `SESSION|`, `FILTER|` and `SBAR|` lines —
they are the proof of what was actually queried. Per repository discipline, label every
material claim Verified, Strong inference, Hypothesis, Contradicted or Unknown, and never
promote a blank result into a negative finding without confirming the filter was applied.
