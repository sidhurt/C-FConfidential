# Create DI QA failures: the test cases reconstructed from QS4

**Date:** 2026-09-21
**System:** QS4 / 700, user `QNOVATE8`, SAP GUI scripting, read-only
**Trigger:** QA reported three failures after the full Create DI test. The tests were run
through `/IWFND/GW_CLIENT`; no document numbers were supplied.

| # | QA expectation | QA remark |
|---|---|---|
| 1 | Schedule line with a future date: the system should not allow a delivery | Not working as expected |
| 2 | Material flagged for deletion: no delivery should be created | Not working as expected |
| 3 | An appropriate error message should appear in the user's log | Not working as expected |

---

## The test run: Verified

The tester was user `S019423`, on 18.09.2026, working on **sales order `5284403` item 10**,
material `000000000015000262`, plant/shipping point `6073`, delivery type `ZNP`, item
category `ZO99`.

API-created deliveries are identifiable by a blank `LIKP-TCODE`; that user's dialog deliveries
the same day show `VL10X` or `ZLE020` (`evidence/LIKP_ERDAT_18.09.2026_VBELN_9004953000-9004959999.txt`).
Item data is in `evidence/LIPS_9004953582-9004953591.txt`.

| Time | Event | Source |
|---|---|---|
| 14:07:40 | Delivery `9004953582`, delivery date 10.08.2026 | LIKP/LIPS |
| 14:12:32–14:15:05 | VA02 / VKM4: rejection reason, credit release, schedule line reconfirmed | CDPOS |
| **14:15:34** | **VA02: schedule line `0001` `EDATU` 10.08.2026 → 25.09.2026** (`MBDAT`/`WADAT`/`LDDAT`/`TDDAT` also 25.09) | `evidence/CDPOS_VERKBELEG_0005284403_18.09.txt` |
| 14:16:07 | **Delivery `9004953583`, delivery date 25.09.2026**: future schedule line delivered | LIKP |
| 14:20:46, 14:26:51 | Deliveries `…584`, `…585` (25.09.2026) | LIKP |
| 14:22:27–14:24:03 | Delivery block `LIFSK 01` set, then removed (a separate test) | CDPOS |
| 14:27:48 | MM06: `MARC-LVORM` / `MBEW-LVORM` set for plant 6073 | `evidence/CDPOS_MATERIAL_15000262_0193184372-75.txt` |
| 14:29:44 | MM06: flag removed | same |
| **14:30:19** | **MM06: flag set again** | same |
| **14:30:29–14:37:13** | **Deliveries `…586`–`…589`**: created with the plant deletion flag active (`…588` quantity 0.333, `…589` quantity 0.017) | LIKP/LIPS |

**Verified:** `API_OUTBOUND_DELIVERY_SRV` created deliveries for a schedule line due a week in
the future (failure 1). **Verified:** it created deliveries while the material carried a
plant-level deletion flag (failure 2). Failure 3 follows from those two: no check fired, so
there was no error to return.

Deliveries `9004953582`–`9004953589` remain open (`WBSTK A`) in QS4.

---

## Standard-first reading

**1. Future schedule line.**
- VL01N selects schedule lines due up to a **selection date** (default today). That is
  standard delivery-due logic, not a client rule.
- The standard create entity accepts only `ShippingPoint` on the header and a reference plus
  quantity on items (DS4 metadata, `sessions/2026-08-18-runtime-certification/evidence/META_API_OUTBOUND_DELIVERY_V2_response.xml`).
  There is no due-date input.
- *Hypothesis:* the API's internal due date is not "today". That is not read in source.
- Standard-first handling: the portal checks the confirmed schedule-line date before calling
  Create DI, for example through the standard sales order API.

**2. Plant-level deletion flag.**
- Whether VL01N blocks this, and with which message, is **Unknown**. The dialog behaviour was
  not reproduced, because that would create a delivery.
- If it is a controllable system message, changing its category to error is a configuration
  fix. If it is a tcode-guarded client check (the pattern found on 2026-09-18 for
  `SAPMV50A`), the API won't reach it.
- Standard-first handling if configuration can't do it: a portal pre-check on the
  material/plant deletion flag, through a standard product API.

**3. Error message.** Re-test once 1 and 2 have a blocking path. Confirm that the portal
surfaces the OData error-response details.

## VL01N comparison (Siddharth, screenshots, 2026-09-21)

- **Case 1:** VL01N on `5284217/000010` logs **`VL 248` (type W)**, "No schedule lines due for
  delivery up to the selected date". Its long text says the system does not create a delivery
  item. This is standard due-date selection, not client code. **Verified: a parity gap.**
  VL01N creates nothing; the API created deliveries dated 25.09.
  `5284217` therefore currently has no due schedule line and is **not a clean positive
  candidate** today.
- **Case 2:** per the business, VL01N has **no deletion-flag check at all**, and they want one
  added. **This is a new business rule, not an API parity gap.** It applies to VL01N as much as
  to the API.

## Open

- The VL01N message number for cases 1 and 2. This needs a dialog attempt by a person, or
  the message class in customizing.
- Whether any of `9004953582`–`…589` triggered the ILMS process-order hook. That only applies
  to freight groups `A0000001`/`A0000022`, and `MFRGR` for `15000262` was not read.
- Clean-up of the eight open test deliveries is for the tester or functional owner.
