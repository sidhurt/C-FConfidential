# Delivery and goods-issue customisation — first pass

**Date:** 2026-09-18
**Method:** re-analysis of `sessions/2026-09-02-migo-customisation-inventory/evidence/ENHOBJ_Z.txt`
(610 enhancement→object links, QS4/700, read 2026-09-02), filtered to delivery and
goods-movement objects.
**System access used:** none. This is derived entirely from evidence already captured.
**Subset:** `analysis/ENHOBJ_DELIVERY_GI.txt` — 64 rows.

---

> **Update 2026-09-18, after the SAP GUI sweep. See `FINDINGS.md`.** The evidence supersedes
> three statements below:
>
> - **Layer 4 reachability is now answered for the save exits.** The OData Create DI ran
>   `SAPMV50A` `USEREXIT_SAVE_DOCUMENT`. Proof: process order `003004365654` was created by
>   the unguarded `ZEI_LE_UPDATE_DELIVERY_HEAD` hook with `ABLAD 9004953174`.
> - **`ZSD_SHIP_CHECK` is not a shipment check.** It is a GSTIN-inactive check gated to
>   VL01N/VL02N. The name-based suggestion of a shipment prerequisite is Contradicted.
> - **"`ZEI_LE_UPDATE_DELIVERY_CUSTOM1` fired" is withdrawn as a strong inference.** It acts
>   only on `EXTENSION_IN`, which the OData call never supplies, so it cannot have had an
>   effect.
>
> The text below is kept as written for traceability.

## Headline

**24 distinct active Z-enhancements touch the delivery and goods-issue path.**

The v1.9 workbook classifies OF-06 Create PGI as `STANDARD-DIRECT` with
"No custom build required for this step." **That classification is not supported by this
evidence** and should be treated as provisional until the layer analysis below is completed.

This is the MIGO problem repeating on a different object. It was found the same way, and it
needs the same treatment before PGI can be called standard.

---

## The layer split

The enhancements do not sit in one place. Where they sit decides whether an external caller
reaches them. Four layers, in descending likelihood of being reached by OData:

### Layer 1 — Posting core: `MB_GOODSMOVEMENT` (2 implementations) — SOURCE READ, CLEARED

| Implementation | Interface | Class |
|---|---|---|
| `ZEI_MM_GOODSMVT_BAPI_CUSTOM` | `IF_EX_MB_BAPI_GOODSMVT_CREATE` | `ZCL_MM_GOODSMVT_BAPI_CUSTOM` |
| `ZMB_DOCUMENT_BADI` | `IF_EX_MB_DOCUMENT_BADI` | `ZCL_IM_ZEMPL_MB_DOC` |

**Source read 2026-09-18 from `sessions/2026-09-02-migo-customisation-inventory/src/`.
Neither implementation affects a delivery goods issue.** An earlier draft of this document
inferred that both would fire on PGI. That inference was wrong and is retracted.

**`ZCL_MM_GOODSMVT_BAPI_CUSTOM`** implements one method,
`if_ex_mb_bapi_goodsmvt_create~extensionin_to_matdoc`. That BAdI is specific to
`BAPI_GOODSMVT_CREATE` and fires only when a caller supplies `EXTENSIONIN`. **A delivery PGI
does not call that BAPI** — it posts through the delivery update path — so the method is not
reached.

Two further observations, relevant to how much weight this code can bear:

- Its only populated branch maps `EXTENSIONIN` structure `MSEG`, field `LSMNG`.
- That branch looks **defective**. Having matched `ls_extension-valuepart1 = 'LSMNG'`, it then
  reads `ct_imseg` with `line_id = ls_extension-valuepart1` — i.e. searching for a line whose
  id is the literal `'LSMNG'`. That will not match a real line id. *Hypothesis: dead code.*
  Worth confirming before anyone cites this BAdI as precedent for the CNF extension pattern,
  since Submit MIGO's proposed direction is a sibling of this exact BAdI.

**`ZCL_IM_ZEMPL_MB_DOC`** implements the generic material-document BAdI — the one that *does*
fire on any material document creation, including PGI. Both its methods are effectively inert
for us:

- `MB_DOCUMENT_BEFORE_UPDATE` is wrapped entirely in `IF sy-tcode = 'IFCU'`. An external OData
  call does not run under that transaction code, so the body cannot execute. Inside the guard
  it overwrites `MSEG-KOSTL` from parameter id `ZCOST` via a field-symbol assignment to
  `(SAPMM07M)XMSEG[]`.
- `MB_DOCUMENT_UPDATE` contains **nothing but a `BREAK` statement.**

Both methods also carry a hardcoded `BREAK ibmabap21` — a developer break-point for a named
user left in an active enhancement. Harmless in background and RFC contexts, but it is
leftover debug code sitting on the material-document posting path and should be raised.

**Consequence:** the posting layer is clear for PGI. This *strengthens* the case that PGI is
close to standard — but it says nothing about Layers 2–4, which is where delivery-specific
logic would live and where nothing has been read.

### Layer 2 — Delivery processing BAdI: `LE_SHP_DELIVERY_PROC` (6 implementations)

| Implementation | Class |
|---|---|
| `ZEI_LE_DELIVERY_PROCESS` | `ZCLLE_DELIVERY_PROCESS` |
| `ZENH_SHP_DELV_INTCO` | `ZCL_IM_LE_SHP_DELV_INTECO` |
| `ZLE_SHP_DELIVERY_PROC` | `ZCL_IM_LE_SHP_DELIVERY_PROC` |
| `ZSDEI_DELIVERY` | `ZCL_IM_SDEI_DELIVERY` |
| `ZSD_DELV_ATT_EHC` | — |
| `ZUCCSDE034_LIC_NOTIF` | — |

This is the delivery-processing BAdI in the LE-SHP core, not the dialog program. It is called
by the delivery processing framework. **Likely reached by the OData path, but the specific
methods implemented decide it** — `LE_SHP_DELIVERY_PROC` has many methods and some are
dialog-oriented.

**This tie is the same count as `MB_MIGO_BADI` had. Six implementations on one spot is not a
system anyone should call standard without reading them.**

### Layer 3 — Delivery creation BAdI: `ES_SAPLV50I_BADI` (2 implementations)

| Implementation | Interface | Path |
|---|---|---|
| `ZEI_LE_UPDATE_DELIVERY_CUSTOM` | `IF_DLV_CREATE_SLS_EXTIN` | sales order → delivery (**Trade / Non-trade**) |
| `ZEI_LE_UPDATE_DELIVERY_CUSTOM1` | `IF_DLV_CREATE_STO_EXTIN` | STO → delivery (**Create DI, STO path**) |

**This is the single most useful finding in this pass.**

`CURRENT_STATE.md` records that the STO Create DI path calls
`BAPI_OUTB_DELIVERY_CREATE_STO`. `ZEI_LE_UPDATE_DELIVERY_CUSTOM1` implements the STO
creation extension on that same path.

So Create DI — which we already executed successfully, producing delivery `9004953174` —
**very likely ran through client custom code.** We have never checked.

That makes it a decisive, free experiment: read the class, work out what it should have done,
then look at `9004953174` and see whether it did. **One document already exists, no
authorisation is required, and the answer tells us which layers the OData path actually
reaches.** See §"What to do first".

It also matters for pillar coverage: the sales-order variant is a *separate implementation*.
Trade and Non-trade go through different custom code than STO. That is a second, independent
reason those pillars cannot inherit STO's certification.

### Layer 4 — Delivery transaction runtime: `SAPMV50A` / `MV50AFZ1` / `SAPFV50C` (13 implementations)

| Implementation | Include | Name suggests |
|---|---|---|
| `ZSD_SHIP_CHECK` | `MV50AFZ1` | **a shipment check** |
| `ZSD_DEL_SAVE_CHECK` | `MV50AFZ1` | a save-time check |
| `ZEI_LE_VALIDATE_TRANSPOTER` | `MV50AFZ1` | transporter validation |
| `ZEI_LE_VALIDATE_YSTO` | `MV50AFZ1` | YSTO validation |
| `ZSD_RESTRICT_GRN` | `MV50AFZ1` | a GRN restriction |
| `ZZ_LE_BIDDING_QTY` | `MV50AFZ1` | quantity logic |
| `ZEI_SD_UPDATE_DELBILLINGTYPE` | `MV50AFZ1` | billing type determination |
| `ZEI_LE_UPDATE_DELIVERY_HEAD` | `MV50AFZ1` | header updates |
| `ZZCRM_DI_SEND` | `MV50AFZ1` | CRM/portal outbound |
| `ZEI_SD_CHANGE_CALC_TPE` | `MV50AF0P_PREISFINDUNG_GESAMT` | pricing |
| `ZEI_LE_ADD_CHECK_BUTTON_HEAD` | `MV50AF0C_CUA_SETZEN` | screen/CUA — dialog only |
| `ZEI_LE_ADD_CHECK_BUTTON_PAI` | `MV50AF0F_FCODE_BEARBEITEN` | screen/CUA — dialog only |
| `ZSDENH_CLEAR_SHIPPING_DATA` | `SAPFV50C` / `FV50C002` | clears shipping data |

`MV50AFZ1` is the classic delivery user-exit include. **Whether these fire through an OData
or BAPI caller is NOT determinable from the registry** — it depends on which routine each
plug-in sits in. Some `MV50AFZ1` exits are invoked from delivery processing generally; the
CUA and screen ones are dialog-only by construction.

**Do not assume either way.** `ENHINCINX` gives the exact routine each plug-in sits in and was
flagged as unpulled in the September sweep. That is the query that settles it.

`ZSD_SHIP_CHECK` is worth naming separately. The name is consistent with — though it does not
prove — a client rule requiring a shipment. That is exactly the rule discussed as the possible
non-standard dependency between PGI and the freight chain. **Read it.**

### Layer 5 — Function group `V50S` (1)

`ZENH_SD_CHANGE_BILLTYP` touches `LV50SF09` and `FV50XF0B_IBDLV_OBDLV_DOCFLOW` — delivery
document flow. Relevant to what PGI writes into `VBFA`.

---

## What this does and does not establish

**Verified:** 24 active Z-enhancements exist on delivery and goods-movement objects in
QS4/700, distributed across five layers as above. Registry evidence, read 2026-09-02.

**Verified (source read 2026-09-18):** neither `MB_GOODSMOVEMENT` implementation affects a
delivery goods issue. One is `BAPI_GOODSMVT_CREATE`-specific and unreachable from PGI; the
other is gated on `sy-tcode = 'IFCU'` in one method and empty in the other. **The posting
layer is clear.** This retracts the earlier inference that both would fire.

**Strong inference:** `ZEI_LE_UPDATE_DELIVERY_CUSTOM1` fired during Create DI on
`9004953174`, because it implements the STO creation extension on the BAPI that path uses.

**Unknown:** what the other 22 do. Only the two posting-layer classes have been read. No
`LE_SHP_DELIVERY_PROC`, `ES_SAPLV50I_BADI` or `MV50AFZ1` source has been captured — the
September extraction covered the MIGO family only.

**Unknown:** which of the 13 transaction-layer plug-ins, if any, are reachable from outside
the dialog.

**Contradicted:** the v1.9 OF-06 disposition "No custom build required for this step" — not
because it is proven wrong, but because it was written without this evidence and cannot stand
on what it cites.

---

## What to do first — no authorisation needed

Ordered by value per hour. None of this needs the QS4 write window.

### 1. Read `ZEI_LE_UPDATE_DELIVERY_CUSTOM1`, then check `9004953174` against it

The decisive experiment, and it costs one class read.

We have a delivery created through OData on a path that carries a client BAdI implementation.
Read `ZCLLE_UPDATE_DELIVERY_CUSTOM1` (`IF_DLV_CREATE_STO_EXTIN`), determine what it writes,
then read `9004953174` and see whether it is there.

- **Its effect is present** → the OData path reaches client BAdI code. The whole "standard
  service" framing needs revisiting, and the same question applies to PGI.
- **Its effect is absent** → the OData path bypasses it, exactly as `BAPI_GOODSMVT_CREATE`
  bypasses the MIGO-runtime BAdIs. The scope question becomes "what is in the 24 that the
  business needs, and how do we reach it."

Either answer is worth more than a PGI post.

### 2. Read the two `MB_GOODSMOVEMENT` classes — already on disk

`ZCL_MM_GOODSMVT_BAPI_CUSTOM` and `ZCL_IM_ZEMPL_MB_DOC` are already extracted under
`sessions/2026-09-02-migo-customisation-inventory/src/`. They were captured for the MIGO
investigation and never read with PGI in mind.

**Zero SAP access. Read them today.** They are the enhancements most likely to fire on PGI.

### 3. Read `ZSD_SHIP_CHECK` and `ZSD_DEL_SAVE_CHECK`

Directly addresses whether the client has coded a shipment or settlement prerequisite that
standard SAP does not impose. If such a rule exists, it is most likely in one of these.

### 4. Pull `ENHINCINX` for the 13 transaction-layer plug-ins

Gives the exact program, include and routine each sits in. That is what decides whether an
external caller reaches them. Flagged as unpulled since 2026-09-02.

### 5. Complete the registries the September sweep left open

`MODATTR` (are the CMOD projects active), the `Y*` namespace (only `Z*` was swept — a `Y`
enhancement on the delivery path would be invisible today), BTEs (`TBE01`/`TBE31`/`TPS34`),
validations and substitutions (`GB01`/`GB92`), and output determination.

**The `Y*` gap matters.** The current 24 is a floor, not a total.

---

## Consequence for the plan

`PLAN.md` in this session treats the PGI post as the next step. That ordering stands, but its
justification changes: the post is **certification**, not scope discovery. The five items above
are what determine scope, and none of them is blocked.

The authorisation request should stay in flight. It is no longer the critical path.

---

## Evidence

- `analysis/ENHOBJ_DELIVERY_GI.txt` — the 64-row filtered subset, derived from
  `sessions/2026-09-02-migo-customisation-inventory/evidence/ENHOBJ_Z.txt`
- Source registry: `ENHHEADER_Z.txt` (242 active `Z*` enhancements), `ENHOBJ_Z.txt` (610
  enhancement→object links), both QS4/700, 2026-09-02, read-only
- Method: `sessions/2026-09-02-migo-customisation-inventory/FINDINGS.md` — the nine-registry
  approach, reused unchanged
