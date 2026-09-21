# Create DI runtime and adversarial test plan

**Status:** designed, not executed. Each call requires a named case, current data revalidation
and explicit authorization.

## Scope lock — 17 September 2026

The agreed Create DI certification scope is exactly V01, V02, V03, V07, V08, V09a and V09b
(`SRC-SID-20260917-02`). Do not mix the parked Primary Plant rules or later depot-prerequisite
set into this campaign.

Freeze and record the active QS4 transport/class versions before the first test. Do not change
code while collecting the baseline: a result set spanning different versions is not evidence.

The campaign is **observe, classify, then remediate**:

1. prove path reachability and field timing;
2. run one-condition matched positive/negative cases through screen, BAPI and OData as applicable;
3. classify each rule as custom-pass, standard-equivalent, bypass, silent-skip or cannot-exercise;
4. implement only the proven gaps through the highest available supported extension rung; and
5. rerun the identical cases as regression evidence.

## Path comparison logic

For each rule, compare the business core with the external provider rather than testing only an
OData `201`:

| BAPI result | OData result | Meaning |
|---|---|---|
| rejects invalid case | rejects invalid case | Core/shared validation is likely effective; confirm the same rule/message and non-persistence. |
| accepts invalid case | rejects invalid case | Provider or standard OData layer supplies the control; decide whether that is an approved equivalent. |
| rejects invalid case | accepts invalid case | OData mapping/path loses a required field or reaches a different branch; trace before changing code. |
| accepts invalid case | accepts invalid case | Proven validation gap, unless SAP split/derived the document into an outcome that independently satisfies the requirement. |

For V01/V02 also run the same negative through `VL01N`/`VL02N` to prove the known screen branch.
Different error text is acceptable only if the functional owner accepts the standard SAP check as
equivalent and the invalid delivery does not persist.

## Rule-specific first questions and likely remediation

| Rule | Baseline question | If the API bypasses or silently skips |
|---|---|---|
| V01 one material | Does standard `_STO`/`_SLS` processing reject or split a configured multi-material request even though custom `ZSD 002` is screen-gated? | Extract the rule into a path-neutral validator and invoke it from the released delivery BAdI for both screen and API paths. Do not merely remove the `SY-TCODE` guard from the existing block. |
| V02 one SLoc | Does the API accept a depot delivery containing two active storage locations? Are storage locations present during final check? | Use the same shared-validator pattern, counting active non-batch-split items correctly and preserving manual behavior. |
| V03 SLoc/SPI | Are `LIPS-LGORT` and `LIKP-SDABW` both populated when `ZCLLE_DELIVERY_PROCESS~DELIVERY_FINAL_CHECK` runs? | Fix contract/derivation timing or move shared validation to a supported point where both values exist. Do not duplicate the rule while leaving blank-field silent skip intact. |
| V07 order blocks | Is the sales-order predecessor available, and is `LIKP-ZZVBELN` populated before final check? Test credit, delivery and billing blocks separately. | Prefer deriving the authoritative predecessor from standard delivery references/current BAPI input and pass it to a shared validator. Populate `ZZVBELN` only if the field remains an approved persistence requirement; do not make safety depend on an accidentally blank custom header. |
| V08 cumulative quantity | Does the validator see the authoritative predecessor and committed earlier deliveries before evaluating the current quantity? | Re-read committed quantity under the correct business lock and validate current plus prior quantity. Avoid trusting a portal pending snapshot. Preserve the standard predecessor/item key rather than relying only on header `ZZVBELN`. |
| V09a FTB self-transporter | Is `INCO1=FTB` and an active `SP` partner present at initial Create DI time? | If transporter is part of Create DI, map/derive it before validation. If transporter is supplied later, move enforcement to the mandatory Modify DI/Pre-PGI transition; an initial-create check cannot validate nonexistent data. |
| V09b depot-transporter mapping | Is the active `SP` partner and shipping point present at the same validation point, and is the cutoff/config gate active? | Same lifecycle decision as V09a. Use one shared transporter validator and keep the two business rules and error cases separate. |

The likely implementation surface is the existing released `LE_SHP_DELIVERY_PROC` BAdI, not
`MB_BAPI_GOODSMVT_CREATE`. A clean implementation should place pure, path-neutral rules in one
reusable validator class and call it from the supported delivery hook where all required fields
are present. T0 must determine that hook; do not select it from source appearance alone.

## T0 — path instrumentation, not adversarial testing

Run approved dynamic-breakpoint traces separately for `_STO`, `_SLS` and their OData routes.
Capture whether `DELIVERY_FINAL_CHECK`, customer `SAVE_DOCUMENT_PREPARE`, SAP
`SHP_EXTEND_ODATA~SAVE_DOCUMENT_PREPARE` and relevant `MV50AFZ1` exits fire; record exact order,
`SY-TCODE`, `IF_TRTYP`, relevant LIKP/LIPS/VBPA fields, `CT_FINCHDEL`, and whether
`(SAPMV50A)TKOMV[]` is assigned and populated.

The decisive point is whether validation runs before OData/custom-field mapping and derivation.
T0 establishes reachability and field timing only; it proves no business rejection by itself.

## Candidate qualification

Before any rule test, document the exact predecessor/item, open quantity, delivery type, plant
classification, shipping point, route, Incoterm, dates, material/MFRGR, SLoc/SPI, `ZZVBELN`,
transporter partner/mapping, every earlier rule gate, the single violated condition, expected
message and non-persistence proof query.

Current candidates are insufficient as a full adversarial set:

- `5600084274/00010` was consumed; do not reuse.
- `5600084222/00010` may support STO T0 after re-read, but availability is unknown and its
  single-item shape cannot test V01/V02.
- Sales order `5270471` can support `_SLS`/VL01N tracing, but its one visible material and
  partial-delivery state do not make it a universal negative fixture.

## Matched adversarial pairs — current scope

| Case | Rule | Positive | Negative | Expected negative result |
|---|---|---|---|---|
| A1 | V01 one material | one distinct material | comparable order with two materials | `ZSD 002` in VL01N/VL02N; branch absent on API |
| A2 | V02 one SLoc | one depot SLoc | comparable delivery with two SLocs | `00 398` in VL01N/VL02N; branch absent on API |
| A3 | V03 SLoc/SPI | mapped pair | pair absent from `ZLETSPIMAP` | `ZLE 104`, if both fields exist at check time |
| A4 | V07 order block | unblocked SO with `ZZVBELN` | blocked SO with `ZZVBELN` | `ZLE 088`; no delivery |
| A5 | V08 cumulative qty | total at/below limit | total just above limit | `ZLE 087`, unless a standard check pre-empts it |
| A6 | V09a self-transporter | allowed carrier on depot FTB | configured self-transporter, other gates met | `ZLE 205` |
| A7 | V09b depot mapping | carrier mapped to shipping point | active carrier absent from mapping | `ZLE 207` |

V09a and V09b are separate rules and require separate evidence.

## Parked cases

- V04/V05/V06/V10 are Primary Plant/configuration-dependent and parked from current C&F scope.
- V11 (`YSTO`) is a conditional source candidate, not an approved requirement.
- V12 is config-dead in QS4 because `ZGPT_SD_PARAM` is empty.
- The ten depot prerequisites belong to shipment/Pre-PGI/finalisation, not initial Create DI.

## Execution pattern

1. Re-read and freeze both fixtures immediately before execution.
2. With explicit approval, run BAPI positive/negative probes and capture the exact rejecting
   method/message. Omitting `BAPI_TRANSACTION_COMMIT` is lower risk, **not read-only**: transient
   locks, number-range or other effects can still occur.
3. Run the OData negative; capture the expected custom error and prove no LIKP/LIPS persisted.
4. Run one approved OData positive; independently re-read the delivery and document flow.
5. For V01/V02, compare VL01N/VL02N with BAPI/OData and capture the tcode branch.
6. After rule equivalence, add replay, concurrency, authorization and recovery cases.

## Safety and evidence rules

- Dynamic breakpoints only; never edit debugger variables or activate source.
- One SAP GUI automation at a time; verify QS4/700 first.
- No business write without explicit case-level authorization.
- A negative that violates multiple rules is invalid evidence because an earlier error can mask
  the target rule through `CT_FINCHDEL`.
- HTTP success/document number is not persistence proof; re-read the created document.
