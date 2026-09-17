# C&F Postman instructions

## Files

Import these four JSON files into Postman:

1. `CNF_CreateDI_Standard_Simple.postman_collection.json`
2. `CNF_CreateDI_QS4_700_Simple.postman_environment.json`
3. `CNF_SubmitMIGO_Standard_Simple.postman_collection.json`
4. `CNF_SubmitMIGO_QS4_700_Simple.postman_environment.json`

Postman does not update collections imported earlier. Delete the old copies first, or choose **Replace** when Postman offers it.

Use the Create DI environment with the Create DI collection. Use the Submit MIGO environment with the Submit MIGO collection. Every URL starts with `{{base}}`, which resolves only when the matching environment is selected.

## Scope

These collections repeat the last certified standard SAP service calls on QS4/700:

- **Create DI** through `API_OUTBOUND_DELIVERY_SRV;v=2`, STO predecessor only. Certified: delivery `9004953174` from STO `5600084209/000010`.
- **Submit MIGO** through `API_MATERIAL_DOCUMENT_SRV`, movement 101 referencing both the STO item and the delivery item. Certified: material document `5007138616/2026` against delivery `9004953150/000010`.

They are technical baselines. They do not contain the delivery-led MIGO contract, BAdI or exit logic, shortage handling, C&F validations or duplicate protection. Trade and Non-trade Create DI are not certified.

Every POST creates a real SAP document.

## Safety controls built in

| Control | Behaviour |
|---|---|
| Confirmation switch | The POST is blocked unless `confirmCreateDI` / `confirmSubmitMIGO` is `YES`. The switch resets to `NO` before the request is sent, so every POST needs a fresh `YES`. |
| Required inputs | The POST is blocked if the CSRF token or any payload variable is empty. |
| Stale-key protection | The stored document key is cleared before the POST. Readbacks refuse to run without a key from the latest POST. |
| Tests | Status code, document key and readback fields are asserted. Check the **Test Results** tab; red means the step did not succeed. |

## Initial setup

1. Select the correct QS4/700 environment.
2. Enter `sap-user` and `sap-pass` in the environment's **Current value** only. Do not export a populated environment.
3. Keep Postman's cookie jar enabled. The CSRF token is bound to the session cookies.
4. Run `00.1` metadata. Expect HTTP 200 with EDMX metadata and green tests.
5. If the workstation does not trust the Shree Cement internal CA, SSL verification may be disabled temporarily for controlled testing only.

## Create DI

Use a fresh STO item with open delivery quantity.

Set:

- `shippingPoint`
- `referenceSDDocument`
- `referenceSDDocumentItem` — normally `000010`
- `actualDeliveryQuantity`
- `deliveryQuantityUnit` — the STO item's unit; there is no default

Run:

1. `01.1 GET CSRF token - Delivery service`. Tests must be green.
2. Check the resolved body of `01.2` (hover the variables or use the Postman console).
3. Set `confirmCreateDI` to `YES`.
4. Send `01.2 POST Create DI - STO deep insert - REAL WRITE` once. Expect HTTP 201 and green tests. `deliveryDocument` is stored.
5. Run `01.3 GET Created DI header - readback`.
6. Run `01.4 GET Created DI items - readback`. It reads only the new delivery's items and checks the STO item, quantity and unit.
7. Verify in `VL03N` and the document flow in `ME23N`.

Do not add `ReferenceSDDocumentCategory`; SAP marks it not creatable.

## Submit MIGO

Use a fresh STO item and delivery with goods issue (641) posted, stock in transit and `EKET WEMNG < MENGE`. Confirm the MM posting period is open.

Set:

- `migoMaterial` — the 25 Aug run sent it zero-padded to 18 characters
- `migoPlant` — receiving plant
- `migoStorageLocation` — receiving storage location
- `migoQuantity`
- `migoUnit` — the STO item's unit; there is no default
- `migoPurchaseOrder`
- `migoPurchaseOrderItem` — normally `00010`
- `migoDelivery`
- `migoDeliveryItem` — normally `000010`
- `materialDocumentHeaderText`
- `postingDate` — optional, `YYYY-MM-DD`. Empty means today's date in India time.

Run:

1. `02.1 GET CSRF token - Material document service`. Tests must be green.
2. Check the resolved body of `02.2`: goods movement code `01`, movement type `101`, reference type `B`, PO item and delivery item.
3. Set `confirmSubmitMIGO` to `YES`.
4. Send `02.2 POST Submit MIGO - GR against STO + delivery - REAL WRITE` once. Expect HTTP 201, `WE` and green tests. `materialDocument` and `materialDocumentYear` are stored.
5. Run `02.3 GET Created material document and items - readback`. The create response has no items, so this step is required.
6. Check the console line for base versus entry quantity. Which SAP quantity pair `QuantityInEntryUnit` fills is not yet established.
7. Verify in `MB03` and PO history in `ME23N`.

`GoodsMovementRefDocType = B` is mandatory. Without it SAP returns 400 `MM_IM_ODATA_API_MDOC/011` naming the PO fields, which is misleading.

## Common errors

| Result | Check |
|---|---|
| Script error "blocked" | Read the message: confirmation switch, missing variable or no key from the last POST. The request was not sent. |
| `401` | Username, password, client and account status. |
| `403` | CSRF token missing or from the other service, cookies disabled, or missing authorization. For Create DI, `403` with `/IWFND/MED/170` means the `;v=2` suffix is missing (version 1 is not registered). |
| `404` | Wrong service or entity path. |
| `400` | Read `error.message.value` and `error.innererror.errordetails`; check field names, padding, quantity, unit, posting period and current document state. |
| `201` | Run the readback and verify in SAP GUI. A returned number alone is not persistence proof. |

## Do not reuse

- STO `5600084209/000010`, delivery `9004953174` (Create DI)
- PO `5600084239/00010`, material document `5007138597` (Submit MIGO, PO-only)
- Delivery `9004953150/000010`, material document `5007138616` (Submit MIGO, PO+delivery)

## Safety and evidence

- Do not resend after a timeout or lost response. Search SAP first (`VL06O`/`LIPS` for deliveries, `MB51`/PO history for receipts).
- Do not add BAdI-derived fields or rules during this baseline test.
- Never share passwords, CSRF tokens, cookies or populated environments.
- A successful standard call proves only that this exact HTTP request persisted the test case. It does not certify equivalence with the SAP transaction or the C&F business rules.

Return the request, response, HTTP status, test results, created document key, readback and SAP GUI evidence for each test. Remove all credentials, tokens and cookies before sharing.
