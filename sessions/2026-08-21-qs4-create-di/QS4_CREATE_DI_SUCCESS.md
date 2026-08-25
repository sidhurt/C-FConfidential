# QS4/700 Create DI — persisted success

Date: 2026-08-21  
System/client: QS4/700  
User: QNOVATE8

## External request

Exactly one creating request was sent:

```http
POST /sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader?sap-client=700
```

```json
{
  "ShippingPoint": "1002",
  "to_DeliveryDocumentItem": [
    {
      "ReferenceSDDocument": "5600084209",
      "ReferenceSDDocumentItem": "000010",
      "ActualDeliveryQuantity": "1",
      "DeliveryQuantityUnit": "TO"
    }
  ]
}
```

`ReferenceSDDocumentCategory` was omitted because live metadata marks it non-creatable.

## Result

- HTTP `201 Created`
- Created outbound delivery: `9004953174`
- Immediate header GET: HTTP `200`
- Immediate predecessor-item GET: HTTP `200`, new item `9004953174/000010`, quantity `1.000 TO`
- POST attempt count: exactly `1`

## Independent SAP readback

LIKP:

- `VBELN=9004953174`
- `LFART=ZNL`
- `VSTEL=1002`
- `VKORG=1000`
- `KUNNR=P5412`
- `ROUTE=P27356`
- `VBTYP=J`
- `WBSTK=A`
- `WADAT_IST` blank

LIPS item `000010`:

- `MATNR=000000000015000177`
- `WERKS=1002`
- `LGORT` blank
- `LFIMG=1 TO`
- `VGBEL=5600084209`
- `VGPOS=000010`
- `BWART=641`
- `WBSTA=A`

VBFA had no row at this stage. The persisted predecessor relationship is independently confirmed by `LIPS-VGBEL/VGPOS`.

## Certification statement

`API_OUTBOUND_DELIVERY_SRV;v=2` is materially proven in QS4/700 for Create DI from an STO: an external deep-insert call created a real, persisted SAP outbound-delivery header and item. This is not a connectivity-only or validation-reachability result.
