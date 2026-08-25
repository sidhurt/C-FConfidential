# STO manual walkthrough — observation checklist

**For:** Siddharth's own manual trace of the complete STO flow in QS4, 2026-08-16.
**Purpose:** capture what the process actually is, so the independent SAP replay and the v1.7 Excel rows are written from observation, not from the generic SAP STO textbook.
**Rule:** record what QS4 does. Where QS4 and the standard flow differ, QS4 wins and the difference is the finding.

Fill this in as you go. One line per observation. `?` is a valid answer and is more useful than a guess.

---

## 0. Identifier cross-reference (do not renumber anything)

The final v1.7 workbook (`sources/SRC-DOC-20260815-01`) is the authority. `PROJECT_BRAIN.md` and `deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md` already use the same numbering — no renumbering is required today. One superseded draft numbering still exists in `outputs/cnf_api_contract_v17/*.inspect.ndjson` and older `outputs/` folders; map it, never rewrite it.

| Current v1.7 (authoritative) | Superseded draft numbering |
|---|---|
| API-01 Submit MIGO | API-02 Submit MIGO |
| API-02 Create DI | API-03 Create DI |
| API-03 Create Invoice / Billing Documents | API-06 Shipment, PGI & Invoice |
| API-04 Shipment Calculation | API-05 Shipment Cost Estimate |
| API-05 Stock Availability | API-04 Stock Availability |
| API-08 STO Orders · API-09 STO Deliveries · API-10 STO Invoice | not present in the draft |
| API-11 Create STO Purchase Order | API-11 (unchanged) |
| API-12 Update DI Quantity | API-09 Modify DI |
| — (removed) | API-01 Check MIGO / Pending Receipt |

STO-relevant v1.7 rows to be evidenced by this trace: **API-11, API-08, API-02, API-12, API-04, API-03, API-09, API-01, API-10.**

---

## 1. Origin and document type

- [ ] Where does the STO originate — SAP dialog (ME21N/ME21), a requisition, MRP, or the portal/T2? Record the transaction actually used.
- [ ] PO document type (`EKKO-BSART`). v1.7 documents **ZP06** — confirm or contradict.
- [ ] Item category (`EKPO-PSTYP`) and special stock/procurement indicator.
- [ ] `EKKO-BSART` as source differentiator: the 14 Aug discussion states PO type distinguishes CRM/Udaan-originated documents (`SRC-MTG-20260814-05 @45:50`). Note what value a portal-originated STO would carry.
- [ ] Is a purchase requisition a real predecessor here, or optional? (`EKPO-BANFN`/`BNFPO` — v1.7 API-11 sends RequisitionNumber/Requisitioner as mandatory.)
- [ ] Does this STO carry a shipping/transport type at PO level at all? (v1.7 API-11 sends `ShippingType`; the PO model has no home for it — this is a live contract defect to confirm or kill.)

## 2. Plants and org structure

- [ ] Supplying plant (`EKKO-RESWK`) — code and description.
- [ ] Receiving plant (`EKPO-WERKS`) — code and description.
- [ ] Are both **warehouse/depot**, or is one a manufacturing plant? The 14 Aug walkthrough says the portal STO screen is **warehouse-to-warehouse only, not plant-originated** (`SRC-MTG-20260814-05 @41:15`). Confirm what QS4 actually permits.
- [ ] Same company code both sides, or cross-company? This decides whether an intercompany billing document can exist at all (drives API-10).
- [ ] Purchasing organisation and purchasing group — entered or derived?
- [ ] Storage location on the PO item — present, blank, or determined later?

## 3. Screen-by-screen walk

One row per screen. Record the transaction code and the SAP screen/program shown in **System → Status**, not the menu label.

| # | T-code | Screen / tab | What you did | What SAP validated or refused | Document/number produced |
|---|---|---|---|---|---|
| 1 | | | | | |
| 2 | | | | | |
| 3 | | | | | |
| 4 | | | | | |
| 5 | | | | | |
| 6 | | | | | |
| 7 | | | | | |
| 8 | | | | | |

Expect (do not assume) something along: STO PO → outbound delivery → shipment → shipment cost → cost release → PGI → billing → GR at receiving plant. The 14 Aug session states the dispatch order as **DI → shipment number → shipment cost → shipment cost release → PGI → invoice** (`SRC-MTG-20260814-01 @12:28, @15:04`), while another speaker in the same meeting insists the portal treats shipment and invoice as one action. **Record which one QS4 enforces.**

## 4. Documents created and the references that connect them

| Document | Number | Type / category | Created by (T-code) | Reference it carries back | Reference it carries forward |
|---|---|---|---|---|---|
| STO purchase order | | `BSART=` | | requisition? | |
| Outbound delivery / DI | | `LIKP-LFART=` | | STO PO + item | |
| Shipment | | `VTTK-SHTYP=` | | delivery | |
| Shipment cost doc | | | | shipment | |
| PGI material document | | `MSEG-BWART=` | | delivery | |
| Billing / STO invoice | | `VBRK-FKART=` | | delivery | accounting doc |
| GR material document (MIGO) | | `MSEG-BWART=` | | delivery or PO? | |

- [ ] Open **document flow** (VA03/VL03N `Environment → Document flow`, or ME23N item → Purchase order history) and screenshot the whole chain.
- [ ] Record which link is *missing* from the document flow — the 14 Aug session complains that with three MIGOs of 10 T against one 50 T delivery, only the most recent is traceable (`SRC-MTG-20260814-05 @32:00, @33:34`). Confirm whether SAP really loses that or the display just collapses it.
- [ ] **GR reference model — the single most important answer today:** does the receiving MIGO reference the **outbound delivery**, the **STO PO**, or an **inbound delivery**? This decides API-01's primary service (`API_MATERIAL_DOCUMENT` item `Delivery`/`DeliveryItem` vs `PurchaseOrder`/`PurchaseOrderItem` vs `API_INBOUND_DELIVERY_SRV;v=2 PostGoodsReceipt`).

## 5. Quantity, batch, storage location, status

- [ ] Quantity at each hop: ordered → delivered → picked → PGI'd → invoiced → received. Note where they legitimately diverge.
- [ ] Unit and whether any hop converts it.
- [ ] Batch: determined automatically or entered? At delivery creation or at picking? Split into how many batches?
- [ ] Storage location: on the outbound side (issuing SLoc) and inbound side (receiving SLoc). Which is derived, which is typed?
- [ ] Receiving allocation across multiple SLocs — does QS4's MIGO actually allow one receipt split across GDF/CUT/DMG/RDFR/STG in one posting, or one SLoc per posting?
- [ ] Status fields after each step: `EKPO` delivery-completed flag, PO history, `LIKP/LIPS` goods-movement status, `VBUK/VBUP` equivalents, billing status.
- [ ] Where does the "STO pending list per warehouse" come from — is it a real SAP list/report, or only the portal/DSP view? (`SRC-MTG-20260814-05 @08:11, @08:37` says storage-location assignment comes from DSP and inward quantity from MATDOC.)

## 6. User-entered versus SAP-derived

For every field you touched, mark it. This column is what the Excel request/response mapping is built from.

| Field | Screen | Entered by user | Derived by SAP | Derived from what |
|---|---|---|---|---|
| | | | | |

Pay particular attention to: company code, purchasing org/group, shipping point, route, incoterm, plant SLoc, movement type, delivery type, billing type. v1.7 currently sends CompanyCode and ShippingType as caller input on API-11 — confirm whether SAP derives them.

## 7. Exceptions — do not skip these

- [ ] **Partial receipt:** receive less than dispatched. What is the remaining/open quantity field, and where is it readable?
- [ ] **Over-receipt:** attempt it. Exact message number and text (`Message → Long text → Technical information`).
- [ ] **Second receipt against the same delivery:** allowed? What changes?
- [ ] **Cancellation:** cancel the GR (MIGO cancellation / MBST), cancel the invoice, reverse PGI (VL09). Record what each produces and what it does to the predecessor status. The 14 Aug session states invoice cancellation must roll the document back to the DI stage (`SRC-MTG-20260814-04 @01:51`) — confirm SAP behaviour.
- [ ] **Failure and retry:** post the same thing twice. Does SAP create a duplicate? (Expected: yes. This is the evidence for the CPI/T2-owned idempotency envelope.)
- [ ] **Blocked/invalid combinations:** same plant both sides, closed period, blocked material, quantity above open balance. Capture the message IDs.

## 8. How the documents reach T2/T1

- [ ] Is there an actual output/IDoc/event on any of these documents? Check message output (NAST), change pointers (BDCP2), and any Z event/BAdI on save.
- [ ] The 14 Aug design position is **event-based push from S/4 to T2 as soon as the STO/DI/invoice is created** (`SRC-MTG-20260814-05 @41:54, @43:34`). Record whether such a trigger exists in QS4 today for STO documents, or whether it is aspirational.
- [ ] If a portal-originated DI would be echoed back by that same push, note the loop-control question (raised at `@43:18`, proposed control on PO type + user type at `@46:33`). This is CPI/T2 ownership, not ABAP — but the SAP-side discriminator must be observable.

## 9. Technical evidence to grab while you are in the screen

Capture as you go, not afterwards.

- [ ] `System → Status` on every screen: program, screen number, transaction, package.
- [ ] Table/field for anything ambiguous: `F1 → Technical Information` — table + field name.
- [ ] Z-fields on any header/item (`LIKP-ZZ*` is already known to carry vehicle/driver — confirm whether STO deliveries use them).
- [ ] Any Z-transaction, Z-report or Z-table in the path.
- [ ] Where a BAPI/FM/class name surfaces (SM50, ST05 short trace, or a message referencing it) — record it; do not go hunting.
- [ ] Document numbers of everything you create, plus date/time and the QS4 client. The replay needs these to read the same documents.

## 10. Handover line to Phase 2

When the manual trace is done, tell me:

1. the document chain you actually observed, with real numbers;
2. the GR reference model (§4, last item);
3. anything QS4 did that the generic STO flow does not do;
4. whether any test posting is authorised for the replay, and on which documents.

Until then the automated replay does not start.
