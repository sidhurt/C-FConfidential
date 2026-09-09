# Legacy handover — C&F Submit MIGO investigation

**Prepared for:** a successor investigator continuing Siddharth's work  
**Prepared:** 1 September 2026  
**Repository:** `C:\Users\sidmy\Downloads\shree-cement-cnf-agent-cowork-20260729T062834Z-1-001\shree-cement-cnf-agent-cowork`  
**SAP system:** QS4, client 700  
**Current phase:** R&D and evidence gathering; no final delivery-only implementation has been proved

## 1. Read this first

Siddharth is the bridge between the SAP functional/ABAP side and the CPI/portal side. He needs two levels of output:

1. Internally, be technically exact and distinguish what is proved, inferred and still unknown.
2. For the client, translate the result into simple SAP/business language. Do not lead with class names, method names or protocol mechanics unless they ask.

The current requirement is not “remove PO everywhere in SAP.” It is:

- the C&F caller should identify the receipt by **Outbound Delivery Number + Delivery Item**;
- PO Number and PO Item must not be mandatory caller inputs;
- the receipt must be controlled against the selected delivery quantity, not the full PO quantity;
- Material Document Number and Year must be returned;
- the user-visible business operation should be one **Submit MIGO POST**;
- the stakeholders do not want a separate business GET and are concerned that every API call costs money.

The central technical question is whether QS4 already has a reusable delivery-based derivation path, or whether a wrapper must be built to read the delivery internally, derive the BAPI fields and invoke the posting logic.

Do not collapse these different questions:

- Can PO fields be absent from the external request? **Yes.**
- Can the current direct standard OData request contain no PO fields? **Yes; a PO-free direct-input collection now exists.**
- Can the current standard endpoint be called with literally only Delivery + Item? **Not yet proved.**
- Can a custom endpoint expose only Delivery + Item and derive the rest inside SAP? **Architecturally yes, and existing QS4 code proves this derivation-wrapper pattern in other scenarios.**
- Does that remove the underlying STO/PO from SAP document flow? **No.** PO/STO may remain an internal predecessor without being a caller-facing field.

## 2. Current defensible position

Use this wording until the remaining live tests are complete:

> C&F Submit MIGO is being designed as an outbound-delivery-referenced receipt. PO and PO Item have been removed from the caller-facing request. The direct standard SAP API can already be exercised in a PO-free form when the posting fields are supplied. A literal Delivery Number + Delivery Item-only request requires SAP-side derivation of Material, receiving Plant, Storage Location, open Quantity and Unit, followed by delivery-level validation and posting. Existing custom programs prove that QS4 already uses server-side derivation before calling `BAPI_GOODSMVT_CREATE`, but no inspected movement-101 caller has yet proved the complete delivery-item-only derivation path. That sweep and a fresh-delivery runtime test remain open.

Do not say any of the following as established fact:

- “The standard API derives every field from the delivery.”
- “The BAPI requires PO.”
- “The BAPI never requires Material/Plant/Quantity/Unit.”
- “All MIGO enhancements run when the BAPI or OData service posts.”
- “All custom enhancements have been covered.”
- “Delivery `9004953294` is ready” without rechecking PGI and GR status.

## 3. Meeting evidence and what the stakeholders actually asked for

Primary source: [`sources/SRC-MTG-20260831-01_transcript.en.txt`](../../sources/SRC-MTG-20260831-01_transcript.en.txt). Cross-read the Hindi transcript for technical nouns. The 31 August meeting is not yet formally reconciled in the registers, and speaker-to-name mapping is unconfirmed.

### 3.1 Reference and request shape

- `04:37–07:03`: the functional concern was that PO reference exposes the full PO quantity rather than the selected delivery quantity.
- `11:46–15:37`: they demonstrated MIGO reference options and explicitly directed C&F receipt against **outbound delivery**. PO/PO Item should not be mandatory.
- `20:05–25:28`: they asked for a Postman test with PO/PO Item removed and said Delivery/Delivery Item should be the mandatory business reference.
- `22:53`: one speaker said Material should not be mandatory because it is already on the delivery item.
- `26:21–26:37`: Quantity, Unit and Storage Location were still discussed as values that remain relevant.
- `28:49–30:45`: while walking the saved BAPI test, they explicitly acknowledged Posting Date, Document Date, delivery reference, Material, Plant, Movement Type, Quantity and Unit as the minimum posting information; PO/PO Item were not needed.

Therefore the meeting contains tension between the desired **external contract** and the fields required to execute a posting. Treat “only Delivery + Item mandatory” as the desired caller contract, not as proof that the unmodified standard endpoint derives everything.

### 3.2 SE37 direction

- `23:11–31:33`: they directed Siddharth to use `BAPI_GOODSMVT_CREATE` in SE37 and the saved Test Data Directory entry named **Prashant**.
- They asked him to inspect header/item values, use Goods Movement Code `01`, post with commit and use existing custom BAPI callers as references.
- They said the custom fields are outside the standard BAPI and must also be accounted for.

### 3.3 Enhancements, validations and errors

- `31:12–33:32`: standard BAPI does not itself expose the custom MIGO fields; the team's custom code must be studied.
- The requested sweep includes implicit/explicit enhancements, BAdIs, user/customer exits and custom programs.
- They raised bag/tonne handling and meaningful error mapping.
- The 27 August review independently surfaced “many user exits,” delivery-level receipt, full-quantity/shortage reconciliation, yard-registration blocking, three-day TAT alerts and an RSD-specific restriction. See [`meetings/2026-08-27-postman-di-migo-review.md`](../../meetings/2026-08-27-postman-di-migo-review.md).

### 3.4 GET and CSRF

- `09:15–10:46`: they did not want a business GET before Submit MIGO. The team explained that the existing GET was used to obtain data and fetch a CSRF token.
- Their present concern is commercial as well as conceptual: each API call may cost money, so they want one CreateDI POST and one SubmitMIGO POST.

Be precise:

- A direct SAP OData write normally needs a CSRF token acquired before the write.
- The business/UI can still expose one Submit MIGO action if CPI or a backend wrapper obtains/reuses the token and performs internal reads itself.
- That produces one **external business call**, not necessarily one physical hop inside the landscape.
- Do not promise a literal single SAP HTTP request until the authentication/session/API-management design is confirmed.

## 4. Chronology of this investigation

### 4.1 Initial Postman and meeting questions

The conversation began with repeated questions about:

- why a GET exists when the client wants POST only;
- why PO is present when the intended business reference is the delivery;
- whether a delivery whose MIGO is pending exists;
- whether Delivery + Delivery Item alone can be uploaded to the current collection;
- how Material, receiving Plant and Storage Location are obtained from a delivery;
- what to say in the meeting/MOM without drowning non-technical stakeholders in implementation language.

Siddharth wants MOMs written in first person as acknowledgements, not about him in the third person. Do not include attendees or “functional involvement” unless he explicitly asks.

### 4.2 Prashant walkthrough and historical delivery reconstruction

Screenshots and SE37 inspection established the saved test entry:

- Function: `BAPI_GOODSMVT_CREATE`
- Test Data Directory entry: `prashant_22_nov`
- Saved: 22 November 2024
- Header:
  - Posting Date `22.11.2024`
  - Document Date `22.11.2024`
  - Reference `0082562455`
  - Bill of Lading `5263/SEN/18`
  - Goods Movement Code `01`
- Item:
  - Material `15000275`
  - Plant `1041`
  - Storage Location `RMYD`
  - Movement Type `101`
  - Entry Quantity `0.000`
  - Entry Unit `TO`
  - Movement Indicator `B`
  - Delivery `82562455`
  - Delivery Item `000010`
  - PO Number blank
  - PO Item initial/blank (`00000`)

The historical document chain was then reconstructed:

- Outbound delivery `82562455`, item `10`
- Material `15000275`
- Delivery display showed `33.600 TO`
- Underlying document flow contained PO/STO `5600035281/10`
- Goods receipt material document `5002024552/2024`
- Actual posted receipt:
  - Movement `101`
  - Quantity `33.600 TO`
  - Receiving Plant `1041`
  - Storage Location `FBGU`
  - Batch `2436000341`

The saved test values do not match the actual receipt (`RMYD` and `0.000` versus `FBGU` and `33.600`). The Prashant entry is therefore useful as a historical **field-layout/reference example**, not as canonical runtime data and not as proof of the current minimum payload.

### 4.3 SE37 execution on 1 September

The saved test was actually executed, contrary to an earlier draft statement that it had only been inspected.

1. The unchanged test returned no material document and error `M7 053`: posting is possible only in periods `2026/06` and `2026/05` for company code `1000`.
2. Through SAP GUI scripting, the working-copy Posting Date was changed to `30.06.2026` and executed again.
3. The same `M7 053` error remained.
4. No material document was created and no commit was run.
5. The saved Test Data Directory record was not overwritten.

This result proves only that the stale historical test cannot be used as a posting proof in the current period/context. It does not answer the delivery-only contract.

Useful scripts are in [`outputs/sap-gui-script`](../../outputs/sap-gui-script/).

### 4.4 Fresh delivery data

An SD colleague supplied outbound delivery `9004953294` with two items:

| Item | Material | Delivery quantity |
|---|---:|---:|
| `10` | `15000177` | `10 TO` |
| `20` | `15000114` | `15 TO` |

The screenshot showed Ship-to `P5412`, date `27.08.2026` and a blank Actual GI Date at that moment. Siddharth later said the SD colleague would create a PO of quantity 100 and multiple deliveries of quantity 1, completing PGI and invoicing before testing.

Do not post against any of these until all of the following are rechecked immediately before execution:

- outbound delivery is complete enough for the intended receipt;
- PGI/641 exists;
- no 101 GR already exists for that delivery item;
- receiving Plant and valid receiving Storage Location are known;
- open receivable quantity and UoM are known;
- the item has been deliberately allocated to one test lane.

Do not burn 100 deliveries through ad hoc tests. Allocate separate delivery items for:

- MIGO GUI baseline;
- SE37 BAPI happy path;
- direct standard OData/Postman happy path;
- over-quantity rejection;
- duplicate/replay rejection;
- missing/invalid custom-data scenario.

## 5. SE37 mental model Siddharth needs

Siddharth's remaining learning gap was why SE37 goes “forward, back, insert values, then execute elsewhere.” Explain it this way:

- The first SE37 screen represents the **whole function call**.
- `GOODSMVT_HEADER` is one nested structure. Clicking its structure button opens its fields.
- `GOODSMVT_ITEM` is a table. Clicking it opens the rows; opening row 1 opens the fields for that item.
- The green check applies changes to the current nested editor and returns to its parent. Back does not post anything.
- F8 on the main test screen executes the full function with all header/item values collected.
- `TESTRUN = X` is simulation only.
- A successful real BAPI call must be followed by `BAPI_TRANSACTION_COMMIT` in the same logical unit of work. In SE37, use a Test Sequence containing `BAPI_GOODSMVT_CREATE` followed by `BAPI_TRANSACTION_COMMIT`, or another verified same-session method.

For a fresh delivery, do not copy the stale Prashant values blindly. Use it only to understand which fields go where.

## 6. Current Postman state

The active reviewed Submit MIGO artifacts are:

- [`CNF_SubmitMIGO.postman_collection.json`](../postman/Postman%20collection%20-%20SubmitMIGO%20CreateDI%20-%20Reviewed/CNF_SubmitMIGO.postman_collection.json)
- [`CNF_SubmitMIGO_QS4.postman_environment.json`](../postman/Postman%20collection%20-%20SubmitMIGO%20CreateDI%20-%20Reviewed/CNF_SubmitMIGO_QS4.postman_environment.json)

They now represent a **PO-free direct-input** call to `API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader`.

Current item payload:

```json
{
  "Material": "{{material}}",
  "Plant": "{{receivingPlant}}",
  "StorageLocation": "{{storageLocation}}",
  "GoodsMovementType": "101",
  "GoodsMovementRefDocType": "B",
  "QuantityInEntryUnit": "{{quantity}}",
  "EntryUnit": "{{unit}}",
  "Delivery": "{{delivery}}",
  "DeliveryItem": "{{deliveryItem}}"
}
```

Changes already made:

- Purchase Order and Purchase Order Item were removed from the active request.
- The environment no longer contains PO variables.
- The pre-request guard rejects PO fields and requires Material, Plant, Storage Location, positive Quantity, Unit, Delivery and Delivery Item.
- The collection contains one CSRF-token GET and one POST; there is no second verification GET.
- A historical PO-inclusive saved response was retained only as labelled evidence and is not the active request shape.
- No SAP POST has been sent from this revised collection.

This is not the final Delivery+Item-only design. It is the shortest honest collection that can be exercised against the current standard endpoint without pretending that derivation has already been implemented.

## 7. What the standard Material Document API code proved

Siddharth supplied the standard service implementation methods `create_material_document`, `prepare_items`, `map_item_input` and `item_check_allowed_fields`.

### 7.1 Call chain

The service:

1. maps/checks the header;
2. maps/checks items;
3. maps serials;
4. calls internal goods-movement creation using BAPI-shaped structures;
5. maps the returned material document header and BAPI messages.

### 7.2 Field mapping

`map_item_input` directly copies caller fields into the BAPI item:

- Material;
- Plant;
- Storage Location;
- Movement Type;
- PO/PO Item when supplied;
- Movement reference type;
- Quantity and Unit;
- Delivery and Delivery Item.

For a delivery, it identifies whether the number is inbound or outbound and maps it into the corresponding BAPI delivery fields. The inspected method itself does **not** read LIPS to derive Material, Plant, Storage Location, Quantity or Unit.

### 7.3 Mandatory fields are contextual

`item_check_allowed_fields` calls `get_relevant_fields` using movement type, special stock and reference-document type. It raises:

- an error when a contextually mandatory property is initial;
- an error when a populated property is unsupported for that movement type.

Therefore do not infer the exact minimum from the public entity shape or the mapping source alone. A QS4 runtime test with a fresh delivery is required. Some values may also be derived later by the underlying BAPI/reference logic even though the OData mapping does not derive them itself.

Source attachment for `map_item_input`: `C:\Users\sidmy\.codex\attachments\4e6d4f66-2233-46cb-86ec-4e0d2c434fb5\pasted-text.txt`.

## 8. Custom MIGO logic found so far

This is a partial inventory, not complete enhancement coverage.

### 8.1 `ZMMR_MIGO_SCREEN_ADD`

Source attachment: `C:\Users\sidmy\.codex\attachments\4a7f6a15-aecf-4850-b115-264bbc1ea891\pasted-text.txt`.

This custom dynpro program reads live MIGO memory using dynamic assignments to `(SAPLMIGO)GOHEAD` and `(SAPLMIGO)GOITEM`. For relevant receipts it reads PO/item and header delivery-note/reference context, then queries custom tables such as:

- `ZLETILMSDELIVERY`;
- `ZLETILMSTOKEN`;
- `ZLET_VEHICLE`;
- `ZMMT_MIGO_HDR`;
- `MATDOC`.

It derives/displays operational fields such as Token, LR number/date, transporter, vehicle/type, invoice date and challan information.

Important implication: this code is coupled to the MIGO GUI runtime. A BAPI or OData call does not run the MIGO screen merely because it creates the same material document.

### 8.2 Custom table `ZMMT_MIGO_HDR`

The Token field's technical information showed:

- Dynpro program `ZMMR_MIGO_SCREEN_ADD`, screen `0101`;
- table `ZMMT_MIGO_HDR`;
- field `TOKEN`;
- dynpro field `GS_MIGO_HDR-TOKEN`.

The custom table also carries fields around transporter/vehicle, LR, E-Way Bill, AFR manifest and related receipt context. The exact mandatory set for C&F is not yet established.

### 8.3 `ZCLMM_MB_MIGO_BADI` — `IF_EX_MB_MIGO_BADI~POST_DOCUMENT`

Source attachment: `C:\Users\sidmy\.codex\attachments\618f4aee-2864-47f9-856a-8255d4b2341e\pasted-text.txt`.

Observed behavior:

- reads the custom MIGO header structure;
- inserts/modifies `ZMMT_MIGO_HDR`;
- collects delivery/item quantities from current MSEG plus prior MATDOC records;
- reads delivery quantity from LIPS;
- blocks quantity greater than the delivery and contains further full-quantity/shortage checks;
- prepares GRN/downstream information including token, DI, quantity, truck and material-document details;
- calls `ZMMF_MIGO_UPDATE_DETAIL` in update task;
- contains external HTTP/downstream processing.

This is strong evidence of custom validation and side effects. It is an `MB_MIGO_BADI` implementation, so treat it as MIGO-application logic unless a runtime trace proves otherwise. Do not assume the standard BAPI/OData path triggers it.

### 8.4 `ZMM_MIGO_POSTING`, transaction `ZMM063`

Sources:

- `C:\Users\sidmy\.codex\attachments\42c9ab7b-1e92-436c-8f00-4d26efbdc0d4\pasted-text.txt`
- `C:\Users\sidmy\.codex\attachments\3cfdb371-e72e-43b2-bef9-c1d99235ac2f\pasted-text.txt`
- `C:\Users\sidmy\.codex\attachments\86295ddf-aa92-48a1-8973-e936f708be84\pasted-text.txt`

The movement-101 Excel branch supplies:

- Movement Indicator `B`;
- PO Number and Item;
- batch;
- Movement Type `101`;
- Storage Location;
- Quantity;
- Unit.

Material and Plant are not explicitly supplied in that branch and are left for reference/BAPI determination. The Delivery assignment is commented out. This is PO-referenced, not delivery-only evidence. The program passes `EXTENSIONIN`, but population of the extension table for this 101 branch was not established.

### 8.5 `ZMM_STO_AUTO_POSTING`

Repository source: [`sessions/2026-08-18-runtime-certification/sto/ZMM_STO_AUTO_POSTING_src.txt`](../../sessions/2026-08-18-runtime-certification/sto/ZMM_STO_AUTO_POSTING_src.txt).

This program creates an entire document chain: PO/STO, outbound delivery, PGI, billing and then goods receipt. Before calling the BAPI it builds values from the documents already held by the program:

- dates from billing context;
- delivery as header reference;
- Storage Location from STO/PO item context;
- Quantity and Unit from billing item;
- PO/item and delivery/item from created document references;
- Movement Type `101` and indicator `B` as constants.

Material and Plant are omitted from the BAPI item and appear to be reference-derived. This proves a custom program can hide technical derivation from its caller, but its internal logic still uses the STO/PO/document chain.

### 8.6 `ZMM_IFMS_AUTO` HTTP handler — live discovery on 1 September

QS4 where-used led to class `ZMM_IFMS_AUTO`, method `IF_HTTP_EXTENSION~HANDLE_REQUEST`. Its full source was copied read-only through SAP GUI scripting.

This is not the DI/101 receipt, but it proves an important architecture pattern already exists in QS4:

- one custom HTTP request accepts business fields;
- the ABAP code deserializes JSON;
- reads custom/master tables;
- derives material, Storage Location, Cost Center and quantities;
- creates/resolves reservation data;
- calls `BAPI_GOODSMVT_CREATE`;
- performs duplicate checks;
- commits on success;
- returns a simplified success/error JSON response.

The MINES branch derives:

- Storage Location from `ZIFMS_PLANT_LOC`;
- materials/allocation from `ZIFMS_ALLOCATION` and validation tables;
- Cost Center from equipment data;
- reservation and BAPI item data.

The RETAIL branch reads reservation/MATDOC state, checks quantity, derives Storage Location and Cost Center, then calls and commits the BAPI.

This caller uses other movement/reference scenarios (`GM_CODE 03` and reservation logic), not delivery-based 101. Use it only to support “server-side derivation and one-call wrapper are feasible and already familiar in this system.”

## 9. Live BAPI where-used sweep — exact continuation point

The sweep began on 1 September using SAP GUI scripting only.

### 9.1 Current SAP state

At handover time:

```text
Connections=1
Connection 0 sessions=1
System=QS4
Client=700
Transaction=SE37
Program=SAPLSEO_CLEDITOR
Screen=200
Title=Class Builder Class ZMM_IFMS_AUTO Display
Method=IF_HTTP_EXTENSION~HANDLE_REQUEST
```

Press Back once through SAP GUI scripting to return to the where-used result.

### 9.2 Where-used result captured

`BAPI_GOODSMVT_CREATE` reported **24 Hits**. The UI groups class methods and program objects, so do not reinterpret the count from the visible names.

Classes/methods shown:

- `ZCL_MINE_PROD_CONF` → `BAPI_MOVEMENTTYPE`
- `ZCL_RMC_BATCHER` → `BATCH_TRANSFER`
- `ZCL_RMC_BATCHER` → `BATCH_TRANSFER_TO_LAST`
- `ZMM_IFMS_AUTO` → `IF_HTTP_EXTENSION~HANDLE_REQUEST` (two call occurrences, around source lines 316 and 513)

Programs/includes shown:

- `ADROT_COIH`
- `LCOIHFH3`
- `LCOIHFHK`
- `LITOBFLTCONU02`
- `LZSD_PURULIAU05` — short description “Intercompany Sales Migo”
- `ZDACE_GOODS_MOVEMENT_CLS`
- `ZEWME001_CUSTOM_MIGO_TR_FORM`
- `ZEWM_CUSTOM_MIGO_TR_FORM`
- `ZLEIILMSDOCUMENTS_GOODSREC`
- `ZLEIILMSDOCUMENTS_GRN_BTST`
- `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01`
- `ZMMR_GAS_CYL_FRM`
- `ZMMR_STO_GR_SUB`
- `ZMM_GI_LOAN`
- `ZMM_INITIAL_STOCK_UPLOAD_F`
- `ZMM_INITIAL_STOCK_UPLOAD_F_STG`
- `ZMM_MIGO_POSTING_FORMS`
- `ZMM_STO_AUTO_POSTING`
- `ZPP_MP_DIVERSION_AUTOPGI_PAI`
- `ZSD_BACK_SHORTAGE_CLASS`

### 9.3 Existing scripting utilities

Use only SAP GUI scripting. Do not switch to Windows mouse/keyboard automation.

Key files:

- [`list-sap-sessions.vbs`](../../outputs/sap-gui-script/list-sap-sessions.vbs)
- [`dump-controls.vbs`](../../outputs/sap-gui-script/dump-controls.vbs) — now dumps every SAP window
- [`open-bapi-display.vbs`](../../outputs/sap-gui-script/open-bapi-display.vbs)
- [`open-bapi-where-used.vbs`](../../outputs/sap-gui-script/open-bapi-where-used.vbs)
- [`run-bapi-where-used.vbs`](../../outputs/sap-gui-script/run-bapi-where-used.vbs)
- [`dump-where-used-list.vbs`](../../outputs/sap-gui-script/dump-where-used-list.vbs)
- [`copy-abap-editor.vbs`](../../outputs/sap-gui-script/copy-abap-editor.vbs)
- [`sap-back.vbs`](../../outputs/sap-gui-script/sap-back.vbs)

`copy-abap-editor.vbs` successfully performs `SelectAll` in the SAP ABAP editor and invokes SAP's **Copy to Clipboard** menu. `Get-Clipboard -Raw` can then read the text for analysis. The source was only read, never edited.

`open-where-used-program.vbs` is not yet reliable: a previously selected method occurrence causes Display to reopen `ZMM_IFMS_AUTO`. Prefer navigating directly to includes through SE38 and classes through SE24 rather than fighting the hierarchical where-used list.

### 9.4 Continue in this order

Start with the callers most likely to contain outbound-delivery/101 receipt logic:

1. `ZMMR_STO_GR_SUB`
2. `LZSD_PURULIAU05`
3. `ZLEIILMSDOCUMENTS_GOODSREC`
4. `ZLEIILMSDOCUMENTS_GRN_BTST`
5. `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01`
6. `ZSD_BACK_SHORTAGE_CLASS`
7. `ZDACE_GOODS_MOVEMENT_CLS`
8. `ZEWME001_CUSTOM_MIGO_TR_FORM` and `ZEWM_CUSTOM_MIGO_TR_FORM`

`ZMM_MIGO_POSTING_FORMS` and `ZMM_STO_AUTO_POSTING` are already substantially inspected; use them as controls.

For each movement-101 call, trace assignments backwards and record:

| Question | Values to capture |
|---|---|
| Reference | delivery/item, PO/item, reservation or another document |
| Required BAPI data | Material, Plant, SLoc, Quantity, Unit, Movement Type, Movement Indicator |
| Lineage | external input, constant, SAP read, custom-table read, earlier document, or BAPI-derived |
| Header | posting/document dates, reference, header text, bill of lading |
| Controls | delivery open quantity, over-receipt, duplicate/replay, status checks |
| Custom behavior | extension fields, custom table writes, BAdIs/FMs, HTTP or update-task side effects |
| Transaction | commit/rollback and response document/year |

Do not stop at the line calling the BAPI. The decisive evidence is the field construction immediately before it.

## 10. Enhancement coverage: what is and is not done

### Covered deeply enough to discuss

- one saved SE37 BAPI example and its historical document chain;
- standard Material Document API call and item mapping;
- `ZMMR_MIGO_SCREEN_ADD` custom MIGO screen logic;
- `ZCLMM_MB_MIGO_BADI~POST_DOCUMENT` delivery-quantity/custom-data logic;
- custom table `ZMMT_MIGO_HDR` and its where-used surface;
- `ZMM_MIGO_POSTING` movement-101 branch;
- `ZMM_STO_AUTO_POSTING` movement-101 branch;
- `ZMM_IFMS_AUTO` as proof of an existing custom HTTP/BAPI derivation wrapper pattern;
- the top-level `BAPI_GOODSMVT_CREATE` where-used inventory.

### Not yet complete

- every Z caller in the 24-hit BAPI where-used result;
- every implementation of MIGO/material-document BAdIs;
- implicit and explicit enhancement points in the relevant SAP programs;
- SMOD/CMOD customer exits and classic user exits;
- validation/configuration paths that are not direct code references;
- runtime proof of which custom logic executes through:
  - MIGO GUI;
  - SE37 `BAPI_GOODSMVT_CREATE`;
  - `API_MATERIAL_DOCUMENT_SRV`;
- the exact C&F mandatory custom fields;
- the exact QS4 minimum payload for outbound delivery movement 101;
- the bag/tonne rule and conversion source;
- complete shortage/damage/yard-release behavior;
- production parity with QS4.

Static where-used analysis alone cannot guarantee all enhancements are covered. The final proof needs one controlled successful MIGO GUI posting and one controlled BAPI/API posting with runtime debugging/tracing or explicit enhancement breakpoints.

## 11. Architecture options

### Option A — current direct standard API, explicit posting fields

External request contains:

- Delivery + Item;
- Material;
- receiving Plant;
- receiving Storage Location;
- Quantity;
- Unit;
- movement constants/dates.

PO/PO Item remain absent. This is what the revised Postman collection currently demonstrates.

### Option B — one business POST with SAP/CPI derivation

External request contains Delivery + Item and any true business-only values. Backend logic:

1. reads the outbound delivery item and document flow;
2. confirms PGI and no existing GR/duplicate;
3. derives Material, receiving Plant, receiving SLoc, UoM and open receipt quantity;
4. applies C&F/custom validations and fills custom fields;
5. calls the posting BAPI/service and commits;
6. returns Material Document Number, Year and meaningful errors.

This is the only currently defensible way to meet the literal Delivery+Item-only external contract without a frontend GET.

### Option C — frontend GET followed by standard POST

The frontend reads delivery details, then calls the standard write API. This is technically straightforward but conflicts with the stakeholders' request/cost concern. Do not recommend it as the target unless they reverse that constraint.

### Explicit non-decision

Do not assume that only DIs created in the new C&F portal may be posted. Siddharth raised that as a possible limitation, not as an agreed business requirement.

## 12. Questions to answer ourselves versus questions for the client

### Technical discovery — do not ask the client to do our homework

- Which existing 101 callers derive fields, and from where?
- Which standard/custom validation fires on BAPI and OData paths?
- Does `MB_MIGO_BADI` execute outside MIGO? Prove by runtime trace, not assumption.
- Can the standard endpoint accept a minimal PO-free delivery reference in QS4?
- Which custom tables/functions are updated on a successful BAPI/API posting?
- What is the exact status/document-flow check for PGI complete and GR pending?
- What idempotency mechanism already exists or can be reused?

### Business ownership — ask only after presenting technical evidence

- Which custom fields are mandatory for **C&F** and which belong only to other receipt scenarios?
- What is the source of each C&F field when not on the delivery?
- Should Quantity be the full open delivery quantity automatically, or may the caller request a partial receipt?
- What are the approved bag/tonne rounding and conversion rules?
- How are shortage and damage represented, and which quantities post to stock?
- Which receiving Storage Location rule applies by plant/material/C&F depot?
- What response/error wording does the portal need?
- Is one external POST acceptable even if CPI/SAP performs internal reads/token handling?

## 13. Client-facing R&D status

If asked “what has been done?”, use this concise answer:

> R&D is in progress against the exact review points. We have rebuilt the SE37 reference, traced its delivery and historical material document, removed PO/PO Item from the active Submit MIGO request, and traced both the standard Material Document API and the first set of custom MIGO programs. We found the custom additional-data table, its MIGO screen program, the post-document BAdI and delivery-quantity validations. We also confirmed that existing SAP custom services already derive technical BAPI values internally, so a one-business-call design is feasible. What remains is to finish the movement-101 caller/enhancement sweep and prove the minimum delivery-based payload on a fresh PGI-complete, GR-pending delivery.

If they ask about Prashant:

> The Prashant record gave us the field structure and proved that PO fields can be absent in a saved BAPI example. It is historical and already consumed, and its saved quantity/storage location do not match the actual posted receipt, so it cannot be used as current posting proof. We executed it as directed; it failed on the current posting-period check and created no material document. We now need the fresh delivery set for runtime proof.

If they ask why the investigation is not “done” after one example:

> The example covers one saved input layout. The client system has several custom MIGO programs and enhancement paths. We have identified the principal custom screen/BAdI path and the full BAPI caller inventory, but each relevant movement-101 caller must be checked to determine which rules execute in MIGO only and which also execute through the BAPI/API.

Do not lead the meeting with `M7 053`; it is not the business-priority question. Mention it only to explain why the stale record did not produce a document.

## 14. Safety and execution rules for continuation

- Use **SAP GUI Scripting only**. Siddharth explicitly rejected Windows-control automation.
- Read-only inspection is authorized and preferred.
- Do not post, commit, change customizing or overwrite saved test data unless Siddharth explicitly asks for that execution.
- Before any posting, recheck the delivery because QS4 is shared and candidates become stale quickly.
- Never reuse a delivery after a successful 101 receipt.
- Use `TESTRUN` first where possible, but remember simulation does not prove commit-side custom logic.
- Preserve a control delivery for GUI MIGO comparison.
- Record Material Document Number/Year and all RETURN messages for every execution.
- Do not expose credentials or commit Postman environment secrets.

## 15. Repository/worktree state

The repository is dirty. Do not “clean up” unrelated changes.

Known state at handover:

- old Postman paths are staged/deleted from a prior reorganization;
- the reviewed Postman folder is untracked;
- study guides, evidence and SAP GUI scripts are untracked;
- these are Siddharth's working artifacts and must not be discarded;
- no commit was requested for this handover.

Run `git status --short` before editing. Use `apply_patch` for changes. Do not reset, checkout or delete the prior staged deletions.

Key investigation summary: [`sessions/2026-09-01-bapi-field-derivation/FINDINGS.md`](../../sessions/2026-09-01-bapi-field-derivation/FINDINGS.md).

Earlier study guide: [`deliverables/study-guides/DI_MIGO_ABAP_Study_Guide_2026-08-31.md`](../study-guides/DI_MIGO_ABAP_Study_Guide_2026-08-31.md). It predates the 1 September SE37 execution and current where-used findings; treat this handover as the newer source where they differ.

## 16. Immediate next actions

1. Read this handover and [`FINDINGS.md`](../../sessions/2026-09-01-bapi-field-derivation/FINDINGS.md).
2. Confirm the active SAP session with [`list-sap-sessions.vbs`](../../outputs/sap-gui-script/list-sap-sessions.vbs).
3. Use [`sap-back.vbs`](../../outputs/sap-gui-script/sap-back.vbs) once to return from `ZMM_IFMS_AUTO` to the BAPI where-used result.
4. Continue the priority caller sweep listed in §9.4, preferably opening includes directly in SE38 and copying their source through SAP GUI scripting.
5. Update the derivation matrix in `sessions/2026-09-01-bapi-field-derivation/FINDINGS.md` after each relevant caller.
6. Then enumerate the relevant BAdI/enhancement/exit implementations. Keep MIGO-only logic separate from material-document/BAPI logic.
7. Do not run a posting until the fresh deliveries are PGI-complete and individually allocated to test lanes.
8. Build the runtime matrix comparing:
   - MIGO GUI;
   - SE37 BAPI test sequence + commit;
   - direct standard OData POST;
   - eventual Delivery+Item-only wrapper.
9. Update Siddharth in simple language after each consequential discovery; do not make him interpret raw ABAP screens.

The next decisive result is not another list of program names. It is a documented movement-101 caller showing, field by field, whether Delivery, PO, Material, Plant, Storage Location, Quantity and Unit are input, internally read or BAPI-derived—and whether the custom C&F validations and fields survive the non-MIGO path.
