# Create DI — QA test results

**Source ID:** `SRC-SID-20260921-03`
**Date:** 2026-09-21
**Source type:** QA response relayed by Siddharth, plus VL01N screenshots taken by Siddharth

## Statements

1. The complete Create DI test in QA passed 8 validations. Three were reported "Not working as
   expected":
   1. A schedule line with a future date should not allow a delivery.
   2. A material flagged for deletion should not get a delivery.
   3. An appropriate error message should be shown in the user's log.
2. **VL01N comparison for case 1** (order `5284217/000010`): the log shows **`VL 248`**, type
   W, "No schedule lines due for delivery up to the selected date". Its long text says the
   system does not create a delivery item for the order item.
3. **Case 2:** VL01N has **no** deletion-flag check in the business's standard screen flow.
   The business wants one added.
4. The tests were executed through `/IWFND/GW_CLIENT`.

## Reconstruction

The test deliveries were identified from QS4 change documents, not supplied. See
`sessions/2026-09-21-create-di-qa-failures/FINDINGS.md`.
