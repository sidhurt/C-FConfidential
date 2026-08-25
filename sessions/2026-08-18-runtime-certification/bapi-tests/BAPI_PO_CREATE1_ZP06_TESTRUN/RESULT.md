# BAPI_PO_CREATE1 — ZP06 negative test (TESTRUN = X)

**System:** DS4 · **Client:** 200 · **User:** QNOVATE8 · **Date:** 2026-08-18
**Transaction:** SE37 → Display `BAPI_PO_CREATE1` → F8 single test
**Executions:** exactly one. `BAPI_TRANSACTION_COMMIT` was **not** called. `NO_AUTHORITY` was **not** set.
**Runtime:** 8,294,416 microseconds.

## Inputs populated

Only three values were entered. No plant, material, vendor, purchasing organisation or quantity was invented.

| Parameter | Field | GUI field ID | Value | Readback |
|---|---|---|---|---|
| `TESTRUN` | (scalar) | `wnd[0]/usr/txt[34,12]` | `X` | `X` |
| `POHEADER` | `DOC_TYPE` | `wnd[0]/usr/txt[17,3]` *(Structure Editor: Change POHEADER from Entry)* | `ZP06` | `ZP06` |
| `POHEADERX` | `DOC_TYPE` | `wnd[0]/usr/txt[5,3]` *(Structure Editor: Change POHEADERX from Entry)* | `X` | `X` |

Field identity was confirmed two ways, not assumed:
- the POHEADER row rendered back as `              ZP06…` — `ZP06` begins at offset 15, i.e. immediately after `PO_NUMBER`(10) + `COMP_CODE`(4), which is the `DOC_TYPE` position in `BAPIMEPOHEADER`;
- the POHEADERX row rendered back as `  X` — `X` at offset 3, the same ordinal position in `BAPIMEPOHEADERX`.

## RETURN — 4 entries, verbatim

| # | TYPE | ID | NUMBER | MESSAGE |
|---|---|---|---|---|
| 1 | `I` | `MMPUR_BASE` | `054` | `Function "Create Purchase Order" Performed in Test Run` |
| 2 | `E` | `MEPO` | `002` | `PO header data still faulty` |
| 3 | `E` | `ME` | `013` | `Document type ZP06 not allowed with doc.  category F (Please check input)` |
| 4 | `W` | `W5` | `005` | `Please enter items first` |

*(The double space in row 3 after `doc.` is SAP's own text and is reproduced as displayed.)*

**`MESSAGE_V1`–`MESSAGE_V4`, `PARAMETER`, `ROW` and `FIELD` were not captured.** The SE37 Structure Editor list view renders only `T` / `ID` / `NUM` / `MESSAGE` for this table. Horizontal scrolling was unavailable (`HorizontalScrollbar` is not exposed) and `ResizeWorkingPane` had no effect. They are recorded as `NOT CAPTURED` in `RETURN.tsv` rather than guessed.

## Exports

| Parameter | Value |
|---|---|
| `EXPPURCHASEORDER` | *(blank)* — no PO number returned, as expected under TESTRUN |
| `EXPHEADER` | `              ZP06 918.08.2026QNOVATE8    00010          ENEN     0  0  0 0.000 0.000                             18` |
| `EXPPOEXPIMPHEADER` | *(blank)* |
| `RETURN` (table) | input `0 Entries` → `Result: 4 Entries` |
| `POITEM` (table) | `0 Entries` |

`EXPHEADER` positional decode is in `EXPHEADER_positional_decode.tsv`. It is derived from field offsets in `BAPIMEPOHEADER`, not from a labelled screen, and is marked as such.

## Interpretation

**The actual message is `ME 013` — "Document type ZP06 not allowed with doc.  category F (Please check input)".** It is *not* "document type not defined". That distinction matters:

- `ME 013` is the check that a document type is permitted **for a given document category**. Category `F` is the purchase order category. The message therefore reports that `ZP06` is not assigned to / not valid for category `F` **in this client**.
- This is consistent with the earlier `T161` read, where a filter on `BSART = ZP06` returned *"No table entries found for specified key"* against 35 rows, all SAP-standard. A document type absent from `T161` cannot be allowed for category `F`.
- The BAPI echoed `ZP06` back unchanged in `EXPHEADER` — it accepted the value into the interface and rejected it at validation, rather than clearing or defaulting it.

**Validation ordering observed:** the test-run acknowledgement (`MMPUR_BASE 054`) is emitted first, then the generic header verdict (`MEPO 002`), then the specific cause (`ME 013`), then a separate warning that no items were supplied (`W5 005`). The document-type error is raised **alongside**, not behind, the missing-items warning — supplying items would not have suppressed it, and the missing-items condition is only a `W`, not an `E`.

**What this does and does not prove.** It proves that `BAPI_PO_CREATE1` in DS4/200 rejects `ZP06` at header validation, and gives the exact message and message ID for that rejection. `TESTRUN = X` exercises validation only — it does **not** demonstrate that a real STO could be created once `ZP06` exists, and it says nothing about item-level, schedule-line, plant-pair or item-category-`7` validation, none of which was reached.

## Safety

No document was created or changed. `EXPPURCHASEORDER` is blank and `TESTRUN = X` was confirmed set before execution and echoed back on the result screen. No commit was issued. `NO_AUTHORITY` was left blank. The SE37 test variant was not saved.

## Open item at end of run

Pressing the Structure Editor's **Entry** button (`tbar[1]/btn[9]`, "Table Entry F9") opened a modal titled **"Position on Entry"**. Per the standing instruction it was **left open and not dismissed**. The session is currently sitting on that modal.

The correct control for the full field list is `tbar[1]/btn[19]` — "Single Entry (Shift+F7)" — not `btn[9]`. Recovering `MESSAGE_V1`–`V4`, `PARAMETER`, `ROW` and `FIELD` requires dismissing the open modal and pressing `btn[19]` instead.
