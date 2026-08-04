# Handover — Complete Current-State Briefing for an AI Agent

**Version:** 3.0 · **Date:** 2026-08-04
**Supersedes:** v2.0 (2026-08-03), which predates all system-observed evidence
**Status:** Current state only. Superseded beliefs are removed, not annotated — except §10, which lists them explicitly so nobody re-derives them.

---

## 0. Navigate this repository before reasoning about it

### 0.1 Register-ID precedence

| System | Where | Status |
|---|---|---|
| **`API-01`..`API-10`** | `deliverables/CNF_API_Classification.xlsx` | **Authoritative** — the API inventory, aligned 1:1 with the client's process register |
| **`Q-001`..`Q-048`** | `OPEN_QUESTIONS.md` | **Authoritative** — open questions |
| **`D-001`..`D-026`** | `DECISION_LOG.md` | **Authoritative** — decisions and established facts |
| `A-01`..`A-15` | Planning workbook → Assumptions | Current |
| `C-1`..`C-10` | Various | Current — conflicts |
| `V-01`..`V-29` | Planning workbook → Validation Register | Parallel to Q-items. **Where V and Q disagree, Q wins** |
| `IF-`, `R-` | `_archive/` | **Retired.** Mapping in `_archive/README.md` |

### 0.2 Stale — do not trust

- `MASTER_PLAN.md`, `NEXT_MOVE.md`, `SEGW_ODATA_PLAN.md`, `BAPI_CANDIDATES.md`, `CPI_CONTRACTS.md` — written before any client documentation arrived. Method sound; SAP specifics are pre-evidence guesses
- `SAP_API_DOSSIER.md` — Part A (32-defect review of the vendor spec) is accurate and still useful. Part C's API set is superseded
- `_archive/` — provenance only

**Trust order:** this file → `DECISION_LOG.md` → `OPEN_QUESTIONS.md` → `DOMAIN_GLOSSARY.md` → `SYSTEM_OF_RECORD_MATRIX.md` → `PROJECT_BRAIN.md` (conceptual model) → the two deliverable workbooks.

### 0.3 Evidence hierarchy — this project now has four tiers

Introduced 2026-08-04, when direct system access began producing evidence that contradicted documents. **Higher tiers override lower ones.**

| Tier | Source | Examples |
|---|---|---|
| **1. System observation** | Read directly from QS4 — SE11, SE16, SE38, SE93, System→Status | S/4HANA 2022; `ZLETSPIMAP` contents; no `ZCNF*` objects |
| **2. Client documents** | Configuration written by the client's own SAP team | KDS catalogue, feature→SAP mapping, architecture deck |
| **3. Direct statement** | Siddharth in conversation, tagged `SRC-SID-*`. Logged **Verified**; preserve any hedge he states | DI = delivery; Option C selected |
| **4. Meeting reconstruction** | Secondhand from transcripts | 28 July decisions D-001..D-006 |

**Tier 4 is fragile here.** The 28 July recordings are lost from disk, so D-001 to D-006 can never be re-adjudicated. Treat them as needing business re-confirmation.

### 0.4 Source documents — `sources/`

Originals prefixed by source ID; plain-text extractions in `sources/extracted/`. Index and caveats in `sources/README.md`.

`SRC-TECH-001` vendor spec · `SRC-DOC-20260803-01` feature→SAP mapping · `SRC-DOC-20260803-02` **the KDS catalogue** · `SRC-ARCH-20260803-01` architecture options · `SRC-MTG-20260803-01` UI walkthrough transcripts · **`SRC-CODE-20260804-01` SE38 source of `ZLE_MRN_PENDING_REPORT`, `ZSD_PENDING_ORDER_REP_PP`, `EDOC_COCKPIT`**

**Never supplied to anyone:** the BRD (`SRC-BRD-001`) and CPI workbook (`SRC-CPI-001`). Largest documentary gap.

---

## 1. The project

**Client:** Shree Cement Ltd (Bangur). **Program:** C&F Agent Interface — a portal for Clearing & Forwarding depot agents. **Namespace:** `ZCNF_*` (nothing built yet).

**Siddharth:** the **only** SAP ABAP developer on this workstream. Has **QS4 read access** (user QNOVATE8, client 700). No DEV access. No formal written assignment.

**Business chain:**

```text
Sales Order / STO
  → Outbound Delivery ("DI")        VL01N · LIKP/LIPS
  → storage location + batch allocation
  → transporter · route · freight
  → Post Goods Issue                mvt 601 · MATDOC
  → Shipment                        VT01N · VTTK/VTTP/VTTS
  → Shipment Cost                   VI01 · VFKK/VFKP
  → Billing                         VF01 · VBRK/VBRP → FI
  → e-Invoice (IRN) + E-Way Bill    SAP eDocument + DigiGST
  → status · download · correction
```

Peripheral: inbound goods receipt (MIGO), plant→depot STO transfer, reports.

---

## 2. Landscape and architecture

### 2.1 Confirmed by system observation (D-018)

**SAP S/4HANA 2022 on-premise** · ABAP Platform 2022 · HANA 2.00.087 · Fiori FES 2022 SP04 · Linux/x86_64 · Unicode.

**Three-system landscape: `DS4` (dev) → `QS4` (quality) → `PS4` (production).** The vendor spec claimed two-system DEV→PRD. Wrong.

Consequences: released A2X APIs and CDS views exist; **RAP is available and SEGW is deprecated for new development** (Q-046); `MATDOC` is the material document table, not `MKPF`/`MSEG`.

### 2.2 Gateway reality

Only **7 A2X services registered**: `API_SALES_ORDER_SRV`, `API_BUSINESS_PARTNER`, `API_CV_ATTACHMENT_SRV`, plus four PM/PP. **Not registered:** `API_OUTBOUND_DELIVERY_SRV`, `API_BILLING_DOCUMENT_SRV`, `API_MATERIAL_DOCUMENT_SRV`, `API_MATERIAL_STOCK_SRV`.

They exist in S/4HANA 2022 — they are simply not activated here. **Available ≠ activated.** Activation is a small Basis task (Q-045) and should happen before any decision to build custom.

Client Gateway convention: every service is `Z<name>` technical with the SAP name as External Service Name.

### 2.3 Option C — the selected data-integration pattern (D-014)

| Data | Portal reads from | Freshness |
|---|---|---|
| **Orders, Deliveries, Invoices** | **Hybris T1 (CRM)** — live OCC | Real-time |
| Invoice PDF download | Hybris T1 | Real-time |
| Pending MRN, STO List | T2, synced from Datasphere | 15 min |
| Stock Ageing | T2, from Datasphere | Daily |
| Depot→Sloc, Vehicle, Transporter masters | T2, from Datasphere | Daily |

**Option C removes most read APIs from SAP scope.** What remains: the write commands, two real-time reads (Stock Availability, Shipment Cost estimate — **neither appears on the Option C diagram**, Q-038), and a **new unowned outbound flow**: S/4 → T1 push for deliveries and invoices (**Q-037**).

CPI is confirmed in the runtime path. An early vendor document showed a direct storefront→Gateway connection — that reading is wrong.

### 2.4 Created-in vs read-from

S/4 **creates** deliveries and invoices; the portal **reads** them from T1. Never conflate. Commerce T2 owns depot, user, geography, material alias, Incoterms, storage location, depot-SL, SL-SPI — these are **inputs** to SAP APIs. Datasphere owns MRN, STO, plant-SL, ageing. Full table in `SYSTEM_OF_RECORD_MATRIX.md`.

---

## 3. The ABAP role

### 3.1 The thesis

> **A BAPI will not repair a semantically wrong payload.**

Client seniors pushed back on the work being scoped as "field mapping and BAPI posting". They were right. The semantic gap is now largely closed by the KDS catalogue and system observation — but the principle stands.

### 3.2 Scope

**In:** S/4 source analysis; ABAP classes; OData services (SEGW or RAP — undecided, Q-046); API/BAPI selection; SAP-side validation, error mapping, logging, idempotency; commit policy; CPI-facing contracts; tests.

**Out:** frontend, iFlow construction, Datasphere modelling, Basis parameters/roles, functional sign-off, GSP credential ownership, production postings.

**Standing rule:** collaborate across every boundary, but do not silently accept ownership.

### 3.3 The live boundary question

"You own the SAP T2 APIs" was said without an entity list. Three readings, and they must be distinguished:

1. **OData services T2/CPI call into SAP** — always his. Coherent.
2. **Outbound push from S/4** (Q-037) — coherent as his, but **new scope in no estimate.** Name it, don't absorb it.
3. **End-to-end including CPI iFlows and Commerce ingestion** — **not** his scope.

Note that under Option C, T2 reads from Datasphere, not S/4 — so a literal "S/4→T2" read path barely exists.

---

## 4. Verified knowledge base

### 4.1 System-observed (tier 1)

| Fact | Detail |
|---|---|
| Backend | S/4HANA 2022 on-premise, ABAP Platform 2022, three-system DS4/QS4/PS4 |
| `ZCNF*` objects | **None exist.** Greenfield confirmed (D-019) |
| **SPI** | **Special Processing Indicator**, data element `SDABW`, a **delivery item field** (`LIPS-SDABW`). `ZLETSPIMAP` keys `MANDT`+`LGORT`+`SDABW` is a **valid-combinations** table — GDF permits five SPIs (RLCO, RLMI, SP01, SP04, SP08). Storage location alone does **not** determine SPI (D-020, Q-044) |
| Storage locations | Literal 4-char `T001L` codes: ASST, CLYC, CUT, DMG, DRD, DTP, FRSH, GDF, GDRK, PRST, RCPT, RMYD, RSD, SOW, STG |
| Material document | **`MATDOC`** on S/4, not `MKPF`/`MSEG` |
| Registered A2X services | 7 only; the delivery/billing/material ones are absent |

### 4.2 Source-verified (tier 1, from `SRC-CODE-20260804-01`)

| Fact | Detail |
|---|---|
| **"Pending MRN"** | **In-transit quantity on plant→depot movement** = dispatched − received, per delivery. Chain: STO (`EBELN`) → outbound delivery from supplying plant → goods issue → in transit → goods receipt **mvt 101** at receiving plant, linked via `MATDOC-VBELN_IM` (D-021, closes Q-004) |
| **Existing CDS views** | **`zsd_mrn_pending_cds_opt`** (main, all filters) · `zle_di_inv_details` (dispatched qty) · `zle_mrn_goods_reciet_cds` (received qty). **Directly consumable** |
| **`ZSD_PENDING_ORDER_FM`** | **RFC-enabled** FM returning `zsd_st_pending_order_out`; called via `DESTINATION IN GROUP` for parallel processing (D-022) |
| Plant authorization | Custom object **`ZLE_PLNT`**, field `WERKS`. Already in use — reuse, don't reinvent (D-024) |
| Vehicle / LR-GR | **`VTTK-ZZVEHICLE_NO`**, **`VTTK-ZZLR_GR_NO`** — Z-fields on the **shipment header** (D-025) |
| E-Way Bill number | **`/DIGIGST/OWARD_H-EWBNUMBER`** |
| Statutory frameworks | **Both present.** SAP eDocument installed (standard `EDOC_COCKPIT`, `EDOCUMENT`, `CL_EDOC_COCKPIT_UI`, `ZEDOC_DCC_SRV`) **and** DigiGST for India (D-023) |
| Credit status | **`CMGST`** + `DDTEXT`. Multi-valued — the portal's two-value display is lossy (D-026) |
| Quantity chain | contract `ZMENG` → `ORDER_QTY` → `SCHEDULE_QTY` → `DEL_QTY` → `INV_QTY` → `REJ_QTY` → **`BAL_QTY`**. Six steps, not D-001's three (D-026, Q-048) |
| Man-made state | `ZSDTPRICE-ZREGION` / `ZREGION_TEXT` — client regional grouping, distinct from SAP region |
| Landmine | **`TVARVC` name `ZLE526_EXCLUDE_DI`** — hardcoded delivery exclusions added under a ticket in Apr 2026. Plus a residual `MATDOC` reconciliation loop amended three times across 2024–25. **Reimplementing "pending" without these gives subtly wrong numbers** (Q-047) |

### 4.3 Document-verified (tier 2, KDS catalogue)

**Material master — plain fields in `MVKE`, texts in `TVM1`–`TVM5`. Not classification characteristics.**

| Field | Meaning | Values |
|---|---|---|
| `MVGR1` | Product type | OPC, PPC, PSC, CC, AAC, RMC, Clinker, Rubble, Mortar, Raw Material, Scrap, Synthetic Gypsum, Limestone, Misc |
| `MVGR2` | **Grade** | OPC43, OPC53, PPC, PSC, CC, PPC PREMIUM, PPC POWER, PPC CS, CLINKER, AAC BLOCK, MORTAR, OPC 53 S |
| `MVGR3` | **Brand** | SHREE, BANGUR, ROCKSTRONG, MAGNA |
| `MVGR4` | Pack type | HDPE, LPP, LOOSE |
| `MVGR5` | **Trade / Non-trade** | `1` TRADE, `002` NON TRADE |

**Org structure:** Sales org `1000` = Shree Cement Ltd (`TVKO`). Company codes `1000`, `1300` (`T001`) — relayed as sales orgs, documented as company codes, **conflict C-10 / Q-040**. Division `10` = Cement. Distribution channels `10`, `20`, `99`. Sales area→plant via `TVKWZ`; →sales office via `TVKBZ`.

**Customer groups** (`KNVV-KDGRP` / `T151`), 45 values. `10` Dlr-Wholesale · `11` Dealer-Retail · `13` Retailer/Sub Dealer · `14` Institutional · `19` Obligatory Non Trade · `27` Transporter · `28` Depot · **`31` Handling Agent**. The C&F agent is enrolled as **both vendor and customer** — group `31`, account group `ZDOM`, via `ZMDM_BP`.

**Other:** Material Freight Group `MFRGR`/`TMFG` (A0000001 Cement Packed … A0000022 Cement Loose (F)) drives shipment cost. Material Pricing Group `KONDM`/`T178`. Nielsen Indicator `MARC`/`TNLS` linked to `MVGR3` via condition table `KOTG508` and an **`MV45AFZZ` user exit**. Incoterm maintained as condition type **`ZISP`** via VK11/12/13 — distribution FTP 330, FTB 57, EXP 9, EXW 2, EXR 1.

**Transport:** classic LE-TRA (VT01N) and shipment costing (VI01). MIGO movement types 101/102/311/313/315/122/551. STO document type `ZP06`.

### 4.4 Approved business rules

D-001 `Order = DI + Pending` (simplification, see D-026) · D-002 one storage location per DI, batches sum **exactly** · D-003 E-Way extension Road-only, 24h, repeatable · D-004 Part B editable during validity · D-005 only DI quantity editable while open · D-006 FleetX tracking · D-007 **DI = outbound delivery, `LIKP-VBELN`** · D-009 **quantity change resets batch determination** · D-010 DI leaves In-Progress on success *or* failure · D-011 keyed on DI number, not order · D-013 shipment cost estimate is read-only.

D-009 to D-013 came from a UI/UX design review, **not** a business decision owner, and that session stated the design is not a final handoff.

---

## 5. The API model

| ID | API | Class | Position |
|---|---|---|---|
| API-01 | Check MIGO | **W** | **Upgraded.** Expose existing CDS `zsd_mrn_pending_cds_opt`. Must honour the TVARVC exclusion list and the residual reconciliation loop |
| API-02 | Submit MIGO | **S** | `BAPI_GOODSMVT_CREATE` / `API_MATERIAL_DOCUMENT_SRV`. Does **not** derive MRN |
| API-03 | Create DI | **S** | Predecessor is **both SO and STO**. Branch on `_CREATE_SLS` / `_CREATE_STO` |
| API-04 | Stock Availability | **C** | Unrestricted stock at batch grain. **Absent from Option C — Q-038** |
| API-05 | Shipment Cost | **X / S** | Estimate mode has **no standard equivalent** (costing is document-bound). Use condition-technique simulation |
| API-06 | Invoice Creation | **X** | Staged orchestration, 4 SAP LUWs + 2 external calls. Hardest item |
| API-07 | Invoice Correction | **S** | Standard order type **RK** (Invoice Correction Request) exists for this |
| API-08 | E-Invoice Correction | **T** | DigiGST + SAP eDocument. IRN cannot be amended — cancel-and-reissue in window, credit note outside |
| API-09 | E-Way Bill Extension | **?** | Stated "not core SAP" — **may be out of ABAP scope** |
| API-10 | Modify DI *(proposed)* | **S** | Quantity change **resets batch determination** (D-009) |
| **NEW** | **S/4 → T1 push** | **unowned** | Deliveries/invoices read from T1 but created in S/4. No trigger, mechanism or owner. **Q-037** |

**Tiers:** `S` standard · `C` composite over standard sources · `X` no standard equivalent · `W` wrap existing client artifact · `T` third-party add-on.

### 5.1 API-03 design — settled

Both BAPIs verified from source. Structurally identical; three differences only:

| | `_SLS` | `_STO` |
|---|---|---|
| Reference table | `SALES_ORDER_ITEMS` (`BAPIDLVREFTOSALESORDER`) | `STOCK_TRANS_ITEMS` (`BAPIDLVREFTOSTO`) |
| Input BAdI | `badi_dlv_create_sls_extin` | `badi_dlv_create_sto_extin` |
| Internal FM | `SHP_DELIVERY_CREATE_FROM_SLS` | `SHP_DELIVERY_CREATE_FROM_STO` |

Everything else identical — `SHIP_POINT`, `DUE_DATE`, `NO_DEQUEUE`, `EXTENSION_IN`/`OUT` (`BAPIPAREX`), shared output BAdI `badi_dlv_create_extout`, `DELIVERIES`/`CREATED_ITEMS`.

**Three design consequences:**
1. **Strategy pattern** — one interface, two reference-table builders. Derive the predecessor type from the document number; do not trust the caller.
2. **`EXTENSION_IN` + BAdI is the custom-field path** — vehicle/driver/transporter go through it, **inside the LUW**. This eliminates the vendor spec's second-commit Z-table hole. (Though `VTTK` Z-fields suggest the shipment is the real home.)
3. **There is no `sales_order` importing parameter** — the reference is a table. The vendor spec would not have compiled. One call can create **multiple deliveries** (`NUM_DELIVERIES`), so the contract cannot assume 1:1.

### 5.2 API-06 — required components

No standard orchestration exists. Needs: process state persistence, stage engine with preconditions, per-stage guards, process-level idempotency on an external request ID, **a business lock on the DI number** (not only the request ID — two different valid requests can target one delivery), reconciliation for "SAP committed, response lost", and retryable-vs-terminal error classification per stage.

Likely simplification: the client indicates the sequence is staged "with some automated". If IRN fires automatically on billing save, API-06 **drives stages 1–4 and observes 5–6**.

### 5.3 Cross-cutting

**Idempotency has no standard SAP equivalent** — custom by necessity, and the most underestimated item. Use the standard Business Application Log for logging (not Z-tables). Reuse `ZLE_PLNT` for plant authorization. Standard document authority fires inside the BAPIs regardless.

---

## 6. Open questions, ranked

**Critical:** Q-037 (what pushes S/4→T1) · Q-038 (real-time stock availability, absent from Option C) · Q-031 (SO vs STO branch determination) · Q-027 (SD/MM KT — **Sujal** named) · Q-012 (master/reference code dictionaries — largely served by the KDS catalogue)

**High:** Q-046 (**SEGW or RAP** — biggest technical decision) · Q-045 (activate the four released A2X services) · Q-044 (SPI determination when a storage location permits several) · Q-042 (DigiGST integration surface; is API-09 in scope) · Q-039 (does DSP replicate raw tables or a CDS view) · Q-035 (queryable invoice status; where a failed invoice retries) · Q-034 (FTP/FTB/EX configuration) · Q-032 (measured invoice latency — nobody has measured it) · Q-033 (pickup code, conflict C-8)

**Medium:** Q-047 (TVARVC exclusion list) · Q-048 (six-step quantity chain vs D-001) · Q-040 (1000/1300 sales org vs company code) · Q-041 (ODN confirmation) · Q-025 (Modify DI in scope)

**Closed by system observation:** Q-001, Q-002, Q-004, Q-013, Q-043.

---

## 7. Live conflicts

| ID | Conflict |
|---|---|
| **C-8** | Pickup code "disabled in FTP" vs "only present in FTP", stated seconds apart. The KDS index says `ZISP` *"drives DI and FTP pickup-code logic"*, leaning to the second |
| **C-9** | D-005 says editable "while DI is open"; D-009 says editing resets batch determination — implying the window closes at or reaches through batch determination |
| **C-10** | `1000`/`1300` — sales organisations (relayed) vs company codes (KDS document) |

---

## 8. What to do next

1. **Re-read `DECISION_LOG.md` and `OPEN_QUESTIONS.md`** — this file goes stale the moment new evidence arrives.
2. **Read the remaining report sources**: `ZLE_MRN_REPORT`, `ZSD_SALES_REGISTER_N`, `ZMM_INVENTORY_AGING_REPORT`. Two of three checked so far revealed consumable artifacts underneath.
3. **Trace one real delivery in QS4** — VL03N → document flow → VF03. Check `LIPS-SDABW` on a live record to see how SPI actually lands.
4. **Ask Basis to activate the four released A2X services** (Q-045). Small, concrete, and shrinks the custom surface before any build decision.
5. **Form a position on SEGW vs RAP** (Q-046) and bring it rather than defaulting.
6. **Raise Q-037 in the next architecture conversation.** A real gap in the chosen design, unnamed by anyone else.
7. **Do not generate speculative deliverables unasked.** The set is sufficient.

---

## 9. Constraints on an AI agent here

Per `AI_OPERATING_RULES.md`: plan and draft only until explicit approval. Never enable SAP GUI scripting or change RZ11/profile parameters — **always prohibited regardless of approval level**. Never modify roles. Never post, release, activate or transport without specific approval. QAS and PRD writes require separate authority.

No agent in this project has SAP connectivity. All system evidence is Siddharth reading screens and pasting results.

---

## 10. Beliefs held earlier that are now known wrong

Listed so no successor re-derives them.

| Was believed | Actually |
|---|---|
| SPI = shipping point (`VSTEL`), or a mis-transcription of SCPI | **Special Processing Indicator**, `SDABW`, a delivery item field |
| `ZLETSPIMAP` maps storage location → SPI | **Valid combinations.** One storage location permits several |
| Brand/grade are classification characteristics (class type 022) | Plain material group fields `MVGR3`/`MVGR2` |
| Client uses SAP Document Compliance **or** DigiGST | **Both.** SAP handles document lifecycle, DigiGST the India statutory layer |
| MRN relates to Gate Entry (`ZDACE_GE_MIGO`) | **In-transit quantity** on plant→depot movement, dispatched − received |
| Material documents are `MKPF`/`MSEG` | **`MATDOC`** on S/4HANA |
| The client Z-reports can be wrapped as services | T-codes are report programs — **but a CDS view and an RFC-enabled FM sit underneath them.** Look past the transaction to what it calls |
| Landscape is two-system DEV→PRD (vendor spec) | **Three systems**: DS4 / QS4 / PS4 |
| "S/4HANA means released APIs are available" | Available in the product, **not activated** on this Gateway |

---

## 11. What would invalidate this document

- DEV access — converts design intent into buildable fact
- Arrival of the BRD or CPI workbook — never supplied
- An answer to Q-037 or Q-038 — either changes SAP scope materially
- A decision on Q-046 (SEGW vs RAP) — changes every service's construction
- Formal design handoff — the 3 Aug UI review was explicitly **not** final
