# Shree Cement C&F Agent — current SAP implementation state

**As of:** 2026-09-21
**Authority:** This document overrides older implementation-status statements where they conflict. The v1.9 workbook remains the business-contract baseline; it is not the current technical certification record.

**Numbering:** API IDs follow the v1.9 workbook **tab** scheme, which matches the client's agreed API list (`deliverables/CNF_v1.9_ERRATA_2026-09-18.md`, Defect 1). Earlier versions of this file used the workbook's internal body scheme:

| Before 21 Sep | Now |
|---|---|
| OF-02 Stock | OF-03 Stock |
| OF-04 Pre-PGI | OF-05 Pre-PGI |
| OF-05 Create PGI | OF-06 Create PGI |
| OF-06 Create Order STO | OF-08 Create Order STO |

OF-02 (agreed-list item 2, "Modify DI") was retired in v1.9 as quantity-only and is reinstated here with a wider scope (`SRC-SID-20260921-01`). Agreed-list item 4 ("Get shipment cost") stays retired; its content lives in OF-05.

## What changed

The project has moved beyond service discovery. The decisive question is no longer whether a standard SAP service exists or returns a successful response. It is whether the externally invoked path creates the intended document and preserves the client-specific validations, derivations, commit behavior, replay protection and downstream linkage that users receive through SAP transactions.

The September BAPI and enhancement investigation proved that those paths can differ materially. In particular, MIGO transaction enhancements do not automatically run when the same posting core is reached through `BAPI_GOODSMVT_CREATE` or `API_MATERIAL_DOCUMENT_SRV`.

## Certification model

| Classification | Meaning |
|---|---|
| Standard read — proven | Representative business data was returned and reconciled to SAP. |
| Standard write — path proven | A document persisted, but business-equivalence or scenario coverage remains incomplete. |
| Standard service with required enhancement | The SAP-delivered endpoint remains the transport, but logic in a released BAdI or exit is required for the business contract. A source-code enhancement does not qualify (see extension order below). |
| Custom command exposure | SAP business logic exists as a BAPI/FM chain, but no suitable standard external command exists. |
| Existing client route to trace | Installed client/add-on logic appears to own the operation; trace and reuse it before building. |
| Blocked by business definition | The object, owner or contract is not settled enough for implementation. |

## API-by-API disposition

| API | Current classification | What is proven | What remains |
|---|---|---|---|
| MIGO-01 Show Inward MRNs | Existing read logic and CPI/T1 per-delivery enrichment; runtime trace open | Pending receipt is derived per delivery from existing CDS/report logic led by `zsd_mrn_pending_cds_opt`. The portal reads an existing SAP/Datasphere projection whose field/table relationships are filled in CPI/T1 and transmitted in 30-minute batches, rather than calling SAP on each screen interaction (`SRC-SID-20260910-01/-02`). | Capture the deployed view/iFlow and exact T1/T2 persistence handoff; settle stable key, watermark/recovery controls and live revalidation. Do not rebuild this as a greenfield SAP composite-read API or describe it as “no evidence.” |
| MIGO-02 Submit MIGO | Standard service with required enhancement — partial implementation; not certified | Standard OData posted material document `5007138616/2026` using PO + delivery references. Direct BAPI callers prove a delivery-only 101 pattern is viable. The QS4 `MB_BAPI_GOODSMVT_CREATE` implementation/class `ZEI_MM_GOODSMVT_BAPI_CUSTOM` / `ZCL_MM_GOODSMVT_BAPI_CUSTOM` now makes some validations work, including reported no-PO handling, but the implementation is explicitly not complete or bulletproof (`SRC-SID-20260917-01/-02`). **Source read 18/21 Sep:** `SEHAJTECH`'s 17–18 Sep transports add the following:<br>(a) the BAdI now derives PO/item from `LIPS-VGBEL/VGPOS` when absent and calls new `ZCL_MM_MIGO_VALIDATION_FACADE`;<br>(b) implicit enhancement `ZSD_ENH_API_MATDOC_DEFINE_MPC` in SAP's `CL_API_MATERIAL_DOCUME_MPC_EXT→DEFINE` adds 19 `ZZ_` header properties;<br>(c) class enhancement `ZSD_ENH_API_MAT_DOC_DPC`, a post-method on `…DPC_EXT→CREATE_DOCUMENT`, writes them to `ZMMT_MIGO_HDR`.<br>`ZSD_ENH_API_MATDOC_CREATE_DOC` is registered but empty (`sessions/2026-09-18-submit-migo-header-fields/FINDINGS.md`). | Inventory implemented versus missing validations; capture active source/version and rule-by-rule runtime evidence; then prove persistence, duplicate/concurrency, partial/shortage, reversal and representative rail/road cases. Confirm the rejected explicit enhancement `ZCNF_SUBMIT_MIGO_MAP2I` is absent from the active QS4 path. **Governance:** (b) and (c) sit at rung 5 of the extension order below, which is lower than the explicit enhancement rejected on 4 Sep. They need architect sign-off, or a released alternative (Q-086). Run one end-to-end post with custom header fields and confirm whether a facade error stops the posting. |
| OF-01 Create DI | Standard write — depot routes proven; billing-block check required | 17 Sep, QS4/700, `/IWFND/GW_CLIENT`: `API_OUTBOUND_DELIVERY_SRV;v=2` created and re-read depot Trade DI `9004953534` (`ZTRD`→`ZNP`), Non-trade (`ZNTR`→`ZLF`) and depot STO (`ZNL`) DIs; factory STO `9004953174` earlier. T0 trace: both customer `DELIVERY_FINAL_CHECK` implementations run on OData before `SAVE_DOCUMENT_PREPARE`; `SY-TCODE` blank. Standard SAP refuses over-quantity (`VL/363`), credit block (`VL/060`), incomplete order/missing SPI (`VL/096`) and delivery blocks `01`/`15`. V03 enforced on OData change (`ZLE/104`). A header billing block does **not** stop creation (`9004953540`). | Build the billing-block check (`deliverables/handover/CREATE_DI_BILLING_BLOCK_DEVELOPMENT_APPROACH_2026-09-17.md`); confirm one-line-per-DI covers V01; settle bill-to-ship-to scope (factory-side paired deliveries, `SRC-SID-20260917-10`); rerun as the CPI integration user; read-back of Test 4/5 DIs `9004953537`/`9004953538` done. Duplicates are Hybris/CPI (`SRC-SID-20260917-08`). **QA, 18 Sep (`SRC-SID-20260921-03`):** 8 validations passed and 3 failed.<br>• Future schedule line: a **VL01N parity gap**. VL01N logs `VL 248` and creates nothing; the API delivered a line due 25.09 (`9004953583`–`…589`) because the create exposes no due date. Fix in the portal (schedule-line date pre-check) or in the BAdI.<br>• Plant deletion flag: VL01N has no such check, so this is a **new business rule** needing a change request.<br>• Error message: re-test once the other two block.<br>Eight QA deliveries `9004953582`–`…589` remain open (`sessions/2026-09-21-create-di-qa-failures/FINDINGS.md`).<br>**Side effect:** the unguarded client save hook `ZEI_LE_UPDATE_DELIVERY_HEAD` creates **and releases** a `ZPFG` process order for every API-created delivery with freight group `A0000001`/`A0000022`. Order `003004365654` exists for `9004953174`; tell the functional owner. |
| OF-02 Modify DI | Standard write, with a model-declaration gap for 7 custom dispatch fields | Required per the SD consultant; portal scope and fields are in `SRC-SID-20260921-01`. **Standard today:** quantity (`ActualDeliveryQuantity`), storage location, batch/pick (`PickAndBatchSplitOneItem` etc.), `BillOfLading`, `MeansOfTransport`/`Type`, dates, texts. **Custom fields:** `LIKP-ZZ*` sit in SAP's extension include (`ZSDA_CUSTOM_FIELDS1` appended to `SHPDELIVERY_INCL_EEW_PS`, which is also the API's `ext` group). Header PATCH skips the whitelist for `ext` fields and SAP's `SHP_EXTEND_ODATA` writes them to `LIKP`, so persistence is standard. **Gap:** live QS4 `$metadata` declares none of them. There are no customer enhancements on the delivery API classes. SPI is display-only; the pick-up code is validated in the portal (`SRC-SID-20260921-02`). Details: `sessions/2026-09-21-modify-di-extension-channel/FINDINGS.md`. | Declare 7 fields: `ZZLRGRNO`, `ZZLRGRDATE`, `ZZVEHICLE_NO`, `ZZDRIVER_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB`, `ZZPARTNER`. Prefer CFL registration (rung 1) if it can adopt developer-appended fields (check pending); otherwise an implicit enhancement at the end of `CL_API_OUTBOUND_DELIVE_MPC_EXT→DEFINE` (rung 5, architect sign-off; Q-084). Then run one PATCH, read back `LIKP`, and confirm the transporter `SP` partner is created from `ZZPARTNER` by client derivation D1. **Note:** D1 runs in `SAVE_DOCUMENT_PREPARE`, after `DELIVERY_FINAL_CHECK`, so V09a/V09b cannot see the new transporter in the same save. They would apply on the next save (PGI). This is consistent with Q-082's finalisation gate. |
| OF-03 Stock Availability | Standard read — proven | `API_MATERIAL_STOCK_SRV` returned real QS4 stock at account-model grain. | Freeze business filters, included stock types, authorization behavior and T2/Datasphere projection. |
| OF-05 Pre-PGI | Custom command exposure; depot-readiness gate proposed | No standard shipment or shipment-cost OData exists: the 15 Aug catalogue sweep of 2,626 Gateway projects found none (`sessions/2026-08-15-standard-api-discovery/CNF_FULL_CATALOG_DISCOVERY_REPORT.md`). Cost creation and release are to be merged into one call (`SRC-MTG-20260817-01`). Shipment creation persists only with explicit commit; `SD_SCDS_CREATE` and headless `SD_SCDS_RELEASE` are callable. The existing VL02N **Depo Pre-requisite's** function checks batch, SPI, shipping/transport type, Incoterm, vehicle, LR/GR, transporter and `ZFB1` (`SRC-SID-20260915-03`). | Obtain architect/functional approval for the exact finalisation boundary; refactor those rules into a path-neutral validator; preserve the VL02N preview; call the validator as a mandatory Pre-PGI/finalisation gate; replace the `(SAPMV50A)TKOMV[]` pricing dependency; prove one real shipment-cost creation/release flow, including locks and partial-failure recovery. |
| OF-06 Create PGI | Standard-write candidate — not certified | Delivery v2 advertises `PostGoodsIssue` and `ReverseGoodsIssue`. **18 Sep, source and data:**<br>• The OData path runs `SAPMV50A` save exits: Create DI of `9004953174` fired unguarded `USEREXIT_SAVE_DOCUMENT` code (Verified by the resulting process order).<br>• Of the 13 transaction-layer plug-ins, most are `sy-tcode`-gated (VL0xN) and skip for API callers.<br>• The unguarded `ZNL` YSTO check passes for freight groups in set `ZSD_MFG_YSTO`.<br>• `ZSD_SHIP_CHECK` is a GSTIN check, not a shipment prerequisite.<br>• All 47 sampled goods-issued `ZNL` deliveries had a shipment (practice, not a coded rule).<br>Details: `sessions/2026-09-18-pgi-certification/FINDINGS.md`. | Settle the picking mechanics (storage location, batch with stock, picked quantity) through the standard pick actions; then execute PGI and reversal against controlled data under the write authorisation; re-read the material document and document flow. |
| OF-08 Create Order (STO) | Custom command exposure | Standard PO API reads STOs but rejects the required ZP06/item-category create shape. `BAPI_PO_CREATE1` is the core candidate. | Build the wrapper, prove commit/rollback and persistence, freeze derived organization/shipping values and test replay. |
| OF-07 Create Invoice | Custom command exposure, or conditional internal service | Standard Billing API is read/PDF only. `SD_CUSTOMER_INVOICES_CREATE` exposes a genuine `CreateBillingDocuments` POST but is application-internal (D-059, Q-068). The alternative is released `BAPI_BILLINGDOC_CREATEMULTIPLE` behind a wrapper. PGI and invoice cannot be combined, because each creates its own accounting document (`SRC-MTG-20260817-01`). | Select and execute the billing-create core, persist, re-read through the standard Billing API, and verify accounting/statutory continuation. |
| INV-01 E-Way Bill Extension | Existing client route to trace | eDocument, DigiGST tables and EY destinations are installed. | Identify the supported callable boundary and prove provider response, persistence and duplicate protection. |
| INV-02 Invoice Correction | Existing client route to trace | The permitted correction delta and installed statutory footprint are known. | Trace cancel/correct/regenerate semantics and prove separate e-Invoice and E-Way outcomes. |

## Submit MIGO — current hard boundary

The earlier “standard direct” label is retired for Submit MIGO.

- `API_MATERIAL_DOCUMENT_SRV` can post a 101 movement, but the proven request used both PO/item and delivery/item.
- The required portal contract is delivery-led. Existing ILMS callers show that SAP can derive the posting from delivery/item without caller-supplied PO.
- The standard OData mapping and allowed-field checks are not equivalent to a direct BAPI call.
- Eight identified MIGO-side customisation points are not reached by the BAPI/OData path. They include quantity, storage-location, billing-status and other business checks.
- `MB_BAPI_GOODSMVT_CREATE` is the approved direction. It is a released BAdI, the correct rung in the extension order below. Some validations, including reported no-PO handling, now work in QS4 through `ZEI_MM_GOODSMVT_BAPI_CUSTOM` / `ZCL_MM_GOODSMVT_BAPI_CUSTOM`, but the implementation is incomplete and not bulletproof (`SRC-SID-20260917-01/-02`).
- The 2 Sep finding that "the BAdI is never invoked" was wrong. Those test runs failed before the BAdI call at `LMB_BUS2017U04:546`. On 4 Sep the same probe fired once a run reached it (`deliverables/handover/CNF_SUBMIT_MIGO_STATE_OF_THINGS_2026-09-04.md`). That wrong finding is why work detoured into an explicit enhancement.
- The explicit enhancement `ZCNF_SUBMIT_MIGO_MAP2I` (code plugged into SAP's `MAP2I_B2017_GM_ITEM_TO_IMSEG`) was rejected at the 4 Sep architecture review as a last-resort option and is being deleted. Confirm the deletion transport has imported into QS4.
- The new phase-1 run is reported successful, but its material-document key, payload, messages and independent `MATDOC`/`MSEG` re-read have not yet been captured in the repository.

### Extension order — state it before proposing any custom code

SAP's order of preference for where custom logic goes, most to least acceptable:

1. Configuration / customizing
2. Standard released API or BAPI, used as delivered
3. **BAdI** (enhancement spot, or classic BAdI) or customer exit: an interface SAP has committed to keep stable
4. **Explicit enhancement**: custom code inserted at an `ENHANCEMENT-POINT`/`-SECTION` SAP left in its own source
5. **Implicit enhancement**: custom code inserted at the start or end of any SAP routine
6. **Modification** of SAP source (access key, SPAU adjustment)

Rungs 4–6 run inside SAP's code, can see its local variables and have no interface contract. A support pack can break them silently. Architects treat them as last resort. Any proposal on this project names its rung and why every higher rung was ruled out, with evidence, before the technical argument. Rungs 4–6 need architect sign-off before anything is built.

Active focus moves to Create DI, but Submit MIGO remains a partial implementation rather than a completed phase. Its missing validations and certification evidence stay open as a bounded follow-up.

## Create DI / Pre-PGI — current hard boundary

- The agreed Create DI validation scope is V01, V02, V03, V07, V08, V09a and V09b (`SRC-SID-20260917-02`). Certification is rule-by-rule; a clean create response proves none of them individually.
- The STO Create DI OData route is persistence-proven. Trade and Non-trade remain separate `_SLS` certification cases.
- `LE_SHP_DELIVERY_PROC` is not structurally isolated from BAPI delivery processing in the same way as `MB_MIGO_BADI`, but individual customer rules can still be screen-restricted or data-dependent.
- The one-distinct-material and depot single-storage-location rules in `ZLE_SHP_DELIVERY_PROC` explicitly require `VL01N` or `VL02N`; an external OData/BAPI caller is expected to bypass those particular branches.
- The currently retained non-Primary candidates are depot SLoc/SPI compatibility; referenced-order block and cumulative-quantity checks dependent on `LIKP-ZZVBELN`; an FTB self-transporter prohibition; and a separate depot-transporter-to-shipping-point mapping check. They are potentially shared, but their OData execution and required runtime data are not yet proven.
- Reviewer feedback relayed on 15 Sep states that the route/wheeler/load/freight validation group should apply only to Primary Plant deliveries. The captured freight-scale rule has a direct Primary Plant test; the route-configuration and first-item maximum-load rules do not visibly have the same test. Configuration may restrict them indirectly (`SRC-SID-20260915-02`).
- The reviewed Primary Plant SPI rule is not yet an approved requirement. The owner must decide whether interface-supplied SPI is rejected, overwritten or validated.
- The VL02N **Depo Pre-requisite's** button and the BAdI branch call `ZLEF_DELIVERY_VALIDATONS`. Its supplied source contains exactly ten later-stage business requirements (the `ZFB1` existence and non-zero-rate conditions form one freight requirement). Both known entry points are VL02N-oriented; no known path invokes the function during the initial Create DI POST.
- The function is not API-ready as written: it mixes validation with ALV/global-log behavior and reads pricing from `(SAPMV50A)TKOMV[]`.
- `SAVE_DOCUMENT_PREPARE` contains transporter/SPI/OData field derivations that may execute after `DELIVERY_FINAL_CHECK`. Until T0 proves call order and field availability, several apparently shared checks retain a silent-skip risk.
- The existing T-cases are designs, not yet qualified adversarial tests. The known STO/SO candidates do not provide matched positive/negative fixtures for every retained rule.

### 17 Sep — scope, data and API limits

- **C&F Create DI is depot-origin** (`SRC-SID-20260917-06`): depot → customer via `ZTRD` (→ `ZNP`, the dominant depot flow) and `ZNTR` (→ `ZLF`), and depot → depot STO (`ZNL`). All three routes were created through OData on 17 Sep (see OF-01).
- The STO candidates from plant `1002` are A1 (primary). They cannot exercise any depot rule.
- The standard delivery service cannot create or update SPI (`SpecialProcessingCode`) or the transporter partner, and cannot set storage location at **create**. Rules V02/V03/V09a/V09b therefore sit at the enrichment step.
  - **21 Sep update:** that enrichment step's write interface is now identified as **OF-02 Modify DI on the same standard delivery service**.
    - Storage location and batch are updatable.
    - SPI is display-only by design (`SRC-SID-20260921-02`).
    - The transporter can reach `VBPA` through `ZZPARTNER` via client derivation D1, once the 7 custom fields are declared.
  - Q-082 (which transition enforces the depot-prerequisite validator) remains open.
- `LIKP-ZZVBELN` is filled on 2 of 153,514 deliveries since 25.07.2026 and on no depot delivery; V07/V08 are recorded as dormant for C&F (writer still unidentified).
- Open depot sales-order candidates and the staged test sequence: `sessions/2026-09-14-create-di-enhancement-equivalence/CREATE_DI_TEST_APPROACH_2026-09-17.md`.

The consolidated Create DI authority beneath this file is
`sessions/2026-09-14-create-di-enhancement-equivalence/CREATE_DI_CURRENT_POSITION_2026-09-17.md`, read together with `CREATE_DI_TEST_APPROACH_2026-09-17.md` for the 17 Sep scope and test position.

### Working lifecycle direction — approval required before build

```text
Create DI
  -> enrich batch/SPI/transporter/vehicle/LR-GR
  -> shared depot-prerequisite validation at Pre-PGI/finalisation
  -> PGI / dispatch
  -> Submit MIGO receipt for STO movements
```

Keep initial Create DI narrow. Preserve the VL02N button as a preview, but extract the business rules into a path-neutral validator and enforce the same validator inside the approved Pre-PGI/finalisation command. Do not merely remove the `SY-TCODE` guard: delivery save hooks also serve change, deletion, PGI and reversal contexts.

For STO, dispatch creates the transporter, vehicle and LR/GR facts. The receiving MIGO path should derive/copy them for traceability and accept receipt-specific facts rather than asking the receiver to recreate the outbound shipment. This is a working architecture direction supported by existing ILMS derivation patterns, not yet an architect-certified contract. FTP/FTB/EXW ownership and field rules remain open.

### 21 Sep — the dispatch commit (working direction, not approved)

The portal Figma (`SRC-SID-20260921-01/-02`) makes the chain after Create DI one user commitment. Before "Generate Invoice & E-Way Bill", every step is resubmittable; after it, nothing changes. This matches the 17 Aug orchestration discussion (`SRC-MTG-20260817-01`):

- sequential calls;
- cost creation and release merged;
- PGI and invoice kept separate;
- 20–30 s end to end;
- two error classes, and no fire-and-forget background run.

Recommended integration pattern: hold the draft in the portal/T2 and write to SAP only at commit, in a fixed order:

1. OF-02 item quantity
2. OF-02 batch / storage location / pick
3. OF-02 header dispatch fields and `ZZPARTNER`
4. OF-05 shipment, then cost create+release
5. OF-06 PGI
6. OF-07 billing
7. INV e-invoice / e-way bill

Writing at each "Proceed" is possible (the delivery stays changeable until PGI), but it multiplies batch-split undo, locks and ETag conflicts.

The design risk is now CPI orchestration. It needs:

- a step ledger;
- idempotent resume-from-failed-step (Q-010 duplicate protection; D-064 repeat-request framework);
- user-visible partial-failure states, because PGI, billing and e-way are irreversible or only reversible by reversal documents.

## Repository precedence

Read in this order:

1. `CURRENT_STATE.md`
2. `deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx` for business contract and numbering
3. `sessions/2026-09-14-create-di-enhancement-equivalence/FINDINGS.md` and its rule register for Create DI/Pre-PGI enhancement evidence; for 18–21 Sep, read these sessions:
   - `sessions/2026-09-21-modify-di-extension-channel/` (OF-02)
   - `sessions/2026-09-21-create-di-qa-failures/` (OF-01 QA)
   - `sessions/2026-09-18-pgi-certification/` (OF-06)
   - `sessions/2026-09-18-submit-migo-header-fields/` (MIGO-02 custom fields; read its 21 Sep correction)
4. `deliverables/CNF_MIGO_CUSTOMISATION_DISPOSITION_2026-09-04.md`
5. `deliverables/handover/CNF_SUBMIT_MIGO_STATE_OF_THINGS_2026-09-04.md`
6. `sessions/2026-09-01-bapi-field-derivation/FINDINGS.md`
7. `sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md`
8. `DECISION_LOG.md`, `OPEN_QUESTIONS.md` and registered `SRC-SID-*` records
9. Older handovers and discovery packs as dated evidence only

## Next execution gates

**Status as of 21 Sep:** gates 1–3 below are **done** (17 Sep T0 trace and the Trade/Non-trade/STO depot creates, OF-01). The 21 Sep additions come first.

- **A. OF-01 QA closure:** portal schedule-line due-date pre-check (or BAdI); a change request for the deletion-flag rule; re-test error surfacing; clean up the QA deliveries `9004953582`–`…589`; brief the functional owner on the `ZPFG` process-order side effect.
- **B. OF-02 Modify DI:**
  1. Finish the read-only CFL registry check (can CFL adopt `ZSDA_CUSTOM_FIELDS1`?).
  2. Get Q-084 decided.
  3. Declare the 7 fields.
  4. Run one PATCH with `LIKP` readback, including the `ZZPARTNER` → `SP` derivation.
  5. Confirm with SD whether billing or the e-way bill reads `LIKP-PICKUPCODE`.
- **C. Dispatch commit orchestration:** write the CPI step ledger, resume and partial-failure contract across OF-02 → OF-05 → OF-06 → OF-07 → INV (Q-085).
- **D. MIGO-02 governance:** put the rung-5 custom-field enhancements to the architect (Q-086), then run one end-to-end post.
- **E. Housekeeping:** apply the v1.9 errata to the workbook (tab numbering, stale runtime status).

1. Make Create DI the primary execution workstream. Run T0 instrumentation for `_STO`, `_SLS` and OData to capture the exact BAdI hit set, call order and field contents at `DELIVERY_FINAL_CHECK` and `SAVE_DOCUMENT_PREPARE`.
2. Re-read and qualify Create DI fixtures before any write. `5600084274/00010` is consumed (`SRC-SID-20260915-01`); `5600084222/00010` was not consumed by the recorded `HEAD` attempt but its current availability is unknown. **21 Sep:** Trade candidate `5284403/000010` is consumed by QA (schedule line moved, material deletion-flagged at 6073); `5284217/000010` had no due schedule line on 21 Sep.
3. Prove Trade and Non-trade `_SLS` creation and persistence, not merely STO. Capture the predecessor, delivery type, BAPI route, created `LIKP/LIPS` document and document flow.
4. Build matched positive/negative fixtures for V01, V02, V03, V07, V08, V09a and V09b; then execute BAPI and OData pairs and prove expected errors plus non-persistence for rejected cases.
5. Settle the initial Create DI contract: caller-supplied versus SAP-derived Shipping Point and unit, plus the treatment of SPI and custom extension fields before the validation methods run.
6. Test Create DI replay, concurrency, authorization and stale pending quantity after validation-path equivalence is established.
7. Obtain architect/functional approval for the Pre-PGI/finalisation validation boundary, then design the shared depot-prerequisite validator without `SY-TCODE`, ALV or `(SAPMV50A)TKOMV[]` dependencies.
8. Close Submit MIGO phase-1 evidence as a bounded follow-up: capture the active class source/version, one delivery-led/no-PO run, returned messages, material-document/year, `MATDOC`/`MSEG` re-read, custom-header persistence and replay behavior (`SRC-SID-20260917-01`).
9. Freeze a single reviewed Postman pack only after those runtime results are reflected in the contract and examples.

## Definition of done for a write API

A write API is complete only when the exact route and version are fixed, a representative document persists, the document is independently re-read, client-specific enhancement behavior is accounted for, duplicate and concurrent attempts are tested, authorization and negative cases are captured, downstream linkage is verified, and recovery/reversal is documented.
