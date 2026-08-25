# Handover — Standard SAP API discovery for CNF

> **Superseded status (2026-08-15):** catalogue discovery and Tier-A extraction are complete. Retain this file only for SAP GUI scripting history and discovery protocol. Current findings are in `sessions/2026-08-15-standard-api-discovery/TIER_A_DEEP_DIVE_FINDINGS.md`, the current matrix is `CNF_STANDARD_API_MATRIX.tsv`, and the implementation path is `deliverables/CNF_STANDARD_API_SOLUTION_AND_TEST_PLAN.md`.

**Date:** 2026-08-14
**System:** `QS4` / client `700` / user `QNOVATE8` (SAP QAS, `/H/10.220.2.236/S/3200`)
**Audience:** the next AI agent on this project
**Supersedes:** `SAP_SEGW_SCRIPTING_HANDOVER.md` (2026-08-05). That document's scope (six custom SEGW projects) and one of its factual claims are obsolete — see §7.

---

## 1. The mandate — read this before doing anything

The project direction **changed** on 2026-08-14. If you carry forward the older framing you will do the wrong work.

**Custom APIs are disavowed.** The business has decisively rejected building custom `ZCNF_*` OData services. This is a hard stop, not a preference.

**The deliverable is standard SAP.** Most of the C&F architecture already exists and works in the client's landscape with SAP handling it. Roughly **2,700 standard SAP-exposed OData services** are available. Somewhere in there are the **~10–15** that serve C&F operations. The business states they all exist as standard.

**The job is discovery and provisioning**, in this order:

1. Search the ~2,700 and find legitimate candidate services per business process.
2. Where several services have similar names, **research the delta** and justify which one is correct.
3. Provision (activate) the chosen services.
4. Build custom **only** where a workflow genuinely has no standard equivalent.

**`CNF_API_Request_Response_Specification_v1.7.xlsx` is now reference only.** Located at
`outputs/cnf_api_contract_v17/` (also in the codex worktree at
`C:\Users\sidmy\.codex\worktrees\2a63\shree-cement-cnf-agent-cowork\outputs\019ff55e-v17-check-migo-removal\`).

It remains **excellent and authoritative** for: confirmed business processes, what each API must do, and business expectations per operation. Its `Proposed service` column (`ZCNF_DELIVERY_SRV`, etc.) and its custom-wrapper methodology are **dead**. Use it as the context and vocabulary for discourse about the processes. Do not use it as an implementation plan.

The eleven business APIs it defines (the demand side of the search):

| ID | Name | Class |
|---|---|---|
| API-01 | Check MIGO / Pending Receipt | C |
| API-02 | Submit MIGO | S |
| API-03 | Create DI | S |
| API-04 | Stock Availability | C |
| API-05 | Shipment Cost Estimate | X / S |
| API-06 | Shipment, PGI & Invoice | X |
| API-07 | Invoice Correction | S / X |
| API-08 | E-Way Bill Extension | S |
| API-09 | Modify DI | S |
| API-11 | Create STO PO | candidate |

(`S` = standard SAP operation wrapped · `C` = composite read · `X` = multi-stage / no standard end-to-end equivalent. API-10 was removed in v1.7.)

**QS4 is the quality system and permits no create / update / delete operations.** Everything is read-only. Do not post, register, activate, save, generate or check.

---

## 2. What was actually done in this session

One service was studied end to end as a pilot: **`API_OUTBOUND_DELIVERY_0002`** (SEGW project), whose runtime service is `API_OUTBOUND_DELIVERY_SRV`.

Extracted read-only via SAP GUI scripting:

- 823 SEGW tree nodes (full recursive expansion of the project)
- 52 ALV grids (entity types, properties, entity sets, complex types, associations, association sets, function imports, per-FI parameters, runtime artifacts, one data-source mapping)

No SAP object was created, changed, saved, generated, activated or registered.

---

## 3. Scripting method that works — reuse this

### Attach

Use **64-bit Windows Script Host with VBScript**. PowerShell COM calls to the SAP scripting engine fail on this machine; `cscript.exe` works.

```bash
"$WINDIR/System32/cscript.exe" //nologo ".\tmp\sap_probe.vbs"
```

```vbscript
Set rot    = CreateObject("SapROTWr.SapROTWrapper")
Set sapGui = rot.GetROTEntry("SAPGUI")
Set app    = sapGui.GetScriptingEngine
```

### Never hardcode the connection index

The connection id **changed mid-session** from `/app/con[2]` to `/app/con[0]`. Always select the newest connection that actually exposes a session:

```vbscript
For i = app.Children.Count - 1 To 0 Step -1
  If app.Children.Item(CLng(i)).Children.Count > 0 Then
    Set conn = app.Children.Item(CLng(i))
    Exit For
  End If
Next
```

A connection showing `Sessions=0` means either no logged-in session behind it, or the scripting handshake is not active. Check `conn.DisabledByServer` to tell the difference — `False` means the server permits scripting.

### Finding controls — do not hardcode paths

- **The SEGW tree** is a `GuiShell` whose `.Text` is `SAP.TableTreeControl.1`. Walk `wnd[0]/usr` and match on that text. The splitter path differs between SEGW screens.
- **ALV grids enumerate as `GuiShell`, not `GuiGridView`.** Match on `.Text` containing `GridViewCtrl`. Filtering by `Type = "GuiGridView"` finds nothing — this cost a debug cycle.
- The Mapping screen carries a **second** tree (the data-source browser) plus an HTML control. Dump by explicit control id when you need it.

### The SEGW tree loads lazily

Unexpanded nodes report `GetNodeChildrenCount = 0` even when they have children. A guard like `If childCount <> 0 Then ExpandNode` expands nothing. Attempt `ExpandNode` on **every** in-scope node, track visited keys in a dictionary, and loop passes until no new nodes appear. The pilot converged in 4 passes: 7 → 104 → 527 → 823 nodes.

### Read container grids, not leaf nodes

Selecting a **container** node (`Properties`, `Entity Sets`, `Function Imports`, `Function Import Parameters`, `Associations`, `Runtime Artifacts`) shows an ALV listing **all its children with full attributes**. This is the single biggest efficiency win: 52 selections instead of 800.

Grid reading API: `.RowCount`, `.ColumnOrder` (collection), `.GetDisplayedColumnTitle(colId)`, `.GetCellValue(row, colId)`.

### Open a project via the menu, never a double-click

```vbscript
session.FindById("wnd[0]/mbar/menu[0]/menu[1]").Select   ' Project > Open
session.FindById("wnd[1]/usr/ctxtPROJECT").Text = "<PROJECT>"
session.FindById("wnd[1]/tbar[0]/btn[8]").Press
```

---

## 4. Hazards — all of these were hit for real

| Hazard | What happens | Handling |
|---|---|---|
| **Double-clicking a SEGW tree node** | Double-clicking `Service Maintenance` opened a **Create Project** dialog pre-filled to copy the project. SAP rejected it — *"You are not authorized to create project 'API_OUTBOUND_DELIVERY_0002'"* — so nothing was created, but this is a genuine write attempt | Use menu navigation. If a modal appears, read it before closing. `wnd.Close` is the cancel path and confirms nothing |
| **Transient `Permission denied: 'GetScriptingEngine'`** | Script dies instantly | Retry; it clears on its own |
| **Connection replaced mid-session** | `Connections=0`, then a new `con[0]` appears. The SEGW project view is lost | Re-probe, reopen the project. Extracted files are unaffected |
| **Shell timeout ≠ script stopped** | The 5-min wrapper timeout kills the shell while `cscript.exe` keeps running against SAP | `tasklist //FI "IMAGENAME eq cscript.exe"` before rerunning, or you get two scripts driving one session |
| **VBScript is case-insensitive** | A variable `nodePath` collides with a function `NodePath` → `Name redefined` compile error | Distinct names |
| **Compile errors produce no stdout** | Piping the first run through `grep` shows *nothing at all* and looks like a silent hang | Run unfiltered first |
| **`session.CreateSession` did nothing** | No second session | Use `okcd = "/o<TCODE>"` instead |
| **`/nSEGW` navigation timed out once** | >5 minutes, no response | Allow long timeouts; verify state before retrying |

---

## 5. Evidence on disk

| Path | Contents |
|---|---|
| `sources/SRC-SYS-20260814-01_QS4_700_SEGW_API_OUTBOUND_DELIVERY_0002/SEGW_TREE.tsv` | All 823 nodes: key, parent, depth, children, path |
| `.../GRID_MANIFEST.tsv` | The 52 grids with row/column counts |
| `.../grids/*.tsv` | One TSV per grid. Column-id row, column-title row, then data |
| `sessions/2026-08-14-api-outbound-delivery-0002/README.md` | Design-time contract report with confidence labels |
| `sources/SRC-SYS-20260805-02_QS4_700_GATEWAY_SERVICE_CATALOG.xlsx` | 522 **registered** Gateway services (from the earlier session) |
| `tmp/qs4_evidence/` | SE37/SE38 BAPI extractions from 2026-08-13 — see §9 |

TSVs are UTF-16. `Import-Csv -Delimiter "\`t"` in PowerShell reads them directly.

### Scripts (`tmp/`)

| Script | Purpose |
|---|---|
| `sap_probe.vbs` | List connections/sessions. **Run first, always** |
| `sap_scripting_diag.vbs` | `DisabledByServer`, connection string — diagnose `Sessions=0` |
| `sap_segw_state.vbs` | Windows, titles, status bar, working-area control tree (skips menubar) |
| `sap_segw_export_project.vbs` | `EXPAND <outdir> [project]` — scoped recursive tree export |
| `sap_segw_export_all_grids.vbs` | `<outdir> [project]` — selects every container node, exports each ALV |
| `sap_segw_dump_node_grid.vbs` | `"<path suffix>" [outfile] [ALLOW_SERVICE_MAINTENANCE]` — one node, ad-hoc |
| `sap_segw_open_named_project.vbs` | `"<PROJECT>"` — navigate to SEGW and open a project via the menu |
| `sap_dump_tree_by_id.vbs` | Dump any tree by explicit control id (for the data-source tree) |
| `sap_close_modals.vbs` | Close stray modals top-down, safely |
| `sap_new_session_tcode.vbs` | Open a tcode in a second session via `/o` |

Both SEGW exporters scope to a target project and skip `Service Maintenance` unless explicitly opted in.

---

## 6. What was found in `API_OUTBOUND_DELIVERY_0002`

**Model size:** 13 entity types · 13 entity sets · 4 complex types · 14 associations · 13 association sets · 15 function imports.

**Runtime artifacts:** `API_OUTBOUND_DELIVERY_MDL` (`R3TR IWMO`), `API_OUTBOUND_DELIVERY_SRV` (`R3TR IWSV`), and `CL_API_OUTBOUND_DELIVE_DPC` / `_DPC_EXT` / `_MPC` / `_MPC_EXT`.

**All 15 function imports are `POST`** and return complex types, not entity sets. 13 return message envelopes; only `CreateBatchSplitItem` returns real data. Includes `PostGoodsIssue` and `ReverseGoodsIssue`.

**CRUD annotations** (the useful part): `A_OutbDeliveryHeader` is C/U/D; `A_OutbDeliveryItem` is U/D but **not** creatable; five entity sets carry no CRUD annotation at all.

**Response envelope** is `BAPIRET2`-shaped: `SystemMessageType` (S/E/W/I/A), `SystemMessageIdentification`, `SystemMessageNumber`, `SystemMessageVariable1..4`. Cardinality `0..n` means a **collection** of messages — success only if no row is `E` or `A`.

Full detail is in `sessions/2026-08-14-api-outbound-delivery-0002/README.md`.

### Two findings that matter beyond this service

**1. It is not registered.** `API_OUTBOUND_DELIVERY_SRV` does **not** appear in the 522-row Gateway catalogue. Ten `API_*` services are registered on QS4; this is not one of them.

This is **not a blocker — it is the shape of the whole project.** ~2,700 available vs 522 activated. The gap *is* the provisioning backlog, and identifying which subset to activate is the deliverable.

Registered services appear as a pair: technical name `Z<NAME>` → external name `<NAME>` (e.g. `ZAPI_SALES_ORDER_SRV` → `API_SALES_ORDER_SRV`).

**2. Create-from-predecessor is not demonstrated.** The header entity type has exactly **one** creatable-annotated property, `ShippingPoint`. The item is not creatable. `OrderID` and `OrderItem` exist but are not creatable. There is no `ReferenceSDDocument` property anywhere.

Either this is a deep create the annotations don't describe, or this service does not offer reference-based creation. **SEGW cannot distinguish the two.** Since Create DI is where the entire C&F flow begins, this is the most important open question about this service.

### Mapping against the v17 process list

| v17 API | Covered? | Basis |
|---|---|---|
| API-09 Modify DI | **Strong fit** | `A_OutbDeliveryItem` updatable; `ActualDeliveryQuantity` updatable — matches "quantity-only while DI is open" |
| API-06 — PGI portion | **Direct hit** | `PostGoodsIssue`, `ReverseGoodsIssue` |
| API-06 — batch determination | **Partial** | `PickAndBatchSplitOneItem`, `CreateBatchSplitItem` |
| API-03 Create DI | **Unproven** | See finding 2 above |
| Invoice / e-invoice / e-way / shipment | **No** | Different services |

### Unexamined siblings already loaded on the box

The SEGW tree showed three projects side by side:

- **`API_OUTBOUND_DELIVERY`** — the sibling generation. Comparing it against `_0002` is the cheapest available delta exercise and may resolve the Create DI question. **Do this first.**
- **`API_BILLING_DOCUMENT`** — candidate for API-06 invoice and API-07 correction.
- `API_OUTBOUND_DELIVERY_0002` — done.

---

## 7. Correction to the previous handover

`SAP_SEGW_SCRIPTING_HANDOVER.md` (2026-08-05) states the standard API "can create an outbound delivery from a reference document, including a sales order or STO."

**The extracted model does not support that claim.** See §6 finding 2. Treat it as unproven.

That document is also scoped to six *custom* SEGW projects (`ZAPI_PLANT_WEIGHBRIDGE_RMC`, `ZCRM_SO_REJECT`, `ZCRM_STAGEGATE`, `ZCUSTOMER_DETAIL`, `ZMM_SCRUM_SER_PO`, `API_SALES_ORDER`). Under the current mandate that scope is no longer the target, though the custom projects remain useful evidence of what the client has already built bespoke.

---

## 8. What SEGW can and cannot tell you

Calibrate expectations before spending a session on a service.

**SEGW gives you roughly 80% of the contract shape and 0% of the behaviour.**

Reliable from SEGW: resource model, full typed schema (field, Edm type, precision, scale, length, nullable, key), relationships and `$expand` targets, allowed verbs per collection, function imports with method/parameters/return type, response complex types.

Endpoints are *derivable* because OData's URL grammar is protocol-fixed:

```
/sap/opu/odata/sap/<SERVICE>/A_OutbDeliveryHeader('0080000123')?$expand=to_DeliveryDocumentItem
/sap/opu/odata/sap/<SERVICE>/PostGoodsIssue?DeliveryDocument='0080000123'      [POST]
```

**Not available from SEGW:** the base URL and whether the service is callable at all; whether the annotations are actually true; real mandatory rules; the error catalogue; idempotency, commit and locking semantics; auth / CSRF / ETag.

**Annotations are declarations, not enforcement.** `MPC_EXT` can rewrite them at runtime and `DPC_EXT` decides actual behaviour. The `ShippingPoint`-only finding is exactly this trap.

**`$metadata` is the authoritative published contract** and supersedes SEGW wherever they differ. It is one read-only GET and contains everything 52 grid reads produced. For scale, the efficient pattern is: **shortlist via catalogue/SEGW, confirm via `$metadata`.** An unregistered service has no `$metadata` — which is the same fact as "no endpoint", seen from the other side.

Mandatory-ness is decided in four places, and layers 2 and 4 routinely disagree: (1) OData protocol — keys; (2) metadata annotations — *descriptive only, does not reject*; (3) `DPC_EXT` code; (4) BAPI and SAP config — the real gatekeeper, including conditional rules like batch-managed materials and serial profiles that no metadata can express.

---

## 9. Architectural consequence of dropping custom — unresolved

The v17 request/response fields are **wrapper-shaped**. `RequestId`, `SourceSystem`, `IsReplay`, `MessageCode`, `BusinessFlow` are constructs a custom `ZCNF_*` service would have provided. **Standard SAP OData provides none of them.**

Some map cleanly onto the `BAPIRET2` envelope — `Status` → `SystemMessageType`, `MessageCode` → `SystemMessageIdentification` + `SystemMessageNumber`, `Message` → `SystemMessageVariable1..4`.

**Idempotency and replay do not map at all.** With custom disavowed, something else must own them — CPI, T2, or the portal. This is a business/architecture decision, not a lookup, and it **recurs on every Command-class API**. Raise it early.

Separately: `tmp/qs4_evidence/` holds SE37/SE38 extractions of `BAPI_GOODSMVT_CREATE`, `BAPI_OUTB_DELIVERY_CREATE_SLS` / `_STO`, `BAPI_OUTB_DELIVERY_CHANGE`, `BAPI_OUTB_DELIVERY_CONFIRM_DEC`, `BAPI_BILLINGDOC_CREATEMULTIPLE`, `BAPI_BILLINGDOC_CANCEL1`, `BAPI_MATERIAL_AVAILABILITY`, `BAPI_SHIPMENT_COST_ESTIMATE`, `BAPI_PO_CREATE1`. These are the *function-module* layer, relevant only if a standard OData service turns out not to exist for a given process. Under the current mandate they are fallback evidence, not the primary track.

---

## 10. Do not repeat these mistakes

- **Do not write API contracts from one studied service.** A request/response workbook was built in this session covering only `API_OUTBOUND_DELIVERY_0002`. It was rejected, correctly. `deliverables/SAP_API_OUTBOUND_DELIVERY_SRV_Request_Response.xlsx` should be treated as **scrap** — do not extend it, do not cite it.
- **Do not organize deliverables by SAP artifact.** The workbook had one sheet per function import (`PostGoodsIssue`, `PickOneItem`). `PickOneItem` is not a business API. Organize by the **business API list** (API-01…API-11); SAP artifacts are the answer, never the index.
- **Do not treat the `Creatable` annotation as truth.**
- **Do not trawl 2,700 services blind.** Drive from the v17 demand list.
- **Do not double-click SEGW tree nodes.**
- **Do not build another sheet until the candidate service set exists.**

---

## 11. Next steps

**Step 1 — Get the inventory.** Ask whether the business can supply the ~2,700-service list they showed; a supplied list is faster and more authoritative than deriving one. Otherwise derive it from the system, which is one read-only query rather than per-service GUI scraping:

- `SE16` → `TADIR`, `PGMID = R3TR`, `OBJECT = IWSV` → every OData runtime service in this landscape
- same with `OBJECT = IWPR` → the SEGW projects behind them
- filter to the `API_*` prefix — SAP's naming for released integration APIs — which removes most UI and internal services

**Step 2 — Shortlist by domain.** Keyword-match candidate names against the v17 processes: `DELIVERY`, `BILLING`, `GOODSMVT` / `MATERIAL_DOCUMENT`, `SHIPMENT`, `STOCK`, `PURCHASEORDER`, `EWAYBILL` / `EDOCUMENT`. Expect ~2,700 to collapse to a few dozen.

**Step 3 — Resolve deltas.** For each business process with multiple candidates, compare entity sets, function imports and version. Start with `API_OUTBOUND_DELIVERY` vs `API_OUTBOUND_DELIVERY_0002` — the scripts are ready and it directly addresses the Create DI gap.

**Step 4 — Confirm registration status** per chosen service against the 522-row catalogue, and produce the activation list. That is the provisioning deliverable.

**Step 5 — Only then** discuss contracts, on the v17 spine, one sheet per business API.

---

## 12. State at handover

- SAP session was last seen at **SAP Easy Access**, connection `/app/con[0]`, `QS4` / `700` / `QNOVATE8`, scripting enabled (`DisabledByServer = False`).
- **A `cscript.exe` may still be attached** — the last `/nSEGW` navigation timed out at 5 minutes. **Check `tasklist` before driving SAP again.**
- The user instructed that desktop/computer-use control be stopped. Screenshot work, if genuinely needed, should be delegated to a Sonnet subagent, and desktop access requires explicit user approval each time.
- No SAP object was created, changed, saved, generated, activated or registered at any point.
