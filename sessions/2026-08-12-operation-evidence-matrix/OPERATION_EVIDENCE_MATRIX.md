# Operation Evidence Matrix

**Date:** 2026-08-12 · **Status:** working evidence record, not approved scope
**Method:** evidence-constrained contract development. Records what the evidence proves, isolates what it merely suggests.

## Sources used

| Tier | Source | Weight here |
|---|---|---|
| 1 | Latest explicit team clarification — *"Every operation from PGI through GR requires an API"*; *"S4 is the runtime"* | Governs |
| 2 | Formal manager/team interface register — `D-047` seven T2→S/4 rows; `D-048` feed separation | Baseline scope |
| 3 | BRD `SCL-OMCC-BRD-01` v3.0, **status Client Review**, issued 10/08/2026, author Sujal Somay | Strong working evidence, not approved technical spec |
| 4 | Validated production Figma — `SRC-FIG-20260811-02`..`13` | Product behaviour |
| 5 | SAP system/code evidence — `D-023`, `D-033`, `D-035`, `D-038` | Implementation reality |
| 6 | Workbook inference / architectural recommendation | Never overrides the above |

Every BRD citation below is a specific `FR-*` requirement ID, so any cell can be checked without re-reading the document.

---

## 1. Operation matrix

Legend — **Formal**: appears in the seven-row register. **Derived**: operation the BRD/Figma requires but the formal register does not name. **Gap**: required capability with no contract anywhere.

### Inbound / receipt

| Operation | Formal parent row | BRD evidence | Figma | Team confirmation | Caller | Provisional service | Status |
|---|---|---|---|---|---|---|---|
| Check MIGO / Pending Receipt | *none* | `FR-MIG-05,06,07,08,09,10` | `SRC-FIG-…-08` | S/4 is runtime | Unconfirmed | RECEIPT | **Derived** — source question closed by Tier-1; contract retained as API-01 |
| Post Goods Receipt | SubmitMigo | `FR-MIG-19,20,21` | `SRC-FIG-…-08` | Yes | T2 | RECEIPT | **Formal** |
| Get GR / receipt status refresh | SubmitMigo | `FR-MIG-22,24` | Yes | Implied | Unconfirmed | RECEIPT | **Derived** — may be a re-read of Check MIGO rather than its own endpoint |
| Get valid storage locations (inbound) | *none* | `FR-MIG-13` — *all* configured locations for the warehouse | Yes | Not addressed | Unconfirmed | RECEIPT | **Source unresolved** — do not restore a standalone SAP API from inference |
| Reverse Goods Receipt | *none* | **No BRD requirement found** | None | Not addressed | — | — | **Unsupported** — architectural speculation only; exclude from scope and estimate |

### Outbound / fulfilment

| Operation | Formal parent row | BRD evidence | Figma | Team confirmation | Caller | Provisional service | Status |
|---|---|---|---|---|---|---|---|
| Create DI | CreateDI | `FR-DI-18,19,20`; STO variant `FR-IWM-20,22` | `SRC-FIG-…-02,10` | Yes | Unconfirmed | DELIVERY | **Formal** |
| Modify DI quantity | *none* | `FR-INV-11,12,13,14` — FR-INV-14 says *"upon successful update of the DI Quantity **in SAP**"*; STO variant `FR-IWM-27..30` | Yes | Yes | Unconfirmed | DELIVERY | **Derived, SAP-bound** — BRD language places the update in SAP |
| Get eligible storage locations (outbound) | *none* | `FR-INV-15`, `FR-IWM-31` — *eligible* subset, distinct from `FR-MIG-13` | Yes | Not addressed | Unconfirmed | — | **Source unresolved** |
| Batch determination (FIFO) | *none* | `FR-INV-16,17`; `FR-IWM-32,33` | Yes | Not addressed | Unconfirmed | — | **Ownership unresolved** — see §2.1; user cannot modify the allocation |
| SPI selection | *none* | `FR-INV-18` (default `SP01`); `FR-IWM-34` (default `SPI01`) | Yes | Not addressed | Unconfirmed | — | **Derived** — code conflict, see §3 |
| Validate transporter | *none* | `FR-IWM-36,37` — code entry returns transporter details or blocks | Yes | Not addressed | Unconfirmed | DISPATCH | **Gap** — no contract in the workbook |
| Calculate shipment cost | Shipment Calculation | `FR-INV-21,22`; `FR-IWM-39,40` | Yes | Yes | Unconfirmed | DISPATCH | **Formal** |
| Create Shipment | CreateInvoice | `FR-INV-33(2)`; `FR-IWM-46` | Yes | Yes | Unconfirmed | DISPATCH | **Derived** — needs its own contract |
| Post Goods Issue | CreateInvoice | `FR-INV-33(1)`; `FR-IWM-46` | Yes | Yes | Unconfirmed | DISPATCH | **Derived** — needs its own contract |
| Create Invoice | CreateInvoice | `FR-INV-30,31,33(3)` | Yes | Yes | Unconfirmed | DISPATCH | **Formal** |
| Generate E-Way Bill | CreateInvoice | `FR-INV-33(4)`; `FR-IWM-46` | Yes | Yes | Unconfirmed | EDOC | **Derived** — needs its own contract |
| Generate E-Invoice | *possibly* CreateInvoice | **Absent from `FR-INV-33`**; appears only in `FR-DF-05`, `FR-DOC-03`, `FR-IWM-46` | Yes | Yes | Unconfirmed | EDOC | **Weakest evidence in this table** — the BRD's own submission list omits it |
| Get Document Flow | *none* | `FR-DF-03,05,06` | `SRC-FIG-…-04,12` | S/4 is runtime | Unconfirmed | — | **Derived** — source question closed by Tier-1 |
| Check document availability / download | *none* | `FR-DOC-09,10` — *"verify whether … generated in SAP"* | Yes | Not addressed | Unconfirmed | EDOC | **Gap** — no contract in the workbook |
| Correct Invoice | Invoice Correction | `FR-IDC-10,11,12` | `SRC-FIG-…-07` | Yes | Unconfirmed | EDOC | **Formal** — editable set contradicts workbook, see §2.2 |
| Extend E-Way Bill | E-Way Bill Extension | `FR-EWB-11,12,13,15,17,18` | `SRC-FIG-…-13` | Yes | Unconfirmed | EDOC | **Formal** — request fields contradict workbook, see §2.3 |

### STO / intra-warehouse

| Operation | Formal parent row | BRD evidence | Figma | Team confirmation | Caller | Provisional service | Status |
|---|---|---|---|---|---|---|---|
| Create STO Purchase Order | *none* | `FR-IWM-09,10,11,12,13,14,15,16` — full field list, validation, success response, list refresh | `SRC-FIG-…-09` | Not addressed | Unconfirmed | provisional | **Strongly supported operation, unresolved service boundary** |
| Get STO PO list / status | *none* | `FR-IWM-04,05,06,07,08` | `SRC-FIG-…-09` | Not addressed | Unconfirmed | provisional | **Derived** — may be the `D-048` S/4→T2 feed rather than a call |
| Destination-side GR | SubmitMigo | §4.5 intro; `FR-IWM-46` lists GR as a tracked document | `SRC-FIG-…-12` | Yes | T2 | RECEIPT | **Formal, separate LUW** — see §4 |

### Inventory

| Operation | Formal parent row | BRD evidence | Figma | Team confirmation | Caller | Provisional service | Status |
|---|---|---|---|---|---|---|---|
| Get stock availability | Stock Availability | `FR-PIR-09,10` — non-zero storage locations for the selected SKU | `SRC-FIG-…-05` | Yes | Unconfirmed | STOCK | **Formal** |
| Post physical inventory reconciliation | *none* | `FR-PIR-06,17,18,21,22` — submit variance + mandatory reason, posting date recorded | `SRC-FIG-…-05` | Not addressed | Unconfirmed | STOCK | **Gap** — see §2.4 |
| Get stock ageing | *none* | Not in §4.6 | Dashboard | Not addressed | Unconfirmed | STOCK | **Derived** — `D-014`/`D-048` place ageing on DSP→T2 batch; conflicts with Tier-1 runtime statement |

---

## 2. Where the BRD contradicts the current workbook

Tier 3 outranks Tier 6, so these are workbook corrections pending, not BRD questions.

### 2.1 Batch allocation is not a caller input

`FR-INV-17` and `FR-IWM-33`: *"Users shall **not** be permitted to modify system recommended allocated quantities across available batches."*

The v1.7 API-06 sheet sends `BatchAllocations[].Batch` and `BatchAllocations[].Quantity` as **mandatory caller inputs**. If the user cannot alter the proposal, the portal is echoing back SAP's own determination — which invites drift between proposal and posting. The caller contract should plausibly send storage location + SPI and let SAP determine, or send the allocation purely as an assertion for mismatch rejection. `FR-IWM-35` adds that progress is blocked until allocated quantity exactly equals DI quantity.

**Unresolved:** whether batch determination is a separate read endpoint, part of stock availability, or logic executed inside PGI. Do not create an endpoint for architectural tidiness.

### 2.2 API-07 allows editing fields the BRD marks non-editable

`FR-IDC-10` fixes the editable set precisely:

| Field | BRD | v1.7 API-07 sheet |
|---|---|---|
| Part A Distance | **Editable** | present |
| Part A Transporter Name | **Non-editable, auto-populated** | present as a request field |
| Part A Transporter ID | **Non-editable, auto-populated** | present as a request field |
| Part B Transport Mode | **Non-editable, auto-populated** | present as a request field |
| Part B Vehicle Type | **Editable** | present |
| Part B Vehicle Number | **Editable** | present |

Three request fields the BRD says the user cannot change. Either the sheet is wider than the requirement, or the BRD is narrower than reality — an owner decides, not us.

### 2.3 API-08 carries request fields that appear on no screen

`FR-EWB-15` lists the entire extension form: Transport Mode (non-editable), Vehicle Number (editable), From Place, From State, Pincode, Extension Reason Code, Extension Remarks.

`RemainingDistance` and `TransitType` are **mandatory caller fields** on the v1.7 sheet and appear nowhere in the BRD form. They are provider-payload obligations, so they must be derived by SAP/GSP rather than demanded from the portal — unless an owner states otherwise.

Everything else on that sheet now has direct BRD confirmation: eligibility opens 8 hours before expiry (`FR-EWB-11`), is refused after expiry (`FR-EWB-13`, no after-expiry window), the action is labelled *Extend E-Way Bill for 24 Hours* (`FR-EWB-18`), remarks cap at 200 characters (`FR-EWB-17`).

### 2.4 Physical inventory posting has no contract

Removing API-12 removed a duplicate **read**. `FR-PIR-06,17,18,21,22` prove a **write** exists: post a reconciliation with per-SKU variance, mandatory variance reason, reconciler name (`FR-PIR-08`) and posting date. Nothing in the workbook covers it. This is a missing operation, not a resolved duplicate — it is what `SG-04` anticipated.

### 2.5 Ageing definitions do not agree

`FR-MIG-06`: MRN ageing = calendar days between **Invoice Date** and current date.
v1.7 API-01 `OrderAgeingDays`: predecessor **sales-order/PO creation** to confirmed depot arrival, or to current date while in transit.

Different start events, same column name on screen. One of them is wrong.

---

## 3. New conflicts to log

| Ref | Conflict | Evidence |
|---|---|---|
| SPI default | `FR-INV-18` says default `SP01`; `FR-IWM-34` says default `SPI01` | Internal BRD inconsistency |
| Bags↔MT | `FR-PIR-13` fixes a bag at 50 kg / 0.05 MT as a constant; `Q-060` requires derivation from material UoM (`MARM`) | BRD states the business rule; SAP source still unproven |
| Ageing start event | §2.5 above | `FR-MIG-06` vs `SRC-SID-20260811-10` |
| LR/GR conditionality | `FR-INV-24`, `FR-IWM-43`: mandatory for FTB only, optional for EXW/FTP. v1.7 API-06 marks `Shipment.LrGrNumber` mandatory unconditionally | BRD is more specific |
| Pickup code conditionality | `FR-INV-27`: mandatory for FTP **and** EXW, disabled for FTB. `FR-IWM-44`: mandatory for FTP **only**, disabled for FTB | Internal BRD inconsistency; v1.7 says only "when configured Incoterm requires it" |
| Stock type on receipt | `FR-MIG-23`: shortage location posts to **Blocked** stock type and cannot fulfil orders; all other locations post to **Unrestricted** | Confirms these are real storage locations receiving real postings, with the restriction carried by stock type. `Allocations[]` may need a stock-type outcome per line |

---

## 4. GR boundary

BRD §4.5 intro and `FR-IWM-46` place GR in the consolidated status list while describing it as a destination-warehouse action performed after physical arrival:

```
Source warehouse:       PO → DI → PGI / shipment / invoice / E-Way Bill
Destination warehouse:  physical arrival → MIGO → GR
```

GR appearing in one document-flow view does not put it inside the outbound transaction. It stays in the inbound service and its own LUW.

---

## 5. What none of this evidence proves

The BRD does not identify: the API caller, SEGW project count or grouping, BAPIs or function modules, LUW and commit boundaries, retry or idempotency ownership, or the mapping from any derived operation back to a formal register row.

Service names remain `RECEIPT` / `DELIVERY` / `STOCK` / `DISPATCH` / `EDOC` as provisional. `INBOUND` / `OUTBOUND` / `INVENTORY` / `STO` are architectural proposals pending ABAP sign-off and must not be written into the workbook's Proposed service column yet.
