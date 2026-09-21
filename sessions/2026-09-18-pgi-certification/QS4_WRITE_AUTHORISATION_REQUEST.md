# QS4 controlled write request — picking and goods issue on one nominated delivery

**Raised:** 2026-09-18
**System / client:** QS4 / 700
**User:** QNOVATE8
**Requested by:** Siddharth (Novate, C&F Agent SAP workstream)
**Approval needed from:** QS4 system owner + SD/MM functional owner

---

## What is being requested

Permission to run **picking and one goods issue** against a single nominated outbound
delivery in QS4/700, followed immediately by a reversal.

One delivery. One tonne. Created by us on 21 August specifically for this purpose.

## The nominated document

| Attribute | Value |
|---|---|
| Outbound delivery | `9004953174` |
| Item | `000010` |
| Predecessor STO | `5600084209` item `000010` |
| Material | `000000000015000177` |
| Supplying plant | `1002` |
| Receiving plant | `5412` |
| Quantity | `1.000 TO` |
| Delivery type | `ZNL` |
| Current goods-movement status | `WBSTK = A` (not started) |
| Actual goods-issue date | blank |

This delivery was created on 21.08.2026 by an external OData call as part of the agreed
Create DI certification. It has never been picked and never been goods-issued. It exists
solely as a test document.

## Why it is needed

The C&F portal will call SAP to post goods issue. We have confirmed from live `$metadata`
that the operation exists on `API_OUTBOUND_DELIVERY_SRV;v=2` and confirmed its signature.
**We have never executed it.**

Until it is executed we cannot answer three questions the design depends on:

1. **Does picking through the API assign a storage location?** The delivery item currently
   has no storage location and no batch. None of the standard picking operations accepts a
   storage location as input. We believe SAP derives it from the batch. That is an inference
   from one traced document, not a proven fact.
2. **Does the goods issue post cleanly from outside SAP**, with movement type `641` and the
   expected stock-in-transit behaviour?
3. **Does a repeated call create a second material document?** SAP has no replay guard on
   this chain. Whether the delivery's own status blocks a duplicate is untested.

Every downstream item — invoice creation, the freight chain, the portal's error handling —
is specified against assumptions that these three answers either confirm or invalidate.

## Exactly what will be executed

Serially, one at a time, with full before/after capture at each step. Nothing beyond this list.

| # | Operation | Target | Effect |
|---|---|---|---|
| 1 | `GET A_OutbDeliveryItem` | `9004953174` | Read only. Baseline. |
| 2 | `CreateBatchSplitItem` or `PickAndBatchSplitOneItem` | `9004953174/000010` | Adds a batch-split line. No stock movement. |
| 3 | `GET A_OutbDeliveryItem` | `9004953174` | Read only. Confirms storage location and batch. |
| 4 | `PostGoodsIssue` | `9004953174` | **Posts the goods issue.** Stock reduces at plant 1002. |
| 5 | `GET` document flow / material document | `9004953174` | Read only. Captures the material document. |
| 6 | `ReverseGoodsIssue` | `9004953174` | Posts the compensating movement. Stock restored. |

## Blast radius

**Contained to one delivery and one tonne of one material at plant 1002.**

- No other delivery, order, shipment, invoice or material is touched.
- No master data is changed.
- No configuration is changed.
- No transport is created.
- Nothing is executed in production.

## What we are honestly telling you about the risk

Three things, stated plainly rather than buried:

1. **Reversal is a compensating document, not an erasure.** After step 6 the stock balance
   returns to where it started, but both the original material document and the reversal
   remain on the record permanently. This is how SAP works and it cannot be avoided.

2. **Number ranges are consumed.** The material document numbers used are gone, whether or
   not the postings are later reversed.

3. **The batch we pick will be a real batch carrying real stock.** We will nominate the batch
   for your approval before step 2 rather than choosing one ourselves, so that you can pick
   one with no other business significance.

## What we need from you

| # | Item | Owner |
|---|---|---|
| 1 | Written approval to execute the six operations above | QS4 system owner |
| 2 | A nominated batch at plant 1002 carrying at least 1 TO of material `000000000015000177`, with no other business significance | SD/MM functional |
| 3 | Confirmation that `9004953174` is acceptable as the test document, or a different delivery nominated in its place | SD/MM functional |
| 4 | A preferred time window, if any | QS4 system owner |
| 5 | Named person we notify on completion, with the evidence pack | — |

## What you get back

A written evidence pack within one working day of execution, containing per step: the exact
request, the exact response, the SAP table state before, the SAP table state after, and a
reconciliation. Plus a plain statement of what was proven and what was not.

If any step fails we stop, report, and do not proceed to the next one.

## If this is refused

That is a legitimate answer and we will work to it. The alternative is building the DS4 test
data set described in `deliverables/DS4_TEST_DATA_REQUEST.md` — a multi-day master-data
exercise that produces a synthetic approximation of your configuration rather than the real
thing. We would rather ask for one tonne here than a week of setup there, but the decision
is yours.
