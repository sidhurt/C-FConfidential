# BAPI evidence run matrix

**Executed evidence runs: 2 of 15.** Interface capture and DDIC extraction are *not* evidence runs and are excluded from the count.

## Executed

### 1. `BAPI_MATERIAL_AVAILABILITY` — released, read-only, executed twice

| | Run A | Run B |
|---|---|---|
| Input | `MATERIAL 15000177`, `PLANT 1002`, `UNIT TO` | `MATERIAL MAT18`, `PLANT PLQ3`, `UNIT EA` |
| `RETURN` | `WM3351 Material 15000177 not maintained in plant 1002` | *(no error row)* |
| `AV_QTY_PLT` | `0.000` | `0.000` |
| Document effect | none | none |
| Commit | not required — read-only | same |

**Proven:** the BAPI is callable and authorised in DS4/200; QS4-derived master data does not exist in DS4; the valid DEV material has zero ATP.
**Implication:** ATP ≠ book stock. This BAPI **cannot** satisfy API-05. `API_MATERIAL_STOCK_SRV` remains the correct API-05 surface.
**Verdict:** `STANDARD WORKS` (for ATP).

### 2. `BAPI_PO_CREATE1` — released, `TESTRUN=X`, executed once

| | Value |
|---|---|
| Input | `TESTRUN=X`; `POHEADER-DOC_TYPE=ZP06`; `POHEADERX-DOC_TYPE=X`. Nothing else populated. |
| GUI field ids | `txt[34,12]` / `txt[17,3]` / `txt[5,3]` |
| `RETURN` | `I MMPUR_BASE 054` test run performed · `E MEPO 002` PO header data still faulty · **`E ME 013 Document type ZP06 not allowed with doc.  category F`** · `W W5 005` enter items first |
| Exports | `EXPPURCHASEORDER` blank; `EXPHEADER` echoed `ZP06` back unchanged |
| Post-state | no document; no commit issued |
| Retry / reversal | n/a — nothing created |

**Proven:** `ZP06` is not configured for document category `F` in DS4/200; the BAPI accepts the value into the interface and rejects it at header validation; the document-type error is raised alongside — not behind — the missing-items warning, so supplying items would not suppress it.
**Implication:** API-11 CNF parity is `BLOCKED BY CONFIGURATION`, not a BAPI defect.
**Verdict:** `BLOCKED BY CONFIGURATION`.

## Not executed — all remaining 13

| BAPI | Release | Mode when run | Blocker |
|---|---|---|---|
| `BAPI_PO_CREATE1` (generic `UB`) | Released | `TESTRUN=X` | no vendor, no valuation, material not in two plants |
| `BAPI_GOODSMVT_CREATE` | Released | `TESTRUN=X` | `MBEW` empty — no valued material |
| `BAPI_GOODSMVT_CANCEL` | Released | real | no material document to cancel |
| `BAPI_BILLINGDOC_CREATEMULTIPLE` | Released | `TESTRUN=X` | no billable delivery |
| `BAPI_BILLINGDOC_CANCEL1` | Released | `TESTRUN=X`, `NO_COMMIT=X` | no billing document |
| `BAPI_OUTB_DELIVERY_CREATE_STO` | Released | real, disposable | no STO |
| `BAPI_OUTB_DELIVERY_CREATE_SLS` | Released | real, disposable | no sales order |
| `BAPI_OUTB_DELIVERY_CHANGE` | **Not released** | real, disposable | no delivery; wrapper + upgrade risk if adopted |
| `BAPI_OUTB_DELIVERY_CONFIRM_DEC` | Released | real, disposable | no delivery, no stock |
| `BAPI_SHIPMENT_CREATE` | Released | real, disposable | no delivery, **no transporter** (`LFA1` empty). No `TESTRUN` — first run is a real create. |
| `BAPI_SHIPMENT_CHANGE` | **Not released** | — | **Do not run until the business operation it is meant to prove is defined.** Not proven to perform cost release. |
| `BAPI_SHIPMENT_COST_ESTIMATE` | **Not released** | real, non-posting *(unproven)* | no shipment/delivery/carrier/rate. Requires in-memory shipment **and** `DLVHEADER`/`DLVITEMS`. |
| `BAPI_TRANSACTION_COMMIT` / `_ROLLBACK` | Released | paired with the above | commit ownership to be established empirically per BAPI |

## Rules carried into every future run

- Commit ownership is determined **empirically per BAPI**, never assumed.
- `BAPI_TRANSACTION_ROLLBACK` affects only the current uncommitted LUW. After a commit, use the SAP reversal/cancellation process instead.
- A single success never proves idempotency — retry is a separate captured run.
- Remote-enabled ≠ released. The three unreleased modules require a client-owned wrapper with named upgrade-risk ownership if adopted.
- Never create a second document because the first capture was incomplete.
