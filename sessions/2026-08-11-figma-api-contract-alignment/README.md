# 11 August 2026 — Figma and API Contract Alignment Handover

> **Status: additive session delta pending canonical reconciliation.**  
> This pack preserves today's validated knowledge without deleting or silently rewriting older material. The canonical registers remain the files named in `CLAUDE.md`; tomorrow's cleanup should promote this delta into them and then mark superseded material explicitly.

## Why this pack exists

The repository's canonical documentation currently lags the v1.7 workbook and the latest validated Figma flows. Some older files still say STO is deferred, describe twelve API slots, restore the removed standalone E-Invoice Correction/Inventory Reconciliation operations, or use the pre-12-August API numbering. Updating those files piecemeal would create a high risk of half-reconciled truth.

This session pack is therefore a controlled bridge:

- durable source images have been copied from temporary attachments into `sources/`;
- direct business clarifications have been preserved as `SRC-SID-20260811-08` through `SRC-SID-20260811-12`;
- today's process and API model is stated once;
- workbook defects and unresolved SAP validation gates are called out explicitly;
- a file-by-file canonical cleanup sequence is prepared for the next session.

No legacy file was deleted as part of this handover.

## Fast read path for the next AI

1. Read repository rules and the canonical hierarchy in [`../../CLAUDE.md`](../../CLAUDE.md).
2. Read [`01_PROCESS_AND_BUSINESS_HANDOVER.md`](01_PROCESS_AND_BUSINESS_HANDOVER.md).
3. Read [`05_DI_FLOW_DEEP_CONTEXT.md`](05_DI_FLOW_DEEP_CONTEXT.md) for the DI/API relationship and the API-03 versus API-04 precision guard.
4. Read [`02_API_CONTRACT_HANDOVER.md`](02_API_CONTRACT_HANDOVER.md) when working on a request/response contract.
5. Read [`06_PREDICTIVE_SEGW_BAPI_IMPLEMENTATION_MAP.md`](06_PREDICTIVE_SEGW_BAPI_IMPLEMENTATION_MAP.md) when studying, estimating or designing the ABAP/SEGW implementation behind each API.

That is enough for normal continuation. Use the following only when needed:

- [`03_EVIDENCE_AND_CONFIDENCE.md`](03_EVIDENCE_AND_CONFIDENCE.md) — when a claim conflicts with an older file or needs promotion into a canonical register.
- [`04_CANONICAL_RECONCILIATION_BACKLOG.md`](04_CANONICAL_RECONCILIATION_BACKLOG.md) — during tomorrow's cleanup.
- [`06_PREDICTIVE_SEGW_BAPI_IMPLEMENTATION_MAP.md`](06_PREDICTIVE_SEGW_BAPI_IMPLEMENTATION_MAP.md) — candidate BAPIs, CDS views, SEGW models, transaction boundaries, effort ranges and QS4 proof gates for the current API-01..API-11 catalogue.
- [`manifest.yaml`](manifest.yaml) — compact machine-readable index.

## Session outcome in one page

- The current business model is **Trade, Non-trade and STO**.
- STO is the **intra-warehouse movement** between Shree Cement locations. It uses a stock-transport PO predecessor; Trade and Non-trade use a sales-order predecessor. The downstream DI journey is shared.
- **DI = SAP outbound delivery** in project terminology.
- The validated STO sequence is Purchase Order → Create DI → In Process fulfilment → document flow, including receiving-side GR.
- The validated STO screen also creates the stock-transport purchase order itself. Working v1.7 therefore contains **candidate API-11 Create STO Purchase Order**, used only for STO/intra-warehouse. Its successful `PurchaseOrder` becomes API-03's `PredecessorDocument` with `PredecessorType = STO_PO`.
- The validated outbound sequence is DI → optional DI quantity change → storage location/SPI → FIFO batch allocation → transporter/shipment → shipment cost → PGI → billing → e-Invoice → E-Way Bill.
- The validated inbound sequence is pending receipt/MRN work item → quantity classification → MIGO → SAP material document plus fiscal year; the exact meaning of the UI's “MRN Document Number” remains unresolved.
- API-04 is the sole stock-availability/physical-inventory read. The separate Inventory Reconciliation operation was removed; physical-difference posting is still unresolved.
- The standalone E-Invoice Correction operation was removed as nonexistent/out of requirement. **Current API-08 is E-Way Bill Extension**, not that removed operation.
- Siddharth's current v1.7 numbering is authoritative: API-08 E-Way Bill Extension, API-09 Modify DI, API-10 Valid Storage Locations, and candidate API-11 Create STO Purchase Order.
- The v1.7 workbook now contains eleven API sheets, API-01 through API-11. API-11 is explicitly candidate pending formal scope and SAP MM ownership approval.
- The current workbook incorrectly treats DMG/STG as SAP storage-location inputs. The latest direct business clarification says they are rejected/non-stock classifications that contribute to replacement/pending quantity.
- The stated business-scope codes are FTP, FTB and EXW; Division 10 = Cement; two ageing measures exist; outbound selection follows FIFO. Incoterm configuration and `1000`/`1300` organizational mapping still contain evidence conflicts.
- The E-Way Bill management list is a read surface; API-08 is the separate extension command. Per `SRC-SID-20260812-01`, extension is eligible only during the eight hours immediately before expiry, with no after-expiry window. Success adds exactly 24 hours; duration is fixed and is not a request field.

## Current working artifacts

- Workbook: [`../../outputs/cnf_api_contract_v17/CNF_API_Request_Response_Specification_v1.7.xlsx`](../../outputs/cnf_api_contract_v17/CNF_API_Request_Response_Specification_v1.7.xlsx)
- Direct-clarification record: [`../../sources/SRC-SID-20260811-08_to_12_Direct_Clarifications_Session_Record.md`](../../sources/SRC-SID-20260811-08_to_12_Direct_Clarifications_Session_Record.md)
- E-Way timing correction: [`../../sources/SRC-SID-20260812-01_EWay_Extension_Timing_Clarification.md`](../../sources/SRC-SID-20260812-01_EWay_Extension_Timing_Clarification.md)
- New STO evidence: `SRC-FIG-20260811-09` through `SRC-FIG-20260811-12`
- New E-Way evidence: `SRC-FIG-20260811-13`
- Focused STO Create Purchase Order evidence: `SRC-FIG-20260812-01`
- STO API and numbering clarifications: `SRC-SID-20260812-02`, `SRC-SID-20260812-03`
- New mapping evidence: `SRC-DOC-20260811-02` through `SRC-DOC-20260811-04`

## Authority discipline

This pack records **business/product truth at today's confidence level**. It does not prove SAP object names, tables, DDIC types, BAPIs, OData entities, commit behavior, locking, or statutory adapter mappings. Those stay candidate or open until system evidence or owner confirmation exists.
