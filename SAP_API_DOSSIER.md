# SAP API Dossier — C&F Agent Interface

**Owner:** Siddharth (SAP backend / ABAP)
**Date:** 2026-07-29
**Status:** Design baseline. No DEV access, no formal assignment. Nothing here is built or system-verified.
**Purpose:** Consolidate the client-supplied technical specification and the meeting-derived process model into a single proposed SAP-side API set, with every blocker named.

## How to read this document

Three parts, in evidence order:

- **Part A** — the specification the client team supplied (`SRC-TECH-001`): what it proposes, what it gets right, and its defect register.
- **Part B** — the process model established by the 28 July design walkthrough (`SRC-MTG-20260728-01..04`) and by direct statement.
- **Part C** — the API set the SAP team should build, derived from A and B, with build sequence and blockers.

Confidence labels follow `README.md`. **Every SAP API name, DDIC field, and BAPI signature claim in this document is Strong inference pending SE37/SE11/SE24 verification.** None has been checked against a real system. Treat the "Verify" column in Part C as mandatory, not advisory.

---

# Part A — The received specification (`SRC-TECH-001`)

## A.1 What it is

| Attribute | Value |
|---|---|
| Title | SAP ABAP & OData Technical Specification |
| Version / date | 1.0 · July 2026 |
| Stated audience | "Prepared For: SAP Development Team" |
| Author / reviewer / approver | **None stated** |
| Scope | 6 services, 1 OData project, 4 Z-tables, 4 auth objects, 1 role |

**Classification: greenfield build instruction, not as-built documentation.** The document is written in the imperative throughout — "Create Project", "Right-click → Generate Runtime Objects", "Tick Enable checkbox → Save". It describes work to be done, not a system that exists.

This resolves conflict **C-3**: no `ZCNF_*` objects were found in the Quality client because none have been built. It answers the bulk of **Q-001**. The residual question is narrower but still open: *this is a proposal — is it the **approved** proposal, and who owns it?* With no author or sign-off block, that cannot be read off the document.

## A.2 Proposed object inventory

Recorded because it is the client team's naming baseline and there is no good reason to churn it.

```text
Service:    ZCNF_AGENT_SRV        Namespace: ZCNF_AGENT
Base URL:   /sap/opu/odata/sap/ZCNF_AGENT_SRV/

Package tree
  ZCNF_AGENT
    ZCNF_AGENT_DDIC       structures ZCNF_S_*, table types ZCNF_T_*, Z-tables
    ZCNF_AGENT_FM         ZCNF_MIGO_FG · ZCNF_DELIVERY_FG · ZCNF_EWAYBILL_FG · ZCNF_INVOICE_FG
    ZCNF_AGENT_GATEWAY    ZCL_ZCNF_AGENT_SRV_MPC_EXT · ZCL_ZCNF_AGENT_SRV_DPC_EXT
    ZCNF_AGENT_AUTH       ZCNF_MIGO · ZCNF_DI · ZCNF_EWB · ZCNF_INV · role ZCNF_CNF_AGENT

Function modules (all RFC-enabled)
  ZCNF_CHECK_MIGO · ZCNF_SUBMIT_MIGO · ZCNF_CREATE_DI
  ZCNF_MODIFY_DI · ZCNF_EXTEND_EWAYBILL · ZCNF_INVOICE_CORRECTION

Z-tables
  ZCNF_DI_ADDL       vehicle / driver / transporter against a delivery
  ZCNF_EWB_LOG       E-Way Bill extension audit
  ZCNF_INV_CORR_LOG  invoice correction audit
  ZCNF_GSP_CONFIG    GSP endpoint + auth token
```

## A.3 What the specification gets right

Stated plainly, because the defect register below is long and the document is not worthless.

- The **naming and package discipline** is coherent and worth keeping (`ZCNF_` prefix, DDIC/FM/Gateway/Auth split, transport sequencing DDIC → FG → classes → SEGW → registration).
- **`BAPIRET2` / `BAPIRET2T` as the uniform return type** is the correct ABAP convention.
- The **error-then-commit pattern** (`READ TABLE ... type = 'E'` → `ROLLBACK` else `COMMIT`) is correctly written in every occurrence.
- **`BAPI_GOODSMVT_CREATE`** for goods receipt and **`BAPI_OUTB_DELIVERY_CHANGE`** for delivery change are the right families of candidate.
- The **step-by-step SEGW → `/IWFND/MAINT_SERVICE` → SICF → GW_CLIENT** sequence is accurate and useful as an operational runbook.
- Declaring that **GSP credentials must not be hardcoded** shows the right instinct, even though the proposed storage is wrong (S-16).

## A.4 Defect register

IDs are citable. Severity: **Blocker** = will not compile or will not run; **Critical** = compiles but produces wrong business outcomes or a security hole; **Major** = violates an agreed standard or approved decision; **Minor** = quality.

### Blockers

| ID | § | Finding |
|---|---|---|
| S-01 | 5 | `BAPI_OUTB_DELIVERY_CREATE_STO` is called with a `sales_order` parameter. That BAPI takes shipping point, due date, and a table of stock-transport items — it has no `sales_order` import. The call is invalid as written. |
| S-02 | 5, 6 | `bapi**ib**dlvhdrchg` / `bapi**ib**dlvitemchg` (**inbound** delivery structures) are declared for **outbound** delivery operations. `BAPI_OUTB_DELIVERY_CHANGE` expects the `bapi**ob**dlv*` family. |
| S-03 | 3 | `SELECT ... FROM mkpf ... WHERE bwart = '101'` — MKPF has no `BWART` field. Movement type lives in MSEG. The spec's own comment says "via MKPF/MSEG" but the code touches only MKPF. |
| S-04 | 3 | `FOR ALL ENTRIES IN @lt_so` with no `IF lt_so IS NOT INITIAL` guard. On an empty driver table this selects the **entire VBFA table**. |
| S-05 | 8 | `BAPI_BILLINGDOC_CREATEMULTIPLE` is used to create a credit/debit memo **request**. A memo request is a *sales* document (`BAPI_SALESORDER_CREATEFROMDAT2`), not a billing document. The fields used (`req_type`, `reason`) do not exist in `bapivbrkrequest`. Export is named `EV_CREDIT_MEMO_NO` but assigned `ls_out-billingdoc`. |
| S-06 | 7 | The GSP JSON response parse is a commented-out placeholder. `ev_new_validity` is never populated — yet it is written to `ZCNF_EWB_LOG` and returned in the success message. Every extension would log and report a blank validity date. |

### Critical

| ID | § | Finding |
|---|---|---|
| S-07 | all | **No idempotency anywhere.** Not one FM accepts an external request or correlation ID. No duplicate detection, no request→result store, no safe-retry replay. A CPI retry after a lost response posts a second goods receipt, a second delivery, or a second credit memo. Contradicts `SEGW_ODATA_PLAN.md` §Writes; leaves Q-010 open. **Highest-risk item in the document.** |
| S-08 | 5,6,7,8 | Z-table writes sit **outside** the BAPI LUW — `BAPI_TRANSACTION_COMMIT` followed by a separate `INSERT`/`UPDATE` + `COMMIT WORK`. If the second commit fails the delivery exists and its vehicle/driver/transporter data is silently gone. `SEGW_ODATA_PLAN.md`: *"Do not hide partial completion."* |
| S-09 | 4 | `ev_mrn = \|MRN-{ lv_mat_doc }\|` — **MRN is fabricated.** MRN is *Unresolved* in `DOMAIN_GLOSSARY.md`; a developer invented its meaning as a string prefix on the material document number. `BRAND_GRADE` and `DO_NUMBER` are likewise sourced as "Custom" with no derivation. `BRAND_GRADE` is a KDS concept (Q-021). |
| S-10 | 3 | `GR_STATUS` is binary — "material document exists → Done, else Pending". The walkthrough explicitly requires **partial** receipt visibility with remaining quantity pending. R-001 cannot be met by this design. |
| S-11 | 11.2 | `AUTHORITY-CHECK OBJECT 'ZCNF_MIGO' ID 'ACTVT' FIELD '01'` checks ACTVT only, while the object declares ACTVT **and WERKS**. Plant is never checked — a depot user can post for any plant. |
| S-12 | 11.1 | `ZCNF_DI`, `ZCNF_EWB`, `ZCNF_INV` carry **only** ACTVT. No plant/depot field exists, so there is no way to restrict a C&F agent to their own depot. All agents share one role `ZCNF_CNF_AGENT`. No data-level segregation between agents. |
| S-13 | 4 | `gm_code = '01'` (GR for purchase order) combined with `mvt_ind = 'B'` (delivery note) and an **outbound** delivery number located via `vbtyp_n = 'J'`. The reference model is internally inconsistent and collides with unresolved Q-004. |
| S-14 | 8 | `BAPI_BILLINGDOC_CANCEL1` with no IRN cancellation-window handling and no E-Way Bill linkage — despite e-Invoice and E-Way Bill being major walkthrough topics. Cancelling a billed document that already carries an IRN has consequences this design does not represent. |
| S-15 | 7 | GSP JSON is built by string interpolation of free-text input (`IV_REASON_REMARKS`, CHAR100). An embedded quote or backslash breaks or injects into the payload. Should serialize a typed structure via `/ui2/cl_json`. |
| S-16 | 7 | GSP bearer token stored as a plain column in `ZCNF_GSP_CONFIG` and `SELECT`ed into a local variable. A Z-table is not secure credential storage. This also puts GSP credential ownership inside ABAP — explicitly **outside** scope per `ROLE_BOUNDARIES.md`. |
| S-17 | 7 | Synchronous outbound HTTP inside an OData request — no timeout, no retry, no circuit breaker, no `receive` exception handling. A slow GSP blocks a Gateway work process. |

### Major

| ID | § | Finding |
|---|---|---|
| S-18 | 1.1 | **CPI does not appear in the document.** Integration is drawn as `React app → HTTPS OData V2 → SAP Gateway`. No CPI, no Commerce/Hybris. Contradicts the entire program architecture. Determines contract ownership, auth boundary, correlation, and retry. (Conflict **C-6**.) |
| S-19 | 9 | *"All business logic is wired in the DPC Extension class."* Contradicts `SEGW_ODATA_PLAN.md` §Preferred layering and `BAPI_CANDIDATES.md` §Design rule. FM-based rather than class-based also means no ABAP Unit testability and no test doubles. |
| S-20 | 2 | Target system undeclared: "ECC 6.0 EhP7+ **or** S/4HANA 1909+". No BAPI in the document can have been validated. Also states a **two-system landscape (DEV → PRD)** — no QAS — for a design that posts credit memos and cancels billing documents. (Conflict **C-8**.) |
| S-21 | 5 | Contradicts **D-002**: `ZCNF_S_DI_ITEM` carries one `STORAGE_LOC` and one `BATCH` *per item*. No header-level storage location, no multi-batch split within an item, no validation that batch quantities sum to DI quantity. |
| S-22 | 6 | Contradicts **D-005**: `ZCNF_MODIFY_DI` permits changing quantity, batch, planned GI date, vehicle, driver and transporter. Approved scope is DI **quantity** only, while the DI is open. |
| S-23 | 7 | Contradicts **D-003**: `IV_TRANSPORT_MODE` accepts `1=Road, 2=Rail`. Extension was fixed to Road only. |
| S-24 | 3 | Contradicts **D-001**: `ORDER_QTY` exists; DI quantity and pending quantity are derived nowhere. `Order = DI + Pending` is unimplementable from this structure. |
| S-25 | 10.2 | Every `BAPIRET2` type `E` maps to HTTP **400**. Business validation belongs at 422 or an approved 4xx per `CPI_CONTRACTS.md`; 400 is a schema error. No 409 for conflict/duplicate, no 503 for lock/temporary. |
| S-26 | 3, 9 | `EV_TOTAL_COUNT` is described as "for pagination" but no `$top`/`$skip` is handled and the FM has no offset/limit parameters. The VBAK/VBAP select is unbounded. |
| S-27 | 7 | No standard **SAP eDocument** evaluation. SAP ships an eDocument framework for India e-Invoice and E-Way Bill (eDocument Cockpit). The spec goes straight to custom Z-tables plus direct GSP REST calls without recording why the standard framework was rejected. Potentially a large reinvention. |

### Minor

| ID | § | Finding |
|---|---|---|
| S-28 | 9 | `Edm.Decimal` precision/scale declared with no unit-pairing annotation; `Edm.DateTime` as `/Date(epoch-ms)/` for DATS fields with no timezone rule — a standard off-by-one-day source. Both required by `SEGW_ODATA_PLAN.md` §Keys and types. |
| S-29 | 9 | `MigoItem` shows no key property marked. An OData V2 entity type without a key is invalid. *(The §9 and §12 tables extract with visible column misalignment — confirm against the original PDF layout before treating this and S-30 as source defects rather than extraction artifacts.)* |
| S-30 | 12 | Test cases are offset from FM names ("Valid delivery creation / `ZCNF_SUBMIT_MIGO`", "Modify after GI / `ZCNF_CREATE_DI`"). Also SE37 only — no ABAP Unit, no negative authorization tests, no idempotency or concurrency tests, no CPI end-to-end. Contradicts `WORKFLOW.md` §Phase 5 layered test order. |
| S-31 | 1.2 | Naming table is internally inconsistent — declares class prefix `ZCL_CNF_` but §9 generates `ZCL_ZCNF_AGENT_SRV_DPC_EXT`. Feeds Q-019 (conventions to agree with the second ABAP developer). |
| S-32 | 7 | Extension reason code `6 = First Extension` is not a standard NIC reason (1–5 are). Validate against the actual GSP contract. |

## A.5 Verdict

**Usable for:** scope signal, naming and package baseline, the SEGW/Gateway/SICF activation runbook, and evidence that the work is greenfield.

**Not usable as:** a build instruction. Six items will not compile or run; eleven produce wrong business outcomes or security holes; four contradict decisions the business approved on 28 July.

**Coverage:** 6 of 24 register entries (IF-001, 002, 003, 004, 008, 023) and roughly 6 of 27 requirements. The entire invoice journey established in the walkthrough — PGI, shipment, shipment cost, billing, e-Invoice, document flow — has no service in the document.

---

# Part B — Process model from meetings and direct statement

## B.1 Evidence caveat

The four 28 July recordings and the meeting summary are **not present in this repository**. Every claim in this Part is second-hand via reconciliation in `meetings/2026-07-28-design-walkthrough.md`, and disputed terms cannot be re-adjudicated from this repo alone. Session 3 is flagged as heavy crosstalk with lower evidentiary confidence. The BRD (`SRC-BRD-001`) and CPI workbook (`SRC-CPI-001`) have never been ingested by anyone.

## B.2 The operational spine

```text
Order ──> DI (outbound delivery) ──> one storage location ──> 1..n batches
      ──> transporter + route + freight ──> shipment details (LR/GR, vehicle, driver)
      ──> { PGI · shipment · shipment cost · billing } ──> { e-Invoice/IRN · E-Way Bill }
      ──> document flow / status / download
      ──> E-Way Part A correction | Part B vehicle update | 24h extension
```

Peripheral: MIGO/partial receipt, warehouse transfer, physical inventory reconciliation, dashboards, ageing.

## B.3 Approved decisions the API set must honour

| ID | Decision | API consequence |
|---|---|---|
| D-001 | Labels are Order Quantity / DI Quantity; `Order = DI + Pending` | Pending-order read must derive all three quantities, not just order quantity |
| D-002 | One storage location per DI/invoice; multiple batches inside it | Storage location belongs at **header** level; batch allocation is a 1..n child; SAP must validate the sum |
| D-003 | E-Way Bill extension transport mode is Road only | Reject any other mode server-side; do not expose a mode parameter |
| D-004 | E-Way Bill Part B remains editable during validity | Part B update needs a validity precondition check |
| D-005 | Only DI quantity is editable after creation, and only while the DI is open | Change command exposes quantity only; precondition on delivery status |
| D-006 | Vehicle tracking uses FleetX | No SAP posting by default; integration owner unassigned |
| D-007 | **DI = Delivery. DI No. = outbound delivery number (`LIKP-VBELN`)** | DI reads target LIKP/LIPS; document flow via VBFA. Predecessor still open (Q-031) |

Batch quantities must sum exactly to DI quantity — no under- or over-allocation. SAP remains the invoice-generating authority. Extension is 24h, repeatable, using current vehicle location and a reason. Driver mobile is mandatory (documents sent by SMS).

## B.4 What the meetings require that the specification omits

This gap list is the main input to Part C.

| Need | Source | Spec coverage |
|---|---|---|
| Pending-order dashboard split credit-free / credit-blocked | walkthrough | none |
| Order/DI/pending quantity derivation | D-001 | none |
| Open DI list and detail | walkthrough | none |
| Storage location and batch filtered for the warehouse | walkthrough | none |
| Batch proposal with quantity-sum validation | D-002 | none |
| Transporter search by code or name | walkthrough | none |
| Estimated shipment cost for user validation | walkthrough | none |
| Shipment details capture (LR/GR, vehicle, driver, pickup code) | walkthrough | partial, in a Z-table |
| PGI · shipment · shipment cost · billing as process stages | walkthrough | none |
| e-Invoice / IRN status | walkthrough | none |
| E-Way Part A correction, Part B vehicle update | D-004 | none |
| Document flow status with related identifiers | walkthrough | none |
| Document download after completion | walkthrough | none |
| Partial receipt with remaining quantity pending | walkthrough | contradicted (S-10) |
| FleetX tracking link | D-006 | none |
| KDS / master-code dictionary behind every payload field | walkthrough | none (S-09) |

---

# Part C — Proposed SAP API set

## C.1 Design decisions

Stated as decisions with reasons, so they can be challenged individually.

**C.1.1 Six bounded services, not one monolith.** The spec proposes a single `ZCNF_AGENT_SRV`. With 24+ interfaces and two ABAP developers that is a bottleneck: one bad activation breaks every endpoint, and both developers collide in one SEGW project and one transport continuously. Split by document domain so each service is independently transportable and independently ownable.

**C.1.2 Thin `DPC_EXT`, logic in classes, BAPIs behind wrappers.** Reverses S-19. Per `SEGW_ODATA_PLAN.md` layering. Classes, not function modules, so ABAP Unit and test doubles are possible.

**C.1.3 Command entities for actions, not PATCH.** Operations with preconditions and side effects (post GI, extend E-Way Bill, submit receipt) are modelled as POST to a command entity set that returns a result, not as PATCH on a business entity. PATCH implies partial-update semantics that these operations do not have.

**C.1.4 Read-first.** Every service's read endpoints precede its write endpoints. Per `NEXT_MOVE.md` and `MASTER_PLAN.md` Phase 6.

**C.1.5 Staged invoice journey as the working model.** PGI, shipment, shipment cost, billing and the external e-document legs are separate SAP units of work with independent failure and unpredictable latency. Modelled as explicit commands plus a status read, with a process instance to correlate them. The synchronous-atomic variant is preserved as the alternative pending **Q-008 / Q-026**.

**C.1.6 Idempotency, correlation and authorization are shared infrastructure, not per-service.** Fixes S-07, S-11, S-12. Built once, in Phase A, before any write endpoint exists.

**C.1.7 Keep the `ZCNF_` namespace.** The client team's naming is sound and churning it costs goodwill for no engineering gain. Resolve the internal inconsistency (S-31) with the second ABAP developer under Q-019.

## C.2 Service decomposition

| Service | Domain | Contains |
|---|---|---|
| `ZCNF_MASTER_SRV` | reference and master data | plants, storage locations, materials, transporters, reason codes |
| `ZCNF_ORDER_SRV` | order and DI lifecycle | pending orders, order detail, DI list/detail, DI create, DI quantity change |
| `ZCNF_STOCK_SRV` | stock and batch | availability, batch proposal, allocation validation |
| `ZCNF_DISPATCH_SRV` | dispatch and billing | freight estimate, shipment, PGI, billing, process command, process status |
| `ZCNF_EDOC_SRV` | e-documents | IRN status, E-Way status, Part A, Part B, extension, downloads |
| `ZCNF_RECEIPT_SRV` | inbound and receipt | pending receipts, goods receipt, receipt status |

## C.3 API catalogue

`Op` = GET (read) or POST (command). `IF` traces to the retired interface register, now `_archive/INTERFACE_REGISTER.md` — see `_archive/README.md` for the IF→API mapping. **All candidate APIs require SE37/SE11 verification and a released-alternative check before adoption.**

> **Note (2026-08-03):** this dossier predates architecture Option C (D-014), the KDS catalogue and the DigiGST finding (D-017). Part A (the specification defect register) remains accurate and useful. Part C's API set is superseded by `deliverables/CNF_API_Classification.xlsx` and `HANDOVER_AI.md §5`.

### `ZCNF_MASTER_SRV` — reference data

| API | Entity set | Op | IF | Candidate source | Blockers |
|---|---|---|---|---|---|
| A-01 | `PlantSet` | GET | new | T001W / `I_Plant` | Q-007 depot system of record |
| A-02 | `StorageLocationSet` | GET | new | T001L / `I_StorageLocation` | Q-023 selection timing |
| A-03 | `MaterialSet` | GET | new | MARA/MAKT, `BAPI_MATERIAL_GET_DETAIL`, `API_PRODUCT_SRV` | **Q-021** brand/grade derivation |
| A-04 | `TransporterSet` | GET | IF-017 | LFA1 / partner functions / `API_BUSINESS_PARTNER` | Q-007 source, partner function |
| A-05 | `ReasonCodeSet` | GET | new | customizing tables | Q-021, S-32 |

No business state. Safest possible first slice — proves source selection, filters, pagination, auth, error contract, correlation and CPI connectivity with zero posting risk.

### `ZCNF_ORDER_SRV` — order and DI lifecycle

| API | Entity set | Op | IF | Candidate source | Blockers |
|---|---|---|---|---|---|
| A-06 | `PendingOrderSet` | GET | IF-013 | VBAK/VBAP + VBFA aggregation, or CDS; `API_SALES_ORDER_SRV` | **Q-005** S/4 vs Datasphere; D-001 derivation |
| A-07 | `OrderDetailSet` | GET | IF-013 | VBAK/VBAP/VBKD, credit status | Q-021 Incoterm/segment codes |
| A-08 | `DeliverySet` | GET | IF-014 | LIKP/LIPS + VBFA; `API_OUTBOUND_DELIVERY_SRV` | none material — **D-007 settles the object** |
| A-09 | `DeliverySet('key')` | GET | IF-014 | LIKP/LIPS/VBFA + `ZCNF_DI_ADDL` | Q-016 identifiers |
| A-10 | `DeliveryCreateSet` | POST | IF-003 | `BAPI_OUTB_DELIVERY_CREATE_SLS` **or** `_STO` | **Q-031** — the fork. Isolate behind a strategy class |
| A-11 | `DeliveryQuantityChangeSet` | POST | IF-015 / IF-004 | `BAPI_OUTB_DELIVERY_CHANGE` (`bapiobdlv*`) | D-005 scope; C-5 cutoff dispute |

A-10 is the only endpoint where Q-031 bites. Confine the SLS/STO decision to one wrapper class so resolving it changes one implementation, not the OData contract or CPI's schema.

A-11 is the **recommended first write**: single BAPI, one field, a clear precondition (delivery open, not goods-issued), and no new document created. Smallest possible proof of the write pattern.

### `ZCNF_STOCK_SRV` — stock and batch

| API | Entity set | Op | IF | Candidate source | Blockers |
|---|---|---|---|---|---|
| A-12 | `StockAvailabilitySet` | GET | IF-005 | `BAPI_MATERIAL_AVAILABILITY` (ATP) vs MARD/MCHB or `API_MATERIAL_STOCK_SRV` | **Q-014** — ATP or unrestricted physical |
| A-13 | `BatchProposalSet` | GET | IF-016 | MCHB/MCHA, `BAPI_BATCH_GET_DETAIL`, batch determination | **Q-015 / Q-028** — who owns FIFO |
| A-14 | `BatchAllocationValidateSet` | POST | IF-016 | own validation logic | D-002 sum rule |

A-14 is a read-only validation command. D-002's sum rule is a business rule and SAP must be its authority — validating only in the portal means an out-of-band caller can violate it.

### `ZCNF_DISPATCH_SRV` — dispatch and billing

| API | Entity set | Op | IF | Candidate source | Blockers |
|---|---|---|---|---|---|
| A-15 | `FreightEstimateSet` | GET/POST | IF-018 | route + pricing conditions; shipment cost simulation | **Q-025** SPI; Q-022 FTP vs EX-works |
| A-16 | `ShipmentCreateSet` | POST | new (R-008) | `BAPI_SHIPMENT_CREATE` (LE-TRA only) | **LE-TRA vs SAP TM vs custom** |
| A-17 | `ShipmentCostSet` | POST | new (R-008) | `BAPI_SHIPMENTCOST_CREATE` | same as A-16 |
| A-18 | `GoodsIssueSet` | POST | IF-019 | `BAPI_OUTB_DELIVERY_CONFIRM_DEC`, delivery-change GI flag, or `BAPI_GOODSMVT_CREATE` mvt 601 | Q-026; `WS_DELIVERY_UPDATE` is **not released** |
| A-19 | `BillingSet` | POST | IF-019 | `BAPI_BILLINGDOC_CREATEMULTIPLE`, `API_BILLING_DOCUMENT_SRV` | Q-026 predecessor/due-list semantics |
| A-20 | `DispatchProcessSet` | POST | IF-019 | orchestrator over A-18/16/17/19 | **Q-008** — exists only in the staged model |
| A-21 | `DispatchStatusSet` | GET | IF-020 / IF-009 | VBFA document flow + stage state + e-doc status | **Q-029** which identifier per stage |
| A-22 | `InvoiceCorrectionSet` | POST | IF-008 | `BAPI_SALESORDER_CREATEFROMDAT2` (memo request) **or** `BAPI_BILLINGDOC_CANCEL1` (reversal) | fixes S-05; S-14 e-doc consequences |

A-20 is the endpoint the walkthrough calls "Generate Invoice". In the staged model it creates a process instance, returns a process ID immediately, and each stage is driven and observed separately. This is the single largest architectural bet in the document and it rests on **Q-008 / Q-026**.

### `ZCNF_EDOC_SRV` — e-documents

**Ownership is unresolved (Q-009).** If CPI owns the GSP calls, this service shrinks to SAP-side persistence and status reads only, and A-25..A-27 disappear from the ABAP scope entirely. Do not build until Q-009 is answered — and evaluate the standard SAP eDocument India framework first (S-27).

| API | Entity set | Op | IF | Candidate source | Blockers |
|---|---|---|---|---|---|
| A-23 | `EInvoiceStatusSet` | GET | new | eDocument tables / custom persistence | Q-009, S-27 |
| A-24 | `EWayBillSet` | GET | new | eDocument / custom persistence | Q-009, S-27 |
| A-25 | `EWayPartACorrectionSet` | POST | IF-021 | GSP API via CPI or ABAP | Q-009 |
| A-26 | `EWayPartBUpdateSet` | POST | IF-022 | GSP API via CPI or ABAP | Q-009; D-004 validity precondition |
| A-27 | `EWayExtensionSet` | POST | IF-023 | GSP API via CPI or ABAP | Q-009; **D-003 Road only** — no mode parameter |
| A-28 | `DocumentDownloadSet` | GET | IF-012 | output repository / GSP / SAP | **Q-016** where files actually live |

### `ZCNF_RECEIPT_SRV` — inbound and receipt

| API | Entity set | Op | IF | Candidate source | Blockers |
|---|---|---|---|---|---|
| A-29 | `PendingReceiptSet` | GET | IF-001 | depends entirely on Q-004; VBFA/EKBE/inbound delivery | **Q-004**; must support partial (S-10) |
| A-30 | `GoodsReceiptSet` | POST | IF-002 | `BAPI_GOODSMVT_CREATE`, `API_MATERIAL_DOCUMENT_SRV` | **Q-004** determines `gm_code`/`mvt_ind`/reference fields (S-13) |
| A-31 | `ReceiptStatusSet` | GET | IF-001 | MKPF/MSEG + document flow | **MRN definition** (S-09) |

## C.4 Shared components

Built once in Phase A. Not part of any service's business scope.

| Component | Responsibility | Fixes |
|---|---|---|
| `ZCL_CNF_IDEMPOTENCY` | external request ID → result store; replay prior success; timeout reconciliation | S-07 |
| `ZCL_CNF_LOG` | application log + correlation ID persistence, queryable by CPI message ID | S-07, Q-012 |
| `ZCL_CNF_AUTH` | authorization incl. **plant/depot scoping** on every object | S-11, S-12 |
| `ZCL_CNF_ERROR` | stable error response builder; HTTP mapping per `CPI_CONTRACTS.md` | S-25 |
| `ZCX_CNF_*` | business exception hierarchy | — |
| `ZCL_CNF_*_WRAPPER` | one wrapper per BAPI/released API; isolates the SLS/STO fork | S-01, S-02, Q-031 |
| `ZCL_CNF_CONVERT` | unit conversion, ALPHA in/out, decimal + unit pairing, date/timezone | S-28 |

**Idempotency design note.** A Z-table alone does not survive the *"SAP committed, response lost"* case. The external request ID must also be persisted somewhere queryable **on the SAP document itself** so reconciliation can find it without trusting the Z-table. Where that field lives is per-document and unresolved — this is the substance of **Q-010**.

## C.5 Build sequence

| Phase | Content | Prerequisite | Risk |
|---|---|---|---|
| **A** | Shared components + `ZCNF_MASTER_SRV` reads (A-01..A-05) | DEV access, Q-002, Q-019 | none — no business state |
| **B** | `ZCNF_ORDER_SRV` reads (A-06..A-09) | Q-005, D-001 derivation agreed | none — reads only |
| **C** | First write: `DeliveryQuantityChangeSet` (A-11) | C-5 cutoff resolved | low — changes one field on an open delivery |
| **D** | `DeliveryCreateSet` (A-10) | **Q-031** | medium — creates a document |
| **E** | `ZCNF_STOCK_SRV` (A-12..A-14) | Q-014, Q-015/Q-028 | none — reads + validation |
| **F** | `ZCNF_RECEIPT_SRV` (A-29..A-31) | **Q-004**, MRN definition | medium — posts material documents |
| **G** | `ZCNF_DISPATCH_SRV` (A-15..A-22) | **Q-008/Q-026**, LE-TRA vs TM | high — PGI, billing, financial impact |
| **H** | `ZCNF_EDOC_SRV` (A-23..A-28) | **Q-009**, S-27 eDocument evaluation | high — external, statutory |
| **I** | Datasphere analytical reads (IF-010) | Q-005, Q-018 | none — not ABAP-owned |

Phases A and B require no functional answers at all beyond environment facts. **They can start the day DEV access lands.** Everything from D onward is gated on a named question.

## C.6 Explicitly not in this scope

Per `ROLE_BOUNDARIES.md`, recorded so it is not absorbed silently: frontend/UI, iFlow construction, Datasphere modelling, Basis parameters and roles, functional sign-off, **GSP credential ownership**, production postings. FleetX integration (D-006) has no assigned owner — that is a question, not an inheritance.

## C.7 Blocker summary

Ranked by how many proposed APIs each one gates.

| Question | Gates |
|---|---|
| **Q-002 / C-8** ECC or S/4, release, landscape | every API — determines whether released alternatives exist and whether SEGW is even the right vehicle |
| **Q-021** KDS and code dictionaries | every payload field; A-03, A-05, A-07 directly |
| **Q-008 / Q-026** invoice staged or atomic | A-15..A-22 (8 APIs) |
| **Q-009** who calls the GSP | A-23..A-28 (6 APIs) |
| **Q-004** receipt reference model | A-29..A-31 (3 APIs) |
| **Q-031** DI predecessor SO or STO | A-10 |
| **Q-005** S/4 vs Datasphere reads | A-06, A-07, IF-010 |
| **Q-014 / Q-015 / Q-028** stock semantics and FIFO ownership | A-12, A-13 |
| **Q-010 / Q-011 / Q-012** idempotency, error schema, correlation standard | all shared components |
| **Q-016** where document files live | A-28 |
| **Q-019** package/namespace/message-class conventions | Phase A, and agreement with the second ABAP developer |

`Q-006` — the formal assignment — gates the whole document. Nothing here is legitimately startable without it.

---

## Sources

| Source ID | Content | Confidence |
|---|---|---|
| `SRC-TECH-001` | SAP ABAP & OData Technical Specification v1.0 | Verified as document; SAP claims within it unverified |
| `SRC-MTG-20260728-01..04`, `-SUM` | 28 July design walkthrough | Second-hand via reconciliation; originals not in repo |
| `SRC-SID-20260729-01` | DI = delivery, DI No. = delivery number | Verified (D-007) |
| `SRC-CONTEXT-001` | Prior architecture and document summaries | Partial |
| `SRC-BRD-001`, `SRC-CPI-001` | BRD, CPI interface workbook | **Never ingested** |

## What would invalidate this document

- Arrival of the BRD or the CPI workbook — either could reframe Part C's decomposition entirely.
- An answer to Q-002/C-8 — if the backend is S/4 with released APIs available, several proposed SEGW services should not be built at all.
- An answer to Q-008/Q-026 — collapses or confirms A-15..A-22.
- An answer to Q-009 — may delete `ZCNF_EDOC_SRV` from ABAP scope.
- Confirmation that `SRC-TECH-001` is the *approved* design with an owner — changes this from an assessment into a formal change request against it.
