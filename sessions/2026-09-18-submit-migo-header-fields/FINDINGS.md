# Submit MIGO: how custom header fields were added to the standard service

**Date:** 2026-09-18
**System:** QS4 / 700, user `QNOVATE8`, SAP GUI scripting, read-only
**Trigger:** Siddharth reported that the ABAP consultant had pushed changes adding custom
fields to the Submit MIGO header payload (built in DS4, transported to QS4).
**Service:** `API_MATERIAL_DOCUMENT_SRV`, entity `A_MaterialDocumentHeader`

---

> **Correction 2026-09-21: the data half *is* wired.** The 18.09 sweep missed a third
> enhancement, **`ZSD_ENH_API_MAT_DOC_DPC`**, a *class* enhancement (`ENHHEADER` type
> `CLASENH`, changed 18.09.2026 by `SEHAJTECH`). The transport search patterns (`*MATDOC*`,
> `*MATERIAL_DOC*`) did not match `*MAT_DOC*`.
>
> It adds a **post-method on `CL_API_MATERIAL_DOCUME_DPC_EXT→CREATE_DOCUMENT`**
> (`ENHINCINX` `\ME:CREATE_DOCUMENT\SE:%_END`;
> `sessions/2026-09-21-modify-di-extension-channel/evidence/ENHINCINX_ZSD_ENH_API_MAT_DOC_DPC.txt`).
> After posting, the post-method:
>
> 1. takes the material document number and year from the result;
> 2. re-reads the request payload into a local type with the 19 `ZZ_` fields;
> 3. does `MODIFY zmmt_migo_hdr`, keyed `MBLNR`/`MJAHR`
>    (`src/ZSD_ENH_API_MAT_DOC_DPC=======EIMP.txt`).
>
> **Verified from source:** the custom header fields persist to the Z table `ZMMT_MIGO_HDR`, not
> to `MKPF`. The "values are discarded" statement below is **retracted**. `§3` stays accurate
> for SAP's own create path only.

## Summary

The consultant did **not** build a Z service or redefine the service in SEGW. The changes are
**enhancement implementations placed inside SAP's own generated OData classes**, so the
service name and URL are unchanged.

| Layer | Object | State |
|---|---|---|
| Model | `ZSD_ENH_API_MATDOC_DEFINE_MPC`: implicit enhancement at the end of `CL_API_MATERIAL_DOCUME_MPC_EXT→DEFINE` | **Active.** Adds 19 header properties |
| Data provider | `ZSD_ENH_API_MATDOC_CREATE_DOC`: registered on `CL_API_MATERIAL_DOCUME_DPC_EXT` | **No code position.** Nothing reads the new fields |
| Posting BAdI | `ZCL_MM_GOODSMVT_BAPI_CUSTOM→EXTENSIONIN_TO_MATDOC` (changed) | Active. Derives PO from delivery and calls a new validation class. Does **not** use the new fields |
| Validation | `ZCL_MM_MIGO_VALIDATION_FACADE` (new) | Header type is `GOHEAD` plus `bwart_dflt`/`action`/`refdoc` |

**Net state. Strong inference:** a caller can now send the custom header fields without the
Gateway rejecting them, but the values are discarded before posting. That looks like work in
progress; the last transport is from this morning.

---

## Transports

All are transport-of-copies (`TRFUNCTION T`), `AS4USER SEHAJTECH`
(`evidence/E070_DS4K965127-965215.txt`):

| Request | Date / time | Objects (`evidence/E071_DS4K96_*.txt`) |
|---|---|---|
| `DS4K965127` | 17.09.2026 11:27 | `ENHO ZSD_ENH_API_MATDOC_CREATE_DOC`; `METH ZCL_MM_GOODSMVT_BAPI_CUSTOM EXTENSIONIN_TO_MATDOC`; `CLAS ZCL_MM_MIGO_VALIDATION_FACADE` |
| `DS4K965196` | 17.09.2026 20:15 | the above plus `ENHO ZSD_ENH_API_MATDOC_DEFINE_MPC` |
| `DS4K965198`, `…199`, `…206`, `…209` | 17.09.2026 21:13–23:40 | `ZSD_ENH_API_MATDOC_DEFINE_MPC` |
| `DS4K965215` | 18.09.2026 09:42 | `ZSD_ENH_API_MATDOC_DEFINE_MPC`; `EXTENSIONIN_TO_MATDOC` |

The earlier CNF objects (`ZCL_CNF_SUBMIT_MIGO`, `ZCNF_SUBMIT_MIGO`, `ZCNF_SUBMIT_MIGO_MAP2I`,
`DS4K964047`–`DS4K964133`) are not part of this change.

`DS4K963268` carries `IWSG ZAPI_MATERIAL_DOCUMENT_SRV_0001` and `IWOM
ZAPI_MATERIAL_DOCUMENT_MDL_0001_BE`, a Z registration of the service. It is **not examined
here**, and whether it is in use is Unknown.

---

## 1. Model enhancement: Verified

`ENHINCINX`: `ZSD_ENH_API_MATDOC_DEFINE_MPC` at
`\TY:CL_API_MATERIAL_DOCUME_MPC_EXT\ME:DEFINE\SE:END\EI`
(`evidence/ENHINCINX_ZSD_ENH_API_MATDOC.txt`). Active source:
`src/CL_API_MATERIAL_DOCUME_MPC_EXTCM001.txt`, from line 131.

The block calls `model->get_entity_type( 'A_MaterialDocumentHeaderType' )->create_property(…)`
once per field and sets the Edm type, internal type and length:

- **Strings:** `ZZ_LIFNR`(10), `ZZ_TNAME`(35), `ZZ_MODEL`(2), `ZZ_VHCLE`(20),
  `ZZ_ODCDL`(40), `ZZ_REFNO`(16), `ZZ_POST1`(40), `ZZ_EBILL`(12), `ZZ_CHLNO`(16),
  `ZZ_AFRNO`(16), `ZZ_LOVCT`(5), `ZZ_GTPAS`(1), `ZZ_LFSNR`(16), `ZZ_ZFLAG`(1)
- **Dates:** `ZZ_EDATE`, `ZZ_CHLDT`, `ZZ_AFRDT`, `ZZ_LRDAT`
- **NUMC as string:** `ZZ_TOKEN`(10)

Nothing is changed in DDIC. The properties exist only in the runtime model, so they appear in
`$metadata`. `$metadata` was not fetched in this session.

**Hypothesis:** these are the custom MIGO header-tab fields (compare `ZMMT_MIGO_HDR` and the
`ZDACE_CUSTOM_MIGO_HEADER_TAB` BAdI). Not verified.

## 2. Data-provider enhancement: Verified empty

- `ENHHEADER`: `ZSD_ENH_API_MATDOC_CREATE_DOC`, `HOOK_IMPL`, active
  (`evidence/ENHHEADER_ZSD_ENH_API_MATDOC.txt`).
- `ENHOBJ`: only `CLAS CL_API_MATERIAL_DOCUME_DPC_EXT`, with no `METH` row
  (`evidence/ENHOBJ_ZSD_ENH_API_MATDOC.txt`).
- `ENHINCINX`: no row.
- The Enhancement Editor, in display mode, shows an **empty element list**
  (`evidence/ENH_EDITOR_ZSD_ENH_API_MATDOC_CREATE_DOC_elements.txt`).
- None of the 33 method includes of `CL_API_MATERIAL_DOCUME_DPC_EXT` contains an
  `ENHANCEMENT` block (`src/CL_API_MATERIAL_DOCUME_DPC_EXT*`).

## 3. Why the values are dropped: Strong inference

`create_document` (`src/CL_API_MATERIAL_DOCUME_DPC_EXTCM00Q.txt`) calls
`io_data_provider->read_entry_data` into `ty_deep_entity`. The header of that type is
`INCLUDE TYPE cl_api_material_docume_mpc=>ts_a_materialdocumentheadertyp`
(`…DPC_EXTCCDEF.txt`), SAP's static base-model structure, which has no `ZZ_` components. The
method then does `CORRESPONDING if_material_document_api=>ty_header_input( … )` and calls
`io_api->create_material_document`. Nothing on that path carries a `ZZ_` value. The base MPC
type definition itself was not read.

## 4. Posting-layer change: Verified

`ZCL_MM_GOODSMVT_BAPI_CUSTOM→EXTENSIONIN_TO_MATDOC`
(`src/ZCL_MM_GOODSMVT_BAPI_CUSTOM===CM001.txt`) now does two new things:

- For any `IMSEG` line without `EBELN`, it reads `LIPS-VGBEL/VGPOS` for `VBELN/POSNR` and
  fills `EBELN/EBELP`. This is the **delivery-led PO derivation** Submit MIGO needed.
- It maps `IMKPF`/`IMSEG` into `ZCL_MM_MIGO_VALIDATION_FACADE=>validate` and returns the
  first message to `CT_RETURN`.

The old `EXTENSION_IN` `MSEG-LSMNG` branch, with its `line_id = 'LSMNG'` defect, is unchanged.
The new code reads no `ZZ_` field.

---

## Relevance to Modify DI

This is a working template for the **model half** of exposing customer fields on a standard
API without a new service:

- the same implicit enhancement at the end of `DEFINE` in the delivery service's `MPC_EXT`
  would add the `LIKP-ZZ*` fields to `A_OutbDeliveryHeader`;
- the URL is unchanged.

The **data half** (getting the values persisted) is the part this team has not finished, and
it decides the effort. For the delivery API it would mean an enhancement on the header update
that passes the values into the delivery update.

It remains custom ABAP, placed as enhancements inside SAP-generated classes. That supports a
"standard service with enhancement" classification, like Submit MIGO. It carries upgrade risk,
because SAP can regenerate or change those classes.

## Open

- Fetch QS4 `$metadata` for `API_MATERIAL_DOCUMENT_SRV` to confirm the 19 properties are
  advertised.
- Ask the consultant whether `ZSD_ENH_API_MATDOC_CREATE_DOC` is unfinished, and where the
  `ZZ_` values are meant to land.
- `DS4K963268` / `ZAPI_MATERIAL_DOCUMENT_SRV_0001`: purpose and whether it is in use.
