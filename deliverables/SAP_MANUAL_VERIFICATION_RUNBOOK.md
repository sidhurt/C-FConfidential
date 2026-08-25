# Verifying CNF API results by hand in SAP

**Written 2026-08-25. Every table read in here was executed against QS4/700.**

The purpose of this document is to let anyone — you, a functional consultant, a sceptical
client — confirm what an API call actually did, without trusting the API's own response.

The two documents used as worked examples are real:

| What | Document | Created by |
|---|---|---|
| Outbound delivery (Create DI) | `9004953174` from STO `5600084209` item `000010` | OData deep insert, 21 Aug |
| Material document (Submit MIGO) | `5007138597` / `2026` against STO `5600084239` item `00010` | OData deep insert, 25 Aug |

---

## 1. First, the VBFA question — and why it is not a defect

The Create DI certification noted that `LIPS` confirmed the predecessor link but **no `VBFA`
row was observed**. That observation is correct, and it is still true four days later:

```
VBFA where VBELN = 9004953174   ->  No table entries found
VBFA where VBELV = 5600084209   ->  No table entries found
```

**This is correct SAP behaviour, not a timing issue and not a missing link.**

`VBFA` is the **SD** document flow. Sampling 30 arbitrary rows in QS4/700 returns exactly one
shape:

```
VBTYP_V = C  ->  VBTYP_N = J        (sales order -> delivery)
e.g. 0005284523/000010 -> 9004953119/000010
```

`VBTYP` is a *sales and distribution* document category. A purchase order is an **MM**
document and has no `VBTYP` at all. So a delivery created from a stock transport order has no
SD predecessor to record, and SAP writes no `VBFA` row for it. Waiting for one is waiting for
something that will never arrive.

Do not restate this as "an immediate VBFA row was not observed" — that implies it might appear
later. It will not appear for the PO link, ever.

**The STO document flow lives in two places instead:**

| Side | Table | What it holds |
|---|---|---|
| Delivery | `LIPS-VGBEL` / `LIPS-VGPOS` | The predecessor purchase order and item |
| Purchase order | `EKBE` | Purchase order history — every delivery, goods issue and receipt |

`VBFA` becomes relevant for an STO delivery only **after goods issue**, and then the
predecessor is the *delivery*, not the purchase order.

---

## 2. The fastest manual proof — ME23N

**`ME23N`** — Display Purchase Order. This is the single most useful screen, because the PO
history tab is the STO's document flow.

1. `ME23N`
2. If it opens a different PO: **Other Purchase Order** (`Shift+F5`), enter `5600084209`
3. Expand the **item** section and select item `10`
4. Open the **Purchase Order History** tab

For STO `5600084209` that tab is rendering these `EKBE` rows:

```
VGABE=8  BEWTP=L   9004953078   qty 1.000   14.08.2026
VGABE=8  BEWTP=L   9004953085   qty 2.000   17.08.2026
VGABE=8  BEWTP=L   9004953174   qty 1.000   21.08.2026   <-- created by our API call
```

Our delivery is there. The document flow was recorded correctly all along.

For STO `5600084239` — the one we posted a goods receipt against — the same tab shows the
complete chain:

```
VGABE=8  BEWTP=L   9004953151   qty 2.000                21.08.2026 06:36   delivery
VGABE=6  BEWTP=U   4918168363   BWART 641  qty 2.000     21.08.2026 06:38   goods issue
VGABE=1  BEWTP=E   5007138597   BWART 101  qty 2.000     25.08.2026 12:41   goods receipt (ours)
```

That is a stock transport order read end to end on one screen.

### Decoding the history columns

| `VGABE` | `BEWTP` | Meaning | Observed |
|---|---|---|---|
| 8 | L | Delivery note / outbound delivery | yes |
| 6 | U | Goods issue, stock transfer (`641`) | yes |
| 1 | E | Goods receipt (`101`) | yes |
| 2 | Q | Invoice receipt | not observed on these STOs |

### Also on ME23N

- **Item → Schedule lines** tab shows scheduled versus delivered quantity. This is `EKET`.
- **Item → Status** tab shows ordered / delivered / still to deliver.
- **Header → Status** gives the same at document level.

---

## 3. Verifying a delivery — VL03N

**`VL03N`** — Display Outbound Delivery. Enter `9004953174`.

- **Header → Processing** shows the overall goods movement status
- **Item Overview** shows material, quantity, plant
- The **Document Flow** button (`F7`, or Environment → Document Flow) shows the chain

For an STO delivery before goods issue, document flow is thin precisely because of the `VBFA`
point above. `ME23N` history is the better view until PGI has posted.

**Useful list transactions:**

| Tcode | Use |
|---|---|
| `VL06O` | Outbound delivery monitor — the general list, filter by shipping point, date, status |
| `VL06G` | Deliveries due for goods issue — the eligibility list for PGI |
| `VL06F` | General delivery list |

`VL06G` is the correct place to confirm a delivery is genuinely PGI-eligible before calling
`PostGoodsIssue`.

---

## 4. Verifying a material document — MB03 and MB51

**`MB03`** — Display Material Document. Enter document `5007138597`, year `2026`.

**`MB51`** — Material Document List. Far more useful for hunting: filter by material, plant,
movement type and date. To find every goods receipt against an STO, filter movement type `101`
and the plant.

**`MIGO`** itself, in display mode, shows the same document with the PO reference resolved.

**Stock views:**

| Tcode | Shows |
|---|---|
| `MMBE` | Stock overview — plant, storage location, stock type, in one screen |
| `MB52` | Warehouse stock list — batch-capable, good for reconciliation |
| `MB5T` | **Stock in transit** — the two-step STO view; this is what a `641` creates and a `101` consumes |

`MB5T` is the one to know for STO work. It answers "is this STO receivable yet" directly.

---

## 5. The table map

Use `SE16N` (or `SE16` / `SE11`) when you want the raw truth rather than a rendered screen.

### Purchase order / STO

| Table | Key fields | Notes |
|---|---|---|
| `EKKO` | `EBELN` | Header. `BSART` = doc type (`ZP06`). `LIFNR` is **blank** on an STO; `RESWK` holds the supplying plant |
| `EKPO` | `EBELN`, `EBELP` | Item. `PSTYP = 7` marks a stock transfer item. `WERKS` receiving plant, `LGORT` receiving storage location. `ELIKZ` = delivery complete, `LOEKZ` = deleted, `WEPOS` = GR expected |
| `EKET` | `EBELN`, `EBELP`, `ETENR` | Schedule lines. **`MENGE` scheduled vs `WEMNG` goods-received** — this is the open-quantity test |
| `EKBE` | `EBELN`, `EBELP`, `VGABE`, `BELNR` | Purchase order history. The STO document flow |

### Delivery

| Table | Key fields | Notes |
|---|---|---|
| `LIKP` | `VBELN` | Header. `LFART` delivery type (`ZNL` for STO), `VSTEL` shipping point, `WBSTK` goods movement status (`A` = not started, `C` = complete), `WADAT_IST` actual GI date |
| `LIPS` | `VBELN`, `POSNR` | Item. **`VGBEL` / `VGPOS` hold the predecessor PO and item.** `BWART` the movement type, `LFIMG` delivered quantity |

### Material document

| Table | Key fields | Notes |
|---|---|---|
| `MKPF` | `MBLNR`, `MJAHR` | Header. `BUDAT` posting date, `BLDAT` document date, `USNAM` user, `BKTXT` header text |
| `MSEG` | `MBLNR`, `MJAHR`, `ZEILE` | Item. `BWART`, `MATNR`, `WERKS`, `LGORT`, `MENGE`/`MEINS`, `EBELN`/`EBELP`, `SHKZG` (`S` debit / `H` credit), `DMBTR` value |

### Flow and config

| Table | Notes |
|---|---|
| `VBFA` | **SD flow only.** Sales order → delivery → material document → billing. Not the PO link |
| `MARV` | Current MM posting period per company code. `LFGJA`/`LFMON` current, `VMGJA`/`VMMON` previous, `XRUEM` backposting allowed |
| `T161` | Purchase order document types. `ZP06` has `BREFN = UBF`, i.e. a copy of `UB` |
| `T156` | Movement types |

---

## 6. Prove both API calls yourself, in about five minutes

**Create DI — delivery `9004953174`**

1. `ME23N` → PO `5600084209` → item 10 → **Purchase Order History**
   → expect a `VGABE=8 / BEWTP=L` row for `9004953174`, qty 1.000, 21.08.2026
2. `VL03N` → `9004953174` → confirm material, plant, quantity
3. `SE16N` → `LIPS`, `VBELN = 9004953174`
   → expect `VGBEL = 5600084209`, `VGPOS = 000010`, `BWART = 641`, `WBSTA = A`
4. `SE16N` → `VBFA`, `VBELN = 9004953174` → **expect zero rows, and that is correct**

**Submit MIGO — material document `5007138597`**

1. `MB03` → `5007138597` / `2026`
2. `ME23N` → PO `5600084239` → item 10 → **Purchase Order History**
   → expect `VGABE=1 / BEWTP=E`, movement `101`, qty 2.000, 25.08.2026, user `QNOVATE8`
3. `SE16N` → `EKET`, `EBELN = 5600084239` → expect `MENGE 2.000`, `WEMNG 2.000` (fully received)
4. `SE16N` → `MSEG`, `MBLNR = 5007138597` → expect `BWART 101`, `WERKS 1022`, `LGORT FKGU`,
   `EBELN/EBELP 5600084239/00010`

---

## 7. SE16 discipline — one trap that produces false findings

Selection-screen field IDs are **positional and vary per table**. `ctxtI4-LOW` is `BWART` on
`MSEG` but something else entirely on another table. Guessing produces a filter on the wrong
column and a confident, wrong answer.

Dump the field IDs first, then filter. And **always run a positive control** — a filter value
you know returns rows — before trusting a "no entries found".

`VBFA` has a further trap: its first selection field `RUUID` is **pre-filled with 32 zeros**.
Leave it and the query is silently constrained. Clear it explicitly.

---

## 8. One open item for MM

On STO `5600084239`, `EKBE` shows the goods issue valued and the goods receipt not:

```
VGABE=6  BEWTP=U  641  qty 2.000   value 10,867.50 INR
VGABE=1  BEWTP=E  101  qty 2.000   value 0.00
```

`MSEG-DMBTR` on the receipt is likewise `0.00`. For a stock transfer the receiving value
normally derives from the issuing plant's valuation, so a valued issue against an unvalued
receipt is asymmetric.

This is **not established** as either correct or wrong — it needs an MM answer before any
value field goes into an external API contract.
