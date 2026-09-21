# PGI certification — test plan

**Opened:** 2026-09-18
**Target:** OF-06 Create PGI, plus the picking half of OF-05 Pre-PGI
**System:** QS4 / 700, user `QNOVATE8`
**Service:** `API_OUTBOUND_DELIVERY_SRV;v=2`
**Status:** BLOCKED — awaiting the write authorisation in
`QS4_WRITE_AUTHORISATION_REQUEST.md`

---

## 1. Why this is the next piece of work

Create DI is proven: delivery `9004953174` was created and persisted through
`API_OUTBOUND_DELIVERY_SRV;v=2` on 21.08.2026.

Picking and `PostGoodsIssue` sit on **the same service, the same version, the same
authentication path**. No new infrastructure, no new ABAP, no new activation request. They
are the only remaining steps in the order-fulfilment chain that need nothing built first.

Everything else is gated:

| Candidate | Gate |
|---|---|
| OF-03 Stock Availability | Proven read. What remains is an MM decision on stock categories, not engineering work. |
| OF-05 Pre-PGI, freight half | Needs a custom ABAP wrapper over unreleased `SD_SCD*` modules, plus a named owner for upgrade risk. Weeks, and not ours to start alone. |
| OF-07 Create Invoice | Hard-blocked upstream — SAP refuses billing before goods issue. Also carries an unresolved architecture decision. |

PGI is also the precondition for testing OF-07 at all.

## 2. The state we are starting from

From `sessions/2026-08-21-qs4-create-di/QS4_CREATE_DI_SUCCESS.md`, readback of
`9004953174/000010`:

```
LIKP    VBELN=9004953174  LFART=ZNL  VSTEL=1002  KUNNR=P5412  WBSTK=A  WADAT_IST=blank
LIPS    MATNR=000000000015000177  WERKS=1002  LGORT=blank  LFIMG=1 TO
        VGBEL=5600084209  VGPOS=000010  BWART=641  WBSTA=A
```

**The delivery cannot be goods-issued in this state.** No storage location, no batch. SAP
will not move goods it cannot locate.

## 3. The hypothesis under test

None of the standard picking function imports accepts a storage location:

| Operation | Parameters | Storage location? |
|---|---|---|
| `PickOneItemWithBaseQuantity` | 4 — `ActualDeliveredQtyInBaseUnit`, `BaseUnit`, `DeliveryDocument`, `DeliveryDocumentItem` | No |
| `PickAndBatchSplitOneItem` | 5 — `Batch`, `DeliveryDocument`, `DeliveryDocumentItem`, `SplitQuantity`, `SplitQuantityUnit` | No |
| `CreateBatchSplitItem` | 6 — includes `PickQuantityInSalesUOM` | No |

**Hypothesis:** SAP derives the storage location from the batch's own stock location.

**Basis:** delivery `9004953077` (traced 16.08.2026) carried main line `000010` with no batch
and no storage location, and split lines `900001` (batch `2623029112`, `LGORT` `PC88`) and
`900002` (batch `2630004639`, `LGORT` `SELF`). The batch-split line is where both values
appear.

**Confidence:** inference from one traced document. Not proven.

**If it is wrong:** the fallback is a `PATCH` on `A_OutbDeliveryItem` setting
`StorageLocation`. Whether that property is updatable is unverified — the preserved notes on
the retired API-12 sheet record `Batch` as `creatable=false` / `updatable=true` but say
nothing about `LGORT`. Check `$metadata` before assuming.

**This is step 2 of the run and it decides the shape of the rest.** Resolve it before
anything else.

## 4. Run sequence

One call at a time. Capture `REQUEST`, `RESPONSE`, `PRE_STATE`, `POST_STATE`,
`RECONCILIATION` per step. Stop on any unexpected result — do not proceed to the next step.

### Step 1 — Baseline, read only

```
GET /sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader('9004953174')
    ?$expand=to_DeliveryDocumentItem&sap-client=700
```

Confirm `WBSTK = A`, `WADAT_IST` blank, no `9000xx` lines, `LGORT` blank.
Independently read `LIKP` / `LIPS` in SE16N. Confirm no material document exists.

**Gate:** if the delivery has changed since 21.08.2026 — picked, issued, deleted — stop and
re-baseline before going further.

### Step 2 — Picking / batch split

Use the batch nominated by the functional owner. Prefer `CreateBatchSplitItem`; fall back to
`PickAndBatchSplitOneItem`.

**Encoding caveat:** OData V2 function imports conventionally carry parameters in the query
string. That is inferred from the convention, **not proven** — no function import on this
service has ever been executed. Treat an HTTP 400 as a possible encoding problem before
concluding the operation is unsupported. Try query string first, then request body.

Proving the encoding here unblocks all six function imports at once. It is the highest-value
single result in this run.

### Step 3 — Confirm the derivation, read only

Re-read the item. Record:

- Did a `9000xx` split line appear?
- Does it carry the batch?
- **Does it carry a storage location, and which one?**
- What is `WBSTA` on the main line and on the split line?
- Do main-line and split-line quantities sum correctly, or double-count?

**This answers the hypothesis in §3.** Write the answer down before moving on, whichever way
it falls.

### Step 4 — Post goods issue

```
POST /sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/PostGoodsIssue
     ?DeliveryDocument='9004953174'&sap-client=700
```

Requires `x-csrf-token` **and** the matching session cookie. A token without its cookie is
rejected and the failure looks like an auth error rather than a CSRF error — do not
misdiagnose it.

### Step 5 — Read back the material document

`PostGoodsIssue` does not return the material document number. Retrieve it from
`A_OutbDeliveryDocFlow`, then confirm independently in SAP:

- `MKPF` / `MSEG` — the material document exists, movement type `641`, quantity `1.000 TO`
- `LIKP-WBSTK = C`, `WADAT_IST` populated
- `EKBE` on STO `5600084209` — a goods-issue row appears
- Stock at plant 1002 reduced by 1 TO; stock in transit increased

**A success response is not proof.** The material document must be read back independently.
The shipment-create test in August returned a success message and a real-looking document
number for a document that did not exist.

### Step 6 — Reverse

```
POST .../ReverseGoodsIssue?DeliveryDocument='9004953174'&ReversalReason='<code>'
```

Confirm a **compensating** movement, not a deletion. The original material document must
still be present. Confirm stock is restored.

## 5. Negative tests

Run only with explicit approval, and only after the positive path is complete.

| Test | Expected | Why it matters |
|---|---|---|
| `PostGoodsIssue` twice on the same delivery | Refused; no second material document | SAP has no replay guard on this chain. Whether the delivery's own status blocks a duplicate is the question. |
| `PostGoodsIssue` on an unpicked delivery | Refused | Confirms the picking gate is real. |
| Batch split exceeding available stock | Refused | Confirms live stock revalidation at picking. |

## 6. What this run closes

| Open item | Closed by |
|---|---|
| Storage-location derivation through the API | Step 3 |
| Function-import parameter encoding — affects all six operations | Step 2 |
| `PostGoodsIssue` executes from outside SAP | Step 4 |
| Movement type `641` on a `ZNL` delivery | Step 5 |
| Material document read-back route | Step 5 |
| Reversal is compensating, not deleting | Step 6 |
| Duplicate protection behaviour | §5 |

## 7. What this run does NOT close

State these limits in the evidence pack rather than letting anyone infer more than was proven.

- **Trade and Non-trade.** This is a `ZNL` STO delivery. Nothing here transfers to a sales-order
  predecessor. The movement type for Trade and Non-trade remains OPEN.
- **PGI-specific client enhancements.** Whether the transaction path runs logic the API path
  skips is a separate source audit — the same problem already established for Submit MIGO.
  A clean post does not mean an equivalent post.
- **Whether settlement is technically required before PGI.** If this delivery has no freight
  cost document, a successful PGI proves only that PGI works *without* one — not that SAP
  permits it when settlement is relevant but incomplete. The decisive test remains a
  `VFKK` document with `STABR = A` traced to its delivery's `WBSTK`, and that is a read-only
  query in QS4 needing no authorisation.
- **The `601` versus `641` difference.** Both appear in STO context in our evidence and the
  difference has never been explained.

## 8. Parallel work — no authorisation needed

Three of these cost nothing to start today and have long decision latency. Raise them now
rather than when they become the blocker.

| # | Ask | Owner | Unblocks |
|---|---|---|---|
| 1 | Which `InventoryStockType` values constitute "system stock" | MM / functional | Finalises OF-03 |
| 2 | Billing creation route: Option A (`SD_CUSTOMER_INVOICES_CREATE`, application-internal, no new build) vs Option B (`BAPI_BILLINGDOC_CREATEMULTIPLE`, released, needs a wrapper) | Architecture | OF-07 — the last open architectural choice in the chain |
| 3 | Named owner for SAP upgrade risk on the unreleased `SD_SCD*` modules, plus ABAP wrapper resourcing | SAP/ABAP lead | OF-05 freight half |

Additionally, runnable **without** authorisation:

- **The `STABR = A` query.** Read-only in QS4. Settles whether settlement technically gates
  PGI — the single highest-value outstanding read, flagged as unrun since 18.08.2026.
- **Source inspection of `SAPLV56I_BAPI`.** Determines whether `BAPI_SHIPMENT_CREATE` already
  triggers cost-document creation on save. If it does, the exposed surface for OF-05 shrinks
  materially. Read-only, needs no data.

## 9. Evidence layout

```
sessions/2026-09-18-pgi-certification/
  PLAN.md
  QS4_WRITE_AUTHORISATION_REQUEST.md
  runs/
    01_BASELINE/          REQUEST RESPONSE PRE_STATE POST_STATE RECONCILIATION
    02_BATCH_SPLIT/
    03_DERIVATION_CHECK/
    04_PGI/
    05_MATDOC_READBACK/
    06_REVERSAL/
  FINDINGS.md
```

Per repository discipline: label every material claim Verified, Strong inference,
Hypothesis, Contradicted or Unknown. Do not promote HTTP 200, an allocated document number
or a BAPI success message into a persistence claim. Re-read the created document.
