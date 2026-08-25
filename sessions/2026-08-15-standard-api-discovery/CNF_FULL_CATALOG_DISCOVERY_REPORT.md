# CNF full-catalogue candidate discovery — all 2,626 SEGW projects

**Date:** 2026-08-15
**System:** QS4 / client 700
**Method:** offline. No SEGW project was opened for this audit.
**Supersedes:** the `API_*`-only reduction as the *discovery* boundary. It does **not** supersede any completed deep dive.

---

## 1. Why this audit exists

The earlier reduction ran `2,626 → 214 API_* → 32 keyword hits → 15 candidates`. That is a sound high-confidence pass, but it filtered on the `API_*` prefix **before** asking the business question. SAP ships integration-relevant Gateway projects under many other prefixes.

This audit reverses the order: build the demand vocabulary from v1.7 first, then screen **every** project name and description, then reject semantically.

**Headline result:** the `API_*` filter was hiding the answer to the question that matters most operationally. Of the CNF-relevant `API_*` A2X services, **exactly one is registered in QS4** (`API_SALES_ORDER_SRV`). Meanwhile **twelve non-`API_*` projects that are registered and callable today** map onto CNF business operations — including *Create Outbound Delivery*, *Material Document* and *Create Customer Invoices*.

---

## 2. Demand baseline

### 2.1 Provenance check

The user supplied a second path to the v1.7 workbook, in a Codex worktree. Both files were hashed:

| Copy | SHA-256 | Bytes |
|---|---|---:|
| `sources/SRC-DOC-20260815-01_..._v1.7.xlsx` | `41E67DA30B152F11D25B0315CDD247D7BABB5CC0EC557AE3CA6DEA782311C5A6` | 42,850 |
| `.codex/worktrees/2a63/.../019ff55e-v17-check-migo-removal/...v1.7.xlsx` | `41E67DA30B152F11D25B0315CDD247D7BABB5CC0EC557AE3CA6DEA782311C5A6` | 42,850 |

Byte-identical. The handover's "copied byte-for-byte" claim is verified, and the two paths are the same artifact.

All thirteen sheets were extracted (Overview + API-01…API-12) — the full request/response field contract, not just the Overview row.

### 2.2 What the workbook changed versus the handover summary

Reading the sheets rather than the summary produced three corrections that directly affect candidate selection:

1. **API-01 posts "goods receipt against an outbound delivery"** and makes `Allocations[].StorageLocation` + `Allocations[].Quantity` **mandatory**, with `MaterialDocument` + `MaterialDocumentYear` **mandatory** in the response.
2. **API-07 is not an invoice-cancellation or credit-memo operation.** The sheet states it corrects "only the editable Part A/Part B transport details for an existing invoice" and adds, in terms: it is not a generic billing cancellation or credit-memo API. This **answers the Finance gate** the handover left open for `API_CREDIT_MEMO_REQUEST` and `API_DEBIT_MEMO_REQUEST`.
3. **API-05 requires `StockAgeingDays`** at material × storage-location grain — a requirement neither raw-stock nor ATP candidate obviously satisfies.

### 2.3 Root-directory sources that contributed business context

| Source | Contribution |
|---|---|
| `sources/SRC-DOC-20260815-01_..._v1.7.xlsx` | The demand baseline: 12 business operations, full field contracts, mandatory/optional/derived necessity |
| `DOMAIN_GLOSSARY.md` | SAP object vocabulary: `LIKP`/`LIPS`, `MATDOC` (`MBLNR`/`MJAHR`), `EKKO`/`EKPO`, `T001L`, `VTTK-VSART`, `MFRGR`; and the decisive statement that **DigiGST is not SAP DRC**, with E-Way Bill numbers read from `/DIGIGST/OWARD_H-EWBNUMBER` |
| `SAP_API_DOSSIER.md` | Per-operation SAP candidates: `BAPI_GOODSMVT_CREATE`, `BAPI_OUTB_DELIVERY_CREATE_SLS`/`_STO`, `BAPI_OUTB_DELIVERY_CHANGE`, `BAPI_MATERIAL_AVAILABILITY` vs `MARD`/`MCHB`, `BAPI_SHIPMENT_CREATE` (LE-TRA only), `BAPI_SHIPMENTCOST_CREATE`, `BAPI_BILLINGDOC_CREATEMULTIPLE` |
| `SYSTEM_OF_RECORD_MATRIX.md` | Which reads must be live S/4 (stock availability, shipment cost estimate) versus served from T1/Datasphere — this narrows what actually needs an SAP API |
| `HANDOVER_SEGW_CANDIDATE_DEEP_DIVES.md` | The existing 15-candidate hypothesis, the rejected false positives, and the read-only protocol |

### 2.4 The dictionary

**`CNF_BUSINESS_SEARCH_DICTIONARY.tsv` — 125 rows, 12 business APIs, 110 positive terms, 15 negative terms.**

Term types: `BusinessTerm`, `Synonym`, `Abbreviation`, `SAPObject`, `SAPTable`, `SAPTransaction`, `SAPBapi`, `ModulePrefix`, `Namespace`, `NegativeKeyword`. Negative terms are recorded per business API, so a hit on `CREDIT MEMO` under API-07 is flagged as evidence *against* the candidate rather than for it.

---

## 3. How all 2,626 projects were screened

`tmp/screen_segw_catalog.ps1` matches every dictionary term against `Project + Description` for all 2,626 rows. No prefix filter.

### 3.1 A matching defect found and fixed mid-audit

The first pass used naive substring matching and produced **888 raw matches across 530 projects** — badly inflated. `EWAY` was matching the word "Gat**eway**", which appears in roughly a hundred SAP project descriptions. `EDOC` matched "CHANG**EDOC**", `GST` matched "OR**GST**RUCT", `DRC` matched "**DRC**T".

The fix normalises separators (`_`, `/`, `-` → space) and requires a token boundary on both sides. `EDOC_DCC`, `FDP_GST_INV_GLO_IN` and `/SCMTMS/GENERAL` still match; "Gateway" no longer does.

| Pass | Raw matches | Distinct projects | API-06 hits |
|---|---:|---:|---:|
| Naive substring | 888 | 530 | 109 |
| Token boundary | **737** | **415** | **18** |

### 3.2 Screen result

| Metric | Value |
|---|---:|
| Catalogue rows screened | 2,626 |
| Terms applied | 109 |
| Raw match rows | 737 |
| Distinct projects hit | 415 |
| — of which `API_*` | 35 |
| — of which **non-`API_*`** | **380** |

A keyword hit is not a candidate. All 415 were reviewed against project name, description, SAP module and the v1.7 business object before anything entered the register.

---

## 4. Results per business API

`CNF_FULL_CATALOG_CANDIDATE_REGISTER.tsv` — **77 rows**: 18 Tier A, 14 Tier B, 16 Tier C, 26 rejected, 3 outside-SEGW gaps. 41 distinct projects retained.

### API-01 Submit MIGO

Retained: `API_MATERIAL_DOCUMENT` (Tier A, deep dive complete), **`MMIM_GR4PO_DL`** (Tier A, new), **`MMIM_MATDOC`** (Tier A, new, registered), `API_INBOUND_DELIVERY_0002` (Tier B), plus `MMIM_MATDOC_OV` and `MMIM_GR_CANCELLATION` as Tier C.

`MMIM_GR4PO_DL` — "oData Service Goods receipt Purchase Order/Del." — is the single most on-point description in the catalogue for API-01: goods receipt against **either** a purchase order **or** a delivery, which is precisely the reference ambiguity open item ID-1 is about. It was invisible to the `API_*` filter.

### API-02 Create DI

Retained: `API_OUTBOUND_DELIVERY_0002` (Tier A), **`LE_SHP_OD_CREATE`** (Tier A, new, **registered**), **`LE_SHP_QC_DLVREF`** (Tier A, new, **registered**), `LE_SHP_DELIVERY_CREATE` (Tier B), `API_SALES_ORDER` (Tier B, registered).

Rejected: `LE_SHP_QC_DLVNOREF` — v1.7 API-02 always creates from a predecessor, so a no-reference create is the wrong operation.

### API-03 Create Invoice / Billing Documents

Retained: **`SD_CUSTOMER_INVOICES_CREATE`** (Tier A, new, **registered**), `API_BILLING_DOCUMENT` (Tier A), `SD_CUSTOMER_INVOICES_MANAGE` (Tier B, registered), `LE_SHP_DELIVERY_PICK` (Tier B), `API_OUTBOUND_DELIVERY_0002` (Tier A, supplies picking/batch-split/PGI), plus `SD_BILLINGDOC_PROCFLOW` and `SD_BIL_DOC_LIST_MANAGE` as Tier C.

The handover treated **billing creation as a gap** on the grounds that the OData V2 A2X billing service is read/cancel/PDF only and creation exists just on the V4 successor. `SD_CUSTOMER_INVOICES_CREATE` is a registered, live project literally named *Create Customer Invoices*. That does not close the gap — it is a Fiori application service, not an A2X API — but the gap can no longer be asserted without testing it.

### API-04 Shipment Calculation — **GAP**

No candidate. Direct probes across all 2,626 projects: `SHIPMENTCOST` = 0, `FREIGHT COST` = 0, `TRANSPORT COST` = 0, `VFK` = 0, `LE_TRA` = 0. The only `SHIPMENT` hits are TSW (oil-and-gas Trader's and Scheduler's Workbench) and EHS safety-data-sheet monitoring. `/SCMTMS/` and `TM_*` projects are TM freight-order/agreement/tendering objects, re-confirmed as rejections.

`SD_PRICING_CONDITIONRECORD` is retained Tier C only because v1.7 API-04 returns a `ConditionRecord` for traceability — relevant only if freight is priced through SD conditions.

### API-05 Stock Availability

Retained: `API_MATERIAL_STOCK` (Tier A), `API_PRODUCT_AVAILY_INFO_BASIC` (Tier A comparator), **`MMIM_STOCKINDATERANGE`** (Tier A, new), `API_PHYSICAL_INVENTORY_DOC` (Tier B), `MMIM_MATERIAL_OVERDUE_SIT` (Tier B, new), plus `MM_IM_PHYS_INV_DOC`, `MMIM_DEADSTOCKMATERIAL`, `MMIM_SLOWORNONMOVINGMATERIAL` as Tier C.

`MMIM_STOCKINDATERANGE` ("Analyze Stock in Date Range") is promoted specifically because **v1.7 requires `StockAgeingDays`** and neither A2X stock candidate obviously provides it. This is a requirement-driven promotion, not a name match.

### API-06 E-Way Bill Extension — **GAP**

Confirmed across the full catalogue, not just `API_*`. Direct probes: **`DIGIGST` = 0 hits**, `EWB` = 0, `E_WAY` = 0, `IRN` = 0. The only `WAYBILL` hits are European TM rail/road output forms. All India `EDOC`/`GST` projects are form data providers or subcontracting-challan services.

`EDOC_DCC` remains rejected as an extension command while staying valuable as landscape evidence: it is **registered as `EDOC_DCC_SRV`**, proving the SAP eDocument framework is installed and active in QS4.

### API-07 Invoice Correction — **GAP**

No SEGW project addresses E-Way Bill Part A/Part B correction. Every `CORRECTION` hit is a Russian FI correction-invoice form provider (`FDP_*_RU`), plus a Fiori stock-correction app.

**`API_CREDIT_MEMO_REQUEST` and `API_DEBIT_MEMO_REQUEST` are removed from the shortlist.** The v1.7 API-07 sheet excludes the credit/debit-memo model in its own words. This is `BUSINESS-DEMAND` evidence, which outranks the name similarity that put them on the list.

### API-08 STO Orders

Retained: **`MMIM_STO`** (Tier A, new — literally "Stock Transfer Orders"), `API_PURCHASEORDER_PROCESS` (Tier A), `ME2STAR_ODATA` (Tier B, new), `MM_PUR_POITEMS_MONI` (Tier C, registered).

Rejected: `MM_PUR_CNTRL_PO_MAINTAIN` — Central Procurement operates across connected systems; CNF is single-system intra-company.

### API-09 STO Deliveries

Retained: `API_OUTBOUND_DELIVERY_0002` (Tier A), `LE_SHP_OD_LIST` (Tier B, new), `LE_SHP_OUTBOUND_DELIVERY_FS` and `LE_SHP_DELIVERY_WORK_LIST` (Tier C).

### API-10 STO Invoice

Retained: `API_BILLING_DOCUMENT` (Tier A), `API_SUPPLIERINVOICE_PROCESS` (Tier B), **`LO_GST_INB_INV_CREATE`** (Tier B, new), `SD_CUSTOMER_INVOICES_MANAGE` (Tier C).

`LO_GST_INB_INV_CREATE` ("Create GST Inbound Invoice") materially widens the hard gate. The handover framed the STO-invoice question as SD billing **versus** MM supplier invoice. There is a third India-specific GST invoice object in the catalogue, and it was never screened.

### API-11 Create STO Purchase Order

Retained: `API_PURCHASEORDER_PROCESS` (Tier A), **`MM_PUR_PR_PROCESS`** (Tier B, new, **registered**), `MM_PUR_PO_MAINTAIN` and `MM_PUR_PO_MAINTAIN_V2` (Tier B, new sibling pair).

`MM_PUR_PR_PROCESS` is promoted above a keyword hit because v1.7 API-11 captures a mandatory `RequisitionNumber` — so a purchase requisition may be a real part of this flow rather than a free-text field.

### API-12 Update DI Quantity

Retained: `API_OUTBOUND_DELIVERY_0002` (Tier A), `LE_SHP_DELIVERY_WORK_LIST` (Tier C).

---

## 5. Reconciled shortlist — what changed

The original 15 are **not discarded**. Every one is accounted for:

| Original candidate | New status | Change |
|---|---|---|
| `API_OUTBOUND_DELIVERY_0002` | Tier A for API-02/03/09/12 | retained, scope widened |
| `API_OUTBOUND_DELIVERY` | Tier C | demoted to sibling baseline |
| `API_INBOUND_DELIVERY_0002` | Tier B | demoted — deep dive showed it cannot satisfy API-01 alone |
| `API_INBOUND_DELIVERY` | Tier C | demoted to sibling baseline |
| `API_MATERIAL_DOCUMENT` | Tier A | retained, deep dive complete |
| `API_MATERIAL_STOCK` | Tier A | retained |
| `API_PRODUCT_AVAILY_INFO_BASIC` | Tier A | retained as explicit comparator |
| `API_PURCHASEORDER_PROCESS` | Tier A for API-08/11 | retained |
| `API_BILLING_DOCUMENT` | Tier A for API-03/10 | retained |
| `API_SALES_ORDER` | Tier B | retained; note it is the only registered `API_*` |
| `API_PHYSICAL_INVENTORY_DOC` | Tier B | retained, still gated |
| `API_SUPPLIERINVOICE_PROCESS` | Tier B | retained, still gated |
| `API_BILLING_DOCUMENT_REQUEST` | **REJECTED** | confirmed not an invoice-creation or invoice-read substitute |
| `API_CREDIT_MEMO_REQUEST` | **REJECTED** | v1.7 API-07 excludes the credit-memo model |
| `API_DEBIT_MEMO_REQUEST` | **REJECTED** | same demand-evidence exclusion |

**29 new candidates added**, all non-`API_*`. Twelve are already registered in QS4.

### 5.1 The registered-service finding

| Project | Registered as | Serves |
|---|---|---|
| `LE_SHP_OD_CREATE` | `LE_SHP_OD_CREATE_SRV` | API-02 |
| `LE_SHP_QC_DLVREF` | `LE_SHP_QC_DLVREF_SRV` | API-02 |
| `MMIM_MATDOC` | `MMIM_MATDOC_SRV` | API-01 |
| `MMIM_MATDOC_OV` | `MMIM_MATDOC_OV_SRV` | API-01 |
| `SD_CUSTOMER_INVOICES_CREATE` | `SD_CUSTOMER_INVOICES_CREATE` | API-03 |
| `SD_CUSTOMER_INVOICES_MANAGE` | `SD_CUSTOMER_INVOICES_MANAGE` | API-03, API-10 |
| `SD_BIL_DOC_LIST_MANAGE` | `SD_BIL_DOC_LIST_MANAGE_SRV` | API-03 |
| `SD_BILLINGDOC_PROCFLOW` | `SD_BILLINGDOC_PROCFLOW_SRV` | API-03 |
| `SD_SOFM_DELIVERY` | `SD_SOFM_DELIVERY_SRV_01` | API-02 |
| `MM_PUR_PR_PROCESS` | `MM_PUR_PR_PROCESS_SRV` | API-11 |
| `MM_PUR_POITEMS_MONI` | `MM_PUR_POITEMS_MONI_SRV` | API-08 |
| `SD_PRICING_CONDITIONRECORD` | `SD_PRICING_CONDITIONRECORD_SRV` | API-04 |
| `API_SALES_ORDER` | `API_SALES_ORDER_SRV` | API-02 |

**This must not be over-read.** Registered is not the same as suitable. These are Fiori *application* services: UI-facing, frequently draft-enabled, not released as A2X integration APIs, and SAP does not guarantee their contract stability. An unregistered A2X service with the right semantics may still be the correct answer, with activation as the cost — handover §5 Gate 5 is explicit about that, and nothing here overturns it.

What the finding does change is the **shape of the question for Basis**. It is no longer "activate these A2X services". It is "here are services already live that touch these objects, and here are A2X services that would need activation — which combination does the client want to own?"

---

## 6. Discovery status is not technical proof

Every retained row carries only these claims:

| Established | Not established |
|---|---|
| A SEGW project exists in QS4 | Its design-time surface (except the four already extracted) |
| SAP created it | That SAP publishes it as a released API |
| Name/description indicate business relevance | That it applies to S/4HANA 2022 on-premise |
| Registration status in the 522-row catalogue | That the ICF node / system alias is active |
| | That it covers any v1.7 operation |
| | Whether Basis activation is required or approved |

The register's `RequiredOperationFitAtDiscovery` column is deliberately `UNKNOWN` for every newly discovered project. Nothing has been proven about them beyond name, description, creator, date and registration.

---

## 7. Sibling families requiring delta analysis

| Family | Members | Status |
|---|---|---|
| Outbound delivery | `API_OUTBOUND_DELIVERY` / `_0002` | delta complete |
| Inbound delivery | `API_INBOUND_DELIVERY` / `_0002` | delta complete |
| MM_PUR PO maintain | `MM_PUR_PO_MAINTAIN` / `_V2` | **delta required if pursued** |
| MMIM MATDOC | `MMIM_MATDOC` / `MMIM_MATDOC_OV` | not a version pair; different purpose |
| LE_SHP delivery creation | `LE_SHP_OD_CREATE`, `LE_SHP_QC_DLVREF`, `LE_SHP_DELIVERY_CREATE`, `LE_SHP_QC_DLVNOREF` | **three-way comparison required** |
| SD customer invoices | `SD_CUSTOMER_INVOICES_CREATE` / `_MANAGE` | create vs manage split |
| Physical inventory | `API_PHYSICAL_INVENTORY_DOC` / `MM_IM_PHYS_INV_DOC` | A2X vs Fiori twin |

---

## 8. Business processes with no credible SEGW candidate

| v1.7 operation | Status | What to investigate instead |
|---|---|---|
| **API-04 Shipment Calculation** | `OUTSIDE-SEGW-GAP` | Answer classic LE-TRA vs TM vs external engine first; then `BAPI_SHIPMENTCOST_CREATE` or pricing simulation. No OData path exists in this system. |
| **API-06 E-Way Bill Extension** | `OUTSIDE-SEGW-GAP` | DigiGST/EY integration. Zero `/DIGIGST/` SEGW projects; `/DIGIGST/OWARD_H-EWBNUMBER` is the known persistence point. |
| **API-07 Invoice Correction** | `OUTSIDE-SEGW-GAP` | Same statutory interface as API-06 — Part A/Part B update operations at the provider. |

All three were suspected by the handover. They are now **proven across the full catalogue** rather than inferred from an `API_*` subset.

---

## 9. Ranked deep-dive queue

Ordering rationale: resolve requirements with a single decisive unknown first; prefer candidates whose result changes an architecture or activation decision; treat registered services as cheap to validate.

| # | Target | Business API | Why now |
|---:|---|---|---|
| 1 | `API_MATERIAL_STOCK` + `API_PRODUCT_AVAILY_INFO_BASIC` + `MMIM_STOCKINDATERANGE` | API-05 | Three-way, one sitting; settles raw-vs-ATP **and** the `StockAgeingDays` requirement that currently has no owner |
| 2 | `MMIM_GR4PO_DL` + `MMIM_MATDOC` | API-01 | Directly addresses the GR-reference ambiguity; `MMIM_MATDOC` is registered, so cheap |
| 3 | `LE_SHP_OD_CREATE` + `LE_SHP_QC_DLVREF` + `LE_SHP_DELIVERY_CREATE` | API-02 | Two are registered; decides whether API-02 needs any activation at all |
| 4 | `API_PURCHASEORDER_PROCESS` + `MMIM_STO` | API-08, API-11 | Covers two operations; `MMIM_STO` is the closest-named project in the catalogue |
| 5 | `SD_CUSTOMER_INVOICES_CREATE` + `API_BILLING_DOCUMENT` | API-03 | Tests the declared billing-creation gap against a registered service |
| 6 | `API_SALES_ORDER` | API-02 | Only registered `API_*`; validates the A2X activation assumption end-to-end |
| 7 | `LO_GST_INB_INV_CREATE` + `API_SUPPLIERINVOICE_PROCESS` | API-10 | Only after the STO-invoice document-model gate is answered |
| 8 | `API_PHYSICAL_INVENTORY_DOC` + `MM_IM_PHYS_INV_DOC` | API-05 | Only if PI posting is confirmed in scope |
| 9 | `MM_PUR_PR_PROCESS`, `MM_PUR_PO_MAINTAIN` / `_V2` | API-11 | Only if the A2X PO service cannot create the client STO type |

Deferred: all Tier C rows; `API_OUTBOUND_DELIVERY` and `API_INBOUND_DELIVERY` baselines (complete); the three outside-SEGW gaps (not SEGW work).

**Outstanding from completed extraction:** `API_OUTBOUND_DELIVERY_0002` has full design-time evidence and a sibling delta but **no v1.7 coverage report** for API-02, API-03, API-09 or API-12. That is a writing task with no SAP access needed and should be cleared before new extractions.

---

## 10. Open functional gates

None of these can be answered by inference, and several block dispositions rather than extractions.

| Gate | Blocks | Owner |
|---|---|---|
| **ID-1** Does the QS4 STO flow create an inbound delivery at the receiving depot, and is the GR posted against the STO PO, an inbound delivery, or the dispatching outbound delivery? | API-01 disposition; inbound-delivery family role | MM / configuration |
| **STO invoice object** SD billing, intercompany billing, India GST stock-transfer, or MM supplier invoice? | API-10 entirely | SD / MM / FI |
| **Stock meaning** raw SLoc/batch stock, ATP, or both as separate views? And what is the authoritative source of `StockAgeingDays`? | API-05 | MM / Product |
| **Shipment model** classic LE-TRA, TM, or external engine? | API-04 | LE / architecture |
| **Statutory interface** which DigiGST/EY operation owns E-Way extension and Part A/Part B correction? | API-06, API-07 | Tax / CPI |
| **Fiori-service suitability** are registered Fiori application services acceptable as integration endpoints, or is A2X-released status mandatory? | All twelve registered candidates | Architecture |
| **STO document type** is `ZP06` correct, and what item category / plant mapping applies? | API-08, API-11 | MM |
| **Requisition** is v1.7 `RequisitionNumber` an SAP purchase requisition or a free-text reference? | API-11 | MM / Product |

The **Fiori-service suitability** gate is new and is the most consequential thing this audit surfaced. It determines whether roughly a third of the retained candidates are usable at all.

---

## 11. Artifacts

| File | Rows | Purpose |
|---|---:|---|
| `CNF_BUSINESS_SEARCH_DICTIONARY.tsv` | 125 | v1.7 demand vocabulary, positive and negative terms |
| `CNF_FULL_CATALOG_CANDIDATE_REGISTER.tsv` | 77 | Post-review candidates, rejections and gaps |
| `CNF_FULL_CATALOG_DISCOVERY_REPORT.md` | — | This report |
| `tmp/cnf_screen_raw_matches.tsv` | 737 | Raw screen output before semantic review |
| `tmp/build_cnf_search_dictionary.ps1` | — | Rebuilds the dictionary |
| `tmp/screen_segw_catalog.ps1` | — | Re-runs the full screen |
| `tmp/build_cnf_candidate_register.ps1` | — | Rebuilds the register |

`CNF_DEEP_DIVE_SHORTLIST.md` is **preserved unchanged** as the original hypothesis. This report is the reconciliation on top of it.

No `.xlsx` has been produced. The final workbook comes after the deep dives, organised by v1.7 business API.
