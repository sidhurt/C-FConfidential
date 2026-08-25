# Predictive SEGW/BAPI Implementation Map

> **Status:** pre-build technical hypothesis for study, estimation and QS4 discovery.  
> **Scope:** the current working v1.7 catalogue, API-01 through API-11. API-11 Create STO Purchase Order is a Figma-supported **candidate**, not yet part of the manager's formal interface baseline. The removed operation was standalone E-Invoice Correction; current API-08 is E-Way Bill Extension (`SRC-SID-20260812-03`).  
> **Control:** every BAPI, class, table, lock and service named here is a candidate until verified in Shree Cement's S/4HANA system, unless this repository already records direct system evidence.

This document bridges the business contract and the ABAP build. Read it with [`05_DI_FLOW_DEEP_CONTEXT.md`](05_DI_FLOW_DEEP_CONTEXT.md) and the current [v1.7 workbook](../../outputs/cnf_api_contract_v17/CNF_API_Request_Response_Specification_v1.7.xlsx).

## 1. Mental model

An external CNF API is not the same thing as a BAPI:

```text
CNF application / CPI
        |
SAP Gateway and OData entity
        |
DPC_EXT: parse/map HTTP and OData only
        |
CNF application class: validate and own the use case/LUW
        |
        +-- released BAPI/API for a business command
        +-- CDS/repository for a read
        +-- eDocument/DigiGST adapter for a statutory command
        +-- several stages for an orchestration
        |
commit where appropriate -> authoritative re-read -> response
```

The live APIs are four different technical species:

| Species | APIs | Correct pattern |
|---|---|---|
| Composite reads | API-01, API-04, API-10 | CDS/repository query; normally no BAPI and no commit |
| Atomic SAP document commands | API-02, API-03, API-09 and candidate API-11 | one released BAPI/API, one controlled LUW, commit and re-read |
| Calculation without persistence | API-05 | standard estimator if proven; no commit |
| Orchestration/statutory commands | API-06, API-07, API-08 | durable stage machine or approved add-on/provider adapter |

Selecting a BAPI for every API would therefore be a design error.

## 2. Executive map

| API | Business ownership | Expected SEGW method | Primary SAP mechanism | Principal objects | Confidence / decisive gate |
|---|---|---|---|---|---|
| API-01 Check MIGO / Pending Receipt | Assemble what is still receivable; does not post MIGO | Current POST: `CREATE_DEEP_ENTITY`; native-read alternative: `GET_ENTITYSET` | Existing MRN CDS/report logic; no BAPI | `ZSD_MRN_PENDING_CDS_OPT`, `ZLE_DI_INV_DETAILS`, `ZLE_MRN_GOODS_RECIET_CDS`, `MATDOC` | High calculation; ownership and stable item key unresolved |
| API-02 Submit MIGO | Create one GR material document for accepted real-SLoc allocations | `CREATE_DEEP_ENTITY` | `BAPI_GOODSMVT_CREATE` | `BAPI2017_*`, `MATDOC`, PO/delivery flow | High BAPI family; exact reference and DMG/STG handling require proof |
| API-03 Create DI | Create SAP outbound delivery from sales order or STO PO | Flat `CREATE_ENTITY`; deep only for child collections | Candidate SLS/STO delivery-create BAPIs; Outbound Delivery A2X alternative | predecessor tables, `LIKP/LIPS/VBFA` | High family; exact release/signature, copy control and split behaviour need proof |
| API-04 Stock Availability | Read current book stock by material, plant and real SLoc | `CREATE_DEEP_ENTITY`; GET alternative | `I_MaterialStock` / Material Stock API / custom CDS; no BAPI | released stock CDS; fallback `MARD/MCHB`; custom age source | High read family; category and age semantics unresolved |
| API-05 Shipment Cost Estimate | Simulate SAP freight for DI and carrier without persistence | `CREATE_ENTITY` | Strong candidate `BAPI_SHIPMENT_COST_ESTIMATE` | in-memory shipment structures, LE-TRA condition technique | Medium-high candidate; DI-only parity spike required |
| API-06 Shipment, PGI & Invoice | Advance DI across post-DI fulfilment stages | `CREATE_DEEP_ENTITY`, plus process/stage read | Orchestrator over delivery, shipment, cost, PGI, billing and eDocument operations | delivery, shipment, cost, billing and eDocument objects | Components are plausible; end-to-end chain is highest risk |
| API-07 Invoice Correction | Maintain approved transport/e-document details anchored by billing | Flat/deep create depending final Part A/Part B model | eDocument/DigiGST command adapter; no generic billing BAPI | `EDOCUMENT`, `/DIGIGST/*`, `VBRK/VBRP` | Function understood; exact callable add-on class/FM unknown |
| API-08 E-Way Bill Extension | Extend one eligible E-Way Bill by the fixed duration | `CREATE_ENTITY` | eDocument/DigiGST/EY adapter; no standard BAPI identified | `EDOCUMENT`, `/DIGIGST/OWARD_H`, provider log | Business rule high-confidence; callable/retry semantics unknown |
| API-09 Modify DI | Change DI quantity before batch/pick/PGI | `CREATE_ENTITY` | `BAPI_OUTB_DELIVERY_CHANGE`; A2X PATCH alternative | `LIKP/LIPS/VBFA` and delivery status | High; exact eligibility and stale-client guard need proof |
| API-10 Valid Storage Locations | Return real SLocs and allowed SPI combinations | `CREATE_DEEP_ENTITY` or `GET_ENTITYSET` | `I_StorageLocation`/`T001L` + `ZLETSPIMAP`; no BAPI | `T001L`, `ZLETSPIMAP`, optional material-SLoc source | High source; exact meaning of posting eligibility unresolved |
| API-11 Create STO Purchase Order | Create the MM predecessor used only by the STO/intra-warehouse flow | `CREATE_ENTITY` | Strong candidate `BAPI_PO_CREATE1`; Stock Transport Order API alternative where release-applicable | `EKKO/EKPO/EKET`, MM purchasing/customizing | High BAPI family / candidate scope | Formal approval, PO type/item category, derivations and release strategy |

## 3. Candidate SEGW topology

Ten external operations do not require ten unrelated SEGW projects. A sensible bounded-context hypothesis is:

| SEGW project candidate | Entity sets / APIs |
|---|---|
| `ZCNF_RECEIPT_SRV` | `PendingReceiptQuerySet` (01), `GoodsReceiptSet` (02), `StorageLocationQuerySet` (10) |
| `ZCNF_DELIVERY_SRV` | `DeliveryCreateSet` (03), `DeliveryModifySet` (09) |
| `ZCNF_STOCK_SRV` | `StockQuerySet` with `ToItems` (04) |
| `ZCNF_DISPATCH_SRV` | `ShipmentCostEstimateSet` (05), `DispatchProcessSet` with `ToStages` (06) |
| `ZCNF_EDOC_SRV` | `TransportCorrectionSet` (07), `EWayExtensionSet` (08) |
| `ZCNF_STO_SRV` or approved MM service | candidate `StockTransportOrderCreateSet` (11); owning service remains an architecture decision |

These are proposed names, not observed objects. SEGW generates base MPC/DPC classes; durable logic belongs in `_EXT` and, preferably, application classes called by a thin `DPC_EXT`. Generated base classes can be overwritten when the model is regenerated.

Each service needs entity types/sets, DDIC-backed properties, associations/navigation for repeated children, runtime methods, application/repository/adaptor classes, stable business exceptions, service registration/system alias, ICF activation, logging, authorization and tests.

Prefer SAP data elements such as `VBELN_VL`, `VBELN_VA`, `EBELN`, `EBELP`, `POSNR_VA`, `MATNR`, `WERKS_D`, `LGORT_D`, `VKORG`, `SPART` and `MEINS` over UI-guessed `CHAR` lengths.

| Contract shape | Gateway implementation |
|---|---|
| GET collection | generated `<ENTITYSET>_GET_ENTITYSET` |
| GET one object | generated `<ENTITYSET>_GET_ENTITY` |
| POST flat command/result | generated `<ENTITYSET>_CREATE_ENTITY` |
| POST with child/request-response collections | `/IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY` |
| action/function import | `/IWBEP/IF_MGW_APPL_SRV_RUNTIME~EXECUTE_ACTION` |
| process with stage expansion | `GET_ENTITY`/expanded entity with `ToStages` |

The workbook's POST envelopes for reads are implementable. A future native GET/filter contract could reuse the same repositories.

## 4. Per-API implementation hypotheses

### API-01 - Check MIGO / Pending Receipt

**One sentence:** it builds the receivable work position; API-02 posts it.

Candidate deep model:

```text
PendingReceiptQuery
  RequestId, SourceSystem, RequestedBy
  plant/delivery/date/status filters and paging
  TotalCount, HasMore
  +-- ToItems[*]
      ReceiptPositionId?, DeliveryDocument, DeliveryItem?, PurchaseOrder, POItem?
      SendingPlant, ReceivingPlant, Material, Unit
      DispatchedQuantity, ReceivedQuantity, PendingQuantity, ReceiptStatus
      approved display/enrichment fields
```

Runtime flow:

1. Validate plant scope and filters.
2. Reuse the observed MRN logic instead of recoding it inside Gateway.
3. Query `ZSD_MRN_PENDING_CDS_OPT`, `ZLE_DI_INV_DETAILS` and `ZLE_MRN_GOODS_RECIET_CDS`.
4. Preserve delivery/item grain while deriving dispatched/invoiced minus received.
5. Apply deterministic sorting/paging and enrich only after the core quantity is established.
6. Return without enqueue or commit.

Existing report evidence links GR through `MATDOC-VBELN_IM` and movement 101 (`D-021`, `SRC-CODE-20260804-01`). However, the exact meaning of MRN, the stable receipt-position key and whether S/4 or DSP/T2 owns the live worklist remain open (`C-14`, `C-15`). API-02 must always re-read current quantity; API-01 is not a reservation.

### API-02 - Submit MIGO

**One sentence:** it posts accepted receipt quantity into real SAP storage locations and returns material document + fiscal year.

```text
GoodsReceipt
  RequestId, SourceSystem, RequestedBy
  DeliveryDocument, PurchaseOrder?, ReceivingPlant
  PostingDate, DocumentDate, Material?, Unit?
  +-- ToAllocations[*] { StorageLocation, Quantity }
  -> MaterialDocument, MaterialDocumentYear, Status, RemainingQuantity
     +-- ToPostedItems[*]
```

Primary candidate:

```text
BAPI_GOODSMVT_CREATE
  GOODSMVT_HEADER  BAPI2017_GM_HEAD_01
  GOODSMVT_CODE    BAPI2017_GM_CODE       (candidate GM_CODE = '01')
  GOODSMVT_ITEM[]  BAPI2017_GM_ITEM_CREATE
  GOODSMVT_HEADRET BAPI2017_GM_HEAD_RET
  RETURN[]         BAPIRET2
```

Key mapping: document/posting dates to the header; one BAPI item per accepted real SLoc; `MATERIAL`, receiving `PLANT`, `STGE_LOC`, candidate movement type 101, `ENTRY_QNT` and unit; PO/delivery reference fields as proven by MIGO trace; response `MAT_DOC` and `DOC_YEAR`.

Method sequence:

1. Reserve/check `SourceSystem + RequestId`; reject same key with a different normalized payload hash.
2. Re-read delivery, predecessor, receiving plant, material, PGI/in-transit and live pending quantity.
3. Validate posting period/date, authorization, unit conversion, positive allocation, tolerance and API-10 SLoc/SPI rules.
4. Keep DMG/STG/rejected quantities out of BAPI posting lines. They require a separate approved exception/replacement ledger.
5. Lock or atomically reserve the receipt position and re-read it.
6. Call the BAPI once; treat `A/E/X` messages as failure.
7. Persist idempotency result in the same LUW, commit with wait, then re-read the material document and flow.

Candidate classes/tables: `ZCL_CNF_GR_APPLICATION`, `ZCL_CNF_GOODSMVT_ADAPTER`, `ZCL_CNF_RECEIPT_REPOSITORY`, `ZCL_CNF_IDEMPOTENCY`, `ZCNF_API_REQ`, plus a separately approved receipt-exception table. Exact reference fields and reversal/no-more-GR behaviour require a controlled QS4 test.

Critical correction: DMG/STG are non-stock rejection classifications per `D-052/D-054`, not convenient values for `STGE_LOC`, despite the present workbook wording.

### API-03 - Create DI

**One sentence:** DI means SAP outbound delivery; Trade/Non-trade reference a sales order, while STO references a stock-transport PO.

Flat model: request ID/source/user, predecessor document/type, delivery quantity/unit; response delivery, business flow, material, confirmed quantity/unit, organization, division, Incoterm and status.

Strong candidate strategy:

```text
Trade / Non-trade -> BAPI_OUTB_DELIVERY_CREATE_SLS
  candidate reference table: BAPIDLVREFTOSALESORDER[]

STO -> BAPI_OUTB_DELIVERY_CREATE_STO
  candidate reference table: BAPIDLVREFTOSTO[]
```

The released `API_OUTBOUND_DELIVERY_SRV` is the service-level alternative if activated and approved. It officially supports creation with reference to sales orders and stock transport orders. A custom DPC should not call a locally hosted OData service over HTTP: either CPI consumes that service directly or local ABAP invokes the underlying approved application operation.

Candidate class strategy:

```text
ZCL_CNF_DI_APPLICATION
  -> ZIF_CNF_DI_CREATOR
       -> ZCL_CNF_DI_CREATE_SLS
       -> ZCL_CNF_DI_CREATE_STO
```

Method sequence: idempotency check; derive predecessor type from SAP; read the eligible `VBAK/VBAP/VBEP` or `EKKO/EKPO/EKET` item; validate delivery relevance, block, schedule/due date, shipping point, open quantity and unit; call the strategy; handle SAP delivery split explicitly; commit; re-read `LIKP/LIPS/VBFA`; derive response fields from the created document.

Do not hard-code the unresolved `1000/1300` organization interpretation. Exact BAPI signatures/release status, Shree document types, copy control, locks and multiple-delivery behaviour are QS4 gates.

### API-04 - Stock Availability

**One sentence:** this is current SAP book stock by material, plant and real SLoc; it is not DI inventory, ATP or physical-count difference posting.

```text
StockQuery
  RequestId, Plant, StorageLocation?, Material?, SearchText?
  PageSize, PageOffset, SortBy, SortOrder
  TotalCount, HasMore
  +-- ToItems[*]
      Plant, StorageLocation, descriptions
      Material, Unit, SystemQuantity, StockAgeingDays?
```

Preferred source order: released `I_MaterialStock`/`API_MATERIAL_STOCK_SRV`; project CDS over released semantics; direct `MARD/MCHB` only as an approved fallback. Do not use `BAPI_MATERIAL_AVAILABILITY`: ATP is a different question.

Implementation: authorize plant; allow-list filters/sorts; push predicates down; explicitly decide included inventory and special-stock categories; aggregate to material + plant + SLoc + base unit; preserve legitimate negative values; join released texts; join an approved stock-age provider; page deterministically. No BAPI, lock or commit.

Stock age is the gap. A stock balance does not preserve FIFO receipt layers. The mapped custom inventory-age/report source must be inspected to establish whether age means oldest stock, next FIFO issue layer, weighted age or another rule. `today - last GR date` is not an acceptable shortcut when layers coexist. DMG/STG are not SLoc examples here.

### API-05 - Shipment Cost Estimate

**One sentence:** simulate what SAP freight costing would calculate for this DI/carrier without creating a shipment-cost document.

The strongest standard candidate is released LE-TRA BAPI `BAPI_SHIPMENT_COST_ESTIMATE`, described by SAP as calculating shipment costs for different forwarding agents. Its likely signature uses the `BAPISHIPMENT*` in-memory header, delivery, item, stage, address and deadline family and returns carrier costs plus `BAPIRET2`; capture the exact QS4 interface in `SE37`.

ABAP must derive from the small request: delivery items/quantities/weights/units, planning point, shipment type, shipping mode, route/stages, origin/destination, distance/zones, dates and forwarding-agent identity. Candidate sources include `LIKP/LIPS`, route/partner/address data and LE-TRA configuration.

Candidate flow:

```text
ShipmentCostEstimateSet_CREATE_ENTITY
 -> ZCL_CNF_FREIGHT_APPLICATION
 -> ZIF_CNF_FREIGHT_ESTIMATOR
 -> ZCL_CNF_BAPI_SHIPCOST_EST
```

Read/validate DI and carrier, build the in-memory shipment, call the estimator, map amount/currency and return `NO_VALID_RATE` when appropriate. Do not commit; prove that no `VTTK` or shipment-cost document is created. `RateBasis` and one `ConditionRecord` remain provisional because shipment costing may use several conditions.

Mandatory spike: reproduce the value of one known costed shipment, then reproduce it from DI-derived data only. If standard estimation cannot achieve parity, use an approved façade over the same condition-technique logic—not copied arithmetic and not create-and-reverse.

### API-06 - Shipment, PGI & Invoice orchestration

**One sentence:** API-06 is a state machine composing several SAP business-document operations; there is no single fulfilment BAPI.

```text
DispatchProcess
  RequestId, DeliveryDocument
  allocation/batch/SLoc/SPI data
  transporter, LR/date, vehicle, driver, pickup data
  -> ProcessId, OverallStatus
     +-- ToStages[*]
         StageCode, Status, BusinessDocument?, Attempt, MessageCode, Message
```

Use deep create for execution and an entity/stage read for document-flow status. A synchronous external call can still use a persisted stage journal; synchronous transport does not make multiple SAP LUWs atomic.

| Stage | Preferred mechanism | Important caution |
|---|---|---|
| Validate DI | delivery repository/released API | live `LIKP/LIPS/VBFA` status |
| SLoc/SPI/FIFO batch preparation | standard delivery/batch determination and approved config | do not build a parallel FIFO engine with ad-hoc SQL |
| Change/pick/batch split | Outbound Delivery A2X or `BAPI_OUTB_DELIVERY_CHANGE` where supported | exact batch/pick semantics need tests |
| Shipment | `BAPI_SHIPMENT_CREATE` candidate/released catalogue entry | creates shipment objects such as `VTTK/VTTP/VTTS` |
| Actual shipment cost | callable not yet identified | trace validated `VI01`; API-05 estimator does not create actual cost |
| PGI | released Outbound Delivery A2X `PostGoodsIssue` preferred | `WS_DELIVERY_UPDATE_2` is internal/non-released, not the default |
| Billing | `BAPI_BILLINGDOC_CREATEMULTIPLE` or applicable released billing API | must reproduce `VF01` due-list/copy-control semantics; `VBRK/VBRP` |
| e-Invoice/E-Way | approved eDocument/DigiGST route | provider processing may have its own state |

Candidate spine: `ZCL_CNF_DISPATCH_ORCHESTRATOR`, a `ZIF_CNF_STAGE` implementation per stage, and durable `ZCNF_PROCESS/ZCNF_STAGE/ZCNF_API_REQ` records.

Delivery, shipment, PGI, billing and provider operations cannot be one rollbackable LUW. Persist each completed stage, make retries idempotent and define corrections/compensation. Never hold an SAP enqueue across an external provider call. Existing `ZMM_SCRUM_SER_PO` evidence shows a related staged multi-BAPI/separate-commit pattern at Shree (`D-030`), but is precedent rather than proof of reusable code.

This is the highest-risk API. A detailed estimate is not credible until the actual shipment-cost create operation and DigiGST/eDocument call paths are traced.

### API-07 - Invoice Correction

**One sentence:** despite its historical name, this is transport/e-document detail maintenance anchored by billing, not generic invoice-value correction.

Flat candidate fields: billing document; Part A transporter ID/name and distance; Part B mode, vehicle type and vehicle number; optional reason/remarks; independent e-Invoice and E-Way response statuses.

There is no justified `BAPI_BILLINGDOC_*` command for this. Billing locates the eDocument/DigiGST record. Do not directly update `VBRK`, `EDOCUMENT` or `/DIGIGST/*`.

```text
ZCL_CNF_EDOC_APPLICATION
 -> ZCL_CNF_EDOC_REPOSITORY       (billing -> eDocument/provider record)
 -> ZIF_CNF_EDOC_COMMAND
      -> ZCL_CNF_DIGIGST_ADAPTER  (exact supported class/FM unknown)
```

Flow: idempotency check; resolve billing/eDocument/current status; validate fields allowed in that state; call the approved add-on action; persist correlation/audit; re-read and return independent e-Invoice/E-Way results. `BADI_EDOCUMENT_IN_EWB` is worth inspecting, but a BAdI is an enhancement point, not automatically the callable command. The exact Shree class/FM and error map remain `Q-055`.

### API-08 - E-Way Bill Extension

**One sentence:** invoke the approved statutory adapter to extend one eligible E-Way Bill; the caller does not choose the duration.

Candidate request: request ID, EWB number, optional delivery/billing assertions, vehicle, current place/state/PIN, remaining distance, reason/remarks and transit type. Response: status, previous and updated validity, extension timestamp and correlation.

Confirmed project rule: eligibility exists only during the eight hours immediately **before** expiry, never after; success adds exactly 24 hours; `ExtensionHours` is not requested (`SRC-SID-20260812-01`). `SRC-SID-20260812-03` supersedes the old sheet number and assigns this operation API-08. Standard SAP extension fields align with the Figma request, but no standard BAPI has been identified.

Safe flow: reserve/check idempotency; resolve EWB/current validity through eDocument/DigiGST (system evidence includes `/DIGIGST/OWARD_H-EWBNUMBER`); evaluate time window with the authoritative timestamp/timezone; validate location/distance/reason; release short locks; call the approved DigiGST/EY command; persist provider correlation/result; re-read validity. Do not declare success by locally adding 24 hours and do not bypass the installed framework with direct table updates or an invented raw HTTP client.

### API-09 - Modify DI

**One sentence:** change the quantity of the single eligible delivery item before batch, pick, PGI or billing begins.

Strong candidate:

```text
BAPI_OUTB_DELIVERY_CHANGE
  HEADER_DATA     BAPIOBDLVHDRCHG
  HEADER_CONTROL  BAPIOBDLVHDRCTRLCHG
  DELIVERY
  ITEM_DATA[]     BAPIOBDLVITEMCHG
  ITEM_CONTROL[]  BAPIOBDLVITEMCTRLCHG
  RETURN[]        BAPIRET2
```

Officially documented quantity fields include delivery/base quantity and sales/base units; item control uses candidate `CHG_DELQTY = 'X'`. Verify exact QS4 names.

Flow: idempotency and delivery lock; re-read `LIKP/LIPS` and status; derive the one primary item and SAP units; reject batch/batch-split, picking, partial/full PGI, billing or blocking downstream state; validate positive quantity and predecessor ceiling; call BAPI; inspect messages; commit once; re-read delivery and predecessor. Calculate returned pending quantity separately. Persist the portal reason in approved audit/log storage because the BAPI does not naturally own it.

The released A2X PATCH alternative uses ETags. Since the custom request has no ETag/expected value, enqueue plus live revalidation is mandatory; an expected current quantity/version would protect stale-user intent better.

### API-10 - Valid Storage Locations

**One sentence:** return real SAP SLocs and all allowed SPI combinations for a receiving context, not rejection buckets.

```text
StorageLocationQuery
  RequestId, ReceivingPlant, DeliveryDocument?, Material?, SearchText?
  +-- ToLocations[*]
      StorageLocation, Description, Active, PostingAllowed, LocationType?
      +-- ToAllowedSPIs[*] { SPI }
```

Source order: released `I_StorageLocation` or `T001L`; `ZLETSPIMAP` for valid SLoc/SPI combinations (`D-020`); released material-SLoc source or `MARD` only if material extension is truly required. No BAPI or commit.

Authorize plant, select active real SLocs, apply confirmed material/posting-use rules, return every allowed SPI and deterministic order. Do not pretend `ZLETSPIMAP` determines one SPI when one SLoc can permit several. Exclude DMG/STG unless separately represented as non-posting classification values. The open gate is whether “valid” means master existence, material extension, stock presence or posting permission; those are different predicates (`Q-058`).

### API-11 - Create STO Purchase Order (candidate)

**One sentence:** create the MM stock-transport purchase order used only by the STO/intra-warehouse journey; its successful PO becomes API-03's `STO_PO` predecessor.

Candidate flat model from the validated Figma/workbook:

```text
StockTransportOrderCreate
  RequestId, SourceSystem, RequestedBy
  SourcePlant, ReceivingPlant, CompanyCode
  ShippingType, PurchasingGroup, Product
  PurchaseOrderQuantity, Unit?, DeliveryDate
  RequisitionNumber, Requisitioner
  -> PurchaseOrder, PurchaseOrderItem?
     retained plants/product/quantity/unit/date
     PurchasingOrganization, PurchasingGroup, Status
```

The strongest on-premise ABAP candidate is:

```text
BAPI_PO_CREATE1
  POHEADER       BAPIMEPOHEADER
  POHEADERX      BAPIMEPOHEADERX
  POITEM[]       BAPIMEPOITEM
  POITEMX[]      BAPIMEPOITEMX
  POSCHEDULE[]   BAPIMEPOSCHEDULE
  POSCHEDULEX[]  BAPIMEPOSCHEDULX
  RETURN[]       BAPIRET2
  -> created purchase-order number / exported header
```

SAP recommends `BAPI_PO_CREATE1` over the older `BAPI_PO_CREATE`; it represents the ME21N operation. Shree's own `ZMM_SCRUM_SER_PO` source proves this BAPI exists and is already invoked in QS4 (`D-030/D-031`), but it does **not** prove Shree's STO document mapping.

Predictive field mapping:

| Contract concept | Candidate BAPI mapping |
|---|---|
| configured STO document type | `POHEADER-DOC_TYPE`; standard configuration often uses an STO-specific type, but Shree's value must be read from customizing rather than hard-coded |
| Company code | `POHEADER-COMP_CODE`, preferably derived/validated from receiving plant/company configuration |
| Purchasing organization/group | `PURCH_ORG`, `PUR_GROUP`; derive organization when configuration permits |
| Product | `POITEM-MATERIAL` |
| Receiving plant | `POITEM-PLANT` |
| Source/supplying plant | candidate `POITEM-SUPPL_PLNT` |
| Quantity/unit | `POITEM-QUANTITY`, `PO_UNIT` plus X-structure flags |
| STO item category | `POITEM-ITEM_CAT`; exact configured value requires MM validation |
| Delivery date | `POSCHEDULE-DELIVERY_DATE` with schedule quantity |
| Shipping type | exact PO/shipping field or derived shipping configuration must be traced; do not force a UI label into an unproven DDIC field |
| Requisition number/name | resolve whether Figma means purchase requisition (`PREQ_NO/PREQ_ITEM`), requisitioner, requirement tracking number or a custom field before mapping |
| Result | exported PO number, followed by authoritative `EKKO/EKPO/EKET` re-read |

Candidate runtime/class flow:

```text
StockTransportOrderCreateSet_CREATE_ENTITY
 -> ZCL_CNF_STO_APPLICATION
 -> ZCL_CNF_STO_CONFIG_REPOSITORY
 -> ZCL_CNF_PO_CREATE_ADAPTER
 -> BAPI_PO_CREATE1
```

Method sequence:

1. Enforce STO-only route and idempotency before the non-idempotent BAPI.
2. Validate source != receiving plant, plant/company relationship, material extension, positive quantity, date, purchasing group and user authority.
3. Derive PO type, purchasing organization, unit, item category and shipping/customizing context from SAP.
4. Populate header/item/schedule and their X structures; run a `TESTRUN` validation only if the productive design proves it useful and consistent.
5. Call `BAPI_PO_CREATE1`, reject `A/E/X` messages, persist request-to-PO mapping and commit with wait.
6. Re-read `EKKO/EKPO/EKET`, including release/approval and delivery-relevance state, then return the authoritative PO.
7. Pass that PO to API-03 as a **separate** later command. Never collapse PO and DI into one hidden document.

The standard Stock Transport Order OData V4 service is a conceptual alternative where the installed S/4 release supports it; the official page found is Cloud-focused, so it must not be assumed available on Shree's current on-premise release. Formal interface ownership, release strategy, document type/item category and exact requisition/shipping mappings remain approval gates (`SRC-SID-20260812-02`, `SRC-FIG-20260812-01`).

## 5. Shared ABAP spine

Keep `DPC_EXT` thin:

```abap
METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.
  io_data_provider->read_entry_data( IMPORTING es_data = ls_request ).
  TRY.
      ls_result = mo_application->execute( ls_request ).
      copy_data_to_ref( EXPORTING is_data = ls_result
                        CHANGING  cr_data = er_deep_entity ).
    CATCH zcx_cnf_business INTO lx_business.
      mo_error_mapper->raise_gateway_business_error( lx_business ).
  ENDTRY.
ENDMETHOD.
```

Candidate common objects:

| Object | Responsibility |
|---|---|
| `ZCL_CNF_IDEMPOTENCY` + `ZCNF_API_REQ` | reserve key, compare payload hash, replay original successful result |
| `ZCL_CNF_AUTH` | plant/depot/action authorization |
| `ZCL_CNF_ERROR_MAPPER` | map `BAPIRET2`, provider and business exceptions to stable codes |
| `ZCL_CNF_LOG` | correlation and Business Application Log |
| `ZCL_CNF_UOM` | SAP-authoritative unit conversion |
| `ZCX_CNF_BUSINESS` and message class `ZCNF_API` | stable business errors/messages |

Use `/IWBEP/CX_MGW_BUSI_EXCEPTION` and the Gateway message container for business failures. Keep full SAP/provider detail in application logs.

`RequestId` is operation-specific:

- API-01/04/05/10: correlation only; do not cache mutable reads as writes.
- API-02/03/09/11: same key + same hash returns original result; same key + different hash is conflict.
- API-06: idempotent process creation and idempotent stage execution.
- API-07/08: idempotency across SAP and provider correlation/retry.

Single-document transaction pattern:

```text
validate -> lock/re-read -> call BAPI -> inspect BAPIRET2
-> save idempotency -> BAPI_TRANSACTION_COMMIT WAIT = X
-> authoritative re-read -> response
```

On failure roll back and map the error. Do not update standard business tables directly. For API-06/provider work, persist stages instead of pretending one rollback can undo prior committed documents. Lock the smallest aggregate, re-read after locking and never hold locks across remote calls.

## 6. Discovery and build roadmap

### Phase 0 - prove the candidates

1. Inventory activation/release applicability of `API_OUTBOUND_DELIVERY_SRV`, `API_BILLING_DOCUMENT_SRV`, `API_MATERIAL_DOCUMENT_SRV` and `API_MATERIAL_STOCK_SRV` (`Q-045`).
2. Capture exact `SE37` signatures/release status for each proposed BAPI.
3. Trace one validated GUI path per command: MIGO, ME21N STO creation, VL01N, VL02N, VT01N/VI01, PGI, VF01 and DigiGST correction/extension.
4. Locate the actual supported DigiGST/eDocument classes/FMs.
5. Confirm DDIC keys, status rules, locks and logs.
6. Build golden Trade, Non-trade, STO, partial, missing-rate, duplicate and provider-failure examples.

### Build order

1. Shared Gateway/application/error/idempotency/test foundation.
2. Reads: API-10 -> API-04 -> API-01.
3. Atomic writes: API-09 -> candidate API-11 (after scope approval) -> API-03 -> API-02.
4. API-05 estimation parity spike and implementation.
5. API-07/API-08 after supported add-on callables are known.
6. API-06 last, composing already-proven components.

### Working ABAP effort hypothesis

Focused ABAP engineering days only; excludes CPI/UI, waiting for decisions, customizing, role design and UAT.

| Work | Range | Main uncertainty |
|---|---:|---|
| Shared foundation | 8-12 | number of projects, test/log/idempotency convention |
| API-10 | 3-5 | meaning of posting eligibility |
| API-01 | 5-8 after ownership decision | reuse and stable key |
| API-04 | 8-12 | stock categories and ageing |
| API-09 | 4-6 | status/concurrency boundary |
| candidate API-11 | 6-10 after scope approval | STO type/item/category, derivations and release strategy |
| API-03 | 6-10 | Sales/STO strategy, copy control and splits |
| API-02 | 8-12 | reference, concurrency, exceptions and reversal |
| API-05 | 6-10 if standard estimator fits; 12-18 if not | DI-derived pricing parity |
| API-07 | 6-12 after callable discovery | add-on state/error model |
| API-08 | 6-12 after callable discovery | provider idempotency/retry |
| API-06 | 20-35 after dependencies are proven | several LUWs, unknown cost callable, recovery/statutory stages |

Honest headline: API-06 and DigiGST discovery dominate risk; API-09 is the best first write; API-10 is the best first read; API-05 has the largest upside if its standard-BAPI spike succeeds. Candidate API-11 is technically conventional but cannot be committed into scope before MM/architecture approval.

## 7. Sign-off checklist for every API

Before detailed design is called final, prove:

- SEGW entity/property/navigation names and DDIC types;
- exact released BAPI/API/class/FM signature;
- authoritative read/status source;
- every transformation, default and derivation;
- authorization scope;
- lock/ETag/concurrency rule;
- idempotency/replay behaviour;
- commit owner and number of LUWs;
- reversal/compensation/resume behaviour;
- BAPI/provider error to API/HTTP mapping;
- happy, partial, duplicate, concurrent and failed golden tests;
- authoritative post-operation re-read.

## 8. Official SAP references

- [SEGW and runtime artifacts](https://help.sap.com/docs/ABAP_PLATFORM_NEW/68bf513362174d54b58cddec28794093/cddd22512c312314e10000000a44176d.html)
- [Generated MPC/DPC classes](https://help.sap.com/docs/ABAP_PLATFORM_NEW/68bf513362174d54b58cddec28794093/09742c510e87fa50e10000000a441470.html)
- [Gateway runtime interface](https://help.sap.com/docs/ABAP_PLATFORM_NEW/68bf513362174d54b58cddec28794093/05fb2651c294256ee10000000a445394.html)
- [`BAPI_GOODSMVT_CREATE` guidance](https://help.sap.com/docs/SUPPORT_CONTENT/erpscm/3362167803.html?locale=en-US)
- [Create material document](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/91b21005dded4984bcccf4a69ae1300c/8bb0d08295044ee3af444b4f2a6e4457.html)
- [Outbound Delivery A2X](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/2f36056ae9a044bba55bcbad204b7bc5/4bec9116ac56435ca1332e4a75998d51.html)
- [Create outbound delivery with reference](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/2f36056ae9a044bba55bcbad204b7bc5/ab6845012ee148ba9c2694648c2a0685.html)
- [`BAPI_OUTB_DELIVERY_CHANGE`](https://help.sap.com/docs/SUPPORT_CONTENT/erpscm/3362168185.html)
- [Outbound-delivery operations and PGI](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/2f36056ae9a044bba55bcbad204b7bc5/a4c5d84ecef2494985883829a24e393c.html)
- [`BAPI_PO_CREATE1` structure and use](https://help.sap.com/docs/SUPPORT_CONTENT/spmm/3362167600.html?locale=en-US)
- [Purchase-order BAPI capabilities and limits](https://help.sap.com/docs/SUPPORT_CONTENT/spmm/3362168142.html)
- [Stock Transport Order OData V4 service, release-applicability reference](https://help.sap.com/docs/SAP_S4HANA_CLOUD/bb9f1469daf04bd894ab2167f8132a1a/807b2c79e22c4ef7a4c30c928bb3344e.html)
- [`I_MaterialStock`](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/ee6ff9b281d8448f96b4fe6c89f2bdc8/4c7f68579552346ae10000000a4450e5.html)
- [`I_StorageLocation`](https://help.sap.com/docs/SAP_S4HANA_CLOUD/c0c54048d35849128be8e872df5bea6d/78e66657290ba57ae10000000a4450e5.html)
- [BAPI catalogue containing shipment create/cost estimate](https://help.sap.com/docs/SUPPORT_CONTENT/abap/3353523827.html)
- [Shipment costing and condition technique](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/eff06b275ea640c4a827fc099df3b4aa/a194c95360267214e10000000a174cb4.html)
- [`BAPI_BILLINGDOC_CREATEMULTIPLE`](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/ed84b70c199d4470ae2e5ccb93b2e45b/1ef3e755a408427f8648fb67ea3a09c4.html)
- [India e-Way dashboard/timing](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE/240fcdcc71c640ea9aa9691500b34889/b5bfa1cb4db24421bb0ec43b5d117e1a.html)
- [Extend e-Way Bill fields](https://help.sap.com/docs/SAP_S4HANA_CLOUD/634261119fec4d58970471f2c4a9a740/8d8d0becbfe14a22a34ed4799c5fd414.html)
- [BAPI transaction model](https://help.sap.com/docs/SAP_ERP/b28a6b5d037849d0a5cdde6cf2d341e4/4d5b102ba1483d8fe10000000a42189e.html?version=6.17.latest)

## Bottom line

The likely build is not “eleven APIs, eleven BAPIs.” It is four strong atomic BAPI families (goods movement, delivery, shipment and candidate STO PO), one promising freight-estimation BAPI, three CDS-backed reads, two statutory add-on commands and one durable fulfilment orchestrator. The next increase in precision must come from QS4 signatures and traces, not more confident guessing.
