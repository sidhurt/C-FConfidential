# `ZLE_SHP_DELIVERY_PROC` rule register

**Date:** 2026-09-14  
**Implementation:** `ZLE_SHP_DELIVERY_PROC`  
**Implementing class:** `ZCL_IM_LE_SHP_DELIVERY_PROC`  
**Primary method:** `IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK`  
**Source ownership:** Confirmed by Siddharth (`SRC-SID-20260914-01`)  
**Scope:** Active code in the supplied method captures. This is source analysis, not an OData runtime trace.

## Create/change validation rules

### `ZLE-DI-01` — one distinct material per configured delivery

- **When:** Only when `SY-TCODE` is `VL01N` or `VL02N`.
- **Population:** Current and prior non-deleted delivery items, reduced to distinct item numbers and then distinct materials.
- **Configuration:** TVARVC name `ZDEL_SPLIT`, using `LOW = <VTWEG>,<SPART>` from the first item.
- **Rule:** If more than one distinct material remains, reject the delivery.
- **Message:** `ZSD 002` plus `TEXT-E01`.
- **Create DI assessment:** **Explicit screen-path restriction.** The code includes interactive creation (`VL01N`) but excludes callers whose transaction code is not `VL01N/VL02N`. A headless OData/BAPI Create DI is therefore expected to bypass this implementation's rule; runtime `SY-TCODE` and any equivalent validation elsewhere remain to be proven.

### `ZLE-DI-02` — one storage location for depot delivery items

- **When:** Only when `SY-TCODE` is `VL01N` or `VL02N`.
- **Depot test:** Construct customer `P<WERKS>` from the first retained item and require `KNA1-KDKG1 = 'A2'`.
- **Population:** Non-deleted items after removing rows whose `UECHA = '000000'`; the remaining rows are reduced to distinct `LGORT` values.
- **Rule:** If more than one storage location remains, reject the delivery.
- **Message:** `00 398` plus `TEXT-E02`.
- **Create DI assessment:** **Explicit screen-path restriction.** This is relevant to interactive creation but is expected to be bypassed by headless OData/BAPI Create DI unless enforced elsewhere.

### `ZLE-CHG-01` — additional depot delivery validation

- **When:** `SY-TCODE = 'VL02N'` only, inside the depot block.
- **Exemption:** Delivery type exists in TVARVC `ZSD_PREREQ_DEL`.
- **Rule:** For a non-exempt type, call `ZLEF_DELIVERY_VALIDATONS` with current items/header/partners and `IV_CALLED_FROM = 'B'`.
- **Outcome:** If the function returns `EV_ERROR_OCCURED = 'X'`, reject the delivery.
- **Message:** `00 368` plus `TEXT-E03/TEXT-E04`.
- **Create DI assessment:** Not an initial-create rule; it is a `VL02N` change rule and is not part of a headless Create DI call.

#### Rules inside `ZLEF_DELIVERY_VALIDATONS`

The function body was supplied on 15 September and is preserved as a normalized capture under `source-captures/ZLEF_DELIVERY_VALIDATONS__USER_SUPPLIED_20260915.txt` (`SRC-SID-20260915-03`). It returns immediately unless the first retained item's plant resolves to depot classification `KNA1-KDKG1 = 'A2'`.

| Rule ID | Validation | Source dependency | Current lifecycle/API assessment |
|---|---|---|---|
| `ZLE-PRQ-01` | Every batch-managed main item has a batch-split/subitem assignment | `MARA-XCHPF`, `LIPS-UECHA`; `TEXT-E01` | Later delivery enrichment; not initial Create DI |
| `ZLE-PRQ-02` | SPI/special-processing indicator is populated | `LIKP-SDABW`; `TEXT-E02` | Pre-PGI prerequisite |
| `ZLE-PRQ-03` | Shipping type is populated | `LIKP-VSART`; `TEXT-E04` | Pre-PGI prerequisite |
| `ZLE-PRQ-04` | Means-of-transport type is populated | `LIKP-TRATY`; `TEXT-E03` | Pre-PGI prerequisite |
| `ZLE-PRQ-05` | Incoterm is populated | `LIKP-INCO1`; `TEXT-E05` | Pre-PGI prerequisite |
| `ZLE-PRQ-06` | Vehicle number is populated unless `VSART = '03'` | `LIKP-ZZVEHICLE_NO`; `TEXT-E06` | Conditional Pre-PGI prerequisite; business meaning of `03` open |
| `ZLE-PRQ-07` | LR/GR number is populated | `LIKP-ZZLRGRNO`; `TEXT-E07` | Pre-PGI prerequisite |
| `ZLE-PRQ-08` | LR/GR date is populated | `LIKP-ZZLRGRDATE`; `TEXT-E11` | Pre-PGI prerequisite |
| `ZLE-PRQ-09` | Transporter/forwarding-agent partner role `SP` exists | `VBPA-PARVW`; `TEXT-E08` | Pre-PGI prerequisite |
| `ZLE-PRQ-10` | Pricing condition `ZFB1` exists | `(SAPMV50A)TKOMV[]`; `TEXT-E09` | Screen-global dependency; must be replaced for headless reuse |
| `ZLE-PRQ-11` | `ZFB1-KBETR` is non-zero | `(SAPMV50A)TKOMV[]`; `TEXT-E10` | Screen-global dependency; must be replaced for headless reuse |

The function accumulates messages through `UPDATE_LOG`. For a non-BAdI caller it renders `GT_LOG` through `CL_SALV_TABLE`; for the BAdI caller it suppresses the popup. It then clears the global log and returns `EV_ERROR_OCCURED = 'X'`.

**Design assessment:** preserve the VL02N button as a preview, but do not copy this function unchanged into an API. Extract the business rules into a path-neutral validator with structured messages and an explicit pricing source, then call it from both the existing screen adapter and the approved Pre-PGI/finalisation command. The exact mandatory transition still needs architect/functional approval.

### `ZLE-DEL-01` — delivery deletion authorization

- **When:** A top-level item or delivery header has `UPDKZ = 'D'`.
- **Rule:** User must pass authorization object `ZLIKPDEL`, field `ACTVT = '06'`.
- **Outcome:** Reject unauthorized deletion.
- **Message:** `ZSD 013`.
- **Create DI assessment:** Not relevant to initial creation. There is no transaction-code gate, so it may protect non-screen deletion/change paths if this BAdI method is called there.

## Non-PGI save validations that may be shared with BAPI/OData

### `ZLE-DI-03` — primary-plant SPI restriction

- **When:** `IF_TRTYP` is `B`, `H` or `V`; not a PGI request; not an ILMS PGI call.
- **Early exits:** Deleted header, or `LIKP-SDABW` begins with `NC`; no active item with material freight group.
- **Primary-plant test:** `T001W` plant/customer joined to `KNA1` with `KDKG1 = 'A1'`.
- **Configuration:** Set `ZSPIWERKS`, checked using each item's material freight group `MFRGR`.
- **Rule implemented:** If the material freight group is in `ZSPIWERKS` and header `SDABW` is already non-blank, reject the delivery. The source comment says SPI is auto-filled for a primary plant.
- **Message:** `ZLE 187`.
- **Create DI assessment:** No `SY-TCODE` restriction. It may execute through Create DI if `DELIVERY_FINAL_CHECK` is called and the required fields are populated.

### `ZLE-DI-04` — first-item route/vehicle maximum weight

- **When:** The first delivery item is present.
- **Intended eligibility:** A row in `ZTA_PMD_VALID` for the first item's `WERKS/MFRGR/VTWEG`.
- **Configuration:** Current-date route entry in `ZLET_ROUTE_OVRWT`; its `ZOVERWT` selects a load type in `ZTA_WHEELER_WGHT` for the material freight group and current validity dates.
- **Rule:** If first-item delivery quantity `LFIMG` exceeds maximum `ZTOWEIGHT`, reject the delivery.
- **Messages:** `ZLE 208` for exceeded weight; `ZLE 210` when no current route-overweight configuration is found.
- **Create DI assessment:** No transaction-code restriction. Potentially shared with OData/BAPI if this method fires and route/item fields are populated.

### `ZLE-DI-05` — route-overweight configuration completeness

- **When:** `IF_TRTYP` is `B`, `H` or `V`, the delivery is not before the TVARVC cutoff, and the implementation does not set its skip flag.
- **Cutoff/configuration:** TVARVC `ZLE_WHEELER_FREIGHT`; item eligibility intended through `ZTA_PMD_VALID`.
- **Rule:** Current-date `ZLET_ROUTE_OVRWT` entries must exist for the delivery routes. A returned route row with blank `ZOVERWT` is also treated as invalid configuration.
- **Messages:** `ZLE 078` for blank `ZOVERWT`; `ZLE 079` when no route row is found.
- **Create DI assessment:** No transaction-code restriction. Potentially shared with OData/BAPI.

### `ZLE-DI-06` — freight-scale maximum delivery quantity

- **When:** Same `IF_TRTYP`, cutoff and eligibility block as `ZLE-DI-05`.
- **Pricing dependency:** Dynamically reads `(SAPMV50A)TKOMV[]`, finds item condition `KAPPL = 'F'`, `KSCHL = 'ZFB0'`, then reads maximum scale quantity `KONM-KSTBM` for its condition record.
- **Population:** For plants whose constructed customer `P<WERKS>` has `KNA1-KDKG1 = 'A1'`, sum non-deleted `LIPS-LFIMG` per delivery.
- **Rule:** If total delivery quantity exceeds the maximum pricing scale and the route has `ZOVERWT = 'No'`, reject the delivery.
- **Message:** `ZLE 077` with the route.
- **Create DI assessment:** **Critical API-path risk.** There is no transaction-code gate, but the rule depends on a global table belonging to screen program `SAPMV50A`. If `(SAPMV50A)TKOMV[]` is not assigned/populated during BAPI/OData processing, no maximum scale is derived and the rule silently produces no `ZLE 077` error. Runtime comparison is required.

## PGI rules — not initial Create DI

### `ZLE-PGI-01` — shipment document required before PGI

- **PGI trigger:** `VL01N/VL02N` with `SY-UCOMM = 'WABU_T'`, an ILMS PGI call stack, or `IS_V50AGL-WABUC/WARRENAUSGANG = 'X'`.
- **Material-group exemption:** Set `ZSD_MFG_SHIPSKIP`.
- **Order-type exemption:** TVARVC `ZSD_SHP_NOCHK`; order type is derived from the predecessor sales order or STO purchasing document.
- **Rule:** For a non-exempt order type, document flow must contain a shipment successor with `VBTYP_N = '8'`.
- **Message:** `00 368` with `TEXT-E05/TEXT-E06`.
- **Create DI assessment:** Not part of initial creation; this protects PGI.

### `ZLE-PGI-02` — shipment-cost document required before PGI

- **When:** `ZLE-PGI-01` found a shipment.
- **Shipment-type exemption:** TVARVC `ZSD_SHP_COST_NOCHK`.
- **Rule:** A `VFKP` shipment-cost record must exist. A zero/initial `NETWR` is rejected unless the compared source and destination transportation zones match.
- **Message:** `00 368` with `TEXT-E05/TEXT-E07`.
- **Create DI assessment:** Not part of initial creation; this protects PGI.

### `ZLE-PGI-03` — ILMS BAPI bypass

- **When:** The call stack contains include `ZLEIILMSDOCUMENTS_PGI` and block `BAPI_OUTB_DELIVERY_CHANGE`.
- **Rule implemented:** Skip the shipment/shipment-cost PGI checks above.
- **Create DI assessment:** Intentional BAPI-change exception for the ILMS PGI process, not initial Create DI.

## PGI reversal rule

### `ZLE-REV-01` — delete shipment and shipment cost during `ZNL` reversal

- **Method:** `IF_EX_LE_SHP_DELIVERY_PROC~SAVE_AND_PUBLISH_BEFORE_OUTPUT`.
- **When:** `SY-TCODE = 'VL09'` and `LIKP-LFART = 'ZNL'`.
- **Rule/action:** Find the shipment successor (`VBFA-VBTYP_N = '8'`) and call `ZOTC_SHIPMENT_SCD_DELETE` with shipment and delivery numbers.
- **Create DI assessment:** Screen-restricted PGI reversal cleanup; unrelated to initial Create DI.

The supplied text repeats this method body twice. Treat that as a manual capture/paste duplicate, not two runtime executions.

## Method with no active behavior

### `IF_EX_LE_SHP_DELIVERY_PROC~SAVE_DOCUMENT_PREPARE`

All supplied statements are commented out. The method has no active behavior in this capture.

## Source-level issues requiring runtime confirmation

1. `ZDEL_SPLIT` and `ZTA_PMD_VALID` eligibility use `SELECT COUNT( * )` followed only by a `SY-SUBRC` test; the count is not stored or tested. Confirm whether the intended configuration gates actually work.
2. `ZSD_MFG_SHIPSKIP` is checked in a loop while one flag is repeatedly overwritten; verify behavior for deliveries containing multiple material freight groups.
3. `ZLE-DI-06` depends on `(SAPMV50A)TKOMV[]`; compare assignment and contents in `VL01N` versus an external OData call.
4. `LV_KSTBM_MAX` is not visibly cleared per delivery/item in the captured freight-scale loop; verify multi-delivery behavior.

## Create DI bottom line

- **Expected bypass on external OData/BAPI:** `ZLE-DI-01` and `ZLE-DI-02`, because they explicitly require `VL01N/VL02N`.
- **Potentially shared but runtime-unverified:** `ZLE-DI-03`, `ZLE-DI-04` and `ZLE-DI-05`.
- **Potentially shared with a screen-global dependency:** `ZLE-DI-06`.
- **Not relevant to initial Create DI:** change/delete, PGI and `VL09` reversal rules.

The standard Create DI route cannot be business-certified until the two screen-only controls are either deliberately reimplemented at a supported API boundary or proven to have equivalent enforcement elsewhere, and the potentially shared rules are hit-tested on both `_STO` and `_SLS` routes.
