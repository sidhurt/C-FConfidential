# Prompt for a local Claude Code session with SAP GUI access

Paste everything below the line into a local Claude Code session running on the Windows
machine that has SAP GUI open and logged into QS4/700.

---

You are working in the `C-FConfidential` repository on the branch
`claude/trusting-shannon-gjzo5d`. Pull the latest first — a cloud session has just pushed the
session directory you will be working in.

## Your job

Run a **read-only** SAP GUI scripting sweep against QS4/700 to determine the development
scope for the Create PGI API. Capture evidence, then write findings.

**You are NOT posting, creating, changing, activating or committing anything in SAP.** No
write of any kind. If a script would change SAP state, stop and say so instead of running it.

## Read these first, in this order

1. `AGENTS.md` — repository operating rules, especially evidence discipline and safety
2. `sessions/2026-09-18-pgi-certification/DELIVERY_GI_ENHANCEMENT_FINDINGS.md` — what has
   already been established and what is still unknown
3. `sessions/2026-09-18-pgi-certification/SCRIPTING_RESEARCH_PLAN.md` — the query blocks
4. `sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md` — the nine-registry method
   you are reusing

## Tooling — reuse, do not rewrite

The working scripts are in `sessions/2026-08-18-runtime-certification/scripts/`:

- `qs4_se16_read.vbs <TABLE> <MAXROWS> [selFieldId=VALUE ...]` — read-only SE16 reader. It
  locates QS4/700 by system name, refuses any other system, pages the ALV, and aborts on an
  unexpected modal.
- `qs4_se16_fields.vbs <TABLE>` — lists selection-screen field ids with their labels.
- `se24_open_display.vbs`, `ds4_fm_src2.vbs` — navigation patterns for reading class and
  function module source. Note `se24_open_display.vbs` is hardcoded to DS4/200 — **if you
  adapt it for QS4/700, keep the system guard and change only the expected values.**

Invoke with 64-bit `cscript //nologo`. PowerShell COM does not work on this machine.

Do not write a new general-purpose reader. If you need something the existing scripts cannot
do, write the smallest possible addition and keep the QS4/700 guard.

## Hard-won traps — do not rediscover these

- **Run `qs4_se16_fields.vbs <TABLE>` before reading any table for the first time.** SE16
  selection fields are positional (`I1-LOW`, `I2-LOW`, …) and are `txt` on some tables and
  `ctxt` on others. A wrong id silently produces an *unfiltered* read that looks like a valid
  result.
- **A blank result is not a negative finding** until you have confirmed the filter was
  actually applied. Check the `FILTER|` and `SBAR|` lines in the script output every time.
- **`_` (0x5F) sorts above `Z` (0x5A).** A range ending `...ZZZZ` silently excludes every name
  containing an underscore. Use `Z..Z~` and `Y..Y~`.
- **The ALV lazy-loads.** The reader caps at 200 rows. If you need more, narrow the filter
  rather than raising the cap.
- **Class and service names truncate at 30 characters.**
- **One SAP GUI automation at a time.** Sequential only.
- Verify `SystemName` and `Client` before every run. Never locate the session by index.

## Priority order

Work top down. Stop and report if anything contradicts the existing findings.

### Priority 1 — reachability of the transaction-layer enhancements

Thirteen `Z` enhancements sit on `SAPMV50A` / `MV50AFZ1` / `SAPFV50C`. Whether an external
OData caller reaches them is **the** scope question and is not answerable from the registry
alone.

Pull `ENHINCINX` for these enhancement names and record the program, include, method and
`FULL_NAME` for each — that gives the exact routine each plug-in sits in:

```
ZSD_SHIP_CHECK              ZSD_DEL_SAVE_CHECK           ZEI_LE_VALIDATE_TRANSPOTER
ZEI_LE_VALIDATE_YSTO        ZSD_RESTRICT_GRN             ZZ_LE_BIDDING_QTY
ZEI_SD_UPDATE_DELBILLINGTYPE ZEI_LE_UPDATE_DELIVERY_HEAD ZZCRM_DI_SEND
ZEI_SD_CHANGE_CALC_TPE      ZEI_LE_ADD_CHECK_BUTTON_HEAD ZEI_LE_ADD_CHECK_BUTTON_PAI
ZSDENH_CLEAR_SHIPPING_DATA
```

A routine reached only from the dialog program is not reachable by OData. A routine inside
delivery processing generally may be. **State which you cannot determine rather than
guessing.**

### Priority 2 — read the source of the unread enhancements

No `LE_SHP_DELIVERY_PROC`, `ES_SAPLV50I_BADI` or `MV50AFZ1` source has ever been captured.
The September extraction covered the MIGO family only.

Capture source for, in this order:

1. **`ZCLLE_UPDATE_DELIVERY_CUSTOM1`** — implements `IF_DLV_CREATE_STO_EXTIN` on
   `ES_SAPLV50I_BADI`. This is on the STO delivery-creation path that Create DI used. **This
   is the highest-value single read in the whole sweep** — see Priority 3.
2. `ZCLLE_UPDATE_DELIVERY_CUSTOM` — the sales-order sibling (`IF_DLV_CREATE_SLS_EXTIN`),
   which is the Trade/Non-trade path
3. `ZSD_SHIP_CHECK` and `ZSD_DEL_SAVE_CHECK` — a coded shipment or settlement prerequisite,
   if one exists, is most likely here
4. The six `LE_SHP_DELIVERY_PROC` classes: `ZCLLE_DELIVERY_PROCESS`,
   `ZCL_IM_LE_SHP_DELV_INTECO`, `ZCL_IM_LE_SHP_DELIVERY_PROC`, `ZCL_IM_SDEI_DELIVERY`, plus
   whatever classes back `ZSD_DELV_ATT_EHC` and `ZUCCSDE034_LIC_NOTIF`

Save each under `sessions/2026-09-18-pgi-certification/src/`, following the naming pattern in
`sessions/2026-09-02-migo-customisation-inventory/src/`.

For each, record: which methods are implemented, whether each has a real body or is empty,
and any guard that would stop it executing for an external caller — `sy-tcode` checks,
`sy-batch`, `sy-binpt`, a transaction-specific field-symbol assignment, or a hardcoded user.

**The two posting-layer classes were already read and both turned out inert for PGI. Expect
some of these to be the same.** Empty and guarded methods are a real finding — record them as
firmly as active ones.

### Priority 3 — the decisive experiment

`ZEI_LE_UPDATE_DELIVERY_CUSTOM1` implements the STO delivery-creation extension. Delivery
`9004953174` was created through OData on that path on 21.08.2026.

1. Read the class. Determine exactly what it writes and to which fields.
2. Read `LIKP` and `LIPS` for `9004953174` and check whether that effect is present.

- **Effect present** → the OData path reaches client BAdI code. Say so plainly; it changes the
  "standard service" framing for the whole workbook.
- **Effect absent** → the OData path bypasses it, as `BAPI_GOODSMVT_CREATE` bypasses the
  MIGO-runtime BAdIs. The scope question becomes what the business needs from the 24 and how
  to reach it.
- **The class writes nothing observable** → say that, and explain why the test cannot decide.

This is worth more than any other single result in the sweep. Do not skip it because an
earlier priority is unfinished.

### Priority 4 — does PGI require a shipment in this configuration

1. `LIKP` where `WBSTK = C` and `LFART = ZNL`, 50 rows. Capture the `VBELN` list.
2. For each `VBELN`, read `VTTP` filtered on it — **sequentially, one at a time.**
3. Any delivery with zero `VTTP` rows was goods-issued without ever being on a shipment.

Also run it for at least one non-`ZNL` delivery type; a `ZNL`-only answer does not generalise.

A single confirmed case proves PGI does not require a shipment **in this configuration**, not
merely in standard SAP. Given trap 2 above, verify the filter was applied on every zero
result before you report it.

### Priority 5 — does settlement gate PGI

Flagged as the highest-value outstanding read since 2026-08-18 and still unrun.

1. `VFKK` where `STABR = A` — settlement relevant, started, not finished
2. `VFKP` → `REBEL` gives the shipment `TKNUM`
3. `VTTP` on that `TKNUM` gives the deliveries
4. `LIKP-WBSTK` on those deliveries

Any `WBSTK = C` means goods were issued while a *relevant* settlement was incomplete —
settlement is a business rule, not a technical gate.

The known counter-example `0180915535` does **not** answer this: its cost document was type
`Z006`, which is settlement-irrelevant. You need the relevant-but-incomplete case.

### Priority 6 — storage location, and the rest

- `T184L` for plant `1002` — storage location determination. If rules exist, SAP derives
  `LGORT` and the caller never supplies it. **This answers the picking question without
  posting anything.** Run the fields script first; the key structure needs confirming.
- `TVLP` for the item category on `9004953174/000010` — picking relevance
- `TVLK` for `ZNL` — delivery type config
- `LIPS` for three or four completed `ZNL` deliveries — is `LGORT` on the main line, only on
  `9000xx` split lines, or both? Compare `UECHA`, `CHARG`, `LGORT`, `LFIMG` across the line set
- `MSEG` / `MKPF` for their material documents — settles `601` vs `641` from real data
- `VBFA` for a completed delivery — what document flow PGI actually writes
- `ENHHEADER` and `ENHOBJ` with `Y..Y~`, `VERSION = A` — **the `Y*` namespace was never swept,
  so the current count of 24 enhancements is a floor, not a total**
- `MCHB` for material `000000000015000177`, plant `1002` — which batches carry stock. This
  closes an open item in `QS4_WRITE_AUTHORISATION_REQUEST.md`, which currently asks the
  functional owner to nominate a batch.

## Output

Evidence under `sessions/2026-09-18-pgi-certification/evidence/`, one file per query, named
for the block and table — e.g. `A3_ENHINCINX_DELIVERY.txt`, `B1_VTTP_9004953084.txt`.

Keep the script output **verbatim**, including the `SESSION|`, `FILTER|` and `SBAR|` lines.
They are the proof of what was actually queried. Do not summarise in place.

Source under `sessions/2026-09-18-pgi-certification/src/`.

Then write `sessions/2026-09-18-pgi-certification/FINDINGS.md`:

- What each priority established, with the evidence file cited
- Every material claim labelled **Verified**, **Strong inference**, **Hypothesis**,
  **Contradicted** or **Unknown**
- An explicit list of what you could **not** determine and why
- A revised view on whether Create PGI is genuinely standard, or standard-with-enhancement
  like Submit MIGO

Commit to `claude/trusting-shannon-gjzo5d` and push.

## Rules of engagement

- **Read-only. No writes of any kind.** If in doubt, do not run it.
- Never promote HTTP 200, a success message, an allocated document number or a blank result
  into a finding. Confirm what actually happened.
- If evidence contradicts `DELIVERY_GI_ENHANCEMENT_FINDINGS.md`, **the evidence wins** — say
  so explicitly and update the document. That file already carries one retracted inference;
  a second is fine if the data supports it.
- If a query cannot be run — no authorisation, table not found, script fails — record that as
  a result rather than working around it or silently skipping it.
- Do not post a PGI. Do not pick a delivery. Those need a separate written authorisation that
  has not yet been granted.
