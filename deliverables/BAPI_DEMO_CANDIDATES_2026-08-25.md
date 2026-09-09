# BAPI demo candidates — QS4/700

**Selected read-only on 2026-08-25. System/client: QS4/700. User: QNOVATE8.**

No BAPI was executed during candidate selection. Recheck every candidate immediately before
execution because QS4 is shared and another user or job can consume open quantity.

## Allocation

| Scenario | Use | BAPI | Predecessor |
|---|---|---|---|
| Create DI | Rehearsal / execute now | `BAPI_OUTB_DELIVERY_CREATE_STO` | STO `5600084222`, item `00010` |
| Create DI | **Reserved for tomorrow — do not touch** | `BAPI_OUTB_DELIVERY_CREATE_STO` | STO `5600084223`, item `00010` |
| Submit MIGO | Rehearsal / execute now | `BAPI_GOODSMVT_CREATE` | STO `5600074808/00010`, delivery `9004952821/000010` |
| Submit MIGO | **Reserved for tomorrow — do not touch** | `BAPI_GOODSMVT_CREATE` | STO `5600084246/00010`, delivery `9004953161/000010` |

## Create DI candidate A — rehearsal now

- STO/item: `5600084222/00010`
- `SHIP_POINT`: `1002`
- `DUE_DATE`: `20.08.2026` from `EKET-EINDT`
- Material: `14000035`
- Receiving plant: `1022`
- PO quantity: `1000 TO`
- Existing delivery: `9004953191/000010`, `50 TO`, goods-movement status `A`
- Remaining delivery capacity: `950 TO`
- Recommended demonstration quantity: `1 TO`
- Header/item deletion flags blank; item category `7`; `EKET-WEMNG = 0`

`STOCK_TRANS_ITEMS`:

| Field | Value |
|---|---|
| `REF_DOC` | `5600084222` |
| `REF_ITEM` | `00010` |
| `DLV_QTY` | `1` |
| `SALES_UNIT` | `TO` |

## Create DI candidate B — reserved for tomorrow

- STO/item: `5600084223/00010`
- `SHIP_POINT`: `1002`
- `DUE_DATE`: `20.08.2026` from `EKET-EINDT`
- Material: `14000035`
- Receiving plant: `1023`
- PO quantity: `1000 TO`
- Existing delivery: `9004953192/000010`, `50 TO`, goods-movement status `A`
- Remaining delivery capacity: `950 TO`
- Recommended demonstration quantity: `1 TO`
- Header/item deletion flags blank; item category `7`; `EKET-WEMNG = 0`

`STOCK_TRANS_ITEMS`:

| Field | Value |
|---|---|
| `REF_DOC` | `5600084223` |
| `REF_ITEM` | `00010` |
| `DLV_QTY` | `1` |
| `SALES_UNIT` | `TO` |

## Submit MIGO candidate A — rehearsal now

- STO/item: `5600074808/00010`
- Delivery/item: `9004952821/000010`
- Material: `14000035`
- Receiving plant: `1006`
- Receiving storage location for the test: `RMYD`
  - `EKPO-LGORT` is blank.
  - All 500 sampled historical 101 rows for this material/plant used `RMYD`.
- PO schedule: `500000 TO`; `EKET-WEMNG = 141994.020`; substantial PO receipt capacity remains.
- PGI material document exists; movement `641` is persisted.
- Delivery `9004952821` is fully goods-issued (`LIPS-WBSTA = C`).
- Exact query for movement `101` + delivery `9004952821` returned no rows.

Recommended rehearsal: one `GOODSMVT_ITEM` row with movement `101`, `MVT_IND = B`,
`STGE_LOC = RMYD`, `ENTRY_QNT = 45.610`, `ENTRY_UOM = TO`, PO/item
`5600074808/00010`, and delivery/item `9004952821/000010`.

## Submit MIGO candidate B — reserved for tomorrow

- STO/item: `5600084246/00010`
- Delivery/item: `9004953161/000010`
- Material: `12000009`
- Receiving plant/storage location: `1025/RMYD`
- Quantity: `52.330 TO`
- PO schedule: `10000 TO`; current `EKET-WEMNG = 50.750`
- Delivery item is fully goods-issued (`LIPS-WBSTA = C`) and carries movement `641`.
- Exact query for movement `101` + delivery `9004953161` returned no rows.
- This is the preferred live-presentation candidate: one non-batch delivery item, explicit
  receiving storage location, and a direct PO/delivery relationship.

`GOODSMVT_HEADER`:

| Field | Value |
|---|---|
| `PSTNG_DATE` | presentation date, provided period `2026/05` remains open |
| `DOC_DATE` | presentation date |
| `REF_DOC_NO` | `9004953161` |
| `HEADER_TXT` | e.g. `CNF BAPI DEMO` |

`GOODSMVT_CODE-GM_CODE = 01`.

`GOODSMVT_ITEM`:

| Field | Value |
|---|---|
| `MOVE_TYPE` | `101` |
| `MVT_IND` | `B` |
| `STGE_LOC` | `RMYD` |
| `ENTRY_QNT` | `52.330` |
| `ENTRY_UOM` | `TO` |
| `PO_NUMBER` | `5600084246` |
| `PO_ITEM` | `00010` |
| `DELIV_NUMB` | `9004953161` |
| `DELIV_ITEM` | `000010` |

## Non-negotiable execution sequence

For either BAPI:

1. Execute the BAPI in an SE37 test sequence.
2. Capture the complete `RETURN` table and returned document key.
3. If any `E` or `A` message exists, run `BAPI_TRANSACTION_ROLLBACK`; do not commit.
4. Otherwise run `BAPI_TRANSACTION_COMMIT` with `WAIT = X` in the same sequence.
5. Independently re-read persistence:
   - Create DI: `LIKP` and `LIPS`, including `LIPS-VGBEL/VGPOS`.
   - Submit MIGO: `MKPF`, `MSEG`, and `EKET-WEMNG`; verify both PO and delivery references.

## Evidence produced during selection

- `tmp/bapi_candidate_ekko_8400_4300.tsv`
- `tmp/bapi_candidate_ekpo_8400_4300.tsv`
- `tmp/bapi_candidate_eket_8400_4300.tsv`
- `tmp/bapi_candidate_mseg_641_recent_deliveries.tsv`
- `tmp/bapi_candidate_mseg_101_recent_deliveries.tsv`
- `tmp/bapi_candidate_lips_9004953077.tsv`
- `tmp/bapi_candidate_lips_9004952821.tsv`
- `tmp/bapi_candidate_lips_9004953161.tsv`
