# CNF API/BAPI runtime certification — DS4 client 200

## Executive result

Activation and technical reachability are proven for all seven requested OData services: every `$metadata` request returned HTTP 200. `API_OUTBOUND_DELIVERY_SRV` is the required version 2 runtime path and exposes the batch-split operations.

Business behavior is **not yet certified end to end** because DS4/200 does not contain the QS4 reference chain or equivalent CNF data/configuration. The safe reads returned empty datasets, and the QS4-derived ATP test correctly failed master-data validation in DEV.

## OData status

| Service | Version/path | Runtime result | Business-data result |
|---|---|---|---|
| `API_MATERIAL_DOCUMENT_SRV` | v1 | `$metadata` HTTP 200 | Create is gated; no approved DEV receipt data/code. |
| `API_OUTBOUND_DELIVERY_SRV` | **v2** `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/` | `$metadata` HTTP 200; batch-split imports present | No approved open DEV predecessor/delivery. |
| `API_BILLING_DOCUMENT_SRV` | v1 | `$metadata` HTTP 200 | No comparable DEV invoice. |
| `API_PURCHASEORDER_PROCESS_SRV` | v1 | `$metadata` HTTP 200 | No ZP06 CNF population found in DS4/200. |
| `API_MATERIAL_STOCK_SRV` | v1 | `$metadata` HTTP 200 | Read executed; empty result. |
| `MMIM_MATDOC_SRV` | v1 | `$metadata` HTTP 200 | Registered companion is reachable. |
| `SD_CUSTOMER_INVOICES_CREATE` | v1 | `$metadata` HTTP 200 | Application-internal create route; architecture approval still required. |

An HTTP 200 with an empty collection proves routing and request authorization for that call, but it does not prove row-level authorization or business suitability.

## Corrections to workbook v1.8 assumptions

- Runtime is no longer unproven in DS4/200: all seven service metadata endpoints are live.
- The delivery service must remain version 2.
- `PickAndBatchSplitOneItem` has five parameters, including `SplitQuantityUnit`.
- `CreateBatchSplitItem` has six parameters, including `PickQuantityInSalesUOM`.
- Delivery operational function imports are POSTs; billing `GetPDF` is GET.
- Purchase-order runtime navigation is `to_PurchaseOrderItem` then `to_ScheduleLine`.
- `BAPI_SHIPMENT_COST_ESTIMATE` exists and is remote-enabled, but is **not released**. Its exact live interface is captured; suitability remains unproven until configured freight data exists.

## Next controlled execution gate

Once functional supplies the DEV data listed in `BAPI_TEST_RUNBOOK.md`, run the simulation-capable BAPIs first. Then approve one disposable DEV document chain for OData/BAPI writes, with document numbers recorded after every commit. Do not move local `$TMP` service activation as a transport; repeat/transport registration separately in the target system according to Basis policy.
