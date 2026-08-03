# C&F Agent Interface — SAP API Specification Proposal

**Document ref:** CNF-API-PROP-001 · **Version:** 1.2 · **Date:** 2026-07-29
**Client:** Shree Cement / Bangur · **Prepared by:** SAP Backend Integration Team

> **Repo note.** This file is the register-resident summary. The client-facing deliverables are
> `API_SPECIFICATION_PROPOSAL.pdf` (21 pages, full functional and technical specification) and
> `CNF_API_Register.xlsx` (8 sheets). `API_SPECIFICATION_PROPOSAL.html` is the PDF source.
> All three carry the same content at v1.2.

## v1.2 — cross-system source of record

Per the client landscape diagram, **S/4HANA is not the sole source of data**. The product spans S/4HANA,
SAP Commerce Cloud (T1 and T2) and SAP Datasphere, coordinated by SAP Integration Suite — now **confirmed**
in the runtime path (A-01 closed). Key ownership facts baked into the spec:

- **Commerce T1** serves the portal's pending-order, deliveries, invoice-billing and invoice-download views
  (pushed from SAP via CPI). API-01 is therefore the narrower SAP-side receipt position, not the dashboard.
- **Commerce T2** owns depot, user, geography, material alias, Incoterms, storage location, depot-SL and
  SL-SPI. These are *inputs* to SAP APIs; the Commerce-to-SAP mapping needs an owner (V-27).
- **Datasphere** owns MRN, STO, plant-SL and ageing. **MRN is not a SAP output** — API-02 no longer derives
  it (V-09).
- **Transporter and vehicle master are duplicated** across Commerce T2 and Datasphere — authority unresolved
  (V-26). Datasphere also carries an e-invoice object of unconfirmed source (V-28).

Validation register grew to 29 items (V-26..V-29); assumption log to 11 (A-10, A-11).

## Status

Pre-access design proposal. No SAP system access, no repository inspection, no released-API check, no
functional sign-off. Every SAP object name, BAPI signature, DDIC field and released-API reference is a
**candidate** derived from standard SAP release knowledge and the supplied functional narrative. The
standard-versus-custom classification is an engineering estimate. §Validation register lists the 25 checks
that convert each estimate into a verified fact.

Purpose: agree the API inventory and its boundaries, separate what standard SAP delivers from what must be
built, and make development access the critical path.

## Inventory alignment

The client process register (supplied as a spreadsheet extract and an architecture diagram) lists nine
processes under the SAP module. Our independently derived inventory matched eight of them and differed in two
places, both now resolved:

| Delta | Resolution |
|---|---|
| Client splits **E-Invoice Correction** from **Invoice Correction**; we had one API | Client is correct. A generated IRN cannot be amended — only cancelled within a statutory window and reissued — whereas a billing correction is a correction request or cancellation document. Different constraints, incompatible in one code path. Now specified as API-07 and API-08. |
| Client register has no **Modify DI**; we had one | Retained as API-10, flagged as a proposed addition. Create DI has no amend path without it, and quantity revision, batch reallocation and vehicle substitution are routine before goods issue. Scope confirmation is V-25. |

Final inventory: **10 APIs** — API-01..API-09 aligned one-to-one with the client register, plus API-10 proposed.

## Classification framework

| Class | Meaning | ABAP work |
|---|---|---|
| **S** — Standard | A delivered SAP API, BAPI or released service performs the business operation | Thin wrapper: protocol, authorization, idempotency, error shaping. No business logic |
| **C** — Custom over standard | No single standard API returns the required shape; every underlying source is standard | Composite CDS view or application class over standard reads |
| **X** — New construction | The required behaviour has no standard equivalent | Orchestration, state management, pre-document simulation, external coordination |

Class **S** does not mean zero development — it means the *business operation* is delivered. Class **X** is
where schedule and defect risk concentrate.

## API register

| ID | API | Operation | Class | Candidate standard source | Service | Effort (d) | Gate |
|---|---|---|---|---|---|---|---|
| API-01 | Check MIGO | Read | **C** | Order/delivery/material doc reads + document flow | `ZCNF_RECEIPT_SRV` | 8–12 | V-01, V-05 |
| API-02 | Submit MIGO | Command | **S** | Goods movement posting | `ZCNF_RECEIPT_SRV` | 5–8 | V-01, V-09 |
| API-03 | Create DI | Command | **S** | Outbound delivery creation (SLS or STO variant) | `ZCNF_DELIVERY_SRV` | 6–10 | V-05 |
| API-04 | Stock Availability | Read | **C** | Stock/batch reads + availability check | `ZCNF_STOCK_SRV` | 8–12 | V-07, V-08, V-21 |
| API-05 | Shipment Cost | Read + Estimate | **X / S** | Shipment costing (actual). **No standard pre-document estimate** | `ZCNF_DISPATCH_SRV` | 12–18 | V-06, V-10 |
| API-06 | Invoice Creation | Orchestration | **X** | Standard components per stage. **No standard orchestration** | `ZCNF_DISPATCH_SRV` | 25–35 | V-04, V-02, V-06 |
| API-07 | Invoice Correction | Command | **S** | Invoice correction request / billing cancellation | `ZCNF_BILLING_SRV` | 5–8 | V-14, V-22 |
| API-08 | E-Invoice Correction | Command | **S** | Document Compliance — IRN cancel and reissue | `ZCNF_EDOC_SRV` | 6–10 | V-02, V-14 |
| API-09 | E-Way Bill Extension | Command | **S / X** | Document Compliance for India | `ZCNF_EDOC_SRV` | 3–5 / 15–20 | V-02, V-03 |
| API-10 | Modify DI *(proposed)* | Command | **S** | Outbound delivery change | `ZCNF_DELIVERY_SRV` | 4–6 | V-11, V-25 |

**Distribution:** 5 Standard · 2 Custom over standard · 2 New construction · 2 conditional on Document
Compliance licensing.

**Indicative total:** 97–144 person-days including 15–20 for cross-cutting foundations, assuming Document
Compliance is available. Contingency of +20–25 days if it is not. Excludes functional analysis,
integration-layer work, testing cycles and defect resolution.

## Where the work actually is

**Genuinely custom (no standard equivalent):**

- **API-05 ESTIMATE.** Standard shipment costing is document-bound — it needs a cost document, which needs a
  shipment, which needs deliveries. A pre-commitment estimate has no standard counterpart. Recommended
  approach is condition-technique pricing in simulation without document creation (V-10); direct rate-record
  reading diverges silently from actual costing; create-then-reverse is rejected outright.
- **API-06 orchestration.** Every stage is standard; the resumable, observable, idempotent multi-commit
  process across four SAP units of work and two external calls is not. Requires process state persistence, a
  stage engine, per-stage guards, concurrency control and a reconciliation query.
- **Idempotency (NFR-01).** No standard SAP facility exists for "this external request already succeeded,
  return the prior result." Every command API depends on it. Most commonly underestimated item in the set.
- **API-01 and API-04 composites.** All underlying reads are standard; the joined shape with derived status,
  pending quantity and allocation ranking is not.

**Standard, wrapped only for cross-cutting concerns:** API-02, API-03, API-07, API-10 — and API-08/API-09 if
Document Compliance is licensed.

**Standard exists and should not be rebuilt:** application logging (Business Application Log, not custom
tables), authorization (standard document authority objects fire inside the BAPIs regardless; custom objects
supplement, never replace), error-to-HTTP mapping (Gateway exception framework), credential storage (platform
credential store or SAP secure storage, never an application table).

## The single highest-leverage question

**V-02 — is SAP Document Compliance for India licensed, installed and configured?** API-08 and API-09 both
depend on it. If yes, both are near-standard. If no, API-09 grows by 12–15 days and API-08 needs a bespoke
statutory client with its own status store. One question, ±20–25 days, answerable in minutes with system
access.

Running close second: **V-01** (backend product and release — determines whether released APIs and CDS views
exist at all, and therefore whether several of these need custom construction or SEGW at all) and **V-12**
(master and reference code dictionaries, which gate field-level correctness on every single API and cannot be
resolved by system inspection alone).

## Build sequence

| Phase | Content | Business-state risk |
|---|---|---|
| A | Cross-cutting foundations + API-04, API-01 (reads) | None |
| B | API-10 then API-03 (delivery commands) | Low → medium |
| C | API-02 (goods receipt) | Medium |
| D | API-05, then API-06 (dispatch and billing) | High |
| E | API-07, API-08, API-09 (billing and statutory) | High |

Phase A needs no functional answers beyond environment facts and can start the day access lands.

## Key assumptions

| Ref | Assumption | If wrong |
|---|---|---|
| A-01 | An integration layer sits between portal and SAP and owns transport retry | Credential ownership, retry design and statutory call path change. The supplied narrative shows a *direct* portal-to-Gateway connection with no middleware — V-03 |
| A-03 | DI is the outbound delivery; DI number is the delivery number | Confirmed by client team |
| A-05 | The dispatch-to-invoice sequence spans multiple SAP units of work | If atomic, API-06 redesigns entirely — V-04 |
| A-06 | Classic shipment and shipment costing are in use | API-05 and API-06 shipment stages redesign — V-06 |
| A-07 | Document Compliance for India is licensed | API-08 and API-09 both expand substantially — V-02 |

Full nine-item assumption log in the PDF, Appendix A, and in the workbook's Assumptions sheet.

## Validation register

25 items, V-01..V-25, in the PDF §9 and the workbook's Validation Register sheet. Ranked by how much of the
inventory each gates, with method, gated APIs and owner.

V-01, V-02, V-06, V-15, V-16, V-21 and V-23 are answerable within the first two days of development access and
together resolve the classification of six of the ten APIs.

## Next steps requested of the client

1. Grant development access.
2. Confirm assumption A-01 and ownership of statutory calls (V-03) — one conversation.
3. Functional session on V-04, V-05, V-07, V-08, V-11, V-22, V-25.
4. Master-data knowledge transfer against V-12.
5. Agree development conventions (V-17) before build starts.

On items 1–3 closing, the validation register can be substantially retired within two weeks of access, at
which point this proposal converts to a verified specification and the effort ranges narrow.

## Document control

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-07-29 | Initial proposal. Nine APIs, classification framework, validation register |
| 1.1 | 2026-07-29 | Realigned to client process register. E-Invoice Correction separated as API-08. Modify DI retained as proposed API-10. Service decomposition, effort and validation register updated |
