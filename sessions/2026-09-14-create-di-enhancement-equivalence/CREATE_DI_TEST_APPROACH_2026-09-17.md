# Create DI — rule landscape, test sequence and open decisions

**As of:** 2026-09-17 · **System:** QS4/700
**Scope basis:** `SRC-SID-20260917-06` — C&F Create DI is depot → customer (Trade, Non-trade) and
depot → depot STO.
**Data evidence:** `QS4_READ_2026-09-17_PLANT_CLASS_AND_ZZVBELN.md` and `evidence-2026-09-17/`.
**Agreed rule list (Siddharth, 17.09.2026):** the seven rules below (V01, V02, V03, V07, V08, V09a,
V09b in `CREATE_DI_VALIDATION_MATRIX.md`).

## 1. C&F Create DI population

| Flow | Order type → delivery type (`TVAK-LFARV`) | Depot deliveries 25.07–17.09.2026 |
|---|---|---:|
| Depot → customer, Trade | `ZTRD` → `ZNP` | 47,887 |
| Depot → customer, Non-trade | `ZNTR` → `ZLF` | 3,219 |
| Depot → depot STO | `ZNL` | 834 |

**Verified:** the only API-created delivery (`9004953174`) is a factory STO. None of the three C&F
flows has been created through OData.

## 2. What the standard service can carry

From the captured live metadata
(`../2026-08-18-runtime-certification/evidence/META_API_OUTBOUND_DELIVERY_V2_response.xml`,
18.08.2026 — re-fetch before relying on it):

| Data a rule needs | OData property | Creatable | Updatable |
|---|---|---|---|
| Storage location (`LIPS-LGORT`) | `A_OutbDeliveryItem.StorageLocation` | no | yes |
| SPI (`LIKP-SDABW`) | `A_OutbDeliveryHeader.SpecialProcessingCode` | no | **no** |
| Transporter (`VBPA` `SP`) | `A_OutbDeliveryPartner` entity set | no | **no** |
| Incoterm | `IncotermsClassification` | no | yes |
| `LIKP-ZZVBELN`, `ZZPARTNER` | not exposed | — | — |

**Verified from metadata:** a create carries only shipping point, predecessor document/item,
quantity and unit. SPI and transporter cannot be written through the standard service at all.

## 3. Rule landscape

The rules live in shared `LE_SHP_DELIVERY_PROC` implementations that run on every delivery save.
Whether a rule fires on the API is decided by each rule's own gate.

### Bucket A — gated to screen transactions (API gap)

| Rule | Gate | Consequence |
|---|---|---|
| V01 one distinct material | `SY-TCODE` VL01N/VL02N | **Verified source:** not executed for API create/change. The API accepts multiple items. |
| V02 one storage location (depot) | same | Relevant at storage-location/batch-split enrichment; API changes also bypass it. |

### Bucket B — would fire, but need data the API cannot supply

| Rule | Consequence |
|---|---|
| V03 SLoc + SPI pair (depot) | Runs as soon as `LGORT` exists. SPI is not writable by API; no `ZLETSPIMAP` row has blank SPI. **Strong inference:** an API storage-location update on a depot delivery with blank SPI is rejected `ZLE 104`. Real depot deliveries carry SPI by dispatch (all but 18 of 51,940 depot `ZNP`/`ZLF`/`ZNL`). |
| V09a FTB self-transporter (depot) | Needs a `SP` partner at check time; API cannot add one. `FTB` is common (15,278 `ZNP`, 2,636 `ZLF`, 533 `ZNL`). |
| V09b transporter ↔ shipping point mapping | Same dependency. |

Timing risk (**strong inference**, unproven): `DELIVERY_FINAL_CHECK` may run before
`SAVE_DOCUMENT_PREPARE` derivations, so checks can see blank fields and pass.

### Bucket C — dormant for C&F depot deliveries

| Rule | Consequence |
|---|---|
| V07 blocked referenced order | Runs only with `LIKP-ZZVBELN`: 2 of 153,514 deliveries 25.07–17.09.2026 (factory test), 0 depot. |
| V08 cumulative quantity | Same dependency. |

Standard SAP still covers the intent: credit-failed orders are not delivered (60 of 118 open depot
items have `CMGST = B`) and item over-delivery is refused. The writer of `ZZVBELN` is unidentified,
so dormancy is not yet authoritative.

**Summary:** at creation the API genuinely loses V01. The larger exposure is at enrichment, where
V02, V03, V09a and V09b apply and the standard service cannot carry SPI or transporter.

## 4. Test sequence

| Step | What | Write? | Proves |
|---|---|---|---|
| 0 | Read `VBAP-ANTLF/KZTLF`, open quantity and `VBPA` for `5284812`, `5284692`, `5284664`; `ZLETSPIMAP` for depots 5346/4215; `ZM_KREDA_CDS` definition; one open depot STO item (`evidence-2026-09-17/DEPOT_STO_OPEN_ITEMS.csv`); debug authorisation and external breakpoints for the Gateway Client user | No | Fixtures and gates |
| 1 | T0: create 1 TO from `5284403/000010` (`5284812` failed `VL/096`, see section 7) (`ZTRD` → `ZNP`) under external breakpoints; re-read `LIKP/LIPS/VBPA` | **Yes — approval** | Sales-order route works; `SY-TCODE`; check vs derivation order; classes hit; what is copied from the order (SLoc, SPI, `SP`) |
| 2 | 31+ TO from `5284403`; 1 TO from credit-failed `5284664` | Expected rejection | Standard over-delivery and credit protection |
| 3 | On the Step 1 delivery: API storage-location update (guarded); same change in VL02N as baseline | Guarded | V03 behaviour on API; how the screen fills SPI/transporter |
| 4 | Repeat Step 1 for `5284692` (`ZNTR` → `ZLF`) and a depot STO | **Yes — approval** | Remaining C&F routes |

**Guarded negative:** external breakpoint at the end of `DELIVERY_FINAL_CHECK`; if `CT_FINCHDEL` holds
the expected error, continue; otherwise terminate the debugger session before commit. Never edit
debugger variables. One violated condition per request.

### Tool: `/IWFND/GW_CLIENT` (`SRC-SID-20260917-07`)

Requests run as the logged-on user; the client handles authentication and CSRF. Before every write,
check the **HTTP method radio button** and the **full entity-set URI** — the 15 Sep attempt was a
`HEAD` on the service root (`SRC-SID-20260915-04`). There is no scripted confirmation switch or
assertion, so record request, status, response body and created number manually for each run.

Common request headers: `Content-Type: application/json`, `Accept: application/json`.

| Step | Method | Request URI | Body |
|---|---|---|---|
| 1 positive (Trade) | `POST` | `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader` | `{"ShippingPoint":"6073","to_DeliveryDocumentItem":[{"ReferenceSDDocument":"5284403","ReferenceSDDocumentItem":"000010","ActualDeliveryQuantity":"1","DeliveryQuantityUnit":"TO"}]}` |
| 1 readback | `GET` | `…;v=2/A_OutbDeliveryHeader('<delivery>')?$expand=to_DeliveryDocumentItem,to_DeliveryDocumentPartner` | — |
| 2 over-quantity | `POST` | same as step 1 | same, `ActualDeliveryQuantity` above the re-read open quantity |
| 2 credit block | `POST` | same as step 1 | `ShippingPoint` `5374`, `ReferenceSDDocument` `5284664` |
| 3 storage location | `MERGE`/`PATCH` | `…;v=2/A_OutbDeliveryItem(DeliveryDocument='<delivery>',DeliveryDocumentItem='000010')` | `{"StorageLocation":"<SLoc>"}`; send `If-Match` with the ETag from the preceding `GET` if SAP requires it |
| 4 positive (Non-trade) | `POST` | same as step 1 | `ShippingPoint` `4215`, `ReferenceSDDocument` `5284692` |

Shipping point values are the order items' `VBAP-VSTEL`; re-read them in step 0. The item format
`000010` follows the certified STO request; if the sales-order route rejects it, retry with `10`
and record which form SAP accepts.

**Breakpoints:** the OData call runs in its own work process, not the Gateway Client's dialog
step. Use **external (user) breakpoints** for the logged-on user in the check classes. Session
breakpoints will not stop.

One candidate supports several tests: each successful create consumes 1 TO; rejected requests
consume nothing; enrichment tests reuse an existing test delivery. Check the partial-delivery cap
first, log every created delivery, and re-read open quantity before each write.

Rule V01 needs a depot order with two different materials in a `ZDEL_SPLIT` channel; none exists in
`5284000..5289999`.

## 5. Decisions needed to lock the development approach

| # | Decision | Owner | Why |
|---|---|---|---|
| 1 | Which step and interface writes enrichment data (SLoc/batch, SPI, transporter, vehicle, LR/GR) — Q-082 | Architect / functional | Standard service cannot write SPI or transporter; V02/V03/V09a/V09b must be enforced there |
| 2 | Must the API reject multi-material / multi-SLoc DIs, or does a one-item portal contract suffice? | Functional | Whether V01/V02 need code |
| 3 | Confirm BTST is outside C&F and standard credit/over-delivery checks suffice | Functional | Closes V07/V08 |
| 4 | Does the portal user choose SPI/SLoc (batch-determination step)? | Product / functional | Where V03 is enforced |
| 5 | Rejection contract to the portal | Architect / CPI | Error mapping |

Technical facts still required: T0 `SY-TCODE` and call order; how VL02N sets SPI/transporter today;
the `ZZVBELN` writer (where-used, or ask the 16.09 BTST tester); ownership and change governance of
`ZLE_SHP_DELIVERY_PROC` and `ZEI_LE_DELIVERY_PROCESS`, which also serve screen and ILMS flows.

## 6. Likely development shape (pending section 5)

- **V01/V02:** adjust the transaction gate inside the existing `LE_SHP_DELIVERY_PROC`
  implementation (released BAdI rung) so API create/change is covered, without removing protection
  the gate gives other callers. Design after T0.
- **V03/V09a/V09b:** keep in the same implementation; ensure the data exists at check time (write the
  `SP` partner directly, or have the check also read the source field). Depends on decision 1.
- **V07/V08:** no build; register as dormant with standard SAP covering the intent.

## 7. Runtime result — 17.09.2026, attempt 1 (no write)

`/IWFND/GW_CLIENT`, `POST …;v=2/A_OutbDeliveryHeader`, body: shipping point `5346`, order
`5284812/000010`, 1 TO. **HTTP 400, `VL/096` "Order is incomplete – maintain the order".** No
delivery created. External breakpoints on the four methods in section 4 did not stop: the request
was refused during predecessor checks, before delivery save processing (`DELIVERY_FINAL_CHECK` /
`SAVE_DOCUMENT_PREPARE`).

**Verified (`VBUV`):** the only incompletion entry for `5284812` is `VBKD-SDABW` (SPI) at header
level, incompletion group `ZS`. `VBAK-UVVLK = A` (not complete for delivery).

**Consequence for V03:** depot sales orders must carry SPI (`VBKD-SDABW`) before delivery; the
delivery takes SPI from the order. SPI is therefore a sales-order input, not an enrichment-step
input, on the sales-order route. Of 117 open depot items, 12 orders are incomplete on SPI, 1 on
`TRATY`, 1 on `VSART`, 3 on pricing (`PRSOK`). Evidence: `evidence-2026-09-17/VBUV_5284000_5289999.csv`,
`VBKD_5284000_5289999.csv`.

**Replacement Trade candidate:** `5284403/000010` — `ZTRD`, depot `6073` PB PHAGWARA TR, material
`15000262`, 30 TO, nothing delivered, credit `A`, complete for delivery, SPI `SP01`, Incoterm `FTB`.
Backups with the same profile: `5284465` (6812, 25 TO), `5284217` (6844, 25 TO), `5284415` (6751, 15 TO).
`5284812`, `5284813`, `5284803`, `5284800` are SPI-incomplete and unusable until maintained.

### Readback — `GET A_OutbDeliveryHeader('9004953534')?$expand=to_DeliveryDocumentItem,to_DeliveryDocumentPartner`

**Verified persisted** (separate GET after commit): header as in the create response; one item
`000010`, `ZO99`, material `15000262`, plant `6073`, **storage location blank, batch blank**,
`MaterialIsBatchManaged true`, `MaterialFreightGroup A0000001`, 1.000 TO, `GoodsMovementType 601`,
reference `5284403/000010` category `C`, `ItemGeneralIncompletionStatus A` and
`ItemGdsMvtIncompletionSts A` (item not yet complete for goods issue, consistent with missing
storage location/batch), `PartialDeliveryIsAllowed` blank.

Partners returned as OData external codes: **`SP` = sold-to `11042691`** and **`SH` = ship-to
`20222239`** (internal `AG`/`WE`, matching the debugger's `IT_XVBPA`). The OData `SP` is **not** the
forwarding agent/transporter (internal `PARVW = SP`) that V09a/V09b test. Do not read an OData
`SP` partner as a transporter.

## 9. Runtime result — 17.09.2026, Step 2a (over-quantity negative)

Pre-read `VBAP 5284403/000010`: `KWMENG 30`, `LFSTA B`, `KZTLF` blank (partial allowed), `ANTLF 0`
(no cap), `UEBTO 0.0` — 29 TO open after `9004953534`.

`POST …;v=2/A_OutbDeliveryHeader`, shipping point `6073`, order `5284403/000010`,
`ActualDeliveryQuantity 30`, unit `TO`. **HTTP 400, `VL/363` "Delivery quantity is greater than
target quantity 29 TO".** External breakpoints on both `DELIVERY_FINAL_CHECK` implementations did
not stop; no delivery created and quantity was not truncated.

**Verified:** standard SAP refuses item over-delivery on the OData path before custom delivery
checks — the intent of V08 is covered for a single order item without `ZZVBELN`.

## 10. Runtime result — 17.09.2026, Step 2b (credit-block negative)

Pre-read `VBAK 5284664`: `ZNTR`, `UVVLK C` (complete for delivery), **`CMGST B`**, no delivery or
billing block; `VBAP 000010` plant/shipping point `5374`, 100 TO, `LFSTA A`.

`POST …;v=2/A_OutbDeliveryHeader`, shipping point `5374`, order `5284664/000010`, 1 TO.
**HTTP 400, `VL/060` "Order blocked for delivery as a result of credit check".** External
breakpoints did not stop; no delivery created.

**Verified:** standard SAP refuses a credit-blocked sales order on the OData path before custom
delivery checks — the credit part of V07's intent is covered without `ZZVBELN`. Delivery-block and
billing-block variants of V07 are not yet exercised (no depot order with `LIFSK`/`FAKSK` found in
`5284000..5289999`).

## 11. Step 3 fixtures — V03 on delivery `9004953534` (read 17.09.2026)

`ZLETSPIMAP` (23 rows, no plant column). Pairs containing `SP01`: **`FRSH/SP01`, `GDF/SP01`**.
Storage locations at plant `6073` (`T001L`): `DMG` damage, `DRD` diversion, `DTP` transhipment,
`GDF` fresh GD, `STG` shortage. `MARD` for `15000262`/`6073`: `GDF` 161.400 unrestricted, `STG`
0.100, `DMG`/`DRD`/`DTP` 0. `P6073` is `KDKG1 A2`; `ZNP` is not in `ZSD_PREREQ_DEL`, so V03 is not
bypassed.

| Case | Storage location | Pair with `SP01` in `ZLETSPIMAP`? | Expected |
|---|---|---|---|
| Negative | `DRD` | No (`DRD` maps only to `SP07`) | `ZLE 104`, change rejected |
| Positive | `GDF` | Yes | Change saved |

Other valid negatives: `DMG` (maps `SP06`), `DTP` (maps `SP03/SP04/SP08`), `STG` (not mapped).

## 12. Runtime result — 17.09.2026, Step 3a (V03 negative via OData change)

`PATCH …;v=2/A_OutbDeliveryItem(DeliveryDocument='9004953534',DeliveryDocumentItem='000010')`,
`If-Match W/"'0001'"`, body `{"StorageLocation":"DRD"}`.

Stopped at `ZCLLE_DELIVERY_PROCESS~IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` (HTTP debugger
session). `SY-TCODE` blank; **`IF_TRTYP V`**; `IT_XLIPS[1]-LGORT DRD`; `IT_XLIKP[1]-SDABW SP01`.
After the method: **`CT_FINCHDEL` 1 row — `VBELN 9004953534`, `MSGID ZLE`, `MSGNO 104`, `MSGTY E`.**

**Verified:** V03 (storage location + SPI pair against `ZLETSPIMAP`) executes and raises its error
on an OData delivery change. HTTP response body and non-persistence readback pending.

**HTTP response (3a):** `400`, `error.code ZLE/104`, message "Correct the SPI as per the storage
location", `errordetails[0]` severity `error`, component `LE-SHP-API`. The custom delivery error is
returned to the OData caller unchanged.

## 13. Runtime result — 17.09.2026, Step 3b (V03 positive via OData change)

Same URI and `If-Match W/"'0001'"`, body `{"StorageLocation":"GDF"}` (`GDF/SP01` exists in
`ZLETSPIMAP`). **HTTP 204 No Content.** Item readback to confirm `StorageLocation GDF` pending.

**Readback (3b):** `GET A_OutbDeliveryItem(DeliveryDocument='9004953534',DeliveryDocumentItem='000010')`
→ **`StorageLocation GDF`**, `etag W/"'0002'"`, `DeliveryVersion 0002`, `LastChangeDate` 17.09.2026.
One version increment across 3a + 3b: the rejected `DRD` change did not persist.

**Verified:** V03 is enforced end to end on the OData change path — matched negative (`DRD`,
400 `ZLE/104`, not saved) and positive (`GDF`, 204, saved and re-read).

## 14. Updated rule position after runtime tests (17.09.2026)

| Rule | OData create | OData change | Evidence |
|---|---|---|---|
| V01 one material | Not executed (`SY-TCODE` blank) | Not executed | T0, §8 |
| V02 one SLoc (depot) | Not executed | Not executed (same gate) — no runtime negative yet | T0 `SY-TCODE`, source |
| V03 SLoc + SPI | Skipped when no SLoc | **Enforced** (`ZLE/104`) | §12–13 |
| V07 blocked order (custom) | Skipped (`ZZVBELN` blank) | — | T0 |
| V07 intent: credit block | Standard `VL/060` refuses | — | §10 |
| V08 cumulative qty (custom) | Skipped | — | T0 |
| V08 intent: item over-delivery | Standard `VL/363` refuses | — | §9 |
| V09a / V09b transporter | Skipped (no transporter partner) | Standard service cannot write the partner | T0, metadata |

Supersedes §3 bucket B's V03 inference: SPI is required on the sales order (`VL/096` incompletion,
`VBKD-SDABW`) and is present on the delivery at check time, so V03 validates real SPI rather than
failing on blank SPI.

## 15. Create DI standing — scope corrected (17.09.2026)

Scope basis: `SRC-SID-20260917-09` (Create DI screen: one order line, only input Delivery
Quantity) and `SRC-SID-20260917-08` (enrichment fields belong to later dispatch APIs; duplicates
blocked by Hybris/CPI). Rules V02, V03, V09a, V09b apply to those later steps and are out of Create
DI scope; the V03 result in §12–13 is carried forward to the enrichment API.

| Rule | Applies at Create DI | Proven by test | Standing |
|---|---|---|---|
| V01 one material | Yes | T0: `SY-TCODE` blank, rule not executed | Gap on API; portal sends one order line, so not reachable from the portal. Needs contract confirmation |
| V07 blocked order — credit | Yes (intent) | `VL/060` on `5284664` | Covered by standard SAP |
| V07 blocked order — delivery/billing block | Yes (intent) | Not tested; no depot order with a block | Open (brief Q3) |
| V07 custom (`ZZVBELN`) | — | T0: skipped | Dormant for depots (brief Q4) |
| V08 quantity | Yes (intent) | `VL/363` on `5284403` | Covered by standard SAP for the order item |
| V08 custom (`ZZVBELN`) | — | T0: skipped | Dormant for depots (brief Q4) |
| Duplicate DI | Yes | Not tested in SAP | Owned by Hybris/CPI |

Route coverage: depot Trade `ZTRD → ZNP` proven (`9004953534`). Depot Non-trade `ZNTR → ZLF`
and depot STO `ZNL` not yet created through OData. All tests ran as dialog user `QNOVATE8`.

## 16. Remaining depot tests — fixtures (read 17.09.2026)

**Delivery block configuration (`TVLS` / `TVLST`).** `SPELF` (block delivery creation) is set only for
`01` Credit limit, `02` Political reasons, `03` Bottleneck material, `04` Export papers missing,
`05` Check free of charge delivery, `06` No printing. **Not set** for `07`, `08`, `09`, **`15` Depot
Blocking** (blocks due list, picking, confirmation, goods issue, printing), `30`, `31` GST Inactive
(blocks picking, confirmation, goods issue). Standard SAP should therefore refuse a DI only for codes
`01`–`06`.

**Billing block codes (`TVFST`)** include `14` Stop Supply, `15` Depot Blocking, `11` Legal Case,
`Z1` Customer approval required, `ZA` Inactive. Billing blocks do not stop delivery creation in
standard SAP.

| Test | Order | Precondition | Request | Expected |
|---|---|---|---|---|
| 4 Non-trade create | `5284692/000010` (`ZNTR`, depot 4215, 1 TO, credit D, complete) | none | `ShippingPoint 4215`, 1 TO | 201, `ZLF` |
| 5 Depot STO create | STO `5600083801/00010` (`ZP06`, 8265 UP MATHURA RSD → 8264, material `15000456`, 5,000 TO, nothing delivered, route `E84161`) | none | `ShippingPoint 8265`, `ReferenceSDDocumentItem 000010`, 1 TO | 201, `ZNL`; watch for `ZLE 182` (`YSTO` user exit) |
| 6a Delivery block, blocking code | `5284465/000010` (depot 6812) | VA02: header delivery block `01` | `ShippingPoint 6812`, 1 TO | 400, delivery-block message |
| 6b Delivery block, `15` Depot Blocking | same order | VA02: change block to `15` | same | Guarded: expected to reach `DELIVERY_FINAL_CHECK` with no error |
| 7 Billing block | `5284415/000010` (depot 6751) | VA02: header billing block `14` | `ShippingPoint 6751`, 1 TO | Guarded: expected to reach `DELIVERY_FINAL_CHECK` with no error |

Remove every block set for testing after the run.

## 17. Runtime result — 17.09.2026, Tests 6a/6b (delivery block)

Order **`5284465/000010`** (`ZTRD`, depot 6812) was used for both — verified from change documents
(`CDHDR`/`CDPOS`, §18). Header delivery block set in VA02, then `POST …;v=2/A_OutbDeliveryHeader`,
1 TO.

| Test | Delivery block | Result (Siddharth-reported) |
|---|---|---|
| 6a | `01` Credit limit (`TVLS-SPELF X`) | HTTP 400; message names the delivery block; no debugger stop |
| 6b | `15` Depot Blocking (`TVLS-SPELF` blank) | HTTP 400; message names the depot block; no debugger stop |

**Verified (reported):** standard SAP refuses DI creation through OData for both a creation-blocking
code and code `15`, before custom delivery checks. **Contradicted:** the configuration-based inference
in §16 that code `15` would not stop creation — `SPELF` alone does not predict API behaviour. Exact
message IDs were not captured.

The delivery-block requirement (`SRC-SID-20260917-10`) is met by standard SAP for the tested codes.

## 18. Tests 4, 5 and 7 — results and order-edit audit (17.09.2026)

**Test 4 — Non-trade create** (`5284692/000010`, shipping point `4215`, 1 TO): **positive**
(Siddharth-reported). **Test 5 — depot STO create** (`5600083801/00010`, shipping point `8265`,
1 TO): **positive** (Siddharth-reported). **Re-read from `LIKP`/`LIPS` (17.09.2026):** Test 4 → DI **`9004953537`** (`ZLF`, shipping point `4215`, created 16:39:19 by `QNOVATE8`, item `000010` plant `4215`, material `15000177`, 1 TO, reference `5284692/000010`). Test 5 → DI **`9004953538`** (`ZNL`, shipping point `8265`, ship-to `P8264`, created 16:39:50, item `000010` plant `8265`, material `15000456`, 1 TO, reference `5600083801/000010`). Both persisted; goods movement status `A`.

### Change-document audit of VA02 test edits (`CDHDR`/`CDPOS`, user `QNOVATE8`)

| Time | Order | Change |
|---|---|---|
| 16:44:15 | `5284465` | `VBAK-LIFSK` blank → `01` (Test 6a) |
| 16:44:43 | `5284465` | `LIFSK` `01` → `15` (Test 6b); `VBAK-CMNGV` and schedule-line dates (`VBEP` `EDATU`, `WADAT`, `LDDAT`, `MBDAT`, `TDDAT`) 11.08 → 17.09.2026 |
| 16:45:30 | `5284465` | `LIFSK` `15` → blank |
| 16:50:58 | `5284415` | `VBAK-FAKSK` blank → `15` (Test 7 preparation); `VBAK-CMGST` `A` → `B` (credit re-check on save failed: credit segment 9000, partner `11042691`, overdue items) |
| 16:51:14 | `5284415` | `FAKSK` `15` → blank |

Siddharth confirmed with the owners that these VA01/VA02 test edits in QS4 caused no problem.
Residual state: `5284465` no blocks, credit `A`; `5284415` no blocks, credit `B`.

**Test 7 — billing block: not run.** Saving the billing block re-ran the credit check and
credit-blocked `5284415`, which would mask the result with `VL/060`. The position rests on standard
SAP behaviour (billing block does not stop delivery creation) and the captured custom source
(`ZLE 088` reads `FAKSK` only on the `ZZVBELN` order). A runtime test needs a depot order with a
billing block whose customer passes credit.

## 19. Depot Create DI — standing after all runs (17.09.2026)

| Requirement | Result | Development |
|---|---|---|
| Create depot Trade DI (`ZNP`) | Proven (`9004953534`) | None |
| Create depot Non-trade DI (`ZLF`) | Proven (Test 4) | None |
| Create depot STO DI (`ZNL`) | Proven (Test 5) | None |
| Quantity above open | Refused by standard SAP (`VL/363`) | None |
| Credit-blocked order | Refused by standard SAP (`VL/060`) | None |
| Delivery block (`01`, `15`) | Refused by standard SAP (Tests 6a/6b) | None |
| Incomplete order (missing SPI) | Refused by standard SAP (`VL/096`) | None |
| One material per DI | Not checked on API; portal sends one order line | None, if the portal contract is accepted |
| Billing block | **Not enforced by standard SAP** — DI `9004953540` created with billing block `15` on credit-OK `5284465` | Small change in existing `LE_SHP_DELIVERY_PROC` implementation |
| Bill-to-ship-to | Factory-side paired deliveries (§6 of the read note) | Out of depot scope; open with business |
| Duplicate DI | Hybris/CPI responsibility | None in SAP |

### Test 7 rerun — 17.09.2026 (inconclusive)

`CDPOS`: `5284415` `VBAK-FAKSK` blank → `15` at 17:04:11, `15` → blank at 17:05:12. `VBAK-CMGST` was
already `B` (since 16:50:58). `POST` for `5284415/000010`, 1 TO returned **HTTP 400 `VL/060`
"Order blocked for delivery as a result of credit check"**. The credit block pre-empts any
billing-block behaviour, so the test does **not** show whether a billing block stops DI creation.
Current state: `5284415` no blocks, credit `B`.

### Test 7 — conclusive run, order `5284465` (17.09.2026)

| Time | Event (source) |
|---|---|
| 17:11:38 | `VBAK-FAKSK` blank → **`15`** Depot Blocking (`CDPOS` change `0193182413`); `CMGST` stays `A` |
| 17:11:54 | **Delivery `9004953540` created** through OData (`LIKP-ERZET`; response `DeliveryDocumentType ZNP`, `ShippingPoint 6812`, sold-to `11015691`, `SpecialProcessingCode SP01`, Incoterm `FTB`, `DeliveryBlockReason` and `HeaderBillingBlockReason` blank) |
| 17:12:17 | `FAKSK` `15` → blank (`0193182414`) |

Current state: `5284465` no blocks, credit `A`; 1 TO consumed by `9004953540`.

**Verified:** with a header billing block on a credit-OK depot order, standard SAP creates the DI
through OData — the billing block is **not** enforced at Create DI. The business requirement
(`SRC-SID-20260917-10`) therefore needs a check; §19's "small change in the existing
`LE_SHP_DELIVERY_PROC` implementation" stands. The earlier `VL/060` run on `5284415` is superseded.
Only header billing block `15` was tested.
