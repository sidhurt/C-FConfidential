# Create DI from a sales order — storage location / batch inheritance

**QS4/700, 2026-08-25. NO POST WAS SENT.** No qualifying candidate exists.

## Objective

Determine whether `LIPS-LGORT` and `LIPS-CHARG` are inherited from `VBAP` when a delivery is
created through `API_OUTBOUND_DELIVERY_SRV;v=2` sending only `ShippingPoint`,
`ReferenceSDDocument`, `ReferenceSDDocumentItem`, `ActualDeliveryQuantity` and
`DeliveryQuantityUnit`.

## Outcome

**Not executable.** The test needs an **open, delivery-eligible sales order item that carries a
storage location**. No such item exists in the searched space, and the reason is structural
rather than incidental.

## Search performed

`VBAP` read read-only through SE16, column-limited:

| VBELN range | Rows | Coverage |
|---|---|---|
| `0000000001`–`0004999999` | 1500 | capped |
| `0005000000`–`0005279999` | 1500 | capped |
| `0005280000`–`0005299999` | 400 | capped; reached `0005284532` |
| `0005284533`–`0005999999` | 83 | **complete — top of the number range** |

3,483 sales order items examined. 3,400 of those were also checked for `CHARG`.

## Finding 1 — storage location is a function of item category

| Item category | `LGORT` | Items seen |
|---|---:|---:|
| `ZSDN` | **always populated** (`STG`) | 55 |
| `ZSTS` | **always populated** (`RMYD`) | 3 |
| `ZO99` | always blank | 292 |
| `ZTAD` | always blank | 123 |
| `ZF99` | always blank | 9 |
| `ZB99` | always blank | 1 |

No exceptions in either direction. `LGORT` appears only on `ZSDN` and `ZSTS`.

## Finding 2 — the categories that carry LGORT are never open

Every one of the 58 `ZSDN` / `ZSTS` items found is **fully delivered**. Checked individually
through `A_OutbDeliveryItem?$filter=ReferenceSDDocument eq '<order>'`.

Open items **do** exist — `0005284537`, `0005284538`, `0005284539`, `0005284540`,
`0005284541`, `0005284545`, `0005284546` — but every one is `ZO99`, and `ZO99` never carries a
storage location.

So the two conditions the test requires are, in this dataset, mutually exclusive.

The `ZSDN` orders are created and delivered the same day (created 20.08.2026, deliveries
`9004953119`–`9004953128` in one block), which is consistent with an automated
create-and-deliver process leaving nothing open.

Headers were clean on all candidates: `LIFSK` blank (no delivery block), `FAKSK` blank
(no billing block), `CMGST` blank (no credit status), `ABGRU` blank (no rejection).

## Finding 3 — batch is not maintained at sales order level at all

`VBAP-CHARG` was populated on **zero of 3,400** items across three ranges.

This is not a sampling artefact — it is consistent with batch determination happening at
delivery time rather than order entry. Supporting evidence: the deliveries raised from these
`ZSDN` orders all carry batch-split items (`9004953119/900001`, `900002`, and so on) with the
parent item at `0.000`, while the sales order behind them has no batch.

**Batch inheritance from `VBAP` to `LIPS` therefore cannot be tested in this system**, and on
current evidence there is nothing to inherit — the question may not be meaningful for this
configuration.

## What would unblock the storage-location test

Any one of:

1. A **newly created, undelivered `ZSDN` or `ZSTS` sales order**. Creating one is out of scope
   here and needs SD authorisation plus agreement that a test order may be left open.
2. Confirmation from SD that some other item category is expected to carry `VBAP-LGORT`, with
   an example.
3. Access to a client where the auto-delivery job is not running, leaving `ZSDN` orders open.

## What was deliberately not done

No POST was sent. No picking, batch split, update or PGI was performed. Nothing in QS4 was
changed by this exercise — every read above is read-only.
