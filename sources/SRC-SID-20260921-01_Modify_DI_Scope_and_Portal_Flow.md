# Modify DI — scope, portal flow and field list

**Source ID:** `SRC-SID-20260921-01`
**Date:** 2026-09-21
**Source type:** Direct statements by Siddharth in session, with portal Figma screenshots

## Statements

1. **A Modify DI API is required.** The SD consultant corrected the earlier understanding. It
   must do what VL02N does for the business after Create DI.
2. **The portal flow after Create DI**, as designed in Figma, is:
   - Modal "Generate Billing Documents", with three tabs:
     - **DI Quantity** — update the DI quantity
     - **Batch Determination** — select a storage location; batch is auto-assigned FIFO with
       allocated quantity; SPI ID is shown
     - **Transporter Details** — partner function `SP Forwarding Agent` plus transporter code
   - Then **Shipment Details**:
     - LR/GR number and LR/GR date
     - vehicle number (format-validated)
     - driver code, driver name, driver mobile (10 digits)
     - **Pick Up Code** (required), under "Pick up code validation"
   - Final button: **Generate Invoice & E-Way Bill**.
3. **Transporter name and address** are derived from partner function plus transporter code.
   Both are maintained as transporter master data in T2/CPI.
4. The upper section of each screen (DI, order, ship-to, Incoterm, customer, channel, CRM
   remarks, distance, source plant, product) is **display context**, not input.

## Boundary

The Figma is a design, not a signed contract. Two inconsistencies are visible:

- the Incoterm shows FTP on most screens but FTB on one Shipment Details screen;
- the header shows 30.5 MT while the DI Quantity tab shows 30 MT.

The v1.9 workbook retired "Update DI Qty" (API-12) as not needed; this flow reinstates quantity
modification inside a wider Modify DI.
