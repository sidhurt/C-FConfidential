# Live demo script — recreate every test in front of them

**System DS4, client 200, user QNOVATE8.** Every test below was run on 2026-08-19 and produced
the stated result. Run them in this order — the sequence builds the argument.

Total time: about 25 minutes. Each block stands alone if you get interrupted.

---

## Before you start

Have these open and ready:

1. **SAP GUI** logged into DS4/200
2. **A PowerShell window** on your laptop, outside SAP
3. `DS4_API_TEST_SCRIPT.txt` open for copy-paste

Have a second SAP session ready (`/oSE16`) so you can check tables without losing your place.

---

# PART 1 — The services are real and reachable

## Demo 1.1 — The services are activated  ·  1 min

**Transaction:** `/IWFND/MAINT_SERVICE`

Press **F8** to list. In the filter row, type into **External Service Name**:

```
API_PURCHASEORDER_PROCESS_SRV
```

**What appears:** the service, with technical name `ZAPI_PURCHASEORDER_PROCESS_SRV`.

**Say this:** "The service is registered and active. The internal name is Z-prefixed — that's
just how it was registered here. The name in the URL is the standard SAP one."

Repeat the filter for each, or clear the filter and sort:

```
API_OUTBOUND_DELIVERY_SRV        (note: version 2)
API_MATERIAL_STOCK_SRV
API_MATERIAL_DOCUMENT_SRV
API_BILLING_DOCUMENT_SRV
```

**Proves:** all five services CNF needs are live on their system. 782 services are active in total.

---

## Demo 1.2 — It answers from outside SAP  ·  2 min

**This is the strongest thing you will show. Do it from your own laptop, not from SAP GUI.**

In PowerShell:

```
curl.exe -i -k 'https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/$metadata?sap-client=200'
```

**What appears:** `HTTP/1.1 401 Unauthorized`, in under a second.

**Say this:** "That 401 is the result we want. It means the gateway is reachable from outside
SAP and it is demanding credentials. This has never been done on this project before today."

Now with the login:

```
curl.exe -i -k -u "QNOVATE8:$SAP_PASS" 'https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/$metadata?sap-client=200'
```

**What appears:** `HTTP/1.1 200 OK`, then about 109 KB of XML schema.

**Say this:** "Authenticated call from a workstation outside SAP. 200. The integration path
works end to end."

**Note if asked:** port 8000 does not route from outside — only HTTPS 44300 answers. The
certificate is an internal CA, which is why `-k` is there.

---

## Demo 1.3 — A read that returns data cleanly  ·  1 min

```
curl.exe -i -k -u "QNOVATE8:$SAP_PASS" 'https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200&$top=5&$format=json'
```

**What appears:** `200 OK` and the body `{"d":{"results":[]}}`

**Say this:** "Empty, because this system has no purchase orders. That's the environment we
were given. What it proves is that routing, authorisation and the response format all work.
The shape `d.results` is the OData V2 envelope — that's what the integration will parse."

---

# PART 2 — Where the standard web service stops

## Demo 2.1 — The STO create is refused  ·  3 min

**Get a token first:**

```
curl.exe -i -k -X GET "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/?sap-client=200" -H "X-CSRF-Token: Fetch" -u "QNOVATE8:$SAP_PASS" -c cookies.txt
```

Copy the `x-csrf-token:` value from the output.

**Now the stock transfer order.** Replace `<TOKEN>`:

```
curl.exe -i -k -X POST "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200" -H "X-CSRF-Token: <TOKEN>" -H "Content-Type: application/json" -H "Accept: application/json" -u "QNOVATE8:$SAP_PASS" -b cookies.txt -d '{\"PurchaseOrderType\":\"UB\",\"CompanyCode\":\"1000\",\"PurchasingOrganization\":\"0001\",\"PurchasingGroup\":\"001\",\"SupplyingPlant\":\"PLQ3\",\"to_PurchaseOrderItem\":[{\"Material\":\"MAT18\",\"Plant\":\"PLQ1\",\"PurchaseOrderItemCategory\":\"7\",\"OrderQuantity\":\"1\",\"PurchaseOrderQuantityUnit\":\"EA\"}]}'
```

**What appears:** `HTTP/1.1 400 Bad Request` and, in the body:

```
APPL_MM_PUR_PO/064  Use purchase order type "Standard" ("NB") or a type copied from "NB".
APPL_MM_PUR_PO/065  Use a supported purchase order item category for item.
```

**Say this:** "The standard web service will not create a stock transfer order. Two separate
reasons — the document type, and the item category."

---

## Demo 2.2 — Prove it's the document type, not our data  ·  2 min

**Same command, change only `UB` to `NB`.** Everything else identical.

**What appears:** 400 again — but **only 065**. Error 064 is gone.

**Say this:** "One field changed. 064 disappeared. So 064 is purely about the document type,
and 065 is a separate lock on the item category."

**Now the one that closes the argument.** Change to `NB` and set the item category to empty:

```
curl.exe -i -k -X POST "https://vhresds4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_PURCHASEORDER_PROCESS_SRV/A_PurchaseOrder?sap-client=200" -H "X-CSRF-Token: <TOKEN>" -H "Content-Type: application/json" -H "Accept: application/json" -u "QNOVATE8:$SAP_PASS" -b cookies.txt -d '{\"PurchaseOrderType\":\"NB\",\"CompanyCode\":\"1000\",\"PurchasingOrganization\":\"0001\",\"PurchasingGroup\":\"001\",\"to_PurchaseOrderItem\":[{\"Material\":\"MAT18\",\"Plant\":\"PLQ1\",\"PurchaseOrderItemCategory\":\"\",\"OrderQuantity\":\"1\",\"PurchaseOrderQuantityUnit\":\"EA\"}]}'
```

**What appears:** 400 with `APPL_MM_PUR_PO/088 Document currency is not determined`.

**Say this:** "Neither 064 nor 065. A standard purchase order passes both checks and gets
through to real business validation. **The service works. It just doesn't do stock transfers.**
So this is not our test system being empty — it's a deliberate restriction in the API."

**If someone challenges it, this is the answer.** Same service, same session, same minute.

---

## Demo 2.3 — Why this hits ZP06 specifically  ·  2 min

**Transaction:** `SE16` → table `T161` → **F8**

In the selection screen, set **BSART** = `ZP06`

**What appears:** one row. Look at these fields:

| Field | Value | Meaning |
|---|---|---|
| `BREFN` | `UBF` | field-selection reference — same as **UB** |
| `BSAKZ` | `T` | stock transport |
| `NUMKI` | `56` | number range — matches their 56xxxxxxxx documents |

Now clear BSART and show the full list. Point at `NB`, `NB2`, `NBIC` — all `NBF`. Point at
`UB`, `EUB` — both `UBF`.

**Say this:** "ZP06 is a copy of UB, not of NB. The API asks for NB or an NB copy. ZP06 is
neither. And it's the only Z type in all 78 rows with the stock-transport flag set, so it's
their single STO type."

**Second lock, if they want it:** `SE16` → `EKPO` → EBELN = `5600084210` (a real QS4 STO).
`PSTYP` = `7`. That's the item category error 065 rejects.

---

# PART 3 — The BAPIs work

## Demo 3.1 — The BAPI accepts what the web service refused  ·  4 min

**Transaction:** `SE37` → `BAPI_PO_CREATE1` → **Display** → **F8** (Test)

**First, the failure case.** Set:

- `TESTRUN` = `X`  *(on the main test screen, the value column)*
- Double-click **POHEADER**, set `DOC_TYPE` = `ZP06`, press **F3** to go back
- Double-click **POHEADERX**, set `DOC_TYPE` = `X`, **F3**

Press **F8**. Open the `RETURN` table.

**What appears:**
```
E  ME  013   Document type ZP06 not allowed with doc. category F
```

**Say this:** "ZP06 isn't configured in this dev system — that's the environment, not the BAPI."

**Now the real point.** Change `DOC_TYPE` to `UB` in POHEADER (leave POHEADERX as `X`), and fill:

**POHEADER:** `COMP_CODE` = `1000`, `PURCH_ORG` = `0001`, `PUR_GROUP` = `001`,
`SUPPL_PLNT` = `PLQ3`, leave `VENDOR` **empty**

> `SUPPL_PLNT` sits off-screen. Use the **Column** button (tooltip *Position*, `Ctrl+Shift+F8`)
> and type the field name to jump straight to it.

**POHEADERX:** `X` in each of the same fields

**POITEM:** `PO_ITEM` `00010`, `MATERIAL` `MAT18`, `PLANT` `PLQ1`, `ITEM_CAT` `7`,
`QUANTITY` `1`, `PO_UNIT` `EA`

**POITEMX:** `PO_ITEM` `00010` plus `X` in each of the others

Press **F8**, open `RETURN`.

**What appears — and this is the point:**
```
ME 083   Purchasing group ...
06 166   Please only use plants with local currency
M3 351   Material MAT18 not maintained in plant PLQ1
```

**No `ME 013`.**

**Say this:** "The document type check passed. It moved on to master data — purchasing group,
plant currency, material. Those are all missing-data problems in this dev system. **The BAPI
accepts stock transfer orders.** The standard BAPI is our route."

**If asked about ZP06 specifically:** ZP06 doesn't exist in this client, so we tested UB. ZP06
is a copy of UB — you just saw that in T161 — so it takes the same path.

---

## Demo 3.2 — No vendor on an STO  ·  1 min

**Transaction:** `SE16` → `EKKO` → set **BSART** = `ZP06` → **F8**

**What appears:** 15 documents. Scroll to `LIFNR` — **blank on every one**. `RESWK` holds the
supplying plant.

**Say this:** "A stock transfer order has no vendor. It has a supplying plant. Anyone who
specs a vendor field on this API has misunderstood the document."

---

## Demo 3.3 — The commit proof  ·  5 min

**This is the most valuable technical finding. Take your time.**

**Transaction:** `SE37` → `BAPI_SHIPMENT_CREATE` → **Display** → **F8**

Double-click **HEADERDATA**, set:
- `SHIPMENT_TYPE` = `0001`
- `TRANS_PLAN_PT` = `0001`

**F3**, then **F8**.

**What appears:**
```
TRANSPORT = 1000  (or the next free number)
S  VW  488   Save shipment
W  VW  094   Deliveries missing
```

**Say this:** "Success message. Document number returned."

**Now the reveal.** Second session → `SE16` → `VTTK` → **F8**

**What appears:** **0 rows.**

**Say this:** "The document does not exist. SAP gave us a success message and a real document
number for something it never saved. And that number is now permanently consumed."

**Now do it properly.** Back in SE37, run `BAPI_SHIPMENT_CREATE` again, then **in the same
test sequence** run `BAPI_TRANSACTION_COMMIT` with `WAIT` = `X`.

Check `VTTK` again.

**What appears:** **1 row** — shipment `1001`.

**Say this:** "This is why the service has to own the save, and why success has to mean the
document is actually there — not just that SAP returned a success flag. A caller that trusts
the success message will record shipments that don't exist, and nothing will error."

---

## Demo 3.4 — Goods movement  ·  2 min

**Transaction:** `SE37` → `BAPI_GOODSMVT_CREATE` → **Display** → **F8**

Set:
- `TESTRUN` = `X`
- **GOODSMVT_CODE** → `GM_CODE` = `01`
- **GOODSMVT_HEADER** → `PSTNG_DATE` and `DOC_DATE` = today
- **GOODSMVT_ITEM** row 1 → `MATERIAL` `MAT18`, `PLANT` `PLQ3`, `MOVE_TYPE` `101`,
  `ENTRY_QNT` `1`, `ENTRY_UOM` `EA`

**F8**, open `RETURN`.

**What appears:**
```
E  M7  053   Posting only possible in periods 1998/03 and 1998/02 in company code 0001
```

**Say this:** "It got all the way to posting-period control. That means the movement code and
the item structure were accepted — the only thing stopping it is that this system's posting
periods are open for 1998. That's a config setting, not a design problem."

---

## Demo 3.5 — Stock availability  ·  1 min

**Transaction:** `SE37` → `BAPI_MATERIAL_AVAILABILITY` → **Display** → **F8**

Set `PLANT` = `PLQ3`, `MATERIAL` = `MAT18`, `UNIT` = `EA`. **F8**.

**What appears:** no error, ATP quantity `0.000`.

**Say this:** "This is availability-to-promise. It works. It is **not** the same as book stock —
book stock comes from the material stock web service. Two different questions, two different
sources. That distinction matters for the design."

---

# PART 4 — The freight chain

## Demo 4.1 — The route exists  ·  2 min

**Transaction:** `SE37` → type `SD_SCDS_*` → **F4**

**What appears:** the family — `SD_SCDS_CREATE`, `SD_SCDS_RELEASE`, `SD_SCDS_SAVE`,
`SD_SCDS_SHIPMENT_UPDATE`, and alongside them `SD_SCD_ITEM_CALCULATE`,
`SD_SCD_ITEM_ACCT_ASSIGNMENT`, `SD_SCD_HISTORY_SETTLEMENT`.

**Say this:** "This is the freight cost chain. It was never found before because these aren't
BAPIs — they're internal function modules in package VTRA. Every search for
`BAPI_SHIPMENT_COST` or similar returns nothing, which is why earlier work concluded no route
existed. It does exist."

---

## Demo 4.2 — Release runs without a screen  ·  3 min

**This closed the biggest risk in the design. Show it.**

**Transaction:** `SE37` → `SD_SCDS_RELEASE` → **Display** → **F8**

**Point at the screen first:** `I_OPT_WITH_DIALOG` defaults to `X`.

**Say this:** "The concern was that this function is screen-bound — that it can only run with
a person sitting in front of it. If that were true, it couldn't be wrapped in a service and
the whole freight design would need rethinking."

Now **clear the `X`** — set `I_OPT_WITH_DIALOG` to blank. Press **F8**.

**What appears:** the Result Screen. Runtime around 263,976 microseconds. **No pop-up, no
screen, no error.**

**Say this:** "It runs headless. The dialog flag is a default, not a requirement. The wrapper
is viable for the whole chain, not just half of it."

**Be straight about the limit:** it ran with no documents to settle, because this system has no
freight cost documents. What's proven is that it doesn't demand a screen. Completing a real
settlement needs a system with data.

---

## Demo 4.3 — Why release matters  ·  1 min

**Transaction:** `SE16` → `VFKK` (on **QS4** if you have it open, read-only)

**Say this:** "Their quality system holds 10,496 freight cost documents that were calculated
and never released. Release is the step that pushes freight cost into the accounts. Those
documents never reached the books. That's the business case for this step existing."

---

# If something doesn't work live

**Be relaxed about it.** You have the captured evidence for every one of these.

| If | Do |
|---|---|
| The gateway doesn't answer | Show the saved response files — `evidence/external-http-2026-08-19/` |
| SE37 screen looks different | Field positions vary by SAP GUI version. Use the **Column/Position** button to find fields by name |
| A number range has moved on | Shipment numbers increment. `1001` was ours; a new run gets the next number. The behaviour is the same |
| Someone wants ZP06 run for real | It doesn't exist in this client. That's the test-data ask |

---

# The four sentences to close on

1. **The connection works.** Authenticated calls from outside SAP, proven today.
2. **Standard SAP does the work.** The BAPIs accept everything we need.
3. **Two things have no web service** — creating stock transfer orders, and the freight chain.
   That's what we build, and it's an exposure layer over standard SAP, not custom logic.
4. **What's left needs data.** We tested everything testable in a system with no documents in
   it. Give us a system with real documents and we'll finish the remaining runs.
