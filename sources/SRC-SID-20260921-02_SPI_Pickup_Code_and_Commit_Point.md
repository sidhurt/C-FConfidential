# SPI, pick-up code and the commit point of the dispatch flow

**Source ID:** `SRC-SID-20260921-02`
**Date:** 2026-09-21
**Source type:** Direct statements by Siddharth in session

## Statements

1. **SPI ID** is populated automatically from master data. It relates to shipment cost and
   comes from the sales order. The user does not enter it.
2. **Pick-up code** comes from the existing CRM (T1 / Udaan app) and is associated with
   orders.
3. **Commit point.** Until "Generate Invoice & E-Way Bill" is pressed, every step can be
   revisited, changed and resubmitted. Once it is pressed, the action is final and no changes
   are possible.

## Technical reading at time of receipt

- SPI (`LIKP-SDABW`, `SpecialProcessingCode`) is not updatable on
  `API_OUTBOUND_DELIVERY_SRV;v=2`. Display-only is consistent with that.
- `LIKP-PICKUPCODE` is not exposed by the delivery API. The client's VL02N check compares it
  with `VBAK-PICKUPCODE` for FTP at configured plants. Portal-side validation against the
  order is consistent. Whether billing or the e-way bill reads the delivery's pick-up code is
  not verified.
