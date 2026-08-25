# DS4 test data — what we need, and what each item unblocks

**Short answer: yes, DS4 can be made testable. It is a configuration and master-data job,
not a development one.**

Every item below traces to a specific SAP error message we hit during testing on 2026-08-19.
Nothing here is a wishlist — each line is a door that is currently shut, with the exact
message SAP returned when we walked into it.

---

## Read this first — there may be a cheaper route

DS4 has no vendors, no valuated stock, no deliveries, no sales orders, no ZP06 document type,
and posting periods open only for 1998. Standing all of that up is a genuine master-data
exercise, and at the end of it DS4 still will not resemble production.

**QS4 already has every one of those things** — real ZP06 stock transport orders, real
deliveries, real shipments, real freight cost documents, real invoices.

So the question worth putting to the client is:

> **Would a controlled write window in QS4 against one nominated test document be faster and
> more representative than building master data in DS4?**

One document, agreed in advance, created and reversed. That closes more open items in an
afternoon than a week of DS4 setup, and it tests against their real configuration rather than
a synthetic approximation.

If the answer is no — fair, and the rest of this document is the DS4 route.

---

## The three tiers

Do not try to build everything. Each tier closes a specific set of tests and can be delivered
independently.

| Tier | Effort | Closes |
|---|---|---|
| **1** | Hours | STO creation end to end |
| **2** | 1–2 days | Delivery creation, picking, PGI |
| **3** | Several days | The freight cost chain — the biggest remaining unknown |

---

# TIER 1 — STO creation

**Unblocks:** `BAPI_PO_CREATE1` running for real with `ZP06`, with a commit, producing a
document in `EKKO`/`EKPO`. That is the single most valuable thing still outstanding.

### 1.1 Open a posting period

| | |
|---|---|
| **Error today** | `M7 053 Posting only possible in periods 1998/03 and 1998/02 in company code 0001` |
| **Where** | `MMPV` (and check `MMRV`) |
| **What** | Open the current period for company code `1000` (and `0001` if used) |
| **Owner** | Basis / FI |
| **Effort** | Minutes |

This is the cheapest item on the entire list and it currently blocks every goods movement.

### 1.2 Transport `ZP06` into DS4

| | |
|---|---|
| **Error today** | `ME 013 Document type ZP06 not allowed with doc. category F` |
| **Where** | `OMEC` / `T161`, via transport from QS4 |
| **What** | The `ZP06` document type with its number range (`NUMKI = 56`), field selection `UBF`, and `BSAKZ = T` |
| **Owner** | MM config + Basis for the transport |
| **Effort** | Hours |

Confirm after transport: `SE16 → T161 → BSART = ZP06` should show `BREFN = UBF`, `BSAKZ = T`.

### 1.3 Two plants in the same company code, same currency

| | |
|---|---|
| **Error today** | `06 166 Please only use plants with local currency` |
| **Where** | `OX18` (plant→company code), `OX02` |
| **What** | A supplying plant and a receiving plant under one company code with one local currency |
| **Owner** | MM / FI config |
| **Effort** | Hours |

We confirmed `PLQ3` sits under company code `0001`. The pairing we tested (`PLQ3` → `PLQ1`)
crosses a currency boundary, which is why this fires.

### 1.4 One material extended to both plants, with valuation

| | |
|---|---|
| **Error today** | `M3 351 Material MAT18 not maintained in plant PLQ1` |
| **Where** | `MM01` / `MM17` |
| **What** | One material with Purchasing, Sales, Plant/Storage and **Accounting** views in both plants |
| **Owner** | Material master |
| **Effort** | Under an hour once the plants exist |

The Accounting view matters — it populates `MBEW`, which is what makes stock valuated. Without
it the goods movement tests stay blocked even with the period open.

### 1.5 Purchasing organisation and group

| | |
|---|---|
| **Error today** | `ME 083` on purchasing group |
| **Where** | `OME4`, `OMEQ`, purchasing org → plant assignment |
| **What** | A purchasing group, and the purchasing org assigned to both plants |
| **Owner** | MM config |
| **Effort** | Under an hour |

### Tier 1 acceptance test

`SE37 → BAPI_PO_CREATE1` with `DOC_TYPE = ZP06`, `TESTRUN` blank, followed by
`BAPI_TRANSACTION_COMMIT`. A document number appears in `EKKO` with `LIFNR` blank and
`RESWK` populated.

---

# TIER 2 — Delivery, picking, PGI

**Unblocks:** `API_OUTBOUND_DELIVERY_SRV;v=2` function imports — every one of which currently
has a confirmed signature but no executed run.

### 2.1 Receiving plant as a customer

| | |
|---|---|
| **Why** | An STO delivery ships *to* the receiving plant, which SAP treats as a customer |
| **Where** | `XD01`, then plant→customer assignment in `OMGN` |
| **Owner** | SD config + customer master |
| **Effort** | Hours |

This is also what populates `EKPV` — shipping point, route, `KUNNR`. Those are derived by SAP,
never sent by the caller, so this assignment is what makes them appear at all.

### 2.2 Shipping point and route determination

| | |
|---|---|
| **Where** | `OVL2`, `OVXD`, route determination `OVRF` |
| **What** | A shipping point for the supplying plant, and a route that resolves for the plant pair |
| **Owner** | SD / LE config |
| **Effort** | Hours |

### 2.3 Delivery type for stock transport

| | |
|---|---|
| **Where** | `OMGN` — delivery type per document type and supplying plant |
| **What** | The `NL` / `ZNL` equivalent so an STO can generate a delivery |
| **Note** | `ZNL` does not exist in DS4, so the delivery-type discriminator cannot be tested until it is transported |
| **Owner** | SD / MM config |

### 2.4 Storage location with stock

Post an initial stock receipt (`MB1C`, movement `561`) so there is something to pick and issue.
Requires Tier 1.1 and 1.4 to be complete first.

### Tier 2 acceptance test

Create a delivery against the Tier 1 purchase order, run `PickOneItem`, then `PostGoodsIssue`,
and confirm a material document in `MKPF`/`MSEG` and `LIKP-WBSTA = C`.

---

# TIER 3 — The freight cost chain

**Unblocks the biggest remaining unknown:** whether `SD_SCDS_RELEASE` completes a real
settlement without a screen. We proved it *runs* headless. We could not prove it *settles*,
because there was no freight cost document in the system to settle.

### 3.1 A transporter in the vendor master

| | |
|---|---|
| **Problem today** | `LFA1` is completely empty — there are no vendors at all in DS4 |
| **Where** | `XK01` |
| **What** | One vendor with the transporter partner function, and a transportation service agent role |
| **Owner** | Vendor master |
| **Effort** | Hours |

This single gap blocks the entire freight chain. Nothing in Tier 3 can start without it.

### 3.2 Transportation configuration

| | |
|---|---|
| **What** | Transportation planning point, shipment type, shipment cost type, shipment cost item categories |
| **Tables to check after** | `TVTK`, `TTDS`, `TVFT`, `TVFK` |
| **Owner** | LE-TRA config |
| **Effort** | Days |

We created shipment `1001` in DS4 with type `0001` and planning point `0001`, so the minimum
already exists. Cost determination needs more.

### 3.3 Freight pricing condition records

| | |
|---|---|
| **What** | A pricing procedure for shipment costs and at least one condition record that resolves for the route and shipment type |
| **Owner** | SD/LE pricing |
| **Effort** | Days |

Without a condition record the cost document will be created with zero value, which is not a
meaningful test of calculation or settlement.

### 3.4 Account determination

Settlement posts to accounting. Without account determination configured, release will fail at
the accounting step — which would look like a design problem and is not one.

### Tier 3 acceptance test

Create a shipment with deliveries, create the freight cost document, then run
`SD_SCDS_RELEASE` with `I_OPT_WITH_DIALOG = ' '` and confirm `VFKP-EBELN` receives a freight
purchase order number.

That is the test that closes the last real unknown in the pre-PGI design.

---

## What we are asking for, in one paragraph

> Tier 1 is a few hours of configuration and closes STO creation completely. Tier 2 is a day
> or two and closes delivery and goods issue. Tier 3 is the substantial one — it needs a
> transporter, transportation configuration and freight pricing, and it is what proves the
> settlement step end to end. If a controlled write window in QS4 is possible instead, that
> would close more, faster, and against real configuration.

---

## What we will not do

We will not fabricate master data ourselves to force a passing result. Test data has to be
created by the people who own that configuration, or the test proves nothing about their
system. What we will do is state exactly what is needed, run every test the moment it exists,
and record the raw result either way.

---

## Evidence for every claim in this document

| Claim | Source |
|---|---|
| Posting periods open for 1998 only | `BAPI_GOODSMVT_CREATE` `TESTRUN=X` → `M7 053` |
| ZP06 absent from DS4 | `BAPI_PO_CREATE1` → `ME 013`; `T161` read |
| Plant currency mismatch | `BAPI_PO_CREATE1` `UB` → `06 166` |
| Material not in receiving plant | `BAPI_PO_CREATE1` `UB` → `M3 351` |
| Purchasing group | `BAPI_PO_CREATE1` `UB` → `ME 083` |
| `LFA1` empty | Direct `SE16` read |
| Shipment creation works | Shipment `1001` created and committed in `VTTK` |
| Release runs headless | `SD_SCDS_RELEASE`, dialog off, clean return |
| QS4 has the real data | 15 live ZP06 STOs, delivery `9004953084`, 10,496 freight cost documents |
