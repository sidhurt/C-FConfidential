# Endpoint behaviour certification matrix

**Date:** 2026-08-19 · **DS4/200** write-authorised — **first real writes executed 2026-08-19** · **QS4/700** read-only.

## Counting rule

An operation counts as an **evidence run** only when a representative business input was actually executed, the raw response captured, and the result reconciled to an SAP document or status.

**Evidence runs completed to date: 7 operations / 10 executions.**

### Certification does not transfer between routes

A BAPI result certifies **the BAPI only**. An OData result certifies **that service operation only**. They are separate code paths with separate validation, and **API-11 is the proof**: `BAPI_PO_CREATE1` accepted `UB` and proceeded to business validation, while `API_PURCHASEORDER_PROCESS_SRV` refused `UB` outright on API scope.

Where the v1.8 workbook pairs an operation with a service, that pairing is a **design intent, not a certification**. Every `Executed?` cell below is per-route and must be read as such — no row in section B credits anything in section A, and none in section A credits section B.

1. `BAPI_MATERIAL_AVAILABILITY` — executed twice, read-only.
2. **`BAPI_PO_CREATE1` — executed twice with `TESTRUN=X`.** `ZP06` → `E ME 013` document type not allowed. `UB` → **no `ME 013`**; document-type validation cleared, failed on DS4 data only.
3. **`BAPI_SHIPMENT_CREATE` — executed twice, real writes, 2026-08-19.** Run 1 without commit (discarded); Run 2 with `BAPI_TRANSACTION_COMMIT` in one LUW → shipment `0000001001` persisted in `VTTK`. Evidence: [`writes/SHIPMENT_CREATE_01/RESULT.md`](writes/SHIPMENT_CREATE_01/RESULT.md).
4. **`SD_SCDS_CREATE` — executed once, standalone from SE37, 2026-08-19.** Ran clean outside `VI01` with no dialog context; no cost document produced. Evidence: [`writes/SCDS_CREATE_01/RESULT.md`](writes/SCDS_CREATE_01/RESULT.md).

5. **`API_PURCHASEORDER_PROCESS_SRV` POST `A_PurchaseOrder` — executed, 2026-08-19.** HTTP 400, 742 bytes. Rejected on **API scope**, not on data. Evidence: [`writes/STO_PO_ODATA_02/response_400.xml`](writes/STO_PO_ODATA_02/response_400.xml).

6. **`BAPI_GOODSMVT_CREATE` — executed once, `TESTRUN=X`, 2026-08-19.** `E M7 053 Posting only possible in periods 1998/03 and 1998/02 in company code 0001`. Also establishes plant `PLQ3` → company code `0001`.

Everything else in this matrix is **not executed**. Metadata loading, SE37 interface display, generated payloads, empty 200 GETs and historical document footprints are supporting evidence only and are labelled as such.

## Verdict key

`STANDARD WORKS` · `STANDARD PARTIAL` · `UNRELEASED BUT FUNCTIONAL` · `EXISTING CLIENT AUTOMATION` · `BLOCKED BY DATA` · `BLOCKED BY CONFIGURATION` · `CUSTOM SAP GAP`

---

## A. OData operations, API-01 → API-12

| API | Pillar | Service / operation | Release | Executed? | Pre/post state | Verdict | Blocker |
|---|---|---|---|---|---|---|---|
| **API-01** | STO (Trade/NT untraced) | `API_MATERIAL_DOCUMENT_SRV` POST `A_MaterialDocumentHeader` deep `to_MaterialDocumentItem` | Released | **Yes ×1** (2026-08-20, external HTTPS) | HTTP **400**, nothing created | **`STANDARD WORKS`** — blocked only by MM period | Payload accepted (`GoodsMovementCode 01`, deep `to_MaterialDocumentItem`, material/plant/movement type/qty) and carried to **posting-period control**: `M7/053 Posting only possible in periods 1998/03 and 1998/02`. Same stop as `BAPI_GOODSMVT_CREATE`, reached via a **separate code path** — so this certifies the OData route in its own right. **No custom service needed.** Open a period and this completes. |
| **API-02** | All three | `API_OUTBOUND_DELIVERY_SRV;v=2` POST `A_OutbDeliveryHeader` | Released | **Yes ×3** (2026-08-20, external HTTPS) | HTTP **500** / **405**, nothing created | **`STANDARD WORKS`** — deep insert only; blocked by absent predecessor | **Deep insert with `to_DeliveryDocumentItem` reaches real delivery logic**: `VL/002 A document with number 5600084210 does not exist` (that PO lives in QS4, not DS4). **Header-only POST is refused at 405** with `CX_SADL_ENTITY_CUD_DISABLED`. Metadata does **not** mark the header `creatable=false`, so the schema misleads — the header alone looks creatable and is not. **Always send the deep insert with at least one item** (an empty item array returns a bare 500 dump). **No custom service needed.** |
| **API-03** | All three | Composite: picking → batch split → shipment → cost → settle → PGI → billing | Mixed | **No** | — | `BLOCKED BY DATA` + `CUSTOM SAP GAP` (cost create/settle) | See section C. Not one LUW. |
| **API-04** | All three | `BAPI_SHIPMENT_COST_ESTIMATE` | **Not released** | **No** | — | `BLOCKED BY DATA` | Needs in-memory shipment **and** `DLVHEADER`/`DLVITEMS` — it is not a delivery-only call. Non-posting behaviour **unproven**. |
| **API-05** | All three | `API_MATERIAL_STOCK_SRV` GET `A_MatlStkInAcctMod` | Released | Metadata + empty GET only | — | `BLOCKED BY DATA` | `MARD` empty → no book stock exists to return. Model is read-only (all entity sets `creatable/updatable/deletable=false`), correctly distinct from ATP. |
| **API-06** | All three | DigiGST / EY / eDocument extension | External | **No** | — | `EXISTING CLIENT AUTOMATION` (boundary untraced) | Callable boundary not identified. |
| **API-07** | All three | Invoice correction via same route | External | **No** | — | `EXISTING CLIENT AUTOMATION` (boundary untraced) | QS4 shows five cancel/re-invoice cycles on delivery `9004953084` (`VBTYP N`→`M`, 12:33–14:48 on 17.08.2026) — a real correction pattern worth tracing. |
| **API-08** | STO | `API_PURCHASEORDER_PROCESS_SRV` GET `A_PurchaseOrder` + `to_PurchaseOrderItem` → `to_ScheduleLine` | Released | Empty GET only (200, 0 rows) | — | `BLOCKED BY DATA` (read path only) | `EKKO` has 2 empty shells. ZP06 absent. **Read side only** — the create side of this same service is structurally unavailable for STOs (API-11). Fixing DS4 data unblocks this row and does nothing for API-11. |
| **API-09** | STO | `API_OUTBOUND_DELIVERY_SRV;v=2` GET header + `to_DeliveryDocumentItem` | Released | Empty GET only | — | `BLOCKED BY DATA` | No deliveries. ZNL absent, so the ZNL discriminator cannot be tested in DS4. |
| **API-10** | STO | `API_BILLING_DOCUMENT_SRV` GET `A_BillingDocument` + `to_Item` | Released | Metadata only | — | `BLOCKED BY DATA` | `SalesDocument` **exists** on `A_BillingDocumentItemType` (runtime-confirmed) but whether it carries `VBRP-AUBEL` for an STO invoice needs a positive read on real ZSTO data. |
| **API-11** | STO | `API_PURCHASEORDER_PROCESS_SRV` POST `A_PurchaseOrder` deep | Released | **Yes ×1** | HTTP **400**, no document created | **`STANDARD PARTIAL` — the OData create route does not support stock transport orders.** | `APPL_MM_PUR_PO/064` *"Use purchase order type Standard (NB) or a type copied from NB"* + `APPL_MM_PUR_PO/065` *"Use a supported purchase order item category"*. This is an **API scope restriction, not a data or config gap** — DS4 master data and a transported ZP06 would not change it. Contrast the BAPI, which accepted `UB` and proceeded to business validation. **Open:** whether `ZP06` is copied from `NB` (would pass 064) or from `UB` (would not) — checkable in QS4 `T161`; item category `7` still fails 065 independently. |
| **API-12** | All three | `API_OUTBOUND_DELIVERY_SRV;v=2` PATCH `A_OutbDeliveryItem` | Released | **No** | — | `BLOCKED BY DATA` | Runtime-confirmed: `ActualDeliveryQuantity` updatable; **`DeliveryQuantityUnit` `updatable=false`**; `Batch` `creatable=false`/updatable; `HigherLvlItmOfBatSpltItm` both false — SAP owns the split hierarchy. ETag/stale-ETag/post-PGI untested. |

### Delivery v2 function imports — signatures runtime-confirmed, none executed

All POST. `PostGoodsIssue`(1) · `ReverseGoodsIssue`(2) · `ConfirmPickingAllItems`(1) · `ConfirmPickingOneItem`(2) · `PickAllItems`(1) · `PickOneItem`(2) · `PickOneItemWithBaseQuantity`(4) · `PickOneItemWithSalesQuantity`(4) · `SetPickingQuantityWithBaseQuantity`(4) · `PickAndBatchSplitOneItem`(**5**, incl. `SplitQuantityUnit`) · `CreateBatchSplitItem`(**6**, incl. `PickQuantityInSalesUOM`). Billing `GetPDF` is the only GET.

**Parameter encoding is inferred, not proven.** OData V2 POST function imports conventionally carry parameters in the query string; no executed call has confirmed it.

---

## B. BAPI operations

| BAPI | Release | Executed? | Result | Verdict |
|---|---|---|---|---|
| `BAPI_MATERIAL_AVAILABILITY` | Released | **Yes ×2** | `15000177`/`1002`/`TO` → `WM3351 Material not maintained in plant`, ATP `0.000`. `MAT18`/`PLQ3`/`EA` → no error, ATP `0.000`. | `STANDARD WORKS` for ATP. **Does not satisfy API-05** — ATP ≠ book stock. |
| `BAPI_PO_CREATE1` | Released | **Yes ×2** (`TESTRUN=X`) | `DOC_TYPE=ZP06` → `I MMPUR_BASE 054`, `E MEPO 002`, **`E ME 013 Document type ZP06 not allowed with doc. category F`**, `W W5 005`. `DOC_TYPE=UB` → **no `ME 013`**; failed instead on `ME 083` purchasing group, `06 166` plant currency, `M3 351` material not maintained in receiving plant. `EXPPURCHASEORDER` blank on both, no commit. | `UB` clears document-type validation **in the BAPI**; everything past it is `BLOCKED BY DATA`. `ZP06` is `BLOCKED BY CONFIGURATION`. **Certifies the BAPI only** — API-11 shows the OData route rejects `UB` on scope. |
| `BAPI_GOODSMVT_CREATE` | Released | **Yes ×1** (`TESTRUN=X`) | `GM_CODE=01`, mvt `101`, `MAT18`/`PLQ3`/`1 EA`, posting date 19.08.2026 → one row: `E M7 053 Posting only possible in periods 1998/03 and 1998/02 in company code 0001`. | `BLOCKED BY CONFIGURATION` — **MM period, not valuation**. The call reached period control, so `GM_CODE=01` and the item structure were *not* rejected. Corrects the earlier "no valuation" verdict. Establishes `PLQ3` → company code `0001`. |
| `BAPI_GOODSMVT_CANCEL` | Released | No | — | `BLOCKED BY DATA` |
| `BAPI_OUTB_DELIVERY_CREATE_STO` | Released | No | — | `BLOCKED BY DATA` |
| `BAPI_OUTB_DELIVERY_CREATE_SLS` | Released | No | — | `BLOCKED BY DATA` |
| `BAPI_OUTB_DELIVERY_CHANGE` | **Not released** | No | — | `BLOCKED BY DATA`; wrapper + upgrade risk if adopted |
| `BAPI_OUTB_DELIVERY_CONFIRM_DEC` | Released | No | — | `BLOCKED BY DATA` |
| `BAPI_SHIPMENT_CREATE` | Released | **Yes ×2** (real writes) | Header-only create accepted: `SHIPMENT_TYPE=0001`, `TRANS_PLAN_PT=0001`. Run 1 (no commit) returned `TRANSPORT=1000` and `S VW 488 Save shipment` — **`VTTK` still 0 rows**. Run 2 (+ `BAPI_TRANSACTION_COMMIT`, `WAIT=X`) → `TRANSPORT=1001`, **`VTTK` 1 row**. `W VW 094` deliveries-missing is a warning, not an error. | `STANDARD WORKS` for create. **Caller owns the commit.** Number is allocated pre-commit → uncommitted calls burn number-range values and return phantom shipment numbers. |
| `BAPI_SHIPMENT_CHANGE` | **Not released** | No | — | Do not run until the business operation it is meant to prove is defined. Not proven to perform cost release. |
| `BAPI_SHIPMENT_COST_ESTIMATE` | **Not released** | No | — | `BLOCKED BY DATA`; non-posting behaviour unproven |
| `BAPI_BILLINGDOC_CREATEMULTIPLE` | Released | No | — | `BLOCKED BY DATA` |
| `BAPI_BILLINGDOC_CANCEL1` | Released | No | — | `BLOCKED BY DATA` |
| `BAPI_TRANSACTION_COMMIT` | Released | **Yes ×1** | `WAIT=X`, run in one SE37 test sequence after `BAPI_SHIPMENT_CREATE`; persisted shipment `1001`. | `STANDARD WORKS`. Commit ownership now proven **for `BAPI_SHIPMENT_CREATE` only** — still per-BAPI empirical elsewhere. |
| `BAPI_TRANSACTION_ROLLBACK` | Released | No | — | Untested |

---

## B2. Commit ownership — a contract clause, not a footnote

**Proven, by controlled contrast on `BAPI_SHIPMENT_CREATE` (DS4, 2026-08-19):**

| Run | Call | RETURN | `VTTK` |
|---|---|---|---|
| 1 | create, **no commit** | `TRANSPORT = 1000`, `S VW 488 Save shipment` | **0 rows** |
| 2 | create + `BAPI_TRANSACTION_COMMIT` (`WAIT='X'`), same LUW | `TRANSPORT = 1001` | **1 row** |

### The hazard

The document number is allocated **before** the commit. So an uncommitted call returns a **success message and a real-looking document number for a document that does not exist**, and it **consumes a number-range value** doing so. Number `1000` is permanently burnt in DS4 and no document will ever carry it.

A caller that trusts `RETURN-TYPE = 'S'` plus a populated `TRANSPORT` field will record a shipment number that is not in `VTTK`. That is a silent data-integrity failure, not a runtime error — nothing throws.

### What must be written into the API contract

1. **The service owns the commit.** Every mutating operation states explicitly whether it issues `BAPI_TRANSACTION_COMMIT`, and callers never issue their own.
2. **Success is defined as persistence, not as `RETURN-TYPE = 'S'`.** The response returns a document number only after commit; before that it returns nothing that looks like one.
3. **Commit scope is declared per operation.** Which BAPIs share one LUW is stated in the contract, not inferred by the caller.
4. **Number-burn is accepted and documented.** Failed calls leave gaps in `VTTK` number ranges. Business must be told gaps are normal, so nobody audits them as missing documents.
5. **Commit behaviour is per-BAPI and empirical.** This is proven for `BAPI_SHIPMENT_CREATE` only. `SD_SCDS_CREATE` is the opposite case — `I_OPT_COMMIT` defaults to `'X'`, so it commits *unless told not to*. Two adjacent steps with opposite defaults is exactly how a half-committed process gets built by accident. Every module used must be tested for this individually before it goes in the contract.

---

## C. Stage B — the callable-boundary picture

| Backend stage | Callable operation | Status |
|---|---|---|
| Shipment creation | `BAPI_SHIPMENT_CREATE` | Released, **executed ×2, real writes**. Caller owns the commit — see section B2. |
| Cost-document creation | **`SD_SCDS_CREATE`** | **Identified.** Not released, not RFC-enabled. `I_OPT_COMMIT` defaults to `'X'`. Range-based; `E_REFOBJ_RANGE_LOCKED` returns partial completion. |
| Calculation | **`SD_SCD_ITEM_CALCULATE`** | Not released, not RFC. Item-level; mandatory `I_T180`. QS4 shows it runs automatically inside cost-doc creation — `DTBER`/`UZBER` equals creation timestamp, `STBER=C` on 200/200 sampled items. |
| Account assignment | **`SD_SCD_ITEM_ACCT_ASSIGNMENT`** | Not released, not RFC. The one module that defaults to background (`I_OPT_BACKGROUND='X'`). |
| Settlement / "release" | **`SD_SCDS_RELEASE`** | Not released, not RFC. Function group **`V54R`**. German short text *Überleitung* = transfer, corroborating that release = the settlement step. No static caller found. **EXECUTED 2026-08-19 with `I_OPT_WITH_DIALOG = ' '` → ran headless.** No screen, no modal, no exception, runtime 263,976 µs, returned normally. **The dialog default does not make it screen-bound.** Interface is `C_SCD_TAB` (CHANGING) — you pass the cost documents in and get them back with results. Ran with 0 documents, so completing a *real* settlement headless is still unproven. |
| Persist / commit boundary | **`SD_SCDS_SAVE`** | Not released, not RFC. Mandatory `I_T180`; `I_OPT_RELEASE_WITH_DIALOG` defaults to `'X'`. |
| Status write-back | **`SD_SCDS_SHIPMENT_UPDATE`** | Writes `VTTK-FBGST`/`ARGST`. Not released, not RFC. |
| Settlement status read | **`SD_SCD_HISTORY_SETTLEMENT`** | Pure read, no commit option. Lowest-risk element of the whole surface. |

Full interface analysis: [`stageb-route/STAGEB_CALLABLE_INTERFACE_ANALYSIS.md`](stageb-route/STAGEB_CALLABLE_INTERFACE_ANALYSIS.md). Client route: [`stageb-route/CALLABLE_MECHANISM_FOUND.md`](stageb-route/CALLABLE_MECHANISM_FOUND.md). **Executed from this section: `BAPI_SHIPMENT_CREATE` (×2, real writes) and `SD_SCDS_CREATE` (×1, standalone). The remaining six modules are unexecuted.**

The earlier "none discovered" entries were correct about *BAPIs* and wrong as a conclusion about callable mechanisms. `TFDIR` patterns `*SHIPMENTCOST*` and `BAPI_SHIPMENT*` genuinely return nothing relevant — the modules are named `SD_SCDS_*`, in package `VTRA`, and are not BAPIs.

**Observed ordering** (QS4 delivery `9004953084`, 17.08.2026): delivery `10:26:23` → shipment `1100605471` `11:11:28` → settled `11:11:30` → **PGI `4918168265` mvt 601 `11:11:31`** → billing `1108024764` `11:11:32`.

Settlement preceded PGI by one second. **Observed ordering only** — it does not prove SAP blocks PGI beforehand, four seconds does not prove one LUW, and real user ids do not prove manual operation.

### API-03 external design — now decidable in shape, not in detail

The cost-create and settle routes **are** identified (`SD_SCDS_CREATE`, `SD_SCDS_RELEASE`). What the identification changes:

- The gap is an **exposure layer over existing standard and existing client code**, not a new freight-costing build. `ZDACE_CL_STO_PROCESS` already runs shipment → cost → delivery change → PGI with its own `COMMIT_LUW`/`ROLLBACK_LUW`.
- **Check-then-act is supported**, not assumed: `SD_SCDS_CREATE` accepts `I_OPT_COMMIT = ' '`, so create and commit can be separated deliberately.
- **Partial completion has a standard surface**: `E_REFOBJ_RANGE_LOCKED` returns the reference objects that could not be locked.

#### The wrapper is viable for the create half only

The evidence for wrapper viability is exactly one thing: `SD_SCDS_CREATE` ran standalone from SE37 with no `VI01` dialog context. That is the whole of it.

**UPDATE 2026-08-19 — `SD_SCDS_RELEASE` now also runs headless.** Executed from SE37 with
`I_OPT_WITH_DIALOG = ' '`: no screen, no modal, no exception, runtime 263,976 µs, normal
return. The dialog default is a default, not a hard requirement, and the earlier concern that
this module was screen-bound is closed.

What is still open is narrower: it ran with **zero documents** in `C_SCD_TAB`, so it had
nothing to settle. Completing a *real* settlement without a screen remains unproven and needs
a freight cost document to exist. That is a data prerequisite, not a design risk.

**Net: the wrapper is viable across both halves.** Both `SD_SCDS_CREATE` and
`SD_SCDS_RELEASE` execute standalone outside their dialog transactions.

What is unchanged: these remain **separate business states** across three granularity levels (range / document table / item), none of the modules is released or RFC-enabled, and three of them are structurally dialog-coupled via a mandatory `I_T180`. Any single portal command must still own process id, stage status, duplicate prevention, resume, monitoring and reversal — it cannot honestly be described as a thin passthrough.

**Still blocking the one-vs-three decision:** whether `BAPI_SHIPMENT_CREATE` already triggers `SD_SCDS_CREATE` on save. If it does, the exposed surface shrinks materially. That is a read-only source inspection of `SAPLV56I_BAPI` and needs no DEV data — it is the highest-value next investigation.

---

## D. Correction register for v1.8

| Item | v1.8 / prior belief | Runtime evidence |
|---|---|---|
| `VFKK-STFRE` | release status | **account-assignment** status (`STFRE_K`); blank = *"not relevant"*, not "not done" |
| Cost ↔ shipment join | `FKNUM = REBEL = TKNUM` | **false** — `VFKP-REBEL → VTTK-TKNUM`; observed `FKNUM 1100608871 → REBEL 1100605471` |
| Release evidence | `VFKK-STFRE`/`STABR` | `VTTK-FBGST`/`ARGST` plus `VFKP-EBELN`/`LBLNI` |
| `PickAndBatchSplitOneItem` | 4 params | **5** — `SplitQuantityUnit` |
| `CreateBatchSplitItem` | — | **6** — incl. `PickQuantityInSalesUOM` |
| `GoodsMovementCode` | unknown | `T158G` = 7 values; `01` = MB01 GR-for-PO — **candidate pending a run** |
| Billing create via `API_BILLING_DOCUMENT_SRV` | assumed possible | **impossible** — all 8 entity sets `creatable=false` |
| Stage-B pillar coverage | STO only | delivery `9004953084` is type **`ZLF`** — first Trade-route Stage-B evidence |
| Cost create/release route | "no callable operation discovered" | **`SD_SCDS_CREATE` / `SD_SCDS_RELEASE`** identified in `TFDIR`, interfaces captured. Not BAPIs — that is why `BAPI_SHIPMENT*` searches missed them. |
| "Release" semantics | unknown business meaning | SAP's own short text for `SD_SCDS_RELEASE` is *Überleitung* (**transfer**), independently corroborating the `STABR` status analysis |
| Cost-create commit | assumed caller-controlled | `SD_SCDS_CREATE` `I_OPT_COMMIT` **defaults to `'X'`** — it commits unless explicitly told not to |
| Custom orchestration scope | "build the pre-PGI process" | orchestration already exists in `ZDACE_CL_STO_PROCESS`; the gap is an **exposure layer**, entry point `ZDACE_WT` (weighbridge dialog) |
| STO creation via `API_PURCHASEORDER_PROCESS_SRV` | assumed viable, blocked only by DS4 data/config | **Not viable for STOs.** Runtime 400: the service accepts only `NB` or NB-derived types and a restricted item-category set. The BAPI and the OData service **fail on different grounds** — the BAPI accepted `UB`, the OData service refuses it outright. Do not treat a BAPI success as evidence the OData route works. |
| `BAPI_SHIPMENT_CREATE` commit | unknown | **Caller owns the commit.** Proven by controlled contrast. The shipment number is allocated *before* commit, so an uncommitted call returns a phantom number and burns a number-range value. |
| Goods movement blocker | assumed "no valuation" | **MM period.** `E M7 053` — company code `0001` is open for 1998/03 and 1998/02 only. The call reached period control, so `GM_CODE = 01` and the item structure were not rejected. |
| `ZP06` derivation | unknown, assumed | **Confirmed from QS4 `T161`: `ZP06` → `BSAKZ = T`, `BREFN = UBF`, `NUMKI = 56`.** It is a **`UB` copy**, and the only `Z` type among 78 rows carrying `BSAKZ = T` — their single STO type. Every other `ZP*` is `NBF`/`FOF`/`RBF`/custom. Confirms the OData "NB or copied from NB" rule excludes ZP06, so the `UB` proxy test was valid. |
| `ZP06` item category | unknown | **`EKPO-PSTYP = 7`** on live STO `5600084210` (plant `1025`, 5 TO, 19.08.2026). This is the item category the OData service rejects with error 065 — a **second, independent** lock that holds regardless of document-type derivation. |
| Live ZP06 STO shape | inferred | 15 documents sampled, `BUKRS` 1000/1300, `EKORG` 1000, `EKGRP` 801/802/119/201, **`LIFNR` empty on all**, supplying plant in **`RESWK`**, `WAERS` INR, number range `56xxxxxxxx` matching `NUMKI = 56`. Evidence: [`sto/EKKO_ZP06_QS4.txt`](sto/EKKO_ZP06_QS4.txt), [`sto/EKPO_ZP06_QS4.txt`](sto/EKPO_ZP06_QS4.txt). |
| PO-type derivation field | unidentified | **`T161-BREFN`.** DS4: NB, NB2, NBIC, NBXE, NBXI, DB, ENB → `NBF`; NB2C, NBC7, NBR8 → `NBF2`; **UB, EUB → `UBF`**; FO → `FOF`. `BSAKZ = T` is a second discriminator, set on UB/EUB and blank on the NB family. This is the field to read for `ZP06`. |
| `SD_SCDS_CREATE` dialog coupling | feared screen-bound, wrapper possibly non-viable | **Runs standalone** from SE37 with no `VI01` context. Wrapper is viable. Does **not** extend to `SD_SCDS_RELEASE`, which defaults to dialog mode and remains untested. |

---

## E. What is worth unblocking

The blocked rows are not one category, and working the list top to bottom wastes the effort. They split three ways.

### 1. Structurally out — no amount of DS4 work helps

| Row | Why |
|---|---|
| **API-11** STO create via OData | Service scope: `NB`/NB-derived only, restricted item categories. Config and master data are irrelevant. |
| Billing create via `API_BILLING_DOCUMENT_SRV` | All 8 entity sets `creatable=false`. |

**Do not spend anything here.** The decision these force is a design decision — BAPI or custom service for STO creation — not a test-data decision.

### 2. Cheap and decisive — small effort, changes a verdict

| Item | Cost | What it settles |
|---|---|---|
| `T161` where `BSART = ZP06`, read **`BREFN`** | One QS4 read | Whether ZP06 is NB-derived. `NBF`/`NBF2` → error 064 clears; `UBF` → same family as `UB` and refused identically. Item category `7` still fails 065 either way, so this narrows the answer rather than reversing it. |
| Open an MM period in DS4 company code `0001` | One config change (`MMPV`/`MMRV`) | Unblocks `BAPI_GOODSMVT_CREATE` past `M7 053` and reaches real valuation logic. The current 1998-only period is the single cheapest blocker on the list. |
| Read `SAPLV56I_BAPI` source | Read-only, no data | Whether `BAPI_SHIPMENT_CREATE` already triggers `SD_SCDS_CREATE` on save. If it does, the exposed surface shrinks materially. Highest value per unit effort in the whole matrix. |

### 3. Expensive — a full master-data build, and DS4 may be the wrong bed

`LFA1` is empty (no vendor, therefore no transporter), `MBEW`/`MARD` are empty, plants are split across company codes and currencies, and neither `ZP06`, `ZNL` nor `ZSTO` exists. Stages 5–8 all sit behind this.

Standing this up in DS4 is a genuine master-data project, and at the end of it DS4 still would not resemble production. **Before committing to it, the question to put to the client is whether a QS4 write window against a controlled test document is available instead** — QS4 already holds real STO, delivery, shipment, cost and billing documents, which is precisely what DS4 lacks. That is a client decision, not a technical one, and it is worth asking before anyone builds DS4 master data.

Detail of the DS4 chain, if it is built anyway: `PRE_PGI_EVIDENCE_RUN_BLOCKER_PACKET.md`.
