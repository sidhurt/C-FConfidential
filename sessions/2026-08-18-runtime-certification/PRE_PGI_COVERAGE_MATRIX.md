# Pre-PGI coverage matrix

**Date:** 2026-08-18 · **Author system access:** DS4/200 (read+write authorised, no writes yet executed) and QS4/700 (strictly read-only)
**Scope:** every stage that must complete before Post Goods Issue.

## Legend

| Status | Meaning |
|---|---|
| `PROVEN HISTORICALLY` | A completed document footprint exists in QS4/700 and was read. It proves the stage happened once; it does **not** prove a callable route. |
| `INTERFACE ONLY` | The contract (OData metadata or SE37 interface) is captured and exact. Nothing has been executed. |
| `EXECUTED` | The operation was actually run and its result reconciled in SAP. |
| `BLOCKED` | Cannot run in DS4/200 for a named, evidenced reason. |
| `UNIDENTIFIED ROUTE` | No callable operation has been identified, and the actual client mechanism is not yet known. |

**Nothing in this matrix is `EXECUTED`.** No pre-PGI stage has been run end to end in any system during this certification.

## Matrix

| # | Stage | Status | Evidence / contract | Blocker |
|---|---|---|---|---|
| 1 | Delivery baseline | `PROVEN HISTORICALLY` + `INTERFACE ONLY` | QS4 delivery `0080019087` (LIKP/LIPS/VBFA captured 2026-08-16). OData `A_OutbDeliveryHeader`/`to_DeliveryDocumentItem` runtime-confirmed, `$metadata` 200. | DS4: `LIKP`/`LIPS` empty — no delivery to baseline. |
| 2 | Stock / batch eligibility | `BLOCKED` | `API_MATERIAL_STOCK_SRV` read-only model confirmed; QS4 batch-split subitems 900001/900002 observed on delivery 9004953077. | DS4: `MARD` empty, `MCHA` empty, `MBEW` empty. No stock, no batches, **no valuation records at all**. |
| 3 | Picking | `INTERFACE ONLY` | OData POST function imports runtime-confirmed: `PickAllItems`, `PickOneItem`, `PickOneItemWithBaseQuantity`, `PickOneItemWithSalesQuantity`, `SetPickingQuantityWithBaseQuantity`, `ConfirmPickingOneItem`, `ConfirmPickingAllItems`. BAPI `BAPI_OUTB_DELIVERY_CONFIRM_DEC` released, interface captured. | No delivery and no stock in DS4. |
| 4 | Batch split | `INTERFACE ONLY` | `PickAndBatchSplitOneItem` (POST, 5 params incl. `SplitQuantityUnit`); `CreateBatchSplitItem` (POST, 6 params incl. `PickQuantityInSalesUOM`). `HigherLvlItmOfBatSpltItm` is creatable=false / updatable=false — SAP owns the split hierarchy. | No batch-managed stock in DS4. |
| 5 | Shipment creation | `INTERFACE ONLY` | `BAPI_SHIPMENT_CREATE` **released**. Inputs: `HEADERDATA`, `ITEMDATA`, `STAGEDATA`, `HEADERDEADLINE`, `STAGEDEADLINE`, `ADDRESS`, `HDUNHEADER`, `HDUNITEM`, `ITEMONSTAGE`. Exports: `TRANSPORT`, `SHIPMENTGUID`, `RETURN`. **No TESTRUN parameter.** DS4 config present: `TVTK` 7 shipment types, `TTDS` planning points, `TVRO` routes. QS4 historical: shipment `2100005093`. | DS4: no delivery to assign; **`LFA1` is empty — there are no vendors, therefore no forwarding agents/transporters.** |
| 6 | Freight estimate | `INTERFACE ONLY` | `BAPI_SHIPMENT_COST_ESTIMATE` **NOT RELEASED** (remote-enabled only). Requires in-memory shipment `HEADERDATA`+`ITEMDATA`+`STAGEDATA` **and** `DLVHEADER`+`DLVITEMS`. Exports `RETURNCOSTS` + `RETURN`; **no `TRANSPORT` export**. | Not executed. Non-posting behaviour **not yet proven** — no source inspection and no before/after VFKK/VFKP comparison has been done. |
| 7 | Shipment-cost document creation | `PROVEN HISTORICALLY` (documents exist) + `INTERFACE ONLY` (route identified 2026-08-18) | **`SD_SCDS_CREATE`** (FG `V54C`, package `VTRA`), interface captured. **Not released, not RFC-enabled.** `I_OPT_COMMIT` defaults `'X'`; range-based via `C_REFOBJ_RANGE`; `E_REFOBJ_RANGE_LOCKED` returns partial completion. Client route traced: `ZDACE_WT` → `SAPMZACE_WEIGHMENT` → `ZDACE_CL_STO_PROCESS::SHIP_COST_CRT` → `SD_SCDS_CREATE`. Standard dialog route is `VI01`/`VI02` (`SAPMV54A`). DS4 config: `TVFT` 6 cost document types. QS4 historical: `VFKK`/`VFKP` `2100005093`, type `Y003`/item `Z007`, pricing `ZSCL01`, net 22,800.00 INR. | Not executed. Requires a wrapper — no released, externally callable interface exists. |
| 8 | Cost release / settlement | `INTERFACE ONLY` (route identified 2026-08-18) | **`SD_SCDS_RELEASE`** (FG `V54R`), interface captured. **Not released, not RFC-enabled.** German short text *Überleitung der Frachtkostenpositionen* = **transfer**, independently corroborating that "release" is the settlement step. `I_OPT_WITH_DIALOG` defaults `'X'` — a background caller must override it. Commit boundary is the separate `SD_SCDS_SAVE`. | Not executed. **No static caller found even at full where-used scope** — the invoker is dynamic or screen-flow, and remains unidentified. |
| 9 | Final pre-PGI checkpoint | `BLOCKED` | — | Depends on stages 1–8. |

---

## Correction: `VFKK-STFRE` is not the release indicator

This overturns the working assumption carried in `HANDOVER_V18_SESSION.md`.

`VFKK` has exactly **18 fields**. Its complete status surface is `STERM`, `STBER`, `STFRE`, `STABR`. Domain texts read from `DD07T` in QS4/700:

| Field | Domain | Authoritative meaning | Values |
|---|---|---|---|
| `STBER` | `STBER_K` | **Calculation** status | blank / A not calculated / B partially calculated / **C fully calculated** |
| `STFRE` | `STFRE_K` | **Account assignment** status — *not release* | blank = *"Not relevant for account assignment"* / A not completed / B partially completed / C completed |
| `STABR` | `STABR_K` | **Transfer** status (settlement to MM) | blank = *"Not relevant for transfer"* / A not transferred / B partially transferred / **C fully transferred** |

Two consequences:

1. **`STFRE` means account assignment, not release.** The earlier reading of "999 of 999 documents had STFRE blank, so release never happened" was based on a wrong field meaning. Worse, **blank does not mean "not done" — it means "not relevant"**, so the old sample proved nothing either way.
2. **`VFKK` carries no release field at all.** Whatever the business calls "cost release" is not stored in the cost-document header status surface.

**Update 2026-08-18 — largely resolved.** Release is a **function module, not a status field**: `SD_SCDS_RELEASE`, whose own German short text is *Überleitung* (transfer). Two independent lines now agree that release = the transfer/settlement step recorded in `STABR`, the one that produces `VFKP-EBELN` and `LBLNI`. `SD_SCDS_SHIPMENT_UPDATE` is what writes the mirrored `VTTK-FBGST`/`ARGST`. What remains open is only whether the *client's* vocabulary matches SAP's — a functional confirmation, not a system question. See [`stageb-route/STAGEB_CALLABLE_INTERFACE_ANALYSIS.md`](stageb-route/STAGEB_CALLABLE_INTERFACE_ANALYSIS.md) §2.3.

## Evidence from the one cost document read in full

`VFKP` row `FKNUM 2100005093 / FKPOS 000001`, read from QS4/700:

| Field | Value | Reading |
|---|---|---|
| `FKPTY` | `Z007` | custom cost item type |
| `NETWR` / `WAERS` | `22,800.00` `INR` | freight amount |
| `KALSM` / `KNUMV` | `ZSCL01` / `0000060717` | custom pricing procedure and condition set |
| `TPLST` / `VSART` | `1041` / `01` | planning point, shipping type |
| `PARVW` / `TDLNR` | `SP` / `0013000434` | forwarding agent partner |
| `STBER` / `DTBER` / `UZBER` | `C` / `04.02.2024` / `05:23:47` | **fully calculated** |
| `STFRE` / `DTFRE` / `UZFRE` | blank / blank / `00:00:00` | account assignment never performed |
| `STABR` / `DTABR` / `UZABR` | blank / blank / `00:00:00` | **never transferred** |
| `EBELN` / `EBELP` / `LBLNI` | blank / blank / `00000` | **no purchase order, no service entry sheet** |
| `ERNAM` / `ERDAT` / `ERZET` | `SCLADMIN` / `04.02.2024` / `05:23:47` | created |
| `AENAM` / `AEDAT` / `AEZET` | blank / blank / `00:00:00` | **never changed after creation** |
| `FKSTO` | blank | not cancelled |

**Calculation timestamp `DTBER`/`UZBER` (05:23:47) is identical to the creation timestamp `ERDAT`/`ERZET` (05:23:47), to the second.** That is strong evidence that **cost calculation is automatic at cost-document creation**, not a separate user action. It is not yet proof that cost-*document* creation is itself automatic on shipment save — that remains open.

The document was created, calculated in the same second, and then never touched again. So for this document, nothing resembling a release or settlement ever happened.

## Discrepancy to resolve

`HANDOVER_V18_SESSION.md` records `FKNUM = REBEL = TKNUM`. This row contradicts that: `FKNUM = 2100005093` but `REBEL = 2100005099` and `EXTI1 = 2100005099`, with `POSTX = "2100005099 RAXAUL"`.

So cost document `2100005093` refers to shipment **`2100005099`**, not to the identically numbered shipment `2100005093`. The number ranges overlap, which makes the two easy to confuse. The forwarding agent here (`0013000434`) also differs from the one recorded for shipment `2100005093` (`0013000913`) — consistent with this cost document belonging to a different shipment.

**Do not rely on "the cost document number equals the shipment number" until re-confirmed.** The correct join is `VFKP-REBEL → VTTK-TKNUM`, not `FKNUM = TKNUM`.

## Timestamp trace — closed

`VBFA` on delivery `9004953084` (17.08.2026):

`10:26:23` delivery created → `11:11:28` shipment `1100605471` created, cost doc `1100608871` created/calculated/account-assigned → **`11:11:30` cost settled** (PO `6000105831`, service entry `1003382363`) → **`11:11:31` PGI material document `4918168265`, movement 601** → `11:11:32` billing `1108024764`.

**Settlement preceded PGI by one second — observed ordering only.** It does not prove SAP technically blocks PGI before settlement; only a DS4 attempt to PGI an unsettled delivery can establish that. Four seconds of proximity proves neither one LUW nor one action, and the real user ids on these documents do not prove manual operation.

## What this means for API-03 / Stage B

- Backend stages are **at least three** and are not one LUW: create shipment → create cost document → settle/transfer. Calculation is a fourth concept that appears to be automatic inside cost-document creation.
- Only **one** of these has a released BAPI (`BAPI_SHIPMENT_CREATE`).
- The estimate BAPI is **not released** and is not a cost-document create.
- No BAPI creates or releases the cost document, in either system.
- Therefore any single portal command must be an orchestration with explicit stage state — it cannot be a thin passthrough.
