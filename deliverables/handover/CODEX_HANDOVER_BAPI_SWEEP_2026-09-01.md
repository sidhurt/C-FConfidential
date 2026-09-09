# Handover to Codex — `BAPI_GOODSMVT_CREATE` caller sweep

**Prepared:** 1 September 2026, evening
**Scope of this document:** the where-used caller sweep only. Picks up from `deliverables/handover/LEGACY_HANDOVER_DI_MIGO_2026-09-01.md` §9.4. Nothing about API design, client communication or implementation planning is included here.

---

## 1. Starting state

Handed the DI/MIGO handover with §16 as the queue. Relevant starting facts:

- QS4 session was live, sitting in SE37 → Class Builder → `ZMM_IFMS_AUTO` → `IF_HTTP_EXTENSION~HANDLE_REQUEST`.
- The `BAPI_GOODSMVT_CREATE` where-used result had already been run and its 24 hits captured by name in the prior handover §9.2.
- `FINDINGS.md` conclusion at that point: *"no inspected caller yet demonstrates a complete Delivery + Delivery Item-only pattern."*
- The prior session had recorded SAP GUI Scripting reporting zero connections, so the sweep was pending.

**I did not re-run the where-used list.** I navigated away from it to SE38 and worked from the names captured in §9.2. If that list was incomplete or misread, this sweep inherits that gap.

---

## 2. Method

Read-only SAP GUI Scripting throughout. No program opened in Change mode, nothing edited, activated, executed or posted.

Capture route: SE38 → `Program > Display` (`mbar/menu[0]/menu[2]`) → `SelectAll` on the editor control → `Utilities > Block/Clipboard > Copy to Clipboard` → `Get-Clipboard -Raw` → file.

Two things that cost time and are worth knowing:

- **The editor control id varies by screen.** `wnd[0]/usr/cntlEDITOR/shellcont/shell` for the ABAP editor; a tab-strip path under `tabsFUNC_TAB_STRIP/tabpSOURCE` in Function Builder. `grab-se38-source.vbs` now tries a list.
- **The Copy-to-Clipboard submenu index differs.** `mbar/menu[3]/menu[8]/menu[3]` in the ABAP editor, `mbar/menu[3]/menu[7]/menu[3]` in Function Builder. The script checks the menu text before selecting, and tries both.
- `editor.GetText` fails and `editor.Text` returns the control name (`SAPGUI.AbapEditor.1`), not the source. Clipboard is the only working route. `extract-abap-editor.vbs` and `extract-editor-any.vbs` do not work for this purpose — do not retry them.

Scripts created (all in `outputs/sap-gui-script/`):

`goto-se38.vbs`, `open-se38-source.vbs`, `grab-se38-source.vbs`, `sweep-sources.ps1`, `dump-buttons.vbs` (button/menu tooltips), `extract-editor-any.vbs` (failed approach, retained), `open-se37-fm.vbs`, `fb-attributes.vbs`, `fb-proctype.vbs`, `fb-where-used.vbs` / `fb-where-used2.vbs` (both failed — see §6), `se16-marv.vbs` (never ran — see §7).

`sweep-sources.ps1 NAME1 NAME2 ...` is the driver. It skips names already captured and reports OK/FAIL per name.

---

## 3. What was swept

15 sources captured to `sessions/2026-09-01-bapi-field-derivation/src/`:

`ZDACE_GOODS_MOVEMENT_CLS`, `ZEWME001_CUSTOM_MIGO_TR_FORM`, `ZEWM_CUSTOM_MIGO_TR_FORM`, `ZLEIILMSDOCUMENTS_GOODSREC`, `ZLEIILMSDOCUMENTS_GRN_BTST`, `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01`, `ZMMR_GAS_CYL_FRM`, `ZMMR_STO_GR_SUB`, `ZMM_GI_LOAN`, `ZMM_INITIAL_STOCK_UPLOAD_F`, `ZMM_INITIAL_STOCK_UPLOAD_F_STG`, `ZMM_MIGO_POSTING_FORMS`, `ZPP_MP_DIVERSION_AUTOPGI_PAI`, `ZSD_BACK_SHORTAGE_CLASS`, `ZSD_INTRCO_MIGO`.

Note: `LZSD_PURULIAU05` opens Function Builder on function module **`ZSD_INTRCO_MIGO`**; it is saved under that name.

All 15 confirmed to contain a `BAPI_GOODSMVT_CREATE` call.

---

## 4. What the sweep found

### 4.1 The headline — the prior conclusion is superseded

**A complete delivery-item-only movement-101 path exists in QS4.** Two ILMS includes pass **no `po_number` and no `po_item` to the BAPI at all**:

- `ZLEIILMSDOCUMENTS_GRN_BTST` — the minimal form
- `ZLEIILMSDOCUMENTS_GOODSREC` — the same plus controls

`GRN_BTST` in full:

```abap
material   = LIPS-MATNR      entry_qnt  = LIPS-LFIMG
plant      = LIKP-WERKS      entry_uom  = LIPS-MEINS
stge_loc   = 'GDF'           batch      = LIPS-CHARG
move_type  = '101'           mvt_ind    = 'B'
deliv_numb = LIPS-VBELN      deliv_item = LIPS-POSNR
deliv_numb_to_search = LIPS-VBELN   deliv_item_to_search = LIPS-UECHA
```

Header: `pstng_date`/`doc_date` = `sy-datum`, `gm_code = '01'`. Then `BAPI_GOODSMVT_CREATE`, then `BAPI_TRANSACTION_COMMIT`.

### 4.2 `mvt_ind = 'B'` with delivery-only references

`'B'` means *goods receipt for purchase order*. These programs set it while supplying only delivery numbers, so SAP resolves the PO from the delivery itself. The PO relationship persists inside SAP; the caller neither supplies nor derives it.

This reconciles the earlier position ("SAP may still follow the PO/STO relationship internally") with the new evidence ("no PO is passed"). Both are true.

### 4.3 Custom fields are written by the BAPI caller, not the BAdI

After a successful commit, `GOODSREC` and `GRN_BTST` both do `MODIFY zmmt_migo_hdr` themselves — `mblnr`, `mjahr`, `lifnr`, `vhcle`, `token`, `model` (from `ZLET_VEHICLE`), `tname` (from `I_CUSTOMER`), and in the DDC branch `lrdat`, `lfsnr`, `ebill`, `edate`, `afrno`, `afrdt`, `lovct`, `chldt`, `chlno`.

Grep across all 15 sources confirms **only these two programs write `ZMMT_MIGO_HDR`**. `ZMMR_MIGO_SCREEN_ADD` reads it for display.

Derivation chain, all reachable from delivery + item:

```
ZLETILMSDELIVERY  → token, lrnumber, hzrdmanifest/dt/ct
ZLETILMSTOKEN     → vehical_no, fwdagent, ddctrid, docplant, quantity, mfrgr
ZLET_VEHICLE      → v_typ
I_CUSTOMER        → customerfullname
ZLETDDCREGISTER   → challanno/dt, gstinvno/dt, ewaybillno/dt
```

### 4.4 Controls found in `GOODSREC`

- **Duplicate GR:** `SELECT SINGLE MAX( mblnr ) FROM matdoc WHERE vbeln_im = <dlv> AND vbelp_im = <item> AND bwart = '101' AND cancelled = ' '` → non-initial raises `ZLE/203` with the existing document.
- **Replay:** `ZLETILMSDELIVERY-ZMIGO_PROC` set before, cleared after; collision raises `ZLE/070`.
- **Over-receipt:** quantity capped at `LIPS-LFIMG`. Rail/multimodal (`EKPV-VSBED = '04'`) additionally caps via `BAPI_PO_GETDETAIL` at `withdr_qty - deliv_qty`.
- **Shortage:** difference appended as a second item with `stck_type = '3'` (blocked stock), incoterm-dependent (`EXW`/`FOR`/`EXN`/`FON`).
- **`EXTENSIONIN` is populated** in the DDC branch: structure `MSEG`, field `LSMNG`. Closes the prior open question about whether extensions are used on the BAPI path.

### 4.5 Secondary findings

- `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01` supplies PO, but derives it: `po_number = LIPS-VGBEL`, `po_item = LIPS-VGPOS`.
- `ZSD_INTRCO_MIGO` (group `ZSD_PURULIA`, "Delivery Create") is a pure transaction envelope — passes header/items through unchanged, hardcodes `gm_code = '01'`, commits on success, rolls back on failure. No derivation, no validation, no reads. Attributes confirm **Regular Function Module, not RFC-enabled**.
- `ZMM_MIGO_POSTING_FORMS` 101 branch takes material and plant from an uploaded file (`gs_file3-matnr`, `gs_file3-werks`) — confirms the prior characterisation. Delivery assignment commented out.
- `ZDACE_GOODS_MOVEMENT_CLS` is a 101/`mvt_ind 'B'` caller with four call sites, supplying delivery **and** PO plus all fields from its own internal `rb1_final` table.

---

## 5. Filtering — and how it was verified

Most of the 24 hits are not 101 postings. First pass grepped literal `move_type = '101'` / `gm_code = '..'`:

| Program | Movement |
|---|---|
| `ZSD_BACK_SHORTAGE_CLASS` | `551`, `gm_code 03` |
| `ZEWME001_CUSTOM_MIGO_TR_FORM`, `ZEWM_CUSTOM_MIGO_TR_FORM` | `gm_code 04` |
| `ZMMR_GAS_CYL_FRM` | `309`, `gm_code 04` |
| `ZMM_GI_LOAN` | `gm_code 03` |
| `ZPP_MP_DIVERSION_AUTOPGI_PAI` | `344`, `413`, `gm_code 04` |
| `ZMM_INITIAL_STOCK_UPLOAD_F`, `_STG` | from upload file (`<fs_header>-mvt_typ`) |

**The literal grep is not sufficient on its own.** `ZDACE_GOODS_MOVEMENT_CLS` sets `CONSTANTS lc_movtyp VALUE '101'` and was missed by the first pass — caught only on a second look at movement-type sources. Assume other programs may do the same.

Second pass counted every occurrence of `'101'` in the dismissed files:

- Zero occurrences: `ZSD_BACK_SHORTAGE_CLASS`, `ZMMR_GAS_CYL_FRM`, `ZMM_GI_LOAN`, `ZMM_INITIAL_STOCK_UPLOAD_F`, `_STG`.
- `ZEWME001` / `ZEWM_CUSTOM_MIGO_TR_FORM`: one each, `SELECT ... FROM matdoc WHERE ... ( bwart = '101' OR bwart = '105' )` — a **read** for reporting, not a posting.
- `ZPP_MP_DIVERSION_AUTOPGI_PAI`: two, both `SELECT ... FROM matdoc WHERE bwart = '101'` — **reads**.

So the dismissals hold on two independent checks. The 101-posting population is eight, of which two pass no PO.

---

## 6. What this sweep does NOT cover

Be explicit about these; do not let them be read as closed.

1. **The where-used list was not re-run.** Worked from names captured in the prior handover §9.2. The UI groups class methods and program objects, so the visible names may not equal 24 distinct objects.
2. **`ZSD_INTRCO_MIGO`'s callers were never traced.** It is a pass-through wrapper, so a where-used on `BAPI_GOODSMVT_CREATE` will not surface whatever logic calls it. Any derivation there is unseen. Attempted via the Function Builder where-used button (`tbar[1]/btn[39]`) and via `Utilities > Where-Used List` (`mbar/menu[3]/menu[10]`) — neither fired; screen stayed on `SAPLSFUNCTION_BUILDER` 3000 with no modal. Route via SE37 initial screen + `open-bapi-where-used.vbs` / `run-bapi-where-used.vbs` instead. Stopped on instruction, not because it was resolved.
3. **Movement types set from variables cannot be ruled out statically.** `ZMM_INITIAL_STOCK_UPLOAD_F` takes `mvt_typ` from an upload structure. Judged an upload tool, not verified.
4. **`ZMMR_MIGO_SCREEN_ADD` and `ZCLMM_MB_MIGO_BADI` were not captured in this sweep.** Everything said about them comes from the prior session's Codex attachments, secondhand. Their source is not in `src/`.
5. **No enhancement enumeration.** No SE18/SE19 sweep of MIGO or material-document BAdI implementations, no implicit/explicit enhancement points, no SMOD/CMOD exits. §10 of the prior handover remains open on all of these.
6. **No runtime proof of anything.** Everything here is static source reading. Which logic actually executes on the MIGO GUI, SE37 BAPI and OData paths is unproven.
7. **`MB_MIGO_BADI` validations remain a live gap.** Data capture is answered (§4.3). The validation logic in `POST_DOCUMENT` will not fire on a BAPI/OData path, and which of those rules C&F depends on is unresolved.

---

## 7. SAP session state

**`Connections=0`** at handover. The QS4 session closed after the sweep completed.

Last confirmed state during the sweep was SE38 displaying `ZMM_MIGO_POSTING_FORMS`, then Function Builder displaying `ZSD_INTRCO_MIGO`. Nothing was left in Change mode.

`se16-marv.vbs` was written to read `MARV` (MM period per company code) but **never ran** — the connection had already dropped. It is untested.

---

## 8. Files produced

- `sessions/2026-09-01-bapi-field-derivation/src/` — 15 ABAP sources, UTF-8.
- `sessions/2026-09-01-bapi-field-derivation/FINDINGS.md` — rewritten. The old "no delivery-only caller exists" conclusion was **replaced**, not appended to, because leaving it would have contradicted the new evidence. Added: the delivery-only pattern, the `GOODSREC` derivation table, the controls, the `mvt_ind 'B'` reconciliation, the derivation matrix, and the two things the sweep did not close.
- `outputs/sap-gui-script/` — the scripts listed in §2.

---

## 9. Continuation point

In priority order:

1. **Trace `ZSD_INTRCO_MIGO`'s callers** via SE37 where-used from the initial screen. The only known unexamined path to the BAPI.
2. **Capture `ZMMR_MIGO_SCREEN_ADD` and `ZCLMM_MB_MIGO_BADI` source directly** into `src/`, replacing reliance on the attachments. Then separate the BAdI's validation logic from its data-capture logic — only the former is still a gap.
3. **Re-run the where-used** and reconcile against §9.2's captured names, to confirm nothing was missed in the original capture.
4. **Enumerate MIGO / material-document BAdI implementations and exits** (SE18/SE19, SMOD/CMOD). Untouched.
5. **Runtime work** — needs an open posting period and a reserved PGI-complete, GR-pending delivery item. Neither was available.
