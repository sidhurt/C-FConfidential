# Dormant rules register - what would make them apply to C&F again

**Date:** 2026-09-15
**Status:** these rules are NOT removed from scope. They are currently unreachable for C&F
given today's plants and configuration. This register records the exact condition that would
make each one live again, so nothing is lost if the client's process details change.

**Context.** Plant classification lives in `KNA1-KDKG1` on pseudo-customer `P<plant>`.
Observed in QS4/700: **A1** = cement factories (Beawar, Khushkhera, Panipat, Suratgarh, SGU-2,
JGU, RNCU, Cuttack), **A2** = depots/warehouses, **A4** = RMC plants. C&F is understood to be a
depot-type operation, so C&F deliveries are not expected to carry A1. Confirmed as close to
correct by Siddharth on 2026-09-15, with the caveat that business-process details may still
surface exceptions.

| Rule | Why dormant for C&F today | What would wake it | Cost to wake | Who controls it |
|---|---|---|---|---|
| **V04** `ZLE 210` route config missing | Gated only by `ZTA_PMD_VALID`, which holds plants 1000/1005/1012/1045 (all A1) | **One row added to `ZTA_PMD_VALID`** for any C&F plant | **Very low - single Z-table entry** | Whoever maintains `ZTA_PMD_VALID` |
| **V05** `ZLE 208` qty over vehicle capacity | Same `ZTA_PMD_VALID` gate | Same single row | **Very low** | Same |
| **V06a** `ZLE 079` route row missing | Same `ZTA_PMD_VALID` gate, plus `LIKP-ERDAT >= 20250823` | Same single row | **Very low** | Same |
| **V06b** `ZLE 077` freight scale exceeded | Needs (a) plant A1, (b) a route with `ZOVERWT = 'No'` - no route has that value in 86 rows, (c) pricing table available on the path | All three together | Medium | Route config + plant master + pricing |
| **V10** `ZLE 187` primary-plant SPI must be blank | Needs (a) plant A1 and (b) set `ZSPIWERKS`, which **does not exist** in `SETLEAF` or `SETHEADER` | Someone creates the set AND an A1 plant enters scope | Medium | Whoever creates GS sets |

### Added 2026-09-17 — `ZZVBELN`-dependent rules

| Rule | Why dormant for C&F today | What would wake it | Cost to wake | Who controls it |
|---|---|---|---|---|
| **V07** `ZLE 088` blocked referenced sales order | Runs only when `LIKP-ZZVBELN` is filled. Filled on 2 of 153,514 deliveries 25.07–17.09.2026 (factory BTST test) and on **0 depot** deliveries | Whatever writes `ZZVBELN` starting to fill it on depot deliveries, or BTST entering C&F scope | Unknown — writer not yet identified | Owner of the `ZZVBELN` writer / BTST process |
| **V08** `ZLE 087` cumulative quantity vs order | Same dependency | Same | Same | Same |

Standard SAP still refuses credit-failed orders and item over-delivery, which covers most of the
intent. Classification is **strong inference** until the `ZZVBELN` writer is read. Evidence:
`QS4_READ_2026-09-17_PLANT_CLASS_AND_ZZVBELN.md` sections 2 and 4.

## The risk worth naming to the client

**V04 is the sharp one.** It is gated only by `ZTA_PMD_VALID`, it has **no transaction-code gate
and no create/change gate**, so it executes on every delivery save - creation, change and goods
issue alike. A single row added to that table would switch it on for C&F with no code change, no
transport of code, and no technical review.

**Underneath all of these sits master data.** `KDKG1` is a field on a customer record. Changing
it reclassifies a plant from depot to primary in one edit. That path bypasses any code review.

## Correct wording for the client

Not: "primary plant rules do not apply to C&F."

Instead: "primary plant rules do not apply to C&F **as the plants and configuration stand
today**. Four of them are one configuration entry away from applying. If C&F scope ever includes
a factory-origin dispatch, or if `ZTA_PMD_VALID` is extended, these must be re-tested."

## Still in scope for C&F regardless

Depot-side rules are unaffected by any of the above: V02 (screen-only), V03 (`ZLETSPIMAP`
storage-location/SPI pair), V09a and V09b (transporter), V11 (ZNL YSTO condition), and the
P1-P4 depot prerequisite set in `ZLEF_DELIVERY_VALIDATONS`.

**SPI simplification that follows:** for depot (A2) deliveries the rule is single-valued - SPI
must be **filled**, and the `LGORT` + `SDABW` pair must exist in `ZLETSPIMAP`. The opposite
primary-plant rule (SPI must be blank) only re-enters if V10 wakes per the table above.
