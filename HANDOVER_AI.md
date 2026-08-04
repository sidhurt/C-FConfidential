# Handover â€” Complete Current-State Briefing for an AI Agent

**Version:** 2.0 Â· **Date:** 2026-08-03
**Supersedes:** `HANDOVER_2026-07-30_AI.md` (archive it; it predates the Option C decision, the KDS catalogue, and the DigiGST finding)
**Status:** Current state only. Superseded assumptions have been deliberately removed, not marked â€” if a belief is absent here and present in an older document, the older document is wrong.

---

## 0. Read this first â€” how to navigate this repository

### 0.1 The register-ID problem

This repository accumulated **five parallel numbering systems** as it grew. They overlap. Use this precedence:

| System | Where | Status | Use it for |
|---|---|---|---|
| **`API-01`..`API-10`** | `deliverables/CNF_API_Classification.xlsx` | **CURRENT â€” authoritative** | The API inventory. Aligned 1:1 with the client's own process register |
| **`Q-001`..`Q-043`** | `OPEN_QUESTIONS.md` | **CURRENT â€” authoritative** | Open questions |
| **`D-001`..`D-017`** | `DECISION_LOG.md` | **CURRENT â€” authoritative** | Decisions |
| `V-01`..`V-29` | `deliverables/CNF_Delivery_Planning.xlsx` â†’ Validation Register | Parallel to Q-items, partly duplicative | Client-facing access request only. Where V and Q disagree, **Q wins** |
| `IF-001`..`IF-024` | `_archive/INTERFACE_REGISTER.md` | **RETIRED 2026-08-03** | Archived. Oldâ†’new mapping in `_archive/README.md` |
| `R-001`..`R-027` | `_archive/REQUIREMENTS_MATRIX.md` | **RETIRED 2026-08-03** | Archived |
| `A-01`..`A-13` | Planning workbook â†’ Assumptions | Current | Assumption log with confidence |
| `C-1`..`C-10` | Various | Current | Conflicts |

**If you are asked to update "the interfaces", update `API-01..API-10`.** Do not revive IF- or R- numbering.

### 0.2 Documents in this repo that are STALE â€” do not trust

- `PROJECT_BRAIN.md` â€” still lists SPI as unknown, DI-as-delivery as hypothesis, and a six-interface framing. Useful for the *project thesis* (Â§3.1 below), wrong on facts
- `MASTER_PLAN.md`, `NEXT_MOVE.md`, `SEGW_ODATA_PLAN.md`, `BAPI_CANDIDATES.md`, `CPI_CONTRACTS.md` â€” written pre-evidence. Method is sound; specific SAP claims are unvalidated guesses from before the client documents arrived
- `_archive/` â€” deliberately retired, provenance only. See `_archive/README.md` for what went where and why

**Trust, in order:** this file â†’ `DECISION_LOG.md` â†’ `OPEN_QUESTIONS.md` â†’ `DOMAIN_GLOSSARY.md` â†’ `SYSTEM_OF_RECORD_MATRIX.md` â†’ the two deliverable workbooks.

### 0.3 Source documents â€” in `sources/`

Primary evidence is held in `sources/`, prefixed by source ID. Plain-text extractions of the Office files are in `sources/extracted/` and can be read directly without parsing OOXML. Index and caveats: `sources/README.md`.

| Source ID | Holds |
|---|---|
| `SRC-TECH-001` | Vendor-proposed spec, 32 defects logged |
| `SRC-DOC-20260803-01` | Feature â†’ SAP table/T-code mapping |
| `SRC-DOC-20260803-02` | **The KDS catalogue** â€” 11 sheets of real code values |
| `SRC-ARCH-20260803-01` | Three architecture options; C selected |
| `SRC-MTG-20260803-01` | UI/UX walkthrough transcripts (audio excluded â€” 27 MB, still in `Downloads`) |

**Not held, and unrecoverable:** the 28 July recordings (`SRC-MTG-20260728-01..04`) are no longer on disk. Every 28 July claim â€” **including approved decisions D-001 to D-006** â€” rests permanently on secondhand reconciliation. Treat those decisions as needing business re-confirmation, not as primary evidence.

**Never supplied to anyone:** `SRC-BRD-001` (business requirements) and `SRC-CPI-001` (CPI workbook). Largest documentary gap in the project.

### 0.4 Evidence rule specific to this project

A fact **Siddharth states directly** in conversation is logged **Verified**, source-tagged `SRC-SID-YYYYMMDD-NN`. This is a deliberate exception to the general "conversation is not evidence" rule, recorded in `README.md`. Where he explicitly hedges ("not sure", "90%"), preserve that hedge.

---

## 1. What the project is

**Client:** Shree Cement Ltd (Bangur group). **Program:** C&F Agent Interface â€” a web portal for Clearing & Forwarding depot agents to run dispatch operations. **Namespace:** `ZCNF_*`.

**Siddharth's position:** the **only** SAP ABAP developer on this workstream. No DEV access as of 2026-08-03. No formal written assignment. Everything produced so far is pre-access analysis and design.

**The business chain being digitised:**

```text
Sales Order / STO
   â†’ Outbound Delivery ("DI")           VL01N Â· LIKP/LIPS
   â†’ storage location + batch allocation
   â†’ transporter, route, freight
   â†’ Post Goods Issue                   mvt 601 Â· MKPF/MSEG
   â†’ Shipment                           VT01N Â· VTTK/VTTP/VTTS
   â†’ Shipment Cost                      VI01 Â· VFKK/VFKP
   â†’ Billing                            VF01 Â· VBRK/VBRP â†’ FI
   â†’ e-Invoice (IRN) + E-Way Bill       DigiGST /DIGIGST/INVP
   â†’ document status / download
   â†’ correction Â· extension
```

Peripheral: MIGO goods receipt (inbound), warehouse-to-warehouse STO transfer (`ZP06`), reports.

---

## 2. Architecture â€” as decided

**Landscape:** SAP S/4HANA (or ECC â€” release still unconfirmed, Q-002/V-01) Â· SAP Integration Suite (CPI/SCPI) Â· SAP Commerce Cloud, two tenants **T1 (CRM)** and **T2 (CNF/OMS)** Â· Spartacus storefront Â· SAP Datasphere (DSP) Â· DigiGST add-on.

**Confirmed:** CPI **is** in the runtime path between Commerce and S/4. (An early vendor document showed a direct storefrontâ†’Gateway connection with no middleware â€” that reading is wrong.)

### 2.1 Option C â€” the selected data-integration pattern (D-014)

Three options were presented; **Option C was chosen**:

| Data | Portal reads it from | Freshness |
|---|---|---|
| **Orders, Deliveries, Invoices** | **Hybris T1 (CRM)** â€” live OCC query | Real-time |
| Invoice PDF download | Hybris T1 â€” OCC query | Real-time |
| Pending MRN, STO List | T2, synced from Datasphere | 15 min |
| Stock Ageing | T2, synced from Datasphere | Daily |
| Depotâ†’Storage Location, Vehicle Master, Transporter Master | T2, daily from Datasphere | Daily |

The deck's own stated cost: *"two integration patterns to build and maintain."*

### 2.2 Why this matters more than anything else in this document

**Option C removes most read APIs from SAP scope.** Orders, deliveries, invoices, pending MRN, STO list, stock ageing â€” none is an ABAP endpoint. What remains on the SAP side:

- the **write commands** (Create DI, Modify DI, Submit MIGO, Invoice Creation, Invoice Correction)
- **two real-time reads** â€” Stock Availability and Shipment Cost estimate â€” **neither of which appears on the Option C diagram** (Q-038)
- a **new, unowned outbound flow**: S/4 â†’ T1 push for deliveries and invoices (Q-037)

### 2.3 Source of record â€” creation vs read are different questions

S/4 **creates** deliveries and invoices. Under Option C the portal **reads** them from T1. Do not conflate. Full table in `SYSTEM_OF_RECORD_MATRIX.md`.

Commerce T2 owns: depot, user, agent-depot, geography master, material alias, Incoterms, storage location, depot-SL, SL-SPI. These are **inputs** to SAP APIs, not SAP-derived values. Datasphere owns MRN, STO, plant-SL, ageing â€” **SAP does not generate MRN**.

---

## 3. The ABAP role

### 3.1 The project thesis â€” still the most important sentence in the repository

> **A BAPI will not repair a semantically wrong payload.**

Client senior stakeholders explicitly pushed back on the work being scoped as "CPI/Commerce field mapping and BAPI posting". They were right. A technically correct BAPI call with wrong business codes posts a real document with wrong content, and it fails silently in production rather than loudly in code review.

This is why the KDS catalogue (Â§4) mattered more than any BAPI decision.

### 3.2 Scope

**In:** S/4 source analysis; ABAP application classes; SEGW/OData V2 (subject to release â€” RAP may be correct instead); BAPI/released-API selection and validation; SAP-side validation, error mapping, logging, idempotency; commit/rollback policy; CPI-facing contracts; layered tests.

**Out:** frontend, iFlow construction, Datasphere modelling, Basis parameters/roles, functional sign-off, GSP credential ownership, production postings.

**Standing rule:** *collaborate across every boundary, but do not silently accept ownership.*

### 3.3 The boundary question currently live

"SAP â†’ T2 APIs" has been indicated as Siddharth's responsibility. Three readings, and they must be distinguished:

1. **OData services T2/CPI call into SAP** â€” always was his job. Coherent.
2. **Outbound push from S/4** (Q-037) â€” coherent as his, but **new scope, in no estimate**. Must be named, not absorbed.
3. **End-to-end including CPI iFlows and Commerce ingestion** â€” **not** his scope per `ROLE_BOUNDARIES.md`.

---

## 4. Verified knowledge base

Everything in this section is **documented in client artifacts or stated directly by Siddharth**. This is the highest-confidence material in the project. Still to be system-verified on DEV access, but treat as authoritative for design.

### 4.1 Terminology resolved

| Term | Resolution |
|---|---|
| **DI** | The **outbound delivery**. "DI No." = `LIKP-VBELN`. Not "Delivery Instruction" (D-007) |
| **KDS** | **Key Data Structure** â€” the client's own term for their master/reference code catalogue. A client artifact, not an SAP object. **The catalogue has been received** (`SRC-DOC-20260803-02`) |
| **SPI** | **Special Procurement Indicator**. Mapped storage-locationâ†”SPI in custom table **`ZLETSPIMAP`**. Values `SP01`â€“`SP09`, `RLCO`, `RLMI`, `RLOP`, `VT21`. Governs storage-location eligibility for MIGO/Stock/Invoice |
| **GDF, DTP, GDRK, RSD, CUT, DMG, DRD, FRSH, ASST, CLYC, PRST, RCPT, RMYD, SOW** | Literal 4-character **storage location codes** in `T001L`. Not "categories" |
| **MRN** | Material Receipt Note â€” a **Datasphere object**. SAP does not generate it |
| **ODN** | Official Document Number â€” India GST statutory invoice numbering, distinct from the SAP billing document number. Generated at invoice creation |
| **FTP / FTB / EX** | Three shipping types, Incoterm-driven. FTP = Freight to Pay, FTB = Freight to Bill, EX = Ex-works. Actual Incoterm codes in the data: **FTP (330 records), FTB (57), EXP (9), EXW (2), EXR (1)** |

### 4.2 Material master structure â€” brand and grade are plain fields

Held in `MVKE`, text tables `TVM1`â€“`TVM5`. **Not classification characteristics.**

| Field | Meaning | Values |
|---|---|---|
| `MVGR1` | Product type | `000` OPC Â· `001` PPC Â· `002` PSC Â· `003` CC Â· `004` AAC Â· `005` RMC Â· `006` Clinker Â· `007` Rubble Â· `008` Mortar Â· `009` Raw Material Â· `010` Scrap Â· `011` Synthetic Gypsum Â· `012` Limestone Â· `013` Misc. Service sales |
| `MVGR2` | **Grade** | `0` OPC43 Â· `1` OPC53 Â· `2` PPC Â· `3` PSC Â· `4` CC Â· `5` PPC PREMIUM Â· `6` PPC POWER Â· `7` PPC CS Â· `8` CLINKER Â· `9` AAC BLOCK Â· `10` MORTAR Â· `11` OPC 53 S |
| `MVGR3` | **Brand** | `000` SHREE Â· `001` BANGUR Â· `002` ROCKSTRONG Â· `003` MAGNA |
| `MVGR4` | Pack type | `000` HDPE Â· `001` LPP Â· `002` LOOSE |
| `MVGR5` | **Trade / Non-trade** | `1` TRADE Â· `002` NON TRADE |

### 4.3 Organisational structure

- **Sales org `1000`** = Shree Cement Ltd (`TVKO-VKORG`) â€” the only sales org appearing across every KDS mapping sheet
- **Company codes `1000`, `1300`** (`T001-BUKRS`). `1300` was relayed as "Shree Cement East, a sales organisation" but the KDS document lists it as a company code â€” **conflict C-10, Q-040**
- **Division `10`** = Cement (`TSPA`) Â· **Distribution channels `10`, `20`, `99`** (`TVTW`)
- Sales area â†’ plant via **`TVKWZ`** Â· â†’ sales office via **`TVKBZ`**
- Plant â†’ storage location: **`T001L`**

### 4.4 Customer groups (`KNVV-KDGRP`, text `T151`)

45 values. Relevant: `10` Dlr-Wholesale Â· `11` Dealer-Retail Â· `12` Consignee (Ship-to) Â· `13` Retailer/Sub Dealer Â· `14` Institutional Â· `15` Industrial Â· `16` Builder & Developers Â· `19` Obligatory Non Trade Â· `27` Transporter Â· `28` Depot Â· `29` Plant Â· **`31` Handling Agent** Â· `45` General B2B.

**The C&F agent itself** is enrolled as **both vendor and customer** â€” customer group `31`, account group `ZDOM`, created via T-code **`ZMDM_BP`**.

### 4.5 Other master structures

- **Material Freight Group** `MFRGR` / `TMFG` â€” `A0000001` Cement Packed, `A0000002` Cement Loose, `A0000003` Clinker â€¦ `A0000022` Cement Loose (F). Drives shipment cost
- **Material Pricing Group** `KONDM` / `T178` â€” `01` Normal, `02` Spare parts, `W1`â€“`W3` Warranty
- **Nielsen Indicator** `MARC`/`TNLS` â€” `01` SC, `02` Bangur, `03` RC, `04` Magna, `05`â€“`08` combinations, `09` Others. Linked to `MVGR3` via condition table **`KOTG508`** and a **`MV45AFZZ` user exit** in sales-order processing
- **Incoterm** maintained as **condition type `ZISP`** via VK11/12/13 at sales org + channel + plant with validity dates

### 4.6 Client custom objects already in place

This introduced a **fourth classification tier** â€” several needs already have working implementations:

| Purpose | Object |
|---|---|
| Pending DI / Pending MRN | **`ZLE526`** |
| Completed MRN | **`ZLE520`** |
| Pending orders | **`ZSDR512N`** |
| Sales register / historical billing | **`ZSDR513`** |
| Stock ageing | **`ZMM5013`** |
| Stock at warehouse | `MB52` (standard) |
| Pending STOs | `ME2M` (standard) |
| e-Invoice / E-Way cockpit | **`/DIGIGST/INVP`** |
| Business partner creation | **`ZMDM_BP`** |

### 4.7 Statutory â€” DigiGST, not SAP

**The client uses DigiGST** (`/DIGIGST/INVP`), a third-party GST add-on â€” **not** SAP Document and Reporting Compliance. And **E-Way Bill extension is stated as "handled at GSP/NIC portal, not core SAP"** (D-017).

### 4.8 Transport and movement types

- Classic **LE-TRA** shipment (VT01N) and shipment costing (VI01) confirmed in use
- MIGO movement types in scope: **101/102/313/315/311/122/551** â€” goods receipt, reversal, two-step and one-step intra-plant transfer, vendor return, scrapping
- STO document type **`ZP06`**; receiving warehouse closes with its own MIGO against the same reference

### 4.9 Authorization model

Master role + **derived roles** (PFCG), scoped via `TVKWZ` (sales org + channel + plant) and `TVKVZ` (+ division + sales office). Derived roles carry sales-office assignment. User master `SU01`/`USR02`; role tables `AGR_DEFINE`, `AGR_USERS`, custom `ZUSROLE`.

### 4.10 Approved business rules

| ID | Rule |
|---|---|
| D-001 | `Order Quantity = DI Quantity + Pending Quantity` |
| D-002 | **One storage location per DI**, multiple batches inside it; batch quantities must sum **exactly** to DI quantity |
| D-003 | E-Way Bill extension: **Road only**, 24 hours, repeatable |
| D-004 | E-Way Bill Part B editable during validity |
| D-005 | Only DI quantity editable after creation, while DI is open |
| D-006 | Vehicle tracking via FleetX (integration owner unassigned) |
| D-009 | **Updating DI quantity resets batch determination** |
| D-010 | DI leaves In-Progress list on success **or** failure â†’ Invoice Management |
| D-011 | List removal keyed on **DI number**, not order number (one order â†’ many DIs) |
| D-013 | Shipping cost estimate is **read-only** â€” SAP returns a value, user cannot alter it |

D-009 to D-013 came from a UI/UX design review, **not** a business decision owner, and that session stated the design is not a final handoff. Re-confirm at formal handoff.

---

## 5. The API model â€” current

`API-01`..`API-09` map 1:1 to the client's own process register. `API-10` is a proposed addition.

| ID | API | Class | Current position |
|---|---|---|---|
| API-01 | Check MIGO | **W** | `ZLE526` already implements this. Under Option C the portal reads Pending MRN from DSPâ†’T2 â€” SAP surface may reduce to little or nothing |
| API-02 | Submit MIGO | **S** | `BAPI_GOODSMVT_CREATE`. Does **not** derive MRN (Datasphere-owned) |
| API-03 | Create DI | **S** | Predecessor is **both SO and STO** â†’ must branch between `_CREATE_SLS` and `_CREATE_STO`. **Derive the type from the document number; do not trust the caller** |
| API-04 | Stock Availability | **C** | Unrestricted stock at batch grain. **Absent from the Option C diagram â€” Q-038** |
| API-05 | Shipment Cost | **X / S** | Estimate mode has **no standard SAP equivalent** (costing is document-bound). Recommended: condition-technique pricing in simulation |
| API-06 | Invoice Creation | **X** | Staged orchestration across 4 SAP LUWs + 2 external calls. The hardest item |
| API-07 | Invoice Correction | **S** | Standard has order type **RK** (Invoice Correction Request) purpose-built for this |
| API-08 | E-Invoice Correction | **T** | DigiGST integration. IRN cannot be amended â€” cancel-and-reissue inside window, credit note outside |
| API-09 | E-Way Bill Extension | **?** | Stated "not core SAP" â€” **may be out of ABAP scope entirely** |
| API-10 | Modify DI *(proposed)* | **S** | Quantity change **resets batch determination** (D-009) |
| **NEW** | **S/4 â†’ T1 outbound push** | **unowned** | Deliveries and invoices read live from T1 but created in S/4. No trigger, latency, mechanism or owner. **Q-037** |

**Classification tiers:** `S` standard Â· `C` custom composite over standard sources Â· `X` no standard equivalent, build it Â· `W` wrap existing client custom object Â· `T` third-party add-on.

### 5.1 API-06 design position

Cannot be one LUW. Requires: process state persistence, stage engine with preconditions, per-stage guards, process-level idempotency keyed on an external request ID, **business lock on the DI number** (not just the request ID â€” two different valid requests can target one delivery), reconciliation for the "SAP committed, response lost" case, and retryable-vs-terminal error classification per stage.

**Likely simplification:** the client indicates the sequence is staged "with some automated instead of manual". In DigiGST-style frameworks the IRN typically fires automatically on billing save. If so, API-06 **drives stages 1â€“4 and observes 5â€“6** rather than invoking them.

### 5.2 Cross-cutting â€” no standard SAP equivalent

**Idempotency.** Every command needs an external request-ID store surviving the committed-but-response-lost case. Most commonly underestimated item in the inventory. Use the standard Business Application Log for logging (do not build Z-log tables); standard authorization objects fire inside the BAPIs regardless, so custom objects supplement rather than replace.

---

## 6. Open questions â€” ranked by what they gate

**Critical:**
- **Q-037** â€” What pushes Deliveries/Invoices S/4 â†’ T1? Existing CRM feed or new scope? Is the SAP-side mechanism in ABAP scope?
- **Q-038** â€” Where does real-time Stock Availability sit? Absent from Option C
- **Q-002 / V-01** â€” ECC or S/4HANA, exact release. Determines whether released APIs/CDS exist, and whether SEGW or RAP is correct
- **Q-031** â€” DI predecessor is both SO and STO; how is the branch determined per scenario?
- **Q-027** â€” SD/MM knowledge transfer. **Sujal** (business analyst) named as the person who knows the product

**High:**
- **Q-039** â€” Does DSP replicate raw tables (SLT/CDC) or a CDS view? "Pending" is derived logic; `ZLE526` already implements it. Independent reimplementation will drift
- **Q-042** â€” DigiGST integration surface. Is API-09 out of ABAP scope?
- **Q-043** â€” Should APIs wrap `ZLE526`/`ZSDR512N`/`ZSDR513` rather than rebuild composites? Are they RFC-capable?
- **Q-032** â€” Measured SAP invoice-generation latency. Nobody has measured it; the UI is designed to an explicit best-case assumption
- **Q-035** â€” Does SAP expose queryable invoice status, and where does a *failed* invoice get retried? D-010 removes it from the list on failure with no retry surface specified
- **Q-034** â€” What SAP configuration implements FTP vs FTB vs EX?
- **Q-033** â€” Pickup code: disabled in FTP, or only in FTP? (conflict C-8)
- **Q-010/011/012** â€” Idempotency, error schema, correlation standards

**Medium:** Q-040 (1000/1300 sales org vs company code) Â· Q-041 (ODN confirmation) Â· Q-008/Q-028 (FIFO ownership â€” explicitly TBD) Â· Q-016 (document storage) Â· Q-019 (dev conventions)

---

## 7. Live conflicts

| ID | Conflict |
|---|---|
| **C-8** | Pickup code: "disabled in FTP" vs "only present in FTP", stated seconds apart in the same session. The KDS index says ZISP *"drives DI and FTP pickup-code logic"*, which leans toward the second |
| **C-9** | D-005 says DI quantity editable "while DI is open"; D-009 establishes editing resets batch determination â€” implying the window closes at or reaches through batch determination |
| **C-10** | `1000`/`1300` â€” sales organisations (relayed) vs company codes (KDS document) |

---

## 8. What a successor should do next

1. **Re-read `DECISION_LOG.md` and `OPEN_QUESTIONS.md`** before relying on anything here â€” this file goes stale the moment a new document arrives.
2. **If DEV access has landed:** do not trust any BAPI name, field or classification until re-verified. Start with API-04 and API-01 â€” read-only, zero business-state risk.
3. **If not:** the highest-value unblocked work is (a) asking S2 for the screen-by-screen field-level source mapping â€” it exists and is exactly the contract input needed; (b) booking the Sujal session against `DOMAIN_GLOSSARY.md Â§Required KT outputs`.
4. **Raise Q-037 in the next architecture conversation.** It is a genuine gap in the chosen design, nobody has named it, and it is the highest-leverage contribution available.
5. **Do not generate new speculative deliverables unasked.** The existing set is sufficient; more paper does not accelerate access.

---

## 9. What would invalidate this document

- DEV access â€” converts most of Â§4 from documented to verified, or corrects it
- Arrival of the BRD or CPI workbook â€” never supplied to anyone
- Answers to Q-037 or Q-038 â€” either changes the SAP scope materially
- Formal design handoff â€” the 3 Aug UI review explicitly was **not** final
