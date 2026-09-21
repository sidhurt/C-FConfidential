# Hybris enrichment ownership and duplicate blocking

**Source ID:** `SRC-SID-20260917-08`  
**Date:** 2026-09-17  
**Source type:** Direct clarification from Siddharth (corrected the same day), with a portal "Initiate MIGO" screen image supplied as UI context

## Stated (corrected)

1. **SAP must provide an API that receives the enrichment fields** (transporter, storage location/batch and the other DI enrichment values) from Hybris T2. Hybris does not write them into SAP through an existing interface.
2. SAP master data flows to Hybris T2 as a near-real-time data-sync event; Hybris continuously updates itself from SAP. **SAP remains the authoritative state.**
3. Some custom fields arise downstream of the DI and in the subsequent Pre-PGI steps, so not every field is available at every step.
4. The Hybris front end or CPI must block duplicate DIs.

An earlier reading of statement 1 ("Hybris writes the fields") was corrected by Siddharth: Hybris is the caller; the SAP-side receiving API is to be built.

## Screen context supplied

The "Initiate MIGO" screen shows, for DI `900409985`: status partial, LR/GR, transporter name and number, vehicle, invoice number/date, source plant, total/pending quantity, ageing, a vehicle tracking link, and allocation of the pending quantity across receiving storage locations (`GDF`, `CUT`, `DMG`, `RDFR`, `GDRK`, `RDSH`, `RSD`, `STG`) with the rule that the total must not exceed pending quantity. It is receipt-side design context, not an implementation instruction.

## Consequences

- The enrichment write path (Q-082) is a **SAP API to build**. The standard `API_OUTBOUND_DELIVERY_SRV;v=2` cannot write SPI or the transporter partner (metadata), so this is not a standard-direct call.
- Runtime T0 (`CREATE_DI_TEST_APPROACH_2026-09-17.md` §8) proved `DELIVERY_FINAL_CHECK` runs before `SAVE_DOCUMENT_PREPARE`. For V09a/V09b to work, the API must place the transporter in the delivery partner table before the save checks — not only in `LIKP-ZZPARTNER`, which is converted to a partner after the checks.
- Duplicate protection sits outside SAP. After a timeout the caller must still look up existing deliveries before retrying.

## Scope clarification (Siddharth, 17.09.2026)

Statements 1–3 describe the **dispatch steps after Create DI** (storage location/batch, transporter,
shipment details), not Create DI itself and not Submit MIGO. That logic is deferred until those APIs
are taken up. Statement 4 (duplicate DIs blocked by Hybris or CPI) applies to Create DI now.
