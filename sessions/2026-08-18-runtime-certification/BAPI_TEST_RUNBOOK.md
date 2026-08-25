# DS4/200 BAPI test runbook

## What is proven

- All 15 captured modules exist in DS4/200 and are remote-enabled.
- Twelve business BAPIs plus `BAPI_GOODSMVT_CANCEL`, `BAPI_TRANSACTION_COMMIT`, and `BAPI_TRANSACTION_ROLLBACK` were inspected live in SE37.
- `BAPI_MATERIAL_AVAILABILITY` was executed read-only twice:
  - QS4-derived `15000177 / 1002 / TO`: `WM3351 Material 15000177 not maintained in plant 1002`, ATP `0.000`.
  - DEV master `MAT18 / PLQ3 / EA`: no RETURN error, ATP `0.000`.
- Exact parameter directions, optionality, types, DDIC fields, and return structures are in `payloads/bapi/*.json`.

## Release classification

Released: `BAPI_BILLINGDOC_CANCEL1`, `BAPI_BILLINGDOC_CREATEMULTIPLE`, `BAPI_GOODSMVT_CANCEL`, `BAPI_GOODSMVT_CREATE`, `BAPI_MATERIAL_AVAILABILITY`, `BAPI_OUTB_DELIVERY_CONFIRM_DEC`, `BAPI_OUTB_DELIVERY_CREATE_SLS`, `BAPI_OUTB_DELIVERY_CREATE_STO`, `BAPI_PO_CREATE1`, `BAPI_SHIPMENT_CREATE`, `BAPI_TRANSACTION_COMMIT`, `BAPI_TRANSACTION_ROLLBACK`.

Remote-enabled but **not released**: `BAPI_OUTB_DELIVERY_CHANGE`, `BAPI_SHIPMENT_CHANGE`, `BAPI_SHIPMENT_COST_ESTIMATE`. These are callable technically but are not a stable released integration contract. Any wrapper around them must be treated as a client-owned compatibility boundary.

## How to run in SE37

1. Open `SE37`, enter the function module, choose Display, then Test/Execute (F8).
2. Populate import structures by clicking the structure/value cell. Populate table rows in the table editor.
3. For simulation-capable BAPIs, set `TESTRUN = X` and execute. Do **not** call `BAPI_TRANSACTION_COMMIT`.
4. Capture the full `RETURN`/`ERRORS`/`SUCCESS` tables, every export value, the exact input variant, system/client/user, and timestamp.
5. A technically successful call is not enough: reconcile the result to ME23N/VL03N/MB03/VF03 as appropriate.

## Safe test sequence

| Sequence | Function | Mode | What it proves |
|---:|---|---|---|
| 1 | `BAPI_MATERIAL_AVAILABILITY` | Read-only | ATP behavior and master-data readiness. It is not API-05 book stock. |
| 2 | `BAPI_PO_CREATE1` | `TESTRUN=X` | STO header/item/schedule validation without creating a PO. |
| 3 | `BAPI_GOODSMVT_CREATE` | `TESTRUN=X` | GoodsMovementCode/reference rules and MIGO validation without posting. |
| 4 | `BAPI_BILLINGDOC_CREATEMULTIPLE` | `TESTRUN=X` | Billing due-item/type validation without billing creation. |
| 5 | `BAPI_BILLINGDOC_CANCEL1` | `TESTRUN=X`, `NO_COMMIT=X` | Cancellation eligibility without cancelling. |
| 6 | `BAPI_SHIPMENT_COST_ESTIMATE` | Approved data only | Freight estimate behavior; module is not released. No useful run is possible without a configured delivery/transporter. |
| 7 | Delivery/shipment create/change/confirm BAPIs | Gated write | These do not expose a reliable test-run control. Run only in DEV with approved disposable documents. |

## Commit and rollback rule

`BAPI_TRANSACTION_COMMIT` is a separate call used only after a successful write BAPI when the approved test requires persistence. `BAPI_TRANSACTION_ROLLBACK` can roll back the current LUW before commit, but it is not compensation after a committed delivery, goods issue, billing document, or shipment. Never use `WAIT='X'` or commit merely to make a test “look complete.”

## Business data still required

- A DEV ZP06 STO configuration and one open STO line, or an approved payload to create one.
- A DEV sales order for the Trade/Non-trade delivery path.
- A DEV delivery before picking, one after batch allocation, and one PGI-complete delivery.
- Eligible DEV batches/storage locations and a configured transporter/shipment type/planning point.
- One billable DEV delivery and one cancellable DEV billing document.
- MM confirmation of `GoodsMovementCode` and whether API-01 must send PO, delivery, or both.

