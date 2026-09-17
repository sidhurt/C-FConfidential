# Create DI portal screen

**Source ID:** `SRC-SID-20260917-09`  
**Date:** 2026-09-17  
**Source type:** Portal design screenshot supplied by Siddharth, replacing the "Initiate MIGO" image supplied earlier as Create DI context

## What the screen shows

"Create Delivery Instruction" modal for one sales order line:

- **Displayed, read-only:** order status (Partial), order ID `4700987`, order date, product
  (Bangur POWERMAX TR PPC PP 50KG, `0013000083`), ship-to (Solapur Yard, address), Incoterm
  (`FTP`), customer (Shiva Traders & Suppliers, `11023488`), distribution channel (`10`), CRM
  remarks, distance (233 KM), source plant (PB NAWAN PIND), ship-to zone, ordered quantity (30 MT),
  pending quantity (25 MT).
- **Only user input:** Delivery Quantity (MT), mandatory.
- Action: Create Delivery Instruction.

Values are illustrative design data, not QS4 documents.

## What this establishes

- The Create DI request carries one order line and a quantity. Every other field is display data
  from the portal read model. This matches the proven five-field OData request (shipping point,
  order, item, quantity, unit) used for delivery `9004953534`.
- Storage location/batch, SPI, transporter, vehicle and LR/GR are **not** Create DI inputs. The
  "Initiate MIGO" screen supplied earlier (`SRC-SID-20260917-08`) is receipt-side context and must
  not be read as Create DI scope.
- One DI is raised per order line, so a multi-material DI does not arise from this screen.

## Boundary

- How the portal maps source plant to SAP shipping point, and how it presents pending quantity
  (portal read model versus live SAP check), are not shown.
- Rules applying at later steps (storage location/batch, transporter, shipment details) are outside
  this screen.
