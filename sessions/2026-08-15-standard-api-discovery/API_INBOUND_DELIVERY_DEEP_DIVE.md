# Deep dive — `API_INBOUND_DELIVERY` (sibling baseline)

**Date:** 2026-08-15
**System:** QS4 / client 700 / user QNOVATE8, read-only SEGW
**Tier A rank:** 4
**Role:** required baseline for the inbound sibling delta
**Final disposition:** `KEEP-SIBLING-BASELINE`

This project exists in the deep-dive set to make the `_0002` comparison mechanical, as handover §11 requires. It is not a separate candidate. Full comparison: `INBOUND_DELIVERY_DELTA.md`. Business analysis: `API_INBOUND_DELIVERY_0002_DEEP_DIVE.md`.

---

## 1. Project identity

| Attribute | Value |
|---|---|
| Project | `API_INBOUND_DELIVERY` |
| Catalogue description | Remote API for Inbound Delivery |
| Created by / on | SAP / 20.06.2017 |
| Last changed on | 29.01.2021 |

Evidence directory: `sources/SRC-SYS-20260815-04_QS4_700_SEGW_API_INBOUND_DELIVERY/`
Tree rows: 1,117 total, of which the target project's rows are those with `Path` equal to `API_INBOUND_DELIVERY` or prefixed `API_INBOUND_DELIVERY > `. The remainder belong to the other roots open in the same workbench.
Grid manifest rows: 29.

## 2. Runtime identity

| Attribute | Value | Evidence |
|---|---|---|
| Model | `API_INBOUND_DELIVERY_MDL` | `LOCAL-DESIGN` |
| Service (TADIR object) | `API_INBOUND_DELIVERY_SRV` | `LOCAL-DESIGN` |
| Version selector | `;v=1` | `INFERENCE` — `;v=2` is documented for the `_0002` generation and this is the earlier one |
| DPC / DPC_EXT | `CL_API_INBOUND_DELIVER_DPC` / `_DPC_EXT` | `LOCAL-DESIGN` |
| MPC / MPC_EXT | `CL_API_INBOUND_DELIVER_MPC` / `_MPC_EXT` | `LOCAL-DESIGN` |

The unsuffixed class family belongs to the **base** project here. In the outbound family it belongs to `_0002`. Class names carry no version meaning.

## 3. Model counts

| Surface | Count |
|---:|---:|
| Entity types | 7 |
| Entity sets | 7 |
| Complex types | 2 |
| Associations | 6 |
| Association sets | 6 |
| Function imports | 6 |
| Runtime artifacts | 6 |

## 4. Entity-set operation matrix

| Entity set | Creatable | Updatable | Deletable | Pageable | Addressable | Searchable |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `A_InbDeliveryHeader` | X | X | X | X | X | X |
| `A_InbDeliveryItem` | | X | X | X | X | X |
| `A_InbDeliveryDocFlow` | | X | | | | |
| `A_InbDeliveryAddress` | | | | | | |
| `A_InbDeliveryPartner` | | | | | | |
| `A_InbDeliverySerialNmbr` | | | | | | |
| `A_MaintenanceItemObjList` | | | | | | |

Identical to `_0002` on every shared entity set. No CRUD annotation changed between the generations.

## 5. Function-import matrix

All six are `POST` and all are retained unchanged in `_0002`.

| Function import | Action for | Returns | Parameters |
|---|---|---|---|
| `PostGoodsReceipt` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument` |
| `ReverseGoodsReceipt` | `A_InbDeliveryHeaderType` | `DeliveryMessage` | `DeliveryDocument`, `ActualGoodsMovementDate` |
| `PutawayAllItems` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument` |
| `PutawayOneItem` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem` |
| `ConfirmPutawayAllItems` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument` |
| `ConfirmPutawayOneItem` | `A_InbDeliveryHeaderType` | `PutawayReport` | `DeliveryDocument`, `DeliveryDocumentItem` |

`PutawayOneItem` and `ConfirmPutawayOneItem` are bound to the **header** type here; `_0002` rebinds both to the item type. Parameters are unchanged.

## 6. Business-critical property mapping

Creatable and updatable sets are identical to `_0002` except that `_0002` adds `DeliveryDocumentItemBySupplier` and nine product-attribute properties to the item as read-only fields. `StorageLocation` is read-only in this generation too, so the API-01 storage-location gap is not a `_0002` regression — it has never been writable in this family.

The only header property added in `_0002` is `ReceivingLocationTimeZone`. Six shared header properties and one property each on `A_InbDeliverySerialNmbrType` and `A_MaintenanceItemObjListType` changed contract columns; none affects a field CNF needs.

## 7. v1.7 coverage matrix

Identical to `_0002` on every API-01 requirement, and strictly narrower elsewhere. `NO FIT` for API-01 **used alone**, for the same reasons: no allocation input, no writable storage location, no material-document key in any return shape. The same `PutawayReport`-versus-empty-response conflict (`_0002` deep dive §5.1, open item ID-2) applies here unchanged and is likewise **unresolved**.

Within the broader receiving process this generation is `CONDITIONAL` on the same STO document-flow gate, but it is strictly dominated by `;v=2`, so the conditional role belongs to the sibling, not to this project.

## 8. API identity versus local runtime availability

| Question | Answer | Class |
|---|---|---|
| Does SAP publish this generation for 2022? | No separate 2022 page exists; only the `_0002` generation is documented. | `SAP-OFFICIAL` |
| Does the project exist in QS4 design time? | Yes. | `LOCAL-DESIGN` |
| Is the service registered and callable in QS4? | **No.** `API_INBOUND_DELIVERY_SRV` is absent from the 522-row Gateway catalogue at any version. | `LOCAL-RUNTIME` |
| ICF node / system alias active? | Unknown. | — |

## 9. Official SAP confirmation

`SAP-OFFICIAL`. SAP's S/4HANA 2022 on-premise documentation describes only the `_0002` generation (`;v=2`), whose entity list includes the header and item text entities this project lacks. There is no separate 2022 documentation page for the `;v=1` generation.

`INFERENCE` — explicitly labelled, not fact: the base generation appears superseded for this release. It is **not** proven deprecated; SAP publishes no deprecation notice for it. The absence of a documentation page is weaker evidence than a deprecation statement would be.

## 10. Gaps and decisions

No decision rests on this project. Its purpose was to make the `_0002` delta mechanical, and it has done that. Do not carry it into the activation list.

## 11. Final disposition

**`KEEP-SIBLING-BASELINE`.** Retained as comparison evidence only. `API_INBOUND_DELIVERY_0002` (`;v=2`) is the generation of record for the family. Neither generation satisfies API-01 on its own, and the family's broader receiving-side role remains open — see open item ID-1 in the `_0002` deep dive.
