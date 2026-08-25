# SEGW delta: `API_OUTBOUND_DELIVERY` vs `API_OUTBOUND_DELIVERY_0002`

**Scope:** read-only QS4/700 SEGW design-time evidence. This report does not prove Gateway registration, activation, authorization, or runtime behavior.

## Catalogue identity

| Project | Description | Last changed |
|---|---|---:|
| `API_OUTBOUND_DELIVERY` | Remote API for Outbound Delivery | 17.05.2018 |
| `API_OUTBOUND_DELIVERY_0002` | Remote API for Outbound Delivery | 19.05.2022 |

## Model-surface delta

| Surface | Base | `_0002` | Delta |
|---|---:|---:|---:|
| Entity types | 7 | 13 | +6 |
| Complex types | 2 | 4 | +2 |
| Associations | 6 | 14 | +8 |
| Entity sets | 7 | 13 | +6 |
| Association sets | 6 | 13 | +7 |
| Function imports | 6 | 15 | +9 |
| Runtime artifacts | 6 | 6 | 0 |

New entity types in `_0002`: `A_HandlingUnitHeaderDeliveryType`, `A_HandlingUnitItemDeliveryType`, `A_OutbDeliveryAddress2Type`, `A_OutbDeliveryHeaderTextType`, `A_OutbDeliveryItemTextType`, `A_OutbDeliveryValAddedSrvcType`.

New complex types in `_0002`: `CreatedDeliveryItem`, `HuReturn`.

New entity sets in `_0002`: `A_HandlingUnitHeaderDelivery`, `A_HandlingUnitItemDelivery`, `A_OutbDeliveryAddress2`, `A_OutbDeliveryHeaderText`, `A_OutbDeliveryItemText`, `A_OutbDeliveryValAddedSrvc`.

## Operation delta

The six base function imports are retained. Nine are added in `_0002`: `AddSerialNumberToDeliveryItem`, `CreateBatchSplitItem`, `DeleteAllHandlingUnitsFromDelivery`, `DeleteAllSerialNumbersFromDeliveryItem`, `DeleteSerialNumberFromDeliveryItem`, `PickAndBatchSplitOneItem`, `PickOneItemWithBaseQuantity`, `PickOneItemWithSalesQuantity`, `SetPickingQuantityWithBaseQuantity`.

| Shared function import | Base parameters | `_0002` parameters | Name delta |
|---|---:|---:|---|
| `ConfirmPickingAllItems` | 1 | 1 | None |
| `ConfirmPickingOneItem` | 2 | 2 | None |
| `PickAllItems` | 1 | 1 | None |
| `PickOneItem` | 2 | 2 | None |
| `PostGoodsIssue` | 1 | 1 | None |
| `ReverseGoodsIssue` | 2 | 2 | None |

## Shared entity property delta

| Entity type | Base props | `_0002` props | Added | Removed | Contract-changed common props |
|---|---:|---:|---|---|---|
| `A_MaintenanceItemObjectType` | 9 | 9 | None | None | `FunctionalLocation`, `MaintenanceItemObjectList` |
| `A_OutbDeliveryAddressType` | 48 | 48 | None | None | `POBox`, `POBoxDeviatingCountry` |
| `A_OutbDeliveryDocFlowType` | 10 | 10 | None | None | None |
| `A_OutbDeliveryHeaderType` | 108 | 108 | None | None | `ActualDeliveryRoute`, `ActualGoodsMovementDate`, `ActualGoodsMovementTime`, `BillingDocumentDate`, `BillOfLading`, `CompleteDeliveryIsDefined`, `ConfirmationTime`, `CreatedByUser`, `CreationDate`, `CreationTime`, `CustomerGroup`, `DeliveryBlockReason`, `DeliveryDate`, `DeliveryDocument`, `DeliveryDocumentBySupplier`, `DeliveryDocumentType`, `DeliveryIsInPlant`, `DeliveryPriority`, `DeliveryTime`, `DeliveryVersion`, `DepreciationPercentage`, `DistrStatusByDecentralizedWrhs`, `DocumentDate`, `ExternalIdentificationType`, `ExternalTransportSystem`, `FactoryCalendarByCustomer`, `GoodsIssueOrReceiptSlipNumber`, `GoodsIssueTime`, `HandlingUnitInStock`, `HdrGeneralIncompletionStatus`, `HdrGoodsMvtIncompletionStatus`, `HeaderBillgIncompletionStatus`, `HeaderBillingBlockReason`, `HeaderDelivIncompletionStatus`, `HeaderGrossWeight`, `HeaderNetWeight`, `HeaderPackingIncompletionSts`, `HeaderPickgIncompletionStatus`, `HeaderVolume`, `HeaderVolumeUnit`, `HeaderWeightUnit`, `IncotermsClassification`, `IncotermsTransferLocation`, `IntercompanyBillingDate`, `InternalFinancialDocument`, `IsDeliveryForSingleWarehouse`, `IsExportDelivery`, `LastChangeDate`, `LastChangedByUser`, `LoadingDate`, `LoadingPoint`, `LoadingTime`, `MeansOfTransport`, `MeansOfTransportRefMaterial`, `MeansOfTransportType`, `OrderCombinationIsAllowed`, `OrderID`, `OverallDelivConfStatus`, `OverallDelivReltdBillgStatus`, `OverallGoodsMovementStatus`, `OverallIntcoBillingStatus`, `OverallPackingStatus`, `OverallPickingConfStatus`, `OverallPickingStatus`, `OverallProofOfDeliveryStatus`, `OverallSDProcessStatus`, `OverallWarehouseActivityStatus`, `OvrlItmDelivIncompletionSts`, `OvrlItmGdsMvtIncompletionSts`, `OvrlItmGeneralIncompletionSts`, `OvrlItmPackingIncompletionSts`, `OvrlItmPickingIncompletionSts`, `PaymentGuaranteeProcedure`, `PickedItemsLocation`, `PickingDate`, `PickingTime`, `PlannedGoodsIssueDate`, `ProofOfDeliveryDate`, `ProposedDeliveryRoute`, `Receivinglocationtimezone`, `ReceivingPlant`, `RouteSchedule`, `SalesDistrict`, `SalesOffice`, `SalesOrganization`, `SDDocumentCategory`, `ShipmentBlockReason`, `ShippingCondition`, `Shippinglocationtimezone`, `ShippingPoint`, `ShippingType`, `ShipToParty`, `SoldToParty`, `SpecialProcessingCode`, `StatisticsCurrency`, `Supplier`, `TotalBlockStatus`, `TotalCreditCheckStatus`, `TotalNumberOfPackage`, `TransactionCurrency`, `TransportationGroup`, `TransportationPlanningDate`, `TransportationPlanningStatus`, `TransportationPlanningTime`, `UnloadingPointName`, `Warehouse`, `WarehouseGate`, `WarehouseStagingArea` |
| `A_OutbDeliveryItemType` | 133 | 144 | `EUDeliveryItemARCStatus`, `HigherLvlItmOfBatSpltItm`, `ProductCharacteristic1`, `ProductCharacteristic2`, `ProductCharacteristic3`, `ProductCollection`, `ProductSeason`, `ProductSeasonYear`, `ProductTheme`, `RequirementSegment`, `StockSegment` | None | `ActualDeliveredQtyInBaseUnit`, `ActualDeliveryQuantity`, `AdditionalCustomerGroup1`, `AdditionalCustomerGroup2`, `AdditionalCustomerGroup3`, `AdditionalCustomerGroup4`, `AdditionalCustomerGroup5`, `AdditionalMaterialGroup1`, `AdditionalMaterialGroup2`, `AdditionalMaterialGroup3`, `AdditionalMaterialGroup4`, `AdditionalMaterialGroup5`, `AlternateProductNumber`, `BaseUnit`, `Batch`, `BatchBySupplier`, `BatchClassification`, `BOMExplosion`, `BusinessArea`, `ConsumptionPosting`, `ControllingArea`, `CostCenter`, `CreatedByUser`, `CreationDate`, `CreationTime`, `CustEngineeringChgStatus`, `DeliveryDocument`, `DeliveryDocumentItem`, `DeliveryDocumentItemCategory`, `DeliveryDocumentItemText`, `DeliveryGroup`, `DeliveryQuantityUnit`, `DeliveryRelatedBillingStatus`, `DeliveryToBaseQuantityDnmntr`, `DeliveryToBaseQuantityNmrtr`, `DeliveryVersion`, `DepartmentClassificationByCust`, `DistributionChannel`, `Division`, `FixedShipgProcgDurationInDays`, `GLAccount`, `GoodsMovementReasonCode`, `GoodsMovementStatus`, `GoodsMovementType`, `HigherLevelItem`, `InspectionLot`, `InspectionPartialLot`, `IntercompanyBillingStatus`, `InternationalArticleNumber`, `InventorySpecialStockType`, `InventoryValuationType`, `IsCompletelyDelivered`, `IsNotGoodsMovementsRelevant`, `IsSeparateValuation`, `IssgOrRcvgBatch`, `IssgOrRcvgMaterial`, `IssgOrRcvgSpclStockInd`, `IssgOrRcvgStockCategory`, `IssgOrRcvgValuationType`, `IssuingOrReceivingPlant`, `IssuingOrReceivingStorageLoc`, `ItemBillingBlockReason`, `ItemBillingIncompletionStatus`, `ItemDeliveryIncompletionStatus`, `ItemGdsMvtIncompletionSts`, `ItemGeneralIncompletionStatus`, `ItemGrossWeight`, `ItemIsBillingRelevant`, `ItemNetWeight`, `ItemPackingIncompletionStatus`, `ItemPickingIncompletionStatus`, `ItemVolume`, `ItemVolumeUnit`, `ItemWeightUnit`, `LastChangeDate`, `LoadingGroup`, `ManufactureDate`, `Material`, `MaterialByCustomer`, `MaterialFreightGroup`, `MaterialGroup`, `MaterialIsBatchManaged`, `MaterialIsIntBatchManaged`, `NumberOfSerialNumbers`, `OrderID`, `OrderItem`, `OriginalDeliveryQuantity`, `OriginallyRequestedMaterial`, `OverdelivTolrtdLmtRatioInPct`, `PackingStatus`, `PartialDeliveryIsAllowed`, `PaymentGuaranteeForm`, `PickingConfirmationStatus`, `PickingControl`, `PickingStatus`, `Plant`, `PrimaryPostingSwitch`, `ProductAvailabilityDate`, `ProductAvailabilityTime`, `ProductConfiguration`, `ProductHierarchyNode`, `ProfitabilitySegment`, `ProfitCenter`, `ProofOfDeliveryRelevanceCode`, `ProofOfDeliveryStatus`, `QuantityIsFixed`, `ReceivingPoint`, `ReferenceDocumentLogicalSystem`, `ReferenceSDDocument`, `ReferenceSDDocumentCategory`, `ReferenceSDDocumentItem`, `RetailPromotion`, `SalesDocumentItemType`, `SalesGroup`, `SalesOffice`, `SDDocumentCategory`, `SDProcessStatus`, `ShelfLifeExpirationDate`, `StatisticsDate`, `StockType`, `StorageBin`, `StorageLocation`, `StorageType`, `SubsequentMovementType`, `TransportationGroup`, `UnderdelivTolrtdLmtRatioInPct`, `UnlimitedOverdeliveryIsAllowed`, `VarblShipgProcgDurationInDays`, `Warehouse`, `WarehouseActivityStatus`, `WarehouseStagingArea`, `WarehouseStockCategory`, `WarehouseStorageBin` |
| `A_OutbDeliveryPartnerType` | 8 | 10 | `BusinessPartnerAddressUUID`, `RefBusinessPartnerAddressUUID` | None | None |
| `A_SerialNmbrDeliveryType` | 5 | 5 | None | None | `DeliveryDate`, `MaintenanceItemObjectList` |

## Runtime-artifact identity

| Artifact type | Base object | `_0002` object |
|---|---|---|
| Data Provider Base Class | `CL_API_OUTBOUND_DEL_02_DPC` | `CL_API_OUTBOUND_DELIVE_DPC` |
| Data Provider Extension Class | `CL_API_OUTBOUND_DEL_02_DPC_EXT` | `CL_API_OUTBOUND_DELIVE_DPC_EXT` |
| Model Provider Base Class | `CL_API_OUTBOUND_DEL_02_MPC` | `CL_API_OUTBOUND_DELIVE_MPC` |
| Model Provider Extension Class | `CL_API_OUTBOUND_DEL_02_MPC_EXT` | `CL_API_OUTBOUND_DELIVE_MPC_EXT` |
| Registered Model | `API_OUTBOUND_DELIVERY_MDL` | `API_OUTBOUND_DELIVERY_MDL` |
| Registered Service | `API_OUTBOUND_DELIVERY_SRV` | `API_OUTBOUND_DELIVERY_SRV` |

## Evidence-based interpretation

- `_0002` is the later and materially broader design-time generation. It retains the base picking, PGI, and reversal operations and adds explicit-quantity picking, batch split, serial-number, and handling-unit capabilities.
- Both projects expose the same registered model/service object names (`API_OUTBOUND_DELIVERY_MDL` and `API_OUTBOUND_DELIVERY_SRV`) while pointing to different generated class families. The project suffix therefore cannot be treated as a separate external service name.
- For CNF, `_0002` is the stronger design-time candidate when batch, serial, handling-unit, or unit-specific picking behavior is required. If the process only needs basic picking/PGI/reversal, the extra surface is not itself justification.
- Final selection still requires official SAP release/version mapping plus QS4 Gateway registration/activation evidence. SEGW metadata alone does not prove that either generation is callable.

---

## Addendum 2026-08-15 — runtime version mapping resolved

Added while researching the inbound family. No re-extraction was performed; this is new `SAP-OFFICIAL` and `LOCAL-RUNTIME` evidence layered onto the existing design-time report.

**The `;v=n` selector is the answer to the version question.** SAP's S/4HANA on-premise **2022** documentation addresses every outbound operation at:

```text
/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/
```

(One sample URL on that page reads `;v=0002`; the surrounding twenty-plus samples read `;v=2`. Treat `;v=0002` as a documentation typo, not a second selector form.)

So the conclusion above — that the project suffix is not a separate external service name — was right, and this completes it:

| Layer | Value |
|---|---|
| SEGW project | `API_OUTBOUND_DELIVERY_0002` |
| Generated service object | `API_OUTBOUND_DELIVERY_SRV` |
| External runtime path | `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/` |
| SAP API Hub identity | `API_OUTBOUND_DELIVERY_SRV_0002` |

The 2022 documentation's entity list — handling unit headers and items, header and item texts, `A_OutbDeliveryAddress2`, value-added services — is the **`_0002`** model surface, not the base one. `INFERENCE`: `;v=2` is the release-relevant generation for QS4 and the base project is the superseded `;v=1`.

`LOCAL-RUNTIME` corroboration: the normalised 522-row QS4 Gateway catalogue carries `externalServiceName` and `version` as separate columns, and four services are already registered at `version = 2`. Any Basis activation request for this family must name the service **and** the version.

**Documented constraints for `;v=2`** (`SAP-OFFICIAL`), all of which land on CPI/T2:

- Create is supported with reference to a sales order, a **stock transport order**, or a returns purchase order — relevant to API-02 for both the Trade/Non-trade and STO journeys.
- Only `A_OutbDeliveryHeaderType`, `A_OutbDeliveryItemType`, `A_OutbDeliveryAddress2` and (single-entity GET only) `A_OutbDeliveryDocFlowType`, `A_OutbDeliveryHeaderTextType`, `A_OutbDeliveryItemTextType` are directly addressable.
- Multiple delivery documents cannot be updated in one changeset.
- Roles `S_SERVICE`, `F_LFA1_BEK`, `V_LIKP_VST` are required.

**Separate lead for API-02.** The registered-services catalogue contains two relevant entries that are *not* SEGW `API_*` projects and were therefore invisible to the name-based reduction:

| External service | Description | Registered |
|---|---|---|
| `LE_SHP_OD_CREATE_SRV` | Create Outbound Delivery | yes, version 1 |
| `LE_SHP_QC_DLVREF_SRV` | Quick Create: Delivery with ref. | yes, version 1 |

`API_OUTBOUND_DELIVERY_SRV` is **not** registered; these two are. Before requesting activation of the A2X service for API-02, establish what these already-registered services do and whether they are the client's existing delivery-creation path. This does not change the outbound delta; it changes what to check first.
