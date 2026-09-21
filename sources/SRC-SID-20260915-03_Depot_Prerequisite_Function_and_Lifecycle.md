# Depot prerequisite function and lifecycle clarification

**Source ID:** `SRC-SID-20260915-03`  
**Date:** 2026-09-15  
**Source type:** Direct SAP source supplied by Siddharth plus direct process clarification  
**Related capture:** `../sessions/2026-09-14-create-di-enhancement-equivalence/source-captures/ZLEF_DELIVERY_VALIDATONS__USER_SUPPLIED_20260915.txt`

## What Siddharth supplied

Siddharth supplied the body of function module `ZLEF_DELIVERY_VALIDATONS` after following the **Depo Pre-requisite's** button from `VL02N`. The interface comment distinguishes:

- `IV_CALLED_FROM = 'B'` — BAdI caller;
- `IV_CALLED_FROM = 'C'` — Check-button caller.

The function validates depot deliveries, identified by customer `P<plant>` having `KNA1-KDKG1 = 'A2'`.

## Rules visible in the supplied function

1. Every batch-managed main item must have a batch-split/subitem assignment.
2. `LIKP-SDABW` (SPI/special-processing indicator) must be populated.
3. `LIKP-VSART` (shipping type) must be populated.
4. `LIKP-TRATY` (means-of-transport type) must be populated.
5. `LIKP-INCO1` (Incoterm) must be populated.
6. `LIKP-ZZVEHICLE_NO` must be populated unless `VSART = '03'`.
7. `LIKP-ZZLRGRNO` must be populated.
8. `LIKP-ZZLRGRDATE` must be populated.
9. An active delivery partner with role `SP` must exist.
10. Pricing condition `ZFB1` must exist.
11. The `ZFB1` rate `KBETR` must be non-zero.

When errors exist, the button path displays the accumulated log as an ALV popup. The BAdI path suppresses the ALV and returns `EV_ERROR_OCCURED = 'X'` to its caller.

## Evidence boundary

- **Verified from supplied source:** the checks and the `B`/`C` behavior above exist in the supplied function body.
- **Verified from the previously captured `ZLE_SHP_DELIVERY_PROC` source:** the known BAdI call to this function is within a `VL02N` branch.
- **Strong inference:** the two known callers—the button and that BAdI branch—do not make the function part of the initial headless Create DI OData call.
- **Unknown:** whether another caller exists outside `VL02N`; run a where-used search and API breakpoint trace.
- **Verified design defect for headless reuse:** the `ZFB1` check dynamically reads `(SAPMV50A)TKOMV[]`, and the presentation/error log is mixed into the same function. This is not a path-neutral API validator as written.

## Lifecycle clarification

Siddharth's working process understanding is:

```text
Create DI
  -> enrich delivery with batch/SPI/transporter/vehicle/LR-GR
  -> Pre-PGI readiness validation
  -> PGI / dispatch
  -> inbound Submit MIGO for STO receipts
```

The overlapping transporter, vehicle and LR/GR values describe the same physical movement. The dispatch side is expected to originate them. A receiving-side MIGO process should derive/copy them for traceability and ask the receiver only for receipt-specific facts such as receiving storage location, actual received quantity, shortage/damage and applicable AFR/challan data.

This lifecycle is a **working architecture direction**, not yet an architect-approved implementation decision. Trade and Non-trade normally end at the external customer and therefore do not create the corresponding internal Shree receipt; STO is the flow that connects outbound delivery/PGI to destination MIGO.
