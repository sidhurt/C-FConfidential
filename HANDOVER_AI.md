# Handover — Current-State Briefing

**Version:** 5.0 · **Date:** 2026-08-15
**Supersedes:** v4.1. Adds the unrestricted 2,626-project catalogue, completed Tier-A deep dives, the standard-first solution map and the runtime-proof gate.
**Status:** Current briefing. Where an older section conflicts with §0, §0 wins.

---

## 0. Standard-first correction — read before every older section

- QS4 has **2,626 SEGW design-time projects** and a separate **522-service registered Gateway catalogue**. The six projects inspected on 5 August were not the complete surface; D-028 is superseded on that claim.
- The custom `ZCNF_*` portfolio is not the current implementation plan. Five released candidates lead the transactional core: `API_MATERIAL_DOCUMENT_SRV`, `API_OUTBOUND_DELIVERY_SRV;v=2`, `API_BILLING_DOCUMENT_SRV`, `API_PURCHASEORDER_PROCESS_SRV`, and `API_MATERIAL_STOCK_SRV`.
- None of those five is registered in the observed QS4 catalogue. “Exists,” “registered,” “returns `$metadata`,” and “completes the business transaction” are separate proof levels.
- Registered Fiori services are not automatic substitutes. The Tier-A evidence rejects `LE_SHP_OD_CREATE`, `LE_SHP_QC_DLVREF`, and `MMIM_STO` for the target operations. `SD_CUSTOMER_INVOICES_CREATE` is a genuine but conditional internal billing-create route; `MMIM_MATDOC_SRV` is a read-back complement.
- The current implementation and test plan is `deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md`. Material evidence lives in `sessions/2026-08-15-standard-api-discovery/`.

---

## 1. Navigate

The repository was consolidated on 2026-08-07 from 29 root files to 15. Everything retired is in `_archive/` with a note saying what replaced it. **Never reason from `_archive/`.**

| Register | Holds | IDs |
|---|---|---|
| `PROJECT_BRAIN.md` | The mental model, the four systems, who owns what, live conflicts | `C-nn` |
| `DECISION_LOG.md` | Decisions and established facts | `D-001`..`D-038` |
| `OPEN_QUESTIONS.md` | What is unresolved, and who owns it | `Q-001`..`Q-057` |
| `DOMAIN_GLOSSARY.md` | What the client's terms actually mean | — |
| `MEETING_INGEST.md` | Source index | `SRC-*` |
| `SYSTEM_OF_RECORD_MATRIX.md` | Which system owns which data | — |

`deliverables/` is client-facing output. `sources/` is primary evidence. `API-01`..`API-10` live in `deliverables/API_SPECIFICATION_PROPOSAL.md` and the request/response workbook.

**Evidence tiers, higher overrides lower:** (1) system observation from QS4 · (2) client documents · (3) direct statement from Siddharth, tagged `SRC-SID-*` · (4) meeting transcript, secondhand and ASR-noisy.

---

## 2. The project in one page

A new operational portal for Shree Cement's C&F agents — roughly 600 users across 35+ depots — over existing SAP dispatch processes.

**Two current user journeys.** The 10 Aug KT frames the immediate work as inbound receipt (Pending MRN → storage-location allocation → Submit MIGO) and outbound trade/non-trade fulfilment (T1 order → Create DI → batch/shipment → invoice/e-documents). STO creation is being sequenced later; this is not yet signed scope.

The outbound operational spine is:

```
Sales Order / STO → Delivery ("DI") → one storage location, 1..n batches
  → transporter · route · freight → PGI · shipment · shipment cost · billing
  → e-Invoice (IRN) · E-Way Bill → status · download → correction · extension
```

Adjacent: warehouse-to-warehouse STO creation, physical inventory reconciliation, reports and dashboard/notification surfaces.

**The central thesis, unchanged and still correct:** *a BAPI will not repair a semantically wrong payload.* A technically valid call carrying a business value that means the wrong thing posts successfully, errors nothing, and surfaces weeks later as wrong stock or a disputed invoice. The KDS catalogue largely closes reference-data semantics; the BRD/field-lineage gap and C-14 show that process payload semantics are still open.

---

## 3. Landscape — verified

**Backend (D-018).** S/4HANA 2022 on-premise, ABAP Platform 2022, HANA 2.00.087, Fiori FES 2022 SP04. Three systems: **DS4** (dev) · **QS4** (quality) · **PS4** (production), confirmed independently by the TMS destinations. Work processes are throttled to 6 in DS4 versus 15 in QS4/PS4 — **any performance measured in DEV is ~2.5× pessimistic.**

**Commerce (D-027).** "T" = Terminal. **T1** is the existing *Udaan* Hybris instance — order booking and aggregation between clients, customers and supply-chain logisticians. **T2** is the CNF portal being built: aggregates from T1, applies sourcing logic, lands orders in S/4, and holds a persistent store of recurring SAP/DSP/T1 data. Both are Hybris instances of the Udaan estate.

**Integration (D-034).** CPI is confirmed present — destinations `CPI_IDOC` ("IDOC Connection to CPI"), `CPI_OVS`, `CPI_WB`. An IDoc channel already exists alongside whatever OData carries. A BTP connection exists (`ADS` on SCP).

**Statutory (D-023, D-035).** Both frameworks are live. SAP's eDocument framework is installed (`EDOC_COCKPIT`, `EDOCUMENT`, `ZEDOC_DCC_SRV` registered) and **DigiGST** — published by EY — supplies the India layer. Roughly **50 `EY_*` HTTP destinations** already cover e-Invoice generate/cancel and E-Way Bill generate/cancel/extend/Part-B/multi-vehicle/consolidate.

**Analytics (D-038).** SAP → Datasphere replication is live: extraction-enabled ABAP CDS views → ODP delta queue → HANA Smart Data Integration → tenant `DWCTZ8YIB`, connection `SAP_S4_QA`. Currently replicating billing header (`ZVBRK_CDS_DW`, active) and customer master (`ZKNA1_CDS_VW`, idle). Vehicle master (`ZLETVEHICLECDSDW`) is built and extraction-enabled but **not yet subscribed**.

**Also present, previously unmentioned by anyone:** a BW system (`QS4CLNT500`), EWM (`S4HEWMQ*`), and CIF connections.

**Gateway.** Deny-by-default. The 522-row registered catalogue is materially smaller than the 2,626-project design-time catalogue. The five leading released services—including `API_PURCHASEORDER_PROCESS_SRV`—are absent from the observed registration and need DEV provisioning plus runtime proof (Q-045/Q-067). Embedded vs hub remains unconfirmed (Q-002).

**Option C (D-014)** is the selected data-integration pattern: orders, deliveries and invoices served live from T1 via OCC; Pending MRN and STO List DSP→T2 every 15 min; stock ageing and masters daily. It removes most read APIs from SAP scope and leaves write commands plus two real-time reads.

---

## 4. The ABAP role

**Owns:** SAP source selection and document execution · released API/BAPI choice · ABAP classes and SEGW/RAP services · locking, commit policy, idempotency, correlation · the API error contract.

**Does not own:** business rules and document semantics (SD/MM) · iFlows (CPI team) · Datasphere models (DSP team) · landscape, roles, destinations, service activation (Basis) · portal behaviour (Commerce) · functional sign-off.

Full map in `PROJECT_BRAIN.md` §Who owns what.

**The standing risk is unowned work at boundaries.** `ZCRM_STAGEGATE_SRV` proves a pull-shaped progression path. A 10 Aug meeting separately claims an existing trigger-shaped SAP→CPI→T1 full-document projection. They may coexist, but the latter is not named or observed; Q-037 now asks for both paths' identities, owners, payloads, retry and latency. Two further SAP-side gaps remain outside the estimate: **Datasphere extraction views** (Q-053) and **ILMS ownership** (Q-054).

---

## 5. Verified knowledge base

### 5.1 The first six registered CNF-adjacent services (D-028, completeness claim superseded)

These six SEGW projects were the first registered CNF-adjacent surface inspected. Five are custom, all originating in DS4 from the IBM ABAP pool. They are useful precedent, but **not** the complete catalogue; D-056 records the later 2,626-project export.

| Service | What it is |
|---|---|
| `ZCRM_STAGEGATE_SRV` | **The stage-gate model.** 6-field composite key → `deliveriesItems`, 32 fields |
| `ZCRM_SO_REJECT_SRV` | T1 **writes into** S/4 — order-item rejection (`Vbeln`, `Posnr`, `Abgru`, `Msg`) |
| `ZCUSTOMER_DETAIL_SRV` | Customer master to CPI. `LastUpdateDate` → delta-pull |
| `ZAPI_PLANT_WEIGHBRIDGE_RMC_SRV` | Material master feed to the RMC weighbridge system |
| `ZMM_SCRUM_SER_PO_SRV` | Service POs from an external system |
| `API_SALES_ORDER_SRV` | The one SAP-delivered service; SADL/CDS, approval function imports |

**None of the six implements any of API-01..API-10.** They supply pattern, correlation keys and precedent — not implementations.

### 5.2 What the implementation classes revealed

Three `*_DPC_EXT` classes read in full (`SRC-CODE-20260805-01`). The highest-yield source in the project.

- **Generic CRUD nodes prove nothing (D-029).** `ZCRM_SO_REJECT` shows five operations in the SEGW tree and implements **two**.
- **An API-06-shaped orchestration already exists (D-030).** `ZMM_SCRUM_SER_PO` runs `BAPI_PO_CREATE1` → `BAPI_ENTRYSHEET_CREATE` → `BAPI_INCOMINGINVOICE_PARK` behind one OData call, three documents, three commits, with process state in Z-table `zmm_scrum_ser_po`. **No compensating rollback; the final invoice commits without checking success.** The sequencing was never the hard part.
- **Nothing is idempotent (D-031).** No write API carries a request ID or replay guard. `ZCRM_SO_REJECT` is safe by accident — setting a rejection reason is a state-set. `BAPI_PO_CREATE1` is not.
- **`ZCRM_STAGEGATE` is a read wearing a POST (D-032).** `create_deep_entity`, writes nothing. POST because OData V2 GET can't carry a compound key. **This is the house pattern for composite reads.**
- **Stage gates come from ILMS, not SAP (D-033).** `ZLETILMSDELIVERY` / `ZLETILMSTOKEN` / `ZLETILMSTRANS`, with a `stageid` field. Fallback path reads `LIKP-ZZVEHICLE_NO` and `LIKP-ZZDRIVERMOB` and the forwarding agent from `VBPA` partner function `SP`.
- **No authorization check anywhere — four of four (D-036).** Empty `auth_check` FORM, `#NOT_REQUIRED` on the CDS view, no `AUTHORITY-CHECK` in either DPC_EXT. `ZLE_PLNT` (D-024) is the exception, not the rule.

### 5.3 Source-verified from the SE38 reports (`SRC-CODE-20260804-01`)

- **Pending MRN = invoiced minus goods-received, per delivery** (D-021). Base view `zsd_mrn_pending_cds_opt`, plus `zle_di_inv_details` and `zle_mrn_goods_reciet_cds`. Derived — stored nowhere.
- **Goods receipts must match on `VBELN_IM`, not `EBELN` alone** — production defect `SR/ME/45764`, Sept 2025, when one PO had several deliveries.
- **`ZSD_PENDING_ORDER_FM` is RFC-enabled** (D-022) — directly callable. Its caller is a parallel-RFC job slicing one task per day with a **1200-second wait ceiling**, and an **empty authorization check**.
- **The quantity chain is seven steps** (D-026): contract (`ZMENG`) → order → schedule → delivery → invoice → rejected → **balance (`BAL_QTY`)**. `D-001`'s `Order = DI + Pending` is a simplification.
- **`ZLETSPIMAP` is a valid-combinations table, not a determination table** (D-020). One storage location permits several SPIs; the determination rule doesn't exist (Q-044).
- **Vehicle and LR are Z-fields on the shipment header** (D-025), **and `ZZVEHICLE_NO` also exists on `LIKP`** (D-037).
- **E-Way Bill number reads from `/DIGIGST/OWARD_H-EWBNUMBER`** (D-023).

### 5.4 Document-verified (KDS catalogue, `SRC-DOC-20260803-02`)

Brand is `MVGR3`, grade `MVGR2`, product type `MVGR1`, pack type `MVGR4` — plain material groups, **not** classification characteristics (D-016). Trade/non-trade is on the material at `MVGR5` and separately on the customer at `KDGRP` (D-015). Storage-location codes, sales-area mappings (`TVKWZ`, `TVKBZ`), customer groups (`T151`) all documented in `DOMAIN_GLOSSARY.md`.

### 5.5 What the 10 Aug meetings add (Tier 4, not decisions)

- **Immediate command vs later read model.** Create DI and Submit MIGO are intended to return an S/4 identifier synchronously; delivery/invoice lists later reflect T1 and MIGO status later reflects DSP/T2.
- **MIGO classification and posting.** D-054 establishes the portal states: the list is cumulative receipt position; a Partial modal separates prior inward history from the new classification delta. Line values use 0.05-MT increments and their handled total cannot exceed displayed pending. D-052 resolves the STG/DMG semantics: both appear like storage-location buckets but are rejected/non-stock outcomes. They do not increase inventory and instead feed pending replacement goods for a later Order→DI→MIGO cycle. The API must therefore distinguish handled/classified quantity from GR-posted quantity. Exact pending-ledger destination, posting reference and returned identifier remain Q-066/Q-004/C-14.
- **Display stock is not transactional stock.** Dashboard/ageing can be stale/D-1; system batch determination must block unavailable stock (Q-014/Q-038).
- **Invoice status is explicitly multi-state.** Document Flow shows success/number, failure and Processing; Generated Invoices is success-only, so the failure/retry gap in Q-035 is real.
- **MRN terminology is now a live conflict (C-14).** The meetings offer three incompatible models; source-derived D-021 remains current.
- **The BRD exists outside this repository.** Team access is reported and it contains screen validations/returns. Obtain the controlled version as `SRC-BRD-001`.

---

## 6. The API model

The formal manager/team register contains **seven** T2→S/4 operations (D-047). The evidence-backed design workbook v1.6 expands this into workflow contracts, but those extra workflow IDs are not automatically separate SAP interfaces. `CAND-08` is explicitly a research appendix, not an approved endpoint (D-055/Q-063).

Legacy classification and effort totals must be recalculated only after the seven-formal-to-workbook mapping is approved.

Class **S** means the *business operation* is delivered by SAP — not that the work is zero. Protocol, authorization, idempotency, error shaping and logging sit on top of every API regardless.

**Where the effort actually is:**

- **API-06 invoice orchestration (25–35d).** Every stage is standard. The resumable, observable, idempotent process across four units of work and two external calls is not. A precedent exists (§5.2) and lacks exactly the parts that make it hard.
- **Current v1.7 API-04 shipment calculation (historically API-05, 12–18d estimate).** Standard shipment costing is document-bound. The catalogue has no credible SEGW candidate; validate `BAPI_SHIPMENT_COST_ESTIMATE` and the client's LE/TM configuration before building a narrow simulation endpoint. Create-then-reverse remains rejected.
- **Idempotency (NFR-01).** No standard SAP facility. Every command API depends on it. Most underestimated item in the set, and §5.2 proves it isn't done anywhere today.
- **API-01 and API-04 composites.** All underlying reads standard; the joined shape is not.

**Scope reduction found 2026-08-05:** Invoice/e-document correction and E-Way Bill extension can reuse destinations that already exist (`EY_CANCEL_EINV`, `EY_GENERATE_EINV`, `EY_EWB_EXT_CF`, `EY_EXTENDEWBVALIDITY`). The statutory client is not being built. Existing plumbing does not prove a separate portal-facing e-Invoice correction endpoint.

**Current evidence-backed deliverable:** `outputs/cnf_api_contract_v16/CNF_API_Request_Response_Specification_v1.6.xlsx`. API-07 is functionally aligned to the validated Figma; SAP identifier/type and cancel/regenerate mechanics remain open. The older `deliverables/` workbook is retained as provenance, not the current freeze candidate.

---

## 7. Open questions, ranked

| Rank | Q | Why it leads |
|---|---|---|
| 1 | **Q-032** | Invoice-chain latency, never measured. Decides whether API-06 is synchronous or submit-and-poll — the contract cannot be written without it. Two traced documents gave 21 seconds and 3 days |
| 2 | **Q-010 / NFR-01** | Nothing prevents duplicates today (D-031). Every command API depends on the answer |
| 3 | **Q-050** | No compensating rollback in the existing multi-stage orchestration. API-06 has the same shape |
| 4 | **Q-004 / C-14** | MIGO reference, multi-SLoc allocation and returned identifier are not semantically settled |
| 5 | **Q-037** | Identify the claimed SAP→CPI→T1 projection and distinguish it from stage-gate pull |
| 6 | **Q-038** | Stock availability for batch allocation appears nowhere in Option C |
| 7 | **Q-031** | DI predecessor by trade/non-trade/STO branch. STO is currently deferred |
| 8 | **Q-045 / Q-046** | Activate standard APIs; settle SEGW vs RAP |
| 9 | **Q-053 / Q-054** | Unowned SAP-side work: Datasphere extraction views, ILMS |
| 10 | **Q-006** | MIGO + fulfilment is only a working sequence; formal assignment/acceptance remains absent |

---

## 8. Live conflicts

| ID | Conflict |
|---|---|
| **C-11** | T2 as persistent store (D-027) versus Option C's direct-query design (D-014). The 4 Aug meeting contradicts itself within 35 minutes |
| **C-12** | STO/MRN source three ways — DSP→T2 per D-014, S4→T2 and DSP→T2 four minutes apart in the meeting, and no delta queue exists for either |
| **C-13** | Stage-gate scope in CNF — *"there is no such thing as a stage gate"* contradicted three minutes later, and by the existence of `ZCRM_STAGEGATE_SRV` |
| **C-14** | MRN identity/lifecycle — source code says derived Pending-MRN position; the 10 Aug meetings variously place MRN before MIGO, after MIGO, expand it as Movement Reference Number and expect it as an API response |
| **C-8** | Pickup code: disabled in FTP, or present only in FTP |
| **C-10** | `1000` / `1300` — sales organisations or company codes |

---

## 9. Beliefs held earlier that are now known wrong

Removed from the current documents. Listed here only so nobody re-derives them.

- SPI is a shipping point, or a transcription of SCPI — **no**, Special Procurement Indicator (D-025 area, Q-025).
- Brand and grade are classification characteristics — **no**, plain material groups (D-016).
- SAP Document and Reporting Compliance is the statutory framework — **no**, DigiGST/EY, alongside SAP's eDocument framework (D-017, D-023).
- The landscape is two systems, DEV→PRD, per the vendor spec — **no**, three (D-018).
- `ZLETSPIMAP` is a determination table — **no**, valid combinations only (D-020).
- Pending MRN derives from gate entry — **no**, invoiced minus received (D-021).
- Nothing exists on the S/4→T1 boundary — **no**, `ZCRM_STAGEGATE_SRV` serves it (Q-037).
- CPI is barely present in the architecture — **no**, three destinations including an IDoc channel (D-034). This was inference from one transcript; the destination list disproves it.
- Stage gates map onto the seven `VBFA` document hops — **no**, they are ILMS operational checkpoints (D-033).
- `E8H_000` indicates a hub Gateway — **no**, routinely present and insignificant (Q-049, closed).

---

## 10. What to do next

1. **Measure the invoice chain** (Q-032). Highest-value single action available. Trace real documents through `VBFA` and compare stage timestamps.
2. **Measure a single-slice call to `ZSD_PENDING_ORDER_FM`.** Determines whether the parallel wrapper is load-bearing for a narrow portal query.
3. **Ask Basis to activate the four A2X services in DEV** (Q-045) — may remove several custom builds from scope.
4. **Settle SEGW vs RAP** with the ABAP lead (Q-046) before any service is created.
5. **Name owners** for Q-053 and Q-054 before they default to the ABAP developer.
6. **Get Q-006 answered.** Ask every meeting.
7. **Obtain the approved BRD/Figma revision** and ingest `SRC-BRD-001`; team access now exists.
8. **Resolve Q-004/C-14 with MM/SD** before freezing Submit-MIGO request/response.
9. **Observe the claimed SAP→CPI→T1 projection** and record its object, trigger, payload, correlation and latency (Q-037).

---

## 11. What would invalidate this document

- Production (PS4) turning out to differ materially from QS4 (Q-052) — the structural findings would hold, line-level detail would not.
- Option C being replaced, which would reshape every read API.
- A decision to build on RAP rather than SEGW, which changes the service model but not the business findings.
- The approved BRD or CPI workbook being ingested. BRD access is reported among team members, but no controlled copy is held here; the CPI workbook remains absent.
