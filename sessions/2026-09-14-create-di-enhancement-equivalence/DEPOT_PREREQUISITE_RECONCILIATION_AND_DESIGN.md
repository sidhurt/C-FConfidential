# `ZLEF_DELIVERY_VALIDATONS` — reconciliation and API-path design

**Captured:** 2026-09-15, QS4/700, SE37 display, read-only.
**Evidence:** `source-captures/2026-09-15-QS4-scripted/ZLEF_DELIVERY_VALIDATONS.txt`
**Editor setting** re-enabled for capture and restored to baseline, verified field-by-field.

## 1. What it is

The function module's own header comment settles the screenshot question:

```
"*   IV_CALLED_FROM 'B' BADI , 'C'  Check Button
```

So the **"Depo Pre-requisite's" button passes `'C'`**, and the BAdI passes `'B'`. Same rule
engine, two callers. `IV_CALLED_FROM` controls **presentation only** — with `'B'` the result is
returned silently in `EV_ERROR_OCCURED`; with anything else an ALV popup lists the failures.

**Depot gate:** the first non-deleted item's plant must resolve to `KNA1-KDKG1 = 'A2'` via
customer `P<WERKS>`, otherwise the FM returns immediately. Depot-only, always.

## 2. The rules inside (all new — none previously catalogued)

| Ref | Rule | Fields read | Message |
|---|---|---|---|
| **P1** | Every batch-managed main item must have a batch-split sub-item | `MARA-XCHPF`, `LIPS-UECHA` | TEXT-E01 |
| **P2a** | SPI must be filled | `LIKP-SDABW` | TEXT-E02 |
| **P2b** | Shipping type must be filled | `LIKP-VSART` | TEXT-E04 |
| **P2c** | Means-of-transport type must be filled | `LIKP-TRATY` | TEXT-E03 |
| **P2d** | Incoterms must be filled | `LIKP-INCO1` | TEXT-E05 |
| **P2e** | Vehicle number required unless `VSART = '03'` | `LIKP-ZZVEHICLE_NO` | TEXT-E06 |
| **P2f** | LR/GR number must be filled | `LIKP-ZZLRGRNO` | TEXT-E07 |
| **P2g** | LR/GR date must be filled | `LIKP-ZZLRGRDATE` | TEXT-E11 |
| **P3** | A transporter partner must exist | `VBPA PARVW = 'SP'` | TEXT-E08 |
| **P4** | Freight condition `ZFB1` must exist with a non-zero rate | `(SAPMV50A)TKOMV[]`, `KSCHL='ZFB1'`, `KBETR` | TEXT-E09 / E10 |

Any failure sets `EV_ERROR_OCCURED = 'X'`; the BAdI then raises `00 368` with TEXT-E03/E04 into
`CT_FINCHDEL`.

## 3. Reconciliation against V01–V12

**These are a different *kind* of rule.** V01–V12 are business-limit rules (this quantity is too
high, this combination is not allowed). P1–P4 are **mandatory-data completeness** rules — "is
this depot delivery ready to dispatch yet".

| Interaction | Finding |
|---|---|
| **P2a vs V03** | P2a requires `SDABW` **filled**; V03 then requires the `LGORT`+`SDABW` pair to exist in `ZLETSPIMAP`. Complementary, same depot population. |
| **P2a vs V10** | V10 (Primary Plant, `A1`) requires `SDABW` **blank**; P2a (Depot, `A2`) requires it **filled**. **No conflict** — disjoint plant classes — but it proves SPI semantics are inverted between primary and depot. This is directly relevant to the open point-10 business discussion. |
| **P3 vs V09a/V09b** | P3 checks the transporter **exists**; V09a/V09b check it is **permitted**. P3 is the weaker precondition of the other two. |
| **P4 vs V06b / V11** | Third independent dependency on the screen-program global `(SAPMV50A)TKOMV[]`. **P4 fails open** — if the `ASSIGN` fails the whole check is skipped silently. V03 by contrast fails closed. |
| **Gating** | The BAdI call sits behind `SY-TCODE = 'VL02N'` *inside* the `VL01N/VL02N` block. So **P1–P4 never run during initial creation on any path — not even manual VL01N.** They run on VL02N save, or on demand via the button. |

**Net:** no rule in this FM is currently part of initial Create DI, by design. Nothing in it
contradicts the V01–V12 matrix; it adds a tenth-to-thirteenth family of rules that belongs to a
later process stage.

## 4. Do these need to go on the API path?

**Not on Create DI — no.** Look at what they demand: LR/GR number and date, vehicle number,
transporter partner, freight condition, batch splits. Most of that data does not exist at the
moment a delivery is created; it is captured during dispatch preparation. That is precisely why
the check is bound to **VL02N (change)** and not VL01N (create). It is a *pre-dispatch gate*, not
a *creation gate*, and forcing it into Create DI would make legitimate creation impossible.

**The real question is different:** if the API is to replace the depot flow end to end, then
whatever API step corresponds to "delivery is now dispatch-ready" must carry an equivalent gate.
If Create DI is the only API step in scope, then P1–P4 have **no API counterpart at all**, and
that is a process-design gap to raise with the business rather than a coding gap.

Decision needed from the client: **is the depot dispatch-preparation step in API scope?** Until
that is answered, building anything here is premature.

## 5. If it is in scope — architecture

### Extension rung, stated first

| Rung | Mechanism | Use here |
|---|---|---|
| 1 | **BAdI** (`LE_SHP_DELIVERY_PROC`, existing impl `ZLE_SHP_DELIVERY_PROC`) | **Yes — everything belongs here** |
| 2 | **BAPI extension BAdI** (`IF_DLV_CREATE_SLS_EXTIN` / `_STO_EXTIN`) | Only for inbound custom-field mapping, already in use |
| 3 | Explicit enhancement point | **No** |
| 4 | Implicit enhancement / `MV50AFZ1` user exit | **No — screen-bound by construction** |

Nothing proposed below needs a new enhancement implementation, a new BAdI, or any change to
`MV50AFZ1`. The hooks already exist and are already implemented.

### The actual defect to fix

The code asks **`SY-TCODE`** — which conflates *how the caller arrived* (screen vs API) with
*what stage the document is at* (create vs dispatch-ready). Those are different questions, and
that conflation is the single root cause of the whole Create-DI equivalence problem.

### Design

**D1 — one rule library, no duplication.**
Move P1–P4 (and progressively V03, V07–V10) into a stateless class, e.g.
`ZCL_LE_DLV_VALIDATION`, one method per rule family, each returning a message table. The BAdI,
the "Depo Pre-requisite's" button and any API step all call the same class. `ZLEF_DELIVERY_VALIDATONS`
already shows this pattern works — it just needs to stop being a function-group with the global
`GT_LOG`, which is shared mutable state and must not survive between calls.

**D2 — replace the tcode gate with a validation profile.**
Resolve applicable rules from **(delivery type, plant classification A1/A2, process stage)**.
Derive stage from `IF_TRTYP` plus document status — never from `SY-TCODE`. Keep `IV_CALLED_FROM`
strictly for presentation (ALV popup vs returned message table), never for rule selection.

**D3 — fix the ordering, which is the bigger win.**
Field population that the rules depend on currently happens in `SAVE_DOCUMENT_PREPARE`, after
`DELIVERY_FINAL_CHECK` where the rules run (see the 2026-09-15 addendum, D1/D2/D3 and the SAP
OData extension mapper). Move derivation into `FILL_DELIVERY_HEADER` / `CHANGE_DELIVERY_HEADER` —
both BAdI methods, both rung 1 — so that by the time any check runs the fields are populated.
This single change is what makes the API path capable of enforcing V03 and V07–V10 at all.

**D4 — remove the `(SAPMV50A)TKOMV[]` dependency.**
Three separate rules (V06b, V11, P4) reach into a screen program's global pricing table. That is
the most fragile construct in this entire codebase and it is the reason none of them can be
trusted outside the dialog. Replace with a proper condition read for the delivery. Until this is
done, no pricing-dependent rule can be certified on any non-screen path.

**D5 — do not put business rules in the OData/service layer.**
A second rule engine there would drift from the delivery engine. Keep one enforcement point so
screen and API share identical behaviour by construction.

### Risk that needs business sign-off, not a technical decision

Removing the `SY-TCODE` gates changes behaviour for existing manual users: V01, V02 and P1–P4
would begin applying to callers that are exempt today. That is a deliberate scope expansion and
must be agreed before implementation, not discovered after.
