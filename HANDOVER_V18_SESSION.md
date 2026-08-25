# Handover — v1.8 workbook + Stage B trace

**Date:** 2026-08-17 · **System:** QS4 client 700, user QNOVATE8, read-only throughout.
Read `PROJECT_BRAIN.md` for the mental model. This file is what changed and what is live.

## State of play

**Authoritative deliverable:** `deliverables/CNF_API_Request_Response_Specification_v1.8.xlsx`
73,861 bytes · SHA-256 `214BD4F18B879A97BE74BDC095061BA1E84A3E38465A2820D9A38BBE38B5DB35`
13 sheets, 12/12 audit pass. **Not frozen** — user reviews before freezing.

Companion: `deliverables/CNF_v1.8_STUDY_GUIDE.md` — field-by-field defence notes.

v1.8 is a **new specification**, not annotated v1.7. Each API sheet has 13 numbered sections and names the released SAP service, not the retired `ZCNF_*` custom drafts.

## Three things that define the content

1. **Standard-first.** Six SAP services carry all 12 APIs. Custom only where a gap is proven.
2. **Three equal pillars.** Trade / Non-trade / STO. STO is the only one traced — that is an evidence gap, NOT a scope reduction. Never generalise ZP06, ZNL, ZSTO, 641 or any document number onto Trade/Non-trade.
3. **Three labels only:** CONFIRMED (known) · STO-OBSERVED (seen on a stock transfer, may not hold elsewhere) · OPEN (nobody checked).

## Build system

`tmp/build_v18_new.ps1` regenerates the workbook from v1.7 plus two sheet-definition files:
- `tmp/sheets_sto.ps1` — API-01, 02, 08, 09, 10, 11, 12
- `tmp/sheets_0307.ps1` — API-03 to 07

Then `tmp/audit_v18.ps1` (12-sheet structural and token audit) and `tmp/fact_check.ps1` (proves a rewrite lost no document numbers or field names).

`sessions/2026-08-16-sto-flow-trace/evidence/21_SEGW_PROPERTY_INDEX.tsv` — 4,557 OData properties mined from 16 local SEGW extracts, with IsKey / Creatable / Updatable / Filterable / AbapField. **Reliability boundary: those annotation flags are populated only for the delivery family. Blank elsewhere means NOT CAPTURED, never false.**

## Traps — every one of these bit me, do not repeat

- **`$metadata` inside double-quoted PowerShell strings gets eaten.** Escape with a backtick. It silently produced "local  proves". Happened three times. The build asserts token counts now — do not remove that check.
- **Never run a blanket regex over the build scripts** to fix tokens; it corrupts the single-quoted assertion list and breaks the audit.
- **PowerShell unwraps single-element arrays** returned from an if-block into a string, after which indexing returns CHARACTERS. Cast `[object[]]`.
- **A `$r` loop counter clobbers `$R`** — variables are case-insensitive. Use distinct names.
- **SEGW extract files are UTF-16LE.** grep finds nothing; use `iconv -f UTF-16LE` or `[Encoding]::Unicode`.
- **Extract paths exceed MAX_PATH.** Read via the `\\?\` prefix in .NET.
- **SE16 selection fields are positional `I1-LOW`..`In-LOW`, and are `txt` on some tables and `ctxt` on others.** Use the FIELDS mode in `tmp/sto_se16.vbs` first.
- **SE16 ALV lazy-loads.** Page via `FirstVisibleRow` or most rows come back blank.
- **Edit the spec rows; do not append commentary beside them.** The first v1.8 attempt appended, so the top of every sheet stayed v1.7. User caught it.
- **Write plain English.** No invented labels, no pointers to other rows. User pushed back hard on "Conditional - reference rule".
- Heredocs with this content break the shell. Use the Write tool for markdown.

## Stage B trace (2026-08-17) — evidence in `sessions/2026-08-17-stage-b-trace/evidence/`

Shipment `2100005093`: type **Y003**, planning point 1002, carrier `0013000913`, route P24992, 528 km. Header carries `ZZVEHICLE_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB`, `ZZLR_GR_NO`, `ZZLR_GR_DATE`, `ZZGROSS_WT` / `ZZNET_WT` / `ZZTARE_WT` — **this is where the portal's transport fields land.**

Created 05:18:59, invoice created 05:19:02 — three seconds apart, no change documents, all under user SCLADMIN. **The dispatch process already runs end to end automatically. CNF adds an entry point; it does not build the process.**

Cost documents: VFKK / VFKP, custom types Y003 / Z006 / Y001 / Z008, pricing ZSCL01. `FKNUM = REBEL = TKNUM` — the cost document number equals the shipment number. Shipment `FBGST = C` = "Completely Processed", so calculation ran.

Release status lives on `VFKK-STFRE`. **999 of 999 sampled documents had STFRE and STABR blank.** Business states release always happens before PGI. The sample was entirely `ERDAT` 31.03.2026 and looks like one mass recalculation, so treat it as unrepresentative. **Unresolved: which field actually records the release. Needed before anyone builds.**

Confirmed callable in TFDIR: `BAPI_SHIPMENT_CREATE`, `BAPI_SHIPMENT_CHANGE`, `BAPI_SHIPMENT_COST_ESTIMATE`, all `FMODE=R`. **No BAPI exists to create or release the cost document** — a search for `*SHIPMENTCOST*` returned nothing. That is the real gap.

`PostGoodsIssue` is an OData function import on the delivery service taking one parameter, `DeliveryDocument`. `ReverseGoodsIssue` exists as the standard undo.

## Live design decision — API-03 Stage B

Recommended: **one callable operation, check-then-act, not all-or-nothing.** It reads SAP's own documents to know where it got to (shipment via VTTP, cost document via VFKP, release via VFKK), so repeating the call is safe and never creates a second shipment.

**The client team is pushing for three separate APIs** so they own error handling. Advice given: concede it. It is reversible, functionally near-equivalent, and not worth the relationship cost. Get ownership of half-finished-state monitoring in writing.

**I overclaimed rollback and corrected it.** SAP rollback only covers uncommitted work inside one transaction, and if costing fires automatically on save it is outside that anyway. Once committed you reverse, not roll back — true for one API or three. Do not re-raise rollback as the deciding argument.

## Blockers

| Blocker | Owner |
|---|---|
| API-01 `GoodsMovementCode` value unconfirmed — nothing can post without it | Functional (MM) |
| API-02 creation path: VL10X vs custom ZLE020, neither is VL01N | Functional + ABAP |
| API-02 Trade/Non-trade not traced at all | ABAP to trace |
| API-10 `SalesDocument` to `VBRP-AUBEL` unverified — ABAP_FIELD gives the CDS name, not the table field | ABAP |
| API-11 RequisitionNumber: `BANFN` empty vs `BEDNR` populated, one sample only | Functional |
| API-09 ZNL population unvalidated; delta exposed at DATE grain only | Functional + CPI |
| Stage B: which field records cost release | Functional |
| Nothing is activated. No OData call has ever been made. | Basis |

## Outstanding — offered, not built

1. **Payload pack** — request and response JSON per API, from mined property names plus real observed values. Requests are solid; response shapes are inferred and must be labelled as such.
2. **Runnable test collection** — `.http` or PowerShell with CSRF fetch and each call, ready the moment activation lands.
3. **`$metadata` validator** — pulls metadata once a service is live and diffs it against `21_SEGW_PROPERTY_INDEX.tsv`. Closes three blockers in one run.

User has a client demo imminent and cannot activate (no Basis, no scripting access). A Basis activation message was drafted: five services to activate, two needing role access only.

**Critical for that request:** `API_OUTBOUND_DELIVERY_SRV` exists in two versions under the identical technical name. We need **version 2**, from project `API_OUTBOUND_DELIVERY_0002`. Version 1 lacks the batch-split operations and would activate cleanly then fail on first real use.

## Working with this user

Direct, fast, technically strong, under real deadline pressure. Wants decisions, not surveys. Pushes back hard and is usually right. Will call out over-complication — keep language plain and every cell self-contained. Verify before asserting; he checks. When wrong, say so once, plainly, and move on.
