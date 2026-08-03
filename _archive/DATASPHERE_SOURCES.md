# Datasphere Sources

## Purpose

Track Datasphere objects that may supply analytical or consolidated data to CPI/Commerce. This register does not imply ABAP ownership of Datasphere.

## Discovery register

| ID | Business concept | Space/object | Type | Upstream source | Grain/key | Refresh/latency | Consumer | Owner | Confidence |
|---|---|---|---|---|---|---|---|---|---|
| DS-001 | Inventory ageing | TBD | View/model TBD | S/4 source TBD | Material/plant/sloc/batch? | TBD | Dashboard | Datasphere team | Hypothesis |
| DS-002 | Historical billing | TBD | View/model TBD | Billing source TBD | Invoice/item? | TBD | Reports | Datasphere team | Hypothesis |
| DS-003 | STO in transit | TBD | View/model TBD | STO/delivery flow TBD | STO/item? | TBD | Dashboard | Datasphere team | Hypothesis |
| DS-004 | Depot/warehouse stock | TBD | View/model TBD | Stock source TBD | Material/location? | TBD | Dashboard | Datasphere team | Hypothesis |
| DS-005 | Vehicle/transporter | TBD | View/model TBD | S/4/custom/Commerce TBD | TBD | TBD | Reports | TBD | Hypothesis |
| DS-006 | MRN/MIGO history | TBD | View/model TBD | Material documents TBD | Document/item? | TBD | Reports | Datasphere team | Hypothesis |
| DS-007 | Pending-order/dashboard totals | TBD | View/model TBD | Sales orders/status TBD | Order/item or aggregate? | TBD | Dashboard | Datasphere team | Hypothesis |
| DS-008 | Document-flow history | TBD | View/model TBD | Delivery/shipment/billing TBD | DI/document? | TBD | Reports | Datasphere team | Hypothesis |

## Questions for every Datasphere object

- Business definition and intended consumer?
- Space, object name, and object type?
- Source connection and exact lineage?
- Row grain and business key?
- Transformations, calculated fields, and filters?
- Current-data latency and expected SLA?
- Delta/replication behavior and last successful load?
- Reversal/deletion/update handling?
- Security and analytic privileges?
- Supported exposure mechanism to CPI?
- Data-quality owner and reconciliation method?

## Source selection rule

Use S/4 for current transactional decisions and document creation. Use Datasphere for analytical, historical, consolidated, or expensive pre-modeled reads when its latency is acceptable and the architecture approves direct consumption.

When the same field exists in both:

| Attribute | S/4 interpretation | Datasphere interpretation | Decision |
|---|---|---|---|
| Delivery status | Current transactional state | Replicated/calculated state | S/4 for commands |
| Stock | Current SAP stock semantic | Snapshot/aggregate | Depends on freshness and use |
| Ageing bucket | Usually derived | Analytical calculation | Datasphere likely |
| Billing history | Source documents | Modeled historical view | Datasphere likely for reports |

## Reconciliation

For any interface combining S/4 and Datasphere, define:

- canonical key format;
- expected latency window;
- record-count/amount/quantity checks;
- reversal behavior;
- response when sources disagree;
- owner of correction.

Meeting-derived caution: the walkthrough mentioned a possible 60-day Commerce retention and described reports as historical. This does not prove that Datasphere is the source. Verify retention, freshness, and consumption architecture before assigning those reads.
