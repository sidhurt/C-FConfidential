# Create DI API — validated information

## Validation

| Item | Value |
|---|---|
| System | QS4/700 |
| Date | 21 August 2026 |
| User | `QNOVATE8` |
| Result | `201 Created` |
| STO | `5600084209/000010` |
| Created DI | `9004953174/000010` |
| Quantity | `1.000 TO` |
| External POST count | Exactly one |

## API

| Item | Value |
|---|---|
| Service | `API_OUTBOUND_DELIVERY_SRV;v=2` |
| Protocol | OData V2 |
| SEGW project | `API_OUTBOUND_DELIVERY_0002` |
| Entity | `A_OutbDeliveryHeader` |
| Method | `POST` deep insert |
| QS4 alias | `LOCAL` |
| Path | `/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=2/A_OutbDeliveryHeader?sap-client=700` |

`;v=2` is mandatory. Without it, Gateway returns HTTP `403`, `/IWFND/MED/170`, because version 1 is not registered.

## Validated request

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

Required HTTP handling: authenticated session, CSRF token and matching session cookie.

`ReferenceSDDocumentCategory` was omitted because live metadata marks it `sap:creatable="false"`.

## Request field mapping

| OData property | SAP field |
|---|---|
| `ShippingPoint` | `LIKP-VSTEL` |
| `ReferenceSDDocument` | `LIPS-VGBEL` |
| `ReferenceSDDocumentItem` | `LIPS-VGPOS` |
| `ActualDeliveryQuantity` | `LIPS-LFIMG` |
| `DeliveryQuantityUnit` | `LIPS-VRKME` |

## Persisted result

### LIKP — `9004953174`

| Field | Value |
|---|---|
| `VBELN` | `9004953174` |
| `LFART` | `ZNL` |
| `VSTEL` | `1002` |
| `VKORG` | `1000` |
| `KUNNR` | `P5412` |
| `ROUTE` | `P27356` |
| `VBTYP` | `J` |
| `WBSTK` | `A` |
| `WADAT_IST` | Blank |

### LIPS — `9004953174/000010`

| Field | Value |
|---|---|
| `MATNR` | `000000000015000177` |
| `WERKS` | `1002` |
| `LGORT` | Blank |
| `LFIMG` | `1.000` |
| `VRKME` | `TO` |
| `VGBEL` | `5600084209` |
| `VGPOS` | `000010` |
| `BWART` | `641` |
| `WBSTA` | `A` |

SAP derived the delivery type, material, plant, customer, route and movement type.

## Document flow

| Table | Relevant fields/result |
|---|---|
| `LIPS` | `VGBEL=5600084209`, `VGPOS=000010` |
| `EKBE` | `VGABE=8`, `BEWTP=L`, `BELNR=9004953174`, quantity `1.000` |
| `VBFA` | No PO-to-delivery row, correct because the predecessor is an MM purchase order |

## Tables

| Area | Tables |
|---|---|
| STO header/item/schedule/history | `EKKO`, `EKPO`, `EKET`, `EKBE` |
| Delivery header/item | `LIKP`, `LIPS` |
| SD document flow/status | `VBFA`, `VBUK`, `VBUP` |
| Relevant configuration | `T161`, `TVLK` |

## Transaction codes

| Tcode | Area |
|---|---|
| `ME23N` | STO and Purchase Order History |
| `VL03N` | Display outbound delivery |
| `VL02N` | Change outbound delivery |
| `VL06O`, `VL06G`, `VL06F` | Delivery lists/monitoring |
| `VL10X` | STO delivery-due processing observed in QS4 |
| `ZLE020` | Historical custom STO delivery creation route |
| `SE16N`, `SE11` | Table and field checks |
| `SEGW` | Project `API_OUTBOUND_DELIVERY_0002` |
| `/IWFND/MAINT_SERVICE` | Gateway service/version/alias |
| `/IWFND/GW_CLIENT` | OData execution |
| `/IWFND/ERROR_LOG` | Gateway errors |
| `SICF` | ICF activation |
| `ST22` | ABAP dumps |
| `SU53` | Authorization failures |

## Runtime behavior

| Request | Result |
|---|---|
| Header plus referenced item | `201 Created` |
| Header only | `405`, `CX_SADL_ENTITY_CUD_DISABLED` |
| Empty item array | `500` with dump reference |
| Missing predecessor document | `500`, `VL/002` |
| Path without `;v=2` | `403`, `/IWFND/MED/170` |

`A_OutbDeliveryItem` and `A_OutbDeliveryDocFlow` are not independently creatable. The API has no caller-supplied idempotency key, so a repeated request can create another delivery if open quantity remains.

## Scope validated

Validated: STO -> outbound-delivery header/item creation and predecessor linkage.

Not included: storage-location assignment, picking, batch split, shipment, shipment cost, PGI, billing, e-Invoice or E-Way Bill.

