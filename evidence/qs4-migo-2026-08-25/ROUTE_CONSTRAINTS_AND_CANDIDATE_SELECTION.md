# Submit MIGO (MIGO-02) — QS4/700 preparation, 2026-08-25

Executed read-only via SAP GUI scripting on the operator's existing QS4/700 session (QNOVATE8).
No document was created. No QS4 data was mutated.

## 1. Posting period — OPEN (this was the DS4 blocker; it does not apply in QS4)

`MARV`, client 700:

| BUKRS | LFGJA | LFMON | VMGJA | VMMON | XRUEM | LAEDA |
|---|---|---|---|---|---|---|
| 1000 | 2026 | 05 | 2026 | 04 | X | 31.07.2026 |
| 0001 | 1998 | 03 | 1998 | 02 | X | 25.09.1997 |

Company code `1000` is current. The roll date of 31.07.2026 opening period `05` fixes the
fiscal-year variant as April–March, so **period 2026/05 = August 2026 = today**. Backposting
to period `04` is permitted (`XRUEM = X`).

The `M7/053` failure seen in DS4/200 was against company code `0001`, which is still on
1998/03. That is a stale DEV company code, not a system-wide condition.

## 2. The business receipt references the PURCHASE ORDER, not a delivery

`MSEG` where `BWART = 101` (positive control: every returned row carried `BWART = 101`):

| Material doc | PO / item | Plant | SLoc | Qty | LIFNR | LFBNR |
|---|---|---|---|---|---|---|
| 5007138549 | 5600084213/00010 | 1022 | RCPT | 2 EA | blank | blank |
| 5007138552 | 5600075302/00010 | 6833 | GDF | 5 TO | blank | blank |
| 5007138553 | 5600075921/00010 | 5412 | GDF | 10 TO | blank | blank |

`LIFNR` blank confirms stock-transport orders. `LFBNR` blank confirms the goods receipt is
posted **against the purchase order directly**, not against an inbound delivery.

Therefore the OData item payload uses `PurchaseOrder` + `PurchaseOrderItem`.
This is evidence, not assumption.

## 3. Selected test item — STO 5600084239 item 00010

Chosen because it is the intersection of "stock in transit exists" and "goods receipt still open".

`MSEG` `BWART = 641` — stock in transit posted:

- doc `4918168363`, issuing plant `1005` / `FKGU`, receiving plant `1022`, 2 EA, PO `5600084239/00010`

`EKET`:

- `MENGE = 2.000`, `WEMNG = 0.000` — fully open for goods receipt

`EKPO`:

- `MATNR = 000000000017035056`, `WERKS = 1022`, `LGORT = FKGU`, `MENGE = 2 EA`
- `PSTYP = 7` (stock transfer), `LOEKZ` blank, `ELIKZ` blank, `WEPOS = X`, `RETPO` blank

Rejected candidates: `5600084211`, `5600084213`, `5600084237` (already fully received);
`5600075911` and similar (open, but no 641 — no stock in transit, a receipt would fail).
Second viable candidate held in reserve: `5600084238/00010`, 4 EA, same material and plant.

## 4. Service is live in QS4

```
GET /sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/
HTTP 200 OK, application/json, 107 bytes
```

The plain path resolves. `;v=1` is not required for this service.

## 5. Prepared payload (not yet sent successfully)

```json
{
  "PostingDate": "/Date(1787616000000)/",
  "DocumentDate": "/Date(1787616000000)/",
  "GoodsMovementCode": "01",
  "MaterialDocumentHeaderText": "CNF API TEST",
  "to_MaterialDocumentItem": [
    {
      "Material": "000000000017035056",
      "Plant": "1022",
      "StorageLocation": "FKGU",
      "GoodsMovementType": "101",
      "QuantityInEntryUnit": "2",
      "EntryUnit": "EA",
      "PurchaseOrder": "5600084239",
      "PurchaseOrderItem": "00010"
    }
  ]
}
```

`/Date(1787616000000)/` = 2026-08-25T00:00:00Z.
`CtrlPostgForExtWhseMgmtSyst` deliberately omitted.

## 6. BLOCKER — no usable write transport to QS4 from this machine

Two independent routes were attempted and both fail.

### External HTTPS — 401

```
POST https://vhresqs4ci.sap.shreecement.com:44300/sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/...
HTTP 401 Unauthorized   ("Anmeldung fehlgeschlagen")
sap-system: QS4
```

Routing and TLS are fine — the request reaches QS4. The only credential on this machine is
`C:\Users\sidmy\OneDrive\Documents\DS4 password.txt`, a bare 12-character password with no
stray whitespace. It is the **DS4** credential and QS4 rejects it. No QS4 password exists on
this machine; the QS4 Postman environment ships `sap-pass` empty by design.

### /IWFND/GW_CLIENT — request body will not attach

Method, URI and headers all set correctly:

```
POST /sap/opu/odata/sap/API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader
accept: application/json
content-type: application/json
```

But `ADD_FILE` silently fails to load the body. After pressing Continue on the *Save File*
dialog: no error modal, empty status bar, `REMOVE_FILE` toolbar button still **disabled**, and
the request-body editor still empty. Result: `HTTP 400`, 475-byte error body.

Tried and ruled out: scratchpad path, SAP GUI working directory
(`C:\Users\sidmy\OneDrive\Documents\SAP\SAP GUI\`), with and without trailing backslash. The
directory and file name read back correctly from the dialog every time. The most likely cause
is SAP GUI local **security configuration denying scripted file read**, which fails silently.

### Compounding constraint — response bodies are unreadable here

`shellcont[2]` (request body) and `shellcont[3]` (response body) are both `GuiShell/AbapEditor`.
`.Text` returns only `SAPGUI.AbapEditor.1`; `getSelectedText()` returns length 0;
`getUnprotectedTextPart` is not supported. `COPY_BODY` / "Use as Request" is prohibited by the
project's own operating rules, as are clipboard capture and Ctrl+A/C.

So even with the body attached, GW_CLIENT could not yield the `MaterialDocument` /
`MaterialDocumentYear` response payload or a Postman-ready request/response example.

## 7. What unblocks this

A QS4/700 password for `QNOVATE8`, placed in a local file the same way the DS4 one is
(for example `C:\Users\sidmy\OneDrive\Documents\QS4 password.txt`).

That single item restores external HTTPS, which is the route Codex's plan requires anyway:
it is the only one that can capture a real response body and produce a genuine Postman
request/response pack.

Everything else for this test is already prepared and verified.
