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

- **Create DI** through `API_OUTBOUND_DELIVERY_SRV;v=2` for C&F depots. Proven in QS4/700 on 17 Sep 2026 for depot Trade (`ZTRD` → `ZNP`), depot Non-trade (`ZNTR` → `ZLF`) and depot-to-depot STO (`ZNL`), with the same five-field request. Standard SAP already refuses over-quantity, credit-blocked, delivery-blocked and incomplete orders. A billing block does not stop the DI yet (check planned).
- **Submit MIGO** through `API_MATERIAL_DOCUMENT_SRV`, movement 101 referencing both the STO item and the delivery item. Certified: material document `5007138616/2026` against delivery `9004953150/000010`. This remains a technical baseline; it does not contain the delivery-led MIGO contract or all MIGO validations.

Duplicate protection is not in SAP; it belongs to Hybris/CPI.

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

### Choosing an order

Use an order item at a C&F depot that is open for delivery. Check it in VA03 (sales order) or ME23N (STO) first:

- open quantity left, not rejected
- for a sales order: credit check passed or released, no delivery block, no billing block, order complete (SPI filled on the order)
- nobody else is using it

### Variables

| Variable | Value |
|---|---|
| `shippingPoint` | Sales order: the order item's shipping point (the depot). STO: the supplying depot's shipping point |
| `referenceSDDocument` | Sales order number or STO number |
| `referenceSDDocumentItem` | Item, e.g. `000010` |
| `actualDeliveryQuantity` | Default `1` |
| `deliveryQuantityUnit` | Default `TO` |
| `expectedOutcome` | `CREATE` for a positive test, `REJECT` for a negative test |
| `expectedErrorCode` | Optional, for negatives, e.g. `VL/363` |

### Run

1. `01.1 GET CSRF token - Delivery service`. Tests must be green.
2. Set the variables above and check the resolved body of `01.2`.
3. Set `confirmCreateDI` to `YES`.
4. Send `01.2 POST Create DI - REAL WRITE` once.
   - `CREATE`: expect HTTP 201 and green tests; `deliveryDocument` is stored.
   - `REJECT`: expect HTTP 400, no delivery number, and the error code if you set one.
5. For a created DI, run `01.3` (header and partners) and `01.4` (items). The create response has no items, so these are required.
6. Verify in `VL03N` and the order's document flow.

Do not add `ReferenceSDDocumentCategory`; SAP marks it not creatable. In the partner readback, OData codes are English: `SP` = sold-to, `SH` = ship-to.

### Test scenarios

| Scenario | Order to use | `expectedOutcome` | Expected SAP result |
|---|---|---|---|
| Depot Trade DI | Open `ZTRD` order item at a depot | `CREATE` | 201, delivery type `ZNP` |
| Depot Non-trade DI | Open `ZNTR` order item at a depot | `CREATE` | 201, delivery type `ZLF` |
| Depot STO DI | Open STO item supplied by a depot | `CREATE` | 201, delivery type `ZNL` |
| Quantity above open | Any open order; quantity higher than what is left | `REJECT` (`VL/363`) | 400 "Delivery quantity is greater than target quantity" |
| Credit-blocked order | Order that failed credit check | `REJECT` (`VL/060`) | 400 "Order blocked for delivery as a result of credit check" |
| Delivery-blocked order | Order with a header delivery block | `REJECT` | 400; message names the delivery block |
| Incomplete order | Order missing SPI | `REJECT` (`VL/096`) | 400 "Order is incomplete – maintain the order" |
| Billing-blocked order | Credit-OK order with a billing block | `CREATE` today | 201 — known gap until the billing-block check is built |

Saving an order in VA02 (for example to set a block) re-runs the credit check. For block tests, use a customer without overdue items and re-check the order's credit status after saving.

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

- STO `5600084209/000010`, delivery `9004953174` (Create DI, factory STO)
- Orders `5284403`, `5284692`, `5284664`, `5284465`, `5284415`, `5284812`; STO `5600083801`; deliveries `9004953534`, `9004953537`, `9004953538`, `9004953540` (Create DI depot tests, 17 Sep 2026)
- PO `5600084239/00010`, material document `5007138597` (Submit MIGO, PO-only)
- Delivery `9004953150/000010`, material document `5007138616` (Submit MIGO, PO+delivery)

## Safety and evidence

- Do not resend after a timeout or lost response. Search SAP first (`VL06O`/`LIPS` for deliveries, `MB51`/PO history for receipts).
- Do not add BAdI-derived fields or rules during this baseline test.
- Never share passwords, CSRF tokens, cookies or populated environments.
- A successful standard call proves only that this exact HTTP request persisted the test case. It does not certify equivalence with the SAP transaction or the C&F business rules.

Return the request, response, HTTP status, test results, created document key, readback and SAP GUI evidence for each test. Remove all credentials, tokens and cookies before sharing.
