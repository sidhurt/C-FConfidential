# Completed MRN field-mapping review

**Date:** 2026-09-10  
**Source:** `SRC-DOC-20260910-01_CNF_T2_Field_Mapping_T1_v1.2.xlsx`, sheet `completed MRN`, rows 1–36  
**Method:** opened read-only with LibreOffice Calc through its UNO interface; workbook was not edited

## What the sheet establishes

**Documented / controlled-client evidence, not runtime proof.**

- The sheet defines 35 attributes for a Completed-MRN-oriented Commerce projection.
- The primary Datasphere source named by the architect is `VW_CDS_MATDOC_MATERIALDOCUMENT`; 23 rows reference that view.
- Supplementary data comes from `ZLETILMSDELIVERY_LOCAL_DW`, `VW_CDS_ZLETILMSTOKEN_Token_Creation`, `ZMMT_MIGO_HDR_CD`, Commerce `Warehouse`/`Product`/`Transporter`/`Vehicle` types, and derived calculations.
- `mrnNumber` is mapped to material document number `MATDOC-MBLNR` / `MaterialDocument`.
- The sheet includes `FiscalYear`, purchase-order/item, delivery/item, movement type/reference type, storage location, batch, customer and token as technical/audit attributes beyond the main UI columns.
- The UI-facing fields delivery, invoice number/date, LR/GR, product, ageing, vehicle, dispatch quantity, received quantity, in-transit quantity, status, supplying plant and transporter are represented. No vehicle-tracking-link attribute is present.

## Material gaps before CPI/T2 implementation

1. **Stable key is incomplete.** `MaterialDocument` alone is not globally sufficient; the sheet separately lists `FiscalYear` but does not define a composite key or include `MaterialDocumentItem`. Delivery item is not a substitute for material-document item.
2. **Delivery field typo.** Row 8 names `VBLEN_IM`; the SAP field is `VBELN_IM`.
3. **Dispatch quantity is not wired.** Row 13 names `LIPS-LFIMG`, but the Datasphere field-name cell is blank even though availability is marked yes.
4. **In-transit derivation is internally inconsistent.** Row 15 says `dispatch − received` and names a calculated column, but marks `Derived = no`. The aggregation grain, movement signs and reversal treatment are not defined.
5. **Receipt quantity needs aggregation rules.** Row 14 maps `MATDOC-MENGE` / `QuantityInBaseUnit`, but the sheet does not define how multiple 101 postings, 102 reversals, partial receipts or unit conversion roll up to a delivery/item.
6. **Status is unresolved.** Row 20 equates `PENDING / COMPLETED` to `IsCompletelyDelivered`; row 32 asks whether the same field is duplicated. The business rule is not frozen.
7. **Several enrichments lack an executable field mapping.** Vehicle, LR/GR and dispatch quantity have blank Datasphere field names; product/plant descriptions and grade/brand are marked derived/NA rather than tied to a consumable view.
8. **Ageing is provisional.** Row 23 states `current date - invoice date` and explicitly says the formula needs checking. Time zone, day-boundary and null-invoice behavior are absent.
9. **Commerce type is questionable.** Row 2 maps `mrnNumber` to `PhysicalInventoryDoc.docId`, mixing goods receipt/MRN identity with the physical-inventory domain.
10. **Sheet scope is ambiguous.** A tab named `completed MRN` still contains in-transit quantity and a `PENDING / COMPLETED` status. Confirm whether it is history-only or the unified MRN read model.

## Architecture consequence

**Strong inference:** the intended 30-minute flow should expose one reconciled, consumable Datasphere projection and let CPI transport/upsert it into T2. CPI should not recreate these joins or business calculations. The MIGO confirmation remains a synchronous S/4 command with live lock, re-read and validation; a 30-minute projection cannot authorize the posting.

## Open confirmations

- Exact source object behind `VW_CDS_MATDOC_MATERIALDOCUMENT` and whether it has an active ODP/replication subscription.
- Datasphere-to-CPI access pattern, delta watermark, paging, deletion/tombstone handling, retry and reconciliation controls.
- Composite row key and version/freshness timestamp.
- Approved status, quantity/reversal and ageing rules.
- Missing vehicle-tracking link and exact Commerce destination fields.
