# Immediate handover: `API_OUTBOUND_DELIVERY_0002`

## Objective

Inspect the SAP-standard SEGW project `API_OUTBOUND_DELIVERY_0002` in `QS4/700` and extract its exact request-response surface for the CNF design:

- runtime service and classes;
- entity types, entity sets, keys, properties and navigation;
- supported CRUD operations;
- function imports/actions, HTTP methods, parameters and return types;
- what it can and cannot replace in the CNF API landscape.

Do this read-only. Do **not** inspect Service Maintenance, register services, save, generate, activate, or execute a business posting.

## Live state

- SAP GUI scripting is enabled.
- Scriptable session: `/app/con[2]/ses[0]`.
- System/client/user: `QS4` / `700` / `QNOVATE8`.
- The fresh session is in transaction `SEGW`.
- An older GUI connection, `/app/con[1]`, exposes zero scriptable sessions and already has this project open.
- Consequently, the fresh session currently shows `Open Project` plus the message: `Project 'API_OUTBOUND_DELIVERY_0002' is already open`.
- SAP operations have been stopped at Siddharth's request; the windows were deliberately left untouched.

## Exact next move

1. Dismiss only the duplicate-project message in the fresh session.
2. Release/close the project view in the older GUI window without logging off or saving anything. If that window remains non-scriptable, use desktop control or ask Siddharth to choose **Project > Close** there.
3. Open `API_OUTBOUND_DELIVERY_0002` in `/app/con[2]/ses[0]`.
4. Traverse the SEGW model by technical control IDs and export the required grids/tree nodes to local TSV/Markdown evidence.
5. Produce a compact contract-and-CNF-fit report. Separate SAP-confirmed facts from architectural inference.

## Scripting method

Use 64-bit Windows Script Host; it successfully attaches where PowerShell COM calls fail:

```powershell
& "$env:WINDIR\System32\cscript.exe" //nologo ".\tmp\sap_probe.vbs"
```

Current helper scripts are in `tmp/`:

- `sap_probe.vbs` — lists connections and sessions;
- `sap_open_connection.vbs` — created the scriptable QAS session;
- `sap_open_segw.vbs` — navigates to SEGW;
- `sap_dump_session.vbs` and `sap_dump_windows.vbs` — inspect technical control IDs;
- `sap_open_project_dialog.vbs` and `sap_open_project.vbs` — open the project dialog/project.

Do not assume connection `0`; select the latest connection that has at least one session.

## Findings already worth preserving

- Runtime service: `API_OUTBOUND_DELIVERY_SRV`.
- Runtime classes include `CL_API_OUTBOUND_DELIVE_DPC(_EXT)` and `CL_API_OUTBOUND_DELIVE_MPC(_EXT)`.
- The model exposes 13 entity sets and 15 POST function imports, including picking, batch split, serial-number handling, `PostGoodsIssue`, and `ReverseGoodsIssue`.
- `PostGoodsIssue` has one SEGW parameter: `DeliveryDocument` (`Edm.String`, length 10).
- The standard API can create an outbound delivery from a reference document, including a sales order or STO, and supports delivery changes, picking/batch handling, PGI, and GI reversal.
- It does **not** by itself establish coverage for shipment creation, shipment cost, billing/invoice, e-invoice, e-way bill, or destination GR. Those require separate standard-API discovery or custom gaps.

The immediate task is to prove the detailed contract from the live project—not to redesign the entire CNF API landscape yet.
