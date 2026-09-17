# Create DI — delivery block, billing block and bill-to-ship-to requirements

**Source ID:** `SRC-SID-20260917-10`  
**Date:** 2026-09-17  
**Source type:** Business answer relayed directly by Siddharth

The business stated that Create DI must apply all three:

1. **Delivery block** — a DI must not be created for an order carrying a delivery block.
2. **Billing block** — a DI must not be created for an order carrying a billing block.
3. **Bill-to-ship-to** — the bill-to-ship-to controls (blocked customer order; total quantity against
   the customer order) are in scope.

## Technical position at time of receipt

- Credit block: already refused by standard SAP on OData (`VL/060`, 17.09.2026).
- Delivery block: normally refused by standard SAP when the block reason is configured to block
  delivery; not yet tested or configuration-read.
- Billing block: standard SAP does not refuse delivery creation. The existing custom check (`ZLE 088`)
  inspects billing block only on the order held in `LIKP-ZZVBELN`, which is blank for depot sales-order
  deliveries. Enforcement on the depot Create DI path therefore needs a change or new check.
- Bill-to-ship-to: `ZZVBELN` was filled only on factory-origin `ZNL` deliveries. The standard OData
  request cannot send it, and T0 proved OData extension fields are mapped after
  `DELIVERY_FINAL_CHECK`. Its writer is unidentified.

## Boundary

The original business communication was not supplied. Which C&F location raises bill-to-ship-to DIs
(depot or factory) was not stated.
