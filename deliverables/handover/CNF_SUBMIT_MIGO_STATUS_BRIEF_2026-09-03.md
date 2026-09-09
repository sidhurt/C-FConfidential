# Submit MIGO — delivery-only goods receipt: status brief

**Date:** 2026-09-03 · **Systems:** DS4/200 (dev), QS4/700 (quality) · **Owner:** Siddharth

## The requirement

Post a MIGO goods receipt (movement type 101) from `Delivery` + `DeliveryItem` + `Plant` alone.
No purchase order supplied by the caller.

## Finding 1 — the standard service cannot do this, and we know exactly why

`API_MATERIAL_DOCUMENT_SRV` fails for **outbound** deliveries. This is not a configuration gap
or a missing authorisation. It is a branch in SAP's own mapping class.

`CL_MATERIAL_DOCUMENT_API=>MAP_ITEM_INPUT` (include `CM00V`, lines 34–48):

```abap
IF lo_delivery_handler->is_inbound_delivery( ).
  es_goodsmvt_item_input-deliv_numb_to_search = ir_item->delivery.
  es_goodsmvt_item_input-deliv_item_to_search = ir_item->deliveryitem.
ELSEIF lo_delivery_handler->is_outbound_delivery( ).
  es_goodsmvt_item_input-deliv_numb = ir_item->delivery.
  es_goodsmvt_item_input-deliv_item = ir_item->deliveryitem.
```

The `_TO_SEARCH` fields are what trigger PO resolution. They are populated for inbound deliveries
only. An outbound delivery is mapped to `DELIV_NUMB`/`DELIV_ITEM`, which land in `IMSEG-VBELN`
and `IMSEG-POSNR` — fields that identify a delivery but never cause SAP to go looking for the
purchase order behind it.

Result: `M7 030 Purchase order does not exist`. Reproduced in SE37 both ways.

**This is the finding of the week.** It converts "the standard API doesn't work" from an opinion
into a located, quotable defect in the delivered code.

## Finding 2 — the underlying BAPI *can* do it

`BAPI_GOODSMVT_CREATE` supports delivery-driven receipt without a PO. The resolution path is
`ME_CONFIRMATION_SEARCH_GR`, gated in `MB_CREATE_GOODS_MOVEMENT` (`LMBWLU14:1729`) on three
conditions:

- `IMSEG-VLIEF_AVIS` populated
- `IMSEG-KZBEW = 'B'`
- `IMSEG-EBELN` **initial** — supplying the PO directly *disables* delivery resolution

`LMBWLU14:2057` further proves `VBELP_AVIS` must carry `LIPS-POSNR` (not `UECHA`).

So the capability exists. Only the OData mapping layer withholds it.

## Finding 3 — the fix location is identified and proven

Call sequence inside `BAPI_GOODSMVT_CREATE` (`LMB_BUS2017U04`):

| Line | What happens |
|---|---|
| 223 | `MAP2I_B2017_GM_ITEM_TO_IMSEG` — BAPI item mapped to `IMSEG` |
| 385 | `APPEND t_imseg` |
| 546 | BAdI `MB_BAPI_GOODSMVT_CREATE` fires |
| 558 | Any message in `RETURN` aborts the posting |
| 632 | `PERFORM mb_create_goods_movement` — resolution and posting |

Both 223 and 546 sit **before** 632, so either can supply `VLIEF_AVIS`/`VBELP_AVIS` in time.

## Where we are

**BAdI route — closed.** `ZCNF_SUBMIT_MIGO` was built, activated, transported
(`DS4K964047`, `DS4K964062`, `DS4K964064`) and registered correctly: `BADI_IMPL` POS 7, spot
`MB_GOODSMOVEMENT`, `VERSION=A`, no filters, class includes active in QS4, source re-read from QS4
to confirm. A probe that raises an unconditional error as its **first statement** returned zero
messages. The method is never invoked. The cause is unresolved and is logged as an open question.
The implementation has been made inert and transported to QS4 — it is not armed.

**Enhancement route — next, and structurally safer.** An enhancement inside
`MAP2I_B2017_GM_ITEM_TO_IMSEG` is compiled into the function module itself. It does not depend on
the enhancement framework dispatching a registered implementation, which is precisely the layer
that failed silently for the BAdI. Different failure surface, fewer moving parts.

Planned: `ZCNF_SUBMIT_MIGO_MAP2I`, spot `ES_SAPLMB_BUS2017`, package `ZSCL`, built in DS4 and
transported. Code is written and reviewed; not yet created.

## Test data

STO `5600074803`, plant `1005`, storage location `RMYD`, material `14000035`,
deliveries `9004952595`–`9004952614` (18 items).
Register: `sessions/2026-09-02-migo-candidate-recheck/CANDIDATE_REGISTER.csv`.
Recheck `MSEG VBELN_IM=<delivery> BWART=101` immediately before use.

## Open items

1. Why the registered, active BAdI is never invoked. Unresolved. Does not block the enhancement.
2. `TESTRUN = 'X'` on this BAPI is shallow — it accepted `9999 TO` against a `41.230 TO`
   delivery without complaint. A clean `RETURN` under TESTRUN proves very little; only a real
   posting re-read from `MKPF`/`MSEG` counts.
3. Post-enhancement: verify `ZMMT_MIGO_HDR` is empty for the document. That absence is expected
   and is itself evidence the MIGO BAdIs did not run.

## Evidence

All source captured from QS4 and filed under
`sessions/2026-09-02-std-api-extension-feasibility/src/` —
`LMB_BUS2017U04`, `LMB_BUS2017U17`, `LMBWLU14`,
`CL_MATERIAL_DOCUMENT_API======CM00V`, `CL_MATERIAL_DOCUMENT_API======CM00D`.

Nothing in this brief is inferred. Every claim above cites a line of delivered SAP source or an
observed system result.
