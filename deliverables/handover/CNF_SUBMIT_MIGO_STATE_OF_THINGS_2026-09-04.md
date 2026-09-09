# Submit MIGO — where things stand

**2026-09-04** · DS4/200 and QS4/700

## What this was for

Posting a goods receipt (101) against a delivery, without the caller passing a purchase order —
so the API call carries delivery, delivery item and plant, and SAP works out the rest. Using the
standard service `API_MATERIAL_DOCUMENT_SRV`, no custom service.

## Where it stands

After the architecture review on 4 September, the direction is to do this through the BAdI
`MB_BAPI_GOODSMVT_CREATE` rather than through a source-code enhancement. I've stopped work on the
enhancement and I'm removing it. The BAdI version of the logic hasn't been written yet.

Nothing was ever posted. No material document exists from any of this.

## What's in the systems

**DS4/200**

- `ZCL_CNF_SUBMIT_MIGO` — class for the BAdI. Method body is empty (`RETURN.` only).
- `ZCNF_SUBMIT_MIGO` — BAdI implementation on `MB_BAPI_GOODSMVT_CREATE`. Registered and active,
  but does nothing since the class method is empty.
- `ZCNF_SUBMIT_MIGO_MAP2I` — the enhancement, package `ZSCL`. Being deleted.

**QS4/700**

- `ZCL_CNF_SUBMIT_MIGO` — the empty version is active.
- `ZCNF_SUBMIT_MIGO` — registered, active, does nothing.
- `ZCNF_SUBMIT_MIGO_MAP2I` — still active as of writing. The deletion is being transported;
  worth confirming it has landed.

Earlier in the day this class briefly held test code in QS4 that returned an error on every call.
That's been replaced.

## Transports

`DS4K964047`, `DS4K964062`, `DS4K964064` — the BAdI class, three versions.
`DS4K964117` — the enhancement.
Plus one for emptying the class, and one pending for deleting the enhancement.

Two imports failed on 4 September — one with a `tp` error, one because the target client wasn't
set. Worth verifying imports landed rather than assuming.

## Test data

Deliveries `9004952595`–`9004952614`. All type `ZNL`, all against stock transport order
`5600074803`, supplying plant `1002`, receiving plant `1005`, material `14000035`.

`9004952595` item `000010` is `41.230 TO` and is still unreceived. I used it for every test.

## What I didn't get to

- Only the `Z*` namespace was covered. `Y*` and any reserved namespace weren't.
- BTEs, validations and substitutions, and output determination weren't looked at.
- `MODATTR` wasn't read, so I can't say whether the CMOD projects are actually active.
- `ZGPT_MM_PARAM` contents weren't captured. It holds switches the MIGO custom code reads.
- Five of the customer implementations I found weren't opened: `ZEI_MM_DELIVERY_NOTE`,
  `ZIML_CAN_CHECK`, `ZDACE_MODIFY_MIGO_ITEM_QTY`, `ZMM_MIGO_DATA_CHECK`, `ZPP_COR6_RMC`.
- The Postman collection was never run.

None of these are closed. They shouldn't be treated as covered.

## One thing that was wrong along the way

On 2 September I concluded the BAdI wasn't being called, based on a test that came back empty.
On 4 September the same test did produce a message. The BAdI is called later in the flow than the
point where those earlier runs were failing, so it wasn't being reached. That wrong conclusion is
why I went to the enhancement instead of the BAdI.

## Where everything is

The detail is in the repository rather than in this note.

- `sessions/2026-09-02-migo-customisation-inventory/` — table output and 32 method sources I
  pulled from QS4, covering the customer enhancements on MIGO and goods movement
- `sessions/2026-09-02-std-api-extension-feasibility/` — SAP source I read
- `sessions/2026-09-02-cnf-badi-spike/` — the ABAP for both approaches
- `sessions/2026-09-02-migo-candidate-recheck/` — `CANDIDATE_REGISTER.csv`
- `deliverables/CNF_MIGO_CUSTOMISATION_DISPOSITION_2026-09-04.md` — the customisation list with
  where each piece sits

Most of the table reads were automated with SAP GUI scripting against QS4, read-only. The scripts
are in those folders. Nothing was posted or changed by them.

## If you're picking this up

The logic is short and exists in both forms. What's left is putting it in the BAdI, activating it,
and posting one document. The test data is ready.

First thing to check is whether the enhancement deletion has imported.

Happy to walk through any of it.
