# Handover — CNF Submit MIGO BAdI spike attempt

**Date:** 2026-09-02  
**Systems:** QS4 client 700 (test target); DS4 client 200 is the known development system  
**Immediate objective:** make the existing standard Material Document OData POST create movement 101 using caller-supplied Delivery + Delivery Item + Plant, with no PO/PO Item or other SAP item fields supplied by the caller.

## Outcome

I attached successfully to the live QS4/700 SAP GUI session using SAP GUI Scripting and reached the correct SE19 creation flow.

QS4 rejected repository object creation with:

> SAP system has status 'not modifiable'. Choose 'Display object' or 'Cancel'.

No enhancement implementation, class, source, package assignment or transport was created. I cancelled both unsaved dialogs and left SAP at the SE19 initial screen with one window and no modal dialogs.

This is the expected development boundary: create and activate the implementation in the modifiable development system, then transport it to QS4 for testing against the existing candidates.

## What was established during the attempt

### Correct SE19 object model

The BAPI enhancement is a **New BAdI**, not a Classic BAdI.

- BAdI enhancement spot: `MB_GOODSMOVEMENT`
- BAdI definition: `MB_BAPI_GOODSMVT_CREATE`
- Method: `IF_EX_MB_BAPI_GOODSMVT_CREATE~EXTENSIONIN_TO_MATDOC`

Do not use `ES_SAPLMB_BUS2017` in the SE19 New BAdI creation field. That is the source-code enhancement spot used by enhancement points inside function group `MB_BUS2017`; SAP rejects it for BAdI implementation creation with:

> Action allowed only for spots of enhancement technique "BAdI Definition"

Repository evidence in `ENHOBJ_Z.txt` shows the existing implementation `ZEI_MM_GOODSMVT_BAPI_CUSTOM` references enhancement spot `MB_GOODSMOVEMENT`, interface `IF_EX_MB_BAPI_GOODSMVT_CREATE`, and class `ZCL_MM_GOODSMVT_BAPI_CUSTOM`.

Multiple active implementations already exist for `MB_BAPI_GOODSMVT_CREATE`, so the CNF spike should be a new isolated implementation instead of modifying the customer's existing class.

Proposed names used in the unsaved QS4 dialog:

- Enhancement implementation: `ZCNF_SUBMIT_MIGO`
- Short text: `CNF delivery-based Submit MIGO`
- Suggested implementing class: `ZCL_CNF_SUBMIT_MIGO`

### SAP GUI path attempted

1. Attached to `QS4/700`; initial transaction was SE16.
2. Opened SE19 using SAP GUI Scripting.
3. Initially tried the Classic BAdI entry with `MB_BAPI_GOODSMVT_CREATE`; SAP rejected the field input. This was the wrong creation path.
4. Tried New BAdI with `ES_SAPLMB_BUS2017`; SAP correctly rejected it because it is not the BAdI-definition enhancement spot.
5. Switched New BAdI enhancement spot to `MB_GOODSMOVEMENT`.
6. Opened **Create Enhancement Implementation**.
7. Entered `ZCNF_SUBMIT_MIGO` and its short text.
8. SAP stopped creation because QS4 is not modifiable.
9. Cancelled all unsaved dialogs cleanly.

## Prepared ABAP spike

The candidate method body is ready at:

`sessions/2026-09-02-cnf-badi-spike/ZCL_CNF_SUBMIT_MIGO_EXTENSIONIN_TO_MATDOC.abap`

It has not been syntax-checked or activated in SAP because QS4 refused object creation. Review it in DS4 before activation.

The spike is deliberately restricted to:

- runtime system/client `QS4/700`
- movement `101`
- movement/reference indicator `B`
- receiving Plant `1005`
- STO `5600074803`, item `000010`
- delivery range `9004952595` through `9004952614`

For matching CT_IMSEG items it:

- reads `LIPS` using incoming `VBELN/POSNR`;
- confirms outbound delivery through `LIKP-VBTYP = 'J'`;
- confirms the receiving STO item through `EKPO` and the request Plant;
- sets `VLIEF_AVIS = delivery`;
- sets `VBELP_AVIS = POSNR` for these non-batch-split candidates;
- derives `MATNR` from LIPS;
- uses the matched base quantity/unit pair `LGMNG/MEINS`, falling back to `LFIMG/VRKME`;
- sets Batch only when present;
- retains the request's receiving Plant;
- applies the verified receiving-location rule `RMYD` for this test STO/Plant;
- returns blocking BAPI errors for failed target-scenario derivation.

### Important corrections retained in the code

- Do **not** use `LIPS-UECHA` for these candidates. It is `000000`; their real delivery item is `POSNR = 000010`. UECHA is only relevant when processing a batch-split child whose parent item is recorded there.
- Do **not** combine `LFIMG` with `MEINS` generically. Use either `LGMNG/MEINS` or `LFIMG/VRKME`.
- Do **not** copy the outbound delivery's supplying-side plant/storage location into the receiving goods receipt. Plant comes from the OData request; `RMYD` is the verified receiving SLoc for this spike.
- Do **not** use silent `CHECK` statements after recognizing a target candidate. Return an explicit `BAPIRET2` error.
- The resulting core material document uses the standard MM posting engine, but MIGO-screen BAdIs and GUI-dependent side effects do not run. This spike proves the integration path, not the complete Submit MIGO feature.

## Exact next execution path

1. Log into modifiable DS4/200 or the customer's designated development client.
2. SE19 → New BAdI → Enhancement Spot `MB_GOODSMOVEMENT` → Create.
3. Create enhancement implementation `ZCNF_SUBMIT_MIGO` and select BAdI definition `MB_BAPI_GOODSMVT_CREATE`.
4. Create implementing class `ZCL_CNF_SUBMIT_MIGO` in the customer-approved package and transport request.
5. Insert the prepared method into `EXTENSIONIN_TO_MATDOC`.
6. Syntax-check and activate the class, BAdI implementation and enhancement implementation.
7. Transport to QS4.
8. In QS4, verify the new implementation is active and that the existing `ZEI_MM_GOODSMVT_BAPI_CUSTOM` remains unchanged.
9. Fire the already-known minimal Postman request against an unused registered candidate.
10. If another SAP posting validation appears, correct only the mapping responsible and retry. Continue until the response returns Material Document Number and Year.
11. Verify the created 101 material document and delivery document flow.

Real candidate consumption is authorized. Before retrying an ambiguous response, check MATDOC/MSEG to ensure a material document was not already created.

## Candidate source

`sessions/2026-09-02-migo-candidate-recheck/CANDIDATE_REGISTER.csv`

The primary cluster contains 18 documented candidates for STO `5600074803`, receiving Plant `1005`, receiving SLoc `RMYD`, material `14000035`, item `000010`.

## SAP GUI scripting artifacts created

Directory:

`sessions/2026-09-02-cnf-badi-spike/scripts/`

- `goto-se19.vbs` — attaches to QS4/700 and opens SE19.
- `se19-start-create.vbs` — selects New BAdI and enters enhancement spot `MB_GOODSMOVEMENT`.
- `se19-press-create.vbs` — opens the implementation creation dialog.
- `se19-name-implementation.vbs` — enters the proposed implementation name and short text.
- `se19-state.vbs` — reads SE19 state/status.
- `se19-cancel-unsaved.vbs` — closed the rejected unsaved dialogs.

Use `C:\Windows\SysWOW64\cscript.exe //NoLogo` for the existing VBS harness. SAP may display its scripting-attachment approval dialog for every new script process. The VBS route worked; attempts to hold SAP COM through PowerShell were unreliable (`Cannot create ActiveX component` / type-library mismatch), so continue with VBS.

## Priority boundary

Do not resume broad report or enhancement discovery before this spike is transported and tested.

Current milestone only:

> Prove a real standard OData → BAPI BAdI → 101 material-document posting from Delivery + Delivery Item + Plant.

Custom Token/LR derivation, the eight MIGO validations, `ZMMT_MIGO_HDR` persistence, idempotency and downstream processing remain later production work.
