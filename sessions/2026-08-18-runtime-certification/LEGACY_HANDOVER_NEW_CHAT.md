# Legacy handover prompt — CNF API/BAPI runtime certification

You are continuing a live SAP investigation in a brand-new chat. Treat this document as the authoritative handover. Do not restart discovery from zero and do not merely re-prove that the services are activated.

## Objective

Finish the runtime research and certification of the CNF C&F Agent OData services and standard BAPIs in SAP DS4 client 200. Produce exact request/response evidence, safe BAPI test variants, business-behavior findings, and a clear list of tests that remain blocked by missing DEV data or require explicit approval because they create/change/post SAP documents.

The contract source is:

`deliverables/CNF_API_Request_Response_Specification_v1.8.xlsx`

Only use the current repository and evidence from approximately the last 3–4 days unless an older artifact is explicitly referenced by the current evidence. Read the full relevant folder before acting, but prioritize the paths listed below.

## Why the earlier investigation was insufficient

An earlier investigation mostly repeated activation and `$metadata` checks that had already been completed. It generated a useful evidence folder but did not perform the BAPI interface research or test the business behavior requested in the workbook. It also treated empty HTTP 200 responses too generously: an empty result proves that the route and that particular request were accepted, but it does not prove row-level authorization, useful business data, or functional suitability.

Do not spend the next run reactivating services or repeatedly fetching the same metadata. Activation and metadata reachability are already proven. Continue from the captured interfaces, DDIC structures, payloads, and safe runtime tests.

## Live system and hard facts

- SAP system: `DS4`
- Client: `200`
- SAP user used for evidence: `QNOVATE8`
- SAP GUI scripting works.
- The session may or may not still be logged in when this new chat starts; verify read-only before using it.
- No OData write, BAPI posting, commit, delivery creation, shipment creation, goods movement, billing creation/cancellation, or document change has been executed during this certification run.
- Service registration was done locally with `$TMP`; there is no transport created by this run. Do not claim that target systems will receive these registrations automatically.
- The QS4 reference documents do not exist as a usable equivalent chain in DS4/200.

## OData work already completed — do not repeat without a specific reason

All seven requested services returned HTTP 200 for `$metadata` in DS4/200:

1. `API_MATERIAL_DOCUMENT_SRV` v1
2. `API_OUTBOUND_DELIVERY_SRV` **v2**
3. `API_BILLING_DOCUMENT_SRV` v1
4. `API_PURCHASEORDER_PROCESS_SRV` v1
5. `API_MATERIAL_STOCK_SRV` v1
6. `MMIM_MATDOC_SRV` v1
7. `SD_CUSTOMER_INVOICES_CREATE` v1

The delivery runtime path is exactly:

`/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/`

Version 2 exposes the required batch-split operations. Runtime metadata corrected several workbook/design-time assumptions:

- `PickAndBatchSplitOneItem` is POST and has five parameters, including `SplitQuantityUnit`.
- `CreateBatchSplitItem` is POST and has six parameters, including `PickQuantityInSalesUOM`.
- Delivery operational function imports are POSTs.
- Billing `GetPDF` is GET.
- Purchase-order navigation is `to_PurchaseOrderItem` followed by `to_ScheduleLine`.
- Material-document navigation is `to_MaterialDocumentItem`.
- Delivery header navigation is `to_DeliveryDocumentItem`.
- Billing header navigation is `to_Item`.

Read probes already produced HTTP 200 with empty collections for stock, purchase orders, and deliveries. A new filtered stock call for `MAT18 / PLQ3` also returned an empty collection. Do not reinterpret an empty collection as full business certification.

## Critical Gateway Client capture warning

Do **not** run the existing Gateway capture helper unchanged.

The current `scripts/gw_get.vbs` performs this sequence:

1. Executes the GET.
2. Presses the response-grid command `COPY_BODY`, which is effectively **Use as Request**.
3. Copies the response JSON/XML into the left HTTP Request body editor.
4. Runs a clipboard helper using Ctrl+A/C to save it locally.

This made the response appear in the request pane after execution. It was not sent in the already-completed GET, but it is intrusive and confusing. The same script also has a `CloseModals` routine that sends Escape to every SAP child window, which can close scripting prompts or other subwindows immediately after the user allows access.

Before any future Gateway calls, either replace that capture method or capture only status/headers without modifying the request editor. Requirements:

- Never press `COPY_BODY` / **Use as Request**.
- Never automatically close every `wnd[1]` modal.
- Never use global Ctrl+A/C keystrokes against SAP.
- Never leave a body in a GET request.
- Do not click Download/Save or interact with a file chooser unless Siddharth explicitly approves it and can see what is happening.
- Preserve CSRF, authorization, cookie, and SAP security controls. Do not disable them.

## BAPI work already completed

Live SE37 interfaces and attributes were captured for these 15 modules:

- `BAPI_SHIPMENT_COST_ESTIMATE`
- `BAPI_SHIPMENT_CREATE`
- `BAPI_SHIPMENT_CHANGE`
- `BAPI_GOODSMVT_CREATE`
- `BAPI_GOODSMVT_CANCEL`
- `BAPI_OUTB_DELIVERY_CREATE_STO`
- `BAPI_OUTB_DELIVERY_CREATE_SLS`
- `BAPI_OUTB_DELIVERY_CHANGE`
- `BAPI_OUTB_DELIVERY_CONFIRM_DEC`
- `BAPI_PO_CREATE1`
- `BAPI_BILLINGDOC_CREATEMULTIPLE`
- `BAPI_BILLINGDOC_CANCEL1`
- `BAPI_MATERIAL_AVAILABILITY`
- `BAPI_TRANSACTION_COMMIT`
- `BAPI_TRANSACTION_ROLLBACK`

All are remote-enabled. The following three are **not released**, despite being remote-enabled:

- `BAPI_OUTB_DELIVERY_CHANGE`
- `BAPI_SHIPMENT_CHANGE`
- `BAPI_SHIPMENT_COST_ESTIMATE`

This distinction is architecturally important. Do not call a module “standard released integration” merely because it exists or is RFC-enabled. If a non-released BAPI is used, recommend a narrow client-owned wrapper/compatibility boundary and document the upgrade risk.

The captured shipment header structure also includes client append fields such as `ZZVEHICLE_NO`, `ZZDRIVER_NO`, `ZZDRIVER_NAME`, `ZZGROSS_WT`, `ZZNET_WT`, `ZZTARE_WT`, `ZZLR_GR_NO`, `ZZDRIVERMOB`, and `ZZLR_GR_DATE`. The BAPI itself is standard, but its live input structure is enhanced in this client.

## BAPI tests already executed

Only the read-only `BAPI_MATERIAL_AVAILABILITY` was executed:

1. QS4-derived input `Material=15000177`, `Plant=1002`, `Unit=TO`:
   - `RETURN`: `WM3351 Material 15000177 not maintained in plant 1002`
   - `AV_QTY_PLT`: `0.000`
2. Valid DEV master input `Material=MAT18`, `Plant=PLQ3`, `Unit=EA`:
   - no RETURN error
   - `AV_QTY_PLT`: `0.000`

This proves that the BAPI is callable and authorized and that the valid DEV master has zero ATP. It does **not** replace API-05: `BAPI_MATERIAL_AVAILABILITY` is ATP, while `API_MATERIAL_STOCK_SRV` is book stock.

Read-only SE16 discovery also found:

- `MARC`: `MAT18` and `MAT19` are maintained for plant `PLQ3`.
- `MARM`: `MAT18` has unit `EA`.
- DS4/200 has no useful CNF transaction chain and no confirmed ZP06 population/configuration comparable to QS4.

## Read these files first, in this order

1. `sessions/2026-08-18-runtime-certification/CERTIFICATION_STATUS.md`
2. `sessions/2026-08-18-runtime-certification/BAPI_TEST_RUNBOOK.md`
3. `sessions/2026-08-18-runtime-certification/FINDINGS.md`
4. `sessions/2026-08-18-runtime-certification/analysis/RUNTIME_FUNCTIONIMPORTS.tsv`
5. `sessions/2026-08-18-runtime-certification/analysis/RUNTIME_ENTITYSETS.tsv`
6. `sessions/2026-08-18-runtime-certification/analysis/RUNTIME_PROPERTY_INDEX.tsv`
7. `sessions/2026-08-18-runtime-certification/analysis/RUNTIME_NAVPROPS.tsv`
8. `sessions/2026-08-18-runtime-certification/payloads/odata/CNF_OData_Test_Pack.http`
9. Every JSON file under `sessions/2026-08-18-runtime-certification/payloads/bapi/`
10. The live interface and DDIC TSV files under `sessions/2026-08-18-runtime-certification/bapi/`
11. `sessions/2026-08-18-runtime-certification/workbook/WORKBOOK_VALUES.json`
12. `deliverables/CNF_API_Request_Response_Specification_v1.8.xlsx`

The generated BAPI JSON files contain:

- exact import/export/changing/table/exception parameters;
- optionality, associated type, pass-by-value and text;
- captured DDIC fields for the important structures;
- release and RFC status;
- CNF-oriented sample or simulation inputs where applicable.

The SE37 TABLES capture scrolled with overlapping pages for a few long interfaces. The generator deduplicated by section and parameter. If reading the raw TSVs directly, also deduplicate `Section + Parameter`.

## Exact next methodology

### Step 1 — inventory, not rediscovery

Create a single matrix covering API-01 through API-12 and every BAPI above. For each row record:

- business purpose;
- service/function module;
- release status;
- request payload source;
- expected response/document effect;
- test mode: read-only, `TESTRUN`, gated write, or blocked;
- actual result/evidence path;
- remaining blocker and owner.

Do not fetch metadata again simply to say it is active. Use the preserved metadata and runtime indexes.

### Step 2 — complete safe tests first

The following BAPIs expose safe simulation controls and should be tested before any write, once valid DEV inputs are available:

- `BAPI_PO_CREATE1` with `TESTRUN = X`.
- `BAPI_GOODSMVT_CREATE` with `TESTRUN = X`.
- `BAPI_BILLINGDOC_CREATEMULTIPLE` with `TESTRUN = X`.
- `BAPI_BILLINGDOC_CANCEL1` with `TESTRUN = X` and `NO_COMMIT = X`.
- `BAPI_MATERIAL_AVAILABILITY` is read-only and already has two captured runs.

For each simulation:

1. Open SE37 Display and then the single-test screen.
2. Populate structures/tables from the corresponding JSON payload file.
3. Keep `TESTRUN=X` and do not call `BAPI_TRANSACTION_COMMIT`.
4. Capture every input and all `RETURN`, `ERRORS`, `SUCCESS`, and export fields.
5. Classify messages by type and record the precise missing configuration/master/transaction data.

If the input data is unavailable, do not fabricate a “successful” test. Record a blocker and the exact fields/documents required.

### Step 3 — do not execute non-simulated writes without a fresh explicit gate

The delivery/shipment create/change/confirm BAPIs and the OData POST/PATCH/function-import operations can change SAP documents. Before running any one of them, present Siddharth with:

- exact system/client;
- exact function/URI;
- complete payload;
- expected document or status change;
- whether a commit occurs internally or requires `BAPI_TRANSACTION_COMMIT`;
- reversal/cleanup route;
- the disposable DEV document numbers;
- a plain yes/no approval request.

Do not assume that a rollback BAPI compensates after a commit. It only rolls back the current uncommitted LUW.

### Step 4 — obtain a representative DEV chain

The runtime certification cannot finish from empty DS4 data. Ask functional/MM/SD for, or discover read-only, the following disposable DEV objects:

- one open ZP06 STO line;
- one sales order for the Trade/Non-trade route;
- one delivery before picking;
- one delivery after batch allocation but before PGI;
- one PGI-complete delivery;
- eligible batches and storage locations;
- configured shipment type, transportation planning point, and transporter;
- one billable delivery;
- one cancellable billing document;
- confirmation of API-01 `GoodsMovementCode` and whether PO, delivery, or both references must be sent.

The QS4/700 reference documents are read-only reference evidence only:

- STO `5600000339`
- delivery `0080019087`
- billing document `1100012896`

Never send those numbers to DS4 and assume they exist there. Never post in QS4.

### Step 5 — test behavior, not only HTTP status

For each OData/BAPI operation, capture:

- exact request/inputs;
- HTTP status or BAPI return messages;
- exact response/exports;
- created/changed document number if approved;
- SAP GUI reconciliation transaction and observed state;
- idempotency behavior;
- authorization outcome;
- expected and actual business rules;
- cleanup/reversal outcome where applicable.

Specific open questions from v1.8 that runtime tests must answer include:

- API-01: correct `GoodsMovementCode`; PO versus delivery versus both references.
- API-02: STO versus sales-order predecessor behavior and derived delivery types.
- API-03: batch-split behavior, shipment/cost/release sequence, PGI, billing composition.
- API-04: whether non-released `BAPI_SHIPMENT_COST_ESTIMATE` returns a plausible carrier cost for configured data.
- API-05: book stock versus ATP distinction.
- API-10: whether billing item `SalesDocument` carries the STO PO in the runtime service.
- API-11: ZP06/PSTYP 7 behavior and the unresolved RequisitionNumber meaning.
- API-12: main line versus split line targeting, batch clearing/refusal, and stale ETag behavior.

## Transport guidance

Current service activation was local `$TMP`, which is acceptable for this DEV research but is not a deployment strategy. Do not try to “transport `$TMP`.” For QS4 or later systems, Basis must either:

- repeat Gateway service registration in the target system with the correct alias/version/ICF/roles; or
- create and manage the appropriate Gateway registration/customizing workbench transports according to the landscape policy.

Any custom wrapper required for non-released BAPIs is a separate ABAP workbench object and must be transported normally. Keep service registration, roles, ICF state, and custom code as separate deployment concerns.

## Evidence quality rules

- Preserve raw evidence and hash it in the manifest.
- Never claim a test was executed when only its interface was displayed.
- Never claim business authorization from a metadata 200.
- Never claim “no data exists” from one filtered query; say no matching rows were returned for that request.
- Never claim a BAPI is released merely because it is remote-enabled.
- Redact cookies, authorization headers, CSRF tokens, and session IDs.
- Do not edit or overwrite the v1.8 source workbook during testing. Produce a separate correction/delta report first.
- Keep the user informed before any visible GUI automation, especially anything that changes screens or opens dialogs.

## Required final deliverables

1. A consolidated API-01…API-12 plus BAPI runtime matrix.
2. Exact request/response or SE37 input/output evidence for every executed test.
3. A results report separating:
   - proven successful;
   - callable but empty/no matching data;
   - validation failure with exact message;
   - blocked by missing DEV data/configuration;
   - gated pending write approval;
   - unsuitable/non-released interface risk.
4. A delta/correction list for `CNF_API_Request_Response_Specification_v1.8.xlsx`.
5. A Basis/functional data request containing only the unresolved items necessary for the next test cycle.
6. An updated manifest with SHA-256 hashes for the new evidence.

Begin by reading the listed files and summarizing the existing proof in no more than ten bullets. Then state exactly which safe simulation you can execute next with the data currently available. Do not run a write, disable security, manipulate Gateway request bodies, or repeat the completed activation work.
