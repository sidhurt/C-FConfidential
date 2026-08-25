# The client's own STO payload — extracted from `ZMM_STO_AUTO_POSTING`

**Source: their custom report `ZMM_STO_AUTO_POSTING`, 955 lines, read from DS4 on 2026-08-20
via `RPY_PROGRAM_READ`.**

This is not our reconstruction. It is the working code they already run, and it does the whole
order-fulfilment chain in one program.

---

## 1. CORRECTION — we had one field wrong

**We said:** put the supplying plant in `SUPPL_PLNT` and leave `VENDOR` empty.

**Their code does the opposite:**

```abap
GS_HEADER-VENDOR  = WA_PR-RESWK.
GS_HEADERX-VENDOR = 'X'.
```

`SUPPL_PLNT` appears **zero times** in all 955 lines. They put the supplying plant into the
**`VENDOR`** field.

Both fields exist in `BAPIMEPOHEADER` — confirmed in the structure editor. For stock-transport
document types SAP maps `VENDOR` onto `EKKO-RESWK`, which is why `EKKO-LIFNR` is blank on all
15 of their live ZP06 orders even though the BAPI call populates `VENDOR`.

**Supporting test (DS4, `TESTRUN = X`):** `DOC_TYPE = UB` with `VENDOR = PLQ3` and no
`SUPPL_PLNT` returned:

```
I  MMPUR_BASE 054   Function "Create Purchase Order" Performed
E  MEPO 002         PO header data still faulty
E  ME 083           Enter Purchasing Org.
W  ME 658           Please also populate interface parameter PO
```

**No `ME 013`** (document type accepted) and **no vendor-not-found error**, despite `LFA1`
being completely empty in DS4. If `VENDOR` were being validated as a real vendor master
record, an empty `LFA1` would have produced one. It stopped on a missing purchasing org, which
is a header-completeness check.

**Use `VENDOR`. It is what they run in production.**

---

## 2. `BAPI_PO_CREATE1` — the exact payload

### POHEADER

| Field | Their value | Source |
|---|---|---|
| `COMP_CODE` | derived | `SELECT SINGLE BUKRS FROM T001K WHERE BWKEY = <plant>` |
| `DOC_TYPE` | `ZP06` | hardcoded |
| `VENDOR` | supplying plant | `EBAN-RESWK` from the purchase requisition |
| `PURCH_ORG` | `1000` | hardcoded |
| `PUR_GROUP` | `119` | hardcoded |

> Note: `PUR_GROUP = 119`, not `801`. Both appear on their live orders; the auto-posting
> report always uses `119`.

### POHEADERX

`X` on exactly those five: `COMP_CODE`, `DOC_TYPE`, `VENDOR`, `PURCH_ORG`, `PUR_GROUP`.

### POITEM

| Field | Their value |
|---|---|
| `PO_ITEM` | `SY-TABIX * 10` — 00010, 00020, … |
| `MATERIAL` | requisition material, `ALPHA = IN` converted |
| `PLANT` | receiving plant |
| `STGE_LOC` | storage location — **mandatory in their validation** |
| `TRACKINGNO` | `EBAN-BEDNR` |
| `QUANTITY` | requisition quantity |
| `PO_UNIT` | requisition UoM |
| `ITEM_CAT` | `EBAN-PSTYP` — taken from the requisition, not hardcoded |
| `PREQ_NO` | `EBAN-BANFN` |
| `PREQ_ITEM` | `EBAN-BNFPO` |
| `VAL_TYPE` | `EBAN-BWTAR` |

### POITEMX

`X` on: `PO_ITEMX`, `MATERIAL`, `PLANT`, `STGE_LOC`, `TRACKINGNO`, `QUANTITY`, `PO_UNIT`,
`ITEM_CAT`, `PREQ_NO`, `PREQ_ITEM` — plus `PO_ITEM` carrying the item number itself.

> `VAL_TYPE` is set in `POITEM` but **has no `X` flag**. On the X-structure rule that means
> SAP ignores it. Either a bug in their code or valuation type is derived anyway — worth
> raising with them, quietly.

### POSCHEDULE / POSCHEDULEX

```abap
PO_ITEM        = <item number>
DELIVERY_DATE  = SY-DATUM          " today
```
X-structure: `PO_ITEM` + `DELIVERY_DATE = 'X'`.

### Their input is a purchase requisition

The whole report is driven from `EBAN`. Fields consumed: `BANFN`, `BNFPO`, `MATNR`, `WERKS`,
`RESWK`, `LGORT`, `MENGE`, `MEINS`, `PSTYP`, `BEDNR`, `BWTAR`.

**This answers the open v1.8 question about `RequisitionNumber`** — it was recorded as
undecided between `BANFN` and `BEDNR`. Their code uses **both**, for different things:

- `EBAN-BANFN` → `POITEM-PREQ_NO` (the requisition number)
- `EBAN-BEDNR` → `POITEM-TRACKINGNO` (the tracking number)

Not either/or. Both, in separate fields.

---

## 3. Their commit pattern — the same rule we derived

```abap
IF GV_PO_NUMBER IS NOT INITIAL.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' EXPORTING WAIT = 'X'.
  WAIT UP TO 3 SECONDS.
ELSE.
  CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
ENDIF.
```

They commit **only if a document number came back**, and roll back otherwise. Same pattern
after every stage in the report.

This is independent confirmation of the commit contract we specified from our own testing —
including `WAIT = 'X'`. Their `WAIT UP TO 3 SECONDS` afterwards suggests they hit timing
issues with the next stage reading a document the update task had not finished writing.
**Worth designing for.**

---

## 4. The report does the whole chain

| Stage | Function module | Line |
|---|---|---|
| Create STO | `BAPI_PO_CREATE1` | 557 |
| Create delivery | `BAPI_OUTB_DELIVERY_CREATE_STO` | 619 |
| Change delivery | `BAPI_OUTB_DELIVERY_CHANGE` | 707 |
| Goods issue | `WS_DELIVERY_UPDATE` | 747 |
| Create invoice | `BAPI_BILLINGDOC_CREATEMULTIPLE` | 800 |

Every one followed by commit-or-rollback.

### Create delivery — `BAPI_OUTB_DELIVERY_CREATE_STO`

```abap
SHIP_POINT = EKKO-RESWK        " the supplying plant, used as shipping point
DUE_DATE   = EKET-EINDT

STOCK_TRANS_ITEMS:
  REF_DOC    = EKPO-EBELN
  REF_ITEM   = EKPO-EBELP
  DLV_QTY    = EKPO-MENGE
  SALES_UNIT = EKPO-MEINS
```

**They create STO deliveries through a BAPI, not the OData service.** Both routes exist — we
proved the OData deep insert reaches real delivery logic — but this one is proven in their
production.

---

## 5. What this changes

| | Before | Now |
|---|---|---|
| Supplying plant field | `SUPPL_PLNT` | **`VENDOR`** |
| `PUR_GROUP` | 801 | **119** in the auto-posting path |
| `PURCH_ORG` | 0001 | **1000** |
| `ITEM_CAT` | hardcoded 7 | taken from `EBAN-PSTYP` |
| `RequisitionNumber` | open question | **resolved** — `BANFN` and `BEDNR` both, in different fields |
| `STGE_LOC` | not mentioned | **their code treats it as mandatory** |
| Delivery creation | OData deep insert | they use `BAPI_OUTB_DELIVERY_CREATE_STO` |
| Commit pattern | our specification | **independently confirmed by their code** |

---

## 6. Why this matters for the build

The custom service should wrap **this** payload, not our reconstruction. Every field value
here is what their business actually runs, and the report is a working reference implementation
of the full chain including the commit boundaries.

Two things to raise with them:

1. **`VAL_TYPE` is set without its X flag** — silently ignored under the X-structure rule.
2. **`WAIT UP TO 3 SECONDS` after each commit** — a hard-coded sleep suggests they hit update-task
   timing problems. Our service should handle that deliberately rather than by sleeping.

---

**Raw source:** `sessions/2026-08-18-runtime-certification/sto/ZMM_STO_AUTO_POSTING_src.txt`
