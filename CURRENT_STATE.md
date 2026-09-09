# Shree Cement C&F Agent — current SAP implementation state

**As of:** 2026-09-09
**Authority:** This document overrides older implementation-status statements where they conflict. The v1.9 workbook remains the business-contract baseline; it is not the current technical certification record.

## What changed

The project has moved beyond service discovery. The decisive question is no longer whether a standard SAP service exists or returns a successful response. It is whether the externally invoked path creates the intended document and preserves the client-specific validations, derivations, commit behavior, replay protection and downstream linkage that users receive through SAP transactions.

The September BAPI and enhancement investigation proved that those paths can differ materially. In particular, MIGO transaction enhancements do not automatically run when the same posting core is reached through `BAPI_GOODSMVT_CREATE` or `API_MATERIAL_DOCUMENT_SRV`.

## Certification model

| Classification | Meaning |
|---|---|
| Standard read — proven | Representative business data was returned and reconciled to SAP. |
| Standard write — path proven | A document persisted, but business-equivalence or scenario coverage remains incomplete. |
| Standard service with required enhancement | The SAP-delivered endpoint remains the transport, but supported enhancement logic is required for the business contract. |
| Custom command exposure | SAP business logic exists as a BAPI/FM chain, but no suitable standard external command exists. |
| Existing client route to trace | Installed client/add-on logic appears to own the operation; trace and reuse it before building. |
| Blocked by business definition | The object, owner or contract is not settled enough for implementation. |

## API-by-API disposition

| API | Current classification | What is proven | What remains |
|---|---|---|---|
| MIGO-01 Show Inward MRNs | Existing read logic; exposure ownership open | Pending receipt is derived per delivery from existing CDS/report logic led by `zsd_mrn_pending_cds_opt`. | Settle SAP versus Datasphere/T2 ownership, stable key, cadence and live revalidation boundary. Do not describe this as “no evidence.” |
| MIGO-02 Submit MIGO | Standard service with required enhancement — not certified | Standard OData posted material document `5007138616/2026` using PO + delivery references. Direct BAPI callers prove a delivery-only 101 pattern is viable. | Implement and prove the supported BAdI path; settle delivery-only OData mapping; reproduce/refactor required MIGO validations; prove duplicate/concurrency, partial/shortage, reversal and representative rail/road cases. The current CNF BAdI class is empty and the earlier source enhancement is being removed. |
| OF-01 Create DI | Standard write — STO path proven | `API_OUTBOUND_DELIVERY_SRV;v=2` created and persisted STO delivery `9004953174`; the STO path calls `BAPI_OUTB_DELIVERY_CREATE_STO`. | Prove Trade and Non-trade predecessors, audit delivery-creation enhancements, test replay/negative cases and confirm inheritance rules. |
| OF-02 Stock Availability | Standard read — proven | `API_MATERIAL_STOCK_SRV` returned real QS4 stock at account-model grain. | Freeze business filters, included stock types, authorization behavior and T2/Datasphere projection. |
| OF-04 Pre-PGI | Custom command exposure | Shipment creation persists only with explicit commit; `SD_SCDS_CREATE` and headless `SD_SCDS_RELEASE` are callable. | Build the controlled orchestration boundary and prove one real shipment-cost creation/release flow, including locks and partial-failure recovery. |
| OF-05 Create PGI | Standard-write candidate — not certified | Delivery v2 advertises `PostGoodsIssue` and `ReverseGoodsIssue`. | Execute both against controlled data, re-read document flow, and audit PGI-specific enhancements for Trade, Non-trade and STO. |
| OF-06 Create Order (STO) | Custom command exposure | Standard PO API reads STOs but rejects the required ZP06/item-category create shape. `BAPI_PO_CREATE1` is the core candidate. | Build the wrapper, prove commit/rollback and persistence, freeze derived organization/shipping values and test replay. |
| OF-07 Create Invoice | Custom command exposure | Standard Billing API is read/PDF only. Client code and released BAPI candidates establish a creation route. | Select and execute the billing-create core, persist, re-read through the standard Billing API, and verify accounting/statutory continuation. |
| INV-01 E-Way Bill Extension | Existing client route to trace | eDocument, DigiGST tables and EY destinations are installed. | Identify the supported callable boundary and prove provider response, persistence and duplicate protection. |
| INV-02 Invoice Correction | Existing client route to trace | The permitted correction delta and installed statutory footprint are known. | Trace cancel/correct/regenerate semantics and prove separate e-Invoice and E-Way outcomes. |

## Submit MIGO — current hard boundary

The earlier “standard direct” label is retired for Submit MIGO.

- `API_MATERIAL_DOCUMENT_SRV` can post a 101 movement, but the proven request used both PO/item and delivery/item.
- The required portal contract is delivery-led. Existing ILMS callers show that SAP can derive the posting from delivery/item without caller-supplied PO.
- The standard OData mapping and allowed-field checks are not equivalent to a direct BAPI call.
- Eight identified MIGO-side customisation points are not reached by the BAPI/OData path. They include quantity, storage-location, billing-status and other business checks.
- `MB_BAPI_GOODSMVT_CREATE` is the approved supported extension direction, but the CNF implementation is currently empty and its dispatch was not successfully proven during the spike.
- No new material document was posted by the September enhancement/BAdI work.

Until those points are closed, Submit MIGO is an implementation investigation with one earlier positive standard posting—not a finished API.

## Repository precedence

Read in this order:

1. `CURRENT_STATE.md`
2. `deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx` for business contract and numbering
3. `deliverables/CNF_MIGO_CUSTOMISATION_DISPOSITION_2026-09-04.md`
4. `deliverables/handover/CNF_SUBMIT_MIGO_STATE_OF_THINGS_2026-09-04.md`
5. `sessions/2026-09-01-bapi-field-derivation/FINDINGS.md`
6. `sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md`
7. `DECISION_LOG.md` and `OPEN_QUESTIONS.md`
8. Older handovers and discovery packs as dated evidence only

## Next execution gates

1. Complete the unread MIGO enhancement sources and relevant configuration values.
2. Prove why the CNF `MB_BAPI_GOODSMVT_CREATE` implementation did not execute, then implement the smallest supported derivation hook.
3. Refactor required delivery-GR rules below the transaction/API split so both paths use the same rule implementation.
4. Run one delivery-led receipt against fresh controlled data, re-read `MATDOC/MSEG`, verify custom header persistence and replay behavior.
5. Audit Create DI and PGI enhancement paths before upgrading them from path-proven/candidate to business-certified.
6. Freeze a single reviewed Postman pack only after those runtime results are reflected in the contract and examples.

## Definition of done for a write API

A write API is complete only when the exact route and version are fixed, a representative document persists, the document is independently re-read, client-specific enhancement behavior is accounted for, duplicate and concurrent attempts are tested, authorization and negative cases are captured, downstream linkage is verified, and recovery/reversal is documented.
