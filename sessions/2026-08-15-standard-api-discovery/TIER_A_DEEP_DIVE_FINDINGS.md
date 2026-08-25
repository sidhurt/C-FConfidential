# Tier A deep-dive findings

One section per project. Each is measured against the v1.7 business requirement first, then against the competing Tier A candidate for the same process. Sibling deltas are produced only for genuine version pairs.

**Comparators already extracted:** `API_MATERIAL_DOCUMENT` (API-01), `API_OUTBOUND_DELIVERY_0002` (API-02/03/09/12).

**Service-class vocabulary used below:**

- `RELEASED-INTEGRATION` — SAP publishes it as an A2X/released API for this release.
- `APPLICATION-INTERNAL` — SAP-standard, but built to serve a Fiori app: draft handling, value helps, launchpad navigation metadata. No contract-stability guarantee.
- `UNPROVEN` — insufficient evidence to classify.

---

## MMIM_GR4PO_DL

**Queue position:** 1 of 11
**Business API:** API-01 Submit MIGO
**Evidence:** `sources/SRC-SYS-20260815-06_QS4_700_SEGW_MMIM_GR4PO_DL/`
**Catalogue:** "oData Service Goods receipt Purchase Order/Del." · SAP · last changed 26.07.2016

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 861 |
| **Target-project rows** | **855** |
| Other open roots (1 row each) | 6 |
| Grid manifest rows | 83 |
| Distinct manifest files | 83 |
| Physical grid files | 83 |
| Collisions / orphans / missing | 0 / 0 / 0 |

### Model surface

Native model: 10 entity types, 10 entity sets, 4 complex types, 7 associations, 5 function imports.
SADL/CDS exposures: 18 entity types, 18 entity sets, 4 function imports.
Runtime artifacts: 7 — `MMIM_GR4PO_DL_SRV`, `MMIM_GR4PO_DL_MDL`, `MMIM_GR4PO_DL_ANNO_MDL`, and the `CL_MMIM_GR4PO_DL_*` DPC/MPC families.

**Transactional entities** (all Creatable + Updatable, none deletable, none pageable):
`GR4PO_DL_Headers`, `GR4PO_DL_Items`, `GR4PO_DL_SubItems`, `GR4PO_DL_SerialNumbers`, `GR4PO_DOC_Refs`.

**Header** (28 properties) keyed on `InboundDelivery` + `SourceOfGR`. Carries `PurchasingDocumentCategory`, `PurchasingDocumentType`, `Vendor`, `SupplyingPlant`, `PostingDate`, `DocumentDate`, and — decisively — **`MaterialDocument` and `MaterialDocumentYear`**.

**Item** (98 properties) keyed on `InboundDelivery` + `DeliveryDocumentItem` + `SourceOfGR` + `AccountAssignmentNumber` + `ReferenceLineID`. Carries `Plant`, `StorageLocation`, `Batch`, `Material`, `QuantityInEntryUnit`/`EntryUnit`, `GoodsReceiptQty`, **`OpenQuantity`**, `StockType`, `GoodsMovementType`, `GoodsMovementReasonCode`, **`DeliveryCompleted`**, `NonVltdGRBlockedStockQty`, `ReferenceDocument`/`Year`/`Item`.

Function imports are all UI helpers, not a posting action: `BatchCreate`, `ComponentMatQty`, `ConversionQty`, `MatlPlntControlDpdtFields`, `ShelfLifeExpirationDate`. Posting happens through entity-set create, not a function import.

### v1.7 coverage

**Covers:**

- `Allocations[].StorageLocation` — `GR4PO_DL_Item.StorageLocation`, one item per allocation, via `Header2Items` (1:M).
- `Allocations[].Quantity` — `QuantityInEntryUnit` + `EntryUnit`.
- Multiple allocations in one attempt — header/item deep structure.
- `MaterialDocument` + `MaterialDocumentYear` — both present on the header.
- `PostingDate`, `DocumentDate`.
- **`RemainingQuantity`** — `OpenQuantity`.
- **`ReceiptStatus`** — `DeliveryCompleted` gives the COMPLETED signal.

**Cannot cover:**

- `RequestId` / `IsReplay` idempotency — absent, as in every standard candidate.
- `Errors[].AllocationIndex` — no per-allocation error index.
- The v1.7 reference model. Its header key is `InboundDelivery`; v1.7 API-01 states the reference is an **outbound** delivery. `SourceOfGR` and `PurchasingDocumentCategory` suggest the service can also key on a purchasing document, but that is not proven from design time. Open gate **GR4-1**, and the same underlying question as **ID-1**.

### Versus the competing candidate

| v1.7 requirement | `API_MATERIAL_DOCUMENT` | `MMIM_GR4PO_DL` |
|---|---|---|
| Multi-SLoc allocation in one call | DIRECT | DIRECT |
| `MaterialDocument` + `Year` | DIRECT | DIRECT |
| `RemainingQuantity` | **NO FIT** | **DIRECT** (`OpenQuantity`) |
| `ReceiptStatus` | **NO FIT** | **PARTIAL** (`DeliveryCompleted`) |
| Documented create contract | **YES** (SAP-OFFICIAL, on-premise 2022) | **NO** — design-time only |
| Released integration API | **YES** | **NO** |
| Registered in QS4 | NO | NO |

It **beats** `API_MATERIAL_DOCUMENT` on exactly the two requirements the material-document deep dive recorded as `NO FIT` — remaining quantity and receipt status. That is a real finding: the fields v1.7 asks for do exist in SAP's own goods-receipt model, so those requirements are not inherently unsatisfiable. They are simply outside the A2X material-document contract.

It **loses** on service class, which is decisive for an integration mandate.

### Service class

**`APPLICATION-INTERNAL`.** Three independent design-time signals, none ambiguous:

1. `I_DraftAdministrativeData` is exposed as an entity set — SAP draft handling, which exists to serve a UI edit session.
2. Seventeen of the eighteen SADL entity sets are value helps (`I_*_VH`, `MMIM*VH`, `C_SerialNumbersForGdsMvtVH`).
3. `GR4PO_DOC_Ref` carries `SemanticObject`, `SemanticAction`, `SemanticParam`, `NaviTarget`, `NaviPath` and `ServiceName` — Fiori launchpad navigation metadata embedded in the data model.

This is the OData service behind the Fiori goods-receipt app. It is SAP-standard, but it was not built as an integration contract and SAP publishes no A2X documentation for it.

### Local registration

**Not registered.** `MMIM_GR4PO_DL_SRV` is absent from the 522-row QS4 Gateway catalogue. No `GR4*` service is registered under any name. Registration would be required — and registering it would not make it integration-released.

### Disposition

**CONDITIONAL** — gated on the Fiori-service suitability decision.

It cannot be PRIMARY for API-01: application-internal, draft-enabled, undocumented as an API, unregistered. If the architecture gate rules that Fiori application services are unacceptable as integration endpoints, this becomes REJECT and the finding below still stands.

Its durable value regardless of that gate: it **proves `OpenQuantity` and `DeliveryCompleted` exist in SAP's standard GR model**, so v1.7's `RemainingQuantity` and `ReceiptStatus` should be sourced from a purchasing-document or delivery read alongside `API_MATERIAL_DOCUMENT`, rather than declared unsupported.

### Open gates raised

| # | Gate |
|---|---|
| GR4-1 | What values does `SourceOfGR` take, and can the service key on a purchasing document rather than an inbound delivery? |
| GR4-2 | No property-level creatable/updatable annotations exist; per-field writability is unproven without runtime `$metadata`. |
| GR4-3 | Are `OpenQuantity` and `DeliveryCompleted` populated pre-posting, post-posting, or both? |
| GR4-4 | Fiori-service suitability — architecture decision, shared across all application-internal candidates. |

---

## MMIM_MATDOC

**Queue position:** 2 of 11
**Business API:** API-01 Submit MIGO
**Evidence:** `sources/SRC-SYS-20260815-07_QS4_700_SEGW_MMIM_MATDOC/`
**Catalogue:** "oData Service Material Document" · SAP

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 1,174 |
| **Target-project rows** | **313** |
| Other open roots | 861 (`MMIM_GR4PO_DL` still expanded from queue item 1) |
| Grid manifest rows | 44 |
| Distinct manifest files / physical files | 44 / 44 |
| Collisions / orphans / missing | 0 / 0 / 0 |

The 861 foreign rows are the previous project left open in the workbench. Filtering by `Path` isolates the 313 target rows, exactly as handover §13.1 requires.

### Model surface

8 entity types, 8 entity sets, 2 complex types, 2 associations, 2 function imports, 7 SADL value-help entity types, 7 runtime artifacts (`MMIM_MATDOC_SRV`, `MMIM_MATDOC_MDL`, `MMIM_MATDOC_ANNO_MDL`, `CL_MMIM_MATDOC_*`).

**`MatDocHeader`** (8 properties) keyed on `MaterialDocument` + `MaterialDocumentYear`; also `PostingDate`, `DocumentDate`, `MaterialDocumentHeaderText`, `VersionForPrintingSlip`.

**`MatDocItem`** (27 properties) keyed on `MaterialDocument` + `MaterialDocumentYear` + `MaterialDocumentItem`; carries `MovementType`, `Plant`, `StorageLocation`, `Batch`, `Material`, `QuantityInEntryUnit`, `EntryUnit`, `StockType`, `CurrentStock`, `BlockedStockQuantity`, `GoodsMovementReasonCode`, `Supplier`, `SalesOrder`.

### The decisive finding

**Every entity set is `Addressable` only.** Not one carries Creatable, Updatable or Deletable. Both function imports are `GET`:

| Function import | Method | Purpose |
|---|---|---|
| `AuthorityCheckPost` | GET | Authority *check* for `Application` / `Material` / `Plant` — returns a check table, does not post |
| `ShelfLifeExpirationDate` | GET | Shelf-life determination helper |

`AuthorityCheckPost` is easy to misread from its name. It is a GET returning `CheckTableType` — a pre-flight authorisation probe for a UI, not a posting operation.

### v1.7 coverage

**Covers (as a read-back service only):** `MaterialDocument`, `MaterialDocumentYear`, `Allocations[].MaterialDocumentItem`, `Allocations[].PostedQuantity`, plus `StorageLocation` and `MovementType` per item.

**Cannot cover:** the posting itself — API-01 is a POST command and this service has no write surface at all. Also no `RemainingQuantity`: `CurrentStock` and `BlockedStockQuantity` are stock positions, not open receipt quantity.

### Versus the competing candidate

It does not compete with `API_MATERIAL_DOCUMENT`; it **complements** it. `API_MATERIAL_DOCUMENT` posts and returns header information but leaves open item **MD-4** — whether the create response echoes item numbers and posted quantities. `MMIM_MATDOC` reads exactly those fields by material-document key, and is already registered, so it is the cheapest available answer to MD-4 in a running system.

Against `MMIM_GR4PO_DL` it is weaker on every posting requirement and stronger on nothing except registration.

### Service class

**`APPLICATION-INTERNAL`**, but read-only. Seven SADL value-help entity sets and a dedicated annotation model mark it as the OData service behind a Fiori material-document display app. No draft handling and no launchpad navigation metadata — a lower-risk profile than `MMIM_GR4PO_DL`, because a read-only contract has less to break.

### Local registration

**REGISTERED** as `MMIM_MATDOC_SRV` version 1 in the 522-row QS4 Gateway catalogue. `MMIM_MATDOC_OV_SRV` is registered alongside it.

Registered is not callable. The ICF node and system-alias state are unverified, and no local `$metadata` has been read. Registration only means Basis activation is not the blocker.

### Disposition

**COMPLEMENTARY.** Not a candidate for the API-01 posting command under any reading. Retained as the material-document read-back path: it supplies the response fields `API_MATERIAL_DOCUMENT` may not echo, at zero activation cost.

### Open gates raised

| # | Gate |
|---|---|
| MDOC-1 | Does the registered service actually respond — ICF node, system alias, `$metadata`? Cheapest live check available and it would also settle MD-4. |
| MDOC-2 | Is `MMIM_MATDOC_OV` (also registered) a better read surface than `MMIM_MATDOC` for reconciliation? Tier C; inspect only if the read-back path is adopted. |

---

## LE_SHP_OD_CREATE

**Queue position:** 3 of 11
**Business API:** API-02 Create DI
**Evidence:** `sources/SRC-SYS-20260815-08_QS4_700_SEGW_LE_SHP_OD_CREATE/`
**Catalogue:** "Create Outbound Delivery" · SAP

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 1,949 |
| **Target-project rows** | **775** |
| Other open roots | 1,174 (queue items 1–2 still expanded) |
| Grid manifest rows | 78 |
| Distinct manifest files / physical files | 78 / 78 |
| Collisions / orphans / missing | 0 / 0 / 0 |

### Model surface

Native model is almost empty: **1 entity type, 1 entity set, 0 associations, 0 function imports.** The substance sits in the SADL exposure: 34 entity types, 34 entity sets, 25 associations.

| Entity set | Flags |
|---|---|
| `OutboundDeliveryCreationResponses` | Addressable only |
| `C_OutboundDeliveryCreate` (SADL) | **Updatable** + Pageable — *not* Creatable |
| 32 other SADL sets | value helps (`*VHType`, `I_*Type`) |

### The decisive finding

The name promises a create API. The model is a **collective-processing worklist**.

`C_OutboundDeliveryCreateType` (38 properties) is keyed on `DeliveryBlockReason` + `DeliveryCreationDate` + `DeliveryPriority` + `ForwardingAgent` + `GoodsIssueDate` + `Route` + `SDDocument` + `ShippingPoint` + `ShipToParty`. That is a **delivery due-list line** (VL10-style selection row), not a creation payload. It is `Updatable`, not `Creatable` — the app flags due-list rows for processing.

`OutboundDeliveryCreationResponse` (9 properties) is keyed on **`Sammg`** — a collective-run number — and carries `NoOfDeliveries`, `NoOfIssues`, `NoErrors`, `LogCreateDate`, `Vstel`. That is a **mass-run log**, not a created document.

### v1.7 coverage

**Covers:** selection over sales documents due for delivery (`SDDocument`, `SalesDocumentType`, `SDDocumentCategory`, `ShippingPoint`, `Route`).

**Cannot cover — three independent blockers:**

1. **No `DeliveryQuantity`.** v1.7 API-02 names it the only business value the user enters. No quantity field exists anywhere in the model.
2. **No single `DeliveryDocument` response.** v1.7 requires the created delivery number back. This service returns a collective-run summary and a count.
3. **No STO predecessor.** v1.7 API-02 must accept `PredecessorType = STO_PO`. The model has no purchase-order concept at all — no `PurchaseOrder`, no supplying or receiving plant. Every document reference is an SD document, and the value help is literally `C_SDDocCatOutbDelivSlsOrdVHType` (sales-order document categories).

### Versus the competing candidate

`API_OUTBOUND_DELIVERY_0002` wins decisively. SAP's on-premise 2022 documentation states it creates a delivery with reference to a sales order, **a stock transport order**, or a returns purchase order, and returns the created document. That covers both v1.7 predecessor types and the single-document response shape.

Registration is the only axis where `LE_SHP_OD_CREATE` leads, and it does not compensate: a registered service that cannot express the operation is not a candidate. Handover §5 Gate 5 anticipates exactly this — an unregistered but semantically correct service is not replaced by a semantically wrong registered one.

### Service class

**`APPLICATION-INTERNAL`.** 32 of 34 SADL entity sets are value helps; the transactional entity is a worklist row; the response entity is a processing log keyed on a collective-run number.

### Local registration

**REGISTERED** as `LE_SHP_OD_CREATE_SRV` version 1.

### Disposition

**REJECT** for API-02 — wrong operation shape, no quantity control, no STO predecessor, no single-document response.

This is the clearest case so far that registration status must not drive selection. The discovery report flagged this service as the highest-value new find for API-02 precisely because it was registered; the material evidence does not support that.

### Open gates raised

None. The three blockers are structural and visible in design time.

---

## LE_SHP_QC_DLVREF

**Queue position:** 4 of 11
**Business API:** API-02 Create DI
**Evidence:** `sources/SRC-SYS-20260815-09_QS4_700_SEGW_LE_SHP_QC_DLVREF/`
**Catalogue:** "Quick Create: Delivery with ref." · SAP

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 2,085 |
| **Target-project rows** | **136** |
| Other open roots | 1,949 (queue items 1–3) |
| Grid manifest rows | 32 |
| Distinct manifest files / physical files | 32 / 32 |
| Collisions / orphans / missing | 0 / 0 / 0 |

### Model surface

Native model is **entirely empty** — 0 entity types, 0 entity sets, 0 associations, 0 function imports. Everything is SADL-exposed: 12 entity types, 12 entity sets, 1 association.

| Entity set | Flags |
|---|---|
| `C_DelivWthRefQuickCreate` | **C + U + D + Pageable + Addressable** — a full CRUD transactional entity |
| 11 others | value helps, all read-only |

This is a genuine create surface, unlike queue item 3.

### `C_DelivWthRefQuickCreateType` — 17 properties

Keyed on **`OutboundDelivery`**, so a successful create yields the delivery number as the entity key.

Carries `ReferenceDocument`, `ReferenceSDDocument`, `DeliveryDate`, `PlannedGoodsIssueDate`, `DeliveryDocumentType`, `ShippingPoint`, `ShipToParty`, `CustomerName`, `SalesOrganization`, `DistributionChannel`, `Division` and their name/text twins.

Its value help is `C_SalesOrderDueForDeliveryVH` — `SalesOrder`, `SalesOrderItem`, `ScheduleLine`, `Route`, `ForwardingAgent`, `GoodsIssueDate`.

### v1.7 coverage

**Covers:** create-from-reference against a sales document (`ReferenceSDDocument`), returning `DeliveryDocument` as the entity key. Also `SalesOrganization` and `Division`, both required in the v1.7 response.

**Cannot cover:**

1. **No `DeliveryQuantity`.** All 17 properties are header/organisational; not one is a quantity. v1.7 calls `DeliveryQuantity` "the only business value entered in the validated Create DI modal" and marks it mandatory, with the rule that it must not exceed the open predecessor quantity.
2. **No item level at all.** No material, no item entity, no navigation to items. v1.7's response requires `Material` and `ConfirmedQuantity` from the DI's sole product line.
3. **No STO predecessor.** The value help is sales orders due for delivery; `ReferenceSDDocument` is an SD document. No purchase-order concept exists in the model.
4. **No `Incoterm`**, which v1.7 marks mandatory in the response.

### Versus the competing candidate

`API_OUTBOUND_DELIVERY_0002` wins again, on the same axes plus item-level control. This service is a header-only convenience create for a full-quantity delivery from a sales order — genuinely a create, but a narrower operation than v1.7 specifies.

Between the two LE_SHP candidates, this one is materially closer to API-02 than `LE_SHP_OD_CREATE`: it creates a single document and returns its number. It still fails on quantity control and STO support, which are not negotiable in the v1.7 contract.

### Service class

**`APPLICATION-INTERNAL`.** 11 of 12 entity sets are value helps; the model is a Fiori quick-create dialog backing service with an annotation model.

### Local registration

**REGISTERED** as `LE_SHP_QC_DLVREF_SRV` version 1.

### Disposition

**REJECT** for API-02 — cannot express `DeliveryQuantity`, has no item level, and cannot accept an STO predecessor.

### Open gates raised

| # | Gate |
|---|---|
| QCD-1 | Does the Trade/Non-trade flow ever create a *full-quantity* delivery with no quantity override? If the portal's quantity field is always equal to the open quantity, this service could cover the non-STO subset. v1.7 as written does not permit that assumption. |

---

## Interim position after 4 of 11

| Business API | Leading candidate | Status |
|---|---|---|
| API-01 | `API_MATERIAL_DOCUMENT` (post) + `MMIM_MATDOC` (read-back) | pair emerging; `MMIM_GR4PO_DL` conditional |
| API-02 | `API_OUTBOUND_DELIVERY_0002` | both registered LE_SHP alternatives rejected |

**Pattern across all four:** every registered non-`API_*` candidate examined so far is an `APPLICATION-INTERNAL` Fiori service, and three of four fail the v1.7 operation on structural grounds. Registration has not once predicted fitness. The A2X services remain the semantically correct answers despite needing activation.

---

## SD_CUSTOMER_INVOICES_CREATE

**Queue position:** 5 of 11
**Business API:** API-03 Create Invoice / Billing Documents (BILLING stage)
**Evidence:** `sources/SRC-SYS-20260815-10_QS4_700_SEGW_SD_CUSTOMER_INVOICES_CREATE/`
**Catalogue:** "Create Customer Invoices" · SAP

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 2,935 |
| **Target-project rows** | **850** |
| Other open roots | 2,085 (queue items 1–4) |
| Grid manifest rows | 102 |
| Distinct manifest files / physical files | 102 / 102 |
| Collisions / orphans / missing | 0 / 0 / 0 |

### Model surface

No native entity sets. **Two native function imports**, and 44 SADL entity types of which **none is writable** — all value helps and due-list reads, including `C_BillingDueListItem_F0798Type`, which identifies this as the backing service for Fiori app **F0798 "Create Billing Documents"**.

Runtime artifacts: `SD_CUSTOMER_INVOICES_CREATE` as both Registered Service and Registered Model (no `_SRV` suffix — matching the registered external name exactly), plus `SD_CUSTOMER_INVOICES_CR_ANNO_MDL` and the `CL_SD_CI_CREATE_*` classes.

### The operation

| Function import | Method | Returns |
|---|---|---|
| `CreateBillingDocuments` | **POST** | `FunctionImportResult`, cardinality **1..n** |
| `GetBillingDocumentTypes` | POST | `BillingDocumentTypeText` 0..n |

**`CreateBillingDocuments` parameters (16):** `ReferenceSDDocument`, `ReferenceSDDocumentCategory`, `ReferenceSDDocumentItem`, `ToBeBilledQuantity`, `RequestedBillingDocumentType`, `RequestedBillingDocumentDate`, `BillingDocumentType`, `BillingDocumentDate`, `SalesOrganization`, `BillingDocumentReleaseRequested`, `SeparateBilllingDocumentsRequested` *(SAP's spelling)*, `SnapshotRequested`, `DestinationCountry`, `NewBillToPartyAddressId`, `OldBillToPartyAddressId`, `RefSDDocWithInvalidPartner`.

**`FunctionImportResult` (10 properties):** **`BillingDocument`**, `BillingDocumentItem`, `MessageId`, `MessageType`, `Message`, `BillToParty`, `BillToPartyName`, `OldBillToPartyAddressId`, `BillToPartyAddressText`, `PartnerDeterminationProcedure`.

### v1.7 coverage

**Covers — and this is the significant result:**

- **Billing creation from a delivery.** `ReferenceSDDocument` + `ReferenceSDDocumentCategory` + `ReferenceSDDocumentItem` is exactly the v1.7 API-03 input (`DeliveryDocument` is the validated DI to ship and invoice).
- **`BillingDocument` returned** — a mandatory v1.7 API-03 response field.
- `ToBeBilledQuantity` — quantity control at creation.
- `MessageId` / `MessageType` / `Message` — map onto v1.7 `MessageCode` / `Status` / `Message`.
- `BillingDocumentReleaseRequested` — release to accounting, relevant to the v1.7 `AccountingDocument` response field.
- `RequestedBillingDocumentType`, `RequestedBillingDocumentDate`, `SalesOrganization`.

**Cannot cover:** the rest of the v1.7 API-03 chain. This service does the BILLING stage only — no SHIPMENT, no SHIPMENT_COST, no PGI, no E_INVOICE, no E_WAY_BILL. It does not return `AccountingDocument`, `IRN`, `EWayBillNumber`, `ShipmentDocument`, `ShipmentCostDocument`, `PgiMaterialDocument` or a `ProcessId`/`ProcessStatus`. Nor does it offer idempotency.

That is expected: v1.7 API-03 is explicitly an orchestration (`Class X`), not one SAP operation. This candidate is one stage of it.

### Versus the competing candidate

`API_BILLING_DOCUMENT` (queue item 6) is documented by SAP as OData V2 **read / cancel / PDF** — creation exists only on the OData V4 successor `API_BILLINGDOCUMENT`, which is not a SEGW project and whose QS4 availability is unproven.

On the creation requirement specifically, **`SD_CUSTOMER_INVOICES_CREATE` beats `API_BILLING_DOCUMENT`**: it is the only billing-creation operation found anywhere in the 2,626-project catalogue, and it is already registered.

This materially narrows the billing-creation gap the handover declared. It does not close it — see the service class below — but "no standard creation path exists in QS4" is no longer an accurate statement.

### Service class

**`APPLICATION-INTERNAL`.** 44 SADL entity types, all read-only value helps and due-list projections; a dedicated annotation model; and `C_BillingDueListItem_F0798Type` naming the Fiori app it serves. SAP publishes no A2X documentation for it.

Unlike queue items 3 and 4, however, the *operation* is genuinely the one v1.7 needs. The objection here is service class, not capability.

### Local registration

**REGISTERED** as `SD_CUSTOMER_INVOICES_CREATE` version 1. Note the external name carries no `_SRV` suffix.

### Disposition

**CONDITIONAL** — the leading candidate for the API-03 BILLING stage, gated on the Fiori-service suitability decision (GR4-4).

If that gate permits application-internal services, this is the answer for billing creation and needs no activation. If it does not, API-03 billing creation returns to being an open gap pending the OData V4 `API_BILLINGDOCUMENT` availability check.

### Open gates raised

| # | Gate |
|---|---|
| SCI-1 | Several parameters carry very large `MAX_LENGTH` values (`ReferenceSDDocument` 11,000; `ToBeBilledQuantity` 18,000) while `RequestedBillingDocumentDate` is 10 and `RequestedBillingDocumentType` is 4. This is consistent with delimited *lists* of selected due-list rows — i.e. mass creation — but the delimiter and encoding are unproven from design time. Confirm before designing a single-DI call. |
| SCI-2 | Does `BillingDocumentReleaseRequested` produce the `AccountingDocument` v1.7 needs, or only release for later transfer? |
| SCI-3 | Return cardinality is 1..n. Confirm the mapping from one input delivery to potentially several billing documents (`SeparateBilllingDocumentsRequested`). |

---

## API_BILLING_DOCUMENT

**Queue position:** 6 of 11
**Business APIs:** API-03 (billing result read) · API-10 (STO Invoice read)
**Evidence:** `sources/SRC-SYS-20260815-11_QS4_700_SEGW_API_BILLING_DOCUMENT/`
**Catalogue:** SAP · last changed 19.02.2020

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 469 |
| **Target-project rows** | **459** |
| Other roots (collapsed, 1 row each) | 10 |
| Grid manifest rows | 26 |
| Distinct manifest files / physical files | 26 / 26 |
| Collisions / orphans / missing | 0 / 0 / 0 |

**Workbench reset applied before this extraction.** The first attempt exceeded ten minutes and was abandoned: SEGW had accumulated five expanded projects and the tree had reached 3,393 nodes, so every expansion pass and grid scan walked all of them. Restarting the transaction (`/nSEGW`, navigation only — nothing saved, generated or activated) collapsed the stale roots to one row each and the same extraction completed against **469** nodes. New helper: `tmp/sap_segw_reset_workbench.vbs`. Apply it before each remaining project.

### Model surface

Native model is empty. Eight SADL/CDS entity sets, 14 associations, one native complex type.

| Entity set | Flags |
|---|---|
| `A_BillingDocument` | Pageable + Addressable |
| `A_BillingDocumentItem` | Pageable + Addressable |
| `A_BillingDocumentPartner` / `ItemPartner` | Pageable + Addressable |
| `A_BillingDocumentPrcgElmnt` / `ItemPrcgElmnt` | Pageable + Addressable |
| `A_BillingDocumentText` / `ItemText` | Pageable + Addressable |

**Not one entity set is Creatable, Updatable or Deletable.** Design time confirms exactly what SAP documents for the OData V2 service: read, cancel, PDF.

`A_BillingDocumentType` — 97 properties, key `BillingDocument`. `A_BillingDocumentItemType` — 139 properties, key `BillingDocument` + `BillingDocumentItem`. Navigation: `to_Item`, `to_Partner`, `to_PricingElement`, `to_Text`.

### The design-time under-reporting recurs

A native complex type `FunctionImportResult` exists — `BillingDocument`, `BillingDocumentItem`, `MessageId`, `MessageType`, `Message` — but **no function import appears anywhere in design time**, native or SADL. SAP documents a cancel operation for this service.

This is the second confirmed instance of the pattern first recorded for `API_MATERIAL_DOCUMENT` (open item MD-1), where `Cancel` and `CancelItem` are documented but absent from SEGW. A return type with no visible function import is direct evidence that the design-time model under-reports the runtime surface for SADL-exposed projects. Treat missing function imports in any such project as unproven, never as absent.

### v1.7 coverage

**API-10 STO Invoice — strong read fit.** The item carries `ReferenceSDDocument` + `ReferenceSDDocumentCategory` + `ReferenceSDDocumentItem`, which is the join to the STO outbound delivery v1.7 needs; plus `Material`, `BillingQuantity`, `BillingQuantityUnit`, `NetAmount`, `Plant`. The header supplies `BillingDocument`, `BillingDocumentType`, `BillingDocumentDate`, `CompanyCode`, `SalesOrganization`, `TotalNetAmount`, `TransactionCurrency`, and **`LastChangeDateTime`** — a genuine watermark for the v1.7 `ChangedSince` delta field, which most candidates cannot supply.

`BillingDocumentIsCancelled` and `CancelledBillingDocument` cover the v1.7 `InvoiceStatus` normalisation.

**API-03 — read-back only.** Supplies `BillingDocument` and **`AccountingDocument`**, both v1.7 API-03 response fields. Cannot create.

**Cannot cover:** billing creation, and every non-billing stage of the API-03 chain.

### Versus the competing candidate

These two do not compete; they split the work.

| Requirement | `SD_CUSTOMER_INVOICES_CREATE` | `API_BILLING_DOCUMENT` |
|---|---|---|
| Create the billing document | **DIRECT** | **NO FIT** |
| Read the billing document | no read surface | **DIRECT** (97 + 139 fields) |
| `AccountingDocument` | unproven via a release flag | **DIRECT** as a header field |
| Delta watermark for STO invoice sync | none | **`LastChangeDateTime`** |
| Released integration API | no | **yes** |
| Registered in QS4 | yes | **no** |

For API-03 the pair is: `SD_CUSTOMER_INVOICES_CREATE` creates, `API_BILLING_DOCUMENT` reads back. For API-10 the read service stands alone.

### Service class

**`RELEASED-INTEGRATION`.** A2X naming (`A_*` entity types), SAP-documented for S/4HANA on-premise 2022 with a stated operation set. Contrast with every non-`API_*` candidate examined so far.

### Local registration

**Not registered.** `API_BILLING_DOCUMENT_SRV` is absent from the 522-row QS4 Gateway catalogue. Activation required.

### Disposition

**PRIMARY for API-10** (STO Invoice read) — *conditional on the STO-invoice document-model gate*: this is the right service only if the authoritative object is an SD billing document rather than an MM supplier invoice or an India GST stock-transfer document.

**COMPLEMENTARY for API-03** — billing result read-back alongside a creation service.

**REJECT for API-03 billing creation** — no write surface.

### Open gates raised

| # | Gate |
|---|---|
| ABD-1 | Cancel/PDF function imports are documented by SAP but invisible in design time. Confirm the runtime operation set from `$metadata` after activation. |
| ABD-2 | The STO-invoice document-model gate remains the blocker for API-10 and is unchanged by this extraction. |

---

## MMIM_STO

**Queue position:** 7 of 11
**Business API:** API-08 STO Orders
**Evidence:** `sources/SRC-SYS-20260815-12_QS4_700_SEGW_MMIM_STO/`
**Catalogue:** "Stock Transfer Orders" · SAP

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 87 |
| **Target-project rows** | **76** |
| Other roots (collapsed) | 11 |
| Grid manifest rows | 13 |
| Distinct manifest files / physical files | 13 / 13 |
| Collisions / orphans / missing | 0 / 0 / 0 |

Workbench reset applied first — hence 87 nodes rather than several thousand.

### Model surface

The closest-named project in the catalogue turns out to be the smallest so far: **2 entity types, 2 entity sets, 1 association, 1 function import, 6 runtime artifacts.** No annotation model, no SADL exposures.

| Entity set | Flags |
|---|---|
| `StockTransferOrderHeaders` | **Addressable only** |
| `StockTransferOrderItems` | **Addressable only** |

Neither is Creatable, Updatable, Deletable **or Pageable**.

`StockTransferOrderHeader` — **3 properties**: `PurchaseOrder` (key), `PurchasingDocumentDate`, `SupplyingPlant`.

`StockTransferOrderItem` — 12 properties: `PurchaseOrder` + `PurchaseOrderItem` (key), `SupplyingStorageLocation`, `ReceivingPlant`, `ReceivingStorageLocation`, `Material`, `Batch`, `OrderedQuantity`, `OrderedQuantityUnit`, `ScheduleLineDeliveryDate`, `ScheduledQuantity`, `StockTypeAssignmentReference`.

### What it actually is

`AuthorityCheckSTO` (GET) takes `Application`, `Material`, `SupplyingPlant`, `ReceivingPlant`, `ReceivingStorageLocation`, `OrderedQuantity`, `OrderedQuantityUnit` and **`UsePredictive`**, returning `CheckFieldsSTO` with `Allowed`, `PredictedDelivDte` and `PredictiveIsActive`.

That is an authorisation-and-predicted-delivery-date probe. It shares the `Application` parameter idiom with `MMIM_MATDOC`'s `AuthorityCheckPost`, and the whole project sits in the same `MMIM_*` family as the goods-receipt app. This is a **companion lookup service for the MMIM goods-receipt Fiori app**, not a general stock-transfer-order read API. The name is the most misleading in the shortlist.

### v1.7 coverage

**Covers:** `StockTransportOrder` (as `PurchaseOrder`), `PurchaseOrderItem`, `SupplyingPlant`, `ReceivingPlant`, `Material`, `OrderedQuantity`, `Unit`, `DeliveryDate` (as `ScheduleLineDeliveryDate`).

**Cannot cover — six of the fourteen v1.7 API-08 item fields:**

- **`DocumentType`** — absent. v1.7 names `ZP06` as the documented STO type that must be system-validated. Without the document type this service cannot even distinguish an STO from any other purchase order.
- `CompanyCode`, `PurchasingOrganization`, `PurchasingGroup` — all absent.
- `DocumentStatus` — absent.
- `LastChangedAt` — absent, so no delta watermark for the S/4→CPI→T2 synchronisation v1.7 describes.

It also fails the query contract: v1.7 API-08 specifies `PageSize`/`PageOffset` and filters on supplying plant, receiving plant, material, creation-date range, status and `ChangedSince`. Neither entity set carries a Pageable flag.

### Versus the competing candidate

`API_PURCHASEORDER_PROCESS` (queue item 8) is the A2X purchasing service and is expected to carry document type, purchasing organisation and group, status and change tracking. `MMIM_STO` offers nothing it would lack, and omits six required fields.

The one field `MMIM_STO` exposes that a PO API might not is `ReceivingStorageLocation` — not a v1.7 API-08 requirement.

### Service class

**`APPLICATION-INTERNAL`.** No annotation model and no value helps, but the sole function import is an authority/prediction probe for a UI, and the entity model is far too thin to be an integration contract.

### Local registration

**Not registered.** `MMIM_STO_SRV` is absent from the 522-row QS4 Gateway catalogue.

### Disposition

**REJECT** for API-08 — missing the document type that identifies an STO at all, missing four organisational fields, no status, no change watermark, no paging.

Worth stating plainly: this was ranked Tier A in the discovery report purely on the strength of its name, "Stock Transfer Orders". The material evidence does not support that ranking. Name matching remains triage, not selection.

### Open gates raised

None.

---

## API_PURCHASEORDER_PROCESS

**Queue position:** 8 of 11
**Business APIs:** API-08 STO Orders (read) · API-11 Create STO Purchase Order (create)
**Evidence:** `sources/SRC-SYS-20260815-13_QS4_700_SEGW_API_PURCHASEORDER_PROCESS/`
**Catalogue:** SAP · last changed 04.08.2021

### Extraction integrity

| Measure | Value |
|---|---:|
| Total loaded tree rows | 460 |
| **Target-project rows** | **448** |
| Other roots (collapsed) | 12 |
| Grid manifest rows | 28 |
| Distinct manifest files / physical files | 28 / 28 |
| Collisions / orphans / missing | 0 / 0 / 0 |

### Model surface

Native model empty; 10 SADL/CDS entity sets, and **every one is Creatable + Updatable + Deletable + Pageable + Addressable**:

`A_PurchaseOrder`, `A_PurchaseOrderItem`, `A_PurchaseOrderScheduleLine`, `A_PurchaseOrderNote`, `A_PurchaseOrderItemNote`, `A_PurOrdAccountAssignment`, `A_PurOrdPricingElement`, `A_POSubcontractingComponent`, `A_ValAddedSrvcMM`, `A_ValAddedSrvcMM_2`.

This is the first candidate in the queue with a full transactional CRUD surface on a released A2X model.

`A_PurchaseOrderType` — 57 properties, key `PurchaseOrder`.
`A_PurchaseOrderItemType` — 120 properties, key `PurchaseOrder` + `PurchaseOrderItem`.
`A_PurchaseOrderScheduleLineType` — 14 properties.

### v1.7 coverage — API-08 STO Orders

Thirteen of fourteen item fields land directly:

| v1.7 field | SAP source |
|---|---|
| `StockTransportOrder` | `A_PurchaseOrder.PurchaseOrder` |
| `PurchaseOrderItem` | `A_PurchaseOrderItem.PurchaseOrderItem` |
| **`DocumentType`** | **`PurchaseOrderType`** — enables the ZP06 validation `MMIM_STO` could not do |
| `CompanyCode` | header |
| `PurchasingOrganization` | header |
| `PurchasingGroup` | header |
| `SupplyingPlant` | header `SupplyingPlant` |
| `ReceivingPlant` | item `Plant` |
| `Material` | item |
| `OrderedQuantity` | item `OrderQuantity` |
| `Unit` | item `PurchaseOrderQuantityUnit` |
| `DeliveryDate` | `A_PurchaseOrderScheduleLine.ScheduleLineDeliveryDate` |
| `DocumentStatus` | `PurchasingProcessingStatus` / `PurchasingCompletenessStatus` — **mapping required** |
| **`LastChangedAt`** | **`LastChangeDateTime`** — a real delta watermark for the S/4→CPI→T2 sync |

Paging is supported on every set, satisfying the v1.7 `PageSize`/`PageOffset` contract.

### v1.7 coverage — API-11 Create STO PO

| v1.7 field | SAP source |
|---|---|
| `SourcePlant` | header `SupplyingPlant` |
| `ReceivingPlant` | item `Plant` |
| `CompanyCode` | header |
| `PurchasingGroup` | header |
| `Product` | item `Material` |
| `PurchaseOrderQuantity` | item `OrderQuantity` |
| `Unit` | item `PurchaseOrderQuantityUnit` |
| `DeliveryDate` | schedule line |
| **`RequisitionNumber`** | item **`PurchaseRequisition`** + `PurchaseRequisitionItem` |
| **`Requisitioner`** | item **`RequisitionerName`** |
| Response `PurchaseOrder` | entity key |
| Response `PurchasingOrganization` | header |

`PurchaseRequisition` and `RequisitionerName` settle a discovery-phase question: those v1.7 inputs map to real purchase-order item fields, so `MM_PUR_PR_PROCESS` is not needed to carry them.

**Cannot cover:**

- **`ShippingType`** — v1.7 marks it a mandatory Figma input for API-11. No shipping-type field exists on the purchase-order header or item. Genuine gap.
- Idempotency (`RequestId` / `IsReplay`) — absent, as everywhere.
- `DocumentStatus` needs a mapping decision rather than a field.

### Versus the competing candidate

`MMIM_STO` is beaten on every axis that matters: it lacks the document type, three organisational fields, status, the change watermark and paging. `API_PURCHASEORDER_PROCESS` supplies all of them and can additionally **create**, which `MMIM_STO` cannot.

### Service class

**`RELEASED-INTEGRATION`.** A2X `A_*` entity naming, SAP-documented, with an annotation model.

Property-level creatable annotations mark only the key fields — the familiar SADL pattern where per-property writability lives in the CDS views. Entity-set-level create is unambiguous; per-field write rules remain unproven from design time.

### Local registration

**Not registered.** `API_PURCHASEORDER_PROCESS_SRV` is absent from the 522-row QS4 Gateway catalogue. Activation required.

### Disposition

**PRIMARY for API-08** and **PRIMARY for API-11**, conditional on activation and on confirming the client STO document type and item category.

### Open gates raised

| # | Gate |
|---|---|
| APO-1 | `ShippingType` has no home on the purchase order. Confirm whether the v1.7 API-11 field is genuinely a PO attribute, belongs on the subsequent delivery, or should be dropped. |
| APO-2 | Which of `PurchasingProcessingStatus` / `PurchasingCompletenessStatus` / `PurchasingDocumentDeletionCode` maps to the v1.7 `DocumentStatus` domain? |
| APO-3 | The handover records that SAP deprecates this OData V2 service where a V4 successor exists. Confirm the QS4 position before committing; do not assume V4 availability. |
| APO-4 | Client STO document type (`ZP06` per v1.7) and item category must be system-validated. |

---

## API-05 Stock Availability — three-way comparison

**Queue positions:** 9, 10, 11 of 11
**Business API:** API-05 Stock Availability
**Evidence:**
`sources/SRC-SYS-20260815-14_QS4_700_SEGW_API_MATERIAL_STOCK/`
`sources/SRC-SYS-20260815-15_QS4_700_SEGW_API_PRODUCT_AVAILY_INFO_BASIC/`
`sources/SRC-SYS-20260815-16_QS4_700_SEGW_MMIM_STOCKINDATERANGE/`

These three are not siblings — they are three different answers to "what stock is there?" — so they are compared against the v1.7 requirement directly rather than by pairwise delta.

### Extraction integrity

| Project | Tree total | **Target rows** | Manifest | Distinct | Physical | Collisions |
|---|---:|---:|---:|---:|---:|---:|
| `API_MATERIAL_STOCK` | 66 | **53** | 12 | 12 | 12 | 0 |
| `API_PRODUCT_AVAILY_INFO_BASIC` | 55 | **41** | 10 | 10 | 10 | 0 |
| `MMIM_STOCKINDATERANGE` | 345 | **330** | 48 | 48 | 48 | 0 |

No orphans or missing files in any of the three.

### What each one actually is

**`API_MATERIAL_STOCK`** — 2 read-only entity sets, both Pageable + Addressable, no function imports.
`A_MaterialStock` is a 2-property shell (`Material`, `MaterialBaseUnit`). The substance is `A_MatlStkInAcctMod`, 13 properties with an 11-part key: `Material` + `Plant` + `StorageLocation` + `Batch` + `InventoryStockType` + `InventorySpecialStockType` + `Supplier` + `Customer` + `SDDocument` + `SDDocumentItem` + `WBSElementInternalID`. The single measure is **`MatlWrhsStkQtyInMatlBaseUnit`**.

That key *is* the v1.7 grain: on-hand book stock at material × plant × storage location, with batch and stock type as further dimensions.

**`API_PRODUCT_AVAILY_INFO_BASIC`** — **no entity sets at all.** Three GET function imports returning an `AvailabilityRecord`:

| Function import | Parameters |
|---|---|
| `DetermineAvailabilityOf` | `ATPCheckingRule`, `Material`, `SupplyingPlant`, `RequestedQuantityInBaseUnit` |
| `DetermineAvailabilityAt` | `ATPCheckingRule`, `Material`, `SupplyingPlant`, `RequestedUTCDateTime` |
| `CalculateAvailabilityTimeseries` | `ATPCheckingRule`, `Material`, `SupplyingPlant` |

**`MMIM_STOCKINDATERANGE`** — a parameterised analytical CDS query. `C_StockOnIntervalBoundariesParameters` takes `P_StartDate`, `P_EndDate`, `P_DisplayCurrency`, `P_GroupByField`; `C_StockOnIntervalBoundariesResult` returns 47 properties including `MatlWrhsStkQtyOnStartDate`, `MatlWrhsStkQtyOnEndDate`, `MatlStkIncrQtyInMatlBaseUnit`, `MatlStkDecrQtyInMatlBaseUnit`, `NetGoodsRcptQtyInBaseUnit`, `NetGoodsIssueQtyInBaseUnit`, plus 16 value-help entity sets.

### v1.7 coverage compared

| v1.7 API-05 requirement | `API_MATERIAL_STOCK` | `API_PRODUCT_AVAILY_INFO_BASIC` | `MMIM_STOCKINDATERANGE` |
|---|---|---|---|
| `Items[].Material` | **DIRECT** | DIRECT (input only) | **DIRECT** |
| `Items[].MaterialDescription` | **absent** | absent | **DIRECT** (`MaterialName`) |
| `Items[].Plant` | **DIRECT** | DIRECT (as `SupplyingPlant`) | **DIRECT** |
| `Items[].StorageLocation` | **DIRECT** | **NO FIT — no such parameter** | **DIRECT** |
| `Items[].StorageLocationDescription` | **absent** | absent | **DIRECT** (`StorageLocationName`) |
| `Items[].SystemQuantity` | **DIRECT** (`MatlWrhsStkQtyInMatlBaseUnit`) | ATP quantity — different meaning | period-boundary quantities |
| `Items[].Unit` | **DIRECT** | n/a | **DIRECT** |
| **`Items[].StockAgeingDays`** | **absent** | absent | **absent** |
| Plant-scoped list of all materials | **DIRECT** (Pageable) | **NO FIT — one material per call** | DIRECT (Pageable) |
| `PageSize` / `PageOffset` | **DIRECT** | **NO FIT** | DIRECT |
| Batch dimension for FIFO input | **DIRECT** | absent | DIRECT |

### The three verdicts

**`API_MATERIAL_STOCK` — PRIMARY.** It is the only candidate whose key matches the v1.7 grain and whose measure is on-hand book stock. Released A2X, pageable, batch- and stock-type-aware. Its gaps are cosmetic (`MaterialDescription`, `StorageLocationDescription`) and resolvable from material and storage-location master reads.

**`API_PRODUCT_AVAILY_INFO_BASIC` — REJECT for API-05.** Three independent disqualifiers: it has **no storage-location parameter at all** (ATP is calculated at plant level), it accepts **one material per call** so it cannot return a plant's stock population, and it answers a different business question — calculated availability against a checking rule, not book stock. Handover §2.3 insisted these two must not be collapsed; the design-time evidence confirms it decisively rather than by argument.

It remains a legitimate candidate for a *different* need — the outbound batch/FIFO allocation check that `SYSTEM_OF_RECORD_MATRIX.md` records as a separate real-time requirement (Q-038) — but that is not API-05.

**`MMIM_STOCKINDATERANGE` — COMPLEMENTARY, and it does not solve what it was promoted for.** The discovery report promoted it specifically because it looked like the only possible source of `StockAgeingDays`. **It is not.** It reports how stock *changed* between two dates — opening balance, closing balance, increases, decreases, net receipts and issues — not how long stock has been held. Age bands could only be inferred by running multiple intervals, which is derivation, not the field.

What it does contribute is `MaterialName` and `StorageLocationName`, the two descriptions `API_MATERIAL_STOCK` lacks.

### `StockAgeingDays` is an uncovered requirement

No candidate in the entire catalogue supplies it. This reconciles with existing project evidence rather than contradicting it: `SYSTEM_OF_RECORD_MATRIX.md` records Stock Ageing as derived from the S/4 report `ZMM5013`, delivered to T2 **from Datasphere on a daily/D-1 cadence, display-only**. v1.7 itself marks the field "source dependent".

So the architecture already routes ageing outside the live API path. The correct conclusion is not that API-05 has a gap to close in SAP, but that `StockAgeingDays` should be confirmed as a Datasphere-served field and removed from the live S/4 read contract — a functional decision, not a service-selection one.

### Service class and registration

| Project | Service class | Registered in QS4 |
|---|---|---|
| `API_MATERIAL_STOCK` | `RELEASED-INTEGRATION` | **No** |
| `API_PRODUCT_AVAILY_INFO_BASIC` | `RELEASED-INTEGRATION` | **No** |
| `MMIM_STOCKINDATERANGE` | `APPLICATION-INTERNAL` (16 value helps, annotation model, parameterised analytical query) | **No** |

### Open gates raised

| # | Gate |
|---|---|
| STK-1 | Confirm `StockAgeingDays` is served from Datasphere (`ZMM5013`) and drop it from the live API-05 contract, or name a different SAP source. |
| STK-2 | Where do `MaterialDescription` and `StorageLocationDescription` come from — a master-data service, `MMIM_STOCKINDATERANGE`, or T2's own cache? |
| STK-3 | Which `InventoryStockType` values count as v1.7 `SystemQuantity`? v1.7 says "exact included stock category requires MM confirmation". |
| STK-4 | Does the outbound batch/FIFO allocation check (Q-038) need `API_PRODUCT_AVAILY_INFO_BASIC` as a separate operation? |
