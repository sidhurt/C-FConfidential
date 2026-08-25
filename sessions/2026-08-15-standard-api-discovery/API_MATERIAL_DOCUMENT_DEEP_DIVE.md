# Deep dive — `API_MATERIAL_DOCUMENT`

**Date:** 2026-08-15
**System:** QS4 / client 700 / user QNOVATE8, read-only SEGW
**Tier A rank:** 5
**Primary v1.7 target:** API-01 Submit MIGO
**Final disposition:** `CONDITIONAL-BUSINESS-GATE` — strongest API-01 candidate on evidence so far, **not selected**

---

## 0. Headline

On request and response shape this service fits API-01 where the inbound delivery API did not. `SAP-OFFICIAL` for S/4HANA on-premise 2022 confirms:

- a **single POST creates one header with many items in one call** ("must include both header and item properties in the same request");
- each item carries its own `Plant`, `StorageLocation`, `QuantityInEntryUnit` and `EntryUnit` — which is exactly the v1.7 `Allocations[]` collection;
- each item carries `Delivery` / `DeliveryItem` **and** `PurchaseOrder` / `PurchaseOrderItem`, so a receipt referencing a delivery is expressible;
- the response "returns new material document header information", whose key is `MaterialDocument` + `MaterialDocumentYear`;
- every item carries `MaterialDocumentItem`, which is v1.7's `Allocations[].MaterialDocumentItem`.

**This is not a selection.** Three things stand between this evidence and a decision, and all three are outside what SEGW and SAP documentation can answer:

1. the service is **not registered in QS4** (§8) — SAP publishing an API is not QS4 being able to call it;
2. the correct `GoodsMovementCode` / `GoodsMovementType` depends on the unresolved STO document-flow question (§10, open item ID-1);
3. this project is **SADL/CDS-exposed**, so its SEGW design-time evidence is materially weaker than the delivery family's and cannot corroborate the documented contract (§5.1, §6.1).

Handover §1.3 applies: shape matching is triage, not selection.

---

## 1. Project identity

| Attribute | Value | Evidence |
|---|---|---|
| Project | `API_MATERIAL_DOCUMENT` | `LOCAL-DESIGN` |
| Catalogue description | Remote API for Material Document | `LOCAL-DESIGN` |
| Created by | SAP | `LOCAL-DESIGN` |
| Last changed on | 24.02.2022 | `LOCAL-DESIGN` |

Evidence directory: `sources/SRC-SYS-20260815-05_QS4_700_SEGW_API_MATERIAL_DOCUMENT/`
Tree rows: 158 total, 153 for this project.
Grid manifest rows: 14, all distinct — see §13 for the exporter defect found and fixed during this extraction.

## 2. Runtime identity

| Attribute | Value | Evidence |
|---|---|---|
| Model | `API_MATERIAL_DOCUMENT_MDL` | `LOCAL-DESIGN` |
| Annotation model | `API_MATERIAL_DOCUMENT_ANNO_MDL` (`IWVB`) | `LOCAL-DESIGN` |
| Service (TADIR object) | `API_MATERIAL_DOCUMENT_SRV` (`IWSV`) | `LOCAL-DESIGN` |
| External runtime path | `/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/` | `SAP-OFFICIAL` |
| Version selector | **None.** Every documented 2022 sample URL is unversioned. | `SAP-OFFICIAL` |
| Protocol | OData V2 (A2X) | `SAP-OFFICIAL` |
| DPC / DPC_EXT | `CL_API_MATERIAL_DOCUME_DPC` / `_DPC_EXT` | `LOCAL-DESIGN` |
| MPC / MPC_EXT | `CL_API_MATERIAL_DOCUME_MPC` / `_MPC_EXT` | `LOCAL-DESIGN` |

Two differences from the delivery family worth carrying forward:

- **No `;v=n` selector.** The delivery APIs are addressed at `;v=2`; this one is addressed bare. Do not assume a uniform versioning convention across SAP A2X services — check each.
- **An annotation model artifact exists** (`API_MATERIAL_DOCUMENT_ANNO_MDL`), which the delivery projects do not have. Consistent with the SADL/CDS exposure described in §5.1.

## 3. Model counts

| Surface | Count | Note |
|---:|---:|---|
| Entity types | 3 | all under CDS-Entity Exposures |
| Entity sets | 3 | |
| Complex types | 0 | |
| Associations | 2 | |
| Association sets | 2 | |
| Function imports | **0 in design time** | SAP documents two — see §5.1 |
| Runtime artifacts | 7 | |

Entity types: `A_MaterialDocumentHeaderType`, `A_MaterialDocumentItemType`, `A_SerialNumberMaterialDocumentType`.

Associations: header 1→N item; item 1→M serial number. Navigation properties: `to_MaterialDocumentItem` on the header, `to_SerialNumbers` and `to_MaterialDocumentHeader` on the item.

## 4. Entity-set operation matrix

`LOCAL-DESIGN`.

| Entity set | Creatable | Updatable | Deletable | Pageable | Addressable | Searchable |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `A_MaterialDocumentHeader` | X | | | X | X | |
| `A_MaterialDocumentItem` | | | | X | X | |
| `A_SerialNumberMaterialDocument` | | | | X | X | |

Create is on the **header only**. Items and serial numbers are written as a deep insert through `to_MaterialDocumentItem` / `to_SerialNumbers`, which is why they carry no independent creatable flag. `SAP-OFFICIAL` confirms header and item must arrive in the same request.

Nothing is updatable or deletable. A posted material document is corrected by cancellation, not by change — consistent with SAP inventory semantics and relevant to API-07-style correction thinking later.

## 5. Function imports

**Zero function imports appear in this project's SEGW design time.** There is no `Function Imports` container node at all.

`SAP-OFFICIAL` documents two for the 2022 on-premise service:

| Operation | HTTP | URL |
|---|---|---|
| Cancel material document at header level | POST | `.../API_MATERIAL_DOCUMENT_SRV/Cancel?MaterialDocumentYear='…'&MaterialDocument='…'` |
| Cancel material document at item level | POST | `.../API_MATERIAL_DOCUMENT_SRV/CancelItem?MaterialDocumentYear='…'&MaterialDocument='…'&MaterialDocumentItem='…'` |

### 5.1 Why design-time evidence is weaker here — and what follows

This project's own `Data Model > Entity Types`, `Associations` and `Entity Sets` nodes are **empty**. The entire model sits under `Data Model > Data Source References > Exposures via SADL > CDS-Entity Exposures`. The service is a SADL exposure of CDS entities, not a hand-modelled SEGW service.

Consequences, all of which matter for how this report is read:

- SEGW does not show the `Cancel` / `CancelItem` function imports even though SAP documents them. **The design-time project under-reports the runtime surface.** This is a concrete instance of handover §1.5 and it is the first candidate where the two disagree in this direction.
- Property-level `CREATABLE` / `UPDATABLE` annotations are **entirely absent** on all three entity types (§6.1). They live in the CDS views and `API_MATERIAL_DOCUMENT_ANNO_MDL`, not in SEGW.
- Therefore the calibration that held for the inbound delivery family — where SEGW annotations predicted the documented contract field-for-field — **does not transfer to this project.** Do not carry that confidence across.

Everything in §6 about writability is `SAP-OFFICIAL` only, with no local corroboration available. Local `$metadata` would be needed to close this, and that requires registration first.

## 6. Business-critical property mapping

### 6.1 What SEGW gives, and what it does not

| Entity | Properties | Keys | Property-level C/U annotations |
|---|---:|---|---|
| `A_MaterialDocumentHeaderType` | 14 | `MaterialDocument`, `MaterialDocumentYear` | none present |
| `A_MaterialDocumentItemType` | 89 | `MaterialDocument`, `MaterialDocumentYear`, `MaterialDocumentItem` | none present |
| `A_SerialNumberMaterialDocumentType` | 5 | — | none present |

The **header key is `MaterialDocument` + `MaterialDocumentYear`** and the **item key adds `MaterialDocumentItem`**. That is precisely the authoritative SAP key v1.7 API-01 demands in its response, obtained from the object that owns it.

> **Prohibited derivation.** `MaterialDocumentYear` is read from this key. It must never be derived from `PostingDate`, `DocumentDate`, or the current date. The material-document year is a property of the document SAP creates, not an arithmetic function of a date the caller supplied.

### 6.2 Documented create contract (`SAP-OFFICIAL`, on-premise 2022)

**Header**

| Property | Necessity |
|---|---|
| `GoodsMovementCode` | Mandatory |
| `PostingDate` | Mandatory |
| `DocumentDate` | Optional |
| `MaterialDocumentHeaderText` | Optional |
| `ReferenceDocument` | Optional |
| `ManualPrintIsTriggered`, `VersionForPrintingSlip` | Optional |
| `CtrlPostgForExtWhseMgmtSyst` | Optional — **see the warning below** |

`GoodsMovementCode` values: `01` GR for Purchase Order · `02` GR for Production Order · `03` Goods Issue · `04` Transfer Posting · `05` Other Goods Receipt · `06` Reversal of Goods Movements · `07` Subsequent Adjustment for Subcontract Order.

**Item** — mandatory: `Plant`, `GoodsMovementType`. Optional and directly relevant to CNF: `StorageLocation`, `Material`, `Batch` (mandatory when the material is batch-managed and batches are not determined automatically), `QuantityInEntryUnit`, `EntryUnit`, `PurchaseOrder`, `PurchaseOrderItem`, `Delivery`, `DeliveryItem`, `GoodsMovementRefDocType`, `GoodsMovementReasonCode`, `InventorySpecialStockType`, `Supplier`, `IsCompletelyDelivered`, `ShelfLifeExpirationDate`, `ManufactureDate`, `MaterialDocumentItemText`, `UnloadingPointName`.

SAP's own worked examples include **"Create a Goods Receipt for a Purchase Order with Deliveries"** — the exact combination the CNF depot receipt needs.

> ⚠ **`CtrlPostgForExtWhseMgmtSyst = 1` creates a delivery document instead of a material document** (SAP Note 3021752). For CNF this field must be blank. A wrong value here would silently return a delivery number where the portal expects a material document. Flag this in any CPI mapping.

SAP also warns that "depending on the value of the `GoodsMovementCode`, `GoodsMovementType` and `GoodsMovementRefDocType` properties, the necessity and availability of the other item properties can vary." Field availability is therefore **conditional on the movement scenario**, which is not settled until ID-1 is.

### 6.3 Documented response

"For all of the examples provided, the operation returns new material document header information." The header key is returned. `SAP-OFFICIAL` does not state whether created item numbers are echoed in the response body; the item entity carries `MaterialDocumentItem` as a key and is readable by navigation afterwards. **Whether `Allocations[].MaterialDocumentItem` comes back on the create response or requires a follow-up read is `UNPROVEN`** — open item MD-4.

## 7. v1.7 coverage matrix

API-01 per the authoritative workbook (`BUSINESS-DEMAND`, `SRC-DOC-20260815-01`, sheet *API-01 Submit MIGO*).

| v1.7 field / requirement | Necessity | SAP counterpart | Coverage | Class |
|---|---|---|---|---|
| `DeliveryDocument` (GR reference) | Mandatory | item `Delivery` (+ `DeliveryItem`) | `DIRECT` | `SAP-OFFICIAL` |
| `PurchaseOrder` (assertion only) | Optional | item `PurchaseOrder` / `PurchaseOrderItem` | `DIRECT` | `SAP-OFFICIAL` |
| `ReceivingPlant` (assertion only) | Optional | item `Plant` (mandatory in SAP) | `DIRECT` | `SAP-OFFICIAL` |
| `PostingDate` | Optional, defaults | header `PostingDate` — **mandatory in SAP** | `PARTIAL` | `SAP-OFFICIAL` |
| `DocumentDate` | Optional | header `DocumentDate` | `DIRECT` | `SAP-OFFICIAL` |
| `Material` (assertion only) | Optional | item `Material` | `DIRECT` | `SAP-OFFICIAL` |
| `Unit` (derived) | Derived | item `EntryUnit` / `MaterialBaseUnit` | `DIRECT` | `SAP-OFFICIAL` |
| `Allocations[].StorageLocation` | **Mandatory** | item `StorageLocation`, one item per allocation | `DIRECT` | `SAP-OFFICIAL` |
| `Allocations[].Quantity` | **Mandatory** | item `QuantityInEntryUnit` + `EntryUnit` | `DIRECT` | `SAP-OFFICIAL` |
| Multiple allocations in one business attempt | **Mandatory** | deep insert, many items per POST | `DIRECT` | `SAP-OFFICIAL` |
| `MaterialDocument` | **Mandatory** | header key, returned | `DIRECT` | `SAP-OFFICIAL` + `LOCAL-DESIGN` |
| `MaterialDocumentYear` | **Mandatory** | header key, returned | `DIRECT` | `SAP-OFFICIAL` + `LOCAL-DESIGN` |
| `Allocations[].MaterialDocumentItem` | **Mandatory** | item key exists; echoed on create not confirmed | `UNPROVEN` | MD-4 |
| `Allocations[].PostedQuantity` | Mandatory | readable from the created item | `UNPROVEN` | MD-4 |
| `ReceiptStatus` (PENDING/PARTIAL/COMPLETED) | Mandatory | not returned; `IsCompletelyDelivered` is an **input**, not a computed status | `NO FIT` | `SAP-OFFICIAL` |
| `RemainingQuantity` | Mandatory | not returned by create; needs a PO-history or delivery read | `NO FIT` | `SAP-OFFICIAL` |
| `RequestId` / `IsReplay` idempotency | Mandatory | absent from the standard contract | `NO FIT` | `SAP-OFFICIAL` |
| `Status` / `MessageCode` / `Message` | Mandatory | standard OData error payload only | `PARTIAL` | `SAP-OFFICIAL` |
| `Errors[].AllocationIndex` | Optional | no per-item error index in the standard contract | `NO FIT` | `SAP-OFFICIAL` |

**Coverage summary for API-01, scope `ALONE`: `PARTIAL`.** The core posting — multi-storage-location allocated goods receipt returning the authoritative material-document key — is `DIRECT`. The wrapper concerns v1.7 specifies around it (idempotent replay, receipt status, remaining quantity, per-allocation error shaping, user-safe messages) are `NO FIT` in the standard service and must be built in CPI/T2. Handover §1.1 anticipated exactly this: "Standard does not mean zero work."

`GoodsMovementType` is **mandatory in SAP and absent from v1.7**. Whoever calls this service must determine the movement type. That is a real design obligation the v1.7 contract does not currently acknowledge, and it should go back to the business as a question, not be guessed.

## 8. API identity versus local runtime availability

| Question | Answer | Class |
|---|---|---|
| Does SAP publish this API for this release? | Yes. `API_MATERIAL_DOCUMENT_SRV`, OData V2 A2X, documented for S/4HANA on-premise 2022. No deprecation notice. | `SAP-OFFICIAL` |
| What is the runtime path? | `/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/`, no version selector | `SAP-OFFICIAL` |
| Does the project exist in QS4 design time? | Yes. Seven runtime artifacts generated. | `LOCAL-DESIGN` |
| **Is it registered and callable in QS4 today?** | **No.** Absent from the 522-row Gateway catalogue at any version. | `LOCAL-RUNTIME` |
| Is the ICF node / system alias active? | Unknown. | — |
| Has local `$metadata` been read? | No. Not possible before registration. | — |

Related services that **are** registered locally, and are not substitutes: `MMIM_MATDOC_SRV` ("oData Service Material Document") and `MMIM_MATDOC_OV_SRV` ("Material Documents Overview"). These are Fiori-facing services. Whether either exposes a usable create surface is unexamined and should not be assumed either way — but their presence shows material-document OData capability is already live in QS4 in some form, which is worth knowing before Basis is asked for anything.

## 9. Official SAP confirmation

`SAP-OFFICIAL`, SAP Help Portal, **SAP S/4HANA on-premise, version 2022 (Oct 2022)**:

- *Material Documents - Read, Create* — service overview.
- *Operations for Material Document API* — GET, POST create, `Cancel`, `CancelItem`.
- *Create Material Documents* — full header/item/serial field contract, `GoodsMovementCode` value list, EWM warning, response statement.

Documented integration constraints, all of which land on CPI/T2:

- **A change set containing a create POST may contain nothing else.** One business attempt is one isolated POST. This constrains, but also simplifies, the idempotency design.
- A change set with multiple `CancelItem` calls must target items of the same material document with the same posting date.
- Item property necessity and availability vary by `GoodsMovementCode` / `GoodsMovementType` / `GoodsMovementRefDocType`.
- No ETag requirement is documented for create — unlike the delivery APIs, which require `If-Match` throughout. Do not assume the delivery family's concurrency model applies here.

## 10. Gaps, open items and decisions

| # | Open item | Blocks | Resolution route |
|---|---|---|---|
| MD-1 | `Cancel` / `CancelItem` documented by SAP but absent from SEGW design time | Any claim about this project's complete operation surface | Local `$metadata` after registration |
| MD-2 | No property-level C/U annotations in SEGW (SADL/CDS exposure) — the documented contract has no local corroboration | Independent verification of §6.2 | Local `$metadata`; CDS view inspection |
| MD-3 | Which `GoodsMovementCode` and `GoodsMovementType` the CNF depot receipt uses | The whole create payload; field availability | Same gate as ID-1, plus MM configuration |
| MD-4 | Does the create response echo item numbers and posted quantities, or is a follow-up read needed? | `Allocations[].MaterialDocumentItem`, `PostedQuantity` | Local `$metadata` or an authorised sandbox call |
| MD-5 | `CtrlPostgForExtWhseMgmtSyst` must be blank for CNF; EWM-managed materials behave differently | Correct response object | MM/EWM configuration check in QS4 |
| MD-6 | `ReceiptStatus` and `RemainingQuantity` have no source in this service | Two mandatory v1.7 response fields | Decide the authoritative source — PO history, delivery, or a second service |
| MD-7 | Service is unregistered; ICF/alias state unknown | Everything runtime | Basis |
| MD-8 | Idempotency and per-allocation error shaping absent from the standard contract | v1.7 `RequestId` / `IsReplay` / `Errors[]` | CPI/T2 design, not SAP configuration |

**Shared gate with the inbound delivery family (open item ID-1):** does the QS4 STO flow create an inbound delivery at the receiving depot, and is the CNF goods receipt posted against a purchase order, an inbound delivery, or the dispatching outbound delivery? v1.7 says the reference is an outbound delivery. This service can express all three, so the gate does not disqualify it — but it does determine the payload, and it must be answered by configuration or a decision owner, never by inference.

## 11. Final disposition

| Scope | Status |
|---|---|
| API-01, **core posting** (allocated multi-SLoc GR returning the material-document key) | `DIRECT` — strongest candidate found so far |
| API-01, **complete v1.7 contract** including status, remaining quantity, idempotency, error shaping | `PARTIAL` — the remainder is CPI/T2 work, not SAP |
| Overall | **`CONDITIONAL-BUSINESS-GATE`** — gated on ID-1/MD-3 and on registration |
| QS4 runtime availability | Not registered; activation required |

**Not selected.** Selection requires ID-1 answered, registration and `$metadata` obtained, and the remaining Tier A comparators examined — `API_MATERIAL_STOCK`, `API_PRODUCT_AVAILY_INFO_BASIC` and `API_PHYSICAL_INVENTORY_DOC` are next in the handover sequence and none has been tested yet.

## 12. Matrix rows

Emitted to `CNF_STANDARD_API_MATRIX.tsv` per `MATRIX_SCHEMA.md`. Nineteen API-01 requirement rows for this candidate.

## 13. Evidence integrity — exporter defect found and fixed

The first grid export of this project **silently destroyed nine of fourteen grids.**

`sap_segw_export_all_grids.vbs` truncated output filenames to 70 characters. That was sufficient for the delivery projects, whose node paths are short. This project is SADL/CDS-exposed, so every model node sits under the ~70-character constant prefix `Data Model > Data Source References > Exposures via SADL > CDS-Entity Exposures > …`. All ten nodes beneath it truncated to the same filename and each export overwrote the previous one. The manifest recorded fourteen rows pointing at five physical files; reading it returned the last-written grid's contents under every node path.

**Fix applied** to `tmp/sap_segw_export_all_grids.vbs`: when the sanitised name exceeds 56 characters, keep the *distinguishing tail* prefixed by a deterministic hash of the full node path, and hard-guard every filename through a used-names dictionary that appends a counter on any residual collision.

**Audit of all existing evidence directories** — collisions found only here:

| Evidence directory | Manifest rows | Distinct files | Collisions |
|---|---:|---:|---:|
| `…_SEGW_API_OUTBOUND_DELIVERY` | 29 | 29 | 0 |
| `…_SEGW_API_OUTBOUND_DELIVERY_0002` | 52 | 52 | 0 |
| `…_SEGW_API_INBOUND_DELIVERY` | 29 | 29 | 0 |
| `…_SEGW_API_INBOUND_DELIVERY_0002` | 41 | 41 | 0 |
| `…_SEGW_API_MATERIAL_DOCUMENT` (before fix) | 14 | **5** | **10** |
| `…_SEGW_API_MATERIAL_DOCUMENT` (after fix) | 14 | 14 | 0 |

The delivery-family reports are unaffected. This project was re-exported into a cleaned directory, so no stale files remain. Handover §9.9's rule stands and is now safe to rely on: **the manifest is authoritative** — but from this point the manifest is also collision-free by construction.

Every future candidate with a `Data Source References` node will hit the same path depth. The fix is in the shared exporter, so it applies to all of them.
