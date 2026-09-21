# Create DI enhancement-equivalence investigation

> **RECONCILED 2026-09-15.** Method-include coverage in this file was completed on
> 2026-09-15: every implementing class has **17** methods (`CM001`-`CM009` + `CM00A`-`CM00H`),
> confirmed by SE24 `RowCount` and by an exhaustive include probe. The REPOSRC census recorded
> here on 2026-09-14 was correct and is now fully backed by captured method bodies.
> See `CREATE_DI_ADDENDUM_2026-09-15_HEX_INCLUDES.md`.
>
> Evidence-class separation used across this session:
> **Verified source restriction** (a gate read in active code) /
> **Verified configuration behaviour** (a table or set read in QS4/700) /
> **Strong inference** (BAPI/OData reachability implied by source but not traced) /
> **Runtime unknown** (requires T0-T11, none executed).



**Date:** 2026-09-14  
**Scope:** `API_OUTBOUND_DELIVERY_SRV;v=2` -> delivery-create BAPI -> client delivery enhancements  
**Safety:** Read-only investigation. No delivery was created or changed.

## Executive finding

Create DI is **not yet business-certified**. The STO OData path is persistence-proven and was debugger-traced to `BAPI_OUTB_DELIVERY_CREATE_STO`, but activation of delivery BAdIs does not prove that every client rule runs for the OData call.

The first supplied `IF_EX_LE_SHP_DELIVERY_PROC` method dump contains real business validations and derivations. Some are UI-only, some are potentially shared with BAPI/OData, and several depend on custom fields that the standard OData request may not populate. **The dump is not yet bound to a specific implementation/class by authoritative screen evidence; its filename is not sufficient.**

The non-writing VL01N runtime trace verified interface-level dispatch of `CHANGE_DELIVERY_HEADER`, `CHANGE_FCODE_ATTRIBUTES` and `CHANGE_FIELD_ATTRIBUTES` under `SY-TCODE=VL01N`. It did not hit `DELIVERY_FINAL_CHECK` during an Enter PAI round-trip or Shift+F9 Incompleteness. That is inconclusive because the method is a last-check-before-save hook; no Save was attempted. The trace did not isolate individual customer classes for the three interface-level hits.

An additional unbound `DELIVERY_FINAL_CHECK` dump now provides the first explicit initial-Create-DI divergence: distinct-material and depot storage-location checks are enclosed by `SY-TCODE = 'VL01N' OR 'VL02N'`. They therefore cannot be assumed on a headless OData/BAPI request. The code restriction is verified; an external OData trace and equivalent-rule search are still required before stating that the business rule is definitely absent end to end.

Another important unresolved dependency is `LIKP-ZZVBELN`. Credit/delivery/billing-block checks and aggregate over-delivery protection execute only for delivery headers where this custom field is non-initial. The proven standard STO request did not establish this field. Trade/Non-trade certification must prove how `ZZVBELN` is populated, or prove equivalent standard checks independently.

## Evidence labels

- **Verified:** captured QS4 registry, source or runtime observation directly supports the claim.
- **Strong inference:** source structure strongly supports the claim, but the exact OData runtime path was not traced.
- **Unknown:** source or runtime evidence is still missing.

## Proven route

```text
API_OUTBOUND_DELIVERY_SRV;v=2 deep insert
  -> standard provider
  -> BAPI_OUTB_DELIVERY_CREATE_STO (STO route, debugger-proven)
     or expected BAPI_OUTB_DELIVERY_CREATE_SLS (sales-order route, untraced)
  -> SAP delivery engine
  -> applicable delivery BAdIs / exits / source plug-ins
  -> LIKP/LIPS persistence
```

- **Verified:** STO OData created and persisted delivery `9004953174`.
- **Verified:** the STO request reached `BAPI_OUTB_DELIVERY_CREATE_STO`.
- **Unknown:** the corresponding sales-order OData route and `BAPI_OUTB_DELIVERY_CREATE_SLS` call have not been traced.
- **Unknown:** the runtime set and order of customer enhancement calls for either route.

## Registered customer enhancement surface

### Dedicated BAPI-extension BAdIs

| Route | Enhancement implementation | Class | Interface | Registry state | Current conclusion |
|---|---|---|---|---|---|
| Sales order | `ZEI_LE_UPDATE_DELIVERY_CUSTOM` | `ZCLLE_UPDATE_DELIVERY_CUSTOM` | `IF_DLV_CREATE_SLS_EXTIN` | `@01@` | **Registry binding verified; supplied method source not yet bound to this class.** The supplied interface method performs mapping only and no validation. |
| STO | `ZEI_LE_UPDATE_DELIVERY_CUSTOM1` | `ZCLLE_UPDATE_DELIVERY_CUSTOM1` | `IF_DLV_CREATE_STO_EXTIN` | `@01@` | **Registry binding verified; supplied method source not yet bound to this class.** The supplied interface method performs the same mapping for STO items. |

Both delivery BAPIs expose `EXTENSION_IN` and `EXTENSION_OUT`. The captured implementations loop over `IT_EXTENSION_IN`, match the reference position through `VALUEPART1`, and copy `VALUEPART2` for recognised structure names. Recognised fields are LR/GR number/date, vehicle number/type, driver number/name/mobile and transporter partner. The `LIKP-ZZWERKS` branch is empty. There are no error messages, database reads or business checks.

The current OData deep-insert contract exposes standard header/item properties, not a generic `BAPIPAREX` container. Therefore these implementations are operationally inert unless the standard provider constructs `EXTENSION_IN` rows elsewhere. The captured OData payload does not supply any of the recognised custom data, and the fields belong to the later dispatch/shipment workflow rather than the minimal Create DI modal.

### Shared `LE_SHP_DELIVERY_PROC` implementations

The QS4 registry captured these six customer implementations as active:

| BAdI implementation | Enhancement implementation | Class from captured registry | Source status |
|---|---|---|---|
| `ZEI_LE_DELIVERY_PROCESS` | `ZEI_LE_DELIVERY_PROCESS` | `ZCLLE_DELIVERY_PROCESS` | Registry binding verified; supplied general BAdI dump may belong here, but source binding is unverified |
| `ZLE_SHP_DELV_INTECO` | `ZENH_SHP_DELV_INTCO` | `ZCL_IM_LE_SHP_DELV_INTECO` | Registry binding verified; filename-labelled source supplied, but source binding is unverified |
| `ZLE_SHP_DELIVERY_PROC` | `ZLE_SHP_DELIVERY_PROC` | `ZCL_IM_LE_SHP_DELIVERY_PROC` | Missing |
| `ZSDEI_DELIVERY` | `ZSDEI_DELIVERY` | `ZCL_IM_SDEI_DELIVERY` | Missing |
| `ZSD_DELV_ATT_ENHC` | `ZSD_DELV_ATT_EHC` | `ZCL_IM_SD_DELV_ATT_ENHC` | Missing |
| `ZSDE034_LIC_NOTIF` | `ZUCCSDE034_LIC_NOTIF` | `ZCL_IM_SDE034_LIC_NOTIF` | Missing |

These implementations sit at the shared delivery-processing layer. **Strong inference:** at least some methods are reachable from BAPI delivery processing. This is supported by the inspected implementation's own `CHANGE_DELIVERY_ITEM` comment, which describes a workaround deliberately used with `BAPI_OUTB_DELIVERY_CHANGE`. It does not prove that every method fires for delivery creation.

### `MV50AFZ1` source plug-ins requiring separate treatment

| Enhancement | Location | Initial relevance | Runtime conclusion |
|---|---|---|---|
| `ZEI_LE_UPDATE_DELIVERY_HEAD` | `SAPMV50A` / `MV50AFZ1` | Header derivation | Unknown |
| `ZEI_LE_VALIDATE_TRANSPOTER` | `SAPMV50A` / `MV50AFZ1` | Business validation | Unknown |
| `ZEI_LE_VALIDATE_YSTO` | `SAPMV50A` / `MV50AFZ1` | STO validation | Unknown |
| `ZEI_SD_UPDATE_DELBILLINGTYPE` | `SAPMV50A` / `MV50AFZ1` | Billing-type derivation | Unknown |
| `ZSD_DEL_SAVE_CHECK` | `SAPMV50A` / `MV50AFZ1` | Save validation | Unknown |
| `ZSD_RESTRICT_GRN` | nested under `ZSD_DEL_SAVE_CHECK` | GRN restriction | Unknown |
| `ZSD_SHIP_CHECK` | `SAPMV50A` / `MV50AFZ1` | Shipment validation | Unknown |
| `ZZCRM_DI_SEND` | `SAPMV50A` / `MV50AFZ1` | DI/CRM side effect | Unknown |
| `ZZ_LE_BIDDING_QTY` | nested under `ZZCRM_DI_SEND` | Bidding quantity | Registry state `@08@`, upgrade flag `X`; do not call active without confirmation |

Do not label these transaction-only merely because they are in `MV50AFZ1`. The exact FORM/enhancement position and standard call stack decide whether the BAPI reaches them. This differs from the structurally proven `MB_MIGO_BADI` transaction-only boundary.

## Unbound `IF_EX_LE_SHP_DELIVERY_PROC` method-dump analysis

The following analysis of the code itself remains valid. Attribution to `ZEI_LE_DELIVERY_PROCESS` / `ZCLLE_DELIVERY_PROCESS` is **provisional** until the SE19 implementation header or SE24 class identity is captured together with the methods.

### 1. `CHANGE_FIELD_ATTRIBUTES`

**Classification:** Verified UI-only; irrelevant to headless Create DI behavior.

The entire method is gated by `SY-TCODE = 'VL01N' OR 'VL02N'`. For delivery types `ZNL`, `ZNP`, `ZLF` and material freight groups `A0000001`, `A0000002`, `A0000003`, `A0000022`, it makes gross/net-weight fields display-only. It does not validate or derive persisted business data.

### 2. `DELIVERY_FINAL_CHECK`

This is the critical method.

| Rule | Exact condition | Effect | OData/BAPI exposure |
|---|---|---|---|
| Token-linked item quantity change | `SY-TCODE` is `VL02N` or `VL03N`; item quantity changed; active row exists in `ZLETILMSDELIVERY` | Error `ZLE 100` | **Verified bypass for headless BAPI change.** Relevant to Update DI, not initial Create DI. |
| Token-linked item deletion | Same transaction gate; item `UPDKZ='D'`; token link exists | Error `ZLE 099` | **Verified bypass for headless BAPI change.** |
| Token-linked delivery deletion | Header `UPDKZ='D'`; token link exists | Error `ZLE 099` | Potentially shared if the method fires; no `SY-TCODE` gate. |
| SLoc/SPI eligibility | Depot classification `KNA1-KDKG1='A2'`; item SLoc present; delivery type not bypassed by TVARVC `ZSD_PREREQ_DEL`; no `ZLETSPIMAP` row for SLoc + `LIKP-SDABW` | Error `ZLE 104` | Potentially shared. Create-time relevance depends on whether SLoc and SPI are already populated. |
| FTB self-transporter restriction | `IF_TRTYP` in `B/H/V`; depot plant; `LIKP-INCO1='FTB'`; active forwarding agent `PARVW='SP'`; creation date after TVARVC threshold; vendor is in `ZLE_SELF_TRANSPORTER` | Error `ZLE 205` | Potentially shared. Initial Create DI may not yet contain the forwarding-agent partner. |
| Predecessor block check | `LIKP-ZZVBELN` non-initial; referenced VBAK has `CMGST='B'`, nonblank `LIFSK`, or nonblank `FAKSK` | Error `ZLE 088` | **Critical conditional risk.** Runs only if custom `ZZVBELN` is populated. OData mapping/derivation not proven. |
| Aggregate delivery quantity <= SO quantity | `LIKP-ZZVBELN` non-initial; sum of earlier `LIPS-LFIMG` for deliveries with same `ZZVBELN` plus current items exceeds sum `VBAP-KWMENG` | Error `ZLE 087` | **Critical conditional risk.** Same `ZZVBELN` dependency. |
| Depot-transporter assignment | `IF_TRTYP` in `B/H/V`; delivery after TVARVC `ZLE_DEPOT_TRANSPORTER`; depot classification; active `SP` vendor; vendor absent from `ZM_KREDA_CDS` for shipping-point pseudo-customer | Error `ZLE 207` | Potentially shared. Initial Create DI may not yet have transporter. |

Additional observations:

- The method inserts an error only while `CT_FINCHDEL` is initial. An earlier error can suppress later custom errors from this implementation.
- `CMGST='B'` is the only explicitly blocked credit status in this custom rule. Whether this matches the approved business definition requires SD confirmation.
- The over-delivery check keys earlier deliveries through custom `LIKP-ZZVBELN`, not standard item predecessor fields `LIPS-VGBEL/VGPOS`.
- The code does not by itself prove whether standard SAP's own due-quantity checks already provide an equivalent or stronger block.

### 3. `SAVE_DOCUMENT_PREPARE`

**Mutations:**

1. If `LIKP-ZZPARTNER` is populated and the equivalent `SP` partner is absent, inserts the forwarding-agent partner in `CT_XVBPA`, deriving address and BP link from `LFA1`, `CVI_VEND_LINK` and `BUT000`.
2. For clinker (`MFRGR='A0000003'`) with custom vehicle number `LIKP-ZZVEHICLE_NO`, derives `LIKP-SDABW` from `ZLET_VEHICLE` status/type.

**Create DI risk:** the standard Create DI request does not currently carry transporter or vehicle data; those are captured later in the portal flow. The method will therefore be inert unless another enhancement/predecessor derivation populates the custom fields during creation.

### 4. `FILL_DELIVERY_HEADER`

- Sets `LIKP-VSART='01'` for delivery type `EL`.
- For delivery types listed in TVARVC `ZSD_PREREQ_DEL`, sets a dummy route from `SHORTAGE_DEFAULT_ROUTE` when route is blank. The source comment explicitly says this bypasses route-related validation.

**Classification:** Strong candidate for Create DI path behavior if this method fires. The TVARVC contents must be captured before deciding whether `ZNL`, `ZNP` or `ZLF` are affected.

### 5. `CHANGE_DELIVERY_ITEM`

Imports item changes from ABAP memory ID `BATCH` and copies `STGE_LOC` into `LIPS-LGORT`. The source explicitly ties this to `ZLEIILMSDOCUMENTS` calling `BAPI_OUTB_DELIVERY_CHANGE` because storage location could not otherwise be passed in the historical flow.

**Classification:** Change-path workaround, not initial Create DI logic. It is nevertheless strong evidence that this BAdI implementation is intentionally used by at least one BAPI delivery path.

### 6. `SAVE_AND_PUBLISH_BEFORE_OUTPUT`

The only production-order creation/release logic is commented out. Active behavior is effectively none.

## Unbound dedicated `_SLS_EXTIN` / `_STO_EXTIN` source analysis

The method signatures authoritatively identify the interfaces. They do not establish whether the two bodies came from the registry-mapped classes or were combined manually from separate classes.

Both `ADDITIONAL_INPUT` implementations have the same shape:

1. Loop over `IT_EXTENSION_IN` (`BAPIPAREX`).
2. Find the target SLS/STO item by reference position from `VALUEPART1`.
3. Copy `VALUEPART2` into a recognised custom field.

They map:

- `LIKP-ZZLRGRNO`
- `LIKP-ZZLRGRDATE`
- `LIKP-ZZVEHICLE_NO`
- `LIKP-ZZDRIVER_NO`
- `LIKP-ZZDRIVER_NAME`
- `LIKP-ZZDRIVERMOB`
- `LIKP-ZZPARTNER`
- `LIKP-ZZVHCLTYP`

`LIKP-ZZWERKS` is listed but has no executable assignment.

**Conclusion:** these are extension-field adapters, not business-validation BAdIs. They are not analogous to `MB_MIGO_BADI`. They contain no transaction-code gate and no validation to lose, but the standard OData path may simply pass an empty extension table.

## Provisionally labelled `ZENH_SHP_DELV_INTCO` source analysis

The code analysis below is valid for the supplied method bodies. Binding to enhancement implementation `ZENH_SHP_DELV_INTCO`, BAdI implementation `ZLE_SHP_DELV_INTECO` and class `ZCL_IM_LE_SHP_DELV_INTECO` remains unverified until captured on the SAP implementation/class screen.

### `DELIVERY_FINAL_CHECK`

The active rules are scoped to other delivery populations:

- For `LFART=ZRMC/ZRM2`, require `LIKP-ZZAUFNR`, prevent reuse of the same process order on another delivery for transaction types `H/V`, and require `LIKP-ZZVEHICLE_NO`. Errors: `ZSD 023`, `024`, `111`.
- For inbound delivery type `EL`, limit the number of PO confirmations using `EKES-ETENS` and TVARVC `ZMM_IBD_PO_COUNT`. Error: `ZMM 110`.

There is no `SY-TCODE` gate around these final checks. If the shared method fires, the checks are execution-path-neutral. None targets the known CNF Create DI delivery types `ZNL` (proven STO) or `ZLF` (observed Trade evidence). `ZNP` also does not appear.

### `SAVE_DOCUMENT_PREPARE`

Explicitly restricted to custom transactions `ZSD062` and `ZSD070`. It imports a value from ABAP memory `ZSD062_EXP` and writes `LIKP-LIFEX`.

**Conclusion:** verified screen/custom-transaction-only code, but unrelated to CNF Create DI.

### `CHANGE_DELIVERY_HEADER` and `CHANGE_DELIVERY_ITEM`

Both apply only to `ZRMC/ZRM2`. They call `ZSDF_FETCH_PROCESS_ORDER` and import vehicle/process-order/driver values from ABAP memory IDs. They are irrelevant to the current `ZNL/ZLF/ZNP` Create DI scope unless SD later proves one of those delivery-type assumptions wrong.

## `ZLE_SHP_DELIVERY_PROC` source analysis

Source file supplied first as `METHOD for dont remember.txt`, then as the exact first 458-line prefix of `methods for ZLE_SHP_DELIVERY_PROC.txt`. **Verified:** Siddharth directly confirmed that this source belongs to BAdI implementation `ZLE_SHP_DELIVERY_PROC` (`SRC-SID-20260914-01`). The captured registry separately maps it to enhancement implementation `ZLE_SHP_DELIVERY_PROC` and implementing class `ZCL_IM_LE_SHP_DELIVERY_PROC`.

The complete rule-by-rule extraction is maintained in `ZLE_SHP_DELIVERY_PROC_RULE_REGISTER.md`.

### Explicit `VL01N` / `VL02N` block

The following entire block is enclosed by:

```abap
IF ( sy-tcode = 'VL01N' OR sy-tcode = 'VL02N' ).
```

It performs these rules:

- It reduces the delivery item set to distinct materials. For the first item's sales channel/division (`VTWEG,SPART`), it reads TVARVC name `ZDEL_SPLIT`; when more than one material remains it raises `ZSD 002`.
- For a depot plant identified through customer `P<WERKS>` with `KNA1-KDKG1 = 'A2'`, it rejects more than one storage location with message `00 398`.
- On `VL02N` only, unless the delivery type is present in TVARVC `ZSD_PREREQ_DEL`, it calls `ZLEF_DELIVERY_VALIDATONS` with `IV_CALLED_FROM = 'B'`; returned errors become message `00 368`.

**Verified:** the first two rules include `VL01N`, so they apply during interactive creation rather than only later change/PGI.

**Verified:** callers whose `SY-TCODE` is neither `VL01N` nor `VL02N` do not execute this block.

**Strong inference:** an external OData call into `BAPI_OUTB_DELIVERY_CREATE_STO` / `_SLS` will not present itself as `VL01N` or `VL02N`, so this particular implementation will not enforce the first two rules on Create DI. Runtime tracing is still needed, and the repository must be searched for an equivalent rule elsewhere before classifying the business control itself as absent end to end.

### Change/delete and PGI controls

- Delivery/item deletion checks authorization object `ZLIKPDEL`, activity `06`, without a transaction-code gate. This concerns an existing-delivery change/delete, not initial Create DI.
- The shipment/shipment-cost block is a PGI control. It is activated by `WABU_T`, an ILMS PGI call stack, or the `IS_V50AGL` goods-issue flags. It verifies a shipment document and, conditionally, a non-zero shipment-cost document; it is not an initial-delivery-create rule.
- There is an intentional ILMS/BAPI bypass when include `ZLEIILMSDOCUMENTS_PGI` and block `BAPI_OUTB_DELIVERY_CHANGE` are both present in the call stack.

### Potentially shared create/save controls

These have no `SY-TCODE = VL01N/VL02N` gate and may execute through the shared delivery engine if this implementation is called:

- For transaction types `B/H/V`, a primary-plant/SPI rule uses set `ZSPIWERKS` and can raise `ZLE 187`.
- A route/maximum-weight rule reads `ZTA_PMD_VALID`, `ZLET_ROUTE_OVRWT` and `ZTA_WHEELER_WGHT`; it can raise `ZLE 208` or `ZLE 210`.
- A second wheeler/freight rule reads TVARVC `ZLE_WHEELER_FREIGHT`, `ZTA_PMD_VALID`, `ZLET_ROUTE_OVRWT`, pricing scale table `KONM`, and can raise `ZLE 077`, `078` or `079`.

The second freight rule dynamically reads screen-program global table `(SAPMV50A)TKOMV[]`. **Critical API-path risk:** if that global is not assigned and populated on the BAPI/OData path, `KNUMH`/`KSTBM` is never derived and the `ZLE 077` maximum-quantity rule can silently fail to run. This is not yet proven; capture the assignment state in both `VL01N` and external OData runs.

### Source-quality anomalies to verify

Two eligibility checks use `SELECT COUNT( * )` and then test only `SY-SUBRC`, without storing/testing the count: `ZDEL_SPLIT` and `ZTA_PMD_VALID`. This does not visibly prove the intended membership/configuration test. Confirm the runtime result and `SY-SUBRC` behavior at those lines before relying on those gates.

### Additional methods in the longer capture

`IF_EX_LE_SHP_DELIVERY_PROC~SAVE_DOCUMENT_PREPARE` contains only commented-out source. **Verified:** it has no active behavior in this capture.

`IF_EX_LE_SHP_DELIVERY_PROC~SAVE_AND_PUBLISH_BEFORE_OUTPUT` contains active code restricted to `SY-TCODE = 'VL09'` and delivery type `ZNL`. It finds the follow-on shipment in `VBFA` and calls `ZOTC_SHIPMENT_SCD_DELETE`. This is PGI-reversal cleanup, not Create DI logic.

The `SAVE_AND_PUBLISH_BEFORE_OUTPUT` body appears twice identically in the supplied text. A class cannot contain two active implementations of the same interface method, so treat the repetition as a manual capture/paste artefact; do not infer double execution or a second implementation from it.

## Direct answers

### Are there business validations inside delivery BAdIs?

**Yes — verified.** Supplied `DELIVERY_FINAL_CHECK` sources contain token protection, SLoc/SPI validation, transporter rules, predecessor block checks, aggregate quantity protection, delivery-splitting rules, shipment/PGI prerequisites and weight controls.

### Are any absent from a BAPI path in the same way as `MB_MIGO_BADI`?

- **Verified:** the token-linked quantity-change and item-deletion rules are absent from a headless BAPI change because they explicitly require `SY-TCODE=VL02N/VL03N`.
- **Not applicable to initial Create DI:** those two rules govern changes/deletions of an existing delivery.
- **Verified source restriction relevant to initial Create DI:** the distinct-material/delivery-split and depot single-storage-location rules explicitly require `SY-TCODE=VL01N/VL02N` and therefore include interactive creation while excluding other transaction contexts.
- **Strong inference for OData:** a headless Create DI request will bypass that gated block. Runtime must confirm `SY-TCODE`, and an equivalent-rule search must confirm whether the business control is absent elsewhere.
- **Critical conditional gap:** the credit/block and aggregate-quantity rules silently skip when `LIKP-ZZVBELN` is blank. The standard OData route must prove this field is set or prove equivalent standard validation.
- **Critical conditional risk:** the wheeler/freight maximum rule depends on `(SAPMV50A)TKOMV[]`; prove that this screen-program global is assigned/populated on the BAPI path.

## 2026-09-15 addendum — review feedback and depot prerequisites

### Validation-list review

`SRC-SID-20260915-02` records stakeholder feedback relayed by Siddharth:

- The depot single-storage-location rule and SLoc/SPI compatibility rule looked duplicated to reviewers. They are technically separate: cardinality versus permitted combination.
- The reviewers stated that the route/wheeler/load/freight validations numbered 4–6 should apply only to Primary Plant deliveries.
- The Primary Plant SPI rule numbered 10 requires further discussion.
- They require proof of API/interface execution and a search across BAdIs, user exits, screen exits and implicit/explicit enhancement points.

**Mismatch to resolve:** the captured freight-scale rule includes a direct Primary Plant classification test, while the route-configuration and first-item maximum-load rules do not visibly include the same test. They may be restricted indirectly by configuration; inspect the applicable configuration population before changing code.

### `ZLEF_DELIVERY_VALIDATONS` source now supplied

Siddharth supplied the function body on 15 September. The normalized capture is:

`source-captures/ZLEF_DELIVERY_VALIDATONS__USER_SUPPLIED_20260915.txt`

**Verified from supplied source:** it applies only to depot deliveries (`KNA1-KDKG1 = 'A2'`) and checks:

1. Batch assignment for batch-managed items.
2. SPI/special-processing indicator.
3. Shipping type.
4. Means-of-transport type.
5. Incoterm.
6. Vehicle number unless `VSART = '03'`.
7. LR/GR number.
8. LR/GR date.
9. Transporter/forwarding-agent partner role `SP`.
10. Presence of pricing condition `ZFB1`.
11. Non-zero `ZFB1-KBETR`.

`IV_CALLED_FROM = 'C'` displays an ALV log for the VL02N button. `IV_CALLED_FROM = 'B'` suppresses the popup and returns the error flag for the BAdI caller. The business checks are the same in both modes.

**Verified design constraints:** the function mixes validation, screen presentation and shared global log state. Its pricing check dynamically reads `(SAPMV50A)TKOMV[]`. It is therefore not reusable headlessly without refactoring and a path-neutral pricing source.

**Strong inference:** neither known caller makes these checks part of the initial Create DI OData POST. The button is a VL02N screen action, and the captured BAdI invocation is inside the `SY-TCODE = 'VL02N'` branch. A where-used search and external API breakpoint remain required to exclude another caller.

### Working lifecycle boundary

The defensible working design is:

```text
Create DI
  -> populate batch/SPI/transporter/vehicle/LR-GR during delivery enrichment
  -> run depot-prerequisite validation in the Pre-PGI/finalisation command
  -> PGI / dispatch
  -> Submit MIGO at the receiving location for STO flows
```

Do not add the entire prerequisite set to the initial Create DI POST: many of the required values do not exist yet. Preserve the existing VL02N button as a preview, extract the rules into one path-neutral validator, and call that same validator as a mandatory backend gate at the approved Pre-PGI/finalisation transition. This is a **working architecture direction**, pending architect/functional approval of the exact transition.

For STO, transporter, vehicle and LR/GR originate on the dispatch side and should be derived/copied into the receipt record for traceability. Submit MIGO should primarily accept receipt-side facts. Trade and Non-trade normally use a sales-order predecessor and do not create the corresponding internal Shree receipt; their exact `_SLS` route remains uncertified. FTP/FTB/EXW ownership rules remain open under Q-022/Q-034.

### Gateway Client test note

`SRC-SID-20260915-04` records that the 15 September attempt against `5600084222/00010` used HTTP `HEAD` against the service root and returned an empty HTTP 200. It was not a Create DI write. Do not consume the candidate based on that attempt; re-read current availability before a correctly authorised POST.

## Next evidence captures, in order

1. For every source dump, capture the SE19 screen showing both the BAdI implementation and enhancement implementation, then the implementing class. In SE24, capture the class name together with its method list/source. This is required to bind the supplied text to the correct implementation.
2. For `ZLE_SHP_DELIVERY_PROC`, capture message texts `ZSD 002`, `00 398`, `00 368`, `ZLE 077`, `078`, `079`, `187`, `208`, `210`; capture `FORM UPDATE_LOG`, text symbols `E01`–`E11`, and a byte-for-byte SAP export of `ZLEF_DELIVERY_VALIDATONS`. The normalized user-supplied body is now held, but its called form/texts are not. A corroborating SE19/class screenshot remains useful; source ownership is recorded under `SRC-SID-20260914-01` and `SRC-SID-20260915-03`.
3. Capture message texts `ZLE 087`, `088`, `099`, `100`, `104`, `205`, `207`.
4. Capture TVARVC values for `ZDEL_SPLIT`, `ZSD_PREREQ_DEL`, `ZSD_SHP_NOCHK`, `ZSD_SHP_COST_NOCHK`, `ZLE_WHEELER_FREIGHT`, `SHORTAGE_DEFAULT_ROUTE`, `ZLE_HIRING_TRANS_DATE`, `ZLE_SELF_TRANSPORTER`, `ZLE_DEPOT_TRANSPORTER`; capture set values for `ZSD_MFG_SHIPSKIP` and `ZSPIWERKS`.
5. Capture complete source of `ZCLSG_ABAP_UTILITIES=>CHECK_TVARVC_VALUES`, `CHECK_SET_VALUE`, and the definition/source of `ZM_KREDA_CDS`.
6. Open the remaining `LE_SHP_DELIVERY_PROC` implementations and capture their non-empty methods, prioritising `DELIVERY_FINAL_CHECK`, `SAVE_DOCUMENT_PREPARE`, `DOCUMENT_NUMBER_PUBLISH`, `FILL_DELIVERY_HEADER`, `FILL_DELIVERY_ITEM`, `CHANGE_DELIVERY_HEADER`, `CHANGE_DELIVERY_ITEM`.
7. Bind the supplied `_SLS_EXTIN` / `_STO_EXTIN` methods to their exact implementing-class screens and confirm there are no other non-empty methods.
8. Resolve every `MV50AFZ1` enhancement to its exact FORM/enhancement position through `ENHINCINX`, then capture the active source and gating conditions. This must cover the review request for user exits, screen exits, implicit/explicit enhancements and save-path validations without assuming every source plug-in is screen-only.
9. Retain `SHP_EXTEND_ODATA` for the service-layer investigation; inspect source and runtime independently rather than inferring behavior from its name.
10. Only after source review, run an authorised external OData trace for one sales-order case and one STO case. Compare `SY-TCODE` and `(SAPMV50A)TKOMV[]` between `VL01N` and external OData, record the hit/miss matrix for every relevant implementation/method, and independently re-read LIKP/LIPS.

## Current certification posture

| Scenario | Status |
|---|---|
| STO standard OData persistence | **Verified** |
| STO internal BAPI selection | **Verified: `_STO`** |
| Trade/Non-trade internal BAPI selection | **Expected `_SLS`; runtime unverified** |
| Customer BAdI registration | **Verified** |
| Supplied shared-BAdI method dumps contain business rules | **Verified; exact implementation ownership unbound** |
| Screen/API-risk method dump owned by `ZLE_SHP_DELIVERY_PROC` | **Verified: `SRC-SID-20260914-01`; class registry-mapped to `ZCL_IM_LE_SHP_DELIVERY_PROC`** |
| Initial-create rules explicitly gated to `VL01N/VL02N` | **Verified in source** |
| Those business controls are absent end to end from OData | **Strong inference for this implementation; equivalent-rule search/runtime pending** |
| All required Create DI rules execute through OData | **Unknown** |
| Trade business equivalence | **Not certified** |
| Non-trade business equivalence | **Not certified** |
| STO business equivalence | **Not certified beyond persistence/standard derivations** |

## Live-access blocker

The 2026-09-14 SAP GUI diagnostic reported one connection, description `SAP QAS`, with `Sessions=0` and `DisabledByServer=True`. Therefore no live scripted source capture was performed in this session. The source analysed above was supplied manually by Siddharth. Do not mislabel it as an automated runtime trace.
