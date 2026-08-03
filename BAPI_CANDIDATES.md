# BAPI and SAP API Candidates

These are candidates, not approved implementation choices. Validate actual release signatures, business semantics, customizing, enhancement behavior, and released alternatives.

## Highest-probability candidates

| Domain | Candidate | Possible use | Must validate |
|---|---|---|---|
| Goods movement | `BAPI_GOODSMVT_CREATE` | Post GR/MIGO | GM code, movement type, reference document, batches, quantities |
| Goods movement | `BAPI_GOODSMVT_CANCEL` | Reversal when formally approved | Reversal policy and workflow |
| Transaction | `BAPI_TRANSACTION_COMMIT` | Commit successful BAPI work | Commit owner; wait behavior |
| Transaction | `BAPI_TRANSACTION_ROLLBACK` | Roll back failed unit of work | No partial persistence |
| Sales delivery | `BAPI_OUTB_DELIVERY_CREATE_SLS` | Delivery from sales order | Confirm source document and open schedule lines |
| STO delivery | `BAPI_OUTB_DELIVERY_CREATE_STO` | Delivery from STO | Confirm STO flow; do not use for SO by assumption |
| Delivery change | `BAPI_OUTB_DELIVERY_CHANGE` | Change permitted delivery fields | Status limits, extension fields, PGI cutoff |
| Availability | `BAPI_MATERIAL_AVAILABILITY` | ATP | Whether business means ATP |
| Stock/requirements | `BAPI_MATERIAL_STOCK_REQ_LIST` | Stock/requirements view | Whether output matches portal need |
| Billing | `BAPI_BILLINGDOC_CANCEL1` | Billing cancellation | Approval, accounting and reversal chain |
| Billing | `BAPI_BILLINGDOC_CREATEMULTIPLE` | Billing creation | Predecessor and billing due-list semantics |
| Sales document | `BAPI_SALESORDER_CREATEFROMDAT2` | Credit/debit memo request or order | SD process and document type |
| Sales document | `BAPI_SALESORDER_CHANGE` | Change supported sales document | Allowed changes/status |
| Purchase/STO | `BAPI_PO_GETDETAIL1` | Read PO/STO details | Whether PO/STO is authoritative predecessor |
| Purchase/STO | `BAPI_PO_CREATE1` / `BAPI_PO_CHANGE` | Only if assigned | Workflow and functional authorization |
| Material | `BAPI_MATERIAL_GET_DETAIL` | Material detail | Prefer released CDS/API where better |
| Shipment | `BAPI_SHIPMENT_CREATE` / `CHANGE` / `GETDETAIL` | Classic LE-TRA shipment | Actual transport solution and release |
| Batch | `BAPI_BATCH_GET_DETAIL` | Batch attributes | Classification and FIFO rules |
| Classification | `BAPI_OBJCL_GETDETAIL` | Material/batch characteristics | Object/class types |

## Likely query sources instead of BAPIs

- Released CDS views or standard OData APIs.
- Sales order, delivery, billing, material document, purchase/STO, batch, and shipment document-flow entities.
- Custom CDS/query classes for joined status lists.
- Datasphere-native models for historical or aggregated data.

Avoid direct table access when a released semantic source exists. If direct access is required, document rationale, authorization, performance, and compatibility.

## Validation checklist

For each candidate:

1. What exact business event is being executed?
2. Is the BAPI released and suitable for this system release?
3. Does a newer released API exist?
4. What predecessor document and item keys are mandatory?
5. Which configuration and enhancements affect it?
6. What is returned in `BAPIRET2`?
7. Who owns commit/rollback?
8. Can a timeout cause duplicate creation?
9. How is the external request ID persisted?
10. What authorization checks execute?
11. How are extension/custom fields supplied?
12. What test proves parity with the approved SAP GUI process?

## Design rule

`DPC_EXT` exposes the protocol; an application class owns the use case; a wrapper isolates the BAPI/released API. Do not embed an entire business process in a generated Gateway method.

