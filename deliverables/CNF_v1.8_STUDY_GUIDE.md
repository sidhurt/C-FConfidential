# v1.8 Study Guide

**Companion to** `CNF_API_Request_Response_Specification_v1.8.xlsx`
**Purpose:** know every cell well enough to defend it in a meeting.
**Read order:** Part 1 (how it is built) → Part 2 (the defence model) → Part 3 (glossary) → Part 4 (sheet by sheet).

---

# PART 1 — How the workbook is built

## The one-sentence difference from v1.7

v1.7 answered *"what does the portal need to send and receive?"* and assumed a custom `ZCNF_*` service would be built to serve exactly that shape. v1.8 answers *"which released SAP service already does this, what does it actually accept, and who owns everything SAP will not do?"*

Same twelve APIs. Same numbers. Same business meaning. Nothing renumbered.

## Physical structure

13 sheets: an Overview plus one sheet per API, API-01 through API-12.

Each API sheet has **13 numbered sections**, always in this order:

| § | Section | What it answers |
|---|---|---|
| 1 | Business requirement | What the business needs. This is your v1.7 sheet, unchanged in meaning. |
| 2 | Actual service / route and protocol | Which real SAP service or client route does it |
| 3 | Operation / entity / action | The specific call |
| 4 | Request properties | What you send |
| 5 | Response properties | What comes back |
| 6 | SAP field / object mapping | The DDIC tables and fields underneath |
| 7 | Standard coverage | What SAP covers and what it does not |
| 8 | v1.7 fields absent from the standard contract | Everything v1.7 asked for that SAP does not provide, **with an owner** |
| 9 | Derivations and validations | What SAP works out itself; what it enforces |
| 10 | Genuine custom / orchestration gaps | Real gaps, **with named owners** |
| 11 | Activation / runtime status | Whether it is callable today (it is not) |
| 12 | Required tests | Positive and negative |
| 13 | Disposition | Classification and final verdict |

If you are asked something and don't know where to look: **§1 for what, §2 for which service, §8 for what's missing, §10 for who owns it, §13 for the verdict.**

## The five classifications

Say these in plain language, not jargon:

| Label | Say |
|---|---|
| `STANDARD-DIRECT` | "SAP already does this; we call it as-is." |
| `STANDARD + CPI/T2 ADAPTER` | "SAP does the document work; CPI wraps it for retry, correlation and error codes." |
| `EXISTING CLIENT ROUTE` | "This already exists in your landscape; we must trace it, not rebuild it." |
| `PROVEN CUSTOM GAP` | "Nothing standard covers this; a narrow build is justified." |
| `RUNTIME-UNPROVEN` | "Not yet called in a live system." — **this is on all twelve.** |

## The six SAP services that carry all twelve APIs

| Service | Serves |
|---|---|
| `API_MATERIAL_DOCUMENT_SRV` | API-01 |
| `API_OUTBOUND_DELIVERY_SRV;v=2` | API-02, API-03 (stages A/C), API-09, API-12 |
| `API_BILLING_DOCUMENT_SRV` | API-03 (stage E), API-10 |
| `API_PURCHASEORDER_PROCESS_SRV` | API-08, API-11 |
| `API_MATERIAL_STOCK_SRV` | API-05 |
| `SD_CUSTOMER_INVOICES_CREATE` | API-03 (stage D) — registered but application-internal |

Plus the **existing DigiGST/EY eDocument route** for API-06, API-07 and API-03 stage F. And **nothing at all** for API-04.

**Memorise this:** five services to activate covers nine of twelve APIs.

---

# PART 2 — The defence model (the most important page)

When someone challenges a single field, do not say "runtime-unproven." That word covers five separable claims and only one of them is actually unproven.

| Level | Claim | Status | Where it comes from |
|---|---|---|---|
| **1** | The property **exists** — name, EDM type, precision, scale, max length | **PROVEN** | Local SEGW extract, QS4/700 |
| **2** | The **DDIC field** behind it | **PROVEN** | `ABAP_FIELD` column in the same extract |
| **3** | Its **role** — key, creatable, updatable, nullable, filterable, sortable, unit reference | **PROVEN** | Flag columns in the same extract |
| **4** | The **business value** is correct — ZP06, ZNL, movement 101, ZSTO | **PROVEN** | Read-only QS4 table observation |
| **5** | **SAP accepts it in a live call** | **NOT PROVEN** | Requires Gateway activation |

**Your sentence, per field:**

> "The name and type are read from the local SEGW model in QS4. The DDIC field comes from the same extract. It's marked creatable/updatable there. The business value is observed on document X. What we haven't done is call it."

That is accurate, specific, and much stronger than a blanket caveat.

## Where the evidence physically lives

- **SEGW design-time extracts** — `sources/SRC-SYS-20260814-01_...` and `SRC-SYS-20260815-01..16`. Sixteen projects, pulled by GUI scripting from QS4 client 700 on 14–15 August. These are **local system extracts, not vendor documentation.** Each carries per property: EDM type, precision, scale, max length, `IS_KEY`, `CREATABLE`, `UPDATABLE`, `NULLABLE`, `FILTERABLE`, `SORTABLE`, `UNIT_PROPERTY`, `ABAP_FIELD`.
- **Business document evidence** — `sessions/2026-08-16-sto-flow-trace/evidence/`, 18 files with SHA-256 in `MANIFEST.tsv`. Read-only SE16/ME2W pulls: EKKO, EKPO, EKBE, LIKP, LIPS, VBFA, VBRK, VBRP, MSEG, T001K.
- **Nothing was posted.** No SAP document was created, changed or posted in any session.

## The sample-size caveat — say it before you are asked

Only **one** finding is population-scale: **22,378 ZP06 STO item rows** for supplying plant 1002. Everything else rests on **one or two documents** — `EKPO-BANFN` empty, `LIKP-LFART=ZNL`, the `P`+plant ship-to convention, the ZSTO billing type, the movement-101 reference model.

Each is a real system observation. None is a population proof. Where a single-document finding is load-bearing, the sheet leaves the item OPEN rather than settled.

---

# PART 3 — Glossary you must not fumble

## Tables

| Table | Is | Key fields you will be asked about |
|---|---|---|
| `EKKO` | Purchase order **header** | `EBELN` number, `BSART` doc type, `BUKRS` company code, `EKORG` purch. org, `EKGRP` purch. group, `RESWK` **supplying plant**, `LASTCHANGEDATETIME` |
| `EKPO` | Purchase order **item** | `EBELP`, `WERKS` **receiving plant**, `MATNR`, `MENGE`, `MEINS`, `PSTYP` item category, `BANFN` requisition, `BEDNR` requirement tracking, `LFRET` delivery type |
| `EKET` | PO **schedule line** | `EINDT` delivery date |
| `EKBE` | PO **history** | `VGABE` (1=GR, 6=GI, 8=delivery), `BWART` movement type, `BELNR` material doc |
| `LIKP` | Delivery **header** | `VBELN`, `LFART` **delivery type**, `VBTYP` category, `VSTEL` shipping point, `WERKS` receiving plant, `KUNNR` ship-to, `INCO1`, `VSART` shipping type, `ROUTE`, `WBSTK` GM status, `FKARV` billing type |
| `LIPS` | Delivery **item** | `POSNR`, `VGBEL`/`VGPOS`/`VGTYP` predecessor, `LFIMG` quantity, `CHARG` batch, `LGORT` storage loc, `UECHA` batch-split parent, `BWART` |
| `MKPF` | Material doc **header** | `MBLNR`, `MJAHR`, `BUDAT`, `VGART` |
| `MSEG` | Material doc **item** | `ZEILE`, `BWART`, `WERKS`, `LGORT`, `EBELN`/`EBELP` PO ref, `VBELN_IM`/`VBELP_IM` delivery ref, `LFBNR` inbound-delivery ref |
| `VBRK` | Billing **header** | `VBELN`, `FKART` billing type, `VBTYP`, `FKTYP`, `BUKRS`, `NETWR`, `MWSBK` tax, `RFBSK` accounting status |
| `VBRP` | Billing **item** | `VGBEL`/`VGTYP` delivery ref, `AUBEL`/`AUPOS` order ref, `FKIMG` quantity, `WERKS` |
| `VBFA` | **Document flow** | `VBELV` predecessor, `VBELN` successor, `VBTYP_N` successor category |
| `T001K` | Valuation area → company code | proves intra-company |

## Codes — memorise these six

| Code | Means | Where |
|---|---|---|
| **ZP06** | The client's STO purchase order type | `EKKO-BSART` |
| **ZNL** | The client's STO delivery type | `LIKP-LFART`, corroborated by `EKPO-LFRET` |
| **ZSTO** | The client's STO billing type | `VBRK-FKART` |
| **PSTYP 7** | Stock-transfer item category | `EKPO-PSTYP` |
| **641** | Goods issue to stock in transit | `LIPS-BWART` / `MSEG-BWART` |
| **101** | Goods receipt | `MSEG-BWART` |

## Document categories

`VBTYP` / `ReferenceSDDocumentCategory`: **C** = sales order · **J** = outbound delivery · **M** = invoice · **V** = purchase order · **8** = shipment · **R** / **i** = goods movement

## The observed STO chain — know these numbers

```
STO PO 5600000339  (ZP06, plant 1002 → 1010, Clinker)
  → delivery 0080019087  (ZNL)
      → shipment 2100005093            (VBTYP 8)
      → goods movements 4900180168 / 5000014663
      → billing 1100012896             (ZSTO, 105,625.00 INR + 29,575.00 tax)

Separately on the same PO:
   delivery 0080024605 → GR material doc 5000018851/2024, movement 101, plant 1010
```

The 2026 example: PO **5600084208** → delivery **9004953077** (ZNL, batch-split sub-items 900001/900002).

---

# PART 4 — Sheet by sheet

## Overview sheet

**Rows 1–3.** Title, a note that columns C/D/E/G are re-derived from the twelve sheets, and the v1.8 version statement. *If asked why the class column changed:* v1.7's S/C/X taxonomy is retired, replaced by the five classifications.

**Row 5.** Column headers: API ID · API Name · Operation · Method · Class · SAP standard service · Contract status.

**Rows 6–15.** API-01 to API-10, the manager-shared baseline.
**Rows 17–19.** API-11 and API-12, labelled candidates outside that baseline.

**What to know about the Method column:** it now reflects reality — GET for reads, POST for creates, PATCH for API-12, "n/a — no service" for API-04, "provider HTTP" for API-06/07. v1.7 said POST for everything because the old custom pattern POSTed reads (OData V2 GET cannot carry a compound key). That convention is gone.

**Rows 21–27.** Reading notes carried from v1.7.

**Rows 29+ — the v1.8 block.** In order: the version statement; what changed; the classifications; the honest headline; the zero-candidate finding for API-04/06/07; the evidence statement; system-validated codes; the observed chain; **the sample-size caveat**; **the explicit blockers**; **the five-level field evidence model**; **the blocker reclassification**; and the correct label for the workbook.

**The label — quote it verbatim if challenged:**
> Requirements discovery and standard-API solution mapping complete; local runtime certification and several contract details remain open.

---

## API-01 — Submit MIGO

**One line:** the receiving goods receipt for an STO, posted as a standard material document.

**Service:** `API_MATERIAL_DOCUMENT_SRV` · POST `A_MaterialDocumentHeader` with deep insert `to_MaterialDocumentItem` · movement **101**.

**The headline finding (§1).** The question that blocked this in v1.7 was: what does the GR reference? **Answer: the posted document persists BOTH** — `MSEG-EBELN`/`EBELP` (the STO purchase order) *and* `MSEG-VBELN_IM`/`VBELP_IM` (the outbound delivery). `LFBNR`, `LFBJA`, `LFPOS` are **blank**, so there is no inbound delivery — which **rejects** `API_INBOUND_DELIVERY_SRV;v=2 PostGoodsReceipt` for the STO path on evidence, not on absence.

**The distinction you must hold.** *Persistence* is proven — what the document retains after posting. That does **not** establish which fields the create **request** must supply. SAP may derive the delivery from the PO, the PO from the delivery, or require both. Only a DEV write settles it.

**Numbers:** material doc **5000018851/2024**, plant **1010**, storage location **RMYD**, `VGART=WE`. PO 5600000339 carries **203** goods receipts against **61** goods issues.

**§4 request rows.** `GoodsMovementCode` (**unconfirmed — this is a blocker**), `PostingDate`/`DocumentDate`, `GoodsMovementType` 101, `PurchaseOrder`/`PurchaseOrderItem`, `Delivery`/`DeliveryItem`, `Plant`, `StorageLocation`, `Material`, `QuantityInEntryUnit` + `EntryUnit`.

**§5 response.** `MaterialDocument` + `MaterialDocumentYear` — the authoritative key. The UI calls it an MRN number; confirm the label without changing the SAP key.

**§8 absent fields.** `RequestId`/`IsReplay` (no replay guard — CPI/T2); `ReceiptStatus`/`RemainingQuantity` (not in the create response — must come from a history read, **never fabricated**); `Errors[].AllocationIndex`; the DMG/STG rejection ledger.

**Likely question — "why 203 receipts?"** Partial and repeated receipt against one STO item is normal here. That is exactly the traceability concern raised on 14 August.

**Do not claim:** that we know the request field set.

---

## API-02 — Create DI

**One line:** create the outbound delivery from its predecessor.

**Service:** `API_OUTBOUND_DELIVERY_SRV;v=2` (SEGW project `API_OUTBOUND_DELIVERY_0002`).

**Scope — get this right.** **All three flows — Trade, Non-trade and STO — are confirmed business scope** and all three use this service. What v1.8 proves at field level is the **STO route only**; the Trade/Non-trade sales-order variant has not been traced in QS4. **That is an evidence gap, not a descope.** If you say Trade/Non-trade is "out of scope" you will be wrong.

**Why v=2 and not the base version.** The client's STO delivery is **batch-split** — sub-items 900001/900002 under `UECHA=000010`. `HigherLvlItmOfBatSpltItm` and `CreateBatchSplitItem` exist **only** in `_0002`. If Basis provisions the base version this breaks.

**The STO discriminator:** `ReferenceSDDocumentCategory = V`. Trade/Non-trade would be `C`.

**§4 request — deliberately tiny.** Predecessor (`ReferenceSDDocument`/`Item`/`Category`) plus `ActualDeliveryQuantity`. That's it. Everything else is derived.

**§5 response — what SAP derives.** Delivery **9004953077**; `LFART=ZNL`; `VBTYP=J`; shipping point 1002; receiving plant 5412; ship-to `P5412`; `INCO1=FTB`; `VSART=01`; route P27356; `FKARV=ZSTO`; movement 641.

**Batch split — never sum items.** Main item 000010 carries 10.000 TO. Sub-items 900001 (5.000 TO, batch 2623029112, SLoc PC88) and 900002 (5.000 TO, batch 2630004639, SLoc SELF) sit under it.

**§10 open items.** Two transactions created STO deliveries — **VL10X** (2026) and custom **ZLE020** (2024); neither is VL01N and which is authoritative is undefined. `LIKP-ZZEBELN` holds PO 5600073817 which does **not** match `VGBEL` 5600084208 — meaning unknown, must not be used as the predecessor key.

**Rejected alternatives** — say these if asked why not use what's already registered: `LE_SHP_OD_CREATE_SRV` is a collective due-list worklist with no quantity and no STO predecessor; `LE_SHP_QC_DLVREF_SRV` handles only a narrow sales-order header case.

---

## API-03 — Create Invoice / Billing Documents

**One line:** the portal shows one button; SAP has no single API behind it.

**Lead with:** "This is a **six-stage composition, A to F**, and each stage commits separately."

| Stage | Route | Status |
|---|---|---|
| A Picking / batch split | `API_OUTBOUND_DELIVERY_SRV;v=2` | released, not activated |
| B Shipment, shipment cost **and cost release** | client freight route — **unidentified** | see API-04 |
| C PGI | `PostGoodsIssue` | released, not activated |
| D Billing create | `SD_CUSTOMER_INVOICES_CREATE` | registered but **application-internal** |
| E Billing read-back | `API_BILLING_DOCUMENT_SRV` | released, not activated |
| F e-Invoice / E-Way Bill | DigiGST/EY route | footprint observed, operation not evidenced |

**The operation signatures (verified in the local extract):**
- `PickOneItemWithBaseQuantity` takes exactly four parameters — `ActualDeliveredQtyInBaseUnit` (Edm.Decimal 13,3, unit reference `BaseUnit`), `BaseUnit` (Edm.String 3), `DeliveryDocument` (10), `DeliveryDocumentItem` (6).
- `PickAndBatchSplitOneItem` takes a **different** signature — `Batch`, `DeliveryDocument`, `DeliveryDocumentItem`, `SplitQuantity`. **This is the one your batch-split flow needs.**

*If asked how we know:* read from the QS4 SEGW extract `SRC-SYS-20260814-01`, not from documentation.

**The point stakeholders must absorb.** If stage D fails after stage C committed, **SAP will not roll back the PGI**. No SAP object holds cross-stage process state. `ProcessId`, `ProcessStatus` and `Stages[]` from v1.7 have no SAP home — CPI/T2 owns them.

**Use their own system as proof.** `ZMM_SCRUM_SER_PO` already runs three documents behind one OData call — and has no compensating rollback, and commits its final stage without checking the previous result. It proves the pattern is achievable *and* why the estimate is what it is.

**Stage E caveat.** The V2 billing service has **no creatable entity set** — read/cancel/PDF only. Creation exists only on the OData V4 successor. That is why stage D is a separate, conditional service.

**Ordering.** The 14 August sequence is DI → shipment → shipment cost → **cost release** → PGI → invoice. PGI must precede billing. Whether cost release is a hard SAP precondition or a business rule is **not established**.

---

## API-04 — Shipment Calculation

**One line:** a genuine discovery result, not an unfinished sheet.

**Say it in this order:**
1. **Zero candidates.** API-04 returned no credible service across the full 2,626-project SEGW catalogue screen. That absence *is* the evidence.
2. **`BAPI_SHIPMENT_COST_ESTIMATE`** — existence and suitability in this system are **unverified**. Not located, not inspected, not executed.
3. **An existing client freight route must still be identified** — freight *is* being priced today. Deliveries carry route, transport group, shipping condition and transporter pricing (`KALSP=ZLE001`, `KNUMP` populated).

Only if both come back empty is a narrow custom ABAP endpoint justified. **Do not let this be minuted as "ABAP will build it."**

**Classification:** `PROVEN STANDARD-ODATA DISCOVERY GAP` — deliberately *not* `PROVEN CUSTOM GAP`, which would require both routes disproven.

**Design constraint if built:** it is a *read*. It must not post a shipment-cost document, and a missing rate must return a controlled no-rate result, not an exception.

---

## API-05 — Stock Availability

**One line:** the cleanest sheet in the workbook.

**Service:** `API_MATERIAL_STOCK_SRV` · `GET A_MatlStkInAcctMod` · grain **material × plant × storage location**, with batch and stock type where exposed.

**Scope limits — say them unprompted:** this is **book stock**. Not ATP. Not stock ageing. Not the DI-context batch determination that belongs to API-03.

**Plant is mandatory.** Material and storage location are optional filters.

**Rejected:** `API_PRODUCT_AVAILY_INFO_BASIC` — plant-level ATP, one material per call, no storage-location parameter. A different business question.

**Not SAP's job (§8):** material and storage-location descriptions (Commerce/T1 master data); `StockAgeingDays` (stays on the existing ZMM5013 → Datasphere D-1 feed); paging, caching, refresh throttling and portal aggregation (CPI/T2 and Commerce).

**The one functional decision:** which `InventoryStockType` values count as "system stock". Getting this wrong silently returns the wrong number — the exact semantic failure mode this programme has guarded against since July.

**Acceptance test:** a filtered read must reconcile to MMBE/MB52 for the same material, plant and storage location.

---

## API-06 — E-Way Bill Extension

**One line:** we did not invent a standard API, because there isn't one.

**Zero candidates** in the catalogue screen. What exists is the SAP **eDocument framework** plus the third-party **`/DIGIGST/`** add-on, with roughly 50 `EY_*` HTTP destinations including extension operations.

**Language discipline — this matters.** Say **"installed and configured route footprint observed."** Do **not** say "the route is live." We have seen objects and destinations; we have captured **no** runtime request or response.

**Known:** `/DIGIGST/OWARD_H-EWBNUMBER` holds the E-Way Bill number. `BADI_EDOCUMENT_IN_EWB` exists — but **a BAdI is an enhancement point, not a callable command.** Don't let anyone specify it as the API.

**Business policy, confirmed and firm:** eligible only in the final **eight hours** before expiry; a successful extension adds exactly **24 hours**; the caller never sends a duration. The new validity must come back from the provider — never computed locally.

**Distinction to hold:** `/DIGIGST/` is a third-party add-on, **not** SAP Document Compliance (DRC). An earlier project assumption that DRC was the statutory framework was wrong and has been removed.

**Flag:** a replayed extension is a duplicate **statutory** submission. Replay protection matters more here than anywhere else.

---

## API-07 — Invoice Correction

**One line:** corrects only the transport details on an existing invoice.

**Not:** a billing cancellation, a price or quantity correction, or a re-issue.

**The validated delta only:** Part A transporter name / ID / distance; Part B transport mode / vehicle type / vehicle number. At least one must be supplied.

**We dropped `ReasonCode` and `Remarks`** from v1.7 — not in the validated design. Retain only if statutory processing proves them mandatory.

**Report the two statutory outcomes separately.** e-Invoice and E-Way Bill states are independent; one can succeed while the other fails. That is the PARTIAL case, and collapsing them hides a real failure mode.

**Explicitly forbidden:** direct updates to `VBRK`, `EDOCUMENT` or `/DIGIGST/*`. There is no justified `BAPI_BILLINGDOC_*` for this.

**Unresolved:** whether "Update Details" cancels and regenerates either statutory document — must be established before build. The UI's "Document Number" has no confirmed SAP meaning (`XBLNR` is a candidate).

---

## API-08 — STO Orders

**One line:** with API-05, the cleanest read.

**Service:** `API_PURCHASEORDER_PROCESS_SRV` · `GET A_PurchaseOrder` with `$expand=to_PurchaseOrderItem`.

**ZP06 is system-validated** — not documented, *validated*. ME2W for supplying plant 1002 returned **22,378** STO item rows. Pair with `PSTYP=7` for the approved filter.

**Delta works properly here:** `EKKO-LASTCHANGEDATETIME` is a genuine timestamp and is populated. Contrast with API-09.

**Rejected:** `MMIM_STO_SRV` — no document type, no org fields, no status, no watermark, no paging.

**The one gap:** v1.7 wants a normalized CHAR(12) `DocumentStatus`. SAP offers processing/completeness status plus delivered/invoiced quantities (`MGLIEF`/`MGINV` in ME2W). **The normalization rule does not exist yet** — functional defines it, CPI/T2 implements it.

**Coverage line:** 13 of 14 v1.7 output groups map directly.

---

## API-09 — STO Deliveries

**One line:** same service as API-02, different operation — and two real gaps.

**The discriminator — this changed, know why.** Leading is **`DeliveryDocumentType = ZNL`** (header-level, single-query filterable, corroborated by `EKPO-LFRET=ZNL`). `ReferenceSDDocumentCategory = V` is **supporting only**, because V proves a *purchase-order* predecessor, not an *STO* one — subcontracting, returns-to-vendor and third-party deliveries would also match.

*If asked why it changed:* an earlier draft used V alone as "resolved". That was a real logical gap, caught in review.

**Still open:** ZNL is confirmed on **two documents**, not on the population.

**Gap 1 — PgiMaterialDocument.** Not a property of the delivery header or item entity. You cannot get it from a list read. Needs document-flow enrichment per document, a replicated read model, or a CPI/T2 join. Reachable via EKBE (`VGABE=6`, doc 4918168243/2026) and VBFA.

**Gap 2 — delta grain.** `LIKP` carries timestamps internally, but the OData header exposes `LastChangeDate` as a **DATE only** — unlike API-08 and API-10 which both have true timestamps. **Sub-day delta cannot be expressed.** Against an architecture calling this feed real-time, that is a design constraint stakeholders must hear.

**Also:** the PGI timestamp must be composed from two fields — `WADAT_IST` + `SPE_WAUHR_IST`.

---

## API-10 — STO Invoice

**One line:** v1.7's hard gate is resolved.

**The question was:** SD billing, intercompany billing, or MM supplier invoice? **Answer: SD billing.**

**Evidence — a real document.** VBRK **1100012896**: `FKART=ZSTO`, `VBTYP=M`, `FKTYP=L` (delivery-related), `RFBSK=C` (accounting posted), net **105,625.00 INR** plus **29,575.00** tax, external ref `RJ2302001400`.

**Intercompany ruled out:** T001K shows both valuation areas map to company code **1000**. This is an intra-company transfer that still produces a taxed India GST stock-transfer invoice.
**MM invoice ruled out:** ME2W shows nothing invoiced on the MM side.

**The correction to own.** An earlier draft said the STO purchase order needed a two-hop join through the delivery. **That was wrong.** `VBRP` carries both directly — `VGBEL` (delivery) and `AUBEL` (the STO PO). Single hop.

**Why it stays CONDITIONAL:** the property exposing `AUBEL` is named `SalesDocument` in the OData model but holds a *purchase* order on this flow. Semantically odd, load-bearing, and unverified. **This is expected to be answerable from the billing extract's `ABAP_FIELD` column — no call needed.**

---

## API-11 — Create STO Purchase Order

**One line:** standard create — and it caught two errors in the v1.7 contract.

**Service:** `API_PURCHASEORDER_PROCESS_SRV` · POST deep insert across header, item and schedule line.

**Contract error 1 — `ShippingType`.** v1.7 sends it as a mandatory PO input. **No shipping-type field is populated on EKKO or EKPO.** It lives on the delivery (`LIKP-VSART=01`). Move it to API-02, derive it, or drop it.

**Contract error 2 — `RequisitionNumber`. Now deliberately OPEN.** Two candidates with **different semantics**:
- `A_PurchaseOrderItem.PurchaseRequisition` → `EKPO-BANFN` — what the service exposes and v1.7 maps to. **Empty** on the observed document.
- `RequirementTracking` → `EKPO-BEDNR` — **populated** with 2352.

Evidence is **one purchase order**. That is not enough to settle which the business means, or whether other ZP06 POs carry requisitions. **Do not implement either.** Both are marked do-not-implement on the sheet.

*This is the clearest demonstration of what the evidence pass bought.* Use it if anyone asks whether the exercise was worth the time.

**Also:** `CompanyCode` should be **derived from plant**, not trusted from the caller. Caller-supplied org data is how you get a technically successful posting that means the wrong thing.

**Duplicates:** the standard create has no replay guard. Same payload twice creates two POs.

---

## API-12 — Update DI Quantity

**One line:** deliberately narrow — quantity only, on an open delivery, before batch determination.

**Service:** `API_OUTBOUND_DELIVERY_SRV;v=2` · `PATCH A_OutbDeliveryItem` with `If-Match`.

**Two different limits — do not conflate them.** The **requirement** limit is *before batch determination*. The **system** limit is `WBSTK=C` (goods movement complete). Pre-PGI is a **wider** window than pre-batch-determination, and a delivery can be batch-determined but not yet PGI'd — which is exactly the case the reset rule governs.

**Open — targeting.** Quantity sits on the batch-split **sub-items** (900001/900002), not on main item 000010. v1.7 doesn't say which level the portal targets. The test must run at both levels and record which SAP accepts.

**Expected to be extract-answerable:** `A_OutbDeliveryItemType.ActualDeliveryQuantity` is marked **UPDATABLE** in the extract — so "which property is writable" probably does not need a call.

**Editable window is real:** delivery 9004953077 changed between creation (`CREATION_TS 20260813110819`) and PGI (`CHANGED_TS 20260813111901`).

---

# PART 5 — The three questions you will get

**"Are these ready to build?"**
> "The SAP document behaviour is evidenced and the service selection is defensible. None is proven reachable — no service is activated and no OData call has been made. Next gate is Basis activating five services, then `$metadata` and safe reads."

**"Why is API-03 not one API?"**
> "Because SAP commits those documents separately and will not roll them back together. We can present one button; the recovery and partial-completion logic has to live in CPI/T2. Specifying it as one atomic SAP call would specify something that cannot exist."

**"What did we gain over v1.7?"**
> "Two contract errors caught before build on API-11 alone. The STO-invoice object question closed with a real document. The GR reference model closed. And every field v1.7 assumed SAP would provide now has an owner instead of being discovered in integration testing."

## The three-tier unblocking story

- **Tier 1 — `$metadata` on five services.** No data, no writes, no risk. Settles API-10's `SalesDocument`→`AUBEL`, API-09's filterability, API-12's writable property.
- **Tier 2 — safe reads.** Settles API-05 reconciliation, API-08 delta and paging, API-09 population.
- **Tier 3 — authorised DEV writes.** Only these settle API-01's request fields, API-11's requisition mapping, API-12's cutoff, API-03's stage chain.

**The line:** *"Nine of twelve are blocked on one activation request. Three blockers clear on metadata alone — no data touched."*

## What never to say

Do not call anything **activated**, **callable**, **live**, or **implementation-ready**. Say **specified**, **evidenced**, **conditional on activation**. That distinction is the whole credibility of the document.
