# C&F Create DI depot scope

**Source ID:** `SRC-SID-20260917-06`  
**Date:** 2026-09-17  
**Source type:** Direct clarification from Siddharth

Asked whether (1) C&F Create DI is depot dispatch to customers through Trade/Non-trade sales orders and (2) a C&F depot also creates STO deliveries depot to depot, Siddharth answered: **both**.

## What this establishes

- C&F Create DI originates at a depot (`KNA1-KDKG1 = 'A2'` on `P<plant>`).
- Two predecessor routes are in scope: depot sales order (Trade/Non-trade, `_SLS`) and depot-to-depot STO (`_STO`).
- Factory-origin deliveries are not the C&F Create DI population. The existing STO candidates from plant `1002` (A1) therefore serve only as path-mechanics fixtures, not rule fixtures.

## Boundary

- Whether the factory bill-to-ship-to flow (STO delivery carrying `LIKP-ZZVBELN`) is excluded from C&F was not separately stated. The 2026 QS4 population shows `ZZVBELN` only on factory-origin `ZNL` deliveries (`sessions/2026-09-14-create-di-enhancement-equivalence/QS4_READ_2026-09-17_PLANT_CLASS_AND_ZZVBELN.md`), so V07/V08 are expected to be unreachable for depot-origin C&F deliveries; confirm before removing them from scope.
- The depot-to-depot STO delivery type and whether it ever carries `ZZVBELN` are not yet observed.
