# Handover to Codex — SAP GUI scripting state and tooling

**Date:** 2026-09-02 · **Systems:** QS4/700 (test) and DS4/200 (development, now logged in)

## Current state — BUILT AND ACTIVE IN DS4

The implementation was created manually by Siddharth in DS4/200 (SAP GUI scripting would not
attach to DS4 — see below) and is **active**:

| | |
|---|---|
| Enhancement implementation | `ZCNF_SUBMIT_MIGO` — Active |
| BAdI implementation | `ZCNF_SUBMIT_MIGO` on `MB_BAPI_GOODSMVT_CREATE` |
| Implementing class | `ZCL_CNF_SUBMIT_MIGO` — activated |
| Method | `IF_EX_MB_BAPI_GOODSMVT_CREATE~EXTENSIONIN_TO_MATDOC` |
| Spot | `MB_GOODSMOVEMENT` (New BAdI) |
| Package | **`ZSCL`** (Shree Cement's own package, not `ZLE` — see note) |
| Transport request | **`DS4K964047`** — "CNF Submit MIGO - delivery-based GR BAdI" |

SE19 confirms **Runtime Behavior: "The implementation will be called"**.

**Package note:** I initially proposed `ZLE`, matching the sibling `ZCL_MM_GOODSMVT_BAPI_CUSTOM`.
Siddharth chose `ZSCL` instead — Shree Cement's own package and their established transport route.
Both are children of `ZDS4` with `DLVUNIT=HOME`, so transport behaviour is identical; the choice is
ownership, and `ZSCL` is the better call.

`DS4K964047` was released and imported to QS4. Verified in QS4: `BADI_IMPL` shows
`ZCNF_SUBMIT_MIGO` at POS 7 with class `ZCL_CNF_SUBMIT_MIGO`; `ZEI_MM_GOODSMVT_BAPI_CUSTOM` still
active at POS 8; all class includes present with `R3STATE=A`; method source verified by re-reading
it out of QS4.

## v1 was inert — root cause found

Four SE37 test runs against delivery `9004952595` all returned `RETURN` = 0 entries, including one
with a deliberately wrong plant (`1006`) that should have produced the BAdI's own error message.
Nothing was derived and no message appeared.

**Cause — a type-length defect in the constants I wrote:**

```abap
lc_item_spike TYPE ebelp VALUE '00010'.        " EBELP is 5 characters
...
IF ls_lips-vgbel <> lc_sto_spike OR ls_lips-vgpos <> lc_item_spike.
  CONTINUE.
```

`LIPS-VGPOS` is data element `VGPOS`, **length 6** (`'000010'`). `EBELP` is **length 5**
(`'00010'`). The comparison never matched, so **every item hit `CONTINUE`** at that line — before
the EKPO check, before any derivation, before any error path. Silent skip, which is exactly what
the four tests showed.

The BAdI was firing correctly the whole time. The registration, activation, transport and call path
were all fine.

**v2 fix:** the `vgbel`/`vgpos` restriction is removed entirely. The delivery range
(`9004952595`–`9004952614`) already scopes the spike, and all 18 candidates are on STO
`5600074803`. Fewer constants, no type traps. Source:
`sessions/2026-09-02-cnf-badi-spike/ZCL_CNF_SUBMIT_MIGO_EXTENSIONIN_TO_MATDOC.abap`.

**Next:** apply v2 in DS4, activate, new transport, import to QS4. Then re-run the wrong-plant test
— it should now return `CNF: STO item does not receive into plant`, which proves the BAdI is live.
Only then attempt a real posting.

### Debugging note

Do not run SAP GUI scripting against QS4 while a debugger session is open there. The ABAP debugger
runs in Exclusive mode and holds the work process; concurrent scripting wedged the GUI badly enough
to need the process killed. One or the other, never both.

Also: a session breakpoint set on a comment or `CONSTANTS` line is inert. Use a **method**
breakpoint (`Break./Watchpoints` → Method tab) rather than a source-line one.

### One correction found during activation

`CT_RETURN` is a **single BAPIRET2 structure, not a table**, despite the `CT_` prefix. The syntax
check rejected `APPEND ... TO ct_return` with *"CT_RETURN is not an internal table"*. Use
`ct_return = VALUE #( ... ).` instead.

This sharpens the earlier finding: it is not that "only the first message survives" — there is only
ever **one message slot**. The BAPI passes the `RETURN` header line, not the table
(`ct_return = return`, not `return[]`), which is why `LMB_BUS2017U04:558` can do
`MOVE-CORRESPONDING return TO badiret`. So: set one message, only when you intend to stop the
posting, and return immediately.

## Scripting: what changed from your harness

Your scripts hardcoded `conn = app.Children(0)` and `SystemName = "QS4"`. With two connections open
that silently targets the wrong system. Everything new is **parameterised by system and client** and
resolves the session by scanning all connections.

New scripts in `sessions/2026-09-02-cnf-badi-spike/scripts/`:

| Script | Purpose |
|---|---|
| `sap-state.vbs <SYS> <CLI> [DUMP]` | Read-only state probe: tcode, program, screen, title, sbar, window count |
| `sap-goto.vbs <SYS> <CLI> <TCODE> [DUMP]` | Navigate to a transaction and dump the screen |
| `sap-fill.vbs <SYS> <CLI> <VKEY\|NONE> <fieldid>=<value> ...` | Fill fields on the **topmost** window, optionally send a VKey, dump the result |
| `se19-create-start.vbs <SYS> <CLI> <SPOT>` | SE19 → New BAdI → spot → Create |
| `sap_se16_read.vbs <SYS> <CLI> <TABLE> <MAX> <COLS> [F=V]` | SE16 reader, system-parameterised |

Also still useful, QS4-only: `sessions/2026-09-02-std-api-extension-feasibility/scripts/grab.ps1`
and `open-include.vbs` for pulling ABAP source via SE38 display.

## Gotchas that cost time — don't repeat them

**Always target the topmost window.** `wnd[Children.Count - 1]`, not `wnd[1]`. SE19 object creation
stacks three deep (`wnd[0]` SE19 → `wnd[1]` Create Implementation → `wnd[2]` Object Directory /
Transport). Dumping `wnd[1]` when the action is on `wnd[2]` shows stale content and looks like
nothing happened.

**DS4 renders SE16 results as a classic list, not an ALV grid.** The QS4 reader's `FindGrid` returns
nothing there and reports `NO_GRID`. Values sit in `lbl[col,row]`. Don't assume the read failed.
For DS4 metadata, prefer reading it in QS4 — the repository is identical (transported) and the QS4
reader works.

**PowerShell drops empty string arguments** passed to `cscript`. `... 1005 "" 41.230 TO` shifts every
argument left, so `MATERIAL` silently received the quantity. Use a `-` sentinel and translate it to
blank inside the VBS. `bapi-testrun.vbs` already does this.

**Don't reuse a probe script that re-navigates.** `se37-probe.vbs` starts with `/nSE37`, which wiped
a fully-entered SE37 test payload. Separate "navigate and set up" from "inspect current screen".

**Re-check which session you're on before acting.** Siddharth works in these systems at the same
time. At one point a `/nSE37` navigated away from a MIGO screen he had open. `list-sap-sessions.vbs`
first, every time.

## ABAP corrections since your draft

`sessions/2026-09-02-cnf-badi-spike/ZCL_CNF_SUBMIT_MIGO_EXTENSIONIN_TO_MATDOC.abap` is updated.
Two came from reading `MB_CREATE_GOODS_MOVEMENT` (`LMBWLU14`, captured in
`sessions/2026-09-02-std-api-extension-feasibility/src/`):

- **`VBELP_AVIS = POSNR` — you were right, I was wrong.** `LMBWLU14:2057` does
  `READ TABLE lt_lips WITH KEY posnr = lv_vbelp` where `lv_vbelp = imseg-vbelp_avis`. Passing
  `UECHA` (`000000`) fails that read. Your correction is now proven from source, not argued.
- **`EBELN` must stay initial.** `LMBWLU14:1729` gates the PO search on
  `vlief_avis` filled AND `kzbew = 'B'` AND **`ebeln IS INITIAL`**. Setting the PO directly disables
  the delivery resolution entirely. Your draft correctly never set it — keep it that way.
- **Your `RETURN` after appending to `CT_RETURN` is correct** and I was wrong to flag it.
  `LMB_BUS2017U04:558` is `IF NOT return IS INITIAL` — **any** message aborts the posting regardless
  of type, and only the first survives (`MOVE-CORRESPONDING` then `CLEAR return`). So never append
  informational messages, and returning immediately is right.
- Added `vlief_avis IS INITIAL` and `ebeln IS INITIAL` to the gate — it is a multiple-use BAdI
  (`BADI_MAIN-SINGLE_USE` is blank) with other active implementations.
- Opened the system guard to `DS4` as well as `QS4`, so it can be tested where it is developed
  instead of costing a transport per iteration.

## Remaining sequence

1. Siddharth confirms the transport request.
2. Continue the SE19 flow: select BAdI definition `MB_BAPI_GOODSMVT_CREATE`, create implementing
   class `ZCL_CNF_SUBMIT_MIGO` in `ZLE`, paste the method, activate.
3. Transport to QS4 (Siddharth handles the TR/TOC).
4. Postman: `Delivery` + `DeliveryItem` + `Plant` + `GoodsMovementType 101` +
   `GoodsMovementRefDocType B`, no PO.
5. Verify the document in `MKPF`/`MSEG`/`VBFA`, and confirm `ZMMT_MIGO_HDR` is empty for it —
   that absence is expected and is itself evidence the MIGO BAdIs did not run.

Candidates: 18 on STO `5600074803`, plant `1005`, SLoc `RMYD` —
`sessions/2026-09-02-migo-candidate-recheck/CANDIDATE_REGISTER.csv`. Recheck with
`MSEG VBELN_IM=<delivery> BWART=101` immediately before use.

Full design and evidence: `CODEX_HANDOVER_SUBMIT_MIGO_BADI_IMPLEMENTATION_2026-09-02.md`.
