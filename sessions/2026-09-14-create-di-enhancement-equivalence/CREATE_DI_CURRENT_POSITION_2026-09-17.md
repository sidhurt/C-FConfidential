# Create DI — consolidated current position

**As of:** 2026-09-17  
**System:** QS4/700  
**Purpose:** Current, plain-language synthesis of the Create DI path, custom enhancement sweep,
business rules, lifecycle boundary and runtime-test status. This file supersedes stale open-item
statements in the earlier session notes; the captured source files remain the primary evidence.

**Active workstream from 2026-09-17:** Create DI is the primary execution focus while Submit MIGO
remains only partially implemented (`SRC-SID-20260917-01/-02`). The entry gate is T0 runtime
instrumentation for `_STO`, `_SLS` and OData—not new custom code. Prove method reachability,
call order and field availability before changing any validation or derivation.

> **Update, end of 17.09.2026:** T0 and the runtime tests have been executed. Results, the corrected
> depot scope and the rule standing are in `CREATE_DI_TEST_APPROACH_2026-09-17.md` (§8–19) and
> `QS4_READ_2026-09-17_PLANT_CLASS_AND_ZZVBELN.md`; the only Create DI build identified is the
> billing-block check (`../../deliverables/handover/CREATE_DI_BILLING_BLOCK_DEVELOPMENT_APPROACH_2026-09-17.md`).
> Where this file's runtime-status sections (§8–10) say "not executed", those later documents govern.

## 1. Direct answer

Create DI does **not** have a separate screen-only BAdI comparable to `MB_MIGO_BADI`.
The screen transaction, delivery BAPIs and OData route can enter the common delivery-processing
framework, including `LE_SHP_DELIVERY_PROC`. However, individual customer branches can still be
screen-only because their own source checks `SY-TCODE`, `SY-UCOMM` or screen-program globals.

Therefore:

- **Verified:** some delivery validations are explicitly limited to `VL01N`/`VL02N` and will not
  execute for a headless BAPI/OData request.
- **Strong inference:** several other validations are structurally reachable from a BAPI/OData
  call because they have no transaction-code gate.
- **Unknown:** those other validations are not certified on Create DI until runtime proves the
  method is called, the required fields exist when it is called, and the expected error is returned.

This differs from MIGO. The MIGO finding was a structural path split: `MB_MIGO_BADI` is not the
same enhancement path as `BAPI_GOODSMVT_CREATE`. Create DI instead has a shared delivery BAdI
surface containing individual screen-restricted and data-dependent branches.

## 2. Proven external route

- **Verified:** `API_OUTBOUND_DELIVERY_SRV;v=2` created and persisted STO delivery
  `9004953174`.
- **Verified:** the STO OData path reaches `BAPI_OUTB_DELIVERY_CREATE_STO`.
- **Unknown:** the equivalent Trade and Non-trade sales-order route is expected to reach
  `BAPI_OUTB_DELIVERY_CREATE_SLS`, but that exact runtime route is not yet traced or persistence
  certified.
- **Verified:** both delivery BAPI extension mechanisms can map recognised custom extension
  fields. This is mapping/derivation logic, not business validation.

## 3. Enhancement inventory

Six active customer implementations of `LE_SHP_DELIVERY_PROC` were found and all 17 interface
methods for each class were swept (`CM001`-`CM009` and `CM00A`-`CM00H`):

| Enhancement implementation | BAdI implementation | Implementing class |
|---|---|---|
| `ZEI_LE_DELIVERY_PROCESS` | `ZEI_LE_DELIVERY_PROCESS` | `ZCLLE_DELIVERY_PROCESS` |
| `ZENH_SHP_DELV_INTCO` | `ZLE_SHP_DELV_INTECO` | `ZCL_IM_LE_SHP_DELV_INTECO` |
| `ZLE_SHP_DELIVERY_PROC` | `ZLE_SHP_DELIVERY_PROC` | `ZCL_IM_LE_SHP_DELIVERY_PROC` |
| `ZSDEI_DELIVERY` | `ZSDEI_DELIVERY` | `ZCL_IM_SDEI_DELIVERY` |
| `ZSD_DELV_ATT_EHC` | `ZSD_DELV_ATT_ENHC` | `ZCL_IM_SD_DELV_ATT_ENHC` |
| `ZUCCSDE034_LIC_NOTIF` | `ZSDE034_LIC_NOTIF` | `ZCL_IM_SDE034_LIC_NOTIF` |

Additional relevant implementation:

- **Verified:** SAP standard implementation `SHP_EXTEND_ODATA`, class
  `CL_IM_SHP_EXTEND_ODATA`, is active. Its only non-empty method is
  `SAVE_DOCUMENT_PREPARE`; it maps OData extension fields into `CT_XLIKP`/`CT_XLIPS` and contains
  no business validation.
- **Verified:** `ZSD_DELV_ATT_ENHC` is empty across all 17 methods.
- **Verified:** `ZSDEI_DELIVERY` contains active `ZRMC`/`ZRM2` header-change logic and an active
  `BREAK ibmabap17`. Those delivery types are outside the present Create DI scope, but the hard
  breakpoint remains a defect/risk.

## 4. Agreed Create DI validation scope — runtime certification open

Siddharth confirmed V01, V02, V03, V07, V08, V09a and V09b as the current agreed requirements
on 17 September (`SRC-SID-20260917-02`). Agreement on the rule does not prove that its required
data exists during initial creation. In particular, transporter-dependent V09a/V09b still require
an explicit contract/lifecycle decision if the `SP` partner is supplied only after Create DI.

The technical register keeps the two transporter checks separate. A business email may group
them under one transporter heading, but they are different code branches and require different
negative tests.

| Ref | Plain-language requirement | Current classification |
|---|---|---|
| **V01** | Configured deliveries may contain only one distinct material. | **Verified screen-only:** explicitly restricted to `VL01N`/`VL02N`; error `ZSD 002`. |
| **V02** | Depot deliveries may contain only one storage location. | **Verified screen-only:** explicitly restricted to `VL01N`/`VL02N`; error `00 398`. |
| **V03** | For a depot delivery, the storage-location and SPI combination must exist in `ZLETSPIMAP`. | **Strong inference / API risk:** no tcode gate, but depends on `LGORT` and `SDABW` being present at check time; error `ZLE 104`. |
| **V07** | A referenced sales order with the coded credit, delivery or billing block must not be delivered. | **Strong inference / silent-skip risk:** only runs when custom `LIKP-ZZVBELN` is populated; error `ZLE 088`. |
| **V08** | Cumulative delivered quantity must not exceed the referenced sales-order quantity. | **Strong inference / silent-skip risk:** also depends on `LIKP-ZZVBELN`; error `ZLE 087`. |
| **V09a** | For an applicable depot FTB delivery, a transporter listed as a configured self-transporter is prohibited. | **Strong inference / silent-skip risk:** requires an active `SP` partner and date/config gates; error `ZLE 205`. |
| **V09b** | For an applicable depot delivery, the transporter must be mapped to the shipping point in `ZM_KREDA_CDS`. | **Strong inference / silent-skip risk:** requires an active `SP` partner and date/config gates; error `ZLE 207`. |

The phrase “depot and FTB transporter assignments must be valid” was only an umbrella summary.
It must not replace the precise V09a and V09b statements in technical documentation.

## 5. Primary Plant and other parked candidates

The following source rules were found but are **not in the current Create DI requirement list**:

- V04 route/overweight configuration.
- V05 vehicle/load maximum quantity.
- V06 freight-scale/overweight behaviour.
- V10 Primary Plant SPI behaviour.

Reviewer feedback says the route/wheeler/load/freight group should apply only to Primary Plant,
and V10 still requires business clarification. They are parked, not deleted: configuration or a
future scope decision can make them relevant again.

Two further conditional rules remain recorded separately:

- **V11:** a `ZNL`/manufacturer-group/`YSTO` pricing-condition check. It is near-dormant under
  current configuration but could fire for blank or uncovered manufacturer groups.
- **V12:** the trade-licence implementation can set `LIKP-LIFSK` when a licence is missing or
  expired. It is config-dead in QS4/700 because `ZGPT_SD_PARAM` is empty.

Neither V11 nor V12 is presently approved as a portal Create DI requirement.

## 6. Derivations and the execution-order risk

The sweep found three important derivations in `SAVE_DOCUMENT_PREPARE`:

- **D1:** `ZCLLE_DELIVERY_PROCESS` derives partner role `SP` from `LIKP-ZZPARTNER`.
- **D2:** the same method can derive/overwrite `LIKP-SDABW` from vehicle configuration.
- **D3:** the licence implementation imports `LIFEX` and `SDABW` from ABAP memory in applicable
  contexts.

SAP's `SHP_EXTEND_ODATA` extension mapping also runs in `SAVE_DOCUMENT_PREPARE`. The relevant
business validations run in `DELIVERY_FINAL_CHECK`.

**Strong inference:** standard delivery processing calls `DELIVERY_FINAL_CHECK` before
`SAVE_DOCUMENT_PREPARE`. If confirmed at runtime, V03, V07, V08, V09a and V09b may inspect blank
fields and silently skip even when the API supplied extension values that are mapped later.
Breakpoint hit order and field values must be captured before claiming API equivalence.

## 7. Depot prerequisites — later lifecycle, not initial Create DI

`ZLEF_DELIVERY_VALIDATONS` is depot-gated (`KNA1-KDKG1 = A2`) and contains exactly ten business
requirements:

1. Batch must be assigned for a batch-managed material.
2. SPI must be filled.
3. Shipping type must be filled.
4. Means-of-transport type must be filled.
5. Incoterms must be filled.
6. Vehicle number must be filled unless shipping type is `03`.
7. LR/GR number must be filled.
8. LR/GR date must be filled.
9. A transporter partner (`PARVW = SP`) must exist.
10. Freight condition `ZFB1` must exist with a non-zero rate.

Both known entry points are later-stage/VL02N-oriented: the **Depo Pre-requisite's** button and a
BAdI branch. No known caller invokes this function during the initial Create DI POST.

Seven values could theoretically exist at creation, but vehicle number, LR/GR number and LR/GR
date arise after dispatch is arranged. Because all ten are grouped into one readiness check, the
whole set belongs at the approved shipment/Pre-PGI/finalisation boundary, not initial Create DI.

The function is not API-ready as written. It mixes validation with ALV/global-log presentation,
and its `ZFB1` check reads `(SAPMV50A)TKOMV[]`. If that screen-program table is unavailable on a
headless path, the pricing check is silently skipped.

## 8. Runtime status and what is not yet proven

No T0-T11 runtime validation case has been executed. Source activation and absence of a tcode
gate do not prove that a rule fires through OData.

Still unknown:

- exact BAdI hit set and call order for STO OData, sales-order OData and both delivery BAPIs;
- whether the required custom fields exist at `DELIVERY_FINAL_CHECK` time;
- whether `(SAPMV50A)TKOMV[]` is assigned and populated on a headless path;
- whether the expected custom error, rather than an earlier standard check, rejects each negative;
- Trade and Non-trade persistence and business equivalence;
- replay, concurrency and representative negative behaviour.

## 9. Test-data reality

> **Superseded later on 17.09.2026.** C&F Create DI is depot-origin (`SRC-SID-20260917-06`).
> STO candidates `5600084222/223/274` ship from plant `1002`, which is **A1 (primary)**, so no depot
> rule can fire on them; they remain path-mechanics fixtures only. `ZZVBELN` is effectively unused
> (V07/V08 dormant for depots). Depot sales-order candidates, the metadata limits, the rule buckets
> and the test sequence are in `CREATE_DI_TEST_APPROACH_2026-09-17.md` and
> `QS4_READ_2026-09-17_PLANT_CLASS_AND_ZZVBELN.md`. The text below is kept as the earlier position.


The current documents are baseline/path-tracing candidates, not a complete adversarial fixture
set:

- `5600084274/00010` was reported consumed and must not be reused.
- `5600084222/00010` was not consumed by the recorded `HEAD` request, but current availability is
  unknown and must be re-read. Its single-item shape is unsuitable for V01/V02.
- Sales order `5270471` was used for a non-writing VL01N trace. Its one visible material and
  partial-delivery state do not make it a controlled negative fixture for every rule.

The existing T-cases are **test designs**, not yet executable adversarial cases. Before execution,
each rule needs a qualification sheet containing a matched positive and negative document where
every surrounding gate is proven and exactly one condition differs.

Required matched pairs:

| Rule | Positive fixture | Negative fixture |
|---|---|---|
| V01 | one distinct material | otherwise comparable order with two distinct materials |
| V02 | one storage location | otherwise comparable depot delivery with two storage locations |
| V03 | mapped SLoc/SPI pair | one pair absent from `ZLETSPIMAP` |
| V07 | unblocked referenced SO with `ZZVBELN` present | blocked referenced SO with `ZZVBELN` present |
| V08 | cumulative quantity at/below limit | quantity just above the limit |
| V09a | allowed transporter on depot FTB delivery | configured self-transporter, all other gates met |
| V09b | transporter mapped to shipping point | active transporter not mapped to that shipping point |

## 10. Runtime sequence required for certification

1. **T0 instrumentation:** use approved dynamic breakpoints to prove method reachability, field
   contents and `DELIVERY_FINAL_CHECK` versus `SAVE_DOCUMENT_PREPARE` order for `_STO`, `_SLS`
   and OData. This is path tracing, not adversarial testing.
2. **Qualify fixtures:** prove all database/configuration gates before calling anything.
3. **BAPI paired probes:** with explicit approval, exercise the matched pair without commit and
   capture returned messages and breakpoints. No-commit is lower risk, not purely read-only:
   number-range, locks or other transient effects may still occur.
4. **OData negative:** send the deliberately invalid request; capture the expected error and prove
   that no delivery persisted.
5. **OData positive:** create one approved valid case and independently re-read LIKP/LIPS/document
   flow to prove persistence and derived fields.
6. **Screen comparison:** for V01/V02, show VL01N/VL02N rejection and confirm the same explicit
   tcode branch is not entered on BAPI/OData.
7. **Certification extras:** execute replay, concurrent submission, authorization and recovery
   cases after rule equivalence is established.

Never alter debugger variables to manufacture a condition. If naturally qualifying test data
does not exist, the functional/data owner must prepare controlled fixtures.

## 11. Working lifecycle direction

```text
Create DI
  -> delivery enrichment / dispatch preparation
  -> shipment and shared depot-readiness validation
  -> Pre-PGI/finalisation
  -> PGI / dispatch
  -> Submit MIGO receipt for STO movements
```

This is a working architecture direction, not an approved build decision. The exact enforcement
boundary and rule ownership require functional/architect approval. Any refactoring must follow
the project extension order: configuration, standard released API/BAPI, released BAdI/customer
exit, explicit enhancement, implicit enhancement, modification.

## 12. Primary evidence

- `CREATE_DI_VALIDATION_MATRIX.md`
- `CREATE_DI_ADDENDUM_2026-09-15_HEX_INCLUDES.md`
- `BADI_IMPLEMENTATION_SWEEP.md`
- `DEPOT_PREREQUISITE_RECONCILIATION_AND_DESIGN.md`
- `DORMANT_RULES_REGISTER.md`
- `RUNTIME_TEST_PLAN.md`
- `source-captures/2026-09-15-QS4-scripted/`
