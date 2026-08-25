# Deep dive — `API_INBOUND_DELIVERY_0002`

**Date:** 2026-08-15
**System:** QS4 / client 700 / user QNOVATE8, read-only SEGW
**Tier A rank:** 3
**Primary v1.7 target:** API-01 Submit MIGO
**Final disposition:** `NO FIT` for API-01 **used alone** · `CONDITIONAL-BUSINESS-GATE` within the broader receiving process, pending confirmation of the QS4 STO document flow

---

## 0. Headline

The inbound delivery A2X service is a well-formed standard API whose SAP-official identity is confirmed for S/4HANA 2022. Used **alone**, it cannot satisfy API-01.

Two facts are established by both design-time and official evidence:

1. `PostGoodsReceipt` accepts **one parameter, `DeliveryDocument`**. It cannot carry a storage-location/quantity allocation set.
2. `StorageLocation` on the delivery item is **neither creatable nor updatable**, so the allocation set cannot be staged onto the document beforehand either.

A third point is **unresolved**, and is recorded as a conflict rather than a finding:

3. Whether `PostGoodsReceipt` returns any payload at all. SEGW declares the return type as complex type `PutawayReport` with cardinality `0..n`; SAP's 2022 operation page states the response body is empty. See §5.1. Either way, neither the declared `PutawayReport` structure nor the documented empty body contains a material-document number or year — so the API-01 response requirement is unmet on both readings — but the conflict itself stands open until local runtime `$metadata` or a sandbox call settles it.

v1.7 API-01 requires a mandatory `Allocations[]` array of storage location plus quantity, and mandatory `MaterialDocument` + `MaterialDocumentYear` in the response. This service cannot express that request, and on neither reading of the conflict can it produce that response.

**Scope of this verdict.** `NO FIT` applies to this service *as the API-01 posting service on its own*. It does not rule the service out of the receiving process as a whole: if the QS4 STO flow creates an SAP inbound delivery at the depot, this service remains a candidate for the putaway and confirmation steps around whatever posts the material document. That broader role is `CONDITIONAL-BUSINESS-GATE` until the STO document flow is confirmed — see §10.

---

## 1. Project identity

| Attribute | Value | Evidence |
|---|---|---|
| Project | `API_INBOUND_DELIVERY_0002` | `LOCAL-DESIGN` |
| Catalogue description | Remote API for Inbound Delivery | `LOCAL-DESIGN` |
| Created by / on | SAP / 04.06.2018 | `LOCAL-DESIGN` |
| Last changed on | 05.04.2022 | `LOCAL-DESIGN` |

Evidence directory: `sources/SRC-SYS-20260815-03_QS4_700_SEGW_API_INBOUND_DELIVERY_0002/`
Tree rows for this project: 618 of 621 (three collapsed foreign roots remain in `SEGW_TREE.tsv`; filter by `Path`).
Grid manifest rows: 41.

## 2. Runtime identity

| Attribute | Value | Evidence |
|---|---|---|
| Model | `API_INBOUND_DELIVERY_MDL` | `LOCAL-DESIGN` |
| Service (TADIR object) | `API_INBOUND_DELIVERY_SRV` | `LOCAL-DESIGN` |
| External runtime path | `/sap/opu/odata/sap/API_INBOUND_DELIVERY_SRV;v=2/` | `SAP-OFFICIAL` |
| Version selector | `;v=2` | `SAP-OFFICIAL` |
| API Hub identity | `API_INBOUND_DELIVERY_SRV_0002` | `SAP-OFFICIAL` |
| Protocol | OData V2 (A2X) | `SAP-OFFICIAL` |
| DPC / DPC_EXT | `CL_API_INBOUND_DELI_01_DPC` / `_DPC_EXT` | `LOCAL-DESIGN` |
| MPC / MPC_EXT | `CL_API_INBOUND_DELI_01_MPC` / `_MPC_EXT` | `LOCAL-DESIGN` |

The `_01` class suffix on the `_0002` project is not a version indicator. See `INBOUND_DELIVERY_DELTA.md`.

## 3. Model counts

| Surface | Count |
|---:|---:|
| Entity types | 10 |
| Entity sets | 10 |
| Complex types | 2 |
| Associations | 9 |
| Association sets | 9 |
| Function imports | 12 |
| Runtime artifacts | 6 |

## 4. Entity-set operation matrix

`LOCAL-DESIGN`. Design-time annotations only; `DPC_EXT` is not proven to enforce them.

| Entity set | Creatable | Updatable | Deletable | Pageable | Addressable | Searchable |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `A_InbDeliveryHeader` | X | X | X | X | X | X |
| `A_InbDeliveryItem` | | X | X | X | X | X |
| `A_InbDeliveryDocFlow` | | X | | | | |
| `A_InbDeliveryAddress` | | | | | | |
| `A_InbDeliveryHeaderText` | | | | | | |
| `A_InbDeliveryItemText` | | | | | | |
| `A_InbDeliveryPartner` | | | | | | |
| `A_InbDeliverySerialNmbr` | | | | | | |
| `A_InbDeliveryValAddedSrvc` | | | | | | |
| `A_MaintenanceItemObjList` | | | | | | |

`SAP-OFFICIAL` constraint: only `A_InbDeliveryHeader`, `A_InbDeliveryItem` and `A_InbDeliveryDocFlow` can be addressed directly, and `A_InbDeliveryDocFlow` permits GET on a single entity but not on the entity set. Everything else must be reached by navigation.

## 5. Function-import matrix

All twelve are `POST`, all return a complex type with cardinality `0..n`. `LOCAL-DESIGN`, corroborated operation-for-operation by `SAP-OFFICIAL`.

| Function import | Action for | Returns | Parameters |
|---|---|---|---|
| `PostGoodsReceipt` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument` |
| `ReverseGoodsReceipt` | `A_InbDeliveryHeaderType` | `DeliveryMessage` | `DeliveryDocument`, `ActualGoodsMovementDate` |
| `PutawayAllItems` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument` |
| `PutawayOneItem` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `PutawayOneItemWithBaseQuantity` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem`, `ActualDeliveredQtyInBaseUnit`, `BaseUnit` |
| `PutawayOneItemWithSalesQuantity` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem`, `ActualDeliveryQuantity`, `DeliveryQuantityUnit` |
| `SetPutawayQuantityWithBaseQuantity` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem`, `ActualDeliveredQtyInBaseUnit`, `BaseUnit` |
| `ConfirmPutawayAllItems` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument` |
| `ConfirmPutawayOneItem` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `AddSerialNumberToDeliveryItem` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem`, `SerialNumber` |
| `DeleteSerialNumberFromDeliveryItem` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem`, `SerialNumber` |
| `DeleteAllSerialNumbersFromDeliveryItem` | `A_InbDeliveryItemType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem` |

### The two return shapes

`PutawayReport` (14 properties): seven `SystemMessage*` fields plus `DeliveryDocument`, `DeliveryDocumentItem`, `DeliveryDocumentItemText`, `Material`, `Batch`, `ActualDeliveryQuantity`, `DeliveryQuantityUnit`.

`DeliveryMessage` (13 properties): seven `SystemMessage*` fields plus `DeliveryDocument`, `DeliveryDocumentItem`, `ScheduleLine`, `CollectiveProcessing`, `CollectiveProcessingMsgCounter`, `CollectiveProcessingType`.

Neither contains a material-document number or a material-document year.

### 5.1 UNRESOLVED — `PutawayReport` versus documented empty response

| Source | Claim | Class |
|---|---|---|
| QS4 SEGW function-import grid | `PostGoodsReceipt` returns complex type `PutawayReport`, cardinality `0..n` | `LOCAL-DESIGN` |
| SAP Help, on-premise 2022, *PostGoodsReceipt* | "The body of the response is empty." | `SAP-OFFICIAL` |

These contradict each other and **this deep dive does not resolve the conflict.** Handover §1.5 is explicit that design-time annotations are not proof of `DPC_EXT` behaviour and that runtime `$metadata` supersedes design-time when available — but no local runtime `$metadata` has been obtained, so neither source can be preferred on evidence.

Resolution requires one of: local `$metadata` for `API_INBOUND_DELIVERY_SRV;v=2` once the service is registered, or an authorised sandbox call. Both are outside this mission's read-only scope.

The same conflict pattern may recur on other function-import-bearing candidates. Check it explicitly on each rather than assuming either source wins.

**What does not depend on the conflict:** neither the declared `PutawayReport` structure nor an empty body carries `MaterialDocument` or `MaterialDocumentYear`. The API-01 response gap holds on both readings.

## 6. Business-critical property mapping

`LOCAL-DESIGN`, confirmed field-for-field by `SAP-OFFICIAL` on the create and change operations.

### What can be written

| Entity | Creatable | Updatable |
|---|---|---|
| `A_InbDeliveryHeaderType` (107 props) | `Supplier`, `DeliveryDate`, `DeliveryTime`, `DeliveryDocumentBySupplier`, `BillOfLading`, `ProposedDeliveryRoute`, `ShippingType` | `DeliveryDate`, `DeliveryTime`, `ProposedDeliveryRoute`, `ShippingType` |
| `A_InbDeliveryItemType` (143 props) | `ReferenceSDDocument` **(mandatory)**, `ReferenceSDDocumentItem`, `Material`, `Plant`, `ActualDeliveryQuantity`, `DeliveryQuantityUnit`, `DeliveryDocument` | `ActualDeliveryQuantity` |
| `A_InbDeliveryDocFlowType` (10 props) | — | `QuantityInBaseUnit` |

`SAP-OFFICIAL` create contract for `A_InbDeliveryItem` lists exactly these seven fields with `ReferenceSDDocument` mandatory, and the change contract lists exactly `ActualDeliveryQuantity`. The SEGW annotations are an accurate predictor of the documented contract for this service — useful calibration for the remaining Tier A projects.

### What is read-only

`StorageLocation`, `Batch`, `StockType`, `GoodsMovementType`, `GoodsMovementStatus`, `GoodsMovementReasonCode`, `ShelfLifeExpirationDate`, `ManufactureDate`, `WarehouseStorageBin`, `InventorySpecialStockType` are all present on the item and all **read-only**.

One documentation conflict worth recording: the service overview page says that if you "include additional information (for example, the quantity of the item or storage location) this information will be used when you create the inbound delivery". The operation-level *Create Inbound Delivery* page does **not** list `StorageLocation` among the accepted create fields, and the SEGW annotation does not mark it creatable. Two of three sources agree it is not writable. Treated as **not writable**; the overview prose is `UNPROVEN` and would need local runtime `$metadata` or a sandbox call to overturn.

### Predecessor reference

There is no `PurchaseOrder` property anywhere in the model. The purchase-order number is carried in the generic `ReferenceSDDocument` / `ReferenceSDDocumentItem` / `ReferenceSDDocumentCategory` triple. `SAP-OFFICIAL`: "You cannot create an inbound delivery without reference to a purchase order."

### Material-document read-back path

`A_InbDeliveryDocFlow` exposes `SubsequentDocument`, `SubsequentDocumentCategory` and `SubsequentDocumentItem`. After a goods receipt the material document appears there as a subsequent document, reachable through the item's `to_DocumentFlow` navigation property (the entity set itself is not addressable). **`FiscalYear` is not present anywhere in the document flow**, so the second half of the material-document key still cannot be obtained from this service.

## 7. v1.7 coverage matrix

API-01 as specified in the authoritative workbook (`BUSINESS-DEMAND`, `SRC-DOC-20260815-01`, sheet *API-01 Submit MIGO*):

| v1.7 requirement | Coverage | Basis |
|---|---|---|
| Post goods receipt against a delivery reference | `PARTIAL` | `PostGoodsReceipt` posts GR for an SAP **inbound** delivery. v1.7 states the reference is an **outbound** delivery. |
| `Allocations[].StorageLocation` (mandatory) | `NO FIT` | Not a create or update field; not a `PostGoodsReceipt` parameter. |
| `Allocations[].Quantity` (mandatory, multi-line) | `NO FIT` | Quantity is a single item-level value; there is no allocation collection. |
| `MaterialDocument` in response (mandatory) | `NO FIT` | Absent from `PutawayReport`; absent under the documented empty-body reading; absent from the document flow. |
| `MaterialDocumentYear` in response (mandatory) | `NO FIT` | Not exposed anywhere in the model, including the document flow. |
| `Allocations[].MaterialDocumentItem` (mandatory) | `NO FIT` | No material-document item concept in this service. |
| `ReceiptStatus` / `RemainingQuantity` | `PARTIAL` | Fields exist (`GoodsMovementStatus`, `OverallGoodsMovementStatus`, delivery and doc-flow quantities) but require a second read; not returned by the posting. Whether they map to the v1.7 PENDING/PARTIAL/COMPLETED semantics is `UNPROVEN`. |
| `PostingDate` / `DocumentDate` control | `NO FIT` | `PostGoodsReceipt` takes no date. Only `ReverseGoodsReceipt` accepts `ActualGoodsMovementDate`. |
| Idempotency (`RequestId`, `IsReplay`) | `NO FIT` | No idempotency key in the standard contract. Must be built in CPI/T2. |

**API-01 verdict, used alone: `NO FIT`.**

**API-01 verdict, as one step inside the receiving process: `PARTIAL` / `CONDITIONAL`.** If QS4 creates an inbound delivery for the STO at the depot, this service covers document creation from the PO, putaway, putaway confirmation and goods-receipt triggering — while the allocation input and the material-document key must come from another service. That role stands or falls on the STO document flow question in §10 and must not be treated as settled here.

> **Prohibited derivation.** `MaterialDocumentYear` must never be derived from a posting date, a document date, or the current date. It is part of the authoritative SAP material-document key and must be read from the SAP source that owns it. Any design that infers it is wrong regardless of how plausible the arithmetic looks.

Secondary relevance, should the receiving process turn out to create SAP inbound deliveries:

| v1.7 operation | Coverage | Note |
|---|---|---|
| API-08 STO Orders | `NO FIT` | Wrong object; this is the delivery, not the PO. |
| API-09 STO Deliveries | `UNPROVEN` | Reads the receiving-side delivery only if inbound deliveries exist for STOs. The dispatch-side document is outbound. |

## 8. API identity versus local runtime availability

These are two different questions and must never be reported as one. Handover §8 keeps the design-time and registered inventories separate for exactly this reason.

| Question | Answer | Class |
|---|---|---|
| **Does SAP publish this API for this release?** | Yes. `API_INBOUND_DELIVERY_SRV_0002`, OData V2 A2X, documented for S/4HANA on-premise 2022, no deprecation notice. | `SAP-OFFICIAL` |
| **What would the runtime path be?** | `/sap/opu/odata/sap/API_INBOUND_DELIVERY_SRV;v=2/` | `SAP-OFFICIAL` |
| **Does the project exist in QS4 design time?** | Yes. SEGW project present, six runtime artifacts generated. | `LOCAL-DESIGN` |
| **Is the service registered and callable in QS4 today?** | **No.** `API_INBOUND_DELIVERY_SRV` does not appear in the normalised 522-row QS4 Gateway catalogue at any version. | `LOCAL-RUNTIME` |
| **Is the ICF node / system alias active?** | Unknown. Not established by any evidence held. | — |
| **Has local `$metadata` been read?** | No. | — |

SAP publishing an API says nothing about QS4 being able to call it. Design-time presence says nothing either. Only the registered catalogue speaks to local availability, and it says this service is absent.

Per handover §5 Gate 5, an unregistered but functionally suitable service still stays in scope as a `KEEP` candidate carrying an activation requirement — it is not replaced by a semantically wrong registered service. That principle is not what disqualifies this project from API-01; the operation and data gaps in §7 are.

Basis activation, if requested, must name **both** the service and the version. The landscape already registers four services at `version = 2`, so the `;v=n` mechanism is in use here.

The SEGW Runtime Artifacts row labelled "Registered Service" is an artifact *type*, not evidence of registration. Not used as such here.

## 9. Official SAP confirmation

`SAP-OFFICIAL`, SAP Help Portal, **SAP S/4HANA on-premise, version 2022 (Oct 2022)** — the correct release variant for QS4:

- *Inbound Delivery (A2X)* — technical name `API_INBOUND_DELIVERY_SRV_0002`; read, create, update, delete.
- *Operations for Inbound Delivery API* — all operation URLs use `API_INBOUND_DELIVERY_SRV;v=2`.
- *Create Inbound Delivery* — `ReferenceSDDocument` mandatory; cannot create without a purchase order; delivery splits are not reported back.
- *Change Inbound Delivery Item* — only `ActualDeliveryQuantity` is changeable.
- *PostGoodsReceipt* — `DeliveryDocument` mandatory; ETag required; response body empty; one occurrence per change set.

Integration constraints that will land on CPI/T2 regardless of which service is finally chosen:

- **ETag / `If-Match` is mandatory** for all PATCH and DELETE operations and for `PostGoodsReceipt`. A GET must precede every change. Errors 412 / 428 / 501 are the documented failure modes.
- Multiple delivery documents cannot be updated in one change set.
- No handling-unit reference is available on the inbound side.
- Roles are enforced; operations fail without an authorised role.

No deprecation notice is attached to this service in the 2022 documentation.

## 10. Gaps and decisions

**Missing operations:** multi-storage-location allocated goods receipt; material-document key return; posting-date control on receipt; idempotent replay.

**Activation requirement:** if retained for any purpose, Basis must register and activate `API_INBOUND_DELIVERY_SRV` at `;v=2`, with the ICF node and system alias active.

**Unresolved functional gate (handover §14 Q1), the one that decides this project's fate:**

> Does the QS4 STO process create an SAP **inbound delivery** at the receiving depot, or does the depot post its goods receipt directly against the STO purchase order / the dispatching outbound delivery?

The v1.7 workbook says the receipt reference is an outbound delivery, which points away from this service. But v1.7 describes the portal's view of the dispatch document and is not by itself proof of the SAP receipt document. This must be answered from the QS4 configuration or by a decision owner — not by inference.

- If **no** inbound delivery is created: this project is `REJECT-WRONG-OBJECT` outright.
- If an inbound delivery **is** created: it remains a receiving-side companion for putaway and confirmation, while the material document itself still has to come from elsewhere.

Either way it is not the API-01 posting service on its own.

### Open items carried forward from this deep dive

| # | Open item | Blocks | Resolution route |
|---|---|---|---|
| ID-1 | Does the QS4 STO flow create an inbound delivery at the receiving depot? | The service's entire receiving-side role | QS4 configuration or a decision owner |
| ID-2 | `PutawayReport` return versus documented empty response (§5.1) | Response-shape claims for every function import in this family | Local `$metadata` after registration, or an authorised sandbox call |
| ID-3 | Is `StorageLocation` truly non-writable at create? Overview prose says otherwise than the operation page and the annotation | Whether any allocation input is possible here at all | Local `$metadata`, or an authorised sandbox call |
| ID-4 | Is the ICF node / system alias active for this service? | Activation planning | Basis |
| ID-5 | `A_InbDeliveryValAddedSrvc` present in SEGW but absent from 2022 documentation | Nothing currently; do not build on it | SAP note search if it ever matters |

## 11. Final disposition

| Scope | Status |
|---|---|
| API-01 Submit MIGO, **service used alone** | `NO FIT` — cannot express the allocation request; cannot return the material-document key |
| API-01, **as a step within the receiving process** | `CONDITIONAL-BUSINESS-GATE` — plausible for create-from-PO, putaway and confirmation; gated on ID-1 |
| API-09 STO Deliveries | `UNPROVEN` — gated on ID-1 |
| Sibling generation choice | `KEEP-PRIMARY` for `;v=2` over the base `;v=1` |
| QS4 runtime availability | Not registered; activation would be required |

### What this does *not* decide

It does not select a service for API-01. `API_MATERIAL_DOCUMENT` (Tier A rank 5) is the **next candidate to test**, not a selection: the v1.7 API-01 shape — a header plus an `Allocations[]` collection of storage location and quantity, returning `MaterialDocument`, `MaterialDocumentYear` and a `MaterialDocumentItem` per allocation — resembles a multi-item material document more than a delivery goods receipt, and that resemblance is a hypothesis to be tested through the same six gates, not a conclusion. Handover §1.3 applies: shape matching is triage, not selection.

Nothing may be declared selected for API-01 until that deep dive is complete and its own registration, version and runtime evidence is in hand.
