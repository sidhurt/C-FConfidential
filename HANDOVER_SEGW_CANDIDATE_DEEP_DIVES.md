# Authoritative handover — CNF standard SAP SEGW candidate deep dives

> **Superseded execution state (2026-08-15):** the 15-project frozen shortlist was an intermediate reduction. The full business-led scan later retained 41 unique candidates and all 11 Tier-A deep dives below were completed. Use this document only for its extraction protocol and historical ranking; use `sessions/2026-08-15-standard-api-discovery/TIER_A_DEEP_DIVE_FINDINGS.md` and `CNF_STANDARD_API_MATRIX.tsv` for conclusions.

**Date frozen:** 2026-08-15  
**Owner:** Siddharth  
**Audience:** the AI agent taking over candidate-by-candidate SAP Gateway Service Builder investigation  
**System:** `QS4` / client `700` / user `QNOVATE8`  
**Primary transaction:** `SEGW`  
**Mission state:** catalogue reduction complete; first sibling-family delta complete; ranked deep dives ready to execute  
**Supersedes for this workstream:** `HANDOVER_STANDARD_API_DISCOVERY.md` wherever this document is newer or more specific

---

## 0. Read this first — the mission in one page

The work is **not** to invent a custom CNF API layer. The current mandate is to identify the smallest defensible set of **SAP-standard services** already delivered in the client's S/4HANA landscape and determine which of them can satisfy the confirmed CNF business operations.

The initial SAP Gateway Service Builder catalogue contains **2,626 SEGW projects**. We exported the catalogue metadata for all 2,626, reduced it to **214 `API_*` projects**, keyword-screened those against the v1.7 CNF demand model, rejected semantic false positives, and froze a **15-project candidate set**:

- **10 Tier A projects** with direct business-object fit;
- **5 Tier B projects** whose relevance depends on unresolved document-model decisions.

Do **not** deep-extract all 2,626 projects. Do **not** treat a keyword hit as proof. Do **not** assume a project with `_0002` is automatically the correct one. Do **not** write another request/response contract before the standard-service selection is complete.

Your job is to take the candidates in the ranked order in this handover and produce, for each one:

1. complete read-only SEGW design-time evidence;
2. exact operation/entity/field surface;
3. sibling/version delta when applicable;
4. local runtime registration/activation status;
5. release-specific official SAP confirmation;
6. a business-operation coverage decision against v1.7;
7. a final status: `KEEP`, `CONDITIONAL`, `REJECT`, or `OUTSIDE-SEGW-GAP`.

The end deliverable is a justified standard-SAP activation/provisioning set—probably about 10–15 services—not a catalogue dump and not a custom implementation design.

---

## 1. Non-negotiable anti-drift rules

These are hard constraints. Violating any of them means the work has drifted.

### 1.1 Standard SAP is the target

- The business has disavowed new custom `ZCNF_*` OData services.
- Existing custom services remain architectural evidence and precedent only.
- Do not reopen the question of whether a custom wrapper would be convenient. It would be convenient; it is not the mandate.
- Standard services may still require CPI/T2 orchestration, idempotency, error shaping, activation, roles and configuration. “Standard” does not mean “zero work.”

### 1.2 The business API list is the spine

- Organize all findings by the v1.7 business operation, not by SAP function import or entity name.
- One v1.7 journey may require several SAP services.
- One SAP service may cover several v1.7 operations.
- A function import such as `PickOneItem` is not a business API and must never become the index of the deliverable.

### 1.3 Name matching is triage, not selection

- Project names and descriptions are powerful for reducing 2,626 projects to a manageable set.
- They do not prove object semantics, supported operations, release status or runtime callability.
- Similar names must be compared as families until their delta is understood.
- Seductive false positives must be rejected even when they contain words such as `DELIVERY`, `STOCK`, `ALLOCATION`, `BILLING`, `GST`, `FREIGHT` or `EDOC`.

### 1.4 “Latest” is not a suffix or a date

- `_0002` and a later `Last changed on` date are evidence of a later design-time generation, not proof that it is the correct endpoint for QS4.
- Determine the external runtime service, version selector, SAP release availability, operation delta and client compatibility.
- A newer service can be broader but unnecessary; an older service can be the locally supported generation.
- Never infer external versioning from generated class names. The outbound-delivery family proves the class suffixes can be counterintuitive.

### 1.5 SEGW metadata is design-time evidence, not runtime truth

SEGW reliably exposes model shape:

- entity types and properties;
- entity sets and declared CRUD flags;
- associations, association sets and navigation properties;
- complex types;
- function imports, HTTP methods, parameters and return types;
- generated runtime artifact names.

SEGW does **not** prove:

- that the service is registered or callable;
- that the ICF node and system alias are active;
- that annotations are enforced by `DPC_EXT`;
- actual mandatory rules, locking, authorization, idempotency or commit behavior;
- application configuration and conditional rules;
- the published `$metadata` contract when an extension class rewrites it.

Whenever local runtime `$metadata` is available, it supersedes design-time annotations.

### 1.6 QS4 is read-only for this mission

Never:

- create, copy or change a project;
- press Save, Generate, Activate or Check;
- register or maintain a service;
- enter or double-click `Service Maintenance`;
- execute a create/update/delete business operation;
- post a goods movement, delivery, billing document, PO, physical-inventory difference or any other business document.

Allowed actions are navigation, project opening, tree expansion, grid reading, catalogue reading, runtime-catalogue comparison and read-only official documentation research.

---

## 2. Authoritative demand model — CNF v1.7

### 2.1 The authoritative workbook

Use this stabilized source:

`sources/SRC-DOC-20260815-01_CNF_API_Request_Response_Specification_v1.7.xlsx`

SHA-256:

`41E67DA30B152F11D25B0315CDD247D7BABB5CC0EC557AE3CA6DEA782311C5A6`

It was copied byte-for-byte from the manager-aligned v1.7 artifact in the older Codex worktree.

**Do not use** `outputs/cnf_api_contract_v17/CNF_API_Request_Response_Specification_v1.7.xlsx.inspect.ndjson` as the numbering authority. That inspection artifact reflects an earlier v1.7 state. Some verification PNG names in that directory are also historical.

The workbook's `Proposed service` column contains old `ZCNF_*` wrapper names. Those names are **obsolete implementation framing**. Use the workbook for business intent, operation boundaries, inputs, outputs and unresolved semantics—not for the proposed custom service architecture.

### 2.2 Current business-operation spine

| ID | Business operation | Class | Standard-service search meaning |
|---|---|---|---|
| API-01 | Submit MIGO | S | Post goods receipt/material document against the relevant delivery/PO context; support storage-location allocations; return material document and fiscal year |
| API-02 | Create DI | S | Create SAP outbound delivery from a sales-order predecessor for Trade/Non-trade or an STO purchase-order predecessor for STO |
| API-03 | Create Invoice / Billing Documents | X | Multi-stage delivery-driven journey: storage-location/SPI, batch/FIFO, shipment, cost, PGI, billing and statutory documents |
| API-04 | Shipment Calculation | X / S | Delivery-driven shipment/freight-cost estimate; exact LE versus TM object unresolved |
| API-05 | Stock Availability | C | Authoritative real-time S/4 stock read; distinguish raw SLoc/batch stock from ATP-calculated availability |
| API-06 | E-Way Bill Extension | S | Extend statutory E-Way Bill validity through the installed India statutory stack/provider |
| API-07 | Invoice Correction | S / X | Correct approved invoice/e-document data and handle cancellation/regeneration; exact SAP document model unresolved |
| API-08 | STO Orders | C / S | Read stock-transport purchase orders for S/4 → CPI → T2 |
| API-09 | STO Deliveries | C / S | Read outbound deliveries whose predecessor is an STO purchase order |
| API-10 | STO Invoice | C / S | Read invoices associated with STO dispatches; SD billing versus MM supplier invoice remains a hard gate |
| API-11 | Create STO Purchase Order | S candidate | Create the STO PO used only by the intra-warehouse/STO journey |
| API-12 | Update DI Quantity | S candidate | Narrow quantity-only change to an existing open outbound delivery before batch determination |

### 2.3 Business distinctions that must survive the technical analysis

- **MIGO versus delivery processing:** a delivery API can expose goods-receipt actions, while the material-document API creates the accounting/material document. Compare both; do not collapse them.
- **Physical stock versus ATP:** `API_MATERIAL_STOCK` exposes on-hand/accounting stock dimensions; `API_PRODUCT_AVAILY_INFO_BASIC` calculates ATP availability. They answer different questions.
- **SD billing versus MM supplier invoice:** API-10 cannot be assigned until the authoritative STO invoice object is confirmed.
- **Billing creation versus billing read/cancel:** the local OData V2 billing project is not automatically the creation API.
- **Portal journey versus SAP LUW:** API-03 is one user journey, not proof of one atomic SAP operation.
- **E-Way/e-Invoice versus form output:** a GST form-data provider is not a statutory transaction API.

---

## 3. What has been done

### 3.1 Full SEGW project catalogue acquisition

Using the SEGW `Open Project` value help:

1. open Project → Open;
2. invoke project value help;
3. choose `Restrict Values`;
4. set `Restrict Number To` to `9999`—not 999;
5. continue to the complete result.

The screen returned exactly **2,626 projects**.

Exported catalogue fields:

- Project
- Created by
- Created on
- Last changed by
- Last changed on
- Description

Evidence:

`sources/SRC-SYS-20260815-01_QS4_700_SEGW_PROJECT_CATALOG/SEGW_PROJECT_CATALOG.tsv`

This is catalogue metadata only. It is **not** the internals of all 2,626 projects.

### 3.2 Reduction results

- Total SEGW projects: **2,626**
- Created by SAP: **2,607**
- `API_*` project prefix: **214**
- Initial keyword hits among `API_*`: **32**
- Final candidate projects: **15**
- True versioned sibling families in the final set: outbound delivery and inbound delivery

Working reduction evidence:

- `sources/SRC-SYS-20260815-01_QS4_700_SEGW_PROJECT_CATALOG/CNF_KEYWORD_HITS.tsv`
- `sources/SRC-SYS-20260815-01_QS4_700_SEGW_PROJECT_CATALOG/CNF_EXACT_ROOT_CHECK.tsv`
- `sources/SRC-SYS-20260815-01_QS4_700_SEGW_PROJECT_CATALOG/CNF_SIBLING_FAMILIES.tsv`
- `sessions/2026-08-15-standard-api-discovery/CNF_DEEP_DIVE_SHORTLIST.md`

### 3.3 First complete sibling delta

Completed:

`API_OUTBOUND_DELIVERY` versus `API_OUTBOUND_DELIVERY_0002`

Evidence directories:

- `sources/SRC-SYS-20260815-02_QS4_700_SEGW_API_OUTBOUND_DELIVERY/`
- `sources/SRC-SYS-20260814-01_QS4_700_SEGW_API_OUTBOUND_DELIVERY_0002/`

Delta report:

`sessions/2026-08-15-standard-api-discovery/OUTBOUND_DELIVERY_DELTA.md`

Verified design-time surface:

| Surface | Base | `_0002` | Delta |
|---|---:|---:|---:|
| Entity types | 7 | 13 | +6 |
| Complex types | 2 | 4 | +2 |
| Associations | 6 | 14 | +8 |
| Entity sets | 7 | 13 | +6 |
| Association sets | 6 | 13 | +7 |
| Function imports | 6 | 15 | +9 |
| Runtime artifacts | 6 | 6 | 0 |

The six base function imports are retained:

- `ConfirmPickingAllItems`
- `ConfirmPickingOneItem`
- `PickAllItems`
- `PickOneItem`
- `PostGoodsIssue`
- `ReverseGoodsIssue`

`_0002` adds:

- `AddSerialNumberToDeliveryItem`
- `CreateBatchSplitItem`
- `DeleteAllHandlingUnitsFromDelivery`
- `DeleteAllSerialNumbersFromDeliveryItem`
- `DeleteSerialNumberFromDeliveryItem`
- `PickAndBatchSplitOneItem`
- `PickOneItemWithBaseQuantity`
- `PickOneItemWithSalesQuantity`
- `SetPickingQuantityWithBaseQuantity`

It also adds handling-unit, header/item-text, alternate-address and value-added-service entities.

Both projects expose the **same** model/service artifact names:

- `API_OUTBOUND_DELIVERY_MDL`
- `API_OUTBOUND_DELIVERY_SRV`

Their generated class families differ:

| Artifact | Base project | `_0002` project |
|---|---|---|
| DPC | `CL_API_OUTBOUND_DEL_02_DPC` | `CL_API_OUTBOUND_DELIVE_DPC` |
| DPC_EXT | `CL_API_OUTBOUND_DEL_02_DPC_EXT` | `CL_API_OUTBOUND_DELIVE_DPC_EXT` |
| MPC | `CL_API_OUTBOUND_DEL_02_MPC` | `CL_API_OUTBOUND_DELIVE_MPC` |
| MPC_EXT | `CL_API_OUTBOUND_DEL_02_MPC_EXT` | `CL_API_OUTBOUND_DELIVE_MPC_EXT` |

Do not infer service version from those class names.

Current conclusion:

- `_0002` is the later and materially broader design-time generation.
- It is the stronger CNF candidate for batch split, serial, handling-unit and unit-specific picking requirements.
- The base project already covers basic picking, PGI and reversal.
- Final selection still requires QS4 release/runtime mapping and registration/activation evidence.

---

## 4. Candidate ranking and target order

### 4.1 Tier A — full deep dives

| Rank | Project | Last changed | v1.7 fit | Status / purpose |
|---:|---|---:|---|---|
| 1 | `API_OUTBOUND_DELIVERY_0002` | 19.05.2022 | API-02, API-03, API-09, API-12 | Deep extraction complete; resolve runtime/version and create-from-reference applicability |
| 2 | `API_OUTBOUND_DELIVERY` | 17.05.2018 | Same family | Deep extraction and delta complete; likely legacy/narrower generation |
| 3 | `API_INBOUND_DELIVERY_0002` | 05.04.2022 | API-01 receiving/MIGO | **Next target.** Official family includes goods receipt/reversal, putaway, serial and batch operations |
| 4 | `API_INBOUND_DELIVERY` | 29.01.2021 | Same family | Extract immediately with `_0002`; produce exact sibling delta |
| 5 | `API_MATERIAL_DOCUMENT` | 24.02.2022 | API-01; PGI/GR document reads | Closest standard object to MIGO; validate reference fields, SLoc allocations, movement types, document/year response |
| 6 | `API_MATERIAL_STOCK` | 03.05.2017 | API-05; batch/FIFO input | Strongest raw stock candidate; validate plant/SLoc/batch/stock-type fields and ageing/FIFO feasibility |
| 7 | `API_PRODUCT_AVAILY_INFO_BASIC` | 14.03.2017 | API-05 alternative | ATP-calculated availability candidate; compare meaning against raw stock |
| 8 | `API_PURCHASEORDER_PROCESS` | 04.08.2021 | API-08, API-11 | Direct PO create/read candidate; validate STO document type/item category and local V2 capability |
| 9 | `API_BILLING_DOCUMENT` | 19.02.2020 | API-03, API-07, API-10 | Direct SD billing read/cancel/PDF surface; determine real billing creation and STO invoice object |
| 10 | `API_SALES_ORDER` | 24.05.2022 | API-02 predecessor | Validate Trade/Non-trade predecessor read, open quantity and document-flow navigation |

### 4.2 Tier B — gated, targeted inspections

Do not spend equal effort on these. Apply their gate first.

| Rank | Project | Gate | Expected direction |
|---:|---|---|---|
| 11 | `API_BILLING_DOCUMENT_REQUEST` | CNF must genuinely use SD billing document requests | Official V2 purpose is read/reject/delete BDRs; likely reject as invoice-creation substitute |
| 12 | `API_PHYSICAL_INVENTORY_DOC` | Reconciliation must include PI documents/counts/differences | Strong PI API, but broader than current API-05 read-only stock scope |
| 13 | `API_SUPPLIERINVOICE_PROCESS` | API-10 STO Invoice must be an MM supplier invoice | Keep only if MM confirms this document model |
| 14 | `API_CREDIT_MEMO_REQUEST` | Finance must model API-07 as a credit memo request | Current vehicle/transporter/e-document correction fields do not prove it |
| 15 | `API_DEBIT_MEMO_REQUEST` | Finance must model API-07 as a debit memo request | Same gate as credit memo request |

### 4.3 Exact execution sequence from here

1. `API_INBOUND_DELIVERY` versus `API_INBOUND_DELIVERY_0002`
2. `API_MATERIAL_DOCUMENT`
3. `API_MATERIAL_STOCK`
4. `API_PRODUCT_AVAILY_INFO_BASIC`
5. `API_PHYSICAL_INVENTORY_DOC` as the reconciliation comparator
6. `API_PURCHASEORDER_PROCESS`
7. `API_BILLING_DOCUMENT`
8. shallow rejection comparison: `API_BILLING_DOCUMENT_REQUEST`
9. document-model comparison: `API_SUPPLIERINVOICE_PROCESS`
10. `API_SALES_ORDER`
11. credit/debit memo projects only after the Finance gate is answered

The outbound pair is already complete and should not be re-extracted unless a verification defect is found.

---

## 5. How ranking works — the decision protocol

Do not invent a numerical score that creates false precision. Apply these gates in order.

### Gate 1 — business-object identity

Does the SAP project represent the same SAP business object as the v1.7 operation?

Examples:

- outbound delivery versus customer returns delivery: different object/process;
- SD billing document versus supplier invoice: different object;
- material stock versus product allocation configuration: different meaning;
- eDocument cockpit versus E-Way extension command: different role.

Wrong object means `REJECT`, regardless of keyword strength.

### Gate 2 — required operation coverage

Does the project expose the needed verbs/actions?

Examples:

- API-01 needs posting, not merely reading a delivery;
- API-02 needs create-from-predecessor, not only delivery retrieval;
- API-03 needs picking/batch/PGI plus a separate billing-creation path;
- API-07 may need cancel/regenerate, not only invoice retrieval;
- API-11 needs PO create, not a purchase-order popover.

Classify each business operation as:

- `DIRECT`
- `PARTIAL`
- `NO FIT`
- `UNPROVEN`

### Gate 3 — data and relationship fit

Check the exact fields and relationships required by v1.7:

- predecessor document and category;
- delivery item and open quantity;
- plant, storage location, batch and stock type;
- material document plus fiscal year;
- STO PO ↔ delivery ↔ invoice document flow;
- PGI/GR status and dates;
- billing cancellation/status;
- SLoc/batch stock versus ATP availability.

Presence of a property does not prove it is creatable/updatable or application-valid. Capture annotations and label behavior `UNPROVEN` until official/runtime evidence confirms it.

### Gate 4 — sibling and release fit

For families such as base versus `_0002`:

- compare complete model counts;
- list added/removed entity types and sets;
- compare CRUD annotations;
- list added/removed/changed function imports and parameters;
- compare common property definitions;
- compare runtime artifact names;
- map to official `;v=<n>` selectors;
- pin documentation to S/4HANA 2022/on-premise applicability.

### Gate 5 — local runtime viability

Determine separately:

- project exists in SEGW;
- runtime artifact exists in design time;
- service is registered in the 522-row Gateway catalogue;
- service version/system alias/ICF node is active;
- local `$metadata` can be read;
- Basis activation is required.

An unregistered but functionally perfect service remains a `KEEP` candidate with an activation requirement. Do not replace it with a semantically wrong registered service.

### Gate 6 — standard/released proof

Cross-check official SAP documentation:

- technical service name;
- API version and protocol version;
- supported operations;
- release availability/deprecation;
- restrictions and supported document types;
- successor API, including OData V4 services outside SEGW.

Final candidate outcomes:

- `KEEP-PRIMARY`
- `KEEP-SIBLING-BASELINE`
- `CONDITIONAL-BUSINESS-GATE`
- `REJECT-WRONG-OBJECT`
- `REJECT-MISSING-OPERATION`
- `OUTSIDE-SEGW-GAP`

---

## 6. Known false positives — do not resurrect them

| Project/family | Why rejected |
|---|---|
| `API_PRODUCT_ALLOC_SEQUENCE` | Product-allocation sequence configuration is not depot stock, FIFO batch allocation or physical inventory |
| `API_PRODUCT_ALLOCATION_OBJECT` | Same semantic mismatch as above |
| `API_CUSTOMER_RETURNS_DELIVERY` | CNF is not a customer-returns flow |
| `API_CUSTOMER_RETURNS_DLV_0002` | Same returns mismatch; version similarity is irrelevant |
| `API_DEL_DOC_WITH_CREDIT_BLOCK` | Credit-block worklist, not general delivery processing |
| `API_SUBSQNT_BILLG_DOC_SBI` | Self-billing-specific display; no CNF self-billing requirement established |
| `API_CN_VAT_INVOICE` | China localization, wrong country/process |
| `API_JVA_BILLING` | Joint Venture Accounting billing, wrong module |
| `FDP_GST_INV_GLO_IN` | India GST form data provider, not an A2X statutory transaction API |
| `EDOC_DCC` | Document Compliance Cockpit service; useful installed-framework evidence, not proven E-Way extension API |
| `/SCMTMS/FO_CONFIRMATION` | Freight-order confirmation, not general shipment-cost calculation |
| `/SCMTMS/FRT_PROCUREMENT` | TM strategic freight procurement, wrong operation |
| `TM_FRT_CALCERROR` | Freight-calculation error UI/service, not cost-estimation API |

Name matches outside `API_*` are usually UI, analytical, form-data-provider or localization projects. Promote one only with direct operation evidence.

---

## 7. Gaps SEGW cannot close by itself

### 7.1 E-Way Bill and e-Invoice

The 2,626-project catalogue contains no credible `API_*` SEGW project for E-Way Bill extension or e-Invoice regeneration.

Known landscape evidence from the wider project:

- SAP eDocument framework is installed;
- `EDOC_DCC_SRV` is registered as a cockpit service;
- DigiGST/EY provides the India statutory layer;
- numerous `EY_*` destinations cover e-Invoice and E-Way operations, including extension and Part-B-related actions.

Therefore:

- do not force `EDOC_DCC` or a GST form provider into the shortlist;
- investigate SAP DRC/eDocument plus the configured DigiGST/EY integration;
- treat this as `OUTSIDE-SEGW-GAP` until a real callable interface is identified.

### 7.2 Billing creation

Local SEGW project:

`API_BILLING_DOCUMENT`

The official OData V2 service is principally read/cancel/PDF (and pro-forma completion in later releases). Current SAP documentation also describes an OData V4 service:

`API_BILLINGDOCUMENT`

The V4 service supports creation from an SD document. OData V4 service definitions do not appear as SEGW projects. Do not conclude “no standard creation API” from the SEGW catalogue alone. Check whether the V4 service exists and is supported in QS4/S/4HANA 2022.

### 7.3 Purchase Order successor

Local SEGW project:

`API_PURCHASEORDER_PROCESS`

SAP now documents the OData V2 service as deprecated in environments where its V4 successor exists. That does not prove the successor is available in this S/4HANA 2022 client. Keep the V2 candidate until local release/service-binding evidence is obtained.

### 7.4 Shipment/freight cost

No released `API_*` SEGW candidate is evident by name. Before selecting anything, establish whether the client uses:

- classic LE shipment and shipment-cost documents;
- embedded Transportation Management/freight orders;
- a standard BAPI/function module;
- an external transport-cost engine.

Do not infer this from generic `SHIPMENT`, `FREIGHT` or `/SCMTMS/` project names.

---

## 8. Local runtime catalogue and activation model

There are two different inventories. Never mix them.

### 8.1 Design-time/project catalogue

- Source: SEGW Open Project value help
- Count: **2,626 projects**
- Meaning: projects delivered/available in the software stack
- Evidence: `sources/SRC-SYS-20260815-01_QS4_700_SEGW_PROJECT_CATALOG/SEGW_PROJECT_CATALOG.tsv`

### 8.2 Registered Gateway catalogue

- Source: earlier read-only Gateway service catalogue extraction
- Count: **522 registered services**
- Evidence: `sources/SRC-SYS-20260805-02_QS4_700_GATEWAY_SERVICE_CATALOG.xlsx`
- Normalized analysis: `tmp/segw_workbook_20260805/catalog_analysis.json`
- Cleaned table: `tmp/segw_workbook_20260805/cleaned_catalog.tsv`

Exactly **seven** registered external service names begin with `API_*`:

1. `API_BUSINESS_PARTNER`
2. `API_CV_ATTACHMENT_SRV`
3. `API_MAINTNOTIFICATION`
4. `API_MAINTORDERCONFIRMATION`
5. `API_PROC_ORDER_CONFIRMATION_2_SRV`
6. `API_PROCESS_ORDER_2_SRV`
7. `API_SALES_ORDER_SRV`

The following key CNF candidates are confirmed **not registered** in that catalogue:

- `API_OUTBOUND_DELIVERY_SRV`
- `API_BILLING_DOCUMENT_SRV`
- `API_MATERIAL_DOCUMENT_SRV`
- `API_MATERIAL_STOCK_SRV`

The label `Registered Service` inside a SEGW Runtime Artifacts grid describes the generated artifact type. It is not proof of active Gateway registration.

Registration/activation is a Basis provisioning decision, not permission for this agent to use Service Maintenance.

---

## 9. SAP GUI scripting protocol

### 9.1 Current live state at handover freeze

Verified 2026-08-15 after Siddharth authenticated:

- connection: `/app/con[0]`
- session: `/app/con[0]/ses[0]`
- system: `QS4`
- client: `700`
- user: `QNOVATE8`
- transaction: `SEGW`
- program: `/IWBEP/SAPLFG_SBUI_SB_MAIN`
- screen: `100`
- windows: one; no modal
- running `cscript.exe`: zero after audit
- open, currently unexpanded root projects:
  - `API_BILLING_DOCUMENT`
  - `API_OUTBOUND_DELIVERY`
  - `API_OUTBOUND_DELIVERY_0002`

This state is ephemeral. Always re-probe.

### 9.2 Preflight every SAP interaction

```powershell
Get-CimInstance Win32_Process -Filter "Name='cscript.exe'" |
  Select-Object ProcessId, CreationDate, CommandLine

& "$env:WINDIR\System32\cscript.exe" //nologo ".\tmp\sap_probe.vbs"
```

Proceed only when the target session shows:

- `System=QS4`
- `Client=700`
- `User=QNOVATE8`
- `Transaction=SEGW`

If the SAP screen is logged out, stop and let Siddharth authenticate. Never type or request the password through a script.

### 9.3 Use 64-bit Windows Script Host

Use:

`%WINDIR%\System32\cscript.exe`

PowerShell COM calls to the SAP scripting engine have failed on this machine. VBScript through 64-bit `cscript.exe` works.

### 9.4 Never hardcode the connection index

Connection ids have changed between sessions. Scripts must select a connection that currently exposes a child session. Re-run `sap_probe.vbs` after reconnects.

### 9.5 Open a project safely

Use:

```powershell
& "$env:WINDIR\System32\cscript.exe" //nologo `
  ".\tmp\sap_segw_open_named_project.vbs" `
  "API_INBOUND_DELIVERY_0002"
```

The script uses Project → Open. Do not double-click arbitrary tree nodes to open projects.

If SAP says the project is already open, cancel/close only the modal. `tmp/sap_close_modals.vbs` is the safe cancel helper.

### 9.6 Export a project tree

Create a source directory following this pattern:

`sources/SRC-SYS-YYYYMMDD-NN_QS4_700_SEGW_<PROJECT>/`

Then:

```powershell
& "$env:WINDIR\System32\cscript.exe" //nologo `
  ".\tmp\sap_segw_export_project.vbs" `
  EXPAND `
  ".\sources\SRC-SYS-YYYYMMDD-NN_QS4_700_SEGW_<PROJECT>" `
  "<PROJECT>"
```

The SEGW tree loads lazily. The exporter repeatedly attempts scoped expansion until no new nodes appear.

Important nuance: the script scopes **expansion** to the target project but writes every currently loaded root to `SEGW_TREE.tsv`. When analyzing, filter `Path` to:

- exact project name; or
- prefix `<PROJECT> > `.

### 9.7 Export all model grids

```powershell
& "$env:WINDIR\System32\cscript.exe" //nologo `
  ".\tmp\sap_segw_export_all_grids.vbs" `
  ".\sources\SRC-SYS-YYYYMMDD-NN_QS4_700_SEGW_<PROJECT>" `
  "<PROJECT>"
```

The exporter is deliberately read-only and excludes `Service Maintenance`.

It captures container grids for:

- entity types;
- entity-set properties;
- entity properties and navigation properties;
- complex types;
- associations and association sets;
- function imports;
- function-import parameters;
- referential constraints when present;
- runtime artifacts.

### 9.8 ALV virtualization fix

SAP ALV can report the full row count while returning blank data for off-screen rows. The current exporter scrolls every 15 rows before reading cells. Do not remove this.

The outbound evidence was regenerated after this fix. Header/item property grids now contain no virtualization blanks.

### 9.9 Windows path-length fix

The source paths are long. Generated grid filenames are truncated to 70 characters to remain below legacy Windows `MAX_PATH` limits.

Always use `GRID_MANIFEST.tsv` to map a full node path to the correct current file.

Earlier reruns left some orphan/older grid files:

- base outbound grid directory: 36 physical files, 29 current manifest rows;
- `_0002` grid directory: 78 physical files, 52 current manifest rows.

**The manifest is authoritative.** Ignore files not referenced by it.

### 9.10 Encoding

The SAP-generated TSV evidence is UTF-16. PowerShell normally recognizes the BOM:

```powershell
Import-Csv -LiteralPath '<file>.tsv' -Delimiter "`t"
```

### 9.11 Timeouts and background processes

A shell timeout does not always mean `cscript.exe` stopped. Before rerunning an exporter, check the process list. Never allow two scripts to drive the same SAP session.

### 9.12 Never enter Service Maintenance

A previous double-click on `Service Maintenance` opened a Create Project dialog and caused an unauthorized write attempt. SAP rejected it, but the path is unsafe.

The current exporters explicitly skip it. Preserve that exclusion.

---

## 10. Deep-dive evidence specification

Every Tier A project must produce this structure:

```text
sources/SRC-SYS-YYYYMMDD-NN_QS4_700_SEGW_<PROJECT>/
├── SEGW_TREE.tsv
├── GRID_MANIFEST.tsv
└── grids/
    ├── Data_Model__Entity_Types.tsv
    ├── Data_Model__Entity_Sets.tsv
    ├── Data_Model__Associations.tsv
    ├── Data_Model__Function_Imports.tsv
    ├── Runtime_Artifacts.tsv
    └── ...
```

Create a report under:

`sessions/2026-08-15-standard-api-discovery/<PROJECT>_DEEP_DIVE.md`

For sibling families, create:

`sessions/2026-08-15-standard-api-discovery/<FAMILY>_DELTA.md`

### 10.1 Required report sections

1. **Project identity**
   - project name
   - catalogue description
   - created/changed dates
   - SAP creator
2. **Runtime identity**
   - model name
   - service name
   - DPC/DPC_EXT/MPC/MPC_EXT classes
   - version selector if officially documented
3. **Model counts**
   - entity types
   - entity sets
   - complex types
   - associations
   - association sets
   - function imports
4. **Entity-set operation matrix**
   - creatable
   - updatable
   - deletable
   - pageable/addressable/searchable
5. **Function-import matrix**
   - name
   - HTTP method
   - action-for entity
   - parameters and types
   - return kind/type/cardinality
6. **Business-critical entity/property mapping**
   - only properties relevant to the mapped v1.7 operation
   - keep the full TSV evidence; do not paste hundreds of irrelevant fields into the narrative
7. **v1.7 coverage matrix**
   - `DIRECT`, `PARTIAL`, `NO FIT`, `UNPROVEN`
8. **Local registration status**
   - present/absent in the 522-row catalogue
   - never infer from Runtime Artifacts
9. **Official SAP confirmation**
   - release-specific documentation
   - supported operations/restrictions
   - V2/V4 successor note
10. **Gaps and decisions**
    - exact missing operations/fields
    - activation requirement
    - unresolved functional gate
11. **Final disposition**
    - one of the controlled statuses in §5

### 10.2 Confidence labels

Every consequential statement should be traceable to one of these evidence classes:

- `LOCAL-DESIGN` — extracted from QS4 SEGW
- `LOCAL-RUNTIME` — registered catalogue or local `$metadata`
- `SAP-OFFICIAL` — release-specific SAP documentation
- `BUSINESS-DEMAND` — authoritative v1.7 workbook or approved functional source
- `INFERENCE` — reasoned conclusion; explicitly labeled and never presented as fact

Never merge `LOCAL-DESIGN` and `SAP-OFFICIAL` into a claim that something works in QS4 unless local runtime evidence exists.

---

## 11. Sibling-family delta protocol

When two similarly named projects exist, compare them mechanically before recommending either.

### 11.1 Required comparisons

- catalogue dates and descriptions;
- runtime service/model names;
- entity-type and entity-set names;
- added/removed complex types;
- association/navigation changes;
- entity-set CRUD changes;
- added/removed function imports;
- shared function-import parameter changes;
- added/removed properties on common entity types;
- contract annotation changes on common properties;
- generated class families;
- official API version selector and release history;
- local registration/activation status.

### 11.2 Existing comparison helper warning

`tmp/compare_segw_projects.ps1` generated the outbound-delivery delta successfully, but its report title, catalogue dates and narrative are hardcoded for the outbound family.

Do **not** run it unchanged for inbound delivery. Use it as a parsing/template reference and create or patch a generic family comparer through `apply_patch`.

### 11.3 Recommendation rule

Recommend the later sibling only when its added surface is required or it is the release-supported official version for this client. A larger model is not inherently better.

---

## 12. Official SAP documentation starting points

Always select the S/4HANA 2022/on-premise documentation variant when available. Current-cloud pages are useful for API identity and successor discovery but do not prove local availability.

- Outbound Delivery operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/588780cab2774a7ab9fffca3a7f919fe/a4c5d84ecef2494985883829a24e393c.html`
- Inbound Delivery operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/588780cab2774a7ab9fffca3a7f919fe/f3ff58c5e7ec43c7b55a503be6633567.html`
- Material Document operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/3f57e7df4a114edabffe8b2d581a59ed/1aef4e402acd4c8b8ec2ea2bfda7715b.html`
- Material Stock operations:  
  `https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/eb2a39dd0c124fed8252f684002d55e1/dfc5b3e292874297843ed6cfb08eb83a.html`
- Basic Product Availability Info:  
  `https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/15f9e51998a945cc82545cb6b4dbe5c2/ba15d698dd474a57ad340f9acff13b99.html`
- Purchase Order V2 operations:  
  `https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91af7f8d3acd47da90d33aaacfcd0d59/46dcde53d7964b768dcf75f97f4e3db9.html`
- Purchase Order V2 deprecation note:  
  `https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91af7f8d3acd47da90d33aaacfcd0d59/acd2da57df6cc525e10000000a4450e5.html`
- Billing Document V2 read/cancel/PDF operations:  
  `https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/19d48293097f4a2589433856b034dfa5/a9120b013c9a44efaf417e1a66704901.html`
- Billing Document V4 operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/03c04db2a7434731b7fe21dca77440da/7ec99247a48e4c12bbe02e7a63ae9dbc.html`
- Billing Document Request V2:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/03c04db2a7434731b7fe21dca77440da/ddcccb0282774476869bc499812cf793.html`
- Physical Inventory Document operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/3f57e7df4a114edabffe8b2d581a59ed/05902cf186d2490f974a72b465e7a89b.html`
- Supplier Invoice operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/bb9f1469daf04bd894ab2167f8132a1a/d8b16ace9227447c8c66086bc045a937.html`
- Sales Order V2 operations:  
  `https://help.sap.com/docs/SAP_S4HANA_CLOUD/03c04db2a7434731b7fe21dca77440da/17f4a94ed364458ba96b399d43fd1779.html`

Use only primary SAP sources for technical behavior claims.

---

## 13. Evidence integrity notes

### 13.1 Outbound tree files include multiple open roots

Current counts after the final reruns:

| Evidence directory | Total tree rows | Target-project rows | Current manifest rows |
|---|---:|---:|---:|
| `...API_OUTBOUND_DELIVERY` | 500 | 498 | 29 |
| `...API_OUTBOUND_DELIVERY_0002` | 1,320 | 821 | 52 |

Filter by `Path` prefix. The extra rows are the other projects open in the same SEGW workbench.

### 13.2 Do not extend the rejected pilot workbook

`deliverables/SAP_API_OUTBOUND_DELIVERY_SRV_Request_Response.xlsx` was built prematurely from one project and is scrap for this mission.

Do not extend it, cite it as the project contract or reproduce its artifact-centric layout.

### 13.3 Older handovers are contextual, not current control documents

- `HANDOVER_STANDARD_API_DISCOVERY.md` remains useful for original scripting lessons and the first pilot narrative.
- Its old demand list/numbering is superseded by the stabilized v1.7 workbook and this handover.
- Its statement that ten `API_*` services are registered is corrected here: the normalized 522-row catalogue contains exactly seven.
- `HANDOVER_AI.md` remains the broader architecture/evidence handover, but it predates the 2,626-project reduction and 15-project shortlist.

---

## 14. Open questions that control candidate decisions

Do not answer these by inference.

1. **MIGO document reference:** Does API-01 post against an inbound delivery, outbound delivery, STO PO, or a combination by scenario?
2. **Multiple SLoc allocations:** Can the selected standard operation post the validated multi-storage-location receipt payload in one business attempt?
3. **Create DI:** Which local/released outbound-delivery version supports creation from both sales order and STO PO in S/4HANA 2022?
4. **Stock meaning:** Does API-05 need raw storage-location/batch stock, ATP-calculated availability, or both as separate views?
5. **FIFO age:** Which standard source exposes batch receipt/age data required for FIFO ordering?
6. **STO document type:** Is the client STO PO type supported by the standard PO API, and what item category/plant mapping is required?
7. **STO Invoice object:** SD billing document, intercompany billing, GST stock-transfer document, or MM supplier invoice?
8. **Billing creation:** Is the OData V4 billing API locally available in 2022, or is another released service/BAPI required?
9. **Shipment model:** classic LE or Transportation Management?
10. **Statutory interface:** Which eDocument/DigiGST/EY interface owns E-Way extension and invoice correction/regeneration?
11. **Activation:** Which shortlisted services will Basis approve and activate in DEV/QA?
12. **OData V4 discovery:** Which relevant V4 service bindings exist outside the SEGW catalogue?

---

## 15. Definition of done for the takeover agent

The deep-dive phase is complete only when:

- all 10 Tier A projects have design-time evidence and reports;
- both delivery sibling-family deltas are complete;
- Tier B projects have either a gate answer or an explicit deferred/conditional status;
- every v1.7 operation maps to one or more standard services or a named gap;
- every retained service has an exact runtime technical name and version;
- every retained service has local registration/activation status;
- V2/V4 successor issues are documented without assuming latest-cloud availability in QS4;
- false positives remain rejected with reasons;
- the final shortlist is justified by operations and data, not names;
- an activation/provisioning list is ready for Basis;
- no custom contract workbook has been created prematurely;
- no SAP object or business data has been changed.

The final output should answer, for each v1.7 business operation:

> Which SAP-standard service(s) are the best fit, which exact operations cover it, what remains uncovered, which version applies to QS4, and what must Basis activate?

---

## 16. Immediate start instructions

The next agent should begin here:

1. Read this document completely.
2. Read:
   - `sessions/2026-08-15-standard-api-discovery/CNF_DEEP_DIVE_SHORTLIST.md`
   - `sessions/2026-08-15-standard-api-discovery/OUTBOUND_DELIVERY_DELTA.md`
3. Re-probe SAP and confirm `QS4/700/QNOVATE8/SEGW`.
4. Open `API_INBOUND_DELIVERY` and `API_INBOUND_DELIVERY_0002` via the safe menu script.
5. Create separate evidence directories and export both trees/grids.
6. Build a generic sibling comparer from the outbound comparison template.
7. Produce `INBOUND_DELIVERY_DELTA.md`.
8. Map inbound operations against API-01 Submit MIGO and state exactly what remains unproven.
9. Continue to `API_MATERIAL_DOCUMENT`.

Do not pause after merely collecting files. Collection is not analysis. Each target must end in a controlled evidence-backed disposition.

---

## 17. Final intent statement

This project is a reduction and proof exercise:

```text
2,626 SEGW projects
        ↓ catalogue metadata and SAP ownership
214 API_* projects
        ↓ v1.7 business-object keywords
32 raw hits
        ↓ semantic rejection and sibling grouping
15 candidate projects
        ↓ design-time extraction + official release evidence + runtime status
~10–15 justified standard services
        ↓ Basis activation/provisioning + architecture assignment
CNF business-operation coverage
```

The standard SAP artifact is the answer to a business need; it is never the starting index of the design.

Stay disciplined. Preserve the evidence chain. Reject attractive nonsense quickly. Go deep only where the business object and required operation survive the gates.
