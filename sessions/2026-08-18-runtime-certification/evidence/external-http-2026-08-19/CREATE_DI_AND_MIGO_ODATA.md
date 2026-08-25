# Create DI and Submit MIGO — OData create paths tested
**Executed 2026-08-20 from outside SAP, DS4/200. Both were previously untested.**

These close two gaps. We had tested the *BAPI* for goods movement but never the *OData*
create for either operation, and a BAPI result does not certify the OData route.

---

## Submit MIGO — `API_MATERIAL_DOCUMENT_SRV`

```
POST /API_MATERIAL_DOCUMENT_SRV/A_MaterialDocumentHeader?sap-client=200

{"GoodsMovementCode":"01",
 "to_MaterialDocumentItem":[
   {"Material":"MAT18","Plant":"PLQ3","GoodsMovementType":"101",
    "QuantityInEntryUnit":"1","EntryUnit":"EA"}]}
```

**HTTP 400**

```
M7/053   Posting only possible in periods 1998/03 and 1998/02 in company code 0001
```

### What this proves

The OData create endpoint **accepted the payload shape** — `GoodsMovementCode`, the
`to_MaterialDocumentItem` deep insert, the material, plant, movement type and quantity — and
carried it all the way to **posting-period control**, which is the same place
`BAPI_GOODSMVT_CREATE` stopped.

**Submit MIGO does not need a custom service.** The standard OData create works. The only
blocker is the MM posting period, which is a config setting.

This also independently confirms the earlier BAPI finding through a completely separate code
path — the blocker is the period, not valuation.

---

## Create DI — `API_OUTBOUND_DELIVERY_SRV;v=2`

Two distinct code paths, confirmed by three runs.

### Path 1 — deep insert with items (the correct one)

```
POST /API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader?sap-client=200

{"to_DeliveryDocumentItem":[
   {"ReferenceSDDocument":"5600084210","ReferenceSDDocumentItem":"00010"}]}
```

**HTTP 500**

```
VL/002   A document with number 5600084210 does not exist
```

`5600084210` is a real ZP06 stock transport order **in QS4**, not in DS4. So SAP took the
request, routed it to the real delivery-creation logic, went looking for the predecessor
document, and correctly reported that it is not in this client.

**That is the create path working.** It failed on missing data, not on capability.

### Path 2 — header only, no navigation property

```
POST /API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader?sap-client=200

{"ShippingPoint":"0001"}
```

**HTTP 405**

```
CX_SADL_ENTITY_CUD_DISABLED
Creating operations are disabled for entity
'API_OUTBOUND_DELIVERY_0002~A_OutbDeliveryHeader'
```

### What this proves

**A delivery can only be created as a deep insert that includes `to_DeliveryDocumentItem`.**
A plain header POST is rejected by the SADL layer before any business logic runs.

This is consistent with the metadata, which marks `A_OutbDeliveryItem` as
`sap:creatable="false"` — items cannot be created on their own, only as part of the header's
deep insert. What the metadata does **not** tell you is that the header alone is refused too.
That is only visible at runtime.

**Create DI does not need a custom service.** The standard route is live. It needs a
predecessor document to exist — a purchase order for STO, a sales order for Trade and
Non-trade.

---

## Practical warning for the build team

The metadata does not carry `sap:creatable="false"` on `A_OutbDeliveryHeader`, so a developer
reading only the schema would reasonably expect a header POST to work. It returns **405**.

**The rule is: always send the deep insert.** A header-only create looks legitimate in the
schema and fails at runtime with an error that reads like the whole service is read-only,
which it is not.

One further note — a deep insert with an **empty** item array returns a bare 500 with a dump
reference and no readable message. Send at least one item.

---

## Effect on the build scope

| Operation | Before | After |
|---|---|---|
| Submit MIGO | OData create untested | **Standard OData works** — blocked only by MM period |
| Create DI | OData create untested | **Standard OData works** — deep insert only, needs a predecessor |

Neither is a custom-service candidate. The custom build stays at:

1. **STO creation** — standard OData structurally refuses it
2. **The freight chain** — no standard web service exists
3. **Billing creation** — standard service is read-only

---

## Raw results

| Run | Body | HTTP | Code |
|---|---|---|---|
| MIGO | `GoodsMovementCode` + 1 item | 400 | `M7/053` posting period |
| DI | deep insert, ref `5600084210` | 500 | `VL/002` document does not exist |
| DI | deep insert, empty item array | 500 | unhandled, dump reference only |
| DI | header field only | 405 | `CX_SADL_ENTITY_CUD_DISABLED` |

No document was created by any of these calls.
