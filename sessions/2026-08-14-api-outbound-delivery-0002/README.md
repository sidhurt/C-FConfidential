# `API_OUTBOUND_DELIVERY_0002` — design-time contract

**Date:** 2026-08-14
**System:** `QS4` / client `700` / user `QNOVATE8`, session `/app/con[2]/ses[0]`
**Evidence:** `sources/SRC-SYS-20260814-01_QS4_700_SEGW_API_OUTBOUND_DELIVERY_0002/`
**Method:** SAP GUI scripting, read-only. 823 tree nodes and 52 ALV grids exported. No save, generate, activate, check, registration or business posting. Service Maintenance was excluded by scope and never expanded.

## What this document is

This is the **design-time** contract as SEGW holds it. It is authoritative for the model SAP ships in this project. It is **not** the runtime contract: see §Gaps before using it to write client code.

## Runtime artifacts — SAP-confirmed

| Artifact | Type | TADIR |
|---|---|---|
| `API_OUTBOUND_DELIVERY_MDL` | Registered Model | `R3TR IWMO` |
| `API_OUTBOUND_DELIVERY_SRV` | Registered Service | `R3TR IWSV` |
| `CL_API_OUTBOUND_DELIVE_DPC` | Data Provider Base Class | `R3TR CLAS` |
| `CL_API_OUTBOUND_DELIVE_DPC_EXT` | Data Provider Extension Class | `R3TR CLAS` |
| `CL_API_OUTBOUND_DELIVE_MPC` | Model Provider Base Class | `R3TR CLAS` |
| `CL_API_OUTBOUND_DELIVE_MPC_EXT` | Model Provider Extension Class | `R3TR CLAS` |

Model size: 13 entity types, 13 entity sets, 4 complex types, 14 associations, 13 association sets, 15 function imports.

## Entity sets and CRUD annotations — SAP-confirmed

Flags are the `sap:creatable` / `updatable` / `deletable` annotations carried in the SEGW model.

| Entity set | Entity type | Create | Update | Delete | Pageable | Addressable | Searchable |
|---|---|:--:|:--:|:--:|:--:|:--:|:--:|
| `A_OutbDeliveryHeader` | `A_OutbDeliveryHeaderType` | X | X | X | X | X | X |
| `A_OutbDeliveryItem` | `A_OutbDeliveryItemType` | | X | X | X | X | X |
| `A_OutbDeliveryHeaderText` | `A_OutbDeliveryHeaderTextType` | X | X | X | | | |
| `A_OutbDeliveryItemText` | `A_OutbDeliveryItemTextType` | X | X | X | | | |
| `A_OutbDeliveryAddress2` | `A_OutbDeliveryAddress2Type` | | X | | X | X | X |
| `A_OutbDeliveryDocFlow` | `A_OutbDeliveryDocFlowType` | | X | | | | |
| `A_HandlingUnitHeaderDelivery` | `A_HandlingUnitHeaderDeliveryType` | X | | | | | X |
| `A_HandlingUnitItemDelivery` | `A_HandlingUnitItemDeliveryType` | X | | | | | X |
| `A_OutbDeliveryAddress` | `A_OutbDeliveryAddressType` | | | | | | |
| `A_OutbDeliveryPartner` | `A_OutbDeliveryPartnerType` | | | | | | |
| `A_OutbDeliveryValAddedSrvc` | `A_OutbDeliveryValAddedSrvcType` | | | | | | |
| `A_MaintenanceItemObject` | `A_MaintenanceItemObjectType` | | | | | | |
| `A_SerialNmbrDelivery` | `A_SerialNmbrDeliveryType` | | | | | | |

**Read the blanks carefully.** Five entity sets carry no CRUD annotation at all — they are read-only projections in this model. `A_OutbDeliveryItem` is **not** annotated creatable; only header is.

The `Create` / `Update` / `Delete` / `GetEntity` / `GetEntitySet` nodes under Service Implementation appear identically under all 13 entity sets. They are generic SEGW scaffolding and are **not** evidence that a method is implemented. Do not cite them.

## Keys — SAP-confirmed

| Entity type | Key(s) | Props |
|---|---|---|
| `A_OutbDeliveryHeaderType` | `DeliveryDocument` (String 10) | 108 |
| `A_OutbDeliveryItemType` | `DeliveryDocument` (10), `DeliveryDocumentItem` (6) | 144 |
| `A_OutbDeliveryHeaderTextType` | `DeliveryDocument` (10), `TextElement` (4), `Language` (2) | 6 |
| `A_OutbDeliveryItemTextType` | `DeliveryDocument` (10), `DeliveryDocumentItem` (6), `TextElement` (4), `Language` (2) | 7 |
| `A_OutbDeliveryAddress2Type` | `DeliveryDocument` (10), `PartnerFunction` (2) | 50 |
| `A_OutbDeliveryAddressType` | `AddressID` (10), `POBox` (10), `POBoxDeviatingCountry` (3) | 48 |
| `A_OutbDeliveryPartnerType` | `PartnerFunction` (2), `SDDocument` (10) | 10 |
| `A_OutbDeliveryDocFlowType` | `PrecedingDocument` (10), `PrecedingDocumentItem` (6), `SubsequentDocumentCategory` (4) | 10 |
| `A_OutbDeliveryValAddedSrvcType` | `DeliveryDocument`, `DeliveryDocumentItem`, `ValueAddedServiceType`, `ValueAddedSubServiceType` | 18 |
| `A_HandlingUnitHeaderDeliveryType` | `HandlingUnitInternalId` (10) | 43 |
| `A_HandlingUnitItemDeliveryType` | `HandlingUnitInternalId` (10), `HandlingUnitItem` (6) | 16 |
| `A_SerialNmbrDeliveryType` | `MaintenanceItemObjectList` (Int64) | 5 |
| `A_MaintenanceItemObjectType` | `MaintenanceItemObject` (Int32), `MaintenanceItemObjectList` (Int64) | 9 |

Full per-field lists (Edm type, precision, scale, max length, nullable, filterable, ABAP field) are in `grids/Data_Model__Entity_Types__*__Properties.tsv`.

## Function imports — SAP-confirmed

All 15 are **`POST`**. None returns an entity set; all return a complex type.

| Function import | Return type | Card. | Bound to | Parameters |
|---|---|---|---|---|
| `PostGoodsIssue` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument` |
| `ReverseGoodsIssue` | `Return` | 0..n | `A_OutbDeliveryHeaderType` | `ActualGoodsMovementDate` (Edm.DateTime), `DeliveryDocument` |
| `PickAllItems` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument` |
| `PickOneItem` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `PickOneItemWithBaseQuantity` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `ActualDeliveredQtyInBaseUnit`, `BaseUnit`, `DeliveryDocument`, `DeliveryDocumentItem` |
| `PickOneItemWithSalesQuantity` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `ActualDeliveryQuantity`, `DeliveryDocument`, `DeliveryDocumentItem`, `DeliveryQuantityUnit` |
| `SetPickingQuantityWithBaseQuantity` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `ActualDeliveredQtyInBaseUnit`, `BaseUnit`, `DeliveryDocument`, `DeliveryDocumentItem` |
| `ConfirmPickingAllItems` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument` |
| `ConfirmPickingOneItem` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `PickAndBatchSplitOneItem` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `Batch`, `DeliveryDocument`, `DeliveryDocumentItem`, `SplitQuantity`, `SplitQuantityUnit` |
| `CreateBatchSplitItem` | `CreatedDeliveryItem` | 0..1 | `A_OutbDeliveryItemType` | `ActualDeliveryQuantity`, `Batch`, `DeliveryDocument`, `DeliveryDocumentItem`, `DeliveryQuantityUnit`, `PickQuantityInSalesUOM` |
| `AddSerialNumberToDeliveryItem` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument`, `DeliveryDocumentItem`, `SerialNumber` |
| `DeleteSerialNumberFromDeliveryItem` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument`, `DeliveryDocumentItem`, `SerialNumber` |
| `DeleteAllSerialNumbersFromDeliveryItem` | `PickingReport` | 0..n | `A_OutbDeliveryHeaderType` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `DeleteAllHandlingUnitsFromDelivery` | `HuReturn` | 0..1 | `A_OutbDeliveryHeaderType` | `DeliveryDocument` |

Common parameter typing: `DeliveryDocument` `Edm.String` len 10; `DeliveryDocumentItem` `Edm.String` len 6; `Batch` `Edm.String` len 10; quantity params `Edm.Decimal` precision 13 scale 3; UoM params `Edm.String` len 3; `ActualGoodsMovementDate` `Edm.DateTime` precision 7.

## Response complex types — SAP-confirmed

All four are message-carrying envelopes built on the SAP `BAPIRET`-style fields.

- **`PickingReport`** (14 fields) — `SystemMessageIdentification` (20), `SystemMessageNumber` (3), `SystemMessageType` (1), `SystemMessageVariable1..4` (50 each), plus `DeliveryDocument`, `DeliveryDocumentItem`, `Material` (40), `DeliveryDocumentItemText` (40), `Batch`, `ActualDeliveryQuantity`, `DeliveryQuantityUnit`.
- **`Return`** (13 fields) — the same seven message fields plus `DeliveryDocument`, `DeliveryDocumentItem`, `ScheduleLine` (4), `CollectiveProcessing` (10), `CollectiveProcessingMsgCounter` (2), `CollectiveProcessingType` (1).
- **`HuReturn`** (8 fields) — seven message fields plus `DeliveryDocument`.
- **`CreatedDeliveryItem`** (2 fields) — `DeliveryDocument`, `DeliveryDocumentItem`. The only non-message return; this is how a batch-split item id comes back.

`SystemMessageType` is the success/error discriminator (`S`/`E`/`W`/`I`/`A`). A `0..n` return means the caller must handle a **collection** of messages, not a single status.

## Associations and navigation — SAP-confirmed

14 associations, 13 association sets. Navigation properties actually exposed:

- `A_OutbDeliveryHeaderType` → `to_DeliveryDocumentItem` (1:M), `to_DeliveryDocumentPartner` (1:N), `to_DeliveryDocumentText` (1:M), `to_HandlingUnitHeaderDelivery` (1:M)
- `A_OutbDeliveryItemType` → `to_DocumentFlow` (1:M), `to_DeliveryDocumentItemText` (1:M), `to_SerialDeliveryItem`, `to_ValueAddedService` (1:N), `to_HandlingUnitItemDelivery`
- `A_OutbDeliveryPartnerType` → `to_Address`, `to_Address2` (both 1:1)
- `A_HandlingUnitHeaderDeliveryType` → `to_HandlingUnitItemDelivery` (1:N)
- `A_SerialNmbrDeliveryType` → `to_MaintenanceItemObject` (1:N)

`assoc_Item_DocFlow` is the predecessor-document link (`PrecedingDocument` / `PrecedingDocumentItem` / `SubsequentDocumentCategory`) — the read path from a delivery back to its sales order or STO.

## Correction to the prior handover

The earlier note stated the standard API "can create an outbound delivery from a reference document, including a sales order or STO."

**The SEGW model does not support that claim.** Observed instead:

- `A_OutbDeliveryHeaderType` has exactly **one** creatable-annotated property: `ShippingPoint` (String 4).
- `A_OutbDeliveryItemType` creatable-annotated properties are only `ActualDeliveryQuantity`, `DeliveryDocument`, `DeliveryQuantityUnit`.
- The item carries `OrderID` and `OrderItem` (both `Edm.String`), but **neither is annotated creatable**. There is no `ReferenceSDDocument` property in the model at all.
- `A_OutbDeliveryItem` as an entity set is **not** annotated creatable.

Two readings are possible and SEGW cannot distinguish them: either creation is intended as a **deep create** on the header with items supplied through `to_DeliveryDocumentItem` and reference fields accepted by the DPC despite the annotation, or reference-based creation is not offered by this service. Annotations are metadata hints, not runtime enforcement — the DPC_EXT decides. **Treat delivery-creation-from-reference as unproven until the runtime is checked.** Everything else above stands on the extracted model.

## CNF fit

Covered by this service, at design-time confidence:

- Read delivery header/item/partner/address/text/document-flow, with `$expand` over the navigation properties above.
- Update header logistics fields (dates, times, weights/volumes, incoterms, means of transport, route, bill of lading) and item quantities/batch/weights.
- The full picking chain: pick all / pick one / pick with base or sales quantity / set picking quantity / confirm picking / batch split.
- **PGI and GI reversal** — `PostGoodsIssue`, `ReverseGoodsIssue`.
- Serial-number and handling-unit maintenance on a delivery.

Not covered — needs separate discovery or a custom gap:

- Shipment creation and shipment cost
- Billing / invoice, e-invoice, e-way bill
- Destination goods receipt
- STO purchase-order creation
- Delivery creation from a sales order or STO (see the correction above)

## Gaps — what would make this a runtime contract

Ranked by how much they change client code. All are read-only moves.

1. **`$metadata` from the live service.** `MPC_EXT` can redefine annotations at runtime, so the creatable/updatable flags above are the base model, not necessarily what the service publishes. This also yields the namespace and the exact function-import URI form.
2. **`CL_API_OUTBOUND_DELIVE_DPC_EXT` method list** (SE24, display). This is the only way to establish which CRUD operations are genuinely implemented and how deep create is handled — it settles the correction above.
3. **Service root URL and registration.** Held in Service Maintenance / `/IWFND/MAINT_SERVICE`, excluded from this pass by scope. Without it there is no callable endpoint path.
4. **Error payload, ETag/concurrency and `$batch` support.** None are visible in SEGW.

Until 1–3 are closed, treat every statement above as *design-time model, SAP-confirmed* — accurate about what the project contains, silent about what the endpoint does.

## Evidence index

| File | Contents |
|---|---|
| `SEGW_TREE.tsv` | All 823 nodes, with key/parent/depth/path |
| `GRID_MANIFEST.tsv` | The 52 exported grids with row/column counts |
| `grids/Data_Model__Entity_Sets.tsv` | CRUD annotation matrix |
| `grids/Data_Model__Function_Imports.tsv` | HTTP method, return type, cardinality, bound entity type |
| `grids/Data_Model__Function_Imports__*__Function_Import_Parameters.tsv` | Per-FI parameter types |
| `grids/Data_Model__Entity_Types__*__Properties.tsv` | Per-entity-type field lists with key/type/length/flags |
| `grids/Data_Model__Complex_Types__*__Properties.tsv` | Response envelope shapes |
| `grids/Data_Model__Associations.tsv` | Associations with cardinalities |
| `grids/Runtime_Artifacts.tsv` | Runtime classes and TADIR entries |

## Scripts

In `tmp/`, all selecting the newest connection that exposes a session — never a hardcoded index:

| Script | Purpose |
|---|---|
| `sap_probe.vbs` | List connections/sessions |
| `sap_segw_state.vbs` | Window list, status bar, working-area control tree |
| `sap_segw_export_project.vbs` | Scoped recursive tree expansion + TSV export |
| `sap_segw_export_all_grids.vbs` | Selects every container node and exports its ALV grid |
| `sap_segw_dump_node_grid.vbs` | One node, one grid, ad-hoc |

Both SEGW exporters hard-refuse any path containing `Service Maintenance`.
