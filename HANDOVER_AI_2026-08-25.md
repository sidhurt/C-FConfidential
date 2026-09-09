# Handover — CNF C&F Agent: QS4 standard-service completion and ABAP build transition

> **Historical status snapshot.** Runtime and implementation classifications in this 25 August handover are superseded by `CURRENT_STATE.md` where later BAPI, BAdI or enhancement evidence conflicts. Preserve this file for the evidence trail.

**Written 2026-08-25. Audience: an AI agent that already knows the Shree Cement CNF project.**

This is a delta handover, not a project introduction. It supersedes runtime and transport claims in `HANDOVER_AI_2026-08-19.md` where they conflict. Preserve the older handover for the deeper BAPI/freight investigation history.

---

## 1. Current mission

The activation exercise is complete. The project must now move continuously from:

1. standard-service transport and runtime certification;
2. to a clean Postman request/response evidence pack;
3. to the missing ABAP exposure services;
4. to end-to-end document creation and downstream verification;
5. to negative, duplicate, reversal and recovery tests.

Do not treat a completed stage as a stopping point. Every completed stage must create the next executable queue.

**Current priority:** finish the SAP/ABAP-side API surface for the v1.9 business list, starting with the smallest custom services that unblock real document creation.

---

## 2. Authority and provenance

Use this order when sources disagree:

1. **Executed SAP runtime evidence** — actual QS4/DS4 request and response, created SAP key and persistence verification.
2. **Live `$metadata`** from the exact registered version.
3. **`deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx`** — authoritative business-flow and request/response baseline, but not proof that SAP implements every proposed field.
4. **`sessions/2026-08-18-runtime-certification/ENDPOINT_BEHAVIOR_CERTIFICATION_MATRIX.md`** and raw evidence.
5. Earlier workbooks, plans and architectural discussion.

The v1.9 workbook is authoritative for business intent and API numbering. It is not to be followed byte-for-byte where live SAP proves a different standard contract. Record the difference explicitly.

### Current primary evidence

- `C:\Users\sidmy\OneDrive\Documents\All remaining service testing gw_client.txt`
  - Material Stock root and real reads.
  - Billing and PO root and real reads.
- `C:\Users\sidmy\OneDrive\Documents\final 3 service testing.txt`
  - Correct Billing and PO metadata.
  - Real STO `5600084210` read with item expansion.
- `sessions/2026-08-18-runtime-certification/evidence/external-http-2026-08-19/`
  - Earlier external GET/POST request-response evidence.
- `sessions/2026-08-18-runtime-certification/evidence/external-http-2026-08-19/CREATE_DI_AND_MIGO_ODATA.md`
  - Create-DI and Material Document OData write-path findings.

Never put passwords, cookies, authorization headers or CSRF tokens into handovers or checked-in evidence.

---

## 3. Working rules learned the expensive way

- Confirm `SystemName` and `Client` from the SAP session before every scripted action.
- Run **one SAP GUI script at a time**. Concurrent scripting and manual use of the same session can destabilize SAP GUI.
- Do not use desktop control when SAP GUI scripting can address the transaction directly.
- Do not infer persistence from HTTP 200, an allocated number, or a success message. Re-read the SAP document after commit.
- Do not write directly to SAP tables.
- Treat unexpected modals as blockers; do not blanket-dismiss them.
- The SAP Gateway Client can crash its local XML renderer on large `$metadata` responses. This is a frontend failure, not automatically a service failure. Use a browser or request `Accept: application/xml` for metadata; use JSON for entity reads.
- `;v=2` is mandatory for `API_OUTBOUND_DELIVERY_SRV`. Omitting it produces 403 because v1 is not registered.
- The other four standard services covered here use `;v=1`.
- In QS4, ICF activation was performed locally after import. Do not assume ICF active state will transport automatically.
- Mutating QS4 requires explicit authorization for the exact test. Read-only verification is always preferred first.

---

## 4. Standard services now present in QS4/700

All five service definitions, LOCAL aliases and ICF leaves are present and active in QS4/700.

| Service | Version | Current proven use |
|---|---:|---|
| `API_OUTBOUND_DELIVERY_SRV` | 2 | Create/read outbound delivery; `;v=2` mandatory |
| `API_MATERIAL_DOCUMENT_SRV` | 1 | Material-document deep-create route reached SAP posting control |
| `API_MATERIAL_STOCK_SRV` | 1 | Real stock reads |
| `API_BILLING_DOCUMENT_SRV` | 1 | Billing header/item reads and metadata; no document create |
| `API_PURCHASEORDER_PROCESS_SRV` | 1 | PO/STO header and item reads; standard STO create rejected |

### Transport map

The transport pattern that worked was:

1. register the Gateway service in DS4/200 under transportable package `ZSCL`;
2. capture IWOM, IWSG and SICF in a Workbench request/task;
3. release the child task, not the parent request;
4. create a Transport of Copies and include the object list from the parent request;
5. capture the LOCAL alias in `/IWFND/V_MGDEAM` under a Customizing task;
6. release that child task, create a separate alias ToC and include the parent object list;
7. import repository ToC first and alias ToC second into QS4/700;
8. activate the imported ICF leaf locally in QS4 and run `$metadata` plus a real request.

| Area | Source request/task | Repository ToC | Alias request/task | Alias ToC |
|---|---|---|---|---|
| Outbound Delivery | `DS4K963225` / `DS4K963226` | `DS4K963236` | `DS4K963241` / `DS4K963242` | `DS4K963243` |
| Material Document | `DS4K963269` / `DS4K963270` | `DS4K963268` | alias key later captured in the existing alias chain | `DS4K963273` |
| Material Stock | `DS4K963386` / `DS4K963387` | `DS4K963409` | `DS4K963402` / `DS4K963403` | `DS4K963404` |
| Billing + Purchase Order | `DS4K963412` / `DS4K963413` | `DS4K963414` | `DS4K963415` / `DS4K963416` | `DS4K963417` |

Known trap: `DS4K963401` was an incomplete Material Stock repository ToC created before the source child task was correctly released. Do not use it as the successful precedent. `DS4K963271` carried the Outbound Delivery alias, while `DS4K963272` carried the Material Document alias key; do not confuse the two.

---

## 5. Runtime truth for the five services

### 5.1 Outbound Delivery v2 — positive write route proven

- Route: `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/...`
- Without `;v=2`: 403 `/IWFND/MED/170`.
- Deep insert with items reaches delivery creation logic.
- The project has a successful real Create-DI execution and created-delivery evidence from the later QS4 exercise.
- Do not use a header-only POST. The header-only path returns `CX_SADL_ENTITY_CUD_DISABLED`; deep insert is the real creation path.
- Remaining work is productization: freeze the exact Postman payload, predecessor selection rules, CSRF-cookie flow, response assertions and re-read verification.

### 5.2 Material Document v1 — callable write route, successful posting still gated

- Deep-create request reached posting-period validation through OData.
- Observed result: `M7/053`, posting allowed only in periods `1998/03` and `1998/02` in the tested DS4 company-code context.
- This proves the route, payload shape and business method were reached. It does **not** prove a committed material document.
- Next gate: a write-authorized client with a currently open MM period and valid predecessor/stock data. Success requires returned `MaterialDocument` + `MaterialDocumentYear` and an authoritative re-read.

### 5.3 Material Stock v1 — positive real read proven in QS4

- Root and both entity sets respond.
- Real result from `A_MatlStkInAcctMod`:
  - Material `11000000`
  - Plant `1000`
  - Storage location `RMYD`
  - Stock type `01`
  - Base unit `TO`
  - Quantity `130.797`
- `A_MaterialStock?$top=1` returned a blank material row; do not use that as the business demonstration. Use the account-model entity with filters.
- Both entity sets are read-only in metadata.

### 5.4 Billing Document v1 — reads proven; creation structurally absent

- Correct metadata retrieved after changing metadata `Accept` from JSON to XML.
- Header and item reads succeeded for billing document `90000000`, item `10`.
- All eight entity sets explicitly declare `sap:creatable="false"`, `sap:updatable="false"`, `sap:deletable="false"`.
- Function imports:
  - `GetPDF` — GET
  - `Cancel` — POST
- There is no billing-document create operation. Do not present this service as the Create Invoice solution.

### 5.5 Purchase Order v1 — real STO presence/read proven; STO create still not provided

- Correct metadata and generic PO reads succeeded.
- Real STO `5600084210` read with `to_PurchaseOrderItem` expansion:
  - Type `ZP06`
  - Subtype `T`
  - Supplier blank
  - Supplying plant `1002`
  - Receiving plant `1025`
  - Item category `7`
  - Material `14000037`
  - Storage location `RMYD`
  - Quantity `10000.000 TO`
- This closes the earlier inference: the standard API reads real STOs correctly.
- Earlier `POST A_PurchaseOrder` executions rejected STO combinations with `APPL_MM_PUR_PO/064` and `/065`. Metadata advertises general PO insertability, but the implemented create path did not accept the required STO shape. Retain the executed negative result as the architectural boundary.

### Claim boundary

It is correct to say:

> Five standard services are transported, active and callable in QS4. Create DI has a positive write result; Material Document reaches real posting control; Stock, Billing and STO reads return real data.

It is not correct to say:

> All five business APIs are fully complete end-to-end writes.

---

## 6. v1.9 business API portfolio and SAP-side disposition

The v1.9 workbook has ten business API sheets plus Change Log and Retired Sheets.

### Dedicated standard/custom decision artifact

Read this workbook before proposing new SAP development:

`outputs/simple-api-implementation-matrix-20260824/CNF_API_Service_Implementation_Matrix.xlsx`

It was created specifically to answer, for each implementation service:

- which standard SAP OData or existing route applies;
- which BAPI/FM/source sits underneath;
- what was actually proven at the time;
- whether the decision is **Standard direct**, **Custom exposure** or **Existing route**;
- the minimum implementation still required.

The architectural classifications remain valid. Its **Reality Today** column is dated 22–24 Aug and is now partially stale because the five standard services have since been transported, activated and read-tested in QS4. Use this handover for the updated runtime status.

The matrix also used an earlier numbering alignment. Crosswalk it to the current v1.9 sheet names as follows:

| Decision-matrix row | Current v1.9 sheet |
|---|---|
| `MIGO-02` Submit MIGO | `MIGO-02` Submit MIGO |
| `OF-01` Create DI | `OF-01` Create DI |
| `OF-03` Stock Availability | `OF-02` Stock Availability |
| `OF-05` Pre-PGI | `OF-04` Pre-PGI |
| `OF-06` Create PGI | `OF-05` Create PGI |
| `OF-08` Create Order (STO) | `OF-06` Create Order (STO) |
| `OF-07` Create Invoice | `OF-07` Create Invoice |
| `INV-01` E-Way Bill Extension | `INV-01` E-Way Bill Extension |
| `INV-02` Invoice Correction | `INV-02` Invoice Correction |

### Standard/custom decision summary

| Classification | APIs | Meaning |
|---|---|---|
| **Standard direct** | Submit MIGO, Create DI, Stock Availability, Create PGI | Use the transported SAP standard OData service/action directly. Add CPI/T2 shaping, replay handling and orchestration outside SAP; do not create a redundant ABAP wrapper unless a proven contract gap requires it. |
| **Custom exposure** | Pre-PGI, Create Order (STO), Create Invoice | Standard SAP business logic exists, but the required externally callable boundary does not. Build thin ABAP command services around the named BAPI/FM chain. |
| **Existing route — trace first** | E-Way Bill Extension, Invoice Correction | Existing SAP eDocument/DigiGST/EY logic is installed. Find and reuse its supported callable boundary before building anything new. |
| **Open definition** | Show Inward MRNs | Do not select or build a service until the business object, grain and returned key are settled. |

This is the key design conclusion: **the SAP work is not twelve custom APIs.** Four operations stay on standard OData, three require thin custom exposure, two must reuse or expose an existing statutory route, and one requires business-definition closure.

| v1.9 sheet | Current SAP-side position | Next executable step |
|---|---|---|
| **MIGO-01 Show Inward MRNs** | OPEN. “MRN” is a business term with conflicting definitions. Existing report/CDS logic may provide the source, but the public contract is not settled. | Trace the authoritative CDS/report and agree the MRN identity, grain and key. Then expose/read it without inventing a new SAP document. |
| **MIGO-02 Submit MIGO** | STANDARD-FIRST via `API_MATERIAL_DOCUMENT_SRV;v=1`. Write route reached posting control, no committed document yet. | Open a valid period/test window, post one real receipt, re-read by document/year, then freeze request/response and errors. |
| **OF-01 Create DI** | STANDARD via `API_OUTBOUND_DELIVERY_SRV;v=2`. Positive deep-create route proven. | Turn the proven request into the canonical Postman call, test a clean predecessor, duplicate request and negative data cases, and verify created DI in SAP. |
| **OF-02 Stock Availability** | STANDARD via `API_MATERIAL_STOCK_SRV;v=1`. Real QS4 stock proven. | Define the business filters and response projection for plant/depot/product; test empty, multi-SLoc and authorization cases. |
| **OF-04 Pre-PGI** | CUSTOM exposure required. Standard SAP functions are known: `BAPI_SHIPMENT_CREATE`, `SD_SCDS_CREATE`, `SD_SCDS_RELEASE`. No complete standard web service. | Build `ZCNF_PREPGI_SRV`; prove shipment persistence, shipment-cost creation and release against one authorized dataset. |
| **OF-05 Create PGI** | STANDARD delivery function import `PostGoodsIssue` is known from metadata; execution remains to be certified for the intended flow. | Execute PGI for the created DI, capture response and material-document consequences, then test reversal/retry. |
| **OF-06 Create Order (STO)** | CUSTOM exposure required for the business STO. Standard API reads STO but rejects the required create shape. `BAPI_PO_CREATE1` is the core. | Build `ZCNF_STO_SRV` with validation, commit/rollback, persistence re-read and idempotency ownership; return the authoritative PO number. |
| **OF-07 Create Invoice** | CUSTOM exposure required. Standard Billing API is read-only for document creation. | Build `ZCNF_BILLING_SRV` around the selected released billing creation API, commit, re-read through `API_BILLING_DOCUMENT_SRV`, and return billing/accounting status. |
| **INV-01 E-Way Bill Extension** | OPEN integration boundary. Business fields exist in v1.9; exact SAP/GSP callable route and status persistence are not runtime-certified. | Trace the live e-document/GSP implementation and prove one approved non-production extension request/response before designing a competing service. |
| **INV-02 Invoice Correction** | OPEN integration boundary. UI scope is known; SAP billing/e-document correction mechanism remains unresolved. | Trace current correction/cancel/regenerate implementation and restrict the API to the permitted delta fields. |

---

## 7. Minimum ABAP build programme

Do not build ten custom services. Reuse the five transported standards and build only the missing command boundaries.

### Build 1 — `ZCNF_STO_SRV`

Core:

- `BAPI_PO_CREATE1`
- `BAPI_TRANSACTION_COMMIT` with wait on success
- `BAPI_TRANSACTION_ROLLBACK` on error
- authoritative re-read of `EKKO/EKPO` or the standard PO API after commit

Minimum contract:

- supplying plant, receiving plant, company code, document type, purchasing group, material, quantity, unit, receiving storage location, requested delivery date and requester context;
- response: PO number, item, derived organization/currency/unit fields and normalized SAP messages.

Non-negotiable controls:

- no commit when any `E` or `A` message exists;
- do not trust an allocated number before persistence verification;
- CPI/T2 owns the external idempotency/process key unless SAP persistence is explicitly designed;
- duplicate requests must be tested deliberately.

### Build 2 — `ZCNF_BILLING_SRV`

Preferred released core remains `BAPI_BILLINGDOC_CREATEMULTIPLE`, subject to one final fit test against the actual predecessor and billing type.

Required flow:

1. validate predecessor and billing eligibility;
2. create billing document;
3. commit;
4. re-read through `API_BILLING_DOCUMENT_SRV;v=1`;
5. return billing document plus accounting-transfer state and normalized messages.

Do not copy the entire Billing read model into the create request. Request only caller-owned fields; derive SAP-owned context.

### Build 3 — `ZCNF_PREPGI_SRV`

Core sequence currently expected:

1. `BAPI_SHIPMENT_CREATE`;
2. verify `VTTK` persistence after commit;
3. `SD_SCDS_CREATE`;
4. `SD_SCDS_RELEASE` headless;
5. re-read shipment and shipment-cost document keys/statuses.

Before freezing the wrapper, inspect whether shipment save already triggers part of the freight chain in this configuration. Do not duplicate SAP behavior.

### Possible Build 4/5 — only after trace

- `ZCNF_EWAY_EXT_SRV` only if the existing GSP/e-document route has no supported callable boundary.
- `ZCNF_INVOICE_CORR_SRV` only if the existing correction path has no supported callable boundary.

---

## 8. Immediate execution queue

### Next working session

1. Freeze the five-service Postman collection into clearly labelled folders:
   - metadata/health;
   - positive reads;
   - positive Create DI;
   - Material Document period-blocked write;
   - negative STO create evidence;
   - standard Billing read/PDF.
2. Record actual request and response samples from QS4/DS4; do not substitute invented envelopes.
3. Create the ABAP technical design for `ZCNF_STO_SRV` first because its BAPI route and target document are the clearest custom boundary.
4. Implement a minimal SEGW/RAP-independent OData V2 command surface in the client-approved package and transport path.
5. Unit-test validation and BAPI return handling before any real commit.
6. Execute one authorized STO creation, commit, re-read and downstream Create-DI continuation.

### After the first custom STO succeeds

1. Feed the returned PO into the proven Create-DI standard service.
2. Execute Pre-PGI/PGI against that DI.
3. Execute MIGO when the period/test data permits.
4. Build and execute Billing creation.
5. Run the complete document-flow re-read and reconcile PO → DI → PGI/material document → receipt/material document → billing.

The target is not “an endpoint responded.” The target is an externally initiated business chain whose SAP documents exist, link correctly and can be recovered or reversed when a later stage fails.

---

## 9. Definition of done per API

An API is complete only when all applicable items are true:

- exact versioned route and method frozen;
- request fields mapped to SAP ownership and type;
- CSRF/session behavior documented for writes;
- positive request executed;
- SAP document persisted and independently re-read;
- response contains the authoritative SAP key;
- business and technical errors normalized without hiding SAP evidence;
- duplicate/retry behavior tested;
- authorization failure tested;
- downstream document linkage verified;
- reversal or recovery path documented;
- Postman request, example response and assertions committed;
- transport/package/alias/ICF procedure documented.

Metadata success, HTTP 200 or a BAPI success row alone is not completion.

---

## 10. How to continue with Siddharth

- Lead with the next executable action, not a retrospective.
- Keep instructions screen-specific when he is operating SAP manually.
- Use SAP GUI scripting when repetition is high, but never share a session with concurrent manual actions.
- Do not inflate “callable” into “business-complete.” He needs defensible client language.
- When a standard service is sufficient, use it. When it is not, name the smallest ABAP exposure layer and start building it.
- Maintain momentum: after every successful test, update evidence, freeze the Postman example and immediately begin the next unresolved API.
