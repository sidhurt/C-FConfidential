# Modify DI: can the `LIKP-ZZ*` fields travel through the standard delivery API?

**Date:** 2026-09-21
**System:** QS4 / 700, user `QNOVATE8`, SAP GUI scripting, read-only (SE16, SE38 display,
Enhancement Editor display)
**Service:** `API_OUTBOUND_DELIVERY_SRV;v=2`, entity `A_OutbDeliveryHeader`
**Question:** Modify DI must do what VL02N does, including the custom transport fields. Is
there a standard path?

**This supersedes the 18.09 statements** "no standard way exists" (chat) and "sending `ZZ`
values would be rejected" (`sessions/2026-09-18-pgi-certification/FINDINGS.md`, Modify DI
section).

---

## Answer

**Yes. The standard service already carries custom delivery-header fields end to end.** The
client's 14 `ZZ` fields are already placed in SAP's extension include. The only open condition
is whether the fields are **enabled as properties in the OData model**, and that hasn't been
confirmed on QS4 yet.

## The chain, Verified from QS4 source and DDIC

| Step | Object | What it does | Evidence |
|---|---|---|---|
| 1 | `ZSDA_CUSTOM_FIELDS1` | **Append** (`TABCLASS APPEND`) to SAP's extension include **`SHPDELIVERY_INCL_EEW_PS`**. Holds `ZZLRGRNO`, `ZZLRGRDATE`, `ZZVEHICLE_NO`, `ZZDRIVER_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB`, `ZZWERKS`, `ZZPARTNER`, `ZZVHCLTYP`, `ZZVBELN`, `ZZEBELN`, `ZZAUFNR`, `ZZSEALNO`, `ZZREFDI`. Last changed 18.08.2026 by `NVLDEV10` | `evidence/DD02L_ZSDA_CUSTOM_FIELDS1.txt`, `DD03L_ZSDA_CUSTOM_FIELDS1.txt`, `DD03L_SHPDELIVERY_INCL_EEW_PS.txt` |
| 2 | `AOUTBDELIVERYHEADER` | The API header structure includes `SHPDELIVERY_INCL_EEW_PS` (position 110), so the `ZZ` fields are in the entity's `ext` group. `LIKP` includes the same include (hence `DUMMY_DELIVERY_INCL_EEW_PS` in `LIKP`) | `evidence/DD03L_AOUTBDELIVERYHEADER_includes.txt` |
| 3 | `CL_API_OUTBOUND_DELIVE_MPC_FLX→DEFINE` | Generated. Adds custom properties from the Custom Fields and Logic runtime (`cl_cfd_odata_factory`, `add_custom_metadata`) | `src/CL_API_OUTBOUND_DELIVE_MPC_FLXCM002.txt`, `…CM004.txt` |
| 4 | `CL_SHP_API2_HEADER_PROCESS→GET_ENTITY` | SAP comment: *"custom fields assigned to the service header entity is only a subset of extensibility include shpdelivery_incl_eew_ps"*. It merges patched extension values via `cl_le_shp_odata_api_helper=>get_custom_header_update` | `src/CL_SHP_API2_HEADER_PROCESS====CM005.txt` |
| 5 | `…→UPDATE_ENTITY` / `GET_PATCHED_ATTRIBUTES` / `CHECK_WHITELIST` | Changed fields are split into standard and extension. **The whitelist applies only to standard fields** (`WHERE is_ext = abap_false`), so extension fields are updatable by design | `src/CL_SHP_API2_HEADER_PROCESS====CM003.txt`, `CM004`, `CM006` |
| 6 | `CL_API_OUTBOUND_DELIVE_DPC_EXT` create/item update | Create copies header and item `ext` into the BAPI input (`MOVE-CORRESPONDING … ext`); item update uses `get_patched_fields` on `ext` | `src/CL_API_OUTBOUND_DELIVE_DPC_EXTCM003.txt`, `CM00F.txt` |
| 7 | `SHP_EXTEND_ODATA` (`CL_IM_SHP_EXTEND_ODATA→SAVE_DOCUMENT_PREPARE`) | Copies the changed extension fields into `XLIKP`/`XLIPS` by component name | `sessions/2026-09-14-create-di-enhancement-equivalence/source-captures/2026-09-15-QS4-scripted/CL_IM_SHP_EXTEND_ODATA========CM001.txt` (other branch) |

**Verified:** there are no customer enhancements on any `CL_API_OUTBOUND_DELIVE*` class
(`evidence/ENHINCINX_PROG_*.txt`, `ENHOBJ_API_OUTBOUND_DELIVE.txt`). The positive control on
the MIGO API classes returned their known enhancements
(`ENHOBJ_control_API_MATERIAL_DOCUME.txt`, `ENHINCINX_control_API_MATERIAL_DOCUME.txt`), so the
zero is real. The delivery API is unmodified SAP.

## The one open condition: Unknown

Are the 14 fields **enabled as properties on `A_OutbDeliveryHeader`** in QS4?

- The DS4 `$metadata` captured 18.08.2026
  (`sessions/2026-08-18-runtime-certification/evidence/META_API_OUTBOUND_DELIVERY_V2_response.xml`)
  has **no `ZZ` properties**. It was captured on the same day `ZSDA_CUSTOM_FIELDS1` was last
  changed, and from a different system.
- Enablement is managed by the Custom Fields and Logic runtime (step 3). **Hypothesis:** CFL
  only enables fields it created (`YY1_…`). A developer-made `ZZ` append would then not be
  enableable through CFL, and would need a model-side enhancement instead. Not verified.

**Decisive check:** GET `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/$metadata` in QS4
`/IWFND/GW_CLIENT`, then search for `ZZVEHICLE_NO`.

- **Present:** Modify DI of the custom fields is **pure standard**: a PATCH on
  `A_OutbDeliveryHeader` with the `ZZ` properties. Create DI can carry them the same way.
- **Absent:** the smallest addition is a model-side enhancement that declares the 14
  properties (bound to the `ext` components) on `A_OutbDeliveryHeader`. Steps 4–7 need no
  change. **This is materially smaller than the Submit MIGO extension**, which needed its own
  persistence.

The scripted Gateway harness (`sessions/2026-08-18-runtime-certification/scripts/gw_get.vbs`
with `Copy-EditorBody.ps1`) was not used. It is DS4-guarded, auto-dismisses modals, and
captures by foregrounding the SAP window and sending keystrokes. That is unsafe on a shared
desktop.

### Result, 2026-09-21: absent (Verified)

Siddharth ran the GET in QS4 `/IWFND/GW_CLIENT`
(`https://VHRESQS4CI…:44300/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/$metadata`) and
pasted the response into the session. In it:

- `A_OutbDeliveryHeaderType` contains **no `ZZ*` property** and no custom property of any
  kind. `A_OutbDeliveryItemType` has none either.
- The updatable header properties match DS4: `ActualGoodsMovementDate`, `BillOfLading`,
  `DeliveryBlockReason`, `DeliveryDate`, `DeliveryDocumentBySupplier`, `DeliveryPriority`,
  `DeliveryTime`, `GoodsIssueTime`, the header weights and volume, the Incoterms fields,
  `LoadingDate`/`Time`, `MeansOfTransport`, `MeansOfTransportType`, `PickingDate`/`Time`,
  `PlannedGoodsIssueDate`, `ProposedDeliveryRoute`, `TransportationPlanningDate`/`Time` and
  `UnloadingPointName`.
- `A_OutbDeliveryPartner` is `creatable/updatable/deletable = false`.

**Consequence:** the data half is standard and ready (steps 1, 2 and 4–7), but the model does
not declare the 14 fields. **Modify DI of the `ZZ` fields needs exactly one addition: the 14
properties declared on `A_OutbDeliveryHeaderType`.**

Two ways to add them, in order of preference:

1. **Custom Fields and Logic enablement.** This is configuration, with no code, and only
   possible if CFL can manage these fields. **Hypothesis:** it can't, because CFL manages only
   the `YY1_` fields it creates, and `ZSDA_CUSTOM_FIELDS1` is a developer append. To confirm,
   ask the ABAP consultant, or look for the fields in the Custom Fields app.
2. **Implicit enhancement at the end of `CL_API_OUTBOUND_DELIVE_MPC_EXT→DEFINE`.** This is the
   same technique `ZSD_ENH_API_MATDOC_DEFINE_MPC` uses for MIGO. It creates the 14 properties
   and binds each to its `ZZ` component, so they land in `ext`. **No data-provider code** is
   needed, because SAP's update path and `SHP_EXTEND_ODATA` already persist `ext`.
   - **Rung:** implicit enhancement. That is below a BAdI, but there is no model-extension
     BAdI on this service.
   - **Risk:** SAP can regenerate the class during upgrades.

Neither route has been built or tested. The property-to-`ext` binding in route 2 is **Strong
inference** until a PATCH is read back from `LIKP`.

## The required field list, from the portal Figma flow (Siddharth, 2026-09-21)

The flow is "Generate Billing Documents" (tabs: DI Quantity → Batch Determination →
Transporter Details), then "Shipment Details", then "Generate Invoice & E-Way Bill".
Transporter name and address come from T2/CPI master data using partner function and
transporter code.

| Screen field | SAP field | Standard API today |
|---|---|---|
| Update DI quantity | `LIPS-LFIMG` | Item PATCH `ActualDeliveryQuantity` |
| Storage location | `LIPS-LGORT` | Item PATCH `StorageLocation`; V03 enforced on change (17.09) |
| Batch (FIFO, portal-proposed) | `LIPS-CHARG` / split lines | `PickAndBatchSplitOneItem` / `CreateBatchSplitItem` / item `Batch` |
| SPI ID | `LIKP-SDABW` | **Not writable.** `SpecialProcessingCode` is `updatable=false`; on the sales-order route SPI comes from the order (17.09) |
| Partner function SP + transporter code | `VBPA` `SP` | Partner entity read-only. Via `ZZPARTNER` → client D1 appends `SP` **only when no `SP` exists** (source), so a later change is not covered |
| LR/GR no. and date, vehicle no., driver code/name/mobile | `ZZLRGRNO`, `ZZLRGRDATE`, `ZZVEHICLE_NO`, `ZZDRIVER_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB` | Need the model declaration |
| Pick-up code | `LIKP-PICKUPCODE` | **Not in the API and not in `ZSDA_CUSTOM_FIELDS1`**. The client's VL02N check (FTP, plants in TVARVC `ZUSER_PCODE_INCLUDE`) compares it with `VBAK-PICKUPCODE` |

**Consequence:** the model declaration shrinks to **7 fields**: `ZZLRGRNO`, `ZZLRGRDATE`,
`ZZVEHICLE_NO`, `ZZDRIVER_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB`, `ZZPARTNER`. `ZZVBELN` and the
other fields are not exposed.

**Open for the SD consultant:**

- Is SPI display-only (from the order), or must the portal change it?
- Must the pick-up code be written to `LIKP`, or only validated against the order?
- Can the transporter change after first assignment?

Figma inconsistencies to raise:

- The incoterm shows FTP on most screens but FTB on one Shipment Details screen. The pick-up
  code rule applies to FTP.
- The header shows 30.5 MT; the DI Quantity tab shows 30 MT.

### Settled by Siddharth, 2026-09-21 (SRC-SID)

- **SPI** is populated automatically from master data and the sales order, and is related to
  shipment cost. It is **display-only, not an API write.** The gap is closed.
- **Pick-up code** comes from the existing CRM (T1/Udaan) and is associated with orders.
  **The portal validates it; SAP does not need it written.** Still to confirm: nothing
  downstream (billing, e-way bill) reads `LIKP-PICKUPCODE`.
- **Commit point.** Until "Generate Invoice & E-Way Bill" is pressed, every screen can be
  revisited, changed and resubmitted. After it, nothing changes.

**Consequences:**

- The declaration stays at the 7 fields listed above.
- The transporter is assigned once, at commit, so client derivation D1 ("append `SP` only if
  none exists") covers it. **Strong inference until tested.**
- **Recommended integration pattern:** hold the draft in the portal/T2 and write to SAP only
  at commit, in a fixed order:
  1. item quantity
  2. batch split / storage location / pick
  3. header dispatch fields (`ZZ` + `ZZPARTNER`)
  4. (shipment and cost)
  5. PGI
  6. billing
  7. e-invoice / e-way bill

  Writing at every "Proceed" is technically possible, because the delivery stays changeable
  until PGI. It is rejected because it multiplies batch-split undo, delivery locks and
  ETag/version conflicts.
- **The design risk moves to orchestration.** One user action triggers 5–7 SAP operations, some
  of them irreversible (PGI is only reversible by reversal; billing and e-way bill are
  statutory). CPI needs:
  - a step ledger;
  - resume-from-failed-step with idempotent retries;
  - user-facing partial-failure states (for example, PGI posted but billing failed).

## Consequences

- **Transporter:** `ZZPARTNER` is one of the 14. Client derivation D1
  (`ZCLLE_DELIVERY_PROCESS→SAVE_DOCUMENT_PREPARE`) appends the `SP` partner from it. So if
  `ZZPARTNER` can be sent, the transporter can be set without the read-only partner entity.
- **Sequencing risk: open.** `SHP_EXTEND_ODATA` and the client derivations D1/D2 both run in
  `SAVE_DOCUMENT_PREPARE`, and the client validations run earlier in `DELIVERY_FINAL_CHECK`.
  Whether D1/D2 see the new values in the same save depends on implementation order. This
  needs a breakpoint-order check.
- **VL02N-gated client rules** (transporter authority check, CRM send, bidding quantity) will
  not fire on an API change. That is for business acceptance.

## Also found: correction to 2026-09-18 Submit MIGO findings

`ZSD_ENH_API_MAT_DOC_DPC` (a class enhancement with a post-method on
`CL_API_MATERIAL_DOCUME_DPC_EXT→CREATE_DOCUMENT`) persists the MIGO `ZZ_` header fields to
`ZMMT_MIGO_HDR`. The 18.09 "values are discarded" statement is retracted; see the correction
note in `sessions/2026-09-18-submit-migo-header-fields/FINDINGS.md`.
