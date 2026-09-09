# MIGO customisation — disposition and architectural handling

**Date:** 2026-09-04 · **System observed:** QS4/700 · **Method:** read-only SE16 / source display
**Scope:** every enhancement, exit and custom behaviour on the goods-movement path, and where each
must be handled for the C&F Agent interface.

**Constraint accepted:** no custom services. Everything is handled by `BAPI_GOODSMVT_CREATE` and
its supported extension points.

---

## 1. The finding in one paragraph

Shree Cement's MIGO customisation is split across two different entry paths. The MIGO
**transaction** and `BAPI_GOODSMVT_CREATE` are separate programs that converge on a shared posting
core. Custom code attached to the transaction runs only when a person uses the screen; custom code
attached to the posting core runs for both. **Of the 13 customisations enumerated on this path, 8
are reachable only from the MIGO screen and will never execute for an API caller.** Those 8 include
every delivery-quantity, storage-location and billing-status validation the business currently
relies on. Testing through the BAPI therefore exposes the posting-core behaviour only — it cannot
surface these, and their absence is silent.

---

## 2. Why the split exists — proven from the client's own code

`ZCLMM_MB_MIGO_BADI` reads the MIGO dialog program's global memory directly:

```abap
ASSIGN ('(SAPLMIGO)GOHEAD')   TO <ls_goheader>.
ASSIGN ('(SAPLMIGO)GODYNPRO') TO <ls_godyn>.
IF sy-subrc = 0.
  ...all validations live inside here...
ENDIF.
```

`SAPLMIGO` is the MIGO dialog program. When `BAPI_GOODSMVT_CREATE` is called from OData, CPI or
SE37, `SAPLMIGO` is not in the call stack, the `ASSIGN` fails, `sy-subrc = 4`, and **the entire
validation block is skipped without any message.**

The same holds for the class attributes `gv_action` and `gv_refdoc`, which gate the delivery-based
checks in `POST_DOCUMENT`:

```abap
IF gv_action = 'A01' AND gv_refdoc = 'R05'.   " A01 = goods receipt, R05 = outbound delivery
```

Both are populated by method `MODE_SET`, which is called by the MIGO dialog only. On a BAPI call
they remain empty and every dependent check is bypassed.

This is not inference. It is the gating condition, in their code, on the methods that carry the
validations.

---

## 3. Disposition table

**Legend — A** inherited, fires already · **B** must be re-implemented for the API ·
**C** dialog-only, correctly out of scope · **D** dormant / no effect

| # | Customisation | Dispatch point | What it does | Fires on BAPI path | Disp. |
|---:|---|---|---|:---:|:---:|
| 1 | `ZEI_MM_MB_MIGO_BADI`<br>`ZCLMM_MB_MIGO_BADI` | `MB_MIGO_BADI` | 20 methods. Carries all delivery GR validations (§4) and writes `ZMMT_MIGO_HDR` | **No** | **B** |
| 2 | `ZMM_SEND_MAIL`<br>`ZCL_IM_MM_SEND_MAIL` | `MB_MIGO_BADI~LINE_MODIFY` | Batch check against `ZFITPCBATCH`; also gated `sy-tcode = 'MIGO'` | **No** | **B** |
| 3 | `ZDACE_CUSTOM_MIGO_HEADER_TAB` | `MB_MIGO_BADI` | Custom MIGO header screen tab (PBO / status / publish) | **No** | **C** |
| 4 | `ZDACE_CUSTOM_MIGO_HEADER_TAB_N` | `MB_MIGO_BADI` | Second header-tab implementation | **No** | **C** |
| 5 | `ZEI_MM_DELIVERY_NOTE` | `MB_MIGO_BADI` | Delivery-note handling — *source not yet read* | **No** | **B?** |
| 6 | `ZIML_CAN_CHECK` | `MB_MIGO_BADI` | Cancellation check — *source not yet read* | **No** | **C?** |
| 7 | `ZDACE_MODIFY_MIGO_ITEM_QTY` | plug-in in `LMIGOKC2` | Item quantity modification — *source not yet read* | **No** | **B?** |
| 8 | `ZMM_MIGO_DATA_CHECK` | plug-in in `LMIGOKG1` | Data check — *source not yet read* | **No** | **B?** |
| 9 | `ZEI_MM_GOODSMVT_BAPI_CUSTOM`<br>`ZCL_MM_GOODSMVT_BAPI_CUSTOM` | `MB_BAPI_GOODSMVT_CREATE`<br>`EXTENSIONIN_TO_MATDOC` | Maps `EXTENSION_IN` rows onto `IMSEG`. Only acts if the caller supplies `EXTENSION_IN` with structure `MSEG`, field `LSMNG`. Otherwise a no-op | Yes | **A** |
| 10 | `ZMB_DOCUMENT_BADI`<br>`ZCL_IM_ZEMPL_MB_DOC` | `MB_DOCUMENT_BADI` | Cost-centre override — gated `sy-tcode = 'IFCU'`. `MB_DOCUMENT_UPDATE` is empty | Yes (no effect) | **D** |
| 11 | `ZCL_IM_SDEI_ML81N_REFER` | `MB_CHECK_LINE_BADI` | Gated `sy-tcode = 'ML81N'`, body empty | Yes (no effect) | **D** |
| 12 | `ZPP_COR6_RMC` | plug-in in FG `MBWL` | *Source not yet read* | Yes | **A?** |
| 13 | `ZMM_RESE` → `MBCF0007` | CMOD customer exit | Reservation update. Activation unconfirmed (`MODATTR`) | Yes | **A?** |

**Reachable from the API: 5 of 13, and 3 of those have no effect.** The customisation that carries
business meaning for a delivery-based goods receipt is entirely in rows 1–8.

---

## 4. The validations that will not fire

All are in `ZCLMM_MB_MIGO_BADI`, methods `CHECK_ITEM` and `POST_DOCUMENT`. Message class `ZMM`.

| Msg | Text | Trigger condition |
|---|---|---|
| `ZMM 068` | Invoice not created/Cancelled for outbound Delivery & | GR against outbound delivery where no `VBRP`/`VBRK` exists with `VGBEL` = delivery and `RFBSK <> 'E'` |
| `ZMM 067` | GRN quantity exceeds delivery & quantity | Sum of current items plus already-posted `MATDOC` 101/102 for that delivery item exceeds `LIPS-LFIMG` |
| `ZMM 070` | GRN quantity should be equal to delivery & quantity | `LIKP-VSART = '03'` (rail) and `LIPS-MFRGR = 'A0000001'` — partial receipt forbidden, must match exactly |
| `ZMM 075` | Receiving storage location must be RSD | `LIKP-VSART = '03'` and `LIPS-MFRGR = 'A0000001'` and `LGORT <> 'RSD'`. Applies to deliveries with `LIPS-ERDAT >= 20240723` |
| `ZMM 074` | Receiving storage location must be GDRK | `LIPS-LGORT = 'GDRK'` and the GR storage location differs |
| `ZMM 077` | Po reference not allowed please use outbound delivery | GR **with PO reference** where `EKPO-MFRGR = 'A0000001'` and `EKKO-BSART = 'ZP06'` |
| — | Kindly enter AFR Manifest no. / date / waste category | Material type `ZAFR` on movement 101/103, unless the company code is exempted in `ZGPT_MM_PARAM` (`AFR` / `BUKRS`) |
| — | Service entry sheet & exists for this Material Document | On cancellation, where `ZMMT_MIGO_SERV` holds an entry for the reversed document |

### Two of these deserve the client's attention immediately

**`ZMM 077` is the requirement, already implemented.** The business rule *"do not receive against
the PO, use the outbound delivery"* already exists in this system and is enforced at the MIGO
screen. The C&F interface is being asked to do exactly what this rule mandates — and the rule
itself will not travel to the API path. The API must be correct by construction, because nothing
will stop it being wrong.

**`ZMM 074` / `ZMM 075` conflict with the current spike default.** The Submit MIGO enhancement
currently defaults the receiving storage location to `RMYD` when the caller omits it. Their rules
require `RSD` or `GDRK` under specific rail / material-group conditions. Either the API must make
storage location a mandatory input, or it must reproduce this derivation. **A hardcoded default is
not safe.** This needs confirming against the candidate deliveries before any real posting.

---

## 5. Configuration switches

Behaviour is not fixed in code alone. `ZGPT_MM_PARAM` gates it at runtime:

| `PROGRAM_NAME` | `OBJECT_ID` | `FIELD` | Effect |
|---|---|---|---|
| `MB_MIGO_BADI` | `STO` | `REFDOC` | When active, the **entire** outbound-delivery validation block in `CHECK_ITEM` is bypassed |
| `MB_MIGO_BADI` | `AFR` | `BUKRS` | Company codes exempt from AFR manifest checks |

Also relevant: `TVARVC` variable `ZPP_FG_TO_LOSE_MVTYP` drives the batch check in `ZMM_SEND_MAIL`.

Any statement about which validations are "active" must be read together with these tables. Their
current contents have not been captured — see §8.

---

## 6. Architectural recommendation

The constraint is no custom services, everything via the BAPI and its extensions. That is
satisfiable. The BAPI's supported extension surface, in call order:

| Point | Where | Suitable for |
|---|---|---|
| Enhancement in `MAP2I_B2017_GM_ITEM_TO_IMSEG` | `LMB_BUS2017U17`, called at `LMB_BUS2017U04:223` | **Derivation** — filling fields before mapping completes |
| BAdI `MB_BAPI_GOODSMVT_CREATE~EXTENSIONIN_TO_MATDOC` | `LMB_BUS2017U04:546` | Derivation and abort. One message slot only |
| BAdI `MB_CHECK_LINE_BADI~CHECK_LINE` | posting core | **Validation** — multiple messages, per line |
| BAdI `MB_DOCUMENT_BADI~MB_DOCUMENT_BEFORE_UPDATE` | posting core, pre-update | Late field changes |

**Recommended shape — extract, don't duplicate.**

1. Lift the validation logic out of `ZCLMM_MB_MIGO_BADI` into a **new reusable class**, e.g.
   `ZCL_CNF_GR_DELIVERY_RULES`, with one method per rule, taking plain parameters (delivery, item,
   quantity, storage location, plant) and returning `BAPIRET2`.
2. Have the **existing MIGO BAdI call that class** instead of holding the logic inline. Screen
   behaviour is unchanged; the code simply moves.
3. Have the **BAPI-path extension call the same class**. Both entry paths then enforce one
   implementation of the rule.

This is the answer to *"where should these be handled architecturally"*: **in a layer below both
dispatch points, called by each.** It requires no custom service, keeps the dialog behaviour
intact, and removes the risk of the API and the screen drifting apart — which is otherwise
guaranteed the first time a rule changes.

**Where to attach the validation call.** `MB_CHECK_LINE_BADI` is the better host than the BAPI
BAdI: `CT_RETURN` on `EXTENSIONIN_TO_MATDOC` is a **single `BAPIRET2` structure, not a table**
(`LMB_BUS2017U04:558` aborts on any message), so it can surface only one error per call.
Validation that needs to report several failures belongs in `MB_CHECK_LINE_BADI`.

**Derivation stays separate.** Delivery-to-PO resolution (the `VLIEF_AVIS` / `VBELP_AVIS` mapping)
is not a validation and belongs in the `MAP2I` enhancement, which runs earliest.

---

## 7. Answering the client's premise directly

> *"Testing through the BAPI would expose all the validations involved."*

**Partly true, and the untrue part is the load-bearing one.** BAPI testing exercises the standard
posting core and rows 9–13 above. It cannot exercise rows 1–8, because those are gated on dialog
program globals that do not exist on an API call. A clean BAPI test result is therefore evidence
that the posting core accepted the document — not evidence that the business rules were satisfied.

The correct method is the one used to produce this document: enumerate from the enhancement
registries (`ENHHEADER`, `ENHOBJ`, `MODACT`, `SXC_EXIT`, `SMODILOG`), read each implementation's
source, and classify by dispatch point. Runtime testing then **confirms** the classification; it
cannot discover it.

---

## 8. Open items

1. **Source not yet read** — rows 5, 6, 7, 8, 12. Four are dialog-side and may carry rules;
   dispositions marked `?` are provisional until read.
2. **`ZGPT_MM_PARAM` contents not captured.** The `STO` / `REFDOC` switch can disable the entire
   outbound-delivery validation block. Its current value materially changes §4.
3. **`MODATTR` not confirmed** — CMOD project `ZMM_RESE` activation status unknown.
4. **Storage-location rule vs. candidate deliveries.** Confirm whether deliveries
   `9004952595`–`9004952614` carry `LIKP-VSART = '03'` and `LIPS-MFRGR = 'A0000001'`. If they do,
   `RSD` is required and the spike's `RMYD` default is wrong.
5. **Not swept:** `Y*` namespace, BTEs (`TBE01` / `TBE31` / `TPS34`), validations and substitutions
   (`GB01` / `GB92`), output determination. The denominator of 13 may grow.
6. **Unresolved:** `ZCNF_SUBMIT_MIGO`, registered and active on `MB_BAPI_GOODSMVT_CREATE`, was
   never invoked at runtime. Cause unknown. Note that row 9 sits on the same BAdI and is a no-op
   unless `EXTENSION_IN` is supplied — so passing an `EXTENSION_IN` row with structure `MSEG` and
   field `LSMNG` is a clean independent test of whether that BAdI dispatches at all.

---

## 9. Evidence

`sessions/2026-09-02-migo-customisation-inventory/`

- `evidence/` — `ENHHEADER_Z.txt` (242 rows), `ENHOBJ_Z.txt` (610), `MODACT_ALL.txt`,
  `SXC_EXIT_MB_MIGO_BADI.txt`, `SMODILOG_M.txt`, `T100_ZMM.txt`, `BADI_IMPL_MB.txt`
- `src/` — 32 method sources, read from QS4 via SE24 / SE80 display

`sessions/2026-09-02-std-api-extension-feasibility/src/` — `LMB_BUS2017U04`, `LMB_BUS2017U17`,
`LMBWLU14`, `CL_MATERIAL_DOCUMENT_API======CM00V`, `CM00D`

Every claim in this document cites a line of source read from QS4/700 or a row read from a registry
table in that system. Nothing was posted, activated or changed to produce it.
