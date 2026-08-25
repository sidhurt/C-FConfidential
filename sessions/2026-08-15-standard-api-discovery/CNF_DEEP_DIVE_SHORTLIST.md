# CNF standard SEGW candidate shortlist

**System evidence:** QS4 / client 700, 2,626-project SEGW catalogue.  
**Demand evidence:** CNF API Request/Response Specification v1.7.  
**Selection rule:** prefer SAP-created `API_*` integration projects whose business object and operations can satisfy a v1.7 process. Similar-name variants remain together until their design-time and released-version delta is resolved.

This is a shortlist of **SEGW projects**, not a one-to-one replacement list for the v1.7 business APIs. A multi-stage business journey can require several SAP services, while one SAP service can support several v1.7 operations.

## Tier A — deep-dive set

| Order | SEGW project | Last changed | v1.7 process fit | Why it survives | Main question for deep inspection |
|---:|---|---:|---|---|---|
| 1 | `API_OUTBOUND_DELIVERY_0002` | 19.05.2022 | API-02 Create DI; API-03 picking/batch/PGI; API-09 STO Deliveries; API-12 Update DI Quantity | Direct delivery object; later sibling; already proves PGI/reversal, batch split, serial and quantity-specific picking operations | Confirm create-from-sales-order/STO behavior and runtime version/registration |
| 2 | `API_OUTBOUND_DELIVERY` | 17.05.2018 | Same family as above | Required sibling baseline; full delta is complete | Treat as legacy unless release compatibility or a narrower requirement justifies it |
| 3 | `API_INBOUND_DELIVERY_0002` | 05.04.2022 | API-01 Submit MIGO / receiving-side processing | Later inbound-delivery sibling; official family includes goods receipt/reversal and putaway operations | Determine whether CNF posts against an SAP inbound delivery and whether storage-location allocations are supported |
| 4 | `API_INBOUND_DELIVERY` | 29.01.2021 | Same receiving family | Required baseline for the inbound `_0002` delta | Identify operations and model elements added or changed in `_0002` |
| 5 | `API_MATERIAL_DOCUMENT` | 24.02.2022 | API-01 Submit MIGO; PGI/GR material-document reads | Closest standard SAP object to MIGO; supports material-document create/read/cancel | Validate goods-movement reference, multiple storage-location allocations, movement types and returned document/year |
| 6 | `API_MATERIAL_STOCK` | 03.05.2017 | API-05 Stock Availability; batch/FIFO input | Reads stock quantity by plant, storage location, batch, stock type and special-stock dimensions | Confirm required batch age/FIFO fields, paging and performance at depot scope |
| 7 | `API_PRODUCT_AVAILY_INFO_BASIC` | 14.03.2017 | API-05 availability alternative | SAP ATP calculation can answer available quantity/date, which is different from raw on-hand stock | Decide whether the portal requires ATP or physical SLoc/batch stock; do not combine the meanings |
| 8 | `API_PURCHASEORDER_PROCESS` | 04.08.2021 | API-08 STO Orders; API-11 Create STO Purchase Order | Direct PO create/read/update service and the strongest SEGW name for STO purchase orders | Confirm client STO document type/item category and whether the local V2 service supports the needed create/read surface |
| 9 | `API_BILLING_DOCUMENT` | 19.02.2020 | API-03 billing result; API-07 cancellation/correction; API-10 STO Invoice read | Direct SD billing-document service; official V2 surface supports read/cancel/PDF | Establish the real STO invoice object and separate billing creation from read/cancel operations |
| 10 | `API_SALES_ORDER` | 24.05.2022 | Trade/Non-trade predecessor selection for API-02 Create DI | Direct sales-order source and document relationship for non-STO flows | Confirm filters, open-quantity fields and delivery/document-flow navigation needed by the portal |

## Tier B — targeted conditional inspections

| Order | SEGW project | Last changed | Keep only if | Current assessment |
|---:|---|---:|---|---|
| 11 | `API_BILLING_DOCUMENT_REQUEST` | 08.03.2018 | CNF genuinely uses SD billing document requests as a business object | Similar name but not an invoice-creation substitute; official V2 purpose is read/reject/delete billing document requests |
| 12 | `API_PHYSICAL_INVENTORY_DOC` | 20.05.2021 | Goods reconciliation includes physical inventory documents, counts, recounts or posting differences | Strong reconciliation API, but broader than v1.7's current read-only Stock Availability scope |
| 13 | `API_SUPPLIERINVOICE_PROCESS` | 10.03.2022 | API-10's “STO Invoice” is confirmed as an MM supplier invoice | Strong service for supplier-invoice create/read/release/reverse; wrong object if the requirement is SD billing/GST stock-transfer billing |
| 14 | `API_CREDIT_MEMO_REQUEST` | 03.08.2020 | Finance confirms invoice correction is represented by an SD credit memo request | Not justified by the current vehicle/transporter/e-document correction fields alone |
| 15 | `API_DEBIT_MEMO_REQUEST` | 23.02.2022 | Finance confirms invoice correction is represented by an SD debit memo request | Same gate as the credit-memo candidate; do not inspect deeply before the document model is confirmed |

## Explicitly rejected name matches

| Project/name family | Reason for rejection |
|---|---|
| `API_PRODUCT_ALLOC_SEQUENCE`, `API_PRODUCT_ALLOCATION_OBJECT` | Product-allocation configuration is not depot stock, batch/FIFO allocation, or physical inventory reconciliation |
| `API_CUSTOMER_RETURNS_DELIVERY`, `API_CUSTOMER_RETURNS_DLV_0002` | The approved CNF flow is not a customer-returns process |
| `API_DEL_DOC_WITH_CREDIT_BLOCK` | A credit-block worklist is not general outbound-delivery processing |
| `API_SUBSQNT_BILLG_DOC_SBI` | Self-billing-specific display service; no CNF self-billing requirement is established |
| `API_CN_VAT_INVOICE`, `API_JVA_BILLING` | Country/module-specific services unrelated to India CNF billing |
| `FDP_GST_INV_GLO_IN` | India GST **form data provider**, not an A2X e-Invoice/E-Way business API |
| `EDOC_DCC` | Document Compliance Cockpit service; plausible diagnostic probe, but its name/description indicate UI/cockpit support rather than an external extension command |
| `/SCMTMS/FO_CONFIRMATION`, `/SCMTMS/FRT_PROCUREMENT`, `TM_FRT_CALCERROR` | TM-specific confirmation/procurement/error services; none is identified as a general shipment-cost calculation API |

## Gaps that SEGW cannot close by name

1. **E-Way Bill extension / e-Invoice regeneration:** no credible `API_*` SEGW project exists in the 2,626-row catalogue. `EDOC_DCC` and India GST form providers are not valid substitutes. Investigate SAP Document and Reporting Compliance, eDocument interfaces, and the configured GSP/provider integration.
2. **Billing-document creation:** the local SEGW project `API_BILLING_DOCUMENT` is the OData V2 read/cancel API. Current SAP documentation also exposes a newer OData V4 `API_BILLINGDOCUMENT` service with creation from an SD document; OData V4 service bindings do not appear as SEGW projects. QS4/S/4HANA 2022 applicability must be checked separately.
3. **Shipment/freight cost:** no released `API_*` SEGW candidate is evident by name. Confirm whether the client uses classic LE shipment cost, Transportation Management, or a BAPI-backed operation before selecting a service.
4. **Purchase Order generation:** `API_PURCHASEORDER_PROCESS` is the locally visible OData V2 candidate, but SAP now documents a V4 successor in releases where both exist. Local release compatibility must be checked outside SEGW.

## Recommended execution order

1. Complete `API_INBOUND_DELIVERY` versus `_0002`.
2. Extract `API_MATERIAL_DOCUMENT`.
3. Compare `API_MATERIAL_STOCK`, `API_PRODUCT_AVAILY_INFO_BASIC`, and `API_PHYSICAL_INVENTORY_DOC` against the exact API-05/reconciliation meaning.
4. Extract `API_PURCHASEORDER_PROCESS` and verify STO create/read capability.
5. Extract `API_BILLING_DOCUMENT`, then perform only shallow rejection checks on `API_BILLING_DOCUMENT_REQUEST` and `API_SUPPLIERINVOICE_PROCESS` until the STO invoice object is confirmed.
6. Extract `API_SALES_ORDER` for the Trade/Non-trade predecessor read.
7. Inspect credit/debit memo request services only after Finance confirms that document model.
